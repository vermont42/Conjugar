---
name: run-in-simulator
description: Launch and drive Conjugar in the iOS simulator — build, install, launch, screenshot, and tap the running app to verify a change works (not just tests). Use when asked to run the app, screenshot a screen, or confirm UI behavior.
---

# Run Conjugar in the iOS Simulator

Verified recipe for launching the app and driving its UI programmatically.
All commands run from the repo root.

## 1. Build

```bash
xcodebuild -project Conjugar.xcodeproj -scheme Conjugar \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

The built app lands in DerivedData; resolve the path robustly:

```bash
APP=$(xcodebuild -project Conjugar.xcodeproj -scheme Conjugar \
  -destination 'platform=iOS Simulator,name=iPhone 17' -showBuildSettings build 2>/dev/null \
  | awk '/CODESIGNING_FOLDER_PATH/ { print $3 }' | head -1)
```

(As of 2026-07 this is
`~/Library/Developer/Xcode/DerivedData/Conjugar-dfhwsnzaqgygknduiqopivnayjyh/Build/Products/Debug-iphonesimulator/Conjugar.app`.)

## 2. Boot a simulator and capture its UDID

⚠️ **This machine can have several devices named "iPhone 17", more than one
booted.** Never target by name — capture one UDID and use it for every
subsequent command, or installs/taps/screenshots can hit different devices:

```bash
xcrun simctl boot "iPhone 17" 2>/dev/null  # no-op if one is already booted
open -a Simulator
UDID=$(xcrun simctl list devices | grep "iPhone 17 (" | grep Booted \
  | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
```

## 3. Install and launch

Bundle id: `biz.joshadams.Conjugar`.

```bash
xcrun simctl install $UDID "$APP"
xcrun simctl launch $UDID biz.joshadams.Conjugar
sleep 8   # the launch screen lingers; screenshots before ~8 s show the flamenco splash
```

## 4. Screenshot (and actually look at it)

```bash
xcrun simctl io $UDID screenshot "$SCRATCHPAD/screen.png"
```

Read the PNG. If it shows the dancer splash, wait and reshoot — that's the
launch screen, not the app. iPhone 17 screenshots are 1206×2622 **pixels**
(3× scale).

## 5. Tap / interact — use idb, in points

- `simctl` cannot tap. `osascript`/System Events clicks fail here
  ("not allowed assistive access"), and `cliclick` is not installed.
- **`idb` (in `/usr/local/bin/idb`) works** and needs no extra setup:

```bash
idb ui tap --udid $UDID <x> <y>   # coordinates in POINTS
```

- Convert screenshot pixels → points by dividing by 3 (iPhone 17 is
  402×874 points). Example: the Browse tab's segmented control sits at
  y≈767 pt; its right segment center is ≈(293, 767).
- Tab bar items (points, approx): Browse (56, 820), Quiz (158, 820),
  Info (243, 820), Settings (327, 820).

## 6. Injecting or resetting app state

- ⚠️ `xcrun simctl spawn $UDID defaults write biz.joshadams.Conjugar …`
  does **not** reach the app's sandboxed `UserDefaults.standard` — the app
  reads its container plist, and editing that plist directly is defeated by
  cfprefsd caching. **Don't fight it: change state through the UI (idb
  taps), which is also what you should be verifying anyway.**
- Full reset: `xcrun simctl uninstall $UDID biz.joshadams.Conjugar` then
  reinstall (wipes UserDefaults, so Settings like `verbSort` return to
  defaults).
- The simulator app uses `World.simulator` (`World.swift`), which has a
  **real** `GetterSetterReal`/UserDefaults — persistence behaves like
  production. Relaunch (`simctl terminate` + `simctl launch`) to verify
  settings survive.

## 7. Cleanup

```bash
xcrun simctl terminate $UDID biz.joshadams.Conjugar
```

Leave the simulator booted; booting is the slow part.
