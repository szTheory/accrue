#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";
import {
  OUT_OF_COHORT_LANES,
  declaredMergeBlockingJobs,
  annotationSweepNeeds,
  validateGate01Evidence
} from "./collect_gate01_cohort.mjs";
import { renderGate01Cohort } from "./render_gate01_cohort.mjs";

const fail = (message) => { throw new Error(message); };

function git(repo, args) {
  const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 });
  if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`);
  return result.stdout.trim();
}

// D-30: copied identically from verify_integration_disposition.mjs rather
// than writing new comparisons -- the same missing/extra/changed triple
// discipline applies here.
function assertSameMultiset(authorityName, authority, candidateName, candidate, keyOf) {
  const expected = authority.map(keyOf).sort();
  const actual = candidate.map(keyOf).sort();
  if (expected.length !== actual.length || expected.some((value, index) => value !== actual[index])) {
    fail(`${candidateName} differs from ${authorityName}: expected=[${expected.join(", ")}] actual=[${actual.join(", ")}]`);
  }
}
function exactMap(rows, label, keyOf, valueOf) {
  const result = new Map();
  for (const row of rows) {
    const key = keyOf(row);
    if (result.has(key)) fail(`${label} contains duplicate mapping: ${key}`);
    result.set(key, valueOf(row));
  }
  return result;
}
function assertSameMap(authorityName, authority, candidateName, candidate) {
  const missing = [...authority.keys()].filter((key) => !candidate.has(key)).sort();
  const extra = [...candidate.keys()].filter((key) => !authority.has(key)).sort();
  const changed = [...authority.keys()].filter((key) => candidate.has(key) && candidate.get(key) !== authority.get(key)).sort();
  if (missing.length || extra.length || changed.length) {
    fail(`${candidateName} differs from ${authorityName}: missing=[${missing.join(", ")}] extra=[${extra.join(", ")}] changed=[${changed.join(", ")}]`);
  }
}

function readCiYml(repo) {
  const ciYmlPath = path.join(repo, ".github", "workflows", "ci.yml");
  if (!fs.existsSync(ciYmlPath)) fail(`missing ci.yml at expected path: ${ciYmlPath}`);
  return fs.readFileSync(ciYmlPath, "utf8");
}

// D-09/D-18/D-30/D-37: re-derives the required job set from the LIVE
// `.github/workflows/ci.yml` on every call -- never trusts a value carried in
// the evidence record, which is compared against authority, never treated as
// authority. Explicitly does NOT query GitHub's branch protection settings or
// its rulesets feature for this repository: both are empty here, so a
// protection-derived required set would pass every completeness check
// vacuously (D-18).
function assertCohortCompleteness(repo, record) {
  fail("not implemented");
  const source = readCiYml(repo);
  const declared = declaredMergeBlockingJobs(source);
  const expectedJobs = [...declared, ...OUT_OF_COHORT_LANES];
  const authority = exactMap(expectedJobs.map((job) => ({ job })), "declared cohort plus out-of-cohort lanes", (row) => row.job, () => true);
  const candidate = exactMap(record.rows, "evidence rows", (row) => row.job, () => true);
  assertSameMap("declared cohort plus out-of-cohort lanes", authority, "evidence rows", candidate);
}

function assertDeclarationDrift(repo) {
  const source = readCiYml(repo);
  const declared = declaredMergeBlockingJobs(source).filter((job) => job !== "annotation-sweep");
  const needs = annotationSweepNeeds(source);
  const authority = exactMap(declared.map((job) => ({ job })), "declared merge-blocking cohort minus annotation-sweep", (row) => row.job, () => true);
  const candidate = exactMap(needs.map((job) => ({ job })), "annotation-sweep needs: array", (row) => row.job, () => true);
  assertSameMap("declared merge-blocking cohort minus annotation-sweep", authority, "annotation-sweep needs: array", candidate);
}

// D-29: every proved row must carry BOTH a real integer exit_code and a
// non-empty argv array, and that exit_code must be zero -- a proved row
// recording a non-zero exit code is a self-contradiction (D-15).
function assertExitCodes(record) {
  for (const row of record.rows) {
    if (row.state !== "proved") continue;
    if (!Number.isInteger(row.exit_code)) fail(`proved row "${row.job}" lacks an integer exit_code`);
    if (!Array.isArray(row.argv) || !row.argv.length) fail(`proved row "${row.job}" lacks a non-empty argv array`);
    if (row.exit_code !== 0) fail(`proved row "${row.job}" recorded a non-zero exit code: ${row.exit_code}`);
  }
}

// D-12/D-13: asserts the evidence's own recorded checkout facts assert a
// cache-free scratch clone -- never restored caches, never a repository
// worktree mutation.
function assertCleanCheckout(record) {
  const checkout = record.checkout;
  if (!checkout || checkout.method !== "git clone") fail('checkout.method must be the string "git clone"');
  if (checkout.caches_restored !== false) fail("checkout.caches_restored must be the boolean false");
  if (checkout.worktree_rows_delta !== 0) fail("checkout.worktree_rows_delta must be the integer 0");
}

// D-31: proves the rendered Markdown is byte-reproducible from the committed
// JSON, printing the first differing byte offset rather than a vague mismatch.
function assertDeterminism(record, renderedContent) {
  const fresh = renderGate01Cohort(record);
  if (fresh === renderedContent) return;
  const length = Math.min(fresh.length, renderedContent.length);
  let offset = 0;
  while (offset < length && fresh[offset] === renderedContent[offset]) offset += 1;
  fail(`rendered Markdown is not byte-reproducible from the committed JSON (first differing byte offset: ${offset})`);
}

function applyStrictFlags(repo, record, flags, renderedContent) {
  if (flags.has("require-cohort-completeness")) assertCohortCompleteness(repo, record);
  if (flags.has("require-declaration-drift")) assertDeclarationDrift(repo);
  if (flags.has("require-exit-codes")) assertExitCodes(record);
  if (flags.has("require-clean-checkout")) assertCleanCheckout(record);
  if (flags.has("require-determinism")) {
    if (renderedContent === undefined) fail("--rendered is required with --require-determinism");
    assertDeterminism(record, renderedContent);
  }
}

export function verifyFixtures() {
  function scratchRepoWithCiYml(ciYmlContent) {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-gate01-verify-fixture-"));
    fs.mkdirSync(path.join(scratch, ".github", "workflows"), { recursive: true });
    fs.writeFileSync(path.join(scratch, ".github", "workflows", "ci.yml"), ciYmlContent);
    return scratch;
  }

  const GOOD_CI_YML = [
    "# Merge-blocking on pull_request: `job-a`, `job-b`,",
    "# `annotation-sweep`.",
    "jobs:",
    "  job-a:",
    "    runs-on: ubuntu-24.04",
    "  job-b:",
    "    runs-on: ubuntu-24.04",
    "  annotation-sweep:",
    "    needs:",
    "      [",
    "        job-a,",
    "        job-b,",
    "      ]",
    "    runs-on: ubuntu-24.04",
    ""
  ].join("\n");

  function provedRow(job, overrides = {}) { return { job, lane_class: "merge-blocking", state: "proved", exit_code: 0, argv: ["true"], ...overrides }; }
  function nonRunRow(job, laneClass, overrides = {}) { return { job, lane_class: laneClass, state: "non_run", reason: "fixture reason", ...overrides }; }

  function goodRows() {
    return [
      provedRow("job-a"),
      provedRow("job-b"),
      nonRunRow("annotation-sweep", "merge-blocking", { deferred_to: "GATE-02" }),
      nonRunRow("live-stripe", "credential-gated"),
      nonRunRow("provider-proof-trigger", "scheduler-only"),
      nonRunRow("provider-proof-incident", "scheduler-only"),
      nonRunRow("ios-offline-client", "pr-not-merge-blocking"),
      nonRunRow("mix hex.publish --dry-run", "not-a-declared-gate"),
      nonRunRow("gh workflow run ci.yml", "not-a-declared-gate")
    ];
  }
  function minimalRecord(rows) {
    return {
      schema_version: 1,
      repository: "szTheory/accrue",
      candidate_object: "a".repeat(40),
      observed_at: "2026-09-15T00:00:00+00:00",
      checkout: { method: "git clone", source: "local repository", caches_restored: false, worktree_rows_delta: 0 },
      rows
    };
  }

  // Scenario 1: clean pass on every strict flag; determinism holds.
  {
    const repo = scratchRepoWithCiYml(GOOD_CI_YML);
    try {
      const record = validateGate01Evidence(minimalRecord(goodRows()));
      applyStrictFlags(repo, record, new Set(["require-cohort-completeness", "require-declaration-drift", "require-exit-codes", "require-clean-checkout", "require-determinism"]), renderGate01Cohort(record));
    } finally { fs.rmSync(repo, { recursive: true, force: true }); }
  }

  // Scenario 2: --require-cohort-completeness fails when a declared job is
  // missing from the record, naming it in the missing=[] list.
  {
    const repo = scratchRepoWithCiYml(GOOD_CI_YML);
    try {
      const rows = goodRows().filter((row) => row.job !== "job-b");
      const record = minimalRecord(rows);
      assert.throws(() => assertCohortCompleteness(repo, record), /missing=\[job-b\]/);
    } finally { fs.rmSync(repo, { recursive: true, force: true }); }
  }

  // Scenario 3: --require-cohort-completeness fails when a declared job has
  // two rows -- exactMap's duplicate-key rejection fires during map-building.
  {
    const repo = scratchRepoWithCiYml(GOOD_CI_YML);
    try {
      const rows = [...goodRows(), provedRow("job-a")];
      const record = minimalRecord(rows);
      assert.throws(() => validateGate01Evidence(record), /duplicate job/);
      assert.throws(() => assertCohortCompleteness(repo, { rows }), /duplicate mapping/);
    } finally { fs.rmSync(repo, { recursive: true, force: true }); }
  }

  // Scenario 4: --require-declaration-drift re-derives both sides live and
  // fails, naming the drifted key, when a synthetic ci.yml renames a job in
  // only one of the two declarations.
  {
    const renamedNeeds = GOOD_CI_YML.replace("        job-b,", "        job-b-renamed,");
    const repo = scratchRepoWithCiYml(renamedNeeds);
    try {
      assert.throws(() => assertDeclarationDrift(repo), /missing=\[job-b\]/);
      assert.throws(() => assertDeclarationDrift(repo), /extra=\[job-b-renamed\]/);
    } finally { fs.rmSync(repo, { recursive: true, force: true }); }
  }

  // Scenario 5: --require-exit-codes fails on a proved row with a non-zero
  // exit code, on a missing exit_code, and on a missing argv array.
  {
    const badExit = minimalRecord([provedRow("job-a", { exit_code: 1 })]);
    assert.throws(() => assertExitCodes(badExit), /non-zero exit code/);
    const missingExit = { rows: [{ job: "job-a", lane_class: "merge-blocking", state: "proved", argv: ["true"] }] };
    assert.throws(() => assertExitCodes(missingExit), /lacks an integer exit_code/);
    const missingArgv = { rows: [{ job: "job-a", lane_class: "merge-blocking", state: "proved", exit_code: 0 }] };
    assert.throws(() => assertExitCodes(missingArgv), /lacks a non-empty argv array/);
  }

  // Scenario 6: --require-clean-checkout fails when caches_restored is the
  // boolean true, when method is not "git clone", and when
  // worktree_rows_delta is not 0.
  {
    assert.throws(() => assertCleanCheckout({ checkout: { method: "git clone", caches_restored: true, worktree_rows_delta: 0 } }), /caches_restored must be the boolean false/);
    assert.throws(() => assertCleanCheckout({ checkout: { method: "git worktree add", caches_restored: false, worktree_rows_delta: 0 } }), /method must be the string/);
    assert.throws(() => assertCleanCheckout({ checkout: { method: "git clone", caches_restored: false, worktree_rows_delta: 1 } }), /worktree_rows_delta must be the integer 0/);
  }

  // Scenario 7: --require-determinism fails and prints the first differing
  // byte offset when the rendered Markdown does not match the record.
  {
    const record = minimalRecord(goodRows());
    const rendered = renderGate01Cohort(record);
    const tampered = rendered.slice(0, 50) + "X" + rendered.slice(51);
    assert.throws(() => assertDeterminism(record, tampered), /first differing byte offset: 50/);
  }

  // Scenario 8: a missing or unreadable records file is a hard failure
  // naming the path -- exercised through the same guard main() uses.
  {
    const missingPath = path.join(fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-gate01-verify-fixture-missing-")), "nonexistent.json");
    assert.throws(() => loadRecordsFile(missingPath), new RegExp(`missing or unreadable records file: ${missingPath.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`));
  }

  // Scenario 9: assertSameMap's message contains all three of missing=[,
  // extra=[, changed=[.
  {
    const authority = exactMap([{ k: "a", v: 1 }, { k: "b", v: 1 }], "authority", (r) => r.k, (r) => r.v);
    const candidate = exactMap([{ k: "b", v: 2 }, { k: "c", v: 1 }], "candidate", (r) => r.k, (r) => r.v);
    assert.throws(() => assertSameMap("authority", authority, "candidate", candidate), /missing=\[.*\].*extra=\[.*\].*changed=\[.*\]/s);
  }

}

function loadRecordsFile(recordsPath) {
  if (!recordsPath || !fs.existsSync(recordsPath)) fail(`missing or unreadable records file: ${recordsPath}`);
  return JSON.parse(fs.readFileSync(recordsPath, "utf8"));
}

const BOOLEAN_FLAGS = new Set(["fixtures", "require-cohort-completeness", "require-declaration-drift", "require-exit-codes", "require-clean-checkout", "require-determinism"]);
const VALUE_OPTIONS = new Set(["records", "rendered", "repo", "candidate", "expected-repository"]);

function options(argv) {
  const flags = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]; if (!token.startsWith("--")) fail(`unexpected argument: ${token}`);
    const key = token.slice(2);
    if (BOOLEAN_FLAGS.has(key)) { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option: --${key}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${key} requires a value`);
    if (key in values) fail(`--${key} may be provided only once`);
    values[key] = argv[++index];
  }
  return { flags, values };
}

async function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("gate01 cohort fixtures: PASS"); return; }
  const expectedRepository = parsed.values["expected-repository"];
  if (!expectedRepository) fail("--expected-repository is required");
  const repo = parsed.values.repo || process.cwd();
  const record = validateGate01Evidence(loadRecordsFile(parsed.values.records), { expectedRepository });

  if (parsed.values.candidate) {
    const ref = parsed.values.candidate;
    const resolved = git(repo, ["rev-parse", `${ref}^{commit}`]);
    if (resolved !== record.candidate_object) fail("--candidate does not resolve to the recorded candidate_object");
  }

  let renderedContent;
  if (parsed.flags.has("require-determinism")) {
    if (!parsed.values.rendered) fail("--rendered is required with --require-determinism");
    if (!fs.existsSync(parsed.values.rendered)) fail(`missing or unreadable rendered file: ${parsed.values.rendered}`);
    renderedContent = fs.readFileSync(parsed.values.rendered, "utf8");
  }

  applyStrictFlags(repo, record, parsed.flags, renderedContent);

  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
  const suffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")})`
    : " (schema-only: no strict flags supplied, no completeness or drift check ran)";
  console.log(`gate01 cohort verification: PASS${suffix}`);
}

if (process.env.NODE_TEST_CONTEXT) {
  test("gate01 cohort fixtures pass every negative control", () => verifyFixtures());
} else {
  main().catch((error) => { console.error(`gate01 cohort verify: FAIL: ${error.message}`); process.exitCode = 1; });
}
