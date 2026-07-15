//
//  FocusLedgerTests.swift
//  DailyLevelsTests
//
//  Direct coverage for the persisted-focus aggregation contract.
//

import XCTest
@testable import DailyLevels

final class FocusLedgerTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(day: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 7, day: day, hour: hour, minute: minute))!
    }

    func testSegmentsOnTheSameDayAreAddedTogether() {
        let day = calendar.startOfDay(for: date(day: 13, hour: 9))
        let segments = [
            FocusSegment(startAt: date(day: 13, hour: 9), durationSeconds: 5 * 60),
            FocusSegment(startAt: date(day: 13, hour: 14), durationSeconds: 20 * 60)
        ]

        let result = FocusLedger.secondsByDay(segments: segments, calendar: calendar)

        XCTAssertEqual(result, [day: 25 * 60])
    }

    func testSegmentsRemainSeparatedByLocalDay() {
        let firstDay = calendar.startOfDay(for: date(day: 12, hour: 23))
        let secondDay = calendar.startOfDay(for: date(day: 13, hour: 0))
        let segments = [
            FocusSegment(startAt: date(day: 12, hour: 23), durationSeconds: 10 * 60),
            FocusSegment(startAt: date(day: 13, hour: 0), durationSeconds: 15 * 60)
        ]

        let result = FocusLedger.secondsByDay(segments: segments, calendar: calendar)

        XCTAssertEqual(result[firstDay], 10 * 60)
        XCTAssertEqual(result[secondDay], 15 * 60)
        XCTAssertEqual(result.count, 2)
    }

    func testInvalidDurationsCannotReduceEarnedFocus() {
        let day = calendar.startOfDay(for: date(day: 13, hour: 9))
        let segments = [
            FocusSegment(startAt: date(day: 13, hour: 9), durationSeconds: 10 * 60),
            FocusSegment(startAt: date(day: 13, hour: 10), durationSeconds: 0),
            FocusSegment(startAt: date(day: 13, hour: 11), durationSeconds: -5 * 60)
        ]

        let result = FocusLedger.secondsByDay(segments: segments, calendar: calendar)

        XCTAssertEqual(result, [day: 10 * 60])
    }

    func testLegacySegmentCrossingMidnightIsSplitBetweenDays() {
        let firstDay = calendar.startOfDay(for: date(day: 12, hour: 23))
        let secondDay = calendar.startOfDay(for: date(day: 13, hour: 0))
        let segment = FocusSegment(
            startAt: date(day: 12, hour: 23, minute: 59),
            durationSeconds: 2 * 60
        )

        let result = FocusLedger.secondsByDay(segments: [segment], calendar: calendar)

        XCTAssertEqual(result, [firstDay: 60, secondDay: 60])
    }
}
