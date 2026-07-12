//
//  FocusHistoryCard.swift
//  Daily Levels
//
//  Focus History card (SPEC §4 item 5): title + caption, a 7-day bar chart
//  (rightmost = "Today" in darker green), then a list of recent days.
//  Hand-rolled chart to match the mockup's soft-green rounded bars exactly
//  (no Swift Charts dependency needed).
//

import SwiftUI

struct FocusHistoryCard: View {
    @Environment(FocusEngine.self) private var engine

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Focus History")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.ink)

            Text("Levels earned each day · resets at midnight")
                .font(.footnote)
                .foregroundStyle(Theme.gray)

            WeekBarChart(days: engine.weekHistory)
                .frame(height: 150)
                .padding(.top, 2)

            VStack(spacing: 0) {
                ForEach(engine.recentDays) { day in
                    DayRow(day: day)
                    if day.id != engine.recentDays.last?.id {
                        Divider().background(Theme.hairline)
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Bar chart

private struct WeekBarChart: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let days: [DaySummary]

    /// Chart top: at least 12 (matches the mockup's gridlines), rounded up to a multiple of 6.
    private var top: Int {
        let maxLevel = days.map(\.level).max() ?? 0
        return max(12, Int((Double(maxLevel) / 6).rounded(.up)) * 6)
    }

    var body: some View {
        GeometryReader { geo in
            let labelH: CGFloat = 18
            let plotH = geo.size.height - labelH

            ZStack(alignment: .topLeading) {
                // Dashed gridlines + y labels at 0, top/2, top.
                ForEach([top, top / 2, 0], id: \.self) { value in
                    let y = plotH * (1 - CGFloat(value) / CGFloat(top))
                    HStack(spacing: 6) {
                        Text("\(value)")
                            .font(.caption2)
                            .foregroundStyle(Theme.gray)
                            .frame(width: 16, alignment: .trailing)
                        Line().stroke(Theme.hairline, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .frame(height: 1)
                    }
                    .position(x: geo.size.width / 2 + 11, y: y)
                }

                // Bars
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(days) { day in
                        let isToday = day.id == days.last?.id
                        VStack(spacing: 6) {
                            Spacer(minLength: 0)
                            Capsule(style: .continuous)
                                .fill(isToday ? Theme.greenDeep : Theme.greenSoft)
                                .frame(width: 22,
                                       height: max(2, plotH * CGFloat(day.level) / CGFloat(top)))
                                .animation(reduceMotion ? nil : .easeOut(duration: 0.4), value: day.level)
                            Text(isToday ? "Today" : Format.shortDate(day.date))
                                .font(.caption2.weight(isToday ? .bold : .regular))
                                .foregroundStyle(isToday ? Theme.ink : Theme.gray)
                                .frame(height: labelH)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(isToday ? String(localized: "Today") : Format.longDate(day.date)))
                        .accessibilityValue(Text(accessibilitySummary(for: day)))
                    }
                }
                .padding(.leading, 22)   // clear the y-axis labels
            }
        }
    }
}

/// A 1pt horizontal line shape for the dashed gridlines.
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return p
    }
}

// MARK: - Day list row

private struct DayRow: View {
    let day: DaySummary
    var body: some View {
        HStack {
            Text(Format.longDate(day.date))
                .font(.body)
                .foregroundStyle(Theme.ink)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("Level \(day.level)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.green)
                Text("\(day.focusMinutes) min focus time")
                    .font(.footnote)
                    .foregroundStyle(Theme.gray)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Format.longDate(day.date)))
        .accessibilityValue(Text(accessibilitySummary(for: day)))
    }
}

/// Reuses existing localized strings so chart bars and rows announce the same concise result.
private func accessibilitySummary(for day: DaySummary) -> String {
    let level = String(localized: "Level \(day.level)")
    let focusTime = String(localized: "\(day.focusMinutes) min focus time")
    return "\(level), \(focusTime)"
}
