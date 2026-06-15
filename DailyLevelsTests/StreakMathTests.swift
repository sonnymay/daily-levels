//
//  StreakMathTests.swift
//  DailyLevelsTests
//
//  Calm-streak semantics: counts consecutive Level-1+ days; an unstarted today does
//  NOT break the streak; sub-Level-1 days don't count.
//

import XCTest
@testable import DailyLevels

final class StreakMathTests: XCTestCase {

    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private let today = Date(timeIntervalSince1970: 1_700_000_000)  // fixed, tz-pinned by cal

    /// Start-of-day key `offset` days from `today` (negative = past).
    private func day(_ offset: Int) -> Date {
        cal.startOfDay(for: cal.date(byAdding: .day, value: offset, to: today)!)
    }

    func testNoFocusIsZero() {
        XCTAssertEqual(StreakMath.currentStreak(secondsByDay: [:], today: today, calendar: cal), 0)
    }

    func testTodayOnlyIsOne() {
        XCTAssertEqual(StreakMath.currentStreak(secondsByDay: [day(0): 300], today: today, calendar: cal), 1)
    }

    func testThreeConsecutiveIncludingToday() {
        let map = [day(0): 600, day(-1): 300, day(-2): 1200]
        XCTAssertEqual(StreakMath.currentStreak(secondsByDay: map, today: today, calendar: cal), 3)
    }

    func testGapBreaksStreak() {
        // today + yesterday count; day -2 missing → streak is 2 (older run is severed).
        let map = [day(0): 300, day(-1): 300, day(-3): 300]
        XCTAssertEqual(StreakMath.currentStreak(secondsByDay: map, today: today, calendar: cal), 2)
    }

    func testTodayEmptyCountsRunEndingYesterday() {
        // today empty (open, not broken); yesterday + before count → 2.
        let map = [day(-1): 300, day(-2): 300]
        XCTAssertEqual(StreakMath.currentStreak(secondsByDay: map, today: today, calendar: cal), 2)
    }

    func testBelowLevelOneDoesNotCount() {
        XCTAssertEqual(StreakMath.currentStreak(secondsByDay: [day(0): 299], today: today, calendar: cal), 0)
    }

    func testTodayAndYesterdayEmptyIsZero() {
        XCTAssertEqual(StreakMath.currentStreak(secondsByDay: [day(-2): 300], today: today, calendar: cal), 0)
    }
}
