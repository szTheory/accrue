import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import * as generator from "./generate_phase253_acceptance.mjs";
import { renderAutomatedUat } from "./verify_executable_uat_contract.mjs";

const root = path.resolve(process.env.PHASE253_REPO_ROOT || path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../.."));
test("acceptance requires all five requirements, fourteen tasks, ten edges, and twenty-six UI criteria", () => {
  assert.equal(typeof generator.inspectPhase253Metadata, "function");
  const metadata = generator.inspectPhase253Metadata({ root });
  assert.equal(metadata.requirements.length, 5);
  assert.equal(metadata.tasks.length, 14);
  assert.equal(metadata.edges.length, 10);
  assert.equal(metadata.ui.length, 26);
});

test("current and historical unclassified assumptions remain unresolved", () => {
  const metadata = generator.inspectPhase253Metadata({ root });
  assert.deepEqual(metadata.current_unclassified, ["EDGE-SBK-05-unclassified", "EDGE-UXQ-01-unclassified"]);
  assert.deepEqual(metadata.historical_unclassified, [
    "EDGE-CIQ-01-unclassified",
    "EDGE-LAB-02-unclassified",
    "EDGE-SBK-03-unclassified",
    "EDGE-SCEN-01-unclassified",
  ]);
});

test("process-marker lanes retain named assertion references when TAP bindings are empty", () => {
  assert.deepEqual(generator.expectedAssertionReferences({
    assertion_bindings: {},
    process_markers: ["phase253_current_green", "phase253_clean_green"],
  }), ["phase253_current_green", "phase253_clean_green"]);
});

test("both project prohibitions require native clean and independent violation descriptors", () => {
  const metadata = generator.inspectPhase253Metadata({ root });
  assert.equal(metadata.prohibitions.length, 2);
  assert.ok(metadata.prohibitions.every((item) => item.status === "resolved" && item.verification === "test"));
  assert.ok(metadata.prohibitions.every((item) => item.check_kind === "node-test"));
  assert.ok(metadata.prohibitions.every((item) => item.check_target === "scripts/ci/verify_phase253_presentation.test.mjs"));
  assert.ok(metadata.prohibitions.every((item) => item.check_clean_fixture === "scripts/ci/fixtures/phase253-transparency/clean.json"));
  assert.equal(new Set(metadata.prohibitions.map((item) => item.check_violation_fixture)).size, 2);
});

test("latest acceptance rejects missing, stale, skipped, pooled, and unsafe runtime evidence", () => {
  assert.throws(() => generator.validatePhase253Evidence({ root, resultsPath: "accrue_admin/tmp/phase253/ci-results/missing/results.json" }), /missing|result|bundle/i);
  assert.throws(() => generator.validatePhase253Evidence({ root, resultsPath: "../outside/results.json" }), /unsafe|repository-relative|path/i);
});

test("acceptance UAT generation requires every completed summary", () => {
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "phase253-missing-summary-"));
  const phaseDir = path.join(tempRoot, ".planning", "phases", generator.PHASE_SLUG);
  fs.mkdirSync(phaseDir, { recursive: true });
  try {
    for (const plan of ["01", "02", "03", "04", "05"]) {
      const name = `253-${plan}-SUMMARY.md`;
      fs.copyFileSync(path.join(root, ".planning", "phases", generator.PHASE_SLUG, name), path.join(phaseDir, name));
    }
    assert.throws(() => generator.validateCompletedSummaries({ root: tempRoot }), /253-06-SUMMARY|summary|complete/i);
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
});

test("completed-summary dates accept the existing nested metrics completed_date field", () => {
  assert.equal(generator.completedSummaryDate("metrics:\n  duration: 33m\n  completed_date: 2026-10-27\nstatus: complete"), "2026-10-27");
  assert.equal(generator.completedSummaryDate("completed: 2026-10-27\nstatus: complete"), "2026-10-27");
});

test("generated Phase 253 UAT matches the project contract renderer once verification exists", () => {
  const sourcePhase = path.join(root, ".planning", "phases", generator.PHASE_SLUG);
  const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), "phase253-uat-contract-render-"));
  const temporaryPhase = path.join(temporaryRoot, "253-contract-fixture");
  fs.mkdirSync(temporaryPhase, { recursive: true });
  try {
    for (const { name } of generator.validateCompletedSummaries({ root }).summaries) {
      fs.copyFileSync(path.join(sourcePhase, name), path.join(temporaryPhase, name));
    }
    fs.writeFileSync(path.join(temporaryPhase, "253-VERIFICATION.md"), "---\nstatus: passed\nbehavior_unverified: 0\n---\n");
    const summarySet = generator.validateCompletedSummaries({ root });
    assert.equal(generator.renderUat(summarySet), renderAutomatedUat(temporaryPhase));
  } finally {
    fs.rmSync(temporaryRoot, { recursive: true, force: true });
  }
});

