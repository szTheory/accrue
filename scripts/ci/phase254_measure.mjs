#!/usr/bin/env node
//
// Phase 254 (CIQ-04) measurement harness.
//
// One command reproduces a fingerprinted sample for a named existing Phase
// 252/253 lane, with per-test durations retained, under the D-21 protocols:
//
//   cold     fresh empty MIX_BUILD_PATH + fresh disposable lab database,
//            compile / database / boot-to-health separated (3 runs)
//   warm     healthy `serve --lane admin-review`, page.goto -> story ready
//            marker on representative stories (1 warmup + 10 runs per story)
//   focused  one precompiled lane, per-cell median/p90 and overhead
//            (1 warmup + 5 runs)
//
// Every sample carries a machine fingerprint (FINGERPRINT_KEYS). Numbers taken
// on a developer machine are `informs_only`: a sample is freeze-eligible only
// when it came from a clean ubuntu runner at the full protocol (D-21: Mac
// numbers never freeze CI budgets). The fingerprint is built from an explicit
// allow-list; process.env is never serialized.

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { parsePlaywrightJson } from "./phase252_reporters.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const ADMIN_ROOT = path.join(ROOT, "accrue_admin");
const LAB = "scripts/dev/phase252_lab.mjs";
const MANIFEST_PATH = "storybook/phase252-manifest.json";
const MEASUREMENTS_DIR = "accrue_admin/tmp/phase254/measurements";

export const SCHEMA_VERSION = 1;

const fail = (message) => { throw new Error(`Phase 254 measure: ${message}`); };

// -- fingerprint ----------------------------------------------------------------

export const FINGERPRINT_KEYS = Object.freeze([
  "os", "arch", "cpu_model", "cores", "ram_bytes", "image_os", "image_version", "runner_os",
  "otp", "elixir", "node", "playwright", "workers", "revision", "manifest_sha256", "dirty",
]);

// The only environment inputs the fingerprint reads. They are mapped to
// snake_case output keys; the variable names themselves never appear in output.
const ENV_INPUTS = Object.freeze({ image_os: "ImageOS", image_version: "ImageVersion", runner_os: "RUNNER_OS" });

export const PROTOCOLS = Object.freeze({
  cold: Object.freeze({ runs: 3, warmup: 0 }),
  warm: Object.freeze({ runs: 10, warmup: 1 }),
  focused: Object.freeze({ runs: 5, warmup: 1 }),
});

const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");
const round3 = (value) => Math.round(value * 1000) / 1000;
const nonEmpty = (value) => (typeof value === "string" && value.trim() !== "" ? value.trim() : null);

function git(root, args) {
  const result = spawnSync("git", ["-C", root, ...args], { encoding: "utf8", shell: false, timeout: 20_000, maxBuffer: 20_000_000 });
  if (result.error || result.status !== 0) {
    fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 300)}`);
  }
  return result.stdout;
}

function childEnv(extra = {}) {
  // NODE_TEST_CONTEXT must not reach spawned node processes: node:test treats its
  // mere presence as "already inside a test run" and skips nested registrations.
  const env = { ...process.env, ...extra };
  delete env.NODE_TEST_CONTEXT;
  return env;
}

export function parseConfiguredWorkers(root = ROOT) {
  const config = fs.readFileSync(path.join(root, "accrue_admin", "playwright.phase252.config.js"), "utf8");
  const match = config.match(/\bworkers:\s*(\d+)/);
  if (!match) fail("could not read the configured Playwright workers from playwright.phase252.config.js");
  return Number(match[1]);
}

export function probeToolchain(root = ROOT) {
  const elixir = spawnSync("elixir", ["--version"], { encoding: "utf8", shell: false, timeout: 60_000, env: childEnv() });
  const text = `${elixir.stdout || ""}\n${elixir.stderr || ""}`;
  const otp = text.match(/Erlang\/OTP (\d+)/)?.[1];
  const elixirVersion = text.match(/^Elixir (\S+)/m)?.[1];
  if (!otp || !elixirVersion) fail("could not read the OTP and Elixir versions from `elixir --version`");
  const nodeResult = spawnSync(process.execPath, ["--version"], { encoding: "utf8", shell: false, env: childEnv() });
  const nodeVersion = (nodeResult.stdout || "").trim().replace(/^v/, "");
  if (!nodeVersion) fail("could not read the Node version");
  const playwrightManifest = path.join(root, "accrue_admin", "node_modules", "playwright", "package.json");
  if (!fs.existsSync(playwrightManifest)) fail("Playwright is not installed under accrue_admin/node_modules");
  return {
    otp,
    elixir: elixirVersion,
    node: nodeVersion,
    playwright: JSON.parse(fs.readFileSync(playwrightManifest, "utf8")).version,
    workers: parseConfiguredWorkers(root),
  };
}

export function machineFingerprint(options = {}) {
  const env = options.env ?? process.env;
  const root = options.root ?? ROOT;
  const toolchain = options.toolchain ?? probeToolchain(root);
  const cpus = os.cpus();
  const manifest = fs.readFileSync(path.join(root, MANIFEST_PATH));
  return {
    os: `${os.platform()} ${os.release()}`,
    arch: os.arch(),
    cpu_model: nonEmpty(cpus[0]?.model),
    cores: cpus.length,
    ram_bytes: os.totalmem(),
    image_os: nonEmpty(env[ENV_INPUTS.image_os]),
    image_version: nonEmpty(env[ENV_INPUTS.image_version]),
    runner_os: nonEmpty(env[ENV_INPUTS.runner_os]),
    otp: toolchain.otp,
    elixir: toolchain.elixir,
    node: toolchain.node,
    playwright: toolchain.playwright,
    workers: toolchain.workers,
    revision: git(root, ["rev-parse", "HEAD"]).trim(),
    manifest_sha256: sha256(manifest),
    dirty: git(root, ["status", "--porcelain"]).trim() !== "",
  };
}

// -- statistics and protocol rules -------------------------------------------------

function percentile(values, fraction) {
  const ordered = [...values].sort((left, right) => left - right);
  return ordered[Math.ceil(fraction * ordered.length) - 1];
}

function median(values) {
  const ordered = [...values].sort((left, right) => left - right);
  const middle = Math.floor(ordered.length / 2);
  return ordered.length % 2 === 1 ? ordered[middle] : (ordered[middle - 1] + ordered[middle]) / 2;
}

export function summarizeSamples(values) {
  if (!Array.isArray(values) || values.length === 0) fail("summarizeSamples needs at least one value");
  if (values.some((value) => typeof value !== "number" || !Number.isFinite(value))) fail("summarizeSamples needs finite numeric values");
  return {
    n: values.length,
    median: round3(median(values)),
    p90: round3(percentile(values, 0.9)),
    min: round3(Math.min(...values)),
    max: round3(Math.max(...values)),
  };
}

export function isProtocolComplete(sample) {
  const protocol = PROTOCOLS[sample?.mode];
  if (!protocol) return false;
  return Number.isInteger(sample.n) && Number.isInteger(sample.warmup) &&
    sample.n >= protocol.runs && sample.warmup >= protocol.warmup &&
    Array.isArray(sample.values_ms) && sample.values_ms.length === sample.n;
}

// Reasons a sample may not populate a frozen budget value (D-21, T-254-02).
export function freezeBlockers(sample) {
  const blockers = [];
  const fingerprint = sample?.fingerprint;
  if (!fingerprint || typeof fingerprint !== "object") return ["fingerprint is missing"];
  for (const key of FINGERPRINT_KEYS) {
    if (!(key in fingerprint) || fingerprint[key] === null || fingerprint[key] === undefined || fingerprint[key] === "") {
      blockers.push(`fingerprint.${key} is missing`);
    }
  }
  if (typeof fingerprint.image_os === "string" && !/^ubuntu/.test(fingerprint.image_os)) blockers.push(`image_os ${fingerprint.image_os} is not an ubuntu runner image`);
  if (fingerprint.dirty !== false) blockers.push("the working tree was dirty");
  if (sample.smoke !== false) blockers.push("the sample is below its protocol (smoke)");
  if (sample.mode && !isProtocolComplete(sample)) blockers.push("the sample is below its protocol");
  return blockers;
}

export function isFreezeEligible(sample) {
  return freezeBlockers(sample).length === 0;
}

// -- lanes ------------------------------------------------------------------------

function resultId() {
  return `phase254-${crypto.randomBytes(6).toString("hex")}`;
}

export const LANES = Object.freeze({
  "phase252-render": Object.freeze({
    kind: "playwright",
    describe: "node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-stories-phase252.spec.js",
    build() {
      const id = resultId();
      return {
        executable: process.execPath,
        args: [LAB, "browser", "--", "--reporter=json", "e2e/subscription-stories-phase252.spec.js"],
        cwd: ROOT,
        env: {
          MIX_ENV: "test",
          PHASE252_RESULT_ID: id,
          PLAYWRIGHT_OUTPUT_DIR: path.join(ROOT, "accrue_admin/tmp/phase254/pw-output", id),
        },
        cleanup: [path.join(ROOT, "accrue_admin/tmp/phase252", `render-results-${id}.json`), path.join(ROOT, "accrue_admin/tmp/phase254/pw-output", id)],
      };
    },
  }),
  "phase253-aggregate": Object.freeze({
    kind: "process",
    describe: "node scripts/ci/verify_phase253_compositions.mjs",
    build: () => ({ executable: process.execPath, args: ["scripts/ci/verify_phase253_compositions.mjs"], cwd: ROOT, env: {} }),
  }),
  "phase253-manifest": Object.freeze({
    kind: "process",
    describe: "cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_compositions_manifest_test.exs",
    build: () => ({
      executable: "mix",
      args: ["run", "--no-start", "test/accrue_admin/dev/subscription_compositions_manifest_test.exs"],
      cwd: ADMIN_ROOT,
      env: { MIX_ENV: "test" },
    }),
  }),
  "phase252-aggregate": Object.freeze({
    kind: "process",
    describe: "npm --prefix accrue_admin run phase252:check",
    build: () => ({ executable: "npm", args: ["--prefix", "accrue_admin", "run", "phase252:check"], cwd: ROOT, env: {} }),
  }),
});

export function resolveLane(name) {
  if (!Object.prototype.hasOwnProperty.call(LANES, name)) fail(`unknown lane ${JSON.stringify(name)}; known lanes: ${Object.keys(LANES).join(", ")}`);
  return LANES[name];
}

// -- process timing (the spawnCaptured shape from verify_phase253_compositions) ----

export function spawnTimed(spec) {
  return new Promise((resolve) => {
    const start = Date.now();
    const stdout = [];
    const stderr = [];
    const child = spawn(spec.executable, spec.args, {
      cwd: spec.cwd ?? ROOT,
      env: childEnv(spec.env),
      shell: false,
      stdio: ["ignore", "pipe", "pipe"],
    });
    child.stdout.on("data", (chunk) => stdout.push(Buffer.from(chunk)));
    child.stderr.on("data", (chunk) => stderr.push(Buffer.from(chunk)));
    let settled = false;
    const timer = spec.timeout_ms ? setTimeout(() => child.kill("SIGKILL"), spec.timeout_ms) : null;
    const finish = (exitCode, signal, error = null) => {
      if (settled) return;
      settled = true;
      if (timer) clearTimeout(timer);
      resolve({
        exitCode,
        signal,
        duration_ms: Date.now() - start,
        stdout: Buffer.concat(stdout).toString("utf8"),
        stderr: Buffer.concat(stderr).toString("utf8") + (error ? `${error.message}\n` : ""),
      });
    };
    child.once("error", (error) => finish(127, null, error));
    child.once("exit", (code, signal) => finish(code ?? 1, signal));
  });
}

function tail(text, lines = 8) {
  return text.trim().split("\n").slice(-lines).join("\n");
}

// Runs `command` (a spec or a function returning a spec per run) for `warmup`
// unrecorded plus `runs` recorded iterations and returns the wall time of each
// recorded run. A non-zero exit fails the measurement; there is no best-of.
export async function measureCommand({ mode, lane, command, runs, warmup }) {
  if (!PROTOCOLS[mode]) fail(`unknown measurement mode ${JSON.stringify(mode)}`);
  if (!Number.isInteger(runs) || runs < 1 || !Number.isInteger(warmup) || warmup < 0) fail("runs must be a positive integer and warmup a non-negative integer");
  const values_ms = [];
  const captures = [];
  for (let index = 0; index < warmup + runs; index += 1) {
    const spec = typeof command === "function" ? command(index, index < warmup) : command;
    let outcome;
    try {
      outcome = await spawnTimed(spec);
    } finally {
      for (const target of spec.cleanup ?? []) fs.rmSync(target, { recursive: true, force: true });
    }
    if (outcome.exitCode !== 0) {
      fail(`${lane} ${index < warmup ? "warmup" : "run"} ${index + 1} exited ${outcome.exitCode}${outcome.signal ? ` (${outcome.signal})` : ""}:\n${tail(outcome.stderr || outcome.stdout)}`);
    }
    if (index >= warmup) {
      values_ms.push(outcome.duration_ms);
      captures.push({ stdout: outcome.stdout, stderr: outcome.stderr });
    }
  }
  return { mode, lane, runs, warmup, values_ms, captures };
}

// -- samples ----------------------------------------------------------------------

export function buildLocalSample({ mode, lane, runs, warmup, values_ms, cells = null, cell_samples = [], overhead_ms = null, durations = [], phases = null, fingerprint }) {
  if (!PROTOCOLS[mode]) fail(`unknown measurement mode ${JSON.stringify(mode)}`);
  const stats = summarizeSamples(values_ms);
  const sample = {
    schema_version: SCHEMA_VERSION,
    mode,
    lane,
    protocol: { runs, warmup },
    n: stats.n,
    warmup,
    values_ms,
    median_ms: stats.median,
    p90_ms: stats.p90,
    min_ms: stats.min,
    max_ms: stats.max,
    cells,
    per_cell: cell_samples.length > 0 ? { median_ms: round3(median(cell_samples)), p90_ms: round3(percentile(cell_samples, 0.9)) } : null,
    overhead_ms: overhead_ms === null ? null : round3(overhead_ms),
    durations,
    phases,
    fingerprint,
    source_revision: fingerprint.revision,
    manifest_sha256: fingerprint.manifest_sha256,
    informs_only: true,
    smoke: false,
  };
  sample.smoke = !isProtocolComplete(sample);
  sample.informs_only = !isFreezeEligible(sample);
  return sample;
}

function extractJson(text) {
  try {
    JSON.parse(text);
    return text;
  } catch {
    const start = text.indexOf("{\n");
    const end = text.lastIndexOf("}");
    if (start < 0 || end < start) fail("no Playwright JSON report found in the lane output");
    return text.slice(start, end + 1);
  }
}

// Parses one Playwright JSON report through the Phase 252 reporter (so every
// skipped/retried/flaky/failed result is still rejected) and keeps durations.
export function readReport(reportText) {
  const json = extractJson(reportText);
  const parsed = parsePlaywrightJson(json);
  if (parsed.durations.some(({ duration_ms }) => !Number.isFinite(duration_ms))) fail("Playwright report is missing per-test durations");
  const stats = JSON.parse(json).stats;
  const sum = parsed.durations.reduce((total, entry) => total + entry.duration_ms, 0);
  return { durations: parsed.durations, stats_duration_ms: stats.duration, test_sum_ms: sum, overhead_ms: stats.duration - sum };
}

function medianByIdentity(reports) {
  const byIdentity = new Map();
  for (const report of reports) {
    for (const { identity, duration_ms } of report.durations) {
      if (!byIdentity.has(identity)) byIdentity.set(identity, []);
      byIdentity.get(identity).push(duration_ms);
    }
  }
  return [...byIdentity].map(([identity, values]) => ({ identity, duration_ms: round3(median(values)) }));
}

// Builds a focused-mode sample from the Playwright reports of one or more
// recorded runs. `wall_ms` defaults to each report's stats.duration (the
// `--report` path, where no process wall time exists).
export function focusedSampleFromReports({ reports, lane, runs, warmup, wall_ms, fingerprint }) {
  if (!Array.isArray(reports) || reports.length === 0) fail("focused sample needs at least one report");
  const cells = reports[0].durations.length;
  if (reports.some((report) => report.durations.length !== cells)) fail("focused runs reported different cell counts");
  return buildLocalSample({
    mode: "focused",
    lane,
    runs,
    warmup,
    values_ms: wall_ms ?? reports.map((report) => report.stats_duration_ms),
    cells,
    cell_samples: reports.flatMap((report) => report.durations.map((entry) => entry.duration_ms)),
    overhead_ms: median(reports.map((report) => report.overhead_ms)),
    durations: medianByIdentity(reports),
    fingerprint,
  });
}

export function focusedSampleFromReport({ reportText, lane, fingerprint, runs = 1, warmup = 0 }) {
  return focusedSampleFromReports({ reports: [readReport(reportText)], lane, runs, warmup, fingerprint });
}

export async function runFocused({ lane, runs = PROTOCOLS.focused.runs, warmup = PROTOCOLS.focused.warmup, fingerprint }) {
  const definition = resolveLane(lane);
  const measured = await measureCommand({ mode: "focused", lane, command: () => definition.build(), runs, warmup });
  if (definition.kind === "playwright") {
    const reports = measured.captures.map((capture) => readReport(capture.stdout));
    return focusedSampleFromReports({ reports, lane, runs, warmup, wall_ms: measured.values_ms, fingerprint });
  }
  return buildLocalSample({ mode: "focused", lane, runs, warmup, values_ms: measured.values_ms, fingerprint });
}

export function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`);
}

// -- self-test scenarios (also registered as node:test cases) -------------------------

function withScratchRepo(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-measure-selftest-"));
  try {
    const run = (...args) => {
      const result = spawnSync("git", ["-C", dir, "-c", "core.hooksPath=/dev/null", "-c", "user.email=fixture@example.test", "-c", "user.name=fixture", ...args], { encoding: "utf8" });
      assert.equal(result.status, 0, result.stderr);
    };
    run("init", "-q");
    fs.mkdirSync(path.join(dir, "storybook"), { recursive: true });
    fs.writeFileSync(path.join(dir, MANIFEST_PATH), '{"entries":[]}\n');
    run("add", MANIFEST_PATH);
    run("commit", "-q", "-m", "seed");
    return fn(dir);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

const TOOLCHAIN_FIXTURE = { otp: "28", elixir: "1.19.5", node: "22.14.0", playwright: "1.59.1", workers: 1 };

const SCENARIOS = [
  ["secret-key negative control: a secret-looking environment variable never reaches the fingerprint, while an allow-listed one does", () => withScratchRepo((root) => {
    const env = { ImageOS: "ubuntu24", GITHUB_TOKEN: "ghs_SELFTESTSECRET", AWS_SECRET_ACCESS_KEY: "SELFTESTACCESSKEY" };
    const serialized = JSON.stringify(machineFingerprint({ env, root, toolchain: TOOLCHAIN_FIXTURE }));
    assert.match(serialized, /ubuntu24/);
    for (const forbidden of ["SELFTESTSECRET", "SELFTESTACCESSKEY", "GITHUB_TOKEN", "AWS_SECRET_ACCESS_KEY"]) assert.ok(!serialized.includes(forbidden));
    assert.deepEqual(Object.keys(JSON.parse(serialized)), [...FINGERPRINT_KEYS]);
  })],
  ["dirty-flag scratch-repo control: clean then dirty, derived from git status in a scratch repository", () => withScratchRepo((root) => {
    assert.equal(machineFingerprint({ env: {}, root, toolchain: TOOLCHAIN_FIXTURE }).dirty, false);
    fs.writeFileSync(path.join(root, "stray.txt"), "x\n");
    assert.equal(machineFingerprint({ env: {}, root, toolchain: TOOLCHAIN_FIXTURE }).dirty, true);
  })],
  ["protocol-completeness control: below-protocol focused samples are rejected and the full 5+1 sample is accepted", () => {
    const base = { mode: "focused", n: 5, warmup: 1, values_ms: [1, 2, 3, 4, 5] };
    assert.equal(isProtocolComplete(base), true);
    assert.equal(isProtocolComplete({ ...base, n: 1, values_ms: [1], warmup: 0 }), false);
    assert.equal(isProtocolComplete({ ...base, warmup: 0 }), false);
  }],
  ["summarizeSamples uses nearest-rank p90 and refuses empty input", () => {
    assert.deepEqual(summarizeSamples([5, 1, 3, 2, 4]), { n: 5, median: 3, p90: 5, min: 1, max: 5 });
    assert.throws(() => summarizeSamples([]), /at least one/);
  }],
  ["freeze eligibility: a macOS, dirty or smoke sample is never freeze-eligible", () => {
    const fingerprint = {
      os: "linux", arch: "x64", cpu_model: "cpu", cores: 4, ram_bytes: 1, image_os: "ubuntu24", image_version: "1", runner_os: "Linux",
      otp: "28", elixir: "1.19.5", node: "22", playwright: "1.59.1", workers: 1, revision: "a".repeat(40), manifest_sha256: "b".repeat(64), dirty: false,
    };
    const sample = { mode: "focused", n: 5, warmup: 1, values_ms: [1, 2, 3, 4, 5], smoke: false, fingerprint };
    assert.equal(isFreezeEligible(sample), true);
    assert.equal(isFreezeEligible({ ...sample, fingerprint: { ...fingerprint, image_os: null } }), false);
    assert.equal(isFreezeEligible({ ...sample, fingerprint: { ...fingerprint, dirty: true } }), false);
    assert.equal(isFreezeEligible({ ...sample, smoke: true }), false);
  }],
  ["lane registry control: a known lane resolves and an unknown lane fails", () => {
    assert.equal(resolveLane("phase252-render").kind, "playwright");
    assert.throws(() => resolveLane("nope"), /unknown lane/);
  }],
];

export function verifyFixtures() {
  for (const [name, scenario] of SCENARIOS) {
    scenario();
    process.stdout.write(`  ok - ${name}\n`);
  }
  return SCENARIOS.length;
}

// -- CLI --------------------------------------------------------------------------

const VALUE_OPTIONS = new Set(["out", "lane", "runs", "warmup", "report", "run", "repo", "artifacts"]);
const BOOLEAN_OPTIONS = new Set(["self-test"]);

function parseArgs(argv) {
  const positional = [];
  const flags = new Set();
  const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) { positional.push(token); continue; }
    const key = token.slice(2);
    if (BOOLEAN_OPTIONS.has(key)) { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option --${key}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${key} requires a value`);
    values[key] = argv[++index];
  }
  return { positional, flags, values };
}

function countOption(values, key, fallback) {
  if (values[key] === undefined) return fallback;
  const number = Number(values[key]);
  if (!Number.isInteger(number) || number < 0) fail(`--${key} must be a non-negative integer`);
  return number;
}

function outputPath(values, mode, lane) {
  if (values.out) return path.resolve(values.out);
  return path.join(ROOT, MEASUREMENTS_DIR, `${mode}-${lane}-${new Date().toISOString().replace(/[:.]/g, "-")}.json`);
}

const verbs = {
  async fingerprint({ values }) {
    const out = values.out ? path.resolve(values.out) : null;
    const fingerprint = machineFingerprint();
    if (out) { writeJson(out, fingerprint); process.stdout.write(`Phase 254 fingerprint written to ${path.relative(ROOT, out)}\n`); }
    else process.stdout.write(`${JSON.stringify(fingerprint, null, 2)}\n`);
  },
  async focused({ values }) {
    const lane = values.lane;
    if (!lane) fail("focused requires --lane");
    resolveLane(lane);
    const runs = countOption(values, "runs", PROTOCOLS.focused.runs);
    const warmup = countOption(values, "warmup", PROTOCOLS.focused.warmup);
    const fingerprint = machineFingerprint();
    const sample = values.report
      ? focusedSampleFromReport({ reportText: fs.readFileSync(path.resolve(values.report), "utf8"), lane, fingerprint, runs: 1, warmup: 0 })
      : await runFocused({ lane, runs, warmup, fingerprint });
    const out = outputPath(values, "focused", lane);
    writeJson(out, sample);
    process.stdout.write(`Phase 254 focused ${lane}: median ${sample.median_ms} ms, p90 ${sample.p90_ms} ms, n=${sample.n}, smoke=${sample.smoke}, informs_only=${sample.informs_only} -> ${path.relative(ROOT, out)}\n`);
  },
};

async function main(argv) {
  const { positional, flags, values } = parseArgs(argv);
  if (flags.has("self-test")) {
    const count = verifyFixtures();
    process.stdout.write(`phase254 measure: PASS (self-test: ${count} scenarios)\n`);
    return;
  }
  const [verb] = positional;
  if (!verb || !Object.prototype.hasOwnProperty.call(verbs, verb)) {
    fail(`usage: phase254_measure.mjs <${Object.keys(verbs).join("|")}> [options] | --self-test`);
  }
  await verbs[verb]({ values });
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  main(process.argv.slice(2)).catch((error) => {
    console.error(error.message.startsWith("Phase 254 measure:") ? error.message : `Phase 254 measure: FAIL: ${error.message}`);
    process.exitCode = 1;
  });
}
