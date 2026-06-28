# Daily Levels: Focus Timer

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS_17+-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/swiftui/)
[![App Store](https://img.shields.io/badge/App_Store-Daily_Levels-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/app/id6746621860)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)

**Every 5 minutes of focus levels up your hero. Stay off your phone — the hero grinds. Resets at midnight.**

A calm, minimal focus timer with light RPG visuals as motivation. Inspired by the Health app's step counter, but for deep work. Free to start · one-time Pro unlock to go all the way to Mythic.

**[Download on the App Store →](https://apps.apple.com/app/id6746621860)**

---

## App Screenshots

| | | |
|:---:|:---:|:---:|
| ![Level Up](AppStore/screenshots/captioned/01_levelup.png) | ![Lock Screen](AppStore/screenshots/captioned/02_lock.png) | ![Mythic](AppStore/screenshots/captioned/03_mythic.png) |
| Watch your hero level up | Lock your phone — focus keeps counting | Climb all the way to Mythic |
| ![History](AppStore/screenshots/captioned/04_history.png) | ![Pro Unlock](AppStore/screenshots/captioned/05_paywall.png) | ![Intro](AppStore/screenshots/captioned/06_intro.png) |
| See your focus add up | No subscription — unlock Pro once | Calm. One screen. No noise. |

---

## The Daily Class Ladder

Every day starts fresh. Everyone wakes up a Novice. Your class is a badge for today's effort — resets at midnight.

| Class | Daily Level | Focus Time | Screenshot |
|:---:|:---:|:---:|:---:|
| **Novice** | 1–10 | up to 50 min | ![Novice](AppStore/screenshots/01_novice.png) |
| **Squire** | 11–20 | ~1–1.7 hrs | ![Squire](AppStore/screenshots/02_squire.png) |
| **Swordsman** | 21–30 | ~1.7–2.5 hrs | ![Swordsman](AppStore/screenshots/03_swordsman.png) |
| **Knight** ⚔️ | 31–40 | ~2.6–3.3 hrs | ![Knight](AppStore/screenshots/04_knight.png) |
| **Crusader** | 41–50 | ~3.4–4.2 hrs | ![Crusader](AppStore/screenshots/05_crusader.png) |
| **Champion** | 51–60 | ~4.2–5 hrs | ![Champion](AppStore/screenshots/06_champion.png) |
| **Paladin** | 61–70 | ~5–5.8 hrs | ![Paladin](AppStore/screenshots/07_paladin.png) |
| **Hero** | 71–80 | ~5.9–6.7 hrs | ![Hero](AppStore/screenshots/08_hero.png) |
| **Legend** | 81–90 | ~6.8–7.5 hrs | ![Legend](AppStore/screenshots/09_legend.png) |
| **Mythic** 🏆 | 91–100 | ~7.6–8h20m | ![Mythic](AppStore/screenshots/10_mythic.png) |

> Knight (Level 31 · ~2.6 hrs) is the aspirational everyday milestone. Mythic (Level 100 · 8h20m) is the once-in-a-blue-moon flex worth screenshotting.

---

## How It Works

```
5 minutes of focus = 1 level
Daily level = min(100, floor(todayFocusMinutes / 5))
Resets at midnight (local time) · Cap = Level 100 = 8h20m
```

**Grinding** (hero fights & walks) — timer ticks when:
- App is in the foreground
- Phone is locked ✅ ← living your life counts

**Sleeping** (hero rests by campfire) — timer pauses when:
- You switch to another app ← doomscrolling doesn't count
- You tap Pause

**Hero (Lifetime) Level** — the sum of all daily levels ever earned. Never resets. Shown as a badge. Your permanent record.

---

## Features

- **One screen, one button** — Start / Pause. Nothing else.
- **Lock detection** — phone locked = still grinding; other app = sleeping. Uses `protectedDataWillBecomeUnavailable` to distinguish the two.
- **10-class daily ladder** — Novice → Mythic, reset every midnight
- **Lifetime hero level** — cumulative XP badge that never resets
- **7-day focus history** — bar chart + list of recent days with levels and focus time
- **Free + Pro** — free through first few classes; one-time unlock to reach Mythic
- **No account, no tracking** — everything stays on device (SwiftData)
- **iOS Home Screen widget** — glanceable level + class badge
- **Localized** — English, Spanish, Portuguese, German, French, Japanese

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI | SwiftUI (iOS 17+) |
| Persistence | SwiftData |
| IAP | StoreKit 2 (non-consumable Pro unlock) |
| Background | `BGTaskScheduler` + `UIApplication.beginBackgroundTask` |
| Lock detection | `protectedDataWillBecomeUnavailable` / `protectedDataDidBecomeAvailable` |
| Widget | WidgetKit |
| Tests | XCTest |
| CI | Xcode Cloud / GitHub Actions |

---

## What This Code Shows

- **Lock vs. app-switch detection** — distinguishing phone-locked (keep counting) from app-switched (pause) using iOS protected data notifications — a non-trivial native problem
- **StoreKit 2 integration** — non-consumable IAP with receipt validation, paywall gating, and restore purchases
- **SwiftData persistence** — session modelling, midnight-split logic, derived daily summaries
- **WidgetKit** — home screen widget surfacing live level + class
- **SwiftUI single-screen architecture** — one view, two states (grinding / sleeping), smooth animated transitions
- **Background task lifecycle** — correct use of `beginBackgroundTask` + grace timer + state reconciliation on foreground

---

## Project Structure

```
DailyLevels/
├── DailyLevels/          # Main app target
│   ├── Models/           # SwiftData models: FocusSession, DailySummary, Hero
│   ├── Views/            # SwiftUI views (single main screen + history)
│   ├── Services/         # FocusEngine, LockDetector, SessionStore
│   └── Resources/        # Assets, localizations
├── DailyLevelsTests/     # XCTest unit tests
├── widget/               # WidgetKit extension
└── AppStore/             # Store metadata, screenshots, submission docs
    ├── screenshots/      # Hero class shots (01_novice → 10_mythic)
        │   └── captioned/    # 6 captioned App Store screenshots
            ├── METADATA.md       # App Store listing copy + ASO strategy
                ├── SUBMISSION.md     # Step-by-step submission checklist
                    └── GROWTH.md         # Freemium strategy + growth playbook
                    ```

                    ---

                    ## Build & Run

                    ```bash
                    git clone https://github.com/sonnymay/daily-levels.git
                    open DailyLevels.xcodeproj
                    ```

                    Select your device and run. **Lock detection requires a physical iPhone with a passcode** — the simulator cannot fire `protectedDataWillBecomeUnavailable`.

                    For IAP testing, use a StoreKit configuration file in Xcode (`DailyLevels.storekit`) — no sandbox account needed in development.

                    ---

                    ## App Store Listing

                    **Title:** Daily Levels: Focus Timer
                    **Subtitle:** Pomodoro deep work for study
                    **Category:** Productivity · Health & Fitness
                    **Price:** Free · Pro unlock $6.99 (one-time)
                    **Bundle ID:** `com.santipapmay.DailyLevels`

                    ---

                    ## License

                    MIT
