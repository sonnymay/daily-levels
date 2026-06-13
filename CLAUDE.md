# Daily Levels — Project State

> **What this is:** A calm, minimal native-SwiftUI iOS focus timer. Every 5 min of focus =
> 1 level; resets at midnight; light-RPG visuals as motivation (NOT a game). One screen.
>
> **Source of truth:** [`SPEC.md`](SPEC.md) — read it fully before changing anything.
> (SPEC's working title was "Minute Knight"; the app is named **Daily Levels**. Mechanics unchanged.)

## Phase status

| Phase | Scope (SPEC §) | Status |
|---|---|---|
| **1. Lock-detection probe** | §6, §8 | ✅ Logic ported into the app. **Hardware A–D test still unverified** (user chose to proceed). |
| **2. Engine** | §5 — sessions, level math, daily class, midnight split/reset, SwiftData, unit tests | ✅ Done. 10 unit tests pass. |
| **3. Main screen** | §4 — single screen per mockup, placeholder hero | ✅ Done. Builds + renders on simulator. |
| 4. Sprites · 5. Polish | §8 | Next. Hero panel is a drop-in target for video loops (see below). |

> ⚠️ **Unverified gate:** Phase 1's lock detection was never confirmed on a physical iPhone.
> The whole "phone-locked = keep grinding" behavior rides on it. The risky logic is isolated in
> [`LockClassifier.swift`](DailyLevels/LockClassifier.swift) so if hardware testing fails, only
> that file changes. Run [`TESTING.md`](TESTING.md) on a real device to close the gate.

## Architecture

```
DailyLevels/
├── LevelMath.swift        # pure: level = floor(min/5)            ← unit-tested
├── KnightClass.swift      # pure: §3 class ladder                 ← unit-tested
├── DateUtils.swift        # pure: splitAtMidnights()              ← unit-tested
├── Models.swift           # @Model FocusSession (SwiftData) + DaySummary value type
├── LockClassifier.swift   # §6 lock-vs-app-switch (ported probe), isolated + swappable
├── FocusEngine.swift      # @Observable @MainActor: state, ticker, SwiftData, midnight, lifetime
├── Theme.swift            # cream palette + Color(hex:)
├── DailyLevelsApp.swift   # @main: ModelContainer + shared FocusEngine via .environment
└── Views/
    ├── MainView.swift         # screen layout + Header, ClassBadge, ProgressSection, StartPauseButton, Format
    ├── HeroScenePanel.swift   # video > image asset > placeholder
    ├── LoopingVideoView.swift # AVFoundation gapless loop (no deps)
    └── FocusHistoryCard.swift # 7-day bar chart + day list
DailyLevelsTests/          # LevelMath, KnightClass(10/11·30/31·60/61), MidnightSplit
```

**Data flow:** `FocusEngine` is the single source of truth, injected once via `.environment`.
Views are `@Environment(FocusEngine.self)` and pure-derive everything (level, class, progress,
history) from `now` (1s ticker) + `completedSecondsByDay` (cached SwiftData fetch). No view owns
state. Sleeping time is never persisted, so summing `FocusSession.durationSeconds` is always focus time.

## How the animation drops in (Phase 4 — your ChatGPT→Kling workflow)

`HeroScenePanel` resolves art in this order, all native, no code change needed:
1. **Looping video** — add `grind_loop.mp4` / `sleep_loop.mp4` to the **DailyLevels** target → auto-plays.
2. **Static image** — add image set `HeroGrinding` / `HeroSleeping` to `Assets.xcassets`.
3. Built-in placeholder (current).

## Build · test · run

```bash
SIM=C494865D-5987-4B80-A5D4-EE9EAD88FAA5   # iPhone 16 (any iOS 17+ sim works)
xcodebuild -project "DailyLevels.xcodeproj" -scheme DailyLevels -destination "id=$SIM" build
xcodebuild -project "DailyLevels.xcodeproj" -scheme DailyLevels -destination "id=$SIM" test
# Device: open DailyLevels.xcodeproj in Xcode, set Signing Team, pick your iPhone, Run.
```
Last verified: **BUILD SUCCEEDED**, **10/10 tests pass**, app launches and renders on iPhone 16 sim (Xcode 26.5).

## Decisions

- Native SwiftUI only, **zero third-party deps**. Name "Daily Levels"; bundle `com.santipapmay.DailyLevels`; iOS 17.0.
- **Class ladder (SPEC §3): 10 bands of 10 levels** — Novice, Squire, Swordsman, Knight, Crusader, Champion, Paladin, Hero, Legend, **Mythic**. Daily **level caps at 100** (500 min = 8h20m); UI shows a "Max level — Mythic!" state at the cap. DEBUG `-seedDemoData`/`-autoStart` launch args populate/auto-grind for screenshots.
- Project file hand-written (no xcodegen) using Xcode 26 **file-system-synchronized groups** — new
  `.swift` files under `DailyLevels/` or `DailyLevelsTests/` are auto-included; you rarely touch `project.pbxproj`.
- iOS 17 patterns used: `@Observable` + `@Environment(Type.self)` (modern replacement for ObservableObject/@EnvironmentObject); SwiftData `@Model`/`ModelContainer`.
- Bar chart hand-rolled (not Swift Charts) to match the mockup's soft-green rounded bars exactly.
- Crash recovery is conservative (SPEC §5 edge 5): a session interrupted by app-kill is discarded, not credited.

## Out of scope for v1 (SPEC §9 — do not add without asking)

Tabs · full history screen · settings · streaks · daily-goal card · loot/items/coins/HP ·
multiple zones/monsters-as-content · accounts/sync · widgets/Live Activities · Android.
The "History" link in the card is intentionally **inert** (reserved for v1.1).

## Known follow-ups

- Close the Phase-1 hardware gate (`TESTING.md`).
- Grace window is 30s (SPEC default) in `LockClassifier`; tune after device testing.
- No-passcode devices can't get lock notifications → backgrounding always reads as app-switch;
  SPEC §6 suggests a kind fallback (treat as grinding) — add only if real users hit it.
- Sprites/animations (Phase 4), level-up & class-change moments, app icon (Phase 5).
