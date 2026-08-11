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
  return [
    "# CI Baseline", "", "Privacy-safe, schema-v1 evidence. Raw logs, actors, branches, secrets, payloads, and artifacts are not persisted.", "",
    "## Comparable timing", "", "| Run | Cohort | State | Wall time | Evidence |", "| --- | --- | --- | --- | --- |",
    ...runRows.map((run) => `| ${run.run_id} | ${escapeMarkdown(run.cohort_fingerprint)} | ${run.conclusion} | ${milliseconds(run.workflow_duration_ms)} | [run](${run.run_url}) |`), "",
    "## Cohort claims", "", "| Cohort | Qualifying successes | Status | p50 | p95 |", "| --- | --- | --- | --- | --- |",
    ...cohortRows.map((cohort) => `| ${escapeMarkdown(cohort.cohort_fingerprint)} | ${cohort.sample_count} | ${cohort.sample_status} | ${milliseconds(cohort.p50_ms)} | ${milliseconds(cohort.p95_ms)} |`), "",
    "## Reliability and job timing", "", "| Job | State | Runner queue | DAG wait | Duration | Evidence |", "| --- | --- | --- | --- | --- |",
    ...jobRows.map((job) => `| ${escapeMarkdown(job.stable_identity)} | ${job.conclusion} | ${milliseconds(job.runner_queue_ms)} | ${milliseconds(job.dag_wait_ms)} | ${milliseconds(job.duration_ms)} | [job](${job.job_url}) |`), ""
  ].join("\n");
}

function main() {
  const args = process.argv.slice(2); const input = args[args.indexOf("--input") + 1]; const out = args[args.indexOf("--out") + 1];
  if (!input) throw new Error("usage: render_ci_baseline.mjs --input records.ndjson [--out baseline.md]");
  const records = fs.readFileSync(input, "utf8").trim().split("\n").filter(Boolean).map((line) => JSON.parse(line));
  const output = renderBaseline(records); if (out) fs.writeFileSync(out, output); else process.stdout.write(output);
}
if (process.argv[1] === fileURLToPath(import.meta.url)) { try { main(); } catch (error) { console.error(`render ci baseline: FAIL: ${error.message}`); process.exitCode = 1; } }
