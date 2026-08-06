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

**First full 36-shot sweep: 2026-07-18** (bundle `docs/screenshots/version_1/`). It shook
out four defects that the per-cell verification had not: the iPad's tab coordinates are
**language-dependent** (workaround #18, the only hard failure), `nav_settings` had no
settle so both iPad settings cells caught a **mid-crossfade** frame (#19), one iPad cell
lost a tap to a **mid-render layout shift** (#20), and — not a driver problem at all —
**`ModelRowLabel` was missing `.contentShape(Rectangle())`**, so model rows were untappable
except on their text and all four iPhone `model_view` cells captured the list instead of
the detail. That last one was a real user-facing bug, fixed in
`Conjugar/Views/ModelBrowseView.swift`. All four are addressed; the driver is in better
shape than before the sweep.

**Second full 36-shot sweep: 2026-07-26 — clean, then deliberately discarded.** All 36 cells
captured on the first attempt: zero retries, zero driver warnings, zero re-shoots after
visual review of every PNG, and `verify_store_media.sh` reported **0 blocking, 0 advisory**
on the assembled bundle. **That output no longer exists.** The review turned up the
light-mode status-bar defect described below, Josh chose to fix it, and the fix is an
`Info.plist` change — so every one of those 36 files predates the current build and was
deleted rather than left on disk to be mistaken for current. `version_2` is therefore an
**unused number**: the next sweep should claim it.

The run still counts as the driver's first clean pass, and its findings stand. Everything
the previous sweep shook out stayed fixed, and the three fixes that had only ever been
verified in isolation all held up end to end:

- **Alpha flattening (#23)** — every capture was `hasAlpha: no`; version_1 still fails the
  same check 36/36, so the contrast is real rather than a vacuous pass.
- **Settle gate (#22) + `nav_settings` anchor (#19)** — both iPad settings cells are fully
  opaque, with none of version_1's Browse-grid ghosting.
- **Largest-area `frame_of` (#21)** — no wrong-element taps anywhere.
- **Measured iPad tab centers (#18)** — iPad/es `quiz_mid` and `quiz_results`, the cells that
  hard-failed version_1, both landed on **Test** rather than Información.
- **Model-row tappability (`32c1746`)** — all four `model_view` cells show the `Haber`
  *detail*, not the list.
- **iPad system language (#14)** — the French leftover is gone; iPad status bars read
  `Sun Jul 26` / `Domingo 26 de julio` per language.

Two new findings came out of it, both folded in below: the pinned clock is **locale-formatted**,
which makes the status-bar language dance an iPhone concern too (see *Clean Status Bar*), and
the `Cmd+K` misfire has a root cause the AXRaise never covered (see workaround #10).

**Third full 36-shot sweep: 2026-07-26 (later the same day) — shipped as `version_2`.** This
is the sweep that re-shot everything against the status-bar fix, and it is the bundle on disk
to upload. 35 of 36 cells were right on the first attempt; the one defect was **iPad/es
`quiz_mid`, captured without the soft keyboard** because the iPad had come back from the
prep reboot **booted but with no Simulator window**, so `ensure_soft_keyboard`'s AXRaise had
nothing to raise (new workaround #24 — the driver reported it honestly as
`AppleScript Cmd+K failed 3x`, which is what made it a five-minute fix rather than a shipped
defect). After attaching a window the cell was re-shot correctly. Every PNG was then reviewed
by eye and `verify_store_media.sh docs/screenshots/version_2` reported **0 blocking, 0
advisory**.

Everything the earlier sweeps fixed stayed fixed: alpha-free captures, no ghosted iPad
Settings, no wrong-element taps, `Haber` detail in all four `model_view` cells, and — new
this time — the **light-mode status bar is legible in all 16 light cells**, dark-on-light,
which is the whole reason the second sweep was thrown away. Clocks agree across devices
within a language (`9:41` in English, `09:41` in Spanish) and the iPad date reads
`Sun Jul 26` / `Domingo 26 de julio`. The settle gate never logged
`screen still changing after 8 samples`, so `7.5e7` still has headroom.

Two cosmetic differences were reviewed and deliberately shipped: the Spanish `quiz_mid`
keyboard is the English layout (documented under *Known Gotchas*), and the iPad's Spanish
Browse/Models screens collapse the search field to a magnifying-glass button because the
Spanish tab labels are wider — genuine adaptive layout, not a capture defect.

**Fourth full 36-shot sweep: 2026-08-01 — shipped as `version_3`.** Occasioned by the
**Browse → Verbs tab rename** (commit `37368a1`), which put a stale label in all 36 of
version_2's cells. Two things changed with it: the iPad target moved from the **M4 to the
M5** (per [`docs/screenshot-plan.md`](screenshot-plan.md); same 13-inch geometry and the same
2064×2752 capture, so it is a rename in six `case` arms and nothing more), and the
**soft-keyboard mechanism was rebuilt** because Cmd+K stopped working on this toolchain —
see workaround #25, the one substantial finding of this sweep.

Cost of that discovery: the first cell of the sweep shipped a keyboard-less `quiz_mid` with an
honest warning, and the fix took three iterations to get right, each one visible in a
re-shot cell — Cmd+K inert → hardware keyboard detached but the paste silently dropped (axe's
Cmd+V needs it *attached*) → an edit callout sitting over the question card. The final shape
orders the two states instead of choosing between them.

Everything the earlier sweeps fixed stayed fixed: alpha-free captures (`verify_store_media.sh
docs/screenshots/version_3` → **0 blocking, 0 advisory**), no ghosted iPad Settings, no
wrong-element taps, `Haber` detail in all four `model_view` cells, legible light-mode status
bars, and clocks agreeing within a language (`9:41` / `09:41`, iPad dating `Sat Aug 1` /
`Sábado 1 de agosto`). The settle gate never warned, so `7.5e7` still has headroom on the M5.

One cell needed a re-shoot for a reason the driver got right: iPad/es `quiz_mid` twice logged
`frontmost is 'Safari'` / `'Code'` and **refused to send the menu click**, which is workaround
#10's frontmost guard doing exactly its job — the machine was in use. It landed on the third
try. Both cosmetic differences from version_2 persist and were again deliberately shipped:
the English keyboard layout in the Spanish `quiz_mid` cells, and the iPad's collapsed Spanish
search field. The next sweep should claim **`version_4`**.

**`docs/screenshots/version_1` must not be uploaded, and `version_2` is now stale too** — all
36 of its cells show the old **Browse** tab label. `version_3` is the current bundle; reach
for that one. Three reasons version_1 is dead, all still true of it — the third being that it
predates the status-bar fix, so its 16 light cells show the white-on-white status bar
described in *Known Gotchas*.

1. **All 36 files carry an alpha channel** and fail `scripts/verify_store_media.sh` 36/36.
   `axe` writes RGBA and nothing flattened it at the time; Apple rejects on format, so a
   visual review could never have caught this. Flattening the existing bundle would clear
   the upload block, but see #2.
2. **It is a hand-patched bundle, not the output of one clean run.** The raw timestamps in
   `docs/screenshots/` tell the story: the sweep ran 15:03–15:23, then ~14 individual cells
   were re-shot one at a time through 16:14, and the folder was assembled at 16:15 — before
   the fixes in `17faf79` (16:27) were even committed. So part of it is pre-fix output from
   the run that *found* those defects. It also predates `32c1746` (model rows tappable) and
   `e128b47` (the Purpose & Use rewrite).

On **2026-07-26** five fixes were ported in from the sibling apps — workarounds #21–#23,
`resolve_ibv_scripts` narrowed to the marketplace clone, `scripts/verify_store_media.sh`,
and the `rm -rf` in the `latest/` assembly snippet.

`STABLE_PIXEL_TOLERANCE` was then **measured on Conjugar** the same day and the settle gate
verified against a live cross-fade: a gated capture is byte-identical to the settled screen
where an ungated one reproduces the workaround #19 ghosting exactly. `resolve_ibv_scripts`
was confirmed to resolve to the marketplace clone at run time. The remaining three fixes —
alpha flattening, largest-area `frame_of`, and the `latest/` clear — were verified in
isolation that day and then **exercised end to end by the 2026-07-26 sweep hours later**; all
three held (see *Status* above). The settle gate never once logged
`screen still changing after 8 samples`, so `7.5e7` has adequate headroom on both devices.

**Review every PNG anyway.** A clean run is evidence the known failure modes stayed fixed,
not that the next one cannot fail differently — and every failure this driver has ever had
produced a plausible-looking screenshot with an exit code of 0.

## Running it from a fresh Claude session

One thing you must do yourself first — it needs a click in System Settings and a session can't do it: grant **Accessibility permission to `/usr/bin/osascript`** (System Settings → Privacy & Security → Accessibility → add it). Without it the driver cannot drive Simulator's menu bar, so it cannot detach the hardware keyboard and the `quiz_mid` shot comes out keyboard-less (the driver treats this as non-fatal and the run still completes; see workaround #25). Then paste this to the session:

```
Create the 36 App Store screenshots for this release. Read docs/screenshot-playbook.md
and docs/screenshot-plan.md first, then drive scripts/take_screenshots.sh to produce all
36 (9 views × en/es × iPhone 17 Pro Max + iPad Pro 13-inch (M5)).

Before running:
- Set ALL THREE kill switches to false in Conjugar/Utils/KillSwitches.swift —
  TipDisplay.tipsEnabled, OnboardingDisplay.onboardingEnabled, and
  TutorDisplay.tutorUnavailableRowEnabled — and restore all three to true when all
  screenshots are captured.
- Confirm both simulators exist (see "Simulator Setup") and that jq + axe are on PATH,
  and that ImageMagick (magick) is installed — without it the settle gate and the
  alpha flattening both degrade to no-ops with only a log line.
- Per "Clean Status Bar", run the sweep ONE LANGUAGE PER BOOT on BOTH devices, in this
  order per language: set the sim's system language -> reboot -> RE-APPLY the
  simctl status_bar override -> shoot all 9 views. The reboot clears the override, so
  applying it first silently ships a live wall-clock. The system language matters on the
  iPhone too, not just the iPad: it sets the DATE language on iPad, and on both devices
  it decides whether the pinned time renders "9:41" (en_US) or "09:41" (es_ES).
  Don't assume either sim's current language — run prep_screenshot_sim.sh for every
  (device, language) pass and read the verification lines it prints.

After running:
- Visually review every captured PNG (Read each one). Re-run any bad cell with the
  --device/--lang/--view filters. The two iPad Info scroll targets (the 200/400 values
  in scroll_until_top) were calibrated on iPhone but verified correct on iPad in the
  2026-07-26 sweep — re-check them, but they are not expected to need tuning.
- Assemble docs/screenshots/latest/ and the numbered version_<N>/ upload bundle per the
  playbook. Use version_4: version_1, version_2 and version_3 are all on disk (version_3
  is the 2026-08-01 shipped bundle). Confirm with `ls -d docs/screenshots/version_*` first.
- Run scripts/verify_store_media.sh docs/screenshots/version_<N> and fix anything it
  reports BEFORE uploading. Visual review cannot see an alpha channel or a wrong
  display-size slot; this catches both.
```

**Budget time for re-shoots, and never skip the visual review.** The first full sweep
(2026-07-18) produced **six** bad cells that the driver reported as successes — four from a
real app bug, two from animation timing — plus two hard failures. A swallowed tap or a
mid-transition capture yields a *plausible* screenshot of the wrong screen, which no exit
code can catch. See workarounds #18–20 and *Known Gotchas*.

The second sweep (2026-07-26) then produced **zero** bad cells, so the fixes work — but note
what that actually licenses. It justifies expecting a smooth run; it does not justify
skipping the review, because a clean run and a run with six silent failures are
indistinguishable from the exit codes alone. Budget the review time either way. Reading 36
PNGs costs far less than shipping one wrong screen to the App Store.

Gotchas the session should keep in mind (also covered below): the machine may have **duplicate simulators** with those two names on older runtimes — `udid_for()` takes the first match by list order, which is oldest-runtime-first, so a stale duplicate silently wins. Note `xcrun simctl delete unavailable` does **not** help: those duplicates are perfectly *available*, just on an old iOS, so they survive that command. Delete or rename them by UDID instead (see *iPad reliability*). The full sweep is ~30–45 min and the iPad's first boot can block ~70s — that's `bootstatus -b` working, not a hang.

## Scope

App Store screenshots only — 9 views × 2 languages × 2 devices = 36 PNGs. Not a general-purpose iOS screenshot framework. The capture spec lives in [`docs/screenshot-plan.md`](screenshot-plan.md).

## Prerequisites

- macOS with Xcode 26+ and the **iOS 26.3** simulator runtime installed. (The deployment target is iOS 26, so 26.0 would also run, and everything here was first verified on 26.0; the targets were migrated to 26.3 on 2026-07-18 and re-verified. Tab geometry proved identical between the two to within 0.1 pt.)
- `axe` CLI on PATH (see `ios-build-verify` SKILL.md for installation).
- **Simulator.app running — the driver now handles this itself.** `ensure_simulator_app`
  launches it when absent, and `assert_framebuffer_live` refuses to run against a device that
  renders black (workaround #26). Both run in a preflight pass *before* `build_app.sh`, so a
  dead simulator costs seconds instead of a wasted build. You no longer have to remember to open
  Simulator first; leaving it open is still the best state to run in, since the keyboard steps
  need its menu bar.
- `ios-build-verify` skill installed; resolve its scripts directory once per session:
  ```bash
  export IBV_SCRIPTS=$(dirname "$(find ~/.claude/plugins/marketplaces -path '*ios-build-verify*' -name build_app.sh 2>/dev/null | head -1)")
  ```
  **Search `plugins/marketplaces`, not `~/.claude` broadly.** The plugin cache
  (`~/.claude/plugins/cache/ios-build-verify/<version>/`) holds several versions at once
  and `find`'s directory order is unspecified, so the broad glob picked an arbitrary
  release to build App Store screenshots with — on this machine, 2026-07-26, it matched
  three paths (cache 0.3.1, cache 0.2.1, and the marketplace clone). The marketplace clone
  has no version segment and yields exactly one match. (Ported from Conjuguer `c51e223`.)
- macOS Accessibility permission granted to `osascript`. System Settings → Privacy & Security → Accessibility → add `/usr/bin/osascript`. The driver depends on this to click **I/O ▸ Keyboard ▸ Connect Hardware Keyboard** for the `quiz_mid` keyboard (workaround #25; it was a Cmd+K keystroke through version_2, workaround #6). **Granted and verified on this machine, 2026-07-18.** Note that a *missing* permission is not the only way the AXRaise step fails: a freshly-activated Simulator briefly reports no windows, and the resulting `-1719 "Invalid index"` looks just like a permission problem. The driver now waits 0.5 s after `activate` (was 0.2 s) for that reason.
- **You can use the Mac during a sweep — with one caveat.** Taps, swipes, captures,
  launches and the pasteboard copy all go through `simctl`/`axe`, which talk to the
  **device**, so they do not care what is frontmost on the host. The exception is the
  keyboard step: Simulator's **menu bar** is the only way to attach/detach the hardware
  keyboard, and AppleScript can only click the menu of the frontmost app. That is a few
  seconds inside `quiz_mid` and `quiz_results` — 4 of the 36 cells, so roughly 8 short
  windows per full sweep. Steal focus during one and the driver logs
  `frontmost is 'X', not Simulator; not touching the menu` and that cell needs a re-shoot.
  It **refuses to act rather than clicking blind**, so the cost is a retry, never a stray
  click into your own app — the guard exists because a stray Cmd+K once launched Fitness on
  the host Mac. It also retries 3×, so a momentary steal usually recovers by itself.
  Observed for real in Conjugar's 2026-08-01 sweep (Safari, then VS Code).
- Two simulators named `iPhone 17 Pro Max` and `iPad Pro 13-inch (M5)` (see "Simulator Setup"). The driver resolves their UDIDs by name at run time — no hardcoding. **Confirm there is exactly one iOS-26 device matching each name before running** (`udid_for()` takes the first match by list order, so a stale-runtime duplicate silently wins); see *iPad reliability*. Verified clean on 2026-07-18.
- **All three kill switches off (then restored).** See the next section — this is the
  single easiest step to forget and it silently ruins screenshots.
- **Clean the iPad status bar (App Store polish).** The driver does *not* manage the status bar, so iPad shots ship with whatever the simulator's clock and **system language** produce — and the iPad status bar shows a *date* (e.g. a German `Freitag 26. Juni` if the sim's system language is German), which looks unprofessional on an EN/ES listing. iPhone shots are unaffected (the notch shows only the time). Set a clean status bar before the iPad sweep — see **"Clean Status Bar"** below. (Not needed for iPhone.)

## Disable tips, onboarding, and the tutor row first (then restore)

Conjugar has **three** compile-time master switches, all in
[`Conjugar/Utils/KillSwitches.swift`](../Conjugar/Utils/KillSwitches.swift). All are
ordinarily `true`. **Set all three to `false` before running the driver and restore all
three to `true` afterward.** The driver builds once at start, so the flags must be flipped
*before* you launch it — flipping them mid-sweep does nothing.

| Switch | Effect when `false` | What you get if you forget |
|---|---|---|
| `TipDisplay.tipsEnabled` | `ConjugarApp` skips `Tips.configure()`. TipKit shows nothing until configured, so every `TipView` and `.popoverTip(_:)` stays hidden — no per-call-site changes. | A tip card ("Try the Quiz", "Explore Models", the difficulty nudge, the Game Center nudge) lands in the VerbBrowseView / ModelBrowseView / QuizView / SettingsView shots. |
| `OnboardingDisplay.onboardingEnabled` | `MainTabView`'s launch `.task` never trips `router.showOnboarding`, so the first-launch welcome tour never auto-presents. | The onboarding `.fullScreenCover` opaques whatever screen was being captured — usually the very first cell of the sweep. |
| `TutorDisplay.tutorUnavailableRowEnabled` | `InfoBrowseView`'s tutor section drops its **unavailability reason row**. Only that row: when the model *is* available the section still renders its `NavigationLink`, so the switch can never hide a working feature. | All four **screen 6** (`info_browse`) shots carry a row reading "Apple Intelligence is still preparing. Try again later." — honest on a device, but it reads as a defect in an App Store listing. |

```bash
# before the sweep
sed -i '' 's/static let tipsEnabled = true/static let tipsEnabled = false/; \
           s/static let onboardingEnabled = true/static let onboardingEnabled = false/; \
           s/static let tutorUnavailableRowEnabled = true/static let tutorUnavailableRowEnabled = false/' \
  Conjugar/Utils/KillSwitches.swift

# after the sweep — restore
sed -i '' 's/static let tipsEnabled = false/static let tipsEnabled = true/; \
           s/static let onboardingEnabled = false/static let onboardingEnabled = true/; \
           s/static let tutorUnavailableRowEnabled = false/static let tutorUnavailableRowEnabled = true/' \
  Conjugar/Utils/KillSwitches.swift

git diff --stat Conjugar/Utils/KillSwitches.swift   # must be empty when you are done
```

> **Why the tutor switch exists at all.** Apple Intelligence is *never* available in a
> simulator, so the tutor entry point can only ever render as a reason row there — see
> *Known Gotchas*. Suppressing it is a presentation choice for the store listing, not a
> workaround for a bug, which is why it is a permanent, documented switch rather than a
> temporary local edit. Added July 2026 at Josh's request after the row showed up in the
> first full sweep.

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
rm -rf docs/screenshots/latest && mkdir -p docs/screenshots/latest && \
for view in verb_browse verb_view model_browse model_view quiz_mid \
            info_browse info_view quiz_results settings; do
  for device in "iPhone-17-Pro-Max" "iPad-Pro-13-inch-(M5)"; do
    for lang in en es; do
      latest=$(ls -t docs/screenshots/*"${device}-${lang}-${view}.png" 2>/dev/null | head -1)
      [[ -n "$latest" ]] && cp "$latest" "docs/screenshots/latest/$(basename "$latest")"
    done
  done
done
```

`ls -t` orders by modification time; the timestamp embedded in the filename matches mtime to the second, so the two ordering schemes agree.

**The `rm -rf` is load-bearing.** Without it a re-shoot leaves the previous release's files sitting alongside the new ones — every name is unique because it carries a timestamp, so nothing is overwritten and nothing looks wrong. The numbered-bundle snippet below then matches two candidates per slot and resolves the tie by glob order, which is how a stale cell reaches App Store Connect looking perfectly plausible. (Ported from Conjuguer `c51e223`.)

### Per-Release Upload Bundles

App Store Connect's upload dialog takes one (device × locale) at a time and orders screenshots alphabetically by filename. The descriptive `latest/` names — useful as an archive — get in the way at upload time. For each release, project `latest/` into a numbered bundle:

```
docs/screenshots/version_<N>/
├── iPhone_English/{1..9}.png
├── iPhone_Spanish/{1..9}.png
├── iPad_English/{1..9}.png
└── iPad_Spanish/{1..9}.png
```

`<N>` increments per release (`version_4`, `version_5`, …; `version_3` was claimed by the
2026-08-01 sweep — see *Status*). The row number is the `#` column in the "Per-View Navigation Recipes" table below (1 = VerbBrowseView … 9 = SettingsView). To regenerate after a re-shoot:

```bash
cd docs/screenshots && \
mkdir -p version_<N>/iPhone_English version_<N>/iPhone_Spanish \
         version_<N>/iPad_English  version_<N>/iPad_Spanish && \
for src in latest/*.png; do
  rest="${src##*/}"; base="${rest#????????-??????-}"; base="${base%.png}"
  [[ "$base" =~ ^(iPhone-17-Pro-Max|iPad-Pro-13-inch-\(M5\))-(en|es)-(.+)$ ]] || continue
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

xcrun simctl create "iPad Pro 13-inch (M5)" \
  com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB \
  "$RUNTIME"
```

Note the device-type id carries a RAM suffix — `…iPad-Pro-13-inch-M5-12GB`, not
`…iPad-Pro-13-inch-M5`. Xcode 26 splits each iPad Pro into two memory variants (M5: 12 GB and
16 GB; M4: 8 GB and 16 GB) and the bare id no longer resolves. Only the 12 GB / 8 GB variant
gets the plain `iPad Pro 13-inch (M5)` / `(M4)` name the driver matches; the 16 GB one is
named `… (16GB)` and would not match.

> **The iPad target moved M4 → M5 on 2026-08-01**, when the `version_3` sweep re-shot
> everything after the Browse→Verbs tab rename, following
> [`docs/screenshot-plan.md`](screenshot-plan.md), which names the M5. The two devices are
> interchangeable for this purpose — same 13-inch geometry, same **2064×2752** capture, same
> iOS 26.3 runtime — so nothing in the driver changed but the name in `DEVICES`,
> `tab_coords_for`, `wait_budget_for`, `keyboard_is_visible`, `set_keyboard_state`, and
> `dismiss_review_prompt`. The M4 sim still exists on this machine; it is simply no longer
> the target. If you ever point the driver back at it, change all six sites — a `case` arm
> that misses just falls through to its `*)` default and fails somewhere far away
> (`wait_budget_for` would return empty, `keyboard_is_visible` would return 1 forever).

**No sim renaming needed.** Konjugieren's driver hardcoded UDIDs and renamed the iPad to dodge `_resolve_udid.sh`'s regex-special-char bug (parens in `TARGET_SIM`). Conjugar's driver (like Conjuguer's) bypasses `_resolve_udid.sh` entirely and matches the device name as a Python string literal, so `iPad Pro 13-inch (M5)` works unchanged.

> **Note on `iPhone 17 Pro Max` vs. Conjugar's usual sim.** `.claude/ios-build-verify.config.sh` targets a plain **iPhone 17** and carries hand-set 5-tab coordinates for it (`63,822 …`). Those are **not** the Pro Max values — the screenshot driver has its own `tab_coords_for()` table. Don't cross-copy them.

## Clean Status Bar

The driver itself never touches the status bar, so by default every shot carries the
simulator's live clock, battery, and signal state — and on **iPad** the status bar also
shows a **date**, rendered in the simulator's **system language** (independent of the
app's `-AppleLanguages` override). A sim whose system language is German thus stamps
`Freitag 26. Juni` onto otherwise-English/Spanish iPad screenshots.

> **This is no longer iPad-only (revised 2026-07-26).** Earlier revisions said the
> language/reboot dance was needed only on iPad, reasoning that the iPhone notch shows no
> date. That reasoning is incomplete: **the pinned clock itself renders per-locale.** With
> the identical `--time "9:41"` override, an `en_US` device shows `9:41` (12-hour) and an
> `es_ES` device shows `09:41` (24-hour). So if you set the system language on only one
> device, or on neither, the iPhone and iPad clocks disagree *within the same language*.
> The 2026-07-26 sweep therefore ran the language dance on **both** devices, and the
> resulting set is internally consistent: English shots read `9:41` everywhere, Spanish
> shots read `09:41` everywhere. Do the same. The *date* handling below is still iPad-only.

**Ordering matters and it fails silently.** `status_bar override` is cleared by every
shutdown/reboot but survives `uninstall`/`install`/relaunch. Since changing the system
language *requires* a reboot, an override set before the language change is wiped by it.
The sequence is always:

```
set system language → reboot → RE-APPLY the override → shoot all 9 views of that language
```

Get it backwards and that language's shots carry a live wall-clock — which is exactly the
version_1 defect being re-shot, and nothing in a visual review flags it unless you compare
the clock across languages.

**Use [`scripts/prep_screenshot_sim.sh`](../scripts/prep_screenshot_sim.sh)**, which does the
four steps in that order and then prints the resulting override state *and* `AppleLanguages`
so you can see both landed rather than assume it:

```bash
scripts/prep_screenshot_sim.sh "iPhone 17 Pro Max"     en   # then shoot --lang en
scripts/prep_screenshot_sim.sh "iPad Pro 13-inch (M5)" es   # then shoot --lang es
```

It resolves the UDID by exact device name the same way the driver does, so the iPad's
paren-bearing default name needs no escaping. Added 2026-07-26 after the ordering trap was
hit-adjacent twice in one day.

Because each language needs its own boot, **the driver's default one-boot-per-device flow
no longer applies** — it shoots both languages in a single boot. Invoke it one `--lang` per
boot instead (`--device "iPhone 17 Pro Max" --lang en`, then the Spanish pass after the
next reboot).

Fixing this is two independent pieces:

1. **`simctl status_bar override`** — pins the time/battery/signal to clean values. This is
   per-device and **cleared on every shutdown/reboot**, but it **persists across
   `uninstall`/`install` and app relaunches**, so set it once and leave the device booted
   for the whole sweep. (`take_screenshots.sh` only boots when the device is *not* already
   booted and never reboots, so the override survives a full run.)

   ```bash
   UDID=$(xcrun simctl list devices available | \
     awk -F '[()]' '/iPad Pro 13-inch \(M5\) \(/{print $4; exit}')   # the iOS-26 one
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

> **Override the iPhone's clock too — this is now required, not optional.** Older revisions
> called it a nicety on the grounds that the iPhone notch shows only a time. Two things make
> it mandatory in practice. First, an un-overridden iPhone carries the sim's **live clock**,
> so a sweep spanning an hour boundary ships disagreeing times (version_1: seventeen shots at
> `14:31`, one re-shot cell at `15:31`). Second, per the note above, the *pinned* clock is
> itself locale-formatted, so the iPhone needs the same system-language treatment as the iPad
> for `9:41` / `09:41` to match across devices within a language.

> **Why not bake this into the driver?** The override is trivial to script, but the
> per-language *reboot* doesn't fit the driver's one-boot-per-device loop (it shoots both
> languages in a single boot). Keeping the status-bar setup as an operator step above avoids
> restructuring the driver around reboots — at the cost of remembering to drive it one
> `--lang` per boot.

## iPad reliability — duplicate sims, render budget, per-cell fallback

Three iPad-specific failure modes surfaced in practice (none affect iPhone):

- **Wrong duplicate simulator / old iPadOS.** `udid_for()` returns the *first* name match
  in `simctl list` order, which is grouped by runtime ascending — so if the machine has
  `iPad Pro 13-inch (M5)` instances on iOS 18.x *and* 26.x, it picks an **18.x** one and
  the install dies with *"Requires a Newer Version of iPadOS … Have 18.0; need 26.0"*. Fix by
  removing the stale-OS duplicates from the name's match set — **rename** them out of the way
  if you may want them back (reversible), or **delete** them outright:
  ```bash
  xcrun simctl rename <UDID-of-iOS18-iPad> "iPad Pro 13-inch (M5) iOS18-PARKED"
  # …re-run sweep…  then restore:
  xcrun simctl rename <UDID> "iPad Pro 13-inch (M5)"
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
      if m and "iPad Pro 13-inch (M5)" in m.group(1):
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
  budget, so `wait_budget_for "iPad Pro 13-inch (M5)"` is **45 s**. A *single*
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
      scripts/take_screenshots.sh --device "iPad Pro 13-inch (M5)" --lang en --view "$view" && break
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

6. **Soft keyboard suppression** (`take_screenshots.sh::set_keyboard_state`)
   *Symptom:* Simulator forwards host hardware-keyboard events; the soft keyboard is suppressed by default. *Fix (through version_2):* send Cmd+K via `osascript` (Simulator's "Toggle Software Keyboard"). **Superseded on 2026-08-01 — Cmd+K no longer does anything on this toolchain; the driver now attaches/detaches the hardware keyboard instead. See workaround #25**, which is where the current mechanism is documented.

7. **StoreKit review-prompt suppression** (`take_screenshots.sh::seed_defaults`)
   *Symptom:* the StoreKit review modal (`ReviewPrompterReal`, used even in the simulator World config) opaques the AXTree mid-loop. It fires when `promptActionCount % promptModulo == 0` **and** ≥`promptInterval` since `lastReviewPromptDate`. *Fix:* pre-seed `lastReviewPromptDate` to now via `simctl spawn defaults write`, so the cooldown blocks every prompt this run. (Fallback: workaround #12.)

8. **Deep Info-list rows** (`take_screenshots.sh::scroll_until_top, nav_info_browse, nav_info_view`)
   *Symptom:* a lazy list doesn't report off-screen rows' frames, and a fixed-distance swipe is fragile across devices. *Fix:* `scroll_until_top` swipes in fixed increments until the target row's frame top reaches a target y, then stops (robust to device + dynamic-type differences). Conjugar needs this in **both directions of concern**: screen 6 scrolls the Tutor section off the top so the **About** header pins at top, and screen 7 scrolls deep into the Tenses section to reach *Presente de Indicativo*.

9. **`axe --id` typeMismatch on iPad** (`take_screenshots.sh::tap_id`)
   *Symptom:* `axe tap --id` / `--label` throw a Swift `typeMismatch` decoding error in some iPad screen states (e.g., QuizView pre-Start). *Fix:* route all `tap_id` calls through `tap_id_first` (describe-ui + coord-tap) — same path as workaround #3.

10. **Multi-sim window focus** (`take_screenshots.sh::set_keyboard_state`)
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

    **Frontmost guard (added 2026-07-26).** The AXRaise above is not sufficient on its own,
    and the failure it misses is worse than a wrong *window*: when the raise silently fails
    to take focus at all, `keystroke` still **succeeds** — it lands in whichever application
    is frontmost on the host Mac. Observed the same day, when a stray Cmd+K launched
    **Fitness** on Josh's Mac while the sweep reported nothing wrong. `osascript` returns 0
    either way, and `keyboard_is_visible` can only report that the keyboard is *missing*,
    never that the keystroke went somewhere else — so a *bare* retry does not help, because
    the retry misfires identically. `set_keyboard_state` therefore asks System Events for
    the frontmost process name and **never sends the keystroke unless Simulator owns focus**,
    logging `attempt N: frontmost is 'X', not Simulator; not sending the keystroke`.

    **The whole raise → check → keystroke sequence is a 3× retry loop** (adopted from
    Konjugieren, 2026-07-26; all three apps now share this shape, differing only in how each
    derives `window_match` — Conjugar and Konjugieren use a device-family substring, Conjuguer
    the whole `$DEVICE` string). Putting the frontmost check *inside* the loop is what makes
    it more than a safety valve: a **transient** steal — Simulator still coming forward,
    another app briefly frontmost — recovers on attempt 2 rather than costing the cell, which
    is what the earlier single-attempt version did. A **persistent** steal burns all three
    attempts, sends **zero** keystrokes, and ends in `AppleScript Cmd+K failed 3x
    (accessibility permission …, or Simulator never came frontmost)`. **That message names
    two causes and there is a third, which is the one that actually bit on 2026-07-26: the
    device has no Simulator window at all** — see workaround #24 before chasing permissions.
    The loop also absorbs
    the -1719 race noted above, which is a race rather than a steady state and so usually
    clears by the next attempt. Control flow verified in Conjugar and Conjuguer against a
    stubbed harness across all three cases (clean / transient / persistent).

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
    and treat a ≤2-character label ("g") as keys-present. The caller — `set_keyboard_state`
    since the 2026-08-01 rewrite — re-checks after the toggle and warns if it did not land. Probe points are per-device in
    `keyboard_is_visible`; deliberately **not** the space bar, whose blank label is
    indistinguishable from "nothing found". Found by verification in July 2026.

17. **Model rows keyed by exemplar, not class number** (`take_screenshots.sh::nav_model_browse, nav_model_view`)
    *Symptom:* `ModelInfo.id` is the `classNumber`, and class numbers contain hyphens (`29-2`, `30-1`). The `ID_MATCH` predicate treats `-` as its prefix boundary, so `model_row_29` would spuriously match `model_row_29-2`. *Fix:* identify model rows by **exemplar** (`model_row_decir`, `model_row_haber`) — hyphen-free and what the spec names anyway.

18. **iPad tab centers are language-dependent — measure, don't hardcode** (`take_screenshots.sh::measured_tab_centers, tab_coords_for, tap_tab`)
    *Symptom:* the iPad/es `quiz_mid` and `quiz_results` cells fail with
    `tap_id_first: no element with id 'quiz_start_button'`. *Cause:* the iPad's top
    segmented bar sizes each tab to its **label**, so every center moves with the UI
    language. English centers are `358.2 / 447.7 / 526 / 590.8 / 670.3`; Spanish
    (Explorar/Modelos/Test/Información/Configuración) are `300.25 / 398.25 / 480.5 /
    575.75 / 709.25`. The English "quiz" x (526) lands inside **Información**, so
    `tap_tab quiz` silently opened the Info tab and the Quiz anchor was legitimately
    absent. Worse, English "models" (447.7) sat **0.05 pt** inside the Modelos tab — the
    es model cells passed on pure luck. *Fix:* `tap_tab` calls `measured_tab_centers`,
    which reads the five `AXRadioButton` frames from the live AXTree and returns their
    centers; `tab_coords_for`'s table is now an English-only fallback for when
    measurement returns nothing (always on iPhone, whose pill exposes no children and
    divides evenly regardless of label width). Found July 2026 on the first full sweep.

19. **`nav_settings` had no settle — iPad captured a mid-crossfade frame** (`take_screenshots.sh::nav_settings`)
    *Symptom:* both iPad `settings` cells showed the **Browse grid ghosted through** the
    Settings cards at partial opacity (`ser`/`be`, `poder`/`can` legible behind the
    Region section). *Cause:* `nav_settings` was the only recipe that did `tap_tab` and
    nothing else; the other tab-switching recipes get a delay for free from their
    `verify_screen_loaded` poll. iPad's crossfade outlasts `tap_tab`'s 0.7 s sleep.
    *Fix:* `verify_screen_loaded app_icon_bull` plus an explicit `sleep 1.5` — the anchor
    proves the screen is mounted, the sleep covers the animation, which an anchor's mere
    presence does not.

20. **A tap can land mid-render and be silently swallowed** (retry, not a code fix)
    *Symptom:* one-off — iPad/en `verb_view` captured the Browse grid in light mode
    instead of the `ser` detail; the same cell in Spanish was fine, and a plain re-run
    fixed it. *Cause:* `tap_id_first verb_row_ser` fires right after `wait_for_render`
    returns on the count banner, but the iPad is still laying out 4,811 grid cells, so
    the frame it measured had moved by the time the tap dispatched. *Fix:* none in code —
    this is exactly what the per-cell retry loop in *iPad reliability* is for. **The
    lesson is that a swallowed tap produces a plausible-looking wrong screenshot rather
    than an error**, so the visual review of every PNG is not optional.

21. **`frame_of` takes the largest-area match, not the first** (`take_screenshots.sh::frame_of`)
    *Symptom (in Konjugieren, not yet seen here):* four Info cells captured the Info list
    instead of the article, with no error. *Cause:* an iPad Info row exposed its heading as
    a non-interactive `AXStaticText` *above* the tappable `AXButton` in the tree, and the
    depth-first `[0]` picked the static text — tapping which does nothing at all.
    *Fix:* choose the match with the largest `AXFrame` area. Preferring `AXButton` is the
    obvious alternative and is **wrong**: on iPad a verb row exposes its *translation* as a
    button while the infinitive is static text, so that rule taps the translation. Area is
    what actually distinguishes a row from a label inside it. **This is a safety net in
    Conjugar, not a fix** — as of the 2026-07-18 sweep every tap site on both devices in
    both languages had exactly one match, so old and new behavior agree everywhere in this
    app today. Ported from Konjugieren `4fd2d93` / Conjuguer `c51e223`.

22. **Every capture waits for the image to stop moving** (`take_screenshots.sh::wait_for_stable_screen`)
    *Symptom:* the generalized form of #19 — any capture can land mid-transition.
    *Cause:* no accessibility wait can prevent it. AX state answers "has the hierarchy
    changed", a screenshot is graded on "has the image stopped moving", and the two
    diverge: the outgoing screen's anchor leaves the AX tree within ~0.3 s of a tap while
    an iPad cross-fade is still plainly visible. *Fix:* `take_screenshot` now samples the
    screen up to 8× at 0.35 s and captures once two consecutive frames differ by less than
    `STABLE_PIXEL_TOLERANCE` (ImageMagick `-metric AE`). It never blocks the capture — a
    screen that won't settle logs a warning and is shot anyway. **The tolerance is
    currently Conjuguer's number, not Conjugar's** — see *Measure `STABLE_PIXEL_TOLERANCE`*
    below and do that before the next sweep. Ported from Konjugieren `4fd2d93` /
    Conjuguer `c51e223`.

23. **Captures are flattened to remove the alpha channel** (`take_screenshots.sh::take_screenshot`)
    *Symptom:* App Store Connect rejects the upload — "Images can't include alpha channels
    or transparencies." *Cause:* `axe screenshot` writes RGBA. This is a **format** check
    on Apple's side, not a content check, so a fully opaque RGBA capture is rejected too —
    which means nothing in a visual review can ever reveal it. *Fix:* `magick … -alpha
    remove -alpha off` at the point of capture, plus `scripts/verify_store_media.sh` as the
    backstop before upload. **`docs/screenshots/version_1` predates this and fails 36/36.**
    Ported from Konjugieren `bbfee8d`.

24. **A booted simulator can have no Simulator *window*, which silently kills Cmd+K**
    (`prep_screenshot_sim.sh::ensure_simulator_window`,
    `take_screenshots.sh::set_keyboard_state`)
    *Symptom:* iPad/es `quiz_mid` came out **keyboard-less**, with the driver logging
    `AppleScript Cmd+K attempt 1/2/3 failed` and then
    `AppleScript Cmd+K failed 3x (accessibility permission …, or Simulator never came
    frontmost)`. Both named causes were false: the permission was granted and Simulator did
    come frontmost. *Cause:* the language reboot left the iPad **booted but windowless** —
    `xcrun simctl boot` does not always make Simulator.app attach a window when Simulator is
    already running. Everything else keeps working, because `simctl` and `axe` talk to the
    device rather than to the UI; only the AppleScript path needs a window, and
    `first window whose title contains "iPad"` then fails with `-1719 "Invalid index"` —
    indistinguishable from the missing-permission failure the message blames. *Fix, in two
    places:* `prep_screenshot_sim.sh` checks for a window titled with the device name after
    the reboot and, if there is none, quits and relaunches Simulator.app (on launch it
    attaches a window to every already-booted device), re-booting the device first if the quit
    took it down. It runs **before** the status-bar override, since a re-boot would clear it.
    And `set_keyboard_state` checks for the window **inside** its existing 3× loop, before
    each AXRaise — placed there, beside the frontmost guard, for the same reason that one is
    inside the loop: the window list is *also* briefly unenumerable right after Simulator
    activates, and that transient recovers on the next attempt, while a genuinely windowless
    device burns all three attempts, sends zero keystrokes, and logs the true cause each time.
    The driver deliberately does **not** attempt recovery — restoring a window means quitting
    and relaunching Simulator.app, which is fine at reboot time in prep and far too blunt
    mid-sweep — so this converts a mystery into one reviewable screenshot plus an accurate
    log line. The 3× warning now names all three causes rather than two.
    *Verification:* the detection path and the manual relaunch recovery were both confirmed on
    2026-07-26; the windowless state itself is **intermittent** and did not reproduce on
    demand afterward, so the recovery branch has not been exercised end to end by the script.
    The driver-side check was verified with a stubbed-`osascript` harness across all three
    cases (window present → 1 raise, 1 keystroke; persistently missing → 3 attempts, **0**
    keystrokes, then the warning; missing-then-present → recovers on attempt 2), and by a live
    `--view quiz_mid` cell that captured the keyboard with no false alarm. The same check is
    now in Conjuguer (#19) and Konjugieren (#16); the executable body of
    `set_keyboard_state` (then `ensure_soft_keyboard`) remains byte-identical across Conjugar
    and Konjugieren, with Conjuguer differing only in the one intentional `window_match` line
    — still true after the 2026-08-01 rewrite, which was ported to both siblings the same day.
    Two things that do **not** work once Simulator is already running, both tried:
    `open -a Simulator --args -CurrentDeviceUDID <udid>` (the argument is ignored) and
    Simulator's own **File ▸ Open Simulator ▸ …** menu item (it clicks, and nothing appears).

25. **Cmd+K is dead; the keyboard is now a two-state machine**
    (`take_screenshots.sh::set_keyboard_state, keyboard_state_is, toggle_hardware_keyboard,
    paste_into_quiz_field`)
    *Symptom:* the first cell of the version_3 sweep logged
    `soft keyboard still not visible after Cmd+K` and `quiz_mid` came out keyboard-less —
    the same visible defect as workaround #24, but with none of its causes: the
    accessibility permission was granted, Simulator came frontmost, and the window was
    there. *Cause:* on this toolchain (Xcode 26.3, 2026-08-01) Cmd+K — Simulator's
    **Toggle Software Keyboard** — no longer surfaces the keyboard while a hardware
    keyboard is attached. Clicking that menu item directly via AppleScript is equally
    inert, so it is not a keystroke-delivery problem. What governs the keyboard is
    **I/O ▸ Keyboard ▸ Connect Hardware Keyboard**: iOS shows the software keyboard for a
    focused field exactly when no hardware keyboard is attached, and unchecking it raises
    the keyboard instantly.
    *The trap that makes this more than a one-line fix:* every quiz answer is pasted with
    Cmd+V (workaround #5 — `axe type` still has no keycode for `é`, re-verified), and axe
    injects that combo as **hardware** key events, which the device **ignores while the
    hardware keyboard is detached**. So the two requirements are mutually exclusive at any
    instant: pasting needs it attached, photographing the keyboard needs it detached.
    Detaching does not disturb the field's contents, so the driver orders them —
    `set_keyboard_state hidden` → paste → `set_keyboard_state visible` → capture — and
    `nav_quiz_results`, which submits 12 answers and never photographs a keyboard, holds
    `hidden` throughout. `set_keyboard_state` keeps #24's window / frontmost / 3× retry
    guards verbatim; it never reads the menu's checkmark (only readable while the menu is
    open) but clicks and then asks the screen, which is also what makes it idempotent
    across cells.
    *Second-order defect, fixed with it:* with the keyboard up, the driver's
    `tap_id input_quiz_conjugation` was tapping a field that **already had focus** (QuizView
    auto-focuses after Start), which raises iOS's **"Paste | AutoFill" edit callout** — it
    swallowed the Cmd+V *and* sat in the middle of the screenshot. The tap is gone from both
    quiz recipes, and `paste_into_quiz_field` now confirms the field actually holds the
    answer before moving on, falling back to tap / Cmd+A-replace only when it does not. In
    `nav_quiz_results` that check earns its keep differently: a silently missed paste there
    desynchronizes every later answer from its question.
    *Note on the empty-field read:* the field's `AXValue` reports the **placeholder**
    (`conjugation`) when empty, not `""` — so the check compares against the expected answer
    rather than testing for emptiness.
    *Verification:* iPhone/en `quiz_mid` re-shot clean (answer `soy` in the field, keyboard
    up, no callout, no warnings) and `quiz_results` re-shot all-green from the detached
    state, so both directions of the state machine ran end to end.

26. **A booted simulator can render pure black while every other signal says it is fine**
    (`take_screenshots.sh::ensure_simulator_app, assert_framebuffer_live`)
    *Symptom:* `xcrun simctl bootstatus -b` reports success, `axe describe-ui` returns a
    complete home-screen accessibility tree with icons — and every capture is a mean-0 black
    PNG, from both `axe screenshot` and `simctl io screenshot`. In the run where this was
    found, `simctl launch` also hung for 21 minutes against the same device.
    *Why it is dangerous:* `wait_for_render` polls the **accessibility tree**, which stays
    perfectly healthy throughout. Nothing in the driver's wait path can see this, so the sweep
    runs to completion, reports success, and writes a full set of black screenshots. A live AX
    tree proves the device is *running*, not that it is *rendering* — those are different
    claims, and only the pixels can settle the second one.
    *Fix:* `assert_framebuffer_live` captures a probe frame and requires `magick`'s `%[mean]`
    above 1 (a threshold, not `!= 0` — a nearly-black frame is just as dead, while a live
    dark-mode screen clears it easily on status-bar text alone). It retries 10× at 3 s, because
    a just-booted device legitimately renders black while SpringBoard comes up, then exits 2
    with a diagnostic. `ensure_simulator_app` launches Simulator.app when it is not running.
    Both are called from `ensure_booted`, and `main` runs a **preflight pass over every target
    device before the build**, so this fails in seconds rather than after a ~10-minute
    `build_app.sh`.
    *Cause never established — read this before chasing it.* Simulator.app being absent was the
    most visible anomaly, but **launching it did not clear the condition**, so the tempting
    "headless boot breaks rendering" story is a correlation that was never earned. Quitting and
    relaunching Simulator.app, `simctl shutdown all`, and `launchctl remove
    com.apple.CoreSimulator.CoreSimulatorService` all failed too. **Only a host reboot worked.**
    If you hit this, reboot rather than working down that list. A stray `screencapture`
    permission dialog was also sitting on the host and is worth dismissing first, since a modal
    there can stall host-side capture indefinitely.
    *Observed in Conjuguer on 2026-08-04; the guard is ported to all three apps. The failing
    state is not reproducible on demand, so the abort path was verified by pointing
    `assert_framebuffer_live` at a shut-down device (exits 2 with the diagnostic) and the pass
    path against a live one (returns in ~1 s).*

## Measure `STABLE_PIXEL_TOLERANCE`

`STABLE_PIXEL_TOLERANCE` (in `take_screenshots.sh`, next to `wait_for_stable_screen`) is
the largest frame-to-frame `-metric AE` difference still treated as "settled".

**Measured on Conjugar 2026-07-26 (iOS 26.3, both sim targets): `75000000`.** Re-measure
only if the animations change, or if the "still changing after 8 samples" warning starts
appearing. Do not port this number to Conjuguer or Konjugieren — and note that theirs were
both tried against Conjugar's data and both are too tight for this app (Conjuguer's 5e7
sits 1.08× above our worst benign frame; Konjugieren's 1e8 sits 1.16× below our smallest
observed transition).

| | measured |
|---|---|
| Static screen (Settings, Browse) | exactly `0` |
| Quiz screen, 112 samples, both devices | median 9.8e6 · p95 1.9e7 · **max 4.6e7** |
| iPad tab transition, first delta, 21 samples | **min 1.2e8** · typical 8.3e9–2.5e10 |
| **Chosen** — geometric middle | **7.5e7** (1.6× above floor, 1.5× below ceiling) |

Why it can't just be zero: `QuizView`'s elapsed-time counter ticks and the answer field's
cursor blinks, so the quiz screen never fully settles. `-metric AE` reports summed channel
error in quantum units, not a count of differing pixels — only the ratios are meaningful.

**Verified end to end**, three rounds each on the iPad: a gated capture taken immediately
after a tab tap is **byte-identical** (delta `0`) to a reference of the same screen taken
three seconds later, while the same capture *without* the gate lands 8.0e9–1.2e10 away —
visibly the workaround #19 artifact, with the Browse verb list ghosted through the Settings
cards. On the quiz screen the gate settles in ~1.9–2.1 s and does not warn.

**Known limit, recorded honestly.** An iPad cross-fade's *tail* scores 7.7e6–1.1e7, which
is below the quiz screen's own noise, so no single threshold can separate a late-fade frame
from benign motion. It does not matter in practice: in every observed case the frame after
such a delta was byte-identical to the settled screen, so the gate still yields a correct
capture. If a ghosted screenshot ever reappears, this is the assumption that broke.

### Re-measuring

```bash
UDID=$(xcrun simctl list devices booted -j | python3 -c "import sys,json;print(json.load(sys.stdin)['devices'].popitem()[1][0]['udid'])")
# Sample a screen repeatedly and print consecutive-frame deltas.
sample() {  # usage: sample <label> <count>
  local prev cur; prev=$(mktemp).png; cur=$(mktemp).png
  axe screenshot --udid "$UDID" --output "$prev" >/dev/null
  for _ in $(seq "$2"); do
    sleep 0.35
    axe screenshot --udid "$UDID" --output "$cur" >/dev/null
    echo "$1 $(magick compare -metric AE "$prev" "$cur" null: 2>&1 | awk '{print $1}')"
    mv "$cur" "$prev"
  done
}
```

1. **Noise floor.** Park on Settings (nothing animates) — expect exactly `0`. Then park on
   the quiz mid-answer and run `sample quiz 18`. Take the **maximum**; that is the floor.
2. **Ceiling.** Tap an iPad tab and sample immediately across the cross-fade. Take the
   **minimum** value observed while the fade is still visible.
3. **Pick the geometric middle** of floor↔ceiling and record both measured numbers in the
   comment above the constant, with the date and device — the next reader needs to know
   how much headroom there is.

Err **low**. Too low degrades to "sample 8 times (~2.8 s), warn, capture anyway", which is
still more settling than the driver did before this existed. Too high captures a
mid-cross-fade frame silently, which is the failure this whole mechanism exists to prevent.
Conjugar's floor↔ceiling gap is only ~2.5×, so if the "still changing after 8 samples"
warning starts appearing, **re-measure rather than nudging the number upward.**

Then re-run the end-to-end check: tap a tab, run `wait_for_stable_screen`, capture, and
compare against a reference of the same screen taken three seconds later. It should be `0`.

## Per-View Navigation Recipes

| # | View | Mode | Driver function | Notes |
|---|---|---|---|---|
| 1 | VerbBrowseView | dark | `nav_verb_browse` | Default landing; `wait_for_render browse_verb_count`. Frequency sort is the default (`Settings.verbSortDefault == .frequency`) → **ser** on top. |
| 2 | VerbView | light | `nav_verb_view` | `tap_id_first verb_row_ser`. |
| 3 | ModelBrowseView | dark | `nav_model_browse` | `tap_tab models` → settle on `model_row_decir`. Irregularity sort is the default (`Settings.modelSortDefault == .irregularity`) → the **decir** model at top. |
| 4 | ModelView | light | `nav_model_view` | `tap_tab models` → settle on `model_row_haber` → `tap_id_first model_row_haber`. Spec: don't scroll horizontally — the driver never does. |
| 5 | QuizView (mid) | dark | `nav_quiz_mid` | `tap_tab quiz` → `quiz_start_button` → `set_keyboard_state hidden` → paste fixture answer 0 → `set_keyboard_state visible`. Captured before submit (keyboard visible per spec). The field is not tapped — it is already focused, and tapping it raises an edit callout (workaround #25). |
| 6 | InfoBrowseView | light | `nav_info_browse` | `tap_tab info` → settle on `info_row_purpose_and_use` → `scroll_until_top info_row_purpose_and_use` (scrolls the Tutor section off, pinning the **About** header at top). |
| 7 | InfoView | dark | `nav_info_view` | `tap_tab info` → `scroll_until_top info_row_presente_de_indicativo 400` → tap it. |
| 8 | ResultsView | light | `nav_quiz_results` | `tap_tab quiz` → `quiz_start_button` → N× (paste + Return + sleep 0.3) → `dismiss_review_prompt` if needed → `verify_screen_loaded results_score`. |
| 9 | SettingsView | dark | `nav_settings` | `tap_tab settings` → settle on `app_icon_bull` → `sleep 1.5` (workaround #19); the **Region** picker is the first section, so no scroll. |

Tab-bar coordinates are **measured live** by `measured_tab_centers()` wherever the tabs expose themselves (iPad); `tab_coords_for()` is the fallback table (always used on iPhone). iPhone uses the bottom pill tab bar (y=899.3); iPad uses a top segmented tab bar (y=54), whose centers **shift with the UI language** — see workaround #18. Tab order is `verbs models quiz info settings`, matching `MainTabView`.

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
| `TipDisplay.tipsEnabled` / `OnboardingDisplay.onboardingEnabled` / `TutorDisplay.tutorUnavailableRowEnabled` | operator flips all three to `false` before the sweep | `Conjugar/Utils/KillSwitches.swift` |
| `app_icon_bull` identifier | `nav_settings` settles on it before capturing (workaround #19) | `Conjugar/Views/SettingsView.swift` |
| `AXRadioButton` tab frames (iPad) | `measured_tab_centers` reads all five live, per language (workaround #18) | `Conjugar/Views/MainTabView.swift` |

The `info_row_<stableKey>` keys are locale-independent ASCII (e.g. `presente_de_indicativo`, `purpose_and_use`); `verb_row_<infinitive>` and `model_row_<exemplar>` carry Spanish text (e.g. `verb_row_ser`, `model_row_haber`) — the driver passes them as UTF-8 and matches via `describe-ui` + `jq`, which handles non-ASCII fine.

> **Watch the accented exemplars.** Some Spanish infinitives carry accents (`oír`, `reír`,
> `añadir`). An identifier built from one is valid UTF-8 and matches fine, but don't retype
> it by hand in the driver — copy it, or the ASCII lookalike silently matches nothing.

### Sim Runtime Drift

If the iOS 26.3 simulator runtime is replaced by 26.4+, the AXTree shape may shift slightly — especially for system-controlled surfaces like the StoreKit review prompt. Recreate the sims on the new runtime, re-verify workarounds #7 and #12 still match, and re-run a single test cell:

```bash
scripts/take_screenshots.sh --device "iPad Pro 13-inch (M5)" --lang en --view quiz_results
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

- **Flip *all three* switches off before the run.** `TipDisplay.tipsEnabled`,
  `OnboardingDisplay.onboardingEnabled`, and `TutorDisplay.tutorUnavailableRowEnabled`, all
  in `Conjugar/Utils/KillSwitches.swift`. See *Disable tips, onboarding, and the tutor row
  first*. The driver builds once at start, so they must be set first — and restored to
  `true` when the sweep is done.
- **A "successful" run can still contain wrong screenshots.** The driver only fails when an
  anchor is genuinely missing. A tap that lands mid-transition, or a capture taken during a
  crossfade, produces a well-formed PNG of the *wrong screen* and exits 0. The July 2026
  sweep shipped six such cells before visual review caught them. Read every PNG.
- **Default sorts drive screens 1 and 3.** Screen 1 relies on `Settings.verbSortDefault == .frequency` (ser on top); screen 3 on `Settings.modelSortDefault == .irregularity` (the decir model at top). The driver does not change sorts — segmented pickers render with empty AXTree children on iOS 26 and aren't individually addressable by id. A fresh install starts at the defaults, so this holds; if either default changes, re-spec those screens. Both defaults were verified in `Conjugar/Utils/Settings.swift` in July 2026.
- **The Info scrolls are calibration-sensitive.** Screen 6 wants the About section header at the top; screen 7 parks *Presente de Indicativo* in the safe middle band (`scroll_until_top … 400`) before tapping. Tune the target y values if a header is clipped or a row lands under the tab bar.
- **Apple Intelligence Tutor surfaces are availability-gated.** The Tutor section in InfoBrowseView (and the AI page in OnboardingView) render as a live `NavigationLink` only when `Current.languageModelService.isAvailable`. On a simulator — where the model is always unavailable — it would show a reason row instead, which is why `TutorDisplay.tutorUnavailableRowEnabled` exists: with it `false`, screen 6 shows the About header cleanly with no tutor section at all. Either way the App Store shots will never show the Tutor *entry point*. If you want it in the listing, that shot has to be taken by hand on a real Apple-Intelligence device.
- **The light-mode status bar was white-on-white until 2026-07-26 — FIXED, and it is why
  the clean sweep was thrown away.** In the four light slots (`verb_view`, `model_view`,
  `info_browse`, `quiz_results`) the clock and Wi-Fi glyph were drawn in white on a
  white/near-white background, ranging from faint to invisible; on `verb_view` the green
  battery appeared to float alone with no time beside it. Cause: **`Conjugar/Info.plist` set
  `UIStatusBarStyle = UIStatusBarStyleLightContent` with
  `UIViewControllerBasedStatusBarAppearance = false`** — a UIKit-era holdover from the 2017
  app that forced light status-bar content app-wide regardless of appearance. Correct in the
  five dark slots, wrong in the four light ones, and wrong for every light-mode *user*, not
  just for screenshots. **Both keys were removed** at Josh's direction; with neither present
  the system picks the style from the appearance, so the status bar is dark-on-light in light
  mode and light-on-dark in dark mode. The app builds clean and the built
  `Conjugar.app/Info.plist` carries neither key.

  Two consequences for whoever shoots next. **All 36 cells need re-shooting from the new
  build** — the fix changes the light cells and the sweep that preceded it was deleted, so
  there is nothing to patch into. And **do not re-add either key**: if a future change makes
  the status bar look wrong, the fix belongs in SwiftUI (a `.preferredColorScheme` or
  `.toolbarColorScheme` at the relevant view), not in a global plist override.
- **The soft keyboard is the *English* layout even in the Spanish shots.** The `es` cells of
  `quiz_mid` show a QWERTY keyboard with `EN` on the space bar and no `ñ` key, because the
  simulator's installed-keyboard list (`AppleKeyboards`) is a separate preference from
  `AppleLanguages` and the language dance does not touch it. The plan only requires that the
  keyboard be *visible*, so version_2 ships this way rather than churning two good cells. If
  a future sweep wants a Spanish keyboard for authenticity, set `AppleKeyboards` on the sim
  before the `es` pass and re-shoot `--view quiz_mid --lang es` on both devices.
- **Review-prompt cooldown is per-install.** `seed_defaults` pre-seeds `lastReviewPromptDate` for in-run prompts, but a manual screenshot capture of the StoreKit modal would still require uninstalling/reinstalling first.
- **iPad first-boot is ~70s on a fresh sim.** Data-migration plugins initialize on first boot; subsequent boots are ~22s. The `xcrun simctl bootstatus -b` step can block for ~70s during that initial boot. Don't kill the sweep thinking it's hung — `bootstatus -b` is doing the right thing.
</content>
</invoke>
