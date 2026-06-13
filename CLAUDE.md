# Daily Levels — Project State

> **What this is:** A calm, minimal native-SwiftUI iOS focus timer. Every 5 min of focus =
> 1 level; resets at midnight; light-RPG visuals as motivation (NOT a game). One screen.
>
> **Source of truth:** [`SPEC.md`](SPEC.md) — read it fully before changing anything.
> (SPEC's working title was "Minute Knight"; the app is now named **Daily Levels**. Mechanics unchanged.)

## Phase status

| Phase | Scope (SPEC §) | Status |
|---|---|---|
| **1. Lock-detection probe** | §6, §8 — prove LOCKED vs APP SWITCH on hardware | ✅ Built, builds clean. **Awaiting user hardware verification (tests A–D).** |
| **2. Engine** | §5 — sessions, level math, daily class, midnight split/reset, SwiftData, unit tests | ⛔ Not started — blocked on Phase 1 hardware pass |
| **3. Main screen** | §4 — single screen per mockup, static hero placeholder | ⛔ Not started |
| 4. Sprites · 5. Polish | §8 | Later |

**Current gate:** Phase 1 is a go/no-go gate. Do NOT start Phase 2 until the user confirms
tests A–D classify correctly on a physical iPhone (see [`TESTING.md`](TESTING.md)).

## Layout

```
Daily Levels/
├── DailyLevels.xcodeproj/         # hand-written project (no xcodegen)
│   ├── project.pbxproj            # objectVersion 77, file-system-synchronized group
│   └── xcshareddata/xcschemes/DailyLevels.xcscheme   # shared scheme (headless xcodebuild)
├── DailyLevels/                   # all app source lives here (auto-synced into the target)
│   ├── LockProbeApp.swift         # Phase 1 probe — @main app, verbatim from the provided file
│   └── Assets.xcassets/           # AppIcon + AccentColor (placeholders)
├── SPEC.md · TESTING.md · CLAUDE.md
```

## Key decisions

- **Native SwiftUI only, zero third-party deps** (hard constraint). The risky bits
  (protected-data notifications, background tasks) are all native APIs.
- **Name:** Daily Levels · target `DailyLevels` · display name "Daily Levels".
- **Bundle ID:** `com.santipapmay.DailyLevels` · **Deployment target:** iOS 17.0.
- **Project file is hand-written** because `xcodegen` isn't installed and a tool would add a
  dependency. Xcode 26's **file-system-synchronized root group** means new `.swift` files added
  under `DailyLevels/` are picked up automatically — you normally never edit `project.pbxproj`.
- **`LockProbeApp.swift` is kept byte-for-byte as provided.** The `@main struct LockProbeApp`
  name is intentional and independent of the target name.

## Build & run

```bash
# Build (verify) on a simulator — no code-signing needed:
xcodebuild -project "DailyLevels.xcodeproj" -scheme DailyLevels \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run on hardware: open DailyLevels.xcodeproj in Xcode, set your Signing Team, pick your iPhone, Run.
```
Last verified: **BUILD SUCCEEDED** on iPhone 16 simulator (iOS 18.6 SDK), Xcode 26.5.

## Out of scope for v1 (SPEC §9 — do not add without asking)

Tabs · full history screen · settings beyond minimum · streaks · daily-goal card ·
loot/items/coins/HP · multiple zones / monsters-as-content · accounts/sync · widgets/Live
Activities · Android. The hero scene is **visual motivation only** — no game systems.

## Next session entry point

1. Read `SPEC.md`, then this file.
2. If the user has confirmed Phase 1 tests A–D passed → start **Phase 2 (engine, §5)**:
   `FocusSession` / `DailySummary` / `Hero`, `level = floor(focusMinutes/5)`, class table (§3),
   midnight session-split reset, SwiftData persistence, unit tests (level math, class boundaries
   10/11·30/31·60/61, midnight-crossing session). Plain debug UI only — no main screen yet.
3. If not yet confirmed → wait; do not build past the gate.
