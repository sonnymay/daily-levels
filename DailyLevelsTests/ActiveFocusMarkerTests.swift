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
}
