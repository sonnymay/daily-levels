//
//  FocusEngine.swift
//  Daily Levels
//
//  The data layer + clock (SPEC §5). Owns the SwiftData context, the current
//  grinding/sleeping state, the 1-second UI ticker, and the lock classifier.
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

    enum Mode { case idle, grinding, sleeping }

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
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let classifier = LockClassifier()
    @ObservationIgnored private let activeStartKey = "engine.activeStart"

    // MARK: Init
    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
        reloadSessions()
        recoverFromColdLaunch()
        wireClassifier()
    }

    // MARK: Public actions (the one Start/Pause button)
    func toggle() { isGrinding ? pause() : start() }

    func start() {
        guard mode != .grinding else { return }
        let t = Date()
        activeStart = t
        now = t
        mode = .grinding
        classifier.isActive = true
        UserDefaults.standard.set(t, forKey: activeStartKey)   // crash marker (SPEC §5 edge 5)
        startTicker()
    }

    func pause() {
        endActiveSession(at: Date())
        mode = .sleeping
        classifier.isActive = false
        stopTicker()
        now = Date()
    }

    // MARK: Derived display values
    var isGrinding: Bool { mode == .grinding }

    /// Today's grinding seconds = completed-today + live portion of the active session
    /// that falls after today's midnight (so a session crossing midnight only credits today).
    var todaySeconds: Int {
        secondsByDayIncludingLive()[startOfToday] ?? 0
    }
    var todayMinutes: Int { todaySeconds / 60 }
    var level: Int { LevelMath.level(forFocusMinutes: todayMinutes) }
    var knightClass: KnightClass { KnightClass.forLevel(level) }

    /// Seconds of the current grinding stretch (the "Current session mm:ss" line).
    var currentSessionSeconds: Int {
        guard mode == .grinding, let s = activeStart else { return 0 }
        return max(0, Int(now.timeIntervalSince(s)))
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
            UserDefaults.standard.removeObject(forKey: activeStartKey)
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
        var dict: [Date: Int] = [:]
        for s in all {
            dict[calendar.startOfDay(for: s.startAt), default: 0] += s.durationSeconds
        }
        completedSecondsByDay = dict
    }

    /// SPEC §5 edge 5: if the app was killed mid-session we can't *prove* the user was
    /// grinding, so we conservatively discard the leftover marker and count zero.
    private func recoverFromColdLaunch() {
        if UserDefaults.standard.object(forKey: activeStartKey) != nil {
            UserDefaults.standard.removeObject(forKey: activeStartKey)
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
        // `-todayMinutes N` overrides today's seeded focus time (drives class for screenshots).
        var todayMinutes = 20
        if let i = args.firstIndex(of: "-todayMinutes"), i + 1 < args.count, let n = Int(args[i + 1]) {
            todayMinutes = n
        }
        if args.contains("-seedDemoData") { seedDemoData(todayMinutes: todayMinutes) }
        if args.contains("-autoStart") { debugStartGrinding(secondsAgo: 150) }
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
            self.endActiveSession(at: backgroundedAt)
            self.mode = .sleeping
            self.classifier.isActive = false
            self.stopTicker()
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
