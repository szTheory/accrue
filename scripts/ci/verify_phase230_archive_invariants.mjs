#!/usr/bin/env node
// Phase 230 Plan 06, Task 1 (D-22): a standing, fail-closed sweep asserting that
// every `.planning/phases/<slug>` evidence-path literal in `scripts/ci/**` and
// `.github/workflows/**` -- in JS/bash quoted strings ANYWHERE on a line, and in
// YAML lines ANYWHERE (not only bare `path:` block-scalar lines that start with
// the literal) -- either resolves on disk as written, or is reachable through
// the archive-aware resolver (`scripts/ci/phase_evidence_path.mjs`).
//
// A literal naming a slug that is ALREADY archived (present under
// `.planning/milestones/*-phases/<slug>/`, absent under `.planning/phases/<slug>/`)
// is a hard failure unless the referencing file ITSELF is provably archive-aware
// for that slug -- either by calling `resolvePhaseEvidencePath` with it, or by the
// slug's archived milestones path appearing as a literal in that SAME file (the
// established `firstExistingPath`/dual-directory-constant pattern used elsewhere
// in this codebase, e.g. `verify_phase190_automation_contract.sh`,
// `verify_phase191_ax187_coverage.mjs`, `generate_phase200_closeout_reports.mjs`).
// The safety proof is deliberately per-file, NOT corpus-wide: a stale,
// unrouted literal in one file must not be excused merely because some
// unrelated file elsewhere in `scripts/ci/**`/`.github/workflows/**` happens
// to handle the same archived slug for its own, different evidence reads
// (CR-02 -- a corpus-wide proof let exactly this recur, undetected, twice).
// This is what stops the F-01..F-03 class of bug -- a check that silently reads
// the wrong thing after archiving -- from recurring after a future merge.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import assert from "node:assert/strict";
import { isMainModule } from "./main_module.mjs";

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
// The bash-CLI form of the same resolver (`node scripts/ci/phase_evidence_path.mjs
// <slug> <artifact>`), used by shell scripts that shell out rather than `import`.
const CLI_RESOLVE_RE = new RegExp(`phase_evidence_path\\.mjs\\s+["']?(${SLUG_RE})["']?`, "g");
const DQ_STRING_RE = /"([^"\\]*(?:\\.[^"\\]*)*)"/g;
const SQ_STRING_RE = /'([^'\\]*(?:\\.[^'\\]*)*)'/g;
const PREDICATE_EXEMPT_RE = /\.(startsWith|endsWith|includes)\($/;
// An explicit, narrow, human-reviewed opt-out for a literal that is provably NOT a
// live filesystem read of the archived phase (e.g. inert sample/fixture document
// text) -- mirrors this codebase's established per-occurrence annotation
// convention (see `ax-type-exception`). Trailing-comment only: same line as the
// literal, so it stays visually adjacent to exactly what it exempts and can't
// silently cover unrelated lines.
const EXEMPT_MARKER_RE = /(?:\/\/|#)\s*archive-sweep-exempt:\s*\S/;

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

// Per-file "proven safe" slug sets: a slug is safe FOR A GIVEN FILE only if
// THAT SAME FILE either (a) contains a literal archived-milestone path for it,
// or (b) calls `resolvePhaseEvidencePath` with it (directly, or via a
// same-file variable). This is deliberately NOT corpus-wide (CR-02): a stale,
// unrouted `.planning/phases/<slug>` literal in one file must not be excused
// merely because some unrelated file elsewhere in the corpus happens to
// handle the same archived slug for its own, different evidence reads.
function computeProvenSafeSlugsByFile(root, files) {
  const safeByFile = new Map();
  for (const relPath of files) {
    const content = fs.readFileSync(path.join(root, relPath), "utf8");
    const safe = new Set();

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

    let cliMatch = CLI_RESOLVE_RE.exec(content);
    while (cliMatch) { safe.add(cliMatch[1]); cliMatch = CLI_RESOLVE_RE.exec(content); }
    CLI_RESOLVE_RE.lastIndex = 0;

    safeByFile.set(relPath, safe);
  }
  return safeByFile;
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

// YAML has no single canonical quoting convention for a `.planning/phases/<slug>`
// literal: `path:` block-scalar entries are bare (unquoted) whole lines, but the
// SAME literal can also appear mid-line -- inside a quoted `grep -Eq '...'`
// alternation embedded in a `run:` step, for instance. Scan for the literal
// ANYWHERE on a YAML line (not only lines whose trimmed form starts with it),
// capturing the preceding text as `before` so the (currently JS/bash-only)
// predicate-method exemption stays wired for any future YAML use, and so each
// occurrence still carries its own line number for per-occurrence exemption
// checks (`archive-sweep-exempt:`, the soft-upload step exemption, etc).
const YAML_LITERAL_SCAN_RE = new RegExp(`\\.planning\\/phases\\/(${SLUG_RE})(?:\\/[^"'\`\\s]*)?`, "g");
function extractYamlPathLines(content) {
  const out = [];
  const lines = content.split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    YAML_LITERAL_SCAN_RE.lastIndex = 0;
    let match = YAML_LITERAL_SCAN_RE.exec(line);
    while (match) {
      out.push({ text: match[0], line: i + 1, before: line.slice(0, match.index) });
      match = YAML_LITERAL_SCAN_RE.exec(line);
    }
  }
  return out;
}

// Strip a leading bash variable prefix (`$var/`, `${var}/`) so a quoted bash
// string like `"$repo_root/.planning/phases/224-.../lock.json"` still reduces
// to a checkable bare path.
function stripBashVarPrefix(text) {
  return text.replace(/^\$\{?[A-Za-z_][\w]*\}?\//, "");
}

// A small set of narrow, principled, generically-applicable exemptions for
// literal `.planning/phases/<slug>` occurrences that are provably NOT a live
// filesystem read subject to the F-01..F-03 "silently reads the wrong thing
// after archiving" failure mode -- so they are out of scope for the
// archive-awareness requirement entirely, same as the pre-existing
// `.startsWith()`/`.endsWith()`/`.includes()` predicate exemption above.

// Bash idiom: a backslash-continued `for needle in "..." \ "..." \ do ... done`
// block whose loop variable is used, EVERY time it appears in the body, ONLY
// as an argument to a content-match helper (`require_fixed`,
// `require_source_fixed`, `require_source_regex`, or `grep`) is checking that
// ANOTHER file's TEXT CONTAINS these strings -- it never touches the
// filesystem path the string happens to spell. If the loop variable is used
// ANYWHERE else in the body -- `cat "$var"`, a redirect, a `[ -f "$var" ]`
// test, command substitution, or any other position -- the exemption does
// NOT apply, because that other use MAY be a live filesystem read. The loop
// variable name is captured from the `for <var> in` line itself, not
// assumed. Returns the 1-indexed line numbers of literal-bearing lines
// inside such a block's `in`-list.
const BASH_FOR_START_RE = /^\s*for\s+(\w+)\s+in\b/;
const BASH_DO_LINE_RE = /(^\s*do\s*$)|(;\s*do\s*$)/;
const BASH_DONE_LINE_RE = /^\s*done\b/;
const CONTENT_MATCH_CALL_START_RE = /^(require_fixed|require_source_fixed|require_source_regex|grep)\b/;
function computeBashContentMatchExemptLines(content) {
  const exempt = new Set();
  const lines = content.split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    const forMatch = lines[i].match(BASH_FOR_START_RE);
    if (!forMatch) continue;
    const loopVar = forMatch[1];
    let doLine = -1;
    for (let j = i; j < lines.length && j < i + 200; j += 1) {
      if (BASH_DO_LINE_RE.test(lines[j])) { doLine = j; break; }
    }
    if (doLine === -1) continue;
    let doneLine = -1;
    for (let j = doLine + 1; j < lines.length && j < doLine + 200; j += 1) {
      if (BASH_DONE_LINE_RE.test(lines[j])) { doneLine = j; break; }
    }
    if (doneLine === -1) continue;

    const bodyLines = lines.slice(doLine + 1, doneLine);
    const varRefRe = new RegExp(`\\$\\{?${loopVar}\\}?\\b`);
    let sawContentMatchUse = false;
    let sawOtherUse = false;
    for (const bodyLine of bodyLines) {
      if (!varRefRe.test(bodyLine)) continue;
      if (CONTENT_MATCH_CALL_START_RE.test(bodyLine.trim())) {
        sawContentMatchUse = true;
      } else {
        sawOtherUse = true;
      }
    }
    if (!sawContentMatchUse || sawOtherUse) continue;

    for (let j = i; j <= doLine; j += 1) exempt.add(j + 1);
  }
  return exempt;
}

// YAML idiom: a `path:` block-scalar entry inside a step that ITSELF `uses:
// actions/upload-artifact` and declares `if-no-files-found: ignore` is a
// soft/optional upload by GitHub Actions' own contract -- a missing path
// degrades to "nothing uploaded," never a silent wrong-content read. Both
// conditions must hold within the SAME enclosing step -- an `if-no-files-
// found: ignore` belonging to a different, later step (or a `run:` step that
// merely happens to be followed by an unrelated upload step) does not
// qualify. The enclosing step is found by scanning outward to real step
// boundaries (`- <key>:` list items at the step's own indentation), not a
// fixed line window. Returns the 1-indexed line numbers of literal-bearing
// `path:` lines that fall inside such a step.
const YAML_STEP_ITEM_RE = /^(\s*)-\s/;
const YAML_UPLOAD_ARTIFACT_RE = /uses:\s*actions\/upload-artifact\b/;
const YAML_IF_NO_FILES_IGNORE_RE = /^\s*if-no-files-found:\s*ignore\s*$/;
function computeYamlSoftUploadExemptLines(content) {
  const exempt = new Set();
  const lines = content.split(/\r?\n/);
  for (let i = 0; i < lines.length; i += 1) {
    if (!lines[i].trim().startsWith(".planning/phases/")) continue;

    // Scan upward for the enclosing step's own boundary: the nearest
    // `- <key>:` list item at or above this line.
    let stepStart = -1;
    let stepIndent = -1;
    for (let j = i; j >= 0; j -= 1) {
      const m = lines[j].match(YAML_STEP_ITEM_RE);
      if (m) { stepStart = j; stepIndent = m[1].length; break; }
    }
    if (stepStart === -1) continue;

    // Scan downward for the next sibling list item at the SAME indentation --
    // that is where this step ends (exclusive).
    let stepEnd = lines.length;
    for (let j = stepStart + 1; j < lines.length; j += 1) {
      const m = lines[j].match(YAML_STEP_ITEM_RE);
      if (m && m[1].length <= stepIndent) { stepEnd = j; break; }
    }
    if (i < stepStart || i >= stepEnd) continue; // literal fell outside its own step -- shouldn't happen

    const stepLines = lines.slice(stepStart, stepEnd);
    const stepBody = stepLines.join("\n");
    if (!YAML_UPLOAD_ARTIFACT_RE.test(stepBody)) continue;
    if (!stepLines.some((line) => YAML_IF_NO_FILES_IGNORE_RE.test(line))) continue;

    exempt.add(i + 1);
  }
  return exempt;
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
  const provenSafeSlugsByFile = computeProvenSafeSlugsByFile(root, files);
  const failures = [];
  let literalCount = 0;

  for (const relPath of files) {
    const content = fs.readFileSync(path.join(root, relPath), "utf8");
    const isBash = relPath.endsWith(".sh");
    const isYaml = relPath.endsWith(".yml") || relPath.endsWith(".yaml");
    const lines = content.split(/\r?\n/);

    const occurrences = isYaml
      ? extractYamlPathLines(content)
      : extractQuotedLiterals(content);

    const bashContentMatchExempt = isBash ? computeBashContentMatchExemptLines(content) : null;
    const yamlSoftUploadExempt = isYaml ? computeYamlSoftUploadExemptLines(content) : null;

    for (const occurrence of occurrences) {
      const normalized = isBash ? stripBashVarPrefix(occurrence.text) : occurrence.text;
      const literalMatch = normalized.match(PATH_LITERAL_RE);
      if (!literalMatch) continue;

      // Count every qualifying literal occurrence in the swept corpus, BEFORE
      // exemption filtering -- `literalCount` (surfaced in the CLI summary) is
      // the sweep's own coverage signal: it must rise when a previously
      // invisible literal starts being extracted, even if that literal turns
      // out to be exempt. A metric that only counted post-exemption literals
      // could not distinguish "extractor coverage improved" from "nothing new
      // was found," which is exactly the class of silent gap this sweep exists
      // to catch in the files it scans.
      literalCount += 1;

      if (!isYaml && PREDICATE_EXEMPT_RE.test(occurrence.before)) continue;
      if (EXEMPT_MARKER_RE.test(lines[occurrence.line - 1] || "")) continue;
      if (isBash && bashContentMatchExempt.has(occurrence.line)) continue;
      if (isYaml && yamlSoftUploadExempt.has(occurrence.line)) continue;

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

      const provenSafeSlugs = provenSafeSlugsByFile.get(relPath);
      if (!provenSafeSlugs || !provenSafeSlugs.has(slug)) {
        failures.push(`${relPath}:${occurrence.line}: literal names already-archived phase ${slug}, not routed through resolvePhaseEvidencePath in this same file (scripts/ci/phase_evidence_path.mjs): ${occurrence.text}`);
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

  // Fixture 5 (CR-02 regression): a literal naming an already-archived slug in
  // one file, with NO archive-aware proof in that file, must fail even when a
  // DIFFERENT, unrelated file elsewhere in the corpus happens to handle the
  // same slug archive-aware. Corpus-wide safety inference (the defect this
  // fixture guards against) would incorrectly let this pass.
  {
    const root = makeFixtureRoot();
    writeFile(root, ".planning/milestones/v9.0-phases/906-fixture-cross-file/evidence.json", "{}");
    writeFile(root, "scripts/ci/fixture_stale_unrouted.mjs", 'const P = ".planning/phases/906-fixture-cross-file/evidence.json";\n');
    writeFile(
      root,
      "scripts/ci/fixture_unrelated_archive_aware.mjs",
      [
        'import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";',
        'const SLUG = "906-fixture-cross-file";',
        "resolvePhaseEvidencePath(SLUG, \"other-evidence.json\");",
        "",
      ].join("\n")
    );
    let error = null;
    try { verifyArchiveInvariants({ root }); } catch (caught) { error = caught; }
    assert.ok(error, "a stale literal in one file must not be excused by archive-awareness in a different file");
    assert.match(error.message, /fixture_stale_unrouted\.mjs.*already-archived phase 906-fixture-cross-file/s);
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

  // Defect-1 regression: a `run:` step (NOT an upload step) that reads an
  // archived-slug literal, followed within a few lines by an UNRELATED
  // sibling step's `if-no-files-found: ignore`, must NOT be exempted just
  // because that bare marker line happens to appear nearby. The literal's
  // own enclosing step never declares `uses: actions/upload-artifact`.
  {
    const root = makeFixtureRoot();
    writeFile(
      root,
      ".github/workflows/fixture_yaml_soft_upload_non_upload_step.yml",
      [
        "name: fixture",
        "on: push",
        "jobs:",
        "  test:",
        "    runs-on: ubuntu-latest",
        "    steps:",
        "      - name: Read archived evidence",
        "        run: |",
        "          .planning/phases/910-fixture-nonupload/evidence.json",
        "      - name: Unrelated upload",
        "        uses: actions/upload-artifact@v7",
        "        with:",
        "          name: unrelated",
        "          path: some/other/path",
        "          if-no-files-found: ignore",
        "",
      ].join("\n")
    );
    let error = null;
    try { verifyArchiveInvariants({ root }); } catch (caught) { error = caught; }
    assert.ok(error, "a non-upload step's literal must not be exempted by a neighboring step's if-no-files-found: ignore");
    assert.match(error.message, /910-fixture-nonupload/);
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Defect-1 counter-regression: the genuine `actions/upload-artifact` +
  // `if-no-files-found: ignore` + archived-slug `path:` pattern (as used in
  // `.github/workflows/ci.yml`) must still pass -- the tightened predicate
  // must not break the legitimate case it exists to allow.
  {
    const root = makeFixtureRoot();
    writeFile(
      root,
      ".github/workflows/fixture_yaml_soft_upload_real_upload_step.yml",
      [
        "name: fixture",
        "on: push",
        "jobs:",
        "  test:",
        "    runs-on: ubuntu-latest",
        "    steps:",
        "      - name: Upload Phase fixture evidence",
        "        if: always()",
        "        uses: actions/upload-artifact@v7",
        "        with:",
        "          name: fixture-evidence",
        "          path: |",
        "            .planning/phases/911-fixture-upload/evidence.json",
        "          if-no-files-found: ignore",
        "",
      ].join("\n")
    );
    const result = verifyArchiveInvariants({ root });
    assert.equal(result.failures.length, 0, "genuine upload-artifact + if-no-files-found: ignore step remains exempt");
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Defect-2 regression: a bash loop body that mixes a content-match call
  // (`require_fixed "$needle"`) with a real filesystem use of the SAME loop
  // variable (`cat "$needle"`) must NOT be exempted -- the loop variable is
  // not used exclusively as a content-match argument.
  {
    const root = makeFixtureRoot();
    writeFile(
      root,
      "scripts/ci/fixture_bash_mixed_use.sh",
      [
        "#!/bin/bash",
        "for needle in \\",
        '  ".planning/phases/920-fixture-mixed/evidence.json" \\',
        '  "other"',
        "do",
        '  require_fixed "$needle"',
        '  cat "$needle"',
        "done",
        "",
      ].join("\n")
    );
    let error = null;
    try { verifyArchiveInvariants({ root }); } catch (caught) { error = caught; }
    assert.ok(error, "a loop variable used outside content-match calls must not be exempted");
    assert.match(error.message, /920-fixture-mixed/);
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Defect-2 counter-regression: a bash loop body whose loop variable is used
  // ONLY as an argument to content-match helpers (as in
  // `verify_phase200_ci_contract.sh`) must still pass.
  {
    const root = makeFixtureRoot();
    writeFile(
      root,
      "scripts/ci/fixture_bash_content_only_use.sh",
      [
        "#!/bin/bash",
        "for needle in \\",
        '  ".planning/phases/921-fixture-content-only/evidence.json" \\',
        '  "other"',
        "do",
        '  require_fixed "$needle"',
        "done",
        "",
      ].join("\n")
    );
    const result = verifyArchiveInvariants({ root });
    assert.equal(result.failures.length, 0, "loop variable used only in content-match calls remains exempt");
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Defect-3 regression: a `.planning/phases/<slug>` literal naming an
  // already-archived slug, appearing MID-LINE inside a YAML `run:` step
  // (not at the start of the trimmed line, e.g. embedded in a quoted `grep`
  // alternation), must be detected and fail when unrouted. Under the old
  // line-start-only YAML extractor this literal was invisible to the sweep
  // and would have passed wrongly (not because it was exempt, but because it
  // was never even extracted).
  {
    const root = makeFixtureRoot();
    writeFile(root, ".planning/milestones/v9.0-phases/930-fixture-midline/evidence.json", "{}");
    writeFile(
      root,
      ".github/workflows/fixture_yaml_midline_literal.yml",
      [
        "name: fixture",
        "on: push",
        "jobs:",
        "  test:",
        "    runs-on: ubuntu-latest",
        "    steps:",
        "      - name: Check relevance",
        "        run: |",
        "          if grep -Eq '^(accrue/|\\.planning/phases/930-fixture-midline/)' /tmp/changed.txt; then",
        "            relevant=true",
        "          fi",
        "",
      ].join("\n")
    );
    let error = null;
    try { verifyArchiveInvariants({ root }); } catch (caught) { error = caught; }
    assert.ok(error, "a mid-line YAML literal for an archived, unrouted slug must be detected and fail");
    assert.match(error.message, /930-fixture-midline/);
    fs.rmSync(root, { recursive: true, force: true });
  }

  // Defect-3 counter-regression: the same mid-line YAML literal, annotated
  // with a same-line `archive-sweep-exempt:` marker, passes.
  {
    const root = makeFixtureRoot();
    writeFile(root, ".planning/milestones/v9.0-phases/931-fixture-midline-exempt/evidence.json", "{}");
    writeFile(
      root,
      ".github/workflows/fixture_yaml_midline_literal_exempt.yml",
      [
        "name: fixture",
        "on: push",
        "jobs:",
        "  test:",
        "    runs-on: ubuntu-latest",
        "    steps:",
        "      - name: Check relevance",
        "        run: |",
        "          if grep -Eq '^(accrue/|\\.planning/phases/931-fixture-midline-exempt/)' /tmp/changed.txt; then # archive-sweep-exempt: regex matched against a changed-files listing, not a filesystem read",
        "            relevant=true",
        "          fi",
        "",
      ].join("\n")
    );
    const result = verifyArchiveInvariants({ root });
    assert.equal(result.failures.length, 0, "mid-line YAML literal with a same-line archive-sweep-exempt marker passes");
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

if (!process.env.NODE_TEST_CONTEXT && isMainModule(import.meta.url)) {
  try {
    main();
  } catch (error) {
    console.error(`verify_phase230_archive_invariants: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
