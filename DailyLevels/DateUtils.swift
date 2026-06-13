//
//  DateUtils.swift
//  Daily Levels
//
//  Midnight-split logic (SPEC §5 edge case 1). Pure + calendar-injectable so
//  unit tests can pin a fixed timezone and avoid flakiness.
//

import Foundation

enum DateUtils {

    /// Split a grinding interval [start, end] into one segment per local calendar day,
    /// cutting at midnight. Each returned segment belongs entirely to a single day, so
    /// each day gets its own minutes (SPEC §5: "split into two sessions at 12:00 AM").
    ///
    /// Returns [] for empty/negative intervals. Uses `calendar.date(byAdding: .day)`
    /// for the boundary so DST day-length changes stay correct.
    static func splitAtMidnights(start: Date,
                                 end: Date,
                                 calendar: Calendar = .current) -> [(start: Date, end: Date)] {
        guard end > start else { return [] }

        var segments: [(start: Date, end: Date)] = []
        var segStart = start

        while segStart < end {
            let dayStart = calendar.startOfDay(for: segStart)
            // Next midnight = start of the following day.
            guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                segments.append((segStart, end))
                break
            }
            if end <= nextMidnight {
                segments.append((segStart, end))
                break
            } else {
                segments.append((segStart, nextMidnight))
                segStart = nextMidnight
            }
        }
        return segments
    }
}
