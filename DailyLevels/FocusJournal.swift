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

private struct LossyPendingFocusRecord: Decodable {
    let record: PendingFocusRecord?

    init(from decoder: Decoder) {
        guard let payload = try? Payload(from: decoder),
              let seconds = DateUtils.wholeSeconds(start: payload.startAt, end: payload.endAt)
        else {
            record = nil
            return
        }
        record = PendingFocusRecord(
            id: payload.id,
            startAt: payload.startAt,
            endAt: payload.endAt,
            durationSeconds: seconds
        )
    }

    private struct Payload: Decodable {
        let id: UUID
        let startAt: Date
        let endAt: Date
    }
}

private extension PendingFocusRecord {
    var normalized: PendingFocusRecord? {
        guard let seconds = DateUtils.wholeSeconds(start: startAt, end: endAt) else {
            return nil
        }
        return PendingFocusRecord(
            id: id,
            startAt: startAt,
            endAt: endAt,
            durationSeconds: seconds
        )
    }
}

enum FocusJournal {
    static let key = "engine.pendingFocusRecords"

    static func records(start: Date,
                        end: Date,
                        calendar: Calendar = .current,
                        makeID: () -> UUID = UUID.init) -> [PendingFocusRecord] {
        DateUtils.splitAtMidnights(start: start, end: end, calendar: calendar).compactMap { slice in
            guard let seconds = DateUtils.wholeSeconds(start: slice.start, end: slice.end) else {
                return nil
            }
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
              let decoded = try? JSONDecoder().decode([LossyPendingFocusRecord].self, from: data)
        else { return [] }

        var ids = Set<UUID>()
        return decoded.compactMap { item in
            guard let record = item.record,
                  ids.insert(record.id).inserted
            else { return nil }
            return record
        }
    }

    static func append(_ newRecords: [PendingFocusRecord],
                       defaults: UserDefaults = .standard) {
        let normalizedRecords = newRecords.compactMap(\.normalized)
        guard !normalizedRecords.isEmpty else { return }
        var records = load(defaults: defaults)
        var ids = Set(records.map(\.id))
        records.append(contentsOf: normalizedRecords.filter { ids.insert($0.id).inserted })
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
