import SwiftData
import XCTest
@testable import DailyLevels

@MainActor
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

    func testLoadSalvagesValidRecordsAroundMalformedEntry() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let records = [
            PendingFocusRecord(
                id: UUID(),
                startAt: start,
                endAt: start.addingTimeInterval(60),
                durationSeconds: 60
            ),
            PendingFocusRecord(
                id: UUID(),
                startAt: start.addingTimeInterval(120),
                endAt: start.addingTimeInterval(180),
                durationSeconds: 60
            )
        ]
        let encoded = try JSONEncoder().encode(records)
        var objects = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [[String: Any]]
        )
        objects.insert(["id": "not-a-uuid"], at: 1)
        defaults.set(
            try JSONSerialization.data(withJSONObject: objects),
            forKey: FocusJournal.key
        )

        XCTAssertEqual(FocusJournal.load(defaults: defaults), records)
    }

    func testLoadKeepsFirstRecordWhenStoredIDsRepeat() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let id = UUID()
        let first = PendingFocusRecord(
            id: id,
            startAt: start,
            endAt: start.addingTimeInterval(60),
            durationSeconds: 60
        )
        let conflictingRetry = PendingFocusRecord(
            id: id,
            startAt: start,
            endAt: start.addingTimeInterval(120),
            durationSeconds: 120
        )
        defaults.set(
            try JSONEncoder().encode([first, conflictingRetry]),
            forKey: FocusJournal.key
        )

        XCTAssertEqual(FocusJournal.load(defaults: defaults), [first])
    }

    func testEngineReplaysPendingRecordAndClearsJournal() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FocusSession.self,
            configurations: configuration
        )
        let launchDate = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 30, hour: 10
        )))
        let record = PendingFocusRecord(
            id: UUID(),
            startAt: launchDate.addingTimeInterval(-5 * 60),
            endAt: launchDate,
            durationSeconds: 5 * 60
        )
        FocusJournal.append([record], defaults: defaults)

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: launchDate
        )

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.map(\.id), [record.id])
        XCTAssertEqual(engine.todaySeconds, 5 * 60)
        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)
    }

    func testEngineDoesNotDuplicateJournalRecordAlreadyInSwiftData() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FocusSession.self,
            configurations: configuration
        )
        let launchDate = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 30, hour: 10
        )))
        let record = PendingFocusRecord(
            id: UUID(),
            startAt: launchDate.addingTimeInterval(-5 * 60),
            endAt: launchDate,
            durationSeconds: 5 * 60
        )
        container.mainContext.insert(FocusSession(
            id: record.id,
            startAt: record.startAt,
            endAt: record.endAt,
            durationSeconds: record.durationSeconds
        ))
        try container.mainContext.save()
        FocusJournal.append([record], defaults: defaults)

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: launchDate
        )

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(engine.todaySeconds, 5 * 60)
        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)
    }

    func testEngineReplaysMidnightJournalIntoTheCorrectDays() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FocusSession.self,
            configurations: configuration
        )
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 30, hour: 23, minute: 58
        )))
        let launchDate = start.addingTimeInterval(5 * 60)
        let records = FocusJournal.records(
            start: start,
            end: launchDate,
            calendar: calendar
        )
        FocusJournal.append(records, defaults: defaults)

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: launchDate
        )

        let sessions = try container.mainContext.fetch(FetchDescriptor<FocusSession>())
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions.map(\.durationSeconds).reduce(0, +), 5 * 60)
        XCTAssertEqual(engine.completedSecondsByDay.values.reduce(0, +), 5 * 60)
        XCTAssertEqual(engine.todaySeconds, 3 * 60)
        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)
    }

    func testEngineReplayPreservesPausedGapBetweenCheckpoints() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FocusSession.self,
            configurations: configuration
        )
        let launchDate = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 30, hour: 10
        )))
        let firstStart = launchDate.addingTimeInterval(-10 * 60)
        let secondStart = launchDate.addingTimeInterval(-3 * 60)
        let records = [
            PendingFocusRecord(
                id: UUID(),
                startAt: firstStart,
                endAt: firstStart.addingTimeInterval(2 * 60),
                durationSeconds: 2 * 60
            ),
            PendingFocusRecord(
                id: UUID(),
                startAt: secondStart,
                endAt: launchDate,
                durationSeconds: 3 * 60
            )
        ]
        FocusJournal.append(records, defaults: defaults)

        let engine = FocusEngine(
            context: container.mainContext,
            calendar: calendar,
            defaults: defaults,
            launchDate: launchDate
        )

        let descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.startAt)]
        )
        let sessions = try container.mainContext.fetch(descriptor)
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions.map(\.durationSeconds), [2 * 60, 3 * 60])
        XCTAssertEqual(sessions[0].endAt, firstStart.addingTimeInterval(2 * 60))
        XCTAssertEqual(sessions[1].startAt, secondStart)
        XCTAssertEqual(engine.todaySeconds, 5 * 60)
        XCTAssertTrue(FocusJournal.load(defaults: defaults).isEmpty)
    }
}
