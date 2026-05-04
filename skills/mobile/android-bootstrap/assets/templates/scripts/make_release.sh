#!/usr/bin/env bash
# End-to-end release: bundleRelease + verify + git tag + gh release create (AAB).
# Usage: make_release.sh

set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || { echo "Not a git repo." >&2; exit 1; })"

# --- preconditions --------------------------------------------------
command -v gh >/dev/null || { echo "Missing 'gh' CLI." >&2; exit 1; }
command -v jarsigner >/dev/null || { echo "Missing 'jarsigner'." >&2; exit 1; }
[ -f version.env ] || { echo "version.env missing." >&2; exit 1; }
[ -f .signing.env ] || { echo ".signing.env missing. Run scripts/setup_signing.sh." >&2; exit 1; }

# shellcheck disable=SC1091
. version.env
: "${VERSION_NAME:?}" "${VERSION_CODE:?}"
TAG="v${VERSION_NAME}"

# Clean git tree — releases must be reproducible.
if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree not clean. Commit or stash before releasing." >&2
    exit 1
fi

# Tag must not exist.
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    echo "Tag $TAG already exists. Bump VERSION_NAME in version.env." >&2
    exit 1
fi

# --- build ----------------------------------------------------------
echo ">> Building release AAB (versionCode=$VERSION_CODE, versionName=$VERSION_NAME)"
./gradlew clean bundleRelease

AAB=app/build/outputs/bundle/release/app-release.aab
[ -f "$AAB" ] || { echo "Expected $AAB — Gradle task did not produce it." >&2; exit 1; }

# --- verify signing -------------------------------------------------
echo ">> Verifying signature"
jarsigner -verify "$AAB" | tail -3

# --- tag + release --------------------------------------------------
echo ">> Tagging $TAG"
git tag -a "$TAG" -m "Release $VERSION_NAME (code $VERSION_CODE)"
git push origin "$TAG"

echo ">> Creating GitHub release"
gh release create "$TAG" "$AAB" \
    --title "$VERSION_NAME" \
    --generate-notes

echo
echo "✓ Release $TAG published."
echo "  AAB: $AAB"
echo "  Upload to Play Console: https://play.google.com/console"
