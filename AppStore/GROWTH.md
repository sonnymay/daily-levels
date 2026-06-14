# Daily Levels — Monetization & Growth Playbook

Synthesized from competitor + ASO research (2025–2026). Companion to [METADATA.md](METADATA.md)
(paste-ready store copy) and [SUBMISSION.md](SUBMISSION.md) (the click-path).

---

## 1. Monetization model (decided)

**Free app + one-time non-consumable "Daily Levels Pro" unlock.** Launch price **$6.99**
("Founder's price"), raise to **$9.99** later. Optionally add a cheap annual sub ($4.99–$7.99/yr)
later as a secondary option — not at launch.

**Why (not $0.99 paid, not subscription):**
- Only ~4.9% of iOS apps are paid-upfront — paid kills the funnel (no try-before-buy) and the
  ratings/ASO flywheel barely turns. Net ~$0.70/sale with a hard ceiling.
- A calm single-screen *tool* generates no monthly new value → a subscription invites churn
  (~72% of annual subs cancel within year 1) and "why am I renting a timer?" 1-stars.
- One-time unlock = zero churn, matches "pay once, own it," protects the calm/anti-dark-pattern
  brand, and still preserves the free→try→buy funnel.

**Free vs Pro boundary (implemented):** free hero evolves through the first 3 classes
(Novice/Squire/Swordsman, ≤ level 30). Pro unlocks the evolution Knight → Mythic, shown via a
tasteful "Unlock Pro to evolve" overlay on the hero + an "Daily Levels Pro" row. Code:
`Store.swift`, `PaywallView.swift`, `KnightClass.isProOnly`. Tech: **StoreKit 2 only, no RevenueCat**
(keeps the "Data Not Collected" label; native `Product`/`Transaction` APIs).

**No ads, ever** — banners pay ~$0.44 eCPM, break the calm brand, and would void the privacy label.

**Realistic expectation:** for a no-AI calm utility, LTV ≈ the unlock price (~$7–10 per converting
user). Blended ARPU across all installs is low single digits at best — revenue comes from *volume*,
which is why ratings + ASO + the back-to-school window below matter more than squeezing price.

### What competitors taught us
| App | Model | Price anchors | The hook |
|---|---|---|---|
| **Finch** | Freemium + sub | $9.99/mo · $69.99/yr | Emotional pet + cosmetics; everything functional free → $30–40M ARR bootstrapped |
| **Forest** | $3.99 app + Plus sub | $5.99/mo · $35.99/yr | Cosmetic trees + guilt mechanic; 4.8★ / ~49k |
| **Habitica** | Freemium + $5/mo | $48/yr | RPG depth — but monetizes *weakly* (~$30k/mo). **RPG ≠ revenue; design/calm is the moat** |
| **Study Bunny** | Free+ads + coins IAP | $0.99–$69.99 packs | Pet cosmetics shop + ad removal |
| **Opal** | Freemium, premium sub | ~$99/yr, $399 lifetime | Sells *hours reclaimed* (utility), not vibes |

Takeaway: calm apps monetize **cosmetics + emotion + goodwill**, not feature-gating. Our 10 hero
classes are exactly that cosmetic surface.

---

## 2. ASO (see METADATA.md for paste-ready strings)

- **Title:** `Daily Levels: Focus Timer` — keyword in the highest-weight slot.
- **Subtitle:** `Pomodoro deep work for study`.
- **Keywords:** new terms only (no Title/Subtitle repeats); own the uncontested **focus rpg /
  gamified focus / study rpg** long-tail.
- **Screenshots:** frame 1 = the level-up payoff; captions are indexed since 2025 — use keywords.
- **Ratings flywheel:** `requestReview` fires after a real level-up (day ≥3, once/version) — already
  wired in `MainView.maybeRequestReview()`. First ~10–20 reviews are the biggest early conversion lever.

---

## 3. Positioning

- **Primary:** "Make focusing feel rewarding" — the true differentiator vs. plain pomodoro timers.
- **Primary audience for outreach:** students (StudyTok + study subreddits).
- **Strong secondary lane:** ADHD / focus difficulty (gamification genuinely helps; don't over-claim
  clinical benefit).
- **Skip:** screen-time/blocking framing — crowded, dominated by Apple's Screen Time + Opal, and the
  app doesn't block apps.

---

## 4. Zero-budget growth channels (pick 2–3, not all)

1. **Reddit (highest ROI)** — story posts, *not* link drops. Subs: r/productivity, r/GetStudying,
   r/study, r/GetDisciplined, r/ADHD (strict — contribute first), r/SideProject, r/iosapps, r/apps,
   r/iOSProgramming (build story). Norms: 90/10 rule, warm up a 500+ karma account, post a
   problem→solution story ("pomodoro felt like a chore, so I built one where every 5 min levels up a
   knight"), reply to every comment (45–60 min/day). Tuesday ~9am ET tested well.
2. **TikTok / Reels — StudyTok** — "study with me + watch my knight level up." The level-up is the
   shareable moment. #studytok #studywithme #productivity #adhd. Post consistently yourself.
3. **Product Hunt** — one-day credibility/backlink spike. Tue–Thu for traffic; reply to every comment.
4. **Build-in-public on X** — slow compounding; pairs with the PH launch.
5. **Directories / Show HN / Indie Hackers** — the "focus = RPG leveling" angle is novel enough for
   a Show HN.

---

## 5. Timing — ride back-to-school

Launching mid-June is a **quiet window**. Focus/study apps peak at **back-to-school (Aug–Sep)**,
**New Year (Jan)**, and **exam seasons (Nov–Dec, Apr–May)**. Plan: ship the freemium build + seed
Reddit/TikTok content + bank reviews in **June–July**, then refresh keywords/screenshots and push
TikTok in **early August**.

---

## 6. Week-1 launch checklist

**Pre-launch**
- [ ] Create the IAP `com.santipapmay.DailyLevels.pro` in ASC (Non-Consumable, $6.99). *(owner)*
- [ ] Set app price to **Free**. *(owner)*
- [ ] Archive + upload **build 4** (first StoreKit build), attach build + IAP. *(version already bumped to 4)*
- [ ] Title/Subtitle/Keywords per METADATA.md; 5 captioned 6.9″ screenshots; resize the preview video.
- [ ] TestFlight to 10–20 people; sandbox-test the purchase + restore; collect 2–3 testimonial quotes.
- [ ] Warm up Reddit (500+ karma) + a TikTok/X handle; start contributing now. Line up a PH hunter.

**Day 1**
- [ ] Go live → ask testers/friends to download + leave a genuine rating. First ~10 reviews matter most.
- [ ] Post the build story to r/SideProject and r/iosapps. Start an X build-in-public thread.

**Days 2–4**
- [ ] One Reddit story/day, staggered + customized (r/productivity, r/GetStudying, r/ADHD if contextual).
- [ ] First StudyTok "study with me + knight levels up" clip. Reply to everything.

**Day 5**
- [ ] Product Hunt launch (Tue–Thu). Reply to every comment; point your audience to it.

**Days 6–7**
- [ ] Second TikTok angle (the level-up payoff). Submit to 3–5 free directories. Post a milestone
      update on X + Indie Hackers. Reply to App Store reviews.

**Throughout:** watch keyword rankings (App Store Connect search analytics / free AppFollow tier);
swap weak keywords on the next version update.

---

## Sources
- RevenueCat — State of Subscription Apps 2025/2026 (conversion + price benchmarks)
- Finch $30M ARR breakdown (sparrowapps.io); Opal $10M ARR (speedinvest.com)
- Apple — SKStoreReviewController docs; SwiftLee requestReview guide
- AppFollow / SplitMetrics — ASO keyword & ranking factors; AppTweak — screenshot caption indexing
- Reddit app-launch playbooks; Product Hunt best-day-to-launch guides
> Third-party revenue/download figures are estimates (Sensor Tower / Apptopia class) — directional,
> not audited. App Store prices and rating counts are from the App Store directly.
