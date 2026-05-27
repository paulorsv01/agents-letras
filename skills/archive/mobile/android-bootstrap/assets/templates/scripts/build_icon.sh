#!/usr/bin/env bash
# Generate app/src/main/res/mipmap-*/ic_launcher.png from a 1024x1024 source PNG.
# Uses ImageMagick. Covers standard (square) launcher densities.
# For adaptive icons, use ic_launcher_foreground/ic_launcher_background XML — this script covers the legacy raster.
#
# Usage: build_icon.sh <source-1024.png>

set -euo pipefail

SRC="${1:-}"
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
    echo "Usage: build_icon.sh <source-1024.png>" >&2
    exit 1
fi
if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
    echo "ImageMagick not installed. brew install imagemagick" >&2
    exit 1
fi

# Pick whichever CLI name is present (magick is v7+, convert is v6).
IM=$(command -v magick || command -v convert)

# Verify dimensions
read -r W H < <($IM identify -format "%w %h" "$SRC")
if [ "$W" -lt 1024 ] || [ "$H" -lt 1024 ]; then
    echo "Warning: source is ${W}x${H}, expected >=1024x1024" >&2
fi

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RES_ROOT="app/src/main/res"

declare -A SIZES=(
    [mipmap-mdpi]=48
    [mipmap-hdpi]=72
    [mipmap-xhdpi]=96
    [mipmap-xxhdpi]=144
    [mipmap-xxxhdpi]=192
)

for dir in "${!SIZES[@]}"; do
    mkdir -p "$RES_ROOT/$dir"
    OUT="$RES_ROOT/$dir/ic_launcher.png"
    "$IM" "$SRC" -resize "${SIZES[$dir]}x${SIZES[$dir]}" "$OUT"
    echo "✓ $OUT (${SIZES[$dir]}px)"
done

# Round variant (same sizes, Google-recommended naming)
for dir in "${!SIZES[@]}"; do
    OUT="$RES_ROOT/$dir/ic_launcher_round.png"
    "$IM" "$SRC" -resize "${SIZES[$dir]}x${SIZES[$dir]}" "$OUT"
done
echo "✓ Round variants written."

# Play Store icon (512px)
mkdir -p "$RES_ROOT/../play"
"$IM" "$SRC" -resize 512x512 "$RES_ROOT/../play/icon-512.png"
echo "✓ Play Store 512px icon: app/src/main/play/icon-512.png"
