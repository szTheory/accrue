#!/usr/bin/env node
// Phase 230 Plan 06, Task 1 (D-22): a standing, fail-closed sweep asserting that
// every `.planning/phases/<slug>` evidence-path literal in `scripts/ci/**` and
// `.github/workflows/**` either resolves on disk as written, or is reachable
// through the archive-aware resolver (`scripts/ci/phase_evidence_path.mjs`).
//
// A literal naming a slug that is ALREADY archived (present under
// `.planning/milestones/*-phases/<slug>/`, absent under `.planning/phases/<slug>/`)
// is a hard failure unless the referencing file is provably archive-aware for
// that slug -- either by calling `resolvePhaseEvidencePath` with it, or by the
// slug's archived milestones path appearing as a literal anywhere in the scanned
// corpus (the established `firstExistingPath`/dual-directory-constant pattern
// used elsewhere in this codebase, e.g. `verify_phase190_automation_contract.sh`,
// `verify_phase191_ax187_coverage.mjs`, `generate_phase200_closeout_reports.mjs`).
// This is what stops the F-01..F-03 class of bug -- a check that silently reads
// the wrong thing after archiving -- from recurring after a future merge.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import assert from "node:assert/strict";

export const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");

const fail = (message) => { throw new Error(message); };

const SLUG_RE = "[0-9]+-[a-z0-9]+(?:-[a-z0-9]+)*";
// A qualifying literal: `.planning/phases/<slug>` optionally followed by `/<rest>`.
const PATH_LITERAL_RE = new RegExp(`^\\.planning\\/phases\\/(${SLUG_RE})((?:\\/[^"'\`\\s]*)?)$`);
// Any occurrence (quoted or not) of an archived-milestone path for a slug --
// used only to build the repo-wide "this slug is handled somewhere" proof set.
const MILESTONES_RE = new RegExp(`\\.planning\\/milestones\\/[^\\/"'\\s]+-phases\\/(${SLUG_RE})`, "g");
const VAR_ASSIGN_RE = new RegExp(`\\b(?:const|let|var)\\s+([A-Za-z_$][\\w$]*)\\s*=\\s*["'](${SLUG_RE})["']`, "g");
const RESOLVE_CALL_RE = new RegExp(`resolvePhaseEvidencePath\\s*\\(\\s*([A-Za-z_$][\\w$]*|"${SLUG_RE}"|'${SLUG_RE}')`, "g");
const DQ_STRING_RE = /"([^"\\]*(?:\\.[^"\\]*)*)"/g;
const SQ_STRING_RE = /'([^'\\]*(?:\\.[^'\\]*)*)'/g;
const PREDICATE_EXEMPT_RE = /\.(startsWith|endsWith|includes)\($/;

function listFiles(root, dir, extensions) {
  const out = [];
  const abs = path.join(root, dir);
  if (!fs.existsSync(abs)) return out;
  for (const entry of fs.readdirSync(abs, { withFileTypes: true })) {
    const relPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...listFiles(root, relPath, extensions));
    } else if (extensions.some((ext) => entry.name.endsWith(ext))) {
      out.push(relPath);
    }
  }
  return out.sort();
}

// This sweep's own file is excluded from its own corpus: its fixtures section
// intentionally embeds synthetic `.planning/phases/<slug>` literals (both
// resolving and dangling) as self-test payloads, not real evidence-path usage.
const SELF_PATH = "scripts/ci/verify_phase230_archive_invariants.mjs";

function corpusFiles(root) {
  return [
    ...listFiles(root, "scripts/ci", [".mjs", ".cjs", ".sh"]),
    ...listFiles(root, ".github/workflows", [".yml", ".yaml"]),
  ].filter((relPath) => relPath.split(path.sep).join("/") !== SELF_PATH).sort();
}

// Repo-wide "proven safe" slug set: a slug is safe if ANY file in the corpus
// either (a) contains a literal archived-milestone path for it, or (b) calls
// `resolvePhaseEvidencePath` with it (directly, or via a same-file variable).
function computeProvenSafeSlugs(root, files) {
  const safe = new Set();
  for (const relPath of files) {
    const content = fs.readFileSync(path.join(root, relPath), "utf8");

    let match = MILESTONES_RE.exec(content);
    while (match) { safe.add(match[1]); match = MILESTONES_RE.exec(content); }
    MILESTONES_RE.lastIndex = 0;

    const varToSlug = new Map();
    let varMatch = VAR_ASSIGN_RE.exec(content);
    while (varMatch) { varToSlug.set(varMatch[1], varMatch[2]); varMatch = VAR_ASSIGN_RE.exec(content); }
    VAR_ASSIGN_RE.lastIndex = 0;

    let callMatch = RESOLVE_CALL_RE.exec(content);
    while (callMatch) {
      const token = callMatch[1];
      if (token.startsWith('"') || token.startsWith("'")) {
        safe.add(token.slice(1, -1));
      } else if (varToSlug.has(token)) {
        safe.add(varToSlug.get(token));
      }
      callMatch = RESOLVE_CALL_RE.exec(content);
    }
    RESOLVE_CALL_RE.lastIndex = 0;
  }
  return safe;
}

// Extract candidate quoted-string literal occurrences from JS/bash source, with
// 1-indexed line numbers and enough preceding context to apply the predicate-
// method exemption (`.startsWith(`/`.endsWith(`/`.includes(`).
function extractQuotedLiterals(content) {
  const out = [];
  const lines = content.split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    for (const re of [DQ_STRING_RE, SQ_STRING_RE]) {
      re.lastIndex = 0;
      let match = re.exec(line);
      while (match) {
        const before = line.slice(0, match.index);
        out.push({ text: match[1], line: i + 1, before });
        match = re.exec(line);
      }
    }
  }
  return out;
}

// YAML `path:` block-scalar entries are bare (unquoted) lines; scan them too.
function extractYamlPathLines(content) {
  const out = [];
  const lines = content.split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    const trimmed = lines[i].trim();
    if (trimmed.startsWith(".planning/phases/")) out.push({ text: trimmed, line: i + 1, before: "" });
  }
  return out;
}

// Strip a leading bash variable prefix (`$var/`, `${var}/`) so a quoted bash
// string like `"$repo_root/.planning/phases/224-.../lock.json"` still reduces
// to a checkable bare path.
function stripBashVarPrefix(text) {
  return text.replace(/^\$\{?[A-Za-z_][\w]*\}?\//, "");
}

function archivedCandidates(root, slug) {
  const milestonesRoot = path.join(root, ".planning", "milestones");
  if (!fs.existsSync(milestonesRoot)) return [];
  return fs.readdirSync(milestonesRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && entry.name.endsWith("-phases"))
    .map((entry) => path.join(milestonesRoot, entry.name, slug))
    .filter((candidate) => fs.existsSync(candidate));
}

export function verifyArchiveInvariants({ root = repositoryRoot } = {}) {
  const files = corpusFiles(root);
  const provenSafeSlugs = computeProvenSafeSlugs(root, files);
  const failures = [];
  let literalCount = 0;

  for (const relPath of files) {
    const content = fs.readFileSync(path.join(root, relPath), "utf8");
    const isBash = relPath.endsWith(".sh");
    const isYaml = relPath.endsWith(".yml") || relPath.endsWith(".yaml");

    const occurrences = isYaml
      ? extractYamlPathLines(content)
      : extractQuotedLiterals(content);

    for (const occurrence of occurrences) {
      const normalized = isBash ? stripBashVarPrefix(occurrence.text) : occurrence.text;
      const literalMatch = normalized.match(PATH_LITERAL_RE);
      if (!literalMatch) continue;
      if (!isYaml && PREDICATE_EXEMPT_RE.test(occurrence.before)) continue;

      literalCount += 1;
      const [, slug, restRaw] = literalMatch;
      const rest = restRaw.replace(/^\//, "");

      const activeTarget = rest ? path.join(root, ".planning", "phases", slug, rest) : path.join(root, ".planning", "phases", slug);
      if (fs.existsSync(activeTarget)) continue; // resolves on disk as written

      const activeDirExists = fs.existsSync(path.join(root, ".planning", "phases", slug));
      const archived = !activeDirExists && archivedCandidates(root, slug).length > 0;

      if (!archived) {
        failures.push(`${relPath}:${occurrence.line}: literal names .planning/phases/${slug}${rest ? `/${rest}` : ""}, which resolves nowhere (not active, not archived): ${occurrence.text}`);
        continue;
      }

      if (!provenSafeSlugs.has(slug)) {
        failures.push(`${relPath}:${occurrence.line}: literal names already-archived phase ${slug}, not routed through resolvePhaseEvidencePath (scripts/ci/phase_evidence_path.mjs): ${occurrence.text}`);
      }
    }
  }

  const result = { scannedFileCount: files.length, literalCount, failures };
  if (failures.length > 0) {
    fail(`archive-path sweep found ${failures.length} unresolvable/non-archive-aware literal(s):\n${failures.join("\n")}`);
  }
  return result;
}

// ---------------------------------------------------------------------------
// Fixtures self-test
// ---------------------------------------------------------------------------

function makeFixtureRoot() {
  return fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase230-archive-sweep-"));
}

function writeFile(root, relPath, content) {
  const abs = path.join(root, relPath);
  fs.mkdirSync(path.dirname(abs), { recursive: true });
  fs.writeFileSync(abs, content);
}

function verifyFixtures() {
  // Fixture 1: a literal resolving on disk (active phase) passes.
  {
    const root = makeFixtureRoot();
    writeFile(root, ".planning/phases/900-fixture-active/evidence.json", "{}");
    writeFile(root, "scripts/ci/fixture_reads_active.mjs", 'const P = ".planning/phases/900-fixture-active/evidence.json";\n');
    const result = verifyArchiveInvariants({ root });
    assert.equal(result.failures.length, 0, "active literal should resolve");
    assert.equal(result.literalCount, 1);
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Fixture 2: a literal resolving only via the archived fallback passes
  // (the referencing file demonstrates archive-awareness).
  {
    const root = makeFixtureRoot();
    writeFile(root, ".planning/milestones/v9.0-phases/901-fixture-archived/evidence.json", "{}");
    writeFile(
      root,
      "scripts/ci/fixture_reads_archived.mjs",
      [
        'import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";',
        'const SLUG = "901-fixture-archived";',
        'const P = ".planning/phases/901-fixture-archived/evidence.json";',
        "resolvePhaseEvidencePath(SLUG, \"evidence.json\");",
        "",
      ].join("\n")
    );
    const result = verifyArchiveInvariants({ root });
    assert.equal(result.failures.length, 0, "archived literal routed through resolvePhaseEvidencePath should pass");
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Fixture 3: a literal resolving nowhere fails naming the file and line.
  {
    const root = makeFixtureRoot();
    writeFile(root, "scripts/ci/fixture_dangling.mjs", '\n\nconst P = ".planning/phases/902-fixture-nowhere/evidence.json";\n');
    let error = null;
    try { verifyArchiveInvariants({ root }); } catch (caught) { error = caught; }
    assert.ok(error, "dangling literal should fail");
    assert.match(error.message, /fixture_dangling\.mjs:3/);
    assert.match(error.message, /resolves nowhere/);
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Fixture 4: a literal naming an already-archived slug, not routed through
  // resolvePhaseEvidencePath, fails.
  {
    const root = makeFixtureRoot();
    writeFile(root, ".planning/milestones/v9.0-phases/903-fixture-unrouted/evidence.json", "{}");
    writeFile(root, "scripts/ci/fixture_unrouted.mjs", 'const P = ".planning/phases/903-fixture-unrouted/evidence.json";\n');
    let error = null;
    try { verifyArchiveInvariants({ root }); } catch (caught) { error = caught; }
    assert.ok(error, "unrouted archived-slug literal should fail");
    assert.match(error.message, /already-archived phase 903-fixture-unrouted/);
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Predicate-method exemption: a `.startsWith()` prefix filter against
  // foreign ref content is not a filesystem path resolution and is exempt.
  {
    const root = makeFixtureRoot();
    writeFile(root, ".planning/milestones/v9.0-phases/904-fixture-predicate/evidence.json", "{}");
    writeFile(root, "scripts/ci/fixture_predicate.mjs", 'entry.startsWith(".planning/phases/904-fixture-predicate/");\n');
    const result = verifyArchiveInvariants({ root });
    assert.equal(result.failures.length, 0, "startsWith predicate literal is exempt");
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Reproduce-command hint text (a quoted string containing more than the
  // bare path) is exempt, matching the project's own precedent (v1.61
  // audit: "historical generation-time strings ... frozen evidence").
  {
    const root = makeFixtureRoot();
    writeFile(root, "scripts/ci/fixture_hint.mjs", 'const next = "node scripts/ci/verify_x.mjs --records .planning/phases/905-fixture-hint/x.json";\n');
    const result = verifyArchiveInvariants({ root });
    assert.equal(result.failures.length, 0, "reproduce-command hint text is exempt");
    fs.rmSync(root, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// node:test suite (also runnable via `node --test`)
// ---------------------------------------------------------------------------

test("verifyArchiveInvariants fixtures self-test", () => {
  verifyFixtures();
});

test("verifyArchiveInvariants scans a non-zero number of files in this repository", () => {
  const files = corpusFiles(repositoryRoot);
  assert.ok(files.length > 0);
});

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

function main() {
  if (process.argv.includes("--fixtures")) {
    verifyFixtures();
    console.log("verify_phase230_archive_invariants fixtures: PASS");
    return;
  }
  const result = verifyArchiveInvariants({});
  console.log(`verify_phase230_archive_invariants: PASS (scanned_files=${result.scannedFileCount}, literals=${result.literalCount})`);
}

if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  try {
    main();
  } catch (error) {
    console.error(`verify_phase230_archive_invariants: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
