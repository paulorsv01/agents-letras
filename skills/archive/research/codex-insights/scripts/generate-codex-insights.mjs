#!/usr/bin/env node

import fsp from "node:fs/promises";
import path from "node:path";
import { generateCodexInsights } from "./codex-insights-core.mjs";
import { buildHtmlReport, buildMarkdownReport } from "./codex-insights-render.mjs";

function parseArgs(argv) {
  const options = {};

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--outdir") {
      options.outdir = argv[index + 1];
      index += 1;
      continue;
    }
    if (arg === "--days") {
      options.days = Number(argv[index + 1]);
      index += 1;
    }
  }

  return options;
}

const options = parseArgs(process.argv.slice(2));
const { outdir, summary, insights } = await generateCodexInsights(options);

const artifactPaths = {
  summaryJson: path.join(outdir, "summary.json"),
  insightsJson: path.join(outdir, "insights.json"),
  reportJson: path.join(outdir, "report.json"),
  reportMd: path.join(outdir, "report.md"),
  reportHtml: path.join(outdir, "report.html"),
};

const report = {
  generatedAt: summary.generatedAt,
  sources: summary.sources,
  filters: summary.filters,
  summary,
  insights,
};

await fsp.writeFile(artifactPaths.summaryJson, JSON.stringify(summary, null, 2));
await fsp.writeFile(artifactPaths.insightsJson, JSON.stringify(insights, null, 2));
await fsp.writeFile(artifactPaths.reportJson, JSON.stringify(report, null, 2));
await fsp.writeFile(artifactPaths.reportMd, buildMarkdownReport(summary, insights, artifactPaths));
await fsp.writeFile(artifactPaths.reportHtml, buildHtmlReport(summary, insights));

console.log(
  JSON.stringify(
    {
      outdir,
      artifacts: artifactPaths,
      totals: {
        scanned: summary.totalThreadsScanned,
        analyzed: summary.totalThreadsAnalyzed,
      },
    },
    null,
    2,
  ),
);
