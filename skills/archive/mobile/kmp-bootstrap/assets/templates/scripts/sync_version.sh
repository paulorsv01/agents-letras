#!/usr/bin/env bash
# One-way sync: version.env → iosApp/Configuration/Config.xcconfig.
# Updates MARKETING_VERSION and CURRENT_PROJECT_VERSION in place.
# Usage: sync_version.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

[ -f version.env ] || { echo "version.env missing" >&2; exit 1; }
XCCONFIG=iosApp/Configuration/Config.xcconfig
[ -f "$XCCONFIG" ] || { echo "$XCCONFIG missing" >&2; exit 1; }

# shellcheck disable=SC1091
. version.env
: "${VERSION_NAME:?}" "${VERSION_CODE:?}"
BUILD_NUMBER="${BUILD_NUMBER:-$VERSION_CODE}"

sed -i '' \
    -e "s/^MARKETING_VERSION=.*/MARKETING_VERSION=$VERSION_NAME/" \
    -e "s/^CURRENT_PROJECT_VERSION=.*/CURRENT_PROJECT_VERSION=$BUILD_NUMBER/" \
    "$XCCONFIG"

echo "✓ Synced $XCCONFIG:"
grep -E '^(MARKETING_VERSION|CURRENT_PROJECT_VERSION)=' "$XCCONFIG"
