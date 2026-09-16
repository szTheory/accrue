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

  if (!Array.isArray(record.restore_argv) || !record.restore_argv.length) fail("restore_argv must be a non-empty array of argv arrays (each an array of strings), never a joined shell string");
  for (const argv of record.restore_argv) {
    if (!Array.isArray(argv) || !argv.length || argv.some((element) => typeof element !== "string")) fail("restore_argv element must be an array of strings, never a joined shell string");
    if (argv[0] !== "git") fail("restore_argv element's first entry must be the string git");
  }
  return record;
}

function isAncestor(repo, ancestor, descendant) {
  const result = spawnSync("git", ["-C", repo, "merge-base", "--is-ancestor", ancestor, descendant], { encoding: "utf8", shell: false, timeout: 20000 });
  if (result.error) fail(`git merge-base --is-ancestor failed to run: ${result.error.message}`);
  return result.status === 0;
}

// D-07/D-12: revert proof executed — never asserted — in a scratch `git
// clone` (NEVER `git worktree add`, which would add a row the repository
// inventory verifier's exact worktree multiset would then reject). Removed
// in a `finally` block regardless of outcome.
function proveRevertTree(repo, candidateObject) {
  const scratchRoot = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-recut-revert-"));
  try {
    const clone = path.join(scratchRoot, "clone");
    const cloned = spawnSync("git", ["clone", "--no-hardlinks", "--quiet", repo, clone], { encoding: "utf8", shell: false, timeout: 60000, maxBuffer: 20_000_000 });
    if (cloned.error || cloned.status !== 0) fail(`scratch clone failed: ${(cloned.stderr || cloned.error?.message || "").trim()}`);
    run(clone, ["config", "user.email", "phase231@example.invalid"]);
    run(clone, ["config", "user.name", "Phase 231"]);
    run(clone, ["checkout", "--quiet", candidateObject]);
    const reverted = spawnSync("git", ["-C", clone, "revert", "-m", "1", "--no-edit", candidateObject], { encoding: "utf8", shell: false, timeout: 60000, maxBuffer: 20_000_000 });
    if (reverted.error || reverted.status !== 0) fail(`revert failed in scratch clone: ${(reverted.stderr || reverted.error?.message || "").trim()}`);
    return run(clone, ["rev-parse", "HEAD^{tree}"]);
  } finally {
    fs.rmSync(scratchRoot, { recursive: true, force: true });
  }
}

function missingToolchainLines(repo, tipObject, supersededObject) {
  const tipBlob = run(repo, ["show", `${tipObject}:.tool-versions`]);
  const supersededBlob = run(repo, ["show", `${supersededObject}:.tool-versions`]);
  const tipLines = new Set(tipBlob.split("\n").map((line) => line.trim()).filter(Boolean));
  return supersededBlob.split("\n").map((line) => line.trim()).filter(Boolean).filter((line) => !tipLines.has(line));
}

// D-30: re-derives every shape/ancestry/revert-proof/toolchain gate LIVE from
// git plumbing and compares against the caller-supplied expectations — the
// record is never trusted as its own authority. `candidateObject` is the
// pinned merge commit (231-ROLLBACK-POINT.json's `candidate_object`);
// `tipRef` (defaults to the same value) is the branch's live tip, which is
// what actually gets checked out and so is what the toolchain-pin gate must
// inspect. `firstParent`/`secondParent`, when supplied, are the RECORDED
// expected identity (milestone-HEAD-at-cut / origin-main) — the shape and
// unique-commit-count gates compare live git plumbing against these
// EXTERNALLY SUPPLIED values rather than the candidate's own derived
// immediate parents, which is what makes the "second merge point" (D-05
// advance-by-merging / merge-back-then-recut) failure mode detectable at
// all: for any bona-fide two-parent merge M, `git rev-list M ^P0 ^P1` using
// M's OWN immediate parents is always exactly 1 by construction, so the only
// way this gate can ever observe a value other than 1 is by checking against
// an independently-recorded expected identity instead.
export function collectRecutGates(input, repoArg) {
  const opts = typeof input === "string" ? { candidateObject: input } : (input || {});
  const repo = opts.repo || repoArg;
  if (!repo) fail("collectRecutGates requires a repo");
  const candidateInput = opts.candidateObject;
  if (!candidateInput) fail("collectRecutGates requires a candidateObject");
  const tipRef = opts.tipRef || candidateInput;
  const v161TagObject = opts.v161TagObject || V161_TAG_OBJECT;
  const v161CommitObject = opts.v161CommitObject || V161_COMMIT_OBJECT;
  const closureCommits = opts.closureCommits || CLOSURE_COMMITS;
  const supersededObject = opts.supersededObject || SUPERSEDED_CANDIDATE;

  const candidateObject = run(repo, ["rev-parse", `${candidateInput}^{commit}`]);
  const tipObject = run(repo, ["rev-parse", `${tipRef}^{commit}`]);
  const actualParentsLine = run(repo, ["rev-list", "--parents", "-n", "1", candidateObject]).split(" ").filter(Boolean);
  const actualParents = actualParentsLine.slice(1);

  const expectedFirstParent = opts.firstParent ? run(repo, ["rev-parse", `${opts.firstParent}^{commit}`]) : actualParents[0];
  const expectedSecondParent = opts.secondParent ? run(repo, ["rev-parse", `${opts.secondParent}^{commit}`]) : actualParents[1];

  const gates = [];

  // Shape identity is judged purely on the candidate's OWN immediate parent
  // count (a rebase/squash collapses this to 1). Whether those two parents
  // match the RECORDED expected milestone-HEAD-at-cut/origin-main identity is
  // a separate concern handled below by the unique-commit-count gate, which
  // is what actually detects a "second merge point" (D-05) — a genuine
  // two-parent merge whose own immediate parents differ from the originally
  // recorded ones because it was built by merging an already-merged
  // candidate again.
  gates.push(actualParents.length === 2
    ? { gate: "single_first_parent_merge", state: "proved", evidence: `parents=[${actualParents.join(", ")}]` }
    : { gate: "single_first_parent_merge", state: "failed", evidence: `observed parent count=${actualParents.length} (expected 2)` });

  if (expectedFirstParent && expectedSecondParent) {
    const uniqueCount = Number(run(repo, ["rev-list", "--count", candidateObject, `^${expectedFirstParent}`, `^${expectedSecondParent}`]));
    gates.push(uniqueCount === 1
      ? { gate: "exactly_one_new_commit", state: "proved", evidence: "unique_commit_count=1" }
      : { gate: "exactly_one_new_commit", state: "failed", evidence: `expected 1, actual ${uniqueCount}` });
  } else {
    gates.push({ gate: "exactly_one_new_commit", state: "failed", evidence: "unable to determine expected parents for the unique-commit-count gate" });
  }

  if (actualParents.length === 2) {
    const [firstParent, secondParent] = actualParents;

    const tagObject = run(repo, ["rev-parse", "v1.61"]);
    const tagCommit = run(repo, ["rev-parse", "v1.61^{commit}"]);
    gates.push((tagObject === v161TagObject && tagCommit === v161CommitObject)
      ? { gate: "v1_61_tag_identity", state: "proved", evidence: `tag=${tagObject} commit=${tagCommit}` }
      : { gate: "v1_61_tag_identity", state: "failed", evidence: `expected tag=${v161TagObject} commit=${v161CommitObject}, actual tag=${tagObject} commit=${tagCommit}` });

    gates.push(isAncestor(repo, v161CommitObject, candidateObject)
      ? { gate: "v1_61_commit_ancestor", state: "proved", evidence: `${v161CommitObject} is an ancestor of ${candidateObject}` }
      : { gate: "v1_61_commit_ancestor", state: "failed", evidence: `${v161CommitObject} is not an ancestor of ${candidateObject}` });

    gates.push(isAncestor(repo, secondParent, candidateObject)
      ? { gate: "origin_main_ancestor", state: "proved", evidence: `${secondParent} is an ancestor of ${candidateObject}` }
      : { gate: "origin_main_ancestor", state: "failed", evidence: `${secondParent} is not an ancestor of ${candidateObject}` });

    for (const commit of closureCommits) {
      gates.push(isAncestor(repo, commit, candidateObject)
        ? { gate: `closure_commit_ancestor:${commit}`, state: "proved", evidence: `${commit} is an ancestor of ${candidateObject}` }
        : { gate: `closure_commit_ancestor:${commit}`, state: "failed", evidence: `${commit} is not an ancestor of ${candidateObject}` });
    }

    try {
      const revertedTree = proveRevertTree(repo, candidateObject);
      // D-30: compare the LIVE revert-proof result against the RECORDED
      // expected tree (`opts.expectedRevertedTree`, sourced from
      // 231-ROLLBACK-POINT.json's `expected_reverted_tree` at real-invocation
      // time) rather than against a freshly re-derived first-parent tree.
      // Comparing the revert's own output to the first parent it was just
      // computed against is tautological — for a plain scratch-clone
      // `git revert -m 1`, the resulting tree is *always* the specified
      // mainline parent's tree by construction, so that comparison can never
      // fail. Comparing against an independently recorded expectation is
      // what actually catches drift between the committed record and live
      // git state (the record is never trusted as its own authority).
      const firstParentTree = run(repo, ["rev-parse", `${firstParent}^{tree}`]);
      const expectedRevertedTree = opts.expectedRevertedTree || firstParentTree;
      gates.push(revertedTree === expectedRevertedTree
        ? { gate: "revert_proof", state: "proved", evidence: `tree=${revertedTree}` }
        : { gate: "revert_proof", state: "failed", evidence: `expected tree=${expectedRevertedTree}, actual tree=${revertedTree}` });
    } catch (error) {
      gates.push({ gate: "revert_proof", state: "failed", evidence: error.message });
    }
  }

  try {
    const missingLines = missingToolchainLines(repo, tipObject, supersededObject);
    gates.push(missingLines.length === 0
      ? { gate: "toolchain_pin", state: "proved", evidence: "all superseded .tool-versions lines are present on the candidate tip" }
      : { gate: "toolchain_pin", state: "failed", evidence: `candidate tip .tool-versions is missing line(s) present in the superseded blob: ${missingLines.join(" | ")}` });
  } catch (error) {
    gates.push({ gate: "toolchain_pin", state: "failed", evidence: error.message });
  }

  const allSatisfied = gates.every((gate) => gate.state === "proved");
  return { candidate: { object: candidateObject, tip: tipObject, parents: actualParents }, gates, allSatisfied };
}

function findGate(gates, name) { return gates.find((gate) => gate.gate === name); }
function assertGateProved(gates, name, label) {
  const gate = findGate(gates, name);
  if (!gate) fail(`${label}: gate ${name} was not evaluated`);
  if (gate.state !== "proved") fail(`${label}: ${gate.evidence}`);
}

export function applyRequireShape(gates) {
  assertGateProved(gates, "single_first_parent_merge", "recut candidate shape check failed");
  assertGateProved(gates, "exactly_one_new_commit", "recut candidate shape check failed");
}

export function applyRequireAncestry(gates) {
  assertGateProved(gates, "v1_61_tag_identity", "recut candidate ancestry check failed");
  assertGateProved(gates, "v1_61_commit_ancestor", "recut candidate ancestry check failed");
  assertGateProved(gates, "origin_main_ancestor", "recut candidate ancestry check failed");
  for (const gate of gates) if (gate.gate.startsWith("closure_commit_ancestor:") && gate.state !== "proved") fail(`recut candidate ancestry check failed: ${gate.evidence}`);
}

export function applyRequireRevertProof(gates) {
  assertGateProved(gates, "revert_proof", "recut candidate revert-proof check failed");
}

export function applyRequireToolchain(gates) {
  assertGateProved(gates, "toolchain_pin", "recut candidate toolchain check failed");
}

// WR-01: --expected-repository is required but was never compared against
// anything -- a decorative flag implying a safety property it did not
// provide, unlike its three sibling verifiers' same-named flag. There is no
// `repository` field in RECUT_RECORD_FIELDS to compare against (adding one
// would change the committed 231-ROLLBACK-POINT.json schema), so this checks
// the flag against the LIVE observed repository identity instead: the
// `origin` remote URL, normalized from either the
// `https://github.com/OWNER/NAME(.git)` or `git@github.com:OWNER/NAME(.git)`
// form. A missing/unresolvable origin remote is an explicit failure naming
// the repo path, never a silent pass.
function liveRepositoryIdentity(repo) {
  const result = spawnSync("git", ["-C", repo, "remote", "get-url", "origin"], { encoding: "utf8", shell: false, timeout: 20000 });
  if (result.error || result.status !== 0) fail(`unable to resolve the origin remote for ${repo}: ${(result.stderr || result.error?.message || "no origin remote configured").trim()}`);
  const url = result.stdout.trim();
  const httpsMatch = /^https:\/\/github\.com\/([^/]+)\/([^/]+?)(?:\.git)?\/?$/.exec(url);
  const sshMatch = /^git@github\.com:([^/]+)\/([^/]+?)(?:\.git)?$/.exec(url);
  const match = httpsMatch || sshMatch;
  if (!match) fail(`unable to parse the origin remote URL as an owner/name GitHub identity for ${repo}: ${url}`);
  return `${match[1]}/${match[2]}`;
}

export function assertExpectedRepositoryIdentity(repo, expectedRepository) {
  const observed = liveRepositoryIdentity(repo);
  if (observed !== expectedRepository) fail(`--expected-repository does not match the repository's live origin remote identity: expected ${expectedRepository}, observed ${observed} (repo=${repo})`);
}

export function applyRequireSupersession(record) {
  if (record.supersedes.candidate_object === record.candidate_object) fail("supersedes.candidate_object must differ from candidate_object");
  nonEmptyString(record.supersedes.cause, "supersedes.cause");
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

  function mergeCandidate(repo, milestoneTip, originMain, ref) {
    const g = (args) => run(repo, args);
    const tmpBranch = `recut-merge-tmp-${Math.random().toString(36).slice(2)}`;
    g(["checkout", "-q", "-B", tmpBranch, milestoneTip]);
    const merged = spawnSync("git", ["-C", repo, "merge", "--no-ff", "--no-edit", originMain], { encoding: "utf8", shell: false });
    if (merged.status !== 0) fail(`fixture merge failed: ${merged.stderr}`);
    const mergeObject = g(["rev-parse", "HEAD"]);
    if (ref) g(["branch", "-f", ref, mergeObject]);
    g(["checkout", "-q", "milestone"]);
    g(["branch", "-D", tmpBranch]);
    return mergeObject;
  }

  function fixtureGateOptions(fx, overrides = {}) {
    return {
      v161TagObject: fx.v161Tag,
      v161CommitObject: fx.v161Commit,
      closureCommits: fx.closureCommits,
      supersededObject: fx.milestoneTip,
      ...overrides
    };
  }

  // Scenario 1: clean candidate — collectRecutGates reports every gate proved.
  withFixture((fx) => {
    const mergeObject = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const collected = collectRecutGates(fixtureGateOptions(fx, {
      candidateObject: mergeObject,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain
    }), fx.repo);
    assert.equal(collected.allSatisfied, true, JSON.stringify(collected.gates.filter((g) => g.state !== "proved")));
  });

  // Scenario 2: validateRecutRecord schema controls (forbidden field, restore_argv
  // shape, and full-40-hex object id enforcement across every SHA-bearing field).
  withFixture((fx) => {
    const mergeObject = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const milestoneTree = run(fx.repo, ["rev-parse", `${fx.milestoneTip}^{tree}`]);
    const validRecord = {
      schema_version: 1,
      candidate_ref: "refs/heads/integration/v1.62-candidate",
      candidate_object: mergeObject,
      parents: { first_parent: fx.milestoneTip, second_parent: fx.originMain },
      pre_integration_refs: { "refs/heads/milestone": fx.milestoneTip, "refs/remotes/origin/main": fx.originMain },
      expected_reverted_tree: milestoneTree,
      supersedes: { candidate_object: SUPERSEDED_CANDIDATE, artifact: "230-ROLLBACK-POINT.json", cause: "the superseded candidate predated the Phase 230 verifiers" },
      toolchain_pin: { path: ".tool-versions", sha256: "a".repeat(64), matches_superseded: true },
      restore_argv: [["git", "revert", "-m", "1", "--no-edit", mergeObject]]
    };
    validateRecutRecord(structuredClone(validRecord));

    assert.throws(() => validateRecutRecord({ ...validRecord, extra_field: "x" }), /forbidden field: extra_field/);
    assert.throws(() => validateRecutRecord({ ...validRecord, restore_argv: `git revert -m 1 --no-edit ${mergeObject}` }), /array of strings/);
    assert.throws(() => validateRecutRecord({ ...validRecord, restore_argv: [["node", "revert"]] }), /first entry must be the string git/);
    assert.throws(() => validateRecutRecord({ ...validRecord, candidate_object: "not-a-sha" }), /full lowercase 40-hex/);
    assert.throws(() => validateRecutRecord({ ...validRecord, parents: { first_parent: "bad", second_parent: fx.originMain } }), /full lowercase 40-hex/);
    assert.throws(() => validateRecutRecord({ ...validRecord, expected_reverted_tree: "bad" }), /full lowercase 40-hex/);
    assert.throws(() => validateRecutRecord({ ...validRecord, supersedes: { ...validRecord.supersedes, candidate_object: "bad" } }), /full lowercase 40-hex/);
  });

  // Scenario 3: --require-shape — rebase/squash (one parent) rejected, naming
  // the observed parent count.
  withFixture((fx) => {
    fs.writeFileSync(path.join(fx.repo, "rebased.txt"), "rebased\n");
    run(fx.repo, ["add", "rebased.txt"]);
    run(fx.repo, ["commit", "-qm", "single-parent tip"]);
    const singleParentTip = run(fx.repo, ["rev-parse", "HEAD"]);
    run(fx.repo, ["reset", "-q", "--hard", fx.milestoneTip]);
    const collected = collectRecutGates(fixtureGateOptions(fx, {
      candidateObject: singleParentTip,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain
    }), fx.repo);
    assert.equal(findGate(collected.gates, "single_first_parent_merge").state, "failed");
    assert.throws(() => applyRequireShape(collected.gates), /observed parent count=1/);
  });

  // Scenario 4: --require-shape — a "second merge point" (advance-by-merging /
  // merge-back-then-recut, D-05) fails the unique-commit-count gate, printing
  // expected 1 and actual 2, even though the candidate itself still has
  // exactly two immediate parents.
  withFixture((fx) => {
    // D-05's "merge-back-then-recut": merge the ALREADY-BUILT candidate back
    // into the milestone branch with --no-ff (which forces a merge commit
    // even though milestoneTip is already an ancestor of oldCandidate — a
    // fast-forward would otherwise apply). The resulting commit still has
    // exactly two immediate parents [milestoneTip, oldCandidate], so the
    // per-commit parent-count shape gate alone cannot see anything wrong;
    // only the unique-commit-count gate — computed against the RECORDED
    // milestone-HEAD-at-cut/origin-main identity — reveals the extra
    // reachable-but-unaccounted-for commit (oldCandidate itself).
    const oldCandidate = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const secondMergePoint = mergeCandidate(fx.repo, fx.milestoneTip, oldCandidate);
    const collected = collectRecutGates(fixtureGateOptions(fx, {
      candidateObject: secondMergePoint,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain
    }), fx.repo);
    assert.equal(findGate(collected.gates, "single_first_parent_merge").state, "proved");
    assert.equal(findGate(collected.gates, "exactly_one_new_commit").state, "failed");
    assert.throws(() => applyRequireShape(collected.gates), /expected 1, actual 2/);
  });

  // Scenario 5: --require-ancestry — a wrong v1.61 tag/commit identity and a
  // missing closure commit each fail independently.
  withFixture((fx) => {
    const mergeObject = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const wrongTagOptions = fixtureGateOptions(fx, {
      candidateObject: mergeObject,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain,
      v161CommitObject: "f".repeat(40)
    });
    const collectedWrongTag = collectRecutGates(wrongTagOptions, fx.repo);
    assert.equal(findGate(collectedWrongTag.gates, "v1_61_tag_identity").state, "failed");
    assert.throws(() => applyRequireAncestry(collectedWrongTag.gates), /expected tag=|expected commit=/);

    const missingClosureOptions = fixtureGateOptions(fx, {
      candidateObject: mergeObject,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain,
      closureCommits: [...fx.closureCommits.slice(0, 3), "e".repeat(40)]
    });
    const collectedMissingClosure = collectRecutGates(missingClosureOptions, fx.repo);
    assert.ok(collectedMissingClosure.gates.some((gate) => gate.gate === `closure_commit_ancestor:${"e".repeat(40)}` && gate.state === "failed"));
    assert.throws(() => applyRequireAncestry(collectedMissingClosure.gates), /is not an ancestor/);
  });

  // Scenario 6: --require-revert-proof — a positive control (the live revert
  // result matches the RECORDED expected tree) and a negative control (a
  // stale/tampered `expected_reverted_tree` that no longer matches the live
  // repository). A plain scratch-clone `git revert -m 1` on a genuine
  // two-parent merge always reproduces its own mainline parent's tree by
  // construction, so the only way this gate can meaningfully fail is by
  // comparing against an INDEPENDENTLY RECORDED expectation, not a value
  // re-derived from the same live parent the revert just used.
  withFixture((fx) => {
    const mergeObject = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const milestoneTree = run(fx.repo, ["rev-parse", `${fx.milestoneTip}^{tree}`]);
    const collectedOk = collectRecutGates(fixtureGateOptions(fx, {
      candidateObject: mergeObject,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain,
      expectedRevertedTree: milestoneTree
    }), fx.repo);
    assert.equal(findGate(collectedOk.gates, "revert_proof").state, "proved");
    applyRequireRevertProof(collectedOk.gates);

    const collectedStale = collectRecutGates(fixtureGateOptions(fx, {
      candidateObject: mergeObject,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain,
      expectedRevertedTree: "f".repeat(40)
    }), fx.repo);
    assert.equal(findGate(collectedStale.gates, "revert_proof").state, "failed");
    assert.throws(() => applyRequireRevertProof(collectedStale.gates), /expected tree=/);
  });

  // Scenario 7: --require-toolchain — a candidate tip missing the Elixir line
  // present in the superseded blob is rejected.
  withFixture((fx) => {
    const mergeObject = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    run(fx.repo, ["checkout", "-q", "-B", "recut-toolchain-tmp", mergeObject]);
    fs.writeFileSync(path.join(fx.repo, ".tool-versions"), "nodejs 22.14.0\n");
    run(fx.repo, ["add", ".tool-versions"]);
    run(fx.repo, ["commit", "-qm", "regressed toolchain pin"]);
    const regressedTip = run(fx.repo, ["rev-parse", "HEAD"]);
    run(fx.repo, ["checkout", "-q", "milestone"]);
    run(fx.repo, ["branch", "-D", "recut-toolchain-tmp"]);
    const collected = collectRecutGates(fixtureGateOptions(fx, {
      candidateObject: mergeObject,
      tipRef: regressedTip,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain
    }), fx.repo);
    assert.equal(findGate(collected.gates, "toolchain_pin").state, "failed");
    assert.throws(() => applyRequireToolchain(collected.gates), /missing line\(s\)/);
  });

  // Scenario 8: --require-supersession — same candidate object, and an empty cause.
  {
    const record = { candidate_object: "a".repeat(40), supersedes: { candidate_object: "a".repeat(40), artifact: "230-ROLLBACK-POINT.json", cause: "x" } };
    assert.throws(() => applyRequireSupersession(record), /must differ from candidate_object/);
    const emptyCause = { candidate_object: "a".repeat(40), supersedes: { candidate_object: "b".repeat(40), artifact: "230-ROLLBACK-POINT.json", cause: "" } };
    assert.throws(() => applyRequireSupersession(emptyCause), /non-empty string/);
    const okRecord = { candidate_object: "a".repeat(40), supersedes: { candidate_object: "b".repeat(40), artifact: "230-ROLLBACK-POINT.json", cause: "real cause" } };
    applyRequireSupersession(okRecord);
  }

  // Scenario 9a (WR-01): --expected-repository is checked against the live
  // origin remote identity, not just required-but-ignored. A matching value
  // passes; a mismatched value fails, naming both the observed and expected
  // repository. Covers both the https://github.com/OWNER/NAME(.git) and
  // git@github.com:OWNER/NAME(.git) origin URL forms.
  {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-recut-identity-fixture-"));
    const repo = path.join(scratch, "repo");
    try {
      fs.mkdirSync(repo);
      run(repo, ["init", "-q", "-b", "main"]);
      run(repo, ["config", "user.email", "phase231@example.invalid"]);
      run(repo, ["config", "user.name", "Phase 231"]);
      run(repo, ["remote", "add", "origin", "https://github.com/szTheory/accrue.git"]);
      assertExpectedRepositoryIdentity(repo, "szTheory/accrue");
      assert.throws(() => assertExpectedRepositoryIdentity(repo, "someone-else/not-accrue"), /expected someone-else\/not-accrue, observed szTheory\/accrue/);

      run(repo, ["remote", "set-url", "origin", "git@github.com:szTheory/accrue.git"]);
      assertExpectedRepositoryIdentity(repo, "szTheory/accrue");
      assert.throws(() => assertExpectedRepositoryIdentity(repo, "someone-else/not-accrue"), /expected someone-else\/not-accrue, observed szTheory\/accrue/);

      run(repo, ["remote", "remove", "origin"]);
      assert.throws(() => assertExpectedRepositoryIdentity(repo, "szTheory/accrue"), /unable to resolve the origin remote/);
    } finally {
      fs.rmSync(scratch, { recursive: true, force: true });
    }
  }

  // Scenario 9: no worktree row is created anywhere in this suite (D-07, D-12).
  withFixture((fx) => {
    const before = run(fx.repo, ["worktree", "list"]);
    const mergeObject = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    collectRecutGates(fixtureGateOptions(fx, {
      candidateObject: mergeObject,
      firstParent: fx.milestoneTip,
      secondParent: fx.originMain
    }), fx.repo);
    const after = run(fx.repo, ["worktree", "list"]);
    assert.equal(before, after, "collectRecutGates must not create a git worktree row");
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
  assertExpectedRepositoryIdentity(repo, expectedRepository);
  const recordPath = parsed.values.record || defaultRecordPath();
  const record = validateRecutRecord(JSON.parse(fs.readFileSync(recordPath, "utf8")));
  if (parsed.values.candidate) {
    const ref = parsed.values.candidate.startsWith("refs/") ? parsed.values.candidate : `refs/heads/${parsed.values.candidate}`;
    if (ref !== record.candidate_ref) fail("--candidate does not match the recorded candidate_ref");
  }

  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
  const needsGates = parsed.flags.has("require-shape") || parsed.flags.has("require-ancestry") || parsed.flags.has("require-revert-proof") || parsed.flags.has("require-toolchain");
  if (needsGates) {
    const collected = collectRecutGates({
      candidateObject: record.candidate_object,
      tipRef: record.candidate_ref,
      firstParent: record.parents.first_parent,
      secondParent: record.parents.second_parent,
      expectedRevertedTree: record.expected_reverted_tree
    }, repo);
    if (parsed.flags.has("require-shape")) applyRequireShape(collected.gates);
    if (parsed.flags.has("require-ancestry")) applyRequireAncestry(collected.gates);
    if (parsed.flags.has("require-revert-proof")) applyRequireRevertProof(collected.gates);
    if (parsed.flags.has("require-toolchain")) applyRequireToolchain(collected.gates);
  }
  if (parsed.flags.has("require-supersession")) applyRequireSupersession(record);

  const verificationSuffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")})`
    : " (schema-only: no strict flags supplied, no shape or ancestry check ran)";
  console.log(`recut candidate verification: PASS${verificationSuffix}`);
}

// Only run as CLI/test entrypoint when this file is the invoked script — an
// `import` from another module (e.g. a script asserting these four exports
// exist) must not trigger main()/verifyFixtures() as a side effect.
const isMainModule = process.argv[1] === new URL(import.meta.url).pathname;
if (isMainModule && process.env.NODE_TEST_CONTEXT) {
  test("recut candidate fixtures pass every negative control", () => verifyFixtures());
} else if (isMainModule) {
  try { main(); } catch (error) { console.error(`recut candidate verify: FAIL: ${error.message}`); process.exitCode = 1; }
}
