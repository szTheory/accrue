#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import {
  classifyProviderProof,
  deriveFreshness,
  validateProviderManifest,
} from "./provider_proof.mjs";
import { renderProviderSummary } from "./render_provider_summary.mjs";

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const fixturesPath = path.join(root, ".planning/phases/226-ci-baseline-proof-semantics/fixtures/provider-proof-cases.json");

function rejects(fn, pattern) {
  assert.throws(fn, pattern);
}

function validManifest(overrides = {}) {
  return {
    schema_version: 1,
    selected_count: 2,
    passed_count: 2,
    skipped_count: 0,
    failed_count: 0,
    started_at: "2026-08-11T06:00:00Z",
    finished_at: "2026-08-11T06:01:00Z",
    ...overrides,
  };
}

function runFixtures() {
  const { cases } = JSON.parse(fs.readFileSync(fixturesPath, "utf8"));
  for (const fixture of cases) {
    const record = classifyProviderProof(fixture.input);
    assert.equal(record.proof_state, fixture.expect.proof_state, fixture.name);
    assert.equal(record.reason_code, fixture.expect.reason_code, fixture.name);
  }

  for (const policy of ["required", "advisory"]) {
    for (const proof_state of ["proved", "failed", "misconfigured", "blocked", "skipped", "non_run"]) {
      assert.equal(classifyProviderProof({
        trigger: proof_state === "non_run" ? "pull_request" : "schedule",
        sha: "state-fixture",
        policy,
        raw_job_conclusion: proof_state === "failed" ? "failure" : proof_state === "blocked" ? "cancelled" : proof_state === "skipped" ? "skipped" : "success",
        configuration_complete: proof_state !== "misconfigured",
        intentional_bypass: proof_state === "skipped",
        reason: proof_state === "skipped" ? "approved maintenance" : undefined,
        manifest: proof_state === "misconfigured" ? validManifest({ selected_count: 0, passed_count: 0 }) : validManifest(),
      }).proof_state, proof_state, `${policy}/${proof_state}`);
    }
  }

  rejects(() => classifyProviderProof({ trigger: "schedule", sha: "a", policy: "unknown", raw_job_conclusion: "success" }), /policy/);
  rejects(() => validateProviderManifest(validManifest({ selected_count: -1 })), /non-negative/);
  rejects(() => validateProviderManifest(validManifest({ passed_count: 1 })), /count/);
  rejects(() => classifyProviderProof({ trigger: "schedule", sha: "a", policy: "required", raw_job_conclusion: "skipped", intentional_bypass: true }), /reason/);
  rejects(() => validateProviderManifest(validManifest({ started_at: "not-a-time" })), /timestamp/);

  const staleBoundary = "2026-08-14T06:00:00Z";
  assert.equal(deriveFreshness({ latest_proved_at: "2026-08-11T06:00:00Z", now: staleBoundary, cadence_hours: 24, grace_hours: 48 }), false);
  assert.equal(deriveFreshness({ latest_proved_at: "2026-08-11T06:00:00Z", now: "2026-08-14T06:00:01Z", cadence_hours: 24, grace_hours: 48 }), true);
  const differentSha = classifyProviderProof({ trigger: "push", sha: "current", policy: "required", raw_job_conclusion: "success", latest_proved_sha: "previous", latest_proved_at: "2026-08-11T06:00:00Z" });
  assert.equal(differentSha.proof_state, "non_run");
  assert.equal(differentSha.latest_proved_sha, "previous");

  const summary = renderProviderSummary({
    ...classifyProviderProof({ trigger: "push", sha: "a", policy: "required", raw_job_conclusion: "skipped" }),
    reason_code: "bad **markdown**\n::warning:: payload",
    evidence_url: "https://example.test/a?x=<tag>",
    next_command: "echo `unsafe`",
  });
  assert.doesNotMatch(summary, /\n::warning::/);
  assert.doesNotMatch(summary, /\*\*markdown\*\*/);
  assert.match(summary, /Proof state/);

  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "provider-proof-"));
  try {
    const manifest = path.join(temp, "manifest.json");
    const out = path.join(temp, "record.json");
    fs.writeFileSync(manifest, JSON.stringify(validManifest({ selected_count: 0, passed_count: 0 })));
    const result = spawnSync(process.execPath, [path.join(root, "scripts/ci/provider_proof.mjs"), "--finalize", "--trigger", "schedule", "--sha", "zero", "--policy", "required", "--raw-conclusion", "success", "--configured", "true", "--manifest", manifest, "--out", out]);
    assert.notEqual(result.status, 0, "zero-selected finalize must fail");
    assert.equal(JSON.parse(fs.readFileSync(out, "utf8")).proof_state, "misconfigured");
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
}

try {
  if (process.argv.includes("--fixtures")) runFixtures();
  else throw new Error("use --fixtures");
  console.log("provider proof fixtures: PASS");
} catch (error) {
  console.error(`provider proof fixtures: FAIL: ${error.message}`);
  process.exitCode = 1;
}
