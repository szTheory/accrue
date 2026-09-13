#!/usr/bin/env node

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const REPOSITORY = "szTheory/accrue";
const SHA256 = /^[0-9a-f]{64}$/;
const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const CANONICAL_RECORDS = ".planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json";
const CANONICAL_RENDERED = ".planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md";
const fail = (message) => { throw new Error(message); };
const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const modeOf = (stat) => stat.mode & 0o7777;
const bufferName = (name) => Buffer.isBuffer(name) ? name : Buffer.from(name);
const joinBuffer = (parent, name) => Buffer.concat([parent, Buffer.from("/"), name]);
const relativeBuffer = (parts) => Buffer.concat(parts.flatMap((part, index) => index ? [Buffer.from("/"), part] : [part]));
const typeOf = (stat) => stat.isFile() ? "regular" : stat.isDirectory() ? "directory" : stat.isSymbolicLink() ? "symlink" : "unsupported";

function entryIdentity(fullPath, relative, stat = fs.lstatSync(fullPath)) {
  const type = typeOf(stat);
  if (type === "unsupported") fail(`unsupported protected filesystem entry: ${relative.toString("hex")}`);
  const digest = type === "regular" ? sha256(fs.readFileSync(fullPath)) : type === "symlink" ? sha256(fs.readlinkSync(fullPath, { encoding: "buffer" })) : null;
  return { path_hex: relative.toString("hex"), type, digest, mode: modeOf(stat), uid: stat.uid, gid: stat.gid };
}

export function snapshotTree(root) {
  const rootStat = fs.lstatSync(root);
  if (!rootStat.isDirectory() || rootStat.isSymbolicLink()) fail("protected capsule root must be a non-symlink directory");
  const rows = []; const rootBuffer = Buffer.from(root);
  const walk = (directory, parts) => {
    const entries = fs.readdirSync(directory, { encoding: "buffer" }).map(bufferName).sort(Buffer.compare);
    for (const name of entries) {
      const full = joinBuffer(directory, name); const nextParts = [...parts, name]; const relative = relativeBuffer(nextParts);
      const stat = fs.lstatSync(full); rows.push(entryIdentity(full, relative, stat));
      if (stat.isDirectory()) walk(full, nextParts);
    }
  };
  walk(rootBuffer, []);
  return rows.sort((left, right) => left.path_hex.localeCompare(right.path_hex));
}

function gitBuffer(repo, args) {
  const result = spawnSync("git", ["-C", repo, ...args], { encoding: null, shell: false, timeout: 30_000, maxBuffer: 8 * 1024 * 1024 });
  if (result.error || result.status !== 0) fail(`git ${args[0]} failed while capturing handoff invariants`);
  return result.stdout;
}
const splitNul = (bytes) => {
  const values = []; let start = 0;
  for (let index = 0; index < bytes.length; index += 1) if (bytes[index] === 0) { values.push(bytes.subarray(start, index)); start = index + 1; }
  if (start < bytes.length) values.push(bytes.subarray(start));
  return values;
};

function validateRelativeGitPath(value) {
  if (!value.length || value[0] === 0x2f) fail("Git returned an unsafe untracked path");
  for (const component of value.toString("binary").split("/")) if (!component || component === "." || component === "..") fail("Git returned an unsafe untracked path component");
}

export function snapshotUntracked(repo) {
  const root = Buffer.from(fs.realpathSync(repo));
  return splitNul(gitBuffer(repo, ["ls-files", "--others", "--exclude-standard", "-z"])).filter((value) => value.length).map((relative) => {
    validateRelativeGitPath(relative); return entryIdentity(joinBuffer(root, relative), relative);
  }).sort((left, right) => left.path_hex.localeCompare(right.path_hex));
}

export function snapshotRefs(repo) {
  const values = splitNul(gitBuffer(repo, ["for-each-ref", "--format=%(refname)%00%(objectname)%00", "refs"]));
  const rows = [];
  for (let index = 0; index + 1 < values.length; index += 2) {
    let name = values[index]; if (name[0] === 0x0a) name = name.subarray(1); if (!name.length) continue;
    const object = values[index + 1].toString("ascii").replace(/\n$/, "");
    if (!/^[0-9a-f]{40}$/.test(object)) fail("Git returned an invalid ref object");
    rows.push({ name_hex: name.toString("hex"), object });
  }
  return rows.sort((left, right) => left.name_hex.localeCompare(right.name_hex));
}

export function snapshotWorktrees(repo) {
  const fields = splitNul(gitBuffer(repo, ["worktree", "list", "--porcelain", "-z"]));
  const rows = []; let current = null;
  const finish = () => { if (!current) return; if (!current.path_hex || !current.head || !current.identity) fail("Git returned an incomplete worktree identity"); rows.push(current); current = null; };
  for (const field of fields) {
    if (!field.length) { finish(); continue; }
    if (field.subarray(0, 9).equals(Buffer.from("worktree "))) { finish(); current = { path_hex: field.subarray(9).toString("hex") }; }
    else if (!current) fail("Git returned a worktree field without a header");
    else if (field.subarray(0, 5).equals(Buffer.from("HEAD "))) current.head = field.subarray(5).toString("ascii");
    else if (field.subarray(0, 7).equals(Buffer.from("branch "))) current.identity = `branch:${field.subarray(7).toString("hex")}`;
    else if (field.equals(Buffer.from("detached"))) current.identity = "detached";
    else if (field.equals(Buffer.from("bare"))) fail("bare worktrees are outside the handoff contract");
    else fail("Git returned an unsupported worktree field");
  }
  finish();
  return rows.sort((left, right) => left.path_hex.localeCompare(right.path_hex));
}

export function snapshotWorkspace(repo) {
  return { untracked: snapshotUntracked(repo), refs: snapshotRefs(repo), worktrees: snapshotWorktrees(repo) };
}

export function assertExact(label, before, after) {
  try { assert.deepEqual(after, before); } catch { fail(`${label} changed across the final handoff chain`); }
  return true;
}

function assertFreshAttestation(capsuleDirectory, attestation) {
  const capsule = fs.realpathSync(capsuleDirectory); const parent = fs.realpathSync(path.dirname(attestation));
  if (parent !== capsule || path.dirname(attestation) !== capsule || path.basename(attestation) === "" || path.basename(attestation) === "." || path.basename(attestation) === "..") fail("attestation must be a direct capsule sibling named before capture");
  if (fs.existsSync(attestation) || fs.lstatSync(attestation, { throwIfNoEntry: false })) fail("attestation destination must be absent before capture");
}

function createAttestation(attestation, repository) {
  const descriptor = fs.openSync(attestation, "wx", 0o600);
  try {
    fs.fchmodSync(descriptor, 0o600);
    fs.writeFileSync(descriptor, `${JSON.stringify({ schema_version: 1, purpose: "phase229_final_handoff_invariants", repository, result: "PASS" })}\n`);
    fs.fsyncSync(descriptor);
  } finally { fs.closeSync(descriptor); }
  const stat = fs.lstatSync(attestation);
  if (!stat.isFile() || stat.isSymbolicLink() || modeOf(stat) !== 0o600 || stat.uid !== process.geteuid() || stat.gid !== process.getegid()) fail("exclusive attestation identity is invalid");
}

export function assertOnlyAttestation(before, after, attestationName, uid = process.geteuid(), gid = process.getegid()) {
  const nameHex = Buffer.from(attestationName).toString("hex");
  const retained = after.filter((row) => row.path_hex !== nameHex);
  assertExact("pre-existing capsule entries", before, retained);
  const added = after.filter((row) => row.path_hex === nameHex);
  if (added.length !== 1 || added[0].type !== "regular" || added[0].mode !== 0o600 || added[0].uid !== uid || added[0].gid !== gid || !SHA256.test(added[0].digest || "")) fail("the sole capsule delta must be the exact current-owner mode-0600 attestation");
  return true;
}

function validateAuthority({ capsuleDirectory, recoveryManifest, expectedManifestSha256, recoveryBundle, attestation }) {
  if (!SHA256.test(expectedManifestSha256 || "")) fail("expected manifest SHA-256 must be lowercase hexadecimal");
  assertFreshAttestation(capsuleDirectory, attestation);
  for (const [label, filename] of [["recovery manifest", recoveryManifest], ["recovery bundle", recoveryBundle]]) {
    const stat = fs.lstatSync(filename); if (!stat.isFile() || stat.isSymbolicLink() || stat.uid !== process.geteuid()) fail(`${label} must be a current-owner regular file`);
  }
  const manifestStat = fs.lstatSync(recoveryManifest); if ((modeOf(manifestStat) & 0o077) !== 0) fail("recovery manifest permissions are too broad");
  if (sha256(fs.readFileSync(recoveryManifest)) !== expectedManifestSha256) fail("recovery manifest digest differs from its independent anchor");
  const manifest = JSON.parse(fs.readFileSync(recoveryManifest, "utf8"));
  if (manifest.repository !== REPOSITORY || !SHA256.test(manifest.bundle_sha256 || "") || sha256(fs.readFileSync(recoveryBundle)) !== manifest.bundle_sha256) fail("recovery bundle differs from the anchored manifest");
}

function runStep(label, command, args, cwd) {
  const result = spawnSync(command, args, { cwd, encoding: "utf8", shell: false, timeout: 180_000, maxBuffer: 16 * 1024 * 1024, env: { ...process.env, NODE_TEST_CONTEXT: "" } });
  if (result.error || result.status !== 0) fail(`${label} failed: ${(result.stderr || result.stdout || result.error?.message || "unknown error").trim().slice(0, 1200)}`);
}

function writeCurrentArtifactAttestation(repo, recoveryManifest, destination) {
  const manifest = JSON.parse(fs.readFileSync(recoveryManifest, "utf8"));
  const workflow = new Set([".planning/milestone.lock", ".planning/state.json"]);
  const artifacts = manifest.artifacts.map((entry) => {
    const full = path.join(repo, entry.path); const stat = fs.lstatSync(full); const type = stat.isSymbolicLink() ? "symlink" : stat.isFile() ? "regular" : stat.isDirectory() ? "empty_directory" : "unsupported";
    const digest = type === "regular" ? sha256(fs.readFileSync(full)) : type === "symlink" ? sha256(fs.readlinkSync(full, { encoding: "buffer" })) : type === "empty_directory" ? "not_surfaced" : fail("unsupported current artifact type");
    if (!workflow.has(entry.path) && (type !== entry.type || digest !== entry.sha256)) fail(`non-workflow user artifact changed before final collection: ${entry.path}`);
    if (workflow.has(entry.path) && digest === entry.sha256) fail(`workflow metadata did not carry the expected bounded refresh: ${entry.path}`);
    return { path: entry.path, type: entry.type, before_sha256: entry.sha256, after_sha256: digest, state: workflow.has(entry.path) ? "workflow_metadata_refreshed" : "unchanged" };
  });
  const descriptor = fs.openSync(destination, "wx", 0o600);
  try { fs.fchmodSync(descriptor, 0o600); fs.writeFileSync(descriptor, `${JSON.stringify({ schema_version: 1, purpose: "phase229_final_capture", observed_at: new Date().toISOString(), artifacts })}\n`); fs.fsyncSync(descriptor); } finally { fs.closeSync(descriptor); }
}

function runFinalChain(options) {
  const repo = fs.realpathSync(options.repositoryRoot); const capsule = fs.realpathSync(options.capsuleDirectory);
  if (options.expectedRepository !== REPOSITORY || fs.realpathSync(gitBuffer(repo, ["rev-parse", "--show-toplevel"]).toString("utf8").trim()) !== repo) fail("repository root or identity is invalid");
  validateAuthority(options);
  const beforeCapsule = snapshotTree(capsule); const beforeWorkspace = snapshotWorkspace(repo);
  const scratch = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "phase229-final-snapshot-"))); const snapshotFile = path.join(scratch, "before.json"); const finalCapture = path.join(scratch, "current-artifacts.json");
  let descriptor; let createdAttestation = false;
  try {
    descriptor = fs.openSync(snapshotFile, "wx", 0o600); fs.writeFileSync(descriptor, `${JSON.stringify({ capsule: beforeCapsule, workspace: beforeWorkspace })}\n`); fs.fsyncSync(descriptor); fs.closeSync(descriptor); descriptor = undefined;
    if (modeOf(fs.lstatSync(snapshotFile)) !== 0o600) fail("process-local before snapshot must remain mode 0600");
    writeCurrentArtifactAttestation(repo, options.recoveryManifest, finalCapture);
    runStep("preservation self-test", "bash", [path.join(SCRIPT_DIR, "preserve_repository_state.sh"), "--self-test"], repo);
    runStep("collector tests", process.execPath, ["--test", path.join(SCRIPT_DIR, "collect_repository_inventory.mjs")], repo);
    runStep("final bounded collection", process.execPath, [path.join(SCRIPT_DIR, "collect_repository_inventory.mjs"), "--repo", REPOSITORY, "--recovery-manifest", options.recoveryManifest, "--expected-manifest-sha256", options.expectedManifestSha256, "--recovery-bundle", options.recoveryBundle, "--final-capture-attestation", finalCapture, "--observe-remote", "--out", options.records], repo);
    runStep("deterministic rendering", process.execPath, [path.join(SCRIPT_DIR, "render_repository_inventory.mjs"), "--input", options.records, "--out", options.rendered, "--expected-repository", REPOSITORY], repo);
    runStep("gap closure tests", process.execPath, ["--test", path.join(SCRIPT_DIR, "phase229_gap_closure.test.mjs")], repo);
    runStep("inventory verifier tests", process.execPath, ["--test", path.join(SCRIPT_DIR, "verify_repository_inventory.mjs")], repo);
    runStep("monitor wrapper and docs", process.execPath, [path.join(SCRIPT_DIR, "ci_monitor.cjs"), "--self-test", "--verify-wrapper", path.join(SCRIPT_DIR, "watch_ci.sh"), "--verify-docs", path.join(SCRIPT_DIR, "README.md")], repo);
    runStep("strict real-capsule verification", process.execPath, [path.join(SCRIPT_DIR, "verify_repository_inventory.mjs"), "--records", options.records, "--rendered", options.rendered, "--expected-repository", REPOSITORY, "--repository-root", repo, "--recovery-manifest", options.recoveryManifest, "--expected-manifest-sha256", options.expectedManifestSha256, "--recovery-bundle", options.recoveryBundle, "--require-recovery", "--require-all-ref-recovery", "--require-typed-artifacts", "--require-complete-categories", "--require-edge-cases", "--require-command-provenance", "--require-privacy-controls", "--require-determinism", "--require-workflow-metadata-authorization"], repo);
    assertExact("capsule", beforeCapsule, snapshotTree(capsule)); assertExact("workspace", beforeWorkspace, snapshotWorkspace(repo));
    createAttestation(options.attestation, REPOSITORY); createdAttestation = true;
    assertOnlyAttestation(beforeCapsule, snapshotTree(capsule), path.basename(options.attestation)); assertExact("workspace", beforeWorkspace, snapshotWorkspace(repo));
    console.log("phase229 final handoff invariants: PASS");
  } catch (error) {
    if (createdAttestation) fs.rmSync(options.attestation, { force: true });
    throw error;
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
    fs.rmSync(scratch, { recursive: true, force: true });
  }
}

function runSelfTest() {
  const fixture = { path_hex: "61", type: "regular", digest: "1".repeat(64), mode: 0o600, uid: process.geteuid(), gid: process.getegid() };
  const link = { path_hex: "62", type: "symlink", digest: "2".repeat(64), mode: 0o777, uid: process.geteuid(), gid: process.getegid() };
  const base = [fixture, link];
  const reject = (name, mutate) => { const changed = structuredClone(base); mutate(changed); assert.throws(() => assertExact("capsule", base, changed)); console.log(`handoff invariant ${name}: PASS`); };
  reject("sibling-add", (rows) => rows.push({ ...rows[0], path_hex: "63" }));
  reject("sibling-delete", (rows) => rows.pop());
  reject("sibling-rename", (rows) => { rows[0].path_hex = "64"; });
  reject("content-digest", (rows) => { rows[0].digest = "3".repeat(64); });
  reject("link-digest", (rows) => { rows[1].digest = "4".repeat(64); });
  reject("type-swap", (rows) => { rows[0].type = "symlink"; });
  reject("mode", (rows) => { rows[0].mode = 0o644; });
  reject("owner", (rows) => { rows[0].uid += 1; });
  reject("extra-entry", (rows) => rows.push({ ...rows[0], path_hex: "65" }));
  const workspace = { untracked: [fixture], refs: [{ name_hex: "726566732f746167732f7631", object: "a".repeat(40) }], worktrees: [{ path_hex: "2f746d70", head: "a".repeat(40), identity: "detached" }] };
  for (const [name, mutate] of [["untracked", (value) => { value.untracked[0].digest = "5".repeat(64); }], ["ref-tag", (value) => { value.refs[0].object = "b".repeat(40); }], ["worktree", (value) => { value.worktrees[0].head = "b".repeat(40); }]]) { const changed = structuredClone(workspace); mutate(changed); assert.throws(() => assertExact("workspace", workspace, changed)); console.log(`handoff invariant ${name}: PASS`); }
  const scratch = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "phase229-handoff-self-test-"))); const capsule = path.join(scratch, "capsule"); fs.mkdirSync(capsule);
  const rawName = Buffer.from([0xff, 0x2d, 0x66]); const rawPath = joinBuffer(Buffer.from(capsule), rawName);
  if (process.platform !== "darwin") fs.writeFileSync(rawPath, "raw");
  const rawLink = path.join(capsule, "raw-link"); fs.symlinkSync(Buffer.from([0xfd, 0x0a]), rawLink);
  try {
    const raw = snapshotTree(capsule); if (process.platform !== "darwin") { assert.ok(raw.some((row) => row.path_hex === rawName.toString("hex"))); fs.unlinkSync(rawPath); }
    assert.ok(raw.some((row) => row.path_hex === Buffer.from("raw-link").toString("hex") && row.digest === sha256(Buffer.from([0xfd, 0x0a]))));
    assert.notEqual(Buffer.from(rawName.toString("utf8")).toString("hex"), rawName.toString("hex"), "raw-name fixture proves UTF-8 round trips are lossy"); console.log("handoff invariant raw-non-utf8: PASS");
    const existing = path.join(capsule, "existing.json"); fs.writeFileSync(existing, "occupied", { mode: 0o600 }); assert.throws(() => assertFreshAttestation(capsule, existing)); console.log("handoff invariant preexisting-attestation: PASS"); fs.rmSync(existing);
    const before = snapshotTree(capsule); const attestation = path.join(capsule, "final.json"); createAttestation(attestation, REPOSITORY); assertOnlyAttestation(before, snapshotTree(capsule), "final.json"); console.log("handoff invariant exclusive-attestation: PASS");
  } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
  console.log("phase229 handoff invariant self-test: PASS");
}

function parseArgs(argv) {
  if (argv.length === 1 && argv[0] === "--self-test") return { selfTest: true };
  const options = {}; const allowed = new Set(["repository-root", "capsule-directory", "recovery-manifest", "expected-manifest-sha256", "recovery-bundle", "attestation", "records", "rendered", "expected-repository"]);
  let run = false;
  for (let index = 0; index < argv.length; index += 1) {
    if (argv[index] === "--run-final-chain") { run = true; continue; }
    if (!argv[index].startsWith("--") || !allowed.has(argv[index].slice(2)) || index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`unsupported final handoff option: ${argv[index]}`);
    options[argv[index].slice(2).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())] = argv[++index];
  }
  if (!run || [...allowed].some((name) => !options[name.replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())])) fail("--run-final-chain requires every fixed authority and output option");
  return options;
}

try {
  const options = parseArgs(process.argv.slice(2));
  if (options.selfTest) runSelfTest(); else runFinalChain(options);
} catch (error) {
  console.error(`phase229 handoff invariants: FAIL: ${error.message}`); process.exitCode = 1;
}
