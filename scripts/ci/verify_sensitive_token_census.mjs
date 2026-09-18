#!/usr/bin/env node
//
// SL-C (quick task 260917-l7v): repo-wide census of a sensitive third-party
// reference, scope-locked and ratcheted downward only.
//
// WHY THIS REPLACES THE OLD CHECK. The prior guard was a per-file assertion
// of the shape `grep -c <token> <one file> -> 0`. It measured one file and
// reported on the repository. The true footprint was found by accident
// during a verification pass, not by the gate -- and that same verification
// pass then wrote more occurrences while documenting the exposure. A gate
// that under-measures its own subject is the "count-for-coverage" vacuity
// disguise: honest about its result, wrong about what the result is about.
//
// MAINTAINER DECISION, recorded: merge as-is, do NOT scrub. The reference is
// already public via a merged pull request and a live remote branch ref.
// Neither is reachable by editing files, so scrubbing the working tree would
// be theater -- it would lower a number without lowering the exposure. What
// this gate does instead is make the remaining footprint deliberate: the
// current set is recorded, and anything NEW trips the build.
//
// PRIMARY INVARIANT -- SCOPE LOCK. The reference may appear ONLY under
// `.planning/`, which is internal record-keeping. Any occurrence in shipped
// source, docs, workflows, changelogs, or any path that would reach a
// published Hex tarball is a hard failure. This is the invariant that
// protects the thing worth protecting: a `.planning/` note is editable
// forever, a Hex tarball is permanent and cannot be unpublished.
//
// SECONDARY INVARIANT -- MONOTONIC RATCHET. The total occurrence count may
// go DOWN but never UP. Per-path counts are recorded in the manifest for
// diagnostics and deliberately NOT enforced: this repository archives
// `.planning/phases/NNN-*/` into `.planning/milestones/` at every milestone
// close, and per-path enforcement would redden on that routine, correct
// operation. A gate that fails on correct work is a gate that gets deleted.
//
// NO CI SECRETS. Deliberately none. A pepper or HMAC held in Actions secrets
// would force a choice between passing vacuously on fork pull requests
// (where repository secrets are unavailable) and blocking all outside
// contributions. Both are unacceptable for a public repository, so the
// manifest is self-contained.
//
// CLEARTEXT CONSTRAINT. Each entry stores the reference as a regex source in
// which at least one character is wrapped in a single-character class -- the
// `x[y]z` shape. That source compiles to a regex matching the literal while
// containing no contiguous substring equal to it, so a plain search for the
// reference does not hit this file or the manifest. The literal is
// reconstructed for hashing by collapsing every `[c]` to `c`.
//
// BE HONEST ABOUT WHAT THAT BUYS. It is NOT secrecy. The name is already
// public and no file edit retracts that. It buys exactly two things: this
// new artifact does not mint another searchable occurrence, and
// `pattern_sha256` makes the census target tamper-evident, so an entry
// cannot be quietly repointed at a pattern matching nothing while the gate
// keeps reporting green.
//
// REDACTION. Public CI logs are themselves a publication surface, so every
// path, count, and diagnostic this gate emits passes through redact(). A
// leak gate that leaks in its own failure message is worse than no gate, so
// assertOutputClean() scans the gate's own assembled output and fails if the
// reconstructed literal survives anywhere in it.

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

export const REDACTION = "<REDACTED-ADOPTER-REF>";
export const DEFAULT_CENSUS = ".planning/hygiene/sensitive-token-census.json";

// Paths that must never contain a censused reference regardless of what a
// manifest entry's allowed_prefixes says. allowed_prefixes can only ever
// narrow the permitted set, never widen it past this.
const ALWAYS_FORBIDDEN_PREFIXES = ["accrue/", "accrue_admin/", "accrue_portal/", "guides/", ".github/", "examples/", "packages/", "storybook/", "brandbook/"];
const ALWAYS_FORBIDDEN_FILES = ["CHANGELOG.md", "README.md"];

const NUL_PROBE_BYTES = 8192;

let redactors = [];

export function redact(text) {
  let out = String(text);
  for (const literal of redactors) {
    out = out.replaceAll(new RegExp(escapeRegex(literal), "gi"), REDACTION);
  }
  return out;
}

const fail = (message) => { throw new Error(`sensitive token census: FAIL: ${redact(message)}`); };

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// -- manifest ------------------------------------------------------------------

// Collapses every single-character class `[c]` to `c`. This is the inverse of
// the obfuscation described in CLEARTEXT CONSTRAINT above, and the only
// supported obfuscation: any other regex metacharacter in the source means
// the entry does not describe one literal and is rejected.
export function reconstructLiteral(patternSource) {
  if (typeof patternSource !== "string" || patternSource === "") {
    fail("entry has an empty pattern");
  }
  const collapsed = patternSource.replace(/\[(.)\]/g, "$1");
  if (/[.*+?^${}()|\\]/.test(collapsed) || collapsed.includes("[") || collapsed.includes("]")) {
    fail("entry pattern is not a single obfuscated literal -- only the x[y]z shape is supported");
  }
  if (collapsed === patternSource) {
    fail("entry pattern contains no [c] obfuscation -- it would store the reference in cleartext");
  }
  return collapsed;
}

export function loadCensus(repo, censusRelativePath) {
  const absolute = path.resolve(repo, censusRelativePath);
  if (!fs.existsSync(absolute)) fail(`census manifest missing: ${censusRelativePath}`);
  const raw = fs.readFileSync(absolute, "utf8");
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (error) {
    fail(`census manifest is not valid JSON: ${error.message}`);
  }
  if (!parsed || !Array.isArray(parsed.entries) || parsed.entries.length === 0) {
    fail("census manifest declares zero entries -- refusing to report a pass over an empty census");
  }
  const entries = parsed.entries.map((entry) => {
    for (const field of ["id", "kind", "pattern", "pattern_sha256", "rationale"]) {
      if (typeof entry[field] !== "string" || entry[field].trim() === "") {
        fail(`census entry is missing a non-empty "${field}"`);
      }
    }
    if (!Array.isArray(entry.allowed_prefixes) || entry.allowed_prefixes.length === 0) {
      fail(`census entry "${entry.id}" declares no allowed_prefixes`);
    }
    if (!Number.isInteger(entry.baseline_total) || entry.baseline_total < 0) {
      fail(`census entry "${entry.id}" has a non-integer baseline_total`);
    }
    const literal = reconstructLiteral(entry.pattern);
    const digest = crypto.createHash("sha256").update(literal.toLowerCase(), "utf-8").digest("hex");
    if (digest !== entry.pattern_sha256) {
      fail(`census entry "${entry.id}" pattern does not hash to its recorded pattern_sha256 -- the entry cannot be silently repointed`);
    }
    return { ...entry, literal };
  });
  // Registered before any other check runs, so every later message -- including
  // the cleartext failure immediately below -- is already redacted.
  redactors = entries.map((entry) => entry.literal);
  for (const entry of entries) {
    if (raw.toLowerCase().includes(entry.literal.toLowerCase())) {
      fail(`census manifest contains the reference for "${entry.id}" in cleartext`);
    }
  }
  return { raw, entries };
}

// -- packageable paths ---------------------------------------------------------

// Reads the `files: ~w(...)` list each package declares to Hex and returns
// those globs as repository-relative matchers. Anything matching one of these
// would reach a published tarball, which is permanent.
export function packageableMatchers(repo) {
  const matchers = [];
  for (const pkg of ["accrue", "accrue_admin", "accrue_portal"]) {
    const mixPath = path.join(repo, pkg, "mix.exs");
    if (!fs.existsSync(mixPath)) continue;
    const source = fs.readFileSync(mixPath, "utf8");
    const match = /files:\s*~w\(([^)]*)\)/.exec(source);
    if (!match) continue;
    for (const token of match[1].split(/\s+/).filter(Boolean)) {
      matchers.push({ pkg, token, prefix: `${pkg}/${token}` });
    }
  }
  if (matchers.length === 0) {
    fail("no package files: globs were resolved -- refusing to report a scope-lock pass without knowing what ships");
  }
  return matchers;
}

export function isPackageable(relativePath, matchers) {
  for (const matcher of matchers) {
    const prefix = matcher.prefix;
    if (prefix.includes("*")) {
      const pattern = new RegExp(`^${prefix.split("*").map(escapeRegex).join("[^/]*")}$`);
      if (pattern.test(relativePath)) return matcher;
      continue;
    }
    if (relativePath === prefix || relativePath.startsWith(`${prefix}/`)) return matcher;
  }
  return null;
}

// -- scanning ------------------------------------------------------------------

function git(repo, args) {
  const result = spawnSync("git", ["-C", repo, "--no-optional-locks", ...args], { encoding: "utf8", shell: false, timeout: 30000, maxBuffer: 20_000_000 });
  if (result.error || result.status !== 0) {
    fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`);
  }
  return result.stdout;
}

export function liveCorpus(repo) {
  return git(repo, ["ls-files", "-z"]).split("\0").filter(Boolean).sort();
}

export function assertCorpusNonEmpty(corpus) {
  if (!Array.isArray(corpus) || corpus.length === 0) {
    fail("corpus is empty -- refusing to report a completeness pass over zero tracked files");
  }
}

function isBinary(bytes) {
  return bytes.subarray(0, NUL_PROBE_BYTES).includes(0);
}

// Counts case-insensitive occurrences (not lines) of each entry's literal
// across the corpus. Returns per-entry totals and per-path counts.
export function scanCorpus(repo, corpus, entries) {
  const results = new Map(entries.map((entry) => [entry.id, { entry, total: 0, paths: {} }]));
  for (const relativePath of corpus) {
    const absolute = path.join(repo, relativePath);
    let bytes;
    try {
      bytes = fs.readFileSync(absolute);
    } catch {
      continue; // deleted-but-still-indexed, or a submodule gitlink
    }
    if (isBinary(bytes)) continue;
    const text = bytes.toString("utf8");
    const lowered = text.toLowerCase();
    for (const entry of entries) {
      const needle = entry.literal.toLowerCase();
      let count = 0;
      let index = lowered.indexOf(needle);
      while (index !== -1) {
        count += 1;
        index = lowered.indexOf(needle, index + needle.length);
      }
      if (count === 0) continue;
      const bucket = results.get(entry.id);
      bucket.total += count;
      bucket.paths[relativePath] = count;
    }
  }
  return results;
}

// -- invariants ----------------------------------------------------------------

export function assertNonVacuous(results) {
  for (const [id, bucket] of results.entries()) {
    if (bucket.total === 0) {
      fail(`census entry "${id}" matches zero occurrences corpus-wide -- a pattern that matches nothing cannot be evidence of anything`);
    }
  }
}

export function assertScopeLock(results, matchers) {
  const violations = [];
  for (const [id, bucket] of results.entries()) {
    const allowed = bucket.entry.allowed_prefixes;
    for (const relativePath of Object.keys(bucket.paths)) {
      const packageable = isPackageable(relativePath, matchers);
      if (packageable) {
        violations.push(`${relativePath} (entry "${id}", would ship in the ${packageable.pkg} package via files: ${packageable.token})`);
        continue;
      }
      if (ALWAYS_FORBIDDEN_FILES.includes(relativePath) || ALWAYS_FORBIDDEN_PREFIXES.some((p) => relativePath.startsWith(p))) {
        violations.push(`${relativePath} (entry "${id}", in a shipped or public-facing tree)`);
        continue;
      }
      if (!allowed.some((prefix) => relativePath.startsWith(prefix))) {
        violations.push(`${relativePath} (entry "${id}", outside allowed_prefixes ${allowed.join(", ")})`);
      }
    }
  }
  if (violations.length) {
    fail(`scope lock violated -- the censused reference appears outside its permitted tree: ${violations.join("; ")}`);
  }
}

export function assertRatchet(results) {
  const notes = [];
  for (const [id, bucket] of results.entries()) {
    const baseline = bucket.entry.baseline_total;
    if (bucket.total > baseline) {
      fail(`ratchet violated for entry "${id}": ${bucket.total} occurrences now, baseline is ${baseline} -- this census only ever goes down`);
    }
    if (bucket.total < baseline) {
      notes.push(`entry "${id}" is now ${bucket.total} occurrences, below its baseline of ${baseline} -- lower baseline_total to ${bucket.total} in this same commit`);
    }
  }
  return notes;
}

// A leak gate that leaks in its own failure message is worse than no gate.
export function assertOutputClean(text) {
  for (const literal of redactors) {
    if (String(text).toLowerCase().includes(literal.toLowerCase())) {
      throw new Error(`sensitive token census: FAIL: the gate's own output contained the censused reference in cleartext`);
    }
  }
  return text;
}

export function verifyCensus(repo, censusRelativePath, { requireScopeLock, requireRatchet, requireNoCleartext }) {
  const { entries } = loadCensus(repo, censusRelativePath);
  const corpus = liveCorpus(repo);
  assertCorpusNonEmpty(corpus);
  const results = scanCorpus(repo, corpus, entries);
  assertNonVacuous(results);
  if (requireScopeLock) assertScopeLock(results, packageableMatchers(repo));
  const notes = requireRatchet ? assertRatchet(results) : [];
  // requireNoCleartext is satisfied inside loadCensus (manifest) and by
  // assertOutputClean on the way out (this gate's own emissions).
  void requireNoCleartext;
  const total = [...results.values()].reduce((sum, bucket) => sum + bucket.total, 0);
  const files = new Set([...results.values()].flatMap((bucket) => Object.keys(bucket.paths))).size;
  return { entries: entries.length, corpus: corpus.length, files, total, notes, results };
}

// -- fixtures ------------------------------------------------------------------

const FIXTURE_LITERAL = "acmewidgets";
const FIXTURE_PATTERN = "acmewidget[s]";
const FIXTURE_SHA = crypto.createHash("sha256").update(FIXTURE_LITERAL, "utf-8").digest("hex");

function withScratchRepo(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "gsd-token-census-"));
  try {
    spawnSync("git", ["-C", dir, "init", "-q"], { encoding: "utf8" });
    fs.mkdirSync(path.join(dir, "accrue"), { recursive: true });
    fs.writeFileSync(path.join(dir, "accrue", "mix.exs"), "  files: ~w(lib priv guides mix.exs README* LICENSE* CHANGELOG*)\n");
    return fn(dir);
  } finally {
    redactors = [];
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function seed(dir, relativePath, content) {
  const absolute = path.join(dir, relativePath);
  fs.mkdirSync(path.dirname(absolute), { recursive: true });
  fs.writeFileSync(absolute, content);
  spawnSync("git", ["-C", dir, "add", "-A"], { encoding: "utf8" });
}

function seedCensus(dir, overrides = {}) {
  const entry = {
    id: "token-1",
    kind: "third-party-organization-reference",
    pattern: FIXTURE_PATTERN,
    pattern_sha256: FIXTURE_SHA,
    rationale: "fixture",
    allowed_prefixes: [".planning/"],
    baseline_total: 2,
    baseline_files: 1,
    observed_paths: {},
    ...overrides
  };
  seed(dir, "census.json", JSON.stringify({ entries: [entry] }, null, 2));
  return entry;
}

const STRICT = { requireScopeLock: true, requireRatchet: true, requireNoCleartext: true };

const SCENARIOS = [
  [
    "SCOPE LOCK: an occurrence under accrue/ fails, naming the path with the reference itself redacted",
    () => withScratchRepo((dir) => {
      seedCensus(dir);
      seed(dir, ".planning/note.md", `${FIXTURE_LITERAL} ${FIXTURE_LITERAL}`);
      seed(dir, "accrue/lib/leak.ex", `# ${FIXTURE_LITERAL}\n`);
      assert.throws(() => verifyCensus(dir, "census.json", STRICT), (error) => {
        assert.match(error.message, /scope lock violated/);
        assert.match(error.message, /accrue\/lib\/leak\.ex/);
        assert.ok(!error.message.toLowerCase().includes(FIXTURE_LITERAL), "the failure message must not repeat the reference");
        assert.ok(error.message.includes(REDACTION) || !error.message.toLowerCase().includes(FIXTURE_LITERAL));
        return true;
      });
    })
  ],
  [
    "SCOPE LOCK: an occurrence in a path matched by a package files: glob fails even when it also sits under an allowed prefix",
    () => withScratchRepo((dir) => {
      seedCensus(dir, { allowed_prefixes: [".planning/", "accrue/"] });
      seed(dir, ".planning/note.md", `${FIXTURE_LITERAL} ${FIXTURE_LITERAL}`);
      seed(dir, "accrue/lib/shipped.ex", `# ${FIXTURE_LITERAL}\n`);
      assert.throws(() => verifyCensus(dir, "census.json", STRICT), /would ship in the accrue package via files: lib/);
    })
  ],
  [
    "SCOPE LOCK: an occurrence in a root CHANGELOG.md fails",
    () => withScratchRepo((dir) => {
      seedCensus(dir, { allowed_prefixes: [".planning/", "CHANGELOG.md"] });
      seed(dir, ".planning/note.md", `${FIXTURE_LITERAL} ${FIXTURE_LITERAL}`);
      seed(dir, "CHANGELOG.md", `- ${FIXTURE_LITERAL}\n`);
      assert.throws(() => verifyCensus(dir, "census.json", STRICT), /shipped or public-facing tree/);
    })
  ],
  [
    "RATCHET: a total above the recorded baseline fails, naming both numbers",
    () => withScratchRepo((dir) => {
      seedCensus(dir, { baseline_total: 1 });
      seed(dir, ".planning/note.md", `${FIXTURE_LITERAL} ${FIXTURE_LITERAL}`);
      assert.throws(() => verifyCensus(dir, "census.json", STRICT), /ratchet violated.*2 occurrences now, baseline is 1/s);
    })
  ],
  [
    "a census entry whose reconstructed literal does not hash to its recorded pattern_sha256 fails",
    () => withScratchRepo((dir) => {
      seedCensus(dir, { pattern_sha256: "0".repeat(64) });
      seed(dir, ".planning/note.md", `${FIXTURE_LITERAL} ${FIXTURE_LITERAL}`);
      assert.throws(() => verifyCensus(dir, "census.json", STRICT), /cannot be silently repointed/);
    })
  ],
  [
    "a census pattern matching zero occurrences across a non-empty corpus fails as vacuous, naming the entry id",
    () => withScratchRepo((dir) => {
      seedCensus(dir);
      seed(dir, ".planning/note.md", "nothing to see here\n");
      assert.throws(() => verifyCensus(dir, "census.json", STRICT), /entry "token-1" matches zero occurrences/);
    })
  ],
  [
    "a run over an empty corpus fails rather than reporting a completeness pass",
    () => {
      assert.throws(() => assertCorpusNonEmpty([]), /zero tracked files/);
    }
  ],
  [
    "a census file containing the reconstructed literal in cleartext anywhere fails",
    () => withScratchRepo((dir) => {
      seedCensus(dir, { rationale: `mentions ${FIXTURE_LITERAL} in the clear` });
      seed(dir, ".planning/note.md", `${FIXTURE_LITERAL} ${FIXTURE_LITERAL}`);
      assert.throws(() => verifyCensus(dir, "census.json", STRICT), /in cleartext/);
    })
  ],
  [
    "a census pattern carrying no [c] obfuscation is rejected before it can be stored in cleartext",
    () => {
      assert.throws(() => reconstructLiteral(FIXTURE_LITERAL), /no \[c\] obfuscation/);
    }
  ],
  [
    "gate output containing the reference anywhere fails a self-check on its own emissions",
    () => {
      redactors = [FIXTURE_LITERAL];
      try {
        assert.throws(() => assertOutputClean(`PASS: 3 files, ${FIXTURE_LITERAL}`), /own output contained the censused reference/);
        assert.equal(assertOutputClean(`PASS: 3 files, ${REDACTION}`), `PASS: 3 files, ${REDACTION}`);
      } finally {
        redactors = [];
      }
    }
  ],
  [
    "POSITIVE: a total below the recorded baseline passes and prints that the baseline should be lowered",
    () => withScratchRepo((dir) => {
      seedCensus(dir, { baseline_total: 5 });
      seed(dir, ".planning/note.md", `${FIXTURE_LITERAL} ${FIXTURE_LITERAL}`);
      const result = verifyCensus(dir, "census.json", STRICT);
      assert.equal(result.total, 2);
      assert.equal(result.notes.length, 1);
      assert.match(result.notes[0], /below its baseline of 5 -- lower baseline_total to 2/);
    })
  ],
  [
    "POSITIVE: a phase directory moved from .planning/phases/ to .planning/milestones/ with the same total passes unchanged",
    () => withScratchRepo((dir) => {
      seedCensus(dir, { baseline_total: 2, observed_paths: { ".planning/phases/232-x/note.md": 2 } });
      seed(dir, ".planning/milestones/v1.62-phases/232-x/note.md", `${FIXTURE_LITERAL} ${FIXTURE_LITERAL}`);
      const result = verifyCensus(dir, "census.json", STRICT);
      assert.equal(result.total, 2);
      assert.equal(result.notes.length, 0, "per-path counts are diagnostic only -- an archive move must not redden the build");
    })
  ],
  [
    "the obfuscated manifest does not match itself: the census file never appears in its own results",
    () => withScratchRepo((dir) => {
      seedCensus(dir);
      seed(dir, ".planning/note.md", `${FIXTURE_LITERAL} ${FIXTURE_LITERAL}`);
      const result = verifyCensus(dir, "census.json", STRICT);
      const paths = Object.keys([...result.results.values()][0].paths);
      assert.deepEqual(paths, [".planning/note.md"]);
    })
  ],
  [
    "a manifest declaring zero entries fails rather than reporting a pass over an empty census",
    () => withScratchRepo((dir) => {
      seed(dir, "census.json", JSON.stringify({ entries: [] }));
      seed(dir, ".planning/note.md", `${FIXTURE_LITERAL}`);
      assert.throws(() => verifyCensus(dir, "census.json", STRICT), /zero entries/);
    })
  ],
  [
    "a live repo-level strict run holds the scope lock and the ratchet, and reports non-vacuous counts",
    () => {
      const repo = path.resolve(process.cwd());
      try {
        const result = verifyCensus(repo, DEFAULT_CENSUS, STRICT);
        assert.ok(result.corpus > 0);
        assert.ok(result.entries > 0);
        assert.ok(result.total > 0);
      } finally {
        redactors = [];
      }
    }
  ]
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

// -- entrypoint ----------------------------------------------------------------

const BOOLEAN_FLAGS = new Set(["fixtures", "require-scope-lock", "require-ratchet", "require-no-cleartext"]);
const VALUE_OPTIONS = new Set(["repo", "census"]);

function options(argv) {
  const flags = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]; if (!token.startsWith("--")) fail(`unexpected argument: ${token}`);
    const key = token.slice(2);
    if (BOOLEAN_FLAGS.has(key)) { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option: --${key}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${key} requires a value`);
    values[key] = argv[++index];
  }
  return { flags, values };
}

function emit(line) {
  console.log(assertOutputClean(redact(line)));
}

function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) {
    const count = verifyFixtures();
    const requested = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
    const suffix = requested.length ? ` (fixtures: ${requested.join(", ")}; ${count} scenarios)` : ` (fixtures: no strict flags requested; ${count} scenarios)`;
    emit(`sensitive token census: PASS${suffix}`);
    return;
  }

  const repo = parsed.values.repo || process.cwd();
  const census = parsed.values.census || DEFAULT_CENSUS;
  const requested = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
  const result = verifyCensus(repo, census, {
    requireScopeLock: parsed.flags.has("require-scope-lock"),
    requireRatchet: parsed.flags.has("require-ratchet"),
    requireNoCleartext: parsed.flags.has("require-no-cleartext")
  });
  for (const note of result.notes) emit(`sensitive token census: NOTE: ${note}`);
  const verified = requested.length ? `verified: ${requested.join(", ")}` : "schema-only: no strict flags supplied";
  emit(`sensitive token census: PASS (${verified}; ${result.entries} entries, ${result.corpus} tracked files scanned, ${result.files} files carry a censused reference, ${result.total} occurrences total)`);
}

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
    const message = error.message.startsWith("sensitive token census:") ? error.message : `sensitive token census: FAIL: ${redact(error.message)}`;
    console.error(assertOutputClean(message));
    process.exitCode = 1;
  }
}
