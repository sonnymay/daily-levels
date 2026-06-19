//
//  MainView.swift
//  Daily Levels
//
//  The single screen (SPEC §4). No tabs, no settings, no other screens.
//

import SwiftUI
import StoreKit   // \.requestReview

struct MainView: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(Store.self) private var store
    @State private var levelPulse = 0
    @State private var classPulse = 0
    @State private var celebration: LevelCelebration?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.requestReview) private var requestReview
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @AppStorage("firstLaunchAt") private var firstLaunchAt = 0.0
    @AppStorage("lastReviewVersion") private var lastReviewVersion = ""
    @AppStorage("swordsmanPaywallShown") private var swordsmanPaywallShown = false
    @State private var showIntro = false
    @State private var showPaywall = false
    @State private var showIconPicker = false
    @State private var showCollection = false
    @State private var milestone: Milestone?

    /// Hero art is gated past the free ceiling until Pro is unlocked.
    private var heroLocked: Bool { !store.isPro && engine.knightClass.isProOnly }
    private var heroArtClass: KnightClass { heroLocked ? KnightClass.freeArtCeiling : engine.knightClass }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HeaderView(
                        levelPulse: levelPulse,
                        classPulse: classPulse,
                        celebration: celebration
                    )
                    HeroScenePanel(grinding: engine.isGrinding,
                                   className: heroArtClass.rawValue,
                                   locked: heroLocked,
                                   displayName: heroArtClass.displayName)
                        .onTapGesture {
                            Haptics.actionTap()
                            if heroLocked { showPaywall = true } else { engine.toggle() }
                        }
                        // A soft green ring flashes around the hero on level-up (matches the
                        // panel's 22pt corner). `levelPulse` only increments when motion is on,
                        // so Reduce Motion users never see it.
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Theme.greenDeep, lineWidth: 3)
                                .allowsHitTesting(false)
                                .phaseAnimator([0.0, 0.7, 0.0], trigger: levelPulse) { ring, opacity in
                                    ring.opacity(opacity)
                                } animation: { _ in .easeOut(duration: 0.5) }
                        }
                    ProgressSection()
                    FocusHistoryCard()
                    // Every user sees the 10-hero ladder they're climbing — exposure is what
                    // turns the Pro art from invisible into something worth buying.
                    HeroJourneyRow { showCollection = true }
                    if store.isPro {
                        AppIconRow { showIconPicker = true }
                    } else {
                        UnlockProRow(capped: heroLocked) { showPaywall = true }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)   // breathing room above the pinned button
            }
        }
        // Pinned Start/Pause pill, always visible over the cream background (SPEC §4 item 6).
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                // Reassure that the core mechanic works: focus keeps counting once locked.
                if engine.isGrinding {
                    Label("Lock your phone — focus keeps counting", systemImage: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(Theme.gray)
                        .transition(.opacity)
                }
                StartPauseButton()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .background(Theme.cream)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: engine.isGrinding)
        }
        .onChange(of: engine.level) { oldLevel, newLevel in
            guard newLevel > oldLevel else { return }
            let oldClass = KnightClass.forLevel(oldLevel)
            let newClass = KnightClass.forLevel(newLevel)
            let classChanged = oldClass != newClass

            if !reduceMotion {
                levelPulse += 1
                if classChanged { classPulse += 1 }
            }
            Haptics.progressMilestone(classChanged: classChanged)
            showCelebration(level: newLevel, knightClass: newClass, classChanged: classChanged)
            if classChanged, !showIntro {
                milestone = Milestone(knightClass: newClass)   // gentle, one-tap share at peak pride
            }
            maybeRequestReview(classChanged: classChanged)
        }
        .onAppear {
            if firstLaunchAt == 0 { firstLaunchAt = Date().timeIntervalSince1970 }
            if !hasSeenIntro { showIntro = true }
        }
        .sheet(isPresented: $showIntro, onDismiss: { hasSeenIntro = true }) {
            IntroSheet { showIntro = false }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showIconPicker) {
            AppIconPickerSheet()
        }
        .sheet(isPresented: $showCollection) {
            HeroCollectionSheet()
        }
        .sheet(item: $milestone) { m in
            MilestoneShareSheet(className: m.knightClass.displayName)
        }
        .onChange(of: engine.journeyLevel) { _, new in
            guard new >= 21, !store.isPro, !swordsmanPaywallShown else { return }
            swordsmanPaywallShown = true
            showPaywall = true
        }
    }

    /// Ask for an App Store rating only at a genuine *retention* milestone — reaching a new
    /// class while on a 2+ day streak, a couple days in — and at most once per app version
    /// (Apple throttles further). Habit-formed users leave better, higher ratings, which is
    /// the biggest organic lever for rank + conversion. (Was: any level-up after day 3.)
    private func maybeRequestReview(classChanged: Bool) {
        let now = Date().timeIntervalSince1970
        if firstLaunchAt == 0 { firstLaunchAt = now }
        let daysIn = (now - firstLaunchAt) / 86_400
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        guard classChanged, engine.focusStreak >= 2, daysIn >= 2,
              version != lastReviewVersion else { return }
        lastReviewVersion = version
        requestReview()
    }

    private func showCelebration(level: Int, knightClass: KnightClass, classChanged: Bool) {
        let next = LevelCelebration(level: level, knightClass: knightClass, classChanged: classChanged)
        if reduceMotion {
            celebration = next
        } else {
            withAnimation(.snappy(duration: 0.22)) { celebration = next }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2_400))
            guard celebration?.id == next.id else { return }
            if reduceMotion {
                celebration = nil
            } else {
                withAnimation(.easeOut(duration: 0.22)) { celebration = nil }
            }
        }
    }
}

private struct LevelCelebration: Identifiable, Equatable {
    let id = UUID()
    let level: Int
    let knightClass: KnightClass
    let classChanged: Bool

    // Built via String(localized:) so both the format and the (already-localized) class
    // name translate; the resulting String is then shown verbatim in Text/Label.
    var title: String {
        let cls = String(localized: knightClass.displayName)
        return classChanged
            ? String(localized: "\(cls) reached", comment: "Celebration chip: reached a new class")
            : String(localized: "Level \(level)!", comment: "Celebration chip: reached a new level")
    }

    var accessibilityText: String {
        let cls = String(localized: knightClass.displayName)
        return classChanged
            ? String(localized: "Class changed to \(cls)")
            : String(localized: "Level \(level) reached")
    }
}

// MARK: - Header (SPEC §4 items 1 & 2)

private struct HeaderView: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let levelPulse: Int
    let classPulse: Int
    let celebration: LevelCelebration?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.subheadline)
                    .foregroundStyle(Theme.gray)

                Text("Level \(engine.level)")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText(value: Double(engine.level)))
                    .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: engine.level)
                    .phaseAnimator([1.0, 1.08, 1.0], trigger: levelPulse) { content, scale in
                        content
                            .scaleEffect(scale, anchor: .leading)
                            .foregroundStyle(scale > 1 ? Theme.greenDeep : Theme.ink)
                    } animation: { _ in
                        .easeOut(duration: 0.18)
                    }

                Text("\(engine.todayMinutes) min focused today")
                    .font(.callout)
                    .foregroundStyle(Theme.gray)
                    .contentTransition(.numericText(value: Double(engine.todayMinutes)))
                    .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: engine.todayMinutes)

                Label("5 min = 1 level", systemImage: "hourglass")
                    .font(.footnote)
                    .foregroundStyle(Theme.gray)
                    .padding(.top, 4)

                if let celebration {
                    CelebrationChip(celebration: celebration)
                        .padding(.top, 8)
                        .transition(.scale(scale: 0.92, anchor: .leading).combined(with: .opacity))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 10) {
                ShareDayButton()
                ClassBadge(name: engine.knightClass.displayName, pulse: classPulse)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Share my day (organic-growth hook)

private struct ShareDayButton: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(Store.self) private var store
    @State private var shareImage: Image?

    var body: some View {
        Group {
            if let shareImage {
                ShareLink(item: shareImage,
                          preview: SharePreview("Daily Levels", image: shareImage)) {
                    icon
                }
            } else {
                icon
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Share my day")
        // Render once, then only when the level, minutes, or Pro status change — never per 1s tick.
        .onAppear(perform: render)
        .onChange(of: engine.level) { render() }
        .onChange(of: engine.todayMinutes) { render() }
        .onChange(of: store.isPro) { render() }
    }

    private var icon: some View {
        Image(systemName: "square.and.arrow.up")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.green)
            .padding(8)
            .background(Theme.badgeBg, in: Circle())
    }

    @MainActor private func render() { shareImage = renderShareCard(engine, isPro: store.isPro) }
}

/// One shared renderer for the share image, used by both the header button and the
/// milestone share prompt. Sharing your *real* hero is a Pro flex: free users share their
/// free hero (art + class name capped at the free ceiling, but their real level), while Pro
/// users show off the Knight→Mythic hero they own. That gives a friend a reason to ask, and
/// the sharer a reason to upgrade — without misrepresenting the level they actually earned.
@MainActor private func renderShareCard(_ engine: FocusEngine, isPro: Bool) -> Image? {
    let locked = !isPro && engine.knightClass.isProOnly
    let shareClass = locked ? KnightClass.freeArtCeiling : engine.knightClass
    let card = ShareCardView(
        level: engine.level,
        classDisplayName: shareClass.displayName,
        todayMinutes: engine.todayMinutes,
        heroImage: HeroSceneAsset.sleepImage(for: shareClass.rawValue),
        streak: engine.focusStreak
    )
    let renderer = ImageRenderer(content: card)
    renderer.scale = 1   // card authored at 1080pt → exact 1080×1080 px
    return renderer.uiImage.map(Image.init(uiImage:))
}

// MARK: - Milestone share prompt (gentle word-of-mouth at a class change)

/// Identifies a class-up worth offering to share. Shown once per class change.
private struct Milestone: Identifiable {
    let knightClass: KnightClass
    var id: String { knightClass.rawValue }
}

/// A calm, dismissible sheet offered at the peak-pride moment of reaching a new class.
/// One tap shares the branded card (which reveals the hero art → free word-of-mouth);
/// "Maybe later" closes it. Never shown for ordinary level-ups, never nags.
private struct MilestoneShareSheet: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let className: LocalizedStringResource
    @State private var shareImage: Image?

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("You reached \(String(localized: className))!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text("Show a friend how far your focus has climbed.")
                    .font(.callout)
                    .foregroundStyle(Theme.gray)
                    .multilineTextAlignment(.center)

                if let shareImage {
                    shareImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)

                    ShareLink(item: shareImage,
                              preview: SharePreview("Daily Levels", image: shareImage)) {
                        Label("Share your climb", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Theme.green, in: Capsule())
                    }
                    .buttonStyle(.pressable(scale: 0.97))
                } else {
                    ProgressView().padding(.vertical, 40)
                }

                Button("Maybe later") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(Theme.gray)
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear { shareImage = renderShareCard(engine, isPro: store.isPro) }
        // If Pro is purchased while this is open, re-render so the shared card shows the real hero.
        .onChange(of: store.isPro) { shareImage = renderShareCard(engine, isPro: store.isPro) }
    }
}

private struct ClassBadge: View {
    let name: LocalizedStringResource
    let pulse: Int

    var body: some View {
        Text(name)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.badgeBg, in: Capsule())
            .phaseAnimator([false, true, false], trigger: pulse) { content, active in
                content
                    .scaleEffect(active ? 1.06 : 1)
                    .shadow(color: active ? Theme.green.opacity(0.22) : .clear,
                            radius: active ? 8 : 0,
                            y: active ? 2 : 0)
            } animation: { _ in
                .easeOut(duration: 0.2)
            }
            .accessibilityLabel(Text("Daily class \(String(localized: name))"))
    }
}

private struct CelebrationChip: View {
    let celebration: LevelCelebration

    var body: some View {
        Label(celebration.title, systemImage: celebration.classChanged ? "sparkles" : "arrow.up.circle.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.greenDeep)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.greenSoft.opacity(0.35), in: Capsule())
            .accessibilityLabel(celebration.accessibilityText)
    }
}

// MARK: - Progress (SPEC §4 item 4)

private struct ProgressSection: View {
    @Environment(FocusEngine.self) private var engine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Progress bar: fill = seconds into the current level.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
                    Capsule().fill(Theme.greenDeep)
                        .frame(width: max(8, geo.size.width * engine.levelProgress))
                }
            }
            .frame(height: 12)
            .animation(.easeInOut(duration: 0.3), value: engine.levelProgress)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Level progress")
            .accessibilityValue("\(Int(engine.levelProgress * 100)) percent")

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(engine.todayMinutes) min focused today")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText(value: Double(engine.todayMinutes)))
                        .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: engine.todayMinutes)

                    if engine.isGrinding || engine.isPaused {
                        Text(engine.isPaused ? LocalizedStringKey("Paused") : LocalizedStringKey("Current session"))
                            .font(.caption)
                            .foregroundStyle(Theme.gray)
                        // Big, prominent session clock. `.monospacedDigit()` fixes each digit's
                        // width so the timer doesn't shift left/right as the seconds tick.
                        // While paused it holds its value; resume continues from here.
                        Text(Format.clock(engine.currentSessionSeconds))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(engine.isPaused ? Theme.gray : Theme.ink)
                    } else {
                        Text("Ready to focus")
                            .font(.footnote)
                            .foregroundStyle(Theme.gray)
                    }
                }
                Spacer()
                Text(progressLabel)
                    .font(.subheadline)
                    .foregroundStyle(engine.isMaxLevel || engine.isLevelUpMoment ? Theme.greenDeep : Theme.gray)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var progressLabel: LocalizedStringKey {
        if engine.isMaxLevel { return "Max level — Mythic!" }
        if engine.isLevelUpMoment { return "Level up!" }
        return "Next level in \(engine.minutesToNextLevel) min"
    }
}

// MARK: - Bottom button (SPEC §4 item 6)

private struct StartPauseButton: View {
    @Environment(FocusEngine.self) private var engine

    var body: some View {
        Button {
            Haptics.actionTap()
            engine.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: engine.isGrinding ? "pause.fill" : "play.fill")
                Text(label)
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.green, in: Capsule())
        }
        .buttonStyle(.pressable(scale: 0.97))
        .accessibilityLabel(label)
        .accessibilityHint(engine.isGrinding ? "Pause focus timer"
            : engine.isPaused ? "Resume focus timer" : "Start focus timer")
    }

    private var label: LocalizedStringKey {
        if engine.isGrinding { return "Pause" }
        return engine.isPaused ? "Resume" : "Start"
    }
}

// MARK: - Unlock Pro entry point (shown until purchased)

private struct UnlockProRow: View {
    /// True when a free user has hit the Pro art ceiling — show contextual copy + a soft
    /// outline so the upgrade reads as the natural next step (calm, no urgency/countdown).
    var capped: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Theme.greenDeep)
                VStack(alignment: .leading, spacing: 2) {
                    Text(capped ? "You've reached the free climb" : "Daily Levels Pro")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(capped ? "Unlock Knight → Mythic — yours forever"
                               : "Evolve your hero all the way to Mythic")
                        .font(.caption)
                        .foregroundStyle(Theme.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.gray)
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                if capped {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.greenSoft, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.pressable)
        .accessibilityHint("Opens the Pro unlock")
    }
}

// MARK: - First-run intro (one-time, explains the core loop)

private struct IntroSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Text("Welcome to Daily Levels")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Theme.ink)

                VStack(alignment: .leading, spacing: 16) {
                    IntroRow(icon: "hourglass",
                             text: "Focus to level up — every 5 minutes is one level.")
                    IntroRow(icon: "lock.fill",
                             text: "Lock your phone — your focus keeps counting.")
                    IntroRow(icon: "moon.zzz.fill",
                             text: "Switch apps and your hero rests until you return.")
                    IntroRow(icon: "flame.fill",
                             text: "Come back tomorrow — your streak keeps growing.")
                    IntroRow(icon: "square.and.arrow.up",
                             text: "Share your climb to inspire a friend.")
                }

                Spacer(minLength: 0)

                Button(action: onDismiss) {
                    Text("Start focusing")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.green, in: Capsule())
                }
                .buttonStyle(.pressable(scale: 0.97))
            }
            .padding(28)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct IntroRow: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.greenDeep)
                .frame(width: 28)
            Text(text)
                .font(.callout)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Formatting helpers

enum Format {
    /// Seconds → "mm:ss" (or "h:mm:ss" past an hour).
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%d:%02d", m, sec)
    }

    /// Locale-aware "Jun 6" — day/month order adapts per locale (e.g. "6 juin", "6月6日").
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
    /// Locale-aware "June 12".
    static func longDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).day())
    }
}
