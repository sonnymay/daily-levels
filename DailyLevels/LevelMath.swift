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

    /// Daily level = floor(focusMinutes / 5).
    static func level(forFocusMinutes minutes: Int) -> Int {
        max(0, minutes / minutesPerLevel)
    }

    /// Whole minutes accumulated *into* the current (unfinished) level: 0...4.
    static func minutesIntoLevel(_ minutes: Int) -> Int {
        ((minutes % minutesPerLevel) + minutesPerLevel) % minutesPerLevel
    }
}
