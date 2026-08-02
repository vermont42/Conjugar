#!/usr/bin/env bash
# Drive ios-build-verify (and axe/simctl directly) through the 36 App Store
# screenshots described in docs/screenshot-plan.md.
#
# Usage:
#   scripts/take_screenshots.sh  # all 36
#   scripts/take_screenshots.sh --device "iPhone 17 Pro Max"  # 18
#   scripts/take_screenshots.sh --lang es  # 18
#   scripts/take_screenshots.sh --view model_browse  # 4
#   scripts/take_screenshots.sh --device "iPhone 17 Pro Max" --lang es --view quiz_results  # 1
#
# See docs/screenshot-playbook.md for setup, recovery guidance, and a
# cross-referenced workarounds index. Calibration values and per-view nav
# functions are inline below.
#
# Compatible with macOS bash 3.2 (system default): uses case-statement lookup
# functions instead of associative arrays.

set -euo pipefail

# ---------------------------------------------------------------------------
# Repo root (cwd-independent)
# ---------------------------------------------------------------------------
# Resolve the repo root from this script's own location (scripts/ is one level
# below the root) so the driver works from any working directory — screenshots
# land under <repo>/docs/screenshots and Conjugar.xcodeproj resolves absolutely.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

APP_BUNDLE_ID='biz.joshadams.Conjugar'
# Onboarding is suppressed three ways, in order of reliability:
#   1. OnboardingDisplay.onboardingEnabled = false (compile-time; operator step,
#      see "Disable tips and onboarding first" in the playbook),
#   2. pre-seeding hasSeenOnboarding=true (see seed_defaults),
#   3. these labels, a last-ditch fallback for the wait_for_render loop in case
#      onboarding still surfaces. (workaround #11)
# TipKit tips have no runtime fallback at all — TipDisplay.tipsEnabled = false is
# the only defense, and a stray tip card is invisible to this driver. Review the
# PNGs by eye.
ONBOARDING_LABELS=( "Skip" "Omitir" )

DEVICES=( "iPhone 17 Pro Max" "iPad Pro 13-inch (M5)" )
LANGS=( en es )
VIEWS=( verb_browse verb_view model_browse model_view quiz_mid \
        info_browse info_view quiz_results settings )

# ---------------------------------------------------------------------------
# Lookup tables (case statements; bash 3.2-compatible)
# ---------------------------------------------------------------------------

appearance_for() {
  case "$1" in
    verb_browse)  echo dark  ;;
    verb_view)    echo light ;;
    model_browse) echo dark  ;;
    model_view)   echo light ;;
    quiz_mid)     echo dark  ;;
    info_browse)  echo light ;;
    info_view)    echo dark  ;;
    quiz_results) echo light ;;
    settings)     echo dark  ;;
  esac
}

# Resolve a simulator UDID by its exact device name. Unlike Konjugieren's driver
# (which hardcoded UDIDs to dodge _resolve_udid.sh's paren-in-name regex bug),
# this matches the name as a literal in Python, so the iPad's Apple-default name
# "iPad Pro 13-inch (M5)" works unchanged — no sim renaming needed.
udid_for() {
  xcrun simctl list devices available | python3 -c '
import sys, re
name = sys.argv[1]
for line in sys.stdin:
    m = re.match(r"\s+(.*?) \(([0-9A-Fa-f-]{36})\) \(", line.rstrip())
    if m and m.group(1) == name:
        print(m.group(2))
        break
' "$1"
}

# Tab-bar centers (logical points). Order: verbs models quiz info settings.
# iPhone uses the bottom pill tab bar (y=899.3); iPad uses a top segmented tab bar
# (y=54). NOTE: .claude/ios-build-verify.config.sh carries a *different* hand-set
# MAIN_TABS_COORDS for a plain iPhone 17 ("63,822 …") — do not cross-copy.
#
# Verified 2026-07-18 by tapping all ten and asserting the destination screen's
# anchor appeared (Browse→browse_verb_count, Models→model_row_*, Quiz→
# quiz_start_button, Info→info_row_*, Settings→app_icon_*). Both rows pass.
#
# iPhone values are Conjuguer's, unchanged — its tab-bar children are not exposed
# in the AXTree (the pill reports as one "Tab Bar" group, frame {0,873},{440,83}),
# so these cannot be measured, only confirmed by tapping. They are.
#
# iPad values below are ENGLISH fallbacks only — the live path is measurement.
# The iPad's top segmented bar sizes each tab to its *label*, so every center
# moves when the UI language changes: in Spanish the bar reads Explorar/Modelos/
# Test/Información/Configuración and the real centers are 300.25/398.25/480.5/
# 575.75/709.25 — the English "quiz" value (526) lands inside *Información*, and
# the English "models" value (447.7) sits 0.05 pt inside the Modelos tab. That
# bit in July 2026: the iPad/es quiz_mid and quiz_results cells both failed with
# "no element with id 'quiz_start_button'" because tap_tab quiz had opened Info.
# So tap_tab MEASURES the centers at run time on iPad (measured_tab_centers) and
# only falls back to this table when measurement fails. The iPhone pill exposes
# no children (one "Tab Bar" group, frame {0,873},{440,83}), so it always uses
# the table — its pill divides evenly and is label-width independent.
tab_coords_for() {
  case "$1" in
    "iPhone 17 Pro Max")     echo "67,899.3 142.7,899.3 220,899.3 296.2,899.3 372.6,899.3" ;;
    "iPad Pro 13-inch (M5)") echo "358.2,54 447.7,54 526,54 590.8,54 670.3,54" ;;
  esac
}

# iPad's verb_browse anchor renders slowly (4,811 verbs from verbModelMap.xml,
# laid out in a regular-size-class grid on every cold launch).
wait_budget_for() {
  case "$1" in
    "iPhone 17 Pro Max")     echo 10 ;;
    "iPad Pro 13-inch (M5)") echo 45 ;;
  esac
}

# ---------------------------------------------------------------------------
# CLI parsing
# ---------------------------------------------------------------------------

DEVICE_FILTER=""
LANG_FILTER=""
VIEW_FILTER=""

usage() {
  sed -n '2,15p' "$0" | sed 's/^# \?//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE_FILTER="$2"; shift 2 ;;
    --lang)   LANG_FILTER="$2";   shift 2 ;;
    --view)   VIEW_FILTER="$2";   shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log() { echo "[take_screenshots] $*" >&2; }

# Per-iteration state (set inside loop):
UDID=""
DEVICE=""
DEVICE_SLUG=""
WAIT_FOR_RENDER_BUDGET_S=10
CURRENT_TAB_CENTERS=()

apply_device_state() {
  DEVICE="$1"
  UDID=$(udid_for "$DEVICE")
  [[ -n "$UDID" ]] || { log "no available simulator named '$DEVICE' — see Simulator Setup in the playbook"; exit 2; }
  DEVICE_SLUG="${DEVICE// /-}"
  WAIT_FOR_RENDER_BUDGET_S=$(wait_budget_for "$DEVICE")
  IFS=' ' read -ra CURRENT_TAB_CENTERS <<< "$(tab_coords_for "$DEVICE")"
}

ensure_booted() {
  if ! xcrun simctl list devices booted | grep -q "$UDID"; then
    log "booting $DEVICE ($UDID) — iPad first-boot can take ~70s"
    xcrun simctl boot "$UDID"
  fi
  xcrun simctl bootstatus "$UDID" -b >/dev/null
}

set_appearance() {
  xcrun simctl ui "$UDID" appearance "$1" >/dev/null
}

terminate_app() {
  xcrun simctl terminate "$UDID" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
}

uninstall_app() {
  xcrun simctl uninstall "$UDID" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
}

install_app() {
  xcrun simctl install "$UDID" "$1"
}

# Pre-seed two persisted Settings values (both stored as strings via
# GetterSetterReal → UserDefaults; see Utils/Settings.swift) so the sweep isn't
# interrupted:
#   - hasSeenOnboarding = true  → OnboardingView never shows (workaround #2/#11).
#   - lastReviewPromptDate = now → ReviewPrompterReal's promptInterval cooldown
#     blocks every StoreKit review prompt this run (workaround #7).
#   - didShowGameCenterDialog = true, userRejectedGameCenter = true → QuizView's
#     .onAppear { maybePromptGameCenter() } alert never fires (workaround #15).
# Bool/Date SettingValue decoders accept the string forms "true" and the unix
# epoch, so -string is correct for all of them.
seed_defaults() {
  xcrun simctl spawn "$UDID" defaults write "$APP_BUNDLE_ID" hasSeenOnboarding -string true >/dev/null 2>&1 || true
  xcrun simctl spawn "$UDID" defaults write "$APP_BUNDLE_ID" lastReviewPromptDate -string "$(date +%s)" >/dev/null 2>&1 || true
  xcrun simctl spawn "$UDID" defaults write "$APP_BUNDLE_ID" didShowGameCenterDialog -string true >/dev/null 2>&1 || true
  xcrun simctl spawn "$UDID" defaults write "$APP_BUNDLE_ID" userRejectedGameCenter -string true >/dev/null 2>&1 || true
}

launch_with_lang() {
  local lang="$1" locale
  case "$lang" in
    en) locale='en_US' ;;
    es) locale='es_ES' ;;
    *) log "unknown lang: $lang"; return 1 ;;
  esac
  xcrun simctl launch "$UDID" "$APP_BUNDLE_ID" \
    -AppleLanguages "($lang)" \
    -AppleLocale "$locale" \
    -CONJUGAR_QUIZ_FIXTURE screenshot >/dev/null
}

axe_tree() {
  axe describe-ui --udid "$UDID" 2>/dev/null || echo "{}"
}

# jq predicate that matches an element whose AXUniqueId is exactly $id OR begins
# with "$id-". SwiftUI propagates accessibilityIdentifier through the row's
# NavigationLink wrapper, so a row tagged "verb_row_ser" surfaces in the AXTree
# as "verb_row_ser-verb_row_ser". The "-" boundary keeps the prefix match from
# colliding with sibling ids (e.g. verb_row_ser vs verb_row_servir). Note this is
# also why model rows are keyed by exemplar and not by the hyphen-bearing
# classNumber — see nav_model_browse. (workarounds #3 and #17)
ID_MATCH='select(.AXUniqueId? != null and (.AXUniqueId == $id or (.AXUniqueId | startswith($id + "-"))))'

axe_has_id() {
  axe_tree | jq -e --arg id "$1" "[.. | objects | $ID_MATCH] | length > 0" >/dev/null 2>&1
}

wait_for_render() {
  local anchor="${1:-browse_verb_count}"
  local deadline=$(($(date +%s) + WAIT_FOR_RENDER_BUDGET_S))
  while [[ $(date +%s) -lt $deadline ]]; do
    local tree
    tree=$(axe_tree)
    if echo "$tree" | jq -e --arg id "$anchor" \
        "[.. | objects | $ID_MATCH] | length > 0" \
        >/dev/null 2>&1; then
      return 0
    fi
    for label in "${ONBOARDING_LABELS[@]}"; do
      if echo "$tree" | jq -e --arg l "$label" \
          '[.. | objects | select(.AXLabel? == $l)] | length > 0' \
          >/dev/null 2>&1; then
        axe tap --label "$label" --udid "$UDID" >/dev/null 2>&1 || true
        break
      fi
    done
    sleep 0.5
  done
  log "wait_for_render timed out (${WAIT_FOR_RENDER_BUDGET_S}s) on $DEVICE for $anchor"
  return 5
}

verify_screen_loaded() {
  wait_for_render "$1"
}

# Return the AXFrame "x y w h" of the LARGEST-AREA element whose AXUniqueId
# matches $1, or empty string if none is currently rendered.
#
# Largest-area, not depth-first [0]: ported from Konjugieren, where an iPad Info
# row exposed its heading as a zero-interaction AXStaticText *above* the tappable
# AXButton in the tree, so [0] tapped the static text, nothing happened, and four
# cells captured the Info list instead of the article — with no error anywhere.
# Preferring AXButton is the obvious fix and is wrong: on iPad a verb row exposes
# its translation as a button while the infinitive is static text, so that rule
# taps the translation. Area is the property that actually distinguishes the row
# from a label inside it.
#
# This is a SAFETY NET here, not a fix for an observed Conjugar failure: as of the
# 2026-07-18 sweep every tap site on both devices in both languages had exactly one
# match, so old and new behavior agree everywhere in this app today. Keep it anyway
# — the failure it prevents is silent. (workaround #21)
frame_of() {
  axe_tree | jq -r --arg id "$1" \
    "[.. | objects | $ID_MATCH | select(.AXFrame? != null)] | .[] | .AXFrame" \
    | sed -E 's/[{},]/ /g; s/  +/ /g' \
    | awk 'NF >= 4 { area = $3 * $4; if (area > best) { best = area; line = $0 } } END { if (line != "") print line }'
}

# SwiftUI propagates accessibilityIdentifier to child elements, so `axe tap --id`
# refuses to disambiguate when multiple matches exist; it also throws a Swift
# typeMismatch in some iPad screen states. So we extract the first match's frame
# and tap its center via coords. (workarounds #3 and #9)
tap_id() {
  tap_id_first "$1"
}

tap_id_first() {
  local id="$1" frame x y w h cx cy
  frame=$(frame_of "$id")
  if [[ -z "$frame" ]]; then
    log "tap_id_first: no element with id '$id'"
    return 1
  fi
  read -r x y w h <<< "$frame"
  cx=$(awk "BEGIN{printf \"%.2f\", $x + $w/2}")
  cy=$(awk "BEGIN{printf \"%.2f\", $y + $h/2}")
  axe tap -x "$cx" -y "$cy" --udid "$UDID" >/dev/null
  sleep 0.7
}

# Is the soft keyboard currently on screen?
#
# The keyboard belongs to a separate process, so it does NOT appear in the app's
# `axe describe-ui` tree at all — a full-tree dump of a screen with the keyboard
# plainly visible returns zero keyboard elements. `describe-ui --point` *does*
# see it (same trick workaround #12 uses to look inside the StoreKit modal), so
# probe a coordinate in the middle of the key field and ask what is under it:
# a single-character label ("g") means keys are there; anything longer is the
# app's own content showing through, i.e. no keyboard.
#
# The point is deliberately mid-keyboard rather than on the space bar: space
# reports a blank label, which is indistinguishable from "nothing found".
# (workaround #16)
keyboard_is_visible() {
  local probe labels
  case "$DEVICE" in
    "iPhone 17 Pro Max")     probe="220,760"  ;;
    "iPad Pro 13-inch (M5)") probe="516,1120" ;;
    *) return 1 ;;
  esac
  labels=$(axe describe-ui --point "$probe" --udid "$UDID" 2>/dev/null \
    | jq -r '[.. | objects | select(.AXLabel? != null and .AXLabel != "") | .AXLabel] | join("|")' 2>/dev/null)
  [[ -n "$labels" && ${#labels} -le 2 ]]
}

# Put the target device's keyboard into a known state.
#
#   set_keyboard_state visible  -> hardware keyboard DETACHED, soft keyboard on screen
#   set_keyboard_state hidden   -> hardware keyboard ATTACHED, no soft keyboard
#
# The two are one setting, not two: iOS shows the software keyboard for a focused field
# exactly when no hardware keyboard is attached, and Simulator's
# "I/O > Keyboard > Connect Hardware Keyboard" menu item is what attaches/detaches it.
# The menu acts on the FRONTMOST device window, hence the raise/frontmost guards below.
#
# Why the sweep needs BOTH states, which is the whole shape of this function
# (found 2026-08-01, workaround #25):
#
#   - Screen 5 must SHOW the keyboard, so it needs the hardware keyboard detached.
#   - Every quiz answer is pasted with Cmd+V (workaround #5: axe type has no keycodes for
#     Spanish accents — `axe type "habré"` still fails with "No keycode found for
#     character: 'é'", re-verified 2026-08-01). axe injects that combo as HARDWARE key
#     events, which the device ignores while the hardware keyboard is detached: with it
#     off, Cmd+V silently does nothing and the field keeps its placeholder, while
#     `axe type` (software-keyboard path) still works. Verified by hand on the live quiz
#     screen, both directions.
#
# So the answer is pasted with the keyboard attached and the hardware keyboard is detached
# afterwards, purely to raise the soft keyboard for the capture. Detaching does not
# disturb the field's contents. nav_quiz_results wants the opposite state throughout: it
# submits 12 answers with Cmd+V and Return and never photographs a keyboard.
#
# Cmd+K ("Toggle Software Keyboard") was what this did through the version_2 sweep. As of
# Xcode 26.3 / 2026-08-01 it no longer surfaces the keyboard on this machine — the
# keystroke lands (Simulator frontmost, osascript exit 0) and nothing happens, and
# clicking that menu item directly is equally inert, while toggling Connect Hardware
# Keyboard works instantly. It is gone rather than kept as a fallback: it cannot help, and
# a stray toggle of a second keyboard setting makes this state machine harder to reason
# about.
#
# The menu item is a TOGGLE whose checkmark is only readable while the menu is open, so
# this never reads the setting — it clicks and then asks the screen whether the keyboard
# is where it should be, which is the property that actually matters. That check is also
# what makes the function idempotent across cells: the setting persists across app
# launches, so without it the second quiz_mid cell would toggle the keyboard back off and
# the four quiz_mid shots would alternate. (workarounds #6, #10, #16, #24 and #25)
set_keyboard_state() {
  local want="$1" window_match attempt front
  if keyboard_state_is "$want"; then
    return 0
  fi
  case "$DEVICE" in
    "iPhone 17 Pro Max")     window_match="iPhone" ;;
    "iPad Pro 13-inch (M5)") window_match="iPad" ;;
    *) window_match="" ;;
  esac
  # `delay 0.5` after activate, not 0.2: with a freshly-activated Simulator the window
  # list is briefly unenumerable and the AXRaise fails with a -1719 "Invalid index", which
  # reads exactly like a missing-permission failure and sends you chasing the wrong thing.
  # Observed once at 0.2 s, never at 0.5 s.
  #
  # Retried, and never fatal. That unenumerable window list is a race, not a steady state,
  # and the first quiz cell of a sweep runs moments after a fresh install, which is exactly
  # when it loses. A genuine permission failure fails all three attempts and still gets a
  # warning, and the state check reports the real outcome either way, so continuing costs
  # at most one reviewable screenshot.
  #
  # The menu click is gated on Simulator actually being frontmost, and that guard is NOT
  # redundant with the AXRaise above. When the raise silently fails to take focus, a
  # keystroke still SUCCEEDS — it just lands in whichever app *is* frontmost. Observed
  # 2026-07-26, where a stray Cmd+K launched Fitness on the host Mac while the sweep
  # reported nothing wrong. Checking frontmost first turns a silent misfire into a log line
  # naming the app that caught it — and because the check sits INSIDE the loop, a transient
  # focus steal recovers on the next attempt instead of costing the cell. (workaround #10)
  #
  # A device can be BOOTED yet have no Simulator WINDOW: `xcrun simctl boot` does not
  # always make Simulator.app attach one when Simulator is already running, and a
  # per-language reboot is the usual way in. Nothing else in the sweep notices, because
  # simctl and axe talk to the device rather than to the UI — but AXRaise then has no
  # window to raise and fails with -1719 "Invalid index", indistinguishable from the
  # missing-permission failure. Checking first turns that into a log line naming the real
  # cause. Recovery is deliberately NOT attempted here — restoring a window means quitting
  # and relaunching Simulator.app, too blunt mid-sweep; prep_screenshot_sim.sh does it at
  # reboot time, where a relaunch costs nothing. (workaround #24)
  for attempt in 1 2 3; do
    if [[ "$(osascript -e 'tell application "System Events" to tell process "Simulator" to get name of every window' 2>/dev/null || true)" != *"$window_match"* ]]; then
      log "keyboard($want) attempt $attempt: no Simulator window matching '$window_match' (device booted but windowless? see prep_screenshot_sim.sh); not touching the menu"
      sleep 1.0
      continue
    fi
    if osascript -e 'tell application "Simulator" to activate' \
              -e 'delay 0.5' \
              -e "tell application \"System Events\" to tell process \"Simulator\" to perform action \"AXRaise\" of (first window whose title contains \"$window_match\")" \
              -e 'delay 0.3' \
              >/dev/null 2>&1; then
      front=$(osascript -e 'tell application "System Events" to name of first process whose frontmost is true' 2>/dev/null || true)
      if [[ "$front" != "Simulator" ]]; then
        log "keyboard($want) attempt $attempt: frontmost is '${front:-unknown}', not Simulator; not touching the menu"
        sleep 1.0
        continue
      fi
      if toggle_hardware_keyboard && keyboard_state_is "$want"; then
        return 0
      fi
    fi
    log "keyboard($want) attempt $attempt did not land; retrying"
    sleep 1.0
  done
  log "warning: could not put the keyboard in state '$want' on $DEVICE (accessibility permission for /usr/bin/osascript, Simulator never came frontmost, or the device has no Simulator window)"
}

keyboard_state_is() {
  if [[ "$1" == visible ]]; then
    keyboard_is_visible
  else
    ! keyboard_is_visible
  fi
}

# Click Simulator's "I/O > Keyboard > Connect Hardware Keyboard" for the frontmost
# device window. Callers must have raised the right window first — the menu acts on
# whichever device is frontmost, which is the same reason set_keyboard_state raises
# before touching it. Returns non-zero only if the click itself failed (missing
# accessibility permission, menu path renamed by a future Xcode).
toggle_hardware_keyboard() {
  osascript -e 'tell application "System Events" to tell process "Simulator" to click menu item "Connect Hardware Keyboard" of menu 1 of menu item "Keyboard" of menu 1 of menu bar item "I/O" of menu bar 1' \
    >/dev/null 2>&1 || return 1
  sleep 1.2  # keyboard slide-up animation
}

# axe type lacks HID-keycode mappings for non-ASCII characters (Spanish accents
# á é í ó ú ñ ü), so route typing through the system pasteboard + Cmd+V. Works
# for any Unicode and bypasses the soft-vs-hardware keyboard distinction.
# Conjugated Spanish is full of accents (sé, habré, oí, añadió), so every quiz
# answer routes through here.
# (workaround #5)
type_via_pasteboard() {
  local text="$1"
  printf '%s' "$text" | xcrun simctl pbcopy "$UDID"
  sleep 0.15
  axe key-combo --modifiers 227 --key 25 --udid "$UDID" >/dev/null  # Cmd+V
}

# Current contents of the quiz answer field, or empty string.
quiz_field_value() {
  axe_tree | jq -r --arg id input_quiz_conjugation \
    "[.. | objects | $ID_MATCH | .AXValue] | map(select(. != null and . != \"\")) | .[0] // \"\"" \
    2>/dev/null
}

# Paste one answer into the quiz field and CONFIRM it landed.
#
# The confirmation is not belt-and-braces; it covers a real failure introduced by the
# soft-keyboard fix. QuizView auto-focuses the answer field after Start and re-focuses
# after each submit, so the driver's old `tap_id input_quiz_conjugation` was tapping a
# field that already had focus. With the hardware keyboard connected that was harmless.
# With it detached (see set_keyboard_state) the same tap raises iOS's edit callout
# — "Paste | AutoFill" — which both swallows the Cmd+V that follows AND sits in the
# middle of the screenshot. Observed 2026-08-01: an otherwise perfect quiz_mid cell with
# a placeholder-empty field and the callout over the question card.
#
# So attempt 1 does NOT tap: it relies on the auto-focus, which is the state the app
# actually leaves behind. Only if the value fails to land does it fall back to tapping
# the field (attempt 2) and to Cmd+A-then-replace (attempt 3), each of which can raise
# the callout — a defect in the capture, but a visible one, and better than an empty
# field. In nav_quiz_results the check matters for a different reason: a silently missed
# paste there would desynchronize every later answer from its question.
paste_into_quiz_field() {
  local answer="$1" attempt value
  for attempt in 1 2 3; do
    case "$attempt" in
      2) tap_id_first input_quiz_conjugation || true ;;
      3) tap_id_first input_quiz_conjugation || true
         axe key-combo --modifiers 227 --key 4 --udid "$UDID" >/dev/null 2>&1 || true  # Cmd+A
         sleep 0.2 ;;
    esac
    type_via_pasteboard "$answer"
    sleep 0.35
    value=$(quiz_field_value)
    if [[ "$value" == "$answer" ]]; then
      return 0
    fi
    log "paste attempt $attempt: field reads '${value:-<empty>}', expected '$answer'"
  done
  log "warning: could not paste '$answer' into the quiz field on $DEVICE"
  return 0
}

# Measure the five tab centers from the live AXTree, left to right. Only the
# iPad's top segmented bar exposes its tabs (as AXRadioButton); the iPhone pill
# reports as a single group, so this prints nothing there and tap_tab falls back
# to tab_coords_for's table. Emits "x,y" per tab, space-separated, or nothing if
# the tree does not hold exactly five radio buttons (wrong screen, mid-animation,
# a modal on top) — an all-or-nothing result, so a partial read can never be
# mistaken for a good one.
measured_tab_centers() {
  axe describe-ui --udid "$UDID" 2>/dev/null | jq -r '
    [ .. | objects
      | select(.role? == "AXRadioButton")
      | (.AXFrame | capture("\\{\\{(?<x>[-0-9.]+), (?<y>[-0-9.]+)\\}, \\{(?<w>[-0-9.]+), (?<h>[-0-9.]+)\\}\\}"))
      | { x: ((.x | tonumber) + (.w | tonumber) / 2),
          y: ((.y | tonumber) + (.h | tonumber) / 2) } ]
    | sort_by(.x)
    | if length == 5 then map("\(.x),\(.y)") | join(" ") else empty end
  ' 2>/dev/null
}

tap_tab() {
  local tab_name="$1" index
  case "$tab_name" in
    verbs)    index=0 ;;
    models)   index=1 ;;
    quiz)     index=2 ;;
    info)     index=3 ;;
    settings) index=4 ;;
    *) log "unknown tab: $tab_name"; return 1 ;;
  esac
  # Prefer live-measured centers (iPad, where labels resize the tabs per language);
  # fall back to the calibrated table (iPhone, or any state that fails to measure).
  local measured
  measured=$(measured_tab_centers)
  local centers=( "${CURRENT_TAB_CENTERS[@]}" )
  if [[ -n "$measured" ]]; then
    # shellcheck disable=SC2206
    centers=( $measured )
  fi
  local center="${centers[$index]}"
  axe tap -x "${center%,*}" -y "${center#*,}" --udid "$UDID" >/dev/null
  sleep 0.7
}

swipe_up_pts() {
  local pts="$1"
  [[ "$pts" -le 0 ]] && return 0
  local start_y=600
  local end_y=$((start_y - pts))
  axe swipe --start-x 200 --start-y "$start_y" \
            --end-x 200 --end-y "$end_y" --duration 1.0 \
            --udid "$UDID" >/dev/null
  sleep 0.5
}

# Scroll the current list until the element with id $1 has its top edge at or
# above $2 (logical points). $3 = max swipes, $4 = per-swipe distance (smaller =
# finer landing, less overshoot). More robust than a fixed per-device scroll
# table for the deep Info-list rows (the Tenses section sits below the About +
# Concepts sections). Overshoot guard: a lazy list drops off-screen rows from the
# AXTree, so once we've seen the row and it then vanishes, it has scrolled above
# the top — stop there (the section header is sticky and stays pinned at top).
scroll_until_top() {
  local id="$1" target_y="$2" max_iters="${3:-15}" step="${4:-120}" i frame y seen=0
  for (( i = 0; i < max_iters; i++ )); do
    frame=$(frame_of "$id")
    if [[ -n "$frame" ]]; then
      seen=1
      read -r _ y _ _ <<< "$frame"
      if awk "BEGIN{exit !($y <= $target_y)}"; then
        return 0
      fi
    elif [[ "$seen" -eq 1 ]]; then
      return 0
    fi
    swipe_up_pts "$step"
  done
  log "scroll_until_top: '$id' not at/above y=$target_y after $max_iters swipes"
  return 0
}

read_fixture_answers_path() {
  local data_dir
  data_dir=$(xcrun simctl get_app_container "$UDID" "$APP_BUNDLE_ID" data 2>/dev/null)
  echo "$data_dir/Documents/screenshot_fixture_answers.json"
}

# Largest frame-to-frame difference (ImageMagick -metric AE) still considered "settled".
#
# MEASURED ON CONJUGAR, 2026-07-26, iOS 26.3, both sim targets. These are this app's own
# numbers — do not port them to Conjuguer or Konjugieren, and re-measure here if the
# animations change. Note `-metric AE` reports summed channel error in quantum units, not
# a count of differing pixels; only the ratios below are meaningful.
#
#   Benign motion (must be BELOW this constant), 112 consecutive-frame samples on the quiz
#   screen across both devices — QuizView's elapsed counter ticks and the answer cursor
#   blinks, so it never fully settles:
#       median 9.8e6 · p95 1.9e7 · max 4.6e7
#     A genuinely static screen (Settings, Browse) scores exactly 0.
#
#   A real transition (must be ABOVE this constant), first delta after an iPad tab tap:
#       21 samples, min 1.2e8, typical 8.3e9–2.5e10
#
# 7.5e7 is the geometric middle of 4.6e7 ↔ 1.2e8: 1.6x above the worst benign frame,
# 1.5x below the smallest real transition. That gap is only ~2.5x, so if the "still
# changing after 8 samples" warning starts appearing, RE-MEASURE — do not nudge this up.
#
# Both siblings' values were tried against this data and both are too tight for Conjugar:
# Conjuguer's 5e7 sits 1.08x above our worst benign frame (the quiz screen would trip it),
# and Konjugieren's 1e8 sits only 1.16x below our smallest observed transition.
#
# Known limit, recorded honestly: an iPad cross-fade's *tail* scores 7.7e6–1.1e7, below the
# quiz screen's own noise, so no single threshold separates a late-fade frame from benign
# motion. It does not matter in practice — in every observed case the frame after such a
# delta was byte-identical to the settled screen (the following delta was 0), so the gate
# still yields a correct capture. If a ghosted screenshot ever reappears, this is the
# assumption that broke.
STABLE_PIXEL_TOLERANCE=75000000

# Block until two consecutive screenshots stop differing, so a capture can't land
# mid-transition.
#
# No accessibility wait substitutes for this. AX state answers "has the hierarchy
# changed", but a screenshot is graded on "has the image stopped moving", and those
# diverge: the outgoing screen's anchor leaves the AX tree within ~0.3 s of a tap while
# an iPad cross-fade is still plainly visible. That is exactly how both iPad settings
# cells shipped a frame with the Browse grid ghosted through the cards (fixed narrowly in
# 17faf79 by anchoring nav_settings on app_icon_bull and sleeping; this generalizes it to
# every capture). (workaround #22)
wait_for_stable_screen() {
  local dir previous current differing i
  if ! command -v magick >/dev/null 2>&1; then
    sleep 1.0
    return 0
  fi
  dir=$(mktemp -d)
  previous="$dir/previous.png"
  current="$dir/current.png"
  if ! axe screenshot --udid "$UDID" --output "$previous" >/dev/null 2>&1; then
    rm -rf "$dir"
    sleep 1.0
    return 0
  fi
  for i in 1 2 3 4 5 6 7 8; do
    sleep 0.35
    axe screenshot --udid "$UDID" --output "$current" >/dev/null 2>&1 || break
    # `|| true` is load-bearing: `magick compare` exits 1 whenever the images differ,
    # which is the normal case here, and under `set -o pipefail` (:19) that makes the
    # assignment fail and `set -e` abort the whole sweep.
    differing=$(magick compare -metric AE "$previous" "$current" null: 2>&1 | awk '{print $1}' || true)
    # awk, not [[ -le ]]: the metric comes back in scientific notation (1.80683e+10).
    if [[ -n "$differing" ]] \
       && awk -v d="$differing" -v t="$STABLE_PIXEL_TOLERANCE" 'BEGIN { exit !(d + 0 <= t + 0) }'; then
      rm -rf "$dir"
      return 0
    fi
    mv "$current" "$previous"
  done
  log "wait_for_stable_screen: screen still changing after 8 samples on $DEVICE"
  rm -rf "$dir"
  return 0
}

take_screenshot() {
  local slug="$1"
  wait_for_stable_screen
  mkdir -p "$REPO_ROOT/docs/screenshots"
  local ts out
  ts=$(date +%Y%m%d-%H%M%S)
  out="$REPO_ROOT/docs/screenshots/${ts}-${slug}.png"
  axe screenshot --udid "$UDID" --output "$out" >/dev/null
  # axe writes RGBA; App Store Connect rejects any screenshot with an alpha channel
  # ("Images can't include alpha channels or transparencies"), so flatten at capture
  # rather than discovering it at upload time. This is a FORMAT check on Apple's side,
  # not a content check — every one of version_1's 36 fully-opaque files fails it.
  # `scripts/verify_store_media.sh` is the backstop before upload. (workaround #23)
  if command -v magick >/dev/null 2>&1; then
    magick "$out" -background white -alpha remove -alpha off "$out"
  else
    log "WARNING: magick not found; $out keeps its alpha channel and will be rejected"
  fi
  log "captured: $out"
}

# ---------------------------------------------------------------------------
# Per-view nav functions
# ---------------------------------------------------------------------------

nav_verb_browse() {
  : # default landing; wait_for_render already ran in main loop. Frequency sort
    # is the default (Settings.verbSortDefault = .frequency), so ser is on top.
}

nav_verb_view() {
  tap_id_first verb_row_ser
}

# Model rows are identified by *exemplar*, not by ModelInfo.id (the classNumber).
# Class numbers contain hyphens ("29-2", "30-1") and ID_MATCH treats "-" as its
# prefix boundary, so model_row_29 would spuriously match model_row_29-2.
# (workaround #17)
nav_model_browse() {
  tap_tab models
  # Irregularity sort is the default (Settings.modelSortDefault = .irregularity),
  # which puts the decir model at the top per the spec.
  verify_screen_loaded model_row_decir
}

nav_model_view() {
  tap_tab models
  # Settle on the list before tapping into it, exactly as nav_model_browse does.
  # Without this the tap fires during the tab-switch transition and is swallowed:
  # on iPhone (July 2026) all four model_view cells silently captured the *list*
  # in light mode instead of the haber detail. The iPad masked it — its slower
  # render meant tap_tab's 0.7 s sleep had already covered the transition.
  verify_screen_loaded model_row_haber
  # Spec: haber, and no horizontal scrolling — the driver never scrolls sideways.
  tap_id_first model_row_haber
}

nav_quiz_mid() {
  tap_tab quiz
  tap_id quiz_start_button
  sleep 1.0  # let Quiz.start() write the fixture file + render the first question
  local fixture first_answer
  fixture=$(read_fixture_answers_path)
  first_answer=$(jq -r '.[0].answer // empty' "$fixture")
  [[ -n "$first_answer" ]] || { log "no fixture answer at $fixture — is the app built with -CONJUGAR_QUIZ_FIXTURE support?"; return 1; }
  # Paste FIRST, with the hardware keyboard attached, because Cmd+V only works in that
  # state; then detach it so the soft keyboard rises for the capture. Detaching leaves the
  # field's contents alone. The field is already focused (QuizView auto-focuses after
  # Start), which is why nothing taps it here — see paste_into_quiz_field.
  # (workaround #25)
  set_keyboard_state hidden
  paste_into_quiz_field "$first_answer"
  set_keyboard_state visible
  sleep 0.5  # let the keyboard slide-up finish before the screenshot
}

nav_info_browse() {
  tap_tab info
  # The segmented/animated tab can finish its highlight before the NavigationStack
  # swaps content; anchor on the first About row so the screenshot waits for the list.
  verify_screen_loaded info_row_purpose_and_use
  # Spec: scroll so the "About" ("Acerca de") section header is at top. Unlike
  # Conjuguer — whose spec wanted the *Tenses* header — About is only the second
  # section here: the availability-gated Tutor section sits above it (on a
  # simulator it renders as a single "unavailable" reason row, since Apple
  # Intelligence is never available there). So this is a short scroll that pushes
  # the Tutor section off the top, leaving the sticky About header pinned. Tune
  # the target_y if the header ends up clipped.
  scroll_until_top info_row_purpose_and_use 200
}

nav_info_view() {
  tap_tab info
  verify_screen_loaded info_row_purpose_and_use
  # Presente de Indicativo is the first row of the Tenses section, below all of
  # About; scroll it into the safe middle band (clear of the tab bar) before tapping.
  scroll_until_top info_row_presente_de_indicativo 400
  tap_id_first info_row_presente_de_indicativo
}

nav_quiz_results() {
  tap_tab quiz
  tap_id quiz_start_button
  sleep 1.0
  local fixture answer i count
  fixture=$(read_fixture_answers_path)
  # Conjugar's quiz length varies with Settings.difficulty, so don't hardcode 30
  # the way Conjuguer's driver did — the fixture is the source of truth for how
  # many questions there are.
  count=$(jq 'length' "$fixture")
  [[ "$count" -gt 0 ]] || { log "fixture at $fixture is empty — is the app built with -CONJUGAR_QUIZ_FIXTURE support?"; return 1; }
  # Cmd+V needs the hardware keyboard attached; this screen never shows a keyboard, so
  # keep it attached throughout. A preceding quiz_mid cell leaves it detached.
  # (workaround #25)
  set_keyboard_state hidden
  log "answering $count fixture questions"
  # No tap: the field is auto-focused after Start and re-focused after each submit, and
  # tapping it raises the edit callout that eats the paste (see paste_into_quiz_field).
  for i in $(seq 0 $((count - 1))); do
    answer=$(jq -r ".[$i].answer" "$fixture")
    paste_into_quiz_field "$answer"
    axe key 40 --udid "$UDID" >/dev/null   # Return; submitAnswer() re-focuses the field
    sleep 0.3
  done
  sleep 1.0  # let the results sheet animate in
  if ! axe_has_id results_score; then
    log "results_score not in AX tree; attempting review-prompt dismiss"
    dismiss_review_prompt
    sleep 0.7
  fi
  verify_screen_loaded results_score
}

# Fallback only: seed_defaults should keep the StoreKit review prompt from ever
# firing, but if one slips through it is the system dialog, so its button labels
# are system-localized ("Not Now" / "Ahora no"). The modal opaques the AX
# tree, but describe-ui --point inside it returns each element. Sweep a vertical
# line and tap the bottommost AXButton. (workaround #12)
dismiss_review_prompt() {
  local x_center y last_button_y=""
  case "$DEVICE" in
    "iPhone 17 Pro Max")     x_center=220 ;;
    "iPad Pro 13-inch (M5)") x_center=512 ;;
    *) return 0 ;;
  esac
  for y in 540 575 610 645 680 715; do
    if axe describe-ui --point "${x_center},${y}" --udid "$UDID" 2>/dev/null \
       | grep -qE '"role" : "AXButton"'; then
      last_button_y=$y
    fi
  done
  if [[ -n "$last_button_y" ]]; then
    axe tap -x "$x_center" -y "$last_button_y" --udid "$UDID" >/dev/null 2>&1
    sleep 0.5
    return 0
  fi
  log "review-prompt button not found in vertical sweep"
  return 0
}

nav_settings() {
  tap_tab settings
  # Settle on a Settings anchor, then let the tab crossfade finish. This was the
  # only recipe with no settle at all, and on iPad it showed: both settings cells
  # (July 2026) captured the Browse grid ghosted through the Settings cards at
  # partial opacity — the crossfade was still running when axe grabbed the frame.
  # The other tab-switching recipes get this for free from their
  # verify_screen_loaded poll; the extra sleep covers the animation itself, which
  # an anchor's mere presence does not.
  verify_screen_loaded app_icon_bull
  sleep 1.5
  # Spec: Region at top. Region is the first settingSection in SettingsView
  # (before Difficulty), so no scroll is needed.
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

resolve_ibv_scripts() {
  local path
  # Search only the marketplace clone, never ~/.claude broadly: the plugin cache
  # (~/.claude/plugins/cache/ios-build-verify/<version>/) holds several versions at
  # once, shared across apps, and `find`'s directory order is unspecified — so the
  # broad glob picked an arbitrary release to build App Store screenshots with. The
  # marketplace clone has no version segment and yields exactly one match.
  path=$(find ~/.claude/plugins/marketplaces -path '*ios-build-verify*' -name build_app.sh 2>/dev/null | head -1)
  [[ -n "$path" ]] || { log "ios-build-verify scripts not found"; exit 2; }
  echo "$(dirname "$path")"
}

resolve_app_path() {
  local built_dir
  built_dir=$(xcodebuild -project "$REPO_ROOT/Conjugar.xcodeproj" -scheme Conjugar \
    -destination 'generic/platform=iOS Simulator' \
    -showBuildSettings 2>/dev/null \
    | awk -F= '/^[[:space:]]+BUILT_PRODUCTS_DIR / { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }')
  [[ -n "$built_dir" ]] || { log "could not resolve BUILT_PRODUCTS_DIR"; exit 2; }
  echo "$built_dir/Conjugar.app"
}

filter_skip() {
  local value="$1" filter="$2"
  [[ -z "$filter" ]] && return 1
  [[ "$value" == "$filter" ]] && return 1
  return 0
}

main() {
  # ios-build-verify's build_app.sh resolves its config + project relative to the
  # current directory, so anchor cwd at the repo root regardless of where the
  # driver was invoked from.
  cd "$REPO_ROOT"

  # Honor a pre-set IBV_SCRIPTS so an unpublished build of the skill can be exercised
  # against a real sweep: the skill is developed at ~/Desktop/workspace/ios-build-verify
  # but consumed from GitHub, so the resolver below always finds the *published* copy.
  # Export IBV_SCRIPTS to override; unset it to go back to the published one.
  # An `if` rather than `: "${IBV_SCRIPTS:=$(resolve_ibv_scripts)}"`: the `:` builtin
  # always succeeds, so the resolver's `exit 2` would be swallowed and the sweep would
  # run on with an empty path. This form keeps the abort.
  if [[ -z "${IBV_SCRIPTS:-}" ]]; then
    IBV_SCRIPTS=$(resolve_ibv_scripts)
  fi
  log "ibv scripts: $IBV_SCRIPTS"

  log "building once (install per device after)"
  "$IBV_SCRIPTS/build_app.sh"

  local app_path
  app_path=$(resolve_app_path)
  [[ -d "$app_path" ]] || { log "app bundle not found at $app_path"; exit 2; }
  log "app bundle: $app_path"

  for device in "${DEVICES[@]}"; do
    if filter_skip "$device" "$DEVICE_FILTER"; then continue; fi
    apply_device_state "$device"
    log "===== device: $device ($UDID) ====="
    ensure_booted
    log "uninstalling + installing fresh"
    uninstall_app
    install_app "$app_path"
    seed_defaults

    for lang in "${LANGS[@]}"; do
      if filter_skip "$lang" "$LANG_FILTER"; then continue; fi

      for view in "${VIEWS[@]}"; do
        if filter_skip "$view" "$VIEW_FILTER"; then continue; fi

        log "--- $device / $lang / $view ---"
        set_appearance "$(appearance_for "$view")"
        terminate_app
        launch_with_lang "$lang"
        wait_for_render
        "nav_$view"
        take_screenshot "${DEVICE_SLUG}-${lang}-${view}"
      done
    done
  done

  log "done."
}

main "$@"
