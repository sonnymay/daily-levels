//
//  FocusEngine.swift
//  Daily Levels
//
//  The data layer + clock (SPEC §5). Owns the SwiftData context, the current
//  grinding/paused state, the 1-second UI ticker, and the lock classifier.
//
//  Swift note: `@Observable` (iOS 17) auto-publishes property changes to SwiftUI —
//  no @Published needed. Views read it via `@Environment(FocusEngine.self)`.
//  `@MainActor` keeps all mutation on the main thread (UI + timers live there).
//

import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class FocusEngine {

    enum Mode { case idle, grinding, paused }

    // MARK: Stored, observed state
    private(set) var mode: Mode = .idle
    /// Updated every second while grinding; drives all live UI (session clock, progress).
    private(set) var now: Date = Date()
    /// Completed grinding seconds per local day, cached from SwiftData.
    /// Recomputed on save/launch, not on every tick.
    private(set) var completedSecondsByDay: [Date: Int] = [:]

    // MARK: Non-observed internals
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private var activeStart: Date?            // start of current grinding stretch
    /// Focused seconds already banked in the *current logical session* from earlier stretches
    /// (before the latest resume). Drives the "Current session" clock so it survives pause/resume.
    /// Pure display state — daily totals come from persisted sessions, never from this.
    @ObservationIgnored private var sessionAccumulatedSeconds: Int = 0
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let classifier = LockClassifier()
    @ObservationIgnored static let activeStartKey = "engine.activeStart"

    // MARK: Init
    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
        reloadSessions()
        recoverFromColdLaunch()
        wireClassifier()
    }

    // MARK: Public actions (the one Start/Pause/Resume button)
    func toggle() {
        switch mode {
        case .grinding: pause()
        case .paused:   resume()
        case .idle:     start()
        }
    }

    /// Begin a brand-new focus session (clock from 0:00).
    func start() {
        guard mode != .grinding else { return }
        sessionAccumulatedSeconds = 0
        beginStretch()
    }

    /// Continue a paused session — the "Current session" clock picks up where it left off.
    func resume() {
        guard mode == .paused else { return }
        beginStretch()
    }

    func pause() {
        guard mode == .grinding else { return }
        if let s = activeStart {
            sessionAccumulatedSeconds += max(0, Int(Date().timeIntervalSince(s)))  // bank the live stretch
        }
        endActiveSession(at: Date())
        mode = .paused
        classifier.isActive = false
        stopTicker()
        FocusNotifications.cancelLevelUps()
        now = Date()
    }

    /// Shared start/resume mechanics: open a new grinding stretch and start the clock.
    private func beginStretch() {
        let t = Date()
        activeStart = t
        now = t
        mode = .grinding
        classifier.isActive = true
        UserDefaults.standard.set(t, forKey: Self.activeStartKey)   // crash marker (SPEC §5 edge 5)
        startTicker()
        // Schedule "you leveled up" pings for the locked/background case (SPEC §6 grind-while-locked).
        FocusNotifications.requestAuthorizationIfNeeded()
        FocusNotifications.scheduleLevelUps(currentSeconds: todaySeconds)
    }

    // MARK: Derived display values
    var isGrinding: Bool { mode == .grinding }
    /// Session is held — show "Resume" instead of "Start", and keep the clock on screen.
    var isPaused: Bool { mode == .paused }

    /// Today's grinding seconds = completed-today + live portion of the active session
    /// that falls after today's midnight (so a session crossing midnight only credits today).
    var todaySeconds: Int {
        secondsByDayIncludingLive()[startOfToday] ?? 0
    }
    var todayMinutes: Int { todaySeconds / 60 }
    var level: Int { LevelMath.level(forFocusMinutes: todayMinutes) }
    var knightClass: KnightClass { KnightClass.forLevel(level) }

    /// Focused seconds in the current session (the "Current session mm:ss" line):
    /// earlier banked stretches + the live stretch. Holds its value while paused.
    var currentSessionSeconds: Int {
        let live = (mode == .grinding && activeStart != nil)
            ? max(0, Int(now.timeIntervalSince(activeStart!)))
            : 0
        return sessionAccumulatedSeconds + live
    }

    /// True once the daily level cap (100 = Mythic) is reached — the UI shows a max state.
    var isMaxLevel: Bool { level >= LevelMath.maxLevel }

    /// 0...1 fill of the progress bar = seconds into the current level (full at the cap).
    var levelProgress: Double {
        guard !isMaxLevel else { return 1.0 }
        return Double(todaySeconds % LevelMath.secondsPerLevel) / Double(LevelMath.secondsPerLevel)
    }
    /// True at the instant a level completes — UI shows "Level up!" instead of "0 min" (SPEC §4).
    var isLevelUpMoment: Bool {
        todaySeconds > 0 && todaySeconds % LevelMath.secondsPerLevel == 0
    }
    /// Whole minutes until the next level — never 0 (clamped to 1).
    var minutesToNextLevel: Int {
        let remaining = LevelMath.secondsPerLevel - (todaySeconds % LevelMath.secondsPerLevel)
        return max(1, Int(ceil(Double(remaining) / 60.0)))
    }

    /// Sum of every day's level, ever (SPEC §2 "Hero lifetime level"; never resets).
    var lifetimeLevels: Int {
        secondsByDayIncludingLive().values.reduce(0) { $0 + LevelMath.level(forFocusMinutes: $1 / 60) }
    }

    /// Calm consecutive-day focus streak (days reaching at least Level 1). An unstarted
    /// today doesn't break it — no countdown anxiety. See `StreakMath`.
    var focusStreak: Int {
        StreakMath.currentStreak(secondsByDay: secondsByDayIncludingLive(), today: now, calendar: calendar)
    }

    /// Last 7 days, oldest → newest (rightmost = today) for the bar chart (SPEC §4).
    var weekHistory: [DaySummary] {
        let map = secondsByDayIncludingLive()
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday)!
            return DaySummary(date: day, focusMinutes: (map[day] ?? 0) / 60)
        }
    }

    /// Recent days for the list under the chart: today plus any past day with focus time,
    /// newest first (SPEC §4: "Date · Level N · X min focus time").
    var recentDays: [DaySummary] {
        let map = secondsByDayIncludingLive()
        let days = map.keys.filter { $0 < startOfToday && (map[$0] ?? 0) >= 60 } + [startOfToday]
        return Set(days).sorted(by: >).map { DaySummary(date: $0, focusMinutes: (map[$0] ?? 0) / 60) }
    }

    // MARK: Internals
    private var startOfToday: Date { calendar.startOfDay(for: now) }

    /// completedSecondsByDay + the active session's live seconds, attributed to the
    /// correct day(s) at the midnight boundary.
    private func secondsByDayIncludingLive() -> [Date: Int] {
        var map = completedSecondsByDay
        if mode == .grinding, let s = activeStart {
            for seg in DateUtils.splitAtMidnights(start: s, end: now, calendar: calendar) {
                let day = calendar.startOfDay(for: seg.start)
                map[day, default: 0] += Int(seg.end.timeIntervalSince(seg.start))
            }
        }
        return map
    }

    /// Persist the active stretch, split into one FocusSession per day (SPEC §5 edge 1).
    private func endActiveSession(at end: Date) {
        defer {
            activeStart = nil
            UserDefaults.standard.removeObject(forKey: Self.activeStartKey)
        }
        guard let start = activeStart else { return }
        for seg in DateUtils.splitAtMidnights(start: start, end: end, calendar: calendar) {
            let seconds = Int(seg.end.timeIntervalSince(seg.start))
            guard seconds > 0 else { continue }
            context.insert(FocusSession(startAt: seg.start, endAt: seg.end, durationSeconds: seconds))
        }
        try? context.save()
        reloadSessions()
    }

    private func reloadSessions() {
        let all = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        let segments = all.map { FocusSegment(startAt: $0.startAt, durationSeconds: $0.durationSeconds) }
        completedSecondsByDay = FocusLedger.secondsByDay(segments: segments, calendar: calendar)
    }

    /// SPEC §5 edge 5: if the app was killed mid-session we can't *prove* the user was
    /// grinding, so we conservatively discard the leftover marker and count zero.
    private func recoverFromColdLaunch() {
        Self.discardUnprovenActiveStart(defaults: .standard)
    }

    static func discardUnprovenActiveStart(defaults: UserDefaults = .standard) {
        if defaults.object(forKey: activeStartKey) != nil {
            defaults.removeObject(forKey: activeStartKey)
        }
    }

    // MARK: Ticker
    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.now = Date() }
        }
    }
    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

#if DEBUG
    // MARK: Debug helpers (compiled out of Release; triggered only by launch arguments)

    /// Honors `-seedDemoData` and `-autoStart` launch args so the populated / grinding
    /// screen can be inspected and screenshotted without touching real usage.
    func applyDebugLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        // Screenshot / demo launches shouldn't be covered by the first-run intro sheet.
        if args.contains("-seedDemoData") || args.contains("-autoStart") {
            UserDefaults.standard.set(true, forKey: "hasSeenIntro")
        }
        // `-todayMinutes N` overrides today's seeded focus time (drives class for screenshots).
        var todayMinutes = 20
        if let i = args.firstIndex(of: "-todayMinutes"), i + 1 < args.count, let n = Int(args[i + 1]) {
            todayMinutes = n
        }
        if args.contains("-seedDemoData") { seedDemoData(todayMinutes: todayMinutes) }
        var autoStartSecondsAgo: TimeInterval = 150
        if let i = args.firstIndex(of: "-autoStartSecondsAgo"), i + 1 < args.count,
           let n = TimeInterval(args[i + 1]) {
            autoStartSecondsAgo = n
        }
        if args.contains("-autoStart") { debugStartGrinding(secondsAgo: autoStartSecondsAgo) }
    }

    private func seedDemoData(todayMinutes: Int = 20) {
        // Wipe any existing sessions so the demo is repeatable.
        if let all = try? context.fetch(FetchDescriptor<FocusSession>()) {
            all.forEach { context.delete($0) }
        }
        // Past 6 days (levels 3,7,5,9,5,8) + today (caller-specified), echoing the mockup.
        let minutesByDaysAgo: [Int: Int] = [6: 15, 5: 35, 4: 25, 3: 45, 2: 25, 1: 40, 0: todayMinutes]
        for (daysAgo, minutes) in minutesByDaysAgo {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday)!
            let start = calendar.date(byAdding: .hour, value: 9, to: day)!
            let end = start.addingTimeInterval(Double(minutes * 60))
            context.insert(FocusSession(startAt: start, endAt: end, durationSeconds: minutes * 60))
        }
        try? context.save()
        reloadSessions()
    }

    private func debugStartGrinding(secondsAgo: TimeInterval) {
        activeStart = Date().addingTimeInterval(-secondsAgo)
        now = Date()
        mode = .grinding
        classifier.isActive = true
        startTicker()
    }
#endif

    // MARK: Lock classifier wiring (SPEC §6)
    private func wireClassifier() {
        // Phone locked → keep grinding; nothing to change, time keeps accruing.
        classifier.onLockDetected = { /* keep grinding */ }

        // Confirmed app switch → sleep. End the session at the moment of backgrounding
        // so the time spent in the other app never counts.
        classifier.onAppSwitchDetected = { [weak self] backgroundedAt in
            guard let self, self.mode == .grinding else { return }
            if let s = self.activeStart {
                self.sessionAccumulatedSeconds += max(0, Int(backgroundedAt.timeIntervalSince(s)))
            }
            self.endActiveSession(at: backgroundedAt)
            self.mode = .paused
            self.classifier.isActive = false
            self.stopTicker()
            FocusNotifications.cancelLevelUps()
        }

        // Returned to the app. If we're still grinding (locked the whole time, or came back
        // within the grace window), just resume the live clock.
        classifier.onEnterForeground = { [weak self] _ in
            guard let self else { return }
            if self.mode == .grinding {
                self.now = Date()
                self.startTicker()
            }
        }
    }
}
