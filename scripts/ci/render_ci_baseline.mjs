#!/usr/bin/env node

import fs from "node:fs";
import { fileURLToPath } from "node:url";
import { validateRecord } from "./collect_ci_baseline.mjs";

function escapeMarkdown(value) { return String(value).replace(/[\\|`<>]/g, (char) => `\\${char}`).replace(/[\r\n]+/g, " "); }
function milliseconds(value) { return value == null ? "—" : `${Math.round(value / 1000)}s`; }
function rows(records, kind) { return records.filter((record) => record.kind === kind); }

export function renderBaseline(records) {
  if (!Array.isArray(records)) throw new Error("records must be an array");
  records.forEach(validateRecord);
  const runRows = rows(records, "run");
  const jobRows = rows(records, "job");
  const cohortRows = rows(records, "cohort");
  const snapshot = rows(records, "snapshot")[0];
  const rootJobs = jobRows.filter((job) => job.runner_queue_ms !== null);
  const dependentJobs = jobRows.filter((job) => job.dag_wait_ms !== null);
  const pathJobs = jobRows.filter((job) => /release-gate|host-integration|playwright-e2e/.test(job.stable_identity));
  const pathDuration = pathJobs.reduce((total, job) => total + job.duration_ms + (job.dag_wait_ms || 0), 0);
  const stagedConclusion = cohortRows.some((cohort) => cohort.sample_status === "ready") ? (pathDuration >= 1_980_000 && pathDuration <= 2_160_000 ? "confirmed" : "contrary measured result") : "insufficient_sample — no critical-path percentile claim";
  return [
    "# CI Baseline", "", "## Current fact", "", `**State:** ${stagedConclusion}. **Owner:** CI maintainers. **Next command:** \`node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md\`. Evidence is the immutable Actions links below.`, "", "Privacy-safe, schema-v1 evidence. Raw logs, actors, branches, secrets, payloads, and artifact contents are not persisted.", "",
    "## Comparable cohort", "", snapshot ? `Snapshot generated: ${snapshot.snapshot_generated_at}. Window: ${snapshot.window_start} to ${snapshot.window_end}. Target: ${snapshot.sample_target}.` : "Snapshot metadata unavailable.", "", "### Comparable timing", "", "| Run | Cohort | State | Wall time | Evidence |", "| --- | --- | --- | --- | --- |",
    ...runRows.map((run) => `| ${run.run_id} | ${escapeMarkdown(run.cohort_fingerprint)} | ${run.conclusion} | ${milliseconds(run.workflow_duration_ms)} | [run](${run.run_url}) |`), "",
    "## Measured critical path", "", `Expected staged release → host integration → Playwright path (33–36 minutes): **${stagedConclusion}**. Measured named-path work plus recorded DAG waits: ${milliseconds(pathDuration)}. This is not runner queue time.`, "", "| Cohort | Qualifying successes | Status | p50 | p95 |", "| --- | --- | --- | --- | --- |",
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
