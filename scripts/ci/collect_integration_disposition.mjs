#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";

const SHA = /^[a-f0-9]{40}$/;
const REPOSITORY = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const ISO = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/;
const STATES = new Set(["proved", "failed", "skipped", "advisory", "non_run"]);
const REJECTED_STATES = new Set(["deferred", "n/a", "green"]);

const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase SHA`); return value; }
export function mergeCommit(value, label) { return fullSha(value, label); }
export function patchId(value, label) { if (typeof value !== "string" || !/^[a-f0-9]{40}$/.test(value)) fail(`${label} must be a patch-id hex string`); return value; }
function refName(value, label) { if (typeof value !== "string" || !value.startsWith("refs/") || /[\0-\x1f\x7f ~^:?*\\[\]]/.test(value)) fail(`${label} must be a safe ref name`); return value; }
function repository(value, label) { if (typeof value !== "string" || !REPOSITORY.test(value)) fail(`${label} must be an owner/repository string`); return value; }
function timestamp(value, label) { if (typeof value !== "string" || !ISO.test(value)) fail(`${label} must be an ISO-8601 timestamp with a UTC offset`); return value; }
function nonNegInt(value, label) { if (!Number.isInteger(value) || value < 0) fail(`${label} must be a non-negative integer`); return value; }
function exitCode(value, label) { if (!Number.isInteger(value) || value < 0 || value > 255) fail(`${label} must be a recorded process exit code`); return value; }
function state(value, label) { if (typeof value !== "string" || REJECTED_STATES.has(value) || !STATES.has(value)) fail(`${label} must be one of proved/failed/skipped/advisory/non_run`); return value; }
function run(repo, args) { const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 }); if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`); return result.stdout.trim(); }

export const V161_TAG_OBJECT = "fdb41672dd9240b36623ab22a7a8377a2735e5a3";
export const V161_COMMIT_OBJECT = "e3b06794e4dc0d36deb5fc7cb94cbb0b3207d6d9";
export const CLOSURE_COMMITS = [
  "8a95fbe8109cf22efac4763f3d209e2e1b1aeba9",
  "9e090eb5c6f3f384d5abe5e149cf5485dc120f9a",
  "7cc501a33ac2d808b3fee9857e72a8c7eabd94e6",
  "57c61a9a48f1ae84f7b3c3f45333eb6e5fb7261c"
];

const GATE_NAMES = ["v1_61_identity", "v1_61_ancestor", "origin_main_ancestor", "closure_commits_ancestor", "exactly_one_new_commit"];
const ANCESTRY_FIELDS = new Set(["gate", "state", "exit_code", "evidence"]);
const CANDIDATE_FIELDS = new Set(["ref", "object", "parents", "tree", "committed_at"]);
const SCOPE_FIELDS = new Set(["total_changed_files", "planning_only_changed_files", "source_changed_files", "total_commits", "planning_only_commits"]);
const BINDING_FIELDS = new Set(["origin_main", "milestone_tip", "merge_base"]);
const POST_MERGE_ROW_FIELDS = new Set(["commit", "reason", "owner_plan"]);
const TOP = new Set(["schema_version", "repository", "candidate", "ancestry", "scope", "binding", "hazards", "hazard_count", "post_merge_commits", "post_merge_commit_count"]);

function validateCandidate(candidate) {
  fields(candidate, CANDIDATE_FIELDS, "candidate");
  refName(candidate.ref, "candidate.ref");
  if (!candidate.ref.startsWith("refs/heads/")) fail("candidate.ref must be a refs/heads/* branch (D-31)");
  fullSha(candidate.object, "candidate.object");
  if (!Array.isArray(candidate.parents) || candidate.parents.length !== 2) fail("candidate.parents must be a two-element array");
  candidate.parents.forEach((parent, index) => fullSha(parent, `candidate.parents[${index}]`));
  fullSha(candidate.tree, "candidate.tree");
  timestamp(candidate.committed_at, "candidate.committed_at");
  return candidate;
}

function validateAncestry(rows) {
  if (!Array.isArray(rows) || rows.length !== 5) fail("ancestry must contain exactly the five D-05 gates");
  const seen = new Set();
  for (const row of rows) {
    fields(row, ANCESTRY_FIELDS, "ancestry row");
    if (typeof row.gate !== "string" || !GATE_NAMES.includes(row.gate)) fail("ancestry row gate is not a recognized D-05 gate");
    if (seen.has(row.gate)) fail("ancestry row gate must be unique");
    seen.add(row.gate);
    state(row.state, `ancestry[${row.gate}].state`);
    if (row.state === "proved" && !Object.hasOwn(row, "exit_code")) fail(`a proved ancestry row must carry a recorded exit_code: ${row.gate}`);
    if (Object.hasOwn(row, "exit_code")) exitCode(row.exit_code, `ancestry[${row.gate}].exit_code`);
    if (typeof row.evidence !== "string" || !row.evidence) fail("ancestry row evidence must be a non-empty string");
  }
  for (const name of GATE_NAMES) if (!seen.has(name)) fail(`ancestry is missing required gate: ${name}`);
  return rows;
}

function validateScope(scope) {
  fields(scope, SCOPE_FIELDS, "scope");
  for (const key of SCOPE_FIELDS) nonNegInt(scope[key], `scope.${key}`);
  if (scope.source_changed_files + scope.planning_only_changed_files !== scope.total_changed_files) fail("scope file counts must sum to total_changed_files");
  if (scope.planning_only_commits > scope.total_commits) fail("scope.planning_only_commits cannot exceed scope.total_commits");
  return scope;
}

function validateBinding(binding) { fields(binding, BINDING_FIELDS, "binding"); for (const key of BINDING_FIELDS) fullSha(binding[key], `binding.${key}`); return binding; }

function validatePostMergeCommits(rows) {
  if (!Array.isArray(rows)) fail("post_merge_commits must be an array");
  for (const row of rows) {
    fields(row, POST_MERGE_ROW_FIELDS, "post_merge_commits row");
    fullSha(row.commit, "post_merge_commits row.commit");
    if (typeof row.reason !== "string" || !row.reason) fail("post_merge_commits row.reason must be a non-empty string");
    if (typeof row.owner_plan !== "string" || !row.owner_plan) fail("post_merge_commits row.owner_plan must be a non-empty string");
  }
  return rows;
}

function validateHazards(rows) { if (!Array.isArray(rows)) fail("hazards must be an array"); return rows; }

export function validateDisposition(disposition, { expectedRepository } = {}) {
  fields(disposition, TOP, "disposition");
  for (const key of TOP) if (!(key in disposition)) fail(`disposition is missing required field: ${key}`);
  if (disposition.schema_version !== 1) fail("disposition has unsupported schema version");
  repository(disposition.repository, "disposition.repository");
  if (expectedRepository && disposition.repository !== expectedRepository) fail("disposition.repository must match expectedRepository");
  validateCandidate(disposition.candidate);
  validateAncestry(disposition.ancestry);
  validateScope(disposition.scope);
  validateBinding(disposition.binding);
  validateHazards(disposition.hazards);
  if (disposition.hazard_count !== disposition.hazards.length) fail("hazard_count must equal hazards.length");
  validatePostMergeCommits(disposition.post_merge_commits);
  if (disposition.post_merge_commit_count !== disposition.post_merge_commits.length) fail("post_merge_commit_count must equal post_merge_commits.length");
  return disposition;
}

export function collectAncestryGates(repo, { candidateObject, milestoneTip, originMain, v161TagObject, v161CommitObject, closureCommits }) {
  const rows = [];
  {
    const tagObj = spawnSync("git", ["-C", repo, "rev-parse", "v1.61"], { encoding: "utf8" });
    const commitObj = spawnSync("git", ["-C", repo, "rev-parse", "v1.61^{commit}"], { encoding: "utf8" });
    const tag = (tagObj.stdout || "").trim(); const commit = (commitObj.stdout || "").trim();
    const ok = tagObj.status === 0 && commitObj.status === 0 && tag === v161TagObject && commit === v161CommitObject;
    rows.push({ gate: "v1_61_identity", state: ok ? "proved" : "failed", exit_code: ok ? 0 : 1, evidence: `tag=${tag || "unresolved"} commit=${commit || "unresolved"}` });
  }
  {
    const r = spawnSync("git", ["-C", repo, "merge-base", "--is-ancestor", "v1.61", candidateObject], { encoding: "utf8" });
    rows.push({ gate: "v1_61_ancestor", state: r.status === 0 ? "proved" : "failed", exit_code: r.status ?? 1, evidence: `git merge-base --is-ancestor v1.61 ${candidateObject}` });
  }
  {
    const r = spawnSync("git", ["-C", repo, "merge-base", "--is-ancestor", originMain, candidateObject], { encoding: "utf8" });
    rows.push({ gate: "origin_main_ancestor", state: r.status === 0 ? "proved" : "failed", exit_code: r.status ?? 1, evidence: `git merge-base --is-ancestor ${originMain} ${candidateObject}` });
  }
  {
    let allOk = true; let worstCode = 0;
    for (const sha of closureCommits) {
      const r = spawnSync("git", ["-C", repo, "merge-base", "--is-ancestor", sha, candidateObject], { encoding: "utf8" });
      if (r.status !== 0) { allOk = false; worstCode = r.status ?? 1; }
    }
    rows.push({ gate: "closure_commits_ancestor", state: allOk ? "proved" : "failed", exit_code: allOk ? 0 : worstCode, evidence: `closure=${closureCommits.join(",")}` });
  }
  {
    const r = spawnSync("git", ["-C", repo, "rev-list", "--count", candidateObject, `^${milestoneTip}`, `^${originMain}`], { encoding: "utf8" });
    const count = r.status === 0 ? Number((r.stdout || "").trim()) : -1;
    const ok = r.status === 0 && count === 1;
    rows.push({ gate: "exactly_one_new_commit", state: ok ? "proved" : "failed", exit_code: r.status ?? 1, evidence: `count=${count}` });
  }
  return rows;
}

export function collectScope(repo, { mergeBase, candidateObject }) {
  const files = run(repo, ["diff", "--name-only", mergeBase, candidateObject]).split("\n").filter(Boolean);
  const planningFiles = files.filter((file) => file.startsWith(".planning/"));
  const totalCommits = Number(run(repo, ["rev-list", "--count", `${mergeBase}..${candidateObject}`]));
  const log = run(repo, ["log", "--format=%H", "--name-only", `${mergeBase}..${candidateObject}`]);
  let planningOnlyCommits = 0;
  {
    let current = null; let touched = [];
    const flush = () => { if (current && touched.length && touched.every((entry) => entry.startsWith(".planning/"))) planningOnlyCommits += 1; };
    for (const line of log.split("\n")) {
      if (SHA.test(line)) { flush(); current = line; touched = []; }
      else if (line) touched.push(line);
    }
    flush();
  }
  return {
    total_changed_files: files.length,
    planning_only_changed_files: planningFiles.length,
    source_changed_files: files.length - planningFiles.length,
    total_commits: totalCommits,
    planning_only_commits: planningOnlyCommits
  };
}

// Test-only helper shared with verify_integration_disposition.mjs's fixtures so that
// file never needs the literal ref-mutation verbs it exists to forbid at the CLI layer.
export function buildMergeCandidateForTests(repo, left, right, branch = "integration/v1.62-candidate") {
  run(repo, ["branch", branch, left]);
  const tree = run(repo, ["merge-tree", "--write-tree", left, right]);
  const merge = run(repo, ["commit-tree", tree, "-p", left, "-p", right, "-m", "merge"]);
  run(repo, ["update-ref", `refs/heads/${branch}`, merge]);
  return merge;
}

export function collectIntegrationDisposition({ repo, expectedRepository, candidateRef = "refs/heads/integration/v1.62-candidate", v161TagObject, v161CommitObject, closureCommits }) {
  repository(expectedRepository, "expectedRepository");
  const candidateObject = fullSha(run(repo, ["rev-parse", `${candidateRef}^{commit}`]), "candidate object");
  const parentsLine = run(repo, ["rev-list", "--parents", "-n", "1", candidateObject]);
  const parts = parentsLine.split(" ").filter(Boolean);
  if (parts.length !== 3) fail("candidate must be a single first-parent merge with exactly two parents (D-06)");
  const [, milestoneTip, originMain] = parts;
  const tree = fullSha(run(repo, ["rev-parse", `${candidateObject}^{tree}`]), "candidate tree");
  const committedAt = timestamp(run(repo, ["show", "-s", "--format=%cI", candidateObject]), "candidate.committed_at");
  const mergeBase = run(repo, ["merge-base", milestoneTip, originMain]);
  const ancestry = collectAncestryGates(repo, { candidateObject, milestoneTip, originMain, v161TagObject, v161CommitObject, closureCommits });
  const scope = collectScope(repo, { mergeBase, candidateObject });
  const disposition = {
    schema_version: 1,
    repository: expectedRepository,
    candidate: { ref: candidateRef, object: candidateObject, parents: [milestoneTip, originMain], tree, committed_at: committedAt },
    ancestry,
    scope,
    binding: { origin_main: originMain, milestone_tip: milestoneTip, merge_base: mergeBase },
    hazards: [],
    hazard_count: 0,
    post_merge_commits: [],
    post_merge_commit_count: 0
  };
  return validateDisposition(disposition, { expectedRepository });
}

function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--") || !argv[index + 1]) fail("usage: --repo PATH --expected-repository OWNER/REPO [--candidate-ref REF] --out FILE");
    result[argv[index].slice(2)] = argv[++index];
  }
  return result;
}
function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!options.repo || !options["expected-repository"] || !options.out) fail("--repo, --expected-repository, and --out are required");
  const disposition = collectIntegrationDisposition({
    repo: options.repo,
    expectedRepository: options["expected-repository"],
    candidateRef: options["candidate-ref"] || "refs/heads/integration/v1.62-candidate",
    v161TagObject: V161_TAG_OBJECT,
    v161CommitObject: V161_COMMIT_OBJECT,
    closureCommits: CLOSURE_COMMITS
  });
  fs.writeFileSync(options.out, `${JSON.stringify(disposition, null, 2)}\n`, { mode: 0o600 });
}
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  try { main(); } catch (error) { console.error(`integration disposition collect: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  function fixtureRepo() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase230-collect-fixture-"));
    const repo = path.join(scratch, "repo");
    fs.mkdirSync(repo);
    const g = (args) => run(repo, args);
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
  function mergeCandidate(repo, milestoneTip, originMain, branch = "integration/v1.62-candidate") {
    run(repo, ["branch", branch, milestoneTip]);
    const tree = run(repo, ["merge-tree", "--write-tree", milestoneTip, originMain]);
    const merge = run(repo, ["commit-tree", tree, "-p", milestoneTip, "-p", originMain, "-m", "merge"]);
    run(repo, ["update-ref", `refs/heads/${branch}`, merge]);
    return merge;
  }

  test("collects a clean single-merge candidate with all five gates proved", () => {
    const fx = fixtureRepo();
    try {
      const merge = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain);
      const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
      assert.equal(disposition.candidate.object, merge);
      assert.equal(disposition.ancestry.every((row) => row.state === "proved"), true);
      assert.equal(disposition.hazard_count, 0);
      assert.equal(disposition.post_merge_commit_count, 0);
      assert.equal(disposition.scope.source_changed_files + disposition.scope.planning_only_changed_files, disposition.scope.total_changed_files);
    } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  });

  test("rejects a candidate ref that is not a two-parent merge", () => {
    const fx = fixtureRepo();
    try {
      assert.throws(() => collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidateRef: "refs/heads/milestone", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits }), /two parents|single first-parent merge/);
    } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  });

  test("a zero-contribution second parent still yields hazards:[] and hazard_count:0", () => {
    const fx = fixtureRepo();
    try {
      // origin-main here is already an ancestor of milestone (base), so --no-ff still forces a merge commit.
      const merge = mergeCandidate(fx.repo, fx.milestoneTip, fx.base, "integration/v1.62-candidate-empty");
      const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidateRef: "refs/heads/integration/v1.62-candidate-empty", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
      assert.equal(disposition.candidate.object, merge);
      assert.deepEqual(disposition.hazards, []);
      assert.equal(disposition.hazard_count, 0);
    } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  });
}
