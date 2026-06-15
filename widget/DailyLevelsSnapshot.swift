//
//  DailyLevelsSnapshot.swift
//  Shared by the app AND the widget (add to BOTH targets' membership).
//
//  A tiny value the app writes after each meaningful change and the widget reads in its
//  TimelineProvider. Travels through the shared App Group container — no SwiftData sharing.
//  The App Group ID must be enabled on both targets and registered in the dev portal
//  before archiving (see ../WIDGET_SETUP.md).
//

import Foundation

struct DailyLevelsSnapshot: Codable {
    var level: Int
    var className: String      // already-localized display name, frozen at write time
    var todayMinutes: Int
    var streak: Int
    var date: Date             // start-of-day this snapshot describes (for midnight staleness)

    static let appGroup = "group.com.santipapmay.DailyLevels"
    private static let key = "todaySnapshot"

    /// Shown in the widget gallery and before the first real write.
    static var placeholder: DailyLevelsSnapshot {
        .init(level: 6, className: "Squire", todayMinutes: 32, streak: 4, date: Date())
    }

    static func load() -> DailyLevelsSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = defaults.data(forKey: key),
              let snap = try? JSONDecoder().decode(DailyLevelsSnapshot.self, from: data)
        else { return nil }
        return snap
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: Self.appGroup),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key)
    }

    /// True when this snapshot still describes the current local day. After midnight a stale
    /// snapshot should read as a fresh day (level 0), while the streak is kept until broken.
    func describesToday(_ calendar: Calendar = .current) -> Bool {
        calendar.isDateInToday(date)
    }
}
