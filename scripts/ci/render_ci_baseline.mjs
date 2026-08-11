#!/usr/bin/env node

import fs from "node:fs";
import { fileURLToPath } from "node:url";
import { validateRecord } from "./collect_ci_baseline.mjs";

const SAMPLE_TARGET = 20;
const HYPOTHESIS_MIN_MS = 1_980_000;
const HYPOTHESIS_MAX_MS = 2_160_000;

function escapeMarkdown(value) { return String(value).replace(/[\\|`<>]/g, (char) => `\\${char}`).replace(/[\r\n]+/g, " "); }
function milliseconds(value) { return value == null ? "—" : `${Math.round(value / 1000)}s`; }
function rows(records, kind) { return records.filter((record) => record.kind === kind); }
function percentile(values, fraction) { const ordered = [...values].sort((a, b) => a - b); return ordered[Math.ceil(fraction * ordered.length) - 1]; }
function time(value) { return Date.parse(value); }

/**
 * Derive exactly one release-gate → host-integration → latest Playwright span per
 * successful first-attempt run in a single cohort. Parallel Playwright jobs are
 * deliberately collapsed with max(completed_at), never added together.
 */
export function deriveStagedPathPercentiles(records) {
  if (!Array.isArray(records)) throw new Error("records must be an array");
  records.forEach(validateRecord);
  const jobsByRun = new Map();
  for (const job of rows(records, "job")) {
    if (!jobsByRun.has(job.run_id)) jobsByRun.set(job.run_id, []);
    jobsByRun.get(job.run_id).push(job);
  }
  const groups = new Map();
  for (const run of rows(records, "run")) {
    if (run.conclusion !== "success" || run.run_attempt !== 1) continue;
    if (!groups.has(run.cohort_fingerprint)) groups.set(run.cohort_fingerprint, []);
    groups.get(run.cohort_fingerprint).push(run);
  }
  const candidates = [];
  for (const [cohort_fingerprint, runs] of groups) {
    const firstAttempts = new Map();
    for (const run of runs.sort((left, right) => time(right.completed_at) - time(left.completed_at))) {
      const identity = `${run.original_run_id}:${run.sha}`;
      if (!firstAttempts.has(identity)) firstAttempts.set(identity, run);
    }
    const selectedRuns = [...firstAttempts.values()]
      .sort((left, right) => time(right.completed_at) - time(left.completed_at))
      .slice(0, SAMPLE_TARGET);
    const spans = [];
    const failures = [];
    for (const run of selectedRuns) {
      const jobs = jobsByRun.get(run.run_id) || [];
      const release = jobs.filter((job) => job.stable_identity === "release-gate" && job.conclusion === "success");
      const host = jobs.filter((job) => job.stable_identity === "host-integration" && job.conclusion === "success");
      const playwright = jobs.filter((job) => job.stable_identity.startsWith("playwright-e2e") && job.conclusion === "success");
      if (release.length !== 1 || host.length !== 1 || playwright.length === 0) { failures.push(`run ${run.run_id} is missing a successful ordered stage`); continue; }
      const releaseStart = time(release[0].started_at);
      const hostStart = time(host[0].started_at);
      const hostEnd = time(host[0].completed_at);
      const playwrightStart = Math.min(...playwright.map((job) => time(job.started_at)));
      const playwrightEnd = Math.max(...playwright.map((job) => time(job.completed_at)));
      if (releaseStart > hostStart || hostEnd > playwrightStart || playwrightEnd < hostEnd) { failures.push(`run ${run.run_id} has invalid release-gate → host-integration → Playwright ordering`); continue; }
      spans.push({ run_id: run.run_id, span_ms: playwrightEnd - releaseStart });
    }
    candidates.push({ cohort_fingerprint, selected_run_count: selectedRuns.length, spans, failures });
  }
  const complete = candidates.filter((candidate) => candidate.selected_run_count === SAMPLE_TARGET && candidate.spans.length === SAMPLE_TARGET);
  if (complete.length !== 1) {
    const reason = complete.length === 0
      ? (candidates.flatMap((candidate) => candidate.failures)[0] || `no cohort has ${SAMPLE_TARGET} complete staged-path observations`)
      : "multiple cohorts have complete staged-path observations; select one exact cohort";
    return { valid: false, reason, sample_count: 0, p50_ms: null, p95_ms: null, conclusion: null };
  }
  const candidate = complete[0];
  const values = candidate.spans.map((span) => span.span_ms);
  const p50_ms = percentile(values, 0.5);
  const p95_ms = percentile(values, 0.95);
  return {
    valid: true,
    cohort_fingerprint: candidate.cohort_fingerprint,
    sample_count: values.length,
    p50_ms,
    p95_ms,
    conclusion: p50_ms >= HYPOTHESIS_MIN_MS && p50_ms <= HYPOTHESIS_MAX_MS ? "confirmed" : "contrary_measured_result",
    observations: candidate.spans
  };
}

export function renderBaseline(records) {
  if (!Array.isArray(records)) throw new Error("records must be an array");
  records.forEach(validateRecord);
  const runRows = rows(records, "run"); const jobRows = rows(records, "job"); const cohortRows = rows(records, "cohort"); const snapshot = rows(records, "snapshot")[0];
  const phase225Boundary = runRows.find((run) => run.run_id === 31322443304);
  const rootJobs = jobRows.filter((job) => job.runner_queue_ms !== null); const dependentJobs = jobRows.filter((job) => job.dag_wait_ms !== null);
  const staged = deriveStagedPathPercentiles(records);
  const stagedConclusion = staged.valid ? staged.conclusion : "insufficient_sample — no critical-path percentile claim";
  const stagedFact = staged.valid
    ? `Cohort \`${escapeMarkdown(staged.cohort_fingerprint)}\` has ${staged.sample_count} complete staged-path observations. p50: ${milliseconds(staged.p50_ms)}; p95: ${milliseconds(staged.p95_ms)}.`
    : `No valid staged-path percentile conclusion: ${escapeMarkdown(staged.reason)}.`;
  return [
    "# CI Baseline", "", "## Current fact", "", `**State:** ${stagedConclusion}. **Owner:** CI maintainers. **Next command:** \`node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path\`. Evidence is the immutable Actions links below.`, "", "Privacy-safe, schema-v1 evidence. Raw logs, actors, branches, secrets, payloads, and artifact contents are not persisted.", "",
    "## Comparable cohort", "", snapshot ? `Snapshot generated: ${snapshot.snapshot_generated_at}. Window: ${snapshot.window_start} to ${snapshot.window_end}. Target: ${snapshot.sample_target}.` : "Snapshot metadata unavailable.", phase225Boundary ? `Immediate Phase 225 repair boundary: run [31322443304](${phase225Boundary.run_url}) at SHA \`${phase225Boundary.sha}\`. It is retained as evidence, not substituted for the full cohort.` : "Phase 225 repair boundary is unavailable from this snapshot.", "", "### Comparable timing", "", "| Run | Cohort | State | Wall time | Evidence |", "| --- | --- | --- | --- | --- |",
    ...runRows.map((run) => `| ${run.run_id} | ${escapeMarkdown(run.cohort_fingerprint)} | ${run.conclusion} | ${milliseconds(run.workflow_duration_ms)} | [run](${run.run_url}) |`), "",
    "## Measured critical path", "", `Expected staged release → host integration → Playwright path (33–36 minutes): **${stagedConclusion}**. ${stagedFact} Parallel Playwright shards contribute their latest completion only; no named-job aggregate is a critical-path percentile.`, "", "| Cohort | Qualifying successes | Status | p50 | p95 |", "| --- | --- | --- | --- | --- |",
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
