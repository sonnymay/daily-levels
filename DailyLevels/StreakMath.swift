//
//  StreakMath.swift
//  Daily Levels
//
//  Pure streak logic (no SwiftUI / SwiftData) so the unit tests can pin a fixed
//  timezone. A "streak" here is calm by design: it counts consecutive days that
//  reached at least Level 1, and an *unstarted today* never reads as broken — so the
//  number rewards the habit without the anxiety of a countdown you can lose by lunch.
//

import Foundation

enum StreakMath {
    /// A day counts toward the streak once it reaches Level 1 (5+ minutes of focus).
    static func dayReached(seconds: Int) -> Bool { seconds >= LevelMath.secondsPerLevel }

    /// Consecutive qualifying days ending today — or ending yesterday when today is still
    /// empty (today is "open", not "broken"). 0 when neither today nor yesterday qualifies.
    static func currentStreak(secondsByDay: [Date: Int],
                              today: Date,
                              calendar: Calendar = .current) -> Int {
        func reached(_ day: Date) -> Bool {
            dayReached(seconds: secondsByDay[calendar.startOfDay(for: day)] ?? 0)
        }
        var cursor = calendar.startOfDay(for: today)
        // Today not started yet → the run can still be alive ending yesterday.
        if !reached(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while reached(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
