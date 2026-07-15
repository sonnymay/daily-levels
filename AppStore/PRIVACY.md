# Daily Levels — App Privacy answers

For **App Store Connect → App Privacy** ("nutrition label"). These answers reflect what the
code actually does as of v1.1 — verified against the source, not assumed.

## Summary
**Data Not Collected.** Daily Levels collects **no** data. Everything is stored locally on the
device via SwiftData; there is no account, no backend, no analytics, no ads, no third-party SDKs.
The optional one-time Pro unlock uses **StoreKit 2**, handled by Apple. The app receives only its
verified entitlement and collects no data the developer declares, so the label stays
**Data Not Collected**.

## App Privacy questionnaire
1. "Do you or your third-party partners collect data from this app?" → **No.**
   - This yields a "Data Not Collected" label. No further data-type questions appear.

## Tracking (App Tracking Transparency)
- The app does **not** track. No `NSUserTrackingUsageDescription`, no IDFA, no ad networks.

## Permissions / usage-description strings
- **None required.** The app uses no camera, microphone, location, contacts, photos, or HealthKit.
- The app does not request notification permission.
- **In-app purchase:** the single non-consumable "Daily Levels Pro" unlock uses **StoreKit 2**.
  Apple processes the transaction; the app declares no collected data and uses no third-party
  payment/analytics SDK (no RevenueCat).

## Technical notes (why "no data" is accurate)
- Persistence: `ModelContainer(for: FocusSession.self)` — a local on-device SwiftData store.
- Crash marker: a `Date` and lock-confirmation flag in `UserDefaults`, local only.
- Lock detection: observes `UIApplication.protectedDataWillBecomeUnavailable` and uses a
  finite-length background task — no data leaves the device.
- No `URLSession`, no third-party packages (zero dependencies).

## Export compliance (asked at upload)
- Uses **no custom encryption**. StoreKit communication is handled by Apple; the app implements no
  network client.
- Answer **"No"** to "Does your app use non-exempt encryption?" → set
  `ITSAppUsesNonExemptEncryption = NO`.

`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` is already set in the project so App Store
Connect can reuse the export-compliance answer on upload.
