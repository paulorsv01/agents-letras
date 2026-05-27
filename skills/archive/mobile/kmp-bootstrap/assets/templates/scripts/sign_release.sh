#!/usr/bin/env bash
# Sign an existing androidApp release AAB using credentials in .signing.env.
# Usage: sign_release.sh [path-to-androidApp-release.aab]

set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

AAB="${1:-androidApp/build/outputs/bundle/release/androidApp-release.aab}"
if [ ! -f "$AAB" ]; then
    echo "AAB not found: $AAB" >&2
    echo "Build one with: ./gradlew :androidApp:bundleRelease" >&2
    exit 1
fi

SIGNING_ENV=.signing.env
[ -f "$SIGNING_ENV" ] || { echo "Missing $SIGNING_ENV. Run scripts/setup_signing.sh." >&2; exit 1; }
# shellcheck disable=SC1090
. "$SIGNING_ENV"
: "${KEYSTORE_PATH:?}" "${KEYSTORE_PASSWORD:?}" "${KEY_ALIAS:?}" "${KEY_PASSWORD:?}"

command -v jarsigner >/dev/null || { echo "Missing 'jarsigner'." >&2; exit 1; }

echo ">> Signing $AAB with alias=$KEY_ALIAS"
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
    -keystore "$KEYSTORE_PATH" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    "$AAB" "$KEY_ALIAS" >/dev/null

jarsigner -verify "$AAB" | tail -3
echo "✓ Signed: $AAB"
