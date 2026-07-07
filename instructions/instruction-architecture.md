---
summary: "Where guidance belongs: AGENTS.md, skills, docs, rules, or repo-local instructions."
read_when:
  - Moving guidance out of AGENTS.md.
  - Deciding whether something should become a skill, doc, rule, or local repo instruction.
---

# Instruction Architecture

This repo separates agent guidance by how often it should load and how concrete it is.

## AGENTS.md

Use `AGENTS.md` for rules that should affect nearly every task:

- safety and destructive-action boundaries
- communication preferences
- default execution discipline
- Git and GitHub guardrails
- security constraints
- where to find deeper docs

Keep it short. Agents load AGENTS files before work starts, so every extra paragraph competes with repo code and the actual task.

## Skills

Use skills for reusable workflows with a recognizable trigger:

- reviewing a PR
- auditing a codebase for an improvement plan
- validating a finished change
- using a CLI with local conventions
- debugging a specific platform or toolchain

Skill descriptions are routing text. Keep them short and front-load trigger words. Put detailed workflow steps in `SKILL.md`, and move long references to `references/`.

## Instructions

Use `instructions/` for the long-form behavioral defaults behind the short AGENTS.md rules — guidance that shapes how the agent works on any task:

- engineering principles
- Git and GitHub conventions
- tooling choices
- this instruction-architecture map

These are symlinked to `~/.agents/instructions/` and referenced by absolute path from AGENTS.md, so the agent can read them from any repo. Keep critical rules short in AGENTS.md and put the rationale here.

## Docs

Use `docs/` for documentation of this repo itself — its structure, install flow, and layout:

- path layout
- full repo reference

Repo docs are not symlinked and not referenced from AGENTS.md. They matter only when working inside this repo. Do not expect agents to discover every doc automatically.

## Where A New Instruction Goes

- Always relevant and safety-critical: `AGENTS.md`
- Repeated task with a clear trigger: skill
- Long-form behavioral rationale: `instructions/`
- Documentation about this repo itself: `docs/`
- Project-specific source of truth: local repo `AGENTS.md`
