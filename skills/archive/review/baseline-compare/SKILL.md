---
name: baseline-compare
description: Compare a repo, config, workflow, UI, branch, or document against a named baseline and report only meaningful gaps, regressions, or missing pieces. Use when the user asks to compare with another repo, tool setup, branch, PR, screenshot, spec, or reference implementation.
---

# Baseline Compare

Compare one thing against a named baseline without drifting into implementation.

## Step 1: Lock Subject and Baseline

Identify:

- subject
- baseline
- comparison axes
- expected output

If the baseline is ambiguous, infer the most likely one and say so.

## Step 2: Gather Evidence

Prefer:

- local code and docs first
- the specific referenced page, file, repo, branch, or screenshot
- primary source documentation when the baseline is external

Only pull in enough evidence to compare the relevant contract.

## Step 3: Compare By Contract

Focus on:

- what matches
- what is missing
- what regressed
- what is intentionally different

Do not pad the output with trivial differences.

## Step 4: Keep Compare Separate From Build

If the user asked only for comparison, stop at the comparison.

If the user also wants changes:

- present the comparison first
- then propose or execute the smallest follow-up

## Output Shape

- `Subject`
- `Baseline`
- `Matches`
- `Missing or regressed`
- `Intentional or unclear differences`
- `Recommended next step`
