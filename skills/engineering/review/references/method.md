# Method: Evidence-Based Review Flow

The output unit is a verified flow, not a comment. Human review comments, findings from automated review tools, subagent prose, diffs, screenshots, articles, and failing tests are inputs that generate hypotheses. The parent agent owns truth: subagents and automated reviewers create breadth and pressure; only the parent decides what is real, by reading the code. Every external comment — regardless of source, confidence wording, or tool-assigned severity — enters as an unverified hypothesis and leaves as `confirmed`, `false-positive`, or one of the intermediate statuses. Nothing skips verification because it came from a trusted source.

## Operational State Machine

Move through these states in order. Do not skip from input directly to final comment.

```text
Input artifact
  -> claim
  -> evidence needed
  -> local code path
  -> reachable flow
  -> observer/impact
  -> severity
  -> fix direction
  -> requested output format
```

State definitions:

- **Input artifact:** pasted review, automated-reviewer comment, screenshot, article, issue, diff hunk, failing test, or user hunch.
- **Claim:** the smallest technical statement that can be true or false.
- **Evidence needed:** files, callsites, docs, commands, or UI path required to judge it.
- **Local code path:** full function plus enough caller/callee context to know ownership. Follow the real path beyond the first file touched.
- **Reachable flow:** concrete trigger that can execute the path.
- **Observer/impact:** who or what sees the result: user, UI state, database, background work, log, CI, crash reporter, public API, or nobody.
- **Severity:** based on impact and reachability, not on reviewer wording.
- **Fix direction:** ownership-correct remedy, not necessarily the reviewer suggestion.
- **Requested output format:** report, applicable list, comment text, command proof, or flow explanation.

Keep confirmed issues separate from open questions throughout.

## Non-Negotiables

- **Prove, don't assert.** If a finding predicts a test/build failure, run the narrowest command and paste output. One blocker proven by execution beats ten opinions.
- **False positives are valuable.** Reject them explicitly with the code reason; that sharpens the real invariant. Always separate true positive from false positive.
- **Right symptom, wrong cure.** Human and automated reviewers often flag a real smell and prescribe a mechanical fix. A tool can be right that something is wrong and wrong about what to do. Credit the symptom, trace the root cause, and derive the fix from local ownership and contracts — not from the suggestion.
- **Severity by observer and reach.** State that dies with its scope and nobody observes = low. Lost data/resource, observable stuck state, broken public contract = high.
- **Honest self-correction.** When evidence changes the conclusion (user challenge, doc contradiction, code proof), re-open the path, say plainly you were wrong, recalibrate.
- **Stay read-only** unless the user explicitly asks for fixes. Never post, resolve threads, stage, commit, push, or merge unless explicitly asked.
- Do not treat reviewer confidence, tool-assigned severity, or subagent prose as proof.
- Do not make the last domain bug into a reusable rule. Abstract the workflow, not the subject matter.
- Do not produce final synthesis until the requested input set is complete, unless the user asks for partial status.
- If the user says they want the flow, return the method, worklist, state machine, or call path — not comment findings.

## Two Failure Directions

A review fails in two directions: reporting what is not there (false positive) and missing what is (missed bug). Control both explicitly:

- **Against false positives:** negative criteria in the scope gate, adversarial verification before anything is reported, severity set by observer and reach, a confidence label on every finding.
- **Against missed bugs:** every changed hunk in scope gets a ledger disposition, the scout lists risky categories regardless of whether any input flagged them, and tool silence is never treated as clearance. Automated reviewers miss whole bug classes; their output bounds neither direction of the review. Run your own pass over the diff independent of what external inputs flagged.

## Phase 0: Scope Gate

Before searching broadly, pin down what kind of review is running.

Collect:

- target PR/branch/commit/base
- original issue/PR intent
- user role and requested output
- review inputs to judge: automated-reviewer comments, human comments, pasted reviews, screenshots, article links, CI, issue, diff
- local instructions and ownership boundaries
- read-only vs fix permission
- output mode: report, applicable list, comments-to-post, command proof, workflow extraction

Write the predicate:

```text
Real finding means:
- ...

Not a finding:
- ...

Severity rules:
- high:
- medium:
- low:

Proof required:
- ...
```

Negative criteria are mandatory. Add them before the first broad search:

- generated or test-only path outside the claim
- already guarded by nearby code
- caller/callee contract disproves the scenario
- local state dies with the scope and has no observer
- pre-existing debt not worsened by the change
- broad theory with no local failure mode
- author-context decision with no repo evidence

## Phase 1: Evidence Intake

Gather primary artifacts before judging:

- PR metadata, branch SHA, base SHA, issue, description, commits, checks
- full changed-file list and diff stat
- local instructions for the repo and touched area
- unresolved/outdated review threads when reviewing a PR
- exact code for touched functions, caller, callee, and state owner
- relevant tests or task names
- primary external docs only when behavior depends on library/platform semantics

Screenshots and review UIs are pointers, not proof. Re-open the real file at the current branch before judging.

For pasted reviews, wait for all promised parts unless the user explicitly asks for partial analysis. You may analyze while waiting, but do not synthesize final conclusions early.

## Phase 2: Claim Ledger

Turn every review comment, tool-generated finding, user concern, suspicious hunk, and subagent candidate into a ledger row.

```text
id:
source:
file/line:
claim:
proposed fix:
category:
claimed severity:
input type: comment|tool|user|diff|test|doc|subagent|search
evidence needed:
status: unverified
```

Ledger discipline:

- One claim per row. Split compound comments into separate rows; the parts can resolve differently.
- Every input artifact yields at least one row or an explicit "no actionable claim" note. Nothing is silently dropped.
- Every changed hunk in scope gets a disposition: its own row, coverage by an existing row, or an explicit "reviewed, no claim". Missed bugs live in the hunks nobody claimed.
- The ledger is the single source of coverage counts in synthesis. Do not report a finding that has no ledger row.
- Rows never leave the ledger; they change status. Keep `false-positive` and `stale` rows for the synthesis section that rejects them.

Categories (category defines the fix — same syntax needs a different fix per category):

- behavior / business work
- state/lifecycle
- cleanup/teardown (side effects that must not be interrupted or lost)
- persistence/transaction (atomicity)
- public contract
- architecture boundary
- tests/coverage
- UI state
- background work / async task lifecycle
- style/formatting
- CI/process

Group duplicates by behavior, not by file. Keep three things separate:

- **symptom:** what might be wrong
- **prescription:** what the reviewer or tool says to do
- **verified fix direction:** what local evidence supports

A review can have the right symptom and the wrong cure. Credit the symptom without adopting the cure.

**External-concept promotion rule:** an external concept (article, doc, pattern, best practice) only becomes a finding when you locate its concrete instance in the project code. Until then it is a search directive, not a claim. Once you find the local instantiation, the argument belongs to the repo, not the article — and is much stronger.

## Phase 3: Inline Scout

Before fan-out, do a small local scout to size the work:

- count changed files by ownership area
- search for repeated new helpers, new imports, repeated guard/cleanup/state/transaction patterns, or API boundary changes
- identify representative examples and outliers
- list risky state machines, persistence writes, teardown/cleanup paths, background work / async task lifecycles, public contracts, and UI-observed states

The scout output is not a verdict. It decides decomposition. Repeated identical-shape edits are a hint that the change may be mechanical — but still verify each category, because the same prescription can be right in one class and wrong in another.

## Phase 4: First-Pass Verification

Common failure modes and their corrections (right-symptom/wrong-cure, primary-source discipline, tool-silence): `references/heuristics.md`.

For each high-value ledger row:

- read the full touched function
- read caller and callee enough to know ownership
- identify who observes the failure
- identify whether the state/side effect survives the local scope
- run the narrowest command if the claim predicts a test/build failure
- decide whether this is introduced by the change, pre-existing but worsened, or unchanged debt
- when chaining commands for proof, ensure failures propagate. In shell pipelines, use `set -o pipefail` or check intermediate exit codes. In test runners, inspect the exit code of the runner itself, not just the last step.

Ledger statuses:

- `confirmed`
- `partial`
- `right-symptom-wrong-fix`
- `false-positive`
- `stale`
- `pre-existing`
- `needs-author-context`

Reject false positives explicitly with the code reason. Explicit rejection sharpens the real invariant.

Assign a confidence label to every row that stays alive:

- `proven` — narrowest command or repro executed; output captured
- `read-confirmed` — full path read end-to-end (trigger -> code -> observer), no execution
- `plausible` — consistent with the code read so far, but the path is not fully traced

`plausible` never ships as a finding. Upgrade it with more reading or execution, or report it as an open question.

### Primary source vs opinion

When a claim depends on library or platform semantics, fetch the primary official doc before deciding. Do not assert behavior from memory. Distinguish:

- **official doc recommends X** = baseline (validate against this)
- **an article/author recommends Y** = advanced/ideal opinion

Cite the source. A respected article is still opinion until validated against the official spec.

### Introduced vs pre-existing

Do not blame the change for old debt; be honest about what it introduced vs what already existed. But a change that touches the area is the right opportunity to surface that debt — flag it as pre-existing, not as a regression.

## Phase 5: Fan-Out

See `references/fan-out.md` for decompositions, JSON schemas, and the subagent prompt skeleton. Use subagents only when breadth is real: many files, repeated patterns, multiple ownership areas, or a need for adversarial validation. Subagents generate candidates; they do not decide what is real.

## Phase 6: Barrier

See `references/fan-out.md`. Normalize and dedupe subagent output before deep-reviewing it. Discard malformed, evidence-less, duplicate, and low-value candidates.

## Phase 7: Adversarial Verification

Failure-mode corrections to check against before promoting a candidate: `references/heuristics.md`.

Verify candidates by trying to refute them. Generation optimizes for breadth; this phase optimizes for disproof. A candidate becomes a finding only after a genuine refutation attempt fails.

When fan-out is active, use independent skeptics: a fresh subagent (or a fresh pass with no access to the generator's reasoning) whose only objective is to disprove the candidate with code evidence — a guard the generator missed, an unreachable trigger, a caller contract that excludes the scenario, an existing test that covers it. If generator and skeptic disagree, the parent reads the code path itself and decides; neither side's prose settles it. See `references/fan-out.md` for the skeptic pass.

For each candidate, check:

- full function context
- caller context
- callee contract
- nearby guard/cleanup/helper
- state owner and lifetime
- whether the scenario is reachable
- whether tests already cover it
- whether the proposed fix breaks another invariant

Instruction to any verifier subagent:

```text
On doubt, mark false-positive or needs-context. Do not promote a visual pattern to a finding without an executable path.
```

Deep-review only:

- high severity candidates
- ambiguous call-chain candidates
- systemic patterns that affect the PR-level verdict
- items where a wrong recommendation would cause regression

Parent verification checklist:

```text
Can I name the trigger?
Can I point to the changed line?
Can I name the previous contract?
Can I name the new contract?
Can I name the state/side effect/resource that changes?
Can I name who observes the failure?
Can I distinguish introduced regression from pre-existing debt?
Can I give the smallest proof command or manual repro?
Can I explain why the obvious alternative fix is or is not safe?
Can I give the root-fix (one change that closes the entire class) vs the site-fix (N local patches)? Have I validated the root-fix preconditions across all sites?
Can I give a deterministic repro path? If the claim is a visible UI state, can I name the concrete user action that triggers it? If no confirmed path exists, say so instead of constructing one.
```

If any answer is "no", downgrade, mark needs-context, or keep it out of final findings.

### Root-fix vs site-fix

Prefer the smallest change that resolves the full class (root-fix) over N local patches (site-fix). Before recommending the root-fix, verify its preconditions hold across all sites. If they do not, say which sites need individual treatment and why.

## Phase 8: User Draft Loop

See `references/comment-craft.md`.

## Phase 9: Synthesis

Synthesize only verified facts.

Rank findings by severity first, confidence second: at equal severity, `proven` outranks `read-confirmed`. `plausible` rows are excluded from findings and reported as open questions or residual risk.

Required sections when applicable:

- confirmed high/medium/low findings
- right symptoms with wrong prescriptions
- false positives rejected
- pre-existing debt vs introduced regression
- PR-level approach verdict
- proof run
- residual risk

PR-level approach verdict options (judge the change against the original issue/PR intent — was the implementation case-by-case/thoughtful or mechanical search-and-replace?):

- `thoughtful`: most changes match local categories and preserve invariants
- `mixed`: some correct work, some mechanical or under-tested areas
- `mostly mechanical`: repeated prescription with little category-specific reasoning; evidence is identical-shape repeats, uniform fix without per-category reasoning, inconsistencies (some sites yes, others no)
- `unsound`: core approach breaks important invariants or contradicts issue intent

Output mode mapping:

- **report:** findings first, then false positives, approach verdict, proof run
- **applicable list:** high/medium/low/design only, no long prose
- **comments to post:** path, line, one comment each, no extra explanation unless asked
- **flow explanation:** trigger -> code -> state/side effect -> observer, with code snippets
- **status:** what has run, what is proven, what remains
- **skill extraction:** abstract the method; remove the domain-specific subject

When reporting counts, state coverage:

```text
triaged: 70/71 files
deep-verified: 38 candidates
confirmed: 23 regressions
unverified: 1 file, low expected impact
```

## Partial Stop Rule

You may synthesize before all deep agents finish only when:

- the predicate is explicit
- broad triage coverage is high
- enough candidates have adversarial verification
- remaining unresolved items are unlikely to change the PR-level verdict

Say what is incomplete. Do not pretend partial coverage is exhaustive.
