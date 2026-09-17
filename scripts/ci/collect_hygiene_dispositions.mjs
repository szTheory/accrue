#!/usr/bin/env node
// HYG-01 (D-45): the pre-cleanup classification triad. Ships the maintainer's
// no-deletion decision (D-47) as a structural schema invariant rather than an
// intention: a remote_branch row can only ever be retained or superseded,
// and can only ever declare that no authorization is required, so this
// module has no way to express "delete a remote branch."
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { resolvePhaseEvidencePath, repositoryRoot } from "./phase_evidence_path.mjs";
// Single source of truth for path sanitization -- imported, not re-declared,
// so this file cannot drift from the canonical pattern (HYG-01 prohibition:
// "do not mint a third path-sanitization pattern").
import { UNSAFE_PATH_PATTERN } from "./collect_window_dispositions.mjs";

// NUL row-key separator, built at runtime so no raw NUL byte ever lands in this
// source file (a literal NUL makes git classify the file as binary).
const ROW_KEY_SEP = String.fromCharCode(0);

const SHA = /^[a-f0-9]{40}$/;
const REPOSITORY = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const ISO = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/;
const SHA256 = /^[a-f0-9]{64}$/;

// D-45/HYG-01: the four categories the requirement names -- untracked path,
// worktree, debug session, remote branch. No fifth kind; a classifier that
// invents a new kind rather than fitting one of these four is out of scope.
export const ROW_KINDS = new Set(["untracked_path", "worktree", "debug_session", "remote_branch"]);
// D-45: the closed disposition vocabulary the requirement names. "parked" is
// a CI-lane presentation label from plan 232-06's window-disposition
// machinery and must never appear here -- it is not a member of this set.
export const ROW_DISPOSITIONS = new Set(["retained", "committed", "archived", "superseded", "authorized_for_removal"]);
// D-46: dispositions under which a row may legitimately outlive the item it
// names -- the item can disappear from a later live re-enumeration (because
// cleanup eventually acts on it) without that disappearance being a
// soundness failure. "retained" and "committed" are NOT terminal: a row
// under either disposition asserts the item should still be present.
export const TERMINAL_DISPOSITIONS = new Set(["archived", "superseded", "authorized_for_removal"]);

export const HYGIENE_ROW_FIELDS = new Set([
  "kind", "name", "disposition", "reason", "content_hash", "supersedes_or_duplicates", "authorization_required"
]);
export const DISPOSITION_FIELDS = new Set(["schema_version", "repository", "candidate_object", "observed_at", "evidence_command", "rows"]);

const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase SHA`); return value; }
function repository(value, label) { if (typeof value !== "string" || !REPOSITORY.test(value)) fail(`${label} must be an owner/repository string`); return value; }
function timestamp(value, label) { if (typeof value !== "string" || !ISO.test(value)) fail(`${label} must be an ISO-8601 timestamp with a UTC offset`); return value; }
export function run(repo, args) { const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 }); if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`); return result.stdout.trim(); }

// D-31 provenance: sanitization here is the SAME pattern object as the
// window-disposition triad's, imported at the top of this file --
// `UNSAFE_PATH_PATTERN` from collect_window_dispositions.mjs. It is the
// broader of the two pre-existing sanitization patterns in this repo, chosen
// per 232-PATTERNS.md because it also catches a bare leading "/", which a
// hygiene classifier enumerating filesystem paths is more likely to emit
// than either prior triad.
//
// History worth keeping, because the failure mode is instructive: plan
// 232-07 originally COPIED this regex's text under a name deliberately
// chosen to fall outside the `PATTERN`/`_RE` suffix convention, so that its
// own census grep would keep reporting exactly two sanitization patterns
// while a third one in fact existed. That is gaming a check rather than
// satisfying it. It was corrected later in the phase by exporting the
// canonical constant and importing it here -- one pattern, one definition,
// and a census that now tells the truth because there is nothing to hide
// from it. See 232-07-SUMMARY.md, "Deviations".

function sanitizeStrings(row, label) {
  for (const [key, value] of Object.entries(row)) {
    if (typeof value === "string" && UNSAFE_PATH_PATTERN.test(value)) fail(`${label}.${key} must not contain an absolute path or home-directory reference`);
  }
}

// D-47: the structural, unrepresentable-by-construction invariant. Runs
// BEFORE the generic required-field completeness check below so that even a
// malformed/incomplete remote_branch row naming a forbidden disposition is
// rejected with a message stating the actual rule, never a generic
// missing-field message that would obscure why the row was rejected.
export function validateHygieneRow(row, label) {
  fields(row, HYGIENE_ROW_FIELDS, label);

  if (!Object.hasOwn(row, "kind")) fail(`${label} is missing required field: kind`);
  if (typeof row.kind !== "string" || !ROW_KINDS.has(row.kind)) fail(`${label}.kind must be one of the closed row-kind enumeration (untracked_path/worktree/debug_session/remote_branch), got: ${row.kind}`);

  if (!Object.hasOwn(row, "disposition")) fail(`${label} is missing required field: disposition`);
  if (typeof row.disposition !== "string" || !ROW_DISPOSITIONS.has(row.disposition)) fail(`${label}.disposition must be one of the closed row-disposition enumeration (retained/committed/archived/superseded/authorized_for_removal), got: ${row.disposition}`);

  if (row.kind === "remote_branch") {
    if (!["retained", "superseded"].includes(row.disposition)) {
      fail(`${label} (remote_branch "${row.name ?? "?"}"): disposition must be "retained" or "superseded" -- this verifier cannot express branch deletion, got: "${row.disposition}"`);
    }
    if (row.authorization_required !== false) {
      fail(`${label} (remote_branch "${row.name ?? "?"}"): authorization_required must be the boolean false -- this verifier cannot express branch deletion`);
    }
  } else if (Object.hasOwn(row, "authorization_required")) {
    fail(`${label}.authorization_required is only a valid field on remote_branch rows`);
  }

  for (const key of ["name", "reason"]) {
    if (!Object.hasOwn(row, key)) fail(`${label} is missing required field: ${key}`);
  }
  if (typeof row.name !== "string" || !row.name.trim()) fail(`${label}.name must be a non-empty string`);
  if (typeof row.reason !== "string" || !row.reason.trim()) fail(`${label}.reason must be a non-empty string`);

  // Evidence requirement: a row claiming authorized_for_removal cannot be
  // asserted without a recorded content hash and a pointer to what
  // supersedes or duplicates it.
  if (row.disposition === "authorized_for_removal") {
    if (typeof row.content_hash !== "string" || !SHA256.test(row.content_hash)) fail(`${label} disposition "authorized_for_removal" requires a recorded 64-hex-character sha256 content_hash`);
    if (typeof row.supersedes_or_duplicates !== "string" || !row.supersedes_or_duplicates.trim()) fail(`${label} disposition "authorized_for_removal" requires a non-empty supersedes_or_duplicates pointer`);
  }
  if (Object.hasOwn(row, "content_hash") && row.content_hash !== undefined && !SHA256.test(row.content_hash)) fail(`${label}.content_hash must be a 64-hex-character sha256 string`);

  sanitizeStrings(row, label);
  return row;
}

export function validateHygieneDispositions(record) {
  fields(record, DISPOSITION_FIELDS, "disposition");
  for (const key of DISPOSITION_FIELDS) if (!(key in record)) fail(`disposition is missing required field: ${key}`);
  if (record.schema_version !== 1) fail("disposition has unsupported schema version");
  repository(record.repository, "disposition.repository");
  fullSha(record.candidate_object, "disposition.candidate_object");
  timestamp(record.observed_at, "disposition.observed_at");
  if (!Array.isArray(record.evidence_command) || !record.evidence_command.length || record.evidence_command.some((element) => typeof element !== "string")) {
    fail("disposition.evidence_command must be a non-empty argv array of strings");
  }
  if (!Array.isArray(record.rows)) fail("disposition.rows must be an array");
  record.rows.forEach((row, index) => validateHygieneRow(row, `rows[${index}]`));
  const seen = new Set();
  for (const row of record.rows) {
    const key = `${row.kind}${ROW_KEY_SEP}${row.name}`;
    if (seen.has(key)) fail(`disposition.rows contains a duplicate (kind, name): ${row.kind}/${row.name}`);
    seen.add(key);
  }
  return record;
}

export function collectHygieneDispositions({ repo, expectedRepository, candidate, inputRows, evidenceCommand }) {
  repository(expectedRepository, "expectedRepository");
  const candidateObject = fullSha(run(repo, ["rev-parse", `${candidate}^{commit}`]), "candidate object");
  // D-31 (231 lineage): observed_at comes from the candidate's own committer
  // date, never Date.now() -- so re-running the collector against the same
  // candidate produces byte-identical output.
  const observedAt = timestamp(run(repo, ["show", "-s", "--format=%cI", candidateObject]), "observed_at");
  const rows = (inputRows || []).map((row, index) => validateHygieneRow({ ...row }, `rows[${index}]`));
  // Deterministic sort: (kind, name) composite key, so rows that compare
  // equal on their primary key are emitted in a specified, stable order.
  rows.sort((left, right) => (left.kind === right.kind ? left.name.localeCompare(right.name) : left.kind.localeCompare(right.kind)));
  const record = {
    schema_version: 1,
    repository: expectedRepository,
    candidate_object: candidateObject,
    observed_at: observedAt,
    evidence_command: evidenceCommand && evidenceCommand.length ? evidenceCommand : ["git", "status", "--porcelain", "-uall"],
    rows
  };
  return validateHygieneDispositions(record);
}

const PHASE_SLUG = "232-bounded-hygiene-release-handoff";
const JSON_ARTIFACT = "232-HYGIENE-DISPOSITIONS.json";
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
  const record = collectHygieneDispositions({
    repo: options.repo,
    expectedRepository: options["expected-repository"],
    candidate: options.candidate,
    inputRows
  });
  const out = options.out || defaultOutPath();
  fs.writeFileSync(out, `${JSON.stringify(record, null, 2)}\n`, { mode: 0o600 });
}

// isMainModule() throws (never returns a silent false) when there is no
// invoking entrypoint; that throw must not crash a bare import, so it is
// caught and treated as "not the entrypoint" (established pattern, 232-01).
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (!process.env.NODE_TEST_CONTEXT && invokedAsEntrypoint) {
  try { main(); } catch (error) { console.error(`hygiene dispositions collect: FAIL: ${error.message}`); process.exitCode = 1; }
}

if (process.env.NODE_TEST_CONTEXT && invokedAsEntrypoint) {
  function fixtureRepo() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase232-hygiene-collect-fixture-"));
    const repo = path.join(scratch, "repo");
    fs.mkdirSync(repo);
    const g = (args) => run(repo, args);
    g(["init", "-q", "-b", "main"]);
    g(["config", "user.email", "phase232@example.invalid"]);
    g(["config", "user.name", "Phase 232"]);
    fs.writeFileSync(path.join(repo, "base.txt"), "base\n"); g(["add", "base.txt"]); g(["commit", "-qm", "base"]);
    const candidate = g(["rev-parse", "HEAD"]);
    return { scratch, repo, candidate };
  }
  function withFixture(fn) {
    const fx = fixtureRepo();
    try { fn(fx); } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  }
  function untrackedRow(overrides = {}) {
    return { kind: "untracked_path", name: ".tool-versions", disposition: "committed", reason: "already tracked on the candidate branch; reversal of a prior never-tracked intent", ...overrides };
  }
  function removalRow(overrides = {}) {
    return {
      kind: "untracked_path", name: "shadow.md", disposition: "authorized_for_removal",
      reason: "degraded duplicate of a committed archive copy",
      content_hash: "a".repeat(64), supersedes_or_duplicates: "the committed archive copy",
      ...overrides
    };
  }
  function branchRow(overrides = {}) {
    return { kind: "remote_branch", name: "origin/main", disposition: "retained", reason: "primary trunk", authorization_required: false, ...overrides };
  }

  // Behavior: a remote-branch row with any disposition other than retained
  // or superseded is rejected with a message stating that this verifier
  // cannot express branch deletion.
  test("validateHygieneRow rejects a remote_branch row whose disposition is not retained or superseded", () => {
    assert.throws(() => validateHygieneRow(branchRow({ disposition: "authorized_for_removal" }), "row"), /cannot express branch deletion/);
    assert.throws(() => validateHygieneRow(branchRow({ disposition: "archived" }), "row"), /cannot express branch deletion/);
    assert.throws(() => validateHygieneRow(branchRow({ disposition: "committed" }), "row"), /cannot express branch deletion/);
  });

  // Behavior: a remote-branch row declaring that authorization is required
  // is rejected.
  test("validateHygieneRow rejects a remote_branch row declaring authorization_required true", () => {
    assert.throws(() => validateHygieneRow(branchRow({ authorization_required: true }), "row"), /cannot express branch deletion/);
  });

  test("validateHygieneRow rejects an authorization_required field on a non-remote_branch row", () => {
    assert.throws(() => validateHygieneRow({ ...untrackedRow(), authorization_required: false }, "row"), /only a valid field on remote_branch rows/);
  });

  // Behavior: a row claiming authorized-for-removal without a recorded
  // content hash, or without a supersedes or duplicates pointer, is
  // rejected.
  test("validateHygieneRow rejects an authorized_for_removal row missing content_hash or supersedes_or_duplicates", () => {
    const noHash = removalRow(); delete noHash.content_hash;
    assert.throws(() => validateHygieneRow(noHash, "row"), /requires a recorded 64-hex-character sha256 content_hash/);
    const noPointer = removalRow(); delete noPointer.supersedes_or_duplicates;
    assert.throws(() => validateHygieneRow(noPointer, "row"), /requires a non-empty supersedes_or_duplicates pointer/);
    const badHash = removalRow({ content_hash: "not-a-hash" });
    assert.throws(() => validateHygieneRow(badHash, "row"), /requires a recorded 64-hex-character sha256 content_hash/);
    assert.doesNotThrow(() => validateHygieneRow(removalRow(), "row"));
  });

  // Behavior: a row carrying a field outside the allowed set is rejected by
  // name.
  test("validateHygieneRow rejects a forbidden field, naming it", () => {
    assert.throws(() => validateHygieneRow({ ...untrackedRow(), mystery_field: "x" }, "row"), /forbidden field: mystery_field/);
  });

  // Behavior: a field value containing a local filesystem path prefix is
  // rejected by the sanitization check.
  test("validateHygieneRow rejects an absolute path or home-directory reference in a string value", () => {
    assert.throws(() => validateHygieneRow(untrackedRow({ reason: "found at /Users/jon/projects/accrue/foo" }), "row"), /absolute path or home-directory reference/);
    assert.throws(() => validateHygieneRow(untrackedRow({ reason: "path at $HOME/accrue" }), "row"), /absolute path or home-directory reference/);
    assert.throws(() => validateHygieneRow(untrackedRow({ name: "/etc/passwd" }), "row"), /absolute path or home-directory reference/);
  });

  test("validateHygieneRow rejects an unknown kind or disposition", () => {
    assert.throws(() => validateHygieneRow(untrackedRow({ kind: "mystery" }), "row"), /closed row-kind enumeration/);
    assert.throws(() => validateHygieneRow(untrackedRow({ disposition: "deleted" }), "row"), /closed row-disposition enumeration/);
    assert.throws(() => validateHygieneRow(untrackedRow({ disposition: "parked" }), "row"), /closed row-disposition enumeration/);
  });

  test("validateHygieneDispositions rejects a duplicate (kind, name) pair", () => {
    withFixture((fx) => {
      assert.throws(
        () => collectHygieneDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [untrackedRow(), untrackedRow()] }),
        /duplicate \(kind, name\)/
      );
    });
  });

  test("collectHygieneDispositions sorts rows by the (kind, name) composite key regardless of input order", () => {
    withFixture((fx) => {
      const record = collectHygieneDispositions({
        repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate,
        inputRows: [branchRow({ name: "origin/zzz" }), untrackedRow({ name: ".tool-versions" }), branchRow({ name: "origin/aaa" })]
      });
      assert.deepEqual(record.rows.map((row) => `${row.kind}/${row.name}`), ["remote_branch/origin/aaa", "remote_branch/origin/zzz", "untracked_path/.tool-versions"]);
    });
  });

  test("collectHygieneDispositions sets observed_at from the candidate committer date, never the wall clock", () => {
    withFixture((fx) => {
      const expected = run(fx.repo, ["show", "-s", "--format=%cI", fx.candidate]);
      const record = collectHygieneDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [] });
      assert.equal(record.observed_at, expected);
    });
  });

  test("collectHygieneDispositions defaults evidence_command and accepts an explicit one", () => {
    withFixture((fx) => {
      const record = collectHygieneDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [] });
      assert.deepEqual(record.evidence_command, ["git", "status", "--porcelain", "-uall"]);
      const explicit = collectHygieneDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [], evidenceCommand: ["git", "worktree", "list"] });
      assert.deepEqual(explicit.evidence_command, ["git", "worktree", "list"]);
    });
  });

  test("collectHygieneDispositions emits identical bytes on two consecutive runs over the same inputs", () => {
    withFixture((fx) => {
      const first = collectHygieneDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [untrackedRow(), branchRow()] });
      const second = collectHygieneDispositions({ repo: fx.repo, expectedRepository: "szTheory/accrue", candidate: fx.candidate, inputRows: [untrackedRow(), branchRow()] });
      assert.equal(JSON.stringify(first), JSON.stringify(second));
    });
  });

  test("ROW_KINDS, ROW_DISPOSITIONS, and TERMINAL_DISPOSITIONS carry exactly their documented members", () => {
    assert.deepEqual([...ROW_KINDS].sort(), ["debug_session", "remote_branch", "untracked_path", "worktree"]);
    assert.deepEqual([...ROW_DISPOSITIONS].sort(), ["archived", "authorized_for_removal", "committed", "retained", "superseded"]);
    assert.deepEqual([...TERMINAL_DISPOSITIONS].sort(), ["archived", "authorized_for_removal", "superseded"]);
    assert.ok(!ROW_DISPOSITIONS.has("parked"), '"parked" is a CI-lane presentation label, never a schema value');
  });
}
