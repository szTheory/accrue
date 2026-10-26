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
//   - third-party action pins (item 7): every `uses:` outside `actions/*`
//     and local `./` paths is a full 40-hex commit SHA followed by a
//     `# vX.Y.Z` comment. A mutable tag lets upstream change the code that
//     runs with this job's token; publish-hex.yml and release-please.yml hold
//     HEX_API_KEY and RELEASE_PLEASE_TOKEN, so this check covers EVERY file
//     under .github/workflows, not just the two scoped files.
//
//   - docs keep-set (item 4): in ci.yml's release-gate matrix, `mix docs`
//     and every step that reads its doc/ output run only in the
//     sigra=off/opentelemetry=off cells (Floor and Primary). The sigra=on and
//     otel=on cells were dropped on byte-identical evidence: none of
//     accrue/mix.exs, accrue_admin/mix.exs or their config reads the matrix
//     env flags, a local `mix docs` under each flag set produced the same doc/
//     tree hash, and the CI docs logs of all four cells differed only in the
//     echoed env and a compile-timing line.
//
// Scope: .github/workflows/ci.yml and .github/workflows/accrue_admin_browser.yml
// for concurrency, partition count and timeouts; ci.yml for the docs keep-set;
// all workflow files for pins.
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
  jobs.forEach((job, index) => { job.end = index + 1 < jobs.length ? jobs[index + 1].line : lines.length; });
  return { lines, topLevel, jobs };
}

// Splits one job's `steps:` list into steps. Each step exposes its scalar
// keys (`name`, `id`, `uses`, `if`, `run`) and its `with:` children; a block
// scalar (`run: >-` / `run: |`) is joined from its indented body lines.
export function jobSteps(workflow, jobId) {
  const job = workflow.jobs.find((candidate) => candidate.id === jobId);
  if (!job) fail(`job \`${jobId}\` not found`);
  const { lines } = workflow;
  const stepsLine = lines.findIndex((line, index) => index > job.line && index < job.end && /^    steps:\s*$/.test(line));
  if (stepsLine === -1) fail(`job \`${jobId}\` has no steps: list`);
  const starts = [];
  for (let index = stepsLine + 1; index < job.end; index += 1) if (/^      - /.test(lines[index])) starts.push(index);
  return starts.map((start, position) => {
    const stop = position + 1 < starts.length ? starts[position + 1] : job.end;
    const body = lines.slice(start, stop).map((line, offset) => (offset === 0 ? line.replace(/^      - /, "        ") : line));
    const step = { line: start, with: new Map() };
    for (let index = 0; index < body.length; index += 1) {
      const match = /^        ([A-Za-z0-9_-]+):\s?(.*)$/.exec(body[index]);
      if (!match) continue;
      const [, key, raw] = match;
      if (key === "with" || key === "env") {
        const children = new Map();
        for (let child = index + 1; child < body.length && (isBlank(body[child]) || indentOf(body[child]) > 8); child += 1) {
          const childMatch = /^          ([A-Za-z0-9_-]+):\s?(.*)$/.exec(body[child]);
          if (!childMatch) continue;
          let value = childMatch[2].trim();
          if (value === "|" || value === ">-" || value === "|-" || value === ">") {
            const block = [];
            for (let line = child + 1; line < body.length && (isBlank(body[line]) || indentOf(body[line]) > 10); line += 1) block.push(body[line].trim());
            value = block.filter(Boolean).join("\n");
          }
          children.set(childMatch[1], stripValue(value));
        }
        if (key === "with") step.with = children; else step.env = children;
        continue;
      }
      let value = raw.trim();
      if (value === "|" || value === ">-" || value === "|-" || value === ">") {
        const block = [];
        for (let line = index + 1; line < body.length && (isBlank(body[line]) || indentOf(body[line]) > 8); line += 1) block.push(body[line].trim());
        value = block.filter(Boolean).join(value.startsWith(">") ? " " : "\n");
      }
      step[key] = stripValue(value);
    }
    return step;
  });
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

const FIRST_PARTY_ACTION = /^(?:actions\/|\.\/|docker:\/\/)/;
const PINNED_TARGET = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_./-]+@[0-9a-f]{40}$/;
const VERSION_COMMENT = /^\s+# v\d+\.\d+\.\d+\s*$/;

// Returns the number of third-party `uses:` lines inspected; fails on the
// first one that is not SHA-pinned with a version comment.
export function checkThirdPartyPins(file, source) {
  let inspected = 0;
  source.split("\n").forEach((line, index) => {
    if (line.trim().startsWith("#")) return;
    const match = /^\s*(?:-\s+)?uses:\s*(\S+)(.*)$/.exec(line);
    if (!match || FIRST_PARTY_ACTION.test(match[1])) return;
    inspected += 1;
    if (!PINNED_TARGET.test(match[1])) {
      fail(`${file}:${index + 1}: third-party action \`${match[1]}\` is not pinned to a full 40-hex commit SHA`);
    }
    if (!VERSION_COMMENT.test(match[2])) {
      fail(`${file}:${index + 1}: pinned action \`${match[1]}\` lacks a trailing \`# vX.Y.Z\` version comment`);
    }
  });
  return inspected;
}

export const DOCS_KEEP_SET_IF = "matrix.sigra == 'off' && matrix.opentelemetry == 'off'";
const DOCS_STEP = /\bmix docs\b|verify_exdoc_since_badges\.sh|(?:^|[\s/])doc\//;

export function checkDocsKeepSet(file, workflow) {
  const steps = jobSteps(workflow, "release-gate");
  const docSteps = steps.filter((step) => typeof step.run === "string" && DOCS_STEP.test(step.run));
  if (!docSteps.some((step) => /\bmix docs\b/.test(step.run))) {
    fail(`${file}: release-gate has no \`mix docs\` step -- the docs keep-set rule would be vacuous`);
  }
  for (const step of docSteps) {
    if (step.if !== DOCS_KEEP_SET_IF) {
      fail(`${file}:${step.line + 1}: release-gate docs step \`${step.name ?? step.run}\` must carry \`if: ${DOCS_KEEP_SET_IF}\` (found ${step.if ? `\`${step.if}\`` : "no if:"})`);
    }
  }
  const job = workflow.jobs.find((candidate) => candidate.id === "release-gate");
  const jobText = workflow.lines.slice(job.line, job.end).join("\n");
  const keepCells = (jobText.match(/sigra: 'off'\n\s+opentelemetry: 'off'/g) || []).length;
  if (keepCells < 2) fail(`${file}: release-gate must keep docs in at least the Floor and Primary sigra=off/opentelemetry=off cells (found ${keepCells})`);
  return docSteps.length;
}

export function allWorkflowFiles(repo) {
  const dir = path.join(repo, ".github", "workflows");
  return fs.readdirSync(dir).filter((name) => /\.ya?ml$/.test(name)).sort().map((name) => `.github/workflows/${name}`);
}

export function verifyWorkflowSource(file, source) {
  const workflow = parseWorkflow(source);
  for (const check of SCOPED_CHECKS) check(file, workflow);
  return { jobs: workflow.jobs.length };
}

export function verifyWorkflowSourceWithPins(file, source) {
  return { ...verifyWorkflowSource(file, source), pins: checkThirdPartyPins(file, source) };
}

export function verifyRepo(repo) {
  const results = [];
  for (const file of SCOPED_WORKFLOWS) {
    const absolute = path.join(repo, file);
    if (!fs.existsSync(absolute)) fail(`${file} is missing`);
    results.push({ file, ...verifyWorkflowSource(file, fs.readFileSync(absolute, "utf8")) });
  }
  const ciWorkflow = parseWorkflow(fs.readFileSync(path.join(repo, ".github/workflows/ci.yml"), "utf8"));
  results.docsSteps = checkDocsKeepSet(".github/workflows/ci.yml", ciWorkflow);
  let pins = 0;
  const workflowFiles = allWorkflowFiles(repo);
  for (const file of workflowFiles) pins += checkThirdPartyPins(file, fs.readFileSync(path.join(repo, file), "utf8"));
  // Non-vacuity: erlef/setup-beam is used across the workflows, so a pin
  // scan that inspected zero third-party actions measured nothing.
  if (pins === 0) fail(`third-party pin scan inspected zero uses across ${workflowFiles.length} workflow files`);
  results.pins = pins;
  results.workflowFiles = workflowFiles.length;
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
      - name: Set up BEAM
        uses: erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124 # v1.24.1
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

const RELEASE_GATE = `name: Fixture
jobs:
  release-gate:
    runs-on: ubuntu-24.04
    timeout-minutes: 45
    strategy:
      matrix:
        include:
          - elixir: '1.19.0'
            sigra: 'off'
            opentelemetry: 'off'
          - elixir: '1.19.5'
            sigra: 'off'
            opentelemetry: 'off'
          - elixir: '1.19.5'
            sigra: 'on'
            opentelemetry: 'off'
    steps:
      - uses: actions/checkout@v6

      - name: Accrue compile
        run: cd accrue && mix compile --warnings-as-errors

      - name: Accrue docs
        if: ${DOCS_KEEP_SET_IF}
        run: cd accrue && MIX_ENV=dev mix docs --warnings-as-errors

      - name: "Verify ExDoc @doc since: badges"
        if: ${DOCS_KEEP_SET_IF}
        run: bash scripts/ci/verify_exdoc_since_badges.sh

      - name: Accrue admin docs
        if: ${DOCS_KEEP_SET_IF}
        run: >-
          cd accrue_admin &&
          MIX_ENV=dev mix docs --warnings-as-errors
`;

const docsKeepSet = (source) => checkDocsKeepSet("fixture.yml", parseWorkflow(source));

function mutate(from, to) {
  if (!PASSING.includes(from)) throw new Error(`fixture mutation anchor not found: ${from}`);
  return PASSING.replace(from, to);
}

const SCENARIOS = [
  ["the passing fixture passes every scoped check", () => {
    assert.deepEqual(verifyWorkflowSourceWithPins("fixture.yml", PASSING), { jobs: 2, pins: 1 });
  }],
  ["a third-party action on a mutable tag fails", () => {
    assert.throws(() => verifyWorkflowSourceWithPins("fixture.yml", mutate("erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124 # v1.24.1", "erlef/setup-beam@v1")), /`erlef\/setup-beam@v1` is not pinned/);
  }],
  ["a third-party action pinned to a 39-hex SHA fails", () => {
    assert.throws(() => verifyWorkflowSourceWithPins("fixture.yml", mutate("54075bcc5e249e4758d363f27d099f55d843f124 #", "54075bcc5e249e4758d363f27d099f55d843f12 #")), /not pinned to a full 40-hex/);
  }],
  ["a SHA-pinned third-party action without a # v comment fails", () => {
    assert.throws(() => verifyWorkflowSourceWithPins("fixture.yml", mutate(" # v1.24.1", "")), /lacks a trailing `# vX.Y.Z`/);
    assert.throws(() => verifyWorkflowSourceWithPins("fixture.yml", mutate(" # v1.24.1", " # latest")), /lacks a trailing/);
  }],
  ["first-party actions/* and local ./ actions are not pin-checked", () => {
    assert.equal(checkThirdPartyPins("fixture.yml", "      - uses: actions/checkout@v6\n      - uses: ./.github/actions/local\n"), 0);
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
  ["a release-gate fixture with every docs step on the keep-set passes", () => {
    assert.equal(docsKeepSet(RELEASE_GATE), 3);
  }],
  ["a release-gate mix docs step without the keep-set if: fails", () => {
    const source = RELEASE_GATE.replace(`        if: ${DOCS_KEEP_SET_IF}\n        run: cd accrue && MIX_ENV=dev`, "        run: cd accrue && MIX_ENV=dev");
    assert.notEqual(source, RELEASE_GATE);
    assert.throws(() => docsKeepSet(source), /`Accrue docs` must carry `if: matrix.sigra == 'off'/);
  }],
  ["a doc/-consuming step (exdoc badges) without the keep-set if: fails", () => {
    const source = RELEASE_GATE.replace(`        if: ${DOCS_KEEP_SET_IF}\n        run: bash scripts/ci/verify_exdoc`, "        run: bash scripts/ci/verify_exdoc");
    assert.notEqual(source, RELEASE_GATE);
    assert.throws(() => docsKeepSet(source), /Verify ExDoc @doc since: badges` must carry/);
  }],
  ["a folded-block mix docs step with a weaker if: fails", () => {
    const source = RELEASE_GATE.replace(`        if: ${DOCS_KEEP_SET_IF}\n        run: >-`, "        if: matrix.sigra == 'off'\n        run: >-");
    assert.notEqual(source, RELEASE_GATE);
    assert.throws(() => docsKeepSet(source), /`Accrue admin docs` must carry.*found `matrix.sigra == 'off'`/);
  }],
  ["a release-gate with no mix docs step fails as vacuous", () => {
    assert.throws(() => docsKeepSet(RELEASE_GATE.replace(/mix docs/g, "mix help")), /no `mix docs` step/);
  }],
  ["a matrix that keeps fewer than two off/off cells fails", () => {
    assert.throws(() => docsKeepSet(RELEASE_GATE.replace("          - elixir: '1.19.0'\n            sigra: 'off'", "          - elixir: '1.19.0'\n            sigra: 'on'")), /at least the Floor and Primary/);
  }],
  ["the live scoped workflows pass", () => {
    const results = verifyRepo(process.cwd());
    assert.equal(results.length, SCOPED_WORKFLOWS.length);
    assert.ok(results.pins > 0, "the live pin scan must inspect at least one third-party action");
    assert.ok(results.docsSteps >= 3, "the live release-gate must expose its docs steps to the keep-set check");
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
  console.log(`ci efficiency contract: PASS (verified: ${results.map((r) => `${r.file} ${r.jobs} jobs`).join(", ")}; ${results.docsSteps} release-gate docs steps on the keep-set; ${results.pins} third-party uses pinned across ${results.workflowFiles} workflow files)`);
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
