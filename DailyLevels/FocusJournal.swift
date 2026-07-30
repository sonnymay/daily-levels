//
//  FocusJournal.swift
//  Daily Levels
//
//  A tiny durable journal for completed focus slices awaiting a successful SwiftData save.
//  It protects earned progress from transient local-store failures without adding a backend.
//

import Foundation

struct PendingFocusRecord: Codable, Equatable, Hashable {
    let id: UUID
    let startAt: Date
    let endAt: Date
    let durationSeconds: Int
}

enum FocusJournal {
    static let key = "engine.pendingFocusRecords"

    static func records(start: Date,
                        end: Date,
                        calendar: Calendar = .current,
                        makeID: () -> UUID = UUID.init) -> [PendingFocusRecord] {
        DateUtils.splitAtMidnights(start: start, end: end, calendar: calendar).compactMap { slice in
            let seconds = Int(slice.end.timeIntervalSince(slice.start))
            guard seconds > 0 else { return nil }
            return PendingFocusRecord(
                id: makeID(),
                startAt: slice.start,
                endAt: slice.end,
                durationSeconds: seconds
            )
        }
    }

    static func load(defaults: UserDefaults = .standard) -> [PendingFocusRecord] {
        guard let data = defaults.data(forKey: key),
              let records = try? JSONDecoder().decode([PendingFocusRecord].self, from: data)
        else { return [] }
        return records.filter { $0.durationSeconds > 0 && $0.endAt > $0.startAt }
    }

    static func append(_ newRecords: [PendingFocusRecord],
                       defaults: UserDefaults = .standard) {
        guard !newRecords.isEmpty else { return }
        var records = load(defaults: defaults)
        var ids = Set(records.map(\.id))
        records.append(contentsOf: newRecords.filter { ids.insert($0.id).inserted })
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
