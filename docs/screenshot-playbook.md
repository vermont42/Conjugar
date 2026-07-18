# Screenshot Playbook

Captures App Store screenshots for Conjugar via `scripts/take_screenshots.sh`. The driver carries the calibration values, per-view navigation, and the workarounds inline as comments; this playbook is the prose-and-procedure wrapper around it.

Ported from the sibling app Conjuguer (French) in July 2026 and adapted for Conjugar: Spanish instead of French, `biz.joshadams.Conjugar`, Spanish exemplars (`ser` / `decir` / `haber`), and Conjugar's own Info-list shape (the About header, not Tenses, is screen 6's scroll target).

## Status

The app-side instrumentation landed in July 2026 and was verified end-to-end on
`iPhone 17 Pro Max`: every anchor below resolves in the AXTree, `ser` sits at the top of
the frequency-sorted Browse list, the `decir`/`haber` model rows resolve, and the fixture
quiz plays through to an all-green results screen. All ten tab coordinates (5 tabs × 2
devices) were verified by tapping each and asserting the destination screen's anchor
appeared. Both targets were then **migrated from iOS 26.0 to iOS 26.3** and everything
re-verified on the new runtime (tab coords, keyboard probes, anchors, fixture-to-results on
both devices); all iOS 26.0 devices were deleted afterward. The simulator inventory is now a
single iOS 26.3 row plus some iOS 17 leftovers, so `udid_for()` resolves both names
unambiguously. **The driver is ready to run.**

## Running it from a fresh Claude session

One thing you must do yourself first — it needs a click in System Settings and a session can't do it: grant **Accessibility permission to `/usr/bin/osascript`** (System Settings → Privacy & Security → Accessibility → add it). Without it the soft-keyboard Cmd+K toggle fails, so the `quiz_mid` shot comes out keyboard-less (the driver treats this as non-fatal and the run still completes). Then paste this to the session:

```
Create the 36 App Store screenshots for this release. Read docs/screenshot-playbook.md
and docs/screenshot-plan.md first, then drive scripts/take_screenshots.sh to produce all
36 (9 views × en/es × iPhone 17 Pro Max + iPad Pro 13-inch (M4)).

Before running:
- Set BOTH kill switches to false in Conjugar/Models/ConjugarTips.swift —
  TipDisplay.tipsEnabled and OnboardingDisplay.onboardingEnabled — and restore both
  to true when all screenshots are captured.
- Confirm both simulators exist (see "Simulator Setup") and that jq + axe are on PATH.

After running:
- Visually review every captured PNG (Read each one). Re-run any bad cell with the
  --device/--lang/--view filters. Pay special attention to the two iPad Info scroll
  targets (the 200/400 values in scroll_until_top) — they were calibrated on iPhone only.
- Assemble docs/screenshots/latest/ and the numbered version_<N>/ upload bundle per the
  playbook (this is the next release, so use the next version_N).
```

Gotchas the session should keep in mind (also covered below): the machine may have **duplicate simulators** with those two names on older runtimes — `udid_for()` takes the first match by list order, which is oldest-runtime-first, so a stale duplicate silently wins. Note `xcrun simctl delete unavailable` does **not** help: those duplicates are perfectly *available*, just on an old iOS, so they survive that command. Delete or rename them by UDID instead (see *iPad reliability*). The full sweep is ~30–45 min and the iPad's first boot can block ~70s — that's `bootstatus -b` working, not a hang.

## Scope

App Store screenshots only — 9 views × 2 languages × 2 devices = 36 PNGs. Not a general-purpose iOS screenshot framework. The capture spec lives in [`docs/screenshot-plan.md`](screenshot-plan.md).

## Prerequisites

- macOS with Xcode 26+ and the **iOS 26.3** simulator runtime installed. (The deployment target is iOS 26, so 26.0 would also run, and everything here was first verified on 26.0; the targets were migrated to 26.3 on 2026-07-18 and re-verified. Tab geometry proved identical between the two to within 0.1 pt.)
- `axe` CLI on PATH (see `ios-build-verify` SKILL.md for installation).
- `ios-build-verify` skill installed; resolve its scripts directory once per session:
  ```bash
  export IBV_SCRIPTS=$(dirname "$(find ~/.claude -path '*ios-build-verify*' -name build_app.sh 2>/dev/null | head -1)")
  ```
- macOS Accessibility permission granted to `osascript`. System Settings → Privacy & Security → Accessibility → add `/usr/bin/osascript`. The driver depends on this for the soft-keyboard Cmd+K toggle (workaround #6). **Granted and verified on this machine, 2026-07-18.** Note that a *missing* permission is not the only way the AXRaise step fails: a freshly-activated Simulator briefly reports no windows, and the resulting `-1719 "Invalid index"` looks just like a permission problem. The driver now waits 0.5 s after `activate` (was 0.2 s) for that reason.
- Two simulators named `iPhone 17 Pro Max` and `iPad Pro 13-inch (M4)` (see "Simulator Setup"). The driver resolves their UDIDs by name at run time — no hardcoding. **Confirm there is exactly one iOS-26 device matching each name before running** (`udid_for()` takes the first match by list order, so a stale-runtime duplicate silently wins); see *iPad reliability*. Verified clean on 2026-07-18.
- **Both kill switches off (then restored).** See the next section — this is the single
  easiest step to forget and it silently ruins screenshots.
- **Clean the iPad status bar (App Store polish).** The driver does *not* manage the status bar, so iPad shots ship with whatever the simulator's clock and **system language** produce — and the iPad status bar shows a *date* (e.g. a German `Freitag 26. Juni` if the sim's system language is German), which looks unprofessional on an EN/ES listing. iPhone shots are unaffected (the notch shows only the time). Set a clean status bar before the iPad sweep — see **"Clean Status Bar"** below. (Not needed for iPhone.)

## Disable tips and onboarding first (then restore)

Conjugar has **two** compile-time master switches, both in
[`Conjugar/Models/ConjugarTips.swift`](../Conjugar/Models/ConjugarTips.swift). Both are
ordinarily `true`. **Set both to `false` before running the driver and restore both to
`true` afterward.** The driver builds once at start, so the flags must be flipped *before*
you launch it — flipping them mid-sweep does nothing.

| Switch | Effect when `false` | What you get if you forget |
|---|---|---|
| `TipDisplay.tipsEnabled` | `ConjugarApp` skips `Tips.configure()`. TipKit shows nothing until configured, so every `TipView` and `.popoverTip(_:)` stays hidden — no per-call-site changes. | A tip card ("Try the Quiz", "Explore Models", the difficulty nudge, the Game Center nudge) lands in the VerbBrowseView / ModelBrowseView / QuizView / SettingsView shots. |
| `OnboardingDisplay.onboardingEnabled` | `MainTabView`'s launch `.task` never trips `router.showOnboarding`, so the first-launch welcome tour never auto-presents. | The onboarding `.fullScreenCover` opaques whatever screen was being captured — usually the very first cell of the sweep. |

```bash
# before the sweep
sed -i '' 's/static let tipsEnabled = true/static let tipsEnabled = false/; \
           s/static let onboardingEnabled = true/static let onboardingEnabled = false/' \
  Conjugar/Models/ConjugarTips.swift

# after the sweep — restore
sed -i '' 's/static let tipsEnabled = false/static let tipsEnabled = true/; \
           s/static let onboardingEnabled = false/static let onboardingEnabled = true/' \
  Conjugar/Models/ConjugarTips.swift

git diff --stat Conjugar/Models/ConjugarTips.swift   # must be empty when you are done
```

**Belt and suspenders.** The kill switch is the primary defense, but the driver keeps two
independent fallbacks, because a stale build or a forgotten flag is the most common way a
sweep goes wrong:

- `seed_defaults` pre-seeds `hasSeenOnboarding=true` into the app's `UserDefaults` right
  after install (workaround #2), which suppresses the tour even in a build where
  `onboardingEnabled` is `true`.
- `wait_for_render` taps a localized Skip label (`Skip` / `Omitir`) if the tour surfaces
  anyway (workaround #11).

Neither fallback covers TipKit — `tipsEnabled` is the only defense there, and a tip card
appearing is not something the driver can detect. **Verify visually.**

> The Settings "Show Onboarding" button deliberately **ignores** `onboardingEnabled`, so
> the flow stays manually reachable for review even with the switch off. That does not
> affect the sweep (the driver never taps it), but it means "onboarding still appears when
> I tap the button" is not evidence the switch is broken.

## Game Center UI

Conjugar talks to Game Center, and its UI is the third thing (after tips and onboarding)
that can intrude on a capture. Unlike those two there is **no compile-time switch** — the
suppression is entirely in `seed_defaults`, and it is enough. The reasoning, so a future
session doesn't have to re-derive it:

| Surface | Reachable during a sweep? | Why |
|---|---|---|
| The in-app "upload your scores to Game Center?" alert (`QuizView.onAppear` → `maybePromptGameCenter()`) | **Yes — this is the one that bites.** | Fires on a fresh install and opaques the AXTree, so `quiz_start_button` is absent and screens 5 and 8 both fail. Suppressed by seeding `didShowGameCenterDialog` + `userRejectedGameCenter` (workaround #15). |
| GameKit's own login sheet / "Welcome back" banner | No | GameKit only presents these once something sets `GKLocalPlayer.local.authenticateHandler`, which happens exclusively inside `GameCenterReal.authenticate()`. That is called from just two places — the alert's **Yes** button and Settings' **Enable Game Center** button — and the driver taps neither. **Nothing authenticates at launch**, so the handler is never installed. |
| Settings' "Enable Game Center" section (screen 9) | Yes, and that's fine | With auth never established, `isGameCenterUIHidden` is false and the section renders. It's an honest depiction of a real feature and sits well below the Region picker the spec puts at top. |

So no extra suppression is warranted. **Two residual risks**, both operator-side rather than
driver-side:

- **Don't tap "Enable Game Center" on the sweep simulator.** Doing so installs the auth
  handler for that process and can raise GameKit's banner over a subsequent capture. If it
  happens, the fix is a clean reinstall — `seed_defaults` runs right after `install_app`, and
  the driver uninstalls first.
- **`userRejectedGameCenter=true` is a lie told to the app for the duration of the sweep.**
  It lives in the app's `UserDefaults` and is wiped by the driver's `uninstall_app`, so it
  never leaks into a later manual session on the same sim — but don't seed it into a
  simulator you also use for hand-testing the Game Center flow without reinstalling after.

## Quick Start

```bash
scripts/take_screenshots.sh  # all 36 (~30-45 min)
scripts/take_screenshots.sh --device "iPhone 17 Pro Max"  # 18 (one device)
scripts/take_screenshots.sh --lang es  # 18 (Spanish only)
scripts/take_screenshots.sh --view model_browse  # 4 (one view, both devices/langs)
scripts/take_screenshots.sh --device "iPhone 17 Pro Max" --lang es --view quiz_results  # exactly 1 cell
```

The `--device` value is the device-class label (with parens). UDIDs are resolved by name in `udid_for()`; the driver does not use `_resolve_udid.sh`.

`VIEWS` are: `verb_browse verb_view model_browse model_view quiz_mid info_browse info_view quiz_results settings`.

## Outputs

The driver writes timestamped PNGs to `docs/screenshots/<timestamp>-<device>-<lang>-<view>.png` (gitignored). One file per cell per run; iterating with `--view` accumulates timestamped versions.

For App Store Connect upload, copy the latest version of each cell to `docs/screenshots/latest/`:

```bash
mkdir -p docs/screenshots/latest && \
for view in verb_browse verb_view model_browse model_view quiz_mid \
            info_browse info_view quiz_results settings; do
  for device in "iPhone-17-Pro-Max" "iPad-Pro-13-inch-(M4)"; do
    for lang in en es; do
      latest=$(ls -t docs/screenshots/*"${device}-${lang}-${view}.png" 2>/dev/null | head -1)
      [[ -n "$latest" ]] && cp "$latest" "docs/screenshots/latest/$(basename "$latest")"
    done
  done
done
```

`ls -t` orders by modification time; the timestamp embedded in the filename matches mtime to the second, so the two ordering schemes agree.

### Per-Release Upload Bundles

App Store Connect's upload dialog takes one (device × locale) at a time and orders screenshots alphabetically by filename. The descriptive `latest/` names — useful as an archive — get in the way at upload time. For each release, project `latest/` into a numbered bundle:

```
docs/screenshots/version_<N>/
├── iPhone_English/{1..9}.png
├── iPhone_Spanish/{1..9}.png
├── iPad_English/{1..9}.png
└── iPad_Spanish/{1..9}.png
```

`<N>` increments per release (`version_3`, `version_4`, …). The row number is the `#` column in the "Per-View Navigation Recipes" table below (1 = VerbBrowseView … 9 = SettingsView). To regenerate after a re-shoot:

```bash
cd docs/screenshots && \
mkdir -p version_<N>/iPhone_English version_<N>/iPhone_Spanish \
         version_<N>/iPad_English  version_<N>/iPad_Spanish && \
for src in latest/*.png; do
  rest="${src##*/}"; base="${rest#????????-??????-}"; base="${base%.png}"
  [[ "$base" =~ ^(iPhone-17-Pro-Max|iPad-Pro-13-inch-\(M4\))-(en|es)-(.+)$ ]] || continue
  case "${BASH_REMATCH[3]}" in
    verb_browse) n=1 ;; verb_view) n=2 ;; model_browse) n=3 ;; model_view) n=4 ;;
    quiz_mid) n=5 ;; info_browse) n=6 ;; info_view) n=7 ;; quiz_results) n=8 ;; settings) n=9 ;;
  esac
  case "${BASH_REMATCH[1]}" in iPhone-17-Pro-Max) d=iPhone ;; *) d=iPad ;; esac
  case "${BASH_REMATCH[2]}" in en) l=English ;; es) l=Spanish ;; esac
  cp "$src" "version_<N>/${d}_${l}/${n}.png"
done
```

`latest/` stays untouched as the timestamped archive; `version_<N>/` is a regenerable projection — re-running the snippet after a re-shoot produces the same 36 files. If the playbook table ever reorders, edit only the inner `case` block.

## Simulator Setup

The driver targets two simulators by name and resolves their UDIDs at run time (`udid_for()` matches the exact device name from `xcrun simctl list devices available`). You only need the two devices to exist with the default names. To (re)create either after `simctl erase` or `simctl delete unavailable`:

```bash
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-26-3

xcrun simctl create "iPhone 17 Pro Max" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max \
  "$RUNTIME"

xcrun simctl create "iPad Pro 13-inch (M4)" \
  com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4-8GB \
  "$RUNTIME"
```

Note the device-type id is `…iPad-Pro-13-inch-M4-8GB`, not `…iPad-Pro-13-inch-M4` — Xcode 26
splits the M4 into 8 GB and 16 GB variants and the bare id no longer resolves. The M4 type
*is* still offered on the 26.3 runtime even though a fresh Xcode install seeds only an M5, so
creating it by hand is the way to get the name the driver expects.

**No sim renaming needed.** Konjugieren's driver hardcoded UDIDs and renamed the iPad to dodge `_resolve_udid.sh`'s regex-special-char bug (parens in `TARGET_SIM`). Conjugar's driver (like Conjuguer's) bypasses `_resolve_udid.sh` entirely and matches the device name as a Python string literal, so `iPad Pro 13-inch (M4)` works unchanged.

> **Note on `iPhone 17 Pro Max` vs. Conjugar's usual sim.** `.claude/ios-build-verify.config.sh` targets a plain **iPhone 17** and carries hand-set 5-tab coordinates for it (`63,822 …`). Those are **not** the Pro Max values — the screenshot driver has its own `tab_coords_for()` table. Don't cross-copy them.

## Clean Status Bar

The driver itself never touches the status bar, so by default every shot carries the
simulator's live clock, battery, and signal state — and on **iPad** the status bar also
shows a **date**, rendered in the simulator's **system language** (independent of the
app's `-AppleLanguages` override). A sim whose system language is German thus stamps
`Freitag 26. Juni` onto otherwise-English/Spanish iPad screenshots. iPhone shots are
unaffected — the notch shows only the time, no date.

Fixing this is two independent pieces:

1. **`simctl status_bar override`** — pins the time/battery/signal to clean values. This is
   per-device and **cleared on every shutdown/reboot**, but it **persists across
   `uninstall`/`install` and app relaunches**, so set it once and leave the device booted
   for the whole sweep. (`take_screenshots.sh` only boots when the device is *not* already
   booted and never reboots, so the override survives a full run.)

   ```bash
   UDID=$(xcrun simctl list devices available | \
     awk -F '[()]' '/iPad Pro 13-inch \(M4\) \(/{print $4; exit}')   # the iOS-26 one
   xcrun simctl status_bar "$UDID" override \
     --time "9:41" \
     --dataNetwork wifi --wifiMode active --wifiBars 3 \
     --cellularMode notSupported \
     --batteryState charged --batteryLevel 100
   ```

   Caveats learned the hard way:
   - **`--time` only accepts a plain clock string** like `"9:41"`. `"9:41 AM"` and even a
     well-formed ISO string (`2026-06-26T09:41:00`) are rejected as *"Invalid, non-ISO
     date/time string"* on this runtime. Use `"9:41"`; the system renders the AM/PM and the
     *date* itself from the real clock + system language (step 2), not from `--time`.
   - **`--cellularMode notSupported`** hides the cellular signal — correct for a Wi-Fi iPad
     (forcing `--cellularBars` instead paints a bogus "Carrier" onto a Wi-Fi-only device).
   - Verify with `xcrun simctl status_bar "$UDID" list`; reset with `… status_bar "$UDID" clear`.

2. **System language → fixes the iPad date's language.** `status_bar override` has **no
   date flag**; the date label follows the device's *system* language. Set it (and reboot,
   which is also when you must **re-apply the override** since reboot clears it):

   ```bash
   lang=en   # or es
   case "$lang" in en) loc=en_US ;; es) loc=es_ES ;; esac
   xcrun simctl spawn "$UDID" defaults write -g AppleLanguages -array "$lang"
   xcrun simctl spawn "$UDID" defaults write -g AppleLocale -string "$loc"
   xcrun simctl shutdown "$UDID"; xcrun simctl boot "$UDID"
   xcrun simctl bootstatus "$UDID" -b >/dev/null
   # re-apply the status_bar override here (cleared by the reboot)
   ```

   Because the system language must match each screenshot's language to localize the date
   (English date on EN shots, Spanish on ES), capture the iPad **one language at a time**:
   set system language → reboot → re-apply override → shoot all 9 views of that language →
   repeat for the other language. This is orthogonal to the per-cell reliability loop below,
   which also runs the iPad a language at a time.

> **Why not bake this into the driver?** The override is trivial to script, but the
> per-language *reboot* (needed for the date) doesn't fit the driver's one-boot-per-device
> loop (it shoots both languages in a single boot). Keeping the status-bar setup as an
> operator step above avoids restructuring the driver around reboots. iPhone needs none of
> this.

## iPad reliability — duplicate sims, render budget, per-cell fallback

Three iPad-specific failure modes surfaced in practice (none affect iPhone):

- **Wrong duplicate simulator / old iPadOS.** `udid_for()` returns the *first* name match
  in `simctl list` order, which is grouped by runtime ascending — so if the machine has
  `iPad Pro 13-inch (M4)` instances on iOS 18.x *and* 26.x, it picks an **18.x** one and
  the install dies with *"Requires a Newer Version of iPadOS … Have 18.0; need 26.0"*. Fix by
  removing the stale-OS duplicates from the name's match set — **rename** them out of the way
  if you may want them back (reversible), or **delete** them outright:
  ```bash
  xcrun simctl rename <UDID-of-iOS18-iPad> "iPad Pro 13-inch (M4) iOS18-PARKED"
  # …re-run sweep…  then restore:
  xcrun simctl rename <UDID> "iPad Pro 13-inch (M4)"
  ```
  Confirm the survivor with the `udid_for` Python snippet (workaround #13) before running.
  Conjugar's deployment target is **iOS 26**, so a stale-runtime sim fails at install, not
  at render — the error message is unambiguous
  (*"Requires a Newer Version of iPadOS … Have 18.0; need 26.0"*).

  **This is not hypothetical — it happened here.** In July 2026 this machine had *four*
  simulators named `iPad Pro 13-inch (M4)` (iOS 18.0, 18.1, 18.4, 26.0); `udid_for()`
  returned the **18.0** one and the iPad install failed. The three iOS-18 duplicates were
  deleted on 2026-07-18 and `udid_for()` now resolves cleanly, but the hazard recurs any time
  Xcode installs an older runtime. List the candidates and identify the survivor with:

  ```bash
  xcrun simctl list devices available | python3 -c '
  import sys,re
  runtime=None
  for line in sys.stdin:
      m=re.match(r"-- (.*) --", line.strip())
      if m: runtime=m.group(1); continue
      m=re.match(r"\s+(.*?) \(([0-9A-Fa-f-]{36})\) \(", line.rstrip())
      if m and "iPad Pro 13-inch (M4)" in m.group(1):
          print(f"{runtime:20s} {m.group(2)}")
  '
  ```

  Then either **delete** the stale ones (`xcrun simctl delete <UDID>` — what was done here)
  or, if you want them back later, park them with `simctl rename` (reversible) so only the
  iOS-26 device matches the exact name. Deleting is irreversible: check what is installed on
  a candidate first (`ls ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Bundle/Application`)
  — the 18.0 device here held Conjugar and Conjuguer installs, both trivially reinstallable,
  which is why deleting was safe.
- **Render budget.** The iPad cold-parses 4,811 verbs (`verbModelMap.xml`) in a regular-size-class
  grid on every launch; render time is variable and intermittently exceeds the original 20 s
  budget, so `wait_budget_for "iPad Pro 13-inch (M4)"` is **45 s**. A *single*
  `wait_for_render` timeout still aborts the whole sweep (`set -e`), so generous headroom
  matters.
- **Per-cell fallback.** The *first* launch after a fresh `install` has never hung; only
  2nd+ relaunches within one driver run intermittently exceed even 45 s. The robust path is
  therefore to invoke the driver **one cell at a time** (`--lang L --view V`) with a small
  retry loop — every cell becomes a first-launch-after-install, and a transient miss costs
  one cell, not the run:
  ```bash
  for view in verb_browse verb_view model_browse model_view quiz_mid \
              info_browse info_view quiz_results settings; do
    for attempt in 1 2 3; do
      scripts/take_screenshots.sh --device "iPad Pro 13-inch (M4)" --lang en --view "$view" && break
    done
  done
  ```
  Keep the device booted across the loop so the status-bar override (above) persists.

## Workarounds

Compact reference. The driver's inline comments hold the full WHY for each — cross-references point at the relevant function.

1. **Bash 3.2 compatibility** (`take_screenshots.sh::appearance_for, tab_coords_for, wait_budget_for`)
   *Symptom:* macOS system bash lacks associative arrays. *Fix:* case-statement lookup functions instead of `declare -A`.

2. **Onboarding suppression** (`take_screenshots.sh::seed_defaults`, `ONBOARDING_LABELS`)
   *Symptom:* `OnboardingView` shows on a fresh install (gated on `Settings.hasSeenOnboarding`), opaquing the first screenshot. *Fix:* pre-seed `hasSeenOnboarding=true` via `simctl spawn defaults write` right after install. Belt-and-suspenders on top of the `OnboardingDisplay.onboardingEnabled` compile-time switch; `wait_for_render` also taps a localized Skip label (workaround #11).

3. **SwiftUI identifier propagation** (`take_screenshots.sh::tap_id_first`)
   *Symptom:* SwiftUI propagates `accessibilityIdentifier` to children; `axe tap --id` refuses to disambiguate. *Fix:* parse the first matching `AXFrame` from `describe-ui` and tap its center via coords.

4. **simctl subcommand naming** (`take_screenshots.sh::type_via_pasteboard`)
   *Symptom:* `xcrun simctl pasteboard set` is not a real subcommand. *Fix:* `xcrun simctl pbcopy <UDID>`.

5. **Unicode typing via pasteboard** (`take_screenshots.sh::type_via_pasteboard`)
   *Symptom:* `axe type` lacks HID-keycode mappings for Spanish accents (á é í ó ú ñ ü). *Fix:* paste via `simctl pbcopy` + Cmd+V (`axe key-combo --modifiers 227 --key 25`). Conjugated Spanish answers are full of accents (`sé`, `habré`, `oí`, `añadió`), so every quiz answer routes through this.

6. **Soft keyboard suppression** (`take_screenshots.sh::ensure_soft_keyboard`)
   *Symptom:* Simulator forwards host hardware-keyboard events; the soft keyboard is suppressed by default. *Fix:* send Cmd+K via `osascript` (Simulator's "Toggle Software Keyboard"); idempotent — checks the AXTree for a "space" key first.

7. **StoreKit review-prompt suppression** (`take_screenshots.sh::seed_defaults`)
   *Symptom:* the StoreKit review modal (`ReviewPrompterReal`, used even in the simulator World config) opaques the AXTree mid-loop. It fires when `promptActionCount % promptModulo == 0` **and** ≥`promptInterval` since `lastReviewPromptDate`. *Fix:* pre-seed `lastReviewPromptDate` to now via `simctl spawn defaults write`, so the cooldown blocks every prompt this run. (Fallback: workaround #12.)

8. **Deep Info-list rows** (`take_screenshots.sh::scroll_until_top, nav_info_browse, nav_info_view`)
   *Symptom:* a lazy list doesn't report off-screen rows' frames, and a fixed-distance swipe is fragile across devices. *Fix:* `scroll_until_top` swipes in fixed increments until the target row's frame top reaches a target y, then stops (robust to device + dynamic-type differences). Conjugar needs this in **both directions of concern**: screen 6 scrolls the Tutor section off the top so the **About** header pins at top, and screen 7 scrolls deep into the Tenses section to reach *Presente de Indicativo*.

9. **`axe --id` typeMismatch on iPad** (`take_screenshots.sh::tap_id`)
   *Symptom:* `axe tap --id` / `--label` throw a Swift `typeMismatch` decoding error in some iPad screen states (e.g., QuizView pre-Start). *Fix:* route all `tap_id` calls through `tap_id_first` (describe-ui + coord-tap) — same path as workaround #3.

10. **Multi-sim window focus** (`take_screenshots.sh::ensure_soft_keyboard`)
    *Symptom:* with both sims booted, Cmd+K hits whichever Simulator window is frontmost. *Fix:* AXRaise the target sim's window by title-substring match before sending the keystroke.

    **The match is by device *family* substring (`iPhone` / `iPad`), so it is only unambiguous
    while exactly one simulator per family is booted** — which is what a normal sweep produces.
    Boot a second iPhone or a second iPad (easy to do while testing, or by leaving an unrelated
    sim running) and `first window whose title contains "iPad"` can raise the wrong one; the
    keystroke then lands on a sim that isn't being screenshotted and `quiz_mid` comes out
    keyboard-less. Observed during the 26.0 → 26.3 migration with four windows open. The
    post-toggle check added in workaround #16 catches it and logs
    `soft keyboard still not visible after Cmd+K` — if you see that warning, check
    `osascript -e 'tell application "System Events" to tell process "Simulator" to get name of every window'`
    and shut down any extra sims of that family.

11. **Localized onboarding labels** (`take_screenshots.sh::ONBOARDING_LABELS`)
    *Symptom:* the onboarding-Skip button label is localized (`Skip` / `Omitir`). *Fix:* array of all known labels; the wait-for-render loop tries each (fallback to workaround #2's pre-seed and the `onboardingEnabled` switch).

12. **Lang-agnostic StoreKit dismiss** (`take_screenshots.sh::dismiss_review_prompt`)
    *Symptom:* if a review prompt slips past #7, its button labels are system-localized (`Not Now` / `Ahora no`), and the modal has both single-button and post-star-tap two-button states. *Fix:* vertical sweep of `describe-ui --point` at a known x-center, tap the bottommost `AXButton` found.

13. **Dynamic UDID resolution** (`take_screenshots.sh::udid_for`)
    *Symptom:* `_resolve_udid.sh`'s regex match breaks on the iPad's paren-bearing default name. *Fix:* resolve UDIDs by exact device name with a Python literal comparison, so no hardcoded UDIDs and no sim renaming.

14. **Status bar (time + iPad date language)** (operator step, not in the driver — see *Clean Status Bar*)
    *Symptom:* iPad shots carry the live clock and a system-language date. *Fix:* `simctl status_bar override --time "9:41" …` (persists across install, cleared on reboot) for the clock/battery/signal, plus a per-language **system-language change + reboot** to localize the iPad date. `--time` rejects `"9:41 AM"`/ISO strings — pass a bare `"9:41"`.

15. **Game Center prompt on the Quiz tab** (`take_screenshots.sh::seed_defaults`)
    *Symptom:* `QuizView.onAppear` calls `maybePromptGameCenter()`, which raises an alert
    ("Would you like Conjugar to upload your future scores to Game Center?") on a fresh
    install. It opaques the AXTree, so `quiz_start_button` is simply **not present** and
    screens 5 and 8 both fail at `tap_id`. Conjuguer has no equivalent prompt, so its
    driver never needed this. *Fix:* pre-seed `didShowGameCenterDialog=true` **and**
    `userRejectedGameCenter=true` in `seed_defaults` — `GameCenterPrompt.decision` returns
    `.doNothing` when either is set. Found the hard way while verifying the fixture in
    July 2026.

16. **The soft keyboard is invisible to a full AXTree dump** (`take_screenshots.sh::keyboard_is_visible`)
    *Symptom:* the keyboard runs in its own process, so `axe describe-ui` on a screen with the
    keyboard plainly visible returns **zero** keyboard elements. The original
    `ensure_soft_keyboard` guarded on counting AXTree elements labelled `space`, which is
    therefore always 0 — the guard never fired, and since Cmd+K is a *toggle* whose state
    persists in Simulator across app launches, the second `quiz_mid` cell of a sweep would
    switch the keyboard back **off**. Four `quiz_mid` shots would alternate
    keyboard/no-keyboard, silently. *Fix:* `describe-ui --point` **can** see the keyboard (the
    same trick workaround #12 uses on the StoreKit modal), so probe a mid-keyboard coordinate
    and treat a ≤2-character label ("g") as keys-present. `ensure_soft_keyboard` now also
    re-checks after the toggle and warns if it did not land. Probe points are per-device in
    `keyboard_is_visible`; deliberately **not** the space bar, whose blank label is
    indistinguishable from "nothing found". Found by verification in July 2026.

17. **Model rows keyed by exemplar, not class number** (`take_screenshots.sh::nav_model_browse, nav_model_view`)
    *Symptom:* `ModelInfo.id` is the `classNumber`, and class numbers contain hyphens (`29-2`, `30-1`). The `ID_MATCH` predicate treats `-` as its prefix boundary, so `model_row_29` would spuriously match `model_row_29-2`. *Fix:* identify model rows by **exemplar** (`model_row_decir`, `model_row_haber`) — hyphen-free and what the spec names anyway.

## Per-View Navigation Recipes

| # | View | Mode | Driver function | Notes |
|---|---|---|---|---|
| 1 | VerbBrowseView | dark | `nav_verb_browse` | Default landing; `wait_for_render browse_verb_count`. Frequency sort is the default (`Settings.verbSortDefault == .frequency`) → **ser** on top. |
| 2 | VerbView | light | `nav_verb_view` | `tap_id_first verb_row_ser`. |
| 3 | ModelBrowseView | dark | `nav_model_browse` | `tap_tab models` → settle on `model_row_decir`. Irregularity sort is the default (`Settings.modelSortDefault == .irregularity`) → the **decir** model at top. |
| 4 | ModelView | light | `nav_model_view` | `tap_tab models` → `tap_id_first model_row_haber`. Spec: don't scroll horizontally — the driver never does. |
| 5 | QuizView (mid) | dark | `nav_quiz_mid` | `tap_tab quiz` → `quiz_start_button` → `input_quiz_conjugation` → paste fixture answer 0 → `ensure_soft_keyboard`. Captured before submit (keyboard visible per spec). |
| 6 | InfoBrowseView | light | `nav_info_browse` | `tap_tab info` → settle on `info_row_purpose_and_use` → `scroll_until_top info_row_purpose_and_use` (scrolls the Tutor section off, pinning the **About** header at top). |
| 7 | InfoView | dark | `nav_info_view` | `tap_tab info` → `scroll_until_top info_row_presente_de_indicativo 400` → tap it. |
| 8 | ResultsView | light | `nav_quiz_results` | `tap_tab quiz` → `quiz_start_button` → N× (paste + Return + sleep 0.3) → `dismiss_review_prompt` if needed → `verify_screen_loaded results_score`. |
| 9 | SettingsView | dark | `nav_settings` | `tap_tab settings`; the **Region** picker is the first section, so no scroll. |

Tab-bar coordinates live in `tab_coords_for()`. iPhone uses the bottom pill tab bar (y=899.3); iPad uses a top segmented tab bar (y=54). Tab order is `verbs models quiz info settings`, matching `MainTabView`.

**All ten were verified in July 2026** by tapping each and asserting the destination
screen's anchor appeared. The two rows had to be established differently, which is worth
knowing before re-calibrating:

- **iPhone — confirmed, not measured.** The pill's children are not exposed; the whole bar
  reports as one `Tab Bar` group (frame `{0,873},{440,83}`), so there is nothing to measure.
  Conjuguer's inherited values were kept and each was confirmed by tapping.
- **iPad — measured.** The top bar exposes each tab as an `AXRadioButton`, so the centers are
  exact. Conjuguer's inherited values worked too (each landed inside the right tab) but were
  3–6 pt off-center; `tab_coords_for()` now carries the measured centers. Re-measure with:
  ```bash
  axe describe-ui --udid <UDID> | jq '[.. | objects | select(.role? == "AXRadioButton")] | .[] | {AXLabel, AXFrame}'
  ```

A tap that lands on the right tab but is visibly off-center is not a cosmetic issue to
ignore — it is the early warning that the bar's geometry has shifted, and the next SwiftUI
or device change may push it out of the tab entirely.

> **Screen 6 differs from Conjuguer's.** Conjuguer's spec wanted the *Tenses* header at
> top; Conjugar's [plan](screenshot-plan.md) wants **About** ("Acerca de"). About is the
> *second* section in `InfoBrowseView` — the availability-gated **Tutor** section sits above
> it — so the scroll is short and, on a simulator (where Apple Intelligence is unavailable),
> the Tutor section renders as a single "unavailable" reason row rather than a link. Either
> way `scroll_until_top` handles it; don't hardcode a swipe distance.

### The quiz fixture

Screens 5 and 8 rely on a DEBUG-only deterministic quiz. When launched with
`-CONJUGAR_QUIZ_FIXTURE screenshot`, `Quiz.start()` builds a fixed question plan via
`generateScreenshotFixture()` and writes the correct answers to
`Documents/screenshot_fixture_answers.json` via `exportFixtureAnswers()` (both `#if DEBUG`,
in [`Conjugar/Models/Quiz.swift`](../Conjugar/Models/Quiz.swift)). The driver reads that JSON
(`read_fixture_answers_path`) and types the answers.

Each exported `answer` must be a form `ConjugationResult` scores as a **total match**.
`exportFixtureAnswers()` lowercases every answer to strip the engine's UPPERCASE
irregularity encoding (`TenseBridge` returns `soY`, `habRá` — uppercase flags the irregular
part). Note this is a legibility measure, **not** a correctness one: `ConjugationResult.compare`
lowercases both sides before comparing, so a marked form would score as a `totalMatch`
anyway. (An earlier draft of this playbook claimed otherwise; verified against
`ConjugationResult.swift` in July 2026.)

`compare` also folds diacritics — a missing accent scores `partialMatch`, not `noMatch` —
but the fixture exports fully-accented forms, so every row scores `totalMatch` and the
results screen is all green.

The fixture is **12 hand-picked questions**, not a generated 30 — `Quiz.screenshotFixture`
is a fixed literal list, so the per-question review rows are identical across all four
device × language cells, and short enough that the paste loop costs ~15 s per cell instead
of ~40 s. The driver reads the count from the JSON rather than hardcoding it.

Two constraints on anything added to the fixture, both enforced by comments on
`Quiz.screenshotFixture`:
- **No second-person slots.** `tú` vs. `vos` is a user setting (`Settings.secondSingularQuiz`)
  and `vosotros` is suppressed in the Latin America region, so a second-person question would
  render differently depending on settings the driver does not control.
- **Every slot must conjugate.** `exportFixtureAnswers()` logs an error rather than exporting
  a blank, because a blank would desynchronize the paste loop from the on-screen questions and
  every later answer would miss.

The answer field auto-focuses after **Start** and re-focuses after each submission
(`QuizView`'s `fieldFocused` / `.onSubmit { submit() }`), so the answer sweep is just paste +
Return per question against `input_quiz_conjugation`.

## Instrumentation checklist

What the driver needs from app code — **all of it landed in July 2026** and is listed here
as the maintenance inventory, not as outstanding work. Nothing here is behavioral:
identifiers are invisible to users, and the fixture is `#if DEBUG`.

- [x] `verb_row_<infinitive>` on `VerbBrowseView`'s row `NavigationLink` (both the grid and
      list branches — the iPad uses the grid). Spec needs `verb_row_ser`.
- [x] `model_row_<exemplar>` on `ModelBrowseView`'s row `NavigationLink` (both branches).
      Spec needs `model_row_decir` and `model_row_haber`. **Exemplar, not classNumber** —
      workaround #17.
- [x] `Info.stableKey`: a locale-independent ASCII key on `Info`, since `heading` is a
      localized string for the About articles (`L.Info.purposeAndUseHeading`) even though the
      tense headings are hardcoded Spanish. Spec needs `purpose_and_use` and
      `presente_de_indicativo`.
- [x] `info_row_<stableKey>` on `InfoBrowseView`'s row `NavigationLink`.
- [x] `quiz_start_button` on `QuizView`'s `startButton`.
- [x] `input_quiz_conjugation` on `QuizView`'s answer `TextField`.
- [x] `results_score` on `ResultsView`'s score `Text`.
- [x] `Quiz.screenshotFixture` + `startScreenshotFixture()` + `exportFixtureAnswers()`,
      gated `#if DEBUG` and triggered by the `-CONJUGAR_QUIZ_FIXTURE screenshot` launch
      argument. (Named `screenshotFixture`, not Conjuguer's `generateScreenshotFixture()`:
      Conjugar's is a fixed literal list rather than a generator.)

Reused as-is, no change needed: `browse_verb_count` (already the `ios-build-verify` launch
anchor) doubles as the driver's post-launch render anchor.

Not an identifier, but part of the same landing: `seed_defaults` gained the two Game Center
keys (workaround #15).

## Recovery Guidance

### Don't Break These — Driver Anchor Dependencies

The driver depends on these app-side touchpoints. Renaming any one silently breaks the corresponding screen with no compile-time signal — the next sweep produces a wrong screenshot or `wait_for_render` times out.

| Touchpoint | Driver depends on | Source file |
|---|---|---|
| `browse_verb_count` identifier | `wait_for_render` polls for it after every launch (render anchor) | `Conjugar/Views/VerbBrowseView.swift` |
| `verb_row_<infinitive>` identifiers | `tap_id_first verb_row_ser` for screen 2 | same file |
| `model_row_<exemplar>` identifiers | `model_row_decir` settle (screen 3) + `tap_id_first model_row_haber` (screen 4) | `Conjugar/Views/ModelBrowseView.swift` |
| `info_row_<stableKey>` identifiers | `verify_screen_loaded` + `scroll_until_top info_row_purpose_and_use` (screen 6); `info_row_presente_de_indicativo` (screen 7) | `Conjugar/Views/InfoBrowseView.swift` + `Info.stableKey` in `Conjugar/Models/Info.swift` |
| `Info.stableKey` field | source of every `info_row_<stableKey>` (locale-independent; `heading` is localized for the About articles) | `Conjugar/Models/Info.swift` |
| `quiz_start_button` identifier | quiz nav for screens 5 and 8 | `Conjugar/Views/QuizView.swift` |
| `input_quiz_conjugation` identifier | answer field for screens 5 and 8 | same file |
| `Quiz.screenshotFixture` + `startScreenshotFixture()` + `exportFixtureAnswers()` | DEBUG-gated fixture; JSON written to `Documents/screenshot_fixture_answers.json` when launched with `-CONJUGAR_QUIZ_FIXTURE screenshot` | `Conjugar/Models/Quiz.swift` |
| `didShowGameCenterDialog` / `userRejectedGameCenter` keys | `seed_defaults` pre-seeds both so `maybePromptGameCenter()` stays quiet (workaround #15) | `Conjugar/Utils/Settings.swift` + `Conjugar/Views/QuizView.swift` |
| `results_score` identifier | `verify_screen_loaded results_score` after the answer loop | `Conjugar/Views/ResultsView.swift` |
| `TipDisplay.tipsEnabled` / `OnboardingDisplay.onboardingEnabled` | operator flips both to `false` before the sweep | `Conjugar/Models/ConjugarTips.swift` |

The `info_row_<stableKey>` keys are locale-independent ASCII (e.g. `presente_de_indicativo`, `purpose_and_use`); `verb_row_<infinitive>` and `model_row_<exemplar>` carry Spanish text (e.g. `verb_row_ser`, `model_row_haber`) — the driver passes them as UTF-8 and matches via `describe-ui` + `jq`, which handles non-ASCII fine.

> **Watch the accented exemplars.** Some Spanish infinitives carry accents (`oír`, `reír`,
> `añadir`). An identifier built from one is valid UTF-8 and matches fine, but don't retype
> it by hand in the driver — copy it, or the ASCII lookalike silently matches nothing.

### Sim Runtime Drift

If the iOS 26.3 simulator runtime is replaced by 26.4+, the AXTree shape may shift slightly — especially for system-controlled surfaces like the StoreKit review prompt. Recreate the sims on the new runtime, re-verify workarounds #7 and #12 still match, and re-run a single test cell:

```bash
scripts/take_screenshots.sh --device "iPad Pro 13-inch (M4)" --lang en --view quiz_results
```

### Identifier Renames in App Code

Use the touchpoint table above as the rename checklist. After any identifier change:

```bash
rg -n "<old_identifier>" Conjugar/
rg -n "<old_identifier>" scripts/take_screenshots.sh
```

Update both sides; re-run a single test cell to verify.

### Locale Shifts and New Languages

If a third app language ships:

1. Append the localized "Skip" label to `ONBOARDING_LABELS` in the driver.
2. Append the language code to `LANGS=( en es )` in the driver.
3. Add a corresponding `case` arm in `launch_with_lang()` for the locale string.
4. Re-run `--view quiz_results --lang <new-lang>` to verify `dismiss_review_prompt`'s sweep still finds the system buttons in the new language.

The vertical-sweep dismiss (workaround #12) is lang-agnostic by design, so step 4 should pass without further change.

### SwiftUI Version Bumps

A SwiftUI version that changes how `accessibilityIdentifier` propagates, or where `AXFrame` is reported, can break `tap_id_first` silently. After any major SwiftUI bump:

```bash
axe describe-ui --udid <UDID> | jq '[.. | objects | select(.AXUniqueId? == "verb_row_ser")][0]'
```

If `AXFrame` is missing or the structure has changed, `tap_id_first` needs a corresponding update.

### Re-running Individual Cells

Visual review will surface bad cells. Re-run any single one via the `--device` / `--lang` / `--view` filter flags (Quick Start). Each filter is independent; combine to narrow further.

## Maintenance Triggers

- **New model or info topic.** If the change alters which 9 views ship as App Store screenshots, update [`docs/screenshot-plan.md`](screenshot-plan.md) first; the driver's `VIEWS` array follows. New info topics need a `stableKey` in `Info.swift` (the `info_row_<stableKey>` identifier comes from it).
- **New device size class.** Add the device-class label to `DEVICES`, calibrate `tab_coords_for()` (top vs. bottom tab bar — iPad's regular size class uses a top segmented bar at y=54; iPhone's is a bottom pill bar at y=899.3), and verify the scroll targets still apply. `udid_for()` resolves the new device by name automatically.
- **Quiz length or difficulty default changes.** Screens 5 and 8 read the fixture's own length; confirm `generateScreenshotFixture()` still pins a count rather than inheriting `Settings.difficulty`.
- **`axe` upstream fix for the iPad `--id` `typeMismatch` bug.** If a future `axe` release fixes the bug, `tap_id` can be simplified back to `axe tap --id` directly. The driver's `tap_id_first` is currently always-on; after upstream fix it can become iPad-only or be removed.

## Known Gotchas

- **Flip *both* switches off before the run.** `TipDisplay.tipsEnabled` and
  `OnboardingDisplay.onboardingEnabled`, both in `Conjugar/Models/ConjugarTips.swift`. See
  *Disable tips and onboarding first*. The driver builds once at start, so they must be set
  first — and restored to `true` when the sweep is done.
- **Default sorts drive screens 1 and 3.** Screen 1 relies on `Settings.verbSortDefault == .frequency` (ser on top); screen 3 on `Settings.modelSortDefault == .irregularity` (the decir model at top). The driver does not change sorts — segmented pickers render with empty AXTree children on iOS 26 and aren't individually addressable by id. A fresh install starts at the defaults, so this holds; if either default changes, re-spec those screens. Both defaults were verified in `Conjugar/Utils/Settings.swift` in July 2026.
- **The Info scrolls are calibration-sensitive.** Screen 6 wants the About section header at the top; screen 7 parks *Presente de Indicativo* in the safe middle band (`scroll_until_top … 400`) before tapping. Tune the target y values if a header is clipped or a row lands under the tab bar.
- **Apple Intelligence Tutor surfaces are availability-gated.** The Tutor section in InfoBrowseView (and the AI page in OnboardingView) render as a live `NavigationLink` only when `Current.languageModelService.isAvailable`. On a simulator — where the model is always unavailable — it shows a reason row instead. Screen 6 scrolls past it either way, so this doesn't break the sweep, but it *does* mean the App Store shots will never show the Tutor entry point. If you want it in the listing, that shot has to be taken by hand on a real Apple-Intelligence device.
- **Review-prompt cooldown is per-install.** `seed_defaults` pre-seeds `lastReviewPromptDate` for in-run prompts, but a manual screenshot capture of the StoreKit modal would still require uninstalling/reinstalling first.
- **iPad first-boot is ~70s on a fresh sim.** Data-migration plugins initialize on first boot; subsequent boots are ~22s. The `xcrun simctl bootstatus -b` step can block for ~70s during that initial boot. Don't kill the sweep thinking it's hung — `bootstatus -b` is doing the right thing.
</content>
</invoke>
