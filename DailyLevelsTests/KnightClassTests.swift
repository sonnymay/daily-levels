//
//  KnightClassTests.swift
//  DailyLevelsTests
//
//  SPEC §3 ten-class ladder (bands of 10, cap at level 100 = Mythic).
//  Required boundaries to verify: 10/11, 30/31, 60/61, plus the upper bands.
//

import XCTest
@testable import DailyLevels

final class KnightClassTests: XCTestCase {

    func testRequiredBoundaries() {
        // 10/11 — Novice / Squire
        XCTAssertEqual(KnightClass.forLevel(10), .novice)
        XCTAssertEqual(KnightClass.forLevel(11), .squire)
        // 30/31 — Swordsman / Knight
        XCTAssertEqual(KnightClass.forLevel(30), .swordsman)
        XCTAssertEqual(KnightClass.forLevel(31), .knight)
        // 60/61 — Champion / Paladin
        XCTAssertEqual(KnightClass.forLevel(60), .champion)
        XCTAssertEqual(KnightClass.forLevel(61), .paladin)
    }

    func testUpperBandBoundaries() {
        // 70/71 — Paladin / Hero
        XCTAssertEqual(KnightClass.forLevel(70), .paladin)
        XCTAssertEqual(KnightClass.forLevel(71), .hero)
        // 80/81 — Hero / Legend
        XCTAssertEqual(KnightClass.forLevel(80), .hero)
        XCTAssertEqual(KnightClass.forLevel(81), .legend)
        // 90/91 — Legend / Mythic
        XCTAssertEqual(KnightClass.forLevel(90), .legend)
        XCTAssertEqual(KnightClass.forLevel(91), .mythic)
    }

    func testEdgesAndCap() {
        XCTAssertEqual(KnightClass.forLevel(0), .novice)
        XCTAssertEqual(KnightClass.forLevel(20), .squire)
        XCTAssertEqual(KnightClass.forLevel(21), .swordsman)
        XCTAssertEqual(KnightClass.forLevel(40), .knight)
        XCTAssertEqual(KnightClass.forLevel(41), .crusader)
        XCTAssertEqual(KnightClass.forLevel(50), .crusader)
        XCTAssertEqual(KnightClass.forLevel(51), .champion)
        XCTAssertEqual(KnightClass.forLevel(100), .mythic)   // the cap
        XCTAssertEqual(KnightClass.forLevel(999), .mythic)   // defensive: never exceeds Mythic
    }
}
