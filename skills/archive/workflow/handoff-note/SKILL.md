---
name: handoff-note
description: Create or refresh a temporary root-level handoff.md file that captures the current slice, what is done, the next safe step, blockers, and verification status. Use when the user is leaving, pausing, or explicitly asks to hand off work.
---

# Handoff Note

Create or refresh `handoff.md` at the repo root when the user is leaving or pausing.

`handoff.md` is not a project TODO, backlog, or durable documentation. It is a temporary bridge for the next session. The re-entry flow should consume it and remove it after it has been used.

## Step 1: Gather The Minimum Facts

Collect:

- current branch and `git status --short`
- the current slice of work
- what changed
- what was verified
- next safe step
- blockers or assumptions

Use the current thread and repo state. Do not invent progress.

## Step 2: Write `handoff.md`

Use this structure:

```md
# Handoff

## Current Slice

## Done

## Next Safe Step

## Blockers / Assumptions

## Verification

## Relevant Files
```

## Rules

- create `handoff.md` only for session handoff, not as a place to track project work
- keep it short and factual
- overwrite stale narrative instead of appending a diary
- prefer concrete file paths and commands over vague prose
- if the work is fully done, say so clearly
- if no verification ran, state that explicitly

## Relevant Files

List only the files that matter for re-entry, not every touched file in the repo.
