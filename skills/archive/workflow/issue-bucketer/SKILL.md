---
name: issue-bucketer
description: Split a broad issue sweep, bug hunt, or review request into 2-4 disjoint buckets that can be explored safely and, when appropriate, delegated to sub-agents. Use when the user asks to triage issues, sweep a broad area, check subissues, find bugs across multiple flows, or parallelize exploration without overlapping work.
---

# Issue Bucketer

Turn broad work into a small number of disjoint buckets.

## Step 1: Lock Scope

Start from the clearest scope available:

1. explicitly named issues, paths, flows, or modules
2. current diff or branch
3. the smallest inferred surface that matches the request

If the scope is still broad, narrow it before bucketing.

## Step 2: Choose the Bucketing Axis

Prefer one clear axis:

- subsystem
- user flow
- contract boundary
- risk category

Buckets should be meaningfully separate. Avoid putting the same hot files or codepath in multiple buckets unless overlap is unavoidable.

Default to 2-4 buckets.

## Step 3: Define Each Bucket

For each bucket, write:

- what it covers
- what it should ignore
- read-only or edit-allowed
- proof of completion

When the user wants a sweep first, default buckets to read-only.

## Step 4: Decide Whether to Delegate

Use sub-agents only if the buckets are truly disjoint and parallel work will save time.

Do not delegate if the task is one bug, one file, one failing test, or one tight sequential codepath.

## Step 5: Return or Execute

If the user asked for planning or analysis:

- return the buckets only

If the user asked to execute:

- launch or work the buckets in the same order
- keep the parent responsible for synthesis

## Output Shape

Return a compact bucket list:

1. `Bucket`
2. `Scope`
3. `Ignore`
4. `Mode`
5. `Done when`
