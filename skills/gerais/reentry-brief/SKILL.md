---
name: reentry-brief
description: Reconstruct the active slice of work in the current repo or thread before continuing. Use when the user says continue, update, keep going, asks what they were working on, or resumes an older task where context may be stale.
---

# Reentry Brief

Rebuild working context before acting.

## Step 1: Gather Current State

Start from the smallest reliable sources:

- current `cwd`, branch, and `git status --short`
- root-level `handoff.md`, if present
- unstaged files and their relevant diffs
- staged files and their relevant diffs, if any
- recent commits only when there is no useful handoff or worktree diff
- local instructions and docs near the touched area
- the current thread's last agreed slice, constraints, and blockers

Do not require `handoff.md`. Re-entry should still work from the current worktree when no handoff exists.

Do not trawl broad history if the repo state, `handoff.md`, and unstaged files already narrow the task.

Treat `handoff.md` as a temporary bridge, not a project TODO. If it is present and you use it to reconstruct the slice, remove it after the brief is captured unless the user explicitly asks to keep it.

## Step 2: Infer the Active Slice

Turn the evidence into one compact working brief:

- current slice
- what should stay out of scope
- what is already done
- next safe step
- which files are carrying the current state

If there are multiple plausible slices, present the 2-3 most likely options briefly and stop.

## Step 3: Use the Brief

If the user asked to resume or continue:

- state the inferred scope in one sentence
- continue the work from that slice
- delete the consumed `handoff.md` once it is no longer needed for re-entry

If the user asked what they were working on:

- return the brief without editing anything
- mention whether a `handoff.md` exists
- summarize the unstaged files that shaped the brief

## Output Shape

Keep it short:

- `Current slice`
- `Constraints`
- `Evidence`
- `Next safe step`
- `Open question`, only if one blocks confident action
