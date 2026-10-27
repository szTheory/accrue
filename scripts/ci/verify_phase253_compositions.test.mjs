import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(process.env.PHASE253_REPO_ROOT || path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../.."));
const runnerPath = path.join(root, "scripts/ci/verify_phase253_compositions.mjs");

test("focused Phase 253 composition runner exposes its bounded serial acceptance plan", async () => {
  let runner;
  try {
    runner = await import(pathToFileURL(runnerPath));
  } catch {
    assert.fail("focused Phase 253 composition runner must exist and load");
  }

  assert.equal(typeof runner.buildCommandPlan, "function");
  assert.equal(typeof runner.validateLaneEvidence, "function");
  assert.equal(typeof runner.executeCommandSequence, "function");
});
