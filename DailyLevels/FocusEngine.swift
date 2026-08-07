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
    private(set) var now: Date
    /// Completed grinding seconds per local day, cached from SwiftData.
    /// Recomputed on save/launch, not on every tick.
    private(set) var completedSecondsByDay: [Date: Int] = [:]

    // MARK: Non-observed internals
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private var calendar: Calendar
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let dateProvider: () -> Date
    @ObservationIgnored private var activeStart: Date?            // start of current grinding stretch
    /// Focused seconds already banked in the *current logical session* from earlier stretches
    /// (before the latest resume). Drives the "Current session" clock so it survives pause/resume.
    /// Pure display state — daily totals come from persisted sessions, never from this.
    @ObservationIgnored private var sessionAccumulatedSeconds: Int = 0
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var timeObservers: [NSObjectProtocol] = []
    @ObservationIgnored private let classifier = LockClassifier()
    @ObservationIgnored private var checkpointDay: Date?
    @ObservationIgnored private var checkpointLevel = 0
    @ObservationIgnored static let activeStartKey = ActiveFocusMarkerStore.legacyStartKey
    @ObservationIgnored static let activeWasLockedKey = ActiveFocusMarkerStore.legacyLockedKey

    // MARK: Init
    init(context: ModelContext,
         calendar: Calendar = .autoupdatingCurrent,
         defaults: UserDefaults = .standard,
         launchDate: Date = Date(),
         dateProvider: @escaping () -> Date = Date.init) {
        self.context = context
        self.calendar = calendar
        self.defaults = defaults
        self.dateProvider = dateProvider
        if launchDate.timeIntervalSinceReferenceDate.isFinite {
            now = launchDate
        } else {
            let fallback = dateProvider()
            now = fallback.timeIntervalSinceReferenceDate.isFinite ? fallback : Date()
        }
        replayPendingJournal()
        reloadSessions()
        recoverFromColdLaunch(at: now)
        wireClassifier()
        wireTimeObservers()
    }

    deinit {
        ticker?.invalidate()
        let center = NotificationCenter.default
        timeObservers.forEach(center.removeObserver)
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
        let requestedAt = dateProvider()
        let pausedAt: Date
        if let start = activeStart {
            let boundary = safeSessionBoundary(requestedAt, from: start)
            pausedAt = boundary.date
            sessionAccumulatedSeconds = FocusSeconds.adding(
                sessionAccumulatedSeconds,
                boundary.seconds
            )
        } else {
            pausedAt = requestedAt.timeIntervalSinceReferenceDate.isFinite ? requestedAt : now
        }
        endActiveSession(at: pausedAt)
        mode = .paused
        classifier.isActive = false
        stopTicker()
        now = pausedAt
    }

    /// Shared start/resume mechanics: open a new grinding stretch and start the clock.
    private func beginStretch() {
        let requested = dateProvider()
        let t = requested.timeIntervalSinceReferenceDate.isFinite ? requested : now
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
            live = DateUtils.nonnegativeWholeSeconds(start: activeStart, end: now) ?? 0
        } else {
            live = 0
        }
        return FocusSeconds.adding(sessionAccumulatedSeconds, live)
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
        let totalSeconds = FocusSeconds.sum(secondsByDayIncludingLive().values)
        return LevelMath.earnedLevels(forFocusSeconds: totalSeconds)
    }

    /// Cumulative "journey" level for the Hero Collection — `lifetimeLevels` mapped onto
    /// the 0...maxLevel class ladder. Unlike the daily level it never resets at midnight, so
    /// the collectible hero climbs steadily over days/weeks: that is what makes the Pro
    /// classes (Knight → Mythic) something every user *approaches* and can *see coming*.
    /// Views derive the class + "X of 10" count from this via `KnightClass.forLevel` /
    /// `KnightClass.reachedCount` (reading it once per render, not per hero).
    var journeyLevel: Int { min(LevelMath.maxLevel, lifetimeLevels) }

    /// Every history-card projection derived from one completed-plus-live ledger.
    var historySnapshot: FocusHistorySnapshot {
        HistoryMath.snapshot(
            secondsByDay: secondsByDayIncludingLive(),
            referenceDate: now,
            calendar: calendar
        )
    }

    /// Last 7 days, oldest → newest (rightmost = today) for the bar chart (SPEC §4).
    var weekHistory: [DaySummary] { historySnapshot.weekHistory }

    /// Recent days for the list under the chart: today plus any past day with focus time,
    /// newest first (SPEC §4: "Date · Level N · X min focus time").
    var recentDays: [DaySummary] { historySnapshot.recentDays }

    /// A single kind highlight, never a streak: the strongest focused day on this device.
    var personalBest: DaySummary? { historySnapshot.personalBest }

    // MARK: Internals
    private var startOfToday: Date { calendar.startOfDay(for: now) }

    /// Prefer a requested lifecycle timestamp, then the last finite displayed timestamp.
    /// Falling back to the stretch start preserves proven focus without inventing time.
    private func safeSessionBoundary(_ requested: Date,
                                     from start: Date) -> (date: Date, seconds: Int) {
        if let seconds = DateUtils.nonnegativeWholeSeconds(start: start, end: requested) {
            return (requested, seconds)
        }
        if let seconds = DateUtils.nonnegativeWholeSeconds(start: start, end: now) {
            return (now, seconds)
        }
        return (start, 0)
    }

    /// completedSecondsByDay + the active session's live seconds, attributed to the
    /// correct day(s) at the midnight boundary.
    private func secondsByDayIncludingLive() -> [Date: Int] {
        var map = completedSecondsByDay
        if mode == .grinding, let s = activeStart {
            for seg in DateUtils.splitAtMidnights(start: s, end: now, calendar: calendar) {
                let day = calendar.startOfDay(for: seg.start)
                guard let seconds = DateUtils.nonnegativeWholeSeconds(
                    start: seg.start,
                    end: seg.end
                ) else { continue }
                map[day] = FocusSeconds.adding(map[day, default: 0], seconds)
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
        saveSessions()
        reloadSessions()
    }

    private func persistSession(start: Date, end: Date) {
        let records = FocusJournal.records(start: start, end: end, calendar: calendar)
        FocusJournal.append(records, defaults: defaults)
        for record in records {
            context.insert(FocusSession(
                id: record.id,
                startAt: record.startAt,
                endAt: record.endAt,
                durationSeconds: record.durationSeconds
            ))
        }
    }

    /// Replaying a confirmed locked interval must be idempotent. If the app was terminated
    /// after SwiftData saved but before the recovery marker cleared, the next launch sees the
    /// first saved slice beginning at that marker and skips the replay. A ModelContext save is
    /// atomic, so that first slice proves the complete recovered interval was committed.
    private func persistRecoveredSession(start: Date, end: Date) throws {
        let existing = try context.fetch(FetchDescriptor<FocusSession>())
        guard !existing.contains(where: { $0.startAt == start }) else { return }
        persistSession(start: start, end: end)
    }

    /// Reapply any earned slices left behind by a failed save. Stable record IDs make replay
    /// safe when SwiftData committed successfully but the process ended before journal cleanup.
    private func replayPendingJournal() {
        let pending = FocusJournal.load(defaults: defaults)
        guard !pending.isEmpty,
              let sessions = try? context.fetch(FetchDescriptor<FocusSession>()) else { return }
        var existingIDs = Set(sessions.map(\.id))
        for record in pending where existingIDs.insert(record.id).inserted {
            context.insert(FocusSession(
                id: record.id,
                startAt: record.startAt,
                endAt: record.endAt,
                durationSeconds: record.durationSeconds
            ))
        }
        saveSessions()
    }

    /// A successful context save commits every pending insert atomically. Only then is it safe
    /// to discard the durable journal; a failure leaves it available for the next launch.
    @discardableResult
    private func saveSessions() -> Bool {
        do {
            try context.save()
            FocusJournal.clear(defaults: defaults)
            return true
        } catch {
            return false
        }
    }

    private func reloadSessions() {
        let all = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        let segments = all.compactMap { session -> FocusSegment? in
            guard let seconds = DateUtils.wholeSeconds(
                start: session.startAt,
                end: session.endAt
            ) else { return nil }
            return FocusSegment(startAt: session.startAt, durationSeconds: seconds)
        }
        completedSecondsByDay = FocusLedger.secondsByDay(segments: segments, calendar: calendar)
    }

    /// A foreground crash keeps only prior checkpoints. If iOS terminated the app while
    /// the phone was confirmed locked, recover that locked stretch generously, capped at
    /// one full daily climb. This favors the user's earned progress over anti-cheat rules.
    private func recoverFromColdLaunch(at launchDate: Date) {
        guard let interval = Self.coldLaunchRecoveryInterval(
            defaults: defaults,
            now: launchDate
        ) else {
            Self.discardUnprovenActiveStart(defaults: defaults)
            return
        }

        do {
            try persistRecoveredSession(start: interval.start, end: interval.end)
            guard saveSessions() else {
                reloadSessions()
                return
            }
            reloadSessions()
            Self.discardUnprovenActiveStart(defaults: defaults)
        } catch {
            // Keep the confirmed-lock marker so a later launch can retry without losing time.
            reloadSessions()
        }
    }

    static func discardUnprovenActiveStart(defaults: UserDefaults = .standard) {
        ActiveFocusMarkerStore.clear(defaults: defaults)
    }

    static func coldLaunchRecoveryInterval(defaults: UserDefaults = .standard,
                                           now: Date = Date()) -> DateInterval? {
        guard now.timeIntervalSinceReferenceDate.isFinite,
              let marker = ActiveFocusMarkerStore.load(defaults: defaults),
              marker.isLocked,
              marker.startAt.timeIntervalSinceReferenceDate.isFinite,
              marker.startAt < now else { return nil }
        let maximum = TimeInterval(LevelMath.maxLevel * LevelMath.secondsPerLevel)
        let end = min(now, marker.startAt.addingTimeInterval(maximum))
        guard DateUtils.wholeSeconds(start: marker.startAt, end: end) != nil else { return nil }
        return DateInterval(start: marker.startAt, end: end)
    }

    private static func saveActiveMarker(start: Date, locked: Bool,
                                         defaults: UserDefaults = .standard) {
        ActiveFocusMarkerStore.save(
            ActiveFocusMarker(startAt: start, isLocked: locked),
            defaults: defaults
        )
    }

    private static func clearActiveMarker(defaults: UserDefaults = .standard) {
        ActiveFocusMarkerStore.clear(defaults: defaults)
    }

    /// Bank the current stretch without ending the user's logical focus session.
    private func checkpointActiveSession(at end: Date, locked: Bool) {
        guard mode == .grinding, let start = activeStart else { return }
        let boundary = safeSessionBoundary(end, from: start)
        now = boundary.date
        if boundary.seconds > 0 {
            sessionAccumulatedSeconds = FocusSeconds.adding(
                sessionAccumulatedSeconds,
                boundary.seconds
            )
            endActiveSession(at: boundary.date)
        }
        activeStart = boundary.date
        checkpointDay = calendar.startOfDay(for: boundary.date)
        checkpointLevel = level
        Self.saveActiveMarker(start: boundary.date, locked: locked, defaults: defaults)
    }

    /// A confirmed lock is earned focus. Persist that completed locked stretch as soon as
    /// the app returns, then begin a fresh foreground checkpoint at the same instant.
    func continueGrindingAfterLock(at returnedAt: Date) {
        guard mode == .grinding else { return }
        checkpointActiveSession(at: returnedAt, locked: false)
        startTicker()
    }

    /// Bank all foreground focus as soon as iOS backgrounds the app. Classification can
    /// then decide lock vs. app switch without risking this already-earned stretch.
    func prepareForBackground(at backgroundedAt: Date) {
        guard mode == .grinding else { return }
        checkpointActiveSession(at: backgroundedAt, locked: false)
        stopTicker()
    }

    /// An app switch pauses at the background boundary, but the screen should render using
    /// the current foreground day when the decision is made (especially across midnight).
    func pauseAfterAppSwitch(backgroundedAt: Date, observedAt: Date) {
        guard mode == .grinding else { return }
        let pausedAt: Date
        if let start = activeStart {
            let boundary = safeSessionBoundary(backgroundedAt, from: start)
            pausedAt = boundary.date
            sessionAccumulatedSeconds = FocusSeconds.adding(
                sessionAccumulatedSeconds,
                boundary.seconds
            )
        } else {
            pausedAt = backgroundedAt.timeIntervalSinceReferenceDate.isFinite ? backgroundedAt : now
        }
        endActiveSession(at: pausedAt)
        mode = .paused
        classifier.isActive = false
        stopTicker()
        if DateUtils.nonnegativeWholeSeconds(start: pausedAt, end: observedAt) != nil {
            now = observedAt
        } else {
            now = pausedAt
        }
    }

    /// Refresh cached day attribution whenever iOS reports a meaningful clock change or
    /// the app returns. This keeps idle/paused screens correct across midnight and timezone moves.
    func refreshCurrentEnvironment(at date: Date, calendar: Calendar) {
        self.calendar = calendar
        if date.timeIntervalSinceReferenceDate.isFinite {
            now = date
        }
        reloadSessions()
    }

    /// A manual clock jump must not invent or erase foreground focus. Bank only the
    /// elapsed time already shown by the ticker, then anchor the live stretch to the new
    /// wall clock. Confirmed locked time is left intact because locking is earned focus.
    func handleSignificantTimeChange(at date: Date, calendar: Calendar) {
        let correctedAt = date.timeIntervalSinceReferenceDate.isFinite ? date : now
        guard mode == .grinding,
              ActiveFocusMarkerStore.load(defaults: defaults)?.isLocked != true else {
            refreshCurrentEnvironment(at: correctedAt, calendar: calendar)
            return
        }

        checkpointActiveSession(at: now, locked: false)
        activeStart = correctedAt
        Self.saveActiveMarker(start: correctedAt, locked: false, defaults: defaults)
        refreshCurrentEnvironment(at: correctedAt, calendar: calendar)
        checkpointDay = calendar.startOfDay(for: correctedAt)
        checkpointLevel = level
    }

    // MARK: Ticker
    private func startTicker() {
        stopTicker()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.tick(at: self.dateProvider())
            }
        }
        // Display updates can arrive a fraction late because elapsed focus uses Date math,
        // not tick counts. This lets iOS coalesce wakeups and spend less battery.
        timer.tolerance = 0.1
        ticker = timer
    }

    func tick(at date: Date) {
        guard date.timeIntervalSinceReferenceDate.isFinite else { return }
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
        let date = dateProvider()
        activeStart = date.addingTimeInterval(-secondsAgo)
        now = date
        mode = .grinding
        classifier.isActive = true
        checkpointDay = calendar.startOfDay(for: now)
        checkpointLevel = level
        startTicker()
    }
#endif

    // MARK: Lock classifier wiring (SPEC §6)
    private func wireClassifier() {
        // Bank foreground focus immediately. The classifier can safely wait to distinguish
        // a lock from an app switch without keeping earned time only in memory.
        classifier.onEnterBackground = { [weak self] backgroundedAt in
            self?.prepareForBackground(at: backgroundedAt)
        }

        // Mark the short stretch since backgrounding as confirmed-locked so a system
        // termination can recover all subsequent locked time on the next launch.
        classifier.onLockDetected = { [weak self] in
            guard let self, self.mode == .grinding else { return }
            self.checkpointActiveSession(at: self.dateProvider(), locked: true)
        }

        // Confirmed app switch → sleep. End the session at the moment of backgrounding
        // so the time spent in the other app never counts.
        classifier.onAppSwitchDetected = { [weak self] backgroundedAt in
            guard let self else { return }
            self.pauseAfterAppSwitch(
                backgroundedAt: backgroundedAt,
                observedAt: self.dateProvider()
            )
        }

        // Returning after a confirmed lock keeps grinding. App switches are paused first,
        // including quick returns that happen before the classifier's grace timer expires.
        classifier.onEnterForeground = { [weak self] wasLocked in
            guard let self, wasLocked else { return }
            self.continueGrindingAfterLock(at: self.dateProvider())
        }
    }

    private func wireTimeObservers() {
        let center = NotificationCenter.default
        timeObservers = [
            center.addObserver(forName: UIApplication.didBecomeActiveNotification,
                               object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.refreshCurrentEnvironment(
                        at: self.dateProvider(),
                        calendar: .autoupdatingCurrent
                    )
                }
            },
            center.addObserver(forName: UIApplication.significantTimeChangeNotification,
                               object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.handleSignificantTimeChange(
                        at: self.dateProvider(),
                        calendar: .autoupdatingCurrent
                    )
                }
            }
        ]
    }
}
