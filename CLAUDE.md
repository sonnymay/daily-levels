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
| **4. Sprites** | §8 — grinding animation per class | ✅ 10 Kling clips wired (`<class>_grind.mp4`), compressed 122MB→21MB. Sleeping now uses per-class `<class>_sleep.png` stills (no `sleep_loop.mp4` yet). |
| **5. Polish / App Store** | §8 — icon, metadata, submission | 🔶 Live on App Store Connect (App ID **6780007939**). Build **3** (1.0) uploaded + processing (incl. pause/resume fix, haptics, level-up celebration + notifications, per-class sleep art, accessibility, light-mode lock, first-run intro). Metadata, privacy (Data Not Collected), age **9+**, price **$0.99**, availability all 175 regions, App Review contact (Sonny May, phone) — all set. **Remaining: attach build 3, drag 10 screenshots + click Add for Review → Submit (account-owner only).** |

### App Store Connect state (for next session)
- App: **Daily Levels**, App ID `6780007939`, bundle `com.santipapmay.DailyLevels`, Team `57U5D693VS`, ASC Issuer `69a6de7a-0b32-47e3-e053-5b8c7c11a4d1`.
- App icon: user-provided knight art (`~/Downloads/app_icon_source.png` → resized into the asset catalog). Build number is now **3** (uploaded 2026-06-14; `CURRENT_PROJECT_VERSION = 3`). Archive needs `DEVELOPMENT_TEAM=57U5D693VS` passed on the `xcodebuild` command (not stored in pbxproj).
- Price **$0.99** (paid; Paid Apps agreement active). Age rating **9+** (cartoon/fantasy violence = Infrequent).
- Screenshots: 10-class set in `AppStore/screenshots/` + 6.5″ copies in `~/Downloads/dl_screens/`. ASC's web uploader rejects agent file uploads (allowlist), so screenshots must be **dragged in by the user**.
- Re-archive/upload recipe: `xcodebuild ... archive` then `xcodebuild -exportArchive -exportOptionsPlist /tmp/UploadOptions.plist` (destination=upload). Bump `CURRENT_PROJECT_VERSION` for each new upload.

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

## Hero animation (Phase 4 — wired)

`HeroScenePanel(grinding:className:)` resolves art in this order, all native:
1. **Looping video** — grinding plays `"<class>_grind.mp4"` (novice…mythic, bundled & compressed);
   sleeping plays `sleep_loop.mp4` if present. `.id(url)` swaps the clip when the class changes.
2. **Static image** — `HeroGrinding` / `HeroSleeping` in `Assets.xcassets` (fallback).
3. Built-in placeholder (final fallback / classes without a clip yet).

Videos are H.264, 1080-wide, CRF 26, audio-stripped (~1–2MB each, 21MB total). To re-compress
new clips: `ffmpeg -i in.mp4 -an -vf scale=1080:-2:flags=lanczos -c:v libx264 -crf 26 -preset slow -movflags +faststart out.mp4`.

## Build · test · run

```bash
SIM=C494865D-5987-4B80-A5D4-EE9EAD88FAA5   # iPhone 16 (any iOS 17+ sim works)
xcodebuild -project "DailyLevels.xcodeproj" -scheme DailyLevels -destination "id=$SIM" build
xcodebuild -project "DailyLevels.xcodeproj" -scheme DailyLevels -destination "id=$SIM" test
# Device: open DailyLevels.xcodeproj in Xcode, set Signing Team, pick your iPhone, Run.
```
Last verified: **Debug + Release BUILD SUCCEEDED**, **12/12 tests pass**, per-class videos play, app
runs on iPhone 16 / 16 Pro Max sims (Xcode 26.5). DEBUG screenshot flags: `-seedDemoData -autoStart -todayMinutes N`.

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
