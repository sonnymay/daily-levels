//
//  Theme.swift
//  Daily Levels
//
//  Light cream palette per the mockup (SPEC §4: light, minimal, iOS-native — NOT dark/gamer).
//

import SwiftUI

enum Theme {
    static let cream     = Color(hex: 0xF3F0E8)   // app background
    static let card      = Color(hex: 0xFBFAF5)   // history card surface
    static let ink       = Color(hex: 0x1B1B1D)   // primary text
    static let gray      = Color(hex: 0x8A8A8E)   // secondary text
    static let green     = Color(hex: 0x5E8C3E)   // button + accent
    static let greenDeep = Color(hex: 0x4C7A33)   // filled progress + "Today" bar
    static let greenSoft = Color(hex: 0xC3DBA4)   // past-day bars
    static let track     = Color(hex: 0xE4E1D8)   // progress bar track
    static let badgeBg   = Color(hex: 0xE7E4DB)   // class badge pill
    static let hairline  = Color(hex: 0xE8E5DC)   // list dividers
}

extension Color {
    /// Build a Color from a 0xRRGGBB literal — handy for matching a mockup exactly.
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
