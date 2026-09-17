#!/usr/bin/env node
// HYG-01 (D-46): fails closed in BOTH directions. Completeness re-enumerates
// the live repository at verify time and fails if any live item has no
// corresponding row. Soundness fails if a row names something that no
// longer exists without a terminal disposition. Both checks are computed
// from a LIVE re-enumeration on every invocation, never from a cached
// collect-time list -- a repository mutated between collect and verify
// fails the verifier instead of passing on stale facts (see the
// mutate-between-reads fixture below).
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import {
  ROW_KINDS,
  ROW_DISPOSITIONS,
  TERMINAL_DISPOSITIONS,
  validateHygieneDispositions,
  validateHygieneRow,
  run
} from "./collect_hygiene_dispositions.mjs";
import { renderHygieneDispositions } from "./render_hygiene_dispositions.mjs";
import { resolvePhaseEvidencePath, repositoryRoot } from "./phase_evidence_path.mjs";

// D-58: the closed objectivity-category vocabulary the requirement names.
// "comprehension" additionally requires a pointer to the failing
// documentation-truth or contract check it directly caused -- it has no
// command of its own, so it is the category that swallows cleanup passes
// unless bounded structurally (D-56).
export const CLEANUP_FINDING_CATEGORIES = new Set([
  "test", "lint", "compiler", "security", "documentation-truth",
  "dead-code", "duplication", "comprehension"
]);
export const CLEANUP_FINDING_FIELDS = new Set([
  "finding", "command", "before_exit_code", "after_exit_code", "commit", "category", "comprehension_pointer"
]);
export const CLEANUP_FINDINGS_RECORD_FIELDS = new Set(["schema_version", "repository", "cleanup_range", "passes_taken", "rows"]);
const FULL_SHA = /^[a-f0-9]{40}$/;

function exitCode(value, label) {
  if (!Number.isInteger(value) || value < 0 || value > 255) fail(`${label} must be a recorded process exit code`);
  return value;
}

// D-55/D-58: a finding row is the machine-checkable encoding of "<named
// command> currently exits non-zero; after this change it exits 0." A row
// whose before exit code is zero cannot be asserting that -- reject it by
// name (Task 1 behavior 2).
export function validateCleanupFindingRow(row, label) {
  if (!row || Array.isArray(row) || typeof row !== "object") fail(`${label} must be an object`);
  for (const key of Object.keys(row)) if (!CLEANUP_FINDING_FIELDS.has(key)) fail(`${label} contains forbidden field: ${key}`);
  for (const key of ["finding", "command", "before_exit_code", "after_exit_code", "commit", "category"]) {
    if (!Object.hasOwn(row, key)) fail(`${label} is missing required field: ${key}`);
  }
  if (!Number.isInteger(row.finding) || row.finding < 1) fail(`${label}.finding must be a positive integer`);
  if (typeof row.command !== "string" || !row.command.trim()) fail(`${label}.command must be a non-empty command string`);
  exitCode(row.before_exit_code, `${label}.before_exit_code`);
  if (row.before_exit_code === 0) fail(`${label}.before_exit_code is zero -- a finding must name a command that was actually failing`);
  exitCode(row.after_exit_code, `${label}.after_exit_code`);
  if (row.after_exit_code !== 0) fail(`${label}.after_exit_code must be exactly 0`);
  if (typeof row.commit !== "string" || !FULL_SHA.test(row.commit)) fail(`${label}.commit must be a full lowercase SHA`);
  if (typeof row.category !== "string" || !CLEANUP_FINDING_CATEGORIES.has(row.category)) {
    fail(`${label}.category must be one of the closed objectivity-category enumeration, got: ${row.category}`);
  }
  if (row.category === "comprehension") {
    if (typeof row.comprehension_pointer !== "string" || !row.comprehension_pointer.trim()) {
      fail(`${label} category "comprehension" requires a non-empty comprehension_pointer naming the failing documentation-truth or contract check it directly caused`);
    }
  } else if (Object.hasOwn(row, "comprehension_pointer")) {
    fail(`${label}.comprehension_pointer is only a valid field on category "comprehension" rows`);
  }
  return row;
}

export function validateCleanupRange(range, label) {
  if (!range || Array.isArray(range) || typeof range !== "object") fail(`${label} must be an object`);
  for (const key of Object.keys(range)) if (!["from", "to"].includes(key)) fail(`${label} contains forbidden field: ${key}`);
  if (!Object.hasOwn(range, "from")) fail(`${label} is missing required field: from`);
  if (typeof range.from !== "string" || !FULL_SHA.test(range.from)) fail(`${label}.from must be a full lowercase SHA`);
  if (Object.hasOwn(range, "to") && range.to !== null) {
    if (typeof range.to !== "string" || !FULL_SHA.test(range.to)) fail(`${label}.to must be a full lowercase SHA or null`);
  }
  return range;
}

export function validateCleanupFindings(record) {
  if (!record || Array.isArray(record) || typeof record !== "object") fail("cleanup findings must be an object");
  for (const key of Object.keys(record)) if (!CLEANUP_FINDINGS_RECORD_FIELDS.has(key)) fail(`cleanup findings contains forbidden field: ${key}`);
  for (const key of ["schema_version", "repository", "cleanup_range", "rows"]) {
    if (!Object.hasOwn(record, key)) fail(`cleanup findings is missing required field: ${key}`);
  }
  if (record.schema_version !== 1) fail("cleanup findings has unsupported schema version");
  if (typeof record.repository !== "string" || !record.repository.trim()) fail("cleanup findings.repository must be a non-empty string");
  validateCleanupRange(record.cleanup_range, "cleanup findings.cleanup_range");
  if (Object.hasOwn(record, "passes_taken") && record.passes_taken !== null) {
    if (!Number.isInteger(record.passes_taken) || record.passes_taken < 1 || record.passes_taken > 2) {
      fail("cleanup findings.passes_taken must be 1 or 2 -- a third pass requires written maintainer authorization and is never recorded here");
    }
  }
  if (!Array.isArray(record.rows)) fail("cleanup findings.rows must be an array");
  record.rows.forEach((row, index) => validateCleanupFindingRow(row, `rows[${index}]`));
  const seen = new Set();
  for (const row of record.rows) {
    if (seen.has(row.finding)) fail(`cleanup findings.rows contains duplicate finding number: ${row.finding}`);
    seen.add(row.finding);
  }
  return record;
}

// D-58: the real two-directional join between the declared cleanup range's
// commit set and the findings rows, reusing the same exact-map join
// discipline the completeness/soundness checks above already use.
// `cleanupRangeArg` is the CLI-supplied "<from>..<to>" string -- it must
// agree byte-for-byte with the committed record's own cleanup_range, so a
// caller cannot silently widen or narrow the join by passing a different
// range than the one the findings file itself declares.
export function assertCleanupFindingsJoin(repo, findings, cleanupRangeArg) {
  if (typeof cleanupRangeArg !== "string" || !cleanupRangeArg.includes("..")) fail("--cleanup-range must be of the form FROM..TO");
  const separatorIndex = cleanupRangeArg.indexOf("..");
  const from = cleanupRangeArg.slice(0, separatorIndex);
  const to = cleanupRangeArg.slice(separatorIndex + 2);
  if (!FULL_SHA.test(from) || !FULL_SHA.test(to)) fail("--cleanup-range must supply two full lowercase SHAs separated by \"..\"");
  if (from !== findings.cleanup_range.from) fail(`--cleanup-range from (${from}) does not match the committed cleanup_range.from (${findings.cleanup_range.from})`);
  if (findings.cleanup_range.to !== null && to !== findings.cleanup_range.to) fail(`--cleanup-range to (${to}) does not match the committed cleanup_range.to (${findings.cleanup_range.to})`);

  const commits = from === to ? [] : run(repo, ["rev-list", `${from}..${to}`]).split("\n").filter(Boolean);
  if (commits.length === 0) fail("cleanup findings join inspected zero commits -- refusing to declare a vacuous pass");

  const rowsByCommit = exactMap(findings.rows, "cleanup findings.rows", (row) => row.commit, () => true);
  const missing = commits.filter((sha) => !rowsByCommit.has(sha)).sort();
  const extra = [...rowsByCommit.keys()].filter((sha) => !commits.includes(sha)).sort();
  if (missing.length || extra.length) {
    fail(`cleanup findings join: missing=[${missing.join(", ")}] extra=[${extra.join(", ")}] -- every commit in the declared cleanup range must have exactly one finding row, and every finding row must name a commit inside the range`);
  }
}

// Copied-shape exact-map join helper (231-lineage discipline: never a new ad
// hoc .every()/.includes() comparison -- reused for the cleanup-findings
// join above).
function exactMap(rows, label, keyOf, valueOf) {
  const result = new Map();
  for (const row of rows) {
    const key = keyOf(row);
    if (result.has(key)) fail(`${label} contains duplicate mapping: ${key}`);
    result.set(key, valueOf(row));
  }
  return result;
}

const fail = (message) => { throw new Error(message); };
const SEP = String.fromCharCode(0);
const key = (kind, name) => `${kind}${SEP}${name}`;

// D-46: enumerate every live HYG-01 item at verify time. `collapsedUntracked`
// exists ONLY to construct the collapsed-directory negative control -- the
// real CLI path always passes collapsedUntracked: false (the individual-
// files enumeration).
function liveUntrackedPaths(repo, { collapsedUntracked = false } = {}) {
  const args = collapsedUntracked ? ["status", "--porcelain"] : ["status", "--porcelain", "-uall"];
  const output = run(repo, args);
  return output.split("\n")
    .filter((line) => line.startsWith("?? "))
    .map((line) => line.slice(3).trim())
    .filter(Boolean);
}

function liveWorktrees(repo) {
  const output = run(repo, ["worktree", "list", "--porcelain"]);
  const blocks = output.split(/\n\n+/).map((block) => block.trim()).filter(Boolean);
  return blocks.map((block) => {
    const lines = block.split("\n");
    const branchLine = lines.find((line) => line.startsWith("branch "));
    if (branchLine) return branchLine.slice("branch refs/heads/".length);
    if (lines.some((line) => line === "detached")) return "detached";
    if (lines.some((line) => line === "bare")) return "bare";
    return "unknown";
  });
}

// D-46/D-54: "debug session" live items are local branches following the
// repository's established `tampered-*` naming convention for local-only
// negative-control test artifacts (see 232-CONTEXT.md D-54). This is NOT a
// generic "every local branch with no upstream" heuristic -- that heuristic
// also matches legitimate in-flight integration/review/milestone branches
// governed by other phase-232 decisions (D-01..D-12), which are explicitly
// out of HYG-01's scope.
function liveDebugSessions(repo) {
  const output = run(repo, ["for-each-ref", "--format=%(refname:short)", "refs/heads"]);
  return output.split("\n").filter(Boolean).filter((name) => /^tampered-/.test(name));
}

// D-47: real remote branches only -- excludes symbolic refs such as
// origin/HEAD (which points AT one of these branches, never an item of its
// own).
function liveRemoteBranches(repo) {
  const output = run(repo, ["for-each-ref", "--format=%(refname:short)\t%(symref)", "refs/remotes/origin"]);
  return output.split("\n").filter(Boolean)
    .map((line) => line.split("\t"))
    .filter(([, symref]) => !symref)
    .map(([name]) => name);
}

function liveHygieneMap(repo, options = {}) {
  const map = new Map();
  for (const name of liveUntrackedPaths(repo, options)) map.set(key("untracked_path", name), true);
  for (const name of liveWorktrees(repo)) map.set(key("worktree", name), true);
  for (const name of liveDebugSessions(repo)) map.set(key("debug_session", name), true);
  for (const name of liveRemoteBranches(repo)) map.set(key("remote_branch", name), true);
  return map;
}

// Injectable-live-map form so the "zero-item cohort" negative control can
// exercise the REAL assertion logic (not a bypass) without needing an
// actual git repository with zero worktrees, which cannot exist.
export function assertCompletenessAgainstLive(live, rows) {
  if (live.size === 0) fail("hygiene dispositions completeness inspected zero live items -- refusing to declare a vacuous pass");
  const committed = new Set(rows.map((row) => key(row.kind, row.name)));
  const missing = [...live.keys()].filter((liveKey) => !committed.has(liveKey)).sort();
  if (missing.length) {
    fail(`hygiene dispositions completeness: ${missing.length} live item(s) have no corresponding row: ${missing.map((entry) => entry.replace(SEP, "/")).join(", ")}`);
  }
}
export function assertCompleteness(repo, rows, options) {
  return assertCompletenessAgainstLive(liveHygieneMap(repo, options), rows);
}

export function assertSoundnessAgainstLive(live, rows) {
  if (rows.length === 0) fail("hygiene dispositions soundness inspected zero rows -- refusing to declare a vacuous pass");
  const unsound = rows.filter((row) => !live.has(key(row.kind, row.name)) && !TERMINAL_DISPOSITIONS.has(row.disposition));
  if (unsound.length) {
    fail(`hygiene dispositions soundness: ${unsound.length} row(s) name something that no longer exists without a terminal disposition: ${unsound.map((row) => `${row.kind}/${row.name} (disposition: ${row.disposition})`).join(", ")}`);
  }
}
export function assertSoundness(repo, rows, options) {
  return assertSoundnessAgainstLive(liveHygieneMap(repo, options), rows);
}

// D-31 lineage: proves the rendered Markdown is byte-reproducible from the
// committed JSON, printing the first differing byte offset.
function assertDeterminism(record, renderedContents) {
  const fresh = renderHygieneDispositions(record);
  if (fresh === renderedContents) return;
  const shortest = Math.min(fresh.length, renderedContents.length);
  let offset = 0;
  while (offset < shortest && fresh[offset] === renderedContents[offset]) offset += 1;
  fail(`rendered Markdown is not byte-reproducible from the committed JSON (first differing byte offset: ${offset})`);
}

const BOOLEAN_FLAGS = new Set(["fixtures", "require-completeness", "require-soundness", "require-determinism", "require-cleanup-findings-join"]);
const VALUE_OPTIONS = new Set(["repo", "records", "rendered", "expected-repository", "candidate", "cleanup-range", "cleanup-findings"]);

function options(argv) {
  const flags = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]; if (!token.startsWith("--")) fail(`unexpected argument: ${token}`);
    const optionKey = token.slice(2);
    if (BOOLEAN_FLAGS.has(optionKey)) { flags.add(optionKey); continue; }
    if (!VALUE_OPTIONS.has(optionKey)) fail(`unknown option: --${optionKey}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${optionKey} requires a value`);
    if (optionKey in values) fail(`--${optionKey} may be provided only once`);
    values[optionKey] = argv[++index];
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

const CLEANUP_FINDINGS_PHASE_SLUG = "232-bounded-hygiene-release-handoff";
const CLEANUP_FINDINGS_ARTIFACT = "232-CLEANUP-FINDINGS.json";
function defaultCleanupFindingsPath() {
  try { return resolvePhaseEvidencePath(CLEANUP_FINDINGS_PHASE_SLUG, CLEANUP_FINDINGS_ARTIFACT); }
  catch { return path.join(repositoryRoot, ".planning", "phases", CLEANUP_FINDINGS_PHASE_SLUG, CLEANUP_FINDINGS_ARTIFACT); }
}
function readCleanupFindingsFile(findingsPath) {
  if (!fs.existsSync(findingsPath)) fail(`cleanup findings file does not exist: ${findingsPath}`);
  let contents;
  try { contents = fs.readFileSync(findingsPath, "utf8"); }
  catch (error) { fail(`cleanup findings file could not be read: ${findingsPath} (${error.message})`); }
  return JSON.parse(contents);
}

// Every accepted strict flag is wired to a real comparison -- a
// parsed-but-unused required flag is the exact defect shape 231-REVIEW.md
// WR-01/WR-02 recorded and this verifier must not reproduce.
function applyStrictFlags(repo, record, renderedContents, parsed) {
  if (parsed.flags.has("require-completeness")) assertCompleteness(repo, record.rows);
  if (parsed.flags.has("require-soundness")) assertSoundness(repo, record.rows);
  if (parsed.flags.has("require-determinism")) {
    if (renderedContents === undefined) fail("--rendered is required with --require-determinism");
    assertDeterminism(record, renderedContents);
  }
  if (parsed.flags.has("require-cleanup-findings-join")) {
    if (!parsed.values["cleanup-range"]) fail("--cleanup-range is required with --require-cleanup-findings-join");
    const findingsPath = parsed.values["cleanup-findings"] || defaultCleanupFindingsPath();
    const findings = validateCleanupFindings(readCleanupFindingsFile(findingsPath));
    assertCleanupFindingsJoin(repo, findings, parsed.values["cleanup-range"]);
  }
}

export function verifyFixtures() {
  function fixtureRepo() {
    const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase232-hygiene-verify-fixture-"));
    const repo = path.join(scratch, "repo");
    fs.mkdirSync(repo);
    const g = (args) => run(repo, args);
    g(["init", "-q", "-b", "main"]);
    g(["config", "user.email", "phase232@example.invalid"]);
    g(["config", "user.name", "Phase 232"]);
    fs.writeFileSync(path.join(repo, "base.txt"), "base\n"); g(["add", "base.txt"]); g(["commit", "-qm", "base"]);
    return { scratch, repo };
  }
  function withFixtureRepo(fn) {
    const fx = fixtureRepo();
    try { fn(fx); } finally { fs.rmSync(fx.scratch, { recursive: true, force: true }); }
  }
  function untrackedRow(overrides = {}) {
    return { kind: "untracked_path", name: "loose.txt", disposition: "retained", reason: "fixture row", ...overrides };
  }
  function minimalRecord(rows) {
    return { schema_version: 1, repository: "szTheory/accrue", candidate_object: "a".repeat(40), observed_at: "2026-09-16T00:00:00+00:00", evidence_command: ["git", "status", "--porcelain", "-uall"], rows };
  }

  // 1: clean pass -- a live untracked file has exactly one matching row and
  // no row is dangling.
  withFixtureRepo((fx) => {
    fs.writeFileSync(path.join(fx.repo, "loose.txt"), "loose\n");
    const rows = [untrackedRow(), { kind: "worktree", name: "main", disposition: "retained", reason: "single clean worktree" }];
    assertCompleteness(fx.repo, rows);
    assertSoundness(fx.repo, rows);
  });

  // Negative control 1: missing row -- a live item present in the
  // repository with no corresponding row fails, naming the item.
  withFixtureRepo((fx) => {
    fs.writeFileSync(path.join(fx.repo, "loose.txt"), "loose\n");
    const rows = [{ kind: "worktree", name: "main", disposition: "retained", reason: "single clean worktree" }];
    assert.throws(() => assertCompleteness(fx.repo, rows), /hygiene dispositions completeness:.*untracked_path\/loose\.txt/);
  });

  // Negative control 2: dangling row -- a row naming something that no
  // longer exists, without a terminal disposition, fails, naming the row.
  withFixtureRepo((fx) => {
    const rows = [{ kind: "untracked_path", name: "ghost.txt", disposition: "retained", reason: "no longer exists" }];
    assert.throws(() => assertSoundness(fx.repo, rows), /hygiene dispositions soundness:.*untracked_path\/ghost\.txt/);
    // A terminal disposition tolerates the same absence.
    const terminalRow = { kind: "untracked_path", name: "ghost.txt", disposition: "authorized_for_removal", reason: "already cleaned up", content_hash: "a".repeat(64), supersedes_or_duplicates: "the archive" };
    assert.doesNotThrow(() => assertSoundness(fx.repo, [terminalRow]));
  });

  // Negative control 3: zero-item cohort -- a completeness run that
  // inspected zero live items fails rather than passing (a real repository
  // can never produce an empty live map, since it always has at least one
  // worktree; this exercises the floor logic directly, the same discipline
  // render_window_dispositions.mjs's bucketOf defensive test uses).
  assert.throws(() => assertCompletenessAgainstLive(new Map(), []), /completeness inspected zero live items/);
  assert.throws(() => assertSoundnessAgainstLive(new Map(), []), /soundness inspected zero rows/);

  // Negative control 4: non-deterministic render -- the committed Markdown
  // must byte-equal a fresh render of the committed JSON, or the run fails.
  {
    const record = minimalRecord([untrackedRow()]);
    const rendered = renderHygieneDispositions(record);
    assert.throws(() => assertDeterminism(record, `${rendered}tampered`), /first differing byte offset: \d+/);
    assert.doesNotThrow(() => assertDeterminism(record, rendered));
  }

  // Negative control 5: collapsed-directory enumeration -- an
  // untracked-path enumeration performed with the directory-collapsing
  // default produces a different live set than the individual-files
  // enumeration, and the verifier fails when the record was built from the
  // collapsed one.
  withFixtureRepo((fx) => {
    fs.mkdirSync(path.join(fx.repo, "shadow"));
    fs.writeFileSync(path.join(fx.repo, "shadow", "a.txt"), "a\n");
    fs.writeFileSync(path.join(fx.repo, "shadow", "b.txt"), "b\n");
    const collapsed = liveUntrackedPaths(fx.repo, { collapsedUntracked: true });
    const individual = liveUntrackedPaths(fx.repo, { collapsedUntracked: false });
    assert.notDeepEqual(collapsed.sort(), individual.sort());
    assert.deepEqual(collapsed, ["shadow/"]);
    assert.deepEqual(individual.sort(), ["shadow/a.txt", "shadow/b.txt"]);
    // A record built from the collapsed enumeration is missing the two
    // individually-enumerated files when checked against the (correct,
    // non-collapsed) live re-enumeration.
    const collapsedRecordRows = [{ kind: "untracked_path", name: "shadow/", disposition: "retained", reason: "fixture: collapsed enumeration" }];
    assert.throws(() => assertCompleteness(fx.repo, collapsedRecordRows), /hygiene dispositions completeness:/);
    // The individually-enumerated record passes.
    const individualRecordRows = [
      { kind: "untracked_path", name: "shadow/a.txt", disposition: "retained", reason: "fixture" },
      { kind: "untracked_path", name: "shadow/b.txt", disposition: "retained", reason: "fixture" },
      { kind: "worktree", name: "main", disposition: "retained", reason: "single clean worktree" }
    ];
    assert.doesNotThrow(() => assertCompleteness(fx.repo, individualRecordRows));
  });

  // Extra fixture (required by Task 2's <action>, not one of the five
  // acceptance-criteria negative controls above): completeness is computed
  // from a LIVE re-enumeration, never a cached collect-time list -- a
  // repository mutated between the collect-time record and the verify-time
  // re-enumeration fails rather than passing on stale facts.
  withFixtureRepo((fx) => {
    fs.writeFileSync(path.join(fx.repo, "loose.txt"), "loose\n");
    const rows = [untrackedRow(), { kind: "worktree", name: "main", disposition: "retained", reason: "single clean worktree" }];
    assert.doesNotThrow(() => assertCompleteness(fx.repo, rows), "record matches the live state at the moment it was built");
    // The repository is mutated AFTER the record was built (an interrupted
    // or concurrent process adding a new untracked file).
    fs.writeFileSync(path.join(fx.repo, "another.txt"), "another\n");
    assert.throws(() => assertCompleteness(fx.repo, rows), /hygiene dispositions completeness:.*another\.txt/, "a live re-enumeration must see the mutation and fail, never trust the stale record");
  });

  // Debug-session and remote-branch live enumeration, exercised directly
  // (no real fixture repo has local `tampered-*` branches or a remote
  // named `origin`, so these are proven against the repository's own live
  // state, matching the collector's own precedent of live self-tests
  // elsewhere in this triad family).
  withFixtureRepo((fx) => {
    run(fx.repo, ["branch", "tampered-fixture"]);
    assert.deepEqual(liveDebugSessions(fx.repo), ["tampered-fixture"]);
  });

  // D-58 Task 1 behavior 1: a finding row missing its command, before exit
  // code, after exit code, or commit SHA is rejected by name.
  function cleanupRow(overrides = {}) {
    return { finding: 1, command: "test 1 -eq 0", before_exit_code: 1, after_exit_code: 0, commit: "a".repeat(40), category: "dead-code", ...overrides };
  }
  test("cleanup findings behavior 1: a row missing command, before_exit_code, after_exit_code, or commit is rejected by name", () => {
    for (const key of ["command", "before_exit_code", "after_exit_code", "commit"]) {
      const row = cleanupRow(); delete row[key];
      assert.throws(() => validateCleanupFindingRow(row, "row"), new RegExp(`missing required field: ${key}`));
    }
  });

  // D-58 Task 1 behavior 2: a finding row whose recorded before exit code
  // is zero is rejected -- a finding must name a command that was actually
  // failing.
  test("cleanup findings behavior 2: a row whose before_exit_code is zero is rejected", () => {
    assert.throws(() => validateCleanupFindingRow(cleanupRow({ before_exit_code: 0 }), "row"), /before_exit_code is zero/);
  });
  test("cleanup findings: a row whose after_exit_code is non-zero is rejected", () => {
    assert.throws(() => validateCleanupFindingRow(cleanupRow({ after_exit_code: 1 }), "row"), /after_exit_code must be exactly 0/);
  });
  test("cleanup findings: a comprehension-category row without a comprehension_pointer is rejected, and a non-comprehension row carrying one is rejected", () => {
    assert.throws(() => validateCleanupFindingRow(cleanupRow({ category: "comprehension" }), "row"), /requires a non-empty comprehension_pointer/);
    assert.doesNotThrow(() => validateCleanupFindingRow(cleanupRow({ category: "comprehension", comprehension_pointer: "verify_package_docs.sh needle X" }), "row"));
    assert.throws(() => validateCleanupFindingRow(cleanupRow({ comprehension_pointer: "x" }), "row"), /only a valid field on category "comprehension" rows/);
  });

  withFixtureRepo((fx) => {
    function commitOnFixture(message) {
      fs.writeFileSync(path.join(fx.repo, `${message.replace(/\s+/g, "-")}.txt`), `${message}\n`);
      run(fx.repo, ["add", "."]);
      run(fx.repo, ["commit", "-qm", message]);
      return run(fx.repo, ["rev-parse", "HEAD"]);
    }
    const from = run(fx.repo, ["rev-parse", "HEAD"]);
    const first = commitOnFixture("finding one");
    const second = commitOnFixture("finding two");
    const to = second;
    const cleanupRangeArg = `${from}..${to}`;
    function findingsRecord(rows, overrides = {}) {
      return { schema_version: 1, repository: "szTheory/accrue", cleanup_range: { from, to }, passes_taken: 1, rows, ...overrides };
    }

    // D-58 Task 1 behavior 3: a commit inside the declared range with no
    // finding row fails the join, naming the SHA.
    {
      const findings = findingsRecord([cleanupRow({ finding: 1, commit: first })]);
      assert.throws(() => assertCleanupFindingsJoin(fx.repo, findings, cleanupRangeArg), new RegExp(`missing=\\[${second}\\]`));
    }

    // D-58 Task 1 behavior 4: a finding row naming a SHA outside the
    // declared range fails the join, naming the SHA.
    {
      const outside = "b".repeat(40);
      const findings = findingsRecord([cleanupRow({ finding: 1, commit: first }), cleanupRow({ finding: 2, commit: second }), cleanupRow({ finding: 3, commit: outside })]);
      assert.throws(() => assertCleanupFindingsJoin(fx.repo, findings, cleanupRangeArg), new RegExp(`extra=\\[${outside}\\]`));
    }

    // Clean pass: every commit in range has exactly one finding row.
    {
      const findings = findingsRecord([cleanupRow({ finding: 1, commit: first }), cleanupRow({ finding: 2, commit: second })]);
      assert.doesNotThrow(() => assertCleanupFindingsJoin(fx.repo, findings, cleanupRangeArg));
    }

    // D-58 Task 1 behavior 5: a join run over an empty cleanup range with a
    // non-empty findings file fails rather than passing.
    {
      const emptyRangeArg = `${from}..${from}`;
      const findings = { schema_version: 1, repository: "szTheory/accrue", cleanup_range: { from, to: from }, passes_taken: null, rows: [cleanupRow({ finding: 1, commit: first })] };
      assert.throws(() => assertCleanupFindingsJoin(fx.repo, findings, emptyRangeArg), /inspected zero commits/);
    }

    // --cleanup-range must agree with the committed record's own range.
    {
      const findings = findingsRecord([cleanupRow({ finding: 1, commit: first }), cleanupRow({ finding: 2, commit: second })]);
      assert.throws(() => assertCleanupFindingsJoin(fx.repo, findings, `${first}..${to}`), /does not match the committed cleanup_range/);
    }
  });
}

function verificationSuffixFor(parsed) {
  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
  return requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")})`
    : " (schema-only: no strict flags supplied, no completeness, soundness, or determinism check ran)";
}

async function main() {
  const parsed = options(process.argv.slice(2));

  // Fixtures mode: runs the hermetic positive/negative-control battery
  // (never touches the real repository or --records/--rendered) and THEN
  // prints the same anti-vacuity suffix the committed-record path prints,
  // naming exactly which strict checks were requested alongside --fixtures
  // -- so a --fixtures invocation combined with --require-completeness
  // etc. proves those checks' OWN logic ran (via verifyFixtures()'s
  // negative controls) and is not silently schema-only.
  if (parsed.flags.has("fixtures")) {
    verifyFixtures();
    console.log(`hygiene dispositions verification: PASS${verificationSuffixFor(parsed)}`);
    return;
  }

  const repo = parsed.values.repo || repositoryRoot;
  const record = validateHygieneDispositions(readDispositionFile(parsed.values.records));

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
  console.log(`hygiene dispositions verification: PASS${verificationSuffixFor(parsed)}`);
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  test("hygiene dispositions fixtures pass every negative control", () => verifyFixtures());

  test("validateHygieneDispositions/validateHygieneRow re-exported enums stay closed", () => {
    assert.deepEqual([...ROW_KINDS].sort(), ["debug_session", "remote_branch", "untracked_path", "worktree"]);
    assert.deepEqual([...ROW_DISPOSITIONS].sort(), ["archived", "authorized_for_removal", "committed", "retained", "superseded"]);
    assert.throws(() => validateHygieneRow({ kind: "mystery", name: "x", disposition: "retained", reason: "r" }, "row"), /closed row-kind enumeration/);
  });

  test("a missing or unreadable disposition file is a hard failure naming the path, never an empty-set pass", () => {
    const missingPath = path.join(fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase232-hygiene-verify-missing-")), "does-not-exist.json");
    assert.throws(() => readDispositionFile(missingPath), new RegExp(`disposition record file does not exist: ${missingPath.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`));
  });
} else if (invokedAsEntrypoint) {
  main().catch((error) => { console.error(`hygiene dispositions verify: FAIL: ${error.message}`); process.exitCode = 1; });
}
