// Phase 254 (D-13 / D-14): the per-case result ledger.
//
// The composition run used to read-modify-write one shared results file per case. This
// test proves, with positive controls, that:
//   1. that old algorithm loses a row under an interleaved write (the race is real);
//   2. the per-case layout loses none under the same interleaving and under two real
//      concurrent writer processes;
//   3. merging rejects foreign, duplicate, unparsable and misnamed files, and keys that
//      could escape the directory;
//   4. a Playwright project that depends on a failing upstream project is not passed
//      (so a reconcile step can never certify a run whose cells failed), with a paired
//      passing-upstream control showing the fixture can pass.

import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import { createRequire } from "node:module";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const ADMIN_ROOT = path.join(ROOT, "accrue_admin");
const LEDGER_PATH = path.join(ADMIN_ROOT, "e2e", "phase254-result-ledger.js");
const require = createRequire(import.meta.url);
const ledger = require(LEDGER_PATH);
const { caseResultPath, mergeCaseResults, writeCaseResult } = ledger;

const IDENTITY = Object.freeze({ runId: "a".repeat(32), manifestDigest: "b".repeat(64) });

function row(key, overrides = {}) {
  return { key, run_id: IDENTITY.runId, manifest_sha256: IDENTITY.manifestDigest, status: "passed", ...overrides };
}

function scratch(prefix) {
  return fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), `phase254-ledger-${prefix}-`));
}

// -- the old algorithm, reproduced as a fixture (not imported) -----------------------------

function oldRead(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function oldWrite(filePath, results) {
  const temporaryPath = `${filePath}.${process.pid}.tmp`;
  fs.writeFileSync(temporaryPath, `${JSON.stringify(results, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(temporaryPath, filePath);
}

// appendResult from phase253-composition-helpers.js, split at the read/write seam so a
// test can interleave two callers deterministically.
function oldAppendSteps(filePath, candidate) {
  let snapshot;
  return {
    read() {
      snapshot = oldRead(filePath);
    },
    write() {
      const existing = snapshot.cases.findIndex((entry) => entry.key === candidate.key);
      if (existing === -1) snapshot.cases.push(candidate);
      else snapshot.cases[existing] = candidate;
      oldWrite(filePath, snapshot);
    },
  };
}

test("positive control: the old read-modify-write ledger loses a row under an interleaved write", () => {
  const dir = scratch("old");
  try {
    const filePath = path.join(dir, "results.json");
    oldWrite(filePath, { run_id: IDENTITY.runId, cases: [] });
    const first = oldAppendSteps(filePath, row("case-one"));
    const second = oldAppendSteps(filePath, row("case-two"));
    // A reads, B reads, A writes, B writes: B's stale snapshot overwrites A's row.
    first.read();
    second.read();
    first.write();
    second.write();
    const keys = oldRead(filePath).cases.map((entry) => entry.key);
    assert.deepEqual(keys, ["case-two"], "the old algorithm must lose case-one for this control to mean anything");
    assert.equal(keys.includes("case-one"), false);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("the same interleaving with writeCaseResult loses no row and mergeCaseResults returns both", () => {
  const dir = scratch("new");
  try {
    // The per-case layout has no read step to interleave; both orders must give the same result.
    writeCaseResult(dir, row("case-two"), IDENTITY);
    writeCaseResult(dir, row("case-one"), IDENTITY);
    const merged = mergeCaseResults(dir, IDENTITY);
    assert.deepEqual(merged.map((entry) => entry.key), ["case-one", "case-two"]);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("two concurrent writer processes lose no row", async () => {
  const dir = scratch("concurrent");
  try {
    const writerSource = `
      const { writeCaseResult } = require(${JSON.stringify(LEDGER_PATH)});
      const identity = ${JSON.stringify(IDENTITY)};
      const [dir, prefix] = process.argv.slice(1);
      for (let index = 0; index < 60; index += 1) {
        writeCaseResult(dir, {
          key: prefix + "::case::" + index,
          run_id: identity.runId,
          manifest_sha256: identity.manifestDigest,
          status: "passed",
        }, identity);
      }
    `;
    const runWriter = (prefix) => new Promise((resolve, reject) => {
      const child = spawn(process.execPath, ["-e", writerSource, dir, prefix], { stdio: ["ignore", "ignore", "pipe"] });
      let stderr = "";
      child.stderr.on("data", (chunk) => { stderr += chunk; });
      child.once("error", reject);
      child.once("exit", (code) => (code === 0 ? resolve() : reject(new Error(`writer ${prefix} exited ${code}: ${stderr}`))));
    });
    await Promise.all([runWriter("alpha"), runWriter("beta")]);
    const merged = mergeCaseResults(dir, IDENTITY);
    assert.equal(merged.length, 120);
    assert.equal(new Set(merged.map((entry) => entry.key)).size, 120);
    assert.deepEqual(fs.readdirSync(dir).filter((name) => !name.endsWith(".json")), [], "no temp file may be left behind");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("re-running a case replaces only that case's file", () => {
  const dir = scratch("rerun");
  try {
    writeCaseResult(dir, row("retry-me", { status: "failed" }), IDENTITY);
    writeCaseResult(dir, row("other"), IDENTITY);
    writeCaseResult(dir, row("retry-me", { status: "passed" }), IDENTITY);
    const merged = mergeCaseResults(dir, IDENTITY);
    assert.deepEqual(merged.map((entry) => [entry.key, entry.status]), [["other", "passed"], ["retry-me", "passed"]]);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("importing the ledger module has no side effects", () => {
  const dir = scratch("import");
  try {
    const result = spawnSync(process.execPath, ["-e", `
      const before = JSON.stringify(process.env);
      require(${JSON.stringify(LEDGER_PATH)});
      process.stdout.write(before === JSON.stringify(process.env) ? "env-unchanged" : "env-changed");
    `], { cwd: dir, encoding: "utf8", env: { PATH: process.env.PATH } });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stdout, "env-unchanged");
    assert.deepEqual(fs.readdirSync(dir), [], "importing must not create files or read a manifest");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

// -- merge rejections ------------------------------------------------------------------------

function writeRaw(dir, name, value) {
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, name), typeof value === "string" ? value : JSON.stringify(value));
}

test("mergeCaseResults rejects a row from a different run or manifest", () => {
  const dir = scratch("identity");
  try {
    writeCaseResult(dir, row("good"), IDENTITY);
    assert.equal(mergeCaseResults(dir, IDENTITY).length, 1, "positive control: a matching directory merges");
    writeRaw(dir, `${encodeURIComponent("foreign-run")}.json`, row("foreign-run", { run_id: "c".repeat(32) }));
    assert.throws(() => mergeCaseResults(dir, IDENTITY), /different run or manifest: foreign-run/);
    fs.rmSync(path.join(dir, `${encodeURIComponent("foreign-run")}.json`));
    writeRaw(dir, `${encodeURIComponent("foreign-manifest")}.json`, row("foreign-manifest", { manifest_sha256: "d".repeat(64) }));
    assert.throws(() => mergeCaseResults(dir, IDENTITY), /different run or manifest: foreign-manifest/);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("mergeCaseResults rejects a duplicate key and a file named for another key", () => {
  const dir = scratch("duplicate");
  try {
    writeCaseResult(dir, row("original"), IDENTITY);
    assert.equal(mergeCaseResults(dir, IDENTITY).length, 1, "positive control");
    writeRaw(dir, "copy-of-original.json", row("original"));
    assert.throws(() => mergeCaseResults(dir, IDENTITY), /duplicate case result key: original/);
    fs.rmSync(path.join(dir, "copy-of-original.json"));
    writeRaw(dir, "misnamed.json", row("something-else"));
    assert.throws(() => mergeCaseResults(dir, IDENTITY), /file name does not match its key: misnamed\.json/);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("mergeCaseResults rejects an unparsable file and ignores temp files", () => {
  const dir = scratch("unparsable");
  try {
    writeCaseResult(dir, row("fine"), IDENTITY);
    writeRaw(dir, `${encodeURIComponent("fine")}.json.123.1.tmp`, "{ partial");
    assert.deepEqual(mergeCaseResults(dir, IDENTITY).map((entry) => entry.key), ["fine"], "a half-written temp file is invisible");
    writeRaw(dir, "broken.json", "{ not json");
    assert.throws(() => mergeCaseResults(dir, IDENTITY), /unreadable or not JSON: broken\.json/);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("mergeCaseResults of a directory that does not exist returns no rows", () => {
  assert.deepEqual(mergeCaseResults(path.join(scratch("absent"), "missing"), IDENTITY), []);
});

test("key sanitization rejects path separators and dot segments but accepts composition keys", () => {
  const dir = scratch("keys");
  try {
    for (const bad of ["a/b", "a\\b", "../escape", "..", ".", ".hidden", "a..b", "", "x\0y", "/abs"]) {
      assert.throws(() => caseResultPath(dir, bad), /case result key/, `key ${JSON.stringify(bad)} must be rejected`);
      assert.throws(() => writeCaseResult(dir, row(bad), IDENTITY), /case result key/);
    }
    const composed = "one_row::synthetic-text::320::light";
    const target = caseResultPath(dir, composed);
    assert.equal(path.dirname(target), dir, "a composition key stays inside the directory");
    assert.equal(path.basename(target), `${encodeURIComponent(composed)}.json`);
    assert.notEqual(caseResultPath(dir, "a::b"), caseResultPath(dir, "a__b"), "distinct keys never share a file");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("writeCaseResult rejects a row bound to another run", () => {
  const dir = scratch("write-identity");
  try {
    assert.throws(() => writeCaseResult(dir, row("x", { run_id: "e".repeat(32) }), IDENTITY), /identity differs/);
    assert.throws(() => writeCaseResult(dir, row("x"), { runId: "", manifestDigest: "" }), /needs a runId/);
    assert.deepEqual(fs.existsSync(dir) ? fs.readdirSync(dir) : [], []);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

// -- Playwright project dependency semantics (scratch two-project fixture) -------------------

const PLAYWRIGHT_ROOT = path.dirname(createRequire(path.join(ADMIN_ROOT, "package.json")).resolve("@playwright/test/package.json"));
const PLAYWRIGHT_CLI = path.join(PLAYWRIGHT_ROOT, "cli.js");
const PLAYWRIGHT_ENTRY = createRequire(path.join(ADMIN_ROOT, "package.json")).resolve("@playwright/test");

function runDependencyFixture({ upstreamPasses }) {
  const dir = scratch(upstreamPasses ? "dep-pass" : "dep-fail");
  try {
    const header = `const { test, expect } = require(${JSON.stringify(PLAYWRIGHT_ENTRY)});\n`;
    fs.writeFileSync(path.join(dir, "upstream.spec.js"), `${header}
      test("upstream cell", () => { expect(${upstreamPasses ? "true" : "false"}).toBe(true); });
    `);
    fs.writeFileSync(path.join(dir, "dependent.spec.js"), `${header}
      test("dependent reconcile", () => { expect(1).toBe(1); });
    `);
    fs.writeFileSync(path.join(dir, "pw.config.js"), `
      module.exports = {
        testDir: ${JSON.stringify(dir)},
        reporter: [["json"]],
        workers: 1,
        retries: 0,
        fullyParallel: false,
        projects: [
          { name: "upstream", testMatch: /upstream\\.spec\\.js/ },
          { name: "dependent", testMatch: /dependent\\.spec\\.js/, dependencies: ["upstream"] },
        ],
      };
    `);
    const result = spawnSync(process.execPath, [PLAYWRIGHT_CLI, "test", "--config", path.join(dir, "pw.config.js")], {
      cwd: dir,
      encoding: "utf8",
      env: { ...process.env, CI: "1", FORCE_COLOR: "0" },
      timeout: 120_000,
    });
    const report = JSON.parse(result.stdout);
    const statuses = {};
    const visit = (suite) => {
      for (const spec of suite.specs || []) {
        for (const entry of spec.tests || []) {
          statuses[spec.title] = (entry.results || []).map((attempt) => attempt.status).join(",") || "not-run";
        }
      }
      for (const nested of suite.suites || []) visit(nested);
    };
    for (const suite of report.suites || []) visit(suite);
    return { exitCode: result.status, statuses, stderr: result.stderr };
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

test("dependency control: a dependent project is not passed when its upstream project fails", () => {
  const { exitCode, statuses, stderr } = runDependencyFixture({ upstreamPasses: false });
  assert.equal(statuses["upstream cell"], "failed", stderr);
  assert.ok(Object.hasOwn(statuses, "dependent reconcile"), "the dependent test must still be listed");
  assert.notEqual(statuses["dependent reconcile"], "passed", "the dependent reconcile-shaped test must not pass");
  assert.notEqual(exitCode, 0);
});

test("dependency control (positive): the same fixture passes the dependent test when its upstream passes", () => {
  const { exitCode, statuses, stderr } = runDependencyFixture({ upstreamPasses: true });
  assert.equal(statuses["upstream cell"], "passed", stderr);
  assert.equal(statuses["dependent reconcile"], "passed");
  assert.equal(exitCode, 0);
});
