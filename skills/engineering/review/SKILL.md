---
name: review
description: "Single review entrypoint: diffs, PRs, issues, CI failures, comments, branch audits, review-of-review, simplification, and quality audits. Evidence-based with claim ledger, fan-out, and adversarial verification."
---

# Review

One skill for all review work. Three things live here:

1. **Practical review** — PR/issue/branch/commit/diff/CI/comments with cause, best fix, proof, risk.
2. **Rigorous evidence-based flow** — scope gate, claim ledger, fan-out, adversarial verification, synthesis. For review-of-review, triage of automated-reviewer comments, branch audits, systemic questions.
3. **Quality audit modality** — strict maintainability/abstraction/structure rubric. Run alone or layered onto any phase as extra severity criteria.

## Core Principle

The **parent agent owns truth.** Human comments, findings from automated review tools (CodeRabbit, Copilot, Graphite, Greptile, or similar), subagent prose, diffs, screenshots, articles, and failing tests are *inputs that generate hypotheses* — not the output. Every external comment is a hypothesis to verify locally, never a finding by itself. The output unit is a **verified flow**:

```text
trigger -> changed code -> contract/state/side effect -> observer -> impact -> severity -> fix direction
```

Prove over assert: one blocker proven by execution beats ten opinions. Severity is set by observer and reach, not by reviewer wording. False positives are valuable — reject them explicitly with the code reason. Stay read-only unless the user asks for fixes. Full non-negotiables in `references/method.md`.

## Routing

Pick the modality from the user's wording. Each row names the reference to load when depth is needed.

| Trigger | Modality | Reference |
| --- | --- | --- |
| "review", "audit", "check this PR", "is this fix good" | Practical review | scope + verify, then compact output |
| "address comments", "requested changes" | PR comment triage | `references/method.md` (ledger), `references/commands.md` |
| "review-of-review", triage comments from an automated review tool, "X reviewer said…" | Review-of-review | `references/method.md` (all phases), `references/fan-out.md` |
| "branch audit", "is this PR thoughtful or mechanical", systemic theme | Branch/codebase audit | `references/method.md` (all phases), `references/fan-out.md` |
| consult CI failure logs, "why checks fail" | CI review | `references/commands.md` |
| "simplify", "clean up", "refactor changes" | Simplification | `references/commands.md`, light `references/quality-audit.md` |
| "simplify" + "ambitious"/"structural", "code quality audit", "maintainability review", "deep quality" | **Quality audit** | `references/quality-audit.md` |
| "review swarm", "parallel review" | Fan-out | `references/fan-out.md` |
| autoreview / review closeout | Closeout | `references/commands.md` |
| draft me a PR comment | Comment drafting | `references/comment-craft.md` |

When the user says `/review`, treat it as this skill. Most requests combine modalities (e.g. a PR review that needs both regression-checking and a quality audit) — run the method and apply the rubric as added severity criteria.

## Scope

Prefer the smallest correct scope, in priority order:

1. Explicit paths, PR, issue, branch, commit, or URL from the user
2. Current git changes
3. Current branch PR
4. Files edited earlier in the current turn

Minimal scope commands:

```bash
git diff
gh pr diff <ref> --patch
```

Always read local instructions and relevant docs for the touched area before judging. When following a finding, **follow the real code path beyond the first file touched** — most shallow reviews stop too early. Keep **confirmed issues separate from open questions**.

Full scope/command catalog (PR-comment threads, CI, closeout, author-context calibration; host-specific CLIs and their equivalents) in `references/commands.md`.

## Method (Evidence-Based Flow)

Move input -> verified flow. Never jump from an artifact straight to a final comment. The flow runs through 10 ordered phases (Phase 0-9):

`Scope Gate -> Evidence Intake -> Claim Ledger -> Inline Scout -> First-Pass Verification -> Fan-Out -> Barrier -> Adversarial Verification -> User Draft Loop -> Synthesis.`

- **Quick practical review:** write the predicate, verify the touched paths, emit the compact output.
- **Rigorous/systemic work:** run all phases.

Each phase, the ledger schema, the partial-stop rule, the primary-source rule, and the rule that an external concept becomes a finding only once you locate its concrete local instance: see `references/method.md`.

## Quality Audit Modality

Activate when the user asks for a quality/maintainability/structure audit, or when "simplify" comes with "ambitious"/"structural". Run alone (skip the ledger, go straight to the rubric) or layer it onto the method as extra severity criteria in verification phases.

Core stance — **hunt code-judo:** restructurings that delete whole branches, helpers, layers, or conditionals rather than rearranging them. Prefer the version that feels inevitable in hindsight.

Baseline prompt: *"rethink how to structure the changes to meaningfully improve quality without impacting behavior."*

Full rubric (code-judo, ~1k-line rule, anti-spaghetti, abstraction-that-pays-its-keep, atomicity, canonical layer, 13 review questions, ordered remedies, approval bar, tone, model phrases): `references/quality-audit.md`.

## Output

Lead with findings ranked by severity, then confidence (`proven` > `read-confirmed`; `plausible` items go to open questions, not findings — see `references/method.md`). Each finding needs file/line or symbol, concrete failure mode, and fix direction. If no blocking issue exists, say so directly and list proof plus residual risk.

Compact shape (serializes the verified flow):

```text
Ref:        # issue, PR, branch, commit, or file scope
Surface:    # runtime, CLI, UI, API, data, build, docs, infra, workflow
Findings:   # severity-ordered; file:line, failure mode, fix
Cause:      # code path + confidence; if not proven, name the missing evidence
Proof:      # tests/CI/repro/logs/docs/live behavior actually checked
Refactor:   # does a larger refactor improve correctness/clarity enough to justify the risk?
Risk:       # what remains unverified
Next:
```

Deliver the **requested** output mode — do not return comments when the user asked for the flow:

- **report** — findings, then false positives, approach verdict, proof run
- **applicable list** — high/medium/low/design only, no long prose
- **comments to post** — path, line, one comment each, no extra explanation unless asked
- **flow explanation** — trigger -> code -> state/side effect -> observer, with snippets
- **status** — what ran, what is proven, what remains
- **skill extraction** — abstract the method, remove the domain subject

For rigorous reviews, also report (when applicable): confirmed findings, right-symptom/wrong-prescription, false positives rejected, pre-existing debt vs introduced regression, PR-level approach verdict (thoughtful / mixed / mostly mechanical / unsound), proof run, residual risk, coverage (`triaged N/M, deep-verified N, confirmed N, unverified N`). Detail in `references/method.md`.

## References

- `references/method.md` — state machine, ledger, all 10 phases (0-9), non-negotiables, adversarial checklist, root-fix vs site-fix, partial-stop, synthesis, output-mode mapping, primary-source and external-concept rules
- `references/fan-out.md` — five decompositions, three JSON schemas, subagent skeleton, barrier/dedupe
- `references/quality-audit.md` — full quality rubric: code-judo, 1k rule, anti-spaghetti, abstraction/atomicity/boundary rules, 13 questions, remedies, approval bar, tone
- `references/commands.md` — gh/git/closeout/CI (and non-GitHub equivalents), PR-comment threads, author-context, simplification, parallel
- `references/comment-craft.md` — user-draft loop, author voice, overclaim calibration, deterministic-repro / UI proof
- `references/heuristics.md` — review heuristics, common failure modes, session-derived lessons
