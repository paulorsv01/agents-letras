---
name: canonicalize-tailwind
description: Sort, normalize, deduplicate, and resolve conflicting Tailwind utility classes.
---

# Canonicalize Tailwind

Use this when the user wants to clean up, canonicalize, or normalize Tailwind class lists.

## Activation

### Use For

- cleaning up Tailwind classes
- canonicalizing Tailwind utility lists
- sorting, normalizing, or deduplicating Tailwind classes
- resolving conflicting Tailwind utilities in class strings

### Do Not Use For

- new design or layout work
- component extraction or code organization
- visual changes rather than class-list cleanup

## Load First

- No companion modules are required.

## Progress Updates

Keep the user informed so longer runs do not look stuck.

- One-line status update before each major phase.
- Concrete and lightweight: what you are doing now, not verbose logs.

## Workflow

1. Identify Tailwind class strings in the requested files or components.
2. Locate the project's CSS entry (the file containing `@import "tailwindcss"` — e.g. `rg -l '@import "tailwindcss"' --glob '*.css'`) and always pass it via `--css`; only fall back to the default design system when the project has no custom theme. Without this, theme-defined utilities are missed (e.g. `text-[#ff0000]` stays arbitrary instead of canonicalizing to a themed `text-brand`).
3. Canonicalize class strings with `npx @tailwindcss/cli canonicalize`.
4. Apply changed class strings back to the source.
5. Run the project's formatter or relevant checks when available.

## Requirements

- Run from the project root with Tailwind CSS v4 installed. Outside the project's dependency tree the command fails with `Can't resolve 'tailwindcss'`.
- The `canonicalize` subcommand needs `@tailwindcss/cli` 4.3+. If the project pins an older 4.x CLI, `npx` fails with `Invalid command: canonicalize` — use `npx @tailwindcss/cli@latest` instead.
- If the project is on Tailwind v3, stop and tell the user this skill does not apply.

## Commands

`npx @tailwindcss/cli canonicalize` cleans up Tailwind class lists — collapses shorthands (`mt-2 mr-2 mb-2 ml-2` → `m-2`), resolves overrides (`py-3 p-1 px-3` → `p-3`), canonicalizes arbitrary values to named utilities, and sorts classes. Pass `--css path/to/input.css` to respect the project's custom theme (see Workflow step 2).

### Single class string

```sh
npx @tailwindcss/cli canonicalize "mt-2 mr-2 mb-2 ml-2"
# m-2
```

### Multiple class strings

Positional args, each returned on its own line:

```sh
npx @tailwindcss/cli canonicalize "py-3 p-1 px-3" "mt-2 mr-2 mb-2 ml-2"
# p-3
# m-2
```

### Stdin

One class string per line (`printf` is portable; `echo` does not interpret `\n` under bash/sh):

```sh
printf 'py-3 p-1 px-3\nmt-2 mr-2 mb-2 ml-2\n' | npx @tailwindcss/cli canonicalize
# p-3
# m-2
```

### JSON output

`--format json` or `--format jsonl` for structured output with `input`/`output`/`changed` fields:

```sh
npx @tailwindcss/cli canonicalize --format json "py-3 p-1 px-3"
# [{ "input": "py-3 p-1 px-3", "output": "p-3", "changed": true }]
```

### Streaming

`--stream` processes stdin line-by-line without buffering:

```sh
npx @tailwindcss/cli canonicalize --stream
```

## Rules

- Only canonicalize complete static class strings — conflict resolution assumes the string is the element's full class list.
- Leave interpolated or conditionally-composed fragments alone (template literals, `clsx`/`cva`/`cn` branches). If you must touch them, canonicalize each static fragment for sorting/shorthand only, and never merge conflicts across fragments combined at runtime — doing so can change override semantics or drop a class another branch relies on.

## Verify

- Review the `git diff` of touched files to confirm class strings still express the same visual intent.
- For bulk runs, use `--format json`/`jsonl` and inspect entries with `"changed": true`.
- Run the project's build, lint, typecheck, or formatting commands when available.
