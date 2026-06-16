# Minute Knight — Product Spec v1.0

> Working name: **Minute Knight** (pun on "midnight" — when daily levels reset).
> Backup names: 5 Minute Knight, Knightly. Confirm App Store availability before release.
>
> One-liner: *A focus timer where every 5 minutes of focus levels up your hero. Stay off your phone; the hero grinds. Resets at midnight.*

---

## 1. What this app is (and is not)

**Is:** A calm, minimal focus timer (like Forest) with light RPG visuals as motivation. One screen. Two buttons states (Start/Pause). Daily progress like the iPhone Health step counter.

**Is NOT:** A game. No inventory, quests, coins, HP systems, monsters-as-gameplay, battles, or rewards economy. The hero scene is **visual motivation only**.

**Tone:** Kind, not guilt-based. The hero never dies or loses progress. The only "failure" state is the hero falling asleep.

---

## 2. Core mechanics

| Rule | Value |
|---|---|
| Focus → level rate | **5 minutes of focus = 1 level** |
| Daily level | `min(100, floor(todayFocusMinutes / 5))` — resets at **midnight local time**. Caps at **100** (500 min = 8h20m, a perfect deep-work day) |
| History | Previous days kept forever (date, level reached, total focus time) |
| Hero (lifetime) level | Sum of all levels ever earned; never resets; shown as a badge |
| Daily class | Based on **today's** level (see §3); resets at midnight with the level |

**Examples:** 20 min = Level 4 · 25 min = Level 5 · 60 min = Level 12 · 65 min = Level 13.

### Focus states

| State | Trigger | Effect |
|---|---|---|
| **Grinding** | User taps Start; app in foreground OR phone locked | Minutes count; hero animates fighting/walking |
| **Sleeping** | User taps Pause, OR user switches to another app (after ~30s grace) | Minutes do NOT count; hero sleeps by a campfire |

Phone locked = still grinding (user is living their life — that's the point).
Other apps open = sleeping (user is doomscrolling — no EXP for that).

---

## 3. Daily class ladder

Class is derived from **today's** level. Everyone wakes up a Novice.

| Daily level | Class | Focus time |
|---|---|---|
| 1–10 | Novice | up to 50 min |
| 11–20 | Squire | ~1–1.7 hrs |
| 21–30 | Swordsman | ~1.7–2.5 hrs |
| 31–40 | Knight | ~2.6–3.3 hrs |
| 41–50 | Crusader | ~3.4–4.2 hrs |
| 51–60 | Champion | ~4.2–5 hrs |
| 61–70 | Paladin | ~5–5.8 hrs |
| 71–80 | Hero | ~5.9–6.7 hrs |
| 81–90 | Legend | ~6.8–7.5 hrs |
| 91–100 | Mythic | ~7.6–8.3 hrs (the daily cap) |

(Level 0, before any focus, is also Novice — everyone wakes up a Novice.)

Class is a **label only** — no stats, no abilities, no unlocks. The escalation is intentional:
ranks 1–4 are normal days (most users live here), 5–7 are serious study/work days, 8–9 are
exam-week territory, and **Mythic** (level 100 = 8h20m) is the once-in-a-blue-moon flex worth
screenshotting. Reaching "Knight" at level 31 (~2.6 hrs) is the aspirational everyday milestone.

---

## 4. Main screen (single screen — see mockup)

Design reference: light cream mockup (June 12, 2026). Light, minimal, iOS-native feel. NOT dark/gamer aesthetic.

Top to bottom:

1. **Header (left):** "Today" (small gray) → "Level 4" (large bold) → "20 min focused today" (gray) → "⏳ 5 min = 1 level" (small gray caption)
2. **Header (right):** Class badge — current daily class (e.g., "Novice"). Tap target may later show the class ladder.
3. **Hero scene panel:** Rounded card with pixel-art scene. Two animation states: grinding (hero walks/fights a slime) and sleeping (hero by campfire). Original character design — NOT Ragnarok Online assets (IP).
4. **Progress bar:** Fill = minutes into current level (0–5 min). Left label: "20 min focused today" + "Current session 12:34" beneath. Right label: "Next level in X min" (never show "0 min" — show "Level up!" moment instead).
5. **Focus History card:** Title "Focus History" + caption "Levels earned each day · resets at midnight". Small bar chart: last 7 days, oldest→newest, rightmost bar = "Today" in darker green, others soft green. Below chart: list of recent days — `Date · Level N · X min focus time` with chevron. "History" link reserved for a full-history screen (v1.1, not v1).
6. **Bottom button:** One large pill button. Grinding → green "⏸ Pause". Paused/idle → "▶ Start". Icon must always match the action.

No tab bar. No settings screen in v1 (or a single sheet at most). No other buttons.

---

## 5. Data model

```
FocusSession
- id: UUID
- startAt: Date
- endAt: Date
- durationSeconds: Int   // grinding time only (sleeping time excluded)

DailySummary (derived or cached)
- date: YYYY-MM-DD (local)
- focusMinutes: Int
- level: Int             // floor(focusMinutes / 5)
- class: String          // derived from level via §3 table

Hero
- lifetimeLevels: Int    // sum of all DailySummary.level (or recompute)
```

Storage: local first (SwiftData/CoreData or SQLite). No accounts, no backend in v1. iCloud sync = later.

### Edge cases (must handle)
1. **Session crosses midnight:** split into two sessions at 12:00:00 AM local so each day gets its own minutes. Daily level/class reset applies at the split.
2. **Sleeping time never counts.** Only grinding seconds accumulate.
3. **Timezone change / DST:** "midnight" = local time at that moment; acceptable v1 simplification.
4. **Clock tampering:** ignore for v1 (single-player, who cares).
5. **App killed mid-session:** persist session start; on relaunch, recover using last-known state conservatively (count only provable grinding time).

---

## 6. Lock detection (the critical technical piece)

**Problem:** iOS reports "app backgrounded" identically for (a) phone locked and (b) user switched to another app. We must distinguish them: (a) = keep grinding, (b) = hero sleeps.

**Approach:**
- On `didEnterBackground`: start a ~30s background task + grace timer; assume nothing yet.
- If `protectedDataWillBecomeUnavailable` fires → device locked → classify **LOCKED**, keep counting time.
- If grace timer expires with no lock notification → classify **APP SWITCH** → stop counting from background time; hero sleeps.
- On `willEnterForeground` / `protectedDataDidBecomeAvailable`: reconcile elapsed time according to classification.

**Known caveats (verify in prototype):**
- Requires a device passcode; without one, protected-data notifications never fire → fallback: treat all backgrounding as grinding (be generous, stay kind).
- Lock notification can be delayed (passcode grace period settings). Tune the grace window on real hardware.
- Must test on a **physical iPhone with passcode** — simulator is unreliable for this.

**This is build step 1. If it fails on hardware, the design changes — do not build the UI first.**

---

## 7. Tech stack (recommendation)

**SwiftUI, native iOS.** Rationale: single screen, but the hard parts (protected-data notifications, background tasks, local notifications, Live Activity later) are all native APIs. React Native would need a custom native module for exactly the risky part. App is small enough that SwiftUI is learnable in days, and AI codegen handles SwiftUI well.

If RN is strongly preferred (existing familiarity): RN UI + one small native Swift module for lock detection. Acceptable, more moving parts.

Sprites: layered PNG sprite sheets (AI-generated, then cleaned). Two animations minimum: grind loop, sleep loop. No video.

---

## 8. Build order

1. **Lock-detection prototype** — bare app logging LOCKED vs APP SWITCH correctly on hardware. *Go/no-go gate.*
2. **Engine** — session tracking, level math, midnight split/reset, persistence. Plain debug UI.
3. **Main screen** — full UI per §4, static hero image placeholder.
4. **Sprites** — grinding + sleeping animations wired to state.
5. **Polish** — level-up moment, class-change moment, app icon, TestFlight.

## 9. Explicitly out of scope for v1

Tabs · full History screen · settings beyond minimum · streaks · daily goal card · loot/items/coins/HP · multiple zones or monsters-as-content · accounts/sync · widgets/Live Activities · Android.

(Good v1.1 candidates: full history screen, streaks, Live Activity on lock screen, class-change celebration share card.)

## 10. Open items

- [ ] Confirm "Minute Knight" availability on App Store (then reserve the name in App Store Connect)
- [ ] Final character design (original, not RO) — sprite sheet generation
- [ ] Grace-window tuning after prototype (start at 30s)
- [ ] App icon
- [ ] Write onboarding copy (first-launch tooltip or empty-state message)
