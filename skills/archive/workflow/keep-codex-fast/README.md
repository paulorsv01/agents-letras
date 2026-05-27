# Keep Codex Fast

- Source: https://github.com/vibeforge1111/keep-codex-fast
- Status: `SKILL.md`, script, tests, references, and assets are copied from the public source.
- License: MIT (see `LICENSE`).

Backup-first Codex local-state maintenance skill. It inspects sessions, logs, worktrees, and config drift in report-only mode by default, then can back up and archive stale state when explicitly asked.

## Use

```text
Use $keep-codex-fast to inspect my Codex local state and recommend a safe maintenance plan.
```

## Safety Model

- First run is read-only.
- Apply mode backs up before changing local state.
- It archives or moves files instead of permanently deleting chats, logs, or worktrees.
- Important active repo chats should get handoff docs before archiving.
- Recurring automation should be report-only, never mutating.

## Manual Script

```bash
python scripts/keep_codex_fast.py
python scripts/keep_codex_fast.py --details
python scripts/keep_codex_fast.py --backup-only
python scripts/keep_codex_fast.py --apply --archive-older-than-days 10 --worktree-older-than-days 7
```

## Upstream Update

```bash
gh repo clone vibeforge1111/keep-codex-fast /tmp/keep-codex-fast -- --depth 1
cp /tmp/keep-codex-fast/SKILL.md .
cp /tmp/keep-codex-fast/LICENSE .
cp -R /tmp/keep-codex-fast/agents .
cp -R /tmp/keep-codex-fast/scripts .
cp -R /tmp/keep-codex-fast/tests .
cp -R /tmp/keep-codex-fast/references .
cp -R /tmp/keep-codex-fast/assets .
```

Keep this README in the concise local format.
