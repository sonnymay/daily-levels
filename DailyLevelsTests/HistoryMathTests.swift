import XCTest
@testable import DailyLevels

final class HistoryMathTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

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
}
