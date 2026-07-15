# Daily Levels release testing

Use this checklist for the release candidate. The 48 unit tests cover level math, local-day
aggregation, midnight splitting, DST and timezone changes, cold-launch recovery, entitlement
migration, and the lock-classification state machine. The tests below verify the iOS lifecycle
behavior that only a physical device can prove.

## Prerequisites

1. Install the release candidate on a physical iPhone with a passcode set to **Require Immediately**.
2. Keep the iPhone connected to Xcode so the app can be terminated during the recovery checks.
3. Start each case from a paused or idle session and note the current-session and today totals.
4. Do not use Simulator results to approve lock behavior; protected-data notifications are not a
   reliable stand-in for the side button on real hardware.

Run the automated gate before the device checks:

```bash
./AppStore/validate_release.sh 1.1 7
xcodebuild -project DailyLevels.xcodeproj -scheme DailyLevels \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skipMacroValidation CODE_SIGNING_ALLOWED=NO test
```

## Required device checks

### A. Locked focus keeps earning

1. Tap **Start**, wait at least 10 seconds, then lock with the side button.
2. Leave the phone locked for 2 minutes.
3. Unlock and return to Daily Levels.

Pass when the hero is still grinding, the button still says **Pause**, and both clocks gained about
2 minutes. No previously earned focus may disappear.

### B. A brief app switch pauses immediately

1. Resume grinding, open another app, and return within 5 seconds.
2. Note the current-session and today totals.

Pass when the hero is sleeping, the button says **Resume**, and only focus earned before leaving was
credited. This specifically verifies the return-before-grace-window path.

### C. A normal app switch excludes away time

1. Resume grinding and open another app for at least 35 seconds.
2. Return to Daily Levels.

Pass when the session is paused and the time spent in the other app was not credited. Resuming must
continue the same current-session total without losing its earlier focus.

### D. Switching apps before locking stays paused

1. Resume grinding and open another app.
2. Wait at least 35 seconds, then lock the phone for 1 minute.
3. Unlock and return to Daily Levels.

Pass when the hero is sleeping and none of the away time was credited. The 35-second wait lets the
app-switch classification finish before the later device lock.

### E. Termination while locked recovers focus

1. Start grinding, lock the phone, and wait 10 seconds.
2. While the phone remains locked, stop the process from Xcode.
3. Wait 1 minute, unlock, and relaunch Daily Levels.

Pass when today's total includes the confirmed locked interval. The app may relaunch idle, but it
must not lose the focus earned while the device was locked.

### F. Termination after an app switch does not invent focus

1. Start grinding, open another app, and wait at least 35 seconds.
2. Stop the process from Xcode, then relaunch Daily Levels.

Pass when only the time before the app switch was credited and the away interval is absent.

## Accessibility spot checks

- Turn on VoiceOver and confirm the hero, progress, session control, history bars, collection items,
  paywall actions, purchase action, and restore action have useful labels and values.
- Set Larger Text to its maximum accessibility size and confirm text does not overlap or hide the
  Start, Pause, Resume, purchase, or restore controls.
- Turn on Reduce Motion and confirm hero media becomes still and level-up feedback does not depend on
  animation alone.

## Known platform boundary

Daily Levels distinguishes a lock from an app switch using
`protectedDataWillBecomeUnavailable`. iOS emits that signal only when device data protection is
active, so a passcode is required for the locked-phone guarantee. Without a passcode, an unconfirmed
background trip fails closed as an app switch after the grace window and pauses focus.

## Release pass criteria

Approve the build only when checks A-F pass on a passcode-enabled iPhone, the accessibility spot
checks have no blocking issue, the release validator passes, and the complete XCTest suite is green.
Record the device model, iOS version, build number, date, and result with the release notes.
