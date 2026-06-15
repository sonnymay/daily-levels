//
//  AppIconPicker.swift
//  Daily Levels
//
//  Minimal alternate-app-icon picker, offered as a Pro perk. The alternate icons
//  ("IconNight", "IconRoyal") are PLACEHOLDER art (tinted from the base icon) — replace
//  with designer art before launch. Switching uses UIApplication.setAlternateIconName.
//

import SwiftUI

enum AppIconOption: String, CaseIterable, Identifiable {
    case classic, night, royal
    var id: String { rawValue }

    /// nil = the primary app icon.
    var alternateName: String? {
        switch self {
        case .classic: return nil
        case .night:   return "IconNight"
        case .royal:   return "IconRoyal"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .classic: return "Classic"
        case .night:   return "Night"
        case .royal:   return "Royal"
        }
    }

    var swatch: Color {
        switch self {
        case .classic: return Theme.green
        case .night:   return Color(hex: 0x2E3A59)
        case .royal:   return Color(hex: 0x6B5B73)
        }
    }
}

struct AppIconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var current = UIApplication.shared.alternateIconName

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                Text("App Icon")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.ink)

                VStack(spacing: 0) {
                    ForEach(Array(AppIconOption.allCases.enumerated()), id: \.element.id) { idx, opt in
                        Button { select(opt) } label: { row(opt) }
                            .buttonStyle(.pressable)
                        if idx < AppIconOption.allCases.count - 1 {
                            Divider().background(Theme.hairline)
                        }
                    }
                }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func row(_ opt: AppIconOption) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(opt.swatch)
                .frame(width: 40, height: 40)
            Text(opt.title)
                .font(.body)
                .foregroundStyle(Theme.ink)
            Spacer()
            if opt.alternateName == current {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func select(_ opt: AppIconOption) {
        guard opt.alternateName != current else { return }
        Haptics.actionTap()
        UIApplication.shared.setAlternateIconName(opt.alternateName) { _ in }
        current = opt.alternateName
    }
}

/// Entry row (shown to Pro users) that opens the icon picker.
struct AppIconRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "app.badge.checkmark")
                    .font(.title3)
                    .foregroundStyle(Theme.greenDeep)
                Text("App Icon")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.gray)
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityHint("Choose an app icon")
    }
}
