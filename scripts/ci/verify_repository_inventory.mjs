#!/usr/bin/env node

// Phase 229 starts test-first: the production modules are intentionally absent
// until the fixture contract below is made green.
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
import test from "node:test";
import {
  createRepositoryValidationContext,
  validateInventory,
  collectRepositoryInventory,
  normalizeRemoteFact
} from "./collect_repository_inventory.mjs";
import { renderRepositoryInventory } from "./render_repository_inventory.mjs";

const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");
function git(repo, args) { const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8" }); assert.equal(result.status, 0, result.stderr); return result.stdout.trim(); }
function recoveryFixture() {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "phase229-recovery-barrier-")); const repo = path.join(scratch, "repo"); fs.mkdirSync(repo); git(repo, ["init", "-q"]); git(repo, ["config", "user.email", "phase229@example.invalid"]); git(repo, ["config", "user.name", "phase229"]);
  fs.mkdirSync(path.join(repo, ".planning")); fs.writeFileSync(path.join(repo, ".planning/milestone.lock"), "before-lock\n"); fs.writeFileSync(path.join(repo, ".planning/state.json"), "before-state\n"); fs.writeFileSync(path.join(repo, "tracked"), "fixture\n"); git(repo, ["add", "tracked"]); git(repo, ["commit", "-qm", "fixture"]); git(repo, ["branch", "-M", "main"]); const object = git(repo, ["rev-parse", "HEAD"]); git(repo, ["update-ref", "refs/remotes/origin/main", object]); git(repo, ["tag", "v1.61", object]);
  const originalRef = "refs/heads/main"; const encodedRef = `refs/accrue-preserve/phase-229/${Buffer.from(originalRef).toString("hex")}`; git(repo, ["update-ref", encodedRef, object]); const bundle = path.join(scratch, "recovery.bundle"); git(repo, ["bundle", "create", bundle, originalRef]);
  const beforeLock = sha256("before-lock\n"); const beforeState = sha256("before-state\n"); fs.writeFileSync(path.join(repo, ".planning/milestone.lock"), "after-lock\n"); fs.writeFileSync(path.join(repo, ".planning/state.json"), "after-state\n"); const afterLock = sha256("after-lock\n"); const afterState = sha256("after-state\n");
  const manifest = { schema_version: 1, repository: "szTheory/accrue", recovery_verified: true, bundle_sha256: sha256(fs.readFileSync(bundle)), refs: [{ original_ref: originalRef, object, encoded_ref: encodedRef, bundle_member: true }], artifacts: [{ path: ".planning/milestone.lock", type: "regular", sha256: beforeLock }, { path: ".planning/state.json", type: "regular", sha256: beforeState }], empty_directory_policy: "not_surfaced_by_git" };
  const manifestPath = path.join(scratch, "manifest.json"); fs.writeFileSync(manifestPath, JSON.stringify(manifest), { mode: 0o600 }); fs.chmodSync(manifestPath, 0o600); const expectedManifestSha256 = sha256(fs.readFileSync(manifestPath)); const attestation = { schema_version: 1, purpose: "phase229_final_capture", observed_at: "2026-09-13T00:00:00.000Z", artifacts: [{ path: ".planning/milestone.lock", type: "regular", before_sha256: beforeLock, after_sha256: afterLock, state: "workflow_metadata_refreshed" }, { path: ".planning/state.json", type: "regular", before_sha256: beforeState, after_sha256: afterState, state: "workflow_metadata_refreshed" }] }; const attestationPath = path.join(scratch, "attestation.json"); fs.writeFileSync(attestationPath, JSON.stringify(attestation));
  return { scratch, repo, bundle, manifestPath, expectedManifestSha256, attestationPath, manifest, attestation };
}
function assertRecoveryFailure(mutate, expected) {
  const fixture = recoveryFixture(); let calls = 0;
  try {
    mutate(fixture);
    assert.throws(() => collectRepositoryInventory({
      repo: fixture.repo, recoveryManifest: fixture.manifestPath, expectedManifestSha256: fixture.expectedManifestSha256, recoveryBundle: fixture.bundle,
      finalCaptureAttestation: fixture.attestationPath, expectedRepository: "szTheory/accrue", observeRemote: true,
      adapter: { get: () => { calls += 1; return { object: { sha: "a".repeat(40) } }; } }
    }), expected);
    assert.equal(calls, 0, "recovery validation must finish before remote observation");
  } finally { fs.rmSync(fixture.scratch, { recursive: true, force: true }); }
}

export function verifyFixtures() {
  const context = createRepositoryValidationContext({ expectedRepository: "szTheory/accrue" });
  const inventory = {
    schema_version: 2,
    repository: "szTheory/accrue",
    mode: "local_only",
    recovery: { verified: true, manifest_sha256: "f".repeat(64), bundle_sha256: "a".repeat(64), refs: [{ original_ref: "refs/heads/main", object: "b".repeat(40), encoded_ref: "refs/accrue-preserve/phase-229/726566732f68656164732f6d61696e", bundle_member: true }] },
    artifacts: { empty_directory_policy: "not_surfaced_by_git", entries: [{ path: "link", type: "symlink", sha256: "d".repeat(64) }, { path: "nested/file.txt", type: "regular", sha256: "c".repeat(64) }] },
    refs: { local_main: "b".repeat(40), cached_origin_main: "b".repeat(40), milestone_branch: "b".repeat(40), v161_tag: "b".repeat(40), all: [{ name: "refs/heads/main", object: "b".repeat(40), role: "local_main" }] },
    remotes: Object.fromEntries(["remote_main", "pull_requests", "release_branches", "actions"].map((key) => [key, { repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", request: `GET /repos/szTheory/accrue/${key}`, available: false, state: "unavailable", reason: "network" }])),
    planning: { ship_windows: [], milestone: "absent", state: "absent" },
    worktrees: [{ branch: "phase/229", sha: "b".repeat(40), dirty: false }]
  };
  const validated = validateInventory(inventory, context);
  assert.equal(renderRepositoryInventory(validated, context), renderRepositoryInventory(structuredClone(validated), context));
  const permuted = structuredClone(validated); permuted.recovery.refs.reverse(); permuted.artifacts.entries.reverse(); permuted.refs.all.reverse();
  assert.equal(renderRepositoryInventory(validated, context), renderRepositoryInventory(permuted, context), "permutations must render identical bytes");
  assert.throws(() => validateInventory({ ...inventory, actor: "forbidden" }, context), /forbidden field/);
  assert.throws(() => validateInventory({ ...inventory, artifacts: { ...inventory.artifacts, entries: [{ path: "../secret", type: "regular", sha256: "c".repeat(64) }] } }, context), /relative path/);
  const workflowMetadata = [{ path: ".planning/milestone.lock", type: "regular", before_sha256: "1".repeat(64), after_sha256: "2".repeat(64), state: "workflow_metadata_refreshed" }, { path: ".planning/state.json", type: "regular", before_sha256: "3".repeat(64), after_sha256: "4".repeat(64), state: "workflow_metadata_refreshed" }];
  assert.equal(validateInventory({ ...inventory, artifacts: { ...inventory.artifacts, authorized_workflow_metadata: workflowMetadata } }, context).artifacts.authorized_workflow_metadata.length, 2);
  assert.throws(() => validateInventory({ ...inventory, artifacts: { ...inventory.artifacts, authorized_workflow_metadata: [workflowMetadata[0]] } }, context), /two exact workflow metadata paths/);
  assert.throws(() => validateInventory({ ...inventory, remotes: {} }, context), /remote/);

  // Phase 229 complete-inventory contract: this intentionally exercises APIs
  // before they exist, so the first TDD run must fail.
  assert.equal(typeof collectRepositoryInventory, "function");
  assert.equal(typeof normalizeRemoteFact, "function");
  const remote = normalizeRemoteFact({
    repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z",
    request: "GET /repos/szTheory/accrue/git/ref/heads/main", sha: "e".repeat(40)
  }, context);
  assert.equal(remote.available, true);
  assert.throws(() => normalizeRemoteFact({ repository: "szTheory/accrue", observed_at: "bad", request: "GET /repos/szTheory/accrue/git/ref/heads/main", sha: "e".repeat(40) }, context), /observed_at/);
  const unavailable = normalizeRemoteFact({ repository: "szTheory/accrue", observed_at: "2026-09-13T00:00:00.000Z", request: "GET /repos/szTheory/accrue/git/ref/heads/main", available: false, reason: "network" }, context);
  assert.equal(unavailable.sha, undefined);
  assert.throws(() => normalizeRemoteFact({ ...unavailable, sha: "f".repeat(40) }, context), /no claimed remote value/);
  assert.equal(assertCommandProvenance(validated, context), true);
  assert.throws(() => assertCommandProvenance({ ...validated, remotes: { ...validated.remotes, actions: { ...validated.remotes.actions, request: "GET /repos/other/repo/actions" } } }, context), /provenance/);
  assert.throws(() => renderRepositoryInventory({ ...inventory, planning: { ...inventory.planning, raw_payload: "forbidden" } }, context), /forbidden field/);
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "phase229-inventory-"));
  try {
    const source = path.join(scratch, "source.json"); const rendered = path.join(scratch, "rendered.md");
    fs.writeFileSync(source, `${JSON.stringify(validated)}\n`); fs.writeFileSync(rendered, renderRepositoryInventory(validated, context));
    assert.equal(fs.readFileSync(rendered, "utf8"), renderRepositoryInventory(JSON.parse(fs.readFileSync(source, "utf8")), context));
    assert.equal(fs.existsSync(path.join(scratch, "invalid.md")), false, "invalid input must not render output");

    const incompleteRecovery = structuredClone(validated);
    incompleteRecovery.refs.all.push({ name: "refs/heads/secondary", object: "c".repeat(40), role: "other" });
    const incompleteSource = path.join(scratch, "incomplete-recovery.json");
    const incompleteRendered = path.join(scratch, "incomplete-recovery.md");
    fs.writeFileSync(incompleteSource, `${JSON.stringify(incompleteRecovery)}\n`);
    fs.writeFileSync(incompleteRendered, renderRepositoryInventory(incompleteRecovery, context));
    const reductionProbe = spawnSync(process.execPath, [
      new URL(import.meta.url).pathname,
      "--records", incompleteSource,
      "--rendered", incompleteRendered,
      "--expected-repository", "szTheory/accrue",
      "--require-all-ref-recovery"
    ], { encoding: "utf8", env: { ...process.env, NODE_TEST_CONTEXT: "" } });
    assert.notEqual(reductionProbe.status, 0, "all-ref verification must reject one recovery mapping when two original refs exist");
  } finally { fs.rmSync(scratch, { recursive: true, force: true }); }

  const barrier = recoveryFixture(); let adapterCalls = 0;
  try {
    const captured = collectRepositoryInventory({ repo: barrier.repo, recoveryManifest: barrier.manifestPath, expectedManifestSha256: barrier.expectedManifestSha256, recoveryBundle: barrier.bundle, finalCaptureAttestation: barrier.attestationPath, expectedRepository: "szTheory/accrue", observeRemote: true, adapter: { get: () => { adapterCalls += 1; return { object: { sha: "e".repeat(40) } }; } } });
    assert.equal(captured.recovery.manifest_sha256, barrier.expectedManifestSha256); assert.equal(adapterCalls, 4, "remote observation begins only after complete local validation");
  } finally { fs.rmSync(barrier.scratch, { recursive: true, force: true }); }
  assertRecoveryFailure(({ bundle }) => fs.appendFileSync(bundle, "tamper"), /digest/);
  assertRecoveryFailure(({ repo, bundle, manifestPath }) => {
    fs.writeFileSync(path.join(repo, "tracked"), "replacement\n"); git(repo, ["add", "tracked"]); git(repo, ["commit", "-qm", "replacement"]); const object = git(repo, ["rev-parse", "HEAD"]); const originalRef = "refs/heads/main"; const encodedRef = `refs/accrue-preserve/phase-229/${Buffer.from(originalRef).toString("hex")}`; git(repo, ["update-ref", encodedRef, object]); const replacementBundle = `${bundle}.replacement`; git(repo, ["bundle", "create", replacementBundle, originalRef]); fs.renameSync(replacementBundle, bundle); const manifest = JSON.parse(fs.readFileSync(manifestPath)); manifest.bundle_sha256 = sha256(fs.readFileSync(bundle)); manifest.refs[0].object = object; fs.writeFileSync(manifestPath, JSON.stringify(manifest)); fs.chmodSync(manifestPath, 0o600);
  }, /manifest digest/);
  assertRecoveryFailure(({ manifestPath }) => fs.chmodSync(manifestPath, 0o644), /permissions/);
  { const originalGeteuid = process.geteuid; try { Object.defineProperty(process, "geteuid", { configurable: true, value: undefined }); assertRecoveryFailure(() => {}, /ownership cannot be validated/); } finally { Object.defineProperty(process, "geteuid", { configurable: true, value: originalGeteuid }); } }
  assertRecoveryFailure((fixture) => { fixture.expectedManifestSha256 = "0".repeat(64); }, /manifest digest/);
  assertRecoveryFailure((fixture) => { fixture.expectedManifestSha256 = undefined; }, /expected recovery manifest SHA-256/);
  assertRecoveryFailure(({ repo }) => git(repo, ["update-ref", "-d", "refs/accrue-preserve/phase-229/726566732f68656164732f6d61696e"]), /git rev-parse failed/);
  assertRecoveryFailure(({ manifestPath }) => { const manifest = JSON.parse(fs.readFileSync(manifestPath)); manifest.refs[0].object = "f".repeat(40); fs.writeFileSync(manifestPath, JSON.stringify(manifest)); }, /digest|preservation target|bundle/);
  assertRecoveryFailure(({ attestationPath }) => { const attestation = JSON.parse(fs.readFileSync(attestationPath)); attestation.observed_at = "not-a-time"; fs.writeFileSync(attestationPath, JSON.stringify(attestation)); }, /observed_at/);
  assertRecoveryFailure(({ attestationPath }) => { const attestation = JSON.parse(fs.readFileSync(attestationPath)); attestation.artifacts.pop(); fs.writeFileSync(attestationPath, JSON.stringify(attestation)); }, /cover every frozen artifact|exactly two/);
}

function options(argv) {
  const result = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--")) throw new Error(`unexpected argument: ${argv[index]}`);
    const key = argv[index].slice(2); result.add(key);
    if (!["fixtures", "require-recovery", "require-all-ref-recovery", "require-typed-artifacts", "require-local-only", "require-complete-categories", "require-edge-cases", "require-privacy-controls", "require-determinism", "require-command-provenance", "require-workflow-metadata-authorization"].includes(key)) values[key] = argv[++index];
  }
  return { flags: result, values };
}
function assertCommandProvenance(inventory, context) {
  for (const key of ["remote_main", "pull_requests", "release_branches", "actions"]) {
    const fact = inventory.remotes[key];
    if (!fact || fact.repository !== context.expectedRepository || typeof fact.observed_at !== "string" || !new RegExp(`^GET /repos/${context.expectedRepository.replace("/", "\\/")}/`).test(fact.request || "")) {
      throw new Error(`command provenance is required for ${key}`);
    }
    normalizeRemoteFact(fact, context);
  }
  return true;
}
function assertWorkflowMetadataAuthorization(inventory) {
  const changes = inventory.artifacts.authorized_workflow_metadata;
  if (!changes) throw new Error("workflow metadata authorization evidence is required");
  if (changes.length !== 2 || changes.some((change) => ![".planning/milestone.lock", ".planning/state.json"].includes(change.path))) throw new Error("workflow metadata authorization must remain exact-path bounded");
  return true;
}
async function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("repository inventory fixtures: PASS"); return; }
  const { records, rendered, "expected-repository": expectedRepository } = parsed.values;
  if (!records || !rendered || !expectedRepository) throw new Error("--records, --rendered, and --expected-repository are required");
  const context = createRepositoryValidationContext({ expectedRepository });
  const inventory = validateInventory(JSON.parse(fs.readFileSync(records, "utf8")), context);
  if (parsed.flags.has("require-recovery") && inventory.recovery.verified !== true) throw new Error("verified recovery is required");
  if (parsed.flags.has("require-all-ref-recovery") && inventory.recovery.refs.length === 0) throw new Error("all-ref recovery is required");
  if (parsed.flags.has("require-typed-artifacts") && !inventory.artifacts.entries.every((entry) => ["regular", "symlink", "empty_directory"].includes(entry.type))) throw new Error("typed artifacts are required");
  if (parsed.flags.has("require-local-only") && inventory.mode !== "local_only") throw new Error("local-only inventory is required");
  if (parsed.flags.has("require-complete-categories") && (!inventory.refs.all || !inventory.worktrees || !inventory.planning || Object.keys(inventory.remotes).length !== 4)) throw new Error("complete categories are required");
  if (parsed.flags.has("require-edge-cases") && inventory.artifacts.empty_directory_policy !== "not_surfaced_by_git") throw new Error("edge-case policy is required");
  if (parsed.flags.has("require-command-provenance")) assertCommandProvenance(inventory, context);
  if (parsed.flags.has("require-workflow-metadata-authorization")) assertWorkflowMetadataAuthorization(inventory);
  assert.equal(fs.readFileSync(rendered, "utf8"), renderRepositoryInventory(inventory, context), "rendered Markdown must be byte-reproducible");
  console.log("repository inventory verification: PASS");
}
if (process.env.NODE_TEST_CONTEXT) {
  test("strict all-ref recovery rejects incomplete recovery sets", () => verifyFixtures());
} else {
  main().catch((error) => { console.error(`repository inventory fixtures: FAIL: ${error.message}`); process.exitCode = 1; });
}
