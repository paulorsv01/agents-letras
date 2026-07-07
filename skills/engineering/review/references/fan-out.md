# Fan-Out: Decompositions, Schemas, Barrier

Use subagents only when breadth is real: many files, repeated patterns, multiple ownership areas, or a need for adversarial validation. Cover the whole codebase when the theme is systemic, not just the diff. Quantify coverage (X/Y). Subagents generate candidates; the parent verifies and decides what is real.

Orchestration for scale: discovery (per slice/file) -> dedupe (barrier only when a global view is needed) -> adversarial verification (skeptic pass) -> synthesis.

## Choose One Decomposition

- **Changed-file review:** one agent per changed file or small file group. Best for judging if a change was thoughtful or mechanical.
- **Codebase audit:** one agent per ownership slice (e.g. data, domain, presentation, lifecycle/resources, background work, infra, tests).
- **Review-of-review:** for triaging a batch of external comments (human or automated-reviewer): one agent validates high-severity comments, one hunts false positives/stale items, one checks whether proposed fixes violate boundaries.
- **Flow tracing:** one agent per candidate flow: entrypoint, changed call, state owner, persistence/resource effect, observer.
- **External-fact check:** one agent per library/platform claim, restricted to primary docs or source.

A role-based split is a valid example decomposition for a broad change: intent/regression, security/privacy, performance/reliability, contracts/coverage. Give each reviewer the same scope and intent packet.

## Every Subagent Gets

- exact objective
- read-only permission
- included/excluded paths
- review predicate
- output schema
- instruction to verify, not speculate
- instruction that doubt should lower confidence

## Schemas

Discovery:

```json
{
  "file": "path",
  "line": 123,
  "category": "behavior|state|cleanup|persistence|contract|architecture|test|ui|async|style|ci",
  "severity": "high|medium|low|none",
  "context": "function/call path",
  "evidence": "specific code fact",
  "why": "failure mode or why harmless",
  "suggestedFix": "direction only",
  "verdict": "candidate|confirmed|false-positive|needs-context"
}
```

Flow tracing:

```json
{
  "candidateId": "id",
  "trigger": "user action/job/event/test",
  "changedCode": "file:line/function",
  "callPath": ["entry", "domain/usecase", "data/platform"],
  "contractBefore": "old behavior or caller expectation",
  "contractAfter": "new behavior",
  "stateOrSideEffect": "what persists or is observed",
  "observer": "UI/user/job/db/log/CI/none",
  "reachability": "reachable|not-reachable|needs-context",
  "evidence": "specific local facts",
  "verdict": "confirmed|false-positive|needs-context"
}
```

Changed-file quality:

```json
{
  "file": "path",
  "fileVerdict": "ok|suspicious|problematic",
  "mechanicalSmell": true,
  "changeVerdicts": [
    {
      "line": 123,
      "verdict": "correct-thoughtful|insufficient|regression|redundant|unnecessary",
      "evidence": "specific code fact"
    }
  ]
}
```

## Subagent Prompt Skeleton

```text
Read-only. Do not fix or post.
Objective: <narrow scope>.
Review predicate: <real finding / not finding / severity>.
Included paths: <paths>.
Excluded paths: <paths>.
For every candidate, provide a concrete trigger -> code -> observer flow.
Do not promote a visual pattern to a finding without a reachable call path.
If unsure, mark needs-context or false-positive.
Return only the requested JSON schema.
```

## Barrier (Phase 6)

Do not deep-review raw subagent output.

Normalize: paths, line numbers, categories, duplicate keys, severity labels.

Dedupe keys:

- audit: `file:line:category`
- changed-file quality: `file:function`
- review comment: `thread-id` or `file:line:claim`

Discard:

- malformed output
- no evidence
- duplicate behavior already represented better elsewhere
- low-value candidates that cannot affect the final decision
- prose not tied to a file, path, command, or contract

## Skeptic Pass (Phase 7 support)

For adversarial verification, spawn skeptics separate from generators. A skeptic gets one candidate (or a small batch), the same scope and intent packet, and a single objective: refute the candidate with code evidence — a guard the generator missed, an unreachable trigger, a caller contract that excludes the scenario, an existing test that already covers it.

Rules:

- Do not pass the skeptic the generator's reasoning beyond the candidate row itself; independence is the point.
- Skeptic verdicts: `refuted` (with the code reason), `stands` (with the strongest surviving evidence), `needs-context`.
- The parent breaks generator/skeptic disagreement by reading the code path itself. Neither subagent's prose settles it.
- A `stands` verdict does not auto-promote the candidate; it still goes through the parent verification checklist in `references/method.md`.
