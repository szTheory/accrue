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

  const original = datedRun(fixture.successful_run, 301, 21, { original_run_id: 300, run_attempt: 1, conclusion: "failure" });
  const retry = datedRun(fixture.successful_run, 302, 22, { original_run_id: 300, run_attempt: 2 });
  const rerun = summarizeCohorts([...twenty, original, retry])[0];
  assert.equal(rerun.sample_count, 20, "a later retry cannot inflate green samples");
  assert.equal(rerun.reliability.rerun_count, 1, "reliability retains rerun facts");

  const failed = datedRun(fixture.successful_run, 401, 23, { conclusion: "failure", jobs: fixture.successful_run.jobs.map((job, index) => ({ ...job, id: 4010 + index, html_url: `https://github.com/acme/accrue/actions/runs/401/job/${4010 + index}`, conclusion: "failure", failure_message: "Timeout request 1234567890abcdef" })) });
  const failedRecords = collectBaseline([failed]).filter((record) => record.kind === "job");
  assert.equal(new Set(failedRecords.map((job) => job.failure_signature)).size, 1, "matrix failures collapse to one root signature");
  assert.deepEqual(summarizeCohorts([failed])[0].reliability.root_incidents[0].affected_cells.sort(), ["build", "test"]);

  const scheduled = datedRun(fixture.successful_run, 501, 24, { event: "schedule", provider_state: "non_run" });
  const dispatch = datedRun(fixture.successful_run, 502, 24, { event: "workflow_dispatch", provider_state: "misconfigured" });
  assert.notEqual(cohortFingerprint(scheduled), cohortFingerprint(dispatch), "provider-only schedule and full dispatch are separate cohorts");
  assert.equal(collectBaseline([scheduled])[0].provider_state, "non_run");
  assert.equal(collectBaseline([dispatch])[0].provider_state, "misconfigured");

  assert.throws(() => collectBaseline([datedRun(fixture.successful_run, 601, 25, { updated_at: "not-a-time" })]), /updated_at/);
  assert.throws(() => collectBaseline([{ ...fixture.successful_run, jobs: [{ ...fixture.successful_run.jobs[0], name: "!!!" }] }]), /job.name/);
}

export function verifyFixtures() {
  const fixture = JSON.parse(fs.readFileSync(fixturePath(), "utf8"));
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-ci-baseline-"));
  try {
    const records = collectBaseline([fixture.successful_run]);
    assert.equal(records.length, 3, "successful fixture emits run plus two jobs");
    const ndjsonPath = path.join(temp, "baseline.ndjson");
    fs.writeFileSync(ndjsonPath, `${records.map((record) => JSON.stringify(record)).join("\n")}\n`);
    const markdown = renderBaseline(records);
    assert.match(markdown, /Comparable timing/, "renderer includes timing table");
    assert.doesNotMatch(markdown, /unsafe-branch-name/, "renderer never receives raw branch name");
    rejectsForbiddenFields(fixture);
    cohortControls(fixture);
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
}

function main() {
  if (!process.argv.includes("--fixtures")) fail("usage: verify_ci_baseline.mjs --fixtures");
  verifyFixtures();
  console.log("ci baseline fixtures: PASS");
}

try {
  main();
} catch (error) {
  console.error(`ci baseline fixtures: FAIL: ${error.message}`);
  process.exitCode = 1;
}
