#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

./scripts/setup_codex_environment.sh

if [ -d .git ]; then
    git config core.hooksPath .githooks
fi

echo ">> Local setup ready."
