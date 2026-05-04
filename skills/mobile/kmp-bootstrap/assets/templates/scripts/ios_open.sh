#!/usr/bin/env bash
# Open iOS workspace (or project) in Xcode.
# Usage: ios_open.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ -d iosApp/iosApp.xcworkspace ]; then
    open iosApp/iosApp.xcworkspace
elif [ -d iosApp/iosApp.xcodeproj ]; then
    open iosApp/iosApp.xcodeproj
else
    echo "No Xcode workspace/project found at iosApp/." >&2
    exit 1
fi
