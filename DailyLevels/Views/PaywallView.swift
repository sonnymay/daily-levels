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
    @State private var isLoadingPrice = false

    private let privacyURL = URL(string: "https://github.com/sonnymay/daily-levels/blob/main/PRIVACY_POLICY.md")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// Drives the failure alert off `store.lastError`; dismissing clears it.
    private var showError: Binding<Bool> {
        Binding(get: { store.lastError != nil }, set: { if !$0 { store.lastError = nil } })
    }

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
                                       title: "7 more hero evolutions",
                                       text: "Unlock Knight, Crusader, Champion, Paladin, Hero, Legend, and Mythic.")
                            BenefitRow(icon: "arrow.up.forward.circle.fill",
                                       title: "Earn every evolution",
                                       text: "Your focus still does the work. New hero art appears as your journey level grows.")
                            BenefitRow(icon: "checkmark.seal.fill",
                                       title: "One purchase. Yours forever.",
                                       text: "No subscription and no renewal. Restore it on any device using your Apple Account.")
                        }

                        // Show the real heroes — the ones you've earned but can't yet own —
                        // so the purchase is concrete, not abstract.
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your collection")
                                .font(.headline)
                                .foregroundStyle(Theme.ink)
                            HeroCollectionGrid()
                        }

                        Label("Private and ad-free for everyone", systemImage: "hand.raised.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.gray)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }

                purchaseFooter
            }
        }
        .alert("Purchase failed", isPresented: showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(store.lastError ?? "")
        }
        .task {
            if store.proProduct == nil { await loadPrice() }
        }
    }

    private var purchaseFooter: some View {
        VStack(spacing: 12) {
            if let price = store.priceText {
                Button {
                    Task { await store.purchase(); if store.isPro { dismiss() } }
                } label: {
                    Group {
                        if store.isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Text("Unlock 7 heroes · \(price)")
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
            } else {
                Button {
                    Task { await loadPrice() }
                } label: {
                    Group {
                        if isLoadingPrice {
                            ProgressView().tint(Theme.green)
                        } else {
                            Text("Retry loading price")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.pressable(scale: 0.97))
                .disabled(isLoadingPrice)
            }

            Button("Restore Purchases") {
                Task { await store.restore(); if store.isPro { dismiss() } }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.gray)
            .disabled(store.isWorking)   // no double-tap → no two concurrent AppStore.sync() calls

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

    private func loadPrice() async {
        isLoadingPrice = true
        await store.loadProducts()
        isLoadingPrice = false
    }
}

private struct BenefitRow: View {
    let icon: String
    let title: LocalizedStringKey   // LocalizedStringKey so the catalog actually resolves (was String → English-only)
    let text: LocalizedStringKey

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
