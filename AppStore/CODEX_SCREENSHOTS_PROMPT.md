# Codex prompt - upload App Store screenshots for Daily Levels

Paste the fenced block into Codex. Self-contained.

## Current release story

The checked-in release sets tell the same five-part story on iPhone and iPad. Keep this order;
Apple gives the earliest screenshots the most visibility.

| File | What it shows |
|------|-------------|---------------|
| `01_level_up.png` | The core five-minutes-per-level focus loop |
| `02_lock_counts.png` | Locking the phone keeps earning focus |
| `03_one_button.png` | The deliberate one-screen, one-button experience |
| `04_history.png` | Seven-day history and a kind personal best, with no streak pressure |
| `05_pro_heroes.png` | The cumulative Hero Collection and one-time Pro evolution unlock |

```
Upload App Store screenshots for an iOS app that is already fully configured in App Store
Connect. Do NOT submit the app for review — only upload the screenshots and report back.

FACTS
- App: "Daily Levels", App ID 6780007939, bundle com.santipapmay.DailyLevels
- Apple Team ID: 57U5D693VS, App Store Connect Issuer ID: 69a6de7a-0b32-47e3-e053-5b8c7c11a4d1
- Version: 1.1 (en-US)
- iPhone screenshots: AppStore/screenshots/release_6_9/01_level_up.png through
  05_pro_heroes.png, each 1320x2868
- iPad screenshots: AppStore/screenshots/release_13_inch/01_level_up.png through
  05_pro_heroes.png, each 2064x2752
- Upload all 10 files. Keep numeric order within each device family.

PREFERRED METHOD — fastlane deliver (headless via App Store Connect API key):
1. Install fastlane if needed: `brew install fastlane` (or `gem install fastlane`).
2. API key: look for ~/.appstoreconnect/private_keys/AuthKey_*.p8.
   - If absent, STOP and ask me to create one: App Store Connect → Users and Access →
     Integrations → App Store Connect API → "+" → name "Daily Levels Upload", access
     App Manager → Generate → Download AuthKey_<KEY_ID>.p8, leave it in ~/Downloads.
     Then `mkdir -p ~/.appstoreconnect/private_keys && mv ~/Downloads/AuthKey_*.p8 ~/.appstoreconnect/private_keys/`.
   - Build the fastlane api_key JSON (key_id from filename, issuer_id above, key contents from the .p8).
3. Arrange screenshots for fastlane in /tmp/dl_fastlane/screenshots/en-US/. Prefix the copied
   iPhone filenames with "iphone_" and iPad filenames with "ipad_" so the two sets do not overwrite
   each other. Preserve the 01..05 numeric suffixes; fastlane detects each display from dimensions.
4. Run, from a temp dir:
   fastlane deliver \
     --api_key_path <api_key.json> \
     --app_identifier com.santipapmay.DailyLevels \
     --skip_binary_upload true --skip_metadata true \
     --overwrite_screenshots true \
     --screenshots_path /tmp/dl_fastlane/screenshots \
     --force true
   (--force skips the HTML preview confirmation; deliver will NOT submit for review.)
5. Verify in App Store Connect that version 1.1 shows five iPhone 6.9" screenshots and five
   13-inch iPad screenshots in numeric order.

FALLBACK — if fastlane/API key is not workable, use macOS UI automation: open Finder at
the two checked-in release directories and drag each five-file set onto its matching screenshot
drop zone on the Daily Levels 1.1 version page (requires the page open + Accessibility permission).

CONSTRAINTS: do not submit for review, do not enter my Apple password or do 2FA yourself
(stop and ask), do not commit any .p8 to git. Report the result or the exact blocker.
```
