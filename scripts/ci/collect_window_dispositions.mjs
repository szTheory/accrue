#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { resolvePhaseEvidencePath, repositoryRoot } from "./phase_evidence_path.mjs";

const SHA = /^[a-f0-9]{40}$/;
const REPOSITORY = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const ISO = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/;

// D-29: Phase 226's proof-state lexicon. No aggregate boolean, no
// `deferred`/`n/a`/`green` alias reachable.
// D-14/D-32-04: exported so the renderer's total (disposition, state) pair
// map and the verifier's cartesian-product reachability test can enumerate
// the same closed state set this module validates against -- neither may
// hand-transcribe a copy that could drift from this one.
export const ROW_STATES = new Set(["proved", "failed", "skipped", "advisory", "non_run"]);
const STATES = ROW_STATES;
const REJECTED_STATES = new Set(["deferred", "n/a", "green"]);

// D-22: the closed set of ship-window row kinds this triad disposes of, and
// the closed set of dispositions a row may carry. Unknown value => hard
// failure, never pass-through -- the same discipline HAZARD_CLASSES uses in
// collect_integration_disposition.mjs.
export const ROW_KINDS = new Set(["unrun-verify", "deviation"]);
export const ROW_DISPOSITIONS = new Set(["fixed", "waived"]);

export const WINDOW_ROW_FIELDS = new Set([
  "id", "phase", "kind", "disposition", "state", "exit_code",
  "owner", "rationale", "release_impact", "current_evidence",
  "evidence_command", "resolved_at"
]);
export const DISPOSITION_FIELDS = new Set(["schema_version", "repository", "candidate_object", "observed_at", "rows"]);

const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase SHA`); return value; }
function repository(value, label) { if (typeof value !== "string" || !REPOSITORY.test(value)) fail(`${label} must be an owner/repository string`); return value; }
function timestamp(value, label) { if (typeof value !== "string" || !ISO.test(value)) fail(`${label} must be an ISO-8601 timestamp with a UTC offset`); return value; }
function run(repo, args) { const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 }); if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`); return result.stdout.trim(); }

// D-31: no absolute path, $HOME reference, or /Users//home segment reaches a
// committed evidence artifact. Applied to every string leaf (including argv
// array elements) of a validated row, not just current_evidence, so a
// forbidden value in any field is caught the same way.
const UNSAFE_PATH_PATTERN = /(^\/|\/Users\/|\/home\/|\$HOME)/;
function sanitizeStrings(row, label) {
  for (const [key, value] of Object.entries(row)) {
    if (typeof value === "string" && UNSAFE_PATH_PATTERN.test(value)) fail(`${label}.${key} must not contain an absolute path or home-directory reference`);
    if (Array.isArray(value)) {
      for (const element of value) if (typeof element === "string" && UNSAFE_PATH_PATTERN.test(element)) fail(`${label}.${key} must not contain an absolute path or home-directory reference`);
    }
  }
}

export function validateWindowRow(row, label) {
  fields(row, WINDOW_ROW_FIELDS, label);
  for (const key of ["id", "phase", "kind", "disposition", "state", "current_evidence"]) {
    if (!Object.hasOwn(row, key)) fail(`${label} is missing required field: ${key}`);
  }
  if (!Number.isInteger(row.id) || row.id < 0) fail(`${label}.id must be a non-negative integer`);
  if (typeof row.phase !== "string" || !row.phase.trim()) fail(`${label}.phase must be a non-empty string`);
  if (typeof row.kind !== "string" || !ROW_KINDS.has(row.kind)) fail(`${label}.kind must be one of the closed row-kind enumeration (unrun-verify/deviation), got: ${row.kind}`);
  // D-22: "open" is explicitly not a member of ROW_DISPOSITIONS, so it is
  // already rejected by the enum membership check below -- named here so the
  // rejection reads as deliberate, not incidental.
  if (typeof row.disposition !== "string" || !ROW_DISPOSITIONS.has(row.disposition)) fail(`${label}.disposition must be one of the closed row-disposition enumeration (fixed/waived), got: ${row.disposition}`);
  if (typeof row.state !== "string" || REJECTED_STATES.has(row.state) || !STATES.has(row.state)) fail(`${label}.state must be one of proved/failed/skipped/advisory/non_run`);

  if (row.state === "proved" && (!Object.hasOwn(row, "exit_code") || row.exit_code === null || row.exit_code === undefined)) fail(`${label} state "proved" requires a recorded exit_code`);
  if (Object.hasOwn(row, "exit_code") && row.exit_code !== null && row.exit_code !== undefined) {
    if (!Number.isInteger(row.exit_code) || row.exit_code < 0 || row.exit_code > 255) fail(`${label}.exit_code must be a recorded process exit code`);
  }

  if (row.disposition === "waived") {
    for (const key of ["owner", "rationale", "release_impact"]) {
      if (typeof row[key] !== "string" || !row[key].trim()) fail(`${label} disposition "waived" requires a non-empty ${key}`);
    }
  }
  // CR-01: a row closed as "fixed" (safe to ship) must record a genuinely
  // passing re-run -- never failed/skipped/advisory/non_run. Without this, a
  // row could claim "fixed" while its own state field admits it never
  // actually passed.
  if (row.disposition === "fixed" && row.state !== "proved") {
    fail(`${label} disposition "fixed" requires state "proved" (got "${row.state}") -- a row closed as fixed must have a genuinely passing re-run, never failed/skipped/advisory/non_run`);
  }
  for (const key of ["owner", "rationale", "release_impact"]) {
    if (Object.hasOwn(row, key) && row[key] !== undefined && typeof row[key] !== "string") fail(`${label}.${key} must be a string`);
  }

  if (typeof row.current_evidence !== "string" || !row.current_evidence.trim()) fail(`${label}.current_evidence must be a non-empty string`);

  if (Object.hasOwn(row, "evidence_command") && row.evidence_command !== undefined) {
    if (!Array.isArray(row.evidence_command) || !row.evidence_command.length || row.evidence_command.some((element) => typeof element !== "string")) fail(`${label}.evidence_command must be a non-empty argv array of strings`);
  }
  if (Object.hasOwn(row, "resolved_at") && row.resolved_at !== null && row.resolved_at !== undefined) {
    if (typeof row.resolved_at !== "string" || !ISO.test(row.resolved_at)) fail(`${label}.resolved_at must be an ISO-8601 timestamp or null`);
  }

  sanitizeStrings(row, label);
  return row;
}

export function validateWindowDispositions(record) {
  fields(record, DISPOSITION_FIELDS, "disposition");
  for (const key of DISPOSITION_FIELDS) if (!(key in record)) fail(`disposition is missing required field: ${key}`);
  if (record.schema_version !== 1) fail("disposition has unsupported schema version");
  repository(record.repository, "disposition.repository");
  fullSha(record.candidate_object, "disposition.candidate_object");
  timestamp(record.observed_at, "disposition.observed_at");
  if (!Array.isArray(record.rows)) fail("disposition.rows must be an array");
  record.rows.forEach((row, index) => validateWindowRow(row, `rows[${index}]`));
  const seen = new Set();
  for (const row of record.rows) {
    if (seen.has(row.id)) fail(`disposition.rows contains duplicate id: ${row.id}`);
    seen.add(row.id);
  }
  return record;
}

// D-25: transcribed verbatim from verify_repository_inventory.mjs's
// directShipWindows (~line 523-547) -- the authoritative 10-column
// .planning/WINDOWS.md parse contract. This function returns the RICHER
// per-row object (id/phase/kind/file/line/description/status/reason/
// recorded_at/resolved_at) rather than the terse "id:status" string form,
// but relaxes none of the parser's own checks: same pinned header, same
// bounded-input guard, same 10-column requirement, same numeric-id and
// status-enum validation, same duplicate-id rejection, same four frontmatter
// count cross-checks. This is deliberately NOT a second, divergent parser --
// it is the same contract, read into a richer shape.
const WINDOWS_HEADER = "| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |";

export function readShipWindowRows(repositoryRoot) {
  const filename = path.join(repositoryRoot, ".planning/WINDOWS.md");
  const contents = fs.readFileSync(filename, "utf8");
  if (Buffer.byteLength(contents, "utf8") > 512 * 1024) fail("ship-window ledger exceeds its bounded input size");
  const count = (name) => {
    const match = new RegExp(`^${name}:\\s*(\\d+)\\s*$`, "m").exec(contents);
    if (!match) fail(`ship-window ledger is missing ${name}`);
    return Number(match[1]);
  };
  const start = contents.indexOf(WINDOWS_HEADER);
  if (start < 0) fail("ship-window ledger is malformed (header does not match the pinned 10-column contract)");
  const rows = [];
  for (const line of contents.slice(start + WINDOWS_HEADER.length).trimStart().split("\n")) {
    if (!line.startsWith("|")) break;
    const columns = line.split("|").slice(1, -1).map((item) => item.trim());
    if (columns.every((item) => /^-+$/.test(item))) continue;
    if (columns.length !== 10) fail("ship-window ledger contains an invalid row (must have exactly 10 columns)");
    const [id, phase, kind, file, lineNumber, description, status, reason, recordedAt, resolvedAt] = columns;
    if (!/^\d+$/.test(id)) fail("ship-window ledger row has a non-numeric id");
    if (!["open", "waived", "fixed"].includes(status)) fail("ship-window ledger row has an invalid status");
    rows.push({
      id: Number(id),
      phase,
      kind,
      file,
      line: lineNumber || null,
      description,
      status,
      reason: reason || "",
      recorded_at: recordedAt || null,
      resolved_at: resolvedAt || null
    });
  }
  const ids = new Set();
  for (const row of rows) { if (ids.has(row.id)) fail("ship-window ledger contains duplicate IDs"); ids.add(row.id); }
  if (
    count("total_count") !== rows.length ||
    count("open_count") !== rows.filter((row) => row.status === "open").length ||
    count("waived_count") !== rows.filter((row) => row.status === "waived").length ||
    count("fixed_count") !== rows.filter((row) => row.status === "fixed").length
  ) fail("ship-window ledger counts are inconsistent");
  return rows.sort((left, right) => left.id - right.id);
}

export function collectWindowDispositions({ repo, expectedRepository, candidate, inputRows }) {
  repository(expectedRepository, "expectedRepository");
  const candidateObject = fullSha(run(repo, ["rev-parse", `${candidate}^{commit}`]), "candidate object");
  // D-31: observed_at comes from the candidate's own committer date -- never
  // Date.now() -- so re-running the collector against the same candidate
  // produces byte-identical output.
  const observedAt = timestamp(run(repo, ["show", "-s", "--format=%cI", candidateObject]), "observed_at");
  const rows = (inputRows || []).map((row, index) => validateWindowRow({ ...row }, `rows[${index}]`));
  rows.sort((left, right) => left.id - right.id);
  const record = {
    schema_version: 1,
    repository: expectedRepository,
    candidate_object: candidateObject,
    observed_at: observedAt,
    rows
  };
  return validateWindowDispositions(record);
}

// D-32: new artifacts resolve through phase_evidence_path.mjs so they keep
// working after milestone archiving. resolvePhaseEvidencePath requires the
// target to already exist (it also searches archived milestone directories),
// so for the collector's own OUTPUT -- which does not exist until this
// script writes it -- fall back to the canonical active-phase path.
const PHASE_SLUG = "231-exact-sha-release-gate-proof";
const JSON_ARTIFACT = "231-WINDOW-DISPOSITIONS.json";
export function defaultOutPath() {
  try { return resolvePhaseEvidencePath(PHASE_SLUG, JSON_ARTIFACT); }
  catch { return path.join(repositoryRoot, ".planning", "phases", PHASE_SLUG, JSON_ARTIFACT); }
}

function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--") || !argv[index + 1]) fail("usage: --repo PATH --expected-repository OWNER/REPO --candidate REF_OR_SHA --records-in FILE [--out FILE]");
    result[argv[index].slice(2)] = argv[++index];
  }
  return result;
}
function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!options.repo || !options["expected-repository"] || !options.candidate || !options["records-in"]) fail("--repo, --expected-repository, --candidate, and --records-in are required");
  const inputRows = JSON.parse(fs.readFileSync(options["records-in"], "utf8"));
  const record = collectWindowDispositions({
    repo: options.repo,
    expectedRepository: options["expected-repository"],
    candidate: options.candidate,
    inputRows
  });
  const out = options.out || defaultOutPath();
  fs.writeFileSync(out, `${JSON.stringify(record, null, 2)}\n`, { mode: 0o600 });
}
if (!process.env.NODE_TEST_CONTEXT && isMainModule(import.meta.url)) {
  try { main(); } catch (error) { console.error(`window dispositions collect: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && isMainModule(import.meta.url)) {
  function fixtureRepo() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-window-collect-fixture-"));
    const repo = path.join(scratch, "repo");
    fs.mkdirSync(repo);
    const g = (args) => run(repo, args);
    g(["init", "-q", "-b", "main"]);
    g(["config", "user.email", "phase231@example.invalid"]);
    g(["config", "user.name", "Phase 231"]);
    fs.writeFileSync(path.join(repo, "base.txt"), "base\n"); g(["add", "base.txt"]); g(["commit", "-qm", "base"]);
    const candidate = g(["rev-parse", "HEAD"]);
    return { scratch, repo, candidate };
  }
  function withFixture(fn) {
    const fx = fixtureRepo();
    try { fn(fx); } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  }
  function validRow(overrides = {}) {
    return {
      id: 1,
      phase: "214.2",
      kind: "unrun-verify",
      disposition: "fixed",
      state: "proved",
      exit_code: 0,
      current_evidence: "the gate now runs and passes at the candidate SHA",
      ...overrides
    };
  }
  function waivedRow(overrides = {}) {
    return {
      id: 2,
      phase: "220",
      kind: "unrun-verify",
      disposition: "waived",
      state: "failed",
      owner: "maintainer",
      rationale: "the original blocker still reproduces",
      release_impact: "no user-facing regression; tracked separately",
      current_evidence: "the pre-existing failing test still fails at the candidate SHA",
      ...overrides
    };
  }

  test("validateWindowRow rejects an unknown kind", () => {
    assert.throws(() => validateWindowRow(validRow({ kind: "mystery" }), "row"), /closed row-kind enumeration/);
  });
  test("validateWindowRow rejects an unknown disposition, including the literal open", () => {
    assert.throws(() => validateWindowRow(validRow({ disposition: "open" }), "row"), /closed row-disposition enumeration/);
    assert.throws(() => validateWindowRow(validRow({ disposition: "mystery" }), "row"), /closed row-disposition enumeration/);
  });
  test("validateWindowRow rejects rejected states deferred/n_a/green and unknown states", () => {
    for (const state of ["deferred", "n/a", "green", "mystery"]) {
      assert.throws(() => validateWindowRow(validRow({ state }), "row"), /proved\/failed\/skipped\/advisory\/non_run/);
    }
  });
  test("validateWindowRow rejects disposition fixed paired with any state other than proved (CR-01)", () => {
    for (const state of ["failed", "skipped", "advisory", "non_run"]) {
      const row = validRow({ state });
      if (state !== "proved") delete row.exit_code;
      assert.throws(() => validateWindowRow(row, "row"), /disposition "fixed" requires state "proved"/);
    }
  });
  test("validateWindowRow accepts disposition fixed paired with state proved, and waived paired with failed", () => {
    assert.doesNotThrow(() => validateWindowRow(validRow({ disposition: "fixed", state: "proved", exit_code: 0 }), "row"));
    assert.doesNotThrow(() => validateWindowRow(waivedRow({ disposition: "waived", state: "failed" }), "row"));
  });
  test("validateWindowRow rejects proved without a recorded exit_code", () => {
    const row = validRow(); delete row.exit_code;
    assert.throws(() => validateWindowRow(row, "row"), /requires a recorded exit_code/);
    assert.throws(() => validateWindowRow(validRow({ exit_code: null }), "row"), /requires a recorded exit_code/);
  });
  test("validateWindowRow rejects waived rows missing owner, rationale, or release_impact", () => {
    const noOwner = waivedRow(); delete noOwner.owner;
    assert.throws(() => validateWindowRow(noOwner, "row"), /requires a non-empty owner/);
    const noRationale = waivedRow(); delete noRationale.rationale;
    assert.throws(() => validateWindowRow(noRationale, "row"), /requires a non-empty rationale/);
    const noImpact = waivedRow(); delete noImpact.release_impact;
    assert.throws(() => validateWindowRow(noImpact, "row"), /requires a non-empty release_impact/);
  });
  test("validateWindowRow rejects a forbidden field, naming it", () => {
    assert.throws(() => validateWindowRow({ ...validRow(), mystery_field: "x" }, "row"), /forbidden field: mystery_field/);
  });
  test("validateWindowRow rejects an absolute path or home-directory reference in a string value", () => {
    assert.throws(() => validateWindowRow(validRow({ current_evidence: "/Users/jon/projects/accrue/proof" }), "row"), /absolute path or home-directory reference/);
    assert.throws(() => validateWindowRow(validRow({ current_evidence: "proof at $HOME/accrue" }), "row"), /absolute path or home-directory reference/);
    assert.throws(() => validateWindowRow(waivedRow({ owner: "/home/maintainer" }), "row"), /absolute path or home-directory reference/);
  });
  test("validateWindowDispositions rejects duplicate ids", () => {
    withFixture((fx) => {
      assert.throws(() => collectWindowDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [validRow({ id: 1 }), validRow({ id: 1 })] }), /duplicate id/);
    });
  });

  test("readShipWindowRows rejects an 11-column synthetic row", () => {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-window-ledger-fixture-"));
    try {
      fs.mkdirSync(path.join(scratch, ".planning"));
      const contents = [
        "---", "schema_version: 1", "open_count: 0", "waived_count: 0", "fixed_count: 1", "total_count: 1", "last_updated: 2026-09-15T00:00:00.000Z", "---", "",
        "# Broken Windows Ledger", "",
        WINDOWS_HEADER,
        "|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|",
        "| 1 | 214 | deviation | f.ex |  | desc | fixed |  | 2026-09-15T00:00:00.000Z | extra-column |  |",
        ""
      ].join("\n");
      fs.writeFileSync(path.join(scratch, ".planning", "WINDOWS.md"), contents);
      assert.throws(() => readShipWindowRows(scratch), /exactly 10 columns/);
    } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
  });

  test("readShipWindowRows rejects a header mismatch, a duplicate id, and an inconsistent frontmatter count", () => {
    function ledgerScratch() {
      const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-window-ledger-fixture-"));
      fs.mkdirSync(path.join(scratch, ".planning"));
      return scratch;
    }
    {
      const scratch = ledgerScratch();
      try {
        fs.writeFileSync(path.join(scratch, ".planning", "WINDOWS.md"), "---\nschema_version: 1\nopen_count: 0\nwaived_count: 0\nfixed_count: 0\ntotal_count: 0\nlast_updated: 2026-09-15T00:00:00.000Z\n---\n\n# Broken Windows Ledger\n\n| id | phase | kind | file | line | description | status | reason |\n");
        assert.throws(() => readShipWindowRows(scratch), /header does not match/);
      } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
    }
    {
      const scratch = ledgerScratch();
      try {
        const contents = [
          "---", "schema_version: 1", "open_count: 0", "waived_count: 0", "fixed_count: 2", "total_count: 2", "last_updated: 2026-09-15T00:00:00.000Z", "---", "",
          "# Broken Windows Ledger", "", WINDOWS_HEADER,
          "|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|",
          "| 1 | 214 | deviation | f.ex |  | desc | fixed |  | 2026-09-15T00:00:00.000Z |  |",
          "| 1 | 215 | deviation | g.ex |  | desc2 | fixed |  | 2026-09-15T00:00:00.000Z |  |",
          ""
        ].join("\n");
        fs.writeFileSync(path.join(scratch, ".planning", "WINDOWS.md"), contents);
        assert.throws(() => readShipWindowRows(scratch), /duplicate IDs/);
      } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
    }
    {
      const scratch = ledgerScratch();
      try {
        const contents = [
          "---", "schema_version: 1", "open_count: 0", "waived_count: 0", "fixed_count: 5", "total_count: 1", "last_updated: 2026-09-15T00:00:00.000Z", "---", "",
          "# Broken Windows Ledger", "", WINDOWS_HEADER,
          "|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|",
          "| 1 | 214 | deviation | f.ex |  | desc | fixed |  | 2026-09-15T00:00:00.000Z |  |",
          ""
        ].join("\n");
        fs.writeFileSync(path.join(scratch, ".planning", "WINDOWS.md"), contents);
        assert.throws(() => readShipWindowRows(scratch), /counts are inconsistent/);
      } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
    }
  });

  test("readShipWindowRows accepts a zero-row ledger and a one-row ledger", () => {
    function ledgerScratch(contents) {
      const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase231-window-ledger-fixture-"));
      fs.mkdirSync(path.join(scratch, ".planning"));
      fs.writeFileSync(path.join(scratch, ".planning", "WINDOWS.md"), contents);
      return scratch;
    }
    const zero = ledgerScratch(["---", "schema_version: 1", "open_count: 0", "waived_count: 0", "fixed_count: 0", "total_count: 0", "last_updated: 2026-09-15T00:00:00.000Z", "---", "", "# Broken Windows Ledger", "", WINDOWS_HEADER, "|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|", ""].join("\n"));
    try { assert.deepEqual(readShipWindowRows(zero), []); } finally { fs.rmSync(zero, { recursive: true, force: true }); }

    const one = ledgerScratch([
      "---", "schema_version: 1", "open_count: 0", "waived_count: 0", "fixed_count: 1", "total_count: 1", "last_updated: 2026-09-15T00:00:00.000Z", "---", "",
      "# Broken Windows Ledger", "", WINDOWS_HEADER,
      "|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|",
      "| 1 | 214 | deviation | f.ex |  | desc | fixed |  | 2026-09-15T00:00:00.000Z |  |",
      ""
    ].join("\n"));
    try {
      const rows = readShipWindowRows(one);
      assert.equal(rows.length, 1);
      assert.equal(rows[0].id, 1);
    } finally { fs.rmSync(one, { recursive: true, force: true }); }
  });

  test("readShipWindowRows returns exactly 10 rows against the live repository ledger", () => {
    const rows = readShipWindowRows(repositoryRoot);
    assert.equal(rows.length, 10);
    assert.deepEqual(rows.map((row) => row.id), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  });

  test("collectWindowDispositions accepts the zero-row and one-row empty cases", () => {
    withFixture((fx) => {
      const empty = collectWindowDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [] });
      assert.deepEqual(empty.rows, []);
      const one = collectWindowDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [validRow()] });
      assert.equal(one.rows.length, 1);
    });
  });

  test("collectWindowDispositions sorts rows ascending by numeric id regardless of input order", () => {
    withFixture((fx) => {
      const record = collectWindowDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [validRow({ id: 5 }), validRow({ id: 1 }), waivedRow({ id: 3 })] });
      assert.deepEqual(record.rows.map((row) => row.id), [1, 3, 5]);
    });
  });

  test("collectWindowDispositions sets observed_at from the candidate committer date, never the wall clock", () => {
    withFixture((fx) => {
      const expected = run(fx.repo, ["show", "-s", "--format=%cI", fx.candidate]);
      const record = collectWindowDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [] });
      assert.equal(record.observed_at, expected);
    });
  });

  test("collectWindowDispositions emits identical bytes on two consecutive runs over the same inputs", () => {
    withFixture((fx) => {
      const first = collectWindowDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [validRow(), waivedRow()] });
      const second = collectWindowDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [validRow(), waivedRow()] });
      assert.equal(JSON.stringify(first), JSON.stringify(second));
    });
  });

  test("ROW_KINDS and ROW_DISPOSITIONS carry exactly their documented members", () => {
    assert.deepEqual([...ROW_KINDS].sort(), ["deviation", "unrun-verify"]);
    assert.deepEqual([...ROW_DISPOSITIONS].sort(), ["fixed", "waived"]);
  });

  test("ROW_STATES is exported and carries exactly the documented proof-state lexicon", () => {
    assert.deepEqual([...ROW_STATES].sort(), ["advisory", "failed", "non_run", "proved", "skipped"]);
  });
}
