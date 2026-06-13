//
//  KnightClassTests.swift
//  DailyLevelsTests
//
//  SPEC §3 class ladder. The required boundaries to verify are 10/11, 30/31, 60/61.
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
        // 60/61 — Champion / Legend
        XCTAssertEqual(KnightClass.forLevel(60), .champion)
        XCTAssertEqual(KnightClass.forLevel(61), .legend)
    }

    func testAllBandsAndEdges() {
        XCTAssertEqual(KnightClass.forLevel(0), .novice)
        XCTAssertEqual(KnightClass.forLevel(20), .squire)
        XCTAssertEqual(KnightClass.forLevel(21), .swordsman)
        XCTAssertEqual(KnightClass.forLevel(40), .knight)
        XCTAssertEqual(KnightClass.forLevel(41), .crusader)
        XCTAssertEqual(KnightClass.forLevel(50), .crusader)
        XCTAssertEqual(KnightClass.forLevel(51), .champion)
        XCTAssertEqual(KnightClass.forLevel(999), .legend)
    }
}
