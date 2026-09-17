#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { validateHygieneDispositions, ROW_KINDS, ROW_DISPOSITIONS } from "./collect_hygiene_dispositions.mjs";
import { resolvePhaseEvidencePath, repositoryRoot } from "./phase_evidence_path.mjs";

const fail = (message) => { throw new Error(message); };

// Copied verbatim from render_window_dispositions.mjs -- Markdown-table
// safety for arbitrary row string content.
const escape = (value) => String(value ?? "").replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");

// D-45: one bucket per HYG-01 row kind. Buckets always render, even at zero
// rows -- an absent heading is ambiguous between "none" and "the renderer
// forgot" (232-CONTEXT.md "Specific Ideas").
const BUCKETS = [
  { key: "untracked_path", title: "Untracked paths" },
  { key: "worktree", title: "Worktrees" },
  { key: "debug_session", title: "Debug sessions" },
  { key: "remote_branch", title: "Remote branches" }
];

const ROW_HEADING = [
  "| Name | Disposition | Reason | Content hash | Supersedes / duplicates | Authorization required |",
  "| --- | --- | --- | --- | --- | --- |"
];

function optionalCell(value) {
  return value === undefined || value === null || value === "" ? "\u2014" : escape(value);
}

function rowLine(row) {
  const authorization = Object.hasOwn(row, "authorization_required") ? String(row.authorization_required) : "\u2014";
  return `| ${escape(row.name)} | ${escape(row.disposition)} | ${escape(row.reason)} | ${optionalCell(row.content_hash)} | ${optionalCell(row.supersedes_or_duplicates)} | ${authorization} |`;
}

// Pure function of the validated JSON -- no filesystem read beyond the
// object passed in, no Date.now(), no other wall-clock source. Called twice
// with the same input it returns byte-identical strings.
export function renderHygieneDispositions(record) {
  const value = validateHygieneDispositions(record);

  // Belt-and-suspenders: every row's kind/disposition must be a member of
  // the closed enumerations imported from the collector (never a locally
  // re-declared copy). This never fires through the public entrypoint
  // (validateHygieneDispositions already rejects an unknown kind/disposition
  // first) but documents, at the render layer too, exactly which enums this
  // renderer was built against.
  for (const row of value.rows) {
    if (!ROW_KINDS.has(row.kind)) fail(`row "${row.name}" has a kind outside the closed enumeration: ${row.kind}`);
    if (!ROW_DISPOSITIONS.has(row.disposition)) fail(`row "${row.name}" has a disposition outside the closed enumeration: ${row.disposition}`);
  }

  const grouped = new Map(BUCKETS.map((bucket) => [bucket.key, []]));
  for (const row of value.rows) {
    if (!grouped.has(row.kind)) fail(`row "${row.name}" has a kind with no declared bucket: ${row.kind}`);
    grouped.get(row.kind).push(row);
  }
  // Stable order: sort within each bucket by name so rows that compare
  // equal on their primary key are emitted in a specified, stable order.
  for (const rows of grouped.values()) rows.sort((left, right) => left.name.localeCompare(right.name));

  const sections = BUCKETS.flatMap(({ key, title }) => {
    const rows = grouped.get(key);
    return [
      `## ${title}`, "",
      rows.length ? `${rows.length} row(s).` : "0 row(s).", "",
      ...(rows.length ? [...ROW_HEADING, ...rows.map(rowLine)] : []),
      ""
    ];
  });

  return [
    "# Hygiene Dispositions", "",
    "Sanitized schema-v1 evidence classifying every untracked path, every worktree, every debug session, and every remote maintenance or release branch as retained, committed, archived, superseded, or authorized for removal, before any cleanup touches the repository. No raw payloads, actor identities, secret values, or absolute paths are present.", "",
    "This document is a deterministic re-render (a projection) of the schema-v1 JSON record identified below; the JSON is the evidence of record, and this Markdown is generated from it, never edited directly.", "",
    "A `remote_branch` row can only ever carry disposition `retained` or `superseded` and can only ever declare `authorization_required: false` -- this verifier cannot express branch deletion, and no row may express deletion of a remote branch or a tag; the no-deletion decision is a structural invariant, not an intention (D-47).", "",
    "## Candidate identity", "",
    `Candidate object: \`${value.candidate_object}\`. Observed at: ${escape(value.observed_at)}. Rows: **${value.rows.length}**.`, "",
    `Evidence command: \`${value.evidence_command.join(" ")}\``, "",
    ...sections,
    ""
  ].join("\n");
}

const PHASE_SLUG = "232-bounded-hygiene-release-handoff";
const JSON_ARTIFACT = "232-HYGIENE-DISPOSITIONS.json";
const MD_ARTIFACT = "232-HYGIENE-DISPOSITIONS.md";
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
  const rendered = renderHygieneDispositions(record);
  fs.writeFileSync(outPath, rendered, { mode: 0o600 });
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (!process.env.NODE_TEST_CONTEXT && invokedAsEntrypoint) {
  try { main(); } catch (error) { console.error(`hygiene dispositions render: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && invokedAsEntrypoint) {
  function minimalRecord(overrides = {}) {
    return {
      schema_version: 1,
      repository: "szTheory/accrue",
      candidate_object: "a".repeat(40),
      observed_at: "2026-09-16T00:00:00+00:00",
      evidence_command: ["git", "status", "--porcelain", "-uall"],
      rows: [],
      ...overrides
    };
  }
  function untrackedRow(overrides = {}) {
    return { kind: "untracked_path", name: ".tool-versions", disposition: "committed", reason: "already tracked on the candidate branch", ...overrides };
  }
  function removalRow(overrides = {}) {
    return {
      kind: "untracked_path", name: "shadow.md", disposition: "authorized_for_removal",
      reason: "degraded duplicate of a committed archive copy",
      content_hash: "a".repeat(64), supersedes_or_duplicates: "the committed archive copy",
      ...overrides
    };
  }
  function worktreeRow(overrides = {}) {
    return { kind: "worktree", name: "primary", disposition: "retained", reason: "single clean worktree; the repository itself", ...overrides };
  }
  function debugSessionRow(overrides = {}) {
    return { kind: "debug_session", name: "tampered-review", disposition: "retained", reason: "local-only negative-control test artifact; must stay local", ...overrides };
  }
  function branchRow(overrides = {}) {
    return { kind: "remote_branch", name: "origin/main", disposition: "retained", reason: "primary trunk", authorization_required: false, ...overrides };
  }

  // Behavior: rendering a record with zero rows in a bucket emits that
  // bucket's heading and an explicit zero-row line.
  test("renders every bucket heading with an explicit zero-row line when the record has zero rows", () => {
    const rendered = renderHygieneDispositions(minimalRecord());
    const headings = rendered.split("\n").filter((line) => line.startsWith("## ")).filter((line) => line !== "## Candidate identity");
    assert.deepEqual(headings, ["Untracked paths", "Worktrees", "Debug sessions", "Remote branches"].map((title) => `## ${title}`));
    assert.match(rendered, /0 row\(s\)\./);
  });

  // Behavior: rendering the same record twice produces byte-identical
  // output.
  test("rendering the same record twice produces byte-identical output", () => {
    const record = minimalRecord({ rows: [untrackedRow(), removalRow(), worktreeRow(), debugSessionRow(), branchRow()] });
    const first = renderHygieneDispositions(record);
    const second = renderHygieneDispositions(record);
    assert.equal(first, second);
  });

  test("a fixture with three empty buckets still emits all four bucket headings", () => {
    const rendered = renderHygieneDispositions(minimalRecord({ rows: [untrackedRow()] }));
    const headings = rendered.split("\n").filter((line) => line.startsWith("## ")).filter((line) => line !== "## Candidate identity");
    assert.deepEqual(headings, ["Untracked paths", "Worktrees", "Debug sessions", "Remote branches"].map((title) => `## ${title}`));
    const zeroRowLines = rendered.split("\n").filter((line) => line === "0 row(s).");
    assert.equal(zeroRowLines.length, 3);
  });

  test("shuffling row order and re-rendering produces identical output, sorted by (kind, name)", () => {
    const rows = [branchRow({ name: "origin/zzz" }), untrackedRow(), branchRow({ name: "origin/aaa" })];
    const forward = minimalRecord({ rows });
    const shuffled = minimalRecord({ rows: [...rows].reverse() });
    assert.equal(renderHygieneDispositions(forward), renderHygieneDispositions(shuffled));
  });

  test("rejects rendering an invalid record", () => {
    assert.throws(() => renderHygieneDispositions({ schema_version: 2 }), /unsupported schema version|missing required field/);
  });

  test("header states the file is a deterministic projection, the JSON is the evidence of record, and states the no-deletion invariant", () => {
    const rendered = renderHygieneDispositions(minimalRecord());
    assert.match(rendered, /deterministic (re-render|projection)/);
    assert.match(rendered, /JSON is the evidence of record/);
    assert.match(rendered, /cannot express branch deletion/);
  });

  test("renders the top-level evidence_command", () => {
    const rendered = renderHygieneDispositions(minimalRecord({ evidence_command: ["git", "status", "--porcelain", "-uall"] }));
    assert.match(rendered, /git status --porcelain -uall/);
  });

  test("escapes pipe, backtick, backslash, and angle-bracket characters, and collapses embedded newlines", () => {
    const rendered = renderHygieneDispositions(minimalRecord({ rows: [untrackedRow({ reason: "a | b ` c \\ d < e\nnext line" })] }));
    assert.doesNotMatch(rendered, /a \| b ` c \\ d < e\nnext line/);
    assert.match(rendered, /a \\\| b \\` c \\\\ d \\< e next line/);
  });

  test("worktree bucket states the single-clean-worktree fact positively rather than leaving the category blank", () => {
    const rendered = renderHygieneDispositions(minimalRecord({ rows: [worktreeRow()] }));
    assert.match(rendered, /single clean worktree/);
    assert.doesNotMatch(rendered, /## Worktrees\n\n0 row\(s\)\./);
  });
}
