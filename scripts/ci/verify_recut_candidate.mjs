#!/usr/bin/env node
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";

// D-04: the only literals in this phase legitimately frozen — copied verbatim
// (full 40-hex, never re-typed from an abbreviation) from
// collect_integration_disposition.mjs, which already defines them for the
// same v1.61/closure identity.
export const V161_TAG_OBJECT = "fdb41672dd9240b36623ab22a7a8377a2735e5a3";
export const V161_COMMIT_OBJECT = "e3b06794e4dc0d36deb5fc7cb94cbb0b3207d6d9";
export const CLOSURE_COMMITS = [
  "8a95fbe8109cf22efac4763f3d209e2e1b1aeba9",
  "9e090eb5c6f3f384d5abe5e149cf5485dc120f9a",
  "7cc501a33ac2d808b3fee9857e72a8c7eabd94e6",
  "57c61a9a48f1ae84f7b3c3f45333eb6e5fb7261c"
];

// D-01/D-04: the superseded candidate this phase re-cuts away from. It is a
// frozen historical object (Phase 230's tip), so pinning it as a comparison
// anchor for --require-toolchain is safe.
export const SUPERSEDED_CANDIDATE = "bab50d92be2695b12d5853e7d578e600376e73d0";

const SHA = /^[a-f0-9]{40}$/;
const DIGEST = /^[a-f0-9]{64}$/;

const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase 40-hex object id`); return value; }
function refName(value, label) { if (typeof value !== "string" || !value.startsWith("refs/") || /[\0-\x1f\x7f ~^:?*\\[\]]/.test(value)) fail(`${label} must be a safe ref name`); return value; }
function relativePath(value, label) { if (typeof value !== "string" || !value || value.startsWith("/") || value.includes("\\") || value.split("/").some((part) => !part || part === "." || part === "..") || /[\0-\x1f\x7f]/.test(value)) fail(`${label} must be a normalized repository-relative path`); return value; }
function nonEmptyString(value, label) { if (typeof value !== "string" || !value.trim()) fail(`${label} must be a non-empty string`); return value; }
function boolean(value, label) { if (typeof value !== "boolean") fail(`${label} must be a boolean`); return value; }

function run(repo, args) {
  const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 });
  if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`);
  return result.stdout.trim();
}

// D-32: new artifacts resolve through phase_evidence_path.mjs so they survive
// milestone archiving — never a hardcoded `.planning/phases/...` literal.
export function defaultRecordPath() {
  return resolvePhaseEvidencePath("231-exact-sha-release-gate-proof", "231-ROLLBACK-POINT.json");
}

export const RECUT_RECORD_FIELDS = new Set([
  "schema_version",
  "candidate_ref",
  "candidate_object",
  "parents",
  "pre_integration_refs",
  "expected_reverted_tree",
  "supersedes",
  "toolchain_pin",
  "restore_argv"
]);

export function validateRecutRecord(record) {
  fields(record, RECUT_RECORD_FIELDS, "recut record");
  if (record.schema_version !== 1) fail("recut record has unsupported schema_version");
  refName(record.candidate_ref, "candidate_ref");
  fullSha(record.candidate_object, "candidate_object");

  fields(record.parents, new Set(["first_parent", "second_parent"]), "parents");
  fullSha(record.parents.first_parent, "parents.first_parent");
  fullSha(record.parents.second_parent, "parents.second_parent");

  if (!record.pre_integration_refs || typeof record.pre_integration_refs !== "object" || Array.isArray(record.pre_integration_refs)) fail("pre_integration_refs must be an object map");
  for (const [ref, object] of Object.entries(record.pre_integration_refs)) { refName(ref, "pre_integration_refs key"); fullSha(object, `pre_integration_refs.${ref}`); }

  fullSha(record.expected_reverted_tree, "expected_reverted_tree");

  fields(record.supersedes, new Set(["candidate_object", "artifact", "cause"]), "supersedes");
  fullSha(record.supersedes.candidate_object, "supersedes.candidate_object");
  if (record.supersedes.artifact !== "230-ROLLBACK-POINT.json") fail("supersedes.artifact must equal 230-ROLLBACK-POINT.json");
  nonEmptyString(record.supersedes.cause, "supersedes.cause");

  fields(record.toolchain_pin, new Set(["path", "sha256", "matches_superseded"]), "toolchain_pin");
  relativePath(record.toolchain_pin.path, "toolchain_pin.path");
  if (!DIGEST.test(record.toolchain_pin.sha256)) fail("toolchain_pin.sha256 must be a SHA-256 digest");
  boolean(record.toolchain_pin.matches_superseded, "toolchain_pin.matches_superseded");

  if (!Array.isArray(record.restore_argv) || !record.restore_argv.length) fail("restore_argv must be a non-empty array");
  for (const argv of record.restore_argv) {
    if (!Array.isArray(argv) || !argv.length || argv.some((element) => typeof element !== "string")) fail("restore_argv element must be an array of strings, never a joined shell string");
    if (argv[0] !== "git") fail("restore_argv element's first entry must be the string git");
  }
  return record;
}

// D-30: this function is deliberately NOT implemented yet (RED phase). It
// must re-derive every shape/ancestry/revert-proof/toolchain gate live from
// git plumbing — see the GREEN commit for the real implementation.
export function collectRecutGates() {
  fail("collectRecutGates is not implemented yet");
}

export function verifyFixtures() {
  function fixtureRepo() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-recut-fixture-"));
    const repo = path.join(scratch, "repo");
    fs.mkdirSync(repo);
    const g = (args) => run(repo, args);
    g(["init", "-q", "-b", "milestone"]);
    g(["config", "user.email", "phase231@example.invalid"]);
    g(["config", "user.name", "Phase 231"]);
    fs.writeFileSync(path.join(repo, "base.txt"), "base\n"); g(["add", "base.txt"]); g(["commit", "-qm", "base"]);
    const base = g(["rev-parse", "HEAD"]);
    fs.writeFileSync(path.join(repo, "v161.txt"), "v161\n"); g(["add", "v161.txt"]); g(["commit", "-qm", "v1.61"]);
    const v161Commit = g(["rev-parse", "HEAD"]);
    g(["tag", "-a", "v1.61", "-m", "v1.61", v161Commit]);
    const v161Tag = g(["rev-parse", "v1.61"]);
    const closureCommits = [];
    for (let index = 0; index < 4; index += 1) {
      fs.writeFileSync(path.join(repo, `closure${index}.txt`), `closure${index}\n`);
      g(["add", `closure${index}.txt`]); g(["commit", "-qm", `closure ${index}`]);
      closureCommits.push(g(["rev-parse", "HEAD"]));
    }
    fs.writeFileSync(path.join(repo, ".tool-versions"), "nodejs 22.14.0\nelixir 1.19.5-otp-28\nerlang 28.5\n");
    g(["add", ".tool-versions"]); g(["commit", "-qm", "toolchain pin"]);
    const milestoneTip = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "-b", "origin-main", base]);
    fs.writeFileSync(path.join(repo, "remote.txt"), "remote\n"); g(["add", "remote.txt"]); g(["commit", "-qm", "remote"]);
    const originMain = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "milestone"]);
    return { scratch, repo, base, v161Tag, v161Commit, closureCommits, milestoneTip, originMain };
  }
  function withFixture(fn) {
    const fx = fixtureRepo();
    try { fn(fx); } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  }

  withFixture((fx) => {
    const g = (args) => run(fx.repo, args);
    g(["checkout", "-q", "-B", "recut-merge-tmp", fx.milestoneTip]);
    const merged = spawnSync("git", ["-C", fx.repo, "merge", "--no-ff", "--no-edit", fx.originMain], { encoding: "utf8", shell: false });
    if (merged.status !== 0) fail(`fixture merge failed: ${merged.stderr}`);
    const mergeObject = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "milestone"]);
    g(["branch", "-D", "recut-merge-tmp"]);

    const collected = collectRecutGates({
      candidateObject: mergeObject,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain,
      v161TagObject: fx.v161Tag,
      v161CommitObject: fx.v161Commit,
      closureCommits: fx.closureCommits,
      supersededObject: fx.milestoneTip
    }, fx.repo);
    assert.equal(collected.allSatisfied, true);
  });
}

const BOOLEAN_FLAGS = new Set(["fixtures", "require-shape", "require-ancestry", "require-revert-proof", "require-toolchain", "require-supersession"]);
const VALUE_OPTIONS = new Set(["repo", "record", "candidate", "expected-repository"]);

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

function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("recut candidate fixtures: PASS"); return; }
  const expectedRepository = parsed.values["expected-repository"];
  if (!expectedRepository) fail("--expected-repository is required");
  const repo = parsed.values.repo || process.cwd();
  const recordPath = parsed.values.record || defaultRecordPath();
  const record = validateRecutRecord(JSON.parse(fs.readFileSync(recordPath, "utf8")));
  if (parsed.values.candidate) {
    const ref = parsed.values.candidate.startsWith("refs/") ? parsed.values.candidate : `refs/heads/${parsed.values.candidate}`;
    if (ref !== record.candidate_ref) fail("--candidate does not match the recorded candidate_ref");
  }

  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
  if (requestedStrictFlags.length) {
    collectRecutGates({
      candidateObject: record.candidate_object,
      tipRef: record.candidate_ref,
      firstParent: record.parents.first_parent,
      secondParent: record.parents.second_parent
    }, repo);
  }

  const verificationSuffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")})`
    : " (schema-only: no strict flags supplied, no shape or ancestry check ran)";
  console.log(`recut candidate verification: PASS${verificationSuffix}`);
}

if (process.env.NODE_TEST_CONTEXT) {
  test("recut candidate fixtures pass every negative control", () => verifyFixtures());
} else {
  try { main(); } catch (error) { console.error(`recut candidate verify: FAIL: ${error.message}`); process.exitCode = 1; }
}
