//
//  HistoryMath.swift
//  Daily Levels
//
//  Small, deterministic history calculations kept separate from SwiftUI and SwiftData.
//

import Foundation

struct FocusHistorySnapshot: Equatable {
    let personalBest: DaySummary?
    let weekHistory: [DaySummary]
    let recentDays: [DaySummary]
}

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

    /// Builds every history-card projection from one completed-plus-live ledger.
    static func snapshot(secondsByDay: [Date: Int],
                         referenceDate: Date,
                         calendar: Calendar) -> FocusHistorySnapshot {
        let today = calendar.startOfDay(for: referenceDate)
        let weekHistory = (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return DaySummary(date: day, focusMinutes: (secondsByDay[day] ?? 0) / 60)
        }
        let recentDayKeys = secondsByDay.keys.filter {
            $0 < today && (secondsByDay[$0] ?? 0) >= 60
        } + [today]
        let recentDays = Set(recentDayKeys).sorted(by: >).map {
            DaySummary(date: $0, focusMinutes: (secondsByDay[$0] ?? 0) / 60)
        }
        let allDays = secondsByDay.map {
            DaySummary(date: $0.key, focusMinutes: $0.value / 60)
        }

        return FocusHistorySnapshot(
            personalBest: personalBest(from: allDays),
            weekHistory: weekHistory,
            recentDays: recentDays
        )
    }
}
