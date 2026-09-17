#!/usr/bin/env node
import fs from "node:fs";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { validateGate01Evidence, COHORT_STATES } from "./collect_gate01_cohort.mjs";

// D-31: a stable start/end HTML comment marker pair so this evidence can be
// spliced into a larger document without re-deriving the content.
export const SPLICE_START = "<!-- phase231-gate01-cohort:start -->";
export const SPLICE_END = "<!-- phase231-gate01-cohort:end -->";

const escape = (value) => String(value).replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");
const HEADINGS = ["| Job | Lane class | State | Exit code | Argv | Reason | Deferred to | Duration (ms) |", "| --- | --- | --- | --- | --- | --- | --- | --- |"];

function rowLine(row) {
  const argv = Array.isArray(row.argv) ? `\`${escape(row.argv.join(" "))}\`` : "\u2014";
  return `| ${escape(row.job)} | ${escape(row.lane_class)} | ${escape(row.state)} | ${Number.isInteger(row.exit_code) ? row.exit_code : "\u2014"} | ${argv} | ${escape(row.reason ?? "\u2014")} | ${escape(row.deferred_to ?? "\u2014")} | ${Number.isInteger(row.duration_ms) ? row.duration_ms : "\u2014"} |`;
}

function section(title, rows) {
  const body = rows.length ? rows.map(rowLine) : ["| (none) | \u2014 | \u2014 | \u2014 | \u2014 | \u2014 | \u2014 | \u2014 |"];
  return ["## " + title, "", `${rows.length} row(s).`, "", ...HEADINGS, ...body, ""];
}

// D-31: pure -- no wall-clock or filesystem call. Buckets rows `failed` first
// (what a maintainer needs to see immediately), then `skipped`/`non_run`/
// `advisory` (what did not run and why), and collapses `proved` last (what
// this repository's own gates already confirm). Every bucket heading renders
// even at zero rows, so an empty bucket is a visible fact, not an omission.
export function renderGate01Cohort(record) {
  const value = validateGate01Evidence(record, { expectedRepository: record.repository });
  const byState = new Map([...COHORT_STATES].map((state) => [state, []]));
  for (const row of value.rows) byState.get(row.state).push(row);
  for (const rows of byState.values()) rows.sort((left, right) => left.job.localeCompare(right.job));

  return [
    "# GATE-01 Cohort Evidence", "",
    "Sanitized schema-v1 evidence proving the repository's own declared merge-blocking cohort ran (or was honestly dispositioned) in a fresh, cache-free clone at the exact candidate SHA. No raw payloads, actor identities, secret values, or absolute paths are present.", "",
    SPLICE_START, "",
    `Candidate: \`${value.candidate_object}\` (observed ${value.observed_at}). Checkout: \`${value.checkout.method}\` from \`${value.checkout.source}\`, caches_restored=${value.checkout.caches_restored}, worktree_rows_delta=${value.checkout.worktree_rows_delta}.`, "",
    ...section("Failed", byState.get("failed")),
    ...section("Skipped", byState.get("skipped")),
    ...section("Non-run", byState.get("non_run")),
    ...section("Advisory", byState.get("advisory")),
    ...section("Proved", byState.get("proved")),
    SPLICE_END, ""
  ].join("\n");
}

function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--") || argv[index + 1] === undefined) throw new Error("usage: --records FILE --out FILE");
    result[argv[index].slice(2)] = argv[++index];
  }
  return result;
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!options.records || !options.out) throw new Error("--records and --out are required");
  const record = JSON.parse(fs.readFileSync(options.records, "utf8"));
  fs.writeFileSync(options.out, renderGate01Cohort(record));
}

// D-29 Rule 1: isMainModule() throws (never returns a silent false) when there
// is no invoking entrypoint -- e.g. a dynamic `import()` from a `node -e`
// inline-eval script, which has no argv[1]. That throw must not crash a bare
// import of this module, so it is caught here and treated as "not the
// entrypoint", matching the established pattern in
// collect_window_dispositions.mjs and verify_window_dispositions.mjs.
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}

if (!process.env.NODE_TEST_CONTEXT && invokedAsEntrypoint) {
  try { main(); } catch (error) { console.error(`gate01 cohort render: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && invokedAsEntrypoint) {
  function provedRow(job, overrides = {}) { return { job, lane_class: "merge-blocking", state: "proved", exit_code: 0, argv: ["true"], ...overrides }; }
  function nonRunRow(job, overrides = {}) { return { job, lane_class: "not-a-declared-gate", state: "non_run", reason: "fixture reason", ...overrides }; }
  function minimalRecord(rows = [], overrides = {}) {
    return {
      schema_version: 1,
      repository: "szTheory/accrue",
      candidate_object: "a".repeat(40),
      observed_at: "2026-09-15T00:00:00+00:00",
      checkout: { method: "git clone", source: "local repository", caches_restored: false, worktree_rows_delta: 0 },
      rows,
      ...overrides
    };
  }

  test("renderGate01Cohort is deterministic across repeated calls on the same record", () => {
    const record = minimalRecord([provedRow("job-a"), nonRunRow("job-b")]);
    const first = renderGate01Cohort(record);
    const second = renderGate01Cohort(record);
    assert.equal(first, second);
  });

  test("renders every bucket heading even at zero rows", () => {
    const rendered = renderGate01Cohort(minimalRecord([]));
    for (const title of ["Failed", "Skipped", "Non-run", "Advisory", "Proved"]) {
      assert.match(rendered, new RegExp(`## ${title}[\\s\\S]*?0 row\\(s\\)\\.`));
    }
  });

  test("fences the rendered evidence with the stable phase231-gate01-cohort splice marker pair", () => {
    const rendered = renderGate01Cohort(minimalRecord([]));
    assert.match(rendered, /<!-- phase231-gate01-cohort:start -->/);
    assert.match(rendered, /<!-- phase231-gate01-cohort:end -->/);
    assert.ok(rendered.indexOf(SPLICE_START) < rendered.indexOf(SPLICE_END));
  });

  test("Failed section precedes Skipped/Non-run and Proved is collapsed last", () => {
    const rendered = renderGate01Cohort(minimalRecord([]));
    const headings = rendered.split("\n").filter((line) => line.startsWith("## "));
    assert.deepEqual(headings, ["## Failed", "## Skipped", "## Non-run", "## Advisory", "## Proved"]);
  });

  test("re-rendering after shuffling row order produces identical output", () => {
    const rows = [provedRow("z"), provedRow("a"), nonRunRow("m")];
    const forward = minimalRecord(rows);
    const shuffled = minimalRecord([...rows].reverse());
    assert.equal(renderGate01Cohort(forward), renderGate01Cohort(shuffled));
  });

  test("rejects rendering an invalid record", () => {
    assert.throws(() => renderGate01Cohort({ schema_version: 2 }), /unsupported schema version|missing required field/);
  });
}
