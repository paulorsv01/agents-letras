# AGENTS.md

## Purpose

- This file is repo-local.
- It should capture the project rules that do not belong in the global agent contract.
- Keep it short, but make it specific enough to stop repeated wrong moves.
- Prefer a compact main file plus a few focused references over a giant handbook.

---

## Scope

- Project: `<project name>`
- Repo owns: `<product / service / app / library / package>`
- Main stack: `<languages, frameworks, runtime>`
- Normal development loop: `<CLI / IDE / dev server / emulator / etc.>`
- Local rules here override global fallback preferences when they are more specific.

---

## Workflow

- Main entrypoint: `<make / bun / pnpm / uv / cargo / xcodebuild / gradle / etc.>`
- Preferred command style: `<example>`
- Use `<tool>` for the normal loop. Do not default to `<other tool>` unless explicitly asked.
- If a task changes the build, release, or operational flow, update the matching scripts/docs in `<paths>`.
- If there is one local source of truth for agent instructions, say it here.

---

## Commands

- `<command>` - `<what it does>`
- `<command>` - `<what it does>`
- `<command>` - `<what it does>`
- `<command>` - `<what it does>`

---

## Source Of Truth

- `<file/path>` owns `<contract, config, metadata, workflow, versioning, etc.>`
- `<file/path>` owns `<contract, config, metadata, workflow, versioning, etc.>`
- `<directory/path>` owns `<operational scripts / adapters / migrations / generated outputs / etc.>`
- `<file/path>` must not be edited directly because `<reason>`
- If a local-only file must never be committed, say it explicitly here.

---

## Architecture

- Request boundary: `<HTTP / RPC / CLI / UI entrypoints>`
- Core domain location: `<path>`
- Data access location: `<path>`
- Integration boundaries: `<path>`
- Business rules belong in `<path>`
- Side effects belong in `<path>`
- Main anti-patterns in this repo: `<what agents often get wrong>`

Examples:
- Keep auth checks in `<path>`, not in `<path>`.
- Use `<service/pattern>` for `<case>`. Do not use `<old pattern>` for new code.
- New screens live in `<path>`. Do not put them in `<path>`.

---

## Decision Tables

### `<Decision name>`

| If | Use |
| --- | --- |
| `<condition>` | `<pattern/tool/path>` |
| `<condition>` | `<pattern/tool/path>` |
| `<condition>` | `<pattern/tool/path>` |

Add only the choices that repeatedly cause wrong code or wasted exploration.

---

## Project Conventions

- Naming: `<module / class / screen / test / file naming rules>`
- Testing: `<what to test first, what test style to prefer, what to avoid>`
- UI: `<design system / component rules / shared primitives>`
- Data: `<schema / migrations / API / contracts>`
- Performance: `<main bottleneck or known trap>`
- Deployment: `<release path / CI expectation / environment model>`

Use this section for repo-specific conventions that should behave like hard local rules, not generic software advice.

---

## Validation

- Smallest relevant validation after code changes: `<command>`
- For `<type of change>`, run `<command>`
- For `<type of change>`, run `<command>`
- For `<type of change>`, run `<command>`

---

## References

- `[<doc name>](<path>)` - `<when to read it>`
- `[<doc name>](<path>)` - `<when to read it>`
- `[<doc name>](<path>)` - `<when to read it>`

Keep references few, explicit, and task-driven.

---

## Maintenance Rules

- Update this file when project workflow, source-of-truth boundaries, or repeated agent mistakes change.
- Do not turn this file into a dump of every architecture note in the repo.
- If a section gets long, move details into a focused reference doc and link it from here.
