import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { repositoryRelativePhaseEvidencePath, resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";

const phase = "999-archive-path-contract";
const artifact = "fixtures/contract.json";

function withRoot(run) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-phase-evidence-"));
  try {
    run(root);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function writeArtifact(root, relativePath) {
  const target = path.join(root, relativePath);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, "{}\n");
  return target;
}

test("prefers a substantive active phase artifact", () => withRoot((root) => {
  const active = writeArtifact(root, `.planning/phases/${phase}/${artifact}`);
  writeArtifact(root, `.planning/milestones/v9.98-phases/${phase}/${artifact}`);
  assert.equal(resolvePhaseEvidencePath(phase, artifact, { root }), active);
  assert.equal(repositoryRelativePhaseEvidencePath(phase, artifact, { root }), `.planning/phases/${phase}/${artifact}`);
}));

test("falls back to one archived artifact and ignores an empty active placeholder", () => withRoot((root) => {
  fs.mkdirSync(path.join(root, ".planning", "phases", phase), { recursive: true });
  const archived = writeArtifact(root, `.planning/milestones/v9.99-phases/${phase}/${artifact}`);
  assert.equal(resolvePhaseEvidencePath(phase, artifact, { root }), archived);
  assert.equal(repositoryRelativePhaseEvidencePath(phase, artifact, { root }), `.planning/milestones/v9.99-phases/${phase}/${artifact}`);
}));

test("fails closed when archived evidence is missing or ambiguous", () => withRoot((root) => {
  assert.throws(() => resolvePhaseEvidencePath(phase, artifact, { root }), /missing phase evidence/);
  writeArtifact(root, `.planning/milestones/v9.97-phases/${phase}/${artifact}`);
  writeArtifact(root, `.planning/milestones/v9.98-phases/${phase}/${artifact}`);
  assert.throws(() => resolvePhaseEvidencePath(phase, artifact, { root }), /ambiguous archived phase evidence/);
}));

test("rejects traversal and malformed phase identifiers", () => withRoot((root) => {
  assert.throws(() => resolvePhaseEvidencePath("../phase", artifact, { root }), /phase slug/);
  assert.throws(() => resolvePhaseEvidencePath(phase, "../secret", { root }), /artifact path/);
  assert.throws(() => resolvePhaseEvidencePath(phase, "/tmp/secret", { root }), /artifact path/);
}));
