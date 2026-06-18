//
//  TrustAuditTests.swift
//  DailyLevelsTests
//
//  High-signal tests for the promises users must be able to trust:
//  local-day boundaries, DST, timezone attribution, cold-launch recovery, and
//  persisted focus history. No network, no UI, no store.
//

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

        FocusEngine.discardUnprovenActiveStart(defaults: defaults)

        XCTAssertNil(defaults.object(forKey: FocusEngine.activeStartKey))
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
