#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import test from "node:test";
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
  fail("not implemented: renderWindowDispositions");
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
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  try { main(); } catch (error) { console.error(`window dispositions render: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
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

  test("renders every bucket heading even when the record has zero rows", () => {
    const rendered = renderWindowDispositions(minimalRecord());
    const headings = rendered.split("\n").filter((line) => line.startsWith("## "));
    assert.deepEqual(headings, [
      "Candidate identity",
      "Waived (maintainer must accept)",
      "Failed on the merits",
      "Skipped, advisory, or not run",
      "Fixed (proved at the candidate SHA)"
    ].map((title) => `## ${title}`));
    assert.match(rendered, /0 rows in this section\./);
  });

  test("leads with waived, then failed, then skipped/advisory/non_run, then fixed collapsed last", () => {
    const rows = [
      fixedRow({ id: 1 }),
      waivedRow({ id: 2 }),
      { id: 3, phase: "227", kind: "unrun-verify", disposition: "fixed", state: "failed", current_evidence: "failed on the merits at the candidate SHA" },
      { id: 4, phase: "217", kind: "unrun-verify", disposition: "fixed", state: "skipped", current_evidence: "credential-gated, honestly skipped" }
    ];
    const rendered = renderWindowDispositions(minimalRecord({ rows }));
    const headings = rendered.split("\n").filter((line) => line.startsWith("## ")).filter((line) => line !== "## Candidate identity");
    assert.deepEqual(headings, ["## Waived (maintainer must accept)", "## Failed on the merits", "## Skipped, advisory, or not run", "## Fixed (proved at the candidate SHA)"]);
    // row 2 (waived) must render before row 1 (fixed/proved).
    assert.ok(rendered.indexOf("| 2 |") < rendered.indexOf("| 1 |"));
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
