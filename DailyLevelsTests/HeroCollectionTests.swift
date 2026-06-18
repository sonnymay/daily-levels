//
//  HeroCollectionTests.swift
//  DailyLevelsTests
//
//  Boundary tests for the Hero Collection's progression + Pro gating. These guard the
//  promises the paywall makes: which heroes are "reached" at a given lifetime/journey
//  level, and which are Pro-gated. Pure — no engine, UI, or StoreKit.
//

import XCTest
@testable import DailyLevels

final class HeroCollectionTests: XCTestCase {

    func testEachClassMapsToTheBottomOfItsBand() {
        XCTAssertEqual(KnightClass.novice.minLevel, 0)
        XCTAssertEqual(KnightClass.squire.minLevel, 11)
        XCTAssertEqual(KnightClass.swordsman.minLevel, 21)
        XCTAssertEqual(KnightClass.knight.minLevel, 31)
        XCTAssertEqual(KnightClass.mythic.minLevel, 91)
    }

    func testMinLevelMatchesForLevelLadder() {
        // The collection's minLevel must agree with the daily class mapping at each boundary.
        for knightClass in KnightClass.allCases {
            XCTAssertEqual(KnightClass.forLevel(knightClass.minLevel), knightClass,
                           "\(knightClass.rawValue) minLevel \(knightClass.minLevel) should map back to itself")
        }
    }

    func testReachedIsInclusiveAtTheBandFloorAndExclusiveBelow() {
        XCTAssertFalse(KnightClass.knight.isReached(atJourneyLevel: 30))
        XCTAssertTrue(KnightClass.knight.isReached(atJourneyLevel: 31))
        XCTAssertTrue(KnightClass.knight.isReached(atJourneyLevel: 40))
    }

    func testNoviceIsAlwaysReachedAndMythicNeedsTheCap() {
        XCTAssertTrue(KnightClass.novice.isReached(atJourneyLevel: 0))
        XCTAssertFalse(KnightClass.mythic.isReached(atJourneyLevel: 90))
        XCTAssertTrue(KnightClass.mythic.isReached(atJourneyLevel: 91))
    }

    func testFreeCeilingIsSwordsmanAndProBeginsAtKnight() {
        XCTAssertFalse(KnightClass.novice.isProOnly)
        XCTAssertFalse(KnightClass.squire.isProOnly)
        XCTAssertFalse(KnightClass.swordsman.isProOnly)   // free ceiling
        XCTAssertTrue(KnightClass.knight.isProOnly)        // first paid hero
        XCTAssertTrue(KnightClass.mythic.isProOnly)
    }

    func testExactlySevenOfTenHeroesAreProGated() {
        let proCount = KnightClass.allCases.filter(\.isProOnly).count
        XCTAssertEqual(proCount, 7)   // Knight → Mythic; Novice/Squire/Swordsman are free
    }

    func testHeroesReachedCountClimbsWithJourneyLevel() {
        func reached(at level: Int) -> Int {
            KnightClass.allCases.filter { $0.isReached(atJourneyLevel: level) }.count
        }
        XCTAssertEqual(reached(at: 0), 1)    // Novice only
        XCTAssertEqual(reached(at: 30), 3)   // through Swordsman (the free set)
        XCTAssertEqual(reached(at: 31), 4)   // Knight earned
        XCTAssertEqual(reached(at: 100), 10) // all
    }
}
