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
import { createRequire } from "node:module";
import net from "node:net";
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

// -- lab server (warm and cold protocols) --------------------------------------------

const sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address();
      server.close(() => resolve(port));
    });
  });
}

// The health payload does not carry the lane today (it drops :lane); a payload
// that does report a lane must report admin-review, and a payload without one is
// accepted only for the lane this harness itself launched. Port, partition and
// database must always match the launch.
export function assertWarmHealthIdentity(health, launch) {
  if (!health || health.ok !== true || health.ready !== true) fail("health identity is not ready");
  const lane = health.lane ?? launch.lane;
  if (lane !== "admin-review") fail(`warm mode requires the admin-review lane, but the health identity reports ${JSON.stringify(lane)}`);
  if (Number(health.port) !== launch.port) fail("health identity port does not match the launched lab server");
  if (String(health.partition) !== launch.partition) fail("health identity partition does not match the launched lab server");
  if (health.database !== launch.database) fail("health identity database does not match the launched lab server");
  return { lane };
}

// Starts `phase252_lab.mjs serve --lane admin-review`, waits for its health
// identity and returns the time from spawn to a ready identity.
export async function bootLab({ mixBuildPath = null, timeoutMs = 300_000 } = {}) {
  const partition = String(crypto.randomInt(1_000_000_000, 9_999_999_999));
  const port = await freePort();
  const launch = { lane: "admin-review", port, partition, database: `accrue_admin_test${partition}` };
  const output = [];
  const start = Date.now();
  const child = spawn(process.execPath, [LAB, "serve", "--lane", launch.lane, "--partition", partition, "--port", String(port)], {
    cwd: ROOT,
    env: childEnv({ MIX_ENV: "test", ...(mixBuildPath ? { MIX_BUILD_PATH: mixBuildPath } : {}) }),
    shell: false,
    stdio: ["ignore", "pipe", "pipe"],
  });
  for (const stream of [child.stdout, child.stderr]) stream.on("data", (chunk) => { output.push(String(chunk)); if (output.length > 200) output.shift(); });
  let exitInfo = null;
  const exited = new Promise((resolve) => child.once("exit", (code, signal) => { exitInfo = { code, signal }; resolve(exitInfo); }));
  child.once("error", (error) => { exitInfo = { code: 127, signal: null, error }; });

  const stop = async () => {
    if (exitInfo) return;
    child.kill("SIGTERM");
    const timer = sleep(90_000).then(() => "timeout");
    if ((await Promise.race([exited, timer])) === "timeout") {
      child.kill("SIGKILL");
      process.stderr.write(`Phase 254 measure: lab server on port ${port} did not stop within 90 s and was killed; check for an orphaned database ${launch.database}\n`);
      await exited;
    }
  };

  let health = null;
  try {
    while (health === null) {
      if (exitInfo) fail(`lab serve exited before becoming healthy (code ${exitInfo.code}):\n${tail(output.join(""))}`);
      if (Date.now() - start > timeoutMs) fail(`lab serve was not healthy within ${timeoutMs} ms:\n${tail(output.join(""))}`);
      try {
        const response = await fetch(`http://127.0.0.1:${port}/__e2e__/health`);
        if (response.status === 200) {
          const body = await response.json();
          if (body.ready === true) health = body;
        }
      } catch {
        // not listening yet
      }
      if (health === null) await sleep(100);
    }
    assertWarmHealthIdentity(health, launch);
  } catch (error) {
    await stop();
    throw error;
  }
  return { ms: Date.now() - start, health, launch, baseURL: `http://127.0.0.1:${port}`, stop };
}

// -- cold protocol ------------------------------------------------------------------

export async function runCold({ runs = PROTOCOLS.cold.runs, warmup = PROTOCOLS.cold.warmup, fingerprint }) {
  const uid = typeof process.getuid === "function" ? process.getuid() : "local";
  const totals = [];
  const compile = [];
  const database = [];
  const boot = [];
  for (let index = 0; index < warmup + runs; index += 1) {
    const base = path.join(fs.realpathSync(os.tmpdir()), `accrue-phase254-${uid}`, crypto.randomBytes(8).toString("hex"));
    const mixBuildPath = path.join(base, "mix-build", "accrue-admin");
    try {
      const compiled = await spawnTimed({ executable: "mix", args: ["compile"], cwd: ADMIN_ROOT, env: { MIX_ENV: "test", MIX_BUILD_PATH: mixBuildPath } });
      if (compiled.exitCode !== 0) fail(`cold compile exited ${compiled.exitCode}:\n${tail(compiled.stderr || compiled.stdout)}`);
      const created = await spawnTimed({ executable: process.execPath, args: [LAB, "exec", "--lane", "admin-review", "--", process.execPath, "-e", ""], cwd: ROOT, env: {} });
      if (created.exitCode !== 0) fail(`cold database create/drop probe exited ${created.exitCode}:\n${tail(created.stderr || created.stdout)}`);
      const lab = await bootLab({ mixBuildPath });
      await lab.stop();
      if (index >= warmup) {
        totals.push(compiled.duration_ms + lab.ms);
        compile.push(compiled.duration_ms);
        database.push(created.duration_ms);
        // boot-to-health includes the lab's own database create and the server's
        // migrate/seed; the isolated create/drop probe is attributed separately.
        boot.push(Math.max(0, lab.ms - created.duration_ms));
      }
    } finally {
      fs.rmSync(base, { recursive: true, force: true });
    }
  }
  return buildLocalSample({
    mode: "cold",
    lane: "cold-start",
    runs,
    warmup,
    values_ms: totals,
    phases: { compile_ms: round3(median(compile)), database_ms: round3(median(database)), boot_ms: round3(median(boot)) },
    fingerprint,
  });
}

// -- warm-preview protocol ------------------------------------------------------------

export const WARM_STORIES = Object.freeze([
  Object.freeze({ id: "collection", path: "/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=one_row" }),
  Object.freeze({ id: "page", path: "/billing/dev/storybook/pages/subscription?tab=active" }),
  Object.freeze({ id: "detail", path: "/billing/dev/storybook/components/subscription_detail?variation_id=active" }),
]);
const READY_MARKER = ".psb-sandbox h1";

export async function runWarm({ runs = PROTOCOLS.warm.runs, warmup = PROTOCOLS.warm.warmup, fingerprint }) {
  const { chromium } = createRequire(path.join(ADMIN_ROOT, "package.json"))("playwright");
  const lab = await bootLab();
  let browser = null;
  try {
    browser = await chromium.launch();
    const context = await browser.newContext({ baseURL: lab.baseURL, viewport: { width: 1280, height: 900 }, colorScheme: "light", reducedMotion: "reduce" });
    const page = await context.newPage();
    const ready = () => page.locator(READY_MARKER).first().waitFor({ state: "visible", timeout: 30_000 });
    await page.goto(`/__e2e__/login?to=${encodeURIComponent(WARM_STORIES[0].path)}`);
    await ready();
    const perStory = Object.fromEntries(WARM_STORIES.map((story) => [story.id, []]));
    for (let iteration = 0; iteration < warmup + runs; iteration += 1) {
      for (const story of WARM_STORIES) {
        const startedAt = performance.now();
        await page.goto(story.path, { waitUntil: "load" });
        await ready();
        const elapsed = performance.now() - startedAt;
        if (iteration >= warmup) perStory[story.id].push(round3(elapsed));
      }
    }
    // One recorded value per iteration: the slowest of the representative
    // stories, so the median/p90 are conservative against the warm-preview target.
    const values_ms = Array.from({ length: runs }, (_unused, index) => Math.max(...WARM_STORIES.map((story) => perStory[story.id][index])));
    return buildLocalSample({
      mode: "warm",
      lane: "warm-preview",
      runs,
      warmup,
      values_ms,
      cells: WARM_STORIES.length,
      cell_samples: WARM_STORIES.flatMap((story) => perStory[story.id]),
      durations: WARM_STORIES.map((story) => ({ identity: story.id, duration_ms: round3(median(perStory[story.id])) })),
      fingerprint,
    });
  } finally {
    if (browser) await browser.close();
    await lab.stop();
  }
}

// -- D-24 attribution -------------------------------------------------------------------

const COMPILE_FIRST_IDS = new Set(["manifest-current", "phase253-manifest-contract"]);
const DATABASE_LANES = new Set(["admin-test", "host-heldout", "self-owned-disposable-review-and-admin-test"]);

export function classifyLane(command) {
  if (command.lane === "isolated-build" || COMPILE_FIRST_IDS.has(command.id)) return "compile";
  if (DATABASE_LANES.has(command.lane)) return "database";
  if (command.lane === "admin-review-browser") return "browser";
  return "other";
}

// Groups every lane duration_ms from the Phase 252/253 results bundles into the
// D-24 buckets: compile, database, boot-to-health and per-cell. A browser lane's
// duration is split into the measured boot-to-health estimate and the remaining
// per-cell time.
export function attributeLaneCost(bundles, { boot_ms = 0 } = {}) {
  if (!Array.isArray(bundles) || bundles.length === 0) fail("attributeLaneCost needs at least one results bundle");
  const buckets = { compile_ms: 0, database_ms: 0, boot_ms: 0, cell_ms: 0, other_ms: 0 };
  const lanes = [];
  let cells = 0;
  for (const bundle of bundles) {
    if (!Array.isArray(bundle.commands) || bundle.commands.length === 0) fail("results bundle has no commands");
    for (const command of bundle.commands) {
      if (typeof command.id !== "string" || !Number.isFinite(command.duration_ms)) fail(`results bundle command ${JSON.stringify(command.id)} has no numeric duration_ms`);
      const bucket = classifyLane(command);
      const tests = command.execution_evidence?.test_count ?? null;
      if (bucket === "browser") {
        const boot = Math.min(boot_ms, command.duration_ms);
        buckets.boot_ms += boot;
        buckets.cell_ms += command.duration_ms - boot;
        cells += tests ?? 0;
      } else if (bucket === "compile") buckets.compile_ms += command.duration_ms;
      else if (bucket === "database") buckets.database_ms += command.duration_ms;
      else buckets.other_ms += command.duration_ms;
      lanes.push({ plan: bundle.plan ?? null, id: command.id, lane: command.lane ?? null, bucket, duration_ms: command.duration_ms, tests });
    }
  }
  lanes.sort((left, right) => right.duration_ms - left.duration_ms);
  return {
    total_ms: Object.values(buckets).reduce((sum, value) => sum + value, 0),
    buckets,
    cells,
    per_cell_ms: cells > 0 ? round3(buckets.cell_ms / cells) : null,
    lanes,
  };
}

export function latestResultsBundle(root, phase) {
  const directory = path.join(root, "accrue_admin", "tmp", phase, "ci-results");
  if (!fs.existsSync(directory)) fail(`no ${phase} results directory at accrue_admin/tmp/${phase}/ci-results`);
  const candidates = [];
  for (const entry of fs.readdirSync(directory)) {
    const file = path.join(directory, entry, "results.json");
    if (!fs.existsSync(file)) continue;
    const bundle = JSON.parse(fs.readFileSync(file, "utf8"));
    if (bundle.status === "passed" && typeof bundle.run_completed_at === "string") candidates.push(bundle);
  }
  if (candidates.length === 0) fail(`no passed ${phase} results bundle found`);
  candidates.sort((left, right) => Date.parse(right.run_completed_at) - Date.parse(left.run_completed_at));
  return candidates[0];
}

export function renderedCaseCount(root, bundle) {
  const file = path.join(root, bundle.browser_result_path);
  if (!fs.existsSync(file)) fail(`browser result ${bundle.browser_result_path} is missing`);
  const rendered = JSON.parse(fs.readFileSync(file, "utf8"));
  if (!Array.isArray(rendered.cases) || rendered.cases.length === 0) fail(`browser result ${bundle.browser_result_path} has no rendered cases`);
  return rendered.cases.length;
}

const WIDENING_RULE = "Budget values, allowances and the selection set are re-frozen only by an appended deviation record (D-23). CI never rewrites this file, a frozen value never widens silently, and local (informs_only) samples never populate a frozen value.";

export function buildProvisionalBudget({ samples, root = ROOT }) {
  if (!Array.isArray(samples) || samples.length === 0) fail("provisional budget needs at least one sample");
  for (const mode of Object.keys(PROTOCOLS)) {
    if (!samples.some((sample) => sample.mode === mode)) fail(`provisional budget needs a ${mode} sample`);
  }
  for (const sample of samples) {
    if (sample.smoke !== false) fail(`${sample.mode} ${sample.lane} sample is smoke and cannot enter the budget record`);
    if (sample.informs_only !== true) fail(`${sample.mode} ${sample.lane} sample is not informs_only; local samples must be informs_only`);
  }
  const phase252 = latestResultsBundle(root, "phase252");
  const phase253 = latestResultsBundle(root, "phase253");
  const cases252 = renderedCaseCount(root, phase252);
  const cases253 = renderedCaseCount(root, phase253);
  const total = cases252 + cases253;
  const coldPhases = samples.find((sample) => sample.mode === "cold")?.phases;
  const attribution = attributeLaneCost([phase252, phase253], { boot_ms: coldPhases?.boot_ms ?? 0 });
  const reference = samples[0].fingerprint;
  const owners = 2;
  return {
    schema_version: SCHEMA_VERSION,
    source_revision: git(root, ["rev-parse", "HEAD"]).trim(),
    manifest_sha256: sha256(fs.readFileSync(path.join(root, MANIFEST_PATH))),
    selection: {
      total,
      selected: total,
      basis: {
        phase252: { run_id: phase252.run_id, rendered_cases: cases252, source_revision: phase252.source_revision },
        phase253: { run_id: phase253.run_id, rendered_cases: cases253, source_revision: phase253.source_revision },
      },
    },
    metrics: { local: samples, ci: [], ci_reference: null, freeze: null, visual: null, a11y: null, final: null },
    provisional_targets: { warm_preview_s: 10, focused_check_s: 60, additional_warm_browser_s: 180, incremental_ci_critical_path_s: 300 },
    target_evaluations: [],
    frozen: null,
    allowances: null,
    warn_at: null,
    ceiling: null,
    known_reds: [],
    deviations: [{
      id: "DEV-254-01",
      kind: "d24-local-attribution",
      target: { name: "incremental_ci_critical_path_s", seconds: 300, source: "D-24 provisional CIQ-04 target" },
      measurement: {
        local_total_ms: attribution.total_ms,
        local_total_s: round3(attribution.total_ms / 1000),
        machine: { os: reference.os, cpu_model: reference.cpu_model, cores: reference.cores, informs_only: true },
        results_revisions: { phase252: phase252.source_revision, phase253: phase253.source_revision },
        cold_phases: coldPhases ?? null,
        attribution,
      },
      decision: "attributed; resolution pending CI observation (254-03) and freeze (254-09)",
      status: "open",
      before: { cells: total, owners },
      after: { cells: total, owners },
    }],
    widening_rule: WIDENING_RULE,
  };
}

// -- CI collection (ci-collect) ------------------------------------------------------------

// The two owner jobs that upload a Phase 254 fingerprint. A job outside this map
// has no fingerprint, so it never yields a sample (it is not an owner, D-21).
export const CI_OWNER_JOBS = Object.freeze({
  "Admin Phase 200 deterministic guardrails": Object.freeze({
    artifact: "phase254-machine-evidence-guardrails",
    fingerprint: "fingerprint-guardrails.json",
    lane_artifacts: Object.freeze(["phase252-machine-evidence", "phase253-machine-evidence"]),
  }),
  "Browser UAT": Object.freeze({
    artifact: "phase254-machine-evidence-browser-uat",
    fingerprint: "fingerprint-browser-uat.json",
    lane_artifacts: Object.freeze([]),
  }),
});

const LOG_LINE = /^([^\t]*)\t([^\t]*)\t(.*)$/;
const TIMESTAMP_PREFIX = /^﻿?\d{4}-\d{2}-\d{2}T[\d:.]+Z\s?/;

// Reads the cache outcome of every cache-restoring step from one job log
// (`gh run view --log`: job, step, timestamped line). A cache-configured step
// without a recognised outcome line is rejected as unparsed, never counted as a
// miss (a miss that was really a parse failure would flatter the cache story).
export function parseCacheOutcomes(log) {
  const byStep = new Map();
  for (const raw of String(log).split(/\r?\n/)) {
    const match = raw.match(LOG_LINE);
    if (!match) continue;
    const step = match[2];
    if (!byStep.has(step)) byStep.set(step, []);
    byStep.get(step).push(match[3].replace(TIMESTAMP_PREFIX, ""));
  }
  const steps = [];
  for (const [name, lines] of byStep) {
    if (/^Post /.test(name)) continue;
    const header = lines.find((line) => /^Run actions\/(?:cache(?:\/restore)?|setup-node)@/.test(line.trim()));
    if (!header) continue;
    const restoring = /actions\/cache/.test(header) || lines.some((line) => /^\s*cache:\s*\S+/.test(line));
    if (!restoring) continue;
    const primary = lines.map((line) => line.match(/^\s*key:\s*(\S.*?)\s*$/)).find(Boolean)?.[1] ?? null;
    const restored = lines.map((line) => line.match(/Cache restored from key:\s*(\S.*?)\s*$/)).find(Boolean)?.[1];
    const notFound = lines.map((line) => line.match(/Cache not found for input keys:\s*(\S.*?)\s*$/)).find(Boolean)?.[1];
    if (restored) {
      steps.push({ name, outcome: primary !== null && primary !== restored ? "partial" : "hit", key: restored });
    } else if (notFound || lines.some((line) => /npm cache is not found/i.test(line))) {
      steps.push({ name, outcome: "miss", key: primary ?? notFound?.split(",")[0].trim() ?? null });
    } else {
      fail(`cache step ${JSON.stringify(name)} has no recognised cache outcome line (unparsed)`);
    }
  }
  return {
    steps,
    hits: steps.filter((step) => step.outcome === "hit").length,
    partial: steps.filter((step) => step.outcome === "partial").length,
    misses: steps.filter((step) => step.outcome === "miss").length,
  };
}

function readCiFingerprint(artifactDir, evidence) {
  const candidates = [path.join(artifactDir, evidence.artifact, evidence.fingerprint), path.join(artifactDir, evidence.fingerprint)];
  const file = candidates.find((candidate) => fs.existsSync(candidate));
  if (!file) fail(`missing fingerprint file ${evidence.artifact}/${evidence.fingerprint} in the downloaded artifacts`);
  const fingerprint = JSON.parse(fs.readFileSync(file, "utf8"));
  for (const key of FINGERPRINT_KEYS) {
    if (!(key in fingerprint)) fail(`fingerprint ${evidence.fingerprint} lacks ${key}`);
  }
  if (typeof fingerprint.image_os !== "string" || fingerprint.image_os === "") fail(`fingerprint ${evidence.fingerprint} lacks image_os`);
  return fingerprint;
}

function findResultFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  const found = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) found.push(...findResultFiles(full));
    else if (entry.name === "results.json") found.push(full);
  }
  return found.sort();
}

function readLaneDurations(artifactDir, laneArtifacts) {
  const lanes = [];
  for (const artifact of laneArtifacts) {
    for (const file of findResultFiles(path.join(artifactDir, artifact))) {
      const bundle = JSON.parse(fs.readFileSync(file, "utf8"));
      if (!Array.isArray(bundle.commands)) continue;
      for (const command of bundle.commands) {
        if (typeof command.id === "string" && Number.isFinite(command.duration_ms)) {
          lanes.push({ lane: `${bundle.plan ?? artifact}:${command.id}`, duration_ms: command.duration_ms });
        }
      }
    }
  }
  return lanes;
}

const seconds = (start, end) => (start && end && Number.isFinite(Date.parse(start)) && Number.isFinite(Date.parse(end))
  ? round3((Date.parse(end) - Date.parse(start)) / 1000)
  : null);

// Turns one attempt-1 run (`gh run view <id> --json jobs,headSha,event,attempt,
// workflowName,databaseId`) plus its downloaded artifacts and job logs into one
// CI sample per owner job. Queue time is excluded: duration_s runs from the job's
// own startedAt. jobLogs is keyed by job databaseId (string) or job name.
export function collectCiSample(runJson, artifactDir, jobLogs = {}) {
  if (!runJson || !Array.isArray(runJson.jobs)) fail("run JSON has no jobs");
  if (Number(runJson.attempt) !== 1) fail(`run ${runJson.databaseId} is attempt ${runJson.attempt}; only first-attempt runs are measured (no reruns)`);
  if (typeof runJson.headSha !== "string" || !/^[0-9a-f]{40}$/.test(runJson.headSha)) fail("run JSON has no valid headSha");
  const samples = [];
  for (const job of runJson.jobs) {
    const evidence = CI_OWNER_JOBS[job.name];
    if (!evidence) continue;
    const fingerprint = readCiFingerprint(artifactDir, evidence);
    const log = jobLogs[String(job.databaseId)] ?? jobLogs[job.name];
    if (typeof log !== "string") fail(`no job log was supplied for ${JSON.stringify(job.name)}`);
    samples.push({
      schema_version: SCHEMA_VERSION,
      workflow: runJson.workflowName,
      run_id: runJson.databaseId,
      head_sha: runJson.headSha,
      event: runJson.event,
      attempt: 1,
      job: job.name,
      conclusion: job.conclusion,
      started_at: job.startedAt ?? null,
      completed_at: job.completedAt ?? null,
      duration_s: seconds(job.startedAt, job.completedAt),
      steps: (job.steps ?? []).map((step) => ({ name: step.name, conclusion: step.conclusion, duration_s: seconds(step.startedAt, step.completedAt) })),
      lanes: readLaneDurations(artifactDir, evidence.lane_artifacts),
      cache: parseCacheOutcomes(log),
      fingerprint,
      informs_only: true,
    });
  }
  if (samples.length === 0) fail(`run ${runJson.databaseId} has none of the owner jobs (${Object.keys(CI_OWNER_JOBS).join(", ")})`);
  return samples;
}

function gh(args) {
  const result = spawnSync("gh", args, { encoding: "utf8", shell: false, maxBuffer: 128 * 1024 * 1024, timeout: 300_000 });
  if (result.error || result.status !== 0) fail(`gh ${args.slice(0, 3).join(" ")} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 300)}`);
  return result.stdout;
}

export function ciCollect({ run, repo, artifacts }) {
  if (!/^\d+$/.test(String(run))) fail("--run must be a numeric workflow run id");
  if (!/^[\w.-]+\/[\w.-]+$/.test(repo)) fail("--repo must be owner/name");
  const runJson = JSON.parse(gh(["run", "view", String(run), "--repo", repo, "--json", "jobs,headSha,event,attempt,workflowName,databaseId"]));
  if (Number(runJson.attempt) !== 1) fail(`run ${run} is attempt ${runJson.attempt}; only first-attempt runs are measured`);
  fs.mkdirSync(artifacts, { recursive: true });
  gh(["run", "download", String(run), "--repo", repo, "--dir", artifacts, "--pattern", "phase254-machine-evidence-*", "--pattern", "phase252-machine-evidence", "--pattern", "phase253-machine-evidence"]);
  const jobLogs = {};
  for (const job of runJson.jobs) {
    if (CI_OWNER_JOBS[job.name]) jobLogs[String(job.databaseId)] = gh(["run", "view", String(run), "--repo", repo, "--job", String(job.databaseId), "--log"]);
  }
  return collectCiSample(runJson, artifacts, jobLogs);
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
  async cold({ values }) {
    const sample = await runCold({ runs: countOption(values, "runs", PROTOCOLS.cold.runs), warmup: countOption(values, "warmup", PROTOCOLS.cold.warmup), fingerprint: machineFingerprint() });
    const out = outputPath(values, "cold", sample.lane);
    writeJson(out, sample);
    process.stdout.write(`Phase 254 cold: median ${sample.median_ms} ms (compile ${sample.phases.compile_ms}, database ${sample.phases.database_ms}, boot ${sample.phases.boot_ms}), n=${sample.n}, smoke=${sample.smoke} -> ${path.relative(ROOT, out)}\n`);
  },
  async warm({ values }) {
    const sample = await runWarm({ runs: countOption(values, "runs", PROTOCOLS.warm.runs), warmup: countOption(values, "warmup", PROTOCOLS.warm.warmup), fingerprint: machineFingerprint() });
    const out = outputPath(values, "warm", sample.lane);
    writeJson(out, sample);
    process.stdout.write(`Phase 254 warm: per-iteration slowest-story median ${sample.median_ms} ms, p90 ${sample.p90_ms} ms, per navigation median ${sample.per_cell.median_ms} ms / p90 ${sample.per_cell.p90_ms} ms, n=${sample.n}, smoke=${sample.smoke} -> ${path.relative(ROOT, out)}\n`);
  },
  async "ci-collect"({ values }) {
    if (!values.run) fail("ci-collect requires --run <run_id>");
    const artifacts = path.resolve(values.artifacts ?? path.join(ROOT, "accrue_admin/tmp/phase254/ci-artifacts", String(values.run)));
    const samples = ciCollect({ run: values.run, repo: values.repo ?? "szTheory/accrue", artifacts });
    const out = values.out ? path.resolve(values.out) : path.join(ROOT, MEASUREMENTS_DIR, `ci-${values.run}.json`);
    writeJson(out, samples);
    process.stdout.write(`Phase 254 ci-collect: run ${values.run} -> ${samples.length} sample(s) (${samples.map((sample) => `${sample.job}: ${sample.duration_s} s, cache hits ${sample.cache.hits}/misses ${sample.cache.misses}`).join("; ")}) -> ${path.relative(ROOT, out)}\n`);
  },
  async "provisional-budget"({ positional, values }) {
    const files = positional.slice(1);
    if (files.length === 0) fail("provisional-budget needs sample files");
    if (!values.out) fail("provisional-budget requires --out");
    const budget = buildProvisionalBudget({ samples: files.map((file) => JSON.parse(fs.readFileSync(path.resolve(file), "utf8"))) });
    writeJson(path.resolve(values.out), budget);
    process.stdout.write(`Phase 254 provisional budget written to ${path.relative(ROOT, path.resolve(values.out))} (${budget.metrics.local.length} local samples, ${budget.selection.total} cells)\n`);
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
  await verbs[verb]({ positional, values });
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
