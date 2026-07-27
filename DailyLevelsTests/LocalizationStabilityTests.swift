//
//  LocalizationStabilityTests.swift
//  DailyLevelsTests
//
//  Guards the invariant that adding localization (KnightClass.displayName) must NOT
//  change rawValue — which builds asset filenames ("<class>_grind.mp4", "<class>_sleep.png")
//  and drives Pro gating. If anyone ever localizes rawValue, these fail loudly.
//

import XCTest
@testable import DailyLevels

final class LocalizationStabilityTests: XCTestCase {

    func testRawValuesStayEnglishAssetKeys() {
        XCTAssertEqual(KnightClass.novice.rawValue, "Novice")
        XCTAssertEqual(KnightClass.knight.rawValue, "Knight")
        XCTAssertEqual(KnightClass.mythic.rawValue, "Mythic")
        // Lowercased rawValue is the asset filename stem.
        XCTAssertEqual(KnightClass.mythic.rawValue.lowercased(), "mythic")
    }

    func testHeroSceneAssetNamingUnchanged() {
        XCTAssertEqual(HeroSceneAsset.resourceName(grinding: true,  className: KnightClass.novice.rawValue), "novice_grind")
        XCTAssertEqual(HeroSceneAsset.resourceName(grinding: false, className: KnightClass.mythic.rawValue), "mythic_sleep")
        XCTAssertEqual(HeroSceneAsset.resourceName(grinding: false, className: KnightClass.knight.rawValue), "knight_sleep")
    }

    func testProGateBoundaryUnchanged() {
        // Free art ceiling is Swordsman; Knight and up are Pro-only.
        XCTAssertFalse(KnightClass.novice.isProOnly)
        XCTAssertFalse(KnightClass.swordsman.isProOnly)
        XCTAssertTrue(KnightClass.knight.isProOnly)
        XCTAssertTrue(KnightClass.mythic.isProOnly)
    }

    func testHeroJourneyStatusHasSpanishTranslations() throws {
        let spanish = Locale(identifier: "es")
        let localizationURL = try XCTUnwrap(
            Bundle.main.url(forResource: "es", withExtension: "lproj")
        )
        let localizationBundle = try XCTUnwrap(Bundle(url: localizationURL))
        let nextClass = "Caballero"
        let statusKey = "%lld of 10 reached · Next: %@ at level %lld"
        let statusFormat = localizationBundle.localizedString(
            forKey: statusKey,
            value: nil,
            table: "Localizable"
        )
        let status = String(format: statusFormat, locale: spanish, 3, nextClass, 31)
        let complete = localizationBundle.localizedString(
            forKey: "All 10 heroes reached",
            value: nil,
            table: "Localizable"
        )

        XCTAssertEqual(status, "3 de 10 alcanzados · Siguiente: Caballero en el nivel 31")
        XCTAssertEqual(complete, "Los 10 héroes alcanzados")
    }
}
