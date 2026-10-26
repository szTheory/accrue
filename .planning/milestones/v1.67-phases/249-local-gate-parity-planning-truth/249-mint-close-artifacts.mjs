#!/usr/bin/env node
// Idempotent phase-249 close minter (plan 249-17).
//
// covered_files is DERIVED here, never typed by hand: the union of this phase
// directory's files and every path changed since the v1.67 base commit that still
// exists on disk, minus the live trackers GSD tooling rewrites after close.
// covered_digest is computed ONLY through the repository's own computeDigest, and the
// UAT is produced ONLY through generateAutomatedUat. Re-running is a fixed point.

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { pathToFileURL } from "node:url";

const BASE_COMMIT = "713d8569";
const PHASE_SLUG = "249-local-gate-parity-planning-truth";

function git(repo, args) {
  const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", maxBuffer: 200_000_000 });
  if (result.status !== 0) throw new Error(`git ${args.join(" ")} failed: ${result.stderr}`);
  return result.stdout;
}

const repo = git(process.cwd(), ["rev-parse", "--show-toplevel"]).trim();
const phaseRel = `.planning/phases/${PHASE_SLUG}`;
const phaseDir = path.join(repo, phaseRel);
const verificationRel = `${phaseRel}/249-VERIFICATION.md`;
const verificationPath = path.join(repo, verificationRel);

const fixedPoint = await import(pathToFileURL(path.join(repo, "scripts/ci/verify_artifact_fixed_point.mjs")).href);
const uatContract = await import(pathToFileURL(path.join(repo, "scripts/ci/verify_executable_uat_contract.mjs")).href);

const EXCLUDED = new Set([
  ".planning/STATE.md",
  ".planning/ROADMAP.md",
  ".planning/REQUIREMENTS.md",
  verificationRel
]);

// 1. Generated UAT first (it reads the SUMMARY coverage and the VERIFICATION status).
uatContract.generateAutomatedUat(phaseDir);

// 2. Derive covered_files.
const lines = (text) => text.split("\n").map((l) => l.trim()).filter(Boolean);
const phaseTracked = lines(git(repo, ["ls-files", "--", phaseRel]));
const phaseUntracked = lines(git(repo, ["ls-files", "--others", "--exclude-standard", "--", phaseRel]));
const changed = lines(git(repo, ["diff", "--name-only", `${BASE_COMMIT}..HEAD`]));
const covered = [...new Set([...phaseTracked, ...phaseUntracked, ...changed])]
  .filter((rel) => !EXCLUDED.has(rel))
  .filter((rel) => fs.existsSync(path.join(repo, rel)) && fs.statSync(path.join(repo, rel)).isFile())
  .sort();
for (const rel of covered) {
  if (/["'\n]/.test(rel)) throw new Error(`unsupported character in covered path: ${rel}`);
}
if (covered.length === 0) throw new Error("no covered files derived");

// 3. Write covered_files into the frontmatter, then read back through scanArtifact.
let source = fs.readFileSync(verificationPath, "utf8");
const listBlock = `covered_files:\n${covered.map((rel) => `  - "${rel}"`).join("\n")}\n`;
if (!/^covered_files:\n(?:  - .*\n)*/m.test(source)) throw new Error("covered_files block not found");
source = source.replace(/^covered_files:\n(?:  - .*\n)*/m, () => listBlock);
fs.writeFileSync(verificationPath, source);

const scanned = fixedPoint.scanArtifact(verificationRel, fs.readFileSync(verificationPath, "utf8"));
if (JSON.stringify(scanned.coveredFiles) !== JSON.stringify(covered)) {
  throw new Error("scanArtifact round trip of covered_files does not match the derived list");
}

// 4. Digest through the repository's own function; 5. assert stability.
const digest = fixedPoint.computeDigest(repo, scanned.coveredFiles);
const again = fixedPoint.computeDigest(repo, scanned.coveredFiles);
if (digest !== again) throw new Error("computeDigest is not stable across two calls");

source = fs.readFileSync(verificationPath, "utf8");
if (!/^covered_digest: .*$/m.test(source)) throw new Error("covered_digest line not found");
source = source.replace(/^covered_digest: .*$/m, () => `covered_digest: "${digest}"`);
fs.writeFileSync(verificationPath, source);

const finalScan = fixedPoint.scanArtifact(verificationRel, fs.readFileSync(verificationPath, "utf8"));
if (finalScan.coveredDigest !== digest) throw new Error("covered_digest round trip failed");
console.log(`249-mint-close-artifacts: ${covered.length} covered files, ${digest}`);
