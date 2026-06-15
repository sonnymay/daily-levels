//
//  DailyLevelsWidget.swift
//  DailyLevelsWidget  (widget extension target only)
//
//  A calm home-screen widget mirroring the app: today's level, class, minutes, and streak,
//  in the cream/green brand palette. Reads the shared snapshot the app publishes; no network,
//  no tracking. Refreshes after midnight so the daily reset shows on its own.
//
//  Palette is inlined (the widget target can't see the app's Theme.swift) — keep in sync.
//

import WidgetKit
import SwiftUI

// MARK: - Palette (mirror of Theme.swift)

private enum W {
    static let cream     = Color(red: 0xF3/255, green: 0xF0/255, blue: 0xE8/255)
    static let ink       = Color(red: 0x1B/255, green: 0x1B/255, blue: 0x1D/255)
    static let gray      = Color(red: 0x8A/255, green: 0x8A/255, blue: 0x8E/255)
    static let green     = Color(red: 0x5E/255, green: 0x8C/255, blue: 0x3E/255)
    static let greenDeep = Color(red: 0x4C/255, green: 0x7A/255, blue: 0x33/255)
    static let greenSoft = Color(red: 0xC3/255, green: 0xDB/255, blue: 0xA4/255)
}

// MARK: - Timeline

struct DLEntry: TimelineEntry {
    let date: Date
    let snapshot: DailyLevelsSnapshot
}

struct DLProvider: TimelineProvider {
    func placeholder(in context: Context) -> DLEntry {
        DLEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DLEntry) -> Void) {
        completion(DLEntry(date: Date(), snapshot: DailyLevelsSnapshot.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DLEntry>) -> Void) {
        let snap = DailyLevelsSnapshot.load() ?? .placeholder
        let entry = DLEntry(date: Date(), snapshot: snap)
        // Refresh just after the next midnight so the level resets visually on a new day.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Widget

struct DailyLevelsWidget: Widget {
    let kind = "DailyLevelsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DLProvider()) { entry in
            DailyLevelsWidgetView(entry: entry)
                .containerBackground(W.cream, for: .widget)
        }
        .configurationDisplayName("Daily Levels")
        .description("Your focus level, class, and streak — today at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - View

struct DailyLevelsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DLEntry

    /// After midnight a stale snapshot reads as a fresh, unfocused day; the streak is kept.
    private var isToday: Bool { entry.snapshot.describesToday() }
    private var level: Int { isToday ? entry.snapshot.level : 0 }
    private var minutes: Int { isToday ? entry.snapshot.todayMinutes : 0 }
    private var streak: Int { entry.snapshot.streak }

    var body: some View {
        switch family {
        case .systemMedium: medium
        default:            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today").font(.caption2).foregroundStyle(W.gray)
            Text("Level \(level)")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(W.ink)
                .contentTransition(.numericText(value: Double(level)))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(entry.snapshot.className)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(W.greenDeep)
                .lineLimit(1)
            Spacer(minLength: 0)
            footer
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today").font(.caption).foregroundStyle(W.gray)
                Text("Level \(level)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(W.ink)
                    .contentTransition(.numericText(value: Double(level)))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(entry.snapshot.className)
                    .font(.headline)
                    .foregroundStyle(W.greenDeep)
                    .lineLimit(1)
                Spacer(minLength: 0)
                footer
            }
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                Image(systemName: "figure.fencing")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(W.green)
                Text("\(minutes) min today")
                    .font(.caption)
                    .foregroundStyle(W.gray)
            }
        }
    }

    @ViewBuilder private var footer: some View {
        if streak >= 2 {
            Label("\(streak)-day streak", systemImage: "flame.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(W.greenDeep)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(W.greenSoft.opacity(0.4), in: Capsule())
        } else {
            Label("Daily Levels", systemImage: "hourglass")
                .font(.caption2)
                .foregroundStyle(W.gray)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    DailyLevelsWidget()
} timeline: {
    DLEntry(date: Date(), snapshot: .placeholder)
}

#Preview(as: .systemMedium) {
    DailyLevelsWidget()
} timeline: {
    DLEntry(date: Date(), snapshot: .placeholder)
}
