//
//  LevelMathTests.swift
//  DailyLevelsTests
//
//  SPEC §2: level = floor(focusMinutes / 5). Examples from the spec are asserted directly.
//

import XCTest
@testable import DailyLevels

final class LevelMathTests: XCTestCase {

    func testSpecExamples() {
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 20), 4)   // 20 min = Level 4
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 25), 5)   // 25 min = Level 5
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 60), 12)  // 60 min = Level 12
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 65), 13)  // 65 min = Level 13
    }

    func testFloorBehaviorAroundBoundaries() {
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 0), 0)
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 4), 0)
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 5), 1)
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 9), 1)
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 10), 2)
    }

    func testNegativeMinutesClampToZero() {
        XCTAssertEqual(LevelMath.level(forFocusMinutes: -3), 0)
    }

    func testLevelCapsAt100() {
        // 500 min = 8h20m = the daily cap.
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 495), 99)
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 500), 100)
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 505), 100)   // never exceeds 100
        XCTAssertEqual(LevelMath.level(forFocusMinutes: 5000), 100)
    }

    func testMinutesIntoLevel() {
        XCTAssertEqual(LevelMath.minutesIntoLevel(0), 0)
        XCTAssertEqual(LevelMath.minutesIntoLevel(3), 3)
        XCTAssertEqual(LevelMath.minutesIntoLevel(5), 0)
        XCTAssertEqual(LevelMath.minutesIntoLevel(22), 2)
    }
}
