//
//  HeroScenePanel.swift
//  Daily Levels
//
//  The rounded hero scene card (SPEC §4 item 3). Two states: grinding / sleeping.
//  Asset resolution order (all native, drop-in):
//    1. Looping video
//         grinding → "<class>_grind.mp4"  (e.g. novice_grind.mp4 … mythic_grind.mp4)
//    2. Static image
//         sleeping → "<class>_sleep.png"  (e.g. novice_sleep.png … mythic_sleep.png)
//         fallback → "HeroGrinding" / "HeroSleeping"  (Assets.xcassets)
//    3. Built-in styled placeholder
//

import SwiftUI

enum HeroSceneAsset {
    static func resourceName(grinding: Bool, className: String) -> String {
        "\(className.lowercased())_\(grinding ? "grind" : "sleep")"
    }

    /// The per-class resting still, for off-screen rendering (e.g. the share card).
    /// `className` is the English `rawValue` (asset key). Falls back to the bundled "HeroSleeping".
    static func sleepImage(for className: String) -> UIImage? {
        let name = resourceName(grinding: false, className: className)
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return UIImage(named: "HeroSleeping")
    }
}

struct HeroScenePanel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let grinding: Bool
    /// Current daily class name (e.g. "Novice"). Drives which grinding clip plays so the
    /// hero's gear visually matches the class. Lowercased to match the bundled filenames.
    let className: String
    /// When true the real class is Pro-gated: art is capped at the free ceiling and a
    /// subtle "Unlock Pro" overlay invites the purchase. Defaults to unlocked.
    var locked: Bool = false
    /// Localized name of the *displayed* class (matches the capped art when locked) — used
    /// only for the VoiceOver label. `className` (English rawValue) still resolves assets.
    var displayName: LocalizedStringResource

    private let height: CGFloat = 232
    private let corner: CGFloat = 22

    var body: some View {
        ZStack {
            if let url = videoURL {
                // `.id(url)` forces SwiftUI to rebuild the player view when the class clip
                // changes (e.g. Novice → Squire), so the new video actually swaps in.
                LoopingVideoView(url: url, isPlaying: !reduceMotion).id(url)
            } else if let image = stillImage {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(.black.opacity(0.05), lineWidth: 1)
        )
        .overlay(alignment: .bottom) {
            if locked {
                Label("Unlock Pro to evolve", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(.bottom, 12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let cls = String(localized: displayName)
        if locked { return String(localized: "Hero locked. Unlock Pro to evolve past \(cls).") }
        return grinding
            ? String(localized: "\(cls) hero, grinding")
            : String(localized: "\(cls) hero, resting")
    }

    private var videoURL: URL? {
        guard grinding else { return nil }
        let resource = HeroSceneAsset.resourceName(grinding: true, className: className)
        return Bundle.main.url(forResource: resource, withExtension: "mp4")
    }

    private var stillImage: UIImage? {
        if !grinding {
            let classSleepName = HeroSceneAsset.resourceName(grinding: false, className: className)
            if let url = Bundle.main.url(forResource: classSleepName, withExtension: "png"),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        let name = grinding ? "HeroGrinding" : "HeroSleeping"
        return UIImage(named: name)
    }

    // Placeholder shown when no class clip/image is present (e.g. a class you haven't made yet).
    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: grinding
                    ? [Color(hex: 0x8FC1E8), Color(hex: 0xA9D38C), Color(hex: 0x7DB060)]
                    : [Color(hex: 0x2E3A59), Color(hex: 0x4A5D7E), Color(hex: 0x6B5B73)],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 10) {
                Image(systemName: grinding ? "figure.fencing" : "moon.zzz.fill")
                    .font(.system(size: 48, weight: .semibold))
                Text(grinding ? LocalizedStringKey("Grinding…") : LocalizedStringKey("Resting by the campfire"))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .shadow(radius: 2, y: 1)
        }
    }
}
