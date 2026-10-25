#!/usr/bin/env node

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

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

function archiveAwareVerificationRef(ref, phaseDir) {
  const normalizedDirectory = phaseDir.split(path.sep).join("/");
  const planningIndex = normalizedDirectory.lastIndexOf("/.planning/");
  if (planningIndex === -1) return ref;
  const root = normalizedDirectory.slice(0, planningIndex);
  return ref.replace(/\.planning\/phases\/(\d+-[a-z0-9]+(?:-[a-z0-9]+)*)/g, (original, phaseName) => {
    try {
      return path.relative(root, resolvePhaseDir(root, phaseName)).split(path.sep).join("/");
    } catch {
      return original;
    }
  });
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

// SL-G (quick task 260917-l7v): started:/updated: used to be sourced from
// VERIFICATION.md's `verified:` field -- but VERIFICATION.md's own
// `covered_digest` covers this generated UAT artifact, so that was a
// DERIVES-then-COVERS cycle: every verifier run bumps `verified:`, which
// rewrites the UAT, which re-stales the digest, which requires another
// verifier run. Source the timestamps from the phase's own SUMMARY
// `completed:` dates instead -- those are written once when a plan finishes
// and do not change on a later verification re-run, so regenerating this
// artifact is a fixed point (see scripts/ci/verify_artifact_fixed_point.mjs).
// `completed:` lives at the frontmatter top level in some phases' SUMMARY
// convention and nested under `metrics:` in others (e.g. phase 229) -- match
// at any indentation rather than assuming one schema.
function anyIndentScalar(metadata, key) {
  const match = metadata.match(new RegExp(`^\\s*${key}:\\s*["']?([^\\n"']+)["']?\\s*$`, "m"));
  return match?.[1]?.trim();
}

function summaryTimestamps(phaseDir, entries) {
  const files = [...new Set(entries.map(({ file }) => file))].sort();
  const dates = files.map((file) => {
    const source = fs.readFileSync(path.join(phaseDir, file), "utf8");
    const metadata = frontmatter(source, file);
    const completed = anyIndentScalar(metadata, "completed");
    if (!completed) {
      fail(`${file}: completed date is required for deterministic UAT derivation (SUMMARY dates are outside VERIFICATION's covered set; verified: is not)`);
    }
    return completed;
  });
  dates.sort();
  return { started: dates[0], updated: dates[dates.length - 1] };
}

export function renderAutomatedUat(phaseDir) {
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
  const { started, updated } = summaryTimestamps(phaseDir, entries);
  const phase = path.basename(phaseDir).match(/^(\d+(?:\.\d+)?)/)?.[1];
  if (!phase) fail(`${phaseDir}: cannot derive phase number`);

  const tests = entries.map(({ file, entry }, index) => {
    const id = entryScalar(entry, "id") || `coverage-${index + 1}`;
    const description = entryScalar(entry, "description") || `${file} ${id}`;
    const refs = entryRefs(entry).map((ref) => archiveAwareVerificationRef(ref, phaseDir));
    if (refs.length === 0) fail(`${file} coverage ${id}: missing verification ref`);
    const statuses = [...entry.matchAll(/\n\s+status:\s*([^\s#]+)/g)].map(
      (match) => match[1]
    );
    const result = statuses.length > 0 && statuses.every((status) => status === "pass")
      ? "pass"
      : "issue";
    return `### ${index + 1}. ${description}\nsource: automated\nverification: ${refs.join(" | ")}\nresult: [${result}]`;
  });

  return `---\nstatus: complete\nphase: ${phase}\nsource: executable-summary-coverage\nstarted: ${started}\nupdated: ${updated}\n---\n\n# Phase ${phase} Automated UAT\n\nEvery acceptance item below is produced from committed executable coverage. No post-hoc human verification is required.\n\n## Tests\n\n${tests.join("\n\n")}\n\n## Summary\n\ntotal: ${tests.length}\npassed: ${tests.filter((test) => /result: \[pass\]/.test(test)).length}\nissues: ${tests.filter((test) => /result: \[issue\]/.test(test)).length}\npending: 0\nskipped: 0\nblocked: 0\n`;
}

export function generateAutomatedUat(phaseDir) {
  const output = renderAutomatedUat(phaseDir);
  const phase = path.basename(phaseDir).match(/^(\d+(?:\.\d+)?)/)?.[1];
  const destination = path.join(phaseDir, `${phase}-UAT.md`);
  fs.writeFileSync(destination, output);
  return destination;
}

// -- recorded historical deviations (A3) --------------------------------------
//
// v1.66 phases (245-248) predate adoption of the executable-UAT contract and
// were archived with honest human-judgment / coverage-less / UAT-less evidence.
// Editing those archived files would falsify their covered_digest fingerprints,
// so each measured deviation is recorded here instead. An entry names exactly one
// artifact and pins its sha256: byte drift, a stale entry (no longer observed),
// an active-phase path, or an unlisted offender all fail. No ranges, no globs.
export const DEVIATION_KINDS = Object.freeze([
  "human_judgment_true",
  "coverage_missing",
  "summary_frontmatter_missing",
  "uat_missing"
]);

function deviationKey(kind, relPath, id) {
  return `${kind}\u0000${relPath}\u0000${id ?? ""}`;
}

function loadDeviations(list) {
  const seen = new Set();
  for (const entry of list) {
    if (!DEVIATION_KINDS.includes(entry.kind)) fail(`recorded deviation: unknown kind ${JSON.stringify(entry.kind)}`);
    if (typeof entry.path !== "string" || !entry.path.startsWith(".planning/milestones/") || entry.path.split("/").includes("..")) {
      fail(`recorded deviation ${entry.path}: only archived paths under .planning/milestones/ are admitted`);
    }
    if (!/^[0-9a-f]{64}$/.test(entry.sha256 ?? "")) fail(`recorded deviation ${entry.path}: sha256 pin is required`);
    if (typeof entry.reason !== "string" || entry.reason.trim() === "") fail(`recorded deviation ${entry.path}: a reason is required`);
    if (entry.kind === "human_judgment_true" && !entry.id) fail(`recorded deviation ${entry.path}: human_judgment_true needs an entry id`);
    const key = deviationKey(entry.kind, entry.path, entry.id);
    if (seen.has(key)) fail(`recorded deviation ${entry.path}: duplicate entry`);
    seen.add(key);
  }
  return list;
}

const OWNER_CAUSE =
  "owner: Accrue maintainer; cause: v1.66 phases predate adoption of the executable-UAT contract and editing the archived file would falsify the archived v3 covered_digest; release impact: none, acceptance is recorded in the sha-pinned VERIFICATION";

export const RECORDED_DEVIATIONS = Object.freeze(loadDeviations([
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/245-rendered-baseline-and-realistic-preview/245-02-SUMMARY.md", id: "D2", sha256: "dddb49a4a0577aa1145db1cd249029ce9cfbd05194f79f2be29a9aa880efc961", reason: OWNER_CAUSE },
  { kind: "uat_missing", path: ".planning/milestones/v1.66-phases/245-rendered-baseline-and-realistic-preview/245-VERIFICATION.md", sha256: "3b7300392f21c98cca582c3528d76962d28e9b46619e622932db982e59207ba8", reason: OWNER_CAUSE },
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/246-collection-controls-and-search/246-04-SUMMARY.md", id: "D3", sha256: "734794940a0ef51524889825c275c2b2fc2264e9d97e6e5b986113c2652c5cee", reason: OWNER_CAUSE },
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/246-collection-controls-and-search/246-05-SUMMARY.md", id: "D2", sha256: "47cdb63e93113532fa892b091be8d23abc8847d529c28774ff99f37b836b1972", reason: OWNER_CAUSE },
  { kind: "summary_frontmatter_missing", path: ".planning/milestones/v1.66-phases/246-collection-controls-and-search/246-IDENTITY-GAP-SUMMARY.md", sha256: "6339556b227a392b1a30e2a1f9d4ec69d05319c9eec506c89c481baa221240d0", reason: OWNER_CAUSE },
  { kind: "uat_missing", path: ".planning/milestones/v1.66-phases/246-collection-controls-and-search/246-VERIFICATION.md", sha256: "17429373516100dee91cc7b0957a8b084da28268ae386286b12b6cb977b8e46a", reason: OWNER_CAUSE },
  { kind: "coverage_missing", path: ".planning/milestones/v1.66-phases/247-evidence-true-details-and-analytics/247-02-SUMMARY.md", sha256: "c30821ddaeed103ab3906a0bcc366d55a98afd91c0479e14ab03e9051bb0e7e9", reason: OWNER_CAUSE },
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/247-evidence-true-details-and-analytics/247-03-SUMMARY.md", id: "D1", sha256: "bf483b29ec91dde4d6e7b20ffbd8e68b287a51fe277e82353f2829169ae9c948", reason: OWNER_CAUSE },
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/247-evidence-true-details-and-analytics/247-03-SUMMARY.md", id: "D2", sha256: "bf483b29ec91dde4d6e7b20ffbd8e68b287a51fe277e82353f2829169ae9c948", reason: OWNER_CAUSE },
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/247-evidence-true-details-and-analytics/247-03-SUMMARY.md", id: "D3", sha256: "bf483b29ec91dde4d6e7b20ffbd8e68b287a51fe277e82353f2829169ae9c948", reason: OWNER_CAUSE },
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/247-evidence-true-details-and-analytics/247-04-SUMMARY.md", id: "D1", sha256: "86bc14f3a3b3e9cfce9bf3374e032e45c607a72d04bf805912c7be30f69e471b", reason: OWNER_CAUSE },
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/247-evidence-true-details-and-analytics/247-04-SUMMARY.md", id: "D2", sha256: "86bc14f3a3b3e9cfce9bf3374e032e45c607a72d04bf805912c7be30f69e471b", reason: OWNER_CAUSE },
  { kind: "coverage_missing", path: ".planning/milestones/v1.66-phases/247-evidence-true-details-and-analytics/247-05-SUMMARY.md", sha256: "ca10904c319cfb650e24f15c033f7a687100d50815cf51c4515cfdbf66cffe5a", reason: OWNER_CAUSE },
  { kind: "coverage_missing", path: ".planning/milestones/v1.66-phases/247-evidence-true-details-and-analytics/247-06-SUMMARY.md", sha256: "9b52e1bc918fa2ee61b020316c82bfa088d0fcb02fe945ae3e820533c7fe8f17", reason: OWNER_CAUSE },
  { kind: "uat_missing", path: ".planning/milestones/v1.66-phases/247-evidence-true-details-and-analytics/247-VERIFICATION.md", sha256: "f926cfc5ead1e9782bbe1f2935c46f88b2d94596a0b4df49dedd358529416de7", reason: OWNER_CAUSE },
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/248-reproducible-scenarios-and-integrated-proof/248-01-SUMMARY.md", id: "D2", sha256: "0862ddfe59dfabac316028cf2e5aa0fe840815f5b33007bf35313bd61ffcd10b", reason: OWNER_CAUSE },
  { kind: "human_judgment_true", path: ".planning/milestones/v1.66-phases/248-reproducible-scenarios-and-integrated-proof/248-02-SUMMARY.md", id: "D2", sha256: "1b5762ba1f9f90b786ef886141b33e0a64e4cfe96d70fec6dcf6d522c4beaaf2", reason: OWNER_CAUSE },
  { kind: "uat_missing", path: ".planning/milestones/v1.66-phases/248-reproducible-scenarios-and-integrated-proof/248-VERIFICATION.md", sha256: "9c6132b2b7c67fe36d41dcb0194c83705b4fa1bfb99aa05f404bddf80723c3de", reason: OWNER_CAUSE }
]));

function repoRootOf(phaseDir) {
  const marker = `${path.sep}.planning${path.sep}`;
  const index = phaseDir.indexOf(marker);
  return index === -1 ? undefined : phaseDir.slice(0, index);
}

function makeWaiver(phaseDir, deviations) {
  const root = repoRootOf(phaseDir);
  const observed = new Set();
  const byKey = new Map(deviations.map((entry) => [deviationKey(entry.kind, entry.path, entry.id), entry]));
  function waive(kind, absPath, id) {
    if (!root) return false;
    const rel = path.relative(root, absPath).split(path.sep).join("/");
    const entry = byKey.get(deviationKey(kind, rel, id));
    if (!entry) return false;
    const actual = crypto.createHash("sha256").update(fs.readFileSync(absPath)).digest("hex");
    if (actual !== entry.sha256) fail(`${rel}: recorded deviation sha256 mismatch (pinned ${entry.sha256}, found ${actual})`);
    observed.add(deviationKey(kind, rel, id));
    return true;
  }
  function assertNoStale() {
    if (!root) return;
    const prefix = phaseDir + path.sep;
    for (const entry of deviations) {
      if (!path.resolve(root, entry.path).startsWith(prefix)) continue;
      if (!observed.has(deviationKey(entry.kind, entry.path, entry.id))) {
        fail(`${entry.path}: stale recorded deviation ${entry.kind}${entry.id ? ` ${entry.id}` : ""} is no longer observed; remove it`);
      }
    }
  }
  return { waive, assertNoStale };
}

export function validatePhaseDirectory(phaseDir, deviations = RECORDED_DEVIATIONS) {
  loadDeviations(deviations);
  const { waive, assertNoStale } = makeWaiver(phaseDir, deviations);
  const files = fs.readdirSync(phaseDir).sort();
  const summaries = files.filter((file) => /-SUMMARY\.md$/.test(file));
  if (summaries.length === 0) fail(`${phaseDir}: no SUMMARY files found`);

  for (const file of summaries) {
    const summaryPath = path.join(phaseDir, file);
    const source = fs.readFileSync(summaryPath, "utf8");
    let metadata;
    try {
      metadata = frontmatter(source, file);
    } catch (error) {
      if (waive("summary_frontmatter_missing", summaryPath)) continue;
      throw error;
    }
    if (scalar(metadata, "status") !== "complete") continue;

    let entries = [];
    let coverage;
    try {
      coverage = coverageBlock(metadata, file);
      entries = coverage.split(/\n(?=  - id:)/).filter((entry) => /- id:/.test(entry));
    } catch (error) {
      if (waive("coverage_missing", summaryPath)) continue;
      throw error;
    }
    if (entries.length === 0) {
      if (waive("coverage_missing", summaryPath)) continue;
      fail(`${file}: coverage has no executable entries`);
    }

    for (const entry of entries) {
      const id = entry.match(/- id:\s*([^\n]+)/)?.[1]?.trim() || "unknown";
      if (!/\n\s+human_judgment:\s*false\s*(?:\n|$)/.test(`\n${entry}`)) {
        if (!waive("human_judgment_true", summaryPath, id)) fail(`${file} coverage ${id}: human_judgment must be false`);
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

  const verificationFile = files.find((file) => /-VERIFICATION\.md$/.test(file));
  const uatFile = files.find((file) => /-UAT\.md$/.test(file));
  let uatTests = 0;
  if (!uatFile) {
    // Only a recorded, sha-pinned deviation pinned to this phase's VERIFICATION may waive the UAT.
    const waived = verificationFile && waive("uat_missing", path.join(phaseDir, verificationFile));
    if (!waived) fail(`${phaseDir}: missing automated UAT artifact`);
  } else {
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
    uatTests = tests.length;
  }

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

  assertNoStale();
  return { summaries: summaries.length, uatTests };
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
  const matches = phaseDirectoriesSince(root, 0)
    .filter((directory) => {
      const name = path.basename(directory);
      return name === phase || name.startsWith(`${phase}-`);
    })
    .filter((directory) => fs.readdirSync(directory).some((file) => /-SUMMARY\.md$/.test(file)));
  const activeRoot = path.join(root, ".planning", "phases") + path.sep;
  const active = matches.filter((directory) => directory.startsWith(activeRoot));
  if (active.length === 1) return active[0];
  if (active.length > 1) fail(`phase ${phase}: expected one active directory, found ${active.length}`);
  if (matches.length !== 1) fail(`phase ${phase}: expected one active or archived directory, found ${matches.length}`);
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
    const summary = `---\nstatus: complete\ncompleted: 2026-08-03\ncoverage:\n  - id: D1\n    verification:\n      - kind: integration\n        ref: "mix test"\n        status: pass\n    human_judgment: false\n---\n`;
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
      path.join(phaseTemp, "218-01-SUMMARY.md"),
      summary.replace("completed: 2026-08-03\n", "")
    );
    rejected = false;
    try {
      generateAutomatedUat(phaseTemp);
    } catch (error) {
      rejected = /completed date is required/.test(error.message);
    }
    if (!rejected) fail("self-test: missing SUMMARY completed date was not rejected");
    fs.writeFileSync(path.join(phaseTemp, "218-01-SUMMARY.md"), summary);

    // SL-G: regenerating the UAT is a byte-level no-op -- started:/updated:
    // come from the SUMMARY's own completed: date, which does not change when
    // VERIFICATION.md is re-verified (bumping a later verified: value must
    // not perturb the UAT this generates).
    generateAutomatedUat(phaseTemp);
    const beforeRewrite = fs.readFileSync(uatFile, "utf8");
    fs.writeFileSync(
      path.join(phaseTemp, "218-VERIFICATION.md"),
      verification.replace("verified: 2026-08-03T00:00:00Z", "verified: 2026-08-04T12:00:00Z")
    );
    generateAutomatedUat(phaseTemp);
    const afterRewrite = fs.readFileSync(uatFile, "utf8");
    assert.equal(afterRewrite, beforeRewrite, "self-test: re-verifying (bumping verified:) must not change the generated UAT");
    fs.writeFileSync(path.join(phaseTemp, "218-VERIFICATION.md"), verification);

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

    const activePlaceholder = path.join(temp, ".planning", "phases", "228-test");
    const archivedPhase = path.join(temp, ".planning", "milestones", "v9.99-phases", "228-test");
    fs.mkdirSync(activePlaceholder, { recursive: true });
    fs.mkdirSync(archivedPhase, { recursive: true });
    fs.writeFileSync(path.join(archivedPhase, "228-01-SUMMARY.md"), summary);
    assert.equal(resolvePhaseDir(temp, "228"), archivedPhase, "an empty active placeholder must not hide archived phase evidence");

    // A3: recorded, sha256-pinned deviations for archived phases.
    const sha = (file) => crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
    const devRoot = path.join(temp, "dev");
    const devPhase = path.join(devRoot, ".planning", "milestones", "v9.99-phases", "250-dev");
    const devRel = (name) => `.planning/milestones/v9.99-phases/250-dev/${name}`;
    const judged = summary.replace("human_judgment: false", "human_judgment: true");
    const writeDev = (summaryText, withUat) => {
      fs.rmSync(devPhase, { recursive: true, force: true });
      fs.mkdirSync(devPhase, { recursive: true });
      fs.writeFileSync(path.join(devPhase, "250-01-SUMMARY.md"), summaryText);
      fs.writeFileSync(path.join(devPhase, "250-VERIFICATION.md"), verification);
      if (withUat) generateAutomatedUat(devPhase);
    };
    const entry = (kind, name, extra = {}) => ({ kind, path: devRel(name), sha256: sha(path.join(devPhase, name)), reason: "owner: test; cause: fixture; release impact: none", ...extra });
    const expectFail = (label, pattern, run) => {
      let message = "";
      try { run(); } catch (error) { message = error.message; }
      if (!pattern.test(message)) fail(`self-test: ${label} was not rejected (got: ${message || "no error"})`);
    };

    writeDev(judged, true);
    const listedJudged = [entry("human_judgment_true", "250-01-SUMMARY.md", { id: "D1" })];
    expectFail("unlisted human_judgment: true", /human_judgment must be false/, () => validatePhaseDirectory(devPhase, []));
    // positive control: the exact listed deviation is honored
    assert.doesNotThrow(() => validatePhaseDirectory(devPhase, listedJudged));
    // a different entry id is not covered by the D1 entry
    expectFail("wrong entry id", /human_judgment must be false/, () => validatePhaseDirectory(devPhase, [entry("human_judgment_true", "250-01-SUMMARY.md", { id: "D9" })]));

    // uat_missing listed: honored, VERIFICATION checks still run
    writeDev(summary, false);
    const listedUat = [entry("uat_missing", "250-VERIFICATION.md")];
    expectFail("unlisted uat_missing", /missing automated UAT artifact/, () => validatePhaseDirectory(devPhase, []));
    assert.deepEqual(validatePhaseDirectory(devPhase, listedUat), { summaries: 1, uatTests: 0 });
    // sha mismatch (byte drift) fails
    fs.writeFileSync(path.join(devPhase, "250-VERIFICATION.md"), `${verification}\n<!-- drift -->\n`);
    expectFail("sha256 byte drift", /sha256 mismatch/, () => validatePhaseDirectory(devPhase, listedUat));
    // waiver does not skip the VERIFICATION checks
    const humanNeeded = verification.replace("status: passed", "status: human_needed");
    fs.writeFileSync(path.join(devPhase, "250-VERIFICATION.md"), humanNeeded);
    expectFail("uat_missing waiver hiding a human_needed VERIFICATION", /status must be passed/, () => validatePhaseDirectory(devPhase, [entry("uat_missing", "250-VERIFICATION.md")]));
    // stale: a UAT now exists, so the uat_missing entry is no longer observed
    writeDev(summary, true);
    expectFail("stale uat_missing entry", /stale recorded deviation/, () => validatePhaseDirectory(devPhase, [entry("uat_missing", "250-VERIFICATION.md")]));
    // stale: flipped to false
    writeDev(summary, true);
    expectFail("stale human_judgment_true entry", /stale recorded deviation/, () => validatePhaseDirectory(devPhase, [entry("human_judgment_true", "250-01-SUMMARY.md", { id: "D1" })]));
    // coverage_missing / summary_frontmatter_missing are honored only when listed
    writeDev("---\nstatus: complete\ncompleted: 2026-08-03\n---\n", false);
    expectFail("unlisted coverage_missing", /missing coverage/, () => validatePhaseDirectory(devPhase, []));
    writeDev("no frontmatter here\n", false);
    expectFail("unlisted summary_frontmatter_missing", /missing YAML frontmatter/, () => validatePhaseDirectory(devPhase, []));

    // load-time rejections
    const base = { kind: "uat_missing", path: devRel("250-VERIFICATION.md"), sha256: "a".repeat(64), reason: "r" };
    expectFail("active-phase path", /only archived paths/, () => loadDeviations([{ ...base, path: ".planning/phases/250-dev/250-VERIFICATION.md" }])); // archive-sweep-exempt: synthetic negative-control path, not a live read
    expectFail("path traversal", /only archived paths/, () => loadDeviations([{ ...base, path: ".planning/milestones/../phases/x" }]));
    expectFail("empty reason", /a reason is required/, () => loadDeviations([{ ...base, reason: " " }]));
    expectFail("unknown kind", /unknown kind/, () => loadDeviations([{ ...base, kind: "everything" }]));
    expectFail("missing sha256 pin", /sha256 pin is required/, () => loadDeviations([{ ...base, sha256: "" }]));
    expectFail("human_judgment_true without id", /needs an entry id/, () => loadDeviations([{ ...base, kind: "human_judgment_true" }]));
    expectFail("duplicate entry", /duplicate entry/, () => loadDeviations([base, base]));
    // the committed list is itself valid and fully archived
    assert.ok(RECORDED_DEVIATIONS.length > 0 && RECORDED_DEVIATIONS.every((e) => e.path.startsWith(".planning/milestones/")));
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

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  test("executable UAT contract self-test runs clean", () => selfTest());
} else if (invokedAsEntrypoint) {
  try {
    main();
  } catch (error) {
    console.error(`executable UAT contract: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
