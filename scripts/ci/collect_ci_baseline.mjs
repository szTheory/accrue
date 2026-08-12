#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const SCHEMA_VERSION = 1;
const CONCLUSIONS = new Set(["success", "failure", "cancelled", "skipped", "neutral", "timed_out", "action_required", "stale", "unknown"]);
const PROVIDER_STATES = new Set(["proved", "failed", "misconfigured", "blocked", "skipped", "non_run"]);
const DOCS_DISPLAY_NAME = "Docs and bash contracts (shift-left)";
const DOCS_PREREQUISITE = "docs-and-bash-contracts-shift-left";
const TIMING_NODES_REQUIRING_COMPLETE_PREREQUISITES = new Set(["annotation-sweep", "host-integration", "playwright-e2e"]);
const LIVE_RUN_CONCURRENCY = 24;
const WORKFLOW_RUNNER_PATH = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../.github/workflows/ci.yml");
const RUN_INPUT_FIELDS = new Set(["id", "html_url", "head_sha", "created_at", "run_started_at", "updated_at", "event", "head_branch", "conclusion", "run_attempt", "original_run_id", "workflow_path", "workflow_revision", "provider_state", "jobs"]);
const JOB_INPUT_FIELDS = new Set(["id", "html_url", "name", "started_at", "completed_at", "conclusion", "runner_image", "needs", "steps", "cache", "setup_costs", "failure_message"]);
const SCHEMA_PATH = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../.planning/phases/226-ci-baseline-proof-semantics/schema-v1.json");

function fail(message) { throw new Error(message); }
function hash(value) { return crypto.createHash("sha256").update(value).digest("hex").slice(0, 16); }
function workflowRevision(source) { return `sha256:${crypto.createHash("sha256").update(source).digest("hex")}`; }
function validWorkflowRevision(value) { return typeof value === "string" && /^sha256:[a-f0-9]{64}$/.test(value); }
function allowedFields(object, allowed, label) {
  if (!object || Array.isArray(object) || typeof object !== "object") fail(`${label} must be an object`);
  for (const key of Object.keys(object)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`);
}
function timestamp(value, label) {
  if (typeof value !== "string" || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{3})?Z$/.test(value)) fail(`${label} must be an ISO-8601 UTC timestamp`);
  const ms = Date.parse(value);
  if (Number.isNaN(ms)) fail(`${label} is invalid`);
  const canonical = value.includes(".") ? value : value.replace("Z", ".000Z");
  if (new Date(ms).toISOString() !== canonical) fail(`${label} must be an ISO-8601 UTC timestamp`);
  return ms;
}
function immutableUrl(value, label, expectedRunId = null, expectedJobId = null) {
  if (typeof value !== "string" || !/^https:\/\/github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\/actions\/runs\/\d+(?:\/job\/\d+)?$/.test(value)) fail(`${label} must be an immutable GitHub Actions URL`);
  const match = value.match(/\/actions\/runs\/(\d+)(?:\/job\/(\d+))?$/);
  if (expectedRunId !== null && Number(match[1]) !== expectedRunId) fail(`${label} must match run_id`);
  if (expectedJobId !== null && Number(match[2]) !== expectedJobId) fail(`${label} must match job_id`);
  return value;
}
function normalizedIdentity(value, label) {
  if (typeof value !== "string" || value.length === 0 || value.length > 400) fail(`${label} must be a bounded string`);
  if (value === DOCS_DISPLAY_NAME) return DOCS_PREREQUISITE;
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
    workflow_revision: String(run.workflow_revision || run.workflow_path || "unknown").replace(/[^a-zA-Z0-9@._/-]/g, "_"),
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
  const providerState = run.provider_state ?? "non_run";
  if (!PROVIDER_STATES.has(providerState)) fail(`run.provider_state is unsupported: ${providerState}`);
  return {
    schema_version: SCHEMA_VERSION, kind: "run", run_id: run.id, run_url: immutableUrl(run.html_url, "run.html_url"), sha: run.head_sha.slice(0, 12),
    created_at: run.created_at, started_at: run.run_started_at, completed_at: run.updated_at, event_class: eventClass(run.event), branch_class: branchClass(run.event, run.head_branch),
    cohort_fingerprint: cohortFingerprint(run), workflow_duration_ms: completed - started, conclusion: conclusion(run.conclusion, "run.conclusion"),
    run_attempt: Number.isInteger(run.run_attempt) && run.run_attempt > 0 ? run.run_attempt : 1, original_run_id: Number.isInteger(run.original_run_id) ? run.original_run_id : run.id, provider_state: providerState
  };
}

function prerequisiteCompletions(needs, dependentIdentity, dependentStart, completedByName) {
  return needs.map((need) => {
    const prerequisiteIdentity = normalizedIdentity(need, "job.needs");
    const completion = completedByName.get(prerequisiteIdentity);
    if (!Number.isFinite(completion)) {
      fail(`job ${dependentIdentity} has unresolved prerequisite ${prerequisiteIdentity}`);
    }
    if (completion > dependentStart) {
      fail(`job ${dependentIdentity} starts before prerequisite ${prerequisiteIdentity} completes`);
    }
    return completion;
  });
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
  const prerequisiteEnds = prerequisiteCompletions(needs, stableIdentity, start, completedByName);
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
  const unresolved = unresolvedPrerequisites(runs);
  if (unresolved.length > 0) fail(unresolved.join("; "));
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
      .filter(({ normalized }) => normalized.event_class !== "schedule" && normalized.conclusion === "success" && normalized.run_attempt === 1 && Date.parse(normalized.completed_at) >= cutoff)
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
  const positive = (value, label) => { if (!Number.isInteger(value) || value < 1) fail(`${label} must be a positive integer`); };
  const nonNegative = (value, label) => { if (!Number.isInteger(value) || value < 0) fail(`${label} must be a non-negative integer`); };
  const normalized = (value, label, pattern = /^[a-z0-9][a-z0-9._/-]{0,399}$/) => { if (typeof value !== "string" || !pattern.test(value)) fail(`${label} must be normalized`); };
  if (record.kind === "snapshot") {
    const generated = timestamp(record.snapshot_generated_at, "snapshot.snapshot_generated_at"); const start = timestamp(record.window_start, "snapshot.window_start"); const end = timestamp(record.window_end, "snapshot.window_end");
    if (start > end || end > generated) fail("snapshot timestamps are not monotonic");
    if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(record.repository) || !/^[A-Za-z0-9_.-]+\.ya?ml$/.test(record.workflow)) fail("snapshot has invalid repository or workflow"); positive(record.sample_target, "snapshot.sample_target");
  } else if (record.kind === "run") {
    positive(record.run_id, "run.run_id"); positive(record.run_attempt, "run.run_attempt"); positive(record.original_run_id, "run.original_run_id"); immutableUrl(record.run_url, "run.run_url", record.run_id);
    if (!/^[a-f0-9]{12}$/.test(record.sha)) fail("run.sha must be a 12-hex SHA");
    if (!["pull_request", "push", "workflow_dispatch", "schedule", "other"].includes(record.event_class) || !["pull_request", "default_branch", "non_default"].includes(record.branch_class)) fail("run has unsupported event or branch class");
    normalized(record.cohort_fingerprint, "run.cohort_fingerprint", /^cohort-v1-[a-f0-9]{16}$/);
    const created = timestamp(record.created_at, "run.created_at"); const started = timestamp(record.started_at, "run.started_at"); const completed = timestamp(record.completed_at, "run.completed_at");
    if (created > started || started > completed) fail("run timestamps are not monotonic"); nonNegative(record.workflow_duration_ms, "run.workflow_duration_ms"); if (record.workflow_duration_ms !== completed - started) fail("run workflow duration disagrees with timestamps");
    if (!CONCLUSIONS.has(record.conclusion) || !PROVIDER_STATES.has(record.provider_state)) fail("record contains unsupported run state");
  } else if (record.kind === "job") {
    positive(record.run_id, "job.run_id"); positive(record.job_id, "job.job_id"); immutableUrl(record.job_url, "job.job_url", record.run_id, record.job_id);
    normalized(record.job_name, "job.job_name"); normalized(record.stable_identity, "job.stable_identity"); normalized(record.matrix_identity, "job.matrix_identity", /^matrix-v1-[a-f0-9]{16}$/);
    const started = timestamp(record.started_at, "job.started_at"); const completed = timestamp(record.completed_at, "job.completed_at"); if (started > completed) fail("job timestamps are not monotonic"); nonNegative(record.duration_ms, "job.duration_ms"); if (record.duration_ms !== completed - started) fail("job duration disagrees with timestamps");
    for (const [label, value] of [["job.runner_queue_ms", record.runner_queue_ms], ["job.dag_wait_ms", record.dag_wait_ms]]) if (value !== null) nonNegative(value, label);
    if (record.failure_signature !== null && !/^failure-v1-[a-f0-9]{16}$/.test(record.failure_signature)) fail("job.failure_signature must be normalized");
    normalizedMetrics(record.setup_costs, ["docker_ms", "browser_ms", "node_ms", "npm_ms", "phoenix_ms", "fixture_ms", "playwright_ms"], "job.setup_costs"); normalizedMetrics(record.cache, ["hit", "restore_ms", "save_ms", "size_bytes"], "job.cache");
    if (!CONCLUSIONS.has(record.conclusion)) fail("record contains unsupported conclusion");
  } else if (record.kind === "cohort") {
    normalized(record.cohort_fingerprint, "cohort.cohort_fingerprint", /^cohort-v1-[a-f0-9]{16}$/); nonNegative(record.sample_count, "cohort.sample_count");
    if (!["ready", "insufficient_sample"].includes(record.sample_status)) fail("record contains unsupported sample status");
    if (record.sample_status === "ready") { positive(record.p50_ms, "cohort.p50_ms"); positive(record.p95_ms, "cohort.p95_ms"); } else if (record.p50_ms !== null || record.p95_ms !== null) fail("insufficient cohort must omit percentiles");
    const reliability = record.reliability; allowedFields(reliability, new Set(["total_runs", "failure_count", "cancellation_count", "skipped_count", "rerun_count", "root_incidents"]), "cohort.reliability");
    for (const key of ["total_runs", "failure_count", "cancellation_count", "skipped_count", "rerun_count"]) nonNegative(reliability[key], `cohort.reliability.${key}`);
    if (!Array.isArray(reliability.root_incidents)) fail("cohort.reliability.root_incidents must be an array");
    for (const incident of reliability.root_incidents) { allowedFields(incident, new Set(["signature", "affected_cells"]), "cohort.root_incident"); if (!/^failure-v1-[a-f0-9]{16}$/.test(incident.signature) || !Array.isArray(incident.affected_cells)) fail("cohort root incident is invalid"); incident.affected_cells.forEach((cell) => normalized(cell, "cohort.root_incident.affected_cell")); }
  }
  return record;
}

function args(argv) { const out = {}; for (let i = 0; i < argv.length; i += 2) { if (!argv[i]?.startsWith("--")) fail(`unexpected argument: ${argv[i]}`); out[argv[i].slice(2)] = argv[i + 1] ?? true; } return out; }
function ghJson(endpoint, paginate = false) {
  const response = spawnSync("gh", ["api", endpoint, ...(paginate ? ["--paginate", "--slurp"] : [])], { encoding: "utf8", shell: false, maxBuffer: 64 * 1024 * 1024 });
  if (response.status !== 0) fail(`gh api failed for ${endpoint}: ${response.stderr.trim() || "unknown error"}`);
  const value = JSON.parse(response.stdout);
  return paginate ? value.flat() : value;
}
function ghJsonAsync(endpoint, paginate = false) {
  return new Promise((resolve, reject) => {
    const child = spawn("gh", ["api", endpoint, ...(paginate ? ["--paginate", "--slurp"] : [])], { shell: false });
    let stdout = ""; let stderr = "";
    child.stdout.on("data", (chunk) => { stdout += chunk; }); child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.on("error", reject); child.on("close", (status) => {
      if (status !== 0) reject(new Error(`gh api failed for ${endpoint}: ${stderr.trim() || "unknown error"}`));
      else { const value = JSON.parse(stdout); resolve(paginate ? value.flat() : value); }
    });
  });
}
// This is deliberately a closed, time-bounded inventory rather than a fallback for
// missing jobs.  Each row was established from the repository's workflow history
// and the authenticated 90-day Actions inventory on 2026-08-12.  It describes old
// workflow generations only; current and future runs still use the declared DAG.
const HISTORICAL_DAG_COMPATIBILITY_CUTOFF = "2026-08-12T14:00:00Z";
const HISTORICAL_DAG_COMPATIBILITY = [
  { workflow_revision: "sha256:2535a639493f2b5549d3bb0e1baf12bc12ede268b55cd710e41da3afb22f2e42", job: "admin-drift-and-docs", prerequisite: "release-gate", events: ["schedule"], starts_at: "2026-05-30T00:00:00Z", era: "scheduled-provider-only root before the 226 baseline snapshot", rule: "treat as scheduled root", evidence: "090685036a6c978fcc5906c235187bc9e29dffcf" },
  { workflow_revision: "sha256:943d650205233f1c5c017bc605c90077600ba8c33240ea6268326887c0960ec0", job: "admin-ui-ratchet-guardrails", prerequisite: "admin-hardening-guardrails", events: ["schedule"], starts_at: "2026-07-07T00:00:00Z", era: "parked scheduled ratchet before the 226 baseline snapshot", rule: "treat as scheduled root", evidence: "737c07f58337a1d9b771e705e92b1efba54a4c1d" },
  { workflow_revision: "sha256:943d650205233f1c5c017bc605c90077600ba8c33240ea6268326887c0960ec0", job: "admin-ui-ratchet-guardrails", prerequisite: "admin-phase-200-deterministic-guardrails", events: ["schedule"], starts_at: "2026-07-07T00:00:00Z", era: "parked scheduled ratchet before the 226 baseline snapshot", rule: "treat as scheduled root", evidence: "737c07f58337a1d9b771e705e92b1efba54a4c1d" },
  { workflow_revision: "sha256:89a5a0cb25d05eb88f40cffed7f1ba2549676b440d0a018d218eaa69e253cae8", job: "admin-ui-ratchet-guardrails", prerequisite: "admin-phase-200-deterministic-guardrails", events: ["push", "pull_request", "workflow_dispatch", "schedule"], starts_at: "2026-06-30T00:00:00Z", era: "parked ratchet workflow generation before the 226 baseline snapshot", rule: "retain the observed ratchet root when Phase 200 is absent", evidence: "79f268ebb7220f2da6e1429263b5516b990ad649" },
  { workflow_revision: "sha256:abe82c1752c18b85daccb8a33255b78adee988866a6f1df64c68186d4f90fd43", job: "host-docker-boot-smoke", prerequisite: DOCS_PREREQUISITE, events: ["push", "pull_request", "workflow_dispatch", "schedule"], starts_at: "2026-06-01T00:00:00Z", era: "pre-226 host-smoke workflow generation", rule: "treat the retired/missing docs prerequisite as absent from this historical lane", evidence: "332bddce795b0b07ec49a96a3303dafee7e4687c" },
  { workflow_revision: "sha256:f6b1d06c0897168bdff1b692a63d1704db24b96a48620504888b1fe2f30c47fa", job: "host-integration", prerequisite: "admin-drift-and-docs", events: ["push", "pull_request", "workflow_dispatch", "schedule"], starts_at: "2026-08-11T00:00:00Z", era: "pre-226 host-integration workflow generation", rule: "retain the observed host root when admin drift is absent", evidence: "1426a6b300e00910762d44479001ca23183eb4cc" },
  { workflow_revision: "sha256:f6b1d06c0897168bdff1b692a63d1704db24b96a48620504888b1fe2f30c47fa", job: "host-integration", prerequisite: DOCS_PREREQUISITE, events: ["push", "pull_request", "workflow_dispatch", "schedule"], starts_at: "2026-08-11T00:00:00Z", era: "pre-226 host-integration workflow generation", rule: "retain the observed host root when docs is absent", evidence: "1426a6b300e00910762d44479001ca23183eb4cc" },
  ...["1/3", "2/3", "3/3"].map((shard) => ({ workflow_revision: "sha256:fbef942d3a3f18c88689962c5d658a0a6dde16a95cfeb8e06b99b68d58e3ce99", job: `playwright-e2e-shard-${shard}`, prerequisite: "host-integration", events: ["push", "pull_request", "workflow_dispatch", "schedule"], starts_at: "2026-06-01T00:00:00Z", era: "pre-226 Playwright workflow generation", rule: "retain the observed Playwright root when host integration is absent", evidence: "c1ea350a37285e48b424b35b97ae3db367db3567" }))
];

function compatibilityRule(repo, run, job, prerequisite, present) {
  const created = Date.parse(run.created_at);
  if (repo !== "szTheory/accrue" || !Number.isFinite(created) || created >= Date.parse(HISTORICAL_DAG_COMPATIBILITY_CUTOFF) || present.has(prerequisite) || !validWorkflowRevision(run.workflow_revision)) return null;
  return HISTORICAL_DAG_COMPATIBILITY.find((rule) =>
    rule.workflow_revision === run.workflow_revision && rule.job === job && rule.prerequisite === prerequisite && rule.events.includes(run.event) && created >= Date.parse(rule.starts_at)
  ) || null;
}

function matrixAliases(identity, body, display) {
  if (identity === "playwright-e2e") {
    const shards = body.match(/shard:\s*\[([^\]]+)\]/)?.[1]?.split(",").map((value) => value.trim()).filter(Boolean) || [];
    const aliases = shards.map((shard) => `playwright-e2e-shard-${shard}/${shards.length}`);
    if (display === "Playwright E2E shard ${{ matrix.shard }}/${{ strategy.job-total }}" && shards.length > 0) {
      aliases.push(normalizedIdentity(display, "workflow matrix job"));
    }
    return aliases;
  }
  if (identity !== "release-gate") return [];
  return [...body.matchAll(/- elixir: '([^']+)'\s+otp: '([^']+)'\s+sigra: '([^']+)'\s+opentelemetry: '([^']+)'\s+compatibility: '([^']+)'\s+support: '([^']+)'/g)].map(([, elixir, otp, sigra, opentelemetry, compatibility, support]) =>
    normalizedIdentity(`Release gate (${compatibility}; elixir=${elixir} otp=${otp} sigra=${sigra} opentelemetry=${opentelemetry})${support === "advisory" ? " [advisory]" : ""}`, "workflow matrix job")
  );
}
export function workflowRunnerContracts(source = fs.readFileSync(WORKFLOW_RUNNER_PATH, "utf8")) {
  const contracts = [];
  const pattern = /^  ([A-Za-z0-9_-]+):\n([\s\S]*?)(?=^  [A-Za-z0-9_-]+:\n|(?![\s\S]))/gm;
  for (const match of source.matchAll(pattern)) {
    const [, rawIdentity, body] = match;
    const identity = normalizedIdentity(rawIdentity, "workflow job id");
    const display = body.match(/^    name:\s*(.+)$/m)?.[1]?.trim();
    const runsOn = body.match(/^    runs-on:\s*(.+)$/m)?.[1]?.trim();
    if (!runsOn) continue;
    const canonical = display && !display.includes("${{") ? normalizedIdentity(display, "workflow job name") : identity;
    const needs = (body.match(/^    needs:\s*\[([\s\S]*?)\]/m)?.[1]?.split(",").map((value) => value.trim()).filter(Boolean).map((value) => normalizedIdentity(value, "workflow prerequisite")) || []);
    contracts.push({ identity, canonical, aliases: new Set([identity, canonical, ...matrixAliases(identity, body, display)]), needs, runsOn });
  }
  if (contracts.length === 0) fail("workflow runner contract has no jobs");
  return contracts;
}
export function resolveWorkflowJobIdentity(jobName, contracts = workflowRunnerContracts()) {
  const observed = normalizedIdentity(jobName, "job.name");
  const matches = contracts.filter((contract) => (contract.aliases || new Set([contract.identity, contract.display].filter(Boolean))).has(observed));
  if (matches.length === 0) fail(`job ${observed} has unresolved workflow job identity`);
  if (matches.length !== 1) fail(`job ${observed} has ambiguous workflow job identity`);
  return matches[0];
}
function workflowNeeds(name, run, present = new Set(), repo = "", contracts = workflowRunnerContracts()) {
  const contract = resolveWorkflowJobIdentity(name, contracts);
  const declared = contract.needs.map((need) => {
    const prerequisite = contracts.find((candidate) => candidate.identity === need);
    if (!prerequisite) fail(`workflow job ${contract.identity} has unresolved declared prerequisite ${need}`);
    return prerequisite.canonical;
  });
  const normalized = normalizedIdentity(name, "job.name");
  return declared.filter((prerequisite) => !compatibilityRule(repo, run, normalized, prerequisite, present)).map((prerequisite) => {
    // Matrix jobs have stable declared IDs but Actions exposes enumerated shard
    // labels. Persist the observed alias so timestamp lookup remains exact.
    const observed = [...present].find((candidate) => resolveWorkflowJobIdentity(candidate, contracts).canonical === prerequisite);
    return observed || prerequisite;
  });
}

export function unresolvedPrerequisites(runs, contractsByRun = new Map()) {
  if (!Array.isArray(runs)) fail("runs must be an array");
  return runs.flatMap((run) => {
    const contracts = contractsByRun.get(run) || workflowRunnerContracts();
    const present = new Set((run.jobs || []).map((job) => normalizedIdentity(job.name, "job.name")));
    return (run.jobs || []).flatMap((job) => (job.needs === undefined ? workflowNeeds(job.name, run, present, run.repository || "szTheory/accrue", contracts) : job.needs)
      .map((prerequisite) => normalizedIdentity(prerequisite, "job.needs"))
      .filter((prerequisite) => !present.has(prerequisite))
      .map((prerequisite) => `job ${normalizedIdentity(job.name, "job.name")} has unresolved prerequisite ${prerequisite}`));
  }).sort();
}
function setupCosts(steps = []) {
  const costs = {};
  for (const step of steps) {
    if (!step.started_at || !step.completed_at) continue;
    const ms = duration(step.started_at, step.completed_at, "step");
    const name = String(step.name || "").toLowerCase();
    const key = name.includes("docker") || name.includes("container") ? "docker_ms"
      : name.includes("chromium") || name.includes("browser") ? "browser_ms"
      : name.includes("set up node") ? "node_ms"
      : name.includes("npm ci") || name.includes("install admin deps") || name.includes("install assets deps") ? "npm_ms"
      : name.includes("phoenix") || name.includes("compile admin") ? "phoenix_ms"
      : name.includes("fixture") || name.includes("seed") ? "fixture_ms"
      : name.includes("playwright") ? "playwright_ms" : null;
    if (key) costs[key] = (costs[key] || 0) + ms;
  }
  return costs;
}
function cacheFacts(steps = []) {
  const matched = steps.filter((step) => /cache/i.test(String(step.name || "")) && step.started_at && step.completed_at);
  if (!matched.length) return {};
  return { hit: matched.some((step) => /restore/i.test(String(step.name || ""))), restore_ms: matched.filter((step) => /restore/i.test(String(step.name || ""))).reduce((sum, step) => sum + duration(step.started_at, step.completed_at, "step"), 0), save_ms: matched.filter((step) => /save/i.test(String(step.name || ""))).reduce((sum, step) => sum + duration(step.started_at, step.completed_at, "step"), 0), size_bytes: 0 };
}
function runnerClassImage(runsOn) {
  const declared = String(runsOn).trim().replace(/^['"]|['"]$/g, "");
  if (/\bself-hosted\b/i.test(declared)) return "self-hosted/declared";
  if (/^(ubuntu|macos|windows)-[a-z0-9.-]+$/i.test(declared)) return `github-hosted/${declared.toLowerCase()}`;
  fail("workflow runner contract has unsupported runs-on declaration");
}
export function workflowRunnerImage(jobName, contracts = workflowRunnerContracts()) {
  try {
    return runnerClassImage(resolveWorkflowJobIdentity(jobName, contracts).runsOn);
  } catch (error) {
    fail(error.message.replace("workflow job identity", "workflow runner contract"));
  }
}
async function fetchGhPages(endpoint) {
  return endpoint.includes("/jobs?") ? ghJsonAsync(endpoint, true) : ghJson(endpoint, true);
}
async function fetchWorkflowContent(repo, workflow, headSha) {
  const value = await ghJsonAsync(`/repos/${repo}/contents/.github/workflows/${workflow}?ref=${headSha}`);
  if (!value || typeof value.content !== "string" || value.encoding !== "base64") fail("workflow content lookup returned no base64 content");
  return Buffer.from(value.content, "base64").toString("utf8");
}
export async function liveRuns(repo, workflow, windowDays, { fetchPages = fetchGhPages, fetchWorkflow, now = Date.now } = {}) {
  const loadWorkflow = fetchWorkflow || (fetchPages === fetchGhPages ? fetchWorkflowContent : async () => fs.readFileSync(WORKFLOW_RUNNER_PATH, "utf8"));
  const cutoff = new Date(now() - windowDays * 86_400_000).toISOString().slice(0, 10);
  const listed = (await fetchPages(`/repos/${repo}/actions/workflows/${workflow}/runs?per_page=100&created=>=${cutoff}`)).flatMap((page) => page.workflow_runs || []);
  const results = [];
  for (let index = 0; index < listed.length; index += LIVE_RUN_CONCURRENCY) {
    results.push(...await Promise.all(listed.slice(index, index + LIVE_RUN_CONCURRENCY).map(async (run) => {
    if (!Number.isInteger(run.run_attempt) || run.run_attempt < 1) fail("run.run_attempt must be a positive integer");
    if (typeof run.head_sha !== "string" || !/^[0-9a-f]{40}$/i.test(run.head_sha)) fail("run.head_sha must be a full SHA");
    const source = await loadWorkflow(repo, workflow, run.head_sha);
    if (typeof source !== "string" || source.length === 0) fail("workflow source must be a non-empty string");
    // Fixture callers may supply a recorded historical digest without a Contents
    // transport.  Production collection always uses the fetched bytes below.
    const revision = fetchWorkflow || fetchPages === fetchGhPages ? workflowRevision(source) : (validWorkflowRevision(run.workflow_revision) ? run.workflow_revision : workflowRevision(source));
    const contracts = workflowRunnerContracts(source);
    const attempt = run.run_attempt;
    const attemptJobs = (await fetchPages(`/repos/${repo}/actions/runs/${run.id}/attempts/${attempt}/jobs?per_page=100`)).flatMap((page) => page.jobs || []).map((job) => {
      if (job.run_attempt != null && job.run_attempt !== attempt) fail("job.run_attempt must match run.run_attempt");
      return job;
    }).filter((job) => job.conclusion !== "skipped" && typeof job.name === "string" && /[A-Za-z0-9]/.test(job.name) && job.started_at && job.completed_at && Date.parse(job.completed_at) >= Date.parse(job.started_at));
    const eligibleJobs = attemptJobs.filter((job) => {
      const contract = resolveWorkflowJobIdentity(job.name, contracts);
      if (!TIMING_NODES_REQUIRING_COMPLETE_PREREQUISITES.has(contract.identity)) return true;
      return contract.needs.every((need) => {
        const prerequisite = contracts.find((candidate) => candidate.identity === need);
        return prerequisite && attemptJobs.some((candidate) =>
          candidate.conclusion === "success" && resolveWorkflowJobIdentity(candidate.name, contracts).canonical === prerequisite.canonical
        );
      });
    });
    const present = new Set(eligibleJobs.map((job) => normalizedIdentity(job.name, "job.name")));
    const jobs = eligibleJobs.map((job) => ({
      id: job.id, html_url: job.html_url, name: job.name, started_at: job.started_at, completed_at: job.completed_at,
      conclusion: CONCLUSIONS.has(job.conclusion) ? job.conclusion : "unknown", runner_image: workflowRunnerImage(job.name, contracts), needs: workflowNeeds(job.name, { ...run, workflow_revision: revision }, present, repo, contracts),
      setup_costs: setupCosts(job.steps), cache: cacheFacts(job.steps)
    }));
    const createdAt = run.created_at;
    const startedAt = Date.parse(run.run_started_at || createdAt) < Date.parse(createdAt) ? createdAt : (run.run_started_at || createdAt);
    const updatedAt = Date.parse(run.updated_at) < Date.parse(startedAt) ? startedAt : run.updated_at;
    return { id: run.id, html_url: run.html_url, head_sha: run.head_sha, created_at: createdAt, run_started_at: startedAt, updated_at: updatedAt, event: run.event, head_branch: run.head_branch, conclusion: CONCLUSIONS.has(run.conclusion) ? run.conclusion : "unknown", run_attempt: attempt, original_run_id: run.id, workflow_path: workflow, workflow_revision: revision, provider_state: "non_run", jobs };
    })));
  }
  return results;
}
async function main() {
  const options = args(process.argv.slice(2));
  const windowDays = Number(options["window-days"] || 90); const sampleSize = Number(options["sample-size"] || 20);
  let runs; let snapshot = null;
  if (options.input || options.fixtures) runs = JSON.parse(fs.readFileSync(options.input || options.fixtures, "utf8")).runs || Object.values(JSON.parse(fs.readFileSync(options.input || options.fixtures, "utf8")));
  else {
    if (!options.repo || !options.workflow) fail("live collection requires --repo and --workflow");
    runs = await liveRuns(options.repo, options.workflow, windowDays);
    const now = new Date().toISOString();
    snapshot = { schema_version: SCHEMA_VERSION, kind: "snapshot", snapshot_generated_at: now, window_start: new Date(Date.now() - windowDays * 86_400_000).toISOString(), window_end: now, repository: options.repo, workflow: options.workflow, sample_target: sampleSize };
  }
  const records = collectBaseline(runs); const cohorts = summarizeCohorts(runs, { windowDays, sampleSize });
  const output = `${[...(snapshot ? [snapshot] : []), ...records, ...cohorts].map((record) => JSON.stringify(validateRecord(record))).sort((left, right) => left.localeCompare(right)).join("\n")}\n`;
  if (options.out) fs.writeFileSync(options.out, output); else process.stdout.write(output);
}
if (process.argv[1] === fileURLToPath(import.meta.url)) main().catch((error) => { console.error(`collect ci baseline: FAIL: ${error.message}`); process.exitCode = 1; });
