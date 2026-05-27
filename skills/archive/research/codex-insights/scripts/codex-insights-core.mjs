import fs from "node:fs";
import fsp from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { execFileSync } from "node:child_process";

const HOME = os.homedir();
const TIME_ZONE = "America/Sao_Paulo";
const DEFAULT_OUTDIR = path.resolve(process.cwd(), "codex-insights");

function run(command, args) {
  return execFileSync(command, args, {
    encoding: "utf8",
    maxBuffer: 1024 * 1024 * 256,
  });
}

function sqliteJson(dbPath, sql) {
  const raw = run("sqlite3", ["-json", dbPath, sql]).trim();
  return raw ? JSON.parse(raw) : [];
}

function numberOrNull(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function numberOrZero(value) {
  return numberOrNull(value) ?? 0;
}

function toDate(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function fromUnixSeconds(value) {
  if (!Number.isFinite(Number(value))) return null;
  return new Date(Number(value) * 1000);
}

function formatDateKey(date) {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function formatDateTime(date) {
  return new Intl.DateTimeFormat("en-US", {
    timeZone: TIME_ZONE,
    year: "numeric",
    month: "short",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(date);
}

function replaceHome(value) {
  return typeof value === "string" ? value.replace(HOME, "~") : value;
}

function basenameOrUnknown(projectPath) {
  if (!projectPath) return "(unknown)";
  const clean = projectPath.replace(/[\\/]+$/, "");
  const base = path.basename(clean);
  return base || clean || "(unknown)";
}

function toWeekdayIndex(date) {
  return (date.getDay() + 6) % 7;
}

function normalizeWhitespace(text) {
  return text.replace(/\s+/g, " ").trim();
}

function truncate(text, maxLength = 160) {
  if (!text) return "";
  return text.length <= maxLength ? text : `${text.slice(0, maxLength - 1)}...`;
}

function humanList(items) {
  if (items.length === 0) return "";
  if (items.length === 1) return items[0];
  if (items.length === 2) return `${items[0]} and ${items[1]}`;
  return `${items.slice(0, -1).join(", ")}, and ${items.at(-1)}`;
}

function extractText(value) {
  if (!value) return "";
  if (typeof value === "string") return value;
  if (Array.isArray(value)) return value.map(extractText).filter(Boolean).join("\n");
  if (typeof value !== "object") return "";
  if (typeof value.text === "string") return value.text;
  if (typeof value.input_text === "string") return value.input_text;
  if (typeof value.output_text === "string") return value.output_text;
  if (Array.isArray(value.content)) return extractText(value.content);
  return "";
}

function pickShortUserSnippet(text) {
  const normalized = normalizeWhitespace(text);
  if (!normalized) return "";
  if (normalized.includes("AGENTS.md instructions for")) return "";
  if (normalized.length > 1000) return "";
  return truncate(normalized, 180);
}

function projectLabel(projectPath) {
  return replaceHome(projectPath || "(unknown)");
}

function areaNameFromPath(projectPath) {
  const label = projectLabel(projectPath);
  if (label === "~") return "Home folder";
  return basenameOrUnknown(projectPath);
}

function isSubstantiveThread(thread) {
  if (thread.userMessages >= 2) return true;
  if (thread.assistantMessages >= 2) return true;
  if (thread.toolCalls >= 2) return true;
  if (thread.childThreads > 0) return true;
  if (thread.totalTokens >= 10_000) return true;
  return false;
}

async function parseRollout(filePath) {
  if (!filePath || !fs.existsSync(filePath)) {
    return {
      exists: false,
      startTime: null,
      endTime: null,
      inputTokens: null,
      cacheReadTokens: null,
      outputTokens: null,
      reasoningOutputTokens: null,
      totalTokens: null,
      userMessages: 0,
      assistantMessages: 0,
      toolCounts: {},
      firstUserSnippet: "",
    };
  }

  const stream = fs.createReadStream(filePath, { encoding: "utf8" });
  const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });
  let startTime = null;
  let endTime = null;
  let bestUsage = null;
  let userMessages = 0;
  let assistantMessages = 0;
  let firstUserSnippet = "";
  const toolCounts = new Map();

  for await (const line of rl) {
    if (!line) continue;

    let item = null;
    try {
      item = JSON.parse(line);
    } catch {
      continue;
    }

    endTime = item.timestamp ?? endTime;

    if (item.type === "session_meta") {
      startTime ??= item.payload?.timestamp ?? item.timestamp ?? null;
      continue;
    }

    if (item.type === "event_msg" && item.payload?.type === "token_count") {
      const usage = item.payload?.info?.total_token_usage;
      if (!usage) continue;

      const current = {
        inputTokens: numberOrZero(usage.input_tokens),
        cacheReadTokens: numberOrZero(usage.cached_input_tokens),
        outputTokens: numberOrZero(usage.output_tokens),
        reasoningOutputTokens: numberOrZero(usage.reasoning_output_tokens),
        totalTokens: numberOrZero(usage.total_tokens),
      };

      if (!bestUsage || current.totalTokens >= bestUsage.totalTokens) {
        bestUsage = current;
      }

      continue;
    }

    if (item.type !== "response_item") continue;

    const payload = item.payload ?? {};

    if (payload.type === "message") {
      if (payload.role === "user") {
        userMessages += 1;
        if (!firstUserSnippet) {
          firstUserSnippet = pickShortUserSnippet(extractText(payload.content));
        }
      } else if (payload.role === "assistant") {
        assistantMessages += 1;
      }
      continue;
    }

    if (payload.type === "function_call" && payload.name) {
      toolCounts.set(payload.name, (toolCounts.get(payload.name) ?? 0) + 1);
    }
  }

  return {
    exists: true,
    startTime,
    endTime,
    inputTokens: bestUsage?.inputTokens ?? null,
    cacheReadTokens: bestUsage?.cacheReadTokens ?? null,
    outputTokens: bestUsage?.outputTokens ?? null,
    reasoningOutputTokens: bestUsage?.reasoningOutputTokens ?? null,
    totalTokens: bestUsage?.totalTokens ?? null,
    userMessages,
    assistantMessages,
    toolCounts: Object.fromEntries(toolCounts),
    firstUserSnippet,
  };
}

function aggregateHeatmap(threads) {
  const grid = Array.from({ length: 7 }, () => Array.from({ length: 24 }, () => 0));
  for (const thread of threads) {
    const date = toDate(thread.startedAt);
    if (!date) continue;
    grid[toWeekdayIndex(date)][date.getHours()] += 1;
  }
  return grid;
}

function aggregateProjects(threads, limit = 5) {
  const buckets = new Map();

  for (const thread of threads) {
    const key = thread.projectLabel;
    const current =
      buckets.get(key) ??
      {
        projectLabel: thread.projectLabel,
        areaName: thread.areaName,
        sessionCount: 0,
        totalTokens: 0,
        childThreads: 0,
        toolCalls: 0,
        firstSeen: thread.startedAt,
        lastSeen: thread.updatedAt,
        modelCounts: new Map(),
      };

    current.sessionCount += 1;
    current.totalTokens += thread.totalTokens;
    current.childThreads += thread.childThreads;
    current.toolCalls += thread.toolCalls;
    current.firstSeen = current.firstSeen < thread.startedAt ? current.firstSeen : thread.startedAt;
    current.lastSeen = current.lastSeen > thread.updatedAt ? current.lastSeen : thread.updatedAt;

    if (thread.model) {
      current.modelCounts.set(thread.model, (current.modelCounts.get(thread.model) ?? 0) + 1);
    }

    buckets.set(key, current);
  }

  return [...buckets.values()]
    .map((bucket) => ({
      ...bucket,
      dominantModel: [...bucket.modelCounts.entries()].sort((left, right) => right[1] - left[1])[0]?.[0] ?? null,
    }))
    .sort((left, right) => right.sessionCount - left.sessionCount || right.totalTokens - left.totalTokens)
    .slice(0, limit);
}

function aggregateCounts(threads, keyFn) {
  const buckets = new Map();
  for (const thread of threads) {
    const key = keyFn(thread);
    buckets.set(key, (buckets.get(key) ?? 0) + 1);
  }
  return [...buckets.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((left, right) => right.count - left.count || left.name.localeCompare(right.name));
}

function aggregateTools(threads, limit = 8) {
  const buckets = new Map();
  for (const thread of threads) {
    for (const [name, count] of Object.entries(thread.toolCounts)) {
      buckets.set(name, (buckets.get(name) ?? 0) + numberOrZero(count));
    }
  }
  return [...buckets.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((left, right) => right.count - left.count || left.name.localeCompare(right.name))
    .slice(0, limit);
}

function buildProjectAreas(summary) {
  return summary.topProjects.slice(0, 5).map((project) => ({
    name: project.areaName,
    session_count: project.sessionCount,
    description: `You come back to ${project.projectLabel} often, which suggests this is one of your main working areas. The sessions cluster around ${project.dominantModel ?? "your default model"} and span from ${project.firstSeen.slice(0, 10)} to ${project.lastSeen.slice(0, 10)}.`,
  }));
}

function buildInteractionStyle(summary) {
  const topProject = summary.topProjects[0];
  const topTools = summary.topTools.slice(0, 3).map((tool) => tool.name);
  const reasoningLead = summary.reasoningSplit[0];
  const spawnRate = summary.totalThreadsAnalyzed > 0 ? summary.threadsWithChildren / summary.totalThreadsAnalyzed : 0;
  const repoFocus = topProject ? topProject.sessionCount / summary.totalThreadsAnalyzed : 0;

  const paragraphOne = repoFocus >= 0.45
    ? `You tend to stay anchored in **${topProject.areaName}** instead of hopping randomly between codebases. That makes your Codex usage look more like deep project work than quick one-off prompting, with repeated returns to the same repos over time.`
    : `You use Codex across several repos, which makes your workflow look like a **multi-context bench** rather than a single long-running stream. The same account is carrying several active work areas, so re-entry and context compression matter more than usual.`;

  const paragraphTwo = spawnRate >= 0.15
    ? `You already lean on Codex as an execution partner, not just a chat window. The sessions show real tool usage${topTools.length ? ` through ${humanList(topTools)}` : ""}, plus sub-agent splits often enough that parallel exploration is part of your normal rhythm.`
    : `You mostly keep work inside the main thread, even when sessions get large. That keeps the flow simple, but it also means bigger prompts, heavier context carry, and fewer chances to split broad work into smaller bounded lanes.`;

  const keyPattern = reasoningLead
    ? `Most of your work clusters around ${reasoningLead.name} reasoning with ${summary.modelSplit[0]?.name ?? "your main model"}, which reinforces a deliberate, repo-grounded workflow.`
    : "Your usage pattern is concentrated, repo-grounded, and driven by real working sessions instead of throwaway prompts.";

  return {
    narrative: `${paragraphOne}\n\n${paragraphTwo}`,
    key_pattern: keyPattern,
  };
}

function buildWhatWorks(summary) {
  const topProject = summary.topProjects[0];
  const secondaryProject = summary.topProjects[1];
  const results = [];

  if (topProject) {
    results.push({
      title: "Deep repo continuity",
      description: `You keep returning to ${topProject.projectLabel}, which lets Codex accumulate real momentum around one codebase instead of restarting from scratch every time. That is usually where the strongest results show up, because the work stays close to a real repo, a real branch, and a real slice.`,
    });
  }

  if (summary.threadsWithChildren > 0) {
    results.push({
      title: "Parallel exploration",
      description: `You are already using child threads in ${summary.threadsWithChildren} sessions, which means you are not treating Codex as a single narrow conversation. That is the right shape for review swarms, parallel investigation, and bounded side work.`,
    });
  } else {
    results.push({
      title: "High-signal main threads",
      description: `Even without much sub-agent usage, your main threads are doing real work through tools, file reads, and grounded repo context. The pattern is closer to focused pair programming than generic prompt-and-answer usage.`,
    });
  }

  if (secondaryProject) {
    results.push({
      title: "Sustained multi-repo work",
      description: `Your history is not locked to one repo forever. Alongside ${topProject?.areaName ?? "the main project"}, you also maintain active work in ${secondaryProject.projectLabel}, which suggests you are using Codex as shared infrastructure across ongoing projects rather than for a single isolated experiment.`,
    });
  } else {
    results.push({
      title: "Focused execution",
      description: `The thread mix stays tight enough that Codex is mostly pointed at real ongoing work instead of scattered experiments. That focus tends to produce cleaner outcomes and less re-anchoring overhead.`,
    });
  }

  return {
    intro: "The strongest patterns come from continuity, grounded repo context, and real execution instead of purely conversational use.",
    impressive_workflows: results.slice(0, 3),
  };
}

function buildFriction(summary) {
  const examples = summary.recentThreads.slice(0, 6);
  const averageTokens = summary.totalThreadsAnalyzed > 0 ? Math.round(summary.totalTokens / summary.totalThreadsAnalyzed) : 0;
  const spawnRate = summary.totalThreadsAnalyzed > 0 ? summary.threadsWithChildren / summary.totalThreadsAnalyzed : 0;
  const projectSpread = summary.distinctProjects;
  const categories = [];

  categories.push({
    category: "Big-thread gravity",
    description: `A lot of work still accumulates inside large main threads. When the average analyzed thread is around ${averageTokens.toLocaleString()} tokens, context carry becomes part of the cost and mistakes are more likely to come from stale or overloaded state.`,
    examples: examples.slice(0, 2).map((thread) => `${thread.title} in ${thread.projectLabel} pulled ${thread.totalTokens.toLocaleString()} total tokens.`),
  });

  if (spawnRate < 0.1) {
    categories.push({
      category: "Too little parallel splitting",
      description: `The history suggests you still solve most broad tasks in one lane. That keeps control high, but it leaves review sweeps, multi-bucket bug hunts, and sidecar exploration heavier than they need to be.`,
      examples: examples.slice(2, 4).map((thread) => `${thread.title} stayed in the parent thread even though it touched ${thread.toolCalls} tool calls.`),
    });
  }

  if (projectSpread >= 5) {
    const switchExamples = summary.topProjects
      .slice(0, 2)
      .map((project) => project.projectLabel);
    categories.push({
      category: "Context switching tax",
      description: `You are carrying work across ${projectSpread} active project areas. That is productive, but it raises the odds of vague resumes, missing assumptions, and having to rebuild the current slice before you can move again.`,
      examples: [
        `${switchExamples[0] ?? "The main repo"} and ${switchExamples[1] ?? "the next active repo"} both stayed active across the same reporting window.`,
        `The reporting window still shows ${projectSpread} active project areas competing for attention.`,
      ],
    });
  }

  while (categories.length < 3) {
    categories.push({
      category: "Artifact gaps",
      description: "A lot of insight is still trapped in the thread itself. When recurring analysis does not end in a reusable artifact, you lose some of the leverage that report files and dashboards could preserve. Use handoff notes only as temporary session bridges.",
      examples: examples.slice(-2).map((thread) => `${thread.title} ended as a live thread rather than a reusable report artifact.`),
    });
  }

  return {
    intro: "The friction is less about Codex being absent and more about where context gets heavy, repeated, or hard to preserve.",
    categories: categories.slice(0, 3),
  };
}

function buildSuggestions(summary) {
  const repeatedRepo = summary.topProjects[0];
  const spawnRate = summary.totalThreadsAnalyzed > 0 ? summary.threadsWithChildren / summary.totalThreadsAnalyzed : 0;
  const additions = [
    {
      addition: "For recurring repo work, prefer reusable artifacts such as report.md or report.html for durable context. Use handoff.md only when leaving unfinished work.",
      why: `You repeatedly return to ${repeatedRepo?.projectLabel ?? "the same repos"}, so preserving conclusions outside the thread would reduce re-entry cost.`,
      prompt_scaffold: "Add under ## Documentation or ## Verification",
    },
    {
      addition: "When a task naturally splits into investigation, implementation, and verification, use sub-agents for the non-blocking slices.",
      why: spawnRate > 0 ? "You already do this in some sessions, so formalizing it would make the pattern more consistent." : "Most large sessions still stay in one lane, so this would reduce big-thread drag.",
      prompt_scaffold: "Add under ## Behavioral Rules",
    },
  ];

  const features = [
    {
      feature: "Artifacts",
      one_liner: "Turn recurring analysis into saved reports and dashboards.",
      why_for_you: "A lot of your Codex usage is real project work, so reusable outputs beat thread-only summaries when you revisit the same repo.",
      example_code: "Generate report.md, summary.json, and report.html for this analysis and link them in the final answer.",
    },
    {
      feature: "Sub-agents",
      one_liner: "Split broad work into bounded parallel lanes.",
      why_for_you: spawnRate >= 0.1 ? "You already use child threads enough that this is a workflow worth sharpening, not a new habit from scratch." : "Your larger sessions would benefit from more bounded sidecar exploration instead of carrying everything in one thread.",
      example_code: "Use 2 sub-agents: one for read-only exploration, one for verification. Keep the blocking implementation local.",
    },
    {
      feature: "Memory",
      one_liner: "Reuse durable repo context instead of re-explaining it.",
      why_for_you: `You return to ${repeatedRepo?.areaName ?? "the same codebases"} often enough that continuity is worth baking into the workflow.`,
      example_code: "Before a deep review, check relevant memory entries and keep only the durable constraints that still match the repo state.",
    },
  ];

  const patterns = [
    {
      title: "Artifact-first review",
      suggestion: "When the output is analytical, ask for files, not only chat prose.",
      detail: "This works especially well for repo reviews, telemetry summaries, and recurring status reads. It gives you something stable to revisit, diff, or share later without replaying the whole session.",
      copyable_prompt: "Analyze this repo and generate report.md, summary.json, and report.html with findings, evidence, and next steps.",
    },
    {
      title: "Two-lane execution",
      suggestion: "Keep the blocking edit local and send the side work elsewhere.",
      detail: "That pattern reduces waiting without losing control. It fits broad reviews, issue bucketing, and any task where exploration and implementation do not need the same write scope.",
      copyable_prompt: "Keep the main fix local. Use one sub-agent for read-only exploration and one for validation. Bring back only the concrete findings.",
    },
    {
      title: "Re-entry by default",
      suggestion: "When leaving unfinished repo work, leave a compact temporary pause note before stopping.",
      detail: "That gives the next session a clean re-entry point without turning handoff into a backlog. The payoff is biggest in repos you touch again and again.",
      copyable_prompt: "Create or refresh a temporary handoff.md for this pause with current slice, done work, next safe step, blockers, and verification.",
    },
  ];

  return {
    agents_md_additions: additions,
    features_to_try: features,
    usage_patterns: patterns,
  };
}

function buildOnTheHorizon(summary) {
  const topProject = summary.topProjects[0];
  const focusName = topProject?.areaName ?? "your main repo";
  return {
    intro: "The next jump is not more chat volume. It is turning Codex into repeatable workflow infrastructure around the repos you already live in.",
    opportunities: [
      {
        title: "Scheduled repo health checks",
        whats_possible: `Instead of rerunning the same repo inspection by hand, you can have Codex generate recurring health snapshots for ${focusName} with fixed outputs and diffable artifacts.`,
        how_to_try: "Pair automations with artifact generation so the result is a report, not only a thread.",
        copyable_prompt: "Review this repo and regenerate report.md, summary.json, and report.html with changed hotspots, unresolved findings, and next actions.",
      },
      {
        title: "Parallel issue bucketing",
        whats_possible: "Broad bug hunts and review sweeps can become multi-lane by default, with one lane per bucket and a parent synthesis pass. That turns one giant session into a controlled tree of smaller ones.",
        how_to_try: "Use bounded sub-agents with explicit file ownership and a strict synthesis step in the parent thread.",
        copyable_prompt: "Split this bug hunt into 3 disjoint buckets, explore them in parallel, then synthesize only the concrete risks and fixes.",
      },
      {
        title: "Artifact-backed memory loops",
        whats_possible: "The strongest future workflow is a loop where Codex reads repo state, updates memory only through approved artifacts, and hands the next session a stable starting point.",
        how_to_try: "Use reports and shared skills as the durable layer between sessions. Use handoff files only as temporary bridges that re-entry consumes.",
        copyable_prompt: "Reconstruct the current slice from repo state and the last report artifact, then continue from the next safe step.",
      },
    ],
  };
}

function buildFunEnding(summary) {
  const candidate = summary.recentThreads.find((thread) => /[?!=:]/.test(thread.title)) ?? summary.recentThreads[0];
  return {
    headline: candidate ? `${candidate.title} became one of the more memorable Codex thread titles in this window.` : "The report is grounded in real working threads, not empty telemetry.",
    detail: candidate ? `It came from ${candidate.projectLabel} on ${candidate.startedAt.slice(0, 10)} and stood out because the thread title reads like live work instead of generic bookkeeping.` : "The standout pattern is how repo-grounded the history is.",
  };
}

function buildAtAGlance(interactionStyle, whatWorks, friction, suggestions, horizon) {
  return {
    whats_working: `${interactionStyle.key_pattern} ${whatWorks.impressive_workflows?.[0]?.description ?? ""}`.trim(),
    whats_hindering: `${friction.categories?.[0]?.description ?? ""} ${friction.categories?.[1]?.description ?? ""}`.trim(),
    quick_wins: `${suggestions.features_to_try?.[0]?.why_for_you ?? ""} ${suggestions.usage_patterns?.[0]?.suggestion ?? ""}`.trim(),
    ambitious_workflows: `${horizon.opportunities?.[0]?.whats_possible ?? ""} ${horizon.opportunities?.[1]?.whats_possible ?? ""}`.trim(),
  };
}

function buildInsights(summary) {
  const project_areas = { areas: buildProjectAreas(summary) };
  const interaction_style = buildInteractionStyle(summary);
  const what_works = buildWhatWorks(summary);
  const friction_analysis = buildFriction(summary);
  const suggestions = buildSuggestions(summary);
  const on_the_horizon = buildOnTheHorizon(summary);
  const fun_ending = buildFunEnding(summary);
  const at_a_glance = buildAtAGlance(interaction_style, what_works, friction_analysis, suggestions, on_the_horizon);

  return {
    at_a_glance,
    project_areas,
    interaction_style,
    what_works,
    friction_analysis,
    suggestions,
    on_the_horizon,
    fun_ending,
  };
}

export async function generateCodexInsights(options = {}) {
  const outdir = path.resolve(options.outdir ?? DEFAULT_OUTDIR);
  const dbPath = path.join(HOME, ".codex", "state_5.sqlite");
  const days = Number.isFinite(Number(options.days)) ? Number(options.days) : null;
  const cutoffUnix = days ? Math.floor((Date.now() - days * 24 * 60 * 60 * 1000) / 1000) : null;
  const whereClause = cutoffUnix ? `where updated_at >= ${cutoffUnix}` : "";

  const threadRows = sqliteJson(
    dbPath,
    [
      "select",
      "  id, rollout_path, created_at, updated_at, cwd, title, tokens_used,",
      "  model, reasoning_effort, archived",
      "from threads",
      whereClause,
      "order by created_at asc;",
    ].join(" "),
  );

  const spawnRows = sqliteJson(dbPath, "select parent_thread_id, child_thread_id from thread_spawn_edges;");
  const childCounts = new Map();
  for (const row of spawnRows) {
    childCounts.set(row.parent_thread_id, (childCounts.get(row.parent_thread_id) ?? 0) + 1);
  }

  const threads = [];
  for (const row of threadRows) {
    const rollout = await parseRollout(row.rollout_path);
    const startedAt = toDate(rollout.startTime) ?? fromUnixSeconds(row.created_at);
    const updatedAt = fromUnixSeconds(row.updated_at) ?? startedAt;
    if (!startedAt || !updatedAt) continue;

    const totalTokens =
      rollout.totalTokens ??
      numberOrNull(row.tokens_used) ??
      numberOrZero(rollout.inputTokens) +
        numberOrZero(rollout.cacheReadTokens) +
        numberOrZero(rollout.outputTokens) +
        numberOrZero(rollout.reasoningOutputTokens);

    const toolCalls = Object.values(rollout.toolCounts).reduce((sum, value) => sum + numberOrZero(value), 0);

    threads.push({
      id: row.id,
      projectPath: row.cwd || "(unknown)",
      projectLabel: projectLabel(row.cwd),
      areaName: areaNameFromPath(row.cwd),
      title: row.title || truncate(rollout.firstUserSnippet, 80) || "(untitled thread)",
      startedAt: startedAt.toISOString(),
      updatedAt: updatedAt.toISOString(),
      dateKey: formatDateKey(startedAt),
      startedAtDisplay: formatDateTime(startedAt),
      model: row.model || null,
      reasoningEffort: row.reasoning_effort || null,
      archived: Number(row.archived) === 1,
      rolloutPath: replaceHome(row.rollout_path),
      userMessages: rollout.userMessages,
      assistantMessages: rollout.assistantMessages,
      toolCalls,
      toolCounts: rollout.toolCounts,
      childThreads: childCounts.get(row.id) ?? 0,
      firstUserSnippet: rollout.firstUserSnippet,
      inputTokens: numberOrZero(rollout.inputTokens),
      cacheReadTokens: numberOrZero(rollout.cacheReadTokens),
      outputTokens: numberOrZero(rollout.outputTokens),
      reasoningOutputTokens: numberOrZero(rollout.reasoningOutputTokens),
      totalTokens: numberOrZero(totalTokens),
    });
  }

  const substantiveThreads = threads.filter(isSubstantiveThread);
  const dates = substantiveThreads.map((thread) => thread.startedAt).sort();
  const uniqueDays = new Set(substantiveThreads.map((thread) => thread.dateKey));
  const modelSplit = aggregateCounts(substantiveThreads, (thread) => thread.model || "(unknown)");
  const reasoningSplit = aggregateCounts(substantiveThreads, (thread) => thread.reasoningEffort || "(unknown)");
  const topProjects = aggregateProjects(substantiveThreads);
  const topTools = aggregateTools(substantiveThreads);
  const recentThreads = [...substantiveThreads]
    .sort((left, right) => right.updatedAt.localeCompare(left.updatedAt))
    .slice(0, 10)
    .map((thread) => ({
      id: thread.id,
      title: thread.title,
      projectLabel: thread.projectLabel,
      startedAt: thread.startedAt,
      totalTokens: thread.totalTokens,
      toolCalls: thread.toolCalls,
      childThreads: thread.childThreads,
    }));

  const summary = {
    generatedAt: new Date().toISOString(),
    timeZone: TIME_ZONE,
    filters: { days },
    sources: {
      threadsDb: replaceHome(dbPath),
      sessionsDir: "~/.codex/sessions",
      sessionIndex: "~/.codex/session_index.jsonl",
    },
    totalThreadsScanned: threads.length,
    totalThreadsAnalyzed: substantiveThreads.length,
    totalMessages: substantiveThreads.reduce((sum, thread) => sum + thread.userMessages + thread.assistantMessages, 0),
    totalToolCalls: substantiveThreads.reduce((sum, thread) => sum + thread.toolCalls, 0),
    totalChildThreads: substantiveThreads.reduce((sum, thread) => sum + thread.childThreads, 0),
    threadsWithChildren: substantiveThreads.filter((thread) => thread.childThreads > 0).length,
    totalTokens: substantiveThreads.reduce((sum, thread) => sum + thread.totalTokens, 0),
    distinctProjects: new Set(substantiveThreads.map((thread) => thread.projectLabel)).size,
    daysActive: uniqueDays.size,
    dateRange: {
      start: dates[0]?.slice(0, 10) ?? null,
      end: dates.at(-1)?.slice(0, 10) ?? null,
    },
    modelSplit,
    reasoningSplit,
    topProjects,
    topTools,
    heatmap: aggregateHeatmap(substantiveThreads),
    recentThreads,
    threads: substantiveThreads,
  };

  const insights = buildInsights(summary);

  await fsp.mkdir(outdir, { recursive: true });

  return {
    outdir,
    summary,
    insights,
  };
}
