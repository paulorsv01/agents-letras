function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function escapeHtmlWithBold(text) {
  return escapeHtml(text).replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");
}

function markdownParagraphs(text) {
  if (!text) return "";
  return text
    .split("\n\n")
    .map((paragraph) => `<p>${escapeHtmlWithBold(paragraph).replace(/\n/g, "<br>")}</p>`)
    .join("\n");
}

function buildHeatmap(grid) {
  const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const maxValue = Math.max(...grid.flat(), 1);
  return `
    <div class="heatmap-grid">
      <div class="heatmap-corner"></div>
      ${Array.from({ length: 24 }, (_, hour) => `<div class="heatmap-label">${String(hour).padStart(2, "0")}</div>`).join("")}
      ${grid
        .map(
          (row, rowIndex) => `
            <div class="heatmap-label weekday">${weekdays[rowIndex]}</div>
            ${row
              .map((value) => {
                const alpha = value === 0 ? 0.08 : 0.18 + (value / maxValue) * 0.72;
                return `<div class="heatmap-cell" title="${value} thread(s)" style="background: rgba(17, 24, 39, ${alpha.toFixed(3)});"></div>`;
              })
              .join("")}
          `,
        )
        .join("")}
    </div>
  `;
}

export function buildMarkdownReport(summary, insights, artifactPaths) {
  const atAGlance = insights.at_a_glance;
  const stats = [
    `${summary.totalThreadsScanned.toLocaleString()} threads scanned`,
    `${summary.totalThreadsAnalyzed.toLocaleString()} analyzed`,
    `${summary.totalMessages.toLocaleString()} messages`,
    `${summary.totalToolCalls.toLocaleString()} tool calls`,
    `${summary.totalChildThreads.toLocaleString()} child threads`,
  ].join(" · ");

  return `# Codex Insights

${stats}
${summary.dateRange.start ?? "n/a"} to ${summary.dateRange.end ?? "n/a"}

## At a Glance

**What's working:** ${atAGlance?.whats_working ?? "n/a"}

**What's hindering you:** ${atAGlance?.whats_hindering ?? "n/a"}

**Quick wins to try:** ${atAGlance?.quick_wins ?? "n/a"}

**Ambitious workflows:** ${atAGlance?.ambitious_workflows ?? "n/a"}

## Artifacts

- JSON data: \`${artifactPaths.reportJson}\`
- Summary data: \`${artifactPaths.summaryJson}\`
- Insights data: \`${artifactPaths.insightsJson}\`
- HTML report: \`${artifactPaths.reportHtml}\`

## Top Project Areas

${(insights.project_areas?.areas ?? [])
  .map((area) => `- **${area.name}** (${area.session_count} sessions): ${area.description}`)
  .join("\n")}

## Interaction Style

${insights.interaction_style?.narrative ?? "n/a"}

## Impressive Things You Did

${(insights.what_works?.impressive_workflows ?? [])
  .map((item) => `- **${item.title}**: ${item.description}`)
  .join("\n")}

## Where Things Go Wrong

${(insights.friction_analysis?.categories ?? [])
  .map((item) => `- **${item.category}**: ${item.description}`)
  .join("\n")}

## Existing Codex Features to Try

${(insights.suggestions?.features_to_try ?? [])
  .map((item) => `- **${item.feature}**: ${item.why_for_you}`)
  .join("\n")}

## New Ways to Use Codex

${(insights.suggestions?.usage_patterns ?? [])
  .map((item) => `- **${item.title}**: ${item.suggestion}`)
  .join("\n")}

## On the Horizon

${(insights.on_the_horizon?.opportunities ?? [])
  .map((item) => `- **${item.title}**: ${item.whats_possible}`)
  .join("\n")}
`;
}

export function buildHtmlReport(summary, insights) {
  const atAGlance = insights.at_a_glance ?? {};
  const projectAreas = insights.project_areas?.areas ?? [];
  const whatWorks = insights.what_works?.impressive_workflows ?? [];
  const friction = insights.friction_analysis?.categories ?? [];
  const features = insights.suggestions?.features_to_try ?? [];
  const patterns = insights.suggestions?.usage_patterns ?? [];
  const horizon = insights.on_the_horizon?.opportunities ?? [];
  const memoryAdditions = insights.suggestions?.agents_md_additions ?? [];
  const funEnding = insights.fun_ending;

  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Codex Insights</title>
    <style>
      * { box-sizing: border-box; }
      body {
        margin: 0;
        font-family: "Inter", "SF Pro Display", "Segoe UI", sans-serif;
        background: linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
        color: #0f172a;
        line-height: 1.6;
      }
      .page { max-width: 1040px; margin: 0 auto; padding: 40px 24px 80px; }
      .hero {
        background: radial-gradient(circle at top left, rgba(59, 130, 246, 0.18), transparent 38%),
          radial-gradient(circle at top right, rgba(16, 185, 129, 0.14), transparent 42%),
          #ffffff;
        border: 1px solid rgba(148, 163, 184, 0.26);
        border-radius: 28px;
        padding: 28px;
        box-shadow: 0 24px 80px rgba(15, 23, 42, 0.08);
      }
      h1, h2, h3 { margin: 0 0 12px; line-height: 1.1; }
      h1 { font-size: clamp(2rem, 5vw, 3.4rem); }
      h2 { font-size: 1.55rem; margin-top: 40px; }
      h3 { font-size: 1.05rem; }
      p { margin: 0 0 14px; color: #334155; }
      .meta { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 18px; }
      .pill {
        padding: 8px 12px;
        border-radius: 999px;
        background: rgba(15, 23, 42, 0.06);
        color: #0f172a;
        font-size: 0.92rem;
      }
      .grid { display: grid; gap: 18px; }
      .glance-grid, .cards { grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); }
      .card {
        background: #ffffff;
        border: 1px solid rgba(148, 163, 184, 0.22);
        border-radius: 22px;
        padding: 20px;
        box-shadow: 0 16px 44px rgba(15, 23, 42, 0.06);
      }
      .card strong { color: #020617; }
      .section-intro { max-width: 70ch; }
      .list { display: grid; gap: 14px; }
      .muted { color: #64748b; font-size: 0.95rem; }
      .heatmap-wrap { overflow-x: auto; }
      .heatmap-grid {
        display: grid;
        grid-template-columns: repeat(25, minmax(20px, 1fr));
        gap: 6px;
        min-width: 720px;
        align-items: center;
      }
      .heatmap-label { font-size: 0.75rem; color: #64748b; text-align: center; }
      .weekday { text-align: right; padding-right: 8px; }
      .heatmap-cell {
        width: 100%;
        aspect-ratio: 1;
        border-radius: 7px;
        border: 1px solid rgba(148, 163, 184, 0.12);
      }
      .fun-ending {
        margin-top: 36px;
        padding: 24px;
        border-radius: 24px;
        background: #0f172a;
        color: #e2e8f0;
      }
      .fun-ending p { color: #cbd5e1; }
      code {
        display: block;
        white-space: pre-wrap;
        word-break: break-word;
        padding: 12px 14px;
        border-radius: 14px;
        background: rgba(15, 23, 42, 0.06);
        color: #0f172a;
        margin-top: 12px;
      }
      @media (max-width: 720px) {
        .page { padding: 20px 16px 56px; }
        .hero, .card { padding: 18px; border-radius: 18px; }
      }
    </style>
  </head>
  <body>
    <main class="page">
      <section class="hero">
        <h1>Codex Insights</h1>
        <p class="section-intro">A fixed artifact pipeline over <code>~/.codex/state_5.sqlite</code> and the rollout JSONL archive. This mirrors the Claude <code>/insights</code> shape, but uses Codex session data and a deterministic renderer.</p>
        <div class="meta">
          <span class="pill">${summary.totalThreadsScanned.toLocaleString()} threads scanned</span>
          <span class="pill">${summary.totalThreadsAnalyzed.toLocaleString()} analyzed</span>
          <span class="pill">${summary.totalMessages.toLocaleString()} messages</span>
          <span class="pill">${summary.totalToolCalls.toLocaleString()} tool calls</span>
          <span class="pill">${summary.totalChildThreads.toLocaleString()} child threads</span>
          <span class="pill">${summary.dateRange.start ?? "n/a"} to ${summary.dateRange.end ?? "n/a"}</span>
        </div>
      </section>

      <h2>At a Glance</h2>
      <section class="grid glance-grid">
        <article class="card"><h3>What's working</h3><p>${escapeHtmlWithBold(atAGlance.whats_working ?? "")}</p></article>
        <article class="card"><h3>What's hindering you</h3><p>${escapeHtmlWithBold(atAGlance.whats_hindering ?? "")}</p></article>
        <article class="card"><h3>Quick wins</h3><p>${escapeHtmlWithBold(atAGlance.quick_wins ?? "")}</p></article>
        <article class="card"><h3>Ambitious workflows</h3><p>${escapeHtmlWithBold(atAGlance.ambitious_workflows ?? "")}</p></article>
      </section>

      <h2>What You Work On</h2>
      <section class="grid cards">
        ${projectAreas
          .map(
            (area) => `
              <article class="card">
                <h3>${escapeHtml(area.name)}</h3>
                <p class="muted">~${area.session_count} analyzed sessions</p>
                <p>${escapeHtml(area.description)}</p>
              </article>
            `,
          )
          .join("")}
      </section>

      <h2>How You Use Codex</h2>
      <section class="card">
        ${markdownParagraphs(insights.interaction_style?.narrative ?? "")}
        <p><strong>Key pattern:</strong> ${escapeHtml(insights.interaction_style?.key_pattern ?? "")}</p>
      </section>

      <h2>Impressive Things You Did</h2>
      <section class="grid cards">
        ${whatWorks
          .map(
            (item) => `
              <article class="card">
                <h3>${escapeHtml(item.title)}</h3>
                <p>${escapeHtml(item.description)}</p>
              </article>
            `,
          )
          .join("")}
      </section>

      <h2>Where Things Go Wrong</h2>
      <section class="grid cards">
        ${friction
          .map(
            (item) => `
              <article class="card">
                <h3>${escapeHtml(item.category)}</h3>
                <p>${escapeHtml(item.description)}</p>
                <div class="list">
                  ${(item.examples ?? []).map((example) => `<p class="muted">${escapeHtml(example)}</p>`).join("")}
                </div>
              </article>
            `,
          )
          .join("")}
      </section>

      <h2>Existing Codex Features to Try</h2>
      <section class="grid cards">
        ${features
          .map(
            (item) => `
              <article class="card">
                <h3>${escapeHtml(item.feature)}</h3>
                <p>${escapeHtml(item.one_liner)}</p>
                <p><strong>Why for you:</strong> ${escapeHtml(item.why_for_you)}</p>
                ${item.example_code ? `<code>${escapeHtml(item.example_code)}</code>` : ""}
              </article>
            `,
          )
          .join("")}
      </section>

      <h2>New Ways to Use Codex</h2>
      <section class="grid cards">
        ${patterns
          .map(
            (item) => `
              <article class="card">
                <h3>${escapeHtml(item.title)}</h3>
                <p>${escapeHtml(item.suggestion)}</p>
                <p class="muted">${escapeHtml(item.detail ?? "")}</p>
                ${item.copyable_prompt ? `<code>${escapeHtml(item.copyable_prompt)}</code>` : ""}
              </article>
            `,
          )
          .join("")}
      </section>

      <h2>Suggested AGENTS Additions</h2>
      <section class="grid cards">
        ${memoryAdditions
          .map(
            (item) => `
              <article class="card">
                <h3>${escapeHtml(item.prompt_scaffold ?? "AGENTS.md suggestion")}</h3>
                <p>${escapeHtml(item.addition)}</p>
                <p class="muted">${escapeHtml(item.why)}</p>
              </article>
            `,
          )
          .join("")}
      </section>

      <h2>On the Horizon</h2>
      <section class="grid cards">
        ${horizon
          .map(
            (item) => `
              <article class="card">
                <h3>${escapeHtml(item.title)}</h3>
                <p>${escapeHtml(item.whats_possible)}</p>
                <p class="muted">${escapeHtml(item.how_to_try ?? "")}</p>
                ${item.copyable_prompt ? `<code>${escapeHtml(item.copyable_prompt)}</code>` : ""}
              </article>
            `,
          )
          .join("")}
      </section>

      <h2>When You Use Codex</h2>
      <section class="card heatmap-wrap">
        <p class="section-intro">Weekly activity heatmap based on analyzed thread start times.</p>
        ${buildHeatmap(summary.heatmap)}
      </section>

      <h2>Recent Active Threads</h2>
      <section class="grid cards">
        ${summary.recentThreads
          .map(
            (thread) => `
              <article class="card">
                <h3>${escapeHtml(thread.title)}</h3>
                <p>${escapeHtml(thread.projectLabel)}</p>
                <p class="muted">${escapeHtml(thread.startedAt.slice(0, 10))} · ${thread.totalTokens.toLocaleString()} total tokens · ${thread.toolCalls} tool calls · ${thread.childThreads} child threads</p>
              </article>
            `,
          )
          .join("")}
      </section>

      <section class="fun-ending">
        <h2>${escapeHtml(funEnding?.headline ?? "Memorable Moment")}</h2>
        <p>${escapeHtml(funEnding?.detail ?? "")}</p>
      </section>
    </main>
  </body>
</html>`;
}
