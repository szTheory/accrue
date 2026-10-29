// Phase 254 (CIQ-04): the budget verifier's scenarios are defined once in phase254_budget.mjs
// (they also back --self-test). Each registers here as a named test; the CLI cases below run
// the real verbs against a scratch directory, never the live budget.
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { SCENARIOS, TARGET_KEYS } from "./phase254_budget.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const SCRIPT = path.join(ROOT, "scripts/ci/phase254_budget.mjs");

for (const [name, scenario] of SCENARIOS) test(name, scenario);

test("the four CIQ-04 target keys are pinned", () => {
  assert.deepEqual([...TARGET_KEYS], ["warm_preview_s", "focused_check_s", "additional_warm_browser_s", "incremental_ci_critical_path_s"]);
});

function scratch(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-budget-test-"));
  try { return fn(dir); } finally { fs.rmSync(dir, { recursive: true, force: true }); }
}

function cli(args, env = {}) {
  const clean = { ...process.env };
  delete clean.CI;
  delete clean.NODE_TEST_CONTEXT;
  return spawnSync(process.execPath, [SCRIPT, ...args], { encoding: "utf8", env: { ...clean, ...env } });
}

test("--self-test exits 0 and names the hostile-title fixture", () => {
  const result = cli(["--self-test"]);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /hostile-title fixture/);
  assert.match(result.stdout, /PASS \(self-test: \d+ scenarios\)/);
});

test("restamp-manifest --check exits non-zero on a mismatch and 0 on a match; --write fixes it and refuses under CI", () => {
  scratch((dir) => {
    const manifest = path.join(dir, "manifest.json");
    const budgetFile = path.join(dir, "budget.json");
    fs.writeFileSync(manifest, '{"a":1}\n');
    fs.writeFileSync(budgetFile, JSON.stringify({ manifest_sha256: "0".repeat(64), selection: { total: 3 }, deviations: [] }));
    const args = ["restamp-manifest", "--budget", budgetFile, "--manifest", manifest];
    assert.notEqual(cli([...args, "--check"]).status, 0);
    assert.notEqual(cli([...args, "--write", "--cause", "t-1", "--block", "11-19"], { CI: "true" }).status, 0, "CI must refuse --write");
    assert.equal(JSON.parse(fs.readFileSync(budgetFile, "utf8")).manifest_sha256, "0".repeat(64));
    const written = cli([...args, "--write", "--cause", "t-1", "--block", "11-19"]);
    assert.equal(written.status, 0, written.stderr);
    assert.equal(cli([...args, "--check"]).status, 0);
    const after = JSON.parse(fs.readFileSync(budgetFile, "utf8"));
    assert.equal(after.deviations.length, 1);
    assert.equal(after.deviations[0].id, "DEV-254-11");
    assert.equal(cli([...args, "--write", "--cause", "t-1", "--block", "11-19"]).status, 0);
    assert.equal(JSON.parse(fs.readFileSync(budgetFile, "utf8")).deviations.length, 1, "a matching digest appends nothing");
  });
});

test("freeze refuses to run when CI is set and rejects an unknown option", () => {
  const refused = cli(["freeze", "--samples", "x.json", "--main-reference", "y.json"], { CI: "true" });
  assert.notEqual(refused.status, 0);
  assert.match(refused.stderr, /refuses to run when CI is set/);
  assert.notEqual(cli(["freeze", "--bogus", "1"]).status, 0);
});
