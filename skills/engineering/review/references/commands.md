# Commands: gh / git / closeout / CI / context

Read local instructions and relevant docs before judging any change.

Commands below assume GitHub + the `gh` CLI. For other hosts, adapt to the equivalent CLI or API (`glab` for GitLab, `az repos` for Azure DevOps, the Bitbucket REST API for Bitbucket). The pattern is what matters, not the tool.

## Scope Selection

```bash
git diff
git diff --cached
gh pr view <ref> --json number,title,state,author,body,comments,reviews,files,commits,statusCheckRollup,mergeStateStatus,headRefName,baseRefName,url
gh pr diff <ref> --patch
gh issue view <ref> --json number,title,state,author,body,comments,labels,updatedAt,url
```

## PR Comments

1. Resolve the PR with `gh pr view`.
2. Fetch thread-aware review state when needed with `gh api graphql`; flat comments are not enough for unresolved inline review threads.
3. Group actionable feedback by behavior or file.
4. Separate real requested changes from informational comments, stale threads, duplicates, and conflicts.
5. If the user asked to fix comments, implement only actionable items in scope.
6. Do not reply, resolve threads, submit reviews, push, or merge unless explicitly asked.

If comments conflict or would cause a regression, stop and explain the tradeoff.

## CI Review (GitHub Actions)

```bash
gh pr checks <pr> --json name,state,bucket,link,startedAt,completedAt,workflow
gh run view <run_id> --json name,workflowName,conclusion,status,url,event,headBranch,headSha
gh run view <run_id> --log-failed
```

Inspect only failing or relevant jobs. Avoid broad log dumps. Identify the root cause before editing. If fixing CI requires product or workflow tradeoffs, explain before changing.

For non-GitHub CI, identify the equivalent log command for the CI provider in use (GitLab CI, CircleCI, Buildkite, Jenkins, etc.). The pattern is the same: find the failing job, fetch its raw log, identify the root cause before editing.

## Review Closeout

This section's specific commands apply to harnesses that expose a built-in review command. For standalone environments without one, skip the tool-specific commands and use `git diff` + focused tests as proof instead. The flow is unchanged: scope the diff, get candidate findings, then verify each by reading the real code path before changing code.

When a built-in review command exists, use it only as advisory proof. Treat its findings like any automated-reviewer output: hypotheses to enter into the ledger and verify against the code, never conclusions. Pick the target (the flags below follow one common review CLI's shape; other CLIs differ — check the actual CLI's `--help` for equivalents):

```bash
<review-cli> --uncommitted          # scope: uncommitted changes
<review-cli> --base origin/main     # scope: vs base branch
<review-cli> --commit HEAD          # scope: single commit
```

For PR branches, prefer the actual PR base:

```bash
base=$(gh pr view --json baseRefName --jq .baseRefName)
<review-cli> --base "origin/$base"
```

Rules:

- Do not push just to review.
- Reject speculative findings, broad rewrites, and fixes that over-complicate the codebase.
- If a review-triggered fix changes code, rerun focused tests and rerun review when worth the cost.
- Report accepted findings, rejected findings with reason, proof run, and remaining risk.

## External Contributor Context

For changes from an unknown external contributor, collect only public host context when it changes review risk:

```bash
gh pr view <pr> --json author,commits,files,reviews,comments
gh api "users/<login>"
gh api "repos/<owner>/<repo>/contributors" --paginate
gh search prs --author "<login>" --repo "<owner>/<repo>" --json number,state,title,createdAt,mergedAt,url
```

Use it to calibrate review depth, not to judge the person. Report only relevant signals: prior activity in the repo, size/focus of the current change, whether changes touch sensitive areas, whether the author appears new.

Skip for local work, trusted internal contributors, tiny docs-only changes, or when the user only wants code findings.

## Simplification

Review for: existing helpers/utilities to reuse; duplicated or near-duplicated logic; redundant state, cached derived values, dead code, needless indirection; unnecessary recomputation, broad reads, repeated I/O, leaks, missing cleanup; unclear names, cleverness, local convention drift.

If the user asked only for review, report findings. If they asked to simplify or clean up, apply only high-confidence, behavior-preserving fixes and run focused validation. For ambitious/structural simplification, escalate to the quality-audit rubric in `references/quality-audit.md`.

## Parallel Review

Keep sub-agents read-only. See `references/fan-out.md` for decompositions and schemas. Give each reviewer the same scope and intent packet; ask for file/line or symbol, issue, impact, recommended fix, and confidence. The parent filters duplicates, drops weak findings, and owns final synthesis.
