#!/usr/bin/env node
//
// CI efficiency shape contract (quick task 261025-vdn).
//
// The efficiency PR changed how CI spends time without changing what CI
// proves. This contract pins the SHAPE of every one of those changes so a
// later edit cannot quietly turn an efficiency setting into a weakened gate:
//
//   - concurrency (item 2): cancel-in-progress is true only for
//     pull_request, and every non-PR run (push to main, schedule, dispatch)
//     gets a run_id-unique group. The run_id half is load-bearing: with a
//     shared group a NEWER pending run replaces an older PENDING run even
//     when cancel-in-progress is false, so a shared main group could drop a
//     main push or a scheduled live-stripe proof without any cancellation.
//   - MIX_OS_DEPS_COMPILE_PARTITION_COUNT (item 3): set to 4 workflow-wide
//     (ubuntu-24.04 runners have 4 vCPU) and never overridden.
//   - timeout-minutes (item 6): every job carries one, within [10, 60].
//
// Scope: .github/workflows/ci.yml and .github/workflows/accrue_admin_browser.yml.
// The YAML is parsed line-based by indentation (no YAML dependency); the
// parser only needs the fixed two-space GitHub Actions layout this repository
// uses, and a file it cannot read as that layout FAILS rather than passing.
//
// Modes (D-32): `node --test` registers every fixture scenario; `--fixtures`
// runs them; `--repo <path>` checks the live workflow files.

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

const fail = (message) => { throw new Error(`ci efficiency contract: FAIL: ${message}`); };

export const SCOPED_WORKFLOWS = [".github/workflows/ci.yml", ".github/workflows/accrue_admin_browser.yml"];

export const CONCURRENCY_GROUP = "${{ github.workflow }}-${{ github.event_name == 'pull_request' && github.ref || github.run_id }}";
export const CANCEL_IN_PROGRESS = "${{ github.event_name == 'pull_request' }}";
export const PARTITION_COUNT_KEY = "MIX_OS_DEPS_COMPILE_PARTITION_COUNT";
export const TIMEOUT_MIN = 10;
export const TIMEOUT_MAX = 60;

// -- line-based workflow parsing ----------------------------------------------

const indentOf = (line) => line.length - line.trimStart().length;
const isBlank = (line) => line.trim() === "" || line.trim().startsWith("#");

function stripValue(raw) {
  let value = raw.trim();
  if ((value.startsWith("'") && value.endsWith("'")) || (value.startsWith('"') && value.endsWith('"'))) value = value.slice(1, -1);
  return value;
}

// Returns the `key: value` children directly under the mapping that starts at
// `start` (exclusive) with child indent `childIndent`, stopping at the first
// non-blank line indented less than childIndent.
function childMap(lines, start, childIndent) {
  const map = new Map();
  for (let index = start + 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (isBlank(line)) continue;
    const indent = indentOf(line);
    if (indent < childIndent) break;
    if (indent !== childIndent) continue;
    const match = /^\s*([A-Za-z0-9_-]+):\s?(.*)$/.exec(line);
    if (match) map.set(match[1], { value: stripValue(match[2]), line: index });
  }
  return map;
}

export function parseWorkflow(source) {
  const lines = source.split("\n");
  const topLevel = new Map();
  for (let index = 0; index < lines.length; index += 1) {
    const match = /^([A-Za-z0-9_-]+):\s?(.*)$/.exec(lines[index]);
    if (match) topLevel.set(match[1], { value: stripValue(match[2]), line: index });
  }
  const jobsEntry = topLevel.get("jobs");
  if (!jobsEntry) fail("workflow has no top-level jobs: block");
  const jobs = [];
  for (let index = jobsEntry.line + 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (isBlank(line)) continue;
    if (indentOf(line) === 0) break;
    const match = /^  ([A-Za-z0-9_-]+):\s*$/.exec(line);
    if (match) jobs.push({ id: match[1], line: index, props: childMap(lines, index, 4) });
  }
  if (jobs.length === 0) fail("workflow declares zero jobs -- refusing to report a pass over nothing");
  return { lines, topLevel, jobs };
}

// -- checks --------------------------------------------------------------------

export function checkConcurrency(file, workflow) {
  const entry = workflow.topLevel.get("concurrency");
  if (!entry) fail(`${file}: no workflow-level concurrency: block`);
  const children = childMap(workflow.lines, entry.line, 2);
  const group = children.get("group")?.value;
  const cancel = children.get("cancel-in-progress")?.value;
  if (group !== CONCURRENCY_GROUP) {
    fail(`${file}: concurrency.group must be run_id-unique for every non-PR event: expected \`${CONCURRENCY_GROUP}\`, found \`${group ?? "<missing>"}\``);
  }
  if (cancel !== CANCEL_IN_PROGRESS) {
    fail(`${file}: concurrency.cancel-in-progress must be gated to pull_request: expected \`${CANCEL_IN_PROGRESS}\`, found \`${cancel ?? "<missing>"}\``);
  }
}

export function checkPartitionCount(file, workflow) {
  const env = workflow.topLevel.get("env");
  const value = env ? childMap(workflow.lines, env.line, 2).get(PARTITION_COUNT_KEY)?.value : undefined;
  if (value !== "4") fail(`${file}: workflow-level env must set ${PARTITION_COUNT_KEY}: 4 (found ${value ?? "<missing>"})`);
  workflow.lines.forEach((line, index) => {
    const match = new RegExp(`^\\s+${PARTITION_COUNT_KEY}:\\s*(.*)$`).exec(line);
    if (match && index !== env.line && stripValue(match[1]) !== "4") {
      fail(`${file}:${index + 1}: ${PARTITION_COUNT_KEY} is overridden to ${stripValue(match[1])}`);
    }
  });
}

export function checkTimeouts(file, workflow) {
  for (const job of workflow.jobs) {
    const raw = job.props.get("timeout-minutes")?.value;
    if (raw === undefined) fail(`${file}: job \`${job.id}\` has no timeout-minutes`);
    if (!/^\d+$/.test(raw)) fail(`${file}: job \`${job.id}\` timeout-minutes is not an integer: ${raw}`);
    const minutes = Number(raw);
    if (minutes < TIMEOUT_MIN || minutes > TIMEOUT_MAX) {
      fail(`${file}: job \`${job.id}\` timeout-minutes ${minutes} is outside [${TIMEOUT_MIN}, ${TIMEOUT_MAX}]`);
    }
  }
}

export const SCOPED_CHECKS = [checkConcurrency, checkPartitionCount, checkTimeouts];

export function verifyWorkflowSource(file, source) {
  const workflow = parseWorkflow(source);
  for (const check of SCOPED_CHECKS) check(file, workflow);
  return { jobs: workflow.jobs.length };
}

export function verifyRepo(repo) {
  const results = [];
  for (const file of SCOPED_WORKFLOWS) {
    const absolute = path.join(repo, file);
    if (!fs.existsSync(absolute)) fail(`${file} is missing`);
    results.push({ file, ...verifyWorkflowSource(file, fs.readFileSync(absolute, "utf8")) });
  }
  return results;
}

// -- fixtures ------------------------------------------------------------------

const PASSING = `name: Fixture

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${CONCURRENCY_GROUP}
  cancel-in-progress: ${CANCEL_IN_PROGRESS}

env:
  ${PARTITION_COUNT_KEY}: 4

jobs:
  fast:
    name: Fast
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v6
  slow:
    name: Slow
    runs-on: ubuntu-24.04
    timeout-minutes: 45
    env:
      MIX_ENV: test
    steps:
      - name: Compile
        run: mix compile --warnings-as-errors
`;

function mutate(from, to) {
  if (!PASSING.includes(from)) throw new Error(`fixture mutation anchor not found: ${from}`);
  return PASSING.replace(from, to);
}

const SCENARIOS = [
  ["the passing fixture passes every scoped check", () => {
    assert.deepEqual(verifyWorkflowSource("fixture.yml", PASSING), { jobs: 2 });
  }],
  ["a job without timeout-minutes fails", () => {
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate("    timeout-minutes: 45\n", "")), /job `slow` has no timeout-minutes/);
  }],
  ["a timeout outside [10, 60] fails", () => {
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate("timeout-minutes: 45", "timeout-minutes: 360")), /outside \[10, 60\]/);
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate("timeout-minutes: 10", "timeout-minutes: 5")), /outside \[10, 60\]/);
  }],
  ["cancel-in-progress not gated to pull_request fails", () => {
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate(`cancel-in-progress: ${CANCEL_IN_PROGRESS}`, "cancel-in-progress: true")), /gated to pull_request/);
  }],
  ["a missing cancel-in-progress fails", () => {
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate(`  cancel-in-progress: ${CANCEL_IN_PROGRESS}\n`, "")), /cancel-in-progress.*<missing>/);
  }],
  ["a concurrency group shared across non-PR runs (no run_id) fails", () => {
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate(`group: ${CONCURRENCY_GROUP}`, "group: ${{ github.workflow }}-${{ github.ref }}")), /run_id-unique/);
  }],
  ["a missing concurrency block fails", () => {
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate(`concurrency:\n  group: ${CONCURRENCY_GROUP}\n  cancel-in-progress: ${CANCEL_IN_PROGRESS}\n`, "")), /no workflow-level concurrency/);
  }],
  ["a workflow missing MIX_OS_DEPS_COMPILE_PARTITION_COUNT: 4 fails", () => {
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate(`  ${PARTITION_COUNT_KEY}: 4\n`, "  OTHER: 1\n")), /must set MIX_OS_DEPS_COMPILE_PARTITION_COUNT: 4/);
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate(`${PARTITION_COUNT_KEY}: 4`, `${PARTITION_COUNT_KEY}: 2`)), /found 2/);
  }],
  ["a job-level override of the partition count fails", () => {
    assert.throws(() => verifyWorkflowSource("fixture.yml", mutate("      MIX_ENV: test\n", `      MIX_ENV: test\n      ${PARTITION_COUNT_KEY}: 1\n`)), /overridden to 1/);
  }],
  ["a workflow with zero jobs fails rather than passing over nothing", () => {
    assert.throws(() => parseWorkflow("name: x\njobs:\n"), /zero jobs/);
  }],
  ["the live scoped workflows pass", () => {
    const results = verifyRepo(process.cwd());
    assert.equal(results.length, SCOPED_WORKFLOWS.length);
    for (const result of results) assert.ok(result.jobs > 0, `${result.file} must declare jobs`);
  }]
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

// -- entrypoint ----------------------------------------------------------------

function options(argv) {
  const flags = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]; if (!token.startsWith("--")) fail(`unexpected argument: ${token}`);
    const key = token.slice(2);
    if (key === "fixtures") { flags.add(key); continue; }
    if (key !== "repo") fail(`unknown option: --${key}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${key} requires a value`);
    values[key] = argv[++index];
  }
  return { flags, values };
}

function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) {
    console.log(`ci efficiency contract: PASS (fixtures; ${verifyFixtures()} scenarios)`);
    return;
  }
  const results = verifyRepo(parsed.values.repo || process.cwd());
  console.log(`ci efficiency contract: PASS (verified: ${results.map((r) => `${r.file} ${r.jobs} jobs`).join(", ")})`);
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
  try {
    main();
  } catch (error) {
    console.error(error.message.startsWith("ci efficiency contract:") ? error.message : `ci efficiency contract: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
