#!/usr/bin/env bash
# List available iOS simulators.
# Usage: ios_list.sh [os-filter]   # e.g. ios_list.sh "iOS 18"

set -euo pipefail

FILTER="${1:-iOS}"
echo ">> Available simulators ($FILTER):"
xcrun simctl list devices available | awk -v f="$FILTER" '
  /^-- / { show = ($0 ~ f) }
  show && /\([A-F0-9-]+\)/ { print }
'
