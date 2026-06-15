//
//  ShareCardView.swift
//  Daily Levels
//
//  A square, brand-styled card rendered OFF-SCREEN by ImageRenderer and shared via
//  ShareLink — the organic-growth hook (Reddit / StudyTok / iMessage). It takes no
//  @Environment (it's rendered detached from the view hierarchy), so every value is
//  passed in as a plain `let`. Reuses the same localized keys as the main UI.
//

import SwiftUI

struct ShareCardView: View {
    let level: Int
    let classDisplayName: LocalizedStringResource
    let todayMinutes: Int
    let heroImage: UIImage?
    var streak: Int = 0        // shown only at 2+ — a braggable, shareable habit
    var side: CGFloat = 1080   // 1080×1080 — clean on every social surface

    var body: some View {
        ZStack {
            Theme.cream
            VStack(spacing: 30) {
                Spacer(minLength: 0)

                if let heroImage {
                    Image(uiImage: heroImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: side * 0.60, height: side * 0.60)
                        .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 44, style: .continuous)
                                .strokeBorder(.black.opacity(0.06), lineWidth: 1)
                        )
                }

                VStack(spacing: 10) {
                    Text(classDisplayName)
                        .font(.system(size: 78, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Level \(level)")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(Theme.greenDeep)
                    Text("\(todayMinutes) min focused today")
                        .font(.system(size: 38))
                        .foregroundStyle(Theme.gray)

                    if streak >= 2 {
                        Label("\(streak)-day focus streak", systemImage: "flame.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Theme.greenDeep)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 11)
                            .background(Theme.greenSoft.opacity(0.4), in: Capsule())
                            .padding(.top, 6)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Theme.green)
                    Text(verbatim: "Daily Levels")   // brand wordmark — never localized
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Theme.gray)
                }
            }
            .padding(72)
            .multilineTextAlignment(.center)
        }
        .frame(width: side, height: side)
    }
}
