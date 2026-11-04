// Phase 254 CIQ-03 (D-18): tests for the visual identity manifest tooling. Every rejection has a passing
// control; git behavior runs only in scratch repositories under the OS temp directory.

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import { createRequire } from "node:module";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import * as manifest from "./phase254_visual_manifest.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../..");
const guard = createRequire(import.meta.url)("../../accrue_admin/e2e/visual-baseline-set.cjs");
const { snapshotFileName } = guard;

function tmp(prefix) {
  return fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), prefix));
}

function scratchRepo() {
  const dir = tmp("phase254-visual-git-");
  const env = { ...process.env };
  for (const name of ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"]) delete env[name];
  const run = (...args) => {
    const result = spawnSync("git", ["-C", dir, "-c", "core.hooksPath=/dev/null", "-c", "user.email=fixture@example.test", "-c", "user.name=fixture", "-c", "commit.gpgsign=false", ...args], { encoding: "utf8", env });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };
  run("init", "-q");
  return { dir, run };
}

test("the shipped self-test scenarios each run (every rejection paired with a passing control)", () => {
  assert.equal(manifest.verifyFixtures(), manifest.SCENARIOS.length);
  assert.ok(manifest.SCENARIOS.length >= 4);
});

test("--self-test exits 0 and names every scenario", () => {
  const result = spawnSync(process.execPath, [path.join(HERE, "phase254_visual_manifest.mjs"), "--self-test"], { cwd: ROOT, encoding: "utf8", env: { ...process.env, NODE_TEST_CONTEXT: "" } });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /Phase 254 visual manifest self-test: PASS/);
  for (const [name] of manifest.SCENARIOS) assert.ok(result.stdout.includes(name), name);
});

test("a changed PNG since the merge-base without current asset digests fails; with them it passes (scratch repository)", () => {
  const { dir: repo, run } = scratchRepo();
  const root = manifest.fixtureRoot();
  try {
    const shots = path.join(repo, "shots");
    fs.mkdirSync(shots);
    const key = "phase254-page-active-w1280-light";
    const file = snapshotFileName(key);
    fs.writeFileSync(path.join(shots, file), "first bytes");
    fs.writeFileSync(path.join(shots, "dashboard.png"), "legacy");
    run("add", "-A");
    run("commit", "-q", "-m", "base");
    const base = run("rev-parse", "HEAD");
    assert.deepEqual(manifest.changedPngsSince(base, "shots", { root: repo }), [], "positive control: nothing changed yet");
    fs.writeFileSync(path.join(shots, file), "second bytes");
    run("add", "-A");
    run("commit", "-q", "-m", "change");
    assert.deepEqual(manifest.changedPngsSince(base, "shots", { root: repo }), [file], "the reader finds the changed PNG");
    const bytes = "second bytes";
    const stale = manifest.mintedEntry(key, bytes, root, { mint_run_id: "" });
    const problems = manifest.checkManifest({
      dir: shots, manifest: { schema_version: 1, entries: { [key]: stale } }, versions: manifest.FIXTURE_VERSIONS, changedPngs: manifest.changedPngsSince(base, "shots", { root: repo }), root, caseKeys: [key],
    });
    assert.match(problems.join("\n"), /changed since the merge-base without a current mint run id and asset digests/);
    const fresh = manifest.checkManifest({
      dir: shots, manifest: { schema_version: 1, entries: { [key]: manifest.mintedEntry(key, bytes, root) } }, versions: manifest.FIXTURE_VERSIONS, changedPngs: manifest.changedPngsSince(base, "shots", { root: repo }), root, caseKeys: [key],
    });
    assert.deepEqual(fresh, []);
    assert.throws(() => manifest.changedPngsSince("1".repeat(40), "shots", { root: repo }), /not reachable/);
    assert.throws(() => manifest.changedPngsSince("--output=x", "shots", { root: repo }), /base must be a commit sha/);
  } finally {
    fs.rmSync(repo, { recursive: true, force: true });
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("buildManifest output satisfies the baseline set guard end to end, and a tampered PNG then fails it", () => {
  const root = manifest.fixtureRoot();
  const artifact = tmp("phase254-visual-art-");
  const identities = tmp("phase254-visual-id-");
  try {
    const keys = ["phase254-page-active-w1280-light", "phase254-page-review_cancel_now-w320-dark"];
    const previous = manifest.buildLegacyManifest({ dir: path.join(ROOT, manifest.BASELINE_DIR), root: ROOT });
    for (const name of guard.EXPECTED_BASELINES) fs.writeFileSync(path.join(artifact, name), fs.readFileSync(path.join(ROOT, manifest.BASELINE_DIR, name)));
    for (const key of keys) {
      fs.writeFileSync(path.join(artifact, snapshotFileName(key)), `bytes ${key}`);
      const current = manifest.currentAssetDigests("story", root);
      fs.writeFileSync(path.join(identities, `${key}.json`), JSON.stringify({ key, kind: "story", snapshot: snapshotFileName(key), served: current.served, scenario_file_sha256: current.scenario_file_sha256, ...manifest.FIXTURE_VERSIONS }));
    }
    const built = manifest.buildManifest({
      artifactDir: artifact, identityDir: identities, reasons: { "*": { reason: "first mint", finding_id: "CIQ-03" } }, mint: { run_id: "42", sha: "d".repeat(40) }, previous, root, caseKeys: keys,
    });
    fs.writeFileSync(path.join(artifact, "manifest.json"), JSON.stringify(built));
    assert.equal(Object.keys(built.entries).length, 14);
    for (const name of guard.EXPECTED_BASELINES) assert.equal(built.entries[name.replace(/\.png$/, "")].provenance, "phase211-committed", "unchanged legacy entries are kept verbatim");
    assert.equal(guard.checkBaselineSet(artifact, { caseKeys: keys }).ok, true);
    fs.writeFileSync(path.join(artifact, snapshotFileName(keys[0])), "tampered");
    const tampered = guard.checkBaselineSet(artifact, { caseKeys: keys });
    assert.equal(tampered.ok, false);
    assert.deepEqual(tampered.mismatched, [snapshotFileName(keys[0])]);
  } finally {
    for (const directory of [root, artifact, identities]) fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("buildManifest rejects a mint without a run id or commit sha and identity files that disagree on versions", () => {
  const root = manifest.fixtureRoot();
  const artifact = tmp("phase254-visual-art-");
  const identities = tmp("phase254-visual-id-");
  try {
    const keys = ["phase254-page-active-w1280-light", "phase254-page-active-w1280-dark"];
    keys.forEach((key, index) => {
      fs.writeFileSync(path.join(artifact, snapshotFileName(key)), `bytes ${key}`);
      const current = manifest.currentAssetDigests("story", root);
      fs.writeFileSync(path.join(identities, `${key}.json`), JSON.stringify({ key, kind: "story", snapshot: snapshotFileName(key), served: current.served, scenario_file_sha256: current.scenario_file_sha256, playwright_version: "1.0.0", browser_version: index === 0 ? "1.0.0.0" : "2.0.0.0" }));
    });
    const reasons = { "*": { reason: "r", finding_id: "CIQ-03" } };
    assert.throws(() => manifest.buildManifest({ artifactDir: artifact, identityDir: identities, reasons, mint: { run_id: "", sha: "d".repeat(40) }, root, caseKeys: keys }), /mint run id and a 40-character commit sha/);
    assert.throws(() => manifest.buildManifest({ artifactDir: artifact, identityDir: identities, reasons, mint: { run_id: "1", sha: "short" }, root, caseKeys: keys }), /mint run id and a 40-character commit sha/);
    assert.throws(() => manifest.buildManifest({ artifactDir: artifact, identityDir: identities, reasons, mint: { run_id: "1", sha: "d".repeat(40) }, root, caseKeys: keys }), /disagree about the Playwright and browser versions/);
    fs.writeFileSync(path.join(identities, `${keys[1]}.json`), fs.readFileSync(path.join(identities, `${keys[0]}.json`), "utf8").replace(keys[0], keys[1]).replace(snapshotFileName(keys[0]), snapshotFileName(keys[1])));
    assert.doesNotThrow(() => manifest.buildManifest({ artifactDir: artifact, identityDir: identities, reasons, mint: { run_id: "1", sha: "d".repeat(40) }, root, caseKeys: keys }), "positive control: agreeing versions build");
    fs.writeFileSync(path.join(artifact, "unknown-capture.png"), "x");
    assert.throws(() => manifest.buildManifest({ artifactDir: artifact, identityDir: identities, reasons, mint: { run_id: "1", sha: "d".repeat(40) }, root, caseKeys: keys }), /neither a legacy baseline nor a case key/);
  } finally {
    for (const directory of [root, artifact, identities]) fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("every Phase 211 key is either an untouched legacy entry equal to a fresh seed-legacy build or a minted entry for the committed bytes", () => {
  const dir = path.join(ROOT, manifest.BASELINE_DIR);
  const committed = JSON.parse(fs.readFileSync(path.join(dir, "manifest.json"), "utf8"));
  const legacyKeys = guard.EXPECTED_BASELINES.map((name) => name.replace(/\.png$/, ""));
  const fresh = manifest.buildLegacyManifest({ dir, root: ROOT });
  const stillLegacy = [];
  for (const key of legacyKeys) {
    const entry = committed.entries[key];
    assert.ok(entry, `${key} has a manifest entry`);
    if (entry.provenance === "phase211-committed") {
      // An untouched key: exactly what seed-legacy would write for it today.
      assert.deepEqual(entry, fresh.entries[key], key);
      stillLegacy.push(key);
    } else {
      // A rebaselined key: a minted entry (mint run id, reason, finding id) for the committed bytes.
      assert.equal(entry.provenance, "phase254-mint", key);
      assert.match(String(entry.mint_run_id), /^\d+$/, `${key}: mint run id`);
      assert.ok(entry.reason && entry.finding_id, `${key}: reason and finding id`);
      assert.equal(entry.sha256, manifest.sha256(fs.readFileSync(path.join(dir, entry.file))), `${key}: sha256 equals the committed PNG`);
    }
  }
  assert.equal(Object.keys(committed.entries).filter((key) => committed.entries[key].provenance === "phase211-committed").length, stillLegacy.length, "no legacy entry outside the 12 legacy keys");
  assert.ok(stillLegacy.length <= legacyKeys.length);
});

test("the CLI check passes on the real tree without a base and fails on an unreachable base", () => {
  const script = path.join(HERE, "phase254_visual_manifest.mjs");
  const env = { ...process.env, NODE_TEST_CONTEXT: "" };
  const ok = spawnSync(process.execPath, [script, "check"], { cwd: ROOT, encoding: "utf8", env });
  assert.equal(ok.status, 0, ok.stderr);
  assert.match(ok.stdout, /check PASS/);
  const bad = spawnSync(process.execPath, [script, "check", "--base", "1".repeat(40)], { cwd: ROOT, encoding: "utf8", env });
  assert.notEqual(bad.status, 0);
  assert.match(bad.stderr, /not reachable/);
});
