import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import test from "node:test";

import {
  createGhApiReadAdapter,
  collectRemoteFacts,
  collectRepositoryInventory,
  collectWorktrees,
  readShipWindows
} from "./collect_repository_inventory.mjs";

const REPOSITORY = "szTheory/accrue";
const OBSERVED_AT = new Date("2026-09-13T00:00:00.000Z");
const VERIFY_INVENTORY = fileURLToPath(new URL("./verify_repository_inventory.mjs", import.meta.url));
const RENDER_INVENTORY = fileURLToPath(new URL("./render_repository_inventory.mjs", import.meta.url));
const PRESERVATION_PREFIX = "refs/accrue-preserve/phase-229/";
const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");
const encodedRef = (name) => `${PRESERVATION_PREFIX}${Buffer.from(name).toString("hex")}`;

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
    worktrees: collectWorktrees({ repo })
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
