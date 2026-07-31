#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

function fail(message) {
  throw new Error(message);
}

function frontmatter(source, file) {
  const match = source.match(/^---\n([\s\S]*?)\n---(?:\n|$)/);
  if (!match) fail(`${file}: missing YAML frontmatter`);
  return match[1];
}

function scalar(source, key) {
  const match = source.match(new RegExp(`^${key}:\\s*["']?([^\\n"']+)["']?\\s*$`, "m"));
  return match?.[1]?.trim();
}

function coverageBlock(metadata, file) {
  const lines = metadata.split("\n");
  const start = lines.findIndex((line) => line === "coverage:");
  if (start === -1) fail(`${file}: complete SUMMARY is missing coverage:`);

  const block = [];
  for (const line of lines.slice(start + 1)) {
    if (/^[A-Za-z0-9_-]+:/.test(line)) break;
    block.push(line);
  }
  return block.join("\n");
}

export function validatePhaseDirectory(phaseDir) {
  const files = fs.readdirSync(phaseDir).sort();
  const summaries = files.filter((file) => /-SUMMARY\.md$/.test(file));
  if (summaries.length === 0) fail(`${phaseDir}: no SUMMARY files found`);

  for (const file of summaries) {
    const source = fs.readFileSync(path.join(phaseDir, file), "utf8");
    const metadata = frontmatter(source, file);
    if (scalar(metadata, "status") !== "complete") continue;

    const coverage = coverageBlock(metadata, file);
    const entries = coverage.split(/\n(?=  - id:)/).filter((entry) => /- id:/.test(entry));
    if (entries.length === 0) fail(`${file}: coverage has no executable entries`);

    for (const entry of entries) {
      const id = entry.match(/- id:\s*([^\n]+)/)?.[1]?.trim() || "unknown";
      if (!/\n\s+human_judgment:\s*false\s*(?:\n|$)/.test(`\n${entry}`)) {
        fail(`${file} coverage ${id}: human_judgment must be false`);
      }
      if (!/\n\s+ref:\s*["']?\S/.test(`\n${entry}`)) {
        fail(`${file} coverage ${id}: missing verification ref`);
      }
      const statuses = [...entry.matchAll(/\n\s+status:\s*([^\s#]+)/g)].map((match) => match[1]);
      if (statuses.length === 0 || statuses.some((status) => status !== "pass")) {
        fail(`${file} coverage ${id}: every verification status must be pass`);
      }
    }
  }

  const uatFile = files.find((file) => /-UAT\.md$/.test(file));
  if (!uatFile) fail(`${phaseDir}: missing automated UAT artifact`);
  const uat = fs.readFileSync(path.join(phaseDir, uatFile), "utf8");
  const uatMetadata = frontmatter(uat, uatFile);
  if (scalar(uatMetadata, "status") !== "complete") fail(`${uatFile}: status must be complete`);
  if (/result:\s*\[(pending|blocked|skipped|issue)\]/i.test(uat)) {
    fail(`${uatFile}: unresolved UAT result`);
  }

  const tests = uat.split(/\n(?=### \d+\.)/).slice(1);
  if (tests.length === 0) fail(`${uatFile}: no UAT tests found`);
  for (const test of tests) {
    const name = test.match(/^###\s+([^\n]+)/)?.[1] || "unknown";
    if (!/^source:\s*automated\s*$/m.test(test)) fail(`${uatFile} ${name}: source must be automated`);
    if (!/^result:\s*\[pass\]\s*$/m.test(test)) fail(`${uatFile} ${name}: result must be [pass]`);
    if (!/^verification:\s*\S.+$/m.test(test)) fail(`${uatFile} ${name}: verification evidence is required`);
  }

  const verificationFile = files.find((file) => /-VERIFICATION\.md$/.test(file));
  if (!verificationFile) fail(`${phaseDir}: missing VERIFICATION artifact`);
  const verification = fs.readFileSync(path.join(phaseDir, verificationFile), "utf8");
  const verificationMetadata = frontmatter(verification, verificationFile);
  if (scalar(verificationMetadata, "status") !== "passed") {
    fail(`${verificationFile}: status must be passed`);
  }
  if (scalar(verificationMetadata, "behavior_unverified") !== "0") {
    fail(`${verificationFile}: behavior_unverified must be 0`);
  }
  if (/why_human:|human verification required/i.test(verification)) {
    fail(`${verificationFile}: human verification language remains`);
  }

  return { summaries: summaries.length, uatTests: tests.length };
}

function resolvePhaseDir(root, phase) {
  const phasesRoot = path.join(root, ".planning", "phases");
  const matches = fs
    .readdirSync(phasesRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && (entry.name === phase || entry.name.startsWith(`${phase}-`)))
    .map((entry) => path.join(phasesRoot, entry.name));
  if (matches.length !== 1) fail(`phase ${phase}: expected one active directory, found ${matches.length}`);
  return matches[0];
}

function currentPhase(root) {
  const state = fs.readFileSync(path.join(root, ".planning", "STATE.md"), "utf8");
  const phase = scalar(frontmatter(state, ".planning/STATE.md"), "current_phase");
  if (!phase) fail(".planning/STATE.md: current_phase is missing");
  return phase;
}

function selfTest() {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-executable-uat-"));
  try {
    const summary = `---\nstatus: complete\ncoverage:\n  - id: D1\n    verification:\n      - kind: integration\n        ref: "mix test"\n        status: pass\n    human_judgment: false\n---\n`;
    const uat = `---\nstatus: complete\n---\n\n## Tests\n\n### 1. Automated proof\nsource: automated\nverification: mix test\nresult: [pass]\n`;
    const verification = `---\nstatus: passed\nbehavior_unverified: 0\n---\n`;
    fs.writeFileSync(path.join(temp, "1-SUMMARY.md"), summary);
    fs.writeFileSync(path.join(temp, "1-UAT.md"), uat);
    fs.writeFileSync(path.join(temp, "1-VERIFICATION.md"), verification);
    validatePhaseDirectory(temp);

    fs.writeFileSync(path.join(temp, "1-UAT.md"), uat.replace("[pass]", "[pending]"));
    let rejected = false;
    try {
      validatePhaseDirectory(temp);
    } catch (error) {
      rejected = /unresolved UAT result/.test(error.message);
    }
    if (!rejected) fail("self-test: pending UAT was not rejected");
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
  console.log("executable UAT contract self-test: PASS");
}

function main() {
  const args = process.argv.slice(2);
  if (args.includes("--self-test")) return selfTest();

  const phaseIndex = args.indexOf("--phase");
  const root = process.env.ROOT_DIR || process.cwd();
  const phase = phaseIndex === -1 ? currentPhase(root) : args[phaseIndex + 1];
  if (!phase) fail("--phase requires a value");

  const result = validatePhaseDirectory(resolvePhaseDir(root, phase));
  console.log(
    `executable UAT contract: PASS (phase ${phase}, ${result.summaries} summaries, ${result.uatTests} automated UAT tests)`
  );
}

try {
  main();
} catch (error) {
  console.error(`executable UAT contract: FAIL: ${error.message}`);
  process.exitCode = 1;
}
