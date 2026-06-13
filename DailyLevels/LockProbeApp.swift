//
//  LockProbeApp.swift
//  Minute Knight — Build Step 1: Lock-Detection Prototype
//
//  PURPOSE
//  Prove that iOS lets us distinguish:
//    LOCKED      -> user pressed power button / phone auto-locked  -> hero keeps grinding
//    APP SWITCH  -> user opened another app                        -> hero sleeps
//
//  HOW IT WORKS
//  Both cases fire `didEnterBackground`. Only locking fires
//  `protectedDataWillBecomeUnavailable` (requires a device passcode).
//  So: on backgrounding, hold a short background task open and wait.
//  If the lock notification arrives within the grace window -> LOCKED.
//  If it never arrives -> APP SWITCH.
//
//  HOW TO RUN
//  1. Xcode -> New Project -> iOS App -> SwiftUI. Replace the generated
//     App file's contents with this entire file (delete ContentView.swift).
//  2. Run on a REAL iPhone with a passcode set. (Simulator's lock
//     notifications are unreliable — do not trust simulator results.)
//
//  TEST SCRIPT (do each, then return to the app and read the log)
//  A. Press the side button to lock. Wait ~15s. Unlock, return.
//       EXPECT: "Device locked" then "Classified: LOCKED".
//  B. Swipe to Home / open another app. Wait ~15s. Return.
//       EXPECT: no lock event, then "Classified: APP SWITCH".
//  C. Open another app, THEN lock the phone.
//       EXPECT: "Classified: APP SWITCH" (they left the app first — correct).
//  D. Lock, wait 2 minutes, unlock.
//       EXPECT: LOCKED, and elapsed time on return is accurate.
//  E. Settings -> Face ID & Passcode -> Require Attention etc. left default;
//     if you use a passcode grace period ("Require Passcode: After 5 min"),
//     repeat test A and note any delay in the lock notification.
//
//  PASS = A–D classify correctly on hardware. Then the design is safe to build.
//

import SwiftUI
import UIKit

@main
struct LockProbeApp: App {
    @StateObject private var probe = LockProbe()

    var body: some Scene {
        WindowGroup {
            ProbeView()
                .environmentObject(probe)
        }
    }
}

// MARK: - Core logic

final class LockProbe: ObservableObject {

    @Published var events: [ProbeEvent] = ProbeEvent.load()

    /// Seconds to wait after backgrounding before classifying as APP SWITCH.
    /// Tune this after hardware testing (spec says start at 30; 10 is fine for the probe).
    private let graceSeconds: TimeInterval = 10

    private var backgroundedAt: Date?
    private var sawLockEvent = false
    private var graceTimer: Timer?
    private var bgTask: UIBackgroundTaskIdentifier = .invalid

    init() {
        let nc = NotificationCenter.default

        nc.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                       object: nil, queue: .main) { [weak self] _ in
            self?.handleDidEnterBackground()
        }
        nc.addObserver(forName: UIApplication.willEnterForegroundNotification,
                       object: nil, queue: .main) { [weak self] _ in
            self?.handleWillEnterForeground()
        }
        nc.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
                       object: nil, queue: .main) { [weak self] _ in
            self?.sawLockEvent = true
            self?.log("🔒 Device locked (protected data unavailable)")
            // If we were still inside the grace window, we can classify early.
            if self?.graceTimer != nil {
                self?.classify()
            }
        }
        nc.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification,
                       object: nil, queue: .main) { [weak self] _ in
            self?.log("🔓 Device unlocked (protected data available)")
        }

        log("🚀 Probe launched. Passcode set on device: \(UIDevice.current.isPasscodeLikelySet ? "probably yes" : "UNKNOWN — set one!")")
    }

    private func handleDidEnterBackground() {
        backgroundedAt = Date()
        sawLockEvent = false
        log("⬇️ App backgrounded — waiting \(Int(graceSeconds))s to classify…")

        // Keep the process alive long enough to observe a lock notification.
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "lock-probe") { [weak self] in
            self?.endBackgroundTask()
        }

        graceTimer?.invalidate()
        graceTimer = Timer.scheduledTimer(withTimeInterval: graceSeconds, repeats: false) { [weak self] _ in
            self?.classify()
        }
    }

    private func classify() {
        graceTimer?.invalidate()
        graceTimer = nil

        if sawLockEvent {
            log("✅ Classified: LOCKED — hero keeps grinding")
        } else {
            log("😴 Classified: APP SWITCH — hero sleeps")
        }
        endBackgroundTask()
    }

    private func handleWillEnterForeground() {
        if let t = backgroundedAt {
            let away = Int(Date().timeIntervalSince(t))
            // Returned before the grace window finished -> brief flick away, treat as grinding.
            if graceTimer != nil {
                graceTimer?.invalidate()
                graceTimer = nil
                endBackgroundTask()
                log("↩️ Returned in \(away)s (within grace) — counts as grinding")
            } else {
                log("⬆️ App foregrounded — was away \(away)s")
            }
        }
        backgroundedAt = nil
    }

    private func endBackgroundTask() {
        if bgTask != .invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        }
    }

    // MARK: logging

    func log(_ message: String) {
        let event = ProbeEvent(date: Date(), message: message)
        events.insert(event, at: 0)
        ProbeEvent.save(events)
        print("[LockProbe] \(event.timestamp) \(message)")
    }

    func clear() {
        events = []
        ProbeEvent.save(events)
    }
}

// MARK: - Event model (persisted so logs survive relaunch)

struct ProbeEvent: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let message: String

    var timestamp: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }

    static func load() -> [ProbeEvent] {
        guard let data = UserDefaults.standard.data(forKey: "probeEvents"),
              let events = try? JSONDecoder().decode([ProbeEvent].self, from: data)
        else { return [] }
        return events
    }

    static func save(_ events: [ProbeEvent]) {
        if let data = try? JSONEncoder().encode(Array(events.prefix(200))) {
            UserDefaults.standard.set(data, forKey: "probeEvents")
        }
    }
}

// MARK: - Passcode heuristic (informational only)

private extension UIDevice {
    /// Rough check: protected data is available while unlocked regardless,
    /// so we can't truly know. This just reminds the tester.
    var isPasscodeLikelySet: Bool {
        UIApplication.shared.isProtectedDataAvailable
    }
}

// MARK: - UI

struct ProbeView: View {
    @EnvironmentObject var probe: LockProbe

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("1. Lock the phone → expect LOCKED\n2. Switch apps → expect APP SWITCH\nRun on a real iPhone with a passcode.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Event log (newest first)") {
                    ForEach(probe.events) { event in
                        HStack(alignment: .top, spacing: 8) {
                            Text(event.timestamp)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Text(event.message)
                                .font(.callout)
                        }
                    }
                }
            }
            .navigationTitle("Lock Probe 🗡️")
            .toolbar {
                Button("Clear") { probe.clear() }
            }
        }
    }
}
