#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_BUILD="$ROOT_DIR/androidApp/build.gradle.kts"
VERSION_FILE="$ROOT_DIR/version.env"
IOS_CONFIG="$ROOT_DIR/iosApp/Configuration/Config.xcconfig"

application_id=$(sed -nE 's/^[[:space:]]*applicationId = "([^"]+)".*/\1/p' "$ANDROID_BUILD" | head -n 1)
version_code=$(sed -nE 's/^VERSION_CODE=(.+)$/\1/p' "$VERSION_FILE" | head -n 1)
version_name=$(sed -nE 's/^VERSION_NAME=(.+)$/\1/p' "$VERSION_FILE" | head -n 1)
ios_bundle_id=""
ios_marketing_version=""
ios_project_version=""

if [ -f "$IOS_CONFIG" ]; then
    ios_bundle_id=$(sed -nE 's/^BUNDLE_ID=(.+)$/\1/p' "$IOS_CONFIG" | head -n 1)
    ios_marketing_version=$(sed -nE 's/^MARKETING_VERSION=(.+)$/\1/p' "$IOS_CONFIG" | head -n 1)
    ios_project_version=$(sed -nE 's/^CURRENT_PROJECT_VERSION=(.+)$/\1/p' "$IOS_CONFIG" | head -n 1)
fi

case "${1:-all}" in
    applicationId)
        printf '%s\n' "$application_id"
        ;;
    versionCode)
        printf '%s\n' "$version_code"
        ;;
    versionName)
        printf '%s\n' "$version_name"
        ;;
    all)
        printf 'android %-16s %s\n' "applicationId" "$application_id"
        printf 'android %-16s %s\n' "versionCode" "$version_code"
        printf 'android %-16s %s\n' "versionName" "$version_name"
        if [ -f "$IOS_CONFIG" ]; then
            printf 'ios     %-16s %s\n' "bundleId" "$ios_bundle_id"
            printf 'ios     %-16s %s\n' "marketingVersion" "$ios_marketing_version"
            printf 'ios     %-16s %s\n' "projectVersion" "$ios_project_version"
        fi
        ;;
    *)
        echo "Usage: resolve_metadata.sh [applicationId|versionCode|versionName|all]" >&2
        exit 2
        ;;
esac
