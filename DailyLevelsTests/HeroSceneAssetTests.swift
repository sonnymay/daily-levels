//
//  HeroSceneAssetTests.swift
//  DailyLevelsTests
//
//  Verifies the class-specific hero scene resource naming used by HeroScenePanel.
//

import XCTest
@testable import DailyLevels

final class HeroSceneAssetTests: XCTestCase {

    func testGrindingUsesPerClassVideoName() {
        XCTAssertEqual(HeroSceneAsset.resourceName(grinding: true, className: "Novice"), "novice_grind")
    }

    func testSleepingUsesPerClassImageName() {
        XCTAssertEqual(HeroSceneAsset.resourceName(grinding: false, className: "Novice"), "novice_sleep")
        XCTAssertEqual(HeroSceneAsset.resourceName(grinding: false, className: "Mythic"), "mythic_sleep")
    }

    func testSleepingImageIsReusedFromCache() throws {
        let first = try XCTUnwrap(HeroSceneAsset.sleepImage(for: "Novice"))
        let second = try XCTUnwrap(HeroSceneAsset.sleepImage(for: "Novice"))

        XCTAssertTrue(first === second)
    }
}
