#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="$(basename "$ROOT_DIR")"
OPENAI_CONFIG="$ROOT_DIR/agents/openai.yaml"

mkdir -p "$ROOT_DIR/agents"

if [ -f "$OPENAI_CONFIG" ]; then
    echo ">> Keeping existing agents/openai.yaml"
    exit 0
fi

cat > "$OPENAI_CONFIG" <<EOF
interface:
  display_name: "$PROJECT_NAME"
  short_description: "Work in this Kotlin Multiplatform project"
  default_prompt: "Work in this Kotlin Multiplatform project. Use the Makefile and scripts/ at the repo root as the operational interface. If the repo has a local AGENTS.md, follow it."
EOF

echo ">> Wrote agents/openai.yaml"
