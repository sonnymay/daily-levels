import XCTest
@testable import DailyLevels

@MainActor
final class StoreEntitlementTests: XCTestCase {
    func testStoreCanStartWithoutLiveStoreKitObservers() {
        let store = Store(startObserving: false)

        XCTAssertNil(store.proProduct)
        XCTAssertFalse(store.isPro)
        XCTAssertFalse(store.isWorking)
    }

    func testPaidBuildsBeforeFreemiumAreGrandfathered() {
        XCTAssertTrue(Store.isLegacyPaidBuild("1"))
        XCTAssertTrue(Store.isLegacyPaidBuild("2"))
        XCTAssertTrue(Store.isLegacyPaidBuild("5"))
    }

    func testFreemiumAndLaterBuildsAreNotGrandfathered() {
        XCTAssertFalse(Store.isLegacyPaidBuild("6"))
        XCTAssertFalse(Store.isLegacyPaidBuild("10"))
    }

    func testVersionLikeAndInvalidValuesFailClosed() {
        XCTAssertTrue(Store.isLegacyPaidBuild("2.0"))
        XCTAssertFalse(Store.isLegacyPaidBuild("0"))
        XCTAssertFalse(Store.isLegacyPaidBuild("-1"))
        XCTAssertFalse(Store.isLegacyPaidBuild("not-a-build"))
        XCTAssertFalse(Store.isLegacyPaidBuild(""))
    }
}
