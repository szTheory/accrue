#!/usr/bin/env node

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import * as selection from "./phase254_selection.mjs";
import { latestResultsFile } from "./verify_a11y_dispositions.mjs";
import { repositoryRoot } from "./phase_evidence_path.mjs";

const ROOT = repositoryRoot;
const HERE = path.dirname(fileURLToPath(import.meta.url));
const FIXTURE_ROOT = path.join(HERE, "fixtures/phase254-transparency");
const REVIEW_VIEW = path.join(ROOT, ".planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-DESIGN-REVIEW.md");
const COVERAGE_GUIDE = path.join(ROOT, "guides/subscription-story-coverage.md");
const A11Y_CLI = path.join(HERE, "verify_a11y_dispositions.mjs");

function fail(message) {
  throw new Error(`Phase 254 transparency: ${message}`);
}

function excludedSection(summary) {
  const marker = "### Excluded case ids";
  const start = summary.indexOf(marker);
  if (start < 0) fail("selection summary omits the excluded case ids section");
  return summary.slice(start + marker.length).trim().split("\n")[0].trim();
}

export function assertSelectionTransparency(summary) {
  const mode = summary.match(/^- Mode: \*\*(full|affected)\*\*$/m)?.[1];
  if (!mode) fail("selection summary does not state a recognized mode");
  const counts = summary.match(/^- Selected: (\d+) of (\d+) cases; excluded: (\d+)$/m);
  if (!counts) fail("selection summary does not state selected/total and excluded counts");
  const [, selectedText, totalText, excludedText] = counts;
  const selected = Number(selectedText);
  const total = Number(totalText);
  const excluded = Number(excludedText);
  if (selected + excluded !== total) fail("selection counts do not reconcile");
  const ids = excludedSection(summary);
  if (mode === "affected") {
    if (excluded === 0 || ids === "" || ids === "None excluded.") fail("affected selection omits excluded case ids");
    if (!/not the full sweep/i.test(summary)) fail("affected selection lacks an explicit not-full-sweep label");
    const wording = summary
      .replace(/not the full sweep/ig, "")
      .replace(/the push to main runs the full sweep/ig, "");
    if (/\bfull (?:run|sweep|coverage)\b/i.test(wording)) fail("affected selection is worded as full-run coverage");
  } else if (selected !== total || excluded !== 0 || ids !== "None excluded.") {
    fail("full selection must select every case and name that none were excluded");
  }
  return true;
}

function assertNoQualityClaim(text) {
  const claims = [
    /\b(?:certif(?:y|ies|ied|ication)|conforms? to|complies? with|meets?)\b.{0,80}\bWCAG\b/i,
    /\bWCAG\b.{0,80}\b(?:certified|conformant|conformance|compliant)\b/i,
    /\b(?:complete|full|comprehensive) accessibility\b/i,
    /\b(?:aesthetic|accessibility) score\s+(?:of|:|=)\s*(?:\d+|[A-F])\b/i,
  ];
  for (const claim of claims) if (claim.test(text)) fail(`unsupported accessibility/design claim: ${claim}`);
}

export function assertAccessibilityTransparency({ designReview, a11yOutput, guideBriefs, guideNextJob }) {
  for (const [label, text] of Object.entries({ designReview, a11yOutput, guideBriefs, guideNextJob })) {
    assertNoQualityClaim(`${label}\n${text}`);
  }

  const captures = designReview.split("## Captures")[1]?.split("## Findings")[0] ?? "";
  const captureRows = captures.match(/^\| CAP-254-\d{2} \|/gm) ?? [];
  const statedCount = designReview.match(/\b(\d+) (?:enumerated )?D-33 capture cells\b/i)?.[1];
  if (!statedCount || Number(statedCount) !== captureRows.length || captureRows.length === 0) {
    fail("design review does not state and enumerate its bounded capture-cell scope");
  }
  const reportedCells = a11yOutput.match(/\b(\d+) cells reported\b/i)?.[1];
  if (!reportedCells || Number(reportedCells) < 1) fail("a11y result does not state the number of enumerated cells reported");
  return true;
}

export function assertBriefTransparency({ guideBriefs, guideNextJob }) {
  if (!/synthetic/i.test(guideBriefs) || !/not adopter research or usage evidence/i.test(guideBriefs)) {
    fail("adopter briefs must be labelled synthetic assumptions, not research or usage evidence");
  }
  if (/\b(?:are|is|based on|represents?)\s+(?:real\s+)?(?:customer|adopter) demand\b/i.test(guideBriefs)) {
    fail("adopter briefs claim real customer demand");
  }
  if (!/Status: `recommendation-input`/i.test(guideNextJob) || !/not a milestone or implementation commitment/i.test(guideNextJob)) {
    fail("next-job table must be labelled recommendation input, not a milestone or commitment");
  }
  if (/\b(?:opened|approved|committed to)\s+(?:a\s+)?milestone\b/i.test(guideNextJob)) {
    fail("next-job recommendation claims an opened or committed milestone");
  }
  return true;
}

function readFixture(name) {
  return JSON.parse(fs.readFileSync(path.join(FIXTURE_ROOT, name), "utf8"));
}

function loadInjectedSubject() {
  const supplied = process.env.GSD_PROHIB_SUBJECT;
  if (!supplied) return null;
  const absolute = path.resolve(ROOT, supplied);
  if (!absolute.startsWith(`${ROOT}${path.sep}`)) fail("injected prohibition subject must stay inside the repository");
  try {
    return JSON.parse(fs.readFileSync(absolute, "utf8"));
  } catch (error) {
    fail(`injected prohibition subject is missing or invalid: ${error.message}`);
  }
}

function section(source, heading) {
  const start = source.indexOf(heading);
  if (start < 0) fail(`coverage guide is missing ${heading}`);
  const bodyStart = start + heading.length;
  const next = source.slice(bodyStart).search(/^## /m);
  return source.slice(start, next < 0 ? source.length : bodyStart + next);
}

function currentSurfaces() {
  const projection = JSON.parse(fs.readFileSync(path.join(ROOT, "accrue_admin/storybook/phase254-selection.json"), "utf8"));
  const changed = selection.readChangedPathsFile("scripts/ci/fixtures/phase254-selection/collection-only.txt", { root: ROOT });
  const report = selection.selectCases({
    projection,
    run: { ...changed.run, workflow: "ci", job: "admin-phase200-guardrails", run_id: "transparency-test" },
    changedPaths: changed.changedPaths,
    fullReasons: changed.fullReasons,
    fixtureSource: changed.fixtureSource,
  });
  const selectionSummary = selection.renderSelectionSummary(report);

  const a11y = spawnSync(process.execPath, [A11Y_CLI, "--results-latest"], { cwd: ROOT, encoding: "utf8" });
  if (a11y.status !== 0) fail(`current a11y output failed (${a11y.status}): ${a11y.stderr}`);
  const designReview = fs.readFileSync(REVIEW_VIEW, "utf8");
  const guide = fs.readFileSync(COVERAGE_GUIDE, "utf8");
  // Resolve the same selected results bundle as the validator to keep scope bound to a real run.
  const results = JSON.parse(fs.readFileSync(latestResultsFile(ROOT), "utf8"));
  const guideBriefs = section(guide, "## Synthetic adopter briefs");
  const guideNextJob = section(guide, "## Next-job candidates");
  return { selectionSummary, designReview, a11yOutput: a11y.stdout, guideBriefs, guideNextJob, results };
}

function assertSurfaces(surfaces, { requireResults = false } = {}) {
  assertSelectionTransparency(surfaces.selectionSummary);
  assertAccessibilityTransparency(surfaces);
  assertBriefTransparency(surfaces);
  if (requireResults) {
    assert.ok(Array.isArray(surfaces.results.cases) && surfaces.results.cases.length > 0, "a11y scope must come from an actual enumerated results bundle");
  }
  return true;
}

test("current generated selection, accessibility, design review and curation surfaces stay scoped and honest", () => {
  const surfaces = currentSurfaces();
  assertSurfaces(surfaces, { requireResults: true });
  const reported = Number(surfaces.a11yOutput.match(/\b(\d+) cells reported\b/i)?.[1]);
  assert.equal(reported, surfaces.results.cases.length, "the a11y report count must match the actual results bundle");
});

test("the prohibition subject stays within the bounded and truthful presentation contract", () => {
  const subject = loadInjectedSubject() ?? currentSurfaces();
  assertSurfaces(subject);
});

test("clean transparency fixture passes all three bounded checks", () => {
  const surfaces = readFixture("clean.json");
  assertSelectionTransparency(surfaces.selectionSummary);
  assertAccessibilityTransparency(surfaces);
  assertBriefTransparency(surfaces);
});

test("affected selection cannot omit exclusions while claiming a full run", () => {
  const clean = readFixture("clean.json");
  const violation = readFixture("selection-violation.json");
  for (const key of Object.keys(clean)) if (key !== "selectionSummary") assert.equal(violation[key], clean[key], `${key} must remain unchanged`);
  assert.throws(() => assertSelectionTransparency(violation.selectionSummary), /excluded case ids|full-run coverage/i);
});

test("bounded accessibility/design output rejects a conformance claim", () => {
  const clean = readFixture("clean.json");
  const violation = readFixture("a11y-claim-violation.json");
  for (const key of Object.keys(clean)) if (key !== "designReview") assert.equal(violation[key], clean[key], `${key} must remain unchanged`);
  assert.throws(() => assertAccessibilityTransparency(violation), /unsupported accessibility\/design claim/i);
});

test("synthetic briefs and recommendation input cannot become customer demand or a milestone", () => {
  const clean = readFixture("clean.json");
  const violation = readFixture("brief-violation.json");
  for (const key of Object.keys(clean)) if (key !== "guideBriefs") assert.equal(violation[key], clean[key], `${key} must remain unchanged`);
  assert.throws(() => assertBriefTransparency(violation), /real customer demand/i);
});
