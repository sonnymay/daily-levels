# Daily Levels — App Store submission guide

This lists what's **done in code/repo** and the exact **human-only steps** to get to review.
Steps marked 🔴 require your Apple account / payment / device and cannot be automated by an agent.

---

## ✅ Done (in the repo)
- App icon (1024², no alpha) — `DailyLevels/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Display name **Daily Levels**, bundle id **com.santipapmay.DailyLevels**, version **1.0 (1)**
- `ITSAppUsesNonExemptEncryption = NO` set (skips the export prompt)
- Per-class hero videos wired + compressed (21MB total)
- Listing copy — `AppStore/METADATA.md`
- Privacy answers — `AppStore/PRIVACY.md` (Data Not Collected; no tracking)
- Screenshots (6.9", iPhone 16 Pro Max) — `AppStore/screenshots/`
- Builds clean, 12/12 unit tests pass

---

## 🔴 BLOCKER 0 — Hardware lock-detection gate (do FIRST)
The core "phone locked = keep grinding" behavior was **never verified on a real iPhone**
(SPEC §6, the go/no-go gate). Before submitting:
1. Open the project in Xcode, run on **your physical iPhone with a passcode set**.
2. Run tests **A–D** in [`TESTING.md`](../TESTING.md).
3. If A–D pass → proceed. If any fail → the fix is isolated to
   `DailyLevels/LockClassifier.swift`; fix before submitting.

> An agent can't press your phone's lock button. This is yours to run.

---

## 🔴 BLOCKER 1 — Apple Developer Program
You need an active **Apple Developer Program** membership ($99/yr) on your Apple ID.
- Check / enroll: https://developer.apple.com/account → "Enroll".
- Without this you cannot create a Distribution signing certificate or an app record.

---

## Step-by-step (after Blockers 0 & 1)

### A. Sign the app in Xcode  🔴
1. Open `DailyLevels.xcodeproj` in Xcode.
2. Select the **DailyLevels** target → **Signing & Capabilities**.
3. Check **Automatically manage signing**.
4. **Team** → pick your Apple Developer team. Xcode creates the cert + provisioning profile.
   - If it complains the bundle id is taken, change `PRODUCT_BUNDLE_IDENTIFIER` to a unique
     reverse-DNS you own and update `AppStore/METADATA.md` accordingly.

### B. Create the app record in App Store Connect  🔴
1. https://appstoreconnect.apple.com → **Apps → + → New App**.
2. Platform **iOS**; Name **Daily Levels**; Primary language **English (U.S.)**;
   Bundle ID **com.santipapmay.DailyLevels** (pick from the dropdown — appears after Step A
   registers it, or register it at developer.apple.com → Identifiers first); SKU `dailylevels1`.

### C. Archive & upload the build  🔴 (needs your signing from Step A)
In Terminal (or use Xcode ▸ Product ▸ Archive ▸ Distribute App):
```bash
cd "/Users/santipapmay/Documents/Daily Levels"
xcodebuild -project DailyLevels.xcodeproj -scheme DailyLevels \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/DailyLevels.xcarchive archive

xcodebuild -exportArchive -archivePath build/DailyLevels.xcarchive \
  -exportOptionsPlist AppStore/ExportOptions.plist \
  -exportPath build/export
# then upload:
xcrun altool --upload-app -f build/export/DailyLevels.ipa \
  -t ios --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```
- `AppStore/ExportOptions.plist` is provided (method: app-store-connect). **Edit its
  `teamID`** to your 10-char Team ID (Apple Developer → Membership).
- For `altool`, create an **App Store Connect API key** (Users and Access → Integrations →
  App Store Connect API → +). Or simplest: in **Xcode → Organizer**, select the archive →
  **Distribute App → App Store Connect → Upload** (GUI handles auth/2FA). 🔴 (Apple login + 2FA)

### D. Fill the listing & submit  🔴
In App Store Connect → your app → the 1.0 version:
1. **Screenshots** — drag the PNGs from `AppStore/screenshots/` into the 6.9" slot.
2. **Description / Keywords / Subtitle / Promotional text** — copy from `AppStore/METADATA.md`.
3. **Support URL** — `https://github.com/sonnymay/daily-levels`.
4. **Build** — select the build uploaded in Step C (takes ~5–15 min to finish processing).
5. **App Privacy** — answer per `AppStore/PRIVACY.md` (Data Not Collected; no tracking).
6. **Age rating** — 4+, all "None".
7. **Pricing** — Free (Pricing and Availability). 🔴 (and accept any pending
   Paid/Free Apps agreements in Business → Agreements — first-time accounts only).
8. **Add for Review → Submit for Review.** 🔴

---

## What stops an agent here (summary of human-only steps)
- Pressing the iPhone lock button for the TESTING.md gate.
- Apple ID login + **2FA** (Xcode/App Store Connect).
- Apple Developer Program enrollment & **payment**.
- Choosing/creating the **Distribution certificate & Team** in the signing UI.
- Accepting Apple's **legal agreements** and the final **Submit for Review** click.

Everything else (code, icon, compressed media, metadata text, privacy answers, screenshots,
ExportOptions template) is prepared in this repo.
