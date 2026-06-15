# Widget setup (v1.1 — do AFTER the freemium build is submitted)

A calm home-screen widget showing today's **level · class · minutes · streak**. All the code
is staged in [`widget/`](widget/) and ready to drop in. It is **not** wired into the build yet,
on purpose: a widget needs an App Group whose ID must be registered in the Apple Developer portal
*before any archive*, and adding that now would block the imminent freemium archive/upload.

> **Why a new target and not just files?** A widget is an **app-extension** — its own bundle that
> the system runs. Let Xcode create the target (below); do **not** hand-edit `project.pbxproj`.

---

## 1. Apple Developer portal (owner-only, one time)

1. **Identifiers ▸ App Groups ▸ +** → create `group.com.santipapmay.DailyLevels`.
2. **Identifiers ▸ App IDs** → open `com.santipapmay.DailyLevels`, enable **App Groups**, assign the group above.
3. Create a new App ID `com.santipapmay.DailyLevels.DailyLevelsWidget`, enable **App Groups**, assign the same group.

(With automatic signing, Xcode will create the matching provisioning profiles on first build.)

## 2. Create the widget target (Xcode)

1. **File ▸ New ▸ Target… ▸ Widget Extension.** Product Name: **`DailyLevelsWidget`**.
   Uncheck "Include Live Activity" and "Include Configuration App Intent" (this is a static widget).
   Team: `57U5D693VS`. Embed in **DailyLevels**. Activate the scheme if asked.
2. **Delete** the three files Xcode generated inside the new `DailyLevelsWidget` group
   (its sample `*.swift` + the sample `Info.plist`) — you'll replace them with the staged ones.

## 3. Drop in the staged code

Move the files from [`widget/`](widget/) into the project:

| Staged file | Goes to | Target membership |
|---|---|---|
| `DailyLevelsWidgetBundle.swift` | `DailyLevelsWidget/` | **widget only** |
| `DailyLevelsWidget.swift` | `DailyLevelsWidget/` | **widget only** |
| `DailyLevelsSnapshot.swift` | `DailyLevels/` (app folder) | **app AND widget** (tick both in the File Inspector ▸ Target Membership) |
| `Info.plist` | `DailyLevelsWidget/` | set as the widget's `INFOPLIST_FILE` |
| `DailyLevelsWidget.entitlements` | `DailyLevelsWidget/` | widget's `CODE_SIGN_ENTITLEMENTS` |
| `DailyLevels.app.entitlements` | `DailyLevels/` | app's `CODE_SIGN_ENTITLEMENTS` |

Then in **Signing & Capabilities** add the **App Groups** capability to *both* targets and tick
`group.com.santipapmay.DailyLevels`. (Adding the capability in Xcode also writes the entitlements;
the staged `.entitlements` files above are there so you can confirm the contents match.)

> `DailyLevelsSnapshot.swift` is the only shared file — it must belong to **both** targets so the
> app can write the snapshot and the widget can read it. Everything else is widget-only.

## 4. Publish the snapshot from the app

Add this to `DailyLevels/FocusEngine.swift` so the widget always has fresh data:

```swift
import WidgetKit   // at the top, alongside the other imports

// In FocusEngine, add:
@ObservationIgnored private var lastPublishedLevel = -1

/// Mirror today's state to the shared App Group so the widget can read it.
private func publishWidgetSnapshot() {
    DailyLevelsSnapshot(
        level: level,
        className: String(localized: knightClass.displayName),
        todayMinutes: todayMinutes,
        streak: focusStreak,
        date: startOfToday
    ).save()
    lastPublishedLevel = level
    WidgetCenter.shared.reloadAllTimelines()
}
```

Call it where the picture changes (cheap — guarded so the per-second ticker only reloads the
widget when the level actually changes, respecting the OS refresh budget):

- end of `reloadSessions()` → `publishWidgetSnapshot()`   *(launch / persistence)*
- end of `beginStretch()` and `pause()` → `publishWidgetSnapshot()`   *(start / pause / resume)*
- inside the ticker closure, after `self?.now = Date()`:
  ```swift
  if let self, self.level != self.lastPublishedLevel { self.publishWidgetSnapshot() }
  ```

## 5. Verify

```bash
SIM=C494865D-5987-4B80-A5D4-EE9EAD88FAA5
xcodebuild -project "DailyLevels.xcodeproj" -scheme DailyLevels -destination "id=$SIM" build
```

Run the app once (so it writes a snapshot), then on the simulator home screen: long-press ▸ **+** ▸
search "Daily Levels" ▸ add the small and medium sizes. Confirm level/class/streak match the app.
App Groups work on the simulator without the portal step; the portal registration in §1 is required
for device builds, TestFlight, and the App Store.

## Notes
- The widget palette is inlined in `DailyLevelsWidget.swift` (the widget target can't see
  `Theme.swift`) — keep the two in sync if you retheme.
- No hero art in the widget by design (the `*_sleep.png`/`*_grind.mp4` live in the **app** bundle,
  not the widget's). The widget uses an SF Symbol; copy a still into the widget's asset catalog
  later if you want real class art.
- Bump `CURRENT_PROJECT_VERSION` on both targets for the v1.1 upload.
