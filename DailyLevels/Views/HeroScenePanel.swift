//
//  HeroScenePanel.swift
//  Daily Levels
//
//  The rounded hero scene card (SPEC §4 item 3). Two states: grinding / sleeping.
//  Asset resolution order (all native, drop-in):
//    1. Looping video
//         grinding → "<class>_grind.mp4"  (e.g. novice_grind.mp4 … mythic_grind.mp4)
//         sleeping → "sleep_loop.mp4"     (single shared resting clip, optional)
//    2. Static image  "HeroGrinding" / "HeroSleeping"  (Assets.xcassets)
//    3. Built-in styled placeholder
//

import SwiftUI

struct HeroScenePanel: View {
    let grinding: Bool
    /// Current daily class name (e.g. "Novice"). Drives which grinding clip plays so the
    /// hero's gear visually matches the class. Lowercased to match the bundled filenames.
    let className: String

    private let height: CGFloat = 232
    private let corner: CGFloat = 22

    var body: some View {
        ZStack {
            if let url = videoURL {
                // `.id(url)` forces SwiftUI to rebuild the player view when the class clip
                // changes (e.g. Novice → Squire), so the new video actually swaps in.
                LoopingVideoView(url: url).id(url)
            } else if let name = imageName {
                Image(name).resizable().scaledToFill()
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
    }

    private var videoURL: URL? {
        let resource = grinding ? "\(className.lowercased())_grind" : "sleep_loop"
        return Bundle.main.url(forResource: resource, withExtension: "mp4")
    }

    private var imageName: String? {
        let name = grinding ? "HeroGrinding" : "HeroSleeping"
        return UIImage(named: name) != nil ? name : nil
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
                Text(grinding ? "Grinding…" : "Resting by the campfire")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .shadow(radius: 2, y: 1)
        }
    }
}
