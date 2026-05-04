#!/usr/bin/env bash
# Build a release XCFramework for the :shared module.
# Output: shared/build/XCFrameworks/release/shared.xcframework
#
# Usage: build_xcframework.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo ">> Building release XCFramework for :shared"
./gradlew :shared:assembleSharedReleaseXCFramework

OUT=shared/build/XCFrameworks/release/shared.xcframework
if [ ! -d "$OUT" ]; then
    # Fall back to aggregate task name some Gradle versions use.
    ./gradlew :shared:assembleXCFramework
    OUT=shared/build/XCFrameworks/release/shared.xcframework
fi

[ -d "$OUT" ] || { echo "XCFramework not found at $OUT after build." >&2; exit 1; }
echo "✓ $OUT"
du -sh "$OUT"
