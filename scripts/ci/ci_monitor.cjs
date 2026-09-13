#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const { spawnSync } = require("node:child_process");

const REPOSITORY = "szTheory/accrue";
const FULL_SHA = /^[0-9a-f]{40}$/;
const COMMANDS = new Set(["list", "inspect", "watch"]);
const MAX_LIMIT = 100;
const MAX_POLL_SECONDS = 300;
const MAX_TIMEOUT_SECONDS = 3600;
const MAX_FAILURE_DETAILS = 10;

class MonitorError extends Error { constructor(code, message) { super(message); this.code = code; } }
function fail(code, message) { throw new MonitorError(code, message); }
function validateRepository(repo) { if (repo !== REPOSITORY) fail(64, `repository must be ${REPOSITORY}`); return REPOSITORY; }
function validateFullSha(sha) { if (typeof sha !== "string" || !FULL_SHA.test(sha)) fail(64, "--sha must be a full lowercase 40-hex SHA"); return sha; }
function positiveInteger(value, flag, maximum) {
  if (!/^[1-9][0-9]*$/.test(String(value))) fail(64, `${flag} must be a positive integer`);
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number > maximum) fail(64, `${flag} must be at most ${maximum}`);
  return number;
}

function parseArgs(argv) {
  const options = { repo: REPOSITORY, limit: 20, timeoutSeconds: 900, pollSeconds: 10, format: "json" };
  const positional = [];
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (!arg.startsWith("--")) { positional.push(arg); continue; }
    const value = () => { const next = argv[index + 1]; if (next === undefined || next.startsWith("--")) fail(64, `${arg} requires a value`); index += 1; return next; };
    if (arg === "--repo") options.repo = value();
    else if (arg === "--sha") options.sha = value();
    else if (arg === "--branch") options.branch = value();
    else if (arg === "--workflow") options.workflow = value();
    else if (arg === "--limit") options.limit = positiveInteger(value(), "--limit", MAX_LIMIT);
    else if (arg === "--timeout-seconds") options.timeoutSeconds = positiveInteger(value(), "--timeout-seconds", MAX_TIMEOUT_SECONDS);
    else if (arg === "--poll-seconds") options.pollSeconds = positiveInteger(value(), "--poll-seconds", MAX_POLL_SECONDS);
    else if (arg === "--format") options.format = value();
    else if (arg === "--verify-wrapper") options.verifyWrapper = value();
    else if (arg === "--self-test") options.selfTest = true;
    else fail(64, `unrecognized option: ${arg}`);
  }
  if (positional.length > 1) fail(64, "only one subcommand is allowed");
  options.command = positional[0];
  if (options.format !== "json" && options.format !== "text") fail(64, "--format must be json or text");
  if (options.command !== undefined && !COMMANDS.has(options.command)) fail(64, `unknown command: ${options.command}`);
  return options;
}

function required(value, label) { if (value === null || value === undefined || value === "") fail(67, `${label} is unavailable`); return value; }
function normalizeRun(raw, repository = REPOSITORY) {
  if (!raw || typeof raw !== "object") fail(67, "GitHub run response is null or invalid");
  const runId = raw.databaseId ?? raw.id;
  if (!Number.isInteger(runId) || runId < 1) fail(67, "GitHub run has no numeric run ID");
  const sha = validateFullSha(required(raw.headSha ?? raw.head_sha, "GitHub run head SHA"));
  const createdAt = required(raw.createdAt ?? raw.created_at, "GitHub run created time");
  const updatedAt = raw.updatedAt ?? raw.updated_at ?? null;
  return { repository, sha, run_id: runId, created_at: String(createdAt), updated_at: updatedAt === null ? null : String(updatedAt), status: String(raw.status ?? "unknown"), conclusion: raw.conclusion == null ? null : String(raw.conclusion), workflow: raw.workflowName ?? raw.name ?? null, url: `https://github.com/${repository}/actions/runs/${runId}`, provider_proof: raw.providerProof === "proved" ? "proved" : "non_run" };
}
function compareRuns(left, right) { return left.created_at.localeCompare(right.created_at) || left.sha.localeCompare(right.sha) || left.run_id - right.run_id; }

function readOnlyArgv(argv) {
  const joined = argv.join(" ");
  if (!argv.includes("-R") || argv[argv.indexOf("-R") + 1] !== REPOSITORY) fail(67, "GitHub read omitted the fixed repository");
  if (!/^run (list|view)\b/.test(joined) || /\b(dispatch|rerun|cancel|delete|edit|create)\b/.test(joined)) fail(67, "forbidden GitHub operation requested");
  return argv;
}
function createReadAdapter(invoke) {
  const calls = [];
  const asJson = (argv) => {
    readOnlyArgv(argv); calls.push([...argv]);
    const response = invoke([...argv]);
    if (response === null || response === undefined) fail(67, "GitHub response is unavailable");
    if (typeof response === "string") { try { return JSON.parse(response); } catch { fail(67, "GitHub response was not JSON"); } }
    return response;
  };
  return {
    calls,
    listRuns({ branch, workflow, limit = 20, commit } = {}) {
      const argv = ["run", "list", "-R", REPOSITORY, "--json", "databaseId,headSha,status,conclusion,createdAt,updatedAt,workflowName"];
      if (branch) argv.push("--branch", branch); if (workflow) argv.push("--workflow", workflow); if (commit) argv.push("--commit", commit);
      argv.push("--limit", String(limit));
      const response = asJson(argv);
      if (!Array.isArray(response)) fail(67, "GitHub run list response is not an array");
      return response;
    },
    viewRun(runId) {
      const response = asJson(["run", "view", String(runId), "-R", REPOSITORY, "--json", "databaseId,headSha,status,conclusion,createdAt,updatedAt,workflowName,jobs"]);
      if (!response || typeof response !== "object") fail(67, "GitHub run view response is null or invalid");
      return response;
    }
  };
}
function createGhReadAdapter() {
  return createReadAdapter((argv) => {
    const result = spawnSync("gh", argv, { encoding: "utf8", shell: false });
    if (result.error) fail(67, `GitHub CLI unavailable: ${result.error.code || result.error.message}`);
    if (result.status !== 0) fail(67, `GitHub read failed: ${(result.stderr || "unknown error").trim().slice(0, 240)}`);
    return result.stdout;
  });
}
function listRuns(adapter, options) {
  validateRepository(options.repo);
  const runs = adapter.listRuns({ branch: options.branch, workflow: options.workflow, limit: options.limit });
  if (runs.length === 0) fail(65, "no GitHub Actions runs matched the requested list");
  return runs.map((run) => normalizeRun(run)).sort(compareRuns);
}
function summarizeFailures(jobs) {
  if (!Array.isArray(jobs)) fail(67, "GitHub jobs response is not an array");
  return jobs.filter((job) => job && job.conclusion === "failure").slice(0, MAX_FAILURE_DETAILS).map((job) => ({
    name: String(job.name ?? "unnamed job").slice(0, 160), conclusion: "failure", attempt: Number.isInteger(job.runAttempt) && job.runAttempt > 0 ? job.runAttempt : 1,
    failing_steps: Array.isArray(job.steps) ? job.steps.filter((step) => step && step.conclusion === "failure").slice(0, MAX_FAILURE_DETAILS).map((step) => ({ name: String(step.name ?? "unnamed step").slice(0, 160), conclusion: "failure", number: Number.isInteger(step.number) ? step.number : null })) : []
  }));
}
function inspectSha(adapter, options) {
  validateRepository(options.repo); const sha = validateFullSha(options.sha);
  const matching = adapter.listRuns({ commit: sha, workflow: options.workflow, limit: MAX_LIMIT }).map((run) => normalizeRun(run)).filter((run) => run.sha === sha);
  if (matching.length === 0) fail(65, `no GitHub Actions run matches SHA ${sha}`);
  if (matching.length > 1) fail(66, `ambiguous GitHub Actions runs match SHA ${sha}`);
  const viewed = adapter.viewRun(matching[0].run_id); const run = normalizeRun(viewed);
  if (run.sha !== sha) fail(67, `GitHub run view did not retain SHA ${sha}`);
  return { ...run, failed_jobs: summarizeFailures(viewed.jobs ?? []) };
}
function resolveBranchSha(adapter, options) {
  if (!options.branch) return validateFullSha(options.sha);
  const candidates = listRuns(adapter, { ...options, limit: 1 });
  if (candidates.length !== 1) fail(66, `branch ${options.branch} did not resolve exactly one run`);
  return candidates[0].sha;
}
function watchSha(adapter, options, { now = () => Date.now(), sleep = () => {} } = {}) {
  validateRepository(options.repo); const sha = resolveBranchSha(adapter, options); const started = now();
  while (true) {
    const result = inspectSha(adapter, { ...options, sha });
    if (result.status === "completed") return result;
    if (now() - started >= options.timeoutSeconds * 1000) fail(68, `watch timed out for SHA ${sha}`);
    sleep(options.pollSeconds * 1000);
  }
}
function render(value, format) {
  if (format === "json") return `${JSON.stringify(value)}\n`;
  if (Array.isArray(value)) return value.map((run) => `${run.repository} ${run.sha} ${run.run_id} ${run.status} ${run.conclusion ?? "pending"}`).join("\n") + "\n";
  return `${value.repository} ${value.sha} ${value.run_id} ${value.status} ${value.conclusion ?? "pending"}\n`;
}
function verifyWrapper(path) {
  const wrapper = fs.readFileSync(path, "utf8"); const execCount = (wrapper.match(/\bexec\s+node\b/g) || []).length;
  if (execCount !== 1 || !/ci_monitor\.cjs["']?\s+watch/.test(wrapper) || !/--repo\s+szTheory\/accrue/.test(wrapper) || !/--timeout-seconds/.test(wrapper) || /\bgh\s+(run|api|workflow)\b/.test(wrapper)) fail(67, "wrapper must perform exactly one bounded monitor exec with no direct GitHub command");
  return true;
}
function fixtureAdapter(sequence) {
  let index = 0;
  return createReadAdapter((argv) => { const next = sequence[Math.min(index, sequence.length - 1)]; index += 1; return typeof next === "function" ? next(argv) : next; });
}
function runSelfTest({ wrapperPath } = {}) {
  const sha = "a".repeat(40);
  const run = { databaseId: 7, headSha: sha, status: "completed", conclusion: "failure", createdAt: "2026-01-01T00:00:00Z", updatedAt: "2026-01-01T00:01:00Z", workflowName: "CI" };
  const adapter = fixtureAdapter([[run], { ...run, jobs: [{ name: "unit", conclusion: "failure", runAttempt: 1, steps: [{ name: "test", conclusion: "failure", number: 3, raw: "never emitted" }] }] }]);
  const inspected = inspectSha(adapter, { repo: REPOSITORY, sha });
  assert.equal(inspected.repository, REPOSITORY); assert.equal(inspected.sha, sha);
  assert.deepEqual(inspected.failed_jobs, [{ name: "unit", conclusion: "failure", attempt: 1, failing_steps: [{ name: "test", conclusion: "failure", number: 3 }] }]);
  assert.ok(adapter.calls.every((argv) => argv.includes("-R") && argv[argv.indexOf("-R") + 1] === REPOSITORY)); assert.ok(adapter.calls.every((argv) => /^(run list|run view)/.test(argv.join(" "))));
  assert.throws(() => validateRepository("other/repo"), /repository must/); assert.throws(() => validateFullSha("A".repeat(40)), /lowercase/);
  assert.throws(() => inspectSha(fixtureAdapter([[]]), { repo: REPOSITORY, sha }), /no GitHub Actions run/); assert.throws(() => inspectSha(fixtureAdapter([[run, { ...run, databaseId: 8 }]]), { repo: REPOSITORY, sha }), /ambiguous/);
  assert.throws(() => listRuns(fixtureAdapter([null]), { repo: REPOSITORY, limit: 1 }), /unavailable/); assert.throws(() => listRuns(fixtureAdapter([[]]), { repo: REPOSITORY, limit: 1 }), /no GitHub Actions runs/);
  assert.throws(() => readOnlyArgv(["run", "rerun", "-R", REPOSITORY]), /forbidden/); assert.equal(normalizeRun({ ...run, conclusion: "success" }).provider_proof, "non_run");
  assert.deepEqual(listRuns(fixtureAdapter([[{ ...run, databaseId: 9 }, { ...run, databaseId: 8, headSha: "b".repeat(40) }]]), { repo: REPOSITORY, limit: 2 }).map((item) => item.run_id), [9, 8]);
  assert.equal(inspectSha(fixtureAdapter([[{ ...run, conclusion: "cancelled" }], { ...run, conclusion: "cancelled", jobs: [] }]), { repo: REPOSITORY, sha }).conclusion, "cancelled");
  let clock = 0; const queued = { ...run, status: "queued", conclusion: null };
  assert.throws(() => watchSha(fixtureAdapter([[queued], { ...queued, jobs: [] }, [queued], { ...queued, jobs: [] }]), { repo: REPOSITORY, sha, timeoutSeconds: 1, pollSeconds: 1 }, { now: () => clock, sleep: () => { clock += 1000; } }), /timed out/);
  const inProgress = { ...run, status: "in_progress", conclusion: null };
  const completed = { ...run, status: "completed", conclusion: "success" };
  assert.equal(watchSha(fixtureAdapter([[inProgress], { ...inProgress, jobs: [] }, [completed], { ...completed, jobs: [] }]), { repo: REPOSITORY, sha, timeoutSeconds: 2, pollSeconds: 1 }, { now: () => clock, sleep: () => { clock += 1000; } }).conclusion, "success");
  if (wrapperPath) verifyWrapper(wrapperPath);
  return true;
}
function main(argv = process.argv.slice(2), adapter = createGhReadAdapter()) {
  const options = parseArgs(argv);
  if (options.selfTest) { runSelfTest({ wrapperPath: options.verifyWrapper }); process.stdout.write("ci monitor self-test: PASS\n"); return 0; }
  if (options.verifyWrapper) { verifyWrapper(options.verifyWrapper); process.stdout.write("ci monitor wrapper: PASS\n"); return 0; }
  if (!options.command) fail(64, "subcommand must be one of: list, inspect, watch");
  const value = options.command === "list" ? listRuns(adapter, options) : options.command === "inspect" ? inspectSha(adapter, options) : watchSha(adapter, options, { sleep: (milliseconds) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds) });
  process.stdout.write(render(value, options.format)); return 0;
}
if (require.main === module && !process.env.NODE_TEST_CONTEXT) { try { main(); } catch (error) { process.stderr.write(`ci monitor: ${error.message}\n`); process.exitCode = error instanceof MonitorError ? error.code : 70; } }
if (process.env.NODE_TEST_CONTEXT) require("node:test")("ci monitor self-test validates a read-only exact-SHA monitor", () => { assert.equal(runSelfTest(), true); });

module.exports = { REPOSITORY, MonitorError, parseArgs, validateRepository, validateFullSha, createReadAdapter, listRuns, inspectSha, summarizeFailures, watchSha, verifyWrapper, runSelfTest, main };
