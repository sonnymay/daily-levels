//
//  MainView.swift
//  Daily Levels
//
//  The single screen (SPEC §4). No tabs, no settings, no other screens.
//

import SwiftUI

struct MainView: View {
    @Environment(FocusEngine.self) private var engine

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HeaderView()
                    HeroScenePanel(grinding: engine.isGrinding, className: engine.knightClass.rawValue)
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
            StartPauseButton()
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(Theme.cream)
        }
    }
}

// MARK: - Header (SPEC §4 items 1 & 2)

private struct HeaderView: View {
    @Environment(FocusEngine.self) private var engine

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.subheadline)
                    .foregroundStyle(Theme.gray)

                Text("Level \(engine.level)")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Theme.ink)

                Text("\(engine.todayMinutes) min focused today")
                    .font(.callout)
                    .foregroundStyle(Theme.gray)

                Label("5 min = 1 level", systemImage: "hourglass")
                    .font(.footnote)
                    .foregroundStyle(Theme.gray)
                    .padding(.top, 4)
            }
            Spacer()
            ClassBadge(name: engine.knightClass.rawValue)
        }
    }
}

private struct ClassBadge: View {
    let name: String
    var body: some View {
        Text(name)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.badgeBg, in: Capsule())
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

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(engine.todayMinutes) min focused today")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)

                    if engine.isGrinding {
                        Text("Current session")
                            .font(.caption)
                            .foregroundStyle(Theme.gray)
                        // Big, prominent session clock. `.monospacedDigit()` fixes each digit's
                        // width so the timer doesn't shift left/right as the seconds tick.
                        Text(Format.clock(engine.currentSessionSeconds))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.ink)
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
        Button(action: engine.toggle) {
            HStack(spacing: 10) {
                Image(systemName: engine.isGrinding ? "pause.fill" : "play.fill")
                Text(engine.isGrinding ? "Pause" : "Start")
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.green, in: Capsule())
        }
        .buttonStyle(.plain)
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
