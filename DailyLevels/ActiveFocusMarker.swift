//
//  ActiveFocusMarker.swift
//  Daily Levels
//
//  One durable payload for the active checkpoint and its lock confirmation.
//

import Foundation

struct ActiveFocusMarker: Codable, Equatable {
    let startAt: Date
    let isLocked: Bool
}

enum ActiveFocusMarkerStore {
    static let key = "engine.activeMarker.v1"
    static let legacyStartKey = "engine.activeStart"
    static let legacyLockedKey = "engine.activeWasLocked"

    static func load(defaults: UserDefaults = .standard) -> ActiveFocusMarker? {
        if let data = defaults.data(forKey: key),
           let marker = try? JSONDecoder().decode(ActiveFocusMarker.self, from: data) {
            return marker
        }

        guard let startAt = defaults.object(forKey: legacyStartKey) as? Date else {
            return nil
        }
        let marker = ActiveFocusMarker(
            startAt: startAt,
            isLocked: defaults.bool(forKey: legacyLockedKey)
        )
        save(marker, defaults: defaults)
        return marker
    }

    static func save(_ marker: ActiveFocusMarker, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(marker) else { return }
        defaults.set(data, forKey: key)
        defaults.removeObject(forKey: legacyStartKey)
        defaults.removeObject(forKey: legacyLockedKey)
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: legacyStartKey)
        defaults.removeObject(forKey: legacyLockedKey)
    }
}
