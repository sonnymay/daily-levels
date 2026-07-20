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
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var activeStart: Date?            // start of current grinding stretch
    /// Focused seconds already banked in the *current logical session* from earlier stretches
    /// (before the latest resume). Drives the "Current session" clock so it survives pause/resume.
    /// Pure display state — daily totals come from persisted sessions, never from this.
    @ObservationIgnored private var sessionAccumulatedSeconds: Int = 0
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let classifier = LockClassifier()
    @ObservationIgnored private var checkpointDay: Date?
    @ObservationIgnored private var checkpointLevel = 0
    @ObservationIgnored static let activeStartKey = "engine.activeStart"
    @ObservationIgnored static let activeWasLockedKey = "engine.activeWasLocked"

    // MARK: Init
    init(context: ModelContext,
         calendar: Calendar = .current,
         defaults: UserDefaults = .standard) {
        self.context = context
        self.calendar = calendar
        self.defaults = defaults
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
        let pausedAt = Date()
        if let s = activeStart {
            sessionAccumulatedSeconds += max(0, Int(pausedAt.timeIntervalSince(s)))  // bank the live stretch
        }
        endActiveSession(at: pausedAt)
        mode = .paused
        classifier.isActive = false
        stopTicker()
        now = pausedAt
    }

    /// Shared start/resume mechanics: open a new grinding stretch and start the clock.
    private func beginStretch() {
        let t = Date()
        activeStart = t
        now = t
        mode = .grinding
        classifier.isActive = true
        checkpointDay = calendar.startOfDay(for: t)
        checkpointLevel = level
        Self.saveActiveMarker(start: t, locked: false, defaults: defaults)
        startTicker()
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
        let live: Int
        if mode == .grinding, let activeStart {
            live = max(0, Int(now.timeIntervalSince(activeStart)))
        } else {
            live = 0
        }
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

    /// Complete five-minute blocks across all focus time (SPEC §2 "Hero lifetime level").
    /// Partial blocks carry across midnight, so earned journey progress is never discarded.
    var lifetimeLevels: Int {
        let totalSeconds = secondsByDayIncludingLive().values.reduce(0, +)
        return LevelMath.earnedLevels(forFocusSeconds: totalSeconds)
    }

    /// Cumulative "journey" level for the Hero Collection — `lifetimeLevels` mapped onto
    /// the 0...maxLevel class ladder. Unlike the daily level it never resets at midnight, so
    /// the collectible hero climbs steadily over days/weeks: that is what makes the Pro
    /// classes (Knight → Mythic) something every user *approaches* and can *see coming*.
    /// Views derive the class + "X of 10" count from this via `KnightClass.forLevel` /
    /// `KnightClass.reachedCount` (reading it once per render, not per hero).
    var journeyLevel: Int { min(LevelMath.maxLevel, lifetimeLevels) }

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
            Self.clearActiveMarker(defaults: defaults)
        }
        guard let start = activeStart else { return }
        persistSession(start: start, end: end)
        try? context.save()
        reloadSessions()
    }

    private func persistSession(start: Date, end: Date) {
        for seg in DateUtils.splitAtMidnights(start: start, end: end, calendar: calendar) {
            let seconds = Int(seg.end.timeIntervalSince(seg.start))
            guard seconds > 0 else { continue }
            context.insert(FocusSession(startAt: seg.start, endAt: seg.end, durationSeconds: seconds))
        }
    }

    private func reloadSessions() {
        let all = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        let segments = all.map { FocusSegment(startAt: $0.startAt, durationSeconds: $0.durationSeconds) }
        completedSecondsByDay = FocusLedger.secondsByDay(segments: segments, calendar: calendar)
    }

    /// A foreground crash keeps only prior checkpoints. If iOS terminated the app while
    /// the phone was confirmed locked, recover that locked stretch generously, capped at
    /// one full daily climb. This favors the user's earned progress over anti-cheat rules.
    private func recoverFromColdLaunch() {
        if let interval = Self.coldLaunchRecoveryInterval(defaults: defaults) {
            persistSession(start: interval.start, end: interval.end)
            try? context.save()
            reloadSessions()
        }
        Self.discardUnprovenActiveStart(defaults: defaults)
    }

    static func discardUnprovenActiveStart(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: activeStartKey)
        defaults.removeObject(forKey: activeWasLockedKey)
    }

    static func coldLaunchRecoveryInterval(defaults: UserDefaults = .standard,
                                           now: Date = Date()) -> DateInterval? {
        guard defaults.bool(forKey: activeWasLockedKey),
              let start = defaults.object(forKey: activeStartKey) as? Date,
              start < now else { return nil }
        let maximum = TimeInterval(LevelMath.maxLevel * LevelMath.secondsPerLevel)
        return DateInterval(start: start, end: min(now, start.addingTimeInterval(maximum)))
    }

    private static func saveActiveMarker(start: Date, locked: Bool,
                                         defaults: UserDefaults = .standard) {
        defaults.set(start, forKey: activeStartKey)
        defaults.set(locked, forKey: activeWasLockedKey)
    }

    private static func clearActiveMarker(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: activeStartKey)
        defaults.removeObject(forKey: activeWasLockedKey)
    }

    /// Bank the current stretch without ending the user's logical focus session.
    private func checkpointActiveSession(at end: Date, locked: Bool) {
        guard mode == .grinding, let start = activeStart else { return }
        now = end
        if end > start {
            sessionAccumulatedSeconds += Int(end.timeIntervalSince(start))
            endActiveSession(at: end)
        }
        activeStart = end
        checkpointDay = calendar.startOfDay(for: end)
        checkpointLevel = level
        Self.saveActiveMarker(start: end, locked: locked, defaults: defaults)
    }

    /// A confirmed lock is earned focus. Persist that completed locked stretch as soon as
    /// the app returns, then begin a fresh foreground checkpoint at the same instant.
    func continueGrindingAfterLock(at returnedAt: Date) {
        guard mode == .grinding else { return }
        checkpointActiveSession(at: returnedAt, locked: false)
        startTicker()
    }

    /// An app switch pauses at the background boundary, but the screen should render using
    /// the current foreground day when the decision is made (especially across midnight).
    func pauseAfterAppSwitch(backgroundedAt: Date, observedAt: Date) {
        guard mode == .grinding else { return }
        if let start = activeStart {
            sessionAccumulatedSeconds += max(0, Int(backgroundedAt.timeIntervalSince(start)))
        }
        endActiveSession(at: backgroundedAt)
        mode = .paused
        classifier.isActive = false
        stopTicker()
        now = observedAt
    }

    // MARK: Ticker
    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick(at: Date()) }
        }
    }

    private func tick(at date: Date) {
        now = date
        guard mode == .grinding else { return }
        let day = calendar.startOfDay(for: date)
        if checkpointDay != day || level > checkpointLevel {
            checkpointActiveSession(at: date, locked: false)
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
            UserDefaults.standard.set(true, forKey: "knightPaywallShown")
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
        checkpointDay = calendar.startOfDay(for: now)
        checkpointLevel = level
        startTicker()
    }
#endif

    // MARK: Lock classifier wiring (SPEC §6)
    private func wireClassifier() {
        // Bank everything earned before suspension, then mark the remaining stretch as
        // confirmed-locked so a system termination can recover it on next launch.
        classifier.onLockDetected = { [weak self] in
            guard let self, self.mode == .grinding else { return }
            self.checkpointActiveSession(at: Date(), locked: true)
        }

        // Confirmed app switch → sleep. End the session at the moment of backgrounding
        // so the time spent in the other app never counts.
        classifier.onAppSwitchDetected = { [weak self] backgroundedAt in
            self?.pauseAfterAppSwitch(backgroundedAt: backgroundedAt, observedAt: Date())
        }

        // Returning after a confirmed lock keeps grinding. App switches are paused first,
        // including quick returns that happen before the classifier's grace timer expires.
        classifier.onEnterForeground = { [weak self] wasLocked in
            guard let self, wasLocked else { return }
            self.continueGrindingAfterLock(at: Date())
        }
    }
}
