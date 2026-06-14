//
//  Haptics.swift
//  Daily Levels
//
//  Tiny tactile cues for the few moments that matter: button taps, level ups,
//  and class changes. No settings surface; keep them subtle.
//

import UIKit

@MainActor
enum Haptics {
    static func actionTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.55)
    }

    static func progressMilestone(classChanged: Bool) {
        if classChanged {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
        }
    }
}
