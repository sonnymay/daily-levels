# TESTING — Phase 1: Lock-Detection Probe

This is the **go/no-go gate** for Daily Levels (SPEC.md §6, §8). The whole app depends on
iOS being able to tell these two cases apart:

| Situation | What iOS reports | What we want |
|---|---|---|
| **LOCKED** — you press the side button / phone auto-locks | `didEnterBackground` **+** `protectedDataWillBecomeUnavailable` | hero keeps grinding (time counts) |
| **APP SWITCH** — you open another app / go Home | `didEnterBackground` only | hero sleeps (time does **not** count) |

Both fire `didEnterBackground` identically. Only **locking** fires
`protectedDataWillBecomeUnavailable` (and only when a device passcode is set). The probe
waits a short grace window after backgrounding: if the lock notification arrives → LOCKED;
if it never arrives → APP SWITCH.

**If A–D below classify correctly on real hardware, the design is safe and we proceed to
Phase 2. If they don't, the design changes — do not build the engine/UI first.**

---

## Prerequisites

1. A **physical iPhone** with a **passcode set** (Settings → Face ID & Passcode).
   - The simulator's lock notifications are unreliable — **do not trust simulator results.**
   - Without a passcode, `protectedData…` notifications never fire; the design's fallback is to
     treat all backgrounding as grinding (generous/kind). Test that case too if relevant.
2. Open `DailyLevels.xcodeproj` in Xcode, select your iPhone as the run destination, set your
   Signing Team (target **DailyLevels** → Signing & Capabilities → your Apple ID), and press Run.
3. Watch the in-app **event log** (newest first). Tap **Clear** between tests to keep it readable.

---

## Test script

Run each test, then return to the app and read the log.

### A. Lock → expect LOCKED
Press the side button to lock the phone. Wait ~15s. Unlock and return to the app.
**EXPECT:** `🔒 Device locked` then `✅ Classified: LOCKED — hero keeps grinding`.

### B. App switch → expect APP SWITCH
Swipe up to the Home screen (or open another app). Wait ~15s. Return to the app.
**EXPECT:** no lock event, then `😴 Classified: APP SWITCH — hero sleeps`.

### C. Switch first, then lock → expect APP SWITCH
Open another app, **then** lock the phone. Return to the probe.
**EXPECT:** `😴 Classified: APP SWITCH` — they left the app first, which is correct (no EXP for doomscrolling).

### D. Long lock → LOCKED with accurate elapsed time
Lock the phone, wait **2 minutes**, then unlock.
**EXPECT:** `LOCKED`, and the "was away Ns" elapsed time on return is accurate (~120s).

### E. Passcode grace period (informational)
Settings → Face ID & Passcode → **Require Passcode**. If it's set to anything other than
"Immediately" (e.g. "After 5 minutes"), repeat **Test A** and note any delay before the lock
notification arrives. This tells us how to tune the grace window (SPEC §6, §10 — starts at 30s).

---

## Pass criteria

- ✅ **A–D classify correctly** → lock detection works → **GO**: proceed to Phase 2 (engine).
- ❌ Any of A–D misclassifies → **NO-GO**: report what you saw; the approach needs rework before any UI.

## Notes for the tester

- The grace window in the probe is **10s** (`graceSeconds` in `LockProbeApp.swift`); the spec
  starts the real app at 30s. Returning to the app *within* the grace window counts as grinding
  (a brief flick away is forgiven).
- Logs persist across relaunch (stored in UserDefaults), so you can force-quit and reopen to
  confirm an event was recorded.
