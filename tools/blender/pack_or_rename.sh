#!/usr/bin/env bash
#
# pack_or_rename.sh — turn render_sprites.py output into Xcode-ready assets.
#
# render_sprites.py writes zero-padded frames:
#     tools/blender/renders/<actor>_<action>/<action>_0001.png … _000N.png
#
# This script either:
#   (rename) copies them to the flipbook naming the game expects —
#            <actor>_<action>_1.png … _N.png (1-based, matches playerFrame) — or
#   (sheet)  packs them into one horizontal sprite sheet via ImageMagick montage.
#
# Usage:
#   tools/blender/pack_or_rename.sh rename [actor] [action] [srcdir] [outdir]
#   tools/blender/pack_or_rename.sh sheet  [actor] [action] [srcdir] [outdir] [cell]
#
# Defaults: actor=dancer action=walk
#           srcdir=tools/blender/renders/<actor>_<action>
#           outdir=tools/blender/dist
#           cell=96   (sheet cell size in px)
#
# Examples:
#   tools/blender/pack_or_rename.sh rename dancer walk
#   tools/blender/pack_or_rename.sh sheet  dancer walk "" "" 96
#
set -euo pipefail

MODE="${1:-rename}"
ACTOR="${2:-dancer}"
ACTION="${3:-walk}"
SRC="${4:-tools/blender/renders/${ACTOR}_${ACTION}}"
OUT="${5:-tools/blender/dist}"
CELL="${6:-96}"

if [[ ! -d "$SRC" ]]; then
  echo "error: source dir not found: $SRC" >&2
  exit 1
fi

# Collect frames in sorted (zero-padded) order.
shopt -s nullglob
frames=("$SRC/${ACTION}_"*.png)
shopt -u nullglob
if [[ ${#frames[@]} -eq 0 ]]; then
  echo "error: no ${ACTION}_*.png frames in $SRC" >&2
  exit 1
fi
IFS=$'\n' frames=($(sort <<<"${frames[*]}")); unset IFS

mkdir -p "$OUT"

case "$MODE" in
  rename)
    # Crop every frame to ONE common bounding box — the union of non-transparent
    # content across all frames — so the sprite is tightly the character, framed
    # identically each frame (no drift), instead of a big mostly-empty square.
    tmp_union="$(mktemp -t union_XXXX).png"
    magick "${frames[@]}" -background none -layers merge "$tmp_union"
    box="$(magick "$tmp_union" -trim -format '%wx%h%O' info:)"   # e.g. 109x169+42+12
    rm -f "$tmp_union"
    echo "common crop box: $box"
    i=1
    for f in "${frames[@]}"; do
      dest="$OUT/${ACTOR}_${ACTION}_${i}.png"
      magick "$f" -crop "$box" +repage "$dest"
      echo "  $f -> $dest ($box)"
      i=$((i + 1))
    done
    echo "cropped+renamed ${#frames[@]} frames -> $OUT/${ACTOR}_${ACTION}_1..$((i - 1)).png"
    ;;
  sheet)
    n=${#frames[@]}
    sheet="$OUT/${ACTOR}_${ACTION}_sheet.png"
    magick montage "${frames[@]}" \
      -tile "${n}x1" -geometry "${CELL}x${CELL}+0+0" \
      -background transparent -filter Catrom "$sheet"
    echo "packed $n frames -> $sheet (${n}x1 @ ${CELL}px cells)"
    ;;
  *)
    echo "error: unknown mode '$MODE' (want: rename | sheet)" >&2
    exit 1
    ;;
esac
