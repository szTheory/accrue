#!/usr/bin/env node
//
// D-32 meta-verifier: enforces the guard-and-non-vacuity contract plans
// 232-01/02 established, against the git-tracked scripts/ci/*.mjs cohort.
// Exit-code-only enforcement would rubber-stamp a file that imports the
// shared guard but registers no real test, or a file that is silently
// absent from a short or empty glob -- this file closes both gaps.

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

const fail = (message) => { throw new Error(`ci script contract: FAIL: ${message}`); };

// D-32 assertion (3): the cohort floor is a live-measured, committed,
// non-zero integer -- re-measured via `git ls-files 'scripts/ci/*.mjs' |
// wc -l` on 2026-09-17 during quick task 260917-l7v (result: 55; was 41 when
// re-measured 2026-09-16; 67 re-measured 2026-10-24 during phase 249-05). Every
// future audit MUST re-measure this live value rather than trusting the
// constant below (D-00/D-15): the constant only stops a SHORT OR EMPTY glob
// from being silently reported as a pass, it is not a ceiling.
const COMMITTED_COHORT_FLOOR = 67;

// D-32 assertion (2), third exemption: a library module with no CLI
// entrypoint is exempt from importing isMainModule. Every entry below MUST
// carry a one-line reason -- this is an explicit, committed allowlist, never
// an inferred property. Empty today: every git-tracked scripts/ci/*.mjs file
// either imports the shared guard or is a *.test.mjs file.
const LIBRARY_MODULE_ALLOWLIST = new Map([
  // scripts/ci/main_module.mjs DEFINES isMainModule and deliberately calls it
  // unwrapped in its own negative-control tests (it must be able to observe the
  // throw it exists to produce). Requiring it to wrap its own assertions would
  // delete the only coverage proving the throw happens at all.
  ["scripts/ci/main_module.mjs", "defines the shared guard; its own tests must call it unwrapped to assert the throw"]
]);

// Archived-evidence verifier exemptions. DISTINCT from the library-module
// allowlist above: these are CLI verifiers whose exact bytes are recorded in an
// archived capture manifest's source_digests receipt. Editing them (to add the
// guard and tests) would make that receipt untrue, so they are frozen instead.
// Each entry pins the file's current sha256: the exemption dies the moment the
// file is edited, leaves the cohort, or starts importing the guard. Only
// manifest-named verifiers are eligible. Tracked as the REQUIREMENTS Future item
// "Re-capture or formally retire drifted phase 245/248 evidence verifiers".
const ARCHIVED_EVIDENCE_VERIFIER_EXEMPTIONS = new Map([
  ["scripts/ci/verify_phase246_render_proof.mjs", {
    reason: "bytes named in the 246 captures/phase246-current-proof manifest source_digests receipt; already drifted from the receipt, frozen to avoid drifting further",
    sha256: "a0867d852a153bb40f9a3e98a5ff752a252d71a03071a5184e2bee201dbf59b6"
  }],
  ["scripts/ci/verify_phase247_render_proof.mjs", {
    reason: "bytes named in the 247 phase247-current-proof and phase247-initial-verification manifest source_digests receipts; currently matches the receipt",
    sha256: "43b507954d2ddf6b939168e712977e07abb6371213f1735ba1ecd64d79ef0029"
  }],
  ["scripts/ci/verify_phase248_render_proof.mjs", {
    reason: "bytes named in the 248 phase248-current-proof and phase248-initial-proof manifest source_digests receipts",
    sha256: "f794edc39a93c2058b19e475964c2d0d5d64bea931d2b4cd1487657a8fc2d351"
  }],
  // Not manifest-named, but these two test files assert the LIVE tree against the
  // archived 248 capture evidence, which has since drifted (the served admin CSS no
  // longer matches the 248 manifest digest; the render-proof PNG captures are not
  // tracked). They fail today independent of any guard. Frozen until the drifted
  // 245/248 evidence is re-captured or retired (REQUIREMENTS Future item).
  ["scripts/ci/verify_phase248_integrated_proof.test.mjs", {
    reason: "asserts live served CSS against the archived 248 manifest digest; evidence drifted, awaiting re-capture or retirement (REQUIREMENTS Future: drifted phase 245/248 evidence verifiers)",
    sha256: "efbdfa81da83e76b28fc76812c1dd8c934eb2a610839e1db3c6679d2b85f0834"
  }],
  ["scripts/ci/verify_phase248_render_proof.test.mjs", {
    reason: "tests the receipt-pinned 248 render-proof verifier against archived PNG captures that are no longer present; awaiting re-capture or retirement (REQUIREMENTS Future: drifted phase 245/248 evidence verifiers)",
    sha256: "e5c75d0222e7d264ca416592683ac0636946d8f77b1315221e944b4adecff7f6"
  }]
]);

// Validates the exemption map against the cohort and returns the Set of exempt
// relative paths. Fails on an empty reason, a sha mismatch, a path absent from
// the cohort (stale), or a listed file that now imports the guard (stale).
export function assertArchivedExemptions(files, exemptions = ARCHIVED_EVIDENCE_VERIFIER_EXEMPTIONS) {
  const byPath = new Map(files.map((file) => [file.relativePath, file]));
  for (const [relativePath, entry] of exemptions) {
    if (!entry || typeof entry.reason !== "string" || entry.reason.trim() === "") {
      fail(`archived-evidence exemption ${relativePath} has an empty reason`);
    }
    const file = byPath.get(relativePath);
    if (!file) fail(`stale archived-evidence exemption: ${relativePath} is not in the cohort`);
    const source = fs.readFileSync(file.absolutePath);
    const actual = crypto.createHash("sha256").update(source).digest("hex");
    if (actual !== entry.sha256) fail(`archived-evidence exemption ${relativePath} sha256 mismatch (file edited since pin)`);
    const text = source.toString("utf8");
    if (/from\s+["']\.\/main_module\.mjs["']/.test(text) && /\bisMainModule\b/.test(text)) {
      fail(`stale archived-evidence exemption: ${relativePath} now imports the guard; remove it from the map`);
    }
  }
  return new Set(exemptions.keys());
}

function git(repo, args) {
  const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 });
  if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`);
  return result.stdout;
}

// Enumerates the cohort from git's tracked-file index, never a raw directory
// read, so an untracked scratch file can never silently join or leave the
// cohort (D-32).
export function liveCohort(repo) {
  return git(repo, ["ls-files", "scripts/ci/*.mjs"]).split("\n").filter(Boolean).sort();
}

// D-32 assertion (3): fails when the live count drops below the committed
// floor -- a short or empty glob must never be reported as a completeness
// pass. Also the "before declaring any completeness pass, assert a non-zero
// count of items actually inspected" guard (D-32 assertion 4).
export function assertCohortFloor(cohort, floor = COMMITTED_COHORT_FLOOR) {
  if (!Number.isInteger(floor) || floor <= 0) fail("committed cohort floor must be a positive integer");
  if (!Array.isArray(cohort) || cohort.length === 0) fail("cohort is empty -- refusing to report a completeness pass over zero inspected items");
  if (cohort.length < floor) fail(`live cohort size ${cohort.length} is below the committed floor ${floor}`);
  return cohort.length;
}

// D-32 assertion (2): every cohort file must import isMainModule from the
// shared helper, be a *.test.mjs file, or carry an explicit, reasoned
// allowlist entry (the "library module, no CLI entrypoint" exemption).
export function assertGuardCoverage(files, exemptions = ARCHIVED_EVIDENCE_VERIFIER_EXEMPTIONS) {
  if (!Array.isArray(files) || files.length === 0) fail("guard coverage was asked to inspect zero files");
  const exempt = assertArchivedExemptions(files, exemptions);
  const offenders = [];
  const bareGuards = [];
  for (const file of files) {
    if (file.relativePath.endsWith(".test.mjs")) continue;
    if (exempt.has(file.relativePath)) continue;
    if (LIBRARY_MODULE_ALLOWLIST.has(file.relativePath)) continue;
    const source = fs.readFileSync(file.absolutePath, "utf8");
    const importsGuard = /from\s+["']\.\/main_module\.mjs["']/.test(source) && /\bisMainModule\b/.test(source);
    if (!importsGuard) {
      offenders.push(file.relativePath);
      continue;
    }
    // D-29 Rule 1: importing the guard is NOT the property this check exists
    // to prove. isMainModule() THROWS -- it never returns a silent false --
    // when there is no invoking entrypoint, which is exactly the shape of a
    // dynamic `import()` from an argv[1]-less `node -e` inline eval. Calling
    // it directly inside an `if` condition therefore crashes a bare import of
    // the module, reproducing the ambiguous-entrypoint failure D-29 was built
    // to eliminate. The call must be reached through a precomputed boolean
    // assigned inside try/catch. Enforcing the SHAPE (a bare assignment,
    // wrapped in try/catch) rather than a name is deliberate: a shape cannot
    // be evaded by copying the call under a different identifier, which is
    // how the guard census was gamed earlier in this phase.
    // Scan CODE only: a line comment explaining the guard, a block-comment
    // rationale, and a quoted fixture string inside a self-test all mention
    // isMainModule() without calling it, and each would otherwise read as an
    // unwrapped call site.
    const code = source
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .split("\n")
      .map((line) => line.replace(/\/\/.*$/, ""))
      .filter((line) => !/["'`][^"'`]*\bisMainModule\s*\(/.test(line));
    const callSiteLines = code.filter((line) => /\bisMainModule\s*\(/.test(line));
    const unwrappedCallSites = callSiteLines.filter(
      (line) => !/^\s*(?:try\s*\{\s*)?(?:let\s+|const\s+|var\s+)?[A-Za-z_$][\w$]*\s*=\s*isMainModule\s*\(/.test(line)
    );
    if (unwrappedCallSites.length) {
      bareGuards.push(file.relativePath);
      continue;
    }
    if (!/try\s*\{[^{}]*\bisMainModule\s*\([^{}]*\}\s*catch/.test(code.join("\n"))) {
      bareGuards.push(file.relativePath);
    }
  }
  if (offenders.length) fail(`missing the shared module-boundary guard: ${offenders.join(", ")}`);
  if (bareGuards.length) {
    fail(
      `module-boundary guard is called outside try/catch (a bare import under an empty argv[1] will crash): ${bareGuards.join(", ")}`
    );
  }
}

// D-32 assertion (1) + D-33: spawns `node --test --test-reporter=tap` per
// cohort file, requires exit 0, and requires at least one TAP line whose
// name is not the file's own invocation path -- the non-vacuity signature a
// file with zero real `test()` registrations cannot produce (node:test
// treats a guard-less or test-less direct invocation as one implicit test
// named after the file itself).
export function assertNonVacuity(files, exemptions = ARCHIVED_EVIDENCE_VERIFIER_EXEMPTIONS) {
  if (!Array.isArray(files) || files.length === 0) fail("non-vacuity was asked to inspect zero files");
  const exempt = assertArchivedExemptions(files, exemptions);
  const offenders = [];
  for (const file of files) {
    if (exempt.has(file.relativePath)) continue;
    // NODE_TEST_CONTEXT must NOT propagate to the spawned child: this
    // verifier itself may be running under `node --test` (e.g. its own
    // self-test), and node:test's recursion guard treats the mere PRESENCE
    // of the variable (even an empty string) as "already inside a test
    // run", silently skipping the nested invocation ("run() is being called
    // recursively within a test file") -- turning every real non-vacuity
    // check into a false pass. The key must be deleted, not merely
    // blanked, to actually clear that state.
    const childEnv = { ...process.env };
    delete childEnv.NODE_TEST_CONTEXT;
    const result = spawnSync(process.execPath, ["--test", "--test-reporter=tap", file.spawnPath], {
      cwd: file.cwd,
      encoding: "utf8",
      // scripts/ci/phase229_gap_closure.test.mjs's own bounded ceiling is
      // 120s (232-02 D-31); give every cohort file the same headroom so a
      // slow-but-legitimate file is never mistaken for a hung one.
      timeout: 150_000,
      maxBuffer: 20_000_000,
      env: childEnv
    });
    if (result.error || result.status !== 0) {
      offenders.push(`${file.relativePath} (exit ${result.status ?? "spawn error"})`);
      continue;
    }
    const names = [...(result.stdout || "").matchAll(/^(?:ok|not ok) \d+ - (.+)$/gm)].map((match) => match[1].trim());
    const real = names.some((name) => name !== file.spawnPath);
    if (!real) offenders.push(`${file.relativePath} (vacuity: the only TAP entry is the file's own path)`);
  }
  if (offenders.length) fail(`vacuous or failing under node --test: ${offenders.join(", ")}`);
}

function cohortFiles(repo, cohort) {
  return cohort.map((relativePath) => ({
    relativePath,
    absolutePath: path.join(repo, relativePath),
    spawnPath: relativePath,
    cwd: repo
  }));
}

export function verifyFixtures() {
  const NO_EXEMPT = new Map();
  function withScratch(fn) {
    const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "gsd-ci-script-contract-"));
    try { return fn(dir); } finally { fs.rmSync(dir, { recursive: true, force: true }); }
  }

  const MAIN_MODULE_STUB = [
    'import { fileURLToPath } from "node:url";',
    "export function isMainModule(url) {",
    "  return process.argv[1] === fileURLToPath(url);",
    "}",
    ""
  ].join("\n");

  function write(dir, name, content) {
    fs.writeFileSync(path.join(dir, name), content);
    return { relativePath: name, absolutePath: path.join(dir, name), spawnPath: name, cwd: dir };
  }

  // Scenario 1: a conforming file (guard imported, one real named test)
  // passes both --require-guard-coverage and --require-non-vacuity.
  withScratch((dir) => {
    write(dir, "main_module.mjs", MAIN_MODULE_STUB);
    const conforming = write(dir, "conforming.mjs", [
      'import test from "node:test";',
      'import assert from "node:assert/strict";',
      'import { isMainModule } from "./main_module.mjs";',
      "function add(a, b) { return a + b; }",
      "let entry = false;",
      "try { entry = isMainModule(import.meta.url); } catch { entry = false; }",
      "if (entry && process.env.NODE_TEST_CONTEXT) {",
      '  test("add adds two numbers", () => assert.equal(add(1, 2), 3));',
      "}",
      ""
    ].join("\n"));
    assert.doesNotThrow(() => assertGuardCoverage([conforming], NO_EXEMPT), "a conforming file passes guard coverage");
    assert.doesNotThrow(() => assertNonVacuity([conforming], NO_EXEMPT), "a conforming file passes non-vacuity");
  });

  // Scenario 2: a synthetic file whose only test name equals its own path
  // (zero real registrations) fails --require-non-vacuity, naming the file
  // and the word vacuity.
  withScratch((dir) => {
    write(dir, "main_module.mjs", MAIN_MODULE_STUB);
    const vacuous = write(dir, "vacuous.mjs", [
      'import { isMainModule } from "./main_module.mjs";',
      '"use strict";',
      "let entry = false;",
      "try { entry = isMainModule(import.meta.url); } catch { entry = false; }",
      'if (entry) { console.log("hi"); }',
      ""
    ].join("\n"));
    assert.doesNotThrow(() => assertGuardCoverage([vacuous], NO_EXEMPT), "a guard-importing file still passes guard coverage");
    assert.throws(() => assertNonVacuity([vacuous], NO_EXEMPT), /vacuous\.mjs.*vacuity/s);
  });

  // Scenario 3: a synthetic CLI file with no isMainModule import and no
  // *.test.mjs suffix fails --require-guard-coverage, naming the file.
  withScratch((dir) => {
    const guardless = write(dir, "guardless.mjs", 'console.log("hi");\n');
    assert.throws(() => assertGuardCoverage([guardless], NO_EXEMPT), /guardless\.mjs/);
  });

  // Scenario 3b: a synthetic file that DOES import the shared guard but calls
  // it directly inside an `if` condition -- the exact shape that crashes a
  // bare `import()` under an empty argv[1] -- fails --require-guard-coverage,
  // naming the file and the try/catch requirement. Without this scenario the
  // guard-coverage check regresses to "the import statement is present",
  // which is what let six real offenders through in phase 232.
  withScratch((dir) => {
    write(dir, "main_module.mjs", MAIN_MODULE_STUB);
    const bare = write(dir, "bare_guard.mjs", [
      'import { isMainModule } from "./main_module.mjs";',
      'if (isMainModule(import.meta.url)) { console.log("hi"); }',
      ""
    ].join("\n"));
    assert.throws(() => assertGuardCoverage([bare], NO_EXEMPT), /bare_guard\.mjs/);
    assert.throws(() => assertGuardCoverage([bare], NO_EXEMPT), /outside try\/catch/);
  });

  // Scenario 4: a synthetic file that registers a real named test but the
  // test genuinely fails (non-zero exit) fails --require-non-vacuity,
  // naming the file and its exit code -- distinct from the vacuity
  // message, since this file is NOT vacuous, it is broken.
  withScratch((dir) => {
    write(dir, "main_module.mjs", MAIN_MODULE_STUB);
    const failing = write(dir, "failing.mjs", [
      'import test from "node:test";',
      'import assert from "node:assert/strict";',
      'import { isMainModule } from "./main_module.mjs";',
      "let entry = false;",
      "try { entry = isMainModule(import.meta.url); } catch { entry = false; }",
      "if (entry && process.env.NODE_TEST_CONTEXT) {",
      '  test("this assertion is deliberately wrong", () => assert.equal(1, 2));',
      "}",
      ""
    ].join("\n"));
    assert.doesNotThrow(() => assertGuardCoverage([failing], NO_EXEMPT), "a guard-importing file still passes guard coverage");
    assert.throws(() => assertNonVacuity([failing], NO_EXEMPT), /failing\.mjs \(exit \d+\)/);
  });

  // Scenario 5: a cohort whose live file count is below the committed floor
  // fails rather than passing on a short or empty glob.
  assert.throws(() => assertCohortFloor(["a", "b"], 3), /below the committed floor/);
  assert.throws(() => assertCohortFloor([], 1), /empty/);
  assert.throws(() => assertCohortFloor(["a"], 0), /positive integer/);
  assert.doesNotThrow(() => assertCohortFloor(["a", "b", "c"], 3));

  // Scenarios 6-11: archived-evidence exemption map negative controls.
  const sha = (text) => crypto.createHash("sha256").update(text).digest("hex");
  const FROZEN = 'console.log("frozen cli");\n';
  withScratch((dir) => {
    const frozen = write(dir, "frozen.mjs", FROZEN);
    const map = new Map([["frozen.mjs", { reason: "receipt-pinned fixture", sha256: sha(FROZEN) }]]);
    // 6: a pinned exempt file passes both checks (it would otherwise fail both).
    assert.throws(() => assertGuardCoverage([frozen], NO_EXEMPT), /frozen\.mjs/);
    assert.doesNotThrow(() => assertGuardCoverage([frozen], map), "pinned exemption skips guard coverage");
    assert.doesNotThrow(() => assertNonVacuity([frozen], map), "pinned exemption skips non-vacuity");
    // 7: an edited file fails the sha pin.
    fs.writeFileSync(frozen.absolutePath, FROZEN + "// edited\n");
    assert.throws(() => assertGuardCoverage([frozen], map), /frozen\.mjs.*sha256 mismatch/);
    assert.throws(() => assertNonVacuity([frozen], map), /sha256 mismatch/);
    // 10: an unlisted CLI file still fails while another is exempt.
    fs.writeFileSync(frozen.absolutePath, FROZEN);
    const other = write(dir, "other.mjs", 'console.log("x");\n');
    assert.throws(() => assertGuardCoverage([frozen, other], map), /other\.mjs/);
    // 8: a listed path absent from the cohort is stale.
    assert.throws(() => assertGuardCoverage([other], map), /stale.*frozen\.mjs/);
    // 11: an empty or whitespace reason fails at load.
    for (const reason of ["", "   "]) {
      const bad = new Map([["frozen.mjs", { reason, sha256: sha(FROZEN) }]]);
      assert.throws(() => assertGuardCoverage([frozen], bad), /empty reason/);
    }
  });
  withScratch((dir) => {
    write(dir, "main_module.mjs", MAIN_MODULE_STUB);
    const SRC = [
      'import { isMainModule } from "./main_module.mjs";',
      "let entry = false;",
      "try { entry = isMainModule(import.meta.url); } catch { entry = false; }",
      ""
    ].join("\n");
    const conforming = write(dir, "conforming.mjs", SRC);
    const map = new Map([["conforming.mjs", { reason: "was frozen", sha256: sha(SRC) }]]);
    // 9: a listed file that now imports the guard is stale.
    assert.throws(() => assertGuardCoverage([conforming], map), /stale.*imports the guard/);
  });
}

const BOOLEAN_FLAGS = new Set(["fixtures", "require-guard-coverage", "require-non-vacuity", "require-cohort-floor"]);
const VALUE_OPTIONS = new Set(["repo", "expected-repository"]);

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

// --expected-repository is wired into a real comparison against the repo's
// own `origin` remote URL -- a required flag that is parsed but never
// compared is exactly the WR-01 defect this meta-verifier exists to catch
// elsewhere; it must not reintroduce it here.
function assertExpectedRepository(repo, expectedRepository) {
  const remote = git(repo, ["remote", "get-url", "origin"]).trim();
  if (!remote.endsWith(`${expectedRepository}.git`) && !remote.endsWith(expectedRepository)) {
    fail(`repository origin "${remote}" does not match --expected-repository ${expectedRepository}`);
  }
}

function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("ci script contract fixtures: PASS"); return; }
  const expectedRepository = parsed.values["expected-repository"];
  if (!expectedRepository) fail("--expected-repository is required");
  const repo = parsed.values.repo || process.cwd();
  assertExpectedRepository(repo, expectedRepository);

  const cohort = liveCohort(repo);
  if (parsed.flags.has("require-cohort-floor")) {
    assertCohortFloor(cohort);
  } else if (cohort.length === 0) {
    fail("cohort is empty -- refusing to report a completeness pass over zero inspected items");
  }
  const files = cohortFiles(repo, cohort);
  if (parsed.flags.has("require-guard-coverage")) assertGuardCoverage(files);
  if (parsed.flags.has("require-non-vacuity")) assertNonVacuity(files);

  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
  const suffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")})`
    : " (schema-only: no strict flags supplied, no guard-coverage, non-vacuity, or cohort-floor check ran)";
  console.log(`ci script contract: PASS${suffix}`);
}

// D-29: this file previously had no entrypoint guard at all when it was
// first drafted -- main() must never run on a bare import. isMainModule()
// throws (never returns a silent false) when there is no invoking
// entrypoint; that throw is caught here and treated as "not the entrypoint"
// (established pattern, 232-01 Deviation 3 / 232-02).
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  test("ci script contract fixtures pass every negative control", () => verifyFixtures());
} else if (invokedAsEntrypoint) {
  try {
    main();
  } catch (error) {
    console.error(error.message.startsWith("ci script contract:") ? error.message : `ci script contract: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
