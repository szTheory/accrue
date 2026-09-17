#!/usr/bin/env node
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import {
  ROW_KINDS,
  ROW_DISPOSITIONS,
  ROW_STATES,
  validateWindowDispositions,
  validateWindowRow,
  readShipWindowRows
} from "./collect_window_dispositions.mjs";
import { renderWindowDispositions, bucketOf, BUCKET_OF_PAIR } from "./render_window_dispositions.mjs";
import { resolvePhaseEvidencePath, repositoryRoot } from "./phase_evidence_path.mjs";

const fail = (message) => { throw new Error(message); };

// D-30: exact-map completeness with a missing/extra/changed triple, copied
// verbatim from verify_integration_disposition.mjs/verify_repository_inventory.mjs
// -- never a new ad hoc `.every()`/`.includes()` comparison (D-30).
function exactMap(rows, label, keyOf, valueOf) {
  const result = new Map();
  for (const row of rows) {
    const key = keyOf(row);
    if (result.has(key)) fail(`${label} contains duplicate mapping: ${key}`);
    result.set(key, valueOf(row));
  }
  return result;
}
function assertSameMap(authorityName, authority, candidateName, candidate) {
  const missing = [...authority.keys()].filter((key) => !candidate.has(key)).sort((a, b) => a - b);
  const extra = [...candidate.keys()].filter((key) => !authority.has(key)).sort((a, b) => a - b);
  const changed = [...authority.keys()].filter((key) => candidate.has(key) && candidate.get(key) !== authority.get(key)).sort((a, b) => a - b);
  if (missing.length || extra.length || changed.length) {
    fail(`${candidateName} differs from ${authorityName}: missing=[${missing.join(", ")}] extra=[${extra.join(", ")}] changed=[${changed.join(", ")}]`);
  }
}

// D-30: the row-id join is exact set equality in both directions, recomputed
// inside the verifier. The live WINDOWS.md non-open row's `status` and the
// disposition row's `disposition` are the SAME two-valued vocabulary
// (fixed/waived), so a single assertSameMap call yields missing (id only in
// the ledger), extra (id only in the record), and changed (id on both sides
// but status/disposition disagree) in one pass (D-26, D-30).
function assertRowJoin(ledgerRows, dispositionRows) {
  const openIds = ledgerRows.filter((row) => row.status === "open").map((row) => row.id).sort((a, b) => a - b);
  if (openIds.length) fail(`ship-window ledger still has ${openIds.length} open row(s) with no disposition partner: ids=[${openIds.join(", ")}]`);

  const nonOpenLedgerRows = ledgerRows.filter((row) => row.status !== "open");
  const authority = exactMap(nonOpenLedgerRows, "WINDOWS.md non-open rows", (row) => row.id, (row) => row.status);
  const candidate = exactMap(dispositionRows, "231-WINDOW-DISPOSITIONS rows", (row) => row.id, (row) => row.disposition);
  assertSameMap("WINDOWS.md non-open rows", authority, "231-WINDOW-DISPOSITIONS rows", candidate);
}

// D-23: "current evidence" means re-derived at the candidate SHA, never the
// ledger's original description copied forward. A row whose current_evidence
// is byte-identical to its ledger description is a copied-forward
// description, not re-derived evidence, and fails closed.
function assertEvidenceFreshness(ledgerRows, dispositionRows) {
  const descriptionById = exactMap(ledgerRows, "WINDOWS.md rows", (row) => row.id, (row) => row.description);
  for (const row of dispositionRows) {
    const description = descriptionById.get(row.id);
    if (description !== undefined && description === row.current_evidence) {
      fail(`row ${row.id}'s current_evidence is byte-identical to its original ledger description -- not re-derived evidence (D-23)`);
    }
  }
}

// Independent of validateWindowRow's own (always-on) schema check -- this is
// the same completeness assertion re-run at the verifier layer, over the
// record as it exists on disk, so a hand-edited/corrupted committed record
// that never went through the collector is still caught.
function assertWaiverCompleteness(dispositionRows) {
  for (const row of dispositionRows) {
    if (row.disposition !== "waived") continue;
    for (const key of ["owner", "rationale", "release_impact"]) {
      if (typeof row[key] !== "string" || !row[key].trim()) fail(`waived row ${row.id} is missing a non-empty ${key} (GATE-03, D-22)`);
    }
  }
}

// CR-01: sibling of assertWaiverCompleteness -- independent of
// validateWindowRow's own (always-on) schema check, re-run at the verifier
// layer over the record as it exists on disk, so a hand-edited/corrupted
// committed record that never went through the collector is still caught.
// A row closed as "fixed" (safe to ship) must record a genuinely passing
// re-run -- never failed/skipped/advisory/non_run (D-22, GATE-03).
function assertFixedRowsProved(dispositionRows) {
  for (const row of dispositionRows) {
    if (row.disposition !== "fixed") continue;
    if (row.state !== "proved") fail(`fixed row ${row.id} has state "${row.state}", not "proved" (CR-01, GATE-03, D-22) -- a row closed as fixed must have a genuinely passing re-run, never failed/skipped/advisory/non_run`);
  }
}

// D-31: re-rendering the committed JSON must byte-equal the committed
// Markdown. On mismatch, report the first differing byte offset so a
// reviewer does not have to diff the whole file by hand.
function assertDeterminism(record, renderedContents) {
  const fresh = renderWindowDispositions(record);
  if (fresh === renderedContents) return;
  const shortest = Math.min(fresh.length, renderedContents.length);
  let offset = 0;
  while (offset < shortest && fresh[offset] === renderedContents[offset]) offset += 1;
  fail(`rendered Markdown is not byte-reproducible from the committed JSON (first differing byte offset: ${offset})`);
}

const BOOLEAN_FLAGS = new Set(["fixtures", "require-row-join", "require-evidence-freshness", "require-waiver-completeness", "require-determinism"]);
const VALUE_OPTIONS = new Set(["repo", "records", "rendered", "expected-repository", "candidate"]);

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

function readDispositionFile(recordsPath) {
  if (!recordsPath) fail("--records is required");
  if (!fs.existsSync(recordsPath)) fail(`disposition record file does not exist: ${recordsPath}`);
  let contents;
  try { contents = fs.readFileSync(recordsPath, "utf8"); }
  catch (error) { fail(`disposition record file could not be read: ${recordsPath} (${error.message})`); }
  return JSON.parse(contents);
}

function applyStrictFlags(repo, record, renderedContents, parsed) {
  if (parsed.flags.has("require-row-join") || parsed.flags.has("require-evidence-freshness")) {
    const ledgerRows = readShipWindowRows(repo);
    if (parsed.flags.has("require-row-join")) assertRowJoin(ledgerRows, record.rows);
    if (parsed.flags.has("require-evidence-freshness")) assertEvidenceFreshness(ledgerRows, record.rows);
  }
  if (parsed.flags.has("require-waiver-completeness")) { assertWaiverCompleteness(record.rows); assertFixedRowsProved(record.rows); }
  if (parsed.flags.has("require-determinism")) {
    if (renderedContents === undefined) fail("--rendered is required with --require-determinism");
    assertDeterminism(record, renderedContents);
  }
}

export function verifyFixtures() {
  function ledgerScratch() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-window-verify-fixture-"));
    fs.mkdirSync(path.join(scratch, ".planning"));
    return scratch;
  }
  const WINDOWS_HEADER = "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |";
  const WINDOWS_SEP = "|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|";
  function windowsMd(rows) {
    const counts = {
      open: rows.filter((row) => row.status === "open").length,
      waived: rows.filter((row) => row.status === "waived").length,
      fixed: rows.filter((row) => row.status === "fixed").length
    };
    const lines = [
      "---", "schema_version: 1",
      `open_count: ${counts.open}`, `waived_count: ${counts.waived}`, `fixed_count: ${counts.fixed}`, `total_count: ${rows.length}`,
      "last_updated: 2026-09-15T00:00:00.000Z", "---", "",
      "# Broken Windows Ledger", "", WINDOWS_HEADER, WINDOWS_SEP,
      ...rows.map((row) => `| ${row.id} | ${row.phase} | ${row.kind} | ${row.file} | ${row.line ?? ""} | ${row.description} | ${row.status} | ${row.reason ?? ""} | ${row.recorded_at ?? "2026-09-15T00:00:00.000Z"} | ${row.resolved_at ?? ""} |`),
      ""
    ];
    return lines.join("\n");
  }
  function withLedger(rows, fn) {
    const scratch = ledgerScratch();
    try {
      fs.writeFileSync(path.join(scratch, ".planning", "WINDOWS.md"), windowsMd(rows));
      fn(scratch);
    } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
  }

  function ledgerRow(overrides = {}) {
    return { id: 1, phase: "214.2", kind: "unrun-verify", file: "examples/accrue_host/e2e/verify01-admin-mobile.spec.js", description: "the checked-in Playwright config has no chromium-mobile project", status: "fixed", ...overrides };
  }
  function dispositionRow(overrides = {}) {
    return { id: 1, phase: "214.2", kind: "unrun-verify", disposition: "fixed", state: "proved", exit_code: 0, current_evidence: "examples/accrue_host/playwright.config.js already defines a chromium-mobile project at the candidate SHA", ...overrides };
  }
  function dispositionRecord(rows, overrides = {}) {
    return { schema_version: 1, repository: "szTheory/accrue", candidate_object: "a".repeat(40), observed_at: "2026-09-15T00:00:00+00:00", rows, ...overrides };
  }

  // 1: clean pass -- one fixed row, one waived row, all four strict flags.
  withLedger([ledgerRow({ id: 1, status: "fixed" }), ledgerRow({ id: 2, kind: "deviation", status: "waived", description: "a still-reproducing pre-existing failure" })], (scratch) => {
    const record = dispositionRecord([
      dispositionRow({ id: 1 }),
      { id: 2, phase: "214.2", kind: "deviation", disposition: "waived", state: "failed", owner: "maintainer", rationale: "still reproduces", release_impact: "no regression, tracked separately", current_evidence: "the failure still reproduces at the candidate SHA" }
    ]);
    const rendered = renderWindowDispositions(record);
    const ledgerRows = readShipWindowRows(scratch);
    assertRowJoin(ledgerRows, record.rows);
    assertEvidenceFreshness(ledgerRows, record.rows);
    assertWaiverCompleteness(record.rows);
    assertDeterminism(record, rendered);
  });

  // 2: empty case -- zero non-open ledger rows joined against zero disposition rows passes.
  withLedger([], (scratch) => {
    const ledgerRows = readShipWindowRows(scratch);
    assertRowJoin(ledgerRows, []);
  });

  // 3: one-row case passes when ids match, fails when they differ.
  withLedger([ledgerRow({ id: 7, status: "fixed" })], (scratch) => {
    const ledgerRows = readShipWindowRows(scratch);
    assertRowJoin(ledgerRows, [dispositionRow({ id: 7 })]);
    assert.throws(() => assertRowJoin(ledgerRows, [dispositionRow({ id: 9 })]), /missing=\[7\].*extra=\[9\]/s);
  });

  // 4: missing -- an id only in the ledger.
  withLedger([ledgerRow({ id: 1, status: "fixed" }), ledgerRow({ id: 4, status: "waived", description: "second row" })], (scratch) => {
    const ledgerRows = readShipWindowRows(scratch);
    assert.throws(() => assertRowJoin(ledgerRows, [dispositionRow({ id: 1 })]), /missing=\[4\]/);
  });

  // 5: extra -- an id only in the record.
  withLedger([ledgerRow({ id: 1, status: "fixed" })], (scratch) => {
    const ledgerRows = readShipWindowRows(scratch);
    assert.throws(() => assertRowJoin(ledgerRows, [dispositionRow({ id: 1 }), dispositionRow({ id: 2 })]), /extra=\[2\]/);
  });

  // 6: changed -- an id on both sides whose ledger status disagrees with the record's disposition.
  withLedger([ledgerRow({ id: 1, status: "fixed" })], (scratch) => {
    const ledgerRows = readShipWindowRows(scratch);
    assert.throws(() => assertRowJoin(ledgerRows, [dispositionRow({ id: 1, disposition: "waived", owner: "m", rationale: "r", release_impact: "i" })]), /changed=\[1\]/);
  });

  // 7: duplicate id on the disposition side fails rather than silently collapsing.
  withLedger([ledgerRow({ id: 1, status: "fixed" })], (scratch) => {
    const ledgerRows = readShipWindowRows(scratch);
    assert.throws(() => assertRowJoin(ledgerRows, [dispositionRow({ id: 1 }), dispositionRow({ id: 1 })]), /duplicate mapping/);
  });

  // 8: a still-open ledger row fails even if it happens to have a disposition partner.
  withLedger([ledgerRow({ id: 1, status: "open", description: "still open" })], (scratch) => {
    const ledgerRows = readShipWindowRows(scratch);
    assert.throws(() => assertRowJoin(ledgerRows, [dispositionRow({ id: 1 })]), /still has 1 open row/);
  });

  // 9: evidence freshness -- byte-identical current_evidence to the ledger description fails.
  withLedger([ledgerRow({ id: 1, status: "fixed", description: "same text on both sides" })], (scratch) => {
    const ledgerRows = readShipWindowRows(scratch);
    assert.throws(() => assertEvidenceFreshness(ledgerRows, [dispositionRow({ id: 1, current_evidence: "same text on both sides" })]), /byte-identical to its original ledger description/);
    // A genuinely re-derived value passes.
    assertEvidenceFreshness(ledgerRows, [dispositionRow({ id: 1, current_evidence: "a different, re-derived value" })]);
  });

  // 10: waiver completeness -- missing owner/rationale/release_impact fails even
  // though the row was constructed by hand, bypassing validateWindowRow.
  {
    const incompleteWaived = { id: 3, phase: "220", kind: "unrun-verify", disposition: "waived", state: "failed", owner: "", rationale: "r", release_impact: "i", current_evidence: "still fails" };
    assert.throws(() => assertWaiverCompleteness([incompleteWaived]), /missing a non-empty owner/);
    assertWaiverCompleteness([{ ...incompleteWaived, owner: "maintainer" }]);
  }

  // 10a: CR-01 -- a fabricated fixed/failed row is rejected by
  // assertFixedRowsProved even when hand-authored and never passed through
  // the collector; a fixed/proved row and a waived/failed row still pass.
  {
    const fabricatedFixed = { id: 4, phase: "214.2", kind: "unrun-verify", disposition: "fixed", state: "failed", current_evidence: "still fails, but marking fixed anyway" };
    assert.throws(() => assertFixedRowsProved([fabricatedFixed]), /fixed row 4 has state "failed", not "proved"/);
    assertFixedRowsProved([dispositionRow({ id: 4, disposition: "fixed", state: "proved", exit_code: 0 })]);
    assertFixedRowsProved([{ id: 5, phase: "220", kind: "unrun-verify", disposition: "waived", state: "failed", owner: "maintainer", rationale: "still reproduces", release_impact: "no regression", current_evidence: "still fails" }]);
  }

  // 11: determinism -- a tampered rendered file fails with a byte-offset message.
  {
    const record = dispositionRecord([dispositionRow({ id: 1 })]);
    const rendered = renderWindowDispositions(record);
    assert.throws(() => assertDeterminism(record, `${rendered}tampered`), /first differing byte offset: \d+/);
    assertDeterminism(record, rendered);
  }

  // 12: a missing or unreadable disposition file is a hard failure naming the path,
  // never an empty-set pass.
  {
    const missingPath = path.join(fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-window-verify-missing-")), "does-not-exist.json");
    assert.throws(() => readDispositionFile(missingPath), new RegExp(`disposition record file does not exist: ${missingPath.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`));
  }

  // 13: validateWindowDispositions/validateWindowRow re-exported enums stay closed.
  assert.deepEqual([...ROW_KINDS].sort(), ["deviation", "unrun-verify"]);
  assert.deepEqual([...ROW_DISPOSITIONS].sort(), ["fixed", "waived"]);
  assert.throws(() => validateWindowRow({ id: 1, phase: "x", kind: "mystery", disposition: "fixed", state: "proved", exit_code: 0, current_evidence: "e" }, "row"), /closed row-kind enumeration/);

}

// D-14: the pair space this probe row minimally satisfies -- exit_code when
// state is "proved" (CR-01), owner/rationale/release_impact when disposition
// is "waived" (GATE-03) -- so a candidate pair's LEGALITY is decided purely
// by validateWindowRow's own rejection rule, never a hand-listed table that
// could silently drift from the schema (D-14, CR-01).
function probeRow(disposition, state) {
  const row = { id: 1, phase: "1", kind: "unrun-verify", disposition, state, current_evidence: "probe row for cartesian-product reachability" };
  if (state === "proved") row.exit_code = 0;
  if (disposition === "waived") { row.owner = "maintainer"; row.rationale = "probe"; row.release_impact = "probe"; }
  return row;
}

// D-14: re-derived by calling validateWindowRow, never transcribed -- this
// is the entire point of the reachability test: legality cannot drift from
// the schema because it is never copied out of it.
export function deriveLegalPairs() {
  const legal = [];
  for (const disposition of ROW_DISPOSITIONS) {
    for (const state of ROW_STATES) {
      try {
        validateWindowRow(probeRow(disposition, state), "probe");
        legal.push([disposition, state]);
      } catch {
        // illegal pair -- not in scope for this reachability test
      }
    }
  }
  return legal;
}

async function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("window dispositions fixtures: PASS"); return; }

  const repo = parsed.values.repo || repositoryRoot;
  const record = validateWindowDispositions(readDispositionFile(parsed.values.records));

  if (parsed.values["expected-repository"] && record.repository !== parsed.values["expected-repository"]) fail("--expected-repository does not match the recorded disposition.repository");
  if (parsed.values.candidate) {
    const { spawnSync } = await import("node:child_process");
    const resolved = spawnSync("git", ["-C", repo, "rev-parse", `${parsed.values.candidate}^{commit}`], { encoding: "utf8" });
    if (resolved.status !== 0) fail(`unable to resolve --candidate against the repository: ${(resolved.stderr || "").trim()}`);
    if (resolved.stdout.trim() !== record.candidate_object) fail("--candidate does not match the recorded disposition.candidate_object");
  }

  let renderedContents;
  if (parsed.values.rendered) {
    if (!fs.existsSync(parsed.values.rendered)) fail(`rendered markdown file does not exist: ${parsed.values.rendered}`);
    renderedContents = fs.readFileSync(parsed.values.rendered, "utf8");
  }

  applyStrictFlags(repo, record, renderedContents, parsed);

  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
  const verificationSuffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")})`
    : " (schema-only: no strict flags supplied, no row-join or determinism check ran)";
  console.log(`window dispositions verification: PASS${verificationSuffix}`);
}

// D-29/231-REVIEW IN-01: this file previously had no entrypoint guard at all
// -- main() ran unconditionally on import whenever NODE_TEST_CONTEXT was
// unset. isMainModule() throws (never returns a silent false) when there is
// no invoking entrypoint; that throw is caught here and treated as "not the
// entrypoint" so an ambiguous import stays side-effect-free instead of
// crashing (see main_module.mjs, D-29).
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  test("window dispositions fixtures pass every negative control", () => verifyFixtures());
  // CR-01 follow-through (D-14): asserts BOTH directions of the mapping in one
  // pass -- no legal pair renders unbucketed (reachedBuckets has no member
  // outside declaredBuckets), and no declared bucket is dead code
  // (declaredBuckets has no member outside reachedBuckets). deepEqual on the
  // two sorted arrays gives both simultaneously.
  test("every legal (disposition, state) pair renders under exactly one declared bucket, and no declared bucket is unreachable by any legal pair", () => {
    const legalPairs = deriveLegalPairs();
    // A completeness loop over zero items must not silently declare pass.
    assert.ok(legalPairs.length > 0, "derived legal-pair set must be non-empty");

    // "Exactly one declared bucket": bucketOf() throws on an unmapped pair
    // rather than returning undefined, so a legal pair that somehow missed the
    // map surfaces here as a thrown error, not a silent gap.
    const reachedBuckets = new Set();
    for (const [disposition, state] of legalPairs) {
      reachedBuckets.add(bucketOf({ id: 1, disposition, state }));
    }
    const declaredBuckets = new Set([...BUCKET_OF_PAIR.values()]);
    assert.deepEqual([...reachedBuckets].sort(), [...declaredBuckets].sort());
  });
} else if (invokedAsEntrypoint) {
  main().catch((error) => { console.error(`window dispositions verify: FAIL: ${error.message}`); process.exitCode = 1; });
}
