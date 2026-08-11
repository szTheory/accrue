#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { collectBaseline, cohortFingerprint, summarizeCohorts } from "./collect_ci_baseline.mjs";
import { renderBaseline } from "./render_ci_baseline.mjs";

function fail(message) {
  throw new Error(message);
}

function fixturePath() {
  return path.resolve(".planning/phases/226-ci-baseline-proof-semantics/fixtures/ci-baseline-cases.json");
}

function rejectsForbiddenFields(fixture) {
  for (const field of ["actor", "logs", "secret_metadata", "provider_payload", "artifact_content", "user_data"]) {
    assert.throws(
      () => collectBaseline([{ ...fixture.successful_run, [field]: "forbidden" }]),
      new RegExp(`forbidden field: ${field}`),
      `${field} is rejected`
    );
  }
  assert.throws(
    () => collectBaseline([{ ...fixture.successful_run, head_branch: undefined, raw_branch: "forbidden" }]),
    /forbidden field: raw_branch/,
    "raw branch fields are rejected"
  );
}

function datedRun(base, id, offset, overrides = {}) {
  const stamp = (seconds) => new Date(Date.parse(base.created_at) + (offset * 86_400_000) + (seconds * 1_000)).toISOString();
  return {
    ...base, id, html_url: `https://github.com/acme/accrue/actions/runs/${id}`, head_sha: `${id.toString(16).padStart(12, "0")}${"a".repeat(28)}`,
    created_at: stamp(0), run_started_at: stamp(5), updated_at: stamp(305),
    jobs: base.jobs.map((job, index) => ({ ...job, id: (id * 10) + index, html_url: `https://github.com/acme/accrue/actions/runs/${id}/job/${(id * 10) + index}`, started_at: stamp(index ? 200 : 10), completed_at: stamp(index ? 300 : 190) })),
    ...overrides
  };
}

function cohortControls(fixture) {
  const nineteen = Array.from({ length: 19 }, (_, index) => datedRun(fixture.successful_run, 200 + index, index));
  const twenty = [...nineteen, datedRun(fixture.successful_run, 220, 20)];
  const insufficient = summarizeCohorts(nineteen);
  assert.equal(insufficient[0].sample_count, 19);
  assert.equal(insufficient[0].sample_status, "insufficient_sample");
  assert.equal(insufficient[0].p50_ms, null);
  const ready = summarizeCohorts(twenty);
  assert.equal(ready[0].sample_count, 20);
  assert.equal(ready[0].sample_status, "ready");
  assert.equal(ready[0].p50_ms, 300000);
  assert.equal(ready[0].p95_ms, 300000);

  const nonRunPopulation = (event, startId) => Array.from(
    { length: 20 },
    (_, index) => datedRun(fixture.successful_run, startId + index, index, { event, provider_state: "non_run" })
  );
  const nonRunPush = nonRunPopulation("push", 230);
  const nonRunPullRequest = nonRunPopulation("pull_request", 260);
  const nonRunCohorts = summarizeCohorts([...nonRunPush, ...nonRunPullRequest]);
  assert.equal(nonRunCohorts.length, 2, "push and pull_request remain separate timing cohorts");
  for (const cohort of nonRunCohorts) {
    assert.equal(cohort.sample_count, 20, "non_run full-CI cohort has the locked sample count");
    assert.equal(cohort.sample_status, "ready", "non_run full-CI cohort is ready");
    assert.notEqual(cohort.p50_ms, null, "non_run full-CI cohort emits p50");
    assert.notEqual(cohort.p95_ms, null, "non_run full-CI cohort emits p95");
  }
  for (const run of [...nonRunPush, ...nonRunPullRequest]) {
    assert.equal(collectBaseline([run])[0].provider_state, "non_run", "timing eligibility does not manufacture provider proof");
  }

  const original = datedRun(fixture.successful_run, 301, 21, { original_run_id: 300, run_attempt: 1, conclusion: "failure" });
  const retry = datedRun(fixture.successful_run, 302, 22, { original_run_id: 300, run_attempt: 2, head_sha: original.head_sha });
  const rerun = summarizeCohorts([...twenty, original, retry])[0];
  assert.equal(rerun.sample_count, 20, "a later retry cannot inflate green samples");
  assert.equal(rerun.reliability.rerun_count, 1, "reliability retains rerun facts");

  const failed = datedRun(fixture.successful_run, 401, 23, { conclusion: "failure" });
  failed.jobs = failed.jobs.map((job) => ({ ...job, conclusion: "failure", failure_message: "Timeout request 1234567890abcdef" }));
  const failedRecords = collectBaseline([failed]).filter((record) => record.kind === "job");
  assert.equal(new Set(failedRecords.map((job) => job.failure_signature)).size, 1, "matrix failures collapse to one root signature");
  assert.deepEqual(summarizeCohorts([failed])[0].reliability.root_incidents[0].affected_cells.sort(), ["build", "test"]);
  const cancelled = datedRun(fixture.successful_run, 402, 23, { conclusion: "cancelled" });
  const skipped = datedRun(fixture.successful_run, 403, 23, { conclusion: "skipped" });
  const reliability = summarizeCohorts([failed, cancelled, skipped])[0].reliability;
  assert.equal(reliability.failure_count, 1);
  assert.equal(reliability.cancellation_count, 1);
  assert.equal(reliability.skipped_count, 1);

  const scheduled = datedRun(fixture.successful_run, 501, 24, { event: "schedule", provider_state: "non_run" });
  const dispatch = datedRun(fixture.successful_run, 502, 24, { event: "workflow_dispatch", provider_state: "misconfigured" });
  assert.notEqual(cohortFingerprint(scheduled), cohortFingerprint(dispatch), "provider-only schedule and full dispatch are separate cohorts");
  assert.equal(collectBaseline([scheduled])[0].provider_state, "non_run");
  assert.equal(collectBaseline([dispatch])[0].provider_state, "misconfigured");

  const instrumented = datedRun(fixture.successful_run, 550, 25);
  instrumented.jobs[0].cache = { hit: true, restore_ms: 12, save_ms: 2, size_bytes: 128 };
  instrumented.jobs[0].setup_costs = { node_ms: 5, npm_ms: 6, browser_ms: 7, playwright_ms: 8 };
  const instrumentedJob = collectBaseline([instrumented]).find((record) => record.kind === "job");
  assert.deepEqual(instrumentedJob.cache, { hit: true, restore_ms: 12, save_ms: 2, size_bytes: 128 });
  assert.deepEqual(instrumentedJob.setup_costs, { node_ms: 5, npm_ms: 6, browser_ms: 7, playwright_ms: 8 });

  assert.throws(() => collectBaseline([datedRun(fixture.successful_run, 601, 25, { updated_at: "not-a-time" })]), /updated_at/);
  assert.throws(() => collectBaseline([{ ...fixture.successful_run, jobs: [{ ...fixture.successful_run.jobs[0], name: "!!!" }] }]), /job.name/);
}

export function verifyFixtures() {
  const fixture = JSON.parse(fs.readFileSync(fixturePath(), "utf8"));
  for (const scenario of ["successful_first_attempt", "failure", "cancellation", "rerun", "provider_non_run", "provider_misconfigured", "repeated_matrix_signature", "privacy_rejection", "arithmetic", "insufficient_sample"]) {
    assert.ok(fixture.scenarios.includes(scenario), `fixture inventory includes ${scenario}`);
  }
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-ci-baseline-"));
  try {
    const records = collectBaseline([fixture.successful_run]);
    assert.equal(records.length, 3, "successful fixture emits run plus two jobs");
    const ndjsonPath = path.join(temp, "baseline.ndjson");
    fs.writeFileSync(ndjsonPath, `${records.map((record) => JSON.stringify(record)).join("\n")}\n`);
    const markdown = renderBaseline(records);
    assert.match(markdown, /Comparable timing/, "renderer includes timing table");
    assert.doesNotMatch(markdown, /unsafe-branch-name/, "renderer never receives raw branch name");
    const jobs = records.filter((record) => record.kind === "job");
    assert.equal(jobs[0].runner_queue_ms, 10_000, "root queue is measured from workflow creation");
    assert.equal(jobs[0].dag_wait_ms, null, "root jobs have no DAG wait");
    assert.equal(jobs[1].runner_queue_ms, null, "dependent jobs do not masquerade DAG wait as queue");
    assert.equal(jobs[1].dag_wait_ms, 10_000, "dependent wait uses latest prerequisite completion");
    rejectsForbiddenFields(fixture);
    cohortControls(fixture);
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
}

function main() {
  const args = process.argv.slice(2);
  const recordsIndex = args.indexOf("--records");
  const renderedIndex = args.indexOf("--rendered");
  if (args.includes("--fixtures")) verifyFixtures();
  if (recordsIndex !== -1) {
    const source = args[recordsIndex + 1];
    if (!source) fail("--records requires an NDJSON path");
    const records = fs.readFileSync(source, "utf8").trim().split("\n").filter(Boolean).map((line) => JSON.parse(line));
    const expected = renderBaseline(records);
    if (renderedIndex !== -1) {
      const rendered = args[renderedIndex + 1];
      if (!rendered) fail("--rendered requires a Markdown path");
      assert.equal(fs.readFileSync(rendered, "utf8"), expected, "rendered Markdown must be byte-reproducible");
    }
  }
  if (!args.includes("--fixtures") && recordsIndex === -1) fail("usage: verify_ci_baseline.mjs --fixtures | --records records.ndjson [--rendered baseline.md]");
  console.log("ci baseline fixtures: PASS");
}

try {
  main();
} catch (error) {
  console.error(`ci baseline fixtures: FAIL: ${error.message}`);
  process.exitCode = 1;
}
