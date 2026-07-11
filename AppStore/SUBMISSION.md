# Daily Levels - App Store 1.1 submission

This checklist is for **version 1.1 build 6** of App Store Connect app `6780007939`, bundle
`com.santipapmay.DailyLevels`, Team `57U5D693VS`.

## Current binary checkpoint

- The 1.1 (6) archive completed successfully on July 10, 2026.
- The signed binary upload completed successfully; App Store Connect reported it as processing
  immediately after upload. Recheck processing before attaching the build to version 1.1.
- The app has not been submitted for review. The final stop below still applies.

## Prepared in the repo

- Native SwiftUI app with no third-party dependencies, tracking, account, or backend.
- `ITSAppUsesNonExemptEncryption = NO`.
- Free experience through Swordsman and one non-consumable Pro unlock for seven more heroes.
- Product ID `com.santipapmay.DailyLevels.pro`; purchase and restore use StoreKit 2.
- Paid production customers from builds before 6 are grandfathered into Pro through a verified
  `AppTransaction`.
- Listing copy: [`METADATA.md`](METADATA.md).
- Privacy answers: [`PRIVACY.md`](PRIVACY.md) - Data Not Collected, no tracking.
- Unit tests cover midnight, DST, timezone changes, cold-launch recovery, and entitlement migration.

## Required checks before submission

1. Run tests A-D in [`../TESTING.md`](../TESTING.md) on a physical iPhone with a passcode. Confirm
   locking keeps focus active and switching apps pauses at the background timestamp.
2. In Xcode with the local StoreKit configuration, test a new purchase, cancellation, pending state,
   and Restore Purchases.
3. Install build 6 over the public paid 1.0 app and confirm the user receives Pro automatically.
4. Confirm the five files in `screenshots/release_6_9/` are opaque 1320x2868 PNGs and the five in
   `screenshots/release_13_inch/` are opaque 2064x2752 PNGs. Any paid hero shown in marketing must
   be labeled as requiring Pro.

## Archive and stage the binary

```bash
cd "/Users/santipapmay/Documents/Documents - Santipap’s MacBook Air/Daily Levels"
xcodebuild -project DailyLevels.xcodeproj -scheme DailyLevels -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath /tmp/DailyLevels-1.1-6.xcarchive \
  DEVELOPMENT_TEAM=57U5D693VS CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates archive

xcodebuild -exportArchive \
  -archivePath /tmp/DailyLevels-1.1-6.xcarchive \
  -exportOptionsPlist /tmp/UploadOptions.plist \
  -exportPath /tmp/DailyLevels-1.1-6-export \
  -allowProvisioningUpdates
```

`/tmp/UploadOptions.plist` must use `method=app-store-connect`, `destination=upload`, Team
`57U5D693VS`, automatic signing, and symbol upload. Stop if Xcode requests an Apple password or 2FA.

## App Store Connect setup

1. Create version **1.1** and apply the English listing from `METADATA.md`.
2. Set the app's base price to **Free**.
3. Create or verify the non-consumable **Daily Levels Pro** at the storefront price shown in
   `METADATA.md`, including English (U.S.) display name and description.
4. Upload `screenshots/release_6_9/` and `screenshots/release_13_inch/` in numeric order to their
   matching 6.9-inch iPhone and 13-inch iPad slots.
5. Attach build **1.1 (6)** and the Pro IAP to the version.
6. Confirm age rating **9+**, export compliance **No**, IDFA **No**, and privacy **Data Not Collected**.
7. Verify the price, screenshots, build, IAP, review contact, support URL, and release option.

## Final stop

Do not click **Submit for Review** or release the app until the owner explicitly confirms the final
summary: Daily Levels, version 1.1, build 6, Free, one $6.99-equivalent non-consumable, screenshot
counts for every required device family, and paid-1.0 users grandfathered into Pro.

Apple password entry, 2FA, legal agreements, the physical lock-button test, and final submission are
owner actions. Never print or commit an App Store Connect `.p8` private key.
