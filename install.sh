#!/bin/zsh
set -euo pipefail

AGENTS="$(cd "$(dirname "$0")" && pwd)"
AGENTS_HOME="$HOME/.agents"
SKILLS_SYNCED=1
path=("$HOME/.local/bin" "$HOME/.local/share/mise/shims" "/opt/homebrew/bin" $path)
export PATH

# Create or replace a symlink target. If a real file already exists, keep a
# timestamped backup so the installer is reversible.
link() {
  local source="$1" target="$2"

  [[ -e "$source" ]] || { echo "  [skip] $target (missing source $source)" >&2; return 0; }

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    echo "  [ok] $target"
    return 0
  fi

  if [[ -e "$target" ]]; then
    local backup="$target.bak.$(date +%s)"
    mv "$target" "$backup"
    echo "  [backup] $target → $backup"
  fi

  ln -sf "$source" "$target"
  echo "  [link] $target → $source"
}

sync_skills() {
  if ! command -v skills &>/dev/null; then
    echo "skills CLI not found; skipping skills sync. Install it later, or copy skills manually." >&2
    SKILLS_SYNCED=0
    return 0
  fi

  skills --config "$AGENTS/skills.toml" sync --apply
  link "$AGENTS/.runtime/skills" "$AGENTS_HOME/skills"
}

configure_git_hooks() {
  if git -C "$AGENTS" rev-parse --is-inside-work-tree &>/dev/null; then
    git -C "$AGENTS" config core.hooksPath .githooks
    echo "  [git] core.hooksPath = .githooks"
  fi
}

echo "agents installer"
echo "================"

# Hub links. Tools point to ~/.agents so the repo can move later without
# rewriting every tool-specific config path.
echo "\n~/.agents/"
link "$AGENTS/AGENTS.md"     "$AGENTS_HOME/AGENTS.md"
link "$AGENTS/agents"        "$AGENTS_HOME/agents"
link "$AGENTS/instructions"  "$AGENTS_HOME/instructions"
link "$AGENTS/claude"        "$AGENTS_HOME/claude"

echo "\nskills"
link "$AGENTS/skills.toml" "$HOME/.config/skills/skills.toml"
sync_skills

# Tool configs that consume the hub. Machine-specific state stays outside the
# repo.
echo "\ntool configs"
link "$AGENTS_HOME/claude/settings.json" "$HOME/.claude/settings.json"
# ~/.claude.json is Claude Code's live mutable state (identity, project trust,
# history). Seed it once instead of symlinking so machine-specific data never
# lands in the tracked baseline.
[[ -e "$HOME/.claude.json" ]] || cp "$AGENTS_HOME/claude/claude.json" "$HOME/.claude.json"
link "$AGENTS_HOME/AGENTS.md"           "$HOME/.claude/CLAUDE.md"
link "$AGENTS_HOME/agents"              "$HOME/.claude/agents"
if (( SKILLS_SYNCED )); then
  link "$AGENTS_HOME/skills"            "$HOME/.claude/skills"
fi

echo "\ngit hooks"
configure_git_hooks

echo "\nDone."
