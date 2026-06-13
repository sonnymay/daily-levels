//
//  KnightClass.swift
//  Daily Levels
//
//  Daily class ladder (SPEC §3). A *label only* — no stats, no abilities.
//  Derived from TODAY's level; resets at midnight with the level.
//

import Foundation

enum KnightClass: String, CaseIterable {
    case novice    = "Novice"     // level 0–10
    case squire    = "Squire"     // level 11–20
    case swordsman = "Swordsman"  // level 21–30
    case knight    = "Knight"     // level 31–40
    case crusader  = "Crusader"   // level 41–50
    case champion  = "Champion"   // level 51–60
    case legend    = "Legend"     // level 61+

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
        default:    return .legend
        }
    }
}
