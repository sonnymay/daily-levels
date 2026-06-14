//
//  MainView.swift
//  Daily Levels
//
//  The single screen (SPEC §4). No tabs, no settings, no other screens.
//

import SwiftUI

struct MainView: View {
    @Environment(FocusEngine.self) private var engine
    @State private var levelPulse = 0
    @State private var classPulse = 0
    @State private var celebration: LevelCelebration?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    HeroScenePanel(grinding: engine.isGrinding, className: engine.knightClass.rawValue)
                        .onTapGesture {
                            Haptics.actionTap()
                            engine.toggle()
                        }
                    ProgressSection()
                    FocusHistoryCard()
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
            showCelebration(level: newLevel, className: newClass.rawValue, classChanged: classChanged)
        }
    }

    private func showCelebration(level: Int, className: String, classChanged: Bool) {
        let next = LevelCelebration(level: level, className: className, classChanged: classChanged)
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
    let className: String
    let classChanged: Bool

    var title: String {
        classChanged ? "\(className) reached" : "Level \(level)!"
    }

    var accessibilityText: String {
        classChanged ? "Class changed to \(className)" : "Level \(level) reached"
    }
}

// MARK: - Header (SPEC §4 items 1 & 2)

private struct HeaderView: View {
    @Environment(FocusEngine.self) private var engine
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
            ClassBadge(name: engine.knightClass.rawValue, pulse: classPulse)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct ClassBadge: View {
    let name: String
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
            .accessibilityLabel("Daily class \(name)")
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

                    if engine.isGrinding || engine.isPaused {
                        Text(engine.isPaused ? "Paused" : "Current session")
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

    private var progressLabel: String {
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
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(engine.isGrinding ? "Pause focus timer"
            : engine.isPaused ? "Resume focus timer" : "Start focus timer")
    }

    private var label: String {
        if engine.isGrinding { return "Pause" }
        return engine.isPaused ? "Resume" : "Start"
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

    private static let shortDay: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f      // "Jun 6"
    }()
    private static let longDay: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM d"; return f     // "June 12"
    }()

    static func shortDate(_ date: Date) -> String { shortDay.string(from: date) }
    static func longDate(_ date: Date) -> String { longDay.string(from: date) }
}
