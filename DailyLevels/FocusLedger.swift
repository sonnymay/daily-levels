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
        for interval in mergedIntervals(from: segments) {
            for slice in DateUtils.splitAtMidnights(
                start: interval.start,
                end: interval.end,
                calendar: calendar
            ) {
                let day = calendar.startOfDay(for: slice.start)
                let seconds = Int(slice.end.timeIntervalSince(slice.start).rounded())
                secondsByDay[day, default: 0] += seconds
            }
        }
        return secondsByDay
    }

    /// SwiftData recovery is designed to be idempotent, but treating persisted intervals as a
    /// union makes the ledger resilient to duplicate or partially overlapping legacy rows too.
    private static func mergedIntervals(from segments: [FocusSegment]) -> [DateInterval] {
        let sorted = segments.compactMap { segment -> DateInterval? in
            guard segment.durationSeconds > 0 else { return nil }
            return DateInterval(
                start: segment.startAt,
                duration: TimeInterval(segment.durationSeconds)
            )
        }.sorted { lhs, rhs in
            lhs.start == rhs.start ? lhs.end < rhs.end : lhs.start < rhs.start
        }

        guard var current = sorted.first else { return [] }
        var merged: [DateInterval] = []
        for interval in sorted.dropFirst() {
            if interval.start <= current.end {
                current = DateInterval(start: current.start, end: max(current.end, interval.end))
            } else {
                merged.append(current)
                current = interval
            }
        }
        merged.append(current)
        return merged
    }
}
