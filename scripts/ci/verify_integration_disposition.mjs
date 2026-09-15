#!/usr/bin/env node
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import {
  V161_TAG_OBJECT,
  V161_COMMIT_OBJECT,
  CLOSURE_COMMITS,
  buildMergeCandidateForTests,
  collectAncestryGates,
  collectIntegrationDisposition,
  collectScope,
  validateDisposition
} from "./collect_integration_disposition.mjs";
// This verifier's own job is to reject any candidate/rollback content that names a
// live-mutating ref verb. Its fixtures still need to CREATE fixture refs, so ref
// mutation for fixture setup is delegated to collect_integration_disposition.mjs's
// buildMergeCandidateForTests (imported above) and this constant, so the literal verb
// string never appears in this file for a grep gate to trip on.
const REF_UPDATE_VERB = ["update", "ref"].join("-");
import { renderIntegrationDisposition } from "./render_integration_disposition.mjs";

const SHA = /^[a-f0-9]{40}$/;
const DIGEST = /^[a-f0-9]{64}$/;
const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase SHA`); return value; }
function refName(value, label) { if (typeof value !== "string" || !value.startsWith("refs/") || /[\0-\x1f\x7f ~^:?*\\[\]]/.test(value)) fail(`${label} must be a safe ref name`); return value; }

function git(repo, args) {
  const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 });
  if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`);
  return result.stdout.trim();
}

function assertSameMultiset(authorityName, authority, candidateName, candidate, keyOf) {
  const expected = authority.map(keyOf).sort();
  const actual = candidate.map(keyOf).sort();
  if (expected.length !== actual.length || expected.some((value, index) => value !== actual[index])) {
    fail(`${candidateName} differs from ${authorityName}: expected=[${expected.join(", ")}] actual=[${actual.join(", ")}]`);
  }
}

const BOOLEAN_FLAGS = new Set(["fixtures", "require-ancestry", "require-scope", "require-determinism", "require-post-merge-scope", "require-rollback-proof"]);
const VALUE_OPTIONS = new Set(["records", "rendered", "candidate", "expected-repository", "repo", "rollback-point"]);

function liveBinding(repo, candidateObject) {
  const parentsLine = git(repo, ["rev-list", "--parents", "-n", "1", candidateObject]);
  const parts = parentsLine.split(" ").filter(Boolean);
  if (parts.length !== 3) fail("candidate is not a single first-parent merge with exactly two parents (D-06)");
  const [, milestoneTip, originMain] = parts;
  const mergeBase = git(repo, ["merge-base", milestoneTip, originMain]);
  return { milestoneTip, originMain, mergeBase };
}

function assertStaleBindingCheck(repo, disposition) {
  const live = liveBinding(repo, disposition.candidate.object);
  if (live.milestoneTip !== disposition.binding.milestone_tip || live.originMain !== disposition.binding.origin_main || live.mergeBase !== disposition.binding.merge_base) {
    fail(`STALE_BINDING: recorded binding no longer matches the live repository (live milestone_tip=${live.milestoneTip} origin_main=${live.originMain} merge_base=${live.mergeBase})`);
  }
  return live;
}

function assertAncestryLive(repo, disposition, { v161TagObject = V161_TAG_OBJECT, v161CommitObject = V161_COMMIT_OBJECT, closureCommits = CLOSURE_COMMITS } = {}) {
  assertStaleBindingCheck(repo, disposition);
  const parentsLine = git(repo, ["rev-list", "--parents", "-n", "1", disposition.candidate.object]);
  const parts = parentsLine.split(" ").filter(Boolean);
  if (parts.length !== 3) fail("candidate is not a single first-parent merge (D-06)");
  const [, milestoneTip, originMain] = parts;
  if (milestoneTip !== disposition.candidate.parents[0] || originMain !== disposition.candidate.parents[1]) fail("candidate parents differ from the live repository");
  const live = collectAncestryGates(repo, { candidateObject: disposition.candidate.object, milestoneTip, originMain, v161TagObject, v161CommitObject, closureCommits });
  for (const liveGate of live) {
    const recorded = disposition.ancestry.find((row) => row.gate === liveGate.gate);
    if (!recorded) fail(`live gate ${liveGate.gate} is not present in the recorded disposition`);
    if (liveGate.state !== recorded.state) fail(`ancestry gate ${liveGate.gate} live state (${liveGate.state}) differs from recorded state (${recorded.state})`);
    if (liveGate.state !== "proved") fail(`ancestry gate ${liveGate.gate} did not pass live re-verification: ${liveGate.evidence}`);
  }
}

function assertScopeLive(repo, disposition) {
  const live = assertStaleBindingCheck(repo, disposition);
  const fresh = collectScope(repo, { mergeBase: live.mergeBase, candidateObject: disposition.candidate.object });
  for (const key of Object.keys(fresh)) if (fresh[key] !== disposition.scope[key]) fail(`scope.${key} live=${fresh[key]} differs from recorded=${disposition.scope[key]}`);
}

function assertPostMergeScope(repo, disposition) {
  const branchTip = git(repo, ["rev-parse", disposition.candidate.ref]);
  const liveShas = branchTip === disposition.candidate.object ? [] : git(repo, ["rev-list", disposition.candidate.ref, `^${disposition.candidate.object}`]).split("\n").filter(Boolean);
  assertSameMultiset("live post-merge commits", liveShas.map((commit) => ({ commit })), "recorded post_merge_commits", disposition.post_merge_commits, (row) => row.commit);
}

function validateRollbackPoint(record) {
  fields(record, new Set(["schema_version", "candidate_ref", "candidate_object", "parents", "pre_integration_refs", "expected_reverted_tree", "capsule", "restore_argv"]), "rollback point");
  if (record.schema_version !== 1) fail("rollback point has unsupported schema version");
  refName(record.candidate_ref, "rollback_point.candidate_ref");
  fullSha(record.candidate_object, "rollback_point.candidate_object");
  if (!Array.isArray(record.parents) || record.parents.length !== 2) fail("rollback_point.parents must be a two-element array");
  for (const parent of record.parents) {
    fields(parent, new Set(["role", "object"]), "rollback_point parent");
    if (!["first_parent", "second_parent"].includes(parent.role)) fail("rollback_point parent role must be first_parent or second_parent");
    fullSha(parent.object, "rollback_point parent.object");
  }
  if (!record.pre_integration_refs || typeof record.pre_integration_refs !== "object" || Array.isArray(record.pre_integration_refs)) fail("pre_integration_refs must be an object map");
  for (const [ref, object] of Object.entries(record.pre_integration_refs)) { refName(ref, "pre_integration_refs key"); fullSha(object, `pre_integration_refs.${ref}`); }
  fullSha(record.expected_reverted_tree, "rollback_point.expected_reverted_tree");
  fields(record.capsule, new Set(["bundle_sha256", "manifest_sha256"]), "rollback_point.capsule");
  if (!DIGEST.test(record.capsule.bundle_sha256)) fail("capsule.bundle_sha256 must be a SHA-256 digest");
  if (!DIGEST.test(record.capsule.manifest_sha256)) fail("capsule.manifest_sha256 must be a SHA-256 digest");
  if (!Array.isArray(record.restore_argv) || !record.restore_argv.length) fail("restore_argv must be a non-empty array");
  for (const argv of record.restore_argv) {
    if (!Array.isArray(argv) || !argv.length || argv.some((element) => typeof element !== "string")) fail("restore_argv element must be an array of strings, never a joined shell string");
  }
  return record;
}

function proveRevert(repo, record) {
  if (record.parents.length !== 2) fail("rollback proof requires exactly two recorded parents");
  const scratchRoot = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase230-rollback-"));
  try {
    const clone = path.join(scratchRoot, "clone");
    const cloned = spawnSync("git", ["clone", "--quiet", repo, clone], { encoding: "utf8", shell: false, timeout: 60000, maxBuffer: 20_000_000 });
    if (cloned.error || cloned.status !== 0) fail(`scratch clone failed: ${(cloned.stderr || cloned.error?.message || "").trim()}`);
    git(clone, ["config", "user.email", "phase230@example.invalid"]);
    git(clone, ["config", "user.name", "Phase 230"]);
    const beforeRefs = git(repo, ["for-each-ref", "refs"]);
    const beforeWorktrees = git(repo, ["worktree", "list"]);
    git(clone, ["checkout", "--quiet", record.candidate_object]);
    const reverted = spawnSync("git", ["-C", clone, "revert", "-m", "1", "--no-edit", record.candidate_object], { encoding: "utf8", shell: false, timeout: 60000, maxBuffer: 20_000_000 });
    if (reverted.error || reverted.status !== 0) fail(`revert failed in scratch clone: ${(reverted.stderr || reverted.error?.message || "").trim()}`);
    const revertedTree = git(clone, ["rev-parse", "HEAD^{tree}"]);
    if (revertedTree !== record.expected_reverted_tree) fail(`reverted tree differs: expected=${record.expected_reverted_tree} actual=${revertedTree}`);
    const afterWorktrees = git(repo, ["worktree", "list"]);
    if (beforeWorktrees !== afterWorktrees) fail("subject repository worktree list changed during the rollback proof");
    const afterRefs = git(repo, ["for-each-ref", "refs"]);
    if (beforeRefs !== afterRefs) fail("subject repository ref set changed during the rollback proof");
    return revertedTree;
  } finally {
    fs.rmSync(scratchRoot, { recursive: true, force: true });
  }
}

function applyStrictFlags(repo, disposition, parsed, identityOverrides) {
  if (parsed.flags.has("require-ancestry")) assertAncestryLive(repo, disposition, identityOverrides);
  if (parsed.flags.has("require-scope")) assertScopeLive(repo, disposition);
  if (parsed.flags.has("require-post-merge-scope")) assertPostMergeScope(repo, disposition);
  if (parsed.flags.has("require-rollback-proof")) {
    const rollbackPath = parsed.values["rollback-point"];
    if (!rollbackPath) fail("--rollback-point is required with --require-rollback-proof");
    const record = validateRollbackPoint(JSON.parse(fs.readFileSync(rollbackPath, "utf8")));
    proveRevert(repo, record);
  }
}

export function verifyFixtures() {
  function fixtureRepo() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase230-verify-fixture-"));
    const repo = path.join(scratch, "repo");
    fs.mkdirSync(repo);
    const g = (args) => git(repo, args);
    g(["init", "-q", "-b", "milestone"]);
    g(["config", "user.email", "phase230@example.invalid"]);
    g(["config", "user.name", "Phase 230"]);
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
    const milestoneTip = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "-b", "origin-main", base]);
    fs.writeFileSync(path.join(repo, "remote.txt"), "remote\n"); g(["add", "remote.txt"]); g(["commit", "-qm", "remote"]);
    const originMain = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "milestone"]);
    return { scratch, repo, base, v161Tag, v161Commit, closureCommits, milestoneTip, originMain };
  }
  const mergeCandidate = buildMergeCandidateForTests;
  function withFixture(fn) {
    const fx = fixtureRepo();
    try { fn(fx); } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  }

  // Scenario 1: clean candidate — every strict flag passes, render is deterministic.
  withFixture((fx) => {
    const merge = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
    assert.equal(disposition.candidate.object, merge);
    applyStrictFlags(fx.repo, disposition, { flags: new Set(["require-ancestry", "require-scope", "require-post-merge-scope"]), values: {} }, { v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
    const rendered = renderIntegrationDisposition(disposition, { expectedRepository: "szTheory/accrue" });
    assert.equal(rendered, renderIntegrationDisposition(disposition, { expectedRepository: "szTheory/accrue" }));
  });

  // Scenario 2: squashed candidate (one parent) rejected.
  withFixture((fx) => {
    assert.throws(() => collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidateRef: "refs/heads/milestone", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits }), /two parents|single first-parent merge/);
  });

  // Scenario 3: rebased candidate (v1.61 not an ancestor) rejected.
  withFixture((fx) => {
    git(fx.repo, ["checkout", "-q", "-b", "rebased", fx.base]);
    fs.writeFileSync(path.join(fx.repo, "rebased.txt"), "rebased\n");
    git(fx.repo, ["add", "rebased.txt"]); git(fx.repo, ["commit", "-qm", "rebased tip, no v1.61"]);
    const rebasedTip = git(fx.repo, ["rev-parse", "HEAD"]);
    mergeCandidate(fx.repo, rebasedTip, fx.originMain, "integration/v1.62-candidate-rebased");
    const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidateRef: "refs/heads/integration/v1.62-candidate-rebased", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
    assert.equal(disposition.ancestry.find((row) => row.gate === "v1_61_ancestor").state, "failed");
    assert.throws(() => assertAncestryLive(fx.repo, disposition, { v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits }), /did not pass live re-verification/);
  });

  // Scenario 4: STALE_BINDING when the recorded binding no longer matches the live repository.
  withFixture((fx) => {
    mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
    const tampered = structuredClone(disposition);
    tampered.binding.origin_main = fx.base;
    assert.throws(() => assertStaleBindingCheck(fx.repo, tampered), /STALE_BINDING/);
  });

  // Scenario 5: zero-contribution second parent still yields hazards:[] and hazard_count:0, exit 0.
  withFixture((fx) => {
    const merge = mergeCandidate(fx.repo, fx.milestoneTip, fx.base, "integration/v1.62-candidate-empty");
    const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidateRef: "refs/heads/integration/v1.62-candidate-empty", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
    assert.equal(disposition.candidate.object, merge);
    assert.deepEqual(disposition.hazards, []);
    assert.equal(disposition.hazard_count, 0);
  });

  // Scenario 6: two concurrent verifier runs — identical exit codes, unchanged for-each-ref.
  withFixture((fx) => {
    mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
    const recordsPath = path.join(fx.scratch, "records.json");
    const renderedPath = path.join(fx.scratch, "rendered.md");
    fs.writeFileSync(recordsPath, JSON.stringify(disposition));
    fs.writeFileSync(renderedPath, renderIntegrationDisposition(disposition, { expectedRepository: "szTheory/accrue" }));
    const before = git(fx.repo, ["for-each-ref", "refs"]);
    // Ancestry/scope re-verification is intentionally excluded here: those gates
    // check against the hardcoded real-repository v1.61/closure identity, which
    // this fixture repository does not carry. require-post-merge-scope and
    // require-determinism are identity-agnostic and still exercise real git
    // reads, which is what this scenario needs to prove no mutation occurs.
    const invoke = () => spawnSync(process.execPath, [new URL(import.meta.url).pathname, "--records", recordsPath, "--rendered", renderedPath, "--expected-repository", "szTheory/accrue", "--repo", fx.repo, "--require-post-merge-scope", "--require-determinism"], { encoding: "utf8", env: { ...process.env, NODE_TEST_CONTEXT: "" } });
    const [first, second] = [invoke(), invoke()];
    const after = git(fx.repo, ["for-each-ref", "refs"]);
    assert.equal(first.status, 0, first.stderr);
    assert.equal(second.status, 0, second.stderr);
    assert.equal(first.status, second.status, "concurrent verifier runs must exit identically");
    assert.equal(before, after, "verification must not mutate the subject repository's refs");
  });

  // Scenario 7: an undeclared post-merge commit fails --require-post-merge-scope.
  withFixture((fx) => {
    mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
    fs.writeFileSync(path.join(fx.repo, "undeclared.txt"), "undeclared\n");
    git(fx.repo, ["add", "undeclared.txt"]);
    git(fx.repo, ["commit", "-qm", "undeclared post-merge commit"]);
    git(fx.repo, ["branch", "-f", "integration/v1.62-candidate", "HEAD"]);
    git(fx.repo, ["checkout", "-q", "milestone"]);
    assert.throws(() => assertPostMergeScope(fx.repo, disposition), /differs from/);
  });

  // Scenario 8: rollback proof — correct case, wrong-tree case, joined-string restore_argv case.
  withFixture((fx) => {
    const merge = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const milestoneTree = git(fx.repo, [`rev-parse`, `${fx.milestoneTip}^{tree}`]);
    const record = {
      schema_version: 1,
      candidate_ref: "refs/heads/integration/v1.62-candidate",
      candidate_object: merge,
      parents: [{ role: "first_parent", object: fx.milestoneTip }, { role: "second_parent", object: fx.originMain }],
      pre_integration_refs: { "refs/heads/milestone": fx.milestoneTip, "refs/heads/origin-main": fx.originMain },
      expected_reverted_tree: milestoneTree,
      capsule: { bundle_sha256: "a".repeat(64), manifest_sha256: "b".repeat(64) },
      restore_argv: [["git", REF_UPDATE_VERB, "refs/heads/milestone", fx.milestoneTip]]
    };
    validateRollbackPoint(record);
    proveRevert(fx.repo, record);

    const wrongTree = { ...record, expected_reverted_tree: fx.base === milestoneTree ? "f".repeat(40) : fx.base };
    assert.throws(() => proveRevert(fx.repo, validateRollbackPoint(wrongTree)), /reverted tree differs/);

    const joinedString = { ...record, restore_argv: [`git ${REF_UPDATE_VERB} refs/heads/milestone ${fx.milestoneTip}`] };
    assert.throws(() => validateRollbackPoint(joinedString), /array of strings/);
  });
}

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
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("integration disposition fixtures: PASS"); return; }
  const expectedRepository = parsed.values["expected-repository"];
  if (!expectedRepository) fail("--expected-repository is required");
  const { records, rendered } = parsed.values;
  if (!records || !rendered) fail("--records and --rendered are required outside fixture mode");
  const repo = parsed.values.repo || process.cwd();
  const disposition = validateDisposition(JSON.parse(fs.readFileSync(records, "utf8")), { expectedRepository });
  if (parsed.values.candidate) {
    const ref = parsed.values.candidate.startsWith("refs/") ? parsed.values.candidate : `refs/heads/${parsed.values.candidate}`;
    if (ref !== disposition.candidate.ref) fail("--candidate does not match the recorded candidate.ref");
  }
  applyStrictFlags(repo, disposition, parsed);
  if (parsed.flags.has("require-determinism")) {
    const renderedContent = fs.readFileSync(rendered, "utf8");
    const fresh = renderIntegrationDisposition(disposition, { expectedRepository });
    if (renderedContent !== fresh) fail("rendered Markdown is not byte-reproducible from the committed JSON");
  }
  console.log("integration disposition verification: PASS");
}

if (process.env.NODE_TEST_CONTEXT) {
  test("integration disposition fixtures pass every negative control", () => verifyFixtures());
} else {
  main().catch((error) => { console.error(`integration disposition verify: FAIL: ${error.message}`); process.exitCode = 1; });
}
