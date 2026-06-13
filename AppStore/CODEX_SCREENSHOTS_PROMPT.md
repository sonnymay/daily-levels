# Codex prompt — upload App Store screenshots for Daily Levels

Paste the fenced block into Codex. Self-contained.

```
Upload App Store screenshots for an iOS app that is already fully configured in App Store
Connect. Do NOT submit the app for review — only upload the screenshots and report back.

FACTS
- App: "Daily Levels", App ID 6780007939, bundle com.santipapmay.DailyLevels
- Apple Team ID: 57U5D693VS, App Store Connect Issuer ID: 69a6de7a-0b32-47e3-e053-5b8c7c11a4d1
- Version: 1.0 (en-US), status "Prepare for Submission"
- Screenshots to upload: 10 PNGs at ~/Downloads/dl_screens/ named 01_novice.png … 10_mythic.png,
  each 1242×2688 (iPhone 6.5" display). Upload in that numeric order (Apple shows the first 3 in search).
  These go in the iPhone 6.5" Display slot.

PREFERRED METHOD — fastlane deliver (headless via App Store Connect API key):
1. Install fastlane if needed: `brew install fastlane` (or `gem install fastlane`).
2. API key: look for ~/.appstoreconnect/private_keys/AuthKey_*.p8.
   - If absent, STOP and ask me to create one: App Store Connect → Users and Access →
     Integrations → App Store Connect API → "+" → name "Daily Levels Upload", access
     App Manager → Generate → Download AuthKey_<KEY_ID>.p8, leave it in ~/Downloads.
     Then `mkdir -p ~/.appstoreconnect/private_keys && mv ~/Downloads/AuthKey_*.p8 ~/.appstoreconnect/private_keys/`.
   - Build the fastlane api_key JSON (key_id from filename, issuer_id above, key contents from the .p8).
3. Arrange screenshots for fastlane: create a temp dir, e.g. /tmp/dl_fastlane/screenshots/en-US/
   and copy the 10 files there keeping the 01..10 prefixes (fastlane orders alphabetically,
   and detects the 6.5" display from the 1242×2688 dimensions).
4. Run, from a temp dir:
   fastlane deliver \
     --api_key_path <api_key.json> \
     --app_identifier com.santipapmay.DailyLevels \
     --skip_binary_upload true --skip_metadata true \
     --overwrite_screenshots true \
     --screenshots_path /tmp/dl_fastlane/screenshots \
     --force true
   (--force skips the HTML preview confirmation; deliver will NOT submit for review.)
5. Verify in App Store Connect that the 1.0 version now shows 10 iPhone 6.5" screenshots.

FALLBACK — if fastlane/API key is not workable, use macOS UI automation: open Finder at
~/Downloads/dl_screens/, select all 10, and drag them onto the screenshot drop zone on the
Daily Levels 1.0 version page in the browser (requires the page open + Accessibility permission).

CONSTRAINTS: do not submit for review, do not enter my Apple password or do 2FA yourself
(stop and ask), do not commit any .p8 to git. Report the result or the exact blocker.
```
