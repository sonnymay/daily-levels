# Codex handoff prompt — finish Daily Levels App Store submission

Paste everything in the fenced block into Codex. It is self-contained (Codex has none of our
chat history). It assumes the macOS machine where the project lives.

```
You are finishing an iOS App Store submission for an app that is already built and signed.
Work in /Users/santipapmay/Documents/Daily Levels. Do NOT change app source code or the
class/level logic. Be careful: never commit any .p8 key or secret to git.

FACTS
- App name: Daily Levels
- Bundle id: com.santipapmay.DailyLevels
- Apple Team ID: 57U5D693VS  (Account holder: Santipap May)
- App Store Connect Issuer ID: 69a6de7a-0b32-47e3-e053-5b8c7c11a4d1
- Version/build: 1.0 (1)
- Signed App Store .ipa (ready): /tmp/export/DailyLevels.ipa  (~15 MB)
  (also archived at ~/Library/Developer/Xcode/Archives/2026-06-13/DailyLevels.xcarchive)
- To rebuild the .ipa if missing:
    xcodebuild -project DailyLevels.xcodeproj -scheme DailyLevels -configuration Release \
      -destination 'generic/platform=iOS' -archivePath /tmp/DailyLevels.xcarchive \
      DEVELOPMENT_TEAM=57U5D693VS CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates archive
    xcodebuild -exportArchive -archivePath /tmp/DailyLevels.xcarchive \
      -exportOptionsPlist AppStore/ExportOptions.plist -exportPath /tmp/export -allowProvisioningUpdates
- Listing copy: AppStore/METADATA.md   Privacy answers: AppStore/PRIVACY.md
- Screenshots (6.9", 1320x2868): AppStore/screenshots/1_novice.png, 2_knight.png, 3_legend.png, 4_mythic.png
- Category: Productivity. Age rating 4+. Price: Free.
- Encryption: ITSAppUsesNonExemptEncryption = NO (already set; answer export compliance = No).
- Support URL: https://github.com/sonnymay/daily-levels   Copyright: 2026 Sonny May
- Privacy stance (verified in code): NO data collected, NO tracking, NO accounts/backend, zero deps.

HUMAN-ONLY STEPS — do NOT attempt these yourself; STOP and ask me to do them:
1. Accept the updated Apple Developer Program License Agreement at developer.apple.com/account
   -> Agreements. (Account-holder legal action.)
2. Create the App Store Connect API key: appstoreconnect.apple.com/access/integrations/api ->
   "+" -> name "Daily Levels Upload", access App Manager -> Generate -> Download the
   AuthKey_<KEY_ID>.p8 (downloadable once). Apple ID password and 2FA are mine to enter.
   After I download it, I will leave it in ~/Downloads.

YOUR STEPS (automate all of these):
A. Detect the key: look for ~/Downloads/AuthKey_*.p8 (or ~/.appstoreconnect/private_keys/).
   If absent, STOP and ask me to do Human Step 2. When found:
     mkdir -p ~/.appstoreconnect/private_keys
     mv ~/Downloads/AuthKey_*.p8 ~/.appstoreconnect/private_keys/
   Derive KEY_ID from the filename (AuthKey_<KEY_ID>.p8). Issuer ID is given above.
   Never print the key contents; never commit it.
B. Validate then upload the binary with the API key:
     xcrun altool --validate-app -f /tmp/export/DailyLevels.ipa -t ios \
       --apiKey <KEY_ID> --apiIssuer 69a6de7a-0b32-47e3-e053-5b8c7c11a4d1
     xcrun altool --upload-app -f /tmp/export/DailyLevels.ipa -t ios \
       --apiKey <KEY_ID> --apiIssuer 69a6de7a-0b32-47e3-e053-5b8c7c11a4d1
   If altool reports the agreement is not accepted, STOP and ask me to do Human Step 1.
C. Create the App Store Connect app record + version and push metadata/screenshots. Prefer
   fastlane (install if needed: `brew install fastlane` or `gem install fastlane`). Use the
   API key for auth (fastlane: api_key_path or ASC_KEY env). Steps:
     - `fastlane produce` (or App Store Connect API) to create the app:
         name "Daily Levels", bundle id com.santipapmay.DailyLevels, primary language en-US,
         SKU dailylevels1, Productivity category.
     - Populate metadata from AppStore/METADATA.md (name, subtitle, promotional text,
       description, keywords, support URL, copyright "2026 Sonny May").
     - Upload the 4 screenshots from AppStore/screenshots/ to the 6.9" iPhone display.
     - Set App Privacy = Data Not Collected, no tracking (see AppStore/PRIVACY.md).
     - Age rating 4+ (all "None"); Price Free; export compliance = No.
     - Attach build 1.0 (1) once App Store Connect finishes processing it (poll ~5–15 min).
   (`fastlane deliver` can do binary+metadata+screenshots+submit in one run if you prefer;
    but the binary is already uploaded in step B, so use skip_binary_upload:true.)
D. Before the FINAL irreversible "Submit for Review", STOP and show me a summary
   (app name, version, build number, screenshots count, price) and ask for explicit
   confirmation. Only submit after I say yes.
E. Report: build upload status, processing status, and the review-submission result, or the
   exact blocker + what I must click next.

Constraints: no app password entered by you, no 2FA attempts, no .p8 opened/printed/committed,
no source/logic changes. If anything needs my Apple credentials or a legal acceptance, stop and
tell me precisely what to do.
```
