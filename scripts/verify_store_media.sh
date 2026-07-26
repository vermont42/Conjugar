#!/bin/bash
#
# Preflight for App Store Connect media. Walks a directory of screenshots (.png/.jpg)
# and app previews (.mp4/.mov/.m4v) and asserts every requirement that has bitten this
# project, exiting non-zero and naming the offending file when one fails.
#
#   scripts/verify_store_media.sh ~/Desktop/ASC-upload
#   scripts/verify_store_media.sh docs/screenshots/version_2
#
# Shared verbatim with Conjuguer and Konjugieren — Apple's media requirements are
# app-independent, and this file is deliberately identical in all three repos so a fix
# found in one can be copied without a merge. Keep it that way: if you need something
# Conjugar-specific, put it in the playbook, not here.
#
# Every check corresponds to a real rejection or near-miss in the sibling apps on
# 2026-07-25 (Conjuguer's 2.0 previews were rejected twice — first for wrong dimensions,
# then for non-square pixels); see docs/screenshot-playbook.md and docs/screenshot-plan.md
# for how it applies here.
#
# Conjugar has no app previews yet, so the video half is inert today. It is retained
# rather than stripped: the three repos stay diffable, and a preview will eventually be
# shot for this app too.
#
# Ported 2026-07-26. Conjugar's own docs/screenshots/version_1 bundle fails this script
# 36/36 on the alpha check — that bundle predates the flattening step in
# take_screenshots.sh and must not be uploaded as-is.
#
# Requires: ffprobe, sips (macOS built-in). Screenshot dimension/alpha checks use sips
# so the script works with no third-party image tooling installed.

set -uo pipefail

ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "usage: $(basename "$0") <directory-of-media>" >&2
  exit 2
fi

FAILURES=0
WARNINGS=0
CHECKED_IMAGES=0
CHECKED_VIDEOS=0

# Two severities, and the split is evidence-based rather than a reading of the spec.
#
#   fail() — observed to block an upload, or explicitly forbidden in writing: wrong
#            dimensions, alpha channel, duration outside 15–30 s.
#   warn() — a documented spec deviation that App Store Connect nonetheless accepted.
#            Konjugieren's shipped 1.2 previews carry H.264 Level 5.0/5.1, 125 kbps
#            audio, and a third (timecode) stream, and they went live. Worth cleaning
#            up; not worth blocking a release over.
#
# If a warn-level item ever does block an upload, promote it here and say so in the
# comment — that is the evidence trail this split depends on.
fail() {
  echo "FAIL  $1" >&2
  echo "      $2" >&2
  FAILURES=$((FAILURES + 1))
}

warn() {
  echo "WARN  $1" >&2
  echo "      $2" >&2
  WARNINGS=$((WARNINGS + 1))
}

# Accepted App Store screenshot sizes, portrait and landscape. Sourced from
# https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/
# Re-read that page when Apple adds a display class; a new valid size failing here looks
# exactly like a broken export.
IMAGE_SIZES="
1320x2868 2868x1320
1290x2796 2796x1290
1260x2736 2736x1260
1284x2778 2778x1284
1242x2688 2688x1242
2064x2752 2752x2064
2048x2732 2732x2048
1488x2266 2266x1488
1640x2360 2360x1640
"

# Accepted app-preview sizes. NOT the same as the screenshot sizes above — conflating the
# two is what got all four 2.0 previews rejected.
VIDEO_SIZES="
886x1920 1920x886
1200x1600 1600x1200
1080x1920 1920x1080
900x1200 1200x900
750x1334 1334x750
"

size_ok() {
  local needle="$1" haystack="$2"
  [[ " $(echo "$haystack" | tr '\n' ' ') " == *" $needle "* ]]
}

check_image() {
  local f="$1" w h alpha
  w=$(sips -g pixelWidth "$f" 2>/dev/null | awk '/pixelWidth/{print $2}')
  h=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight/{print $2}')
  alpha=$(sips -g hasAlpha "$f" 2>/dev/null | awk '/hasAlpha/{print $2}')

  if [[ -z "$w" || -z "$h" ]]; then
    fail "$f" "unreadable as an image (sips returned no dimensions)"
    return
  fi

  if ! size_ok "${w}x${h}" "$IMAGE_SIZES"; then
    fail "$f" "dimensions ${w}x${h} are not an accepted App Store screenshot size"
  fi

  # Apple: "Images can't include alpha channels or transparencies." axe screenshot
  # writes RGBA by default, so this is the check that matters most on a fresh sweep.
  if [[ "$alpha" == "yes" ]]; then
    fail "$f" "has an alpha channel; flatten with: magick in.png -background white -alpha remove -alpha off out.png"
  fi

  CHECKED_IMAGES=$((CHECKED_IMAGES + 1))
}

check_video() {
  local f="$1" w h dur level streams vbr abr fps acodec vcodec sar dar

  w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$f" 2>/dev/null)
  h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$f" 2>/dev/null)

  if [[ -z "$w" || -z "$h" ]]; then
    fail "$f" "unreadable as a video (ffprobe found no video stream)"
    return
  fi

  level=$(ffprobe -v error -select_streams v:0 -show_entries stream=level -of csv=p=0 "$f" 2>/dev/null)
  vcodec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$f" 2>/dev/null)
  fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$f" 2>/dev/null)
  acodec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$f" 2>/dev/null)
  abr=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of csv=p=0 "$f" 2>/dev/null)
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null)
  streams=$(ffprobe -v error -show_entries format=nb_streams -of csv=p=0 "$f" 2>/dev/null)

  size_ok "${w}x${h}" "$VIDEO_SIZES" || \
    fail "$f" "dimensions ${w}x${h} are not an accepted app-preview size (iPhone: 886x1920, iPad: 1200x1600) — screenshot sizes are NOT preview sizes"

  # Non-square pixels are the trap that a width×height check alone cannot see. App Store
  # Connect evaluates *display* dimensions, so a file that is 1200x1600 in stored pixels
  # with SAR 2048:2049 presents as 512:683 and is rejected as "dimensions are wrong" —
  # the identical error message a genuinely mis-sized file produces.
  #
  # ffmpeg's `scale=W:-2` causes this: when the computed height needs rounding to an even
  # number, the filter preserves the source display aspect by writing a compensating SAR
  # instead. Adding `setsar=1` after the scale is the fix.
  sar=$(ffprobe -v error -select_streams v:0 -show_entries stream=sample_aspect_ratio -of csv=p=0 "$f" 2>/dev/null)
  if [[ -n "$sar" && "$sar" != "1:1" && "$sar" != "N/A" && "$sar" != "0:1" ]]; then
    dar=$(ffprobe -v error -select_streams v:0 -show_entries stream=display_aspect_ratio -of csv=p=0 "$f" 2>/dev/null)
    fail "$f" "non-square pixels (SAR $sar, DAR ${dar:-?}); stored size ${w}x${h} will not be read as ${w}x${h} — re-encode with ffmpeg -vf 'scale=W:-2,setsar=1,crop=W:H'"
  fi

  [[ "$vcodec" == "h264" || "$vcodec" == "prores" ]] || \
    fail "$f" "video codec is '$vcodec'; App Store previews require H.264 or ProRes 422 HQ"

  # Level is reported ×10 (40 = Level 4.0). Spec caps at High Profile Level 4.0, but
  # Konjugieren shipped 5.0/5.1 previews, so this is advisory.
  if [[ -n "$level" && "$level" != "N/A" ]] && (( level > 40 )); then
    warn "$f" "H.264 level $((level / 10)).$((level % 10)) exceeds the Level 4.0 spec (accepted in practice)"
  fi

  # 15–30 s is a stated hard range, so duration is a blocking check. A naive re-encode
  # of a 30.000 s master produced 30.014 s, and Konjugieren has a 30.015 s file on disk
  # — this is the easiest limit in the pipeline to blow past by accident.
  if [[ -n "$dur" ]]; then
    awk -v d="$dur" 'BEGIN { exit !(d > 30.0) }' && \
      fail "$f" "duration ${dur}s exceeds the 30s maximum; pin it with ffmpeg -frames:v 870 (29.000s)"
    awk -v d="$dur" 'BEGIN { exit !(d < 15.0) }' && \
      fail "$f" "duration ${dur}s is under the 15s minimum"
    awk -v d="$dur" 'BEGIN { exit !(d > 29.5 && d <= 30.0) }' && \
      warn "$f" "duration ${dur}s leaves no rounding margin under the 30s cap; aim for 29s"
  fi

  # A stray timecode/data track survives -map 0:v:0 -map 0:a:0; only -dn removes it.
  if [[ -n "$streams" ]] && (( streams != 2 )); then
    warn "$f" "$streams streams (expected video + audio); drop extras with ffmpeg -dn -sn (accepted in practice)"
  fi

  [[ "$acodec" == "aac" || "$acodec" == "pcm_s16le" || "$acodec" == "pcm_s24le" ]] || \
    fail "$f" "audio codec is '${acodec:-none}'; expected AAC (or PCM for ProRes)"

  if [[ -n "$abr" && "$abr" != "N/A" ]] && (( abr < 240000 )); then
    warn "$f" "audio bit rate $((abr / 1000))kbps is below the 256kbps spec (accepted in practice)"
  fi

  [[ "$fps" == "30/1" || "$fps" == "30000/1001" ]] || \
    fail "$f" "frame rate $fps; App Store previews cap at 30 fps"

  CHECKED_VIDEOS=$((CHECKED_VIDEOS + 1))
}

while IFS= read -r f; do
  case "${f##*.}" in
    png|PNG|jpg|JPG|jpeg|JPEG) check_image "$f" ;;
    mp4|MP4|mov|MOV|m4v|M4V)   check_video "$f" ;;
  esac
done < <(find "$ROOT" -type f \( \
  -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o \
  -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v' \) | sort)

echo
echo "checked $CHECKED_IMAGES image(s) and $CHECKED_VIDEOS video(s) under $ROOT"
echo "$FAILURES blocking, $WARNINGS advisory"

if (( FAILURES > 0 )); then
  echo "$FAILURES blocking problem(s) — do not upload" >&2
  exit 1
fi

if (( CHECKED_IMAGES == 0 && CHECKED_VIDEOS == 0 )); then
  echo "no media found — check the path" >&2
  exit 2
fi

echo "all clear"
