import XCTest
@testable import DailyLevels

final class FocusJournalTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func defaults() throws -> (UserDefaults, String) {
        let suiteName = "FocusJournalTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    func testRecordsSplitAtLocalMidnight() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 30, hour: 23, minute: 58
        )))
        let ids = [
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        ]
        var index = 0

        let records = FocusJournal.records(
            start: start,
            end: start.addingTimeInterval(5 * 60),
            calendar: calendar,
            makeID: {
                defer { index += 1 }
                return ids[index]
            }
        )

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.map(\.id), ids)
        XCTAssertEqual(records.map(\.durationSeconds), [2 * 60, 3 * 60])
        XCTAssertEqual(records[0].endAt, records[1].startAt)
    }

    func testAppendPreservesEarlierRecordsAndDeduplicatesRetries() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let first = PendingFocusRecord(
            id: UUID(),
            startAt: start,
            endAt: start.addingTimeInterval(60),
            durationSeconds: 60
        )
        let second = PendingFocusRecord(
            id: UUID(),
            startAt: start.addingTimeInterval(120),
            endAt: start.addingTimeInterval(180),
            durationSeconds: 60
        )

        FocusJournal.append([first], defaults: defaults)
        FocusJournal.append([first, second], defaults: defaults)

        XCTAssertEqual(FocusJournal.load(defaults: defaults), [first, second])
    }

    func testClearRemovesPendingRecords() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let record = PendingFocusRecord(
            id: UUID(),
            startAt: start,
            endAt: start.addingTimeInterval(60),
            durationSeconds: 60
        )
        FocusJournal.append([record], defaults: defaults)

        FocusJournal.clear(defaults: defaults)

        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)
        XCTAssertNil(defaults.object(forKey: FocusJournal.key))
    }

    func testMalformedJournalDoesNotCrashRecovery() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data("not-json".utf8), forKey: FocusJournal.key)

        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)
    }
}
