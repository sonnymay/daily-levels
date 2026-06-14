# Daily Levels — App Privacy answers

For **App Store Connect → App Privacy** ("nutrition label"). These answers reflect what the
code actually does as of v1.0 — verified against the source, not assumed.

## Summary
**Data Not Collected.** Daily Levels collects **no** data. Everything is stored locally on the
device via SwiftData; there is no account, no backend, no analytics, no ads, no third-party SDKs.
The only Apple services used — **local notifications** (level-up pings) and **StoreKit 2** (the
one-time Pro unlock) — are handled by the OS and collect no data the developer declares, so the
label stays **Data Not Collected**.

## App Privacy questionnaire
1. "Do you or your third-party partners collect data from this app?" → **No.**
   - This yields a "Data Not Collected" label. No further data-type questions appear.

## Tracking (App Tracking Transparency)
- The app does **not** track. No `NSUserTrackingUsageDescription`, no IDFA, no ad networks.

## Permissions / usage-description strings
- **None required.** The app uses no camera, microphone, location, contacts, photos, or HealthKit.
- **Notifications:** the app requests notification permission at runtime via
  `UNUserNotificationCenter` (to ping you on a level-up while the phone is locked). This needs **no**
  `Info.plist` usage-description key, and local notifications collect no data.
- **In-app purchase:** the single non-consumable "Daily Levels Pro" unlock uses **StoreKit 2**.
  Apple processes the transaction; the app declares no collected data and uses no third-party
  payment/analytics SDK (no RevenueCat).

## Technical notes (why "no data" is accurate)
- Persistence: `ModelContainer(for: FocusSession.self)` — a local on-device SwiftData store.
- Crash marker: a single `Date` in `UserDefaults` (`engine.activeStart`), local only.
- Lock detection: observes `UIApplication.protectedDataWillBecomeUnavailable` and uses a
  finite-length background task — no data leaves the device.
- No `URLSession`, no third-party packages (zero dependencies).

## Export compliance (asked at upload)
- Uses **no encryption** beyond Apple-provided OS standard (HTTPS isn't even used — no network).
- Answer **"No"** to "Does your app use non-exempt encryption?" → set
  `ITSAppUsesNonExemptEncryption = NO`.

> ✅ Recommended: add `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` to the build settings
> (done in the project) so App Store Connect skips the export-compliance prompt on every upload.
