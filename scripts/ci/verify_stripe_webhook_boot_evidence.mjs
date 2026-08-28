#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const workflowPath = path.join(root, ".github/workflows/ci.yml");
const startMarker = "<!-- evidence-record:start -->";
const endMarker = "<!-- evidence-record:end -->";
const fields = [
  "status", "owner", "repaired_sha", "dispatch_at", "observed_at", "workflow", "event",
  "input_run_live_stripe", "run_id", "run_attempt", "run_url", "job_name", "job_status",
  "job_conclusion", "preflight_step_status", "preflight_step_conclusion", "suite_step_status",
  "suite_step_conclusion", "finalizer_step_status", "finalizer_step_conclusion",
  "artifact_step_status", "artifact_step_conclusion", "raw_run_conclusion", "raw_job_conclusion",
  "proof_state", "reason_code", "selected_count", "passed_count", "failed_count", "skipped_count",
  "manifest_present", "manifest_selected_count", "manifest_passed_count", "manifest_failed_count",
  "manifest_skipped_count", "manifest_started_at", "manifest_finished_at", "finalizer_result",
  "artifact_present", "created_run", "consumed", "rejection_class", "retry", "authority_closed",
  "outcome",
];
const booleans = new Set(["input_run_live_stripe", "manifest_present", "artifact_present", "created_run", "consumed", "retry", "authority_closed"]);
const integers = new Set(["run_attempt", "selected_count", "passed_count", "failed_count", "skipped_count", "manifest_selected_count", "manifest_passed_count", "manifest_failed_count", "manifest_skipped_count"]);
const dispatchFields = new Set(["status", "owner", "repaired_sha", "dispatch_at", "observed_at", "workflow", "event", "input_run_live_stripe", "created_run", "consumed", "rejection_class", "retry", "authority_closed", "outcome"]);
const runOnly = fields.filter((field) => !dispatchFields.has(field));
const optionalWithoutManifest = new Set(["manifest_selected_count", "manifest_passed_count", "manifest_failed_count", "manifest_skipped_count", "manifest_started_at", "manifest_finished_at"]);

function fail(message) {
  throw new Error(`stripe webhook boot evidence: ${message}`);
}

function timestamp(value, field) {
  if (typeof value !== "string" || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{3})?Z$/.test(value)) fail(`${field} must be an ISO timestamp`);
  const parsed = Date.parse(value);
  const canonical = value.includes(".") ? value : value.replace("Z", ".000Z");
  if (Number.isNaN(parsed) || new Date(parsed).toISOString() !== canonical) fail(`${field} must be an ISO timestamp`);
  return parsed;
}

function scalar(field, value) {
  if (value === "") return "";
  if (booleans.has(field)) {
    if (value !== "true" && value !== "false") fail(`${field} must be true or false`);
    return value === "true";
  }
  if (integers.has(field)) {
    if (!/^\d+$/.test(value)) fail(`${field} must be a non-negative integer`);
    return Number(value);
  }
  return value;
}

function parseRecord(source) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker);
  if (start === -1 || end <= start) fail("record markers are missing or out of order");
  const record = {};
  for (const match of source.slice(start + startMarker.length, end).matchAll(/^- ([a-z0-9_]+): `([^`]*)`\s*$/gm)) {
    const [, field, value] = match;
    if (!fields.includes(field)) fail(`unknown field: ${field}`);
    if (Object.hasOwn(record, field)) fail(`duplicate or conflicting field: ${field}`);
    record[field] = scalar(field, value);
  }
  const missing = fields.filter((field) => !Object.hasOwn(record, field));
  if (missing.length) fail(`missing exact-once field: ${missing[0]}`);
  return record;
}

function requireEmpty(record, names) {
  for (const name of names) if (record[name] !== "") fail(`${name} must be empty`);
}

function validateCounts(record) {
  for (const field of ["selected_count", "passed_count", "failed_count", "skipped_count"]) {
    if (!Number.isInteger(record[field]) || record[field] < 0) fail(`${field} must be a non-negative integer`);
  }
  if (record.passed_count + record.failed_count + record.skipped_count !== record.selected_count) fail("selected_count must equal accounted results");
}

function validateManifest(record, present) {
  if (record.manifest_present !== present) fail(`manifest_present must be ${present}`);
  const names = ["manifest_selected_count", "manifest_passed_count", "manifest_failed_count", "manifest_skipped_count", "manifest_started_at", "manifest_finished_at"];
  if (!present) return requireEmpty(record, names);
  const pairs = [["selected_count", "manifest_selected_count"], ["passed_count", "manifest_passed_count"], ["failed_count", "manifest_failed_count"], ["skipped_count", "manifest_skipped_count"]];
  for (const [proof, manifest] of pairs) if (record[proof] !== record[manifest]) fail(`${manifest} must match ${proof}`);
  if (timestamp(record.manifest_finished_at, "manifest_finished_at") < timestamp(record.manifest_started_at, "manifest_started_at")) fail("manifest timestamps are reversed");
}

function validateCreatedIdentity(record) {
  for (const field of runOnly) if (!optionalWithoutManifest.has(field) && record[field] === "") fail(`${field} must be populated for a created run`);
  if (record.run_attempt !== 1 || !/^\d+$/.test(String(record.run_id))) fail("created run must be numeric attempt 1");
  if (!/^https:\/\/github\.com\/[^/]+\/[^/]+\/actions\/runs\/\d+$/.test(record.run_url)) fail("run_url must be immutable");
  if (record.job_name !== "Stripe test-mode parity (mandatory periodic)" || record.job_status !== "completed") fail("stable live-stripe job identity differs");
  for (const field of ["preflight_step_status", "suite_step_status", "finalizer_step_status", "artifact_step_status"]) if (record[field] !== "completed") fail(`${field} must be completed`);
}

function validateRecord(record) {
  assert.deepEqual(Object.keys(record).sort(), [...fields].sort(), "record must contain the exact field set");
  if (record.owner !== "maintainer" || !/^[0-9a-f]{40}$/.test(record.repaired_sha)) fail("owner or repaired SHA differs");
  if (timestamp(record.observed_at, "observed_at") < timestamp(record.dispatch_at, "dispatch_at")) fail("observed_at precedes dispatch_at");
  if (record.workflow !== "CI" || record.event !== "workflow_dispatch" || record.input_run_live_stripe !== true) fail("dispatch identity differs");
  if (record.retry !== false || record.authority_closed !== true) fail("retry must be false and authority closed");
  if (record.proof_state === "skipped" || record.reason_code === "intentional_bypass") fail("skipped/intentional_bypass is structurally impossible for Phase 228");

  if (record.created_run === false) {
    if (record.consumed !== false || record.status !== "rejected" || record.rejection_class === "" || record.outcome !== "no_run_rejected") fail("no-run tuple is incomplete");
    requireEmpty(record, runOnly);
    return record;
  }
  if (record.created_run !== true || record.consumed !== true || record.rejection_class !== "") fail("created-run authority tuple is incomplete");
  validateCreatedIdentity(record);
  validateCounts(record);
  if (record.artifact_present !== true || record.artifact_step_conclusion !== "success") fail("created run must retain live-stripe-proof");
  const pair = `${record.proof_state}/${record.reason_code}`;
  if (pair === "proved/complete_provider_evidence") {
    if (record.status !== "terminal" || record.outcome !== "proved" || record.raw_run_conclusion !== "success" || record.raw_job_conclusion !== "success" || record.job_conclusion !== "success" || record.selected_count <= 0 || record.passed_count !== record.selected_count || record.failed_count !== 0 || record.skipped_count !== 0 || record.finalizer_result !== "success" || record.finalizer_step_conclusion !== "success") fail("proved tuple is inconsistent");
    validateManifest(record, true);
    return record;
  }
  const allowed = new Set(["misconfigured/configuration_incomplete", "misconfigured/manifest_invalid", "misconfigured/zero_selected_tests", "misconfigured/unaccounted_skipped_tests", "failed/selected_assertions_failed", "blocked/job_cancelled", "blocked/job_timed_out", "blocked/job_action_required", "blocked/job_did_not_complete"]);
  if (!allowed.has(pair) || record.status !== "terminal" || record.outcome !== "not_proved") fail(`terminal tuple is not allowed: ${pair}`);
  if (record.raw_run_conclusion === "success" || record.job_conclusion === "success") fail("non-proved tuple cannot claim success");
  validateManifest(record, !new Set(["misconfigured/configuration_incomplete", "misconfigured/manifest_invalid"]).has(pair));
  if (pair === "misconfigured/zero_selected_tests" && record.selected_count !== 0) fail("zero_selected_tests requires zero selected tests");
  if (pair === "misconfigured/unaccounted_skipped_tests" && record.skipped_count <= 0) fail("unaccounted_skipped_tests requires skipped tests");
  if (pair === "failed/selected_assertions_failed" && record.failed_count <= 0 && record.raw_job_conclusion !== "failure") fail("selected_assertions_failed requires failure");
  const conclusion = { job_cancelled: "cancelled", job_timed_out: "timed_out", job_action_required: "action_required" }[record.reason_code];
  if (conclusion && record.raw_job_conclusion !== conclusion) fail(`${record.reason_code} conclusion differs`);
  return record;
}

function liveStripeJob(workflow) {
  const start = workflow.indexOf("  live-stripe:");
  if (start === -1) fail("live-stripe job is missing");
  const rest = workflow.slice(start + 2);
  const next = rest.search(/\n  [A-Za-z0-9_-]+:/);
  return workflow.slice(start, next === -1 ? workflow.length : start + 2 + next);
}

function assertWorkflowImpossibility(workflow) {
  const dispatch = workflow.match(/^  workflow_dispatch:\n([\s\S]*?)(?=^  schedule:)/m)?.[0] || "";
  assert.deepEqual([...dispatch.matchAll(/^      ([A-Za-z0-9_-]+):$/gm)].map((match) => match[1]), ["run_live_stripe"], "workflow_dispatch input set differs");
  const job = liveStripeJob(workflow);
  assert.match(job, /github\.event_name == 'workflow_dispatch' && inputs\.run_live_stripe/, "manual live-stripe job is not input-gated");
  assert.match(job, /STRIPE_WEBHOOK_SECRET: \$\{\{ secrets\.STRIPE_WEBHOOK_SECRET \}\}/, "signing-secret binding is missing");
  const finalizer = job.match(/- id: provider_proof_finalize[\s\S]*?(?=\n      - )/)?.[0] || "";
  assert.match(finalizer, /provider_proof\.mjs --finalize/, "provider finalizer is missing");
  assert.doesNotMatch(finalizer, /--bypass(?:\s|$)|--(?:bypass-)?reason(?:\s|$)/, "provider finalizer exposes a bypass path");
}

function baseRecord() {
  return {
    status: "terminal", owner: "maintainer", repaired_sha: "a".repeat(40), dispatch_at: "2026-08-28T12:00:00Z", observed_at: "2026-08-28T12:10:00Z", workflow: "CI", event: "workflow_dispatch", input_run_live_stripe: true,
    run_id: "123", run_attempt: 1, run_url: "https://github.com/szTheory/accrue/actions/runs/123", job_name: "Stripe test-mode parity (mandatory periodic)", job_status: "completed", job_conclusion: "success",
    preflight_step_status: "completed", preflight_step_conclusion: "success", suite_step_status: "completed", suite_step_conclusion: "success", finalizer_step_status: "completed", finalizer_step_conclusion: "success", artifact_step_status: "completed", artifact_step_conclusion: "success",
    raw_run_conclusion: "success", raw_job_conclusion: "success", proof_state: "proved", reason_code: "complete_provider_evidence", selected_count: 2, passed_count: 2, failed_count: 0, skipped_count: 0,
    manifest_present: true, manifest_selected_count: 2, manifest_passed_count: 2, manifest_failed_count: 0, manifest_skipped_count: 0, manifest_started_at: "2026-08-28T12:02:00Z", manifest_finished_at: "2026-08-28T12:03:00Z",
    finalizer_result: "success", artifact_present: true, created_run: true, consumed: true, rejection_class: "", retry: false, authority_closed: true, outcome: "proved",
  };
}

function terminal(proof_state, reason_code, overrides = {}) {
  return { ...baseRecord(), proof_state, reason_code, outcome: "not_proved", raw_run_conclusion: "failure", raw_job_conclusion: "failure", job_conclusion: "failure", finalizer_result: "failure", finalizer_step_conclusion: "failure", ...overrides };
}

function noRun() {
  const record = { ...baseRecord(), status: "rejected", created_run: false, consumed: false, rejection_class: "dispatch_rejected", outcome: "no_run_rejected" };
  for (const field of runOnly) record[field] = "";
  return record;
}

function markdown(record, extra = "") {
  const value = (field) => record[field] === true ? "true" : record[field] === false ? "false" : record[field];
  return `${startMarker}\n${fields.map((field) => `- ${field}: \`${value(field)}\``).join("\n")}\n${extra}${endMarker}`;
}

function absentManifest(overrides = {}) {
  return { manifest_present: false, manifest_selected_count: "", manifest_passed_count: "", manifest_failed_count: "", manifest_skipped_count: "", manifest_started_at: "", manifest_finished_at: "", ...overrides };
}

function runFixtures() {
  const workflow = fs.readFileSync(workflowPath, "utf8");
  assertWorkflowImpossibility(workflow);
  const records = [
    baseRecord(),
    terminal("misconfigured", "configuration_incomplete", { ...absentManifest(), selected_count: 0, passed_count: 0, failed_count: 0, skipped_count: 0, preflight_step_conclusion: "failure", suite_step_conclusion: "skipped" }),
    terminal("misconfigured", "manifest_invalid", { ...absentManifest(), selected_count: 0, passed_count: 0, failed_count: 0, skipped_count: 0 }),
    terminal("misconfigured", "zero_selected_tests", { selected_count: 0, passed_count: 0, failed_count: 0, skipped_count: 0, manifest_selected_count: 0, manifest_passed_count: 0, manifest_failed_count: 0, manifest_skipped_count: 0 }),
    terminal("misconfigured", "unaccounted_skipped_tests", { selected_count: 2, passed_count: 1, failed_count: 0, skipped_count: 1, manifest_selected_count: 2, manifest_passed_count: 1, manifest_failed_count: 0, manifest_skipped_count: 1 }),
    terminal("failed", "selected_assertions_failed", { selected_count: 2, passed_count: 1, failed_count: 1, skipped_count: 0, manifest_selected_count: 2, manifest_passed_count: 1, manifest_failed_count: 1, manifest_skipped_count: 0 }),
    terminal("blocked", "job_cancelled", { raw_job_conclusion: "cancelled" }), terminal("blocked", "job_timed_out", { raw_job_conclusion: "timed_out" }), terminal("blocked", "job_action_required", { raw_job_conclusion: "action_required" }), terminal("blocked", "job_did_not_complete", { raw_job_conclusion: "neutral" }), noRun(),
  ];
  for (const record of records) assert.doesNotThrow(() => validateRecord(parseRecord(markdown(record))));
  for (const field of fields) assert.throws(() => parseRecord(markdown(baseRecord()).replace(new RegExp(`^- ${field}:.*\\n?`, "m"), "")), /missing exact-once field/, `missing ${field}`);
  assert.throws(() => parseRecord(markdown(baseRecord(), "- proof_state: `failed`\n")), /duplicate or conflicting/);
  for (const field of ["unknown", "secret_value", "raw_log", "payload", "actor", "endpoint_identifier", "presence_details"]) assert.throws(() => parseRecord(markdown(baseRecord(), `- ${field}: \`forbidden\`\n`)), /unknown field/);
  for (const [field, value] of [["workflow", "Other"], ["event", "schedule"], ["repaired_sha", "short"], ["run_attempt", 2], ["run_url", "mutable"], ["job_name", "renamed"], ["selected_count", 3], ["manifest_passed_count", 1], ["artifact_present", false], ["retry", true], ["authority_closed", false], ["created_run", false], ["consumed", false], ["manifest_finished_at", "2026-08-28T11:00:00Z"]]) {
    assert.throws(() => validateRecord({ ...baseRecord(), [field]: value }), undefined, `${field} mutation`);
  }
  assert.throws(() => validateRecord({ ...baseRecord(), proof_state: "skipped", reason_code: "intentional_bypass" }), /structurally impossible/);
  assert.throws(() => assertWorkflowImpossibility(workflow.replace("      run_live_stripe:", "      bypass_provider:\n        description: forbidden\n        type: boolean\n        required: false\n        default: false\n      run_live_stripe:")), /input set differs/);
  assert.throws(() => assertWorkflowImpossibility(workflow.replace("provider_proof.mjs --finalize", "provider_proof.mjs --finalize --bypass")), /bypass path/);
  assert.throws(() => assertWorkflowImpossibility(workflow.replace("inputs.run_live_stripe", "inputs.other")), /input-gated/);
}

function option(name) {
  const index = process.argv.indexOf(name);
  return index < 0 ? undefined : process.argv[index + 1];
}

function ghJson(endpoint) {
  return JSON.parse(execFileSync("gh", ["api", endpoint], { encoding: "utf8" }));
}

function liveContext() {
  const context = { recordPath: option("--record"), repository: option("--repository"), sha: option("--sha"), dispatchAt: option("--dispatch-at"), observedAt: option("--observed-at") };
  for (const [key, value] of Object.entries(context)) if (!value) fail(`explicit ${key} argument is required`);
  const current = JSON.parse(execFileSync("gh", ["repo", "view", "--json", "nameWithOwner"], { encoding: "utf8" })).nameWithOwner;
  if (current !== context.repository) fail("repository does not match current checkout");
  context.record = parseRecord(fs.readFileSync(context.recordPath, "utf8"));
  if (context.record.repaired_sha !== context.sha || context.record.dispatch_at !== context.dispatchAt || context.record.observed_at !== context.observedAt) fail("record differs from explicit identity arguments");
  assertWorkflowImpossibility(fs.readFileSync(workflowPath, "utf8"));
  return context;
}

function liveInventory(context) {
  const runs = ghJson(`repos/${context.repository}/actions/workflows/ci.yml/runs?event=workflow_dispatch&per_page=100`).workflow_runs || [];
  const bounded = runs.filter((run) => run.head_sha === context.sha && Date.parse(run.created_at) >= timestamp(context.dispatchAt, "dispatch_at") && Date.parse(run.created_at) <= timestamp(context.observedAt, "observed_at"));
  if (!context.record.created_run) {
    if (bounded.length) fail("no-run record conflicts with created run");
    validateRecord(context.record);
    return {};
  }
  const run = bounded.find((candidate) => String(candidate.id) === String(context.record.run_id));
  if (!run || run.name !== "CI" || run.event !== "workflow_dispatch" || run.run_attempt !== 1 || run.html_url !== `https://github.com/${context.repository}/actions/runs/${run.id}`) fail("GitHub run identity differs");
  const jobs = ghJson(`repos/${context.repository}/actions/runs/${run.id}/attempts/1/jobs?filter=all&per_page=100`).jobs || [];
  const job = jobs.find((candidate) => candidate.name === "Stripe test-mode parity (mandatory periodic)");
  if (!job) fail("input-gated live-stripe job did not execute");
  for (const [name, prefix] of [["Preflight live-Stripe provider configuration", "preflight"], ["Run live-Stripe suite", "suite"], ["Finalize live-Stripe provider proof", "finalizer"], ["Upload live-Stripe provider proof", "artifact"]]) {
    const step = job.steps?.find((candidate) => candidate.name === name);
    if (!step || step.status !== context.record[`${prefix}_step_status`] || step.conclusion !== context.record[`${prefix}_step_conclusion`]) fail(`GitHub step differs: ${name}`);
  }
  if (run.conclusion !== context.record.raw_run_conclusion || job.status !== context.record.job_status || job.conclusion !== context.record.job_conclusion) fail("GitHub conclusions differ");
  validateRecord(context.record);
  return { run, job };
}

function verifyTerminal(context) {
  const { run } = liveInventory(context);
  if (!run) return;
  const artifacts = ghJson(`repos/${context.repository}/actions/runs/${run.id}/artifacts?per_page=100`).artifacts || [];
  const artifact = artifacts.find((candidate) => candidate.name === "live-stripe-proof");
  if (Boolean(artifact) !== context.record.artifact_present) fail("artifact presence differs");
  if (!artifact) return;
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "phase-228-proof-"));
  try {
    execFileSync("gh", ["run", "download", String(run.id), "--repo", context.repository, "--name", "live-stripe-proof", "--dir", temporary], { stdio: "ignore" });
    const proof = JSON.parse(fs.readFileSync(path.join(temporary, "accrue-provider-proof.json"), "utf8"));
    for (const field of ["proof_state", "reason_code", "selected_count", "passed_count", "skipped_count"]) if (proof[field] !== context.record[field]) fail(`proof differs: ${field}`);
    const manifestPath = path.join(temporary, "accrue-provider-manifest.json");
    if (context.record.manifest_present !== fs.existsSync(manifestPath)) fail("manifest presence differs");
    if (fs.existsSync(manifestPath)) {
      const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
      for (const field of ["selected_count", "passed_count", "failed_count", "skipped_count", "started_at", "finished_at"]) if (manifest[field] !== context.record[`manifest_${field}`]) fail(`manifest differs: ${field}`);
    }
  } finally {
    fs.rmSync(temporary, { recursive: true, force: true });
  }
}

try {
  const modes = ["--fixtures", "--verify-live-binding", "--verify-terminal"].filter((mode) => process.argv.includes(mode));
  if (modes.length !== 1) fail("choose exactly one mode");
  if (modes[0] === "--fixtures") runFixtures();
  else if (modes[0] === "--verify-live-binding") liveInventory(liveContext());
  else verifyTerminal(liveContext());
  console.log(`stripe webhook boot evidence ${modes[0].slice(2)}: PASS`);
} catch (error) {
  console.error(`stripe webhook boot evidence: FAIL: ${error.message}`);
  process.exitCode = 1;
}
