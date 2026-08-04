import XCTest
@testable import DailyLevels

final class ActiveFocusMarkerTests: XCTestCase {
    private func defaults() throws -> (UserDefaults, String) {
        let suiteName = "ActiveFocusMarkerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    func testSaveRoundTripsOneMarkerPayload() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let marker = ActiveFocusMarker(
            startAt: Date(timeIntervalSince1970: 1_700_000_000),
            isLocked: true
        )

        ActiveFocusMarkerStore.save(marker, defaults: defaults)

        XCTAssertEqual(ActiveFocusMarkerStore.load(defaults: defaults), marker)
        XCTAssertNotNil(defaults.data(forKey: ActiveFocusMarkerStore.key))
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyStartKey))
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyLockedKey))
    }

    func testClearRemovesCurrentAndLegacyMarkerValues() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let startAt = Date(timeIntervalSince1970: 1_700_000_000)
        ActiveFocusMarkerStore.save(
            ActiveFocusMarker(startAt: startAt, isLocked: false),
            defaults: defaults
        )
        defaults.set(startAt, forKey: ActiveFocusMarkerStore.legacyStartKey)
        defaults.set(true, forKey: ActiveFocusMarkerStore.legacyLockedKey)

        ActiveFocusMarkerStore.clear(defaults: defaults)

        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.key))
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyStartKey))
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyLockedKey))
    }

    func testLoadMigratesLegacyLockedMarker() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let startAt = Date(timeIntervalSince1970: 1_700_000_000)
        defaults.set(startAt, forKey: ActiveFocusMarkerStore.legacyStartKey)
        defaults.set(true, forKey: ActiveFocusMarkerStore.legacyLockedKey)

        let marker = ActiveFocusMarkerStore.load(defaults: defaults)

        XCTAssertEqual(marker, ActiveFocusMarker(startAt: startAt, isLocked: true))
        XCTAssertNotNil(defaults.data(forKey: ActiveFocusMarkerStore.key))
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyStartKey))
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyLockedKey))
    }

    func testLoadMigratesLegacyUnlockedMarkerWithoutPromotingIt() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let startAt = Date(timeIntervalSince1970: 1_700_000_000)
        defaults.set(startAt, forKey: ActiveFocusMarkerStore.legacyStartKey)
        defaults.set(false, forKey: ActiveFocusMarkerStore.legacyLockedKey)

        let marker = ActiveFocusMarkerStore.load(defaults: defaults)

        XCTAssertEqual(marker, ActiveFocusMarker(startAt: startAt, isLocked: false))
        XCTAssertFalse(try XCTUnwrap(marker).isLocked)
        XCTAssertNotNil(defaults.data(forKey: ActiveFocusMarkerStore.key))
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyStartKey))
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyLockedKey))
    }

    func testMalformedCurrentPayloadFallsBackToLegacyMarker() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let startAt = Date(timeIntervalSince1970: 1_700_000_000)
        defaults.set(Data("not-json".utf8), forKey: ActiveFocusMarkerStore.key)
        defaults.set(startAt, forKey: ActiveFocusMarkerStore.legacyStartKey)
        defaults.set(true, forKey: ActiveFocusMarkerStore.legacyLockedKey)

        let marker = ActiveFocusMarkerStore.load(defaults: defaults)
        let rewrittenData = try XCTUnwrap(defaults.data(forKey: ActiveFocusMarkerStore.key))
        let rewritten = try JSONDecoder().decode(ActiveFocusMarker.self, from: rewrittenData)

        XCTAssertEqual(marker, ActiveFocusMarker(startAt: startAt, isLocked: true))
        XCTAssertEqual(rewritten, marker)
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyStartKey))
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.legacyLockedKey))
    }

    func testMalformedCurrentPayloadWithoutLegacyMarkerIsRemoved() throws {
        let (defaults, suiteName) = try defaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data("not-json".utf8), forKey: ActiveFocusMarkerStore.key)

        let marker = ActiveFocusMarkerStore.load(defaults: defaults)

        XCTAssertNil(marker)
        XCTAssertNil(defaults.object(forKey: ActiveFocusMarkerStore.key))
    }
}
