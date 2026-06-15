//
//  PaywallView.swift
//  Daily Levels
//
//  Calm, native paywall for the one-time "Daily Levels Pro" unlock. Lists only what
//  Pro actually delivers today (hero evolution + the privacy/indie story) — no promises
//  of features that don't exist yet, per App Review. Restore + Terms/Privacy links included.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let privacyURL = URL(string: "https://github.com/sonnymay/daily-levels/blob/main/PRIVACY_POLICY.md")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Daily Levels Pro")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Theme.ink)
                            Text("One-time unlock. Yours forever.")
                                .font(.callout)
                                .foregroundStyle(Theme.gray)
                        }
                        .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 16) {
                            BenefitRow(icon: "figure.fencing",
                                       title: "Evolve to Mythic",
                                       text: "Unlock your hero’s full journey — Knight, Crusader, all the way to Mythic.")
                            BenefitRow(icon: "lock.open.fill",
                                       title: "All 10 classes",
                                       text: "See every class your focus earns, not just the first three.")
                            BenefitRow(icon: "hand.raised.fill",
                                       title: "No ads, no tracking",
                                       text: "No accounts, no analytics, no ads — ever. Your focus stays on your phone.")
                            BenefitRow(icon: "heart.fill",
                                       title: "Support an indie dev",
                                       text: "A one-time purchase keeps Daily Levels calm and ad-free.")
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }

                purchaseFooter
            }
        }
    }

    private var purchaseFooter: some View {
        VStack(spacing: 12) {
            Button {
                Task { await store.purchase(); if store.isPro { dismiss() } }
            } label: {
                Group {
                    if store.isWorking {
                        ProgressView().tint(.white)
                    } else {
                        Text("Unlock Pro · \(store.priceText)")
                    }
                }
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.green, in: Capsule())
            }
            .buttonStyle(.pressable(scale: 0.97))
            .disabled(store.isWorking)

            Button("Restore Purchases") {
                Task { await store.restore(); if store.isPro { dismiss() } }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.gray)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: privacyURL)
                Text("·").foregroundStyle(Theme.gray)
                Link("Terms", destination: termsURL)
            }
            .font(.caption)
            .tint(Theme.gray)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Theme.cream)
    }
}

private struct BenefitRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.greenDeep)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(text)
                    .font(.callout)
                    .foregroundStyle(Theme.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
