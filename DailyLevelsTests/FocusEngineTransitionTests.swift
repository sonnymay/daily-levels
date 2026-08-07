//
//  FocusEngineTransitionTests.swift
//  DailyLevelsTests
//
//  Integration coverage for trust-sensitive engine transitions using isolated
//  SwiftData and UserDefaults stores.
//

import SwiftData
import XCTest
@testable import DailyLevels

@MainActor
final class FocusEngineTransitionTests: XCTestCase {
    private final class TestClock {
        var now: Date

        init(now: Date) {
            self.now = now
        }

        func advance(by seconds: TimeInterval) {
            now = now.addingTimeInterval(seconds)
        }
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func makeEngine() throws -> (FocusEngine, ModelContainer, UserDefaults, String) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: configuration)
        let suiteName = "FocusEngineTransitionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let engine = FocusEngine(context: container.mainContext,
                                 calendar: calendar,
                                 defaults: defaults)
        return (engine, container, defaults, suiteName)
    }

    private func makeClockedEngine(at date: Date) throws -> (
        FocusEngine, ModelContainer, UserDefaults, String, TestClock
    ) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: configuration)
        let suiteName = "FocusEngineTransitionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let clock = TestClock(now: date)
        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: date,
            dateProvider: { clock.now }
        )
        return (engine, container, defaults, suiteName, clock)
    }

    func testInvalidLaunchDateUsesFiniteInjectedClock() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: configuration)
        let suiteName = "FocusEngineTransitionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let fallback = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 7, hour: 8
        )))

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: Date(timeIntervalSinceReferenceDate: .nan),
            dateProvider: { fallback }
        )

        XCTAssertEqual(engine.now, fallback)
        XCTAssertTrue(engine.now.timeIntervalSinceReferenceDate.isFinite)
        XCTAssertEqual(engine.weekHistory.last?.date, calendar.startOfDay(for: fallback))
    }

    func testStartAndResumeIgnoreInvalidInjectedClocks() throws {
        let launch = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 7, hour: 9
        )))
        let (engine, container, defaults, suiteName, clock) = try makeClockedEngine(at: launch)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        clock.now = Date(timeIntervalSinceReferenceDate: .infinity)

        engine.start()

        XCTAssertEqual(engine.now, launch)
        XCTAssertEqual(
            ActiveFocusMarkerStore.load(defaults: defaults),
            ActiveFocusMarker(startAt: launch, isLocked: false)
        )
        engine.pause()
        clock.now = Date(timeIntervalSinceReferenceDate: .nan)

        engine.resume()

        XCTAssertEqual(engine.now, launch)
        XCTAssertEqual(
            ActiveFocusMarkerStore.load(defaults: defaults),
            ActiveFocusMarker(startAt: launch, isLocked: false)
        )
        XCTAssertTrue(engine.isGrinding)
        _ = container
    }

    func testPausePersistsExactTimeFromInjectedClock() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 31, hour: 10
        )))
        let (engine, container, defaults, suiteName, clock) = try makeClockedEngine(at: start)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        clock.advance(by: 2 * 60 + 5)

        engine.pause()

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.startAt, start)
        XCTAssertEqual(sessions.first?.endAt, clock.now)
        XCTAssertEqual(sessions.first?.durationSeconds, 2 * 60 + 5)
        XCTAssertEqual(engine.currentSessionSeconds, 2 * 60 + 5)
        XCTAssertEqual(engine.todaySeconds, 2 * 60 + 5)
        XCTAssertTrue(engine.isPaused)
        XCTAssertNil(ActiveFocusMarkerStore.load(defaults: defaults))
        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)
    }

    func testPausePreservesLastFiniteDisplayWhenClockIsInvalid() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 7, hour: 10
        )))
        let (engine, container, defaults, suiteName, clock) = try makeClockedEngine(at: start)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let displayedAt = start.addingTimeInterval(90)
        engine.refreshCurrentEnvironment(at: displayedAt, calendar: calendar)
        clock.now = Date(timeIntervalSinceReferenceDate: .infinity)

        engine.pause()

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.startAt, start)
        XCTAssertEqual(sessions.first?.endAt, displayedAt)
        XCTAssertEqual(sessions.first?.durationSeconds, 90)
        XCTAssertEqual(engine.currentSessionSeconds, 90)
        XCTAssertEqual(engine.now, displayedAt)
        XCTAssertTrue(engine.isPaused)
    }

    func testResumeExcludesPausedTimeFromInjectedClock() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 31, hour: 10
        )))
        let (engine, container, defaults, suiteName, clock) = try makeClockedEngine(at: start)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        clock.advance(by: 2 * 60)
        engine.pause()

        clock.advance(by: 30 * 60)
        engine.resume()
        clock.advance(by: 3 * 60)
        engine.pause()

        let descriptor = FetchDescriptor<FocusSession>(sortBy: [SortDescriptor(\.startAt)])
        let sessions = try container.mainContext.fetch(descriptor)
        XCTAssertEqual(sessions.map(\.durationSeconds), [2 * 60, 3 * 60])
        XCTAssertEqual(sessions[1].startAt.timeIntervalSince(sessions[0].endAt), 30 * 60)
        XCTAssertEqual(engine.currentSessionSeconds, 5 * 60)
        XCTAssertEqual(engine.todaySeconds, 5 * 60)
        XCTAssertEqual(engine.level, 1)
        XCTAssertTrue(engine.isPaused)
        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)
    }

    func testCurrentSessionIgnoresOutOfRangeLiveClock() throws {
        let start = Date(timeIntervalSinceReferenceDate: -1_000_000_000)
        let (engine, container, defaults, suiteName, clock) = try makeClockedEngine(at: start)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        engine.refreshCurrentEnvironment(
            at: Date(timeIntervalSinceReferenceDate: TimeInterval(Int.max)),
            calendar: calendar
        )

        XCTAssertEqual(engine.currentSessionSeconds, 0)

        _ = container
        _ = clock
        engine.pause()
    }

    func testCurrentSessionClampsAccumulatedAndLiveOverflow() throws {
        let start = Date(timeIntervalSinceReferenceDate: -3_000)
        let (engine, container, defaults, suiteName, clock) = try makeClockedEngine(at: start)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        clock.advance(by: 2_000)
        engine.pause()
        clock.now = Date(timeIntervalSinceReferenceDate: 0)
        engine.resume()
        engine.refreshCurrentEnvironment(
            at: Date(timeIntervalSinceReferenceDate: TimeInterval(Int.max).nextDown),
            calendar: calendar
        )

        XCTAssertEqual(engine.currentSessionSeconds, Int.max)

        _ = container
        clock.now = Date(timeIntervalSinceReferenceDate: 0)
        engine.pause()
    }

    func testReturningFromLockPersistsEarnedStretchAndStartsFreshMarker() throws {
        let (engine, container, defaults, suiteName) = try makeEngine()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let startedAt = engine.now
        let returnedAt = startedAt.addingTimeInterval(10 * 60)

        engine.continueGrindingAfterLock(at: returnedAt)

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.durationSeconds).reduce(0, +), 10 * 60)
        XCTAssertEqual(engine.completedSecondsByDay[calendar.startOfDay(for: startedAt)], 10 * 60)
        XCTAssertEqual(engine.currentSessionSeconds, 10 * 60)
        XCTAssertEqual(
            ActiveFocusMarkerStore.load(defaults: defaults),
            ActiveFocusMarker(startAt: returnedAt, isLocked: false)
        )
        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)

        engine.pause()
    }

    func testPreparingForBackgroundBanksForegroundFocusWithoutPausing() throws {
        let (engine, container, defaults, suiteName) = try makeEngine()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let startedAt = engine.now
        let backgroundedAt = startedAt.addingTimeInterval(2 * 60)

        engine.prepareForBackground(at: backgroundedAt)

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.durationSeconds).reduce(0, +), 2 * 60)
        XCTAssertTrue(engine.isGrinding)
        XCTAssertEqual(engine.currentSessionSeconds, 2 * 60)
        XCTAssertEqual(
            ActiveFocusMarkerStore.load(defaults: defaults),
            ActiveFocusMarker(startAt: backgroundedAt, isLocked: false)
        )
        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)

        engine.pause()
    }

    func testBackgroundCheckpointUsesLastFiniteBoundaryWhenClockIsInvalid() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 7, hour: 11
        )))
        let (engine, container, defaults, suiteName, clock) = try makeClockedEngine(at: start)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let displayedAt = start.addingTimeInterval(75)
        engine.refreshCurrentEnvironment(at: displayedAt, calendar: calendar)

        engine.prepareForBackground(
            at: Date(timeIntervalSinceReferenceDate: .infinity)
        )

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.durationSeconds), [75])
        XCTAssertEqual(engine.currentSessionSeconds, 75)
        XCTAssertEqual(engine.now, displayedAt)
        XCTAssertTrue(engine.isGrinding)
        XCTAssertEqual(
            ActiveFocusMarkerStore.load(defaults: defaults),
            ActiveFocusMarker(startAt: displayedAt, isLocked: false)
        )

        clock.now = displayedAt
        engine.pause()
    }

    func testAppSwitchAfterBackgroundCheckpointDoesNotDoubleCount() throws {
        let (engine, container, defaults, suiteName) = try makeEngine()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let startedAt = engine.now
        let backgroundedAt = startedAt.addingTimeInterval(2 * 60)
        let classifiedAt = backgroundedAt.addingTimeInterval(30)
        engine.prepareForBackground(at: backgroundedAt)

        engine.pauseAfterAppSwitch(backgroundedAt: backgroundedAt, observedAt: classifiedAt)

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.durationSeconds).reduce(0, +), 2 * 60)
        XCTAssertTrue(engine.isPaused)
        XCTAssertEqual(engine.currentSessionSeconds, 2 * 60)
        XCTAssertNil(ActiveFocusMarkerStore.load(defaults: defaults))
        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)
    }

    func testAppSwitchPausesAtBackgroundBoundaryAndRefreshesTheCurrentDay() throws {
        let (engine, container, defaults, suiteName) = try makeEngine()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let startedAt = engine.now
        let backgroundedAt = startedAt.addingTimeInterval(2 * 60)
        let returnedAt = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: startedAt))

        engine.pauseAfterAppSwitch(backgroundedAt: backgroundedAt, observedAt: returnedAt)

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.durationSeconds).reduce(0, +), 2 * 60)
        XCTAssertTrue(engine.isPaused)
        XCTAssertEqual(engine.currentSessionSeconds, 2 * 60)
        XCTAssertEqual(engine.now, returnedAt)
        XCTAssertEqual(engine.weekHistory.last?.date, calendar.startOfDay(for: returnedAt))
        XCTAssertEqual(engine.todaySeconds, 0)
        XCTAssertNil(ActiveFocusMarkerStore.load(defaults: defaults))
    }

    func testAppSwitchPreservesFiniteFocusWhenCallbackClocksAreInvalid() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 7, hour: 12
        )))
        let (engine, container, defaults, suiteName, clock) = try makeClockedEngine(at: start)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let displayedAt = start.addingTimeInterval(60)
        engine.refreshCurrentEnvironment(at: displayedAt, calendar: calendar)

        engine.pauseAfterAppSwitch(
            backgroundedAt: Date(timeIntervalSinceReferenceDate: .infinity),
            observedAt: Date(timeIntervalSinceReferenceDate: .nan)
        )

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.durationSeconds), [60])
        XCTAssertEqual(engine.currentSessionSeconds, 60)
        XCTAssertEqual(engine.now, displayedAt)
        XCTAssertTrue(engine.isPaused)
        XCTAssertNil(ActiveFocusMarkerStore.load(defaults: defaults))
        _ = clock
    }

    func testJourneyCarriesPartialFocusAcrossLocalDays() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: configuration)
        let suiteName = "FocusEngineTransitionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let firstStart = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 18, hour: 20
        )))
        let secondStart = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 19, hour: 9
        )))
        container.mainContext.insert(FocusSession(
            startAt: firstStart,
            endAt: firstStart.addingTimeInterval(4 * 60),
            durationSeconds: 4 * 60
        ))
        container.mainContext.insert(FocusSession(
            startAt: secondStart,
            endAt: secondStart.addingTimeInterval(60),
            durationSeconds: 60
        ))
        try container.mainContext.save()

        let engine = FocusEngine(context: container.mainContext,
                                 calendar: calendar,
                                 defaults: defaults)

        XCTAssertEqual(engine.lifetimeLevels, 1)
        XCTAssertEqual(engine.journeyLevel, 1)
    }

    func testReloadCountsOverlappingStoredSessionsOnlyOnce() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: configuration)
        let suiteName = "FocusEngineTransitionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 3, hour: 10
        )))
        container.mainContext.insert(FocusSession(
            startAt: start,
            endAt: start.addingTimeInterval(10 * 60),
            durationSeconds: 10 * 60
        ))
        container.mainContext.insert(FocusSession(
            startAt: start.addingTimeInterval(5 * 60),
            endAt: start.addingTimeInterval(15 * 60),
            durationSeconds: 10 * 60
        ))
        try container.mainContext.save()

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: start.addingTimeInterval(60 * 60)
        )

        XCTAssertEqual(engine.todaySeconds, 15 * 60)
        XCTAssertEqual(engine.level, 3)
        XCTAssertEqual(engine.lifetimeLevels, 3)
        XCTAssertEqual(engine.personalBest?.focusMinutes, 15)
    }

    func testReloadDerivesStoredDurationFromTimestamps() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: configuration)
        let suiteName = "FocusEngineTransitionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 1, hour: 10
        )))
        let end = start.addingTimeInterval(5 * 60)
        container.mainContext.insert(FocusSession(
            startAt: start,
            endAt: end,
            durationSeconds: 8 * 60 * 60
        ))
        try container.mainContext.save()

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: end
        )

        XCTAssertEqual(engine.todaySeconds, 5 * 60)
        XCTAssertEqual(engine.level, 1)
        XCTAssertEqual(engine.lifetimeLevels, 1)
        XCTAssertEqual(engine.personalBest?.focusMinutes, 5)
    }

    func testReloadIgnoresInvalidIntervalsWithoutHidingValidFocus() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: configuration)
        let suiteName = "FocusEngineTransitionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 1, hour: 9
        )))
        container.mainContext.insert(FocusSession(
            startAt: start,
            endAt: start.addingTimeInterval(60),
            durationSeconds: 60
        ))
        container.mainContext.insert(FocusSession(
            startAt: start.addingTimeInterval(60 * 60),
            endAt: start.addingTimeInterval(59 * 60),
            durationSeconds: 60 * 60
        ))
        container.mainContext.insert(FocusSession(
            startAt: start.addingTimeInterval(2 * 60 * 60),
            endAt: start.addingTimeInterval(2 * 60 * 60 + 0.5),
            durationSeconds: 60 * 60
        ))
        try container.mainContext.save()

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: start.addingTimeInterval(3 * 60 * 60)
        )

        XCTAssertEqual(engine.completedSecondsByDay.values.reduce(0, +), 60)
        XCTAssertEqual(engine.todaySeconds, 60)
        XCTAssertEqual(engine.lifetimeLevels, 0)
        XCTAssertEqual(engine.personalBest?.focusMinutes, 1)
    }

    func testReloadIgnoresOutOfRangeIntervalWithoutHidingValidFocus() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: configuration)
        let suiteName = "FocusEngineTransitionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 5, hour: 9
        )))
        container.mainContext.insert(FocusSession(
            startAt: start,
            endAt: start.addingTimeInterval(60),
            durationSeconds: 60
        ))
        container.mainContext.insert(FocusSession(
            startAt: Date(timeIntervalSinceReferenceDate: 0),
            endAt: Date(timeIntervalSinceReferenceDate: TimeInterval(Int.max)),
            durationSeconds: 1
        ))
        try container.mainContext.save()

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: start.addingTimeInterval(5 * 60)
        )

        XCTAssertEqual(engine.todaySeconds, 60)
        XCTAssertEqual(engine.completedSecondsByDay.values.reduce(0, +), 60)
        XCTAssertEqual(engine.personalBest?.focusMinutes, 1)
    }

    func testEnvironmentRefreshMovesAnIdleEngineToTheCurrentDay() throws {
        let (engine, container, defaults, suiteName) = try makeEngine()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let nextDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: engine.now))

        engine.refreshCurrentEnvironment(at: nextDay, calendar: calendar)

        XCTAssertEqual(engine.now, nextDay)
        XCTAssertEqual(engine.weekHistory.last?.date, calendar.startOfDay(for: nextDay))
        XCTAssertEqual(engine.recentDays.first?.date, calendar.startOfDay(for: nextDay))
        _ = container
    }

    func testEnvironmentRefreshIgnoresInvalidDateAndKeepsCalendarUpdate() throws {
        let launch = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 7, hour: 23
        )))
        let (engine, container, defaults, suiteName, _) = try makeClockedEngine(at: launch)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        engine.refreshCurrentEnvironment(
            at: Date(timeIntervalSinceReferenceDate: .nan),
            calendar: tokyo
        )

        XCTAssertEqual(engine.now, launch)
        XCTAssertEqual(engine.weekHistory.last?.date, tokyo.startOfDay(for: launch))
        _ = container
    }

    func testEnvironmentRefreshReattributesHistoryAfterTimezoneChange() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FocusSession.self, configurations: configuration)
        let suiteName = "FocusEngineTransitionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 19, hour: 23, minute: 30
        )))
        let end = start.addingTimeInterval(60 * 60)
        container.mainContext.insert(FocusSession(
            startAt: start,
            endAt: end,
            durationSeconds: 60 * 60
        ))
        try container.mainContext.save()
        let engine = FocusEngine(context: container.mainContext,
                                 calendar: calendar,
                                 defaults: defaults)
        XCTAssertEqual(engine.completedSecondsByDay.count, 2)
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        engine.refreshCurrentEnvironment(at: end, calendar: tokyo)

        XCTAssertEqual(engine.completedSecondsByDay.count, 1)
        XCTAssertEqual(engine.completedSecondsByDay.values.first, 60 * 60)
    }

    func testSignificantForwardClockChangeDoesNotInventForegroundFocus() throws {
        let (engine, container, defaults, suiteName) = try makeEngine()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let clockJump = engine.now.addingTimeInterval(2 * 60 * 60)

        engine.handleSignificantTimeChange(at: clockJump, calendar: calendar)

        XCTAssertLessThan(engine.currentSessionSeconds, 2)
        XCTAssertLessThan(engine.todaySeconds, 2)
        XCTAssertEqual(
            ActiveFocusMarkerStore.load(defaults: defaults),
            ActiveFocusMarker(startAt: clockJump, isLocked: false)
        )

        let beforeResume = engine.currentSessionSeconds
        engine.continueGrindingAfterLock(at: clockJump.addingTimeInterval(5 * 60))
        XCTAssertEqual(engine.currentSessionSeconds, beforeResume + 5 * 60)
        _ = container
        engine.pause()
    }

    func testInvalidSignificantClockChangePreservesDisplayedFocus() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 7, hour: 13
        )))
        let (engine, container, defaults, suiteName, _) = try makeClockedEngine(at: start)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let displayedAt = start.addingTimeInterval(2 * 60)
        engine.refreshCurrentEnvironment(at: displayedAt, calendar: calendar)

        engine.handleSignificantTimeChange(
            at: Date(timeIntervalSinceReferenceDate: .nan),
            calendar: calendar
        )

        XCTAssertEqual(engine.currentSessionSeconds, 2 * 60)
        XCTAssertEqual(engine.now, displayedAt)
        XCTAssertEqual(
            ActiveFocusMarkerStore.load(defaults: defaults),
            ActiveFocusMarker(startAt: displayedAt, isLocked: false)
        )
        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.durationSeconds), [2 * 60])

        engine.continueGrindingAfterLock(at: displayedAt.addingTimeInterval(3 * 60))

        XCTAssertEqual(engine.currentSessionSeconds, 5 * 60)
    }

    func testSignificantBackwardClockChangeKeepsForegroundFocusMoving() throws {
        let (engine, container, defaults, suiteName) = try makeEngine()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let clockCorrection = engine.now.addingTimeInterval(-60 * 60)

        engine.handleSignificantTimeChange(at: clockCorrection, calendar: calendar)

        let earnedBeforeCorrection = engine.currentSessionSeconds
        engine.continueGrindingAfterLock(at: clockCorrection.addingTimeInterval(3 * 60))

        XCTAssertEqual(engine.currentSessionSeconds, earnedBeforeCorrection + 3 * 60)
        XCTAssertEqual(
            ActiveFocusMarkerStore.load(defaults: defaults),
            ActiveFocusMarker(
                startAt: clockCorrection.addingTimeInterval(3 * 60),
                isLocked: false
            )
        )
        _ = container
        engine.pause()
    }

    func testSignificantClockChangePreservesConfirmedLockedFocus() throws {
        let (engine, container, defaults, suiteName) = try makeEngine()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        engine.start()
        let startedAt = engine.now
        let backgroundedAt = startedAt.addingTimeInterval(60)
        engine.prepareForBackground(at: backgroundedAt)
        ActiveFocusMarkerStore.save(
            ActiveFocusMarker(startAt: backgroundedAt, isLocked: true),
            defaults: defaults
        )
        let returnedAt = startedAt.addingTimeInterval(60 * 60)

        engine.handleSignificantTimeChange(at: returnedAt, calendar: calendar)
        engine.continueGrindingAfterLock(at: returnedAt)

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.durationSeconds).reduce(0, +), 60 * 60)
        XCTAssertEqual(engine.currentSessionSeconds, 60 * 60)
        engine.pause()
    }
}
