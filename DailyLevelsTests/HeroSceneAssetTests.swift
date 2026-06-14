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
}
