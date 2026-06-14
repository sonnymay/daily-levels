//
//  FocusNotifications.swift
//  Daily Levels
//
//  Local "you leveled up" pings so the payoff lands even when the phone is
//  locked and the app is suspended (the core grinding-while-locked moment).
//
//  How it works: while the app is suspended no code runs, so we can't react to
//  a level-up in real time. Instead, the moment grinding (re)starts we *schedule*
//  one notification per upcoming level boundary using the level math — each fires
//  at its absolute time regardless of app state. Pausing cancels them.
//
//  No settings surface; no Info.plist key needed (local notifications use the
//  system authorization prompt). Foreground level-ups are handled by the in-app
//  celebration chip, so these are effectively the locked/background channel.
//

import UserNotifications

@MainActor
enum FocusNotifications {
    private static let idPrefix = "levelup-"
    /// Stay comfortably under iOS's 64 pending-request ceiling.
    private static let maxToSchedule = 60

    /// Ask once, the first time the user starts focusing. No-op if already decided.
    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    /// Schedule a ping for every upcoming level boundary in the active session,
    /// starting from `currentSeconds` (today's focus seconds when grinding (re)starts)
    /// up to the daily cap. Assumes uninterrupted grinding; pausing re-cancels.
    static func scheduleLevelUps(currentSeconds: Int) {
        cancelLevelUps()
        let center = UNUserNotificationCenter.current()
        let currentLevel = currentSeconds / LevelMath.secondsPerLevel
        guard currentLevel < LevelMath.maxLevel else { return }

        var scheduled = 0
        for level in (currentLevel + 1)...LevelMath.maxLevel {
            let fireIn = Double(level * LevelMath.secondsPerLevel - currentSeconds)
            guard fireIn > 0 else { continue }

            let cls = KnightClass.forLevel(level)
            let classChanged = cls != KnightClass.forLevel(level - 1)

            let content = UNMutableNotificationContent()
            content.title = classChanged ? "\(cls.rawValue) reached" : "Level \(level) reached"
            content.body = classChanged
                ? "New class unlocked — keep grinding!"
                : "You're at level \(level). Keep going."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireIn, repeats: false)
            let request = UNNotificationRequest(identifier: "\(idPrefix)\(level)",
                                                content: content,
                                                trigger: trigger)
            center.add(request)

            scheduled += 1
            if scheduled >= maxToSchedule { break }
        }
    }

    /// Remove any pending level-up pings (called on pause / app-switch).
    static func cancelLevelUps() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
