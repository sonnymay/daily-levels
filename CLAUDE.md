# Daily Levels - Claude Code Notes

Read [`AGENTS.md`](AGENTS.md) and [`SPEC.md`](SPEC.md) before making changes. `AGENTS.md` is the
current project-state reference; do not duplicate release status here.

The non-negotiable product contract is: one calm main screen, one primary Start/Pause/Resume button,
five minutes per level, daily reset at local midnight, locked-phone time counts, app-switch time does
not, and earned progress is never taken away. No streak pressure, coins, shop, ads, notifications,
accounts, tracking, backend, sync, widgets, or new dependencies.

Release target: **1.1 build 6**, bundle `com.santipapmay.DailyLevels`. Build 6 is the first intended
freemium production build. The one-time Pro product is `com.santipapmay.DailyLevels.pro`; verified
production customers whose original app build is below 6 are grandfathered into Pro. Preserve that
migration and use StoreKit's localized price only.

Run the complete simulator test suite after changing focus time, calendar boundaries, lock handling,
StoreKit entitlement logic, class math, or localization. The physical-iPhone checks in `TESTING.md`
are still required before App Store release. Never commit a `.p8` key and stop for owner confirmation
before final submission or release.
