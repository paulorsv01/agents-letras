#!/usr/bin/env bash
# Sign an existing release AAB using credentials in .signing.env.
# Typically you don't call this directly — `make release` uses the Gradle signingConfig.
# Use this to sign an externally-built AAB, or to re-sign with a different key.
#
# Usage: sign_release.sh [path-to-app-release.aab]

set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

AAB="${1:-app/build/outputs/bundle/release/app-release.aab}"
if [ ! -f "$AAB" ]; then
    echo "AAB not found: $AAB" >&2
    echo "Build one with: ./gradlew bundleRelease" >&2
    exit 1
fi

SIGNING_ENV=.signing.env
if [ ! -f "$SIGNING_ENV" ]; then
    echo "Missing $SIGNING_ENV. Run scripts/setup_signing.sh first." >&2
    exit 1
fi
# shellcheck disable=SC1090
. "$SIGNING_ENV"
: "${KEYSTORE_PATH:?}" "${KEYSTORE_PASSWORD:?}" "${KEY_ALIAS:?}" "${KEY_PASSWORD:?}"

if ! command -v jarsigner >/dev/null 2>&1; then
    echo "Missing 'jarsigner' — install a JDK." >&2
    exit 1
fi

echo ">> Signing $AAB with alias=$KEY_ALIAS"
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
    -keystore "$KEYSTORE_PATH" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    "$AAB" "$KEY_ALIAS" >/dev/null

echo ">> Verifying signature"
jarsigner -verify "$AAB" | tail -3
echo "✓ Signed: $AAB"
