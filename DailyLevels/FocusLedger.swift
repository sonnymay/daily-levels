//
//  FocusLedger.swift
//  Daily Levels
//
//  Pure aggregation for completed focus time. Keeping this out of FocusEngine
//  lets trust-sensitive date math be unit-tested without SwiftData or UI state.
//

import Foundation

struct FocusSegment: Equatable {
    let startAt: Date
    let durationSeconds: Int
}

enum FocusLedger {
    static func secondsByDay(segments: [FocusSegment],
                             calendar: Calendar = .current) -> [Date: Int] {
        var secondsByDay: [Date: Int] = [:]
        for segment in segments where segment.durationSeconds > 0 {
            let day = calendar.startOfDay(for: segment.startAt)
            secondsByDay[day, default: 0] += segment.durationSeconds
        }
        return secondsByDay
    }
}
