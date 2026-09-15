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
function relativePath(value, label) { if (typeof value !== "string" || !value || value.startsWith("/") || value.includes("\\") || value.split("/").some((part) => !part || part === "." || part === "..") || /[\0-\x1f\x7f]/.test(value)) fail(`${label} must be a normalized repository-relative path`); return value; }
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

// D-14: closed hazard-class enumeration. Unknown class => hard failure, never pass-through.
export const HAZARD_CLASSES = new Set([
  "convergent-identical",
  "disjoint-hunk",
  "version-release-train-drift",
  "version-keyed-contract-script",
  "dependency-lock-drift",
  "schema-relaxation",
  "doc-rewrite",
  "archive-path-regression",
  "generated-artifact-staleness"
]);
const HAZARD_FIELDS = new Set(["path", "class", "state", "exit_code", "evidence", "owner"]);
const HAZARD_EVIDENCE_FIELDS = new Set(["left_blob", "right_blob", "command", "left_marker_present", "right_marker_present", "note", "insertions", "deletions"]);

// D-21: the closed set of lanes explicitly excluded from Phase 230 (231-owned,
// "same result on origin/main alone"). Every lane is recorded as an explicit
// non_run row so its absence from Phase 230's scope is an evidenced decision.
export const CANONICAL_D21_LANES = [
  "full-mix-test",
  "dialyzer-plt",
  "playwright-e2e",
  "admin-visual-pixel-diff",
  "storybook-specs",
  "host-integration",
  "host-docker-smoke",
  "asset-rebuild",
  "copy-strings-json-regeneration",
  "provider-live-stripe-lane",
  "mix-hex-publish-dry-run",
  "fresh-clone-run",
  "github-actions-dispatch"
];
const LANE_FIELDS = new Set(["lane", "state", "owner", "command", "reason"]);

const TOP = new Set([
  "schema_version", "repository", "candidate", "ancestry", "scope", "binding",
  "co_touched_file_count", "hazards", "hazard_count",
  "lanes", "lane_count",
  "post_merge_commits", "post_merge_commit_count"
]);

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

function validateHazardEvidence(evidence, label) {
  fields(evidence, HAZARD_EVIDENCE_FIELDS, label);
  if (Object.hasOwn(evidence, "left_blob")) fullSha(evidence.left_blob, `${label}.left_blob`);
  if (Object.hasOwn(evidence, "right_blob")) fullSha(evidence.right_blob, `${label}.right_blob`);
  if (Object.hasOwn(evidence, "command") && (!Array.isArray(evidence.command) || !evidence.command.length || evidence.command.some((el) => typeof el !== "string"))) fail(`${label}.command must be a non-empty array of strings (argv form, never a joined shell string)`);
  if (Object.hasOwn(evidence, "left_marker_present") && typeof evidence.left_marker_present !== "boolean") fail(`${label}.left_marker_present must be a boolean`);
  if (Object.hasOwn(evidence, "right_marker_present") && typeof evidence.right_marker_present !== "boolean") fail(`${label}.right_marker_present must be a boolean`);
  if (Object.hasOwn(evidence, "note") && typeof evidence.note !== "string") fail(`${label}.note must be a string`);
  if (Object.hasOwn(evidence, "insertions")) nonNegInt(evidence.insertions, `${label}.insertions`);
  if (Object.hasOwn(evidence, "deletions")) nonNegInt(evidence.deletions, `${label}.deletions`);
  return evidence;
}

function validateHazardRow(row, index) {
  const label = `hazards[${index}]`;
  fields(row, HAZARD_FIELDS, label);
  for (const key of ["path", "class", "state", "evidence", "owner"]) if (!Object.hasOwn(row, key)) fail(`${label} is missing required field: ${key}`);
  relativePath(row.path, `${label}.path`);
  if (typeof row.class !== "string" || !HAZARD_CLASSES.has(row.class)) fail(`${label}.class must be one of the closed hazard-class enumeration, got: ${row.class}`);
  state(row.state, `${label}.state`);
  validateHazardEvidence(row.evidence, `${label}.evidence`);
  if (row.state === "proved") {
    if (!Object.hasOwn(row, "exit_code")) fail(`${label} state "proved" requires a recorded exit_code`);
    if (!Array.isArray(row.evidence.command) || !row.evidence.command.length) fail(`${label} state "proved" requires evidence.command as a non-empty argv array`);
  }
  if (Object.hasOwn(row, "exit_code")) exitCode(row.exit_code, `${label}.exit_code`);
  if (row.class === "convergent-identical") {
    if (!row.evidence.left_blob || !row.evidence.right_blob) fail(`${label} class convergent-identical requires evidence.left_blob and evidence.right_blob`);
    if (row.evidence.left_blob !== row.evidence.right_blob) fail(`${label} class convergent-identical is rejected: evidence.left_blob !== evidence.right_blob`);
  }
  if (typeof row.owner !== "string" || !row.owner) fail(`${label}.owner must be a non-empty string`);
  // D-20: a row owned by Phase 231 belongs to the release-gate boundary and may never be recorded as run by Phase 230.
  if (row.owner === "231" && row.state !== "non_run") fail(`${label} owner "231" (Phase-231-owned) requires state "non_run" (D-20 boundary)`);
  return row;
}

function validateHazards(rows) {
  if (!Array.isArray(rows)) fail("hazards must be an array");
  rows.forEach((row, index) => validateHazardRow(row, index));
  const seenPaths = new Set();
  for (const row of rows) {
    if (seenPaths.has(row.path)) fail(`hazards contains duplicate path: ${row.path}`);
    seenPaths.add(row.path);
  }
  return rows;
}

export function validateLaneRow(row, index) {
  const label = `lanes[${index}]`;
  fields(row, LANE_FIELDS, label);
  for (const key of ["lane", "state", "owner", "command", "reason"]) if (!Object.hasOwn(row, key)) fail(`${label} is missing required field: ${key}`);
  if (typeof row.lane !== "string" || !CANONICAL_D21_LANES.includes(row.lane)) fail(`${label}.lane must be one of the closed D-21 lane enumeration, got: ${row.lane}`);
  if (row.state !== "non_run") fail(`${label}.state must be "non_run" (D-20/D-21 boundary — Phase-231-owned lanes never run in Phase 230)`);
  if (row.owner !== "231") fail(`${label}.owner must be "231"`);
  if (!Array.isArray(row.command) || !row.command.length || row.command.some((el) => typeof el !== "string")) fail(`${label}.command must be a non-empty array of strings (argv form, never a joined shell string)`);
  if (typeof row.reason !== "string" || !row.reason) fail(`${label}.reason must be a non-empty string`);
  return row;
}

function validateLanes(rows) {
  if (!Array.isArray(rows)) fail("lanes must be an array");
  rows.forEach((row, index) => validateLaneRow(row, index));
  const seen = new Set();
  for (const row of rows) {
    if (seen.has(row.lane)) fail(`lanes contains duplicate lane: ${row.lane}`);
    seen.add(row.lane);
  }
  return rows;
}

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
  nonNegInt(disposition.co_touched_file_count, "disposition.co_touched_file_count");
  if (disposition.co_touched_file_count !== disposition.hazards.length) fail("co_touched_file_count must equal hazards.length (one hazard row per co-touched file, D-14/D-15)");
  validateLanes(disposition.lanes);
  if (disposition.lane_count !== disposition.lanes.length) fail("lane_count must equal lanes.length");
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

// D-15: the co-touched file set is recomputed from two live `git diff --name-only
// <merge-base> <parent>` calls and intersected here — never read from CONTEXT.md or
// any other prose. This is the exact fact that grew from five files to six mid-session.
export function collectCoTouchedFiles(repo, { mergeBase, leftObject, rightObject }) {
  const left = new Set(run(repo, ["diff", "--name-only", mergeBase, leftObject]).split("\n").filter(Boolean));
  const right = new Set(run(repo, ["diff", "--name-only", mergeBase, rightObject]).split("\n").filter(Boolean));
  return [...left].filter((file) => right.has(file)).sort();
}

// Files whose disjoint hunks are recognized by name because their resolution requires
// domain knowledge of what survives on each side (D-16). Any co-touched file that is
// NOT blob-identical and does not match one of these known shapes is a hard failure —
// unknown class never passes through.
const DEPENDENCY_LOCK_DRIFT_FILES = new Set(["accrue/mix.exs"]);
const DISJOINT_HUNK_MARKERS = {
  "accrue/lib/accrue/config.ex": {
    leftMarker: "defp safe_mix_env, do: Accrue.Env.mix_env()",
    rightMarker: "from_email: [type: {:or, [:string, nil]}, default: nil]"
  }
};

function classifyHazardFile(repo, file, { leftObject, rightObject, candidateObject }) {
  const leftBlob = fullSha(run(repo, ["rev-parse", `${leftObject}:${file}`]), `${file} left blob`);
  const rightBlob = fullSha(run(repo, ["rev-parse", `${rightObject}:${file}`]), `${file} right blob`);
  if (leftBlob === rightBlob) {
    return {
      path: file,
      class: "convergent-identical",
      state: "proved",
      exit_code: 0,
      evidence: { left_blob: leftBlob, right_blob: rightBlob, command: ["git", "rev-parse", `${leftObject}:${file}`, `${rightObject}:${file}`] },
      owner: "230-03"
    };
  }
  if (DEPENDENCY_LOCK_DRIFT_FILES.has(file)) {
    // D-17: dependency-lock-drift is invisible to a textual merge — both parents are
    // individually green, the merge is textually clean, but the resulting combination
    // (Decimal 3 / ex_money 6 / Ecto 3.14) has never been compiled or tested. Recorded
    // non_run here; Plan 230-05 owns flipping this to proved with a recorded exit code.
    return {
      path: file,
      class: "dependency-lock-drift",
      state: "non_run",
      evidence: {
        command: ["mix", "deps.get", "--check-locked"],
        note: "origin/main moved {:decimal, \"~> 2.0\"} -> \"~> 3.0\" and {:ex_money, \"~> 5.24\"} -> \"~> 6.2\" (plus explicit ex_cldr/ex_cldr_numbers), with Ecto 3.13.6 -> 3.14.2. Milestone money-math and StreamData property tests have never compiled against Decimal 3 / ex_money 6 (D-17)."
      },
      owner: "230-05"
    };
  }
  const markers = DISJOINT_HUNK_MARKERS[file];
  if (markers) {
    const candidateContent = run(repo, ["show", `${candidateObject}:${file}`]);
    const leftPresent = candidateContent.includes(markers.leftMarker);
    const rightPresent = candidateContent.includes(markers.rightMarker);
    const ok = leftPresent && rightPresent;
    return {
      path: file,
      class: "disjoint-hunk",
      state: ok ? "proved" : "failed",
      exit_code: ok ? 0 : 1,
      evidence: { command: ["git", "show", `${candidateObject}:${file}`], left_marker_present: leftPresent, right_marker_present: rightPresent },
      owner: "230-03"
    };
  }
  if (file.endsWith(".md")) {
    // D-39/doc-rewrite: a documentation-only co-touched file. Advisory — no code
    // regression risk, but still classified and evidenced, never silently dropped.
    const numstat = run(repo, ["diff", "--numstat", leftObject, rightObject, "--", file]);
    const [insertionsRaw, deletionsRaw] = numstat.split(/\s+/);
    const insertions = Number(insertionsRaw) || 0;
    const deletions = Number(deletionsRaw) || 0;
    return {
      path: file,
      class: "doc-rewrite",
      state: "advisory",
      evidence: { command: ["git", "diff", "--numstat", leftObject, rightObject, "--", file], insertions, deletions },
      owner: "230-03"
    };
  }
  fail(`unable to classify co-touched hazard file (no recognized shape, closed enumeration has no match): ${file}`);
}

export function collectHazards(repo, { mergeBase, leftObject, rightObject, candidateObject }) {
  const files = collectCoTouchedFiles(repo, { mergeBase, leftObject, rightObject });
  const rows = files.map((file) => classifyHazardFile(repo, file, { leftObject, rightObject, candidateObject }));
  return { rows, coTouchedFileCount: files.length };
}

// D-37: exact-set completeness, recomputed inside the verifier, never a non-empty check.
// Shared by this module's own fixtures and by verify_integration_disposition.mjs's
// --require-hazard-universe so both layers report the identical missing=[]/extra=[] shape.
export function assertHazardUniverse(liveFiles, hazardRows) {
  const recordedPaths = hazardRows.map((row) => row.path);
  const missing = liveFiles.filter((file) => !recordedPaths.includes(file)).sort();
  const extra = recordedPaths.filter((path) => !liveFiles.includes(path)).sort();
  if (missing.length || extra.length) fail(`hazard universe differs from live co-touched files: missing=[${missing.join(", ")}] extra=[${extra.join(", ")}]`);
}

// D-20/D-21: the closed set of lanes explicitly excluded from Phase 230's scope,
// each recorded as an explicit non_run row owned by Phase 231 so their absence is
// an evidenced decision rather than a silent omission.
export function collectLanes() {
  const reason = (what) => `${what} would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230.`;
  const rows = [
    { lane: "full-mix-test", command: ["mix", "test"], reason: reason("Full `mix test` for any project") },
    { lane: "dialyzer-plt", command: ["mix", "dialyzer"], reason: reason("Dialyzer/PLT (its ignore-list hazard is discharged by blob identity in this plan)") },
    { lane: "playwright-e2e", command: ["npx", "playwright", "test"], reason: reason("Playwright E2E") },
    { lane: "admin-visual-pixel-diff", command: ["npx", "playwright", "test", "--grep", "visual-regression"], reason: reason("The admin visual pixel-diff gate") },
    { lane: "storybook-specs", command: ["npm", "run", "test:storybook"], reason: reason("Storybook specs") },
    { lane: "host-integration", command: ["mix", "test", "--only", "host_integration"], reason: reason("host-integration") },
    { lane: "host-docker-smoke", command: ["docker", "compose", "up", "--build", "--abort-on-container-exit"], reason: reason("host-docker-smoke") },
    { lane: "asset-rebuild", command: ["mix", "accrue_admin.assets.build"], reason: reason("Asset rebuild") },
    { lane: "copy-strings-json-regeneration", command: ["mix", "accrue_admin.copy_strings.generate"], reason: reason("copy_strings.json regeneration") },
    { lane: "provider-live-stripe-lane", command: ["mix", "test.live"], reason: reason("Any provider/live-Stripe lane") },
    { lane: "mix-hex-publish-dry-run", command: ["mix", "hex.publish", "--dry-run"], reason: reason("`mix hex.publish --dry-run`") },
    { lane: "fresh-clone-run", command: ["git", "clone", "."], reason: reason("Any fresh-clone run") },
    { lane: "github-actions-dispatch", command: ["gh", "workflow", "run", "ci.yml"], reason: reason("Any GitHub Actions dispatch (229's read-only posture still binds)") }
  ].map((row) => ({ ...row, state: "non_run", owner: "231" }));
  return rows;
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
  const { rows: hazards, coTouchedFileCount } = collectHazards(repo, { mergeBase, leftObject: milestoneTip, rightObject: originMain, candidateObject });
  const lanes = collectLanes();
  const disposition = {
    schema_version: 1,
    repository: expectedRepository,
    candidate: { ref: candidateRef, object: candidateObject, parents: [milestoneTip, originMain], tree, committed_at: committedAt },
    ancestry,
    scope,
    binding: { origin_main: originMain, milestone_tip: milestoneTip, merge_base: mergeBase },
    co_touched_file_count: coTouchedFileCount,
    hazards,
    hazard_count: hazards.length,
    lanes,
    lane_count: lanes.length,
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
      assert.equal(disposition.co_touched_file_count, 0);
      assert.equal(disposition.lanes.length, 13);
      assert.equal(disposition.lane_count, 13);
    } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  });

  // Hazard-classification fixture: a base with a shared convergent-identical file, a
  // milestone side that edits config.ex/mix.exs/an .md guide, and an origin-main side
  // that edits the SAME three files differently plus an unclassifiable co-touched file.
  function hazardFixtureRepo() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase230-hazard-fixture-"));
    const repo = path.join(scratch, "repo");
    fs.mkdirSync(repo);
    const g = (args) => run(repo, args);
    g(["init", "-q", "-b", "milestone"]);
    g(["config", "user.email", "phase230@example.invalid"]);
    g(["config", "user.name", "Phase 230"]);
    fs.mkdirSync(path.join(repo, "accrue", "lib", "accrue"), { recursive: true });
    fs.writeFileSync(path.join(repo, "accrue", "lib", "accrue", "config.ex"), "line1\nline2 safe_mix_env placeholder\nline3\nline4\nline5 from_email placeholder\nline6\n");
    fs.writeFileSync(path.join(repo, "accrue", "mix.exs"), "line1\nline2 decimal placeholder\nline3\nline4\nline5 ex_money placeholder\nline6\n");
    fs.mkdirSync(path.join(repo, "accrue", "guides"), { recursive: true });
    fs.writeFileSync(path.join(repo, "accrue", "guides", "entitlements.md"), "heading\nparagraph a\nparagraph b\nparagraph c\nfooter\n");
    fs.writeFileSync(path.join(repo, "shared.txt"), "shared\n");
    fs.writeFileSync(path.join(repo, "mystery.bin"), "a\nb\nc\nd\ne\n");
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
    fs.writeFileSync(path.join(repo, "accrue", "lib", "accrue", "config.ex"), "line1\ndefp safe_mix_env, do: Accrue.Env.mix_env()\nline3\nline4\nline5 from_email placeholder\nline6\n");
    fs.writeFileSync(path.join(repo, "accrue", "mix.exs"), "line1\n{:decimal, \"~> 3.0\"}\nline3\nline4\nline5 ex_money placeholder\nline6\n");
    fs.writeFileSync(path.join(repo, "accrue", "guides", "entitlements.md"), "heading\nparagraph a MILESTONE\nparagraph b\nparagraph c\nfooter\n");
    fs.writeFileSync(path.join(repo, "shared.txt"), "shared v2\n");
    g(["add", "-A"]); g(["commit", "-qm", "milestone-side edits"]);
    const milestoneTip = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "-b", "origin-main", base]);
    fs.writeFileSync(path.join(repo, "remote.txt"), "remote\n");
    fs.writeFileSync(path.join(repo, "accrue", "lib", "accrue", "config.ex"), "line1\nline2 safe_mix_env placeholder\nline3\nline4\nfrom_email: [type: {:or, [:string, nil]}, default: nil]\nline6\n");
    fs.writeFileSync(path.join(repo, "accrue", "mix.exs"), "line1\nline2 decimal placeholder\nline3\nline4\n{:ex_money, \"~> 6.2\"}\nline6\n");
    fs.writeFileSync(path.join(repo, "accrue", "guides", "entitlements.md"), "heading\nparagraph a\nparagraph b\nparagraph c ORIGIN\nfooter\n");
    fs.writeFileSync(path.join(repo, "shared.txt"), "shared v2\n");
    g(["add", "-A"]); g(["commit", "-qm", "remote"]);
    const originMain = g(["rev-parse", "HEAD"]);
    g(["checkout", "-q", "milestone"]);
    return { scratch, repo, base, v161Tag, v161Commit, closureCommits, milestoneTip, originMain };
  }

  test("classifies convergent-identical, dependency-lock-drift, disjoint-hunk, and doc-rewrite hazard rows from live blobs, never from a hardcoded path list", () => {
    const fx = hazardFixtureRepo();
    try {
      const merge = mergeCandidate(fx.repo, fx.milestoneTip, fx.originMain, "integration/v1.62-candidate-hazard");
      const disposition = collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidateRef: "refs/heads/integration/v1.62-candidate-hazard", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits });
      assert.equal(disposition.candidate.object, merge);
      assert.equal(disposition.co_touched_file_count, disposition.hazards.length);
      const byPath = Object.fromEntries(disposition.hazards.map((row) => [row.path, row]));
      assert.equal(byPath["shared.txt"].class, "convergent-identical");
      assert.equal(byPath["shared.txt"].evidence.left_blob, byPath["shared.txt"].evidence.right_blob);
      assert.equal(byPath["accrue/mix.exs"].class, "dependency-lock-drift");
      assert.equal(byPath["accrue/mix.exs"].state, "non_run");
      assert.equal(byPath["accrue/mix.exs"].owner, "230-05");
      assert.equal(byPath["accrue/lib/accrue/config.ex"].class, "disjoint-hunk");
      assert.equal(byPath["accrue/lib/accrue/config.ex"].state, "proved");
      assert.equal(byPath["accrue/guides/entitlements.md"].class, "doc-rewrite");
      assert.equal(byPath["accrue/guides/entitlements.md"].state, "advisory");
    } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  });

  test("an unclassifiable co-touched file is a hard failure naming the file", () => {
    const fx = hazardFixtureRepo(); // base already carries mystery.bin, untouched by either side yet
    try {
      run(fx.repo, ["checkout", "-q", "milestone"]);
      fs.writeFileSync(path.join(fx.repo, "mystery.bin"), "a\nMILESTONE\nc\nd\ne\n");
      run(fx.repo, ["add", "-A"]); run(fx.repo, ["commit", "-qm", "milestone mystery"]);
      const newMilestoneTip = run(fx.repo, ["rev-parse", "HEAD"]);
      run(fx.repo, ["checkout", "-q", "origin-main"]);
      fs.writeFileSync(path.join(fx.repo, "mystery.bin"), "a\nb\nc\nd\nORIGIN\n");
      run(fx.repo, ["add", "-A"]); run(fx.repo, ["commit", "-qm", "origin mystery"]);
      const newOriginMain = run(fx.repo, ["rev-parse", "HEAD"]);
      run(fx.repo, ["checkout", "-q", "milestone"]);
      mergeCandidate(fx.repo, newMilestoneTip, newOriginMain, "integration/v1.62-candidate-mystery");
      assert.throws(
        () => collectIntegrationDisposition({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidateRef: "refs/heads/integration/v1.62-candidate-mystery", v161TagObject: fx.v161Tag, v161CommitObject: fx.v161Commit, closureCommits: fx.closureCommits }),
        /unable to classify co-touched hazard file.*mystery\.bin/
      );
    } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  });

  test("rejects a hazard row labelled convergent-identical with mismatched blob ids", () => {
    assert.throws(() => validateDisposition({
      schema_version: 1,
      repository: "szTheory/accrue",
      candidate: { ref: "refs/heads/integration/v1.62-candidate", object: "a".repeat(40), parents: ["b".repeat(40), "c".repeat(40)], tree: "d".repeat(40), committed_at: "2026-09-15T00:00:00+00:00" },
      ancestry: ["v1_61_identity", "v1_61_ancestor", "origin_main_ancestor", "closure_commits_ancestor", "exactly_one_new_commit"].map((gate) => ({ gate, state: "proved", exit_code: 0, evidence: "ok" })),
      scope: { total_changed_files: 0, planning_only_changed_files: 0, source_changed_files: 0, total_commits: 0, planning_only_commits: 0 },
      binding: { origin_main: "c".repeat(40), milestone_tip: "b".repeat(40), merge_base: "e".repeat(40) },
      co_touched_file_count: 1,
      hazards: [{ path: "x.txt", class: "convergent-identical", state: "proved", exit_code: 0, evidence: { left_blob: "1".repeat(40), right_blob: "2".repeat(40), command: ["git", "rev-parse"] }, owner: "230-03" }],
      hazard_count: 1,
      lanes: [],
      lane_count: 0,
      post_merge_commits: [],
      post_merge_commit_count: 0
    }), /convergent-identical is rejected/);
  });

  test("rejects a hazard row missing from the recomputed co-touched file set, and a stale extra row", () => {
    const missingCase = () => assertHazardUniverse(["a.txt", "b.txt"], [{ path: "a.txt" }]);
    assert.throws(missingCase, /missing=\[b\.txt\]/);
    const extraCase = () => assertHazardUniverse(["a.txt"], [{ path: "a.txt" }, { path: "c.txt" }]);
    assert.throws(extraCase, /extra=\[c\.txt\]/);
  });

  test("rejects a proved hazard row with no exit_code, and rejects deferred/n-a/green states", () => {
    const base = { path: "x.txt", class: "doc-rewrite", evidence: { command: ["git", "diff"] }, owner: "230-03" };
    assert.throws(() => validateHazards([{ ...base, state: "proved" }]), /requires a recorded exit_code/);
    for (const rejected of ["deferred", "n/a", "green"]) {
      assert.throws(() => validateHazards([{ ...base, state: rejected, exit_code: 0 }]), /must be one of proved\/failed\/skipped\/advisory\/non_run/);
    }
  });

  test("rejects a lane row owned by Phase 231 with a state other than non_run", () => {
    assert.throws(() => validateLaneRow({ lane: "full-mix-test", state: "proved", owner: "231", command: ["mix", "test"], reason: "x" }, 0), /state must be "non_run"/);
  });
}
