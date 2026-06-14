//
//  KnightClass.swift
//  Daily Levels
//
//  Daily class ladder (SPEC §3). A *label only* — no stats, no abilities.
//  Derived from TODAY's level; resets at midnight with the level.
//  Ten bands of 10 levels each, topping out at Mythic (level 91–100).
//

import Foundation

// NOTE: `rawValue` is load-bearing and must stay English — it builds asset filenames
// ("<class>_grind.mp4", "<class>_sleep.png") and drives Pro gating. Never localize it.
// User-facing text uses `displayName` (localized) instead.
enum KnightClass: String, CaseIterable {
    case novice    = "Novice"     // level 0–10   (up to 50 min)
    case squire    = "Squire"     // level 11–20  (~1–1.7 hrs)
    case swordsman = "Swordsman"  // level 21–30  (~1.7–2.5 hrs)
    case knight    = "Knight"     // level 31–40  (~2.6–3.3 hrs)
    case crusader  = "Crusader"   // level 41–50  (~3.4–4.2 hrs)
    case champion  = "Champion"   // level 51–60  (~4.2–5 hrs)
    case paladin   = "Paladin"    // level 61–70  (~5–5.8 hrs)
    case hero      = "Hero"       // level 71–80  (~5.9–6.7 hrs)
    case legend    = "Legend"     // level 81–90  (~6.8–7.5 hrs)
    case mythic    = "Mythic"     // level 91–100 (~7.6–8.3 hrs, the daily cap)

    /// Map a daily level to its class. Boundaries are inclusive on the upper end
    /// of each band (e.g. level 10 = Novice, level 11 = Squire).
    static func forLevel(_ level: Int) -> KnightClass {
        // Swift note: `switch` on ranges; `..<11` means "anything below 11".
        switch level {
        case ..<11: return .novice
        case ..<21: return .squire
        case ..<31: return .swordsman
        case ..<41: return .knight
        case ..<51: return .crusader
        case ..<61: return .champion
        case ..<71: return .paladin
        case ..<81: return .hero
        case ..<91: return .legend
        default:    return .mythic   // 91+ (level is capped at 100, see LevelMath)
        }
    }

    /// Localized, user-facing class name. Distinct from `rawValue` (which stays English for
    /// asset filenames + gating). `LocalizedStringResource` works in both SwiftUI `Text(...)`
    /// and `String(localized:)` (notifications), so every surface localizes from one source.
    var displayName: LocalizedStringResource {
        switch self {
        case .novice:    return LocalizedStringResource("Novice",    comment: "Knight class name")
        case .squire:    return LocalizedStringResource("Squire",    comment: "Knight class name")
        case .swordsman: return LocalizedStringResource("Swordsman", comment: "Knight class name")
        case .knight:    return LocalizedStringResource("Knight",    comment: "Knight class name")
        case .crusader:  return LocalizedStringResource("Crusader",  comment: "Knight class name")
        case .champion:  return LocalizedStringResource("Champion",  comment: "Knight class name")
        case .paladin:   return LocalizedStringResource("Paladin",   comment: "Knight class name")
        case .hero:      return LocalizedStringResource("Hero",      comment: "Knight class name")
        case .legend:    return LocalizedStringResource("Legend",    comment: "Knight class name")
        case .mythic:    return LocalizedStringResource("Mythic",    comment: "Knight class name")
        }
    }
}
