//
//  FormatTests.swift
//  DailyLevelsTests
//
//  Boundary coverage for the session clock shown while focusing and paused.
//

import XCTest
@testable import DailyLevels

final class FormatTests: XCTestCase {

    func testClockClampsNegativeTimeToZero() {
        XCTAssertEqual(Format.clock(-1), "0:00")
        XCTAssertEqual(Format.clock(0), "0:00")
    }

    func testClockFormatsMinutesAndSeconds() {
        XCTAssertEqual(Format.clock(5), "0:05")
        XCTAssertEqual(Format.clock(59), "0:59")
        XCTAssertEqual(Format.clock(60), "1:00")
        XCTAssertEqual(Format.clock(3_599), "59:59")
    }

    func testClockAddsHoursWithoutDroppingLeadingZeroes() {
        XCTAssertEqual(Format.clock(3_600), "1:00:00")
        XCTAssertEqual(Format.clock(3_661), "1:01:01")
        XCTAssertEqual(Format.clock(36_000), "10:00:00")
    }
}
