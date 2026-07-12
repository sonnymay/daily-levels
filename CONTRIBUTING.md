# Contributing to Daily Levels

Thanks for taking the time to improve Daily Levels. This project welcomes focused bug fixes, tests, accessibility improvements, localization corrections, and documentation updates.

## Before You Start

- Search existing issues and pull requests to avoid duplicate work.
- Keep each change small and focused on one problem.
- Do not include secrets, signing certificates, provisioning profiles, or personal App Store Connect data.
- Preserve the app's core behavior: locking the phone continues focus time, while switching to another app pauses it.

## Local Setup

Requirements:

- macOS with Xcode 16 or newer
- iOS 17 SDK or newer
- A physical passcode-enabled iPhone for testing lock detection

```bash
git clone https://github.com/sonnymay/daily-levels.git
cd daily-levels
open DailyLevels.xcodeproj
```

Build and run the unit tests from the command line:

```bash
xcodebuild -project DailyLevels.xcodeproj \
  -scheme DailyLevels \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build test
```

## What to Test

Run the full test suite for every code change. Add or update tests when changing:

- Level calculations
- Midnight session splitting
- Focus ledger aggregation
- Cold-launch recovery
- StoreKit entitlement migration
- Localization-sensitive class names
- Lock-versus-app-switch classification

Lock detection cannot be validated fully in the simulator because protected-data notifications require a physical passcode-enabled iPhone.

## Code Guidelines

- Prefer small, testable pure functions for business logic.
- Keep app state centralized in `FocusEngine`.
- Avoid adding third-party dependencies unless they solve a clear problem that cannot reasonably be handled with Apple frameworks.
- Keep user data on device and preserve the **Data Not Collected** privacy posture.
- Preserve the minimalist scope: no streak pressure, notifications, feeds, accounts, or server features.
- Keep accessibility labels and Dynamic Type behavior intact when changing UI.
- Do not change `KnightClass.rawValue` values casually; they are tied to asset names and Pro gating.

## Pull Requests

A useful pull request should include:

1. A concise explanation of the problem.
2. A summary of the solution.
3. Testing performed.
4. Screenshots or a short recording for visible UI changes.
5. Any known limitations or follow-up work.

Suggested title format:

```text
fix: prevent duplicate focus entries after relaunch
feat: add accessibility labels to history chart
test: cover DST boundary session splitting
docs: clarify physical-device lock testing
```

## Good First Contributions

- Improve VoiceOver labels and hints.
- Add edge-case unit tests.
- Correct localization wording without changing localization keys.
- Improve setup or architecture documentation.
- Reproduce and document device-specific behavior.

For larger feature ideas, open an issue before implementation so the scope can be discussed first.
