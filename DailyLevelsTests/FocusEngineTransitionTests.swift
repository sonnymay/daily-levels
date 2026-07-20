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
        XCTAssertEqual(defaults.object(forKey: FocusEngine.activeStartKey) as? Date, returnedAt)
        XCTAssertFalse(defaults.bool(forKey: FocusEngine.activeWasLockedKey))

        engine.pause()
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
        XCTAssertNil(defaults.object(forKey: FocusEngine.activeStartKey))
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
}
