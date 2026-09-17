#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { validateWindowDispositions, ROW_KINDS, ROW_DISPOSITIONS, ROW_STATES } from "./collect_window_dispositions.mjs";
import { resolvePhaseEvidencePath, repositoryRoot } from "./phase_evidence_path.mjs";

const fail = (message) => { throw new Error(message); };

const escape = (value) => String(value ?? "").replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");

// D-31/D-39 (231 lineage): a stable start/end HTML comment marker pair so a
// later phase can splice this block into a PR body without re-deriving it.
export const SPLICE_START = "<!-- phase231-window-dispositions:start -->";
export const SPLICE_END = "<!-- phase231-window-dispositions:end -->";

// D-13/D-14: bucketing is a total map keyed on the literal (disposition,
// state) pair, never an if-chain with fall-through. CR-01's validateWindowRow
// already restricts a non-waived row to {disposition: "fixed", state:
// "proved"}, and permits any state for a waived row -- so the closed legal
// pair space is exactly these six pairs, re-derived at test time (not
// transcribed) by the verifier's cartesian-product reachability test calling
// validateWindowRow directly. bucketOf() calls fail() on any pair outside
// this map rather than falling through to a default bucket; that branch is
// unreachable through the public renderWindowDispositions() entrypoint
// (validateWindowDispositions rejects an illegal pair first) but stays live
// as defensive fail-safety against a caller that renders an unvalidated
// record directly, exercised directly in this file's own test block.
//
// D-15 (maintainer decision, 2026-09-16): waived rows split by their OWN
// state into three named sections instead of one undifferentiated "waived"
// bucket -- a reader without the schema can tell, from the heading alone,
// whether the gate ran and failed, never produced anything, or (the real,
// currently-legal third case) passed anyway, a ledger/reality mismatch that
// deserves its own declared bucket, not a comment.
const PAIR_SEPARATOR = "\u0000";
export const pairKey = (disposition, state) => `${disposition}${PAIR_SEPARATOR}${state}`;
export const BUCKET_OF_PAIR = new Map([
  [pairKey("waived", "failed"), "waived_gate_ran_and_failed"],
  [pairKey("waived", "skipped"), "waived_gate_never_proved"],
  [pairKey("waived", "advisory"), "waived_gate_never_proved"],
  [pairKey("waived", "non_run"), "waived_gate_never_proved"],
  [pairKey("waived", "proved"), "waived_gate_passed_anyway"],
  [pairKey("fixed", "proved"), "fixed"]
]);

export function bucketOf(row) {
  const bucket = BUCKET_OF_PAIR.get(pairKey(row.disposition, row.state));
  if (!bucket) fail(`row ${row.id} has an unmapped (disposition, state) pair: (${row.disposition}, ${row.state})`);
  return bucket;
}

const BUCKETS = [
  { key: "waived_gate_ran_and_failed", title: "Waived \u2014 the gate ran and failed" },
  { key: "waived_gate_never_proved", title: "Waived \u2014 the gate never proved anything" },
  { key: "waived_gate_passed_anyway", title: "Waived \u2014 the gate passed anyway" },
  { key: "fixed", title: "Fixed \u2014 proved at the candidate SHA" }
];

const ROW_HEADING = [
  "| Id | Phase | Kind | Disposition | State | Exit code | Owner | Rationale | Release impact | Current evidence | Evidence command |",
  "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"
];

// D-19/specifics: evidence_command is present in the JSON and shown nowhere
// today -- it is how a maintainer disbelieves the report and re-runs it.
// Rendered as a shell-readable, space-joined argv string (the array itself
// is already validated as a non-empty array of strings by validateWindowRow).
function evidenceCommandText(row) {
  return Object.hasOwn(row, "evidence_command") && Array.isArray(row.evidence_command) && row.evidence_command.length
    ? row.evidence_command.join(" ")
    : "\u2014";
}

function rowLine(row) {
  return `| ${row.id} | ${escape(row.phase)} | ${escape(row.kind)} | ${escape(row.disposition)} | ${escape(row.state)} | ${Object.hasOwn(row, "exit_code") && row.exit_code !== null && row.exit_code !== undefined ? row.exit_code : "\u2014"} | ${escape(row.owner)} | ${escape(row.rationale)} | ${escape(row.release_impact)} | ${escape(row.current_evidence)} | ${escape(evidenceCommandText(row))} |`;
}

// D-31: pure function of the validated JSON -- no filesystem read beyond the
// object passed in, no Date.now(), no other wall-clock source. Called twice
// with the same input it returns byte-identical strings.
export function renderWindowDispositions(record) {
  const value = validateWindowDispositions(record);

  // Belt-and-suspenders: bucketOf() must be exhaustive over the closed
  // kind/disposition vocabulary imported from the collector (never a locally
  // re-declared copy, D-25's "one parser/one vocabulary" discipline). This
  // never fires in practice -- validateWindowDispositions already rejects an
  // unknown kind/disposition before renderWindowDispositions is reached --
  // but it documents, at the render layer too, exactly which enums this
  // renderer was built against.
  for (const row of value.rows) {
    if (!ROW_KINDS.has(row.kind)) fail(`row ${row.id} has a kind outside the closed enumeration: ${row.kind}`);
    if (!ROW_DISPOSITIONS.has(row.disposition)) fail(`row ${row.id} has a disposition outside the closed enumeration: ${row.disposition}`);
    if (!ROW_STATES.has(row.state)) fail(`row ${row.id} has a state outside the closed enumeration: ${row.state}`);
  }

  const grouped = new Map(BUCKETS.map((bucket) => [bucket.key, []]));
  for (const row of value.rows) grouped.get(bucketOf(row)).push(row);
  for (const rows of grouped.values()) rows.sort((left, right) => left.id - right.id);

  const sections = BUCKETS.flatMap(({ key, title }) => {
    const rows = grouped.get(key);
    return [
      `## ${title}`, "",
      `${rows.length} row(s).`, "",
      ...(rows.length ? [...ROW_HEADING, ...rows.map(rowLine)] : []),
      ""
    ];
  });

  return [
    "# Ship-Window Dispositions", "",
    "Sanitized schema-v1 evidence answering \"can I ship this SHA, and what is still unproven?\" for every non-open row in `.planning/WINDOWS.md`, joined 1:1 by row id. This is a deterministic projection: no raw payloads, actor identities, secret values, or absolute paths are present.", "",
    // D-19/specifics: pre-answers "did you edit evidence?" for every future
    // reader -- this Markdown is a deterministic re-render of the named JSON
    // record, and the JSON is the evidence of record, never this file.
    "This document is a deterministic re-render (a projection) of the schema-v1 JSON record identified below; the JSON is the evidence of record, and this Markdown is generated from it, never edited directly.", "",
    // D-18: applies only to the current phase's own record because the join
    // is against the LIVE `.planning/WINDOWS.md` ledger -- a historical,
    // frozen record verifies schema and determinism only, so nobody "fixes"
    // a false red by editing frozen evidence.
    "The `--require-row-join`/`--require-evidence-freshness` strict checks apply only to the current phase's own record, because the join and freshness comparison are against the live `.planning/WINDOWS.md` ledger. A historical, frozen record from a prior phase verifies schema and determinism only -- if a historical record's row-join or freshness check ever fails, the ledger has moved, not the evidence; the fix is never to edit the frozen record.", "",
    SPLICE_START, "",
    ...([
      "## Candidate identity", "",
      `Candidate object: \`${value.candidate_object}\`. Observed at: ${escape(value.observed_at)}. Rows: **${value.rows.length}**.`, ""
    ]),
    ...sections,
    SPLICE_END,
    ""
  ].join("\n");
}

const PHASE_SLUG = "231-exact-sha-release-gate-proof";
const JSON_ARTIFACT = "231-WINDOW-DISPOSITIONS.json";
const MD_ARTIFACT = "231-WINDOW-DISPOSITIONS.md";
function defaultPath(artifact) {
  try { return resolvePhaseEvidencePath(PHASE_SLUG, artifact); }
  catch { return path.join(repositoryRoot, ".planning", "phases", PHASE_SLUG, artifact); }
}

function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--") || !argv[index + 1]) fail("usage: --records FILE [--out FILE]");
    result[argv[index].slice(2)] = argv[++index];
  }
  return result;
}
function main() {
  const options = parseArgs(process.argv.slice(2));
  const recordsPath = options.records || defaultPath(JSON_ARTIFACT);
  const outPath = options.out || defaultPath(MD_ARTIFACT);
  const record = JSON.parse(fs.readFileSync(recordsPath, "utf8"));
  const rendered = renderWindowDispositions(record);
  fs.writeFileSync(outPath, rendered, { mode: 0o600 });
}
// Rule 1: matches collect_window_dispositions.mjs's fix in this same
// commit -- isMainModule() throws on an ambiguous entrypoint rather than
// returning a silent false; that throw must not crash a bare import.
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (!process.env.NODE_TEST_CONTEXT && invokedAsEntrypoint) {
  try { main(); } catch (error) { console.error(`window dispositions render: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && invokedAsEntrypoint) {
  function minimalRecord(overrides = {}) {
    return {
      schema_version: 1,
      repository: "szTheory/accrue",
      candidate_object: "a".repeat(40),
      observed_at: "2026-09-15T00:00:00+00:00",
      rows: [],
      ...overrides
    };
  }
  function fixedRow(overrides = {}) {
    return { id: 1, phase: "214.2", kind: "unrun-verify", disposition: "fixed", state: "proved", exit_code: 0, current_evidence: "the gate now runs and passes at the candidate SHA", ...overrides };
  }
  function waivedRow(overrides = {}) {
    return { id: 5, phase: "220", kind: "unrun-verify", disposition: "waived", state: "failed", owner: "maintainer", rationale: "still reproduces", release_impact: "no regression, tracked separately", current_evidence: "the pre-existing failing test still fails at the candidate SHA", ...overrides };
  }

  test("renders deterministic markdown for a minimal valid record", () => {
    const record = minimalRecord({ rows: [fixedRow(), waivedRow()] });
    const first = renderWindowDispositions(record);
    const second = renderWindowDispositions(record);
    assert.equal(first, second, "render must be deterministic");
  });

  test("rejects rendering an invalid record", () => {
    assert.throws(() => renderWindowDispositions({ schema_version: 2 }), /unsupported schema version|missing required field/);
  });

  test("renders every D-15 bucket heading even when the record has zero rows", () => {
    const rendered = renderWindowDispositions(minimalRecord());
    const headings = rendered.split("\n").filter((line) => line.startsWith("## "));
    assert.deepEqual(headings, [
      "Candidate identity",
      "Waived — the gate ran and failed",
      "Waived — the gate never proved anything",
      "Waived — the gate passed anyway",
      "Fixed — proved at the candidate SHA"
    ].map((title) => `## ${title}`));
    assert.match(rendered, /0 row\(s\)\./);
  });

  // D-13: the bucketing map is total over the closed (disposition, state)
  // pair space -- an unmapped pair must fail() rather than fall through to a
  // default bucket, naming the row id and both offending values. Every pair
  // that survives validateWindowRow (CR-01) is by construction one of the
  // six legal pairs the map declares, so this defensive branch is exercised
  // by calling bucketOf() directly on a hand-constructed row that bypasses
  // validation -- exactly the scenario the branch guards against.
  test("bucketOf fails closed on an unmapped (disposition, state) pair, naming the row id and both values", () => {
    const brokenRow = { id: 99, disposition: "fixed", state: "failed" };
    assert.throws(
      () => bucketOf(brokenRow),
      /row 99 has an unmapped \(disposition, state\) pair: \(fixed, failed\)/
    );
  });

  // D-15: waived rows split by their own state into three named sections,
  // and a real currently-legal "waived but proved anyway" row is its own
  // declared bucket, not a comment.
  test("waived rows split by state into three named sections, including the real waived-but-proved case", () => {
    const rows = [
      { id: 1, phase: "220", kind: "unrun-verify", disposition: "waived", state: "failed", owner: "m", rationale: "r", release_impact: "i", current_evidence: "the gate ran and failed" },
      { id: 2, phase: "220", kind: "unrun-verify", disposition: "waived", state: "non_run", owner: "m", rationale: "r", release_impact: "i", current_evidence: "the gate never ran" },
      { id: 3, phase: "220", kind: "unrun-verify", disposition: "waived", state: "proved", exit_code: 0, owner: "m", rationale: "r", release_impact: "i", current_evidence: "the gate passed anyway, a ledger/reality mismatch" },
      fixedRow({ id: 4 })
    ];
    const rendered = renderWindowDispositions(minimalRecord({ rows }));
    assert.ok(rendered.indexOf("## Waived — the gate ran and failed") < rendered.indexOf("| 1 |"));
    assert.ok(rendered.indexOf("## Waived — the gate never proved anything") < rendered.indexOf("| 2 |"));
    assert.ok(rendered.indexOf("## Waived — the gate passed anyway") < rendered.indexOf("| 3 |"));
    assert.ok(rendered.indexOf("## Fixed — proved at the candidate SHA") < rendered.indexOf("| 4 |"));
  });

  // D-19/specifics: the header states this file is a deterministic
  // re-render of the JSON record and that the JSON is the evidence of
  // record, and it renders the record's per-row evidence_command.
  test("header states the file is a deterministic projection and the JSON is the evidence of record, and renders evidence_command", () => {
    const rendered = renderWindowDispositions(minimalRecord({
      rows: [fixedRow({ id: 1, evidence_command: ["git", "show", "HEAD:foo.mjs"] })]
    }));
    assert.match(rendered, /deterministic (re-render|projection)/);
    assert.match(rendered, /JSON is the evidence of record/);
    assert.match(rendered, /git show HEAD:foo\.mjs/);
  });

  // D-18: the rendered header notes the row-join strict check applies only
  // to the current phase's own record.
  test("header states the row-join strict check applies only to the current phase's own record", () => {
    const rendered = renderWindowDispositions(minimalRecord());
    assert.match(rendered, /strict checks? appl(?:y|ies) only to the current phase/);
    assert.match(rendered, /historical,? frozen record.*verifies schema and determinism only/);
  });

  // CR-01 (added after this test was first written): a non-waived row must
  // have state "proved", so bucketOf's "failed" and "not_run" branches are
  // now unreachable in practice for any row that passes validateWindowRow --
  // there is no legal {disposition: "fixed", state: "failed"/"skipped"/
  // "advisory"/"non_run"} row to construct any more (that is exactly what
  // CR-01 bans). This test's remaining load-bearing assertion is the section
  // ORDER (waived leads, fixed collapses last) and the intra-bucket row
  // ordering, not full four-bucket occupancy -- `sections` renders every
  // bucket heading unconditionally regardless of row content, so the
  // heading-list assertion below passes independent of which buckets are
  // actually populated.
  test("leads with waived-failed, then waived-never-proved, then waived-passed-anyway, then fixed collapsed last", () => {
    const rows = [
      fixedRow({ id: 1 }),
      waivedRow({ id: 2 }),
      { id: 3, phase: "227", kind: "unrun-verify", disposition: "waived", state: "skipped", owner: "maintainer", rationale: "credential-gated in CI", release_impact: "no regression, tracked separately", current_evidence: "credential-gated, honestly skipped at the candidate SHA" },
      fixedRow({ id: 4, current_evidence: "a second gate now runs and passes at the candidate SHA" })
    ];
    const rendered = renderWindowDispositions(minimalRecord({ rows }));
    const headings = rendered.split("\n").filter((line) => line.startsWith("## ")).filter((line) => line !== "## Candidate identity");
    assert.deepEqual(headings, [
      "## Waived — the gate ran and failed",
      "## Waived — the gate never proved anything",
      "## Waived — the gate passed anyway",
      "## Fixed — proved at the candidate SHA"
    ]);
    // row 2 and row 3 (waived) must render before row 1 and row 4 (fixed/proved).
    assert.ok(rendered.indexOf("| 2 |") < rendered.indexOf("| 1 |"));
    assert.ok(rendered.indexOf("| 3 |") < rendered.indexOf("| 1 |"));
    // within the fixed bucket, rows sort ascending by id.
    assert.ok(rendered.indexOf("| 1 |") < rendered.indexOf("| 4 |"));
  });

  test("row 1's current_evidence renders even when it differs from what would be the ledger's stale description", () => {
    const staleDescription = "Host mobile entitlement contract is skipped because the checked-in Playwright config has no chromium-mobile project.";
    const reDerivedEvidence = "examples/accrue_host/playwright.config.js already defines a chromium-mobile project at the candidate SHA.";
    const rendered = renderWindowDispositions(minimalRecord({ rows: [fixedRow({ id: 1, current_evidence: reDerivedEvidence })] }));
    assert.match(rendered, new RegExp(reDerivedEvidence.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
    assert.doesNotMatch(rendered, new RegExp(staleDescription.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
  });

  test("escapes pipe, backtick, backslash, and angle-bracket characters, and collapses embedded newlines", () => {
    const rendered = renderWindowDispositions(minimalRecord({ rows: [fixedRow({ current_evidence: "a | b ` c \\ d < e\nnext line" })] }));
    assert.doesNotMatch(rendered, /a \| b ` c \\ d < e\nnext line/);
    assert.match(rendered, /a \\\| b \\` c \\\\ d \\< e next line/);
  });

  test("is fenced by the phase231-window-dispositions splice marker pair", () => {
    const rendered = renderWindowDispositions(minimalRecord());
    assert.match(rendered, /<!-- phase231-window-dispositions:start -->/);
    assert.match(rendered, /<!-- phase231-window-dispositions:end -->/);
    assert.ok(rendered.indexOf(SPLICE_START) < rendered.indexOf(SPLICE_END));
  });

  test("re-rendering an empty-rows record produces a well-formed document, not an empty file", () => {
    const rendered = renderWindowDispositions(minimalRecord());
    assert.ok(rendered.trim().length > 0);
    assert.match(rendered, /^# Ship-Window Dispositions/);
  });

  test("shuffling row order and re-rendering produces identical output", () => {
    const rows = [fixedRow({ id: 1 }), waivedRow({ id: 2 }), fixedRow({ id: 3, current_evidence: "third row evidence" })];
    const forward = minimalRecord({ rows });
    const shuffled = minimalRecord({ rows: [...rows].reverse() });
    assert.equal(renderWindowDispositions(forward), renderWindowDispositions(shuffled));
  });
}
