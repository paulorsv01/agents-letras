---
name: codex-insights
description: "Analyze local Codex history and produce evidence-backed reports about session trends, repo heatmaps, workflow friction, and usage patterns."
---

# Codex Insights

Use the same template and workflow shape as Claude Code `/insights`, but source everything from `~/.codex`.

This skill is for broad usage analysis, not just one SQL query. The expected output is the same two-layer deliverable:

- a short markdown summary with an `At a Glance` section
- a fuller shareable artifact such as `report.md`, `report.html`, `summary.json`, and `insights.json`

If the user asks for only one metric or one slice, do not force the whole report. Use the same workflow, but stop once that narrower question is answered.

## Golden Path

Run the fixed generator first:

```bash
node ~/.agents/skills/codex-insights/scripts/generate-codex-insights.mjs
```

Useful variants:

```bash
node ~/.agents/skills/codex-insights/scripts/generate-codex-insights.mjs --days 30
node ~/.agents/skills/codex-insights/scripts/generate-codex-insights.mjs --outdir ./codex-insights
```

Default output directory: `./codex-insights`

Expected artifacts:

- `report.html`
- `report.md`
- `report.json`
- `summary.json`
- `insights.json`

## Source Of Truth

Use these in order:

1. `~/.codex/state_5.sqlite`
   - Primary metadata source.
   - Start with `threads` for `cwd`, title, model, reasoning, archived state, timestamps, and `rollout_path`.
   - Use `thread_spawn_edges` for parent/child thread relationships and sub-agent usage.
   - Use `agent_jobs` only when the question is about batch jobs or orchestrated runs.
2. `~/.codex/session_index.jsonl`
   - Fast lookup by thread id, thread name, and updated time.
   - Good for narrowing which rollouts to inspect.
3. `~/.codex/sessions/**/rollout-*.jsonl`
   - Detailed transcript evidence.
   - Useful event types include `session_meta`, `turn_context`, `event_msg`, and `response_item`.
4. `~/.codex/.codex-global-state.json`
   - Only when settings or UI state are relevant.

Ignore by default:

- `~/.codex/auth*.json`
- plugin cache internals
- bundled marketplace cache
- `.env*`
- raw instruction dumps unless the question is explicitly about instructions

## Match Claude `/insights` Workflow

Mirror the Claude command flow as closely as the Codex data model allows.

### Phase 1: Lite Scan

Start with metadata only.

- identify candidate threads and date range
- count sessions or threads
- rank repos by `cwd`
- split by model and reasoning effort
- identify likely parent or child thread patterns

Do not open rollout JSONL files yet unless the question is already transcript-specific.

### Phase 2: Load Detailed Session Evidence

Open only the rollout files needed for the selected slice.

- use `rollout_path` from `threads` whenever available
- otherwise use `session_index.jsonl` to map ids or recent titles
- skip obvious meta or bookkeeping sessions when they would pollute the analysis
- avoid loading the whole corpus blindly

For each inspected thread, capture a compact session record:

- thread id
- date
- cwd or project area
- title or inferred goal
- main outcome
- friction signals
- notable user instructions to Codex
- whether sub-agents were used

### Phase 3: Deduplicate And Filter

Claude `/insights` deduplicates branches and filters minimal sessions. Do the same in spirit here.

- if multiple records clearly represent the same working thread, keep the strongest evidence source
- filter out trivial sessions that are only warm-up, one-shot status checks, or internal bookkeeping
- call out the filter if it materially changes totals

### Phase 4: Extract Facets

Claude `/insights` extracts per-session facets first, then aggregates. Follow that pattern.

For each substantive Codex session, derive a compact facet set such as:

- brief summary
- underlying goal
- outcome
- helpfulness
- friction detail
- user instructions to Codex
- project area
- tools or capabilities used
- model and reasoning mode
- sub-agent involvement

Keep this step compact and evidence-backed. Do not invent exactness where the rollout is ambiguous.

### Phase 5: Aggregate

Build an aggregated context object before writing prose. Include only metrics you can support.

Typical aggregated fields:

- total sessions or threads analyzed
- scanned total vs analyzed total
- date range
- total messages if measurable
- active days
- top repos
- top project areas
- model split
- reasoning split
- outcomes
- friction categories
- notable tools or capabilities
- sub-agent counts or rate

### Phase 6: Generate Section Insights In Parallel

Use the same section structure as Claude `/insights`, but make it Codex-specific.

Generate these sections first:

1. `project_areas`
   - 4-5 areas
   - include session count and short description
2. `interaction_style`
   - 2-3 paragraphs
   - use second person `you`
   - describe how the user works with Codex
3. `what_works`
   - 3 impressive workflows
   - use second person
4. `friction_analysis`
   - 3 concrete categories
   - each with examples
5. `suggestions`
   - split into three buckets:
   - `agents_md_additions`
   - `features_to_try`
   - `usage_patterns`
6. `on_the_horizon`
   - 3 ambitious workflows
7. `fun_ending`
   - one memorable qualitative moment

Optional only when the user wants product feedback:

- `product_improvements`
- `model_behavior_improvements`

### Phase 7: Synthesize `at_a_glance` Last

Like Claude `/insights`, generate `at_a_glance` after the other sections so it can summarize them.

Use this 4-part structure:

1. `whats_working`
2. `whats_hindering`
3. `quick_wins`
4. `ambitious_workflows`

Keep each part short, high-signal, and coaching in tone. Do not dump raw stats here.

## Codex Feature Reference

Use this in the `suggestions.features_to_try` section. Pick only features that are actually relevant to the observed behavior.

1. `Skills`
   - reusable command-like workflows from `~/.codex/skills` or shared skills repos
   - good for repeated review, reporting, cleanup, and bootstrap flows
2. `Sub-agents`
   - parallel bounded work for disjoint slices
   - good for review swarms, exploration, and split implementation
3. `Memory`
   - reuse relevant prior context from `~/.codex/memories`
   - good for repeated repos, long-running tasks, and continuity
4. `Apps/Plugins/MCP`
   - connected tools such as GitHub, Google Drive, browser, or MCP servers
   - good when the friction is caused by missing external context
5. `Automations`
   - recurring monitors, follow-ups, and scheduled checks
   - good for repeated reports or reminders
6. `Artifacts`
   - reusable local outputs like `report.md`, `dashboard.html`, CSV, or JSON exports
   - good when the user asks for heatmaps, charts, or recurring reviews

For `agents_md_additions`, prefer repeated instructions the user keeps re-explaining across sessions. The point is the same as Claude’s `claude_md_additions`: stop making the user repeat durable workflow rules.

## Output Template

For broad reports, keep the same section order:

- `At a Glance`
- `What You Work On`
- `How You Use Codex`
- `Impressive Things You Did`
- `Where Things Go Wrong`
- `Existing Codex Features to Try`
- `New Ways to Use Codex`
- `On the Horizon`
- `Memorable Moment`

Optional:

- `Feedback for Product`
- `Feedback for Model Behavior`

If you generate an artifact, the markdown summary should still be short and should point to the artifact path.

## Query Recipes

Use `sqlite3` first. Prefer local time in outputs.

Recent threads:

```bash
sqlite3 -header -column ~/.codex/state_5.sqlite "
select
  datetime(updated_at,'unixepoch','localtime') as updated_at,
  cwd,
  title,
  model,
  reasoning_effort,
  archived
from threads
order by updated_at desc
limit 20;
"
```

Top repos by thread count:

```bash
sqlite3 -header -column ~/.codex/state_5.sqlite "
select
  cwd,
  count(*) as thread_count,
  min(datetime(created_at,'unixepoch','localtime')) as first_seen,
  max(datetime(updated_at,'unixepoch','localtime')) as last_seen
from threads
group by cwd
order by thread_count desc
limit 15;
"
```

Model and reasoning split:

```bash
sqlite3 -header -column ~/.codex/state_5.sqlite "
select
  coalesce(model, '(unknown)') as model,
  coalesce(reasoning_effort, '(unknown)') as reasoning_effort,
  count(*) as threads
from threads
group by model, reasoning_effort
order by threads desc;
"
```

Sub-agent usage:

```bash
sqlite3 -header -column ~/.codex/state_5.sqlite "
select
  parent_thread_id,
  count(*) as child_threads
from thread_spawn_edges
group by parent_thread_id
order by child_threads desc
limit 20;
"
```

Rollout event scan:

```bash
rg -n '"type":"(session_meta|turn_context|event_msg|response_item)"' ~/.codex/sessions
```

## Rules

- Keep the Claude `/insights` workflow shape. Do not collapse this into ad hoc commentary.
- Separate measured facts from inference.
- Do not claim exactness from partial rollout sampling.
- Do not surface secrets, auth files, or giant raw instruction blocks.
- Use exact dates when describing recent activity.
- When quoting rollout content, keep excerpts tiny and only when necessary.
- If a metric is weak or incomplete, say so.
- Treat `tokens_used` and similar fields as best-effort until verified.
- If the user asks for charts or graphs, prefer reusable artifacts over a wall of prose.
