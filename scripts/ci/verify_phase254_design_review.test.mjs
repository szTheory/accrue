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
  captureCells,
  gitReader,
  renderDesignReview,
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
