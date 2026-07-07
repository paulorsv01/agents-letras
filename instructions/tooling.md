---
summary: "Small catalog of local tools agents should know about without hardcoding broad tool preferences."
read_when:
  - Choosing a local helper for GitHub, skills, docs, or Apple builds.
  - Updating AGENTS.md tool rules or deciding whether a workflow deserves a skill.
---

# Tooling

Use repo-local tooling first. This file is a catalog, not a global preference list.

## Core

- `rg`: default code search when available.
- `gh`: GitHub CLI for issues, PRs, checks, releases, comments, and repo metadata.
- `gx`: local account-routing wrapper around GitHub remotes and SSH profiles.
- `skills`: manages the categorized `skills/` source tree and the generated flat runtime symlinks.
- `uv`: preferred Python helper runner when the repo does not already define another Python workflow.

## Agents Repo

- `./install.sh`: applies the whole local setup.
- `skills validate --plain`: validates active skill frontmatter, metadata, duplicate names, and quality heuristics.
- `scripts/validate-docs.py`: validates docs frontmatter.
- `scripts/docs-list.py`: lists docs with `summary` and `read_when` hints.

## Review And Build Helpers

- `xcodebuildmcp`: preferred Apple build/run/debug path when working on iOS/macOS projects.

Avoid adding tools here just because they are installed. Add only tools that agents should deliberately choose.
