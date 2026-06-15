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

## Screenshots (6, captioned — indexed for ASO since 2025)
Upload order leads with the payoff, then mechanic, aspiration, proof, the offer, the calm.
Caption text is **baked into each PNG** in `screenshots/captioned/`:
1. `01_levelup.png` — **"Watch your hero level up"** (the differentiator / payoff)
2. `02_lock.png` — **"Lock your phone, focus keeps counting"** (trust + core mechanic)
3. `03_mythic.png` — **"Climb all the way to Mythic"** (aspiration / class ladder)
4. `04_history.png` — **"See your focus add up"** (the 7-day proof)
5. `05_paywall.png` — **"No subscription — unlock Pro once"** (conversion / pricing trust)
6. `06_intro.png` — **"Calm. One screen. No noise."** (the calm promise)

Size **1290×2796 (6.9″ iPhone)** — iPhone-only app, so this is the only required set; ASC derives
smaller sizes. PNG for crisp text.
> Note: `06_intro.png` shows the 3-row first-run intro; the app now ships a 5-row intro (added the
> "come back tomorrow / streak" and "share your climb" rows) — optional refresh before upload.

## App Preview video (optional, high-impact for a gamified app)
A 15–30s clip: timer running → minutes climb → hero levels up / changes class.
**Upload-ready file:** `AppStore/preview_886x1920.mp4` (886×1920, H.264, 20s — a canonical
ASC-accepted portrait preview size). `preview_appstore.mp4` is the 1290×2796 source; both are
gitignored (regenerate via simctl + ffmpeg). Re-encode recipe:
`ffmpeg -i preview_appstore.mp4 -vf scale=886:1920:flags=lanczos -r 30 -c:v libx264 -pix_fmt yuv420p -crf 20 -an -movflags +faststart preview_886x1920.mp4`

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

## Localized listings (per-locale ASO — AI drafts, native review pending)
The app UI is already localized; localizing the **store listing** lifts non-English organic
discovery (audit est. 30–50%). Enter these per language in App Store Connect. **All AI-drafted —
have a native speaker confirm before publishing each locale.** Rules kept: Title ≤30, Subtitle ≤30,
Keywords ≤100 (comma, no spaces), and keywords never repeat Title/Subtitle words.

> Screenshot captions are baked into the English PNGs; to fully localize, re-render the captioned
> screenshots per locale later. The **first two** caption texts are provided below as the priority.

### 🇪🇸 Spanish (es)
- **Title:** `Daily Levels: Enfoque`
- **Subtitle:** `Pomodoro para estudiar mejor`
- **Keywords:** `concentracion,productividad,tdah,sesion,lectura,deberes,atencion,gamificado,rpg,habito`
- **Captions 1–2:** "Sube de nivel mientras te concentras" · "Bloquea el móvil: el foco sigue"

### 🇧🇷 Portuguese — Brazil (pt-BR)
- **Title:** `Daily Levels: Foco`
- **Subtitle:** `Pomodoro para estudar melhor`
- **Keywords:** `concentracao,produtividade,tdah,sessao,leitura,licao,atencao,gamificado,rpg,habito`
- **Captions 1–2:** "Suba de nível enquanto foca" · "Bloqueie o celular: o foco continua"

### 🇩🇪 German (de)
- **Title:** `Daily Levels: Fokus-Timer`
- **Subtitle:** `Pomodoro für tiefes Lernen`
- **Keywords:** `konzentration,produktivitaet,adhs,sitzung,lesen,hausaufgaben,aufmerksamkeit,rpg,gewohnheit`
- **Captions 1–2:** "Fokussiere und steige auf" · "Sperre dein Telefon — der Fokus zählt weiter"

### 🇫🇷 French (fr)
- **Title:** `Daily Levels: Concentration`
- **Subtitle:** `Pomodoro pour mieux étudier`
- **Keywords:** `productivite,tdah,session,lecture,devoirs,attention,gamifie,rpg,habitude,minuteur`
- **Captions 1–2:** "Monte de niveau en te concentrant" · "Verrouille ton téléphone, le focus continue"

### 🇯🇵 Japanese (ja)
- **Title:** `Daily Levels: 集中タイマー`
- **Subtitle:** `勉強がはかどるポモドーロ`
- **Keywords:** `集中,生産性,ADHD,勉強,セッション,読書,宿題,習慣,RPG,ゲーム化`
- **Captions 1–2:** "集中するほどレベルアップ" · "スマホをロックしても集中は続く"
