//
//  PressableButtonStyle.swift
//  Daily Levels
//
//  A calm, tactile press style. `.buttonStyle(.plain)` gives no press feedback at all,
//  which makes taps feel dead; this dips the control slightly and dims it on touch-down,
//  then springs back on release. Honors Reduce Motion (drops the scale, keeps a soft dim).
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? scale : 1))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.62),
                       value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    /// Tactile press feedback for the app's buttons (replaces `.plain`, which has none).
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    static func pressable(scale: CGFloat) -> PressableButtonStyle { PressableButtonStyle(scale: scale) }
}
