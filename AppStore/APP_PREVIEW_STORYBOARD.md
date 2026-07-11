# Daily Levels App Preview Storyboard

Editing master: 30 seconds, portrait H.264 `.mp4`, 1080x1920, 30 fps, 10-12 Mbps, AAC audio.
Use only real in-app footage, with no device frame, and keep frames 0-89 free of captions.

App Store upload: export an 886x1920 copy for the modern 6.5/6.9-inch iPhone preview slot. Keep
the 1080x1920 file as the editable master rather than uploading it directly.

## Source Capture Plan

Record short real-app clips from the simulator or device. For simulator captures, use the existing debug launch flags:

```text
-seedDemoData -todayMinutes N -autoStart -autoStartSecondsAgo S
```

Add `-showHeroCollection` to open the collection directly, or `-unlockPro` when capturing an owned
hero. These flags are debug-only and do not affect release behavior.

| Raw clip | Record this from the app | Suggested source timing | Use in final |
|---|---|---:|---:|
| A | Level 1, Novice hero idle in field: `-seedDemoData -todayMinutes 5` | 00:00-00:05 | 00:00-00:03 |
| B | Tap Start, hero begins grinding: `-seedDemoData -todayMinutes 0` | 00:05-00:13 | 00:03-00:08 |
| C | Level jumps: capture `todayMinutes` 25, 50, 100, 150 | 00:13-00:23 | 00:08-00:14 |
| D | Lock behavior: record before/after app footage, not the iOS lock screen | 00:23-00:33 | 00:14-00:20 |
| E | Class upgrades: capture 5, 60, 160, 280 minutes | 00:33-00:43 | 00:20-00:25 |
| F | Full week history: `-seedDemoData -todayMinutes 160` | 00:43-00:50 | 00:25-00:30 |

For the lock shot, record the app grinding on a physical iPhone, lock the phone for real, unlock,
then show the app with focus time advanced. In the edit, use a quick fade between the before and
after clips so the preview stays inside the app. Do not use this claim until the physical-device
lock test in `TESTING.md` passes for the release build.

## Final Timeline

| Final time | Frames | Shot | Motion / edit | Overlay |
|---|---:|---|---|---|
| 00:00-00:03 | 0-89 | Level 1, Novice in field | Static app screen, subtle hero idle only | None |
| 00:03-00:08 | 90-239 | User taps Start | Tap Start, button changes to Pause, hero starts grinding | "Tap start. Begin your climb." |
| 00:08-00:14 | 240-419 | Level counter jumps | Fast cuts: Level 5, 10, 20, 30 | "Every 5 min of focus = 1 level" |
| 00:14-00:20 | 420-599 | Locked-phone proof | Fade from grinding before lock to higher level after unlock | "Lock your phone. Keep earning." |
| 00:20-00:25 | 600-749 | Class upgrades | Fast cuts: Novice -> Squire -> Knight -> Champion | "10 classes. Midnight reset." |
| 00:25-00:30 | 750-899 | Focus History card | Scroll or hold on week chart and day list | "Daily Levels. Your daily climb." |

## Caption Timing

| Caption | In | Out |
|---|---:|---:|
| Tap start. Begin your climb. | 00:03.00 | 00:08.00 |
| Every 5 min of focus = 1 level | 00:08.00 | 00:14.00 |
| Lock your phone. Keep earning. | 00:14.00 | 00:20.00 |
| 10 classes. Midnight reset. | 00:20.00 | 00:25.00 |
| Daily Levels. Your daily climb. | 00:25.00 | 00:30.00 |

Style captions as large, high-contrast text over the app footage, inside comfortable title-safe
margins. Do not show coins, shops, feeds, streak pressure, or any feature outside the app's simple
focus-timer promise.

## Export QA

- Duration is 30 seconds or less at a constant 30 fps.
- Upload copy is 886x1920 H.264 with no alpha channel or device frame.
- The first three seconds contain only captured app footage and no caption.
- All taps, motion, history data, and class changes come from the real app.
- Captions are readable without covering the hero, timer, main button, or history values.
- The locked-phone claim has passed the physical-iPhone test for this build.
- Audio is optional; if included, it contains no copyrighted music or misleading sound effects.
