#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";

const SHA = /^[a-f0-9]{40}$/;
const REPOSITORY = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const ISO = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/;
// D-31: mirrors the literal grep pattern used by Task 3's committed-evidence
// verify command (`grep -nE '/Users/|/home/|\$HOME'`), so schema-level
// rejection and the file-level grep gate can never silently diverge.
const LEAK_RE = /\/Users\/|\/home\/|\$HOME/;

const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase SHA`); return value; }
function repository(value, label) { if (typeof value !== "string" || !REPOSITORY.test(value)) fail(`${label} must be an owner/repository string`); return value; }
function timestamp(value, label) { if (typeof value !== "string" || !ISO.test(value)) fail(`${label} must be an ISO-8601 timestamp with a UTC offset`); return value; }
function run(repo, args) { const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 }); if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`); return result.stdout.trim(); }

// D-29: closed cohort-outcome lexicon. Explicitly rejected values are checked
// first so a future accidental reuse of a Phase-230-style lexeme (`green`,
// `deferred`, `n/a`) fails loudly rather than silently passing because it
// happens not to collide with COHORT_STATES.
export const COHORT_STATES = new Set(["proved", "failed", "skipped", "advisory", "non_run"]);
const REJECTED_STATES = new Set(["deferred", "n/a", "green"]);

export const LANE_CLASSES = new Set(["merge-blocking", "credential-gated", "scheduler-only", "pr-not-merge-blocking", "not-a-declared-gate"]);

export const COHORT_ROW_FIELDS = new Set(["job", "lane_class", "state", "exit_code", "argv", "reason", "deferred_to", "duration_ms"]);
export const GATE01_FIELDS = new Set(["schema_version", "repository", "candidate_object", "observed_at", "checkout", "rows"]);
const CHECKOUT_FIELDS = new Set(["method", "source", "caches_restored", "worktree_rows_delta"]);

// D-11: the fixed six lanes this repository's CI declares out of the
// merge-blocking cohort (credential-gated, scheduler-only, pr-not-merge-blocking,
// or not-a-declared-gate). Every GATE-01 evidence row set must equal the
// declared merge-blocking cohort plus exactly these six lanes -- never more,
// never fewer -- so an omission is a hard failure rather than a silent gap.
export const OUT_OF_COHORT_LANES = [
  "live-stripe",
  "provider-proof-trigger",
  "provider-proof-incident",
  "ios-offline-client",
  "mix hex.publish --dry-run",
  "gh workflow run ci.yml"
];

const EXPECTED_HEADER_JOBS = new Set([
  "release-manifest-ssot", "docs-contracts-shift-left", "release-gate", "phase18-tax-gate",
  "admin-drift-docs", "admin-group-contracts", "admin-hardening-guardrails", "admin-phase200-guardrails",
  "admin-ui-ratchet-guardrails", "host-integration", "playwright-e2e", "host-docker-smoke", "annotation-sweep"
]);

// D-09/D-18: exact-set equality with a missing/extra pair, recomputed live --
// never a non-empty check, never a boolean pass-through. Shared by the
// declaration-drift check and the cohort-row-completeness check so both
// report the identical missing=[]/extra=[] shape (D-30).
export function assertExactSet(authorityName, authority, candidateName, candidate) {
  const a = new Set(authority);
  const c = new Set(candidate);
  const missing = [...a].filter((value) => !c.has(value)).sort();
  const extra = [...c].filter((value) => !a.has(value)).sort();
  if (missing.length || extra.length) fail(`${candidateName} differs from ${authorityName}: missing=[${missing.join(", ")}] extra=[${extra.join(", ")}]`);
}

// D-09: parses the `ci.yml` header comment block that begins with the text
// "Merge-blocking on pull_request:" and continues across subsequent comment
// lines while each line is purely a backtick-quoted, comma-separated
// continuation of the list. Throws on an absent or unparseable block --
// never returns an empty list, since an empty required set would pass every
// completeness check vacuously (D-18).
export function declaredMergeBlockingJobs(source) {
  fail("not implemented");
  const lines = source.split("\n");
  const headerRe = /^#\s*Merge-blocking on pull_request:\s*(.*)$/;
  let startIndex = -1;
  let remainder = "";
  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(headerRe);
    if (match) { startIndex = index; remainder = match[1]; break; }
  }
  if (startIndex === -1) fail('ci.yml header is missing the "Merge-blocking on pull_request:" declaration block');
  const listLineRe = /^(`[A-Za-z0-9._-]+`\s*,?\s*)+\.?\s*$/;
  const collected = [remainder];
  let index = startIndex + 1;
  while (index < lines.length) {
    const line = lines[index];
    const commentMatch = line.match(/^#\s?(.*)$/);
    if (!commentMatch) break;
    const content = commentMatch[1];
    if (!listLineRe.test(content.trim())) break;
    collected.push(content);
    index += 1;
  }
  const joined = collected.join(" ");
  const jobs = [...joined.matchAll(/`([A-Za-z0-9._-]+)`/g)].map((match) => match[1]);
  if (!jobs.length) fail('ci.yml "Merge-blocking on pull_request:" block contained no backtick-quoted job keys');
  return [...new Set(jobs)].sort();
}

// D-18: reads the LIVE `needs:` array of the `annotation-sweep` job (bracket
// form, possibly spanning multiple lines) -- the independent cross-check for
// the header declaration above. Throws when the job or its `needs:` array is
// absent, rather than returning an empty list.
export function annotationSweepNeeds(source) {
  if (typeof source !== "string" || !source) fail("ci.yml source must be a non-empty string");
  const jobRe = /^ {2}annotation-sweep:\s*$/m;
  const jobMatch = jobRe.exec(source);
  if (!jobMatch) fail("ci.yml has no annotation-sweep job");
  const rest = source.slice(jobMatch.index + jobMatch[0].length);
  const nextJobRe = /^ {2}[A-Za-z0-9_-]+:\s*$/m;
  const nextJobMatch = nextJobRe.exec(rest);
  const block = nextJobMatch ? rest.slice(0, nextJobMatch.index) : rest;
  const needsMatch = /needs:\s*\[([\s\S]*?)\]/.exec(block);
  if (!needsMatch) fail("annotation-sweep job has no needs: array");
  const jobs = needsMatch[1].split(",").map((entry) => entry.trim()).filter(Boolean);
  if (!jobs.length) fail("annotation-sweep job needs: array is empty");
  return [...new Set(jobs)].sort();
}

function assertSanitizedRow(row, label) {
  const strings = [row.job, row.lane_class, row.state, row.reason, row.deferred_to, ...(Array.isArray(row.argv) ? row.argv : [])].filter((value) => typeof value === "string");
  for (const value of strings) if (LEAK_RE.test(value)) fail(`${label} contains a sanitization violation (absolute path or home-directory reference): ${value}`);
}

function validateCheckout(checkout) {
  fields(checkout, CHECKOUT_FIELDS, "checkout");
  for (const key of CHECKOUT_FIELDS) if (!Object.hasOwn(checkout, key)) fail(`checkout is missing required field: ${key}`);
  if (checkout.method !== "git clone") fail('checkout.method must be the string "git clone"');
  if (checkout.source !== "local repository") fail('checkout.source must be the string "local repository"');
  if (typeof checkout.caches_restored !== "boolean") fail("checkout.caches_restored must be a boolean");
  if (!Number.isInteger(checkout.worktree_rows_delta)) fail("checkout.worktree_rows_delta must be an integer");
  return checkout;
}

// D-29: enforces the closed cohort-row lexicon. `proved`, `failed`, and
// `advisory` rows all mean "a real local command ran" and therefore require a
// recorded integer exit_code plus a non-empty argv array; `skipped` and
// `non_run` rows require a non-empty reason instead. D-31's sanitization
// check applies to every string value on the row, including argv elements.
export function validateCohortRow(row, index) {
  const label = index === undefined ? "row" : `rows[${index}]`;
  fields(row, COHORT_ROW_FIELDS, label);
  for (const key of ["job", "lane_class", "state"]) if (!Object.hasOwn(row, key)) fail(`${label} is missing required field: ${key}`);
  if (typeof row.job !== "string" || !row.job) fail(`${label}.job must be a non-empty string`);
  if (typeof row.lane_class !== "string" || !LANE_CLASSES.has(row.lane_class)) fail(`${label}.lane_class must be one of the closed lane-class enumeration, got: ${row.lane_class}`);
  if (typeof row.state !== "string" || REJECTED_STATES.has(row.state) || !COHORT_STATES.has(row.state)) fail(`${label}.state must be one of proved/failed/skipped/advisory/non_run, got: ${row.state}`);

  const executed = row.state === "proved" || row.state === "failed" || row.state === "advisory";
  if (executed) {
    if (!Object.hasOwn(row, "exit_code") || !Number.isInteger(row.exit_code)) fail(`${label} state "${row.state}" requires a recorded integer exit_code`);
    if (!Array.isArray(row.argv) || !row.argv.length || row.argv.some((element) => typeof element !== "string")) fail(`${label} state "${row.state}" requires a non-empty argv array of strings, never a joined shell string`);
  }
  if (row.state === "skipped" || row.state === "non_run") {
    if (typeof row.reason !== "string" || !row.reason.trim()) fail(`${label} state "${row.state}" requires a non-empty reason`);
  }
  if (Object.hasOwn(row, "deferred_to") && (typeof row.deferred_to !== "string" || !row.deferred_to)) fail(`${label}.deferred_to must be a non-empty string when present`);
  if (Object.hasOwn(row, "duration_ms") && !(Number.isInteger(row.duration_ms) && row.duration_ms >= 0)) fail(`${label}.duration_ms must be a non-negative integer when present`);
  assertSanitizedRow(row, label);
  return row;
}

export function validateGate01Evidence(evidence, { expectedRepository } = {}) {
  fields(evidence, GATE01_FIELDS, "evidence");
  for (const key of GATE01_FIELDS) if (!(key in evidence)) fail(`evidence is missing required field: ${key}`);
  if (evidence.schema_version !== 1) fail("evidence has unsupported schema version");
  repository(evidence.repository, "evidence.repository");
  if (expectedRepository && evidence.repository !== expectedRepository) fail("evidence.repository must match expectedRepository");
  fullSha(evidence.candidate_object, "evidence.candidate_object");
  timestamp(evidence.observed_at, "evidence.observed_at");
  validateCheckout(evidence.checkout);
  if (!Array.isArray(evidence.rows)) fail("evidence.rows must be an array");
  evidence.rows.forEach((row, index) => validateCohortRow(row, index));
  const seen = new Set();
  for (const row of evidence.rows) {
    if (seen.has(row.job)) fail(`evidence.rows contains duplicate job: ${row.job}`);
    seen.add(row.job);
  }
  return evidence;
}

// D-09/D-11/D-18: assembles GATE-01 evidence from the caller-supplied raw
// per-job results (`resultRows`), collected outside this module by actually
// running each declared job's local-equivalent command in a scratch clone.
// This function never runs those commands itself -- it derives the required
// row set from `ci.yml`, cross-checks the declaration against the live
// `annotation-sweep` needs: graph, asserts the supplied rows exactly cover
// the required set, validates the closed row lexicon, and stamps
// `observed_at` from the candidate's own committer date (never `Date.now()`).
export function collectGate01Cohort({ repo, expectedRepository, candidate, resultRows }) {
  repository(expectedRepository, "expectedRepository");
  if (!Array.isArray(resultRows)) fail("resultRows must be an array");
  const candidateObject = fullSha(run(repo, ["rev-parse", `${candidate}^{commit}`]), "candidate object");
  const source = fs.readFileSync(path.join(repo, ".github", "workflows", "ci.yml"), "utf8");
  const declared = declaredMergeBlockingJobs(source);
  const needs = annotationSweepNeeds(source);
  assertExactSet("declared merge-blocking cohort minus annotation-sweep", declared.filter((job) => job !== "annotation-sweep"), "annotation-sweep needs: array", needs);

  const expectedJobs = [...declared, ...OUT_OF_COHORT_LANES];
  assertExactSet("declared cohort plus declared out-of-cohort lanes", expectedJobs, "provided result rows", resultRows.map((row) => row.job));
  if (resultRows.length !== expectedJobs.length) fail("resultRows contains a duplicate job entry");

  const rows = resultRows.map((row, index) => validateCohortRow(row, index)).sort((left, right) => left.job.localeCompare(right.job));
  const observedAt = timestamp(run(repo, ["show", "-s", "--format=%cI", candidateObject]), "observed_at");

  const evidence = {
    schema_version: 1,
    repository: expectedRepository,
    candidate_object: candidateObject,
    observed_at: observedAt,
    checkout: { method: "git clone", source: "local repository", caches_restored: false, worktree_rows_delta: 0 },
    rows
  };
  return validateGate01Evidence(evidence, { expectedRepository });
}

function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--") || argv[index + 1] === undefined) fail("usage: --repo PATH --expected-repository OWNER/REPO --candidate REF --results-in FILE --out FILE");
    result[argv[index].slice(2)] = argv[++index];
  }
  return result;
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  const repo = options.repo;
  const expectedRepository = options["expected-repository"];
  const candidate = options.candidate;
  const resultsIn = options["results-in"];
  const out = options.out;
  if (!repo || !expectedRepository || !candidate || !resultsIn || !out) fail("--repo, --expected-repository, --candidate, --results-in, and --out are required");
  const resultRows = JSON.parse(fs.readFileSync(resultsIn, "utf8"));
  const evidence = collectGate01Cohort({ repo, expectedRepository, candidate, resultRows });
  fs.writeFileSync(out, `${JSON.stringify(evidence, null, 2)}\n`, { mode: 0o600 });
}

if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  try { main(); } catch (error) { console.error(`gate01 cohort collect: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
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

  test("declaredMergeBlockingJobs derives exactly the header's backtick-quoted keys, sorted", () => {
    assert.deepEqual(declaredMergeBlockingJobs(GOOD_CI_YML), ["annotation-sweep", "job-a", "job-b"]);
  });

  test("declaredMergeBlockingJobs derives exactly the thirteen live keys from the real ci.yml", () => {
    const source = fs.readFileSync(path.join(path.dirname(new URL(import.meta.url).pathname), "..", "..", ".github", "workflows", "ci.yml"), "utf8");
    const declared = declaredMergeBlockingJobs(source);
    assert.equal(declared.length, 13);
    assert.deepEqual(new Set(declared), EXPECTED_HEADER_JOBS);
  });

  test("annotationSweepNeeds derives exactly the live needs: array, sorted", () => {
    assert.deepEqual(annotationSweepNeeds(GOOD_CI_YML), ["job-a", "job-b"]);
  });

  test("declaredMergeBlockingJobs throws when the header block is absent", () => {
    const stripped = GOOD_CI_YML.split("\n").filter((line) => !line.startsWith("# Merge-blocking") && line !== "# `annotation-sweep`.").join("\n");
    assert.throws(() => declaredMergeBlockingJobs(stripped), /Merge-blocking on pull_request/);
  });

  test("annotationSweepNeeds throws when the annotation-sweep job is absent", () => {
    const stripped = GOOD_CI_YML.replace(/  annotation-sweep:[\s\S]*$/, "");
    assert.throws(() => annotationSweepNeeds(stripped), /annotation-sweep job/);
  });

  test("declaration drift: renaming a job in only the needs: array is detected as missing/extra", () => {
    const renamedNeeds = GOOD_CI_YML.replace("        job-b,", "        job-b-renamed,");
    const declared = declaredMergeBlockingJobs(renamedNeeds).filter((job) => job !== "annotation-sweep");
    const needs = annotationSweepNeeds(renamedNeeds);
    assert.throws(() => assertExactSet("declared", declared, "needs", needs), /missing=\[job-b\].*extra=\[job-b-renamed\]|extra=\[job-b-renamed\].*missing=\[job-b\]/s);
  });

  function provedRow(job, overrides = {}) { return { job, lane_class: "merge-blocking", state: "proved", exit_code: 0, argv: ["true"], ...overrides }; }

  test("validateCohortRow rejects an unknown state", () => {
    assert.throws(() => validateCohortRow(provedRow("x", { state: "unknown" })), /state.*must be one of/);
  });
  test("validateCohortRow rejects each explicitly rejected state literal", () => {
    for (const state of ["green", "deferred", "n/a"]) assert.throws(() => validateCohortRow(provedRow("x", { state })), /must be one of/);
  });
  test("validateCohortRow rejects proved without an exit_code", () => {
    const row = provedRow("x"); delete row.exit_code;
    assert.throws(() => validateCohortRow(row), /requires a recorded integer exit_code/);
  });
  test("validateCohortRow rejects proved with a null exit_code", () => {
    assert.throws(() => validateCohortRow(provedRow("x", { exit_code: null })), /requires a recorded integer exit_code/);
  });
  test("validateCohortRow rejects proved with an empty argv", () => {
    assert.throws(() => validateCohortRow(provedRow("x", { argv: [] })), /non-empty argv array/);
  });
  test("validateCohortRow rejects argv supplied as a string", () => {
    assert.throws(() => validateCohortRow(provedRow("x", { argv: "true" })), /non-empty argv array/);
  });
  test("validateCohortRow rejects skipped without a reason", () => {
    assert.throws(() => validateCohortRow({ job: "x", lane_class: "credential-gated", state: "skipped" }), /requires a non-empty reason/);
  });
  test("validateCohortRow rejects an unknown lane_class", () => {
    assert.throws(() => validateCohortRow(provedRow("x", { lane_class: "unknown" })), /lane_class must be one of/);
  });
  test("validateCohortRow rejects an absolute path in a string value", () => {
    assert.throws(() => validateCohortRow(provedRow("x", { argv: ["/Users/someone/bin/mix", "test"] })), /sanitization violation/);
    assert.throws(() => validateCohortRow({ job: "x", lane_class: "credential-gated", state: "skipped", reason: "needs $HOME/.stripe" }), /sanitization violation/);
  });

  test("row set unequal to the declared cohort is a missing/extra failure", () => {
    const declared = ["job-a", "job-b", "annotation-sweep"];
    const provided = ["job-a", "annotation-sweep", "extra-job"];
    assert.throws(() => assertExactSet("declared cohort", declared, "provided rows", provided), /missing=\[job-b\]/);
    assert.throws(() => assertExactSet("declared cohort", declared, "provided rows", provided), /extra=\[extra-job\]/);
  });

  test("validateGate01Evidence rejects a non-boolean checkout.caches_restored", () => {
    const evidence = {
      schema_version: 1, repository: "szTheory/accrue", candidate_object: "a".repeat(40), observed_at: "2026-09-15T00:00:00+00:00",
      checkout: { method: "git clone", source: "local repository", caches_restored: "true", worktree_rows_delta: 0 },
      rows: []
    };
    assert.throws(() => validateGate01Evidence(evidence), /caches_restored must be a boolean/);
  });

  test("validateGate01Evidence rejects a duplicate job across rows", () => {
    const evidence = {
      schema_version: 1, repository: "szTheory/accrue", candidate_object: "a".repeat(40), observed_at: "2026-09-15T00:00:00+00:00",
      checkout: { method: "git clone", source: "local repository", caches_restored: false, worktree_rows_delta: 0 },
      rows: [provedRow("job-a"), provedRow("job-a")]
    };
    assert.throws(() => validateGate01Evidence(evidence), /duplicate job/);
  });

  test("COHORT_STATES and LANE_CLASSES are exactly the closed five-member enumerations", () => {
    assert.deepEqual([...COHORT_STATES].sort(), ["advisory", "failed", "non_run", "proved", "skipped"]);
    assert.deepEqual([...LANE_CLASSES].sort(), ["credential-gated", "merge-blocking", "not-a-declared-gate", "pr-not-merge-blocking", "scheduler-only"]);
  });
}
