#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";

const SHA = /^[a-f0-9]{40}$/; const DIGEST = /^[a-f0-9]{64}$/;
const REPOSITORY = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/; const ISO = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
const CONTEXT = Symbol("phase229-context");
const TOP = new Set(["schema_version", "repository", "mode", "capture", "recovery", "artifacts", "refs", "remotes", "planning", "worktrees"]);
const REMOTE_KEYS = ["remote_main", "pull_requests", "release_branches", "actions"];
const ROLES = ["local_main", "cached_origin_main", "milestone_branch", "v161_tag"];
const REASONS = new Set(["network", "authentication", "rate_limit", "timeout", "data_shape", "overflow", "unavailable"]);
const REMOTE_PAGE_SIZE = 100;
const REMOTE_MAX_PAGES = 10;
const REMOTE_MAX_ITEMS = 1_000;
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
  validationContext(context); fields(value, new Set(["repository", "observed_at", "request", "requests", "sha", "shas", "available", "reason", "state"]), "remote fact");
  if (value.repository !== context.expectedRepository) fail("remote fact repository must match expectedRepository"); timestamp(value.observed_at, "remote fact observed_at");
  if (!Object.hasOwn(value, "available") || typeof value.available !== "boolean") fail("remote fact available must be a literal boolean");
  if (!Object.hasOwn(value, "state") || !["observed", "unavailable"].includes(value.state)) fail("remote fact state must be observed or unavailable");
  const validRequest = (request) => typeof request === "string" && new RegExp(`^GET /repos/${context.expectedRepository.replace("/", "\\/")}/`).test(request) && !/[\r\n]/.test(request);
  if (plural) {
    if (Object.hasOwn(value, "request") || !Array.isArray(value.requests) || value.requests.length === 0 || value.requests.some((request) => !validRequest(request))) fail("plural remote fact requests must be an ordered repository-bound GET sequence");
  } else if (!validRequest(value.request) || Object.hasOwn(value, "requests")) fail("remote fact request must be a repository-bound GET request");
  if (value.available) {
    if (value.state !== "observed" || Object.hasOwn(value, "reason")) fail("available remote fact must be observed and contain no unavailable reason");
    if (plural) {
      if (Object.hasOwn(value, "sha") || !Array.isArray(value.shas)) fail("plural remote fact requires a SHA array and no singleton SHA");
      value.shas.forEach((sha) => fullSha(sha, "remote fact SHA"));
      return { repository: value.repository, observed_at: value.observed_at, requests: [...value.requests], available: true, state: "observed", shas: [...value.shas] };
    }
    if (Object.hasOwn(value, "shas")) fail("singleton remote fact must not contain SHA array");
    fullSha(value.sha, "remote fact sha");
    return { repository: value.repository, observed_at: value.observed_at, request: value.request, available: true, state: "observed", sha: value.sha };
  }
  if (value.state !== "unavailable" || Object.hasOwn(value, "sha") || Object.hasOwn(value, "shas") || !REASONS.has(value.reason)) fail("unavailable remote fact must have exact unavailable state, bounded reason, and no claimed remote value");
  return { repository: value.repository, observed_at: value.observed_at, ...(plural ? { requests: [...value.requests] } : { request: value.request }), available: false, state: "unavailable", reason: value.reason };
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
  fields(inventory.remotes, new Set(REMOTE_KEYS), "remotes");
  const remotes = Object.fromEntries(REMOTE_KEYS.map((key) => [key, normalizeRemoteFact(inventory.remotes[key], context, { plural: key !== "remote_main" })]));
  fields(inventory.planning, new Set(["ship_windows", "milestone", "state"]), "planning"); if (!Array.isArray(inventory.planning.ship_windows)) fail("planning.ship_windows must be an array"); for (const key of ["milestone", "state"]) if (typeof inventory.planning[key] !== "string" || /[\r\n]/.test(inventory.planning[key])) fail(`planning.${key} must be sanitized`);
  if (!Array.isArray(inventory.worktrees)) fail("worktrees must be an array"); for (const item of inventory.worktrees) { fields(item, new Set(["branch", "sha", "dirty"]), "worktree"); if (typeof item.branch !== "string" || !item.branch || item.branch.startsWith("/") || item.branch.includes("//") || /[\r\n\\]/.test(item.branch)) fail("worktree branch is unsafe"); fullSha(item.sha, "worktree sha"); if (typeof item.dirty !== "boolean") fail("worktree dirty must be boolean"); }
  fields(inventory.capture, new Set(["captured_at", "active_ref", "commit", "primary_worktree"]), "capture");
  timestamp(inventory.capture.captured_at, "capture.captured_at");
  refName(inventory.capture.active_ref, "capture.active_ref");
  if (!inventory.capture.active_ref.startsWith("refs/heads/")) fail("capture.active_ref must be a symbolic branch ref");
  fullSha(inventory.capture.commit, "capture.commit");
  fields(inventory.capture.primary_worktree, new Set(["branch", "head"]), "capture.primary_worktree");
  refName(inventory.capture.primary_worktree.branch, "capture.primary_worktree.branch");
  fullSha(inventory.capture.primary_worktree.head, "capture.primary_worktree.head");
  if (inventory.capture.primary_worktree.branch !== inventory.capture.active_ref || inventory.capture.primary_worktree.head !== inventory.capture.commit) fail("capture active ref and primary worktree identity must agree");
  if (inventory.refs.milestone_branch !== inventory.capture.commit) fail("capture commit must equal the captured milestone role");
  const activeRows = inventory.refs.all.filter((item) => item.name === inventory.capture.active_ref);
  if (activeRows.length !== 1 || activeRows[0].object !== inventory.capture.commit) fail("capture must match exactly one captured active ref row");
  const activeBranch = inventory.capture.active_ref.slice("refs/heads/".length);
  if (!inventory.worktrees.some((item) => item.branch === activeBranch && item.sha === inventory.capture.commit)) fail("capture must match the captured primary worktree row");
  return { ...inventory, remotes };
}

function readTrustedRecoveryManifest(manifestPath, expectedManifestSha256, context) {
  validationContext(context);
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
    if (manifest.repository !== context.expectedRepository) fail("recovery manifest repository must match expectedRepository");
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
function currentArtifact(repo, entry, { lstatSync = fs.lstatSync, readlinkSync = fs.readlinkSync, readFileSync = fs.readFileSync } = {}) {
  const full = path.join(repo, entry.path); const stat = lstatSync(full);
  if (stat.isSymbolicLink()) {
    const bytes = readlinkSync(full, { encoding: "buffer" });
    if (!Buffer.isBuffer(bytes)) fail(`raw symlink read did not return a Buffer: ${entry.path}`);
    return { type: "symlink", sha256: crypto.createHash("sha256").update(bytes).digest("hex") };
  }
  if (stat.isFile()) return { type: "regular", sha256: crypto.createHash("sha256").update(readFileSync(full)).digest("hex") };
  if (stat.isDirectory()) return { type: "empty_directory", sha256: "not_surfaced" };
  fail(`unsupported artifact type: ${entry.path}`);
}
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
const unavailable = (repository, provenance, reason = "unavailable", now = new Date()) => ({ repository, observed_at: now.toISOString(), ...(Array.isArray(provenance) ? { requests: [...provenance] } : { request: provenance }), available: false, state: "unavailable", reason });
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
function responseJson(result, maxBuffer = GH_MAX_BUFFER) {
  if (result.error) fail(result.error.code === "ETIMEDOUT" ? "timeout" : `network: ${result.error.code || result.error.message}`);
  if (result.status !== 0) fail((result.stderr || "GitHub API unavailable").trim().slice(0, 240));
  if (Buffer.byteLength(result.stdout || "", "utf8") > maxBuffer) fail("overflow");
  try { return JSON.parse(result.stdout); } catch { fail("data_shape: GitHub API response is not JSON"); }
}
function boundedPositiveInteger(value, label, maximum) {
  if (!Number.isInteger(value) || value < 1 || value > maximum) fail(`${label} must be a positive integer no greater than ${maximum}`);
  return value;
}
function ghEndpointFor(request, repository, limits, pageByCategory) {
  if (typeof request !== "string" || !request.startsWith(`GET /repos/${repository}/`)) fail("GitHub API request is not repository-bound");
  const endpoint = request.slice("GET /".length);
  if (endpoint === `repos/${repository}/git/ref/heads/main`) return endpoint;
  const escapedRepository = repository.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pluralPatterns = [
    ["pull_requests", new RegExp(`^repos/${escapedRepository}/pulls\\?state=open&per_page=(\\d+)&page=(\\d+)$`)],
    ["release_branches", new RegExp(`^repos/${escapedRepository}/git/matching-refs/heads/release/\\?per_page=(\\d+)&page=(\\d+)$`)],
    ["actions", new RegExp(`^repos/${escapedRepository}/actions/runs\\?per_page=(\\d+)&page=(\\d+)$`)]
  ];
  const matched = pluralPatterns.map(([category, pattern]) => [category, pattern.exec(endpoint)]).find(([, match]) => match);
  if (!matched) fail("GitHub API request is not allowlisted");
  const [category, match] = matched;
  const pageSize = Number(match[1]); const page = Number(match[2]);
  if (pageSize !== limits.pageSize || page > limits.maxPages) fail("GitHub API pagination parameters exceed the configured bounds");
  const expectedPage = (pageByCategory.get(category) || 0) + 1;
  if (page !== expectedPage) fail("GitHub API pagination must be contiguous and ordered");
  pageByCategory.set(category, page);
  return endpoint;
}
export function createGhApiReadAdapter({ repository = "szTheory/accrue", invoke, pageSize = REMOTE_PAGE_SIZE, maxPages = REMOTE_MAX_PAGES, maxItems = REMOTE_MAX_ITEMS, timeoutMs = GH_TIMEOUT_MS, maxBuffer = GH_MAX_BUFFER } = {}) {
  const context = createRepositoryValidationContext({ expectedRepository: repository });
  const limits = Object.freeze({
    pageSize: boundedPositiveInteger(pageSize, "pageSize", REMOTE_PAGE_SIZE),
    maxPages: boundedPositiveInteger(maxPages, "maxPages", REMOTE_MAX_PAGES),
    maxItems: boundedPositiveInteger(maxItems, "maxItems", REMOTE_MAX_ITEMS),
    timeoutMs: boundedPositiveInteger(timeoutMs, "timeoutMs", GH_TIMEOUT_MS),
    maxBuffer: boundedPositiveInteger(maxBuffer, "maxBuffer", GH_MAX_BUFFER)
  });
  const calls = [];
  const pageByCategory = new Map();
  const execute = invoke || ((argv, options) => spawnSync("gh", argv, options));
  return Object.freeze({
    calls,
    limits,
    get(request) {
      const endpoint = ghEndpointFor(request, context.expectedRepository, limits, pageByCategory);
      const argv = ["api", endpoint, "--method", "GET", "--header", "Accept: application/vnd.github+json"];
      calls.push([...argv]);
      const result = execute([...argv], { encoding: "utf8", shell: false, timeout: limits.timeoutMs, maxBuffer: limits.maxBuffer });
      if (result && typeof result === "object" && "stdout" in result) return responseJson(result, limits.maxBuffer);
      if (typeof result === "string") { try { return JSON.parse(result); } catch { fail("data_shape: GitHub API response is not JSON"); } }
      return result;
    }
  });
}
function remoteRead(adapter, request, repository, now, { plural, normalize }) {
  try {
    const raw = adapter.get(request);
    const value = plural ? { shas: normalize(raw) } : { sha: normalize(raw) };
    return normalizeRemoteFact({ repository, observed_at: now.toISOString(), request, available: true, state: "observed", ...value }, createRepositoryValidationContext({ expectedRepository: repository }), { plural });
  } catch (error) { return unavailable(repository, request, unavailableReason(error), now); }
}
function arrayOf(raw, label, maximum = REMOTE_PAGE_SIZE) { if (!Array.isArray(raw)) fail(`${label} response must be an array`); if (raw.length > maximum) fail("overflow"); return raw; }
function sortedShas(items, compare, sha) {
  const normalized = items.map((item) => ({ item, sha: fullSha(sha(item), "remote result SHA") }));
  return normalized.sort((left, right) => compare(left.item, right.item) || left.sha.localeCompare(right.sha)).map((item) => item.sha);
}
function pluralPageRequest(repository, category, page, pageSize) {
  const suffix = category === "pull_requests" ? `pulls?state=open&per_page=${pageSize}&page=${page}`
    : category === "release_branches" ? `git/matching-refs/heads/release/?per_page=${pageSize}&page=${page}`
      : category === "actions" ? `actions/runs?per_page=${pageSize}&page=${page}` : fail("plural GitHub category is not allowlisted");
  return remoteRequest(repository, suffix);
}
function boundedPluralRemoteRead(adapter, repository, category, observedAt, { extract, normalize }) {
  const context = createRepositoryValidationContext({ expectedRepository: repository });
  const limits = adapter?.limits || { pageSize: REMOTE_PAGE_SIZE, maxPages: REMOTE_MAX_PAGES, maxItems: REMOTE_MAX_ITEMS };
  const requests = []; const items = [];
  try {
    for (let page = 1; page <= limits.maxPages; page += 1) {
      const request = pluralPageRequest(repository, category, page, limits.pageSize);
      requests.push(request);
      const pageItems = arrayOf(extract(adapter.get(request)), category, limits.pageSize);
      if (items.length + pageItems.length > limits.maxItems) fail("overflow");
      items.push(...pageItems);
      if (pageItems.length < limits.pageSize) {
        return normalizeRemoteFact({ repository, observed_at: observedAt.toISOString(), requests, available: true, state: "observed", shas: normalize(items) }, context, { plural: true });
      }
      if (page === limits.maxPages || items.length >= limits.maxItems) fail("overflow");
    }
    fail("overflow");
  } catch (error) {
    return normalizeRemoteFact(unavailable(repository, requests, unavailableReason(error), observedAt), context, { plural: true });
  }
}
export function collectRemoteFacts({ repository, adapter, now = () => new Date() }) {
  const request = (suffix) => remoteRequest(repository, suffix);
  const requests = {
    remote_main: request("git/ref/heads/main"),
    pull_requests: request(`pulls?state=open&per_page=${REMOTE_PAGE_SIZE}&page=1`),
    release_branches: request(`git/matching-refs/heads/release/?per_page=${REMOTE_PAGE_SIZE}&page=1`),
    actions: request(`actions/runs?per_page=${REMOTE_PAGE_SIZE}&page=1`)
  };
  if (!adapter || typeof adapter.get !== "function") return Object.fromEntries(REMOTE_KEYS.map((key) => [key, unavailable(repository, key === "remote_main" ? requests[key] : [requests[key]], "unavailable", now())]));
  return {
    remote_main: remoteRead(adapter, requests.remote_main, repository, now(), { plural: false, normalize: (raw) => fullSha(raw?.object?.sha, "remote main SHA") }),
    pull_requests: boundedPluralRemoteRead(adapter, repository, "pull_requests", now(), { extract: (raw) => raw, normalize: (items) => sortedShas(items, (a, b) => {
      if (!Number.isInteger(a?.number) || a.number < 1 || !Number.isInteger(b?.number) || b.number < 1) fail("pull request number must be a positive integer");
      return a.number - b.number;
    }, (item) => item?.head?.sha) }),
    release_branches: boundedPluralRemoteRead(adapter, repository, "release_branches", now(), { extract: (raw) => raw, normalize: (items) => sortedShas(items, (a, b) => {
      if (typeof a?.ref !== "string" || !a.ref.startsWith("refs/heads/release/") || typeof b?.ref !== "string" || !b.ref.startsWith("refs/heads/release/")) fail("release branch ref must be a release ref");
      return a.ref.localeCompare(b.ref);
    }, (item) => item?.object?.sha) }),
    actions: boundedPluralRemoteRead(adapter, repository, "actions", now(), { extract: (raw) => raw?.workflow_runs, normalize: (items) => sortedShas(items, (a, b) => {
      if (!Number.isInteger(a?.id) || a.id < 1 || !Number.isInteger(b?.id) || b.id < 1) fail("Actions run ID must be a positive integer");
      const leftCreated = Date.parse(a.created_at); const rightCreated = Date.parse(b.created_at);
      if (!Number.isFinite(leftCreated) || !Number.isFinite(rightCreated)) fail("Actions created_at must be an ISO-8601 timestamp");
      return leftCreated - rightCreated || a.id - b.id;
    }, (item) => item?.head_sha) })
  };
}
function boundedFile(root, relative, label) {
  const filename = path.join(root, relative);
  const contents = fs.readFileSync(filename, "utf8");
  if (Buffer.byteLength(contents, "utf8") > GH_MAX_BUFFER) fail(`${label} exceeds its bounded input size`);
  return contents;
}
function frontmatterCount(contents, name) {
  const match = new RegExp(`^${name}:\\s*(\\d+)\\s*$`, "m").exec(contents);
  if (!match) fail(`ship-window authority is missing ${name}`);
  return Number(match[1]);
}
export function readShipWindows({ root, readFile = boundedFile } = {}) {
  const contents = readFile(root, ".planning/WINDOWS.md", "ship-window authority");
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
  const total = frontmatterCount(contents, "total_count");
  if (total !== rows.length || frontmatterCount(contents, "open_count") !== rows.filter((row) => row.status === "open").length || frontmatterCount(contents, "waived_count") !== rows.filter((row) => row.status === "waived").length || frontmatterCount(contents, "fixed_count") !== rows.filter((row) => row.status === "fixed").length) fail("ship-window authority counts are inconsistent");
  return rows.sort((left, right) => left.id - right.id).map((row) => `${row.id}:${row.status}`);
}
export function parseWorktreePorcelain(output, dirtyForPath) {
  if (typeof output !== "string" || typeof dirtyForPath !== "function") fail("worktree porcelain input is invalid");
  const rows = []; let current = null;
  const finish = () => {
    if (!current) return;
    if (!current.path || !current.sha || (!current.branch && !current.detached)) fail("worktree porcelain record is incomplete");
    rows.push({ branch: current.detached ? "detached" : current.branch.replace(/^refs\/heads\//, ""), sha: fullSha(current.sha, "worktree SHA"), dirty: Boolean(dirtyForPath(current.path)) }); current = null;
  };
  for (const line of output.split("\n")) {
    if (!line) { finish(); continue; }
    if (line.startsWith("worktree ")) { finish(); current = { path: line.slice(9) }; }
    else if (!current) fail("worktree porcelain record has no worktree header");
    else if (line.startsWith("HEAD ")) current.sha = line.slice(5);
    else if (line.startsWith("branch ")) current.branch = line.slice(7);
    else if (line === "detached") current.detached = true;
    else if (line === "bare") fail("bare worktree records are not inventory worktrees");
    else fail("worktree porcelain record is malformed");
  }
  finish();
  if (!rows.length) fail("worktree porcelain has no records");
  return rows.sort((left, right) => left.branch.localeCompare(right.branch) || left.sha.localeCompare(right.sha) || Number(left.dirty) - Number(right.dirty));
}
export function collectWorktrees({ repo }) {
  const result = spawnSync("git", ["-C", repo, "worktree", "list", "--porcelain"], { encoding: "utf8", timeout: 15_000, maxBuffer: GH_MAX_BUFFER });
  if (result.error || result.status !== 0) fail("git worktree list failed");
  return parseWorktreePorcelain(result.stdout, (worktreePath) => Boolean(run(worktreePath, ["status", "--porcelain"])));
}
export function collectPlanningFacts({ root }) {
  const hashed = (file) => fs.existsSync(path.join(root, file)) ? crypto.createHash("sha256").update(fs.readFileSync(path.join(root, file))).digest("hex") : "absent";
  let shipWindows;
  try { shipWindows = readShipWindows({ root }); } catch (error) { if (error?.code === "ENOENT") shipWindows = []; else throw error; }
  return { ship_windows: shipWindows, milestone: hashed(".planning/MILESTONES.md"), state: hashed(".planning/STATE.md") };
}
export function collectCaptureAnchor({ repo, capturedAt = new Date() }) {
  const activeRef = run(repo, ["symbolic-ref", "--quiet", "HEAD"]);
  if (!activeRef.startsWith("refs/heads/")) fail("active repository ref must be a symbolic branch");
  const commit = fullSha(run(repo, ["rev-parse", "HEAD^{commit}"]), "captured commit");
  return {
    captured_at: timestamp(capturedAt.toISOString(), "capture.captured_at"),
    active_ref: activeRef,
    commit,
    primary_worktree: { branch: activeRef, head: commit }
  };
}
export function collectRepositoryInventory({ repo, recoveryManifest: manifestPath, expectedManifestSha256, recoveryBundle, artifactAuthorization, finalCaptureAttestation, expectedRepository, observeRemote = false, adapter, now = () => new Date() }) {
  const context = createRepositoryValidationContext({ expectedRepository }); const manifest = readTrustedRecoveryManifest(manifestPath, expectedManifestSha256, context); requireRecovery(repo, manifest, recoveryBundle); const attestation = readFinalCaptureAttestation(finalCaptureAttestation, manifest); const workflowMetadataChanges = validateFinalArtifactSnapshot(repo, manifest, attestation); if (artifactAuthorization) validateWorkflowMetadataChanges(readWorkflowMetadataAuthorization(artifactAuthorization)); const capture = collectCaptureAnchor({ repo, capturedAt: now() }); const preserved = new Map(manifest.refs.map((item) => [item.original_ref, item.object])); const resolve = (name) => preserved.get(name) || run(repo, ["rev-parse", `${name}^{}`]);
  const refs = run(repo, ["for-each-ref", "--format=%(refname) %(objectname)"]).split("\n").filter(Boolean).map((line) => { const [name, object] = line.split(" "); return { name, object, role: name === "refs/heads/main" ? "local_main" : name === "refs/remotes/origin/main" ? "cached_origin_main" : name === "refs/tags/v1.61" ? "v161_tag" : "other" }; });
  const remotes = collectRemoteFacts({ repository: expectedRepository, adapter: observeRemote ? adapter : undefined, now });
  return validateInventory({ schema_version: 2, repository: expectedRepository, mode: observeRemote ? "live_remote" : "local_only", capture, recovery: { verified: true, manifest_sha256: expectedManifestSha256, bundle_sha256: manifest.bundle_sha256, refs: sorted(manifest.refs.map(({ original_ref, object, encoded_ref, bundle_member }) => ({ original_ref, object, encoded_ref, bundle_member })), (item) => item.original_ref) }, artifacts: { empty_directory_policy: manifest.empty_directory_policy, entries: sorted(manifest.artifacts.map(({ path: entryPath, type, sha256 }) => ({ path: entryPath, type, sha256 })), (item) => `${item.path}\0${item.type}`), ...(workflowMetadataChanges.length ? { authorized_workflow_metadata: workflowMetadataChanges } : {}) }, refs: { local_main: resolve("refs/heads/main"), cached_origin_main: resolve("refs/remotes/origin/main"), milestone_branch: capture.commit, v161_tag: resolve("refs/tags/v1.61"), all: sorted(refs, (item) => `${item.name}\0${item.object}`) }, remotes, planning: collectPlanningFacts({ root: repo }), worktrees: collectWorktrees({ repo }) }, context);
}
export const collectLocalInventory = (options) => collectRepositoryInventory(options);
function parseArgs(argv) { const result = { observeRemote: false }; for (let index = 0; index < argv.length; index += 1) { if (argv[index] === "--observe-remote") { result.observeRemote = true; continue; } if (argv[index] === "--refresh-cached-refs") fail("--refresh-cached-refs requires separately authorized recovery workflow"); if (!argv[index].startsWith("--") || !argv[index + 1]) fail("usage: --repo OWNER/REPO --recovery-manifest FILE --expected-manifest-sha256 DIGEST --recovery-bundle FILE --final-capture-attestation FILE [--artifact-authorization FILE] [--observe-remote] --out FILE"); result[argv[index].slice(2)] = argv[++index]; } return result; }
function main() { const options = parseArgs(process.argv.slice(2)); if (!options.repo || !options["recovery-manifest"] || !options["expected-manifest-sha256"] || !options["recovery-bundle"] || !options["final-capture-attestation"] || !options.out) fail("--repo, --recovery-manifest, --expected-manifest-sha256, --recovery-bundle, --final-capture-attestation, and --out are required"); const inventory = collectRepositoryInventory({ repo: process.cwd(), recoveryManifest: path.resolve(options["recovery-manifest"]), expectedManifestSha256: options["expected-manifest-sha256"], recoveryBundle: path.resolve(options["recovery-bundle"]), artifactAuthorization: options["artifact-authorization"] ? path.resolve(options["artifact-authorization"]) : undefined, finalCaptureAttestation: path.resolve(options["final-capture-attestation"]), expectedRepository: options.repo, observeRemote: options.observeRemote, adapter: options.observeRemote ? createGhApiReadAdapter({ repository: options.repo }) : undefined }); fs.writeFileSync(options.out, `${JSON.stringify(inventory, null, 2)}\n`, { mode: 0o600 }); }
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) { try { main(); } catch (error) { console.error(`repository inventory collect: FAIL: ${error.message}`); process.exitCode = 1; } }

if (process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  function generatedArtifactFixture() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase229-artifact-flow-"));
    const repo = path.join(scratch, "repo"); const capsule = path.join(scratch, "capsule");
    fs.mkdirSync(repo); fs.mkdirSync(capsule);
    run(repo, ["init", "-q", "-b", "main"]);
    run(repo, ["config", "user.email", "phase229@example.invalid"]);
    run(repo, ["config", "user.name", "Phase 229"]);
    fs.writeFileSync(path.join(repo, "tracked"), "tracked\n");
    run(repo, ["add", "tracked"]); run(repo, ["commit", "-qm", "fixture"]);
    const object = run(repo, ["rev-parse", "HEAD"]);
    run(repo, ["update-ref", "refs/remotes/origin/main", object]); run(repo, ["tag", "v1.61", object]);
    fs.mkdirSync(path.join(repo, ".planning"));
    fs.writeFileSync(path.join(repo, ".planning/milestone.lock"), "before lock\n");
    fs.writeFileSync(path.join(repo, ".planning/state.json"), "before state\n");
    const rawLink = Buffer.from([0xff, 0xfe, 0x0a]); const linkPath = path.join(repo, "raw-link");
    try { fs.symlinkSync(rawLink, linkPath); } catch (error) {
      fs.rmSync(scratch, { recursive: true, force: true });
      fail(`raw-byte symlink fixture is unsupported and must fail closed: ${error.message}`);
    }
    const bundle = path.join(capsule, "recovery.bundle"); const manifestPath = path.join(capsule, "manifest.json");
    const preserve = spawnSync("bash", [path.join(process.cwd(), "scripts/ci/preserve_repository_state.sh"), "--repo-root", repo, "--expected-repository", "szTheory/accrue", "--bundle-out", bundle, "--private-manifest-out", manifestPath], { encoding: "utf8", shell: false, timeout: 30_000, maxBuffer: 1_000_000 });
    assert.equal(preserve.status, 0, preserve.stderr);
    const manifestBytes = fs.readFileSync(manifestPath); const manifest = JSON.parse(manifestBytes);
    const expectedLinkDigest = crypto.createHash("sha256").update(rawLink).digest("hex");
    assert.equal(manifest.artifacts.find((entry) => entry.path === "raw-link")?.sha256, expectedLinkDigest, "preservation freezes exact invalid-UTF-8 and trailing-newline link bytes");
    fs.writeFileSync(path.join(repo, ".planning/milestone.lock"), "after lock\n");
    fs.writeFileSync(path.join(repo, ".planning/state.json"), "after state\n");
    const artifacts = manifest.artifacts.map((entry) => {
      const workflow = WORKFLOW_METADATA_PATHS.has(entry.path);
      const after = workflow ? crypto.createHash("sha256").update(fs.readFileSync(path.join(repo, entry.path))).digest("hex") : entry.sha256;
      return { path: entry.path, type: entry.type, before_sha256: entry.sha256, after_sha256: after, state: workflow ? "workflow_metadata_refreshed" : "unchanged" };
    });
    const attestationPath = path.join(capsule, "attestation.json");
    fs.writeFileSync(attestationPath, JSON.stringify({ schema_version: 1, purpose: "phase229_final_capture", observed_at: "2026-09-13T00:00:00.000Z", artifacts }), { mode: 0o600 });
    fs.chmodSync(attestationPath, 0o600);
    return { scratch, repo, capsule, bundle, manifestPath, manifest, expectedManifestSha256: crypto.createHash("sha256").update(manifestBytes).digest("hex"), attestationPath, expectedLinkDigest, linkPath };
  }

  test("CR-02 final collection preserves raw invalid-UTF-8 symlink bytes", () => {
    const fixture = generatedArtifactFixture();
    try {
      const inventory = collectRepositoryInventory({ repo: fixture.repo, recoveryManifest: fixture.manifestPath, expectedManifestSha256: fixture.expectedManifestSha256, recoveryBundle: fixture.bundle, finalCaptureAttestation: fixture.attestationPath, expectedRepository: "szTheory/accrue" });
      assert.equal(inventory.artifacts.entries.find((entry) => entry.path === "raw-link")?.sha256, fixture.expectedLinkDigest);
      const linkEntry = fixture.manifest.artifacts.find((entry) => entry.path === "raw-link");
      assert.equal(currentArtifact(fixture.repo, linkEntry, { readFileSync() { throw new Error("symlink target must never be opened"); } }).sha256, fixture.expectedLinkDigest);
      assert.throws(() => currentArtifact(fixture.repo, linkEntry, { readlinkSync: () => "decoded" }), /did not return a Buffer/);
      assert.throws(() => currentArtifact(fixture.repo, linkEntry, { readlinkSync() { throw new Error("raw-byte access unsupported"); } }), /raw-byte access unsupported/);
      fs.rmSync(fixture.linkPath); fs.symlinkSync(Buffer.from([0xff, 0xfd, 0x0a]), fixture.linkPath);
      assert.throws(() => collectRepositoryInventory({ repo: fixture.repo, recoveryManifest: fixture.manifestPath, expectedManifestSha256: fixture.expectedManifestSha256, recoveryBundle: fixture.bundle, finalCaptureAttestation: fixture.attestationPath, expectedRepository: "szTheory/accrue" }), /artifact changed|post-invariant mismatch/);
    } finally { fs.rmSync(fixture.scratch, { recursive: true, force: true }); }
  });

  const remoteSchemaFixture = () => ({
    schema_version: 2,
    repository: "szTheory/accrue",
    mode: "local_only",
    recovery: {
      verified: true,
      manifest_sha256: "1".repeat(64),
      bundle_sha256: "2".repeat(64),
      refs: [{ original_ref: "refs/heads/main", object: "a".repeat(40), encoded_ref: encodedRef("refs/heads/main"), bundle_member: true }]
    },
    artifacts: { empty_directory_policy: "not_surfaced_by_git", entries: [] },
    refs: {
      local_main: "a".repeat(40),
      cached_origin_main: "b".repeat(40),
      milestone_branch: "c".repeat(40),
      v161_tag: "d".repeat(40),
      all: [{ name: "refs/heads/milestone", object: "c".repeat(40), role: "other" }]
    },
    remotes: {
      remote_main: { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", request: "GET /repos/szTheory/accrue/git/ref/heads/main", available: true, state: "observed", sha: "e".repeat(40) },
      pull_requests: { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", requests: ["GET /repos/szTheory/accrue/pulls?state=open&per_page=100&page=1"], available: true, state: "observed", shas: [] },
      release_branches: { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", requests: ["GET /repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1"], available: true, state: "observed", shas: ["f".repeat(40)] },
      actions: { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", requests: ["GET /repos/szTheory/accrue/actions/runs?per_page=100&page=1"], available: false, state: "unavailable", reason: "network" }
    },
    planning: { ship_windows: [], milestone: "absent", state: "absent" },
    worktrees: [{ branch: "milestone", sha: "c".repeat(40), dirty: false }],
    capture: {
      captured_at: "2026-09-13T00:00:00.000Z",
      active_ref: "refs/heads/milestone",
      commit: "c".repeat(40),
      primary_worktree: { branch: "refs/heads/milestone", head: "c".repeat(40) }
    }
  });

  test("CR-09 remote facts require exact non-coercive availability and state", async () => {
    const context = createRepositoryValidationContext({ expectedRepository: "szTheory/accrue" });
    const valid = remoteSchemaFixture();
    const normalized = validateInventory(valid, context);
    for (const key of REMOTE_KEYS) {
      assert.notEqual(normalized.remotes[key], valid.remotes[key], `${key} is replaced by its normalized value`);
      assert.equal(typeof normalized.remotes[key].available, "boolean");
    }

    const invalidFacts = [];
    for (const available of [undefined, null, 0, 1, "true", "false"]) {
      const fact = structuredClone(valid.remotes.remote_main);
      if (available === undefined) delete fact.available; else fact.available = available;
      invalidFacts.push(fact);
    }
    for (const [available, state] of [[true, "unavailable"], [true, "fabricated"], [false, "observed"], [false, "fabricated"]]) {
      const fact = available ? structuredClone(valid.remotes.remote_main) : structuredClone(valid.remotes.actions);
      fact.available = available;
      fact.state = state;
      invalidFacts.push(fact);
    }
    invalidFacts.push(
      { ...valid.remotes.remote_main, reason: "network" },
      { ...valid.remotes.remote_main, shas: ["f".repeat(40)] },
      { ...valid.remotes.actions, sha: "f".repeat(40) },
      { ...valid.remotes.pull_requests, sha: "f".repeat(40) },
      { ...valid.remotes.actions, shas: ["f".repeat(40)] }
    );
    for (const fact of invalidFacts) {
      const candidate = remoteSchemaFixture();
      candidate.remotes.remote_main = fact;
      assert.throws(() => validateInventory(candidate, context), /remote fact|singleton/);
    }
    assert.throws(() => normalizeRemoteFact({ ...valid.remotes.remote_main, reason: undefined }, context), /unavailable reason/);
    assert.throws(() => normalizeRemoteFact({ ...valid.remotes.remote_main, shas: undefined }, context), /SHA array/);
    assert.throws(() => normalizeRemoteFact({ ...valid.remotes.pull_requests, sha: undefined }, context, { plural: true }), /singleton SHA/);
    assert.throws(() => normalizeRemoteFact({ ...valid.remotes.actions, shas: undefined }, context, { plural: true }), /claimed remote value/);

    const unavailablePlural = normalizeRemoteFact(valid.remotes.actions, context, { plural: true });
    assert.deepEqual(unavailablePlural, valid.remotes.actions, "unavailable plural provenance survives normalization exactly");
    const source = remoteSchemaFixture();
    const checked = validateInventory(source, context);
    source.remotes.actions.requests[0] = "GET /repos/szTheory/accrue/issues";
    assert.deepEqual(checked.remotes.actions.requests, ["GET /repos/szTheory/accrue/actions/runs?per_page=100&page=1"], "validated rows do not retain caller aliases");

    const malformed = remoteSchemaFixture();
    delete malformed.remotes.remote_main.available;
    malformed.remotes.remote_main.state = "fabricated";
    const { renderRepositoryInventory } = await import("./render_repository_inventory.mjs");
    assert.throws(() => renderRepositoryInventory(malformed, context), /remote fact/);
  });

  test("captured-at anchor binds the active ref and primary worktree without paths", async () => {
    const context = createRepositoryValidationContext({ expectedRepository: "szTheory/accrue" });
    const fixture = remoteSchemaFixture();
    const checked = validateInventory(fixture, context);
    assert.deepEqual(checked.capture, fixture.capture);
    const { renderRepositoryInventory } = await import("./render_repository_inventory.mjs");
    const rendered = renderRepositoryInventory(fixture, context);
    assert.equal(rendered, renderRepositoryInventory(fixture, context), "capture projection is byte-stable across repeated renders");
    assert.match(rendered, /refs\/heads\/milestone/);
    assert.match(rendered, new RegExp("c{40}"));
    assert.deepEqual(Object.keys(checked.capture).sort(), ["active_ref", "captured_at", "commit", "primary_worktree"]);

    for (const mutate of [
      (candidate) => { delete candidate.capture; },
      (candidate) => { candidate.capture.commit = "d".repeat(40); },
      (candidate) => { candidate.capture.active_ref = "refs/heads/other"; },
      (candidate) => { candidate.capture.primary_worktree.branch = "refs/heads/other"; },
      (candidate) => { candidate.capture.primary_worktree.head = "d".repeat(40); },
      (candidate) => { candidate.capture.path = "forbidden"; }
    ]) {
      const candidate = remoteSchemaFixture();
      mutate(candidate);
      assert.throws(() => validateInventory(candidate, context), /capture|inventory/);
    }

    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase229-capture-"));
    try {
      run(scratch, ["init", "-q", "-b", "phase-229"]);
      run(scratch, ["config", "user.email", "phase229@example.invalid"]);
      run(scratch, ["config", "user.name", "Phase 229"]);
      fs.writeFileSync(path.join(scratch, "tracked"), "capture\n");
      run(scratch, ["add", "tracked"]);
      run(scratch, ["commit", "-qm", "capture"]);
      const anchor = collectCaptureAnchor({ repo: scratch, capturedAt: new Date("2026-09-13T00:00:00.000Z") });
      assert.deepEqual(anchor, {
        captured_at: "2026-09-13T00:00:00.000Z",
        active_ref: "refs/heads/phase-229",
        commit: run(scratch, ["rev-parse", "HEAD^{commit}"]),
        primary_worktree: { branch: "refs/heads/phase-229", head: run(scratch, ["rev-parse", "HEAD^{commit}"]) }
      });
      assert.equal(JSON.stringify(anchor).includes(scratch), false);
    } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
  });

  test("open pull requests require terminal page proof", () => {
    const indexedSha = (index) => index.toString(16).padStart(40, "0");
    const firstPage = Array.from({ length: 100 }, (_, index) => ({ number: index + 1, head: { sha: indexedSha(index + 1) } }));
    const responses = new Map([
      ["repos/szTheory/accrue/git/ref/heads/main", { object: { sha: indexedSha(200) } }],
      ["repos/szTheory/accrue/pulls?state=open&per_page=100&page=1", firstPage],
      ["repos/szTheory/accrue/pulls?state=open&per_page=100&page=2", [{ number: 101, head: { sha: indexedSha(101) } }]],
      ["repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1", []],
      ["repos/szTheory/accrue/actions/runs?per_page=100&page=1", { workflow_runs: [] }]
    ]);
    const adapter = createGhApiReadAdapter({ invoke: (argv) => ({ status: 0, stdout: JSON.stringify(responses.get(argv[1])), stderr: "" }) });

    const facts = collectRemoteFacts({ repository: "szTheory/accrue", adapter, now: () => new Date("2026-09-13T00:00:00.000Z") });

    assert.equal(facts.pull_requests.available, true);
    assert.deepEqual(facts.pull_requests.shas, [...firstPage.map((item) => item.head.sha), indexedSha(101)]);
    assert.deepEqual(facts.pull_requests.requests, [
      "GET /repos/szTheory/accrue/pulls?state=open&per_page=100&page=1",
      "GET /repos/szTheory/accrue/pulls?state=open&per_page=100&page=2"
    ]);

    const emptyResponses = new Map([
      ["repos/szTheory/accrue/git/ref/heads/main", { object: { sha: indexedSha(200) } }],
      ["repos/szTheory/accrue/pulls?state=open&per_page=100&page=1", []],
      ["repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1", []],
      ["repos/szTheory/accrue/actions/runs?per_page=100&page=1", { workflow_runs: [] }]
    ]);
    const emptyAdapter = createGhApiReadAdapter({ invoke: (argv) => ({ status: 0, stdout: JSON.stringify(emptyResponses.get(argv[1])), stderr: "" }) });
    const empty = collectRemoteFacts({ repository: "szTheory/accrue", adapter: emptyAdapter, now: () => new Date("2026-09-13T00:00:00.000Z") });
    assert.deepEqual(empty.pull_requests.shas, []);
    assert.deepEqual(empty.pull_requests.requests, ["GET /repos/szTheory/accrue/pulls?state=open&per_page=100&page=1"]);

    const overflowAdapter = createGhApiReadAdapter({ maxPages: 1, invoke: (argv) => ({ status: 0, stdout: JSON.stringify(responses.get(argv[1])), stderr: "" }) });
    const overflow = collectRemoteFacts({ repository: "szTheory/accrue", adapter: overflowAdapter, now: () => new Date("2026-09-13T00:00:00.000Z") });
    assert.equal(overflow.pull_requests.available, false);
    assert.equal(overflow.pull_requests.reason, "overflow");
    assert.equal("shas" in overflow.pull_requests, false);
    assert.deepEqual(overflow.pull_requests.requests, ["GET /repos/szTheory/accrue/pulls?state=open&per_page=100&page=1"]);
  });
  test("release refs and Actions require terminal page proof", () => {
    const indexedSha = (index) => index.toString(16).padStart(40, "0");
    const releasePage = Array.from({ length: 100 }, (_, index) => ({ ref: `refs/heads/release/${String(100 - index).padStart(3, "0")}`, object: { sha: indexedSha(index + 1) } }));
    const actionsPage = Array.from({ length: 100 }, (_, index) => ({ id: 100 - index, created_at: "2026-01-01T00:00:00Z", head_sha: indexedSha(index + 201) }));
    const responses = new Map([
      ["repos/szTheory/accrue/git/ref/heads/main", { object: { sha: indexedSha(500) } }],
      ["repos/szTheory/accrue/pulls?state=open&per_page=100&page=1", []],
      ["repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1", releasePage],
      ["repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=2", [{ ref: "refs/heads/release/101", object: { sha: indexedSha(101) } }]],
      ["repos/szTheory/accrue/actions/runs?per_page=100&page=1", { workflow_runs: actionsPage }],
      ["repos/szTheory/accrue/actions/runs?per_page=100&page=2", { workflow_runs: [{ id: 101, created_at: "2026-01-02T00:00:00Z", head_sha: indexedSha(301) }] }]
    ]);
    const adapter = createGhApiReadAdapter({ invoke: (argv) => ({ status: 0, stdout: JSON.stringify(responses.get(argv[1])), stderr: "" }) });

    const facts = collectRemoteFacts({ repository: "szTheory/accrue", adapter, now: () => new Date("2026-09-13T00:00:00.000Z") });

    assert.equal(facts.release_branches.available, true);
    assert.equal(facts.release_branches.shas.length, 101);
    assert.equal(facts.release_branches.shas.at(-1), indexedSha(101));
    assert.deepEqual(facts.release_branches.requests, [
      "GET /repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1",
      "GET /repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=2"
    ]);
    assert.equal(facts.actions.available, true);
    assert.equal(facts.actions.shas.length, 101);
    assert.equal(facts.actions.shas.at(-1), indexedSha(301));
    assert.deepEqual(facts.actions.requests, [
      "GET /repos/szTheory/accrue/actions/runs?per_page=100&page=1",
      "GET /repos/szTheory/accrue/actions/runs?per_page=100&page=2"
    ]);
  });
  test("plural pagination failures discard partial remote values", () => {
    const sha = (letter) => letter.repeat(40);
    const responses = new Map([
      ["repos/szTheory/accrue/git/ref/heads/main", { object: { sha: sha("a") } }],
      ["repos/szTheory/accrue/pulls?state=open&per_page=2&page=1", []],
      ["repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=2&page=1", []],
      ["repos/szTheory/accrue/actions/runs?per_page=2&page=1", { workflow_runs: [{ id: 2, created_at: "2026-01-02T00:00:00Z", head_sha: sha("b") }, { id: 1, created_at: "2026-01-01T00:00:00Z", head_sha: sha("c") }] }]
    ]);
    const adapter = createGhApiReadAdapter({ pageSize: 2, invoke: (argv) => argv[1].endsWith("actions/runs?per_page=2&page=2") ? { status: 1, stdout: "", stderr: "network ECONNRESET" } : { status: 0, stdout: JSON.stringify(responses.get(argv[1])), stderr: "" } });
    const facts = collectRemoteFacts({ repository: "szTheory/accrue", adapter, now: () => new Date("2026-09-13T00:00:00.000Z") });
    assert.deepEqual(facts.actions, {
      repository: "szTheory/accrue",
      observed_at: "2026-09-13T00:00:00.000Z",
      requests: [
        "GET /repos/szTheory/accrue/actions/runs?per_page=2&page=1",
        "GET /repos/szTheory/accrue/actions/runs?per_page=2&page=2"
      ],
      available: false,
      state: "unavailable",
      reason: "network"
    });

    const malformed = createGhApiReadAdapter({ pageSize: 2, invoke: (argv) => ({ status: 0, stdout: JSON.stringify(argv[1].includes("actions/runs") ? { workflow_runs: {} } : responses.get(argv[1])), stderr: "" }) });
    assert.equal(collectRemoteFacts({ repository: "szTheory/accrue", adapter: malformed, now: () => new Date("2026-09-13T00:00:00.000Z") }).actions.reason, "data_shape");

    const overflowResponses = new Map(responses);
    overflowResponses.set("repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=2&page=1", [{ ref: "refs/heads/release/1", object: { sha: sha("d") } }, { ref: "refs/heads/release/2", object: { sha: sha("e") } }]);
    overflowResponses.set("repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=2&page=2", [{ ref: "refs/heads/release/3", object: { sha: sha("f") } }, { ref: "refs/heads/release/4", object: { sha: sha("0") } }]);
    overflowResponses.set("repos/szTheory/accrue/actions/runs?per_page=2&page=1", { workflow_runs: [] });
    const itemOverflow = createGhApiReadAdapter({ pageSize: 2, maxItems: 3, invoke: (argv) => ({ status: 0, stdout: JSON.stringify(overflowResponses.get(argv[1])), stderr: "" }) });
    const overflow = collectRemoteFacts({ repository: "szTheory/accrue", adapter: itemOverflow, now: () => new Date("2026-09-13T00:00:00.000Z") }).release_branches;
    assert.equal(overflow.reason, "overflow");
    assert.equal("shas" in overflow, false);

    const bufferBound = createGhApiReadAdapter({ maxBuffer: 16, invoke: () => ({ status: 0, stdout: JSON.stringify({ oversized: "x".repeat(32) }), stderr: "" }) });
    const bufferFacts = collectRemoteFacts({ repository: "szTheory/accrue", adapter: bufferBound, now: () => new Date("2026-09-13T00:00:00.000Z") });
    for (const fact of Object.values(bufferFacts)) assert.equal(fact.reason, "overflow");
  });
  test("GitHub plural endpoint allowlist enforces normalized contiguous pages", () => {
    const response = () => ({ status: 0, stdout: "[]", stderr: "" });
    const duplicate = createGhApiReadAdapter({ invoke: response });
    duplicate.get("GET /repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1");
    assert.throws(() => duplicate.get("GET /repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1"), /contiguous and ordered/);
    for (const request of [
      "GET /repos/szTheory/accrue/pulls?state=open&page=1&per_page=100",
      "GET /repos/szTheory/accrue/actions/runs?page=1&per_page=100",
      "GET /repos/szTheory/accrue/actions/runs?per_page=x&page=1",
      "GET /repos/szTheory/accrue/actions/runs?per_page=100&page=11",
      "GET /repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=2",
      "GET /repos/szTheory/accrue/issues?per_page=100&page=1"
    ]) assert.throws(() => createGhApiReadAdapter({ invoke: response }).get(request), /allowlisted|bounds|contiguous/);
    assert.throws(() => createGhApiReadAdapter({ pageSize: 101 }), /pageSize/);
    assert.throws(() => createGhApiReadAdapter({ maxPages: 11 }), /maxPages/);
    assert.throws(() => createGhApiReadAdapter({ maxItems: 1_001 }), /maxItems/);

    let processOptions;
    const bounded = createGhApiReadAdapter({ timeoutMs: 123, maxBuffer: 456, invoke: (_argv, options) => { processOptions = options; return { status: 0, stdout: JSON.stringify({ object: { sha: "a".repeat(40) } }), stderr: "" }; } });
    bounded.get("GET /repos/szTheory/accrue/git/ref/heads/main");
    assert.deepEqual(processOptions, { encoding: "utf8", shell: false, timeout: 123, maxBuffer: 456 });
    assert.deepEqual(Object.keys(bounded).sort(), ["calls", "get", "limits"]);
  });
  test("GitHub observation adapter preserves bounded zero, one, and many remote results", () => {
    const sha = (letter) => letter.repeat(40);
    const responses = new Map([
      ["repos/szTheory/accrue/git/ref/heads/main", { object: { sha: sha("a") } }],
      ["repos/szTheory/accrue/pulls?state=open&per_page=100&page=1", [{ number: 2, head: { sha: sha("c") } }, { number: 1, head: { sha: sha("b") } }]],
      ["repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1", []],
      ["repos/szTheory/accrue/actions/runs?per_page=100&page=1", { workflow_runs: [{ id: 2, created_at: "2026-01-02T00:00:00Z", head_sha: sha("e") }, { id: 1, created_at: "2026-01-02T00:00:00Z", head_sha: sha("d") }] }]
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
      ["api", "repos/szTheory/accrue/pulls?state=open&per_page=100&page=1", "--method", "GET"],
      ["api", "repos/szTheory/accrue/git/matching-refs/heads/release/?per_page=100&page=1", "--method", "GET"],
      ["api", "repos/szTheory/accrue/actions/runs?per_page=100&page=1", "--method", "GET"]
    ]);
    assert.throws(() => adapter.get("GET /repos/szTheory/accrue/issues"), /allowlisted/);
    for (const [message, reason] of [["rate limit 429", "rate_limit"], ["authentication 401", "authentication"], ["timeout ETIMEDOUT", "timeout"], ["network ENOTFOUND", "network"], ["malformed payload", "data_shape"], ["maxBuffer overflow", "overflow"]]) {
      const unavailableFact = collectRemoteFacts({ repository: "szTheory/accrue", adapter: { get: () => { throw new Error(message); } }, now: () => new Date("2026-09-13T00:00:00.000Z") });
      assert.equal(unavailableFact.actions.reason, reason);
      assert.equal("shas" in unavailableFact.actions, false);
    }
  });
  test("repository truth exposes sanitized worktree and ship-window collectors", () => {
    assert.equal(typeof collectWorktrees, "function");
    assert.equal(typeof readShipWindows, "function");
    const porcelain = ["worktree /private/a", `HEAD ${"a".repeat(40)}`, "branch refs/heads/main", "", "worktree /private/b", `HEAD ${"b".repeat(40)}`, "detached", ""].join("\n");
    assert.deepEqual(parseWorktreePorcelain(porcelain, (item) => item.endsWith("b")), [{ branch: "detached", sha: "b".repeat(40), dirty: true }, { branch: "main", sha: "a".repeat(40), dirty: false }]);
    const windows = "---\nopen_count: 1\nwaived_count: 0\nfixed_count: 0\ntotal_count: 1\n---\n| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n| 7 | 229 | deviation | file |  | reason | open |  | now |  |\n";
    assert.deepEqual(readShipWindows({ root: "/fixture", readFile: () => windows }), ["7:open"]);
  });
}
