//
//  HistoryMath.swift
//  Daily Levels
//
//  Small, deterministic history calculations kept separate from SwiftUI and SwiftData.
//

import Foundation

enum HistoryMath {
    /// Returns the focused day with the most minutes. A same-minute tie favors the
    /// latest day so the highlight reflects the user's most recent achievement.
    static func personalBest(from days: [DaySummary]) -> DaySummary? {
        days
            .filter { $0.focusMinutes > 0 }
            .max { lhs, rhs in
                if lhs.focusMinutes == rhs.focusMinutes {
                    return lhs.date < rhs.date
                }
                return lhs.focusMinutes < rhs.focusMinutes
            }
    }
}
