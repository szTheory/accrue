#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const POLICIES = new Set(["required", "advisory"]);
const CONCLUSIONS = new Set(["success", "failure", "cancelled", "timed_out", "skipped", "neutral", "action_required"]);
const SELECTED_TRIGGERS = new Set(["schedule", "workflow_dispatch"]);
const DEFAULT_CADENCE_HOURS = 24;
const DEFAULT_GRACE_HOURS = 48;

function fail(message) {
  throw new Error(message);
}

function nonEmptyString(value, field) {
  if (typeof value !== "string" || value.trim() === "") fail(`${field} is required`);
  return value;
}

function timestamp(value, field) {
  nonEmptyString(value, field);
  if (!/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{3})?Z$/.test(value)) fail(`${field} must be an ISO timestamp`);
  const ms = Date.parse(value);
  if (Number.isNaN(ms)) fail(`${field} must be an ISO timestamp`);
  const canonical = value.includes(".") ? value : value.replace("Z", ".000Z");
  if (new Date(ms).toISOString() !== canonical) fail(`${field} must be an ISO timestamp`);
  return value;
}

function count(value, field) {
  if (!Number.isInteger(value) || value < 0) fail(`${field} must be a non-negative integer`);
  return value;
}

function finiteHours(value, field) {
  if (!Number.isFinite(value) || value < 0) fail(`${field} must be a non-negative number`);
  return value;
}

export function validateProviderManifest(manifest) {
  if (!manifest || typeof manifest !== "object" || Array.isArray(manifest)) fail("manifest must be an object");
  if (manifest.schema_version !== 1) fail("manifest schema_version must be 1");
  const selected_count = count(manifest.selected_count, "manifest selected_count");
  const passed_count = count(manifest.passed_count, "manifest passed_count");
  const skipped_count = count(manifest.skipped_count, "manifest skipped_count");
  const failed_count = count(manifest.failed_count, "manifest failed_count");
  const started_at = timestamp(manifest.started_at, "manifest started_at");
  const finished_at = timestamp(manifest.finished_at, "manifest finished_at");
  if (Date.parse(finished_at) < Date.parse(started_at)) fail("manifest finished_at must not precede started_at");
  if (passed_count + skipped_count + failed_count !== selected_count) fail("manifest count totals must equal selected_count");
  return { schema_version: 1, selected_count, passed_count, skipped_count, failed_count, started_at, finished_at };
}

export function deriveFreshness({ latest_proved_at, now = new Date().toISOString(), cadence_hours = DEFAULT_CADENCE_HOURS, grace_hours = DEFAULT_GRACE_HOURS }) {
  if (latest_proved_at == null) return true;
  const provedAt = Date.parse(timestamp(latest_proved_at, "latest_proved_at"));
  const nowAt = Date.parse(timestamp(now, "now"));
  const cadence = finiteHours(cadence_hours, "cadence_hours");
  const grace = finiteHours(grace_hours, "grace_hours");
  return nowAt > provedAt + (cadence + grace) * 60 * 60 * 1000;
}

function selectedTrigger(trigger) {
  return SELECTED_TRIGGERS.has(trigger);
}

function baseRecord(input) {
  const trigger = nonEmptyString(input.trigger, "trigger");
  const sha = nonEmptyString(input.sha, "sha");
  const policy = nonEmptyString(input.policy, "policy");
  if (!POLICIES.has(policy)) fail("policy must be required or advisory");
  const raw_job_conclusion = nonEmptyString(input.raw_job_conclusion, "raw_job_conclusion");
  if (!CONCLUSIONS.has(raw_job_conclusion)) fail("raw_job_conclusion is not allowed");
  const cadence_hours = input.cadence_hours ?? DEFAULT_CADENCE_HOURS;
  const grace_hours = input.grace_hours ?? DEFAULT_GRACE_HOURS;
  finiteHours(cadence_hours, "cadence_hours");
  finiteHours(grace_hours, "grace_hours");
  if (input.latest_proved_sha != null) nonEmptyString(input.latest_proved_sha, "latest_proved_sha");
  if (input.latest_proved_at != null) timestamp(input.latest_proved_at, "latest_proved_at");
  return {
    schema_version: 1,
    trigger,
    sha,
    policy,
    raw_job_conclusion,
    latest_proved_sha: input.latest_proved_sha ?? null,
    latest_proved_at: input.latest_proved_at ?? null,
    cadence_hours,
    grace_hours,
    stale: deriveFreshness({ latest_proved_at: input.latest_proved_at, now: input.now, cadence_hours, grace_hours }),
    evidence_url: input.evidence_url ?? null,
    next_command: input.next_command ?? "cd accrue && mix test.live",
  };
}

export function classifyProviderProof(input) {
  const record = baseRecord(input);
  const reason = input.reason?.trim();
  if (!selectedTrigger(record.trigger)) {
    return { ...record, proof_state: "non_run", reason_code: "trigger_not_selected", selected_count: 0, passed_count: 0, skipped_count: 0, manifest_written: false };
  }
  if (input.intentional_bypass) {
    if (!reason) fail("intentional bypass requires a reason");
    return { ...record, proof_state: "skipped", reason_code: "intentional_bypass", selected_count: 0, passed_count: 0, skipped_count: 0, manifest_written: false };
  }
  if (input.configuration_complete !== true) {
    return { ...record, proof_state: "misconfigured", reason_code: "configuration_incomplete", selected_count: 0, passed_count: 0, skipped_count: 0, manifest_written: false };
  }
  let manifest;
  try {
    manifest = validateProviderManifest(input.manifest);
  } catch (error) {
    return { ...record, proof_state: "misconfigured", reason_code: "manifest_invalid", selected_count: 0, passed_count: 0, skipped_count: 0, manifest_written: false };
  }
  const counts = { selected_count: manifest.selected_count, passed_count: manifest.passed_count, skipped_count: manifest.skipped_count, manifest_written: true };
  if (manifest.selected_count === 0) return { ...record, ...counts, proof_state: "misconfigured", reason_code: "zero_selected_tests" };
  if (manifest.skipped_count > 0) return { ...record, ...counts, proof_state: "misconfigured", reason_code: "unaccounted_skipped_tests" };
  if (record.raw_job_conclusion === "cancelled" || record.raw_job_conclusion === "timed_out" || record.raw_job_conclusion === "action_required") return { ...record, ...counts, proof_state: "blocked", reason_code: `job_${record.raw_job_conclusion}` };
  if (manifest.failed_count > 0 || record.raw_job_conclusion === "failure") return { ...record, ...counts, proof_state: "failed", reason_code: "selected_assertions_failed" };
  if (record.raw_job_conclusion !== "success") return { ...record, ...counts, proof_state: "blocked", reason_code: "job_did_not_complete" };
  const latest_proved_sha = record.sha;
  const latest_proved_at = manifest.finished_at;
  return {
    ...record,
    ...counts,
    latest_proved_sha,
    latest_proved_at,
    stale: deriveFreshness({ latest_proved_at, now: input.now, cadence_hours: record.cadence_hours, grace_hours: record.grace_hours }),
    proof_state: "proved",
    reason_code: "complete_provider_evidence",
  };
}

function parseArgs(args) {
  const values = {};
  for (let index = 0; index < args.length; index += 1) {
    const key = args[index];
    if (!key.startsWith("--")) fail(`unexpected argument: ${key}`);
    if (["--preflight", "--finalize", "--classify"].includes(key)) values.mode = key.slice(2);
    else values[key.slice(2)] = args[++index];
  }
  return values;
}

function bool(value) {
  return value === "true";
}

function cliInput(values) {
  const input = {
    trigger: values.trigger,
    sha: values.sha,
    policy: values.policy,
    raw_job_conclusion: values["raw-conclusion"],
    configuration_complete: bool(values.configured),
    intentional_bypass: bool(values.bypass),
    reason: values.reason,
    evidence_url: values["evidence-url"],
    latest_proved_sha: values["latest-proved"]?.split("@")[0],
    latest_proved_at: values["latest-proved"]?.split("@")[1],
    cadence_hours: values["cadence-hours"] ? Number(values["cadence-hours"]) : undefined,
    grace_hours: values["grace-hours"] ? Number(values["grace-hours"]) : undefined,
  };
  if (values.manifest) {
    try {
      input.manifest = JSON.parse(fs.readFileSync(values.manifest, "utf8"));
    } catch (_error) {
      input.manifest = undefined;
    }
  }
  return input;
}

function main() {
  const values = parseArgs(process.argv.slice(2));
  if (!values.mode) fail("use --preflight, --finalize, or --classify");
  const record = classifyProviderProof(cliInput(values));
  const output = `${JSON.stringify(record, null, 2)}\n`;
  if (values.out) fs.mkdirSync(path.dirname(values.out), { recursive: true }), fs.writeFileSync(values.out, output);
  else process.stdout.write(output);
  if (values.mode === "finalize" && record.proof_state !== "proved") process.exitCode = 1;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try { main(); } catch (error) { console.error(`provider proof: FAIL: ${error.message}`); process.exitCode = 1; }
}
