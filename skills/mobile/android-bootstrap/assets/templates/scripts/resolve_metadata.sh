#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUILD="$ROOT_DIR/app/build.gradle.kts"
VERSION_FILE="$ROOT_DIR/version.env"

application_id=$(sed -nE 's/^[[:space:]]*applicationId = "([^"]+)".*/\1/p' "$APP_BUILD" | head -n 1)
version_code=$(sed -nE 's/^VERSION_CODE=(.+)$/\1/p' "$VERSION_FILE" | head -n 1)
version_name=$(sed -nE 's/^VERSION_NAME=(.+)$/\1/p' "$VERSION_FILE" | head -n 1)

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
    printf '%-16s %s\n' "applicationId" "$application_id"
    printf '%-16s %s\n' "versionCode" "$version_code"
    printf '%-16s %s\n' "versionName" "$version_name"
    ;;
  *)
    echo "Usage: resolve_metadata.sh [applicationId|versionCode|versionName|all]" >&2
    exit 2
    ;;
esac
