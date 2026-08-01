#!/usr/bin/env bash
# Prepare one simulator for one language of an App Store screenshot sweep.
#
#   scripts/prep_screenshot_sim.sh "iPad Pro 13-inch (M5)" es
#   scripts/prep_screenshot_sim.sh "iPhone 17 Pro Max" en
#
# Does the four steps of docs/screenshot-playbook.md "Clean Status Bar" IN THE ORDER
# THAT MATTERS, then prints proof that each landed:
#
#   set system language -> reboot -> RE-APPLY status bar override -> verify
#
# Why this is a script and not four commands in the playbook: `simctl status_bar
# override` is cleared by every shutdown/reboot but survives install/launch, while
# changing the system language REQUIRES a reboot. So an override applied before the
# language change is silently wiped, and that language's shots ship with a live
# wall-clock instead of the pinned 9:41 — the exact defect version_1 carried. Nothing
# in a visual review catches it unless you happen to compare clocks across languages.
#
# The system language is not cosmetic on either device:
#   - iPad: the status bar shows a DATE, rendered in the system language. A sim left on
#     French stamps "Dimanche 26 juillet" onto English/Spanish screenshots (workaround
#     #14). The app's own UI localizes correctly regardless, which is why it is easy to
#     miss.
#   - BOTH: the pinned time is locale-formatted — en_US renders "9:41", es_ES renders
#     "09:41". Set it on only one device and the two disagree within the same language.
#
# Run this once per (device, language) pair, then shoot that language's 9 views with
# scripts/take_screenshots.sh --device "<name>" --lang <lang>. Keep the device booted
# for the whole language pass so the override survives.

set -euo pipefail

DEVICE_NAME="${1:-}"
LANG_CODE="${2:-}"

if [[ -z "$DEVICE_NAME" || -z "$LANG_CODE" ]]; then
  echo "usage: $(basename "$0") <device-name> <en|es>" >&2
  exit 2
fi

case "$LANG_CODE" in
  en) LOCALE=en_US ;;
  es) LOCALE=es_ES ;;
  *) echo "unknown language '$LANG_CODE' (expected en or es)" >&2; exit 2 ;;
esac

# Resolve by exact device name, the same way take_screenshots.sh::udid_for does — a
# Python string literal comparison, so the iPad's paren-bearing default name works.
UDID=$(xcrun simctl list devices available | python3 -c '
import sys, re
name = sys.argv[1]
for line in sys.stdin:
    m = re.match(r"\s+(.*?) \(([0-9A-Fa-f-]{36})\) \(", line.rstrip())
    if m and m.group(1) == name:
        print(m.group(2))
        break
' "$DEVICE_NAME")

if [[ -z "$UDID" ]]; then
  echo "no available simulator named '$DEVICE_NAME' — see Simulator Setup in the playbook" >&2
  exit 2
fi

log() { echo "[prep_screenshot_sim] $*"; }

log "$DEVICE_NAME ($UDID) -> system language $LANG_CODE ($LOCALE)"

xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || xcrun simctl boot "$UDID"
xcrun simctl spawn "$UDID" defaults write -g AppleLanguages -array "$LANG_CODE"
xcrun simctl spawn "$UDID" defaults write -g AppleLocale -string "$LOCALE"

# The reboot is what makes the language take effect — and what clears the override,
# which is why the override is applied AFTER this and never before.
log "rebooting (required for the language change; also clears the status bar override)"
xcrun simctl shutdown "$UDID"
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b >/dev/null

# A `simctl boot` does not always give the device a Simulator.app WINDOW. When the
# reboot above lands while Simulator.app is already running, the device can come back
# booted-but-windowless: simctl and axe keep working (they talk to the device, not the
# UI), so nothing looks wrong — but take_screenshots.sh's set_keyboard_state raises
# `first window whose title contains "iPad"`, finds no such window, and fails all three
# attempts with -1719 "Invalid index". The only visible symptom is one keyboard-less
# quiz_mid screenshot. Hit on 2026-07-26 on the iPad/es pass (workaround #24).
#
# `open -a Simulator --args -CurrentDeviceUDID` does NOT fix it once Simulator is
# already running (verified — the args are ignored), and neither does File > Open
# Simulator. Quitting and relaunching does: on launch Simulator attaches a window to
# every already-booted device. This runs BEFORE the override because a quit can take
# the device down with it, and a re-boot would clear the override.
ensure_simulator_window() {
  local match="$1" attempt front
  windows() {
    osascript -e 'tell application "System Events" to tell process "Simulator" to get name of every window' 2>/dev/null || true
  }
  if [[ "$(windows)" == *"$match"* ]]; then
    log "Simulator window for '$match' is present"
    return 0
  fi
  log "no Simulator window for '$match' — relaunching Simulator.app to attach one"
  osascript -e 'tell application "Simulator" to quit' >/dev/null 2>&1 || true
  sleep 3
  # A quit may have taken the device with it; bring it back before asking for a window.
  xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || {
    xcrun simctl boot "$UDID"
    xcrun simctl bootstatus "$UDID" -b >/dev/null
  }
  open -a Simulator
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    sleep 2
    if [[ "$(windows)" == *"$match"* ]]; then
      log "Simulator window for '$match' attached (attempt $attempt)"
      return 0
    fi
  done
  log "warning: still no Simulator window for '$match' — the quiz_mid soft keyboard"
  log "         (Cmd+K) will fail for this device; see workaround #24 in the playbook"
}
ensure_simulator_window "$DEVICE_NAME"

log "re-applying status bar override"
# --time takes a bare clock string: "9:41 AM" and ISO strings are both rejected as
# "Invalid, non-ISO date/time string" on this runtime. The system renders AM/PM (or
# not) and the date itself from the locale set above.
# --cellularMode notSupported hides the cellular signal, correct for a Wi-Fi iPad;
# forcing --cellularBars instead paints a bogus "Carrier" onto a Wi-Fi-only device.
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode notSupported \
  --batteryState charged --batteryLevel 100

# Print proof both halves landed. A future reader should be able to see, rather than
# assume, that the override survived the reboot and the language is what was asked for.
log "verification:"
xcrun simctl status_bar "$UDID" list | sed 's/^/    /'
log "AppleLanguages is now: $(xcrun simctl spawn "$UDID" defaults read -g AppleLanguages | tr -d '\n ')"
log "ready — now run: scripts/take_screenshots.sh --device \"$DEVICE_NAME\" --lang $LANG_CODE"
