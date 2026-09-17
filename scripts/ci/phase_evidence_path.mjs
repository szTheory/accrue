#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { isMainModule } from "./main_module.mjs";

export const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

function validatePhaseSlug(phaseSlug) {
  if (typeof phaseSlug !== "string" || !/^\d+-[a-z0-9]+(?:-[a-z0-9]+)*$/.test(phaseSlug)) {
    throw new Error("phase slug must be a numeric, lowercase kebab-case directory name");
  }
}

function validateArtifactPath(artifactPath) {
  if (typeof artifactPath !== "string" || artifactPath.length === 0 || path.isAbsolute(artifactPath)) {
    throw new Error("artifact path must be a nonempty repository-relative path");
  }
  const segments = artifactPath.split(/[\\/]/);
  if (segments.some((segment) => segment === "" || segment === "." || segment === "..")) {
    throw new Error("artifact path must not contain empty, current-directory, or parent-directory segments");
  }
}

export function resolvePhaseEvidencePath(phaseSlug, artifactPath, { root = repositoryRoot } = {}) {
  validatePhaseSlug(phaseSlug);
  validateArtifactPath(artifactPath);

  const active = path.join(root, ".planning", "phases", phaseSlug, artifactPath);
  if (fs.existsSync(active)) return active;

  const milestonesRoot = path.join(root, ".planning", "milestones");
  const matches = fs.existsSync(milestonesRoot)
    ? fs.readdirSync(milestonesRoot, { withFileTypes: true })
      .filter((entry) => entry.isDirectory() && entry.name.endsWith("-phases"))
      .map((entry) => path.join(milestonesRoot, entry.name, phaseSlug, artifactPath))
      .filter((candidate) => fs.existsSync(candidate))
      .sort()
    : [];

  if (matches.length === 0) throw new Error(`missing phase evidence: ${phaseSlug}/${artifactPath}`);
  if (matches.length > 1) throw new Error(`ambiguous archived phase evidence: ${phaseSlug}/${artifactPath}`);
  return matches[0];
}

export function repositoryRelativePhaseEvidencePath(phaseSlug, artifactPath, options) {
  const root = options?.root || repositoryRoot;
  return path.relative(root, resolvePhaseEvidencePath(phaseSlug, artifactPath, options)).split(path.sep).join("/");
}

function main() {
  const [phaseSlug, artifactPath] = process.argv.slice(2);
  try {
    process.stdout.write(`${repositoryRelativePhaseEvidencePath(phaseSlug, artifactPath)}\n`);
  } catch (error) {
    console.error(`resolve phase evidence: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}

// D-29: isMainModule() throws (never returns a silent false) when there is
// no invoking entrypoint; caught here and treated as "not the entrypoint"
// so a bare import stays side-effect-free (established pattern, 232-01).
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  test("resolvePhaseEvidencePath resolves an active-phase artifact and rejects an unsafe artifact path", () => {
    const temp = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "gsd-phase-evidence-path-"));
    try {
      const phaseDir = path.join(temp, ".planning", "phases", "999-fixture-phase");
      fs.mkdirSync(phaseDir, { recursive: true });
      fs.writeFileSync(path.join(phaseDir, "evidence.json"), "{}");
      const resolved = resolvePhaseEvidencePath("999-fixture-phase", "evidence.json", { root: temp });
      assert.equal(resolved, path.join(phaseDir, "evidence.json"));
      assert.equal(repositoryRelativePhaseEvidencePath("999-fixture-phase", "evidence.json", { root: temp }), ".planning/phases/999-fixture-phase/evidence.json"); // archive-sweep-exempt: synthetic fixture phase created under a temp root by this test, never a live repository read
      assert.throws(() => resolvePhaseEvidencePath("999-fixture-phase", "../escape.json", { root: temp }), /must not contain/);
      assert.throws(() => resolvePhaseEvidencePath("999-fixture-phase", "missing.json", { root: temp }), /missing phase evidence/);
    } finally {
      fs.rmSync(temp, { recursive: true, force: true });
    }
  });
} else if (invokedAsEntrypoint) {
  main();
}
