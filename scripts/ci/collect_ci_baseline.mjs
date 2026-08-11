#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const SCHEMA_VERSION = 1;
const CONCLUSIONS = new Set(["success", "failure", "cancelled", "skipped", "neutral", "timed_out", "action_required", "stale", "unknown"]);
const PROVIDER_STATES = new Set(["proved", "failed", "misconfigured", "blocked", "skipped", "non_run"]);
const RUN_INPUT_FIELDS = new Set(["id", "html_url", "head_sha", "created_at", "run_started_at", "updated_at", "event", "head_branch", "conclusion", "run_attempt", "original_run_id", "workflow_path", "provider_state", "jobs"]);
const JOB_INPUT_FIELDS = new Set(["id", "html_url", "name", "started_at", "completed_at", "conclusion", "runner_image", "needs", "steps", "cache", "setup_costs", "failure_message"]);
const SCHEMA_PATH = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../.planning/phases/226-ci-baseline-proof-semantics/schema-v1.json");

function fail(message) { throw new Error(message); }
function hash(value) { return crypto.createHash("sha256").update(value).digest("hex").slice(0, 16); }
function allowedFields(object, allowed, label) {
  if (!object || Array.isArray(object) || typeof object !== "object") fail(`${label} must be an object`);
  for (const key of Object.keys(object)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`);
}
function timestamp(value, label) {
  if (typeof value !== "string" || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{3})?Z$/.test(value)) fail(`${label} must be an ISO-8601 UTC timestamp`);
  const ms = Date.parse(value);
  if (Number.isNaN(ms)) fail(`${label} is invalid`);
  return ms;
}
function immutableUrl(value, label) {
  if (typeof value !== "string" || !/^https:\/\/github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\/actions\/runs\/\d+(?:\/job\/\d+)?$/.test(value)) fail(`${label} must be an immutable GitHub Actions URL`);
  return value;
}
function normalizedIdentity(value, label) {
  if (typeof value !== "string" || value.length === 0 || value.length > 160) fail(`${label} must be a bounded string`);
  const normalized = value.toLowerCase().replace(/\([^)]*\)/g, "").replace(/[^a-z0-9._/-]+/g, "-").replace(/^-+|-+$/g, "");
  if (!normalized) fail(`${label} has no stable identity`);
  return normalized;
}
function eventClass(event) {
  return ({ pull_request: "pull_request", push: "push", workflow_dispatch: "workflow_dispatch", schedule: "schedule" })[event] || "other";
}
function branchClass(event, branch) {
  if (event === "pull_request") return "pull_request";
  if (event === "push" && branch === "main") return "default_branch";
  return "non_default";
}
function conclusion(value, label) {
  if (!CONCLUSIONS.has(value)) fail(`${label} has unsupported conclusion: ${value}`);
  return value;
}
function duration(start, end, label) {
  const result = timestamp(end, `${label}.completed_at`) - timestamp(start, `${label}.started_at`);
  if (result < 0) fail(`${label} has negative duration`);
  return result;
}

export function cohortFingerprint(run, jobs = run.jobs || []) {
  const required = jobs.map((job) => normalizedIdentity(job.name, "job.name")).sort();
  const inputs = {
    workflow_revision: String(run.workflow_path || "unknown").replace(/[^a-zA-Z0-9@._/-]/g, "_"),
    event_class: eventClass(run.event),
    branch_class: branchClass(run.event, run.head_branch),
    runner_images: [...new Set(jobs.map((job) => normalizedIdentity(job.runner_image || "unknown", "job.runner_image")))].sort(),
    required_job_set: required,
    provider_configuration_class: eventClass(run.event) === "schedule" ? "provider_only" : "full_ci"
  };
  return `cohort-v1-${hash(JSON.stringify(inputs))}`;
}

export function normalizeFailureSignature(job) {
  if (!job.failure_message || job.conclusion === "success") return null;
  const message = String(job.failure_message).replace(/[0-9a-f]{8,}/gi, "sha").replace(/\d+/g, "n").replace(/[^a-zA-Z0-9 ]+/g, " ").toLowerCase().trim();
  return `failure-v1-${hash(message)}`;
}

function normalizedMetrics(value, allowed, label) {
  if (value == null) return {};
  allowedFields(value, new Set(allowed), label);
  return Object.fromEntries(Object.entries(value).map(([key, metric]) => {
    if (key === "hit") { if (typeof metric !== "boolean") fail(`${label}.hit must be boolean`); return [key, metric]; }
    if (!Number.isInteger(metric) || metric < 0) fail(`${label}.${key} must be a non-negative integer`);
    return [key, metric];
  }));
}

export function normalizeRun(run) {
  allowedFields(run, RUN_INPUT_FIELDS, "run");
  if (!Number.isInteger(run.id) || run.id < 1) fail("run.id must be a positive integer");
  if (typeof run.head_sha !== "string" || !/^[0-9a-f]{40}$/i.test(run.head_sha)) fail("run.head_sha must be a full SHA");
  const created = timestamp(run.created_at, "run.created_at");
  const started = timestamp(run.run_started_at, "run.run_started_at");
  const completed = timestamp(run.updated_at, "run.updated_at");
  if (started < created || completed < started) fail("run timestamps are not monotonic");
  const providerState = run.provider_state || (eventClass(run.event) === "schedule" ? "non_run" : "proved");
  if (!PROVIDER_STATES.has(providerState)) fail(`run.provider_state is unsupported: ${providerState}`);
  return {
    schema_version: SCHEMA_VERSION, kind: "run", run_id: run.id, run_url: immutableUrl(run.html_url, "run.html_url"), sha: run.head_sha.slice(0, 12),
    created_at: run.created_at, started_at: run.run_started_at, completed_at: run.updated_at, event_class: eventClass(run.event), branch_class: branchClass(run.event, run.head_branch),
    cohort_fingerprint: cohortFingerprint(run), workflow_duration_ms: completed - started, conclusion: conclusion(run.conclusion, "run.conclusion"),
    run_attempt: Number.isInteger(run.run_attempt) && run.run_attempt > 0 ? run.run_attempt : 1, original_run_id: Number.isInteger(run.original_run_id) ? run.original_run_id : run.id, provider_state: providerState
  };
}

export function normalizeJob(job, run, completedByName = new Map()) {
  allowedFields(job, JOB_INPUT_FIELDS, "job");
  if (!Number.isInteger(job.id) || job.id < 1) fail("job.id must be a positive integer");
  const stableIdentity = normalizedIdentity(job.name, "job.name");
  const start = timestamp(job.started_at, "job.started_at");
  const end = timestamp(job.completed_at, "job.completed_at");
  if (end < start) fail("job has negative duration");
  const needs = job.needs || [];
  if (!Array.isArray(needs) || needs.some((item) => typeof item !== "string")) fail("job.needs must be a string array");
  const prerequisiteEnds = needs.map((need) => completedByName.get(normalizedIdentity(need, "job.needs"))).filter(Boolean);
  const runCreated = timestamp(run.created_at, "run.created_at");
  const runnerQueue = needs.length === 0 ? start - runCreated : null;
  const dagWait = needs.length === 0 ? null : start - Math.max(...prerequisiteEnds);
  if (runnerQueue !== null && runnerQueue < 0) fail("root job runner queue is negative");
  if (dagWait !== null && dagWait < 0) fail("dependent job DAG wait is negative");
  return {
    schema_version: SCHEMA_VERSION, kind: "job", run_id: run.id, job_id: job.id, job_url: immutableUrl(job.html_url, "job.html_url"), job_name: stableIdentity,
    stable_identity: stableIdentity, matrix_identity: `matrix-v1-${hash(stableIdentity)}`, started_at: job.started_at, completed_at: job.completed_at,
    conclusion: conclusion(job.conclusion, "job.conclusion"), duration_ms: duration(job.started_at, job.completed_at, "job"), runner_queue_ms: runnerQueue, dag_wait_ms: dagWait,
    failure_signature: normalizeFailureSignature(job),
    setup_costs: normalizedMetrics(job.setup_costs, ["docker_ms", "browser_ms", "node_ms", "npm_ms", "phoenix_ms", "fixture_ms", "playwright_ms"], "job.setup_costs"),
    cache: normalizedMetrics(job.cache, ["hit", "restore_ms", "save_ms", "size_bytes"], "job.cache")
  };
}

export function collectBaseline(runs) {
  if (!Array.isArray(runs)) fail("runs must be an array");
  return runs.flatMap((run) => {
    const normalizedRun = normalizeRun(run);
    const completed = new Map((run.jobs || []).map((job) => [normalizedIdentity(job.name, "job.name"), timestamp(job.completed_at, "job.completed_at")]));
    return [normalizedRun, ...(run.jobs || []).map((job) => normalizeJob(job, run, completed))];
  });
}

function percentile(values, fraction) {
  const ordered = [...values].sort((a, b) => a - b);
  return ordered[Math.ceil(fraction * ordered.length) - 1];
}

export function summarizeCohorts(runs, { windowDays = 90, sampleSize = 20, now = Date.now() } = {}) {
  if (!Array.isArray(runs)) fail("runs must be an array");
  if (!Number.isInteger(windowDays) || windowDays < 1 || !Number.isInteger(sampleSize) || sampleSize < 1) fail("window-days and sample-size must be positive integers");
  const cutoff = now - (windowDays * 86_400_000);
  const groups = new Map();
  for (const run of runs) {
    const normalized = normalizeRun(run);
    const key = normalized.cohort_fingerprint;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push({ raw: run, normalized });
  }
  return [...groups.entries()].sort(([left], [right]) => left.localeCompare(right)).map(([fingerprint, members]) => {
    const firstByIdentity = new Map();
    for (const member of members.sort((a, b) => Date.parse(b.normalized.completed_at) - Date.parse(a.normalized.completed_at))) {
      const identity = `${member.normalized.original_run_id}:${member.normalized.sha}`;
      const current = firstByIdentity.get(identity);
      if (!current || member.normalized.run_attempt < current.normalized.run_attempt) firstByIdentity.set(identity, member);
    }
    const qualifying = [...firstByIdentity.values()]
      .filter(({ normalized }) => normalized.provider_state !== "non_run" && normalized.conclusion === "success" && normalized.run_attempt === 1 && Date.parse(normalized.completed_at) >= cutoff)
      .sort((a, b) => Date.parse(b.normalized.completed_at) - Date.parse(a.normalized.completed_at))
      .slice(0, sampleSize);
    const durations = qualifying.map(({ normalized }) => normalized.workflow_duration_ms);
    const signatures = new Map();
    for (const { raw, normalized } of members) for (const job of raw.jobs || []) {
      const signature = normalizeFailureSignature(job);
      if (!signature) continue;
      if (!signatures.has(signature)) signatures.set(signature, new Set());
      signatures.get(signature).add(normalizedIdentity(job.name, "job.name"));
    }
    const uniqueIdentities = new Set(members.map(({ normalized }) => `${normalized.original_run_id}:${normalized.sha}`));
    const reliability = {
      total_runs: members.length,
      failure_count: members.filter(({ normalized }) => normalized.conclusion === "failure").length,
      cancellation_count: members.filter(({ normalized }) => normalized.conclusion === "cancelled").length,
      skipped_count: members.filter(({ normalized }) => normalized.conclusion === "skipped").length,
      rerun_count: members.length - uniqueIdentities.size,
      root_incidents: [...signatures.entries()].map(([signature, cells]) => ({ signature, affected_cells: [...cells].sort() }))
    };
    const ready = durations.length >= sampleSize;
    return { schema_version: SCHEMA_VERSION, kind: "cohort", cohort_fingerprint: fingerprint, sample_count: durations.length, sample_status: ready ? "ready" : "insufficient_sample", p50_ms: ready ? percentile(durations, 0.5) : null, p95_ms: ready ? percentile(durations, 0.95) : null, reliability };
  });
}

export function validateRecord(record) {
  const schema = JSON.parse(fs.readFileSync(SCHEMA_PATH, "utf8"));
  if (!record || record.schema_version !== schema.schema_version || !schema.record_kinds[record.kind]) fail("record has unsupported schema version or kind");
  const allowed = new Set(schema.record_kinds[record.kind]);
  for (const key of allowed) if (!(key in record)) fail(`record is missing required field: ${key}`);
  for (const key of Object.keys(record)) if (!allowed.has(key)) fail(`record contains forbidden field: ${key}`);
  if (record.kind !== "cohort" && !CONCLUSIONS.has(record.conclusion)) fail("record contains unsupported conclusion");
  if (record.kind === "run" && !PROVIDER_STATES.has(record.provider_state)) fail("record contains unsupported provider state");
  if (record.kind === "cohort" && !["ready", "insufficient_sample"].includes(record.sample_status)) fail("record contains unsupported sample status");
  return record;
}

function args(argv) { const out = {}; for (let i = 0; i < argv.length; i += 2) { if (!argv[i]?.startsWith("--")) fail(`unexpected argument: ${argv[i]}`); out[argv[i].slice(2)] = argv[i + 1] ?? true; } return out; }
function main() {
  const options = args(process.argv.slice(2));
  let runs;
  if (options.input || options.fixtures) runs = JSON.parse(fs.readFileSync(options.input || options.fixtures, "utf8")).runs || Object.values(JSON.parse(fs.readFileSync(options.input || options.fixtures, "utf8")));
  else {
    if (!options.repo || !options.workflow) fail("live collection requires --repo and --workflow");
    const response = spawnSync("gh", ["api", `/repos/${options.repo}/actions/workflows/${options.workflow}/runs?per_page=100`], { encoding: "utf8", shell: false });
    if (response.status !== 0) fail(`gh api failed: ${response.stderr.trim() || "unknown error"}`);
    runs = JSON.parse(response.stdout).workflow_runs || [];
  }
  const output = `${collectBaseline(runs).map((record) => JSON.stringify(validateRecord(record))).join("\n")}\n`;
  if (options.out) fs.writeFileSync(options.out, output); else process.stdout.write(output);
}
if (process.argv[1] === fileURLToPath(import.meta.url)) { try { main(); } catch (error) { console.error(`collect ci baseline: FAIL: ${error.message}`); process.exitCode = 1; } }
