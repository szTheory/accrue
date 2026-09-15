import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";
import test from "node:test";

import {
  createGhApiReadAdapter,
  collectRemoteFacts,
  collectRepositoryInventory,
  collectWorktrees,
  createRepositoryValidationContext,
  readShipWindows
} from "./collect_repository_inventory.mjs";
import { renderRepositoryInventory } from "./render_repository_inventory.mjs";

const REPOSITORY = "szTheory/accrue";
const OBSERVED_AT = new Date("2026-09-13T00:00:00.000Z");
const VERIFY_INVENTORY = fileURLToPath(new URL("./verify_repository_inventory.mjs", import.meta.url));
const RENDER_INVENTORY = fileURLToPath(new URL("./render_repository_inventory.mjs", import.meta.url));
const PRESERVE_REPOSITORY = fileURLToPath(new URL("./preserve_repository_state.sh", import.meta.url));
const README_PATH = fileURLToPath(new URL("./README.md", import.meta.url));
const HANDOFF_INVARIANTS = fileURLToPath(new URL("./verify_phase229_handoff_invariants.mjs", import.meta.url));
const PRESERVATION_PREFIX = "refs/accrue-preserve/phase-229/";
const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");
const encodedRef = (name) => `${PRESERVATION_PREFIX}${Buffer.from(name).toString("hex")}`;

async function loadHandoffLibrary() {
  const originalArgv = process.argv;
  process.argv = [process.execPath, HANDOFF_INVARIANTS, "--self-test"];
  try {
    return await import(`${pathToFileURL(HANDOFF_INVARIANTS).href}?library=${crypto.randomUUID()}`);
  } finally {
    process.argv = originalArgv;
  }
}

function git(repo, args) {
  const result = spawnSync("git", ["-C", repo, ...args], {
    encoding: "utf8",
    shell: false,
    timeout: 15_000,
    maxBuffer: 1_000_000
  });
  assert.equal(result.status, 0, result.stderr || `git ${args[0]} failed`);
  return result.stdout.trim();
}

function strictVerifierFixture() {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "phase229-strict-authority-"));
  const repo = path.join(scratch, "repo");
  const linked = path.join(scratch, "linked");
  fs.mkdirSync(repo);
  git(repo, ["init", "-q", "-b", "main"]);
  git(repo, ["config", "user.email", "phase229@example.invalid"]);
  git(repo, ["config", "user.name", "phase229"]);
  fs.mkdirSync(path.join(repo, ".planning"));
  fs.writeFileSync(path.join(repo, ".planning/WINDOWS.md"), [
    "---", "open_count: 1", "waived_count: 0", "fixed_count: 1", "total_count: 2", "---", "",
    "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |",
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    "| 1 | 229 | deviation | fixture | | first | open | | now | |",
    "| 2 | 229 | deviation | fixture | | second | fixed | | now | |", ""
  ].join("\n"));
  fs.writeFileSync(path.join(repo, "tracked"), "fixture\n");
  git(repo, ["add", ".planning/WINDOWS.md", "tracked"]);
  git(repo, ["commit", "-qm", "fixture"]);
  const object = git(repo, ["rev-parse", "HEAD"]);
  git(repo, ["branch", "secondary"]);
  git(repo, ["update-ref", "refs/remotes/origin/main", object]);
  git(repo, ["tag", "v1.61", object]);
  git(repo, ["worktree", "add", "-q", linked, "secondary"]);

  const originals = git(repo, ["for-each-ref", "--format=%(refname) %(objectname)", "refs"])
    .split("\n").filter(Boolean).map((line) => {
      const separator = line.indexOf(" ");
      return { original_ref: line.slice(0, separator), object: line.slice(separator + 1) };
    });
  for (const row of originals) git(repo, ["update-ref", encodedRef(row.original_ref), row.object]);
  const bundle = path.join(scratch, "recovery.bundle");
  const created = spawnSync("git", ["-C", repo, "bundle", "create", bundle, ...originals.map((row) => row.original_ref)], { encoding: "utf8", shell: false });
  assert.equal(created.status, 0, created.stderr);
  fs.chmodSync(bundle, 0o600);
  const manifest = {
    schema_version: 1,
    repository: REPOSITORY,
    recovery_verified: true,
    bundle_sha256: sha256(fs.readFileSync(bundle)),
    refs: originals.map((row) => ({
      ...row,
      object_type: "commit",
      encoded_ref: encodedRef(row.original_ref),
      bundle_member: true,
      restore_argv: ["git", "update-ref", row.original_ref, row.object]
    })),
    artifacts: [],
    empty_directory_policy: "not_surfaced_by_git"
  };
  const manifestPath = path.join(scratch, "manifest.json");
  const manifestBytes = Buffer.from(`${JSON.stringify(manifest)}\n`);
  fs.writeFileSync(manifestPath, manifestBytes, { mode: 0o600 });
  fs.chmodSync(manifestPath, 0o600);
  const manifestDigest = sha256(manifestBytes);
  const role = (name) => name === "refs/heads/main" ? "local_main"
    : name === "refs/remotes/origin/main" ? "cached_origin_main"
      : name === "refs/tags/v1.61" ? "v161_tag" : "other";
  const refs = originals.map((row) => ({ name: row.original_ref, object: row.object, role: role(row.original_ref) }));
  const preservation = originals.map((row) => ({ name: encodedRef(row.original_ref), object: row.object, role: "phase229_preservation" }));
  const inventory = {
    schema_version: 2,
    repository: REPOSITORY,
    mode: "local_only",
    recovery: {
      verified: true,
      manifest_sha256: manifestDigest,
      bundle_sha256: manifest.bundle_sha256,
      refs: manifest.refs.map(({ original_ref, object: refObject, encoded_ref, bundle_member }) => ({ original_ref, object: refObject, encoded_ref, bundle_member }))
    },
    artifacts: { empty_directory_policy: "not_surfaced_by_git", entries: [] },
    refs: {
      local_main: object,
      cached_origin_main: object,
      milestone_branch: object,
      v161_tag: object,
      all: [...refs, ...preservation].sort((left, right) => left.name.localeCompare(right.name))
    },
    remotes: {
      remote_main: { repository: REPOSITORY, observed_at: OBSERVED_AT.toISOString(), request: `GET /repos/${REPOSITORY}/git/ref/heads/main`, available: false, state: "unavailable", reason: "unavailable" },
      pull_requests: { repository: REPOSITORY, observed_at: OBSERVED_AT.toISOString(), requests: [`GET /repos/${REPOSITORY}/pulls?state=open&per_page=100&page=1`], available: false, state: "unavailable", reason: "unavailable" },
      release_branches: { repository: REPOSITORY, observed_at: OBSERVED_AT.toISOString(), requests: [`GET /repos/${REPOSITORY}/git/matching-refs/heads/release/?per_page=100&page=1`], available: false, state: "unavailable", reason: "unavailable" },
      actions: { repository: REPOSITORY, observed_at: OBSERVED_AT.toISOString(), requests: [`GET /repos/${REPOSITORY}/actions/runs?per_page=100&page=1`], available: false, state: "unavailable", reason: "unavailable" }
    },
    planning: { ship_windows: readShipWindows({ root: repo }), milestone: "absent", state: "absent" },
    worktrees: collectWorktrees({ repo }),
    capture: {
      captured_at: OBSERVED_AT.toISOString(),
      active_ref: "refs/heads/main",
      commit: object,
      primary_worktree: { branch: "refs/heads/main", head: object }
    }
  };
  return { scratch, repo, bundle, manifestPath, manifestDigest, object, inventory };
}

function runStrictVerifier(fixture, inventory, flags = []) {
  const records = path.join(fixture.scratch, `records-${crypto.randomUUID()}.json`);
  const rendered = path.join(fixture.scratch, `rendered-${crypto.randomUUID()}.md`);
  const env = { ...process.env, NODE_TEST_CONTEXT: undefined };
  fs.writeFileSync(records, `${JSON.stringify(inventory, null, 2)}\n`);
  const render = spawnSync(process.execPath, [RENDER_INVENTORY, "--input", records, "--out", rendered, "--expected-repository", REPOSITORY], { encoding: "utf8", shell: false, env });
  if (render.status !== 0) return render;
  return spawnSync(process.execPath, [
    VERIFY_INVENTORY,
    "--records", records,
    "--rendered", rendered,
    "--expected-repository", REPOSITORY,
    "--repository-root", fixture.repo,
    "--recovery-manifest", fixture.manifestPath,
    "--expected-manifest-sha256", fixture.manifestDigest,
    "--recovery-bundle", fixture.bundle,
    "--require-recovery",
    "--require-all-ref-recovery",
    "--require-complete-categories",
    ...flags
  ], { encoding: "utf8", shell: false, timeout: 20_000, env });
}

function runIsolatedNodeTest(file, namePattern) {
  return spawnSync(process.execPath, ["--test", `--test-name-pattern=${namePattern}`, file], {
    cwd: path.dirname(path.dirname(path.dirname(VERIFY_INVENTORY))),
    encoding: "utf8",
    shell: false,
    timeout: 30_000,
    env: { ...process.env, NODE_TEST_CONTEXT: undefined }
  });
}

function documentedStrictBlock() {
  const readme = fs.readFileSync(README_PATH, "utf8");
  const match = /<!-- phase229-strict-verification:start -->\n```bash\n([\s\S]*?)\n```\n<!-- phase229-strict-verification:end -->/.exec(readme);
  assert.ok(match, "README must expose one extractable Phase 229 strict verification block");
  return { block: match[1], readme };
}

function documentedStrictFixture() {
  const scratch = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "phase229-documented-strict-")));
  const repo = path.join(scratch, "repo");
  const capsule = path.join(scratch, "capsule");
  const scripts = path.join(repo, "scripts/ci");
  const evidence = path.join(repo, ".planning/phases/229-repository-truth-recovery-safety");
  fs.mkdirSync(repo); fs.mkdirSync(capsule); fs.mkdirSync(scripts, { recursive: true }); fs.mkdirSync(evidence, { recursive: true });
  git(repo, ["init", "-q", "-b", "main"]);
  git(repo, ["config", "user.email", "phase229@example.invalid"]);
  git(repo, ["config", "user.name", "phase229"]);
  fs.writeFileSync(path.join(repo, ".planning/WINDOWS.md"), [
    "---", "open_count: 0", "waived_count: 0", "fixed_count: 0", "total_count: 0", "---", "",
    "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |",
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |", ""
  ].join("\n"));
  fs.writeFileSync(path.join(repo, "tracked"), "fixture\n");
  git(repo, ["add", ".planning/WINDOWS.md", "tracked"]); git(repo, ["commit", "-qm", "fixture"]);
  const object = git(repo, ["rev-parse", "HEAD"]);
  git(repo, ["update-ref", "refs/remotes/origin/main", object]); git(repo, ["tag", "v1.61", object]);
  fs.writeFileSync(path.join(repo, "artifact.txt"), "untracked recovery fixture\n");
  const bundle = path.join(capsule, "recovery.bundle");
  const manifestPath = path.join(capsule, "manifest.json");
  const preserved = spawnSync("bash", [PRESERVE_REPOSITORY, "--repo-root", repo, "--expected-repository", REPOSITORY, "--bundle-out", bundle, "--private-manifest-out", manifestPath], { encoding: "utf8", shell: false, timeout: 30_000 });
  assert.equal(preserved.status, 0, preserved.stderr);
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const manifestDigest = sha256(fs.readFileSync(manifestPath));
  for (const source of [VERIFY_INVENTORY, RENDER_INVENTORY, fileURLToPath(new URL("./collect_repository_inventory.mjs", import.meta.url))]) fs.copyFileSync(source, path.join(scripts, path.basename(source)));
  const rows = git(repo, ["for-each-ref", "--format=%(refname) %(objectname)"]).split("\n").filter(Boolean).map((line) => {
    const separator = line.indexOf(" "); const name = line.slice(0, separator);
    return { name, object: line.slice(separator + 1), role: name === "refs/heads/main" ? "local_main" : name === "refs/remotes/origin/main" ? "cached_origin_main" : name === "refs/tags/v1.61" ? "v161_tag" : name.startsWith(PRESERVATION_PREFIX) ? "phase229_preservation" : "other" };
  }).sort((left, right) => left.name.localeCompare(right.name));
  const inventory = {
    schema_version: 2, repository: REPOSITORY, mode: "local_only",
    recovery: { verified: true, manifest_sha256: manifestDigest, bundle_sha256: manifest.bundle_sha256, refs: manifest.refs.map(({ original_ref, object: refObject, encoded_ref, bundle_member }) => ({ original_ref, object: refObject, encoded_ref, bundle_member })).sort((left, right) => left.original_ref.localeCompare(right.original_ref)) },
    artifacts: {
      empty_directory_policy: manifest.empty_directory_policy,
      entries: manifest.artifacts.map(({ path: artifactPath, type, sha256: digest }) => ({ path: artifactPath, type, sha256: digest })).sort((left, right) => left.path.localeCompare(right.path)),
      authorized_workflow_metadata: [
        { path: ".planning/milestone.lock", type: "regular", before_sha256: "1".repeat(64), after_sha256: "2".repeat(64), state: "workflow_metadata_refreshed" },
        { path: ".planning/state.json", type: "regular", before_sha256: "3".repeat(64), after_sha256: "4".repeat(64), state: "workflow_metadata_refreshed" }
      ]
    },
    refs: { local_main: object, cached_origin_main: object, milestone_branch: object, v161_tag: object, all: rows },
    remotes: {
      remote_main: { repository: REPOSITORY, observed_at: OBSERVED_AT.toISOString(), request: `GET /repos/${REPOSITORY}/git/ref/heads/main`, available: false, state: "unavailable", reason: "network" },
      pull_requests: { repository: REPOSITORY, observed_at: OBSERVED_AT.toISOString(), requests: [`GET /repos/${REPOSITORY}/pulls?state=open&per_page=100&page=1`], available: false, state: "unavailable", reason: "network" },
      release_branches: { repository: REPOSITORY, observed_at: OBSERVED_AT.toISOString(), requests: [`GET /repos/${REPOSITORY}/git/matching-refs/heads/release/?per_page=100&page=1`], available: false, state: "unavailable", reason: "network" },
      actions: { repository: REPOSITORY, observed_at: OBSERVED_AT.toISOString(), requests: [`GET /repos/${REPOSITORY}/actions/runs?per_page=100&page=1`], available: false, state: "unavailable", reason: "network" }
    },
    planning: { ship_windows: readShipWindows({ root: repo }), milestone: "absent", state: "absent" },
    worktrees: collectWorktrees({ repo }),
    capture: {
      captured_at: OBSERVED_AT.toISOString(),
      active_ref: "refs/heads/main",
      commit: object,
      primary_worktree: { branch: "refs/heads/main", head: object }
    }
  };
  const records = path.join(evidence, "229-REPOSITORY-INVENTORY.json");
  const rendered = path.join(evidence, "229-REPOSITORY-INVENTORY.md");
  fs.writeFileSync(records, `${JSON.stringify(inventory, null, 2)}\n`);
  fs.writeFileSync(rendered, renderRepositoryInventory(inventory, createRepositoryValidationContext({ expectedRepository: REPOSITORY })));
  return { scratch, repo, bundle, manifestPath, manifestDigest };
}

function runDocumentedStrict(block, fixture, overrides = {}) {
  return spawnSync("bash", ["-eu", "-c", block], { cwd: fixture.repo, encoding: "utf8", shell: false, timeout: 30_000, env: { ...process.env, NODE_TEST_CONTEXT: "", PHASE229_PRIVATE_MANIFEST: fixture.manifestPath, PHASE229_MANIFEST_SHA256: fixture.manifestDigest, PHASE229_RECOVERY_BUNDLE: fixture.bundle, ...overrides } });
}

test("WR-01 documented strict command executes generated private authority and rejects invalid inputs", () => {
  const { block, readme } = documentedStrictBlock();
  assert.match(block, /test -n "\$\{PHASE229_PRIVATE_MANIFEST:-\}"/);
  assert.match(block, /--recovery-manifest "\$PHASE229_PRIVATE_MANIFEST"[\s\S]*--expected-manifest-sha256 "\$PHASE229_MANIFEST_SHA256"[\s\S]*--recovery-bundle "\$PHASE229_RECOVERY_BUNDLE"[\s\S]*--require-recovery/);
  assert.equal(readme.includes("accrue-phase229-recovery"), false, "README must not expose a private capsule location");
  const fixture = documentedStrictFixture();
  try {
    const valid = runDocumentedStrict(block, fixture); assert.equal(valid.status, 0, `${valid.stderr}\n${valid.stdout}`);
    for (const name of ["PHASE229_PRIVATE_MANIFEST", "PHASE229_MANIFEST_SHA256", "PHASE229_RECOVERY_BUNDLE"]) {
      const missing = { ...process.env, NODE_TEST_CONTEXT: "", PHASE229_PRIVATE_MANIFEST: fixture.manifestPath, PHASE229_MANIFEST_SHA256: fixture.manifestDigest, PHASE229_RECOVERY_BUNDLE: fixture.bundle }; delete missing[name];
      assert.notEqual(spawnSync("bash", ["-eu", "-c", block], { cwd: fixture.repo, encoding: "utf8", shell: false, env: missing }).status, 0, `${name} missing must fail`);
      assert.notEqual(runDocumentedStrict(block, fixture, { [name]: "" }).status, 0, `${name} empty must fail`);
    }
    assert.notEqual(runDocumentedStrict(block, fixture, { PHASE229_MANIFEST_SHA256: "0".repeat(64) }).status, 0, "wrong digest must fail");
    assert.notEqual(runDocumentedStrict(block, fixture, { PHASE229_RECOVERY_BUNDLE: path.join(fixture.scratch, "wrong.bundle") }).status, 0, "wrong bundle must fail");
    fs.chmodSync(fixture.manifestPath, 0o644);
    assert.notEqual(runDocumentedStrict(block, fixture).status, 0, "unsafe manifest permissions must fail");
  } finally { fs.chmodSync(fixture.manifestPath, 0o600); fs.rmSync(fixture.scratch, { recursive: true, force: true }); }
});

test("final handoff gate rejects capsule workspace and attestation invariant drift", () => {
  const result = spawnSync(process.execPath, [HANDOFF_INVARIANTS, "--self-test"], { encoding: "utf8", shell: false, timeout: 30_000, env: { ...process.env, NODE_TEST_CONTEXT: "" } });
  assert.equal(result.status, 0, `${result.stderr}\n${result.stdout}\n${result.error?.message || ""}`);
  for (const invariant of ["sibling-add", "sibling-delete", "sibling-rename", "content-digest", "link-digest", "type-swap", "mode", "owner", "raw-non-utf8", "untracked", "ref-tag", "worktree", "index", "status", "preexisting-attestation", "extra-entry", "exclusive-attestation"]) {
    assert.match(result.stdout, new RegExp(`handoff invariant ${invariant}: PASS`), `missing ${invariant} process-boundary evidence`);
  }
  assert.match(result.stdout, /phase229 handoff invariant self-test: PASS/);
});

test("final handoff capsule snapshots reject real filesystem identity drift", async () => {
  const { assertExact, assertOnlyAttestation, snapshotTree } = await loadHandoffLibrary();
  const scratch = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "phase229-capsule-behavior-")));
  const makeCapsule = () => {
    const capsule = path.join(scratch, crypto.randomUUID());
    fs.mkdirSync(capsule);
    fs.writeFileSync(path.join(capsule, "record"), "before", { mode: 0o600 });
    fs.symlinkSync(Buffer.from([0x74, 0x61, 0x72, 0x67, 0x65, 0x74, 0x0a]), path.join(capsule, "link"));
    return capsule;
  };
  const rejectMutation = (mutate) => {
    const capsule = makeCapsule();
    const before = snapshotTree(capsule);
    mutate(capsule);
    assert.throws(() => assertExact("capsule", before, snapshotTree(capsule)), /capsule changed/);
  };

  try {
    rejectMutation((capsule) => fs.writeFileSync(path.join(capsule, "added"), "new"));
    rejectMutation((capsule) => fs.rmSync(path.join(capsule, "record")));
    rejectMutation((capsule) => fs.renameSync(path.join(capsule, "record"), path.join(capsule, "renamed")));
    rejectMutation((capsule) => fs.writeFileSync(path.join(capsule, "record"), "after"));
    rejectMutation((capsule) => {
      fs.rmSync(path.join(capsule, "link"));
      fs.symlinkSync(Buffer.from([0xff, 0x0a]), path.join(capsule, "link"));
    });
    rejectMutation((capsule) => fs.chmodSync(path.join(capsule, "record"), 0o644));
    rejectMutation((capsule) => {
      fs.rmSync(path.join(capsule, "record"));
      fs.mkdirSync(path.join(capsule, "record"));
    });

    const capsule = makeCapsule();
    const before = snapshotTree(capsule);
    const attestation = path.join(capsule, "final.json");
    fs.writeFileSync(attestation, "{}\n", { mode: 0o600 });
    fs.chmodSync(attestation, 0o600);
    assert.equal(assertOnlyAttestation(before, snapshotTree(capsule), "final.json"), true);
    fs.writeFileSync(path.join(capsule, "unexpected"), "extra");
    assert.throws(() => assertOnlyAttestation(before, snapshotTree(capsule), "final.json"), /pre-existing capsule entries changed/);
    fs.rmSync(path.join(capsule, "unexpected"));
    fs.chmodSync(attestation, 0o644);
    assert.throws(() => assertOnlyAttestation(before, snapshotTree(capsule), "final.json"), /sole capsule delta/);
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
});

test("final handoff workspace snapshots reject real untracked ref and worktree drift", async () => {
  const { assertExact, snapshotWorkspace } = await loadHandoffLibrary();
  const scratch = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "phase229-workspace-behavior-")));
  const repo = path.join(scratch, "repo");
  const linked = path.join(scratch, "linked");
  try {
    fs.mkdirSync(repo);
    git(repo, ["init", "-q", "-b", "main"]);
    git(repo, ["config", "user.email", "phase229@example.invalid"]);
    git(repo, ["config", "user.name", "phase229"]);
    fs.writeFileSync(path.join(repo, "tracked"), "one\n");
    git(repo, ["add", "tracked"]);
    git(repo, ["commit", "-qm", "one"]);
    const first = git(repo, ["rev-parse", "HEAD"]);
    fs.writeFileSync(path.join(repo, "tracked"), "two\n");
    git(repo, ["commit", "-qam", "two"]);
    const second = git(repo, ["rev-parse", "HEAD"]);
    git(repo, ["tag", "handoff-fixture", first]);
    git(repo, ["branch", "linked", first]);
    git(repo, ["worktree", "add", "-q", linked, "linked"]);
    fs.writeFileSync(path.join(repo, "untracked"), "before\n");

    let before = snapshotWorkspace(repo);
    fs.writeFileSync(path.join(repo, "untracked"), "after\n");
    assert.throws(() => assertExact("workspace", before, snapshotWorkspace(repo)), /workspace changed/);
    fs.writeFileSync(path.join(repo, "untracked"), "before\n");

    before = snapshotWorkspace(repo);
    git(repo, ["update-ref", "refs/tags/handoff-fixture", second]);
    assert.throws(() => assertExact("workspace", before, snapshotWorkspace(repo)), /workspace changed/);
    git(repo, ["update-ref", "refs/tags/handoff-fixture", first]);

    before = snapshotWorkspace(repo);
    git(linked, ["switch", "-q", "--detach"]);
    assert.throws(() => assertExact("workspace", before, snapshotWorkspace(repo)), /workspace changed/);
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
});

const CANONICAL_RECORDS_RELATIVE = ".planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json";
const CANONICAL_RENDERED_RELATIVE = ".planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md";
const TEST_OWNED_MARKER = ".phase229-test-owned";

// `activeBranch` models the real phase shape, where the active execution ref is a milestone
// branch distinct from refs/heads/main: main stays put while the milestone branch advances.
function finalChainFixture({ activeBranch } = {}) {
  const scratch = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "phase229-final-chain-")));
  const repo = path.join(scratch, "repo");
  const capsule = path.join(scratch, "capsule");
  fs.mkdirSync(repo); fs.mkdirSync(capsule);
  fs.mkdirSync(path.join(repo, ".planning/phases/229-repository-truth-recovery-safety"), { recursive: true });
  git(repo, ["init", "-q", "-b", "main"]);
  git(repo, ["config", "user.email", "phase229@example.invalid"]);
  git(repo, ["config", "user.name", "phase229"]);
  fs.writeFileSync(path.join(repo, ".planning/WINDOWS.md"), [
    "---", "open_count: 0", "waived_count: 0", "fixed_count: 0", "total_count: 0", "---", "",
    "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |",
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |", ""
  ].join("\n"));
  fs.writeFileSync(path.join(repo, "tracked"), "fixture\n");
  git(repo, ["add", ".planning/WINDOWS.md", "tracked"]);
  git(repo, ["commit", "-qm", "fixture"]);
  const object = git(repo, ["rev-parse", "HEAD"]);
  git(repo, ["update-ref", "refs/remotes/origin/main", object]);
  git(repo, ["tag", "v1.61", object]);
  if (activeBranch) git(repo, ["checkout", "-q", "-b", activeBranch]);
  fs.writeFileSync(path.join(repo, ".planning/milestone.lock"), "before-lock\n");
  fs.writeFileSync(path.join(repo, ".planning/state.json"), "before-state\n");
  const bundle = path.join(capsule, "recovery.bundle");
  const manifestPath = path.join(capsule, "manifest.json");
  const preserved = spawnSync("bash", [PRESERVE_REPOSITORY, "--repo-root", repo, "--expected-repository", REPOSITORY, "--bundle-out", bundle, "--private-manifest-out", manifestPath], { encoding: "utf8", shell: false, timeout: 30_000 });
  assert.equal(preserved.status, 0, preserved.stderr);
  const manifestDigest = sha256(fs.readFileSync(manifestPath));
  // A second, real workflow-metadata change after the manifest snapshot: required by
  // writeCurrentArtifactAttestation, which insists workflow paths actually moved.
  fs.writeFileSync(path.join(repo, ".planning/milestone.lock"), "after-lock\n");
  fs.writeFileSync(path.join(repo, ".planning/state.json"), "after-state\n");
  const attestation = path.join(capsule, "attestation.json");
  const token = crypto.randomUUID();
  fs.writeFileSync(path.join(repo, TEST_OWNED_MARKER), token);
  fs.writeFileSync(path.join(capsule, TEST_OWNED_MARKER), token);
  return { scratch, repo, capsule, bundle, manifestPath, manifestDigest, attestation, token, object };
}

function runFinalChainCli(fixture, extraEnv = {}) {
  return spawnSync(process.execPath, [
    HANDOFF_INVARIANTS,
    "--run-final-chain",
    "--repository-root", fixture.repo,
    "--capsule-directory", fixture.capsule,
    "--recovery-manifest", fixture.manifestPath,
    "--expected-manifest-sha256", fixture.manifestDigest,
    "--recovery-bundle", fixture.bundle,
    "--attestation", fixture.attestation,
    "--records", CANONICAL_RECORDS_RELATIVE,
    "--rendered", CANONICAL_RENDERED_RELATIVE,
    "--expected-repository", REPOSITORY
  ], { encoding: "utf8", shell: false, timeout: 120_000, env: { ...process.env, NODE_TEST_CONTEXT: "", ...extraEnv } });
}

test("WR-01 real final-chain subprocess proves canonical publication, attestation binding, and exact rollback around the actual mutation boundaries", () => {
  const fixture = finalChainFixture();
  const recordsPath = path.join(fixture.repo, CANONICAL_RECORDS_RELATIVE);
  const renderedPath = path.join(fixture.repo, CANONICAL_RENDERED_RELATIVE);
  try {
    const valid = runFinalChainCli(fixture);
    assert.equal(valid.status, 0, `${valid.stderr}\n${valid.stdout}`);
    assert.match(valid.stdout, /phase229 final handoff invariants: PASS/);
    assert.ok(fs.existsSync(recordsPath) && fs.existsSync(renderedPath) && fs.existsSync(fixture.attestation), "the real final chain must publish both canonical outputs and the handoff attestation");
    const attestation = JSON.parse(fs.readFileSync(fixture.attestation, "utf8"));
    assert.equal(attestation.schema_version, 2);
    assert.equal(attestation.result, "PASS");
    assert.equal(attestation.records_sha256, sha256(fs.readFileSync(recordsPath)));
    assert.equal(attestation.rendered_sha256, sha256(fs.readFileSync(renderedPath)));
  } finally {
    fs.rmSync(fixture.scratch, { recursive: true, force: true });
  }

  // A mismatched token must never activate a mutation hook: the chain runs unmutated and passes.
  const guarded = finalChainFixture();
  try {
    const result = runFinalChainCli(guarded, { PHASE229_TEST_MUTATION: JSON.stringify({ boundary: "before-collection", action: "unstaged", token: "wrong-token" }), PHASE229_TEST_MUTATION_TOKEN: "wrong-token" });
    assert.equal(result.status, 0, `an unmatched mutation token must never fire: ${result.stderr}\n${result.stdout}`);
  } finally {
    fs.rmSync(guarded.scratch, { recursive: true, force: true });
  }

  const mutations = [
    ["before-collection", "unstaged"],
    ["before-collection", "staged"],
    ["before-collection", "add"],
    ["before-collection", "delete"],
    ["before-collection", "rename"],
    ["before-collection", "mode"],
    ["before-collection", "ref"],
    ["before-collection", "worktree"],
    ["before-collection", "untracked"],
    ["before-publish", "capsule"],
    ["before-attestation", "capsule"]
  ];
  for (const [boundary, action] of mutations) {
    const mutant = finalChainFixture();
    const mutantRecords = path.join(mutant.repo, CANONICAL_RECORDS_RELATIVE);
    const mutantRendered = path.join(mutant.repo, CANONICAL_RENDERED_RELATIVE);
    try {
      const result = runFinalChainCli(mutant, { PHASE229_TEST_MUTATION: JSON.stringify({ boundary, action, token: mutant.token }), PHASE229_TEST_MUTATION_TOKEN: mutant.token });
      assert.notEqual(result.status, 0, `mutation ${boundary}:${action} must fail the real final-chain process`);
      assert.doesNotMatch(result.stdout, /phase229 final handoff invariants: PASS/, `mutation ${boundary}:${action} must never print PASS`);
      assert.equal(fs.existsSync(mutantRecords), false, `mutation ${boundary}:${action} must not leave a newly published canonical record`);
      assert.equal(fs.existsSync(mutantRendered), false, `mutation ${boundary}:${action} must not leave newly published canonical Markdown`);
      assert.equal(fs.existsSync(mutant.attestation), false, `mutation ${boundary}:${action} must not leave a handoff attestation`);
    } finally {
      fs.rmSync(mutant.scratch, { recursive: true, force: true });
    }
  }
});

function strictPublishedPair(fixture, extraFlags = []) {
  return spawnSync(process.execPath, [
    VERIFY_INVENTORY,
    "--records", path.join(fixture.repo, CANONICAL_RECORDS_RELATIVE),
    "--rendered", path.join(fixture.repo, CANONICAL_RENDERED_RELATIVE),
    "--expected-repository", REPOSITORY,
    "--repository-root", fixture.repo,
    "--recovery-manifest", fixture.manifestPath,
    "--expected-manifest-sha256", fixture.manifestDigest,
    "--recovery-bundle", fixture.bundle,
    "--handoff-attestation", fixture.attestation,
    "--require-recovery", "--require-all-ref-recovery", "--require-typed-artifacts",
    "--require-complete-categories", "--require-edge-cases", "--require-command-provenance",
    "--require-privacy-controls", "--require-determinism", "--require-handoff-attestation",
    ...extraFlags
  ], { encoding: "utf8", shell: false, timeout: 120_000, env: { ...process.env, NODE_TEST_CONTEXT: undefined } });
}

// CR-03 / D-03: the private capsule is minted once, early, and is then immutable for the rest
// of the phase -- so by the time the canonical inventory is captured, the manifest has frozen
// the active ref many commits in the past. Demanding exact ref equality there would make every
// real capsule permanently unverifiable; proven same-ref ancestry is the property that actually
// holds. The generated-capsule fixtures mint and capture at the same commit, so this gap is
// invisible to them unless the active ref is advanced first, as it is here.
test("CR-03 strict recovery accepts an active ref advanced past the manifest freeze and rejects a diverged one", () => {
  const BRANCH = "gsd/milestone-fixture";
  const advanced = finalChainFixture({ activeBranch: BRANCH });
  try {
    const frozen = git(advanced.repo, ["rev-parse", "HEAD"]);
    for (const step of [1, 2, 3]) {
      fs.writeFileSync(path.join(advanced.repo, `advance-${step}`), `advance ${step}\n`);
      git(advanced.repo, ["add", "--", `advance-${step}`]);
      git(advanced.repo, ["commit", "-qm", `chore: advance the active ref past the manifest freeze ${step}`]);
    }
    const captureCommit = git(advanced.repo, ["rev-parse", "HEAD"]);
    assert.notEqual(captureCommit, frozen, "the active ref must actually advance past the manifest freeze");
    assert.equal(
      spawnSync("git", ["-C", advanced.repo, "merge-base", "--is-ancestor", frozen, captureCommit], { encoding: "utf8", shell: false, timeout: 15_000 }).status,
      0,
      "the advanced fixture must keep the frozen object reachable"
    );

    const published = runFinalChainCli(advanced);
    assert.equal(published.status, 0, `a capsule frozen before the capture commit must remain verifiable: ${published.stderr}\n${published.stdout}`);
    const attestation = JSON.parse(fs.readFileSync(advanced.attestation, "utf8"));
    assert.equal(attestation.capture.commit, captureCommit, "capture must anchor the advanced commit, not the manifest freeze");
    assert.equal(strictPublishedPair(advanced).status, 0, "documented strict verification must accept the advanced active ref");
  } finally {
    fs.rmSync(advanced.scratch, { recursive: true, force: true });
  }

  // The exemption must be ancestry, not a blanket skip: a same-tree root commit leaves the
  // working tree, index and tracked set byte-identical, so only the ancestry check can catch it.
  const diverged = finalChainFixture({ activeBranch: BRANCH });
  try {
    const frozen = git(diverged.repo, ["rev-parse", "HEAD"]);
    const tree = git(diverged.repo, ["rev-parse", "HEAD^{tree}"]);
    const orphan = git(diverged.repo, ["commit-tree", tree, "-m", "diverged root with an identical tree"]);
    git(diverged.repo, ["update-ref", `refs/heads/${BRANCH}`, orphan]);
    assert.notEqual(orphan, frozen, "the diverged commit must differ from the manifest freeze");
    assert.notEqual(
      spawnSync("git", ["-C", diverged.repo, "merge-base", "--is-ancestor", frozen, orphan], { encoding: "utf8", shell: false, timeout: 15_000 }).status,
      0,
      "the diverged fixture must actually break ancestry"
    );

    const rejected = runFinalChainCli(diverged);
    assert.notEqual(rejected.status, 0, "an active ref that diverged from the manifest freeze must be rejected");
    assert.match(`${rejected.stdout}${rejected.stderr}`, /must be an ancestor of the captured active commit/);
    assert.ok(!fs.existsSync(diverged.attestation), "a rejected chain must not create the handoff attestation");
  } finally {
    fs.rmSync(diverged.scratch, { recursive: true, force: true });
  }
});

// CR-03 / D-03: the canonical pair is captured at commit A and then necessarily committed
// (commit B), after which further phase artifacts land (commit C). Capture ancestry plus the
// external attestation must keep strict verification valid as the active branch advances --
// otherwise the act of committing the inventory would invalidate the inventory.
test("CR-03 published canonical pair stays strictly verifiable after its own commit and later phase commits", () => {
  const fixture = finalChainFixture();
  const recordsPath = path.join(fixture.repo, CANONICAL_RECORDS_RELATIVE);
  const renderedPath = path.join(fixture.repo, CANONICAL_RENDERED_RELATIVE);
  const summaryRelative = ".planning/phases/229-repository-truth-recovery-safety/229-20-SUMMARY.md";
  try {
    const published = runFinalChainCli(fixture);
    assert.equal(published.status, 0, `${published.stderr}\n${published.stdout}`);
    const attestation = JSON.parse(fs.readFileSync(fixture.attestation, "utf8"));
    assert.equal(attestation.capture.commit, git(fixture.repo, ["rev-parse", "HEAD"]), "capture must anchor the commit the inventory was taken at");

    assert.equal(strictPublishedPair(fixture).status, 0, "strict verification must pass immediately after publication at capture commit A");

    git(fixture.repo, ["add", "--", CANONICAL_RECORDS_RELATIVE, CANONICAL_RENDERED_RELATIVE]);
    git(fixture.repo, ["commit", "-qm", "feat(229-20): publish canonical repository inventory"]);
    const atB = git(fixture.repo, ["rev-parse", "HEAD"]);
    assert.notEqual(atB, attestation.capture.commit, "commit B must actually advance the active branch");
    assert.equal(strictPublishedPair(fixture).status, 0, "strict verification must survive committing the canonical pair itself");

    fs.writeFileSync(path.join(fixture.repo, summaryRelative), "# 229-20 summary\n");
    git(fixture.repo, ["add", "--", summaryRelative]);
    git(fixture.repo, ["commit", "-qm", "docs(229-20): seal plan summary"]);
    assert.notEqual(git(fixture.repo, ["rev-parse", "HEAD"]), atB, "commit C must advance past commit B");
    assert.equal(strictPublishedPair(fixture).status, 0, "strict verification must survive later phase summary commits");

    // The surviving verification is bound to the exact published bytes, not merely to ancestry.
    const records = fs.readFileSync(recordsPath);
    const tamperedRecords = Buffer.concat([records, Buffer.from("\n")]);
    assert.notEqual(sha256(tamperedRecords), sha256(records), "the records tamper must actually change bytes");
    fs.writeFileSync(recordsPath, tamperedRecords);
    assert.notEqual(strictPublishedPair(fixture).status, 0, "tampered canonical records must fail at commit C");
    fs.writeFileSync(recordsPath, records);
    assert.equal(strictPublishedPair(fixture).status, 0, "restoring the exact published bytes must pass again");

    const rendered = fs.readFileSync(renderedPath);
    const tamperedRendered = Buffer.concat([rendered, Buffer.from("\n")]);
    assert.notEqual(sha256(tamperedRendered), sha256(rendered), "the rendered tamper must actually change bytes");
    fs.writeFileSync(renderedPath, tamperedRendered);
    assert.notEqual(strictPublishedPair(fixture).status, 0, "tampered canonical Markdown must fail at commit C");
    fs.writeFileSync(renderedPath, rendered);

    const substituted = JSON.parse(fs.readFileSync(fixture.attestation, "utf8"));
    substituted.records_sha256 = sha256(Buffer.from("foreign"));
    const substitutePath = path.join(fixture.capsule, "substituted-attestation.json");
    fs.writeFileSync(substitutePath, JSON.stringify(substituted), { mode: 0o600 });
    const swapped = spawnSync(process.execPath, [
      VERIFY_INVENTORY,
      "--records", recordsPath, "--rendered", renderedPath,
      "--expected-repository", REPOSITORY, "--repository-root", fixture.repo,
      "--recovery-manifest", fixture.manifestPath, "--expected-manifest-sha256", fixture.manifestDigest,
      "--recovery-bundle", fixture.bundle, "--handoff-attestation", substitutePath,
      "--require-recovery", "--require-handoff-attestation"
    ], { encoding: "utf8", shell: false, timeout: 120_000, env: { ...process.env, NODE_TEST_CONTEXT: undefined } });
    assert.notEqual(swapped.status, 0, "a substituted attestation must never validate the published pair");
  } finally {
    fs.rmSync(fixture.scratch, { recursive: true, force: true });
  }
});

test("CR-01 preservation rejects post-snapshot artifact mutation before PASS", () => {
  const script = fileURLToPath(new URL("./preserve_repository_state.sh", import.meta.url));
  const result = spawnSync("bash", [script, "--self-test"], { encoding: "utf8", shell: false, timeout: 30_000 });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /preserve repository state self-test: PASS/);
});

test("CR-02 preservation hashes raw symlink link-text bytes including newline edges", () => {
  const script = fileURLToPath(new URL("./preserve_repository_state.sh", import.meta.url));
  const result = spawnSync("bash", [script, "--self-test"], { encoding: "utf8", shell: false, timeout: 30_000 });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /preserve repository state self-test: PASS/);
});

test("CR-03 plural GitHub evidence requires a terminal page and fails closed at bounds", () => {
  const sha = (index) => index.toString(16).padStart(40, "0");
  const fullPage = Array.from({ length: 100 }, (_, index) => ({ number: index + 1, head: { sha: sha(index + 1) } }));
  const responses = new Map([
    [`repos/${REPOSITORY}/git/ref/heads/main`, { object: { sha: sha(500) } }],
    [`repos/${REPOSITORY}/pulls?state=open&per_page=100&page=1`, fullPage],
    [`repos/${REPOSITORY}/pulls?state=open&per_page=100&page=2`, [{ number: 101, head: { sha: sha(101) } }]],
    [`repos/${REPOSITORY}/git/matching-refs/heads/release/?per_page=100&page=1`, []],
    [`repos/${REPOSITORY}/actions/runs?per_page=100&page=1`, { workflow_runs: [] }]
  ]);
  const adapter = createGhApiReadAdapter({ invoke: (argv) => ({ status: 0, stdout: JSON.stringify(responses.get(argv[1])), stderr: "" }) });
  const observed = collectRemoteFacts({ repository: REPOSITORY, adapter, now: () => OBSERVED_AT });
  assert.equal(observed.pull_requests.shas.length, 101);
  assert.equal(observed.pull_requests.requests.length, 2);
  const overflow = collectRemoteFacts({ repository: REPOSITORY, adapter: createGhApiReadAdapter({ maxPages: 1, invoke: (argv) => ({ status: 0, stdout: JSON.stringify(responses.get(argv[1])), stderr: "" }) }), now: () => OBSERVED_AT });
  assert.equal(overflow.pull_requests.reason, "overflow");
  assert.equal("shas" in overflow.pull_requests, false);
});

test("CR-04 strict recovery rejects a fabricated active ref and accepts the actual live object", () => {
  const fixture = strictVerifierFixture();
  try {
    const valid = runStrictVerifier(fixture, fixture.inventory);
    assert.equal(valid.status, 0, `${valid.stderr}\n${valid.stdout}\n${valid.error?.message || ""}`);
    const fabricated = structuredClone(fixture.inventory);
    fabricated.refs.local_main = "f".repeat(40);
    fabricated.refs.milestone_branch = "f".repeat(40);
    fabricated.refs.all.find((row) => row.name === "refs/heads/main").object = "f".repeat(40);
    const rejected = runStrictVerifier(fixture, fabricated);
    assert.notEqual(rejected.status, 0, "fabricated active object must fail the public strict verifier");
  } finally {
    fs.rmSync(fixture.scratch, { recursive: true, force: true });
  }
});

test("CR-05 strict recovery rejects missing extra duplicate and changed canonical preservation rows", () => {
  const fixture = strictVerifierFixture();
  try {
    const preservation = fixture.inventory.refs.all.filter((row) => row.name.startsWith(PRESERVATION_PREFIX));
    const variants = [];
    const missing = structuredClone(fixture.inventory); missing.refs.all = missing.refs.all.filter((row) => !row.name.startsWith(PRESERVATION_PREFIX)); variants.push(missing);
    const extra = structuredClone(fixture.inventory); extra.refs.all.push({ name: `${PRESERVATION_PREFIX}6578747261`, object: fixture.object, role: "phase229_preservation" }); variants.push(extra);
    const duplicate = structuredClone(fixture.inventory); duplicate.refs.all.push(structuredClone(preservation[0])); variants.push(duplicate);
    const changed = structuredClone(fixture.inventory); changed.refs.all.find((row) => row.name === preservation[0].name).object = "f".repeat(40); variants.push(changed);
    for (const inventory of variants) assert.notEqual(runStrictVerifier(fixture, inventory).status, 0, "canonical preservation mutation must fail the public strict verifier");
  } finally {
    fs.rmSync(fixture.scratch, { recursive: true, force: true });
  }
});

test("CR-06 complete categories reject missing extra duplicate and changed worktree or ship-window rows", () => {
  const fixture = strictVerifierFixture();
  try {
    const variants = [];
    const missingWindow = structuredClone(fixture.inventory); missingWindow.planning.ship_windows.pop(); variants.push(missingWindow);
    const extraWindow = structuredClone(fixture.inventory); extraWindow.planning.ship_windows.push("999:open"); variants.push(extraWindow);
    const changedWindow = structuredClone(fixture.inventory); changedWindow.planning.ship_windows[0] = "1:fixed"; variants.push(changedWindow);
    const missingWorktree = structuredClone(fixture.inventory); missingWorktree.worktrees.pop(); variants.push(missingWorktree);
    const extraWorktree = structuredClone(fixture.inventory); extraWorktree.worktrees.push({ branch: "invented", sha: fixture.object, dirty: false }); variants.push(extraWorktree);
    const duplicateWorktree = structuredClone(fixture.inventory); duplicateWorktree.worktrees.push(structuredClone(duplicateWorktree.worktrees[0])); variants.push(duplicateWorktree);
    const changedWorktree = structuredClone(fixture.inventory); changedWorktree.worktrees[0].dirty = !changedWorktree.worktrees[0].dirty; variants.push(changedWorktree);
    for (const inventory of variants) assert.notEqual(runStrictVerifier(fixture, inventory).status, 0, "local category mutation must fail the public strict verifier");
  } finally {
    fs.rmSync(fixture.scratch, { recursive: true, force: true });
  }
});

test("CR-07 strict provenance rejects unrelated missing duplicate skipped reordered foreign and over-bound requests", () => {
  const fixture = strictVerifierFixture();
  try {
    assert.equal(runStrictVerifier(fixture, fixture.inventory, ["--require-command-provenance"]).status, 0, "exact category provenance must pass");
    const variants = [];
    const unrelated = structuredClone(fixture.inventory); unrelated.remotes.remote_main.request = `GET /repos/${REPOSITORY}/issues`; variants.push(unrelated);
    const missing = structuredClone(fixture.inventory); missing.remotes.pull_requests.requests = []; variants.push(missing);
    const duplicate = structuredClone(fixture.inventory); duplicate.remotes.pull_requests.requests = [
      `GET /repos/${REPOSITORY}/pulls?state=open&per_page=100&page=1`,
      `GET /repos/${REPOSITORY}/pulls?state=open&per_page=100&page=1`
    ]; variants.push(duplicate);
    const skipped = structuredClone(fixture.inventory); skipped.remotes.release_branches.requests = [
      `GET /repos/${REPOSITORY}/git/matching-refs/heads/release/?per_page=100&page=1`,
      `GET /repos/${REPOSITORY}/git/matching-refs/heads/release/?per_page=100&page=3`
    ]; variants.push(skipped);
    const reordered = structuredClone(fixture.inventory); reordered.remotes.actions.requests = [
      `GET /repos/${REPOSITORY}/actions/runs?per_page=100&page=2`,
      `GET /repos/${REPOSITORY}/actions/runs?per_page=100&page=1`
    ]; variants.push(reordered);
    const foreign = structuredClone(fixture.inventory); foreign.remotes.actions.requests = ["GET /repos/other/repository/actions/runs?per_page=100&page=1"]; variants.push(foreign);
    const overBound = structuredClone(fixture.inventory); overBound.remotes.actions.requests = Array.from({ length: 11 }, (_, index) => `GET /repos/${REPOSITORY}/actions/runs?per_page=100&page=${index + 1}`); variants.push(overBound);
    const noTerminalPage = structuredClone(fixture.inventory); noTerminalPage.remotes.pull_requests.available = true; noTerminalPage.remotes.pull_requests.state = "observed"; delete noTerminalPage.remotes.pull_requests.reason; noTerminalPage.remotes.pull_requests.shas = Array.from({ length: 100 }, (_, index) => (index + 1).toString(16).padStart(40, "0")); variants.push(noTerminalPage);
    for (const inventory of variants) assert.notEqual(runStrictVerifier(fixture, inventory, ["--require-command-provenance"]).status, 0, "invalid category provenance must fail the public strict verifier");
  } finally {
    fs.rmSync(fixture.scratch, { recursive: true, force: true });
  }
});

test("CR-08 strict privacy rejects POSIX Windows UNC file URI and control-bearing locations", () => {
  const fixture = strictVerifierFixture();
  try {
    assert.equal(runStrictVerifier(fixture, fixture.inventory, ["--require-privacy-controls"]).status, 0, "normalized repository-relative evidence must pass privacy controls");
    const forbidden = [
      "/var/private/phase229-capsule.json", "/root/capsule", "/opt/capsule", "/private/tmp/capsule",
      "C:\\private\\capsule", "C:private\\capsule", "\\\\server\\share\\capsule", "file:///private/capsule",
      "relative\nvalue", "relative\rvalue", "relative\tvalue", `relative${String.fromCharCode(0x7f)}value`
    ];
    for (const value of forbidden) {
      const inventory = structuredClone(fixture.inventory);
      inventory.planning.state = value;
      assert.notEqual(runStrictVerifier(fixture, inventory, ["--require-privacy-controls"]).status, 0, `private/path-like value must fail: ${JSON.stringify(value)}`);
    }
  } finally {
    fs.rmSync(fixture.scratch, { recursive: true, force: true });
  }
});

test("CR-09 CI watch enforces its wall-clock deadline through the public process", () => {
  const monitor = fileURLToPath(new URL("./ci_monitor.cjs", import.meta.url));
  const result = runIsolatedNodeTest(monitor, "watch absolute deadline bounds delayed GitHub reads");
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /ok 1 - watch absolute deadline bounds delayed GitHub reads/);
});

test("WR-02 CI inspection rejects selected-viewed run ID and workflow switching", () => {
  const monitor = fileURLToPath(new URL("./ci_monitor.cjs", import.meta.url));
  const result = runIsolatedNodeTest(monitor, "inspect binds selected run identity before job summary");
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /ok 1 - inspect binds selected run identity before job summary/);
});

test("bounded remote-unavailable evidence retains its reason without a substituted SHA", () => {
  const cases = new Map([
    ["network ENOTFOUND", "network"],
    ["authentication 401", "authentication"],
    ["rate limit 429", "rate_limit"],
    ["timeout ETIMEDOUT", "timeout"],
    ["maxBuffer overflow", "overflow"],
    ["malformed response", "data_shape"]
  ]);

  for (const [message, reason] of cases) {
    const facts = collectRemoteFacts({
      repository: REPOSITORY,
      adapter: { get: () => { throw new Error(message); } },
      now: () => OBSERVED_AT
    });

    for (const fact of Object.values(facts)) {
      assert.equal(fact.available, false);
      assert.equal(fact.reason, reason);
      assert.equal("sha" in fact, false);
      assert.equal("shas" in fact, false);
      const requests = fact.requests || [fact.request];
      assert.ok(requests.length > 0);
      requests.forEach((request) => assert.match(request, /^GET \/repos\/szTheory\/accrue\//));
    }
  }
});

test("sanitized collection records every worktree with dirty and detached state but no path", () => {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "phase229-worktrees-"));
  const repo = path.join(scratch, "repo");
  const linked = path.join(scratch, "linked");
  const detached = path.join(scratch, "detached");

  try {
    fs.mkdirSync(repo);
    git(repo, ["init", "-q", "-b", "main"]);
    git(repo, ["config", "user.email", "phase229@example.invalid"]);
    git(repo, ["config", "user.name", "phase229"]);
    fs.writeFileSync(path.join(repo, "tracked"), "fixture\n");
    git(repo, ["add", "tracked"]);
    git(repo, ["commit", "-qm", "fixture"]);
    const object = git(repo, ["rev-parse", "HEAD"]);
    git(repo, ["branch", "secondary"]);
    git(repo, ["worktree", "add", "-q", linked, "secondary"]);
    git(repo, ["worktree", "add", "-q", "--detach", detached, object]);
    fs.writeFileSync(path.join(linked, "untracked"), "dirty\n");

    const rows = collectWorktrees({ repo });
    assert.deepEqual(rows, [
      { branch: "detached", sha: object, dirty: false },
      { branch: "main", sha: object, dirty: false },
      { branch: "secondary", sha: object, dirty: true }
    ]);
    assert.ok(rows.every((row) => Object.keys(row).sort().join(",") === "branch,dirty,sha"));
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
});

test("ship-window collection distinguishes observed-empty authority and rejects inconsistent counts", () => {
  const table = "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n";
  const empty = `---\nopen_count: 0\nwaived_count: 0\nfixed_count: 0\ntotal_count: 0\n---\n${table}`;
  assert.deepEqual(readShipWindows({ root: "/fixture", readFile: () => empty }), []);

  const inconsistent = `---\nopen_count: 1\nwaived_count: 0\nfixed_count: 0\ntotal_count: 1\n---\n${table}`;
  assert.throws(
    () => readShipWindows({ root: "/fixture", readFile: () => inconsistent }),
    /counts are inconsistent/
  );
});

test("collection rejects a foreign recovery manifest before bundle or remote access", () => {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "phase229-foreign-manifest-"));
  const repo = path.join(scratch, "repo");
  const manifestPath = path.join(scratch, "manifest.json");
  let remoteCalls = 0;

  try {
    fs.mkdirSync(repo);
    git(repo, ["init", "-q", "-b", "main"]);
    const manifest = {
      schema_version: 1,
      repository: "other/repository",
      recovery_verified: true,
      bundle_sha256: "0".repeat(64),
      refs: [],
      artifacts: []
    };
    const bytes = Buffer.from(`${JSON.stringify(manifest)}\n`);
    fs.writeFileSync(manifestPath, bytes, { mode: 0o600 });
    fs.chmodSync(manifestPath, 0o600);

    assert.throws(
      () => collectRepositoryInventory({
        repo,
        recoveryManifest: manifestPath,
        expectedManifestSha256: crypto.createHash("sha256").update(bytes).digest("hex"),
        recoveryBundle: path.join(scratch, "must-not-be-opened.bundle"),
        finalCaptureAttestation: path.join(scratch, "must-not-be-opened-attestation.json"),
        expectedRepository: REPOSITORY,
        observeRemote: true,
        adapter: { get: () => { remoteCalls += 1; } }
      }),
      /recovery manifest repository must match expectedRepository/
    );
    assert.equal(remoteCalls, 0);
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
});
