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
//   - third-party `_build` cache (item 1): release-gate caches
//     accrue/_build/test, accrue_admin/_build/test and accrue_portal/_build/test,
//     and each playwright-e2e shard caches its fixed MIX_BUILD_PATH tree.
//     Every restore is split from its save (actions/cache/restore +
//     actions/cache/save, never the combined action); the step right after a
//     restore prunes the first-party app dirs from the same env dir; the save
//     comes directly after a `mix compile --warnings-as-errors` step, is
//     skipped on an exact hit, reuses the restore's primary key, and carries
//     the restore's exact path list (the cache version is derived from it)
//     including `!` exclusions for the five first-party lib dirs and PLTs.
//     The key names runner.os, the job's OTP and Elixir versions, MIX_ENV, a
//     mix.lock hashFiles and a config/**/*.exs hashFiles (plus the
//     sigra/otel matrix in release-gate and the shard in playwright-e2e).
//
// Scope: .github/workflows/ci.yml and .github/workflows/accrue_admin_browser.yml
// for concurrency, partition count and timeouts; ci.yml for the docs keep-set
// and the `_build` cache; all workflow files for pins.
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

export const FIRST_PARTY_APPS = ["accrue", "accrue_admin", "accrue_portal", "accrue_host", "sigra"];
export const BUILD_CACHE_EXPECTATIONS = [
  { job: "release-gate", envDirs: ["accrue/_build/test", "accrue_admin/_build/test", "accrue_portal/_build/test"], matrixKeys: ["matrix.sigra", "matrix.opentelemetry"] },
  { job: "playwright-e2e", envDirs: ["examples/accrue_host/tmp/accrue-host-proof-playwright-shard-${{ matrix.shard }}/test"], matrixKeys: ["matrix.shard"] }
];
const BUILD_ENV_DIR = /(?:\/_build\/test|\/tmp\/accrue-host-proof-[^/]+\/test)$/;
const CACHE_ACTION = /^actions\/cache(?:\/(restore|save))?@/;

const pathLines = (step) => (step.with.get("path") || "").split("\n").map((line) => line.trim()).filter(Boolean);

// Returns the number of `_build` restore steps verified in `jobId`.
export function checkBuildCache(file, workflow, { job: jobId, envDirs, matrixKeys }) {
  const steps = jobSteps(workflow, jobId);
  const at = (step) => `${file}:${step.line + 1}`;
  const beam = steps.find((step) => /^erlef\/setup-beam@/.test(step.uses || ""));
  if (!beam) fail(`${file}: job \`${jobId}\` has no setup-beam step to bind the cache key to`);
  const otp = beam.with.get("otp-version"); const elixir = beam.with.get("elixir-version");
  const seen = new Set();
  steps.forEach((step, index) => {
    const action = CACHE_ACTION.exec(step.uses || "");
    if (!action) return;
    const paths = pathLines(step);
    const envDir = paths[0];
    if (!envDir || !BUILD_ENV_DIR.test(envDir)) return;
    if (!action[1]) fail(`${at(step)}: \`_build\` cache for ${envDir} uses the combined actions/cache; split it into actions/cache/restore + actions/cache/save`);
    if (action[1] === "save") return; // validated from its restore below
    if (!envDirs.includes(envDir)) fail(`${at(step)}: unexpected \`_build\` cache path ${envDir} in \`${jobId}\``);
    seen.add(envDir);
    // Key.
    const key = step.with.get("key") || "";
    const required = [
      ["runner.os", "${{ runner.os }}"],
      ["the job's OTP version", `otp${otp}`],
      ["the job's Elixir version", `elixir${elixir}`],
      ["MIX_ENV", "${{ env.MIX_ENV }}"],
      ...matrixKeys.map((matrixKey) => [matrixKey, `\${{ ${matrixKey} }}`])
    ];
    for (const [label, needle] of required) if (!key.includes(needle)) fail(`${at(step)}: \`_build\` cache key for ${envDir} is missing ${label} (\`${needle}\`)`);
    if (!/hashFiles\([^)]*mix\.lock[^)]*\)/.test(key)) fail(`${at(step)}: \`_build\` cache key for ${envDir} is missing a mix.lock hashFiles`);
    if (!/hashFiles\([^)]*config\/\*\*\/\*\.exs[^)]*\)/.test(key)) fail(`${at(step)}: \`_build\` cache key for ${envDir} is missing a config/**/*.exs hashFiles`);
    if (!step.id) fail(`${at(step)}: \`_build\` restore for ${envDir} has no id: for its save step to reference`);
    // Path exclusions (restore and save must carry the identical list).
    const required_exclusions = [...FIRST_PARTY_APPS.map((app) => `!${envDir}/lib/${app}`), `!${envDir}/**/*.plt*`];
    for (const exclusion of required_exclusions) if (!paths.includes(exclusion)) fail(`${at(step)}: \`_build\` cache path for ${envDir} lacks the \`${exclusion}\` exclusion`);
    // Prune immediately after the restore.
    const next = steps[index + 1];
    if (!next || (next.run || "").trim() !== `bash scripts/ci/prune_first_party_build.sh ${envDir}`) {
      fail(`${at(step)}: the step right after the \`_build\` restore for ${envDir} must be \`bash scripts/ci/prune_first_party_build.sh ${envDir}\` (found ${next ? `\`${next.name || next.run || next.uses}\`` : "nothing"})`);
    }
    // Exactly one matching save, directly after a warnings-as-errors compile.
    const saves = steps.filter((candidate) => /^actions\/cache\/save@/.test(candidate.uses || "") && pathLines(candidate)[0] === envDir);
    if (saves.length !== 1) fail(`${at(step)}: expected exactly one actions/cache/save for ${envDir}, found ${saves.length}`);
    const save = saves[0];
    const saveIndex = steps.indexOf(save);
    if (saveIndex < index) fail(`${at(save)}: the \`_build\` save for ${envDir} precedes its restore`);
    const previous = steps[saveIndex - 1];
    if (!/\bmix compile --warnings-as-errors\b/.test(previous?.run || "")) {
      fail(`${at(save)}: the \`_build\` save for ${envDir} must come directly after a \`mix compile --warnings-as-errors\` step (found \`${previous?.name || previous?.run || "nothing"}\`)`);
    }
    if (save.if !== `steps.${step.id}.outputs.cache-hit != 'true'`) fail(`${at(save)}: the \`_build\` save for ${envDir} must carry \`if: steps.${step.id}.outputs.cache-hit != 'true'\``);
    if (save.with.get("key") !== `\${{ steps.${step.id}.outputs.cache-primary-key }}`) fail(`${at(save)}: the \`_build\` save for ${envDir} must use key \`\${{ steps.${step.id}.outputs.cache-primary-key }}\``);
    if (JSON.stringify(pathLines(save)) !== JSON.stringify(paths)) fail(`${at(save)}: the \`_build\` save path list for ${envDir} differs from its restore's (the cache version is derived from it)`);
  });
  for (const envDir of envDirs) if (!seen.has(envDir)) fail(`${file}: job \`${jobId}\` has no \`_build\` restore for ${envDir}`);
  return seen.size;
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
  results.buildCaches = BUILD_CACHE_EXPECTATIONS.reduce((sum, expectation) => sum + checkBuildCache(".github/workflows/ci.yml", ciWorkflow, expectation), 0);
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

const BUILD_KEY = "${{ runner.os }}-release-gate-otp${{ matrix.otp }}-elixir${{ matrix.elixir }}-sigra-${{ matrix.sigra }}-otel-${{ matrix.opentelemetry }}-accrue-build-${{ env.MIX_ENV }}-cfg${{ hashFiles('accrue/config/**/*.exs') }}-lock${{ hashFiles('accrue/mix.lock') }}";
const BUILD_PATH = `          path: |
            accrue/_build/test
            !accrue/_build/test/lib/accrue
            !accrue/_build/test/lib/accrue_admin
            !accrue/_build/test/lib/accrue_portal
            !accrue/_build/test/lib/accrue_host
            !accrue/_build/test/lib/sigra
            !accrue/_build/test/**/*.plt*
`;
const BUILD_CACHE = `name: Fixture
jobs:
  release-gate:
    runs-on: ubuntu-24.04
    timeout-minutes: 45
    env:
      MIX_ENV: test
    steps:
      - name: Set up BEAM
        uses: erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124 # v1.24.1
        with:
          otp-version: \${{ matrix.otp }}
          elixir-version: \${{ matrix.elixir }}

      - name: Restore accrue _build cache
        id: accrue_build_cache
        uses: actions/cache/restore@v5
        with:
${BUILD_PATH}          key: ${BUILD_KEY}
          restore-keys: |
            prefix-

      - name: Prune first-party apps from the restored accrue _build
        run: bash scripts/ci/prune_first_party_build.sh accrue/_build/test

      - name: Install accrue deps
        run: cd accrue && mix deps.get

      - name: Accrue compile
        run: cd accrue && mix compile --warnings-as-errors

      - name: Save accrue _build cache
        if: steps.accrue_build_cache.outputs.cache-hit != 'true'
        uses: actions/cache/save@v5
        with:
${BUILD_PATH}          key: \${{ steps.accrue_build_cache.outputs.cache-primary-key }}

      - name: Accrue test
        run: cd accrue && mix test --warnings-as-errors
`;
const ONE_DIR = { job: "release-gate", envDirs: ["accrue/_build/test"], matrixKeys: ["matrix.sigra", "matrix.opentelemetry"] };
const buildCache = (source) => checkBuildCache("fixture.yml", parseWorkflow(source), ONE_DIR);
function mutateBuild(from, to, count = 1) {
  const parts = BUILD_CACHE.split(from);
  if (parts.length - 1 < count) throw new Error(`build-cache fixture anchor not found: ${from}`);
  return BUILD_CACHE.replace(from, to);
}

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
  ["a _build cache fixture with restore, prune and save in place passes", () => {
    assert.equal(buildCache(BUILD_CACHE), 1);
  }],
  ["a _build restore not followed by the prune step fails", () => {
    const source = mutateBuild("      - name: Prune first-party apps from the restored accrue _build\n        run: bash scripts/ci/prune_first_party_build.sh accrue/_build/test\n\n", "");
    assert.throws(() => buildCache(source), /right after the `_build` restore for accrue\/_build\/test must be `bash scripts\/ci\/prune_first_party_build\.sh/);
  }],
  ["a prune of a different dir fails", () => {
    assert.throws(() => buildCache(mutateBuild("prune_first_party_build.sh accrue/_build/test", "prune_first_party_build.sh accrue/_build/dev")), /must be `bash scripts\/ci\/prune_first_party_build\.sh accrue\/_build\/test`/);
  }],
  ["a save not directly after a mix compile --warnings-as-errors step fails", () => {
    const source = mutateBuild("      - name: Accrue compile\n        run: cd accrue && mix compile --warnings-as-errors\n", "      - name: Accrue compile\n        run: cd accrue && mix compile\n");
    assert.throws(() => buildCache(source), /directly after a `mix compile --warnings-as-errors` step/);
  }],
  ["a save without the cache-hit guard or with its own key fails", () => {
    assert.throws(() => buildCache(mutateBuild("        if: steps.accrue_build_cache.outputs.cache-hit != 'true'\n", "")), /must carry `if: steps\.accrue_build_cache\.outputs\.cache-hit != 'true'`/);
    assert.throws(() => buildCache(mutateBuild("key: ${{ steps.accrue_build_cache.outputs.cache-primary-key }}", "key: some-other-key")), /must use key/);
  }],
  ["a combined actions/cache on a _build path fails", () => {
    assert.throws(() => buildCache(mutateBuild("uses: actions/cache/restore@v5", "uses: actions/cache@v5")), /combined actions\/cache/);
  }],
  ["a _build key missing any required component fails", () => {
    for (const [from, to, message] of [
      ["${{ runner.os }}-", "linux-", /missing runner\.os/],
      ["-otp${{ matrix.otp }}", "", /missing the job's OTP version/],
      ["-elixir${{ matrix.elixir }}", "", /missing the job's Elixir version/],
      ["-${{ env.MIX_ENV }}", "-test", /missing MIX_ENV/],
      ["-lock${{ hashFiles('accrue/mix.lock') }}", "", /missing a mix\.lock hashFiles/],
      ["-cfg${{ hashFiles('accrue/config/**/*.exs') }}", "", /missing a config\/\*\*\/\*\.exs hashFiles/]
    ]) {
      assert.throws(() => buildCache(mutateBuild(from, to)), message, `${from} removal must fail`);
    }
  }],
  ["a release-gate _build key missing matrix.sigra or matrix.opentelemetry fails", () => {
    assert.throws(() => buildCache(mutateBuild("-sigra-${{ matrix.sigra }}", "")), /missing matrix\.sigra/);
    assert.throws(() => buildCache(mutateBuild("-otel-${{ matrix.opentelemetry }}", "")), /missing matrix\.opentelemetry/);
  }],
  ["a _build path without the first-party or PLT ! exclusions fails", () => {
    for (const exclusion of ["!accrue/_build/test/lib/accrue\n", "!accrue/_build/test/lib/sigra\n", "!accrue/_build/test/**/*.plt*\n"]) {
      const source = BUILD_CACHE.split(`            ${exclusion}`).join("");
      assert.notEqual(source, BUILD_CACHE);
      assert.throws(() => buildCache(source), /lacks the `!accrue\/_build\/test\//);
    }
  }],
  ["a save whose path list differs from its restore's fails", () => {
    const at = BUILD_CACHE.lastIndexOf("            !accrue/_build/test/lib/sigra\n");
    const source = BUILD_CACHE.slice(0, at) + BUILD_CACHE.slice(at + "            !accrue/_build/test/lib/sigra\n".length);
    assert.throws(() => buildCache(source), /save path list for accrue\/_build\/test differs/);
  }],
  ["a playwright-shard _build key missing matrix.shard fails", () => {
    const shardDir = "examples/accrue_host/tmp/accrue-host-proof-playwright-shard-${{ matrix.shard }}/test";
    const shard = BUILD_CACHE.split("accrue/_build/test").join(shardDir).replace("-sigra-${{ matrix.sigra }}-otel-${{ matrix.opentelemetry }}", "-shard-${{ matrix.shard }}");
    const expectation = { job: "release-gate", envDirs: [shardDir], matrixKeys: ["matrix.shard"] };
    assert.equal(checkBuildCache("fixture.yml", parseWorkflow(shard), expectation), 1);
    assert.throws(() => checkBuildCache("fixture.yml", parseWorkflow(shard.replace("-shard-${{ matrix.shard }}-accrue-build", "-accrue-build")), expectation), /missing matrix\.shard/);
  }],
  ["a job missing an expected _build restore fails", () => {
    assert.throws(() => checkBuildCache("fixture.yml", parseWorkflow(BUILD_CACHE), { ...ONE_DIR, envDirs: ["accrue/_build/test", "accrue_admin/_build/test"] }), /no `_build` restore for accrue_admin\/_build\/test/);
  }],
  ["the live scoped workflows pass", () => {
    const results = verifyRepo(process.cwd());
    assert.equal(results.length, SCOPED_WORKFLOWS.length);
    assert.ok(results.pins > 0, "the live pin scan must inspect at least one third-party action");
    assert.ok(results.docsSteps >= 3, "the live release-gate must expose its docs steps to the keep-set check");
    assert.equal(results.buildCaches, 4, "release-gate (3 projects) and playwright-e2e (1 shard tree) must each carry a pruned _build cache");
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
  console.log(`ci efficiency contract: PASS (verified: ${results.map((r) => `${r.file} ${r.jobs} jobs`).join(", ")}; ${results.docsSteps} release-gate docs steps on the keep-set; ${results.buildCaches} pruned _build caches; ${results.pins} third-party uses pinned across ${results.workflowFiles} workflow files)`);
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
