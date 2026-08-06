//
//  TrustAuditTests.swift
//  DailyLevelsTests
//
//  High-signal tests for the promises users must be able to trust:
//  local-day boundaries, DST, timezone attribution, cold-launch recovery, and
//  persisted focus history. No network, no UI, no store.
//

import SwiftData
import XCTest
@testable import DailyLevels

@MainActor
final class TrustAuditTests: XCTestCase {

    private func calendar(_ identifier: String) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: identifier)!
        return c
    }

    private func date(_ cal: Calendar,
                      _ y: Int, _ mo: Int, _ d: Int,
                      _ h: Int, _ mi: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func testSpringForwardDayHasTwentyThreeHoursButStillOneLocalDay() {
        let cal = calendar("America/New_York")
        let start = date(cal, 2026, 3, 8, 0, 0)
        let end = date(cal, 2026, 3, 9, 0, 0)

        let segments = DateUtils.splitAtMidnights(start: start, end: end, calendar: cal)

        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].start, start)
        XCTAssertEqual(segments[0].end, end)
        XCTAssertEqual(Int(segments[0].end.timeIntervalSince(segments[0].start)), 23 * 60 * 60)
    }

    func testFallBackDayHasTwentyFiveHoursButStillOneLocalDay() {
        let cal = calendar("America/New_York")
        let start = date(cal, 2026, 11, 1, 0, 0)
        let end = date(cal, 2026, 11, 2, 0, 0)

        let segments = DateUtils.splitAtMidnights(start: start, end: end, calendar: cal)

        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].start, start)
        XCTAssertEqual(segments[0].end, end)
        XCTAssertEqual(Int(segments[0].end.timeIntervalSince(segments[0].start)), 25 * 60 * 60)
    }

    func testSameInstantCanBelongToDifferentLocalDaysAfterTimezoneChange() throws {
        let ny = calendar("America/New_York")
        let tokyo = calendar("Asia/Tokyo")
        let instant = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-06-12T23:30:00Z"))
        let segment = FocusSegment(startAt: instant, durationSeconds: 25 * 60)

        let nyLedger = FocusLedger.secondsByDay(segments: [segment], calendar: ny)
        let tokyoLedger = FocusLedger.secondsByDay(segments: [segment], calendar: tokyo)

        let nyDay = try XCTUnwrap(nyLedger.keys.first)
        let tokyoDay = try XCTUnwrap(tokyoLedger.keys.first)
        XCTAssertNotEqual(nyDay, tokyoDay)
        XCTAssertEqual(nyLedger[nyDay], 25 * 60)
        XCTAssertEqual(tokyoLedger[tokyoDay], 25 * 60)
    }

    func testColdLaunchDiscardsUnprovenActiveSessionMarker() throws {
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(Date(timeIntervalSinceNow: -30 * 60), forKey: FocusEngine.activeStartKey)
        defaults.set(false, forKey: FocusEngine.activeWasLockedKey)

        FocusEngine.discardUnprovenActiveStart(defaults: defaults)

        XCTAssertNil(defaults.object(forKey: FocusEngine.activeStartKey))
        XCTAssertNil(defaults.object(forKey: FocusEngine.activeWasLockedKey))
    }

    func testColdLaunchRecoversConfirmedLockedInterval() throws {
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let now = start.addingTimeInterval(90 * 60)
        defaults.set(start, forKey: FocusEngine.activeStartKey)
        defaults.set(true, forKey: FocusEngine.activeWasLockedKey)

        let recovered = try XCTUnwrap(FocusEngine.coldLaunchRecoveryInterval(defaults: defaults, now: now))

        XCTAssertEqual(recovered.start, start)
        XCTAssertEqual(recovered.end, now)
    }

    func testColdLaunchRecoversAtomicLockedMarkerIntoSwiftData() throws {
        let cal = calendar("UTC")
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FocusSession.self,
            configurations: configuration
        )
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let launchDate = date(cal, 2026, 8, 2, 10, 0)
        let lockedAt = launchDate.addingTimeInterval(-30 * 60)
        ActiveFocusMarkerStore.save(
            ActiveFocusMarker(startAt: lockedAt, isLocked: true),
            defaults: defaults
        )

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: cal,
            defaults: defaults,
            launchDate: launchDate
        )

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.startAt, lockedAt)
        XCTAssertEqual(sessions.first?.endAt, launchDate)
        XCTAssertEqual(sessions.first?.durationSeconds, 30 * 60)
        XCTAssertEqual(engine.todaySeconds, 30 * 60)
        XCTAssertNil(ActiveFocusMarkerStore.load(defaults: defaults))
    }

    func testColdLaunchClearsMalformedAtomicMarker() throws {
        let cal = calendar("UTC")
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FocusSession.self,
            configurations: configuration
        )
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data("not-json".utf8), forKey: ActiveFocusMarkerStore.key)

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: cal,
            defaults: defaults,
            launchDate: date(cal, 2026, 8, 2, 10, 0)
        )

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertTrue(sessions.isEmpty)
        XCTAssertEqual(engine.todaySeconds, 0)
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.key))
    }

    func testColdLaunchDiscardsAtomicMarkerWithoutConfirmedLock() throws {
        let cal = calendar("UTC")
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FocusSession.self,
            configurations: configuration
        )
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let launchDate = date(cal, 2026, 8, 2, 10, 0)
        ActiveFocusMarkerStore.save(
            ActiveFocusMarker(
                startAt: launchDate.addingTimeInterval(-30 * 60),
                isLocked: false
            ),
            defaults: defaults
        )

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: cal,
            defaults: defaults,
            launchDate: launchDate
        )

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertTrue(sessions.isEmpty)
        XCTAssertEqual(engine.todaySeconds, 0)
        XCTAssertNil(ActiveFocusMarkerStore.load(defaults: defaults))
    }

    func testColdLaunchIgnoresMarkerWithoutConfirmedLock() throws {
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        defaults.set(now.addingTimeInterval(-30 * 60), forKey: FocusEngine.activeStartKey)
        defaults.set(false, forKey: FocusEngine.activeWasLockedKey)

        let recovered = FocusEngine.coldLaunchRecoveryInterval(defaults: defaults, now: now)

        XCTAssertNil(recovered)
    }

    func testColdLaunchIgnoresFutureLockedMarkerAfterClockMovesBackward() throws {
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        defaults.set(now.addingTimeInterval(15 * 60), forKey: FocusEngine.activeStartKey)
        defaults.set(true, forKey: FocusEngine.activeWasLockedKey)

        let recovered = FocusEngine.coldLaunchRecoveryInterval(defaults: defaults, now: now)

        XCTAssertNil(recovered)
    }

    func testColdLaunchIgnoresSubsecondLockedInterval() throws {
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        ActiveFocusMarkerStore.save(
            ActiveFocusMarker(startAt: start, isLocked: true),
            defaults: defaults
        )

        let recovered = FocusEngine.coldLaunchRecoveryInterval(
            defaults: defaults,
            now: start.addingTimeInterval(0.5)
        )

        XCTAssertNil(recovered)
    }

    func testColdLaunchIgnoresNonfiniteLaunchClock() throws {
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        ActiveFocusMarkerStore.save(
            ActiveFocusMarker(startAt: start, isLocked: true),
            defaults: defaults
        )

        let recovered = FocusEngine.coldLaunchRecoveryInterval(
            defaults: defaults,
            now: Date(timeIntervalSinceReferenceDate: .infinity)
        )

        XCTAssertNil(recovered)
    }

    func testColdLaunchIgnoresNonfiniteLegacyMarker() throws {
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(
            Date(timeIntervalSinceReferenceDate: -.infinity),
            forKey: FocusEngine.activeStartKey
        )
        defaults.set(true, forKey: FocusEngine.activeWasLockedKey)

        let recovered = FocusEngine.coldLaunchRecoveryInterval(
            defaults: defaults,
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertNil(recovered)
    }

    func testColdLaunchIgnoresMarkerWhenDailyCapCannotAdvanceItsDate() throws {
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = Date(timeIntervalSinceReferenceDate: -1e25)
        let maximum = TimeInterval(LevelMath.maxLevel * LevelMath.secondsPerLevel)
        defaults.set(start, forKey: FocusEngine.activeStartKey)
        defaults.set(true, forKey: FocusEngine.activeWasLockedKey)

        let recovered = FocusEngine.coldLaunchRecoveryInterval(
            defaults: defaults,
            now: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertEqual(start.addingTimeInterval(maximum), start)
        XCTAssertNil(recovered)
    }

    func testColdLaunchLockedRecoveryCapsAtDailyMaximum() throws {
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        defaults.set(start, forKey: FocusEngine.activeStartKey)
        defaults.set(true, forKey: FocusEngine.activeWasLockedKey)

        let recovered = try XCTUnwrap(FocusEngine.coldLaunchRecoveryInterval(
            defaults: defaults,
            now: start.addingTimeInterval(24 * 60 * 60)
        ))

        XCTAssertEqual(
            Int(recovered.duration),
            LevelMath.maxLevel * LevelMath.secondsPerLevel
        )
    }

    func testColdLaunchRecoveryDoesNotDuplicateAnAlreadySavedLockedInterval() throws {
        let cal = calendar("UTC")
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FocusSession.self,
            configurations: configuration
        )
        let suiteName = "TrustAuditTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let launchDate = date(cal, 2026, 7, 29, 10, 0)
        let lockedAt = launchDate.addingTimeInterval(-60 * 60)

        defaults.set(lockedAt, forKey: FocusEngine.activeStartKey)
        defaults.set(true, forKey: FocusEngine.activeWasLockedKey)
        let firstEngine = FocusEngine(
            context: container.mainContext,
            calendar: cal,
            defaults: defaults,
            launchDate: launchDate
        )
        XCTAssertEqual(firstEngine.todaySeconds, 60 * 60)

        // Simulate termination after SwiftData saved but before UserDefaults cleared.
        defaults.set(lockedAt, forKey: FocusEngine.activeStartKey)
        defaults.set(true, forKey: FocusEngine.activeWasLockedKey)
        let relaunchedEngine = FocusEngine(
            context: container.mainContext,
            calendar: cal,
            defaults: defaults,
            launchDate: launchDate.addingTimeInterval(15 * 60)
        )

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.durationSeconds, 60 * 60)
        XCTAssertEqual(relaunchedEngine.todaySeconds, 60 * 60)
        XCTAssertNil(defaults.object(forKey: FocusEngine.activeStartKey))
        XCTAssertNil(defaults.object(forKey: FocusEngine.activeWasLockedKey))
    }

    func testCompletedSegmentsProduceStableDailyLevelAfterRelaunch() throws {
        let cal = calendar("UTC")
        let today = cal.startOfDay(for: Date())
        let start = try XCTUnwrap(cal.date(byAdding: .hour, value: 9, to: today))
        let completed = [FocusSegment(startAt: start, durationSeconds: 25 * 60)]

        let firstLoad = FocusLedger.secondsByDay(segments: completed, calendar: cal)
        let relaunchedLoad = FocusLedger.secondsByDay(segments: completed, calendar: cal)

        XCTAssertEqual(firstLoad[today], 25 * 60)
        XCTAssertEqual(relaunchedLoad[today], 25 * 60)
        XCTAssertEqual(LevelMath.level(forFocusMinutes: (relaunchedLoad[today] ?? 0) / 60), 5)
    }
}
