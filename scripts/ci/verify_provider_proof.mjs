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
const workflowPath = path.join(root, ".github/workflows/ci.yml");

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

function jobBody(workflow, jobId) {
  const marker = `  ${jobId}:`;
  const start = workflow.indexOf(marker);
  assert.notEqual(start, -1, `missing stable job id: ${jobId}`);
  const rest = workflow.slice(start + marker.length);
  const nextOffset = rest.search(/\n  [A-Za-z0-9_-]+:/);
  return workflow.slice(start, nextOffset === -1 ? workflow.length : start + marker.length + nextOffset);
}

function stepRegion(job, stepId) {
  const marker = `id: ${stepId}`;
  const start = job.indexOf(marker);
  assert.notEqual(start, -1, `missing required step id: ${stepId}`);
  const next = job.indexOf("\n      - ", start + marker.length);
  return job.slice(start, next === -1 ? job.length : next);
}

function assertWorkflowContract(workflow) {
  const permissions = workflow.match(/^permissions:\n((?:  [a-z-]+: [a-z]+\n)+)/m)?.[1];
  assert.equal(permissions, "  actions: read\n  checks: read\n  contents: read\n", "top-level permissions must remain exactly read-only");
  assert.doesNotMatch(workflow, /^\s+(?:[a-z-]+): write(?:\s|$)/m, "workflow must not request write permissions");
  for (const jobId of ["host-integration", "playwright-e2e", "release-gate", "live-stripe"]) {
    jobBody(workflow, jobId);
  }

  const provider = jobBody(workflow, "live-stripe");
  const host = jobBody(workflow, "host-integration");
  for (const stepId of ["provider_preflight", "live_stripe_suite", "provider_proof_finalize", "provider_proof_summary", "provider_proof_artifact"]) {
    const region = stepRegion(provider, stepId);
    if (stepId !== "provider_preflight" && stepId !== "live_stripe_suite") assert.match(region, /if: always\(\)/, `${stepId} must always run`);
  }
  for (const stepId of ["host_setup_summary", "host_setup_artifact"]) {
    assert.match(stepRegion(host, stepId), /if: always\(\)/, `${stepId} must always run`);
  }
  assert.match(stepRegion(provider, "live_stripe_suite"), /ACCRUE_PROVIDER_MANIFEST/, "suite must receive the provider manifest path");
  assert.match(provider, /ACCRUE_PROVIDER_PROOF_RECORD: \$\{\{ runner\.temp \}\}\//, "provider proof record must use runner temp");
  assert.match(host, /ACCRUE_CI_SETUP_FACTS: \$\{\{ runner\.temp \}\}\//, "setup facts must use runner temp");
  assert.match(provider, /name: live-stripe-proof/, "provider artifact name drifted");
  assert.match(host, /name: accrue-host-ci-setup-facts/, "setup artifact name drifted");

  for (const [name, region] of [
    ["provider", provider],
    ["host setup", host],
  ]) {
    assert.doesNotMatch(region, /(?:GH_TOKEN|GITHUB_TOKEN|[A-Z0-9_]*PAT[A-Z0-9_]*)\s*:/, `${name} evidence steps must not bind write-capable tokens`);
    assert.doesNotMatch(region, /\b(?:git push|gh api\s+.*--method\s+(?:POST|PUT|PATCH|DELETE)|curl\s+.*(?:-X|--request)\s*(?:POST|PUT|PATCH|DELETE))\b/i, `${name} evidence steps must not mutate repository or API state`);
  }
}

function runFixtures() {
  const workflow = fs.readFileSync(workflowPath, "utf8");
  assertWorkflowContract(workflow);
  for (const [name, mutate] of [
    ["write permission", (text) => text.replace("contents: read", "contents: write")],
    ["provider token", (text) => text.replace("id: provider_preflight", "id: provider_preflight\n        env:\n          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}")],
    ["mutation command", (text) => text.replace("id: provider_proof_summary", "id: provider_proof_summary\n        run: git push")],
  ]) {
    rejects(() => assertWorkflowContract(mutate(workflow)), new RegExp(name === "write permission" ? "permissions|write" : name === "provider token" ? "token" : "mutate"));
  }
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
  assert.doesNotThrow(() => validateProviderManifest(validManifest({ started_at: "2024-02-29T00:00:00Z", finished_at: "2024-02-29T00:01:00Z" })), "real leap-day provider manifest timestamps are accepted");
  for (const invalid of ["2026-02-30T00:00:00Z", "2025-02-29T00:00:00Z"]) {
    rejects(() => validateProviderManifest(validManifest({ started_at: invalid })), /manifest started_at must be an ISO timestamp/);
    rejects(() => deriveFreshness({ latest_proved_at: invalid, now: "2026-08-11T06:00:00Z" }), /latest_proved_at must be an ISO timestamp/);
    rejects(() => deriveFreshness({ latest_proved_at: "2026-08-11T06:00:00Z", now: invalid }), /now must be an ISO timestamp/);
  }

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
    const missingManifest = path.join(temp, "missing.json");
    const missingResult = spawnSync(process.execPath, [path.join(root, "scripts/ci/provider_proof.mjs"), "--finalize", "--trigger", "schedule", "--sha", "missing", "--policy", "required", "--raw-conclusion", "failure", "--configured", "true", "--manifest", missingManifest, "--out", out]);
    assert.notEqual(missingResult.status, 0, "missing manifest finalize must fail");
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
