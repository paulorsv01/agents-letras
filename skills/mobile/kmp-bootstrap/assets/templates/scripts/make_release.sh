#!/usr/bin/env bash
# End-to-end KMP release: bundleRelease (Android) + XCFramework (iOS) + gh release create (both artifacts).
# Usage: make_release.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || { echo "Not a git repo." >&2; exit 1; })"

command -v gh >/dev/null || { echo "Missing 'gh' CLI." >&2; exit 1; }
command -v jarsigner >/dev/null || { echo "Missing 'jarsigner'." >&2; exit 1; }
[ -f version.env ] || { echo "version.env missing." >&2; exit 1; }
[ -f .signing.env ] || { echo ".signing.env missing. Run scripts/setup_signing.sh." >&2; exit 1; }

# shellcheck disable=SC1091
. version.env
: "${VERSION_NAME:?}" "${VERSION_CODE:?}"
TAG="v${VERSION_NAME}"

if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree not clean. Commit or stash first." >&2
    exit 1
fi
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    echo "Tag $TAG already exists. Bump VERSION_NAME." >&2
    exit 1
fi

# --- build ---------------------------------------------------------
echo ">> Building Android AAB (versionCode=$VERSION_CODE, versionName=$VERSION_NAME)"
./gradlew clean :androidApp:bundleRelease

echo ">> Syncing version to iOS Config.xcconfig"
scripts/sync_version.sh

echo ">> Building release XCFramework for :shared"
scripts/build_xcframework.sh

AAB=androidApp/build/outputs/bundle/release/androidApp-release.aab
XCF=shared/build/XCFrameworks/release/shared.xcframework
[ -f "$AAB" ] || { echo "Expected $AAB" >&2; exit 1; }
[ -d "$XCF" ] || { echo "Expected $XCF" >&2; exit 1; }

# --- verify signing (Android) -------------------------------------
echo ">> Verifying AAB signature"
jarsigner -verify "$AAB" | tail -3

# --- zip XCFramework for gh upload --------------------------------
XCF_ZIP="$XCF.zip"
rm -f "$XCF_ZIP"
(cd "$(dirname "$XCF")" && zip -rq "$(basename "$XCF").zip" "$(basename "$XCF")")

# --- tag + release ------------------------------------------------
echo ">> Tagging $TAG"
git tag -a "$TAG" -m "Release $VERSION_NAME (code $VERSION_CODE)"
git push origin "$TAG"

echo ">> Creating GitHub release"
gh release create "$TAG" \
    "$AAB#Android AAB" \
    "$XCF_ZIP#iOS XCFramework" \
    --title "$VERSION_NAME" \
    --generate-notes

echo
echo "✓ Release $TAG published."
echo "  AAB:         $AAB"
echo "  XCFramework: $XCF_ZIP"
echo "  Play Console: https://play.google.com/console"
