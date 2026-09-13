#!/usr/bin/env node

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import {
  collectRepositoryInventory,
  createRepositoryValidationContext,
  normalizeRemoteFact,
  validateInventory
} from "./collect_repository_inventory.mjs";
import { renderRepositoryInventory } from "./render_repository_inventory.mjs";

const SHA = /^[a-f0-9]{40}$/;
const DIGEST = /^[a-f0-9]{64}$/;
const PRESERVATION_PREFIX = "refs/accrue-preserve/phase-229/";
const BOOLEAN_FLAGS = new Set([
  "fixtures", "require-recovery", "require-all-ref-recovery", "require-typed-artifacts",
  "require-local-only", "require-complete-categories", "require-edge-cases",
  "require-privacy-controls", "require-determinism", "require-command-provenance",
  "require-workflow-metadata-authorization"
]);
const VALUE_OPTIONS = new Set([
  "records", "rendered", "expected-repository", "repository-root", "recovery-manifest",
  "expected-manifest-sha256", "recovery-bundle"
]);
const REMOTE_KEYS = ["remote_main", "pull_requests", "release_branches", "actions"];
const ROLE_REFS = { local_main: "refs/heads/main", cached_origin_main: "refs/remotes/origin/main", v161_tag: "refs/tags/v1.61" };
const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");
const encodedRef = (name) => `${PRESERVATION_PREFIX}${Buffer.from(name).toString("hex")}`;
const fail = (message) => { throw new Error(message); };

function git(repo, args, options = {}) {
  const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 15_000, maxBuffer: 1_000_000, ...options });
  if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim()}`);
  return result.stdout.trim();
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
  if (missing.length || extra.length || changed.length) fail(`${candidateName} recovery set differs from ${authorityName}: missing=[${missing.join(", ")}] extra=[${extra.join(", ")}] changed=[${changed.join(", ")}]`);
}

function assertSameMultiset(authorityName, authority, candidateName, candidate, keyOf) {
  const expected = authority.map(keyOf).sort();
  const actual = candidate.map(keyOf).sort();
  if (expected.length !== actual.length || expected.some((value, index) => value !== actual[index])) {
    fail(`${candidateName} differs from ${authorityName}: expected=[${expected.join(", ")}] actual=[${actual.join(", ")}]`);
  }
}

function assertCanonicalRefContinuity(authority, candidate, activeRef, activeObject) {
  const missing = [...authority.keys()].filter((key) => !candidate.has(key)).sort();
  const extra = [...candidate.keys()].filter((key) => !authority.has(key)).sort();
  const changed = [...authority.keys()].filter((key) => key !== activeRef && candidate.has(key) && candidate.get(key) !== authority.get(key)).sort();
  if (missing.length || extra.length || changed.length) {
    fail(`canonical non-preservation refs recovery set differs from private manifest: missing=[${missing.join(", ")}] extra=[${extra.join(", ")}] changed=[${changed.join(", ")}]`);
  }
  if (activeRef) {
    if (!authority.has(activeRef)) fail("active execution ref was not frozen by the private manifest");
    if (candidate.get(activeRef) !== activeObject) fail("active execution ref must match the recorded milestone branch object");
  }
}

function privateManifest(manifestPath, expectedDigest, context) {
  if (typeof manifestPath !== "string" || !manifestPath) fail("--recovery-manifest requires a non-empty private manifest path");
  if (typeof expectedDigest !== "string" || !DIGEST.test(expectedDigest)) fail("--expected-manifest-sha256 requires a full lowercase SHA-256 digest");
  if (typeof process.geteuid !== "function") fail("private recovery manifest ownership cannot be validated");
  let descriptor;
  try {
    descriptor = fs.openSync(manifestPath, fs.constants.O_RDONLY | (fs.constants.O_NOFOLLOW || 0));
    const stat = fs.fstatSync(descriptor);
    if (!stat.isFile()) fail("private recovery manifest must be a regular file");
    if (stat.uid !== process.geteuid()) fail("private recovery manifest must be owned by the current effective user");
    if ((stat.mode & 0o077) !== 0) fail("private recovery manifest permissions must be 0600 or stricter");
    const bytes = fs.readFileSync(descriptor);
    if (sha256(bytes) !== expectedDigest) fail("private recovery manifest digest does not match the independent expected SHA-256 anchor");
    const value = JSON.parse(bytes.toString("utf8"));
    if (value?.schema_version !== 1 || value.recovery_verified !== true || value.repository !== context.expectedRepository || !Array.isArray(value.refs)) fail("private recovery manifest identity or schema is invalid");
    if (typeof value.bundle_sha256 !== "string" || !DIGEST.test(value.bundle_sha256)) fail("private recovery manifest bundle digest is invalid");
    const refs = exactMap(value.refs, "private manifest", (row) => row.original_ref, (row) => row.object);
    for (const row of value.refs) {
      if (typeof row.original_ref !== "string" || !row.original_ref.startsWith("refs/") || !SHA.test(row.object || "")) fail("private recovery manifest contains an invalid ref mapping");
      if (row.encoded_ref !== encodedRef(row.original_ref)) fail("private recovery manifest contains a wrong encoded preservation ref");
      if (row.restore_argv !== undefined && (!Array.isArray(row.restore_argv) || row.restore_argv.length !== 4 || row.restore_argv[0] !== "git" || row.restore_argv[1] !== "update-ref" || row.restore_argv[2] !== row.original_ref || row.restore_argv[3] !== row.object)) fail("private recovery manifest restore argv is invalid");
    }
    if (!refs.size) fail("private recovery manifest must contain at least one ref mapping");
    return { value, refs };
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
  }
}

function bundleMap(repo, bundlePath, expectedDigest) {
  if (typeof bundlePath !== "string" || !bundlePath) fail("--recovery-bundle requires a non-empty bundle path");
  let stat;
  try { stat = fs.statSync(bundlePath); } catch { fail("--recovery-bundle must identify an existing regular file"); }
  if (!stat.isFile()) fail("--recovery-bundle must identify an existing regular file");
  if (sha256(fs.readFileSync(bundlePath)) !== expectedDigest) fail("recovery bundle digest differs from the private manifest");
  git(repo, ["bundle", "verify", bundlePath]);
  const rows = git(repo, ["bundle", "list-heads", bundlePath]).split("\n").filter(Boolean).map((line) => {
    const match = /^([a-f0-9]{40}) (refs\/.+)$/.exec(line);
    if (!match) fail("recovery bundle contains an invalid head row");
    return { object: match[1], ref: match[2] };
  });
  return exactMap(rows, "bundle heads", (row) => row.ref, (row) => row.object);
}

function encodedMap(repo) {
  const output = git(repo, ["for-each-ref", "--format=%(refname) %(objectname)", PRESERVATION_PREFIX]);
  const rows = output ? output.split("\n").map((line) => {
    const separator = line.indexOf(" ");
    return { ref: line.slice(0, separator), object: line.slice(separator + 1) };
  }) : [];
  for (const row of rows) if (!row.ref.startsWith(PRESERVATION_PREFIX) || !SHA.test(row.object)) fail("encoded preservation ref listing is invalid");
  return exactMap(rows, "encoded preservation refs", (row) => row.ref, (row) => row.object);
}

export function assertStrictRecovery(inventory, context, { repositoryRoot = process.cwd(), recoveryManifest, expectedManifestSha256, recoveryBundle, requireAllRefs = false } = {}) {
  const checked = validateInventory(inventory, context);
  const manifest = privateManifest(recoveryManifest, expectedManifestSha256, context);
  const bundle = bundleMap(repositoryRoot, recoveryBundle, manifest.value.bundle_sha256);
  const publicRecovery = exactMap(checked.recovery.refs, "committed recovery rows", (row) => row.original_ref, (row) => row.object);
  const expectedEncoded = exactMap(manifest.value.refs, "manifest encoded refs", (row) => row.encoded_ref, (row) => row.object);
  assertSameMap("private manifest", manifest.refs, "original bundle heads", bundle);
  assertSameMap("private manifest", manifest.refs, "committed recovery rows", publicRecovery);
  assertSameMap("private manifest encoded refs", expectedEncoded, "local encoded preservation refs", encodedMap(repositoryRoot));
  if (checked.recovery.manifest_sha256 !== expectedManifestSha256) fail("committed recovery manifest digest differs from the independent expected anchor");
  if (checked.recovery.bundle_sha256 !== manifest.value.bundle_sha256) fail("committed recovery bundle digest differs from the private manifest");
  if (requireAllRefs) {
    const canonicalPreservation = exactMap(checked.refs.all.filter((row) => row.name.startsWith(PRESERVATION_PREFIX)), "canonical preservation refs", (row) => row.name, (row) => row.object);
    const canonical = exactMap(checked.refs.all.filter((row) => !row.name.startsWith(PRESERVATION_PREFIX)), "canonical non-preservation refs", (row) => row.name, (row) => row.object);
    const symbolic = spawnSync("git", ["-C", repositoryRoot, "symbolic-ref", "-q", "HEAD"], { encoding: "utf8", shell: false, timeout: 15_000, maxBuffer: 1_000_000 });
    if (symbolic.error || symbolic.status !== 0 || !symbolic.stdout.trim()) fail("strict recovery requires a live symbolic active ref");
    const activeRef = symbolic.stdout.trim();
    const activeObject = git(repositoryRoot, ["rev-parse", `${activeRef}^{object}`]);
    git(repositoryRoot, ["cat-file", "-e", `${activeObject}^{object}`]);
    if (checked.refs.milestone_branch !== activeObject) fail("recorded milestone branch object differs from the live active object");
    assertSameMap("private manifest encoded refs", expectedEncoded, "canonical preservation refs", canonicalPreservation);
    assertCanonicalRefContinuity(manifest.refs, canonical, activeRef, activeObject);
  }
  return true;
}

function assertCommandProvenance(inventory, context) {
  for (const key of REMOTE_KEYS) {
    const fact = inventory.remotes[key];
    normalizeRemoteFact(fact, context, { plural: key !== "remote_main" });
    if (key === "remote_main") {
      if (fact.request !== `GET /repos/${context.expectedRepository}/git/ref/heads/main`) fail("command provenance for remote_main must use the exact main-ref GET");
      continue;
    }
    const requests = fact.requests;
    if (!Array.isArray(requests) || requests.length === 0 || requests.length > 10) fail(`command provenance for ${key} must use one through ten bounded pages`);
    const suffix = key === "pull_requests" ? "pulls?state=open&per_page=100&page="
      : key === "release_branches" ? "git/matching-refs/heads/release/?per_page=100&page="
        : "actions/runs?per_page=100&page=";
    requests.forEach((request, index) => {
      const expected = `GET /repos/${context.expectedRepository}/${suffix}${index + 1}`;
      if (request !== expected) fail(`command provenance for ${key} must be an exact contiguous ordered page sequence`);
    });
    if (fact.available === true) {
      const completedPages = requests.length - 1;
      if (fact.shas.length < completedPages * 100 || fact.shas.length >= requests.length * 100 || fact.shas.length > 1_000) fail(`command provenance for ${key} lacks terminal-page proof`);
    }
  }
  return true;
}

function assertWorkflowMetadataAuthorization(inventory) {
  const changes = inventory.artifacts.authorized_workflow_metadata;
  const expected = [".planning/milestone.lock", ".planning/state.json"];
  if (!Array.isArray(changes) || changes.length !== expected.length || changes.map((row) => row.path).sort().join("\0") !== expected.join("\0")) fail("workflow metadata authorization must remain exact-path bounded");
  return true;
}

function assertTypedArtifacts(inventory) {
  const entries = inventory.artifacts.entries;
  if (!entries.length) fail("typed artifact evidence must not be empty");
  const keys = entries.map((entry) => `${entry.path}\0${entry.type}\0${entry.sha256}`);
  if (new Set(entries.map((entry) => entry.path)).size !== entries.length) fail("typed artifact paths must be unique");
  if (keys.join("\n") !== [...keys].sort().join("\n")) fail("typed artifact evidence must use canonical deterministic ordering");
  return true;
}

function directWorktrees(repositoryRoot) {
  const listed = spawnSync("git", ["-C", repositoryRoot, "worktree", "list", "--porcelain"], { encoding: "utf8", shell: false, timeout: 15_000, maxBuffer: 512 * 1024 });
  if (listed.error || listed.status !== 0) fail("git worktree list failed while verifying complete categories");
  const rows = []; let current = null;
  const finish = () => {
    if (!current) return;
    if (!current.path || !SHA.test(current.sha || "") || (!current.branch && !current.detached)) fail("git worktree authority contains an incomplete record");
    const status = spawnSync("git", ["-C", current.path, "status", "--porcelain"], { encoding: "utf8", shell: false, timeout: 15_000, maxBuffer: 512 * 1024 });
    if (status.error || status.status !== 0) fail("git worktree status failed while verifying complete categories");
    rows.push({ branch: current.detached ? "detached" : current.branch.replace(/^refs\/heads\//, ""), sha: current.sha, dirty: Boolean(status.stdout) });
    current = null;
  };
  for (const line of listed.stdout.split("\n")) {
    if (!line) { finish(); continue; }
    if (line.startsWith("worktree ")) { finish(); current = { path: line.slice(9) }; }
    else if (!current) fail("git worktree authority record has no header");
    else if (line.startsWith("HEAD ")) current.sha = line.slice(5);
    else if (line.startsWith("branch ")) current.branch = line.slice(7);
    else if (line === "detached") current.detached = true;
    else if (line === "bare") fail("bare worktrees cannot be reconciled as inventory worktrees");
    else fail("git worktree authority contains an unsupported record");
  }
  finish();
  if (!rows.length) fail("git worktree authority contains no worktrees");
  return rows;
}

function directShipWindows(repositoryRoot) {
  const filename = path.join(repositoryRoot, ".planning/WINDOWS.md");
  const contents = fs.readFileSync(filename, "utf8");
  if (Buffer.byteLength(contents, "utf8") > 512 * 1024) fail("ship-window authority exceeds its bounded input size");
  const count = (name) => {
    const match = new RegExp(`^${name}:\\s*(\\d+)\\s*$`, "m").exec(contents);
    if (!match) fail(`ship-window authority is missing ${name}`);
    return Number(match[1]);
  };
  const header = "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |";
  const start = contents.indexOf(header);
  if (start < 0) fail("ship-window authority is malformed");
  const rows = [];
  for (const line of contents.slice(start + header.length).trimStart().split("\n")) {
    if (!line.startsWith("|")) break;
    const columns = line.split("|").slice(1, -1).map((item) => item.trim());
    if (columns.every((item) => /^-+$/.test(item))) continue;
    if (columns.length !== 10 || !/^\d+$/.test(columns[0]) || !["open", "waived", "fixed"].includes(columns[6])) fail("ship-window authority contains an invalid row");
    rows.push({ id: Number(columns[0]), status: columns[6] });
  }
  const ids = new Set();
  for (const row of rows) { if (ids.has(row.id)) fail("ship-window authority contains duplicate IDs"); ids.add(row.id); }
  if (count("total_count") !== rows.length || count("open_count") !== rows.filter((row) => row.status === "open").length || count("waived_count") !== rows.filter((row) => row.status === "waived").length || count("fixed_count") !== rows.filter((row) => row.status === "fixed").length) fail("ship-window authority counts are inconsistent");
  return rows.sort((left, right) => left.id - right.id).map((row) => `${row.id}:${row.status}`);
}

function assertCompleteCategories(inventory, context, { repositoryRoot = process.cwd() } = {}) {
  const all = new Map(inventory.refs.all.map((row) => [row.name, row.object]));
  for (const [role, ref] of Object.entries(ROLE_REFS)) if (all.get(ref) !== inventory.refs[role]) fail(`complete categories require ${role} to match ${ref}`);
  if (![...all.values()].includes(inventory.refs.milestone_branch)) fail("complete categories require the milestone branch object in refs.all");
  if (!Array.isArray(inventory.worktrees) || inventory.worktrees.length === 0 || !inventory.planning || !Array.isArray(inventory.planning.ship_windows)) fail("complete local categories are required");
  assertSameMultiset("direct git worktree authority", directWorktrees(repositoryRoot), "canonical worktrees", inventory.worktrees, (row) => `${row.branch}\0${row.sha}\0${row.dirty ? "1" : "0"}`);
  assertSameMultiset("bounded .planning/WINDOWS.md authority", directShipWindows(repositoryRoot), "canonical ship windows", inventory.planning.ship_windows, String);
  for (const key of REMOTE_KEYS) normalizeRemoteFact(inventory.remotes[key], context, { plural: key !== "remote_main" });
  return true;
}

function assertEdgeCases(inventory) {
  if (inventory.artifacts.empty_directory_policy !== "not_surfaced_by_git") fail("edge-case empty-directory policy is required");
  for (const key of REMOTE_KEYS.filter((item) => item !== "remote_main")) {
    const fact = inventory.remotes[key];
    if (fact.available === true && !Array.isArray(fact.shas)) fail(`edge-case plural category ${key} must preserve zero/one/many arrays`);
    if (fact.available === false && (fact.sha !== undefined || fact.shas !== undefined || !fact.reason)) fail(`edge-case unavailable category ${key} must retain only its bounded reason`);
  }
  return true;
}

function assertPrivacyControls(inventory, rendered, privateValues = []) {
  const forbiddenKey = /(^|_)(actor|token|secret|payload|raw|logs?|bundle_path|manifest_path)($|_)/i;
  const forbiddenLocation = (value) => path.posix.isAbsolute(value)
    || path.win32.isAbsolute(value)
    || /^[A-Za-z]:/.test(value)
    || /^file:/i.test(value);
  const visit = (value, trail = "inventory") => {
    if (Array.isArray(value)) return value.forEach((item, index) => visit(item, `${trail}[${index}]`));
    if (value && typeof value === "object") return Object.entries(value).forEach(([key, item]) => {
      if (forbiddenKey.test(key)) fail(`privacy controls reject forbidden field: ${trail}.${key}`);
      visit(item, `${trail}.${key}`);
    });
    if (typeof value === "string" && (forbiddenLocation(value) || /[\x00-\x1f\x7f]/.test(value))) fail(`privacy controls reject private path or control data at ${trail}`);
  };
  visit(inventory);
  for (const value of privateValues.filter(Boolean)) if (JSON.stringify(inventory).includes(value) || rendered.includes(value)) fail("private recovery location leaked into committed evidence");
  return true;
}

function permutedInventory(inventory) {
  const value = structuredClone(inventory);
  value.recovery.refs.reverse();
  value.artifacts.entries.reverse();
  if (value.artifacts.authorized_workflow_metadata) value.artifacts.authorized_workflow_metadata.reverse();
  value.refs.all.reverse();
  value.worktrees.reverse();
  value.planning.ship_windows.reverse();
  for (const key of REMOTE_KEYS) if (Array.isArray(value.remotes[key].shas)) value.remotes[key].shas.reverse();
  return value;
}

function assertDeterminism(inventory, context, renderer = renderRepositoryInventory) {
  const first = renderer(inventory, context);
  const second = renderer(structuredClone(inventory), context);
  const permuted = renderer(permutedInventory(inventory), context);
  if (first !== second || first !== permuted) fail("deterministic rendering must be byte-identical across repeated and permuted inputs");
  return true;
}

function applyStrictFlags(inventory, context, parsed) {
  const recoveryOptions = { repositoryRoot: parsed.values["repository-root"] || process.cwd(), recoveryManifest: parsed.values["recovery-manifest"], expectedManifestSha256: parsed.values["expected-manifest-sha256"], recoveryBundle: parsed.values["recovery-bundle"], requireAllRefs: parsed.flags.has("require-all-ref-recovery") };
  if (parsed.flags.has("require-recovery") || parsed.flags.has("require-all-ref-recovery")) assertStrictRecovery(inventory, context, recoveryOptions);
  if (parsed.flags.has("require-typed-artifacts")) assertTypedArtifacts(inventory);
  if (parsed.flags.has("require-local-only") && inventory.mode !== "local_only") fail("local-only inventory is required");
  if (parsed.flags.has("require-complete-categories")) assertCompleteCategories(inventory, context, { repositoryRoot: recoveryOptions.repositoryRoot });
  if (parsed.flags.has("require-edge-cases")) assertEdgeCases(inventory);
  if (parsed.flags.has("require-command-provenance")) assertCommandProvenance(inventory, context);
  if (parsed.flags.has("require-workflow-metadata-authorization")) assertWorkflowMetadataAuthorization(inventory);
  const rendered = renderRepositoryInventory(inventory, context);
  if (parsed.flags.has("require-privacy-controls")) assertPrivacyControls(inventory, rendered, [parsed.values["recovery-manifest"], parsed.values["recovery-bundle"]]);
  if (parsed.flags.has("require-determinism")) assertDeterminism(inventory, context);
}

function createBundle(repo, bundle, refs) {
  fs.rmSync(bundle, { force: true });
  const result = spawnSync("git", ["-C", repo, "bundle", "create", bundle, ...refs], { encoding: "utf8", shell: false });
  assert.equal(result.status, 0, result.stderr);
}

function writeManifest(fixture) {
  fs.writeFileSync(fixture.manifestPath, `${JSON.stringify(fixture.manifest)}\n`, { mode: 0o600 });
  fs.chmodSync(fixture.manifestPath, 0o600);
  fixture.expectedManifestSha256 = sha256(fs.readFileSync(fixture.manifestPath));
}

function recoveryFixture({ single = false } = {}) {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "phase229-recovery-barrier-"));
  const repo = path.join(scratch, "repo");
  fs.mkdirSync(repo);
  git(repo, ["init", "-q"]);
  git(repo, ["config", "user.email", "phase229@example.invalid"]);
  git(repo, ["config", "user.name", "phase229"]);
  fs.mkdirSync(path.join(repo, ".planning"));
  fs.writeFileSync(path.join(repo, ".planning/milestone.lock"), "before-lock\n");
  fs.writeFileSync(path.join(repo, ".planning/state.json"), "before-state\n");
  fs.writeFileSync(path.join(repo, ".planning/WINDOWS.md"), [
    "---", "open_count: 1", "waived_count: 0", "fixed_count: 1", "total_count: 2", "---", "",
    "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |",
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    "| 1 | 229 | deviation | fixture | | first | open | | now | |",
    "| 2 | 229 | deviation | fixture | | second | fixed | | now | |", ""
  ].join("\n"));
  fs.writeFileSync(path.join(repo, "tracked"), "fixture\n");
  git(repo, ["add", "tracked", ".planning/WINDOWS.md"]);
  git(repo, ["commit", "-qm", "fixture"]);
  git(repo, ["branch", "-M", "main"]);
  const object = git(repo, ["rev-parse", "HEAD"]);
  if (!single) {
    git(repo, ["branch", "secondary"]);
    git(repo, ["update-ref", "refs/custom/phase229$(not-executed)", object]);
    git(repo, ["update-ref", "refs/remotes/origin/main", object]);
    git(repo, ["tag", "v1.61", object]);
  }
  const originalRows = git(repo, ["for-each-ref", "--format=%(refname) %(objectname)", "refs"]).split("\n").filter(Boolean).map((line) => {
    const separator = line.indexOf(" ");
    return { original_ref: line.slice(0, separator), object: line.slice(separator + 1) };
  });
  for (const row of originalRows) git(repo, ["update-ref", encodedRef(row.original_ref), row.object]);
  const bundle = path.join(scratch, "recovery.bundle");
  createBundle(repo, bundle, originalRows.map((row) => row.original_ref));
  const beforeLock = sha256("before-lock\n"); const beforeState = sha256("before-state\n");
  fs.writeFileSync(path.join(repo, ".planning/milestone.lock"), "after-lock\n");
  fs.writeFileSync(path.join(repo, ".planning/state.json"), "after-state\n");
  const afterLock = sha256("after-lock\n"); const afterState = sha256("after-state\n");
  const manifest = {
    schema_version: 1, repository: "szTheory/accrue", recovery_verified: true,
    bundle_sha256: sha256(fs.readFileSync(bundle)),
    refs: originalRows.map((row) => ({ ...row, object_type: "commit", encoded_ref: encodedRef(row.original_ref), bundle_member: true, restore_argv: ["git", "update-ref", row.original_ref, row.object] })),
    artifacts: [
      { path: ".planning/milestone.lock", type: "regular", sha256: beforeLock },
      { path: ".planning/state.json", type: "regular", sha256: beforeState }
    ],
    empty_directory_policy: "not_surfaced_by_git"
  };
  const manifestPath = path.join(scratch, "manifest.json");
  const fixture = { scratch, repo, bundle, manifestPath, manifest, originalRows, object };
  writeManifest(fixture);
  const attestation = {
    schema_version: 1, purpose: "phase229_final_capture", observed_at: "2026-09-13T00:00:00.000Z",
    artifacts: [
      { path: ".planning/milestone.lock", type: "regular", before_sha256: beforeLock, after_sha256: afterLock, state: "workflow_metadata_refreshed" },
      { path: ".planning/state.json", type: "regular", before_sha256: beforeState, after_sha256: afterState, state: "workflow_metadata_refreshed" }
    ]
  };
  const attestationPath = path.join(scratch, "attestation.json");
  fs.writeFileSync(attestationPath, JSON.stringify(attestation));
  return { ...fixture, attestationPath, attestation };
}

function strictInventory(fixture, { mode = "local_only" } = {}) {
  const sha = (letter) => letter.repeat(40);
  const original = fixture.manifest.refs.map((row) => ({ name: row.original_ref, object: row.object, role: row.original_ref === "refs/heads/main" ? "local_main" : row.original_ref === "refs/remotes/origin/main" ? "cached_origin_main" : row.original_ref === "refs/tags/v1.61" ? "v161_tag" : "other" }));
  const preservation = fixture.manifest.refs.map((row) => ({ name: row.encoded_ref, object: row.object, role: "phase229_preservation" }));
  const context = createRepositoryValidationContext({ expectedRepository: "szTheory/accrue" });
  return validateInventory({
    schema_version: 2, repository: "szTheory/accrue", mode,
    recovery: { verified: true, manifest_sha256: fixture.expectedManifestSha256, bundle_sha256: fixture.manifest.bundle_sha256, refs: fixture.manifest.refs.map(({ original_ref, object, encoded_ref, bundle_member }) => ({ original_ref, object, encoded_ref, bundle_member })) },
    artifacts: {
      empty_directory_policy: "not_surfaced_by_git",
      entries: [
        { path: "empty", type: "empty_directory", sha256: "not_surfaced" },
        { path: "link", type: "symlink", sha256: "d".repeat(64) },
        { path: "nested/file.txt", type: "regular", sha256: "c".repeat(64) }
      ],
      authorized_workflow_metadata: [
        { path: ".planning/milestone.lock", type: "regular", before_sha256: "1".repeat(64), after_sha256: "2".repeat(64), state: "workflow_metadata_refreshed" },
        { path: ".planning/state.json", type: "regular", before_sha256: "3".repeat(64), after_sha256: "4".repeat(64), state: "workflow_metadata_refreshed" }
      ]
    },
    refs: { local_main: fixture.object, cached_origin_main: fixture.object, milestone_branch: fixture.object, v161_tag: fixture.object, all: [...original, ...preservation] },
    remotes: {
      remote_main: { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", request: "GET /repos/szTheory/accrue/git/ref/heads/main", available: true, state: "observed", sha: sha("a") },
      pull_requests: { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", requests: ["GET /repos/szTheory/accrue/pulls?state=open&per_page=100&page=1"], available: true, state: "observed", shas: [] },
      release_branches: { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", requests: ["GET /repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1"], available: true, state: "observed", shas: [sha("b"), sha("c")] },
      actions: { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", requests: ["GET /repos/szTheory/accrue/actions/runs?per_page=100&page=1"], available: false, state: "unavailable", reason: "network" }
    },
    planning: { ship_windows: ["1:open", "2:fixed"], milestone: "present", state: "present" },
    worktrees: [{ branch: "main", sha: fixture.object, dirty: true }]
  }, context);
}

function strictOptions(fixture, requireAllRefs = true) {
  return { repositoryRoot: fixture.repo, recoveryManifest: fixture.manifestPath, expectedManifestSha256: fixture.expectedManifestSha256, recoveryBundle: fixture.bundle, requireAllRefs };
}

function assertRecoveryFailure(mutate, expected) {
  const fixture = recoveryFixture(); let calls = 0;
  try {
    mutate(fixture);
    assert.throws(() => collectRepositoryInventory({ repo: fixture.repo, recoveryManifest: fixture.manifestPath, expectedManifestSha256: fixture.expectedManifestSha256, recoveryBundle: fixture.bundle, finalCaptureAttestation: fixture.attestationPath, expectedRepository: "szTheory/accrue", observeRemote: true, adapter: { get: () => { calls += 1; return { object: { sha: "a".repeat(40) } }; } } }), expected);
    assert.equal(calls, 0, "recovery validation must finish before remote observation");
  } finally { fs.rmSync(fixture.scratch, { recursive: true, force: true }); }
}

function verifyStrictRecoveryControls(context) {
  const fixture = recoveryFixture();
  try {
    const inventory = strictInventory(fixture);
    assert.equal(assertStrictRecovery(inventory, context, strictOptions(fixture)), true, "complete many-ref recovery must pass");
    const missing = structuredClone(inventory); missing.recovery.refs.pop();
    assert.throws(() => assertStrictRecovery(missing, context, strictOptions(fixture)), /committed recovery rows recovery set differs/);
    const extra = structuredClone(inventory); extra.recovery.refs.push({ original_ref: "refs/heads/extra", object: "e".repeat(40), encoded_ref: encodedRef("refs/heads/extra"), bundle_member: true });
    assert.throws(() => assertStrictRecovery(extra, context, strictOptions(fixture)), /committed recovery rows recovery set differs/);
    const duplicate = structuredClone(inventory); duplicate.recovery.refs.push(structuredClone(duplicate.recovery.refs[0]));
    assert.throws(() => assertStrictRecovery(duplicate, context, strictOptions(fixture)), /unique|duplicate/);
    const wrongObject = structuredClone(inventory); wrongObject.recovery.refs[0].object = "f".repeat(40);
    assert.throws(() => assertStrictRecovery(wrongObject, context, strictOptions(fixture)), /committed recovery rows recovery set differs/);
    const wrongEncoded = structuredClone(inventory); wrongEncoded.recovery.refs[0].encoded_ref = encodedRef("refs/heads/wrong");
    assert.throws(() => assertStrictRecovery(wrongEncoded, context, strictOptions(fixture)), /encoded_ref/);
    const missingCanonical = structuredClone(inventory); missingCanonical.refs.all = missingCanonical.refs.all.filter((row) => row.name !== fixture.manifest.refs.at(-1).original_ref);
    assert.throws(() => assertStrictRecovery(missingCanonical, context, strictOptions(fixture)), /canonical non-preservation refs recovery set differs/);
    fs.writeFileSync(path.join(fixture.repo, "tracked"), "advanced execution branch\n");
    git(fixture.repo, ["add", "tracked"]); git(fixture.repo, ["commit", "-qm", "advance active execution branch"]);
    const advancedObject = git(fixture.repo, ["rev-parse", "HEAD"]);
    const advanced = structuredClone(inventory);
    advanced.refs.local_main = advancedObject;
    advanced.refs.milestone_branch = advancedObject;
    advanced.refs.all.find((row) => row.name === "refs/heads/main").object = advancedObject;
    assert.equal(assertStrictRecovery(advanced, context, strictOptions(fixture)), true, "the active execution branch may advance after its frozen recovery point");
    const driftedInactive = structuredClone(advanced);
    driftedInactive.refs.all.find((row) => row.name === "refs/heads/secondary").object = advancedObject;
    assert.throws(() => assertStrictRecovery(driftedInactive, context, strictOptions(fixture)), /changed=\[refs\/heads\/secondary\]/);
    const encodedExtra = `${PRESERVATION_PREFIX}6578747261`;
    git(fixture.repo, ["update-ref", encodedExtra, fixture.object]);
    assert.throws(() => assertStrictRecovery(inventory, context, strictOptions(fixture)), /local encoded preservation refs recovery set differs/);
    git(fixture.repo, ["update-ref", "-d", encodedExtra]);
    const subset = fixture.originalRows.slice(0, -1);
    createBundle(fixture.repo, fixture.bundle, subset.map((row) => row.original_ref));
    fixture.manifest.bundle_sha256 = sha256(fs.readFileSync(fixture.bundle));
    writeManifest(fixture);
    const absentHead = strictInventory(fixture);
    assert.throws(() => assertStrictRecovery(absentHead, context, strictOptions(fixture)), /original bundle heads recovery set differs/);
  } finally { fs.rmSync(fixture.scratch, { recursive: true, force: true }); }

  const foreign = recoveryFixture();
  try {
    foreign.manifest.repository = "other/repository"; writeManifest(foreign);
    assert.throws(() => assertStrictRecovery(strictInventory(foreign), context, strictOptions(foreign)), /identity or schema/);
  } finally { fs.rmSync(foreign.scratch, { recursive: true, force: true }); }

  const single = recoveryFixture({ single: true });
  try {
    const inventory = strictInventory(single);
    assert.equal(assertStrictRecovery(inventory, context, strictOptions(single)), true, "complete single-ref recovery must pass exact equality");
    for (const [field, value, expected] of [
      ["recoveryManifest", null, /non-empty private manifest path/], ["recoveryManifest", "", /non-empty private manifest path/],
      ["expectedManifestSha256", null, /full lowercase SHA-256/], ["expectedManifestSha256", "", /full lowercase SHA-256/],
      ["recoveryBundle", null, /non-empty bundle path/], ["recoveryBundle", "", /non-empty bundle path/]
    ]) assert.throws(() => assertStrictRecovery(inventory, context, { ...strictOptions(single), [field]: value }), expected);
  } finally { fs.rmSync(single.scratch, { recursive: true, force: true }); }
}

function verifyStrictFlagControls(context) {
  const fixture = recoveryFixture();
  try {
    const inventory = strictInventory(fixture);
    assert.equal(assertTypedArtifacts(inventory), true);
    const unordered = structuredClone(inventory); unordered.artifacts.entries.reverse();
    assert.throws(() => assertTypedArtifacts(unordered), /canonical deterministic ordering/);
    assert.equal(assertCompleteCategories(inventory, context, { repositoryRoot: fixture.repo }), true);
    const incomplete = structuredClone(inventory); incomplete.refs.local_main = "f".repeat(40);
    assert.throws(() => assertCompleteCategories(incomplete, context), /local_main/);
    assert.equal(assertEdgeCases(inventory), true);
    const edge = structuredClone(inventory); edge.artifacts.empty_directory_policy = "implicit";
    assert.throws(() => assertEdgeCases(edge), /empty-directory policy/);
    assert.equal(assertCommandProvenance(inventory, context), true);
    const provenance = structuredClone(inventory); provenance.remotes.actions.requests = ["GET /repos/other/repository/actions/runs?per_page=100&page=1"];
    assert.throws(() => assertCommandProvenance(provenance, context), /provenance|ordered repository-bound/);
    const rendered = renderRepositoryInventory(inventory, context);
    assert.equal(assertPrivacyControls(inventory, rendered), true);
    const privatePath = structuredClone(inventory); privatePath.planning.state = "/Users/private/state.json";
    assert.throws(() => assertPrivacyControls(privatePath, rendered), /private path/);
    assert.equal(assertDeterminism(inventory, context), true);
    let counter = 0;
    assert.throws(() => assertDeterminism(inventory, context, () => `render-${counter += 1}`), /byte-identical/);
    assert.equal(inventory.mode, "local_only");
    const live = structuredClone(inventory); live.mode = "live_remote";
    assert.throws(() => { if (live.mode !== "local_only") fail("local-only inventory is required"); }, /local-only/);
    assert.equal(assertWorkflowMetadataAuthorization(inventory), true);
    const noAuthorization = structuredClone(inventory); delete noAuthorization.artifacts.authorized_workflow_metadata;
    assert.throws(() => assertWorkflowMetadataAuthorization(noAuthorization), /exact-path bounded/);
  } finally { fs.rmSync(fixture.scratch, { recursive: true, force: true }); }
}

export function verifyFixtures() {
  const context = createRepositoryValidationContext({ expectedRepository: "szTheory/accrue" });
  verifyStrictRecoveryControls(context);
  verifyStrictFlagControls(context);
  assertRecoveryFailure(({ bundle }) => fs.appendFileSync(bundle, "tamper"), /digest/);
  assertRecoveryFailure((fixture) => {
    fs.writeFileSync(path.join(fixture.repo, "tracked"), "replacement\n"); git(fixture.repo, ["add", "tracked"]); git(fixture.repo, ["commit", "-qm", "replacement"]);
    const object = git(fixture.repo, ["rev-parse", "HEAD"]); const originalRef = "refs/heads/main";
    git(fixture.repo, ["update-ref", encodedRef(originalRef), object]); createBundle(fixture.repo, fixture.bundle, fixture.originalRows.map((row) => row.original_ref));
    fixture.manifest.bundle_sha256 = sha256(fs.readFileSync(fixture.bundle)); fixture.manifest.refs.find((row) => row.original_ref === originalRef).object = object;
    fs.writeFileSync(fixture.manifestPath, JSON.stringify(fixture.manifest)); fs.chmodSync(fixture.manifestPath, 0o600);
  }, /manifest digest/);
  assertRecoveryFailure(({ manifestPath }) => fs.chmodSync(manifestPath, 0o644), /permissions/);
  { const originalGeteuid = process.geteuid; try { Object.defineProperty(process, "geteuid", { configurable: true, value: undefined }); assertRecoveryFailure(() => {}, /ownership cannot be validated/); } finally { Object.defineProperty(process, "geteuid", { configurable: true, value: originalGeteuid }); } }
  assertRecoveryFailure((fixture) => { fixture.expectedManifestSha256 = "0".repeat(64); }, /manifest digest/);
  assertRecoveryFailure((fixture) => { fixture.expectedManifestSha256 = undefined; }, /expected recovery manifest SHA-256/);
  assertRecoveryFailure(({ repo }) => git(repo, ["update-ref", "-d", encodedRef("refs/heads/main")]), /git rev-parse failed/);
  assertRecoveryFailure(({ manifestPath }) => { const manifest = JSON.parse(fs.readFileSync(manifestPath)); manifest.refs[0].object = "f".repeat(40); fs.writeFileSync(manifestPath, JSON.stringify(manifest)); }, /digest|preservation target|bundle/);
  assertRecoveryFailure(({ attestationPath }) => { const attestation = JSON.parse(fs.readFileSync(attestationPath)); attestation.observed_at = "not-a-time"; fs.writeFileSync(attestationPath, JSON.stringify(attestation)); }, /observed_at/);
  assertRecoveryFailure(({ attestationPath }) => { const attestation = JSON.parse(fs.readFileSync(attestationPath)); attestation.artifacts.pop(); fs.writeFileSync(attestationPath, JSON.stringify(attestation)); }, /cover every frozen artifact|exactly two/);
  verifyRenderedRecoveryProcedureControls();
}

function verifyRenderedRecoveryProcedureControls() {
  const fixture = recoveryFixture();
  try {
    const context = createRepositoryValidationContext({ expectedRepository: "szTheory/accrue" });
    const inventory = strictInventory(fixture);
    const rendered = renderRepositoryInventory(inventory, context);
    assert.match(
      rendered,
      /```sh\nPHASE229_BUNDLE="\$\{PHASE229_BUNDLE:\?supply the private recovery bundle path at runtime\}"\nexport PHASE229_BUNDLE\ngit bundle verify "\$PHASE229_BUNDLE"/,
      "recovery instructions must assign and export the runtime bundle before verification"
    );
    const block = /## Recovery procedure[\s\S]*?```sh\n([\s\S]*?)\n```/.exec(rendered)?.[1];
    assert.ok(block, "renderer must emit one executable recovery shell block");
    const fetchLines = block.split("\n").filter((line) => line.startsWith("git fetch "));
    assert.equal(fetchLines.length, fixture.manifest.refs.length, "every original ref has one fetch step");
    assert.ok(fetchLines.every((line) => !line.includes(PRESERVATION_PREFIX)), "restore fetches actual original bundle heads, never encoded preservation refs");
    for (const row of fixture.manifest.refs) {
      assert.ok(fetchLines.some((line) => line.endsWith(`'${row.original_ref}'`)), `restore procedure fetches ${row.original_ref}`);
      assert.ok(git(fixture.repo, ["bundle", "list-heads", fixture.bundle]).split("\n").includes(`${row.object} ${row.original_ref}`), `bundle contains ${row.original_ref}`);
    }

    const restore = path.join(fixture.scratch, "restore");
    fs.mkdirSync(restore);
    git(restore, ["init", "-q"]);
    const executed = spawnSync("sh", ["-eu", "-c", block], {
      cwd: restore,
      encoding: "utf8",
      shell: false,
      env: { ...process.env, PHASE229_BUNDLE: fixture.bundle }
    });
    assert.equal(executed.status, 0, executed.stderr);
    for (const row of fixture.manifest.refs) assert.equal(git(restore, ["rev-parse", `${row.original_ref}^{object}`]), row.object, `exact procedure restores ${row.original_ref}`);

    assert.match(rendered, /\| pull_requests \| observed-empty \| — \|/, "confirmed empty plural categories render distinctly");
    assert.ok(rendered.includes(`| release_branches | observed | \`${"b".repeat(40)}\` |`), "first plural SHA is rendered");
    assert.ok(rendered.includes(`| release_branches | observed | \`${"c".repeat(40)}\` |`), "second plural SHA is rendered");
    assert.match(rendered, /\| actions \| unavailable:network \| — \|/, "unavailable categories retain their reason");
    assert.equal(rendered.includes(fixture.scratch), false, "private fixture locations never enter Markdown");

    const equalPrimaryKeys = structuredClone(inventory);
    equalPrimaryKeys.worktrees.push({ ...equalPrimaryKeys.worktrees[0], dirty: true });
    assert.equal(renderRepositoryInventory(equalPrimaryKeys, context), renderRepositoryInventory(permutedInventory(equalPrimaryKeys), context), "equal primary keys retain deterministic secondary ordering");
  } finally { fs.rmSync(fixture.scratch, { recursive: true, force: true }); }
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
  const parsed = options(process.argv.slice(2)); const expectedRepository = parsed.values["expected-repository"];
  if (!expectedRepository) fail("--expected-repository is required");
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("repository inventory fixtures: PASS"); return; }
  const { records, rendered } = parsed.values;
  if (!records || !rendered) fail("--records and --rendered are required outside fixture mode");
  const context = createRepositoryValidationContext({ expectedRepository });
  const inventory = validateInventory(JSON.parse(fs.readFileSync(records, "utf8")), context);
  applyStrictFlags(inventory, context, parsed);
  assert.equal(fs.readFileSync(rendered, "utf8"), renderRepositoryInventory(inventory, context), "rendered Markdown must be byte-reproducible");
  console.log("repository inventory verification: PASS");
}

if (process.env.NODE_TEST_CONTEXT) {
  test("strict repository inventory flags enforce independent negative controls", () => verifyFixtures());
  test("rendered recovery procedure restores original bundle heads safely", () => verifyRenderedRecoveryProcedureControls());
} else {
  main().catch((error) => { console.error(`repository inventory fixtures: FAIL: ${error.message}`); process.exitCode = 1; });
}
