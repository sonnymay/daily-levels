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

    func testEveryClassSceneAssetIsBundled() {
        for knightClass in KnightClass.allCases {
            let grindingName = HeroSceneAsset.resourceName(
                grinding: true,
                className: knightClass.rawValue
            )
            let sleepingName = HeroSceneAsset.resourceName(
                grinding: false,
                className: knightClass.rawValue
            )

            XCTAssertNotNil(
                Bundle.main.url(forResource: grindingName, withExtension: "mp4"),
                "\(grindingName).mp4 is missing from the app bundle"
            )
            XCTAssertNotNil(
                Bundle.main.url(forResource: sleepingName, withExtension: "png"),
                "\(sleepingName).png is missing from the app bundle"
            )
        }
    }
}
