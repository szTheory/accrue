#!/usr/bin/env node
//
// SL-E (quick task 260917-l7v): a requirement marked Complete must carry
// verification and coverage evidence AT BRANCH TIP.
//
// WHAT THIS CATCHES AND WHAT IT DOES NOT. During phase 232,
// `.planning/REQUIREMENTS.md` marked REL-04 `Complete` in commit `32e4c1cf`
// (titled "docs(232-10): complete plan") roughly eight hours BEFORE the
// deliverable it asserts existed. The tempting framing is "a completion mark
// must not precede its deliverable" -- but that is a TEMPORAL property, and CI
// only ever observes the branch tip, so a mark set early and backfilled later
// in the same PR legitimately passes here. Do NOT "fix" that by adding a
// `git log -S` archaeology check: it would be slow, history-shape-dependent,
// and wrong after any rebase, and it would be asserting something CI is not in
// a position to know. What this gate enforces is the STATE invariant that was
// ALSO violated at that moment and IS checkable at tip: a requirement marked
// Complete must have a passing phase VERIFICATION.md and at least one artifact
// in that phase citing its requirement ID.
//
// There is deliberately NO allowlist in this file. An allowlist here would
// recreate the exact "complete because we said so" failure the gate exists to
// stop. If a genuinely complete requirement goes red because its evidence is
// merely unindexed, FIX THE INDEX -- cite the requirement ID in that phase's
// UAT or SUMMARY.
//
// Checks:
//   --require-completion-evidence : every Complete requirement resolves to a
//                                   phase directory containing a
//                                   `*-VERIFICATION.md` with front-matter
//                                   `status: passed` AND at least one
//                                   `*-UAT.md` / `*-SUMMARY.md` citing its ID.
//   --require-table-agreement     : the checkbox list and the traceability
//                                   table agree in BOTH directions; any orphan
//                                   on either side, or a disagreeing pair,
//                                   fails naming both sides.
// Always on (anti-vacuity, per this repo's convention): zero parsed
// requirements fails; a traceability table that parses data rows but zero
// Complete rows fails loudly naming the parsed count (that is the shape a
// renamed or reshaped header produces); an empty phases corpus fails.

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

const fail = (message) => { throw new Error(`completion evidence: FAIL: ${message}`); };

const REQUIREMENT_ID = "[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-\\d+";
const BULLET_PATTERN = new RegExp(`^\\s*-\\s+\\[( |x|X)\\]\\s+\\*\\*(${REQUIREMENT_ID})\\*\\*`);
const FUTURE_BULLET_PATTERN = new RegExp(`^\\s*-\\s+(?:\\[( |x|X)\\]\\s+)?\\*\\*(${REQUIREMENT_ID})\\*\\*`);
const TABLE_HEADER_PATTERN = /^\|\s*requirement\s*\|\s*phase\s*\|\s*status\s*\|\s*$/i;
const TABLE_DIVIDER_PATTERN = /^\|[\s:|-]+\|$/;
const FUTURE_SECTION_PATTERN = /^##\s+Future Requirements\s*$/i;
const SECTION_PATTERN = /^##\s+\S/;
const FRONT_MATTER_STATUS_PATTERN = /^status:\s*(\S+)\s*$/m;

// -- parsing ---------------------------------------------------------------

// Returns { bullets, rows, futureSkipped, tableDataRows, tableHeaderFound }.
// `bullets` and `rows` are Maps keyed by requirement id, so an orphan on
// either side is a plain set difference rather than a text scan.
export function parseRequirements(text) {
  if (typeof text !== "string" || !text.trim()) fail("requirements file is empty");
  const lines = text.split("\n");
  const bullets = new Map();
  const rows = new Map();
  let futureSkipped = 0;
  let inFuture = false;
  let inTable = false;
  let tableHeaderFound = false;
  let tableDataRows = 0;

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];

    if (SECTION_PATTERN.test(line)) inFuture = FUTURE_SECTION_PATTERN.test(line);

    if (TABLE_HEADER_PATTERN.test(line.trim())) { tableHeaderFound = true; inTable = true; continue; }
    if (inTable) {
      const trimmed = line.trim();
      if (TABLE_DIVIDER_PATTERN.test(trimmed)) continue;
      if (!trimmed.startsWith("|")) { inTable = false; }
      else {
        const cells = trimmed.slice(1, -1).split("|").map((cell) => cell.trim());
        if (cells.length >= 3) {
          tableDataRows += 1;
          const id = cells[0];
          if (new RegExp(`^${REQUIREMENT_ID}$`).test(id)) {
            if (rows.has(id)) fail(`traceability table lists ${id} more than once (line ${index + 1})`);
            rows.set(id, { id, phase: cells[1], status: cells[2], line: index + 1 });
          }
        }
        continue;
      }
    }

    if (inFuture) {
      if (FUTURE_BULLET_PATTERN.test(line)) futureSkipped += 1;
      continue;
    }

    const bullet = BULLET_PATTERN.exec(line);
    if (bullet) {
      const id = bullet[2];
      if (bullets.has(id)) fail(`requirement bullet ${id} appears more than once (line ${index + 1})`);
      bullets.set(id, { id, checked: bullet[1].toLowerCase() === "x", line: index + 1 });
    }
  }

  return { bullets, rows, futureSkipped, tableDataRows, tableHeaderFound };
}

// -- anti-vacuity ----------------------------------------------------------

// The failure shape this exists to stop: a renamed or reshaped traceability
// header means ZERO Complete rows parse, and a naive implementation then
// reports "all 0 Complete requirements are evidenced: PASS". Both the
// zero-parsed case and the rows-but-no-Complete case fail loudly, naming the
// counts, so the miss is legible instead of green.
export function assertParseNonVacuity(parsed) {
  const parsedCount = new Set([...parsed.bullets.keys(), ...parsed.rows.keys()]).size;
  if (parsedCount === 0) {
    fail(`zero requirements parsed (bullets: ${parsed.bullets.size}, table rows: ${parsed.rows.size}, table header found: ${parsed.tableHeaderFound}) -- refusing to report a pass over zero inspected requirements`);
  }
  const complete = [...parsed.rows.values()].filter((row) => isComplete(row.status));
  if (parsed.tableDataRows > 0 && complete.length === 0 && parsed.rows.size === 0) {
    fail(`the traceability table has ${parsed.tableDataRows} data rows but ZERO parsed as requirements -- the header or row shape changed; refusing to pass vacuously`);
  }
  return parsedCount;
}

export function isComplete(status) {
  return typeof status === "string" && status.trim().toLowerCase() === "complete";
}

// -- bidirectional agreement ----------------------------------------------

export function assertTableAgreement(parsed) {
  for (const row of parsed.rows.values()) {
    if (!isComplete(row.status)) continue;
    if (!parsed.bullets.has(row.id)) {
      fail(`orphaned traceability row: ${row.id} is marked Complete on line ${row.line} but has no requirement bullet`);
    }
  }
  for (const bullet of parsed.bullets.values()) {
    const row = parsed.rows.get(bullet.id);
    if (bullet.checked && !row) {
      fail(`orphaned requirement bullet: ${bullet.id} is checked "- [x]" on line ${bullet.line} but has no traceability row`);
    }
    if (bullet.checked && row && !isComplete(row.status)) {
      fail(`disagreement for ${bullet.id}: bullet on line ${bullet.line} is "- [x]" but traceability row on line ${row.line} says "${row.status}"`);
    }
    if (!bullet.checked && row && isComplete(row.status)) {
      fail(`disagreement for ${bullet.id}: bullet on line ${bullet.line} is "- [ ]" but traceability row on line ${row.line} says "Complete"`);
    }
  }
}

// -- evidence resolution ---------------------------------------------------

function listDirs(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).filter((entry) => entry.isDirectory()).map((entry) => entry.name);
}

// Resolves an active phase directory first, then falls back to the milestone
// archives. This repo archives every milestone's phase directories into
// `.planning/milestones/`, so an archived milestone's requirements must not
// become unverifiable merely because the directory moved (the same constraint
// the SL-C census records).
export function resolvePhaseDirectory(repo, phaseNumber) {
  const active = path.join(repo, ".planning", "phases");
  const match = listDirs(active).find((name) => name.startsWith(`${phaseNumber}-`));
  if (match) return path.join(active, match);
  const milestones = path.join(repo, ".planning", "milestones");
  for (const archive of listDirs(milestones)) {
    const archiveDir = path.join(milestones, archive);
    const archived = listDirs(archiveDir).find((name) => name.startsWith(`${phaseNumber}-`));
    if (archived) return path.join(archiveDir, archived);
  }
  return null;
}

function frontMatterStatus(filePath) {
  const text = fs.readFileSync(filePath, "utf8");
  if (!text.startsWith("---")) return null;
  const end = text.indexOf("\n---", 3);
  const block = end === -1 ? text : text.slice(0, end);
  const match = FRONT_MATTER_STATUS_PATTERN.exec(block);
  return match ? match[1] : null;
}

export function assertCompletionEvidence(repo, parsed) {
  const phasesRoot = path.join(repo, ".planning", "phases");
  const milestonesRoot = path.join(repo, ".planning", "milestones");
  if (listDirs(phasesRoot).length === 0 && listDirs(milestonesRoot).length === 0) {
    fail("no phase directories exist under .planning/phases or .planning/milestones -- refusing to report an evidence pass over an empty corpus");
  }

  const complete = [...parsed.rows.values()].filter((row) => isComplete(row.status));
  if (complete.length === 0) {
    fail(`zero Complete requirements parsed from the traceability table (${parsed.tableDataRows} data rows seen) -- refusing to pass vacuously`);
  }

  let verified = 0;
  for (const row of complete) {
    const phaseNumber = (/(\d+)/.exec(row.phase) || [])[1];
    if (!phaseNumber) fail(`${row.id} is marked Complete but its Phase cell "${row.phase}" contains no phase number`);
    const dir = resolvePhaseDirectory(repo, phaseNumber);
    if (!dir) {
      fail(`${row.id} is marked Complete but no phase directory for phase ${phaseNumber} exists under .planning/phases or .planning/milestones/*/`);
    }
    const entries = fs.readdirSync(dir);
    const verifications = entries.filter((name) => name.endsWith("-VERIFICATION.md"));
    if (verifications.length === 0) {
      fail(`${row.id} is marked Complete but no *-VERIFICATION.md exists in ${path.relative(repo, dir)}`);
    }
    const statuses = verifications.map((name) => frontMatterStatus(path.join(dir, name)));
    if (!statuses.some((status) => status === "passed")) {
      fail(`${row.id} is marked Complete but the verification in ${path.relative(repo, dir)} carries status "${statuses.join(", ") || "none"}" rather than passed`);
    }
    const citing = entries.filter((name) => name.endsWith("-UAT.md") || name.endsWith("-SUMMARY.md"))
      .filter((name) => fs.readFileSync(path.join(dir, name), "utf8").includes(row.id));
    if (citing.length === 0) {
      fail(`${row.id} is marked Complete but its ID appears in no *-UAT.md or *-SUMMARY.md in ${path.relative(repo, dir)}`);
    }
    verified += 1;
  }
  return verified;
}

// -- entrypoint ------------------------------------------------------------

export function verifyCompletionEvidence(repo, requirementsPath, { requireCompletionEvidence = false, requireTableAgreement = false } = {}) {
  if (!fs.existsSync(requirementsPath)) fail(`requirements file does not exist: ${requirementsPath}`);
  const parsed = parseRequirements(fs.readFileSync(requirementsPath, "utf8"));
  const parsedCount = assertParseNonVacuity(parsed);
  if (requireTableAgreement) assertTableAgreement(parsed);
  const completeCount = [...parsed.rows.values()].filter((row) => isComplete(row.status)).length;
  const verified = requireCompletionEvidence ? assertCompletionEvidence(repo, parsed) : 0;
  return { parsed: parsedCount, complete: completeCount, verified, futureSkipped: parsed.futureSkipped };
}

// -- fixtures --------------------------------------------------------------

function withScratch(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "gsd-completion-evidence-"));
  try { return fn(dir); } finally { fs.rmSync(dir, { recursive: true, force: true }); }
}

function seed(dir, { requirements, phases = {} }) {
  fs.mkdirSync(path.join(dir, ".planning", "phases"), { recursive: true });
  fs.writeFileSync(path.join(dir, ".planning", "REQUIREMENTS.md"), requirements);
  for (const [phaseDir, files] of Object.entries(phases)) {
    const target = path.join(dir, ".planning", "phases", phaseDir);
    fs.mkdirSync(target, { recursive: true });
    for (const [name, content] of Object.entries(files)) fs.writeFileSync(path.join(target, name), content);
  }
  return path.join(dir, ".planning", "REQUIREMENTS.md");
}

const PASSING_VERIFICATION = "---\nstatus: passed\n---\n\n# Verification\n";
const FAILING_VERIFICATION = "---\nstatus: blocked\n---\n\n# Verification\n";

function requirementsDoc({ bulletState = "x", rowStatus = "Complete", id = "ZZZ-01", phase = "Phase 999", extraRows = "", extraBullets = "" } = {}) {
  return [
    "# Requirements",
    "",
    "## v1.99 Requirements",
    "",
    bulletState === null ? "" : `- [${bulletState}] **${id}**: a fixture requirement.`,
    extraBullets,
    "",
    "## Traceability",
    "",
    "| Requirement | Phase | Status |",
    "|-------------|-------|--------|",
    rowStatus === null ? "" : `| ${id} | ${phase} | ${rowStatus} |`,
    extraRows,
    ""
  ].filter((line) => line !== "").join("\n") + "\n";
}

function scenarioCompleteWithoutVerificationFile() {
  withScratch((dir) => {
    const req = seed(dir, { requirements: requirementsDoc(), phases: { "999-fixture": { "999-UAT.md": "covers ZZZ-01\n" } } });
    assert.throws(
      () => verifyCompletionEvidence(dir, req, { requireCompletionEvidence: true }),
      /ZZZ-01 is marked Complete but no \*-VERIFICATION\.md exists in \.planning\/phases\/999-fixture/
    );
  });
}

function scenarioCompleteWithNonPassingVerification() {
  withScratch((dir) => {
    const req = seed(dir, {
      requirements: requirementsDoc(),
      phases: { "999-fixture": { "999-VERIFICATION.md": FAILING_VERIFICATION, "999-UAT.md": "covers ZZZ-01\n" } }
    });
    assert.throws(
      () => verifyCompletionEvidence(dir, req, { requireCompletionEvidence: true }),
      /carries status "blocked" rather than passed/
    );
  });
}

function scenarioCompleteWithNoCitingArtifact() {
  withScratch((dir) => {
    const req = seed(dir, {
      requirements: requirementsDoc(),
      phases: { "999-fixture": { "999-VERIFICATION.md": PASSING_VERIFICATION, "999-UAT.md": "covers nothing relevant\n" } }
    });
    assert.throws(
      () => verifyCompletionEvidence(dir, req, { requireCompletionEvidence: true }),
      /ZZZ-01 is marked Complete but its ID appears in no \*-UAT\.md or \*-SUMMARY\.md/
    );
  });
}

function scenarioOrphanedCompleteRow() {
  withScratch((dir) => {
    const req = seed(dir, { requirements: requirementsDoc({ bulletState: null }) });
    assert.throws(
      () => verifyCompletionEvidence(dir, req, { requireTableAgreement: true }),
      /orphaned traceability row: ZZZ-01 is marked Complete/
    );
  });
}

function scenarioOrphanedCheckedBullet() {
  withScratch((dir) => {
    const req = seed(dir, { requirements: requirementsDoc({ rowStatus: null }) });
    assert.throws(
      () => verifyCompletionEvidence(dir, req, { requireTableAgreement: true }),
      /orphaned requirement bullet: ZZZ-01 is checked/
    );
  });
}

function scenarioCheckedBulletIncompleteRow() {
  withScratch((dir) => {
    const req = seed(dir, { requirements: requirementsDoc({ rowStatus: "Incomplete" }) });
    assert.throws(
      () => verifyCompletionEvidence(dir, req, { requireTableAgreement: true }),
      /disagreement for ZZZ-01: bullet on line \d+ is "- \[x\]" but traceability row on line \d+ says "Incomplete"/
    );
  });
}

function scenarioReshapedTableParsesZeroCompleteRows() {
  withScratch((dir) => {
    // The header is renamed, so no row parses as a requirement while the table
    // is visibly non-empty. The gate must say so loudly, not report a pass.
    const requirements = [
      "# Requirements",
      "",
      "## v1.99 Requirements",
      "",
      "## Traceability",
      "",
      "| Req ID | Owning Phase | State |",
      "|--------|--------------|-------|",
      "| ZZZ-01 | Phase 999 | Complete |",
      ""
    ].join("\n");
    const req = seed(dir, { requirements });
    assert.throws(
      () => verifyCompletionEvidence(dir, req, { requireCompletionEvidence: true }),
      /zero requirements parsed/
    );
  });
}

function scenarioZeroRequirementsParsed() {
  withScratch((dir) => {
    const req = seed(dir, { requirements: "# Requirements\n\nNothing here at all.\n" });
    assert.throws(() => verifyCompletionEvidence(dir, req, {}), /zero requirements parsed/);
  });
}

function scenarioEmptyPhasesCorpus() {
  withScratch((dir) => {
    const req = seed(dir, { requirements: requirementsDoc() });
    assert.throws(
      () => verifyCompletionEvidence(dir, req, { requireCompletionEvidence: true }),
      /no phase directories exist/
    );
  });
}

function scenarioIncompleteRequirementNeedsNoEvidence() {
  withScratch((dir) => {
    const req = seed(dir, {
      requirements: requirementsDoc({ bulletState: " ", rowStatus: "Incomplete", extraRows: "| ZZZ-02 | Phase 999 | Complete |", extraBullets: "- [x] **ZZZ-02**: an evidenced fixture requirement." }),
      phases: { "999-fixture": { "999-VERIFICATION.md": PASSING_VERIFICATION, "999-SUMMARY.md": "covers ZZZ-02\n" } }
    });
    const result = verifyCompletionEvidence(dir, req, { requireCompletionEvidence: true, requireTableAgreement: true });
    assert.equal(result.complete, 1);
    assert.equal(result.verified, 1);
  });
}

function scenarioFutureRequirementsAreSkippedAndCounted() {
  withScratch((dir) => {
    const requirements = [
      "# Requirements",
      "",
      "## v1.99 Requirements",
      "",
      "- [x] **ZZZ-01**: a fixture requirement.",
      "",
      "## Future Requirements",
      "",
      "- **ZZZ-99**: not yet started, deliberately unevidenced.",
      "",
      "## Traceability",
      "",
      "| Requirement | Phase | Status |",
      "|-------------|-------|--------|",
      "| ZZZ-01 | Phase 999 | Complete |",
      ""
    ].join("\n");
    const req = seed(dir, {
      requirements,
      phases: { "999-fixture": { "999-VERIFICATION.md": PASSING_VERIFICATION, "999-UAT.md": "covers ZZZ-01\n" } }
    });
    const result = verifyCompletionEvidence(dir, req, { requireCompletionEvidence: true, requireTableAgreement: true });
    assert.equal(result.futureSkipped, 1);
    assert.equal(result.verified, 1);
  });
}

function scenarioArchivedMilestonePhaseStillResolves() {
  withScratch((dir) => {
    const req = seed(dir, { requirements: requirementsDoc() });
    const archived = path.join(dir, ".planning", "milestones", "v1.99-phases", "999-fixture");
    fs.mkdirSync(archived, { recursive: true });
    fs.writeFileSync(path.join(archived, "999-VERIFICATION.md"), PASSING_VERIFICATION);
    fs.writeFileSync(path.join(archived, "999-UAT.md"), "covers ZZZ-01\n");
    const result = verifyCompletionEvidence(dir, req, { requireCompletionEvidence: true, requireTableAgreement: true });
    assert.equal(result.verified, 1);
  });
}

const SCENARIOS = [
  ["a requirement marked Complete whose phase has no VERIFICATION.md fails, naming the requirement and the directory searched", scenarioCompleteWithoutVerificationFile],
  ["a requirement marked Complete whose phase verification is not passed fails, naming the observed status", scenarioCompleteWithNonPassingVerification],
  ["a requirement marked Complete whose ID is cited by no UAT or SUMMARY artifact fails, naming the ID", scenarioCompleteWithNoCitingArtifact],
  ["bidirectional direction 1: a Complete traceability row with no requirement bullet fails, naming the orphaned row", scenarioOrphanedCompleteRow],
  ["bidirectional direction 2: a checked requirement bullet with no Complete row fails, naming the orphaned bullet", scenarioOrphanedCheckedBullet],
  ["a checked bullet whose traceability row says Incomplete fails, naming both sides", scenarioCheckedBulletIncompleteRow],
  ["non-vacuity: a reshaped traceability header that parses zero Complete rows fails loudly naming the parsed count", scenarioReshapedTableParsesZeroCompleteRows],
  ["a requirements file with zero parsed requirements fails", scenarioZeroRequirementsParsed],
  ["an empty phases corpus fails rather than reporting an evidence pass", scenarioEmptyPhasesCorpus],
  ["a requirement marked Incomplete needs no evidence and passes alongside an evidenced Complete one", scenarioIncompleteRequirementNeedsNoEvidence],
  ["requirements under Future Requirements are skipped and the skipped count is reported", scenarioFutureRequirementsAreSkippedAndCounted],
  ["a phase archived into .planning/milestones still resolves its evidence", scenarioArchivedMilestonePhaseStillResolves]
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

const BOOLEAN_FLAGS = new Set(["fixtures", "require-completion-evidence", "require-table-agreement"]);
const VALUE_OPTIONS = new Set(["repo", "requirements"]);

function options(argv) {
  const flags = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]; if (!token.startsWith("--")) fail(`unexpected argument: ${token}`);
    const key = token.slice(2);
    if (BOOLEAN_FLAGS.has(key)) { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option: --${key}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${key} requires a value`);
    if (key in values) fail(`--${key} may be provided only once`);
    values[key] = argv[++index];
  }
  return { flags, values };
}

function main() {
  const parsed = options(process.argv.slice(2));
  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();

  // --fixtures returns before --repo / --requirements are ever read.
  if (parsed.flags.has("fixtures")) {
    const count = verifyFixtures();
    const suffix = requestedStrictFlags.length
      ? ` (fixtures: ${requestedStrictFlags.join(", ")}; ${count} scenarios)`
      : ` (fixtures: no strict flags requested; ${count} scenarios)`;
    console.log(`completion evidence: PASS${suffix}`);
    return;
  }

  const repo = parsed.values.repo || process.cwd();
  const requirementsPath = parsed.values.requirements || path.join(repo, ".planning", "REQUIREMENTS.md");
  const result = verifyCompletionEvidence(repo, requirementsPath, {
    requireCompletionEvidence: parsed.flags.has("require-completion-evidence"),
    requireTableAgreement: parsed.flags.has("require-table-agreement")
  });

  const counts = `${result.parsed} parsed, ${result.complete} complete, ${result.verified} evidenced, ${result.futureSkipped} skipped as future`;
  const suffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")}; ${counts})`
    : ` (schema-only: no strict flags supplied; ${counts})`;
  console.log(`completion evidence: PASS${suffix}`);
}

// D-29: isMainModule() throws (never returns a silent false) when there is no
// invoking entrypoint; caught here and treated as "not the entrypoint" so a
// bare import stays side-effect-free (established pattern, 232-01).
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  try {
    main();
  } catch (error) {
    console.error(error.message.startsWith("completion evidence:") ? error.message : `completion evidence: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
