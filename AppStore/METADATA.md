# Daily Levels — App Store listing copy

Paste into App Store Connect → your app → **App Information** / **Version Information**.
Limits are Apple's hard caps. **This reflects the Free + one-time "Pro" unlock model** (see
[GROWTH.md](GROWTH.md) for the strategy and [SUBMISSION.md](SUBMISSION.md) for the steps).

> ASO principle used throughout: the **Title** is the highest-weight field, **Subtitle** second,
> **Keywords** third. Put your best search terms in the Title/Subtitle, then **never repeat**
> those words in the Keyword field (Apple already indexes them) — use the 100 chars for *new* terms.

## App name / Title (30 chars max)
```
Daily Levels: Focus Timer
```
(25 chars — brand + the #1 search term in the strongest slot. Alt: `Daily Levels — Study Timer`.)

## Subtitle (30 chars max)
```
Pomodoro deep work for study
```
(28 chars. Adds pomodoro / deep work / study. Alt, more emotional: `Make focusing feel rewarding`.)

## Keywords (100 chars max, comma-separated, NO spaces, no repeats of Title/Subtitle)
```
concentration,productivity,adhd,session,reading,homework,attention,gamified,rpg,habit,grind,mindful
```
(99 chars. Deliberately omits focus/timer/pomodoro/deep/work/study — already in Title+Subtitle
(dropped "deepfocus" which duplicated those + pushed it to 101). The **rpg / gamified / grind**
terms are a near-uncontested long-tail our hero mechanic can own; "mindful" adds a fresh lane.)

## Promotional text (170 chars, editable anytime without review)
```
Free to start. Every 5 minutes of focus levels up your hero — Novice to Mythic. Unlock Pro once to evolve all the way. No ads, no tracking. A fresh climb every day.
```

## In-App Purchase (create in ASC → Features → In-App Purchases)
- **Type:** Non-Consumable
- **Reference Name:** Daily Levels Pro
- **Product ID:** `com.santipapmay.DailyLevels.pro`  ← must match `Store.proProductID` in code
- **Price:** launch **Tier $6.99** ("Founder's price"); plan to raise to **$9.99** later
- **Display Name:** `Daily Levels Pro`
- **Description:** `Evolve your hero through all 10 classes — Knight to Mythic. No ads, no tracking. One-time unlock, yours forever.`
- **Review screenshot:** use the paywall screenshot (1290×2796 or any required size)
- Submit the IAP **together with** the app version that contains it (first StoreKit build = build 4).

## Description (4000 chars max)
```
Daily Levels turns focus into a daily climb.

Every 5 minutes you stay focused earns 1 level. Tap Start and your hero gets to work — fighting, walking, grinding. The longer you focus, the higher you climb, from Novice all the way to Mythic. At midnight it all resets, so every day is a fresh run.

Put your phone down and the hero keeps grinding — locking your phone still counts, because living your life is the whole point. Switch to another app and the hero falls asleep by the campfire. No focus, no progress. Kind, never punishing: the hero never dies and never loses what you earned.

ONE SCREEN. NO NOISE.
Daily Levels is deliberately simple. One screen, one button. No feeds, no streaks to guilt you, no coins, no ads. Just today's level, your class, and a clean history of how each day went — like the Health app's step count, but for focus.

THE DAILY CLASS LADDER
Your class is a badge for today's effort, reset every midnight:
• Novice — up to 50 min
• Squire — ~1–1.7 hrs
• Swordsman — ~1.7–2.5 hrs
• Knight — ~2.6–3.3 hrs
• Crusader — ~3.4–4.2 hrs
• Champion — ~4.2–5 hrs
• Paladin — ~5–5.8 hrs
• Hero — ~5.9–6.7 hrs
• Legend — ~6.8–7.5 hrs
• Mythic — a perfect 8h20m deep-work day

Reaching Knight is the everyday milestone. Mythic is the once-in-a-blue-moon flex.

FREE TO START · PRO TO GO FURTHER
Daily Levels is free: focus, level up, and watch your hero evolve through its first three classes. A single one-time Pro unlock evolves your hero the rest of the way to Mythic — no subscription, no renewals, yours forever.

PRIVATE BY DESIGN
Everything stays on your device. No account, no sign-up, no servers, no tracking, no ads. Your focus history is yours alone.

Start your climb today.
```

## Screenshot captions (captions are indexed for ASO since 2025 — use keywords)
Order — lead with the payoff, then mechanic, proof, depth:
1. **"Watch your hero level up"** — the level-up / class-change moment (the differentiator)
2. **"Every 5 min of focus = 1 level"** — timer running mid-session
3. **"Lock your phone — focus keeps counting"** — the trust/mechanic shot
4. **"See your focus add up"** — the 7-day history chart
5. **"10 classes, Novice → Mythic"** — the class ladder / aspiration

Asset sizes: provide **6.9″ iPhone (1290×2796)**; ASC derives smaller sizes. PNG for crisp text.

## App Preview video (optional, high-impact for a gamified app)
A 15–30s clip: timer running → minutes climb → hero levels up / changes class. Source recording
produced at `/tmp/dl_preview.mp4` via the simulator (`-autoStart -seedDemoData -unlockPro
-autoStartSecondsAgo`). It is the simulator's native size — **resize/trim to an ASC-accepted
preview spec** (e.g. 886×1920 or 1080×1920, H.264, ≤30s) before upload.

## Category
- Primary: **Productivity**
- Secondary: **Health & Fitness** (optional)

## Age rating
- **9+** as configured live (cartoon/fantasy violence = Infrequent). (Metadata previously said 4+;
  the live app is 9+ — keep 9+.)

## Support URL (required)
```
https://github.com/sonnymay/daily-levels
```

## Copyright
```
2026 Sonny May
```

## What's New (for the freemium version)
```
Daily Levels is now free to start. Pause & resume your session, a one-time Pro unlock to evolve your hero to Mythic, a calmer first run, and accessibility polish.
```
