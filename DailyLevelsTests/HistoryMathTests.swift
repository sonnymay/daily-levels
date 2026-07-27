import XCTest
@testable import DailyLevels

final class HistoryMathTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func day(_ value: Int, minutes: Int) -> DaySummary {
        let date = calendar.date(from: DateComponents(year: 2026, month: 7, day: value))!
        return DaySummary(date: date, focusMinutes: minutes)
    }

    func testPersonalBestIgnoresEmptyDays() {
        let result = HistoryMath.personalBest(from: [
            day(20, minutes: 0),
            day(21, minutes: 0)
        ])

        XCTAssertNil(result)
    }

    func testPersonalBestUsesTheMostFocusedDay() {
        let result = HistoryMath.personalBest(from: [
            day(20, minutes: 45),
            day(21, minutes: 90),
            day(22, minutes: 30)
        ])

        XCTAssertEqual(result, day(21, minutes: 90))
    }

    func testPersonalBestFavorsTheLatestDayWhenMinutesTie() {
        let result = HistoryMath.personalBest(from: [
            day(20, minutes: 75),
            day(22, minutes: 75),
            day(21, minutes: 60)
        ])

        XCTAssertEqual(result, day(22, minutes: 75))
    }

    func testSnapshotBuildsWeekRecentDaysAndPersonalBestFromOneLedger() {
        let referenceDate = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 27, hour: 12)
        )!
        let secondsByDay = [
            day(21, minutes: 0).date: 30,
            day(25, minutes: 30).date: 30 * 60,
            day(26, minutes: 90).date: 90 * 60,
            day(27, minutes: 15).date: 15 * 60
        ]

        let snapshot = HistoryMath.snapshot(
            secondsByDay: secondsByDay,
            referenceDate: referenceDate,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.weekHistory.count, 7)
        XCTAssertEqual(snapshot.weekHistory.first, day(21, minutes: 0))
        XCTAssertEqual(snapshot.weekHistory.last, day(27, minutes: 15))
        XCTAssertEqual(snapshot.recentDays, [
            day(27, minutes: 15),
            day(26, minutes: 90),
            day(25, minutes: 30)
        ])
        XCTAssertEqual(snapshot.personalBest, day(26, minutes: 90))
    }

    func testEmptySnapshotStillIncludesTodayAndSevenDayChart() {
        let referenceDate = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 27, hour: 12)
        )!

        let snapshot = HistoryMath.snapshot(
            secondsByDay: [:],
            referenceDate: referenceDate,
            calendar: calendar
        )

        XCTAssertEqual(snapshot.weekHistory.count, 7)
        XCTAssertEqual(snapshot.recentDays, [day(27, minutes: 0)])
        XCTAssertNil(snapshot.personalBest)
    }
}
