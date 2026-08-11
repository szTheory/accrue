#!/usr/bin/env node

import fs from "node:fs";
import { fileURLToPath } from "node:url";
import { validateRecord } from "./collect_ci_baseline.mjs";

function escapeMarkdown(value) { return String(value).replace(/[\\|`<>]/g, (char) => `\\${char}`).replace(/[\r\n]+/g, " "); }
function milliseconds(value) { return value == null ? "—" : `${Math.round(value / 1000)}s`; }
function rows(records, kind) { return records.filter((record) => record.kind === kind); }
function percentile(values, fraction) { const ordered = [...values].sort((left, right) => left - right); return ordered[Math.ceil(fraction * ordered.length) - 1]; }

export function deriveStagedPathPercentiles(records) {
  if (!Array.isArray(records)) throw new Error("records must be an array");
  records.forEach(validateRecord);
  const runRows = rows(records, "run");
  const jobRows = rows(records, "job");
  const candidates = runRows
    .filter((run) => run.event_class !== "schedule" && run.conclusion === "success" && run.run_attempt === 1)
    .sort((left, right) => Date.parse(right.completed_at) - Date.parse(left.completed_at));
  const identities = new Set();
  for (const run of candidates) {
    const identity = `${run.original_run_id}:${run.sha}`;
    if (identities.has(identity)) throw new Error("critical path requires 20 unique successful first-attempt run/SHA identities");
    identities.add(identity);
  }
  const selected = [];
  for (const run of candidates) {
    const jobs = jobRows.filter((job) => job.run_id === run.run_id && job.conclusion === "success");
    const release = jobs.find((job) => job.stable_identity === "release-gate");
    const host = jobs.find((job) => job.stable_identity === "host-integration");
    // GitHub preserves matrix shard labels in job names (for example,
    // `playwright-e2e-shard-1/3`).  These are parallel instances of the same
    // Playwright stage, so include every stable shard identity in the path and
    // use only the latest completion below; never sum shard durations.
    const playwright = jobs.filter((job) => job.stable_identity === "playwright-e2e" || job.stable_identity.startsWith("playwright-e2e-"));
    if (!release) throw new Error("critical path is missing release-gate stage");
    if (!host) throw new Error("critical path is missing host-integration stage");
    if (playwright.length === 0) throw new Error("critical path is missing playwright-e2e stage");
    if (Date.parse(release.completed_at) > Date.parse(host.started_at)) throw new Error("critical path host-integration stage must start after release-gate");
    if (playwright.some((job) => Date.parse(job.started_at) < Date.parse(host.completed_at))) throw new Error("critical path Playwright stage must start after host-integration");
    selected.push({ run, span_ms: Date.parse(playwright.reduce((latest, job) => Date.parse(job.completed_at) > Date.parse(latest.completed_at) ? job : latest).completed_at) - Date.parse(release.started_at) });
    if (selected.length === 20) break;
  }
  if (selected.length < 20) throw new Error("critical path requires 20 compatible complete paths");
  const samples = selected.map(({ span_ms }) => span_ms);
  const fingerprint_distribution = [...selected.reduce((strata, { run, span_ms }) => {
    if (!strata.has(run.cohort_fingerprint)) strata.set(run.cohort_fingerprint, []);
    strata.get(run.cohort_fingerprint).push(span_ms);
    return strata;
  }, new Map()).entries()].sort(([left], [right]) => left.localeCompare(right)).map(([cohort_fingerprint, spans]) => ({
    cohort_fingerprint,
    sample_count: spans.length,
    range_ms: { min: Math.min(...spans), max: Math.max(...spans) },
    p50_ms: spans.length >= 2 ? percentile(spans, 0.5) : null,
    p95_ms: spans.length >= 2 ? percentile(spans, 0.95) : null
  }));
  const p50_ms = percentile(samples, 0.5);
  const p95_ms = percentile(samples, 0.95);
  return {
    sample_count: samples.length,
    samples,
    fingerprint_distribution,
    p50_ms,
    p95_ms,
    conclusion: p50_ms >= 1_980_000 && p50_ms <= 2_160_000 ? "confirmed" : "contrary_measured_result"
  };
}

export function renderBaseline(records) {
  if (!Array.isArray(records)) throw new Error("records must be an array");
  records.forEach(validateRecord);
  const runRows = rows(records, "run");
  const jobRows = rows(records, "job");
  const cohortRows = rows(records, "cohort");
  const snapshot = rows(records, "snapshot")[0];
  const phase225Boundary = runRows.find((run) => run.run_id === 31322443304);
  const rootJobs = jobRows.filter((job) => job.runner_queue_ms !== null);
  const dependentJobs = jobRows.filter((job) => job.dag_wait_ms !== null);
  let staged = null;
  try { staged = deriveStagedPathPercentiles(records); } catch { /* Rendering remains useful for incomplete evidence; the verifier is fail-closed. */ }
  const stagedConclusion = staged?.conclusion || "insufficient_sample — no critical-path percentile claim";
  return [
    "# CI Baseline", "", "## Current fact", "", `**State:** ${stagedConclusion}. **Owner:** CI maintainers. **Next command:** \`node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md\`. Evidence is the immutable Actions links below.`, "", "Privacy-safe, schema-v1 evidence. Raw logs, actors, branches, secrets, payloads, and artifact contents are not persisted.", "",
    "## Comparable cohort", "", snapshot ? `Snapshot generated: ${snapshot.snapshot_generated_at}. Window: ${snapshot.window_start} to ${snapshot.window_end}. Target: ${snapshot.sample_target}.` : "Snapshot metadata unavailable.", phase225Boundary ? `Immediate Phase 225 repair boundary: run [31322443304](${phase225Boundary.run_url}) at SHA \`${phase225Boundary.sha}\`. It is retained as evidence, not substituted for the full cohort.` : "Phase 225 repair boundary is unavailable from this snapshot.", "", "### Comparable timing", "", "| Run | Cohort | State | Wall time | Evidence |", "| --- | --- | --- | --- | --- |",
    ...runRows.map((run) => `| ${run.run_id} | ${escapeMarkdown(run.cohort_fingerprint)} | ${run.conclusion} | ${milliseconds(run.workflow_duration_ms)} | [run](${run.run_url}) |`), "",
    "## Measured critical path", "", staged ? `Expected staged release → host integration → Playwright path (33–36 minutes): **${stagedConclusion}**. Latest compatible complete paths: ${staged.sample_count}; staged-path p50: ${milliseconds(staged.p50_ms)}; staged-path p95: ${milliseconds(staged.p95_ms)}. Each observation measures release-gate start through the latest Playwright shard completion after host-integration; parallel shards are never summed.` : `Expected staged release → host integration → Playwright path (33–36 minutes): **${stagedConclusion}**. No aggregate named-path total is a critical-path percentile.`, "", staged ? "### Fingerprint strata and sensitivity" : "", staged ? "Topology fingerprints remain visible strata; they are not an all-or-nothing availability gate." : "", staged ? "| Fingerprint | Count | Sensitivity range | Sensitivity p50 | Sensitivity p95 |" : "", staged ? "| --- | --- | --- | --- | --- |" : "", ...(staged ? staged.fingerprint_distribution.map((stratum) => `| ${escapeMarkdown(stratum.cohort_fingerprint)} | ${stratum.sample_count} | ${milliseconds(stratum.range_ms.min)}–${milliseconds(stratum.range_ms.max)} | ${milliseconds(stratum.p50_ms)} | ${milliseconds(stratum.p95_ms)} |`) : []), "", "| Cohort | Qualifying successes | Status | p50 | p95 |", "| --- | --- | --- | --- | --- |",
    ...cohortRows.map((cohort) => `| ${escapeMarkdown(cohort.cohort_fingerprint)} | ${cohort.sample_count} | ${cohort.sample_status} | ${milliseconds(cohort.p50_ms)} | ${milliseconds(cohort.p95_ms)} |`), "",
    "## Setup and cache costs", "", "| Job | Setup costs | Cache facts | Evidence |", "| --- | --- | --- | --- |", ...jobRows.filter((job) => Object.keys(job.setup_costs).length || Object.keys(job.cache).length).map((job) => `| ${escapeMarkdown(job.stable_identity)} | ${escapeMarkdown(JSON.stringify(job.setup_costs))} | ${escapeMarkdown(JSON.stringify(job.cache))} | [job](${job.job_url}) |`), "",
    "## Provider state", "", "All full-CI timing runs are recorded as `non_run` for provider proof; a successful workflow is not live-provider proof. See the Phase 226 provider-proof evidence for the independent provider state.", "",
    "## Reliability", "", `Root-job runner queue observations: ${rootJobs.length}. Dependent DAG-wait observations: ${dependentJobs.length}.`, "", "| Job | State | Runner queue | DAG wait | Duration | Evidence |", "| --- | --- | --- | --- | --- |", ...jobRows.map((job) => `| ${escapeMarkdown(job.stable_identity)} | ${job.conclusion} | ${milliseconds(job.runner_queue_ms)} | ${milliseconds(job.dag_wait_ms)} | ${milliseconds(job.duration_ms)} | [job](${job.job_url}) |`), "",
    "## Exclusions", "", "Failed, cancelled, skipped, and rerun attempts remain reliability evidence and never fill percentile samples. Scheduled/provider-only topologies remain outside full-CI timing cohorts. Raw logs, artifact contents, actors, raw branch names, payloads, and secrets are excluded.", "",
    "## Reproduce", "", "```sh", "gh auth status", "node scripts/ci/collect_ci_baseline.mjs --repo szTheory/accrue --workflow ci.yml --window-days 90 --sample-size 20 --out .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson", "node scripts/ci/render_ci_baseline.mjs --input .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --out /tmp/226-CI-BASELINE.md", "cmp /tmp/226-CI-BASELINE.md .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md", "node scripts/ci/verify_ci_baseline.mjs --fixtures", "```", ""
  ].join("\n");
}

function main() {
  const args = process.argv.slice(2); const input = args[args.indexOf("--input") + 1]; const out = args[args.indexOf("--out") + 1];
  if (!input) throw new Error("usage: render_ci_baseline.mjs --input records.ndjson [--out baseline.md]");
  const records = fs.readFileSync(input, "utf8").trim().split("\n").filter(Boolean).map((line) => JSON.parse(line));
  const output = renderBaseline(records); if (out) fs.writeFileSync(out, output); else process.stdout.write(output);
}
if (process.argv[1] === fileURLToPath(import.meta.url)) { try { main(); } catch (error) { console.error(`render ci baseline: FAIL: ${error.message}`); process.exitCode = 1; } }
