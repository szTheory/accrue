#!/usr/bin/env node
//
// D-32 meta-verifier: enforces the guard-and-non-vacuity contract plans
// 232-01/02 established, against the git-tracked scripts/ci/*.mjs cohort.
// Exit-code-only enforcement would rubber-stamp a file that imports the
// shared guard but registers no real test, or a file that is silently
// absent from a short or empty glob -- this file closes both gaps.

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

const fail = (message) => { throw new Error(`ci script contract: FAIL: ${message}`); };

// D-32 assertion (3): the cohort floor is a live-measured, committed,
// non-zero integer -- re-measured via `git ls-files 'scripts/ci/*.mjs' |
// wc -l` on 2026-09-16 during this plan's own execution (result: 41). Every
// future audit MUST re-measure this live value rather than trusting the
// constant below (D-00/D-15): the constant only stops a SHORT OR EMPTY glob
// from being silently reported as a pass, it is not a ceiling.
const COMMITTED_COHORT_FLOOR = 41;

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
export function assertGuardCoverage(files) {
  if (!Array.isArray(files) || files.length === 0) fail("guard coverage was asked to inspect zero files");
  const offenders = [];
  const bareGuards = [];
  for (const file of files) {
    if (file.relativePath.endsWith(".test.mjs")) continue;
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
export function assertNonVacuity(files) {
  if (!Array.isArray(files) || files.length === 0) fail("non-vacuity was asked to inspect zero files");
  const offenders = [];
  for (const file of files) {
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
    assert.doesNotThrow(() => assertGuardCoverage([conforming]), "a conforming file passes guard coverage");
    assert.doesNotThrow(() => assertNonVacuity([conforming]), "a conforming file passes non-vacuity");
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
    assert.doesNotThrow(() => assertGuardCoverage([vacuous]), "a guard-importing file still passes guard coverage");
    assert.throws(() => assertNonVacuity([vacuous]), /vacuous\.mjs.*vacuity/s);
  });

  // Scenario 3: a synthetic CLI file with no isMainModule import and no
  // *.test.mjs suffix fails --require-guard-coverage, naming the file.
  withScratch((dir) => {
    const guardless = write(dir, "guardless.mjs", 'console.log("hi");\n');
    assert.throws(() => assertGuardCoverage([guardless]), /guardless\.mjs/);
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
    assert.throws(() => assertGuardCoverage([bare]), /bare_guard\.mjs/);
    assert.throws(() => assertGuardCoverage([bare]), /outside try\/catch/);
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
    assert.doesNotThrow(() => assertGuardCoverage([failing]), "a guard-importing file still passes guard coverage");
    assert.throws(() => assertNonVacuity([failing]), /failing\.mjs \(exit \d+\)/);
  });

  // Scenario 5: a cohort whose live file count is below the committed floor
  // fails rather than passing on a short or empty glob.
  assert.throws(() => assertCohortFloor(["a", "b"], 3), /below the committed floor/);
  assert.throws(() => assertCohortFloor([], 1), /empty/);
  assert.throws(() => assertCohortFloor(["a"], 0), /positive integer/);
  assert.doesNotThrow(() => assertCohortFloor(["a", "b", "c"], 3));
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
