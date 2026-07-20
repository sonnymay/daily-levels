//
//  LevelMath.swift
//  Daily Levels
//
//  Pure functions for the core "5 minutes = 1 level" rule (SPEC §2).
//  No SwiftUI / SwiftData here on purpose — this is what the unit tests exercise.
//

import Foundation

enum LevelMath {
    /// SPEC §2: 5 minutes of focus = 1 level.
    static let minutesPerLevel = 5
    static let secondsPerLevel = minutesPerLevel * 60   // 300

    /// SPEC §2/§3: daily level caps at 100 = 500 min = 8h20m (Mythic). A perfect deep-work day.
    static let maxLevel = 100

    /// Daily level = floor(focusMinutes / 5), clamped to 0...maxLevel.
    static func level(forFocusMinutes minutes: Int) -> Int {
        min(maxLevel, max(0, minutes / minutesPerLevel))
    }

    /// Complete five-minute blocks earned across all focus time. Unlike the daily level,
    /// this does not cap at 100; callers may project it onto a finite journey separately.
    static func earnedLevels(forFocusSeconds seconds: Int) -> Int {
        max(0, seconds) / secondsPerLevel
    }

    /// Whole minutes accumulated *into* the current (unfinished) level: 0...4.
    static func minutesIntoLevel(_ minutes: Int) -> Int {
        ((minutes % minutesPerLevel) + minutesPerLevel) % minutesPerLevel
    }
}
