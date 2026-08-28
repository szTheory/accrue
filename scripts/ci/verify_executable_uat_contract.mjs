#!/usr/bin/env node

import assert from "node:assert/strict";
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

function coverageEntries(phaseDir) {
  return fs
    .readdirSync(phaseDir)
    .filter((file) => /-SUMMARY\.md$/.test(file))
    .sort()
    .flatMap((file) => {
      const source = fs.readFileSync(path.join(phaseDir, file), "utf8");
      const metadata = frontmatter(source, file);
      if (scalar(metadata, "status") !== "complete") {
        fail(`${file}: every in-scope SUMMARY must have status: complete`);
      }

      const coverage = coverageBlock(metadata, file);
      return coverage
        .split(/\n(?=  - id:)/)
        .filter((entry) => /- id:/.test(entry))
        .map((entry) => ({ file, entry }));
    });
}

function unquote(value) {
  const trimmed = value.trim();
  if (
    trimmed.length >= 2 &&
    ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'")))
  ) {
    return trimmed.slice(1, -1);
  }
  return trimmed;
}

function entryScalar(entry, key) {
  const match = entry.match(new RegExp(`^\\s+${key}:\\s*(.+)$`, "m"));
  return match ? unquote(match[1]) : undefined;
}

function entryRefs(entry) {
  return entry
    .split("\n")
    .filter((line) => /^\s+ref:\s*/.test(line))
    .map((line) => unquote(line.replace(/^\s+ref:\s*/, "")));
}

function hasUnresolvedHumanVerification(verification) {
  return (
    /^\s*why_human:\s*\S/im.test(verification) ||
    /^\s*status:\s*human_needed\s*$/im.test(verification)
  );
}

function isBackendZeroHumanPlan(source) {
  if (!source.includes("automation_contract: backend-zero-human")) return false;
  return /^automation_contract:\s*backend-zero-human\s*$/m.test(frontmatter(source, "PLAN.md"));
}

export function validateBackendZeroHumanPlan(source, file = "PLAN.md") {
  if (!isBackendZeroHumanPlan(source)) return false;
  if (/type="tracer"/.test(source)) fail(`${file}: backend-zero-human plans cannot use tracer tasks`);
  if (/type="checkpoint:[^"]+"/.test(source)) fail(`${file}: backend-zero-human plans cannot use checkpoint tasks`);
  if (/<human-check>|why_human:|human_verification:/i.test(source)) fail(`${file}: backend-zero-human plan contains human verification`);
  const tasks = source.split(/(?=<task\s)/).slice(1);
  if (tasks.length === 0) fail(`${file}: backend-zero-human plan has no tasks`);
  for (const [index, task] of tasks.entries()) {
    if (!/<automated>\S[\s\S]*?<\/automated>/.test(task)) {
      fail(`${file}: task ${index + 1} is missing an automated verify command`);
    }
  }
  return true;
}

function renderAutomatedUat(phaseDir) {
  const entries = coverageEntries(phaseDir);
  if (entries.length === 0) fail(`${phaseDir}: no executable coverage to generate UAT`);

  const verificationFile = fs
    .readdirSync(phaseDir)
    .find((file) => /-VERIFICATION\.md$/.test(file));
  if (!verificationFile) fail(`${phaseDir}: missing VERIFICATION artifact`);
  const verification = fs.readFileSync(path.join(phaseDir, verificationFile), "utf8");
  const verificationMetadata = frontmatter(verification, verificationFile);
  if (scalar(verificationMetadata, "status") !== "passed") {
    fail(`${verificationFile}: status must be passed before automated UAT generation`);
  }
  if (scalar(verificationMetadata, "behavior_unverified") !== "0") {
    fail(`${verificationFile}: behavior_unverified must be 0 before automated UAT generation`);
  }
  const verifiedAt = scalar(verificationMetadata, "verified");
  if (!verifiedAt) fail(`${verificationFile}: verified timestamp is required for deterministic UAT`);
  const phase = path.basename(phaseDir).match(/^(\d+(?:\.\d+)?)/)?.[1];
  if (!phase) fail(`${phaseDir}: cannot derive phase number`);

  const tests = entries.map(({ file, entry }, index) => {
    const id = entryScalar(entry, "id") || `coverage-${index + 1}`;
    const description = entryScalar(entry, "description") || `${file} ${id}`;
    const refs = entryRefs(entry);
    if (refs.length === 0) fail(`${file} coverage ${id}: missing verification ref`);
    const statuses = [...entry.matchAll(/\n\s+status:\s*([^\s#]+)/g)].map(
      (match) => match[1]
    );
    const result = statuses.length > 0 && statuses.every((status) => status === "pass")
      ? "pass"
      : "issue";
    return `### ${index + 1}. ${description}\nsource: automated\nverification: ${refs.join(" | ")}\nresult: [${result}]`;
  });

  return `---\nstatus: complete\nphase: ${phase}\nsource: executable-summary-coverage\nstarted: ${verifiedAt}\nupdated: ${verifiedAt}\n---\n\n# Phase ${phase} Automated UAT\n\nEvery acceptance item below is produced from committed executable coverage. No post-hoc human verification is required.\n\n## Tests\n\n${tests.join("\n\n")}\n\n## Summary\n\ntotal: ${tests.length}\npassed: ${tests.filter((test) => /result: \[pass\]/.test(test)).length}\nissues: ${tests.filter((test) => /result: \[issue\]/.test(test)).length}\npending: 0\nskipped: 0\nblocked: 0\n`;
}

export function generateAutomatedUat(phaseDir) {
  const output = renderAutomatedUat(phaseDir);
  const phase = path.basename(phaseDir).match(/^(\d+(?:\.\d+)?)/)?.[1];
  const destination = path.join(phaseDir, `${phase}-UAT.md`);
  fs.writeFileSync(destination, output);
  return destination;
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

  const expectedUat = renderAutomatedUat(phaseDir);
  if (uat !== expectedUat) {
    fail(`${uatFile}: content does not exactly match executable SUMMARY coverage; regenerate with --write`);
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
  if (hasUnresolvedHumanVerification(verification)) {
    fail(`${verificationFile}: human verification language remains`);
  }

  return { summaries: summaries.length, uatTests: tests.length };
}

function phaseAutomationState(phaseDir) {
  const files = fs.readdirSync(phaseDir).sort();
  const plans = files.filter((file) => /-PLAN\.md$/.test(file));
  const optedPlans = plans.filter((file) => validateBackendZeroHumanPlan(fs.readFileSync(path.join(phaseDir, file), "utf8"), file));
  if (optedPlans.length === 0) return { opted: false };
  const summaries = files.filter((file) => /-SUMMARY\.md$/.test(file));
  const verificationFile = files.find((file) => /-VERIFICATION\.md$/.test(file));
  const complete = plans.length > 0 && summaries.length === plans.length && Boolean(verificationFile);
  if (complete) {
    const verification = fs.readFileSync(path.join(phaseDir, verificationFile), "utf8");
    const phaseNumber = phaseNumberFromDirectory(phaseDir);
    if (phaseNumber >= 228 && /^#{1,6}\s+.*human verification/im.test(verification)) {
      fail(`${verificationFile}: backend-zero-human verification must not contain a human-verification section`);
    }
  }
  return { opted: true, complete, plans: plans.length, optedPlans: optedPlans.length };
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

function phaseNumberFromDirectory(directory) {
  const match = path.basename(directory).match(/^(\d+(?:\.\d+)?)(?:-|$)/);
  return match ? Number(match[1]) : undefined;
}

function phaseDirectoriesSince(root, since) {
  const directories = [];
  const activeRoot = path.join(root, ".planning", "phases");
  if (fs.existsSync(activeRoot)) {
    for (const entry of fs.readdirSync(activeRoot, { withFileTypes: true })) {
      if (entry.isDirectory()) directories.push(path.join(activeRoot, entry.name));
    }
  }

  const milestonesRoot = path.join(root, ".planning", "milestones");
  if (fs.existsSync(milestonesRoot)) {
    for (const collection of fs.readdirSync(milestonesRoot, { withFileTypes: true })) {
      if (!collection.isDirectory() || !/-phases$/.test(collection.name)) continue;
      const collectionPath = path.join(milestonesRoot, collection.name);
      for (const entry of fs.readdirSync(collectionPath, { withFileTypes: true })) {
        if (entry.isDirectory()) directories.push(path.join(collectionPath, entry.name));
      }
    }
  }

  return directories
    .filter((directory) => {
      const phase = phaseNumberFromDirectory(directory);
      return phase !== undefined && phase >= since;
    })
    .sort((left, right) => phaseNumberFromDirectory(left) - phaseNumberFromDirectory(right));
}

function validateAllSince(root, since, write) {
  const phaseDirs = phaseDirectoriesSince(root, since).filter((directory) =>
    fs.readdirSync(directory).some((file) => /-SUMMARY\.md$/.test(file))
  );
  if (phaseDirs.length === 0) fail(`no executed phase directories found at or after ${since}`);

  let summaries = 0;
  let uatTests = 0;
  for (const phaseDir of phaseDirs) {
    if (write) generateAutomatedUat(phaseDir);
    const result = validatePhaseDirectory(phaseDir);
    summaries += result.summaries;
    uatTests += result.uatTests;
  }
  return { phases: phaseDirs.length, summaries, uatTests };
}

function validateAllOptedIn(root, write) {
  const phaseDirs = phaseDirectoriesSince(root, 0);
  let optedPhases = 0;
  let completedPhases = 0;
  let summaries = 0;
  let uatTests = 0;
  for (const phaseDir of phaseDirs) {
    const state = phaseAutomationState(phaseDir);
    if (!state.opted) continue;
    optedPhases += 1;
    if (phaseNumberFromDirectory(phaseDir) < 228) continue;
    if (!state.complete) continue;
    if (write) generateAutomatedUat(phaseDir);
    const result = validatePhaseDirectory(phaseDir);
    completedPhases += 1;
    summaries += result.summaries;
    uatTests += result.uatTests;
  }
  if (optedPhases === 0) fail("no backend-zero-human phases found");
  return { optedPhases, completedPhases, summaries, uatTests };
}

function currentPhase(root) {
  const state = fs.readFileSync(path.join(root, ".planning", "STATE.md"), "utf8");
  const phase = scalar(frontmatter(state, ".planning/STATE.md"), "current_phase");
  if (!phase) fail(".planning/STATE.md: current_phase is missing");
  return phase;
}

function selfTest() {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-executable-uat-"));
  const phaseTemp = path.join(temp, "218-test");
  try {
    fs.mkdirSync(phaseTemp);
    const summary = `---\nstatus: complete\ncoverage:\n  - id: D1\n    verification:\n      - kind: integration\n        ref: "mix test"\n        status: pass\n    human_judgment: false\n---\n`;
    const verification = `---\nstatus: passed\nbehavior_unverified: 0\nverified: 2026-08-03T00:00:00Z\n---\n`;
    fs.writeFileSync(path.join(phaseTemp, "218-01-SUMMARY.md"), summary);
    fs.writeFileSync(path.join(phaseTemp, "218-VERIFICATION.md"), verification);
    generateAutomatedUat(phaseTemp);
    validatePhaseDirectory(phaseTemp);

    fs.writeFileSync(
      path.join(phaseTemp, "218-VERIFICATION.md"),
      `${verification}\n### Human Verification Required\n\nNone. No human verification required.\n`
    );
    validatePhaseDirectory(phaseTemp);

    fs.writeFileSync(
      path.join(phaseTemp, "218-VERIFICATION.md"),
      `${verification}\nwhy_human: visual approval remains\n`
    );
    let rejected = false;
    try {
      validatePhaseDirectory(phaseTemp);
    } catch (error) {
      rejected = /human verification language remains/.test(error.message);
    }
    if (!rejected) fail("self-test: unresolved human verification was not rejected");

    fs.writeFileSync(path.join(phaseTemp, "218-VERIFICATION.md"), verification);

    const uatFile = path.join(phaseTemp, "218-UAT.md");
    const uat = fs.readFileSync(uatFile, "utf8");
    fs.writeFileSync(uatFile, uat.replace("[pass]", "[pending]"));
    rejected = false;
    try {
      validatePhaseDirectory(phaseTemp);
    } catch (error) {
      rejected = /unresolved UAT result/.test(error.message);
    }
    if (!rejected) fail("self-test: pending UAT was not rejected");

    generateAutomatedUat(phaseTemp);
    const generated = fs.readFileSync(uatFile, "utf8");
    fs.writeFileSync(uatFile, generated.replace("verification: mix test", "verification: echo fake"));
    rejected = false;
    try {
      validatePhaseDirectory(phaseTemp);
    } catch (error) {
      rejected = /does not exactly match executable SUMMARY coverage/.test(error.message);
    }
    if (!rejected) fail("self-test: hand-authored UAT evidence was not rejected");

    generateAutomatedUat(phaseTemp);
    fs.writeFileSync(
      path.join(phaseTemp, "218-02-SUMMARY.md"),
      summary.replace("status: complete", "status: incomplete")
    );
    rejected = false;
    try {
      validatePhaseDirectory(phaseTemp);
    } catch (error) {
      rejected = /every in-scope SUMMARY must have status: complete/.test(error.message);
    }
    if (!rejected) fail("self-test: incomplete SUMMARY was not rejected");

    fs.rmSync(path.join(phaseTemp, "218-02-SUMMARY.md"));
    fs.writeFileSync(
      path.join(phaseTemp, "218-VERIFICATION.md"),
      verification.replace("verified: 2026-08-03T00:00:00Z\n", "")
    );
    rejected = false;
    try {
      generateAutomatedUat(phaseTemp);
    } catch (error) {
      rejected = /verified timestamp is required/.test(error.message);
    }
    if (!rejected) fail("self-test: nondeterministic UAT timestamp fallback was not rejected");

    const automatedPlan = `---\nautomation_contract: backend-zero-human\n---\n<tasks>\n<task type="auto"><verify><automated>mix test</automated></verify></task>\n</tasks>\n`;
    assert.equal(validateBackendZeroHumanPlan(automatedPlan), true);
    for (const [mutation, pattern] of [
      [automatedPlan.replace('type="auto"', 'type="checkpoint:human-verify"'), /checkpoint tasks/],
      [automatedPlan.replace('type="auto"', 'type="tracer"'), /tracer tasks/],
      [automatedPlan.replace("<automated>mix test</automated>", "<human-check>approve</human-check>"), /human verification/],
      [automatedPlan.replace("<automated>mix test</automated>", "<manual>approve</manual>"), /automated verify/],
    ]) {
      assert.throws(() => validateBackendZeroHumanPlan(mutation), pattern);
    }
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
  console.log("executable UAT contract self-test: PASS");
}

function main() {
  const args = process.argv.slice(2);
  if (args.includes("--self-test")) return selfTest();

  const phaseIndex = args.indexOf("--phase");
  const allSinceIndex = args.indexOf("--all-since");
  const allOptedIn = args.includes("--all-opted-in");
  const write = args.includes("--write");
  const root = process.env.ROOT_DIR || process.cwd();
  if (allOptedIn) {
    const result = validateAllOptedIn(root, write);
    console.log(
      `executable UAT contract: PASS (${result.optedPhases} opted-in phases, ${result.completedPhases} complete, ${result.summaries} summaries, ${result.uatTests} automated UAT tests)`
    );
    return;
  }
  if (allSinceIndex !== -1) {
    const since = Number(args[allSinceIndex + 1]);
    if (!Number.isFinite(since)) fail("--all-since requires a numeric phase");
    const result = validateAllSince(root, since, write);
    console.log(
      `executable UAT contract: PASS (${result.phases} phases since ${since}, ${result.summaries} summaries, ${result.uatTests} automated UAT tests)`
    );
    return;
  }
  const phase = phaseIndex === -1 ? currentPhase(root) : args[phaseIndex + 1];
  if (!phase) fail("--phase requires a value");

  const phaseDir = resolvePhaseDir(root, phase);
  if (write) generateAutomatedUat(phaseDir);
  const result = validatePhaseDirectory(phaseDir);
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
