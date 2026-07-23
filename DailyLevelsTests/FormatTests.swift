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

    func testSpokenDurationClampsNegativeTimeToZero() {
        XCTAssertEqual(Format.spokenDuration(-1, locale: english), "0 seconds")
        XCTAssertEqual(Format.spokenDuration(0, locale: english), "0 seconds")
    }

    func testSpokenDurationNamesMinutesAndSeconds() {
        XCTAssertEqual(Format.spokenDuration(5, locale: english), "5 seconds")
        XCTAssertEqual(Format.spokenDuration(65, locale: english), "1 minute, 5 seconds")
    }

    func testSpokenDurationNamesHoursWithoutEmptyUnits() {
        XCTAssertEqual(Format.spokenDuration(3_600, locale: english), "1 hour")
        XCTAssertEqual(
            Format.spokenDuration(3_661, locale: english),
            "1 hour, 1 minute, 1 second"
        )
    }

    private var english: Locale {
        Locale(identifier: "en_US")
    }
}
