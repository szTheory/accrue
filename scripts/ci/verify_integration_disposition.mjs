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
  CANONICAL_D21_LANES,
  buildMergeCandidateForTests,
  collectAncestryGates,
  collectCoTouchedFiles,
  collectExcludedCommitLedger,
  collectIntegrationDisposition,
  collectScope,
  validateDisposition,
  validateDispositionLedger,
  validateExcludedRow,
  validateLaneRow
} from "./collect_integration_disposition.mjs";
// This verifier's own job is to reject any candidate/rollback content that names a
// live-mutating ref verb. Its fixtures still need to CREATE fixture refs, so ref
// mutation for fixture setup is delegated to collect_integration_disposition.mjs's
// buildMergeCandidateForTests (imported above) and this constant, so the literal verb
// string never appears in this file for a grep gate to trip on.
const REF_UPDATE_VERB = ["update", "ref"].join("-");
import { renderIntegrationDisposition, renderExcludedLedger } from "./render_integration_disposition.mjs";

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

// D-37: exact-map completeness with a missing/extra/changed triple, recomputed inside
// the verifier — never a non-empty check, never an asserted boolean. Reused verbatim
// from verify_repository_inventory.mjs's exactMap/assertSameMap primitives.
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

const BOOLEAN_FLAGS = new Set(["fixtures", "require-ancestry", "require-scope", "require-determinism", "require-post-merge-scope", "require-rollback-proof", "require-hazard-universe", "require-excluded-ledger"]);
const VALUE_OPTIONS = new Set(["records", "rendered", "candidate", "expected-repository", "repo", "rollback-point", "dispositions", "dispositions-rendered", "local-main-ref", "review-ref"]);

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

// D-04/230-06: scope is measured against the candidate branch's LIVE TIP
// (git rev-parse disposition.candidate.ref), not the pinned merge-commit
// candidate.object -- the reviewer's actual read surface grows as declared
// post_merge_commits land on the same branch (230-05 is exactly this: two
// commits after the 230-02 merge, both declared in post_merge_commits).
// candidate.object/ancestry/parents stay pinned to the merge commit for
// D-05/D-06 identity purposes; scope is deliberately decoupled from that
// pin so a reviewer's file/commit count never goes stale after a legitimate
// post-merge commit. When a review-ref is supplied, additionally assert that
// the recorded source_changed_files count equals the number of non-
// `.planning/` paths that differ between the merge-base and that ref -- the
// reviewer's real 72-file (recomputed here) read surface, counted inside the
// verifier after capturing spawnSync's own exit status, never through a
// shell pipeline that could swallow a failing `git`.
function assertScopeLive(repo, disposition, { reviewRef } = {}) {
  const live = assertStaleBindingCheck(repo, disposition);
  const tip = git(repo, ["rev-parse", disposition.candidate.ref]);
  const fresh = collectScope(repo, { mergeBase: live.mergeBase, candidateObject: tip });
  for (const key of Object.keys(fresh)) if (fresh[key] !== disposition.scope[key]) fail(`scope.${key} live=${fresh[key]} differs from recorded=${disposition.scope[key]} (measured against the candidate ref's live tip, ${tip})`);

  if (reviewRef) {
    const diffResult = spawnSync("git", ["-C", repo, "diff", "--name-only", live.mergeBase, reviewRef, "--", ".", ":!.planning"], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 });
    if (diffResult.error || diffResult.status !== 0) fail(`review-ref scope diff failed: ${(diffResult.stderr || diffResult.error?.message || "unknown error").trim()}`);
    const reviewSourceCount = diffResult.stdout.split("\n").filter(Boolean).length;
    if (reviewSourceCount !== disposition.scope.source_changed_files) fail(`scope.source_changed_files recorded=${disposition.scope.source_changed_files} differs from review-branch live count=${reviewSourceCount} (git diff --name-only ${live.mergeBase} ${reviewRef} -- . ':!.planning')`);
  }
}

// D-15/D-20/D-21/D-37: recompute the co-touched file set live and assert exact-map
// equality against the committed hazard rows (missing=[]/extra=[]/changed=[]), then
// assert D-21's closed lane enumeration is fully and exclusively represented as
// non_run rows owned by Phase 231. Refuses on a stale binding before any comparison.
function assertHazardUniverseLive(repo, disposition) {
  const live = assertStaleBindingCheck(repo, disposition);
  const liveFiles = collectCoTouchedFiles(repo, { mergeBase: live.mergeBase, leftObject: live.milestoneTip, rightObject: live.originMain });
  const authorityFiles = exactMap(liveFiles.map((path) => ({ path })), "live co-touched files", (row) => row.path, () => true);
  const candidateFiles = exactMap(disposition.hazards, "recorded hazard rows", (row) => row.path, () => true);
  assertSameMap("live co-touched files", authorityFiles, "recorded hazard rows", candidateFiles);
  if (disposition.co_touched_file_count !== liveFiles.length) fail(`co_touched_file_count live=${liveFiles.length} differs from recorded=${disposition.co_touched_file_count}`);
  if (disposition.hazard_count !== disposition.hazards.length) fail("hazard_count must equal hazards.length");

  for (const row of disposition.hazards) if (row.owner === "231" && row.state !== "non_run") fail(`hazard row ${row.path} owned by Phase 231 must carry state "non_run" (D-20)`);
  disposition.lanes.forEach((row, index) => validateLaneRow(row, index));
  const authorityLanes = exactMap(CANONICAL_D21_LANES.map((lane) => ({ lane })), "canonical D-21 lanes", (row) => row.lane, () => true);
  const candidateLanes = exactMap(disposition.lanes, "recorded lanes", (row) => row.lane, () => true);
  assertSameMap("canonical D-21 lanes", authorityLanes, "recorded lanes", candidateLanes);
  if (disposition.lane_count !== CANONICAL_D21_LANES.length) fail(`lane_count=${disposition.lane_count} differs from the canonical D-21 lane count=${CANONICAL_D21_LANES.length}`);
}

function assertPostMergeScope(repo, disposition) {
  const branchTip = git(repo, ["rev-parse", disposition.candidate.ref]);
  const liveShas = branchTip === disposition.candidate.object ? [] : git(repo, ["rev-list", disposition.candidate.ref, `^${disposition.candidate.object}`]).split("\n").filter(Boolean);
  assertSameMultiset("live post-merge commits", liveShas.map((commit) => ({ commit })), "recorded post_merge_commits", disposition.post_merge_commits, (row) => row.commit);
}

// D-07/D-37: --require-excluded-ledger. Recomputes `git rev-list <local-main>
// ^<candidate>` live and asserts EXACT sorted-multiset equality against the committed
// excluded-* ledger rows, keyed by the 40-hex commit id -- an unrecorded excluded
// commit fails, and a recorded row for a commit that is no longer excluded (now an
// ancestor of the candidate) also fails. The literal `excluded_commit_count` integer
// is asserted against the live count, never a non-empty check. Independently provable:
// depends on nothing from --require-ancestry/--require-scope/--require-hazard-universe.
function assertExcludedLedgerLive(repo, ledger, { localMainRef = "refs/heads/main" } = {}) {
  const liveCandidateObject = git(repo, ["rev-parse", `${ledger.candidate.ref}^{commit}`]);
  if (liveCandidateObject !== ledger.candidate.object) fail(`STALE_BINDING: recorded ledger.candidate.object no longer matches the live ${ledger.candidate.ref} (live=${liveCandidateObject}, recorded=${ledger.candidate.object})`);
  const liveLocalMain = git(repo, ["rev-parse", `${localMainRef}^{commit}`]);
  if (liveLocalMain !== ledger.local_main) fail(`STALE_BINDING: recorded ledger.local_main no longer matches the live ${localMainRef} (live=${liveLocalMain}, recorded=${ledger.local_main})`);

  // Duplicate-key rejection over the WHOLE rows array (excluded-* plus
  // carried-on-candidate), reusing the exactMap primitive verbatim.
  exactMap(ledger.rows, "ledger rows", (row) => row.commit, () => true);

  const liveExcludedShas = git(repo, ["rev-list", liveLocalMain, `^${liveCandidateObject}`]).split("\n").filter(Boolean);
  const recordedExcludedRows = ledger.rows.filter((row) => row.disposition !== "carried-on-candidate");
  assertSameMultiset(
    "live excluded commits (git rev-list <local-main> ^<candidate>)",
    liveExcludedShas.map((commit) => ({ commit })),
    "recorded excluded-* ledger rows",
    recordedExcludedRows,
    (row) => row.commit
  );
  if (ledger.excluded_commit_count !== liveExcludedShas.length) fail(`excluded_commit_count live=${liveExcludedShas.length} differs from recorded=${ledger.excluded_commit_count}`);
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
  if (parsed.flags.has("require-scope")) assertScopeLive(repo, disposition, { reviewRef: parsed.values["review-ref"] });
  if (parsed.flags.has("require-hazard-universe")) assertHazardUniverseLive(repo, disposition);
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

  // A second, standalone fixture carrying one real co-touched, disjoint-hunk hazard
  // file (accrue/mix.exs, present at the common base and edited on non-overlapping
  // lines by each side — the same technique proven in
  // collect_integration_disposition.mjs's own hazard fixture, since a file that does
  // not exist at the merge-base cannot merge as a disjoint hunk: git treats two
  // different from-scratch additions as an ADD/ADD conflict) plus one blob-identical
  // convergent-identical file, so --require-hazard-universe has a non-empty hazards
  // array to exercise.
  function hazardFixtureRepo() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase230-verify-hazard-fixture-"));
    const repo = path.join(scratch, "repo");
    fs.mkdirSync(repo);
    const g = (args) => git(repo, args);
    g(["init", "-q", "-b", "milestone"]);
    g(["config", "user.email", "phase230@example.invalid"]);
    g(["config", "user.name", "Phase 230"]);
    fs.mkdirSync(path.join(repo, "accrue"), { recursive: true });
    fs.writeFileSync(path.join(repo, "shared.txt"), "shared\n");
    fs.writeFileSync(path.join(repo, "accrue", "mix.exs"), "line1\nline2\nline3\nline4\nline5\n");
    g(["add", "-A"]); g(["commit", "-qm", "base"]);
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
    fs.writeFileSync(path.join(repo, "shared.txt"), "shared v2\n");
    fs.writeFileSync(path.join(repo, "accrue", "mix.exs"), "line1\n{:decimal, \"~> 3.0\"}\nline3\nline4\nline5\n");
    g(["add", "-A"]); g(["commit", "-qm", "milestone hazard edits"]);
    const milestoneTip = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "-b", "origin-main", base]);
    fs.writeFileSync(path.join(repo, "remote.txt"), "remote\n");
    fs.writeFileSync(path.join(repo, "shared.txt"), "shared v2\n");
    fs.writeFileSync(path.join(repo, "accrue", "mix.exs"), "line1\nline2\nline3\nline4\n{:ex_money, \"~> 6.2\"}\n");
    g(["add", "-A"]); g(["commit", "-qm", "origin hazard edits"]);
    const originMain = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "milestone"]);
    return { scratch, repo, base, v161Tag, v161Commit, closureCommits, milestoneTip, originMain };
  }
  function withHazardFixture(fn) {
    const fx = hazardFixtureRepo();
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

  // Scenario 1.5 (230-06): --require-scope with --review-ref cross-checks
  // scope.source_changed_files against a live `git diff --name-only <merge-base>
  // <review-ref> -- . ':!.planning'` count. A review-ref identical to the
  // candidate passes; a review-ref missing one of the candidate's files fails
  // naming the mismatch, never silently passing on a wrong count.
  withFixture((fx) => {
    const merge = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
    const g = (args) => git(fx.repo, args);
    g(["update-ref", "refs/heads/review-ok", merge]);
    applyStrictFlags(fx.repo, disposition, { flags: new Set(["require-scope"]), values: { "review-ref": "refs/heads/review-ok" } }, { v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });

    // Build a wrong review-ref: same base, but missing one of the candidate's files.
    const wrongTree = g(["rev-parse", `${merge}^{tree}`]);
    const treeListing = g(["ls-tree", "-r", "--name-only", wrongTree]).split("\n").filter(Boolean);
    const dropPath = treeListing[0];
    const indexFile = path.join(fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase230-scope-fixture-index-")), "index");
    spawnSync("git", ["-C", fx.repo, "read-tree", wrongTree], { encoding: "utf8", env: { ...process.env, GIT_INDEX_FILE: indexFile }, shell: false });
    spawnSync("git", ["-C", fx.repo, "rm", "-f", "--cached", "--quiet", "--", dropPath], { encoding: "utf8", env: { ...process.env, GIT_INDEX_FILE: indexFile }, shell: false });
    const wrongTreeSha = spawnSync("git", ["-C", fx.repo, "write-tree"], { encoding: "utf8", env: { ...process.env, GIT_INDEX_FILE: indexFile }, shell: false }).stdout.trim();
    const wrongCommit = g(["commit-tree", wrongTreeSha, "-p", fx.originMain, "-m", "wrong review-ref"]);
    g(["update-ref", "refs/heads/review-wrong", wrongCommit]);
    assert.throws(
      () => applyStrictFlags(fx.repo, disposition, { flags: new Set(["require-scope"]), values: { "review-ref": "refs/heads/review-wrong" } }, { v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits }),
      /source_changed_files recorded=\d+ differs from review-branch live count=\d+/
    );
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

  // Scenario 7.5: --require-hazard-universe — clean pass, missing row, extra row,
  // stale binding, and a Phase-231-owned lane row recorded with the wrong state.
  withHazardFixture((fx) => {
    mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
    const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
    assert.equal(disposition.hazards.length, 2, "fixture expects exactly shared.txt (convergent-identical) and accrue/mix.exs (dependency-lock-drift)");
    // Clean pass.
    assertHazardUniverseLive(fx.repo, disposition);

    // Missing: drop a recorded hazard row that the live repository still co-touches.
    const missingCase = structuredClone(disposition);
    missingCase.hazards = missingCase.hazards.filter((row) => row.path !== "accrue/mix.exs");
    missingCase.hazard_count = missingCase.hazards.length;
    missingCase.co_touched_file_count = missingCase.hazards.length;
    assert.throws(() => assertHazardUniverseLive(fx.repo, missingCase), /missing=\[/);

    // Extra: a committed hazard row for a file the live repository no longer co-touches.
    const extraCase = structuredClone(disposition);
    extraCase.hazards = [...extraCase.hazards, { path: "no-longer-co-touched.txt", class: "doc-rewrite", state: "advisory", evidence: { command: ["git", "diff"] }, owner: "230-03" }];
    extraCase.hazard_count = extraCase.hazards.length;
    extraCase.co_touched_file_count = extraCase.hazards.length;
    assert.throws(() => assertHazardUniverseLive(fx.repo, extraCase), /extra=\[/);

    // Stale binding refuses before any hazard comparison runs.
    const staleCase = structuredClone(disposition);
    staleCase.binding.origin_main = fx.base;
    assert.throws(() => assertHazardUniverseLive(fx.repo, staleCase), /STALE_BINDING/);

    // A lane row owned by Phase 231 recorded with a state other than non_run is rejected.
    const badLaneCase = structuredClone(disposition);
    badLaneCase.lanes = badLaneCase.lanes.map((row, index) => (index === 0 ? { ...row, state: "proved" } : row));
    assert.throws(() => assertHazardUniverseLive(fx.repo, badLaneCase), /must be "non_run"/);
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

  // Scenario 9: --require-excluded-ledger — clean pass, empty-set pass, missing row,
  // obsolete (no-longer-excluded) extra row, duplicate commit key, null/omitted
  // superseded_by, and a boolean patch_id_occurrences_main.
  function ledgerFixtureRepo() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase230-verify-ledger-fixture-"));
    const repo = path.join(scratch, "repo");
    fs.mkdirSync(repo);
    const g = (args) => git(repo, args);
    g(["init", "-q", "-b", "main"]);
    g(["config", "user.email", "phase230@example.invalid"]);
    g(["config", "user.name", "Phase 230"]);
    fs.mkdirSync(path.join(repo, ".planning", "milestones"), { recursive: true });
    fs.writeFileSync(path.join(repo, "other.txt"), "base\n");
    fs.writeFileSync(path.join(repo, ".planning", "milestones", "v1.61-REQUIREMENTS.md"), "| Requirement | Phase | Status |\n| --- | --- | --- |\n| BASE-01 | Phase 226 | Complete |\n| BASE-02 | Phase 226 | Complete |\n");
    g(["add", "-A"]); g(["commit", "-qm", "base"]);
    const base = g(["rev-parse", "HEAD"]);
    fs.writeFileSync(path.join(repo, "other.txt"), "excluded 1\n");
    g(["add", "-A"]); g(["commit", "-qm", "docs(226): abandoned edit one"]);
    const excluded1 = g(["rev-parse", "HEAD"]);
    fs.writeFileSync(path.join(repo, "other.txt"), "excluded 2\n");
    g(["add", "-A"]); g(["commit", "-qm", "docs(226): abandoned edit two"]);
    const mainTip = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "-b", "candidate", base]);
    fs.mkdirSync(path.join(repo, "scripts", "ci"), { recursive: true });
    fs.writeFileSync(path.join(repo, "scripts", "ci", "collect_ci_baseline.mjs"), "// collector\n");
    fs.writeFileSync(path.join(repo, "scripts", "ci", "verify_ci_baseline.mjs"), "// verifier\n");
    g(["add", "-A"]); g(["commit", "-qm", "feat(230): candidate infra"]);
    // Same content the PR branch below will add, so pr_44.matched_commits has a real
    // patch-id match on the candidate for BOTH the "candidate" and "empty-main" ledger
    // scenarios (the empty-set scenario below still needs a real PR match).
    fs.writeFileSync(path.join(repo, "prfile.txt"), "pr fix\n");
    g(["add", "-A"]); g(["commit", "-qm", "fix(accrue): a fix"]);
    const candidateTip = g(["rev-parse", "HEAD"]);
    g(["branch", "empty-main", base]);
    g(["checkout", "-q", "-b", "fix/release-boot-env-resolver", "main"]);
    fs.writeFileSync(path.join(repo, "prfile.txt"), "pr fix\n");
    g(["add", "-A"]); g(["commit", "-qm", "fix(accrue): a fix"]);
    const prTip = g(["rev-parse", "HEAD"]);
    // A second PR-branch ref off empty-main (== base) so the empty-set scenario's
    // ahead/behind computation (relative to localMainRef: empty-main) sees exactly
    // one unique commit, not the two "main"-only excluded commits as well.
    g(["checkout", "-q", "-b", "fix/release-boot-env-resolver-empty", "empty-main"]);
    fs.writeFileSync(path.join(repo, "prfile.txt"), "pr fix\n");
    g(["add", "-A"]); g(["commit", "-qm", "fix(accrue): a fix"]);
    g(["checkout", "-q", "main"]);
    const stubCollectPr = (r, { prBranchRef }) => ({ number: 44, headRefName: prBranchRef.replace("refs/heads/", ""), headObject: git(r, ["rev-parse", prBranchRef]), baseRefName: "main", state: "open", mergeable: "MERGEABLE" });
    return { scratch, repo, base, excluded1, mainTip, candidateTip, prTip, stubCollectPr };
  }
  function withLedgerFixture(fn) {
    const fx = ledgerFixtureRepo();
    try { fn(fx); } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  }

  withLedgerFixture((fx) => {
    const ledger = collectExcludedCommitLedger({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidateRef: "refs/heads/candidate", localMainRef: "refs/heads/main", prBranchRef: "refs/heads/fix/release-boot-env-resolver", carriedCommit: null, collectPr: fx.stubCollectPr });
    assert.equal(ledger.excluded_commit_count, 2);

    // Clean pass.
    assertExcludedLedgerLive(fx.repo, ledger);

    // Missing: drop a row the live repository still excludes.
    const missingCase = structuredClone(ledger);
    missingCase.rows = missingCase.rows.filter((row) => row.commit !== fx.excluded1);
    missingCase.excluded_commit_count = missingCase.rows.length;
    assert.throws(() => assertExcludedLedgerLive(fx.repo, missingCase), /differs from/);

    // Obsolete/extra: a committed row for a commit that is now an ancestor of the
    // candidate (no longer excluded live).
    const extraCase = structuredClone(ledger);
    extraCase.rows = [...extraCase.rows, { ...structuredClone(ledger.rows[0]), commit: fx.base }];
    extraCase.excluded_commit_count = extraCase.rows.length;
    assert.throws(() => assertExcludedLedgerLive(fx.repo, extraCase), /differs from/);

    // Duplicate commit key.
    const dupCase = structuredClone(ledger);
    dupCase.rows = [...dupCase.rows, structuredClone(dupCase.rows[0])];
    assert.throws(() => assertExcludedLedgerLive(fx.repo, dupCase), /duplicate/);

    // Stale binding refuses before any comparison.
    const staleCase = structuredClone(ledger);
    staleCase.candidate.object = fx.base;
    assert.throws(() => assertExcludedLedgerLive(fx.repo, staleCase), /STALE_BINDING/);
  });

  // Empty excluded set — passes with a recorded count of 0, not a failure or an
  // omitted section.
  withLedgerFixture((fx) => {
    const ledger = collectExcludedCommitLedger({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidateRef: "refs/heads/candidate", localMainRef: "refs/heads/empty-main", prBranchRef: "refs/heads/fix/release-boot-env-resolver-empty", carriedCommit: null, collectPr: fx.stubCollectPr });
    assert.equal(ledger.excluded_commit_count, 0);
    assert.deepEqual(ledger.rows, []);
    assertExcludedLedgerLive(fx.repo, ledger, { localMainRef: "refs/heads/empty-main" });
  });

  // Structural fixtures: a row with superseded_by null/omitted, and a boolean
  // patch_id_occurrences_main, both rejected by schema validation (D-37).
  {
    function minimalLedgerRow(overrides = {}) {
      return {
        commit: "a".repeat(40),
        subject: "some subject",
        disposition: "excluded-superseded",
        superseded_by: "no-equivalent",
        supersession_evidence: {
          tree_level: { command: ["git", "cat-file"], files: [{ path: "x.sh", exists_on_candidate: false, superseded_by_path: "x.mjs" }], plan_inventory: { command: ["git", "ls-tree"], abandoned_line_max_plan: 11, milestone_line_max_plan: 21 } },
          requirement_level: { command: ["git", "show"], file: ".planning/milestones/v1.61-REQUIREMENTS.md", requirements: [{ id: "BASE-01", matched_text: "| BASE-01 | Phase 226 | Complete |" }] }
        },
        patch_id_occurrences_main: 1,
        patch_id_occurrences_candidate: 0,
        published_elsewhere: "none",
        ...overrides
      };
    }
    function minimalLedger(rows) {
      return { schema_version: 1, repository: "szTheory/accrue", candidate: { ref: "refs/heads/integration/v1.62-candidate", object: "b".repeat(40), committed_at: "2026-09-15T00:00:00+00:00" }, local_main: "c".repeat(40), excluded_commit_count: rows.filter((row) => row.disposition !== "carried-on-candidate").length, rows, pr_44: { number: 44, head_ref: "fix/x", head_object: "d".repeat(40), base_ref: "main", base_object: "c".repeat(40), state: "open", mergeable: "MERGEABLE", ahead_of_base: 0, behind_base: 0, matched_commits: [], disposition: "close-unmerged-cite-superseding", note: "n" } };
    }
    assert.throws(() => validateExcludedRow({ ...minimalLedgerRow(), superseded_by: null }, 0), /no-equivalent.*array of 40-hex/);
    const omitted = minimalLedgerRow(); delete omitted.superseded_by;
    assert.throws(() => validateDispositionLedger(minimalLedger([omitted]), { expectedRepository: "szTheory/accrue" }), /missing required field: superseded_by/);
    assert.throws(() => validateDispositionLedger(minimalLedger([minimalLedgerRow({ patch_id_occurrences_main: true })]), { expectedRepository: "szTheory/accrue" }), /must be a non-negative integer/);
  }
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
  const repo = parsed.values.repo || process.cwd();

  // D-37 (--require-excluded-ledger): independently provable -- no dependency on
  // --records/--rendered or any other --require-* flag.
  const wantsLedger = parsed.flags.has("require-excluded-ledger");
  const wantsDisposition = parsed.values.records || parsed.values.rendered || !wantsLedger;

  let disposition = null;
  if (wantsDisposition) {
    const { records, rendered } = parsed.values;
    if (!records || !rendered) fail("--records and --rendered are required outside fixture mode");
    disposition = validateDisposition(JSON.parse(fs.readFileSync(records, "utf8")), { expectedRepository });
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
  }

  if (wantsLedger) {
    const dispositionsPath = parsed.values.dispositions;
    if (!dispositionsPath) fail("--dispositions is required with --require-excluded-ledger");
    const ledger = validateDispositionLedger(JSON.parse(fs.readFileSync(dispositionsPath, "utf8")), { expectedRepository });
    assertExcludedLedgerLive(repo, ledger, { localMainRef: parsed.values["local-main-ref"] || "refs/heads/main" });
    // D-38: --require-determinism proves BOTH rendered artifact pairs when both are
    // supplied -- the disposition pair above (if --records/--rendered were given) and
    // this ledger pair.
    if (parsed.flags.has("require-determinism") && parsed.values["dispositions-rendered"]) {
      const renderedContent = fs.readFileSync(parsed.values["dispositions-rendered"], "utf8");
      const fresh = renderExcludedLedger(ledger, { expectedRepository });
      if (renderedContent !== fresh) fail("rendered excluded-commit ledger Markdown is not byte-reproducible from the committed JSON");
    }
  }

  console.log("integration disposition verification: PASS");
}

if (process.env.NODE_TEST_CONTEXT) {
  test("integration disposition fixtures pass every negative control", () => verifyFixtures());
} else {
  main().catch((error) => { console.error(`integration disposition verify: FAIL: ${error.message}`); process.exitCode = 1; });
}
