//
//  Models.swift
//  Daily Levels
//
//  Persistence model (SPEC §5). SwiftData stores only completed *grinding* segments.
//  Sleeping time is never written, so summing durations is always "focus time".
//

import Foundation
import SwiftData

/// One contiguous grinding segment, already split so it lives within a single local day.
/// `@Model` is SwiftData's persistence macro — think of it like a Core Data entity / an
/// ORM row. Instances inserted into a ModelContext are saved to a local SQLite store.
@Model
final class FocusSession {
    var id: UUID
    var startAt: Date
    var endAt: Date
    var durationSeconds: Int   // grinding seconds only (== endAt - startAt for a segment)

    init(id: UUID = UUID(), startAt: Date, endAt: Date, durationSeconds: Int) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.durationSeconds = durationSeconds
    }
}

/// Derived, in-memory summary for one day (SPEC §5 "DailySummary (derived or cached)").
/// Not persisted — recomputed from FocusSessions on demand.
struct DaySummary: Identifiable, Hashable {
    let date: Date          // startOfDay (local)
    let focusMinutes: Int

    var id: Date { date }
    var level: Int { LevelMath.level(forFocusMinutes: focusMinutes) }
    var knightClass: KnightClass { KnightClass.forLevel(level) }
}
