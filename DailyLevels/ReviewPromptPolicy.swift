//
//  ReviewPromptPolicy.swift
//  Daily Levels
//
//  Pure policy for the app's deliberately rare review request.
//

import Foundation

enum ReviewPromptPolicy {
    static let minimumUsageDays = 3.0

    static func shouldRequest(classChanged: Bool,
                              firstLaunchAt: TimeInterval,
                              now: TimeInterval,
                              currentVersion: String,
                              lastReviewVersion: String) -> Bool {
        guard classChanged,
              firstLaunchAt > 0,
              now >= firstLaunchAt,
              !currentVersion.isEmpty,
              currentVersion != lastReviewVersion else {
            return false
        }
        return now - firstLaunchAt >= minimumUsageDays * 86_400
    }
}
