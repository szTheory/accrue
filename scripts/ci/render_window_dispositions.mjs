#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { validateWindowDispositions, ROW_KINDS, ROW_DISPOSITIONS } from "./collect_window_dispositions.mjs";
import { resolvePhaseEvidencePath, repositoryRoot } from "./phase_evidence_path.mjs";

const escape = (value) => String(value ?? "").replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");

// D-31/D-39 (231 lineage): a stable start/end HTML comment marker pair so a
// later phase can splice this block into a PR body without re-deriving it.
export const SPLICE_START = "<!-- phase231-window-dispositions:start -->";
export const SPLICE_END = "<!-- phase231-window-dispositions:end -->";

// Specifics: "the maintainer's actual question ... is 'can I ship this SHA,
// and what is still unproven?'" -- lead with what the maintainer must
// accept (waived), then anything that failed on the merits, then anything
// skipped/advisory/not-run, and collapse proved-fixed rows last. Every row
// lands in exactly the first bucket whose predicate matches, so the buckets
// partition the row set completely regardless of which combinations of
// disposition/state actually occur.
//
// CR-01 note: ROW_DISPOSITIONS is the closed set {fixed, waived}, and
// validateWindowRow/assertFixedRowsProved now reject any non-waived row
// whose state isn't "proved". That makes the "failed" and "not_run"
// branches below unreachable for any row that has actually passed
// validation -- the only rows CR-01 permits are {disposition: "fixed",
// state: "proved"} and {disposition: "waived", state: anything}, and a
// waived row always short-circuits to the "waived" bucket regardless of its
// state. These branches are kept as defensive-only fail-safety (never
// deleted) in case a caller ever renders an unvalidated record directly;
// see the deferred item in 260916-gda-SUMMARY.md about whether waived rows
// should instead bucket by their own state so a maintainer can distinguish
// a waived-but-failed row from a waived-but-merely-skipped one.
function bucketOf(row) {
  if (row.disposition === "waived") return "waived";
  if (row.state === "failed") return "failed";
  if (row.state === "skipped" || row.state === "advisory" || row.state === "non_run") return "not_run";
  return "fixed";
}

const BUCKETS = [
  { key: "waived", title: "Waived (maintainer must accept)" },
  { key: "failed", title: "Failed on the merits" },
  { key: "not_run", title: "Skipped, advisory, or not run" },
  { key: "fixed", title: "Fixed (proved at the candidate SHA)" }
];

const ROW_HEADING = [
  "| Id | Phase | Kind | Disposition | State | Exit code | Owner | Rationale | Release impact | Current evidence |",
  "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"
];

function rowLine(row) {
  return `| ${row.id} | ${escape(row.phase)} | ${escape(row.kind)} | ${escape(row.disposition)} | ${escape(row.state)} | ${Object.hasOwn(row, "exit_code") && row.exit_code !== null && row.exit_code !== undefined ? row.exit_code : "\u2014"} | ${escape(row.owner)} | ${escape(row.rationale)} | ${escape(row.release_impact)} | ${escape(row.current_evidence)} |`;
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
  }

  const grouped = new Map(BUCKETS.map((bucket) => [bucket.key, []]));
  for (const row of value.rows) grouped.get(bucketOf(row)).push(row);
  for (const rows of grouped.values()) rows.sort((left, right) => left.id - right.id);

  const sections = BUCKETS.flatMap(({ key, title }) => {
    const rows = grouped.get(key);
    return [
      `## ${title}`, "",
      rows.length ? `${rows.length} row(s).` : "0 rows in this section.", "",
      ...(rows.length ? [...ROW_HEADING, ...rows.map(rowLine)] : []),
      ""
    ];
  });

  return [
    "# Ship-Window Dispositions", "",
    "Sanitized schema-v1 evidence answering \"can I ship this SHA, and what is still unproven?\" for every non-open row in `.planning/WINDOWS.md`, joined 1:1 by row id. This is a deterministic projection: no raw payloads, actor identities, secret values, or absolute paths are present.", "",
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

const fail = (message) => { throw new Error(message); };
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
if (!process.env.NODE_TEST_CONTEXT && isMainModule(import.meta.url)) {
  try { main(); } catch (error) { console.error(`window dispositions render: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && isMainModule(import.meta.url)) {
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
      { id: 3, phase: "220", kind: "unrun-verify", disposition: "waived", state: "proved", owner: "m", rationale: "r", release_impact: "i", current_evidence: "the gate passed anyway, a ledger/reality mismatch" },
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
    assert.match(rendered, /row-join strict check applies only to the current phase/);
    assert.match(rendered, /historical records verify schema and determinism only/);
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
