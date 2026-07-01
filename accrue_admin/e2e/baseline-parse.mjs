import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");

function resolvePhaseDir() {
  const candidates = [
    ".planning/phases/187-audit-baseline",
    ".planning/milestones/v1.53-phases/187-audit-baseline",
  ];

  for (const candidate of candidates) {
    const absolute = path.join(repoRoot, candidate);
    if (fs.existsSync(absolute)) return absolute;
  }

  return path.join(repoRoot, candidates[0]);
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

const phaseDir = resolvePhaseDir();

readJson(path.join(phaseDir, "baseline.cells.json"));

const defects = fs.readFileSync(path.join(phaseDir, "defects.ndjson"), "utf8").split(/\r?\n/).filter(Boolean);
for (const line of defects) JSON.parse(line);

readJson(path.join(phaseDir, "artifacts.manifest.json"));

console.log("baseline artifacts parse ok");
