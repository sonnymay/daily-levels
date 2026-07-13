# Daily Levels — Monetization & Growth Playbook

Synthesized from competitor + ASO research (2025–2026). Companion to [METADATA.md](METADATA.md)
(paste-ready store copy) and [SUBMISSION.md](SUBMISSION.md) (the click-path).

---

## 1. Monetization model (decided)

**Free app + one-time non-consumable "Daily Levels Pro" unlock.** Launch at **$6.99** and hold
that price until real acquisition and purchase data justify a test. Do not add a subscription.

**Why (not $0.99 paid, not subscription):**
- Only ~4.9% of iOS apps are paid-upfront — paid kills the funnel (no try-before-buy) and the
  ratings/ASO flywheel barely turns. Net ~$0.70/sale with a hard ceiling.
- A calm single-screen *tool* generates no monthly new value → a subscription invites churn
  (~72% of annual subs cancel within year 1) and "why am I renting a timer?" 1-stars.
- One-time unlock = zero churn, matches "pay once, own it," protects the calm/anti-dark-pattern
  brand, and still preserves the free→try→buy funnel.

**Free vs Pro boundary (implemented):** free hero evolves through the first 3 classes
(Novice/Squire/Swordsman, ≤ level 30). Pro unlocks the seven evolutions Knight → Mythic, shown via
the locked hero state and the cumulative Hero Collection. Code:
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
- **Subtitle:** `Put your phone down. Level up.`
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

## 4. Zero-budget growth channel (one lane first)

Start with **StudyTok / Reels** for students. Post three short, real screen recordings over two weeks:
1. Start at Novice, lock the phone, return to a higher level.
2. A quiet 25-minute study session compressed into a class promotion.
3. The free hero journey followed by the seven Pro evolutions.

Use one campaign link for every post so App Store Connect can attribute downloads. Do not spend on
ads or split attention across Product Hunt, directories, and several social accounts until this lane
produces downloads.

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
- [ ] Upload **version 1.1 build 7**, attach the first IAP, and make the app Free.
- [ ] Confirm paid 1.0 customers are grandfathered into Pro via `AppTransaction`.
- [ ] Title/Subtitle/Keywords per METADATA.md; 5 clean 6.9″ screenshots; resize the preview video.
- [ ] TestFlight to 10–20 people; sandbox-test the purchase + restore; collect 2–3 testimonial quotes.
- [ ] Prepare the three StudyTok/Reels clips and one App Store campaign link.

**Day 1**
- [ ] Go live → ask testers/friends to download + leave a genuine rating. First ~10 reviews matter most.
- [ ] Publish clip 1: Novice → lock phone → return to a higher level.

**Days 3–5**
- [ ] Publish clip 2: the compressed 25-minute study session and class promotion.
- [ ] Reply to every useful comment and note the exact questions people ask.

**Days 8–12**
- [ ] Publish clip 3: free journey → seven Pro evolutions.
- [ ] Compare campaign downloads and store conversion before making another product change.

**Throughout:** use App Store Connect only. Track unique impressions, product-page views, first-time
downloads, conversion rate, paying users, and proceeds. Low impressions means discovery; impressions
without downloads means the listing; downloads without purchases means activation or the Pro offer.

---

## 7. Two-week measurement loop

Do not add analytics code or a tracking SDK. Once a week, copy these aggregate values from App Store
Connect into one private note or spreadsheet:

| Date range | Impressions | Product-page views | First-time downloads | Pro units | Proceeds | Change running |
|---|---:|---:|---:|---:|---:|---|
| Week 1 |  |  |  |  |  | None - baseline |
| Week 2 |  |  |  |  |  |  |

Wait for a full 14-day window before changing the product page. If the sample is still tiny, keep
collecting rather than treating a handful of people as a trend. Diagnose in this order:

1. **Few impressions:** improve distribution first - one campaign link, one StudyTok/Reels lane,
   and accurate search terms. Do not redesign the app.
2. **Views but few downloads:** change one listing variable, starting with screenshot 1 or the
   subtitle. Hold everything else steady for the next window.
3. **Downloads but few Pro purchases:** review whether users reach the Hero Collection and understand
   the one-time offer. Test copy or timing before changing price.
4. **Purchases are appearing:** leave the funnel alone long enough to establish a baseline. Spend the
   next cycle on reliability, reviews, and support feedback.

Record the date and exact variable for every experiment. Never add streak guilt, notifications,
accounts, ads, or cross-app tracking to lift a metric; those would invalidate the product promise.

---

## Sources
- RevenueCat — State of Subscription Apps 2025/2026 (conversion + price benchmarks)
- Finch $30M ARR breakdown (sparrowapps.io); Opal $10M ARR (speedinvest.com)
- Apple — SKStoreReviewController docs; SwiftLee requestReview guide
- AppFollow / SplitMetrics — ASO keyword & ranking factors; AppTweak — screenshot caption indexing
- Reddit app-launch playbooks; Product Hunt best-day-to-launch guides
> Third-party revenue/download figures are estimates (Sensor Tower / Apptopia class) — directional,
> not audited. App Store prices and rating counts are from the App Store directly.
