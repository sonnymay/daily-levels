//
//  DateUtils.swift
//  Daily Levels
//
//  Midnight-split logic (SPEC §5 edge case 1). Pure + calendar-injectable so
//  unit tests can pin a fixed timezone and avoid flakiness.
//

import Foundation

enum DateUtils {

    /// Whole elapsed seconds for a valid forward-or-equal wall-clock interval. A legitimate
    /// sub-second interval returns zero; unsafe timestamps and unrepresentable durations fail.
    static func nonnegativeWholeSeconds(start: Date, end: Date) -> Int? {
        guard start.timeIntervalSinceReferenceDate.isFinite,
              end.timeIntervalSinceReferenceDate.isFinite,
              end >= start
        else { return nil }
        let elapsed = end.timeIntervalSince(start)
        guard elapsed.isFinite,
              elapsed >= 0,
              elapsed < TimeInterval(Int.max)
        else { return nil }
        return Int(elapsed)
    }

    /// Whole earned seconds in a positive interval. Sub-second, empty, reversed,
    /// non-finite, and integer-out-of-range intervals do not create focus records.
    static func wholeSeconds(start: Date, end: Date) -> Int? {
        guard let elapsed = nonnegativeWholeSeconds(start: start, end: end),
              elapsed >= 1 else { return nil }
        return elapsed
    }

    /// Split a grinding interval [start, end] into one segment per local calendar day,
    /// cutting at midnight. Each returned segment belongs entirely to a single day, so
    /// each day gets its own minutes (SPEC §5: "split into two sessions at 12:00 AM").
    ///
    /// Returns [] for empty, negative, or non-finite intervals. Uses
    /// `calendar.date(byAdding: .day)` for the boundary so DST day lengths stay correct.
    static func splitAtMidnights(start: Date,
                                 end: Date,
                                 calendar: Calendar = .current) -> [(start: Date, end: Date)] {
        guard start.timeIntervalSinceReferenceDate.isFinite,
              end.timeIntervalSinceReferenceDate.isFinite,
              end > start
        else { return [] }

        var segments: [(start: Date, end: Date)] = []
        var segStart = start

        while segStart < end {
            let dayStart = calendar.startOfDay(for: segStart)
            // Next midnight = start of the following day.
            guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: dayStart),
                  nextMidnight > segStart
            else {
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
