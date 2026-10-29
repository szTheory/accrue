import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";
import {
  ASSET_PATHS,
  PHASE_SLUG,
  RECORD_ARTIFACT,
  RUBRIC,
  SCENARIOS,
  VIEW_ARTIFACT,
  assertViewMatches,
  buildRedEvidence,
  captureCells,
  checkRedEvidence,
  classifyRoutedCell,
  evaluateRedReport,
  gitReader,
  parseRedReport,
  renderDesignReview,
  routedA11yCells,
  scanSubscriptionDetailSpacing,
  scenarioNames,
  verifyDesignReview,
  verifyFixtures
} from "./verify_phase254_design_review.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const SCRIPT = path.join(ROOT, "scripts/ci/verify_phase254_design_review.mjs");
const recordPath = resolvePhaseEvidencePath(PHASE_SLUG, RECORD_ARTIFACT, { root: ROOT });
const viewPath = path.join(path.dirname(recordPath), VIEW_ARTIFACT);
const readRecord = () => JSON.parse(fs.readFileSync(recordPath, "utf8"));

function run(args) {
  const env = { ...process.env };
  delete env.NODE_TEST_CONTEXT;
  return spawnSync(process.execPath, [SCRIPT, ...args], { encoding: "utf8", cwd: ROOT, env });
}

for (const [name, scenario] of SCENARIOS) test(`fixture: ${name}`, scenario);

test("every rejection scenario passes together (verifyFixtures)", () => {
  assert.equal(verifyFixtures(), scenarioNames().length);
  assert.ok(scenarioNames().length >= 18);
});

test("--self-test exits 0 and names every scenario", () => {
  const result = run(["--self-test"]);
  assert.equal(result.status, 0, result.stderr);
  for (const name of scenarioNames()) assert.ok(result.stdout.includes(`ok - ${name}`), `self-test did not name: ${name}`);
});

test("unknown flags, a bad --stage and a missing mode fail closed", () => {
  const unknown = run(["--nope"]);
  assert.notEqual(unknown.status, 0);
  assert.match(unknown.stderr, /unknown option/);
  const badStage = run(["--check", "--stage", "finished"]);
  assert.notEqual(badStage.status, 0);
  assert.match(badStage.stderr, /--stage must be one of/);
  const noMode = run([]);
  assert.notEqual(noMode.status, 0);
  assert.match(noMode.stderr, /exactly one of/);
});

test("the real record passes at stage assessment and the CLI agrees", () => {
  const summary = verifyDesignReview(readRecord(), { root: ROOT, stage: "assessment" });
  assert.deepEqual(summary, { stage: "assessment", findings: 9, captures: 16, verdicts: 7, deferred: 6 });
  const result = run(["--check", "--stage", "assessment"]);
  assert.equal(result.status, 0, result.stderr + result.stdout);
  assert.match(result.stdout, /PASS \(stage assessment/);
});

test("the CLI rejects the assessment record when a later stage is demanded", () => {
  const result = run(["--check", "--stage", "corrected"]);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /at stage assessment, not corrected/);
});

test("the committed Markdown view is exactly the renderer output (and an edited view is rejected)", () => {
  const record = readRecord();
  const view = fs.readFileSync(viewPath, "utf8");
  assert.equal(view, renderDesignReview(record));
  assert.doesNotThrow(() => assertViewMatches(record, view));
  assert.throws(() => assertViewMatches(record, view.replace("# Phase 254 design review", "# edited")), /stale or not the renderer output/);
});

test("the real record carries the five locked D-34 dispositions with the lowest owning tier", () => {
  const record = readRecord();
  const byId = new Map(record.findings.map((finding) => [finding.id, finding]));
  const expected = [
    ["DR-254-01", "fixed", "page", "253#1"],
    ["DR-254-02", "contract-amended", "contract", "253#2"],
    ["DR-254-03", "fixed", "component", "253#2"],
    ["DR-254-04", "contract-amended", "contract", "253#2"],
    ["DR-254-05", "fixed", "copy", "253#3"]
  ];
  for (const [id, disposition, tier, origin] of expected) {
    const finding = byId.get(id);
    assert.equal(finding.disposition, disposition, id);
    assert.equal(finding.owning_tier, tier, id);
    assert.equal(finding.origin, origin, id);
    assert.ok(finding.tests.every((entry) => entry.status === "pending"), `${id}: tests are planned at assessment`);
  }
  for (const id of ["DR-254-02", "DR-254-04"]) {
    const contract = byId.get(id).contract;
    assert.equal(contract.section, "Typography");
    assert.match(contract.path, /253-UI-SPEC\.md$/);
    assert.ok(contract.amended_text.startsWith(`| ${contract.row} |`), `${id}: amended_text is the row it names`);
  }
  assert.equal(byId.get("DR-254-02").contract.action, "amend-row");
  assert.equal(byId.get("DR-254-04").contract.action, "add-row");
});

test("the two new candidates are judged once and neither is fixed in the correction batch", () => {
  const record = readRecord();
  const audit = record.findings.find((finding) => finding.id === "DR-254-06");
  const label = record.findings.find((finding) => finding.id === "DR-254-07");
  assert.deepEqual([audit.disposition, audit.origin], ["deferred", "assessment"]);
  assert.deepEqual([label.disposition, label.origin], ["deferred", "assessment"]);
  assert.match(audit.claim, /950/);
  assert.match(label.claim, /Audit event table: Actor \/ Action \/ Timestamp/);
  for (const finding of [audit, label]) {
    assert.ok(record.deferred.some((entry) => entry.finding_id === finding.id && entry.trigger.length > 0));
  }
});

test("all seven rubric dimensions have exactly one verdict, and assessed-no-finding verdicts name captures and source", () => {
  const record = readRecord();
  assert.deepEqual(record.rubric, RUBRIC);
  assert.deepEqual(record.rubric_verdicts.map((verdict) => verdict.dimension).sort(), [...RUBRIC].sort());
  for (const verdict of record.rubric_verdicts.filter((entry) => entry.verdict === "assessed-no-finding")) {
    assert.ok(verdict.capture_ids.length > 0 && verdict.source_refs.length > 0, verdict.dimension);
  }
});

test("the real record carries 16 captures keyed by the four D-33 patterns and AMD-254-03 with its owner acknowledgement", () => {
  const record = readRecord();
  assert.deepEqual(record.captures.map((capture) => capture.key), captureCells().map((cell) => cell.key));
  assert.equal(record.captures.filter((capture) => capture.key.startsWith("phase254-collection-multiple_rows-w")).length, 4);
  for (const capture of record.captures.filter((entry) => entry.state === "review-open" || entry.state === "focus-visible")) {
    assert.equal(capture.sourcing, "mounted");
  }
  assert.ok(record.captures.every((capture) => capture.png_sha256 === null && capture.pass === null));
  const amendment = record.amendments.find((entry) => entry.id === "AMD-254-03");
  assert.deepEqual(amendment.owner_ack, { date: "2026-10-28", status: "owner-accepted at plan time" });
  assert.deepEqual(amendment.decisions, ["D-33"]);
});

test("no score-like key or tmp-path evidence exists in the real record, and the check can see both when seeded", () => {
  const record = readRecord();
  assert.doesNotMatch(JSON.stringify(record), /"[^"]*score[^"]*"\s*:/i);
  const harness = { root: ROOT, stage: "assessment" };
  const scored = structuredClone(record);
  scored.findings[0].score = 3;
  assert.throws(() => verifyDesignReview(scored, harness), /score-like key/);
  const tmpEvidence = structuredClone(record);
  tmpEvidence.findings[0].tests[0].path = "accrue_admin/tmp/phase254/x.js";
  assert.throws(() => verifyDesignReview(tmpEvidence, harness), /tmp directory/);
});

test("a stale source sha on the real record is rejected (positive control for the sha binding)", () => {
  const record = readRecord();
  record.findings[0].source_refs[0].sha = "f".repeat(64);
  assert.throws(() => verifyDesignReview(record, { root: ROOT, stage: "assessment" }), /source_ref sha .* is stale/);
});

test("spacing scan positive control on the real app.css at source_commit: it finds the page-tier overrides the finding cites", () => {
  const record = readRecord();
  const css = gitReader(ROOT)(record.source_commit, ASSET_PATHS.app_css).toString("utf8");
  const found = scanSubscriptionDetailSpacing(css);
  const values = found.map((entry) => entry.value).sort();
  assert.deepEqual(values, ["0", "0 0.25rem", "0.0625rem", "0.0625rem", "0.1875rem"].sort());
  assert.deepEqual(found.map((entry) => entry.line).sort((a, b) => a - b), [2988, 3050, 3060, 6709 + 1, 6720]);
  assert.ok(found.some((entry) => entry.selector === ".ax-subscription-detail-page .ax-stack-md"));
});

test("gitReader reads a file at a commit from a scratch repository and returns null for an absent path or commit", () => {
  const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "design-review-git-"));
  try {
    const git = (...args) => {
      const result = spawnSync("git", ["-C", scratch, ...args], { encoding: "utf8" });
      assert.equal(result.status, 0, result.stderr);
      return result.stdout.trim();
    };
    git("init", "-q");
    git("config", "user.email", "fixture@example.invalid");
    git("config", "user.name", "Fixture");
    git("config", "commit.gpgsign", "false");
    fs.writeFileSync(path.join(scratch, "a.css"), ".a{}\n");
    git("add", "a.css");
    git("commit", "-q", "-m", "fixture");
    const commit = git("rev-parse", "HEAD");
    const read = gitReader(scratch);
    assert.equal(read(commit, "a.css").toString("utf8"), ".a{}\n");
    assert.equal(read(commit, "missing.css"), null);
    assert.equal(read("0".repeat(40), "a.css"), null);
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
});

// ---------------------------------------------------------------------------------------------
// Red evidence: parseRedReport, evaluateRedReport, --record-red / --check-red (D-35, T-254-37).
// ---------------------------------------------------------------------------------------------

const ESC = String.fromCharCode(27);
const assertionMessage = (expected, actual) =>
  `Error: ${ESC}[2mexpect(${ESC}[22m${ESC}[31mreceived${ESC}[39m${ESC}[2m).${ESC}[22mtoBe${ESC}[2m(${ESC}[22m${ESC}[32mexpected${ESC}[39m${ESC}[2m) // Object.is equality${ESC}[22m\n\nExpected: ${ESC}[32m"${expected}"${ESC}[39m\nReceived: ${ESC}[31m"${actual}"${ESC}[39m`;

function playwrightReport(rows) {
  return {
    config: { rootDir: "/repo/accrue_admin/e2e" },
    suites: [
      {
        title: "subscription-design-phase254.spec.js",
        file: "subscription-design-phase254.spec.js",
        suites: [],
        specs: rows.map((row) => ({
          title: row.title,
          file: "subscription-design-phase254.spec.js",
          tests: [{ projectName: "phase254-design", results: row.results ?? [{ status: row.status, error: row.message ? { message: row.message } : undefined }] }]
        }))
      }
    ]
  };
}

const RED_ROWS = [
  { title: "DR-254-01:computed stack gap at 320 light", status: "failed", message: assertionMessage("16px", "3px") },
  { title: "DR-254-02:source declared literals", status: "failed", message: assertionMessage("var(--ax-type-xl)", "1.5rem") },
  { title: "DR-254-02:computed heading at 767px", status: "passed" },
  { title: "DR-254-02:computed heading at 768px", status: "passed" },
  { title: "DR-254-03:computed label size at 1280 dark", status: "failed", message: assertionMessage("12px", "14px") }
];
const EXPECT = { expectFail: ["DR-254-01:computed", "DR-254-02:source", "DR-254-03:computed"], expectPass: ["DR-254-02:computed"] };
const evaluate = (rows, expectations = EXPECT, format = "playwright") => evaluateRedReport(parseRedReport(format === "playwright" ? playwrightReport(rows) : rows, { format }), expectations);

test("parseRedReport: an assertion failure is red and its expected and actual values are parsed without ANSI codes", () => {
  const { failures, passed } = evaluate(RED_ROWS);
  assert.deepEqual(failures.map((row) => row.key), ["DR-254-01:computed", "DR-254-02:source", "DR-254-03:computed"]);
  assert.deepEqual([failures[0].expected, failures[0].actual], ["16px", "3px"]);
  assert.deepEqual([failures[1].expected, failures[1].actual], ["var(--ax-type-xl)", "1.5rem"]);
  assert.deepEqual(passed.map((row) => row.key), ["DR-254-02:computed", "DR-254-02:computed"]);
  assert.equal(failures[0].finding_id, "DR-254-01");
});

test("parseRedReport: a setup crash, a missing result, an unexpected failure and a skip are each rejected (with the passing control above)", () => {
  const crash = RED_ROWS.map((row, index) => (index === 0 ? { ...row, message: "page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:1/" } : row));
  assert.throws(() => evaluate(crash), /did not run to an assertion/);
  const noValues = RED_ROWS.map((row, index) => (index === 0 ? { ...row, message: "Error: expect(received).toEqual(expected)\n\n- Expected  - 1\n+ Received  + 1" } : row));
  assert.throws(() => evaluate(noValues), /did not run to an assertion/);
  const timedOut = RED_ROWS.map((row, index) => (index === 0 ? { ...row, results: [{ status: "timedOut", error: { message: "Test timeout of 30000ms exceeded." } }] } : row));
  assert.throws(() => evaluate(timedOut), /did not run to an assertion/);
  const missing = RED_ROWS.filter((row) => !row.title.startsWith("DR-254-03"));
  assert.throws(() => evaluate(missing), /DR-254-03:computed has no result/);
  const extra = [...RED_ROWS, { title: "DR-254-04:computed stray", status: "failed", message: assertionMessage("a", "b") }];
  assert.throws(() => evaluate(extra), /unexpected failure/);
  const skipped = RED_ROWS.map((row, index) => (index === 0 ? { title: row.title, status: "skipped" } : row));
  assert.throws(() => evaluate(skipped), /skipped/);
  const unkeyed = [...RED_ROWS, { title: "stray test", status: "passed" }];
  assert.throws(() => evaluate(unkeyed), /no DR-NNN-NN/);
  assert.throws(() => evaluate([]), /no test result/);
  assert.throws(() => evaluateRedReport(parseRedReport({}), EXPECT), /not a Playwright JSON report/);
});

test("parseRedReport: a passing key that fails, an expected-red key that passes, and a bare finding id key", () => {
  const computedFailed = RED_ROWS.map((row) => (row.title.includes("767px") ? { ...row, status: "failed", message: assertionMessage("24px", "28px") } : row));
  assert.throws(() => evaluate(computedFailed), /unexpected failure|expected-passing/);
  const sourcePassed = RED_ROWS.map((row) => (row.title.startsWith("DR-254-02:source") ? { title: row.title, status: "passed" } : row));
  assert.throws(() => evaluate(sourcePassed), /DR-254-02:source did not fail/);
  // A bare finding id matches every kind of that finding.
  const bare = evaluate(RED_ROWS, { expectFail: ["DR-254-01", "DR-254-02:source", "DR-254-03"], expectPass: ["DR-254-02:computed"] });
  assert.equal(bare.failures.length, 3);
  assert.throws(() => evaluate(RED_ROWS, { expectFail: ["DR-254-01", "DR-254-03"], expectPass: [] }), /unexpected failure "DR-254-02:source/);
});

test("parseRedReport exunit: a failing assertion is red; a compile error, a raised error and a missing summary are rejected", () => {
  const output = [
    "Running ExUnit with seed: 1, max_cases: 8",
    "",
    "  * test DR-254-05 label is shared (1.0ms)",
    "  * test DR-254-05 path is shared (2.0ms) [L#9]",
    "",
    "  1) test DR-254-05 literal guard (Fixture.CopyTest)",
    "     test/fixture_test.exs:12",
    "     Assertion with == failed",
    "     code:  assert Copy.label() == \"Open activity\"",
    "     left:  \"View activity\"",
    "     right: \"Open activity\"",
    "",
    "Finished in 0.1 seconds",
    "3 tests, 1 failure"
  ].join("\n");
  const parsed = parseRedReport(output, { format: "exunit" });
  assert.deepEqual(parsed.problems, []);
  const { failures, passed } = evaluateRedReport(parsed, { expectFail: ["DR-254-05"] });
  assert.equal(failures.length, 1);
  assert.equal(failures[0].actual, '"View activity"');
  assert.equal(passed.length, 2);
  assert.throws(() => evaluateRedReport(parseRedReport("** (CompileError) test/x.exs:1: undefined function", { format: "exunit" }), { expectFail: ["DR-254-05"] }), /summary line|did not compile/);
  const raised = output.replace(/Assertion with == failed[\s\S]*right: .*"/, "** (UndefinedFunctionError) function Copy.label/0 is undefined");
  assert.throws(() => evaluateRedReport(parseRedReport(raised, { format: "exunit" }), { expectFail: ["DR-254-05"] }), /did not run to an assertion/);
  assert.throws(() => evaluateRedReport(parseRedReport(output.replace("3 tests, 1 failure", "3 tests, 0 failures"), { format: "exunit" }), { expectFail: ["DR-254-05"] }), /summary reports 0 failures/);
});

test("--record-red writes only what the report parses to, and --check-red reproduces it (and rejects a tampered evidence file or report)", () => {
  const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "design-review-red-"));
  try {
    const report = path.join(scratch, "report.json");
    const evidencePath = path.join(scratch, "evidence.json");
    fs.writeFileSync(report, JSON.stringify(playwrightReport(RED_ROWS)));
    const common = ["--report", report, "--spec", "accrue_admin/e2e/subscription-design-phase254.spec.js"];
    const recordArgs = ["--record-red", ...common, "--expect-fail", EXPECT.expectFail.join(","), "--expect-pass", "DR-254-02:computed", "--out", evidencePath, "--command", "node scripts/dev/phase252_lab.mjs browser -- e2e/x.spec.js", "--exit-code", "1"];
    assert.ok(fs.existsSync(path.join(ROOT, "accrue_admin/e2e/subscription-design-phase254.spec.js")), "the design spec exists for --record-red to hash");
    const recorded = run(recordArgs);
    assert.equal(recorded.status, 0, recorded.stderr + recorded.stdout);
    const evidence = JSON.parse(fs.readFileSync(evidencePath, "utf8"));
    assert.deepEqual(evidence.failures.map((row) => row.key), EXPECT.expectFail);
    assert.equal(evidence.commands[0].exit_code, 1);
    assert.match(evidence.commit, /^[0-9a-f]{40}$/);
    assert.match(evidence.spec_sha256, /^[0-9a-f]{64}$/);
    assert.equal(run(["--check-red", "--report", report, "--evidence", evidencePath]).status, 0);
    // Tampered evidence: an invented failure or a changed value no longer matches the parsed report.
    const tampered = structuredClone(evidence);
    tampered.failures[0].actual = "999px";
    fs.writeFileSync(evidencePath, JSON.stringify(tampered));
    const bad = run(["--check-red", "--report", report, "--evidence", evidencePath]);
    assert.notEqual(bad.status, 0);
    assert.match(bad.stderr, /differ from failures\[\]/);
    // A report that no longer reproduces the red set is rejected.
    fs.writeFileSync(evidencePath, JSON.stringify(evidence));
    fs.writeFileSync(report, JSON.stringify(playwrightReport(RED_ROWS.map((row) => (row.title.startsWith("DR-254-01") ? { title: row.title, status: "passed" } : row)))));
    assert.notEqual(run(["--check-red", "--report", report, "--evidence", evidencePath]).status, 0);
    // Recording needs the command and exit code, and refuses a report that is not the expected red set.
    assert.notEqual(run(recordArgs.filter((arg, index, all) => arg !== "--command" && all[index - 1] !== "--command")).status, 0);
    fs.writeFileSync(report, JSON.stringify(playwrightReport(RED_ROWS.slice(0, 2))));
    assert.notEqual(run(recordArgs).status, 0);
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
});

test("buildRedEvidence and checkRedEvidence reject an evidence file with no commit, no expect_fail or a changed spec", () => {
  const parsed = parseRedReport(playwrightReport(RED_ROWS));
  const base = { ...EXPECT, commit: "a".repeat(40), specPath: "accrue_admin/e2e/x.spec.js", specSha256: "b".repeat(64), commands: [{ command: "run", exit_code: 1 }] };
  const evidence = buildRedEvidence(parsed, base);
  assert.deepEqual(checkRedEvidence(parsed, evidence, { specSha256: "b".repeat(64) }), { failures: 3, passed: 2 });
  assert.throws(() => checkRedEvidence(parsed, evidence, { specSha256: "c".repeat(64) }), /spec file changed/);
  assert.throws(() => checkRedEvidence(parsed, { ...evidence, expect_fail: [] }), /no expect_fail/);
  assert.throws(() => buildRedEvidence(parsed, { ...base, commit: "short" }), /40-hex/);
  assert.throws(() => buildRedEvidence(parsed, { ...base, commands: [] }), /exact command/);
});

test("the real routed-defect register: the D-36 bound classifies 8 inside and 102 outside composition cells plus 2 inside journey cells (positive control: the classifier finds both)", () => {
  const register = JSON.parse(spawnSync("git", ["-C", ROOT, "show", "eefee2a62958dbdefe426d5434ed133e91b3e8ec:accrue_admin/e2e/a11y-dispositions.json"], { encoding: "utf8" }).stdout);
  const { inside, outside } = routedA11yCells(register);
  assert.equal(inside.filter((id) => !id.startsWith("journey::")).length, 8);
  assert.equal(inside.filter((id) => id.startsWith("journey::")).length, 2);
  assert.equal(outside.length, 102);
  assert.equal(classifyRoutedCell("page::active::viewport::1280::dark"), "inside");
  assert.equal(classifyRoutedCell("page::active::breakpoint::768::dark"), "outside");
});
