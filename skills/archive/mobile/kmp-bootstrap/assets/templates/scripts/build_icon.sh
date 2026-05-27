#!/usr/bin/env bash
# Generate androidApp/src/main/res/mipmap-*/ic_launcher.png from a 1024x1024 source PNG.
# iOS icons (AppIcon.appiconset) are edited in Xcode — this script only covers Android.
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
IM=$(command -v magick || command -v convert)

read -r W H < <($IM identify -format "%w %h" "$SRC")
if [ "$W" -lt 1024 ] || [ "$H" -lt 1024 ]; then
    echo "Warning: source is ${W}x${H}, expected >=1024x1024" >&2
fi

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RES_ROOT="androidApp/src/main/res"

declare -A SIZES=(
    [mipmap-mdpi]=48
    [mipmap-hdpi]=72
    [mipmap-xhdpi]=96
    [mipmap-xxhdpi]=144
    [mipmap-xxxhdpi]=192
)

for dir in "${!SIZES[@]}"; do
    mkdir -p "$RES_ROOT/$dir"
    "$IM" "$SRC" -resize "${SIZES[$dir]}x${SIZES[$dir]}" "$RES_ROOT/$dir/ic_launcher.png"
    "$IM" "$SRC" -resize "${SIZES[$dir]}x${SIZES[$dir]}" "$RES_ROOT/$dir/ic_launcher_round.png"
    echo "✓ $RES_ROOT/$dir/ic_launcher*.png"
done

mkdir -p androidApp/src/main/play
"$IM" "$SRC" -resize 512x512 androidApp/src/main/play/icon-512.png
echo "✓ Play Store 512px icon: androidApp/src/main/play/icon-512.png"
echo
echo "Note: iOS icons (AppIcon.appiconset) must be added via Xcode."
