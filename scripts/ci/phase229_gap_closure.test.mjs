import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

import {
  collectRemoteFacts,
  collectRepositoryInventory,
  collectWorktrees,
  readShipWindows
} from "./collect_repository_inventory.mjs";

const REPOSITORY = "szTheory/accrue";
const OBSERVED_AT = new Date("2026-09-13T00:00:00.000Z");

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

test("CR-06 preserves every bounded remote-unavailable reason without a substituted SHA", () => {
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
      assert.match(fact.request, /^GET \/repos\/szTheory\/accrue\//);
    }
  }
});

test("CR-07 collects every real worktree with dirty and detached state but no path", () => {
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

test("CR-07 distinguishes an observed-empty ship-window ledger and rejects inconsistent counts", () => {
  const table = "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n";
  const empty = `---\nopen_count: 0\nwaived_count: 0\nfixed_count: 0\ntotal_count: 0\n---\n${table}`;
  assert.deepEqual(readShipWindows({ root: "/fixture", readFile: () => empty }), []);

  const inconsistent = `---\nopen_count: 1\nwaived_count: 0\nfixed_count: 0\ntotal_count: 1\n---\n${table}`;
  assert.throws(
    () => readShipWindows({ root: "/fixture", readFile: () => inconsistent }),
    /counts are inconsistent/
  );
});

test("CR-08 rejects a foreign recovery manifest before bundle or remote access", () => {
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
