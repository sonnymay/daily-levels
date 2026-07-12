//
//  LockClassifier.swift
//  Daily Levels
//
//  The critical technical piece (SPEC §6), ported from the Phase-1 probe.
//  iOS reports "app backgrounded" identically for (a) phone locked and
//  (b) user switched apps. Only locking fires `protectedDataWillBecomeUnavailable`
//  (and only with a device passcode). So on backgrounding we hold a short
//  background task + grace timer and wait:
//     lock notification arrives  -> LOCKED   (hero keeps grinding)
//     grace expires, no lock     -> APP SWITCH (hero sleeps)
//
//  Kept as a standalone object so that, if hardware testing forces the approach to
//  change, only this file changes — the engine just consumes the callbacks.
//

import UIKit

@MainActor
final class LockClassifier {

    /// Seconds to wait after backgrounding before deciding "app switch".
    /// SPEC §6/§10 say start at 30s and tune on real hardware.
    var graceSeconds: TimeInterval = 30

    /// Engine sets this true only while grinding — we ignore backgrounding otherwise.
    var isActive: Bool = false

    // Callbacks the engine wires up.
    var onLockDetected: (() -> Void)?
    var onAppSwitchDetected: ((_ backgroundedAt: Date) -> Void)?
    var onEnterForeground: ((_ sawLock: Bool) -> Void)?

    private var backgroundedAt: Date?
    private var sawLock = false
    private var graceTimer: Timer?
    private var bgTask: UIBackgroundTaskIdentifier = .invalid

    init() {
        let nc = NotificationCenter.default
        // `queue: .main` guarantees these closures run on the main thread, matching @MainActor.
        nc.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                       object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleEnterBackground() }
        }
        nc.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
                       object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleLock() }
        }
        nc.addObserver(forName: UIApplication.willEnterForegroundNotification,
                       object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleEnterForeground() }
        }
    }

    private func handleEnterBackground() {
        guard isActive else { return }
        backgroundedAt = Date()
        sawLock = false

        // Keep the process alive long enough to observe a lock notification.
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "lock-classify") { [weak self] in
            self?.endBackgroundTask()
        }

        graceTimer?.invalidate()
        graceTimer = Timer.scheduledTimer(withTimeInterval: graceSeconds, repeats: false) { [weak self] _ in
            // Hop back to the main actor; Timer fires on the run loop it was scheduled on (main here).
            MainActor.assumeIsolated { self?.graceExpired() }
        }
    }

    private func handleLock() {
        guard isActive, backgroundedAt != nil else { return }
        sawLock = true
        // It's a real lock — no need to wait out the grace window.
        graceTimer?.invalidate()
        graceTimer = nil
        onLockDetected?()
    }

    private func graceExpired() {
        graceTimer?.invalidate()
        graceTimer = nil
        if !sawLock, let bgAt = backgroundedAt {
            onAppSwitchDetected?(bgAt)   // they left for another app — sleep, don't count away-time
        }
        endBackgroundTask()
    }

    private func handleEnterForeground() {
        guard let _ = backgroundedAt else { return }
        graceTimer?.invalidate()
        graceTimer = nil
        let lockedThisTrip = sawLock
        backgroundedAt = nil
        sawLock = false
        endBackgroundTask()
        onEnterForeground?(lockedThisTrip)
    }

    private func endBackgroundTask() {
        if bgTask != .invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        }
    }
}
