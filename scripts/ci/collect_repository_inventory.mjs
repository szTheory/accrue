#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";

const SHA = /^[a-f0-9]{40}$/; const DIGEST = /^[a-f0-9]{64}$/;
const REPOSITORY = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/; const ISO = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
const CONTEXT = Symbol("phase229-context");
const TOP = new Set(["schema_version", "repository", "mode", "recovery", "artifacts", "refs", "remotes", "planning", "worktrees"]);
const REMOTE_KEYS = ["remote_main", "pull_requests", "release_branches", "actions"];
const ROLES = ["local_main", "cached_origin_main", "milestone_branch", "v161_tag"];
const REASONS = new Set(["network", "authentication", "rate_limit", "timeout", "data_shape", "overflow", "unavailable"]);
const REMOTE_LIMIT = 100;
const GH_TIMEOUT_MS = 10_000;
const GH_MAX_BUFFER = 512 * 1024;
const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase SHA`); return value; }
function digest(value, label) { if (typeof value !== "string" || !DIGEST.test(value)) fail(`${label} must be a SHA-256 digest`); return value; }
function timestamp(value, label) { if (typeof value !== "string" || !ISO.test(value) || Number.isNaN(Date.parse(value))) fail(`${label} must be an ISO-8601 timestamp`); return value; }
function relativePath(value, label) { if (typeof value !== "string" || !value || value.startsWith("/") || value.includes("\\") || value.split("/").some((part) => !part || part === "." || part === "..") || /[\0-\x1f\x7f]/.test(value)) fail(`${label} must be a normalized repository-relative path`); return value; }
function refName(value, label) { if (typeof value !== "string" || !value.startsWith("refs/") || /[\0-\x1f\x7f ~^:?*\\[\\]/.test(value)) fail(`${label} must be a safe ref name`); return value; }
function run(repo, args) { const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", timeout: 15000, maxBuffer: 1000000 }); if (result.status !== 0) fail(`git ${args[0]} failed`); return result.stdout.trim(); }
const encodedRef = (name) => `refs/accrue-preserve/phase-229/${Buffer.from(name).toString("hex")}`;
const sorted = (items, key) => [...items].sort((a, b) => key(a).localeCompare(key(b)));

export function createRepositoryValidationContext({ expectedRepository } = {}) { if (typeof expectedRepository !== "string" || !REPOSITORY.test(expectedRepository)) fail("expectedRepository must be an owner/repository string"); return Object.freeze({ expectedRepository, [CONTEXT]: true }); }
function validationContext(value) { if (!value || value[CONTEXT] !== true || !Object.isFrozen(value)) fail("validationContext must be created by createRepositoryValidationContext"); return value; }

export function normalizeRemoteFact(value, context, { plural = false } = {}) {
  validationContext(context); fields(value, new Set(["repository", "observed_at", "request", "sha", "shas", "available", "reason", "state"]), "remote fact");
  if (value.repository !== context.expectedRepository) fail("remote fact repository must match expectedRepository"); timestamp(value.observed_at, "remote fact observed_at");
  if (typeof value.request !== "string" || !new RegExp(`^GET /repos/${context.expectedRepository.replace("/", "\\/")}/`).test(value.request) || /[\r\n]/.test(value.request)) fail("remote fact request must be a repository-bound GET request");
  if (value.available !== false) {
    if (plural) {
      if (value.sha !== undefined || !Array.isArray(value.shas)) fail("plural remote fact requires a SHA array and no singleton SHA");
      value.shas.forEach((sha) => fullSha(sha, "remote fact SHA"));
      return { repository: value.repository, observed_at: value.observed_at, request: value.request, available: true, state: value.state || "observed", shas: [...value.shas] };
    }
    if (value.shas !== undefined) fail("singleton remote fact must not contain SHA array");
    fullSha(value.sha, "remote fact sha");
    return { repository: value.repository, observed_at: value.observed_at, request: value.request, available: true, state: value.state || "observed", sha: value.sha };
  }
  if (value.available !== false || value.sha !== undefined || value.shas !== undefined || !REASONS.has(value.reason)) fail("unavailable remote fact must have bounded reason and no claimed remote value");
  return { repository: value.repository, observed_at: value.observed_at, request: value.request, available: false, state: "unavailable", reason: value.reason };
}

function validateRecovery(recovery) { fields(recovery, new Set(["verified", "manifest_sha256", "bundle_sha256", "refs"]), "recovery"); if (recovery.verified !== true) fail("recovery must be verified"); digest(recovery.manifest_sha256, "recovery.manifest_sha256"); digest(recovery.bundle_sha256, "recovery.bundle_sha256"); if (!Array.isArray(recovery.refs) || !recovery.refs.length) fail("recovery.refs must be a non-empty array"); const seen = new Set(); for (const ref of recovery.refs) { fields(ref, new Set(["original_ref", "object", "encoded_ref", "bundle_member"]), "recovery ref"); refName(ref.original_ref, "recovery ref original_ref"); fullSha(ref.object, "recovery ref object"); if (ref.encoded_ref !== encodedRef(ref.original_ref)) fail("recovery ref encoded_ref must preserve original name"); if (ref.bundle_member !== true) fail("recovery ref must be in verified bundle"); if (seen.has(ref.original_ref)) fail("recovery refs must be unique"); seen.add(ref.original_ref); } }
const WORKFLOW_METADATA_PATHS = new Set([".planning/milestone.lock", ".planning/state.json"]);
function validateWorkflowMetadataChanges(changes, label = "workflow metadata authorization") {
  if (!Array.isArray(changes) || changes.length !== WORKFLOW_METADATA_PATHS.size) fail(`${label} must enumerate the two exact workflow metadata paths`);
  const seen = new Set();
  for (const change of changes) {
    fields(change, new Set(["path", "type", "before_sha256", "after_sha256", "state"]), label);
    if (!WORKFLOW_METADATA_PATHS.has(change.path) || seen.has(change.path)) fail(`${label} contains an unauthorized path`);
    if (change.type !== "regular" || change.state !== "workflow_metadata_refreshed") fail(`${label} has an invalid change state`);
    digest(change.before_sha256, `${label}.before_sha256`); digest(change.after_sha256, `${label}.after_sha256`);
    if (change.before_sha256 === change.after_sha256) fail(`${label} must record a real change`);
    seen.add(change.path);
  }
  return sorted(changes, (change) => change.path);
}
function validateArtifacts(artifacts) { fields(artifacts, new Set(["empty_directory_policy", "entries", "authorized_workflow_metadata"]), "artifacts"); if (artifacts.empty_directory_policy !== "not_surfaced_by_git") fail("empty-directory policy must be explicit"); if (!Array.isArray(artifacts.entries)) fail("artifacts.entries must be an array"); for (const item of artifacts.entries) { fields(item, new Set(["path", "type", "sha256"]), "artifact"); relativePath(item.path, "artifact.path"); if (!["regular", "symlink", "empty_directory"].includes(item.type)) fail("artifact type is unsupported"); if (item.type === "empty_directory") { if (item.sha256 !== "not_surfaced") fail("empty directory requires marker"); } else digest(item.sha256, "artifact.sha256"); } if (artifacts.authorized_workflow_metadata !== undefined) validateWorkflowMetadataChanges(artifacts.authorized_workflow_metadata); }

export function validateInventory(inventory, context) {
  validationContext(context); fields(inventory, TOP, "inventory"); for (const key of TOP) if (!(key in inventory)) fail(`inventory is missing required field: ${key}`); if (inventory.schema_version !== 2) fail("inventory has unsupported schema version"); if (inventory.repository !== context.expectedRepository) fail("inventory.repository must match expectedRepository"); if (!["local_only", "live_remote"].includes(inventory.mode)) fail("inventory mode is unsupported"); validateRecovery(inventory.recovery); validateArtifacts(inventory.artifacts);
  fields(inventory.refs, new Set([...ROLES, "all"]), "refs"); ROLES.forEach((role) => fullSha(inventory.refs[role], `refs.${role}`)); if (!Array.isArray(inventory.refs.all)) fail("refs.all must be an array"); for (const item of inventory.refs.all) { fields(item, new Set(["name", "object", "role"]), "ref"); refName(item.name, "ref.name"); fullSha(item.object, "ref.object"); if (typeof item.role !== "string") fail("ref.role must be a string"); }
  fields(inventory.remotes, new Set(REMOTE_KEYS), "remotes"); REMOTE_KEYS.forEach((key) => normalizeRemoteFact(inventory.remotes[key], context, { plural: key !== "remote_main" }));
  fields(inventory.planning, new Set(["ship_windows", "milestone", "state"]), "planning"); if (!Array.isArray(inventory.planning.ship_windows)) fail("planning.ship_windows must be an array"); for (const key of ["milestone", "state"]) if (typeof inventory.planning[key] !== "string" || /[\r\n]/.test(inventory.planning[key])) fail(`planning.${key} must be sanitized`);
  if (!Array.isArray(inventory.worktrees)) fail("worktrees must be an array"); for (const item of inventory.worktrees) { fields(item, new Set(["branch", "sha", "dirty"]), "worktree"); if (typeof item.branch !== "string" || !item.branch || item.branch.startsWith("/") || item.branch.includes("//") || /[\r\n\\]/.test(item.branch)) fail("worktree branch is unsafe"); fullSha(item.sha, "worktree sha"); if (typeof item.dirty !== "boolean") fail("worktree dirty must be boolean"); }
  return inventory;
}

function readTrustedRecoveryManifest(manifestPath, expectedManifestSha256) {
  digest(expectedManifestSha256, "expected recovery manifest SHA-256");
  if (typeof manifestPath !== "string" || !manifestPath) fail("private recovery manifest is required");
  if (typeof process.geteuid !== "function") fail("private recovery manifest ownership cannot be validated");
  const noFollow = fs.constants.O_NOFOLLOW || 0;
  let descriptor;
  try {
    descriptor = fs.openSync(manifestPath, fs.constants.O_RDONLY | noFollow);
    const stat = fs.fstatSync(descriptor);
    if (!stat.isFile()) fail("private recovery manifest must be a regular file");
    if (stat.uid !== process.geteuid()) fail("private recovery manifest must be owned by the current effective user");
    if ((stat.mode & 0o077) !== 0) fail("private recovery manifest permissions must be 0600 or stricter");
    const contents = fs.readFileSync(descriptor);
    const actualManifestSha256 = crypto.createHash("sha256").update(contents).digest("hex");
    if (actualManifestSha256 !== expectedManifestSha256) fail("private recovery manifest digest does not match independent expected SHA-256");
    const manifest = JSON.parse(contents.toString("utf8"));
    if (manifest?.schema_version !== 1 || manifest.recovery_verified !== true || !Array.isArray(manifest.refs) || !Array.isArray(manifest.artifacts)) fail("recovery manifest is not verified phase-229 state");
    validateRecovery({ verified: true, manifest_sha256: expectedManifestSha256, bundle_sha256: manifest.bundle_sha256, refs: manifest.refs.map(({ original_ref, object, encoded_ref, bundle_member }) => ({ original_ref, object, encoded_ref, bundle_member })) });
    return manifest;
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
  }
}
function bundleHeads(repo, bundle) {
  const verified = spawnSync("git", ["-C", repo, "bundle", "verify", bundle], { encoding: "utf8", timeout: 15000, maxBuffer: 1000000 });
  if (verified.status !== 0) fail("recovery bundle verification failed");
  const listed = spawnSync("git", ["-C", repo, "bundle", "list-heads", bundle], { encoding: "utf8", timeout: 15000, maxBuffer: 1000000 });
  if (listed.status !== 0) fail("recovery bundle head listing failed");
  const heads = new Map();
  for (const line of listed.stdout.split("\n").filter(Boolean)) {
    const match = /^([a-f0-9]{40}) (refs\/.+)$/.exec(line);
    if (!match || heads.has(match[2])) fail("recovery bundle contains an invalid head");
    heads.set(match[2], match[1]);
  }
  return heads;
}
function requireRecovery(repo, manifest, recoveryBundle) {
  if (typeof recoveryBundle !== "string" || !recoveryBundle || !fs.statSync(recoveryBundle).isFile()) fail("actual recovery bundle is required");
  const actualDigest = crypto.createHash("sha256").update(fs.readFileSync(recoveryBundle)).digest("hex");
  if (actualDigest !== manifest.bundle_sha256) fail("recovery bundle digest does not match private manifest");
  const heads = bundleHeads(repo, recoveryBundle);
  for (const ref of manifest.refs) {
    if (run(repo, ["rev-parse", `${ref.encoded_ref}^{object}`]) !== ref.object) fail("recovery preservation target does not match frozen object");
    if (heads.get(ref.original_ref) !== ref.object) fail("recovery bundle is missing frozen original ref/object membership");
    run(repo, ["cat-file", "-e", `${ref.object}^{object}`]);
  }
  return manifest;
}
function readWorkflowMetadataAuthorization(authorizationPath) {
  if (!authorizationPath) return null;
  const record = JSON.parse(fs.readFileSync(authorizationPath, "utf8"));
  fields(record, new Set(["schema_version", "purpose", "changes"]), "workflow metadata authorization record");
  if (record.schema_version !== 1 || record.purpose !== "phase229_workflow_metadata_refresh") fail("workflow metadata authorization record is invalid");
  return validateWorkflowMetadataChanges(record.changes, "workflow metadata authorization record");
}
function readFinalCaptureAttestation(attestationPath, manifest) {
  if (!attestationPath) fail("final capture attestation is required");
  const record = JSON.parse(fs.readFileSync(attestationPath, "utf8"));
  fields(record, new Set(["schema_version", "purpose", "observed_at", "artifacts"]), "final capture attestation");
  if (record.schema_version !== 1 || record.purpose !== "phase229_final_capture") fail("final capture attestation is invalid");
  timestamp(record.observed_at, "final capture attestation observed_at");
  if (!Array.isArray(record.artifacts) || record.artifacts.length !== manifest.artifacts.length) fail("final capture attestation must cover every frozen artifact");
  const frozen = new Map(manifest.artifacts.map((entry) => [entry.path, entry])); const changes = [];
  for (const invariant of record.artifacts) {
    fields(invariant, new Set(["path", "type", "before_sha256", "after_sha256", "state"]), "final capture artifact invariant");
    const entry = frozen.get(invariant.path);
    if (!entry || entry.type !== invariant.type || entry.sha256 !== invariant.before_sha256) fail("final capture attestation does not match frozen artifact");
    if (WORKFLOW_METADATA_PATHS.has(invariant.path)) {
      if (invariant.state !== "workflow_metadata_refreshed" || invariant.before_sha256 === invariant.after_sha256) fail("final capture workflow metadata invariant is invalid");
      changes.push(invariant);
    } else if (invariant.state !== "unchanged" || invariant.before_sha256 !== invariant.after_sha256) fail("final capture non-workflow artifact must remain unchanged");
    frozen.delete(invariant.path);
  }
  if (frozen.size || changes.length !== WORKFLOW_METADATA_PATHS.size) fail("final capture attestation must contain exactly two workflow metadata invariants");
  validateWorkflowMetadataChanges(changes, "final capture workflow metadata invariants");
  return { observedAt: record.observed_at, artifacts: record.artifacts, workflowMetadataChanges: changes };
}
function currentArtifact(repo, entry) { const full = path.join(repo, entry.path); const stat = fs.lstatSync(full); if (stat.isSymbolicLink()) return { type: "symlink", sha256: crypto.createHash("sha256").update(fs.readlinkSync(full)).digest("hex") }; if (stat.isFile()) return { type: "regular", sha256: crypto.createHash("sha256").update(fs.readFileSync(full)).digest("hex") }; if (stat.isDirectory()) return { type: "empty_directory", sha256: "not_surfaced" }; fail(`unsupported artifact type: ${entry.path}`); }
function validateArtifactSnapshot(repo, manifest, authorization) {
  const permitted = new Map((authorization || []).map((change) => [change.path, change])); const changes = [];
  for (const entry of manifest.artifacts) {
    const current = currentArtifact(repo, entry);
    if (current.type === entry.type && current.sha256 === entry.sha256) continue;
    const change = permitted.get(entry.path);
    if (!change || entry.type !== change.type || entry.sha256 !== change.before_sha256 || current.type !== change.type || current.sha256 !== change.after_sha256) fail(`artifact changed without exact authorization: ${entry.path}`);
    changes.push(change); permitted.delete(entry.path);
  }
  if (permitted.size) fail("workflow metadata authorization did not match the current artifact snapshot");
  return sorted(changes, (change) => change.path);
}
function validateFinalArtifactSnapshot(repo, manifest, attestation) {
  const changes = validateArtifactSnapshot(repo, manifest, attestation.workflowMetadataChanges);
  for (const invariant of attestation.artifacts) {
    const current = currentArtifact(repo, invariant);
    if (current.type !== invariant.type || current.sha256 !== invariant.after_sha256) fail(`final capture artifact post-invariant mismatch: ${invariant.path}`);
  }
  return changes;
}
const unavailable = (repository, request, reason = "unavailable", now = new Date()) => ({ repository, observed_at: now.toISOString(), request, available: false, state: "unavailable", reason });
const remoteRequest = (repository, suffix) => `GET /repos/${repository}/${suffix}`;
function unavailableReason(error) {
  const text = String(error?.message || error || "");
  if (/rate[ _-]?limit|\b429\b/i.test(text)) return "rate_limit";
  if (/auth|\b401\b|\b403\b/i.test(text)) return "authentication";
  if (/timeout|ETIMEDOUT/i.test(text)) return "timeout";
  if (/maxbuffer|overflow/i.test(text)) return "overflow";
  if (/network|ENOTFOUND|ECONN|EAI_AGAIN/i.test(text)) return "network";
  return "data_shape";
}
function responseJson(result) {
  if (result.error) fail(result.error.code === "ETIMEDOUT" ? "timeout" : `network: ${result.error.code || result.error.message}`);
  if (result.status !== 0) fail((result.stderr || "GitHub API unavailable").trim().slice(0, 240));
  if (Buffer.byteLength(result.stdout || "", "utf8") > GH_MAX_BUFFER) fail("overflow");
  try { return JSON.parse(result.stdout); } catch { fail("data_shape: GitHub API response is not JSON"); }
}
function ghEndpointFor(request, repository) {
  if (typeof request !== "string" || !request.startsWith(`GET /repos/${repository}/`)) fail("GitHub API request is not repository-bound");
  const endpoint = request.slice("GET /".length);
  const allowed = [
    `repos/${repository}/git/ref/heads/main`,
    `repos/${repository}/pulls?state=open&per_page=${REMOTE_LIMIT}`,
    `repos/${repository}/git/matching-refs/heads/release/`,
    `repos/${repository}/actions/runs?per_page=${REMOTE_LIMIT}`
  ];
  if (!allowed.includes(endpoint)) fail("GitHub API request is not allowlisted");
  return endpoint;
}
export function createGhApiReadAdapter({ repository = "szTheory/accrue", invoke } = {}) {
  const context = createRepositoryValidationContext({ expectedRepository: repository });
  const calls = [];
  const execute = invoke || ((argv) => spawnSync("gh", argv, { encoding: "utf8", shell: false, timeout: GH_TIMEOUT_MS, maxBuffer: GH_MAX_BUFFER }));
  return Object.freeze({
    calls,
    get(request) {
      const endpoint = ghEndpointFor(request, context.expectedRepository);
      const argv = ["api", endpoint, "--method", "GET", "--header", "Accept: application/vnd.github+json"];
      calls.push([...argv]);
      const result = execute([...argv]);
      if (result && typeof result === "object" && "stdout" in result) return responseJson(result);
      if (typeof result === "string") { try { return JSON.parse(result); } catch { fail("data_shape: GitHub API response is not JSON"); } }
      return result;
    }
  });
}
function remoteRead(adapter, request, repository, now, { plural, normalize }) {
  try {
    const raw = adapter.get(request);
    const value = plural ? { shas: normalize(raw) } : { sha: normalize(raw) };
    return normalizeRemoteFact({ repository, observed_at: now.toISOString(), request, available: true, ...value }, createRepositoryValidationContext({ expectedRepository: repository }), { plural });
  } catch (error) { return unavailable(repository, request, unavailableReason(error), now); }
}
function arrayOf(raw, label) { if (!Array.isArray(raw)) fail(`${label} response must be an array`); if (raw.length > REMOTE_LIMIT) fail("overflow"); return raw; }
function sortedShas(items, compare, sha) {
  return [...items].sort((left, right) => compare(left, right) || sha(left).localeCompare(sha(right))).map((item) => fullSha(sha(item), "remote result SHA"));
}
export function collectRemoteFacts({ repository, adapter, now = () => new Date() }) {
  const request = (suffix) => remoteRequest(repository, suffix);
  const requests = {
    remote_main: request("git/ref/heads/main"),
    pull_requests: request(`pulls?state=open&per_page=${REMOTE_LIMIT}`),
    release_branches: request("git/matching-refs/heads/release/"),
    actions: request(`actions/runs?per_page=${REMOTE_LIMIT}`)
  };
  if (!adapter || typeof adapter.get !== "function") return Object.fromEntries(REMOTE_KEYS.map((key) => [key, unavailable(repository, requests[key], "unavailable", now())]));
  return {
    remote_main: remoteRead(adapter, requests.remote_main, repository, now(), { plural: false, normalize: (raw) => fullSha(raw?.object?.sha, "remote main SHA") }),
    pull_requests: remoteRead(adapter, requests.pull_requests, repository, now(), { plural: true, normalize: (raw) => sortedShas(arrayOf(raw, "pull requests"), (a, b) => Number(a?.number) - Number(b?.number), (item) => item?.head?.sha) }),
    release_branches: remoteRead(adapter, requests.release_branches, repository, now(), { plural: true, normalize: (raw) => sortedShas(arrayOf(raw, "release branches"), (a, b) => String(a?.ref || "").localeCompare(String(b?.ref || "")), (item) => item?.object?.sha) }),
    actions: remoteRead(adapter, requests.actions, repository, now(), { plural: true, normalize: (raw) => sortedShas(arrayOf(raw?.workflow_runs, "Actions"), (a, b) => String(a?.created_at || "").localeCompare(String(b?.created_at || "")) || Number(a?.id) - Number(b?.id), (item) => item?.head_sha) })
  };
}
export function collectPlanningFacts({ root }) { const hashed = (file) => fs.existsSync(path.join(root, file)) ? crypto.createHash("sha256").update(fs.readFileSync(path.join(root, file))).digest("hex") : "absent"; return { ship_windows: [], milestone: hashed(".planning/MILESTONES.md"), state: hashed(".planning/STATE.md") }; }
export function collectRepositoryInventory({ repo, recoveryManifest: manifestPath, expectedManifestSha256, recoveryBundle, artifactAuthorization, finalCaptureAttestation, expectedRepository, observeRemote = false, adapter, now = () => new Date() }) {
  const context = createRepositoryValidationContext({ expectedRepository }); const manifest = readTrustedRecoveryManifest(manifestPath, expectedManifestSha256); requireRecovery(repo, manifest, recoveryBundle); const attestation = readFinalCaptureAttestation(finalCaptureAttestation, manifest); const workflowMetadataChanges = validateFinalArtifactSnapshot(repo, manifest, attestation); if (artifactAuthorization) validateWorkflowMetadataChanges(readWorkflowMetadataAuthorization(artifactAuthorization)); const preserved = new Map(manifest.refs.map((item) => [item.original_ref, item.object])); const resolve = (name) => preserved.get(name) || run(repo, ["rev-parse", `${name}^{}`]);
  const refs = run(repo, ["for-each-ref", "--format=%(refname) %(objectname)"]).split("\n").filter(Boolean).map((line) => { const [name, object] = line.split(" "); return { name, object, role: name === "refs/heads/main" ? "local_main" : name === "refs/remotes/origin/main" ? "cached_origin_main" : name === "refs/tags/v1.61" ? "v161_tag" : "other" }; });
  const remotes = observeRemote ? collectRemoteFacts({ repository: expectedRepository, adapter, now }) : Object.fromEntries(REMOTE_KEYS.map((key) => [key, unavailable(expectedRepository, `GET /repos/${expectedRepository}/${key}`, "unavailable", now())]));
  return validateInventory({ schema_version: 2, repository: expectedRepository, mode: observeRemote ? "live_remote" : "local_only", recovery: { verified: true, manifest_sha256: expectedManifestSha256, bundle_sha256: manifest.bundle_sha256, refs: sorted(manifest.refs.map(({ original_ref, object, encoded_ref, bundle_member }) => ({ original_ref, object, encoded_ref, bundle_member })), (item) => item.original_ref) }, artifacts: { empty_directory_policy: manifest.empty_directory_policy, entries: sorted(manifest.artifacts.map(({ path: entryPath, type, sha256 }) => ({ path: entryPath, type, sha256 })), (item) => `${item.path}\0${item.type}`), ...(workflowMetadataChanges.length ? { authorized_workflow_metadata: workflowMetadataChanges } : {}) }, refs: { local_main: resolve("refs/heads/main"), cached_origin_main: resolve("refs/remotes/origin/main"), milestone_branch: run(repo, ["rev-parse", "HEAD^{commit}"]), v161_tag: resolve("refs/tags/v1.61"), all: sorted(refs, (item) => `${item.name}\0${item.object}`) }, remotes, planning: collectPlanningFacts({ root: repo }), worktrees: [{ branch: run(repo, ["branch", "--show-current"]) || "detached", sha: run(repo, ["rev-parse", "HEAD^{commit}"]), dirty: Boolean(run(repo, ["status", "--porcelain"])) }] }, context);
}
export const collectLocalInventory = (options) => collectRepositoryInventory(options);
function parseArgs(argv) { const result = { observeRemote: false }; for (let index = 0; index < argv.length; index += 1) { if (argv[index] === "--observe-remote") { result.observeRemote = true; continue; } if (argv[index] === "--refresh-cached-refs") fail("--refresh-cached-refs requires separately authorized recovery workflow"); if (!argv[index].startsWith("--") || !argv[index + 1]) fail("usage: --repo OWNER/REPO --recovery-manifest FILE --expected-manifest-sha256 DIGEST --recovery-bundle FILE --final-capture-attestation FILE [--artifact-authorization FILE] [--observe-remote] --out FILE"); result[argv[index].slice(2)] = argv[++index]; } return result; }
function main() { const options = parseArgs(process.argv.slice(2)); if (!options.repo || !options["recovery-manifest"] || !options["expected-manifest-sha256"] || !options["recovery-bundle"] || !options["final-capture-attestation"] || !options.out) fail("--repo, --recovery-manifest, --expected-manifest-sha256, --recovery-bundle, --final-capture-attestation, and --out are required"); const inventory = collectRepositoryInventory({ repo: process.cwd(), recoveryManifest: path.resolve(options["recovery-manifest"]), expectedManifestSha256: options["expected-manifest-sha256"], recoveryBundle: path.resolve(options["recovery-bundle"]), artifactAuthorization: options["artifact-authorization"] ? path.resolve(options["artifact-authorization"]) : undefined, finalCaptureAttestation: path.resolve(options["final-capture-attestation"]), expectedRepository: options.repo, observeRemote: options.observeRemote, adapter: options.observeRemote ? createGhApiReadAdapter({ repository: options.repo }) : undefined }); fs.writeFileSync(options.out, `${JSON.stringify(inventory, null, 2)}\n`, { mode: 0o600 }); }
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) { try { main(); } catch (error) { console.error(`repository inventory collect: FAIL: ${error.message}`); process.exitCode = 1; } }

if (process.env.NODE_TEST_CONTEXT) {
  test("GitHub observation adapter preserves bounded zero, one, and many remote results", () => {
    const sha = (letter) => letter.repeat(40);
    const responses = new Map([
      ["repos/szTheory/accrue/git/ref/heads/main", { object: { sha: sha("a") } }],
      ["repos/szTheory/accrue/pulls?state=open&per_page=100", [{ number: 2, head: { sha: sha("c") } }, { number: 1, head: { sha: sha("b") } }]],
      ["repos/szTheory/accrue/git/matching-refs/heads/release/", []],
      ["repos/szTheory/accrue/actions/runs?per_page=100", { workflow_runs: [{ id: 2, created_at: "2026-01-02T00:00:00Z", head_sha: sha("e") }, { id: 1, created_at: "2026-01-02T00:00:00Z", head_sha: sha("d") }] }]
    ]);
    const adapter = createGhApiReadAdapter({ invoke: (argv) => ({ status: 0, stdout: JSON.stringify(responses.get(argv[1])), stderr: "" }) });
    const facts = collectRemoteFacts({ repository: "szTheory/accrue", adapter, now: () => new Date("2026-09-13T00:00:00.000Z") });
    assert.equal(facts.remote_main.sha, sha("a"));
    assert.deepEqual(facts.pull_requests.shas, [sha("b"), sha("c")]);
    assert.deepEqual(facts.release_branches.shas, []);
    assert.deepEqual(facts.actions.shas, [sha("d"), sha("e")]);
    assert.equal(adapter.calls.length, 4);
    assert.deepEqual(adapter.calls.map((argv) => argv.slice(0, 4)), [
      ["api", "repos/szTheory/accrue/git/ref/heads/main", "--method", "GET"],
      ["api", "repos/szTheory/accrue/pulls?state=open&per_page=100", "--method", "GET"],
      ["api", "repos/szTheory/accrue/git/matching-refs/heads/release/", "--method", "GET"],
      ["api", "repos/szTheory/accrue/actions/runs?per_page=100", "--method", "GET"]
    ]);
    assert.throws(() => adapter.get("GET /repos/szTheory/accrue/issues"), /allowlisted/);
    const unavailableFact = collectRemoteFacts({ repository: "szTheory/accrue", adapter: { get: () => { throw new Error("rate limit 429"); } }, now: () => new Date("2026-09-13T00:00:00.000Z") });
    assert.equal(unavailableFact.actions.reason, "rate_limit");
  });
}
