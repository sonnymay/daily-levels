//
//  MidnightSplitTests.swift
//  DailyLevelsTests
//
//  SPEC §5 edge 1: a session crossing midnight splits at 12:00 AM local so each day
//  gets its own minutes. Tests pin a fixed timezone/calendar for determinism.
//

import XCTest
@testable import DailyLevels

final class MidnightSplitTests: XCTestCase {

    // Fixed calendar so the test doesn't depend on the machine's timezone.
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!   // a normal, DST-observing zone
        return c
    }()

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func testSingleDaySessionIsNotSplit() {
        let start = date(2026, 6, 12, 9, 0)
        let end   = date(2026, 6, 12, 9, 40)
        let segs = DateUtils.splitAtMidnights(start: start, end: end, calendar: cal)

        XCTAssertEqual(segs.count, 1)
        XCTAssertEqual(segs[0].start, start)
        XCTAssertEqual(segs[0].end, end)
    }

    func testSessionCrossingOneMidnightSplitsIntoTwo() {
        // 23:30 June 12 → 00:30 June 13  (30 min on each side of midnight)
        let start = date(2026, 6, 12, 23, 30)
        let end   = date(2026, 6, 13, 0, 30)
        let midnight = date(2026, 6, 13, 0, 0)

        let segs = DateUtils.splitAtMidnights(start: start, end: end, calendar: cal)

        XCTAssertEqual(segs.count, 2)
        XCTAssertEqual(segs[0].start, start)
        XCTAssertEqual(segs[0].end, midnight)
        XCTAssertEqual(segs[1].start, midnight)
        XCTAssertEqual(segs[1].end, end)

        // Each day gets 30 minutes → Level 6 each (floor(30/5)).
        let day1Min = Int(segs[0].end.timeIntervalSince(segs[0].start)) / 60
        let day2Min = Int(segs[1].end.timeIntervalSince(segs[1].start)) / 60
        XCTAssertEqual(day1Min, 30)
        XCTAssertEqual(day2Min, 30)
        XCTAssertEqual(LevelMath.level(forFocusMinutes: day1Min), 6)
        XCTAssertEqual(LevelMath.level(forFocusMinutes: day2Min), 6)
    }

    func testSessionSpanningTwoMidnightsSplitsIntoThree() {
        // Starts late June 12, runs through all of June 13, ends early June 14.
        let start = date(2026, 6, 12, 23, 0)
        let end   = date(2026, 6, 14, 1, 0)
        let segs = DateUtils.splitAtMidnights(start: start, end: end, calendar: cal)

        XCTAssertEqual(segs.count, 3)
        XCTAssertEqual(segs[0].start, start)
        XCTAssertEqual(segs[0].end, date(2026, 6, 13, 0, 0))
        XCTAssertEqual(segs[1].start, date(2026, 6, 13, 0, 0))
        XCTAssertEqual(segs[1].end, date(2026, 6, 14, 0, 0))
        XCTAssertEqual(segs[2].start, date(2026, 6, 14, 0, 0))
        XCTAssertEqual(segs[2].end, end)

        // Middle segment is a full 24h day; total duration is preserved.
        let total = segs.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }
        XCTAssertEqual(total, end.timeIntervalSince(start), accuracy: 0.001)
    }

    func testEmptyAndInvertedIntervalsReturnNothing() {
        let t = date(2026, 6, 12, 9, 0)
        XCTAssertTrue(DateUtils.splitAtMidnights(start: t, end: t, calendar: cal).isEmpty)
        XCTAssertTrue(DateUtils.splitAtMidnights(start: t, end: t.addingTimeInterval(-60), calendar: cal).isEmpty)
    }
}
