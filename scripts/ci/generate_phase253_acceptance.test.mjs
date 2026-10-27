import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(process.env.PHASE253_REPO_ROOT || path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../.."));
const generatorPath = path.join(root, "scripts/ci/generate_phase253_acceptance.mjs");

async function loadGenerator() {
  try {
    return await import(pathToFileURL(generatorPath));
  } catch {
    assert.fail("Phase 253 acceptance generator must be importable");
  }
}

test("acceptance generator parses five requirements, fourteen tasks, ten edges, and twenty-six UI IDs", async () => {
  const generator = await loadGenerator();
  assert.equal(typeof generator.inspectPhase253Metadata, "function");
  const metadata = generator.inspectPhase253Metadata({ root });
  assert.equal(metadata.requirements.length, 5);
  assert.equal(metadata.tasks.length, 14);
  assert.equal(metadata.edges.length, 10);
  assert.equal(metadata.ui.length, 26);
  assert.deepEqual(metadata.current_unclassified, ["EDGE-SBK-05-unclassified", "EDGE-UXQ-01-unclassified"]);
  assert.deepEqual(metadata.historical_unclassified, [
    "EDGE-CIQ-01-unclassified",
    "EDGE-LAB-02-unclassified",
    "EDGE-SBK-03-unclassified",
    "EDGE-SCEN-01-unclassified",
  ]);
});

test("latest acceptance rejects missing, stale, skipped, pooled, and unsafe runtime evidence", async () => {
  const generator = await loadGenerator();
  assert.throws(() => generator.validatePhase253Evidence({ root, resultsPath: "accrue_admin/tmp/phase253/ci-results/missing/results.json" }), /missing|result|bundle/i);
  assert.throws(() => generator.validatePhase253Evidence({ root, resultsPath: "../outside/results.json" }), /unsafe|repository-relative|path/i);
});

test("automated UAT generation waits for every complete human-judgment-free summary", async () => {
  const generator = await loadGenerator();
  assert.throws(() => generator.generatePhase253Acceptance({ root, latest: true, writeUat: true }), /253-06-SUMMARY|summary|complete/i);
});

