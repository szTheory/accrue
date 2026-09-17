#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { performance } = require("node:perf_hooks");

const REPOSITORY = "szTheory/accrue";
const FULL_SHA = /^[0-9a-f]{40}$/;
const COMMANDS = new Set(["list", "inspect", "watch"]);
const MAX_LIMIT = 100;
const MAX_POLL_SECONDS = 300;
const MAX_TIMEOUT_SECONDS = 3600;
const MAX_FAILURE_DETAILS = 10;
const GH_READ_TIMEOUT_MS = 30_000;
const GH_READ_MAX_BUFFER = 1024 * 1024;
const UNSUCCESSFUL_COMPLETION_EXIT = 69;
const DEFAULT_WRAPPER_PATH = path.join(__dirname, "watch_ci.sh");

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
    else if (arg === "--verify-docs") options.verifyDocs = value();
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
  const asJson = (argv, remainingMs) => {
    readOnlyArgv(argv); calls.push([...argv]);
    const timeoutMs = typeof remainingMs === "function" ? remainingMs() : undefined;
    const response = invoke([...argv], { timeoutMs });
    if (typeof remainingMs === "function") remainingMs();
    if (response === null || response === undefined) fail(67, "GitHub response is unavailable");
    if (typeof response === "string") { try { return JSON.parse(response); } catch { fail(67, "GitHub response was not JSON"); } }
    return response;
  };
  return {
    calls,
    listRuns({ branch, workflow, limit = 20, commit, remainingMs } = {}) {
      const argv = ["run", "list", "-R", REPOSITORY, "--json", "databaseId,headSha,status,conclusion,createdAt,updatedAt,workflowName"];
      if (branch) argv.push("--branch", branch); if (workflow) argv.push("--workflow", workflow); if (commit) argv.push("--commit", commit);
      argv.push("--limit", String(limit));
      const response = asJson(argv, remainingMs);
      if (!Array.isArray(response)) fail(67, "GitHub run list response is not an array");
      return response;
    },
    viewRun(runId, { remainingMs } = {}) {
      const response = asJson(["run", "view", String(runId), "-R", REPOSITORY, "--json", "databaseId,headSha,status,conclusion,createdAt,updatedAt,workflowName,jobs"], remainingMs);
      if (!response || typeof response !== "object") fail(67, "GitHub run view response is null or invalid");
      return response;
    }
  };
}
function createGhReadAdapter() {
  return createReadAdapter((argv, { timeoutMs } = {}) => {
    const boundedTimeout = timeoutMs === undefined ? GH_READ_TIMEOUT_MS : Math.max(1, Math.min(GH_READ_TIMEOUT_MS, Math.floor(timeoutMs)));
    const result = spawnSync("gh", argv, { encoding: "utf8", shell: false, timeout: boundedTimeout, maxBuffer: GH_READ_MAX_BUFFER });
    if (result.error?.code === "ETIMEDOUT" && timeoutMs !== undefined) fail(68, "watch timed out during GitHub read");
    if (result.error) fail(67, `GitHub CLI unavailable: ${result.error.code || result.error.message}`);
    if (result.status !== 0) fail(67, `GitHub read failed: ${(result.stderr || "unknown error").trim().slice(0, 240)}`);
    return result.stdout;
  });
}
function listRuns(adapter, options) {
  validateRepository(options.repo);
  const runs = adapter.listRuns({ branch: options.branch, workflow: options.workflow, limit: options.limit, remainingMs: options.remainingMs });
  const normalized = runs.map((run) => normalizeRun(run)).filter((run) => !options.workflow || run.workflow === options.workflow);
  if (normalized.length === 0) fail(65, "no GitHub Actions runs matched the requested list");
  return normalized.sort(compareRuns);
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
  try {
    const matching = adapter.listRuns({ commit: sha, workflow: options.workflow, limit: MAX_LIMIT, remainingMs: options.remainingMs }).map((run) => normalizeRun(run)).filter((run) => run.sha === sha && (!options.workflow || run.workflow === options.workflow));
    if (matching.length === 0) fail(65, "no GitHub Actions run matched");
    if (matching.length > 1) fail(66, "ambiguous GitHub Actions runs matched");
    const selected = matching[0];
    const viewed = adapter.viewRun(selected.run_id, { remainingMs: options.remainingMs }); const run = normalizeRun(viewed);
    if (run.run_id !== selected.run_id) fail(67, `GitHub run view changed selected run ID ${selected.run_id} to ${run.run_id}`);
    if (run.sha !== selected.sha || run.sha !== sha) fail(67, "GitHub run view did not retain the selected and requested SHA");
    if (options.workflow && run.workflow !== options.workflow) fail(67, `GitHub run view did not retain requested workflow ${options.workflow}`);
    return { ...run, failed_jobs: summarizeFailures(viewed.jobs ?? []) };
  } catch (error) {
    if (error instanceof MonitorError) throw new MonitorError(error.code, `${REPOSITORY} ${sha}: ${error.message}`);
    throw error;
  }
}
function resolveBranchSha(adapter, options) {
  if (options.sha) return validateFullSha(options.sha);
  if (!options.branch) return validateFullSha(options.sha);
  const candidates = listRuns(adapter, { ...options, limit: 1 });
  if (candidates.length !== 1) fail(66, `branch ${options.branch} did not resolve exactly one run`);
  return candidates[0].sha;
}
function watchSha(adapter, options, { now = () => performance.now(), sleep = () => {} } = {}) {
  validateRepository(options.repo);
  let sha = options.sha ? validateFullSha(options.sha) : null;
  const deadline = now() + options.timeoutSeconds * 1000;
  const attribution = () => sha || `branch ${options.branch || "unresolved"}`;
  const remainingMs = () => {
    const remaining = Math.ceil(deadline - now());
    if (remaining <= 0) fail(68, `${REPOSITORY} ${attribution()}: watch timed out`);
    return remaining;
  };
  try {
    sha = resolveBranchSha(adapter, { ...options, sha, remainingMs });
    remainingMs();
    while (true) {
      const result = inspectSha(adapter, { ...options, sha, remainingMs });
      remainingMs();
      if (result.status === "completed") return result;
      sleep(Math.min(options.pollSeconds * 1000, remainingMs()));
      remainingMs();
    }
  } catch (error) {
    if (error instanceof MonitorError && !error.message.startsWith(`${REPOSITORY} `)) throw new MonitorError(error.code, `${REPOSITORY} ${attribution()}: ${error.message}`);
    throw error;
  }
}
function render(value, format) {
  if (format === "json") return `${JSON.stringify(value)}\n`;
  if (Array.isArray(value)) return value.map((run) => `${run.repository} ${run.sha} ${run.run_id} ${run.status} ${run.conclusion ?? "pending"}`).join("\n") + "\n";
  return `${value.repository} ${value.sha} ${value.run_id} ${value.status} ${value.conclusion ?? "pending"}\n`;
}
function completionExitCode(value) {
  return !Array.isArray(value) && value.status === "completed" && value.conclusion !== "success"
    ? UNSUCCESSFUL_COMPLETION_EXIT
    : 0;
}
function verifyWrapper(path) {
  const wrapper = fs.readFileSync(path, "utf8"); const execCount = (wrapper.match(/\bexec\s+node\b/g) || []).length;
  if (execCount !== 1 || !/ci_monitor\.cjs["']?\s+watch/.test(wrapper) || !/--repo\s+szTheory\/accrue/.test(wrapper) || !/--timeout-seconds/.test(wrapper) || /\bgh\s+(run|api|workflow)\b/.test(wrapper)) fail(67, "wrapper must perform exactly one bounded monitor exec with no direct GitHub command");
  return true;
}
function wrapperFixture(wrapperPath, args = [], { conclusion = "success" } = {}) {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "phase229-ci-wrapper-"));
  const ghPath = path.join(scratch, "gh");
  const callsPath = path.join(scratch, "calls.ndjson");
  const sha = "a".repeat(40);
  const releaseSha = "b".repeat(40);
  fs.writeFileSync(ghPath, `#!/usr/bin/env node
"use strict";
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.CI_MONITOR_FIXTURE_CALLS, JSON.stringify(args) + "\\n");
const conclusion = process.env.CI_MONITOR_FIXTURE_CONCLUSION;
const sha = "${sha}";
const releaseSha = "${releaseSha}";
const makeRun = (id, headSha, workflow) => ({ databaseId: id, headSha, status: "completed", conclusion, createdAt: "2026-01-01T00:00:00Z", updatedAt: "2026-01-01T00:01:00Z", workflowName: workflow });
const runs = [makeRun(7, sha, "CI"), makeRun(8, sha, "Other"), makeRun(9, releaseSha, "Release")];
if (args[0] === "run" && args[1] === "list") {
  const commitAt = args.indexOf("--commit");
  const selected = commitAt === -1 ? runs : runs.filter((run) => run.headSha === args[commitAt + 1]);
  process.stdout.write(JSON.stringify(selected));
} else if (args[0] === "run" && args[1] === "view") {
  const run = runs.find((candidate) => candidate.databaseId === Number(args[2]));
  process.stdout.write(JSON.stringify({ ...run, jobs: conclusion === "failure" ? [{ name: "unit", conclusion: "failure", runAttempt: 1, steps: [{ name: "test", conclusion: "failure", number: 1 }] }] : [] }));
} else {
  process.stderr.write("fixture rejected operation\\n");
  process.exitCode = 91;
}
`, { mode: 0o755 });
  try {
    const result = spawnSync("bash", [wrapperPath, ...args], {
      encoding: "utf8",
      env: {
        ...process.env,
        PATH: `${scratch}:${process.env.PATH || ""}`,
        NODE_TEST_CONTEXT: "",
        CI_MONITOR_FIXTURE_CALLS: callsPath,
        CI_MONITOR_FIXTURE_CONCLUSION: conclusion
      }
    });
    const calls = fs.existsSync(callsPath)
      ? fs.readFileSync(callsPath, "utf8").trim().split("\n").filter(Boolean).map((line) => JSON.parse(line))
      : [];
    return { ...result, calls, sha, releaseSha };
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
}
function delayedGhWatchFixture({ delayMilliseconds = 1200, timeoutSeconds = 1 } = {}) {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "phase229-ci-deadline-"));
  const ghPath = path.join(scratch, "gh");
  const sha = "a".repeat(40);
  fs.writeFileSync(ghPath, `#!/usr/bin/env node
"use strict";
const args = process.argv.slice(2);
Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ${delayMilliseconds});
const run = { databaseId: 7, headSha: "${sha}", status: "completed", conclusion: "success", createdAt: "2026-01-01T00:00:00Z", updatedAt: "2026-01-01T00:01:00Z", workflowName: "CI" };
if (args[0] === "run" && args[1] === "list") process.stdout.write(JSON.stringify([run]));
else if (args[0] === "run" && args[1] === "view") process.stdout.write(JSON.stringify({ ...run, jobs: [] }));
else process.exitCode = 91;
`, { mode: 0o755 });
  const started = process.hrtime.bigint();
  try {
    const result = spawnSync(process.execPath, [__filename, "watch", "--repo", REPOSITORY, "--sha", sha, "--workflow", "CI", "--timeout-seconds", String(timeoutSeconds), "--poll-seconds", "1"], {
      encoding: "utf8",
      env: { ...process.env, PATH: `${scratch}:${process.env.PATH || ""}`, NODE_TEST_CONTEXT: "" }
    });
    return { ...result, elapsedMilliseconds: Number(process.hrtime.bigint() - started) / 1e6, sha };
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
}
function optionValue(argv, option) {
  const index = argv.indexOf(option);
  return index === -1 ? undefined : argv[index + 1];
}
function verifyWrapperBehavior(wrapperPath) {
  const defaultRun = wrapperFixture(wrapperPath);
  assert.equal(defaultRun.status, 0, `no-argument wrapper must succeed for a completed successful CI run; stderr: ${defaultRun.stderr}`);
  assert.deepEqual({ repository: JSON.parse(defaultRun.stdout).repository, sha: JSON.parse(defaultRun.stdout).sha }, { repository: REPOSITORY, sha: defaultRun.sha }, "wrapper output must identify the fixed repository and resolved full SHA");
  assert.ok(defaultRun.calls.length >= 3, "wrapper must resolve then inspect the selected run");
  assert.equal(optionValue(defaultRun.calls[0], "--branch"), "main", "no-argument wrapper must resolve branch main");
  assert.ok(defaultRun.calls.filter((argv) => argv[1] === "list").every((argv) => optionValue(argv, "--workflow") === "CI"), "default wrapper run listings must select only workflow CI");
  assert.ok(defaultRun.calls.every((argv) => optionValue(argv, "-R") === REPOSITORY), "every wrapper read must bind the fixed repository");

  const positionalBranch = wrapperFixture(wrapperPath, ["release/v1"]);
  assert.equal(positionalBranch.status, 0, `positional branch wrapper failed: ${positionalBranch.stderr}`);
  assert.equal(optionValue(positionalBranch.calls[0], "--branch"), "release/v1");

  const exactSha = wrapperFixture(wrapperPath, ["ignored-branch", "--sha", "a".repeat(40)]);
  assert.equal(exactSha.status, 0, `exact-SHA wrapper failed: ${exactSha.stderr}`);
  assert.ok(exactSha.calls.every((argv) => !argv.includes("--branch")), "explicit SHA must bypass branch resolution");
  assert.ok(exactSha.calls.filter((argv) => argv[1] === "list").every((argv) => optionValue(argv, "--workflow") === "CI"), "explicit SHA retains the CI workflow default");

  const explicitWorkflow = wrapperFixture(wrapperPath, ["--workflow", "Release"]);
  assert.equal(explicitWorkflow.status, 0, `explicit-workflow wrapper failed: ${explicitWorkflow.stderr}`);
  assert.deepEqual({ repository: JSON.parse(explicitWorkflow.stdout).repository, sha: JSON.parse(explicitWorkflow.stdout).sha }, { repository: REPOSITORY, sha: explicitWorkflow.releaseSha });
  assert.ok(explicitWorkflow.calls.filter((argv) => argv[1] === "list").every((argv) => optionValue(argv, "--workflow") === "Release"));

  for (const conclusion of ["failure", "cancelled", "action_required", "stale", "skipped", "timed_out", "neutral", "unknown"]) {
    const unsuccessful = wrapperFixture(wrapperPath, [], { conclusion });
    assert.equal(unsuccessful.status, 69, `${conclusion} completion must exit 69; stderr: ${unsuccessful.stderr}`);
    assert.deepEqual({ repository: JSON.parse(unsuccessful.stdout).repository, sha: JSON.parse(unsuccessful.stdout).sha }, { repository: REPOSITORY, sha: unsuccessful.sha }, `${conclusion} output must retain repository and exact SHA`);
  }
  return true;
}
function verifyDocs(path) {
  const docs = fs.readFileSync(path, "utf8");
  const required = [
    /Phase 229 repository truth and read-only CI observation/,
    /229-REPOSITORY-INVENTORY\.json/,
    /229-REPOSITORY-INVENTORY\.md/,
    /verify_repository_inventory\.mjs/,
    /ci_monitor\.cjs list --repo szTheory\/accrue/,
    /ci_monitor\.cjs inspect --repo szTheory\/accrue --sha FULL_SHA/,
    /ci_monitor\.cjs watch --repo szTheory\/accrue --sha FULL_SHA --timeout-seconds \d+ --poll-seconds \d+/,
    /Actions success is not live-provider proof/,
    /branch `main`, workflow `CI`, timeout `900` seconds, and poll interval `10` seconds/,
    /explicit full SHA takes precedence and bypasses branch resolution/,
    /another workflow on the same branch cannot become the default target/,
    /completed `success` exits `0`/i,
    /Completed `failure`, `cancelled`, `action_required`, `stale`, `skipped`, `timed_out`, `neutral`, or unknown non-success conclusions[\s\S]*exit `69`/,
    /malformed usage exits `64`[\s\S]*no match exits `65`[\s\S]*ambiguity exits `66`[\s\S]*responses exit `67`[\s\S]*deadline exits `68`/,
    /provider_proof: non_run/,
    /CI execution[\s\S]*history integration[\s\S]*PR\/ref mutation[\s\S]*publication are outside Phase 229/,
    /read-only/,
    /watch_ci\.sh.*compatibility/i,
    /JSON.*authority.*Markdown.*projection/i
  ];
  if (!required.every((pattern) => pattern.test(docs))) fail(67, "documentation must preserve the Phase 229 repository-bound list, exact-SHA inspect, bounded watch, and evidence semantics");
  return true;
}
function fixtureAdapter(sequence) {
  let index = 0;
  return createReadAdapter((argv) => { const next = sequence[Math.min(index, sequence.length - 1)]; index += 1; return typeof next === "function" ? next(argv) : next; });
}
function runSelfTest({ wrapperPath = DEFAULT_WRAPPER_PATH, docsPath } = {}) {
  const sha = "a".repeat(40);
  const run = { databaseId: 7, headSha: sha, status: "completed", conclusion: "failure", createdAt: "2026-01-01T00:00:00Z", updatedAt: "2026-01-01T00:01:00Z", workflowName: "CI" };
  const adapter = fixtureAdapter([[run], { ...run, jobs: [{ name: "unit", conclusion: "failure", runAttempt: 1, steps: [{ name: "test", conclusion: "failure", number: 3, raw: "never emitted" }] }] }]);
  const inspected = inspectSha(adapter, { repo: REPOSITORY, sha });
  assert.equal(inspected.repository, REPOSITORY); assert.equal(inspected.sha, sha);
  assert.deepEqual(inspected.failed_jobs, [{ name: "unit", conclusion: "failure", attempt: 1, failing_steps: [{ name: "test", conclusion: "failure", number: 3 }] }]);
  assert.ok(adapter.calls.every((argv) => argv.includes("-R") && argv[argv.indexOf("-R") + 1] === REPOSITORY)); assert.ok(adapter.calls.every((argv) => /^(run list|run view)/.test(argv.join(" "))));
  assert.throws(() => validateRepository("other/repo"), /repository must/); assert.throws(() => validateFullSha("A".repeat(40)), /lowercase/);
  assert.throws(() => inspectSha(fixtureAdapter([[]]), { repo: REPOSITORY, sha }), (error) => error.code === 65 && error.message.includes(REPOSITORY) && error.message.includes(sha));
  assert.throws(() => inspectSha(fixtureAdapter([[run, { ...run, databaseId: 8 }]]), { repo: REPOSITORY, sha }), (error) => error.code === 66 && error.message.includes(REPOSITORY) && error.message.includes(sha));
  assert.throws(() => inspectSha(fixtureAdapter([null]), { repo: REPOSITORY, sha }), (error) => error.code === 67 && error.message.includes(REPOSITORY) && error.message.includes(sha));
  assert.throws(() => listRuns(fixtureAdapter([[]]), { repo: REPOSITORY, limit: 1 }), (error) => error.code === 65);
  assert.throws(() => readOnlyArgv(["run", "rerun", "-R", REPOSITORY]), /forbidden/); assert.equal(normalizeRun({ ...run, conclusion: "success" }).provider_proof, "non_run");
  assert.deepEqual(listRuns(fixtureAdapter([[{ ...run, databaseId: 9 }, { ...run, databaseId: 8, headSha: "b".repeat(40) }]]), { repo: REPOSITORY, limit: 2 }).map((item) => item.run_id), [9, 8]);
  assert.equal(inspectSha(fixtureAdapter([[{ ...run, conclusion: "cancelled" }], { ...run, conclusion: "cancelled", jobs: [] }]), { repo: REPOSITORY, sha }).conclusion, "cancelled");
  let clock = 0; const queued = { ...run, status: "queued", conclusion: null };
  assert.throws(() => watchSha(fixtureAdapter([[queued], { ...queued, jobs: [] }, [queued], { ...queued, jobs: [] }]), { repo: REPOSITORY, sha, timeoutSeconds: 1, pollSeconds: 1 }, { now: () => clock, sleep: () => { clock += 1000; } }), (error) => error.code === 68 && error.message.includes(sha));
  const inProgress = { ...run, status: "in_progress", conclusion: null };
  const completed = { ...run, status: "completed", conclusion: "success" };
  assert.equal(watchSha(fixtureAdapter([[inProgress], { ...inProgress, jobs: [] }, [completed], { ...completed, jobs: [] }]), { repo: REPOSITORY, sha, timeoutSeconds: 2, pollSeconds: 1 }, { now: () => clock, sleep: () => { clock += 1000; } }).conclusion, "success");
  if (wrapperPath) { verifyWrapper(wrapperPath); verifyWrapperBehavior(wrapperPath); }
  if (docsPath) verifyDocs(docsPath);
  return true;
}
function main(argv = process.argv.slice(2), adapter = createGhReadAdapter()) {
  const options = parseArgs(argv);
  if (options.selfTest) { runSelfTest({ wrapperPath: options.verifyWrapper, docsPath: options.verifyDocs }); process.stdout.write("ci monitor self-test: PASS\n"); return 0; }
  if (options.verifyWrapper) { verifyWrapper(options.verifyWrapper); process.stdout.write("ci monitor wrapper: PASS\n"); return 0; }
  if (options.verifyDocs) { verifyDocs(options.verifyDocs); process.stdout.write("ci monitor docs: PASS\n"); return 0; }
  if (!options.command) fail(64, "subcommand must be one of: list, inspect, watch");
  const value = options.command === "list" ? listRuns(adapter, options) : options.command === "inspect" ? inspectSha(adapter, options) : watchSha(adapter, options, { sleep: (milliseconds) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds) });
  process.stdout.write(render(value, options.format)); return completionExitCode(value);
}
if (require.main === module && !process.env.NODE_TEST_CONTEXT) { try { process.exitCode = main(); } catch (error) { process.stderr.write(`ci monitor: ${error.message}\n`); process.exitCode = error instanceof MonitorError ? error.code : 70; } }
if (process.env.NODE_TEST_CONTEXT) {
  const test = require("node:test");
  test("ci monitor core validates a read-only exact-SHA monitor", () => { assert.equal(runSelfTest({ wrapperPath: null }), true); });
  test("watch absolute deadline bounds delayed GitHub reads", () => {
    const result = delayedGhWatchFixture();
    assert.equal(result.status, 68, `deadline breach must exit 68; stdout: ${result.stdout}; stderr: ${result.stderr}`);
    assert.ok(result.elapsedMilliseconds >= 800 && result.elapsedMilliseconds <= 2200, `watch should terminate near its one-second budget, elapsed ${result.elapsedMilliseconds.toFixed(0)}ms`);
    assert.match(result.stderr, new RegExp(`${REPOSITORY} ${result.sha}.*timed out`));
    assert.equal(result.stdout, "", "a response that completed after the deadline must not be reported as success");
  });
  test("inspect binds selected run identity before job summary", () => {
    const sha = "a".repeat(40);
    const selected = { databaseId: 7, headSha: sha, status: "completed", conclusion: "success", createdAt: "2026-01-01T00:00:00Z", updatedAt: "2026-01-01T00:01:00Z", workflowName: "CI" };
    const switchedRun = { ...selected, databaseId: 8 };
    Object.defineProperty(switchedRun, "jobs", { get() { throw new Error("jobs must not be read from a mismatched run"); } });
    assert.throws(() => inspectSha(fixtureAdapter([[selected], switchedRun]), { repo: REPOSITORY, sha, workflow: "CI" }), (error) => error.code === 67 && error.message.includes(REPOSITORY) && error.message.includes(sha) && error.message.includes("run ID"));

    const switchedWorkflow = { ...selected, workflowName: "Other" };
    Object.defineProperty(switchedWorkflow, "jobs", { get() { throw new Error("jobs must not be read from a mismatched workflow"); } });
    assert.throws(() => inspectSha(fixtureAdapter([[selected], switchedWorkflow]), { repo: REPOSITORY, sha, workflow: "CI" }), (error) => error.code === 67 && error.message.includes(REPOSITORY) && error.message.includes(sha) && error.message.includes("workflow"));

    assert.equal(inspectSha(fixtureAdapter([[selected], { ...selected, jobs: [] }]), { repo: REPOSITORY, sha, workflow: "CI" }).run_id, 7);
    const workflowOmitted = { ...selected, workflowName: undefined, jobs: [] };
    assert.equal(inspectSha(fixtureAdapter([[selected], workflowOmitted]), { repo: REPOSITORY, sha }).workflow, null);
  });
  test("compatibility wrapper defaults to main and CI and propagates unsuccessful completions", () => {
    verifyWrapper(DEFAULT_WRAPPER_PATH);
    assert.equal(verifyWrapperBehavior(DEFAULT_WRAPPER_PATH), true);
  });
}

module.exports = { REPOSITORY, MonitorError, parseArgs, validateRepository, validateFullSha, createReadAdapter, listRuns, inspectSha, summarizeFailures, watchSha, completionExitCode, verifyWrapper, verifyWrapperBehavior, verifyDocs, runSelfTest, main };
