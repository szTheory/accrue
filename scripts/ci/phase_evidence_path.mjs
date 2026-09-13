#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

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

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [phaseSlug, artifactPath] = process.argv.slice(2);
  try {
    process.stdout.write(`${repositoryRelativePhaseEvidencePath(phaseSlug, artifactPath)}\n`);
  } catch (error) {
    console.error(`resolve phase evidence: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
