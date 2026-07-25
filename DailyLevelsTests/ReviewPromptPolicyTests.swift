import XCTest
@testable import DailyLevels

final class ReviewPromptPolicyTests: XCTestCase {
    private let firstLaunch = 1_000_000.0
    private let version = "1.1"

    func testOrdinaryLevelUpDoesNotRequestReview() {
        XCTAssertFalse(shouldRequest(classChanged: false, daysLater: 10))
    }

    func testPromotionBeforeThreeDaysDoesNotRequestReview() {
        XCTAssertFalse(shouldRequest(classChanged: true, daysLater: 2.99))
    }

    func testPromotionAtThreeDaysCanRequestReview() {
        XCTAssertTrue(shouldRequest(classChanged: true, daysLater: 3))
    }

    func testSameVersionNeverRequestsTwice() {
        XCTAssertFalse(
            ReviewPromptPolicy.shouldRequest(
                classChanged: true,
                firstLaunchAt: firstLaunch,
                now: firstLaunch + 10 * 86_400,
                currentVersion: version,
                lastReviewVersion: version
            )
        )
    }

    func testNewVersionCanRequestAfterAnOlderVersion() {
        XCTAssertTrue(
            ReviewPromptPolicy.shouldRequest(
                classChanged: true,
                firstLaunchAt: firstLaunch,
                now: firstLaunch + 10 * 86_400,
                currentVersion: version,
                lastReviewVersion: "1.0"
            )
        )
    }

    func testInvalidOrFutureLaunchDateFailsClosed() {
        XCTAssertFalse(
            ReviewPromptPolicy.shouldRequest(
                classChanged: true,
                firstLaunchAt: 0,
                now: firstLaunch,
                currentVersion: version,
                lastReviewVersion: ""
            )
        )
        XCTAssertFalse(
            ReviewPromptPolicy.shouldRequest(
                classChanged: true,
                firstLaunchAt: firstLaunch + 1,
                now: firstLaunch,
                currentVersion: version,
                lastReviewVersion: ""
            )
        )
    }

    private func shouldRequest(classChanged: Bool, daysLater: Double) -> Bool {
        ReviewPromptPolicy.shouldRequest(
            classChanged: classChanged,
            firstLaunchAt: firstLaunch,
            now: firstLaunch + daysLater * 86_400,
            currentVersion: version,
            lastReviewVersion: ""
        )
    }
}
