#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const SHA = /^[a-f0-9]{40}$/;
const DIGEST = /^[a-f0-9]{64}$/;
const REPOSITORY = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const CONTEXT = Symbol("phase229-context");
const TOP_LEVEL = new Set(["schema_version", "repository", "mode", "recovery", "artifacts", "refs", "remotes", "planning", "worktrees"]);

function fail(message) { throw new Error(message); }
function fields(value, allowed, label) {
  if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`);
  for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`);
}
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase SHA`); return value; }
function digest(value, label) { if (typeof value !== "string" || !DIGEST.test(value)) fail(`${label} must be a SHA-256 digest`); return value; }
function relativePath(value, label) {
  if (typeof value !== "string" || !value || value.startsWith("/") || value.includes("\\") || value.split("/").some((part) => !part || part === "." || part === "..") || /[\0-\x1f\x7f]/.test(value)) fail(`${label} must be a normalized repository-relative path`);
  return value;
}
function run(repo, args) {
  const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8" });
  if (result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || "unknown error").trim()}`);
  return result.stdout.trim();
}

export function createRepositoryValidationContext({ expectedRepository } = {}) {
  if (typeof expectedRepository !== "string" || !REPOSITORY.test(expectedRepository)) fail("expectedRepository must be an owner/repository string");
  return Object.freeze({ expectedRepository, [CONTEXT]: true });
}
function context(value) { if (!value || value[CONTEXT] !== true || !Object.isFrozen(value)) fail("validationContext must be created by createRepositoryValidationContext"); return value; }

export function validateInventory(inventory, validationContext) {
  context(validationContext); fields(inventory, TOP_LEVEL, "inventory");
  for (const key of ["schema_version", "repository", "mode", "recovery", "artifacts", "refs", "remotes"]) if (!(key in inventory)) fail(`inventory is missing required field: ${key}`);
  if (inventory.schema_version !== 1) fail("inventory has unsupported schema version");
  if (inventory.repository !== validationContext.expectedRepository) fail("inventory.repository must match expectedRepository");
  if (inventory.mode !== "local_only") fail("inventory.mode must be local_only");
  fields(inventory.recovery, new Set(["verified", "bundle_sha256", "refs"]), "recovery");
  if (inventory.recovery.verified !== true) fail("recovery must be verified"); digest(inventory.recovery.bundle_sha256, "recovery.bundle_sha256");
  if (!Array.isArray(inventory.recovery.refs) || inventory.recovery.refs.length === 0) fail("recovery.refs must be a non-empty array");
  const names = new Set();
  for (const ref of inventory.recovery.refs) {
    fields(ref, new Set(["original_ref", "object", "encoded_ref", "bundle_member"]), "recovery ref");
    if (typeof ref.original_ref !== "string" || !ref.original_ref.startsWith("refs/") || /[\0-\x1f\x7f]/.test(ref.original_ref)) fail("recovery ref original_ref must be a safe ref name");
    fullSha(ref.object, "recovery ref object");
    if (typeof ref.encoded_ref !== "string" || !/^refs\/accrue-preserve\/phase-229\/[0-9a-f]+$/.test(ref.encoded_ref)) fail("recovery ref encoded_ref must be phase-229 encoded");
    if (ref.bundle_member !== true) fail("recovery ref must be in verified bundle");
    if (names.has(ref.original_ref)) fail("recovery refs must be unique"); names.add(ref.original_ref);
  }
  fields(inventory.artifacts, new Set(["empty_directory_policy", "entries"]), "artifacts");
  if (inventory.artifacts.empty_directory_policy !== "not_surfaced_by_git") fail("empty-directory policy must be explicit");
  if (!Array.isArray(inventory.artifacts.entries)) fail("artifacts.entries must be an array");
  let previous = "";
  for (const entry of inventory.artifacts.entries) {
    fields(entry, new Set(["path", "type", "sha256"]), "artifact"); relativePath(entry.path, "artifact.path");
    if (!["regular", "symlink", "empty_directory"].includes(entry.type)) fail("artifact type is unsupported");
    if (entry.type === "empty_directory") { if (entry.sha256 !== "not_surfaced") fail("empty directory requires marker"); } else digest(entry.sha256, "artifact.sha256");
    const order = `${entry.path}\0${entry.type}`; if (order < previous) fail("artifact entries must be deterministically sorted"); previous = order;
  }
  fields(inventory.refs, new Set(["local_main", "cached_origin_main", "milestone_branch", "v161_tag"]), "refs");
  Object.entries(inventory.refs).forEach(([key, value]) => fullSha(value, `refs.${key}`));
  fields(inventory.remotes, new Set(["available", "state"]), "remotes");
  if (inventory.remotes.available !== false || inventory.remotes.state !== "unavailable") fail("remote observations must be explicitly unavailable in local-only mode");
  return inventory;
}

export function collectLocalInventory({ repo, recoveryManifest, expectedRepository }) {
  const validationContext = createRepositoryValidationContext({ expectedRepository });
  const manifest = JSON.parse(fs.readFileSync(recoveryManifest, "utf8"));
  if (manifest.schema_version !== 1 || manifest.recovery_verified !== true || !Array.isArray(manifest.refs) || !Array.isArray(manifest.artifacts)) fail("recovery manifest is not verified phase-229 state");
  const refs = Object.fromEntries(manifest.refs.map(({ original_ref, object, encoded_ref, bundle_member }) => ({ original_ref, object, encoded_ref, bundle_member }))
    .map((record) => [record.original_ref, record]));
  const resolve = (name) => refs[name]?.object || run(repo, ["rev-parse", `${name}^{}`]);
  const inventory = {
    schema_version: 1, repository: expectedRepository, mode: "local_only",
    recovery: { verified: true, bundle_sha256: manifest.bundle_sha256, refs: manifest.refs.map(({ original_ref, object, encoded_ref, bundle_member }) => ({ original_ref, object, encoded_ref, bundle_member })).sort((a, b) => a.original_ref.localeCompare(b.original_ref)) },
    artifacts: { empty_directory_policy: manifest.empty_directory_policy, entries: manifest.artifacts.map(({ path: artifactPath, type, sha256 }) => ({ path: artifactPath, type, sha256 })).sort((a, b) => `${a.path}\0${a.type}`.localeCompare(`${b.path}\0${b.type}`)) },
    refs: { local_main: resolve("refs/heads/main"), cached_origin_main: resolve("refs/remotes/origin/main"), milestone_branch: run(repo, ["rev-parse", "HEAD^{commit}"]), v161_tag: resolve("refs/tags/v1.61") },
    remotes: { available: false, state: "unavailable" }
  };
  return validateInventory(inventory, validationContext);
}

function parseArgs(argv) { const result = {}; for (let index = 0; index < argv.length; index += 2) { if (!argv[index].startsWith("--") || !argv[index + 1]) fail("usage: --repo OWNER/REPO --recovery-manifest FILE --local-only --out FILE"); result[argv[index].slice(2)] = argv[index + 1]; } return result; }
function main() {
  const argv = process.argv.slice(2); if (!argv.includes("--local-only")) fail("--local-only is required");
  const filtered = argv.filter((value) => value !== "--local-only"); const options = parseArgs(filtered);
  if (!options.repo || !options["recovery-manifest"] || !options.out) fail("--repo, --recovery-manifest, and --out are required");
  const inventory = collectLocalInventory({ repo: process.cwd(), recoveryManifest: path.resolve(options["recovery-manifest"]), expectedRepository: options.repo });
  fs.writeFileSync(options.out, `${JSON.stringify(inventory, null, 2)}\n`, { mode: 0o600 });
}
if (process.argv[1] === new URL(import.meta.url).pathname) { try { main(); } catch (error) { console.error(`repository inventory collect: FAIL: ${error.message}`); process.exitCode = 1; } }
