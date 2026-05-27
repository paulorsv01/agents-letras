# shadcn CLI

Always use the project's package runner:

- `npx shadcn@latest`
- `pnpm dlx shadcn@latest`
- `bunx --bun shadcn@latest`

## First command

Run `shadcn info` first.

It tells you:

- framework
- aliases
- `base` vs `radix`
- Tailwind version
- icon library
- resolved file paths

## Commands to prefer

- inspect project: `shadcn info`
- search registry: `shadcn search`
- get docs/examples URLs: `shadcn docs <component>`
- preview install/update: `shadcn add <component> --dry-run`
- inspect diff: `shadcn add <component> --diff [file]`
- inspect exact generated file: `shadcn add <component> --view [file]`

## Important rules

- do not fetch raw component files manually
- do not use `--overwrite` unless the user explicitly wants that
- do not guess a registry if the user did not specify one
- when switching presets, ask whether to reinstall, merge, or skip
