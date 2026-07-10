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
    @AppStorage("knightPaywallShown") private var knightPaywallShown = false
    @State private var showIntro = false
    @State private var showPaywall = false
    @State private var showCollection = false

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
                            guard heroLocked else { return }
                            Haptics.actionTap()
                            showPaywall = true
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
                    // One calm secondary entry point: progress and Pro both live in the collection.
                    HeroJourneyRow { showCollection = true }
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
            maybeRequestReview(classChanged: classChanged)
        }
        .onAppear {
            if firstLaunchAt == 0 { firstLaunchAt = Date().timeIntervalSince1970 }
            if !hasSeenIntro { showIntro = true }
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-showHeroCollection") { showCollection = true }
            if arguments.contains("-showPaywall") { showPaywall = true }
            #endif
        }
        .sheet(isPresented: $showIntro, onDismiss: { hasSeenIntro = true }) {
            IntroSheet {
                engine.start()
                showIntro = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showCollection) {
            HeroCollectionSheet()
        }
        .onChange(of: engine.journeyLevel) { _, new in
            // Ask only once the first paid evolution has actually been earned.
            guard new >= KnightClass.knight.minLevel, !store.isPro, !knightPaywallShown else { return }
            knightPaywallShown = true
            showPaywall = true
        }
    }

    /// Ask only after a real class promotion, several days in, and once per app version.
    private func maybeRequestReview(classChanged: Bool) {
        let now = Date().timeIntervalSince1970
        if firstLaunchAt == 0 { firstLaunchAt = now }
        let daysIn = (now - firstLaunchAt) / 86_400
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        guard classChanged, daysIn >= 3,
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
            ClassBadge(name: engine.knightClass.displayName, pulse: classPulse)
        }
        .accessibilityElement(children: .contain)
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

// MARK: - First-run intro (one-time, explains the core loop)

private struct IntroSheet: View {
    let onStart: () -> Void

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
                             text: "Locking counts. Switching apps pauses your hero.")
                }

                Spacer(minLength: 0)

                Button(action: onStart) {
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
