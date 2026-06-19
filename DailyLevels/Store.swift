//
//  Store.swift
//  Daily Levels
//
//  StoreKit 2 entitlement manager for the single non-consumable "Daily Levels Pro"
//  unlock. No RevenueCat, no third-party SDK — keeps the "Data Not Collected" label
//  intact. Mirrors FocusEngine's pattern: an @Observable @MainActor source of truth
//  injected once via .environment, read by views as @Environment(Store.self).
//
//  Free vs Pro boundary lives in `KnightClass.isProOnly` (below): the hero visually
//  evolves through the first three classes for free; Pro unlocks Knight → Mythic.
//

import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class Store {
    /// Must match the non-consumable product ID created in App Store Connect.
    static let proProductID = "com.santipapmay.DailyLevels.pro"

    private(set) var proProduct: Product?
    private(set) var isPro = false
    private(set) var isWorking = false
    var lastError: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        #if DEBUG
        // Reflect immediately (before the async refresh) so previews/screenshots aren't gated.
        if ProcessInfo.processInfo.arguments.contains("-unlockPro") { isPro = true }
        #endif
        // Long-running listener for renewals / Ask-to-Buy approvals / refunds (SPEC-grade hygiene).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await refresh() }
    }

    deinit { updatesTask?.cancel() }

    /// Price to show on the paywall; falls back to the launch "Founder's price" if the
    /// product hasn't loaded yet (e.g. offline, or not yet live in App Store Connect).
    var priceText: String { proProduct?.displayPrice ?? "$6.99" }

    func refresh() async {
        await updateEntitlements()   // entitlements first — never block isPro on product metadata
        await loadProducts()
    }

    func loadProducts() async {
        do {
            proProduct = try await Product.products(for: [Self.proProductID]).first
        } catch {
            lastError = error.localizedDescription
        }
    }

    func updateEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               t.productID == Self.proProductID,
               t.revocationDate == nil {
                owned = true
            }
        }
        #if DEBUG
        // Lets screenshot/preview launches show the full hero evolution.
        if ProcessInfo.processInfo.arguments.contains("-unlockPro") { owned = true }
        #endif
        isPro = owned
    }

    func purchase() async {
        isWorking = true
        defer { isWorking = false }
        if proProduct == nil { await loadProducts() }   // first-launch / offline retry, then surface failure
        guard let product = proProduct else {
            lastError = String(localized: "Couldn’t reach the App Store. Check your connection and try again.")
            return
        }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    await updateEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Wire to the paywall's "Restore Purchases" button (required by App Review).
    func restore() async {
        isWorking = true
        defer { isWorking = false }
        do { try await AppStore.sync() }
        catch { lastError = error.localizedDescription }
        await updateEntitlements()
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let t) = result {
            await t.finish()
            await updateEntitlements()
        }
    }
}

// MARK: - Free vs Pro boundary

extension KnightClass {
    /// Highest class whose hero art is free; beyond this, Pro unlocks the evolution.
    static let freeArtCeiling: KnightClass = .swordsman   // Novice · Squire · Swordsman (≤ level 30)

    /// True for classes whose hero art is gated behind Pro (Knight → Mythic).
    var isProOnly: Bool {
        guard let mine = Self.allCases.firstIndex(of: self),
              let ceiling = Self.allCases.firstIndex(of: Self.freeArtCeiling) else { return false }
        return mine > ceiling
    }
}
