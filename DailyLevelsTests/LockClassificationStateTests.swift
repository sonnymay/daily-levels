import XCTest
@testable import DailyLevels

final class LockClassificationStateTests: XCTestCase {
    private let backgroundedAt = Date(timeIntervalSince1970: 1_700_000_000)

    func testForegroundWithoutLockIsAnAppSwitch() {
        var state = LockClassificationState()
        state.enterBackground(at: backgroundedAt)

        XCTAssertEqual(state.enterForeground(), .appSwitch(backgroundedAt))
        XCTAssertNil(state.enterForeground())
    }

    func testDetectedLockKeepsGrindingOnForeground() {
        var state = LockClassificationState()
        state.enterBackground(at: backgroundedAt)

        XCTAssertTrue(state.detectLock())
        XCTAssertEqual(state.enterForeground(), .locked)
        XCTAssertNil(state.graceExpired())
    }

    func testGraceExpiryReportsAppSwitchOnlyOnce() {
        var state = LockClassificationState()
        state.enterBackground(at: backgroundedAt)

        XCTAssertEqual(state.graceExpired(), backgroundedAt)
        XCTAssertNil(state.graceExpired())
        XCTAssertFalse(state.detectLock())
        XCTAssertNil(state.enterForeground())
    }

    func testLockWithoutPendingBackgroundIsIgnored() {
        var state = LockClassificationState()

        XCTAssertFalse(state.detectLock())
        XCTAssertFalse(state.sawLock)
        XCTAssertNil(state.enterForeground())
    }

    func testNewBackgroundTripClearsPreviousLockSignal() {
        let secondBackground = backgroundedAt.addingTimeInterval(10)
        var state = LockClassificationState()
        state.enterBackground(at: backgroundedAt)
        XCTAssertTrue(state.detectLock())

        state.enterBackground(at: secondBackground)

        XCTAssertFalse(state.sawLock)
        XCTAssertEqual(state.enterForeground(), .appSwitch(secondBackground))
    }
}
