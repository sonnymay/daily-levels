//
//  HeroCollectionView.swift
//  Daily Levels
//
//  The Hero Collection — the conversion centerpiece. The daily class resets at
//  midnight, so most users never *see* the classes Pro unlocks. The collection fixes
//  that: it shows all ten heroes, fills steadily with cumulative "journey" progress
//  (FocusEngine.journeyLevel, which never resets), and reveals the Knight→Mythic art a
//  user has *earned but not yet owned* — the calm, fair moment to offer Pro.
//
//  Three states per hero:
//    • reached + free / reached + Pro-owned → shown in full ("Unlocked")
//    • reached + Pro-locked                 → shown with a soft veil + "Pro" (earned, tap to own)
//    • not yet reached                      → blurred silhouette + "Reach level N"
//

import SwiftUI

// MARK: - Entry row on the main screen

/// A calm one-screen entry point (SPEC §4 keeps it minimal): the current journey hero,
/// "X of 10 reached", tap to open the full collection. Shown to free *and* Pro users so
/// everyone sees the ladder they're climbing.
struct HeroJourneyRow: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let action: () -> Void

    var body: some View {
        let journeyLevel = engine.journeyLevel
        let nextClass = KnightClass.allCases.first { !$0.isReached(atJourneyLevel: journeyLevel) }
        return Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            HeroThumbnail(className: KnightClass.forLevel(journeyLevel).rawValue,
                                          size: 44,
                                          dimmed: false)
                            title
                            Spacer()
                            chevron
                        }
                        journeyStatus(level: journeyLevel, nextClass: nextClass)
                    }
                } else {
                    HStack(spacing: 12) {
                        HeroThumbnail(className: KnightClass.forLevel(journeyLevel).rawValue,
                                      size: 44,
                                      dimmed: false)
                        VStack(alignment: .leading, spacing: 2) {
                            title
                            journeyStatus(level: journeyLevel, nextClass: nextClass)
                        }
                        Spacer()
                        chevron
                    }
                }
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Hero Collection"))
        .accessibilityValue(Text("\(KnightClass.reachedCount(atJourneyLevel: journeyLevel)) of 10 heroes reached"))
        .accessibilityHint(Text("Opens your hero collection"))
    }

    private var title: some View {
        Text("Hero Collection")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.ink)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.gray)
    }

    @ViewBuilder
    private func journeyStatus(level: Int, nextClass: KnightClass?) -> some View {
        if let nextClass {
            Text("\(KnightClass.reachedCount(atJourneyLevel: level)) of 10 reached · Next: \(String(localized: nextClass.displayName)) at level \(nextClass.minLevel)")
                .font(.caption)
                .foregroundStyle(Theme.gray)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("All 10 heroes reached")
                .font(.caption)
                .foregroundStyle(Theme.gray)
        }
    }
}

// MARK: - Full-screen collection sheet

struct HeroCollectionSheet: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                SheetCloseRow { dismiss() }

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        HeroCollectionGrid { showPaywall = true }
                        if !store.isPro { unlockCTA }
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .presentationDragIndicator(.visible)
        .accessibilityAction(.escape) { dismiss() }
    }

    private var header: some View {
        let journeyLevel = engine.journeyLevel
        return VStack(alignment: .leading, spacing: 6) {
            Text("Hero Collection")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("Your journey: lifetime level \(journeyLevel) · \(String(localized: KnightClass.forLevel(journeyLevel).displayName))")
                .font(.callout)
                .foregroundStyle(Theme.gray)
            Text("\(KnightClass.reachedCount(atJourneyLevel: journeyLevel)) of 10 reached — keep focusing to climb.")
                .font(.footnote)
                .foregroundStyle(Theme.gray)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var unlockCTA: some View {
        Button { showPaywall = true } label: {
            Group {
                if let price = store.priceText {
                    Text("Unlock 7 more heroes · \(price)")
                } else {
                    Text("Unlock 7 more heroes")
                }
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.green, in: Capsule())
        }
        .buttonStyle(.pressable(scale: 0.97))
        .padding(.top, 4)
    }
}

// MARK: - The grid (reused by the sheet and the paywall)

struct HeroCollectionGrid: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(Store.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Called when a Pro-locked hero is tapped (opens the paywall). No-op when already on it.
    var onUnlock: () -> Void = {}

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        // Read the (cumulative) journey level once, not once per card.
        let journeyLevel = engine.journeyLevel
        let isPro = store.isPro
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(KnightClass.allCases, id: \.self) { knightClass in
                HeroClassCard(
                    knightClass: knightClass,
                    reached: knightClass.isReached(atJourneyLevel: journeyLevel),
                    proLocked: knightClass.isProOnly && !isPro,
                    onUnlock: onUnlock
                )
            }
        }
    }
}

// MARK: - One hero card

private struct HeroClassCard: View {
    let knightClass: KnightClass
    let reached: Bool
    let proLocked: Bool
    let onUnlock: () -> Void

    /// Earned-but-not-owned: the conversion moment (tap → paywall).
    private var unlockable: Bool { reached && proLocked }

    @ViewBuilder
    var body: some View {
        if unlockable {
            Button {
                Haptics.actionTap()
                onUnlock()
            } label: {
                cardContent
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
        } else {
            cardContent
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel)
        }
    }

    private var cardContent: some View {
        VStack(spacing: 8) {
            art
            Text(knightClass.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(reached ? Theme.ink : Theme.gray)
            caption
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var art: some View {
        HeroThumbnail(className: knightClass.rawValue,
                      size: 120,
                      dimmed: !reached,
                      blurred: !reached)
            .overlay(alignment: .topTrailing) {
                if proLocked {
                    Text("Pro")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.greenDeep, in: Capsule())
                        .padding(6)
                } else if reached {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Theme.greenDeep, .white)
                        .padding(6)
                }
            }
            .overlay {
                if !reached {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(radius: 2)
                }
            }
    }

    @ViewBuilder private var caption: some View {
        if !reached {
            Text("Reach level \(knightClass.minLevel)")
                .font(.caption2)
                .foregroundStyle(Theme.gray)
        } else if proLocked {
            Label("Tap to unlock", systemImage: "sparkles")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.greenDeep)
        } else {
            Text("Unlocked")
                .font(.caption2)
                .foregroundStyle(Theme.gray)
        }
    }

    private var accessibilityLabel: String {
        let name = String(localized: knightClass.displayName)
        if !reached { return String(localized: "\(name), locked. Reach level \(knightClass.minLevel).") }
        if proLocked { return String(localized: "\(name), earned. Tap to unlock with Pro.") }
        return String(localized: "\(name), unlocked.")
    }
}

// MARK: - Shared thumbnail

/// Per-class resting still, square-cropped and rounded. Falls back to a soft gradient
/// when a class has no art yet (so the collection never shows a broken tile).
struct HeroThumbnail: View {
    let className: String
    var size: CGFloat = 120
    var dimmed: Bool = false
    var blurred: Bool = false

    var body: some View {
        Group {
            if let ui = HeroSceneAsset.sleepImage(for: className) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Color(hex: 0x4A5D7E), Color(hex: 0x2E3A59)],
                               startPoint: .top, endPoint: .bottom)
                    .overlay(Image(systemName: "shield.fill")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(.white.opacity(0.5)))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .blur(radius: blurred ? 6 : 0)
        .overlay {
            if dimmed {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.black.opacity(0.4))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
