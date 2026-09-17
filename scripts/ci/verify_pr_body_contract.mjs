#!/usr/bin/env node
//
// REL-04 (232-11, D-59/D-60/D-61): a machine-checkable contract over the
// committed integration pull-request body, so its required properties are
// verified rather than review-time hope. The failure mode this guards
// against is the wall-of-green-check-marks body: reviewers correctly learn
// to skim a body they cannot disbelieve, so every accepted strict flag here
// is wired into a real comparison (never parsed-and-ignored) and prints a
// suffix naming exactly which checks ran, matching this repo's established
// anti-vacuity convention (verify_window_dispositions.mjs,
// verify_ci_script_contract.mjs).
//
// Sections check   (--require-sections):       risk-first heading, the
//                                               required heading set, the
//                                               provenance-versus-behavior
//                                               sentence, and an inline
//                                               rollback command.
// Density check     (--require-density):        line count inside the
//                                               declared density band.
// Falsifiability check:                        RETIRED (quick task
//                                               260917-l7v, SL-A). It is
//                                               gone, not weakened, and it
//                                               must not come back. It
//                                               accepted any markdown bullet
//                                               containing a backtick or a
//                                               link -- a PUNCTUATION check
//                                               wearing the name of a TRUTH
//                                               check -- and three false
//                                               claims shipped through it
//                                               during phase 232, including a
//                                               merge count that was right
//                                               only against a stale local
//                                               `main`. Claim TRUTH now lives
//                                               in the typed sidecar pair
//                                               scripts/ci/render_pr_claims.mjs
//                                               + scripts/ci/verify_pr_claims.mjs,
//                                               which measures each claim
//                                               through a frozen evaluator
//                                               table and fails on a
//                                               measured-versus-asserted
//                                               mismatch. The SHAPE checks
//                                               below are sound and stay:
//                                               claim shape and claim truth
//                                               are different concerns.
// Leak check         (always run):              reuses
//                                               collect_window_dispositions.mjs's
//                                               UNSAFE_PATH_PATTERN verbatim
//                                               (the same pattern
//                                               collect_hygiene_dispositions.mjs
//                                               already reuses) rather than
//                                               defining a third one.
// --expected-repository (when supplied):        any github.com/OWNER/REPO
//                                               reference in the body must
//                                               match.

import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { UNSAFE_PATH_PATTERN } from "./collect_window_dispositions.mjs";

const fail = (message) => { throw new Error(`pr body contract: FAIL: ${message}`); };

// D-59: target 50-80 lines, density over length.
export const DENSITY_BAND = { min: 50, max: 80 };

// D-59: the first heading must name what a reviewer would reject this for,
// not what went well.
export const RISK_HEADING_PATTERN = /^#{1,3}\s*(risk|what (a )?reviewer would reject|reject this (pr|change|integration) for)/i;

// D-59/D-61: besides the risk-first heading, a Rollback section (the D-61
// one-command rollback) and a Scope section (the "no unrelated scope" rule)
// must both be present.
export const REQUIRED_HEADINGS = [
  { name: "Rollback", pattern: /^#{1,3}\s*rollback\b/i },
  { name: "Scope", pattern: /^#{1,3}\s*scope\b/i }
];

function isHeadingLine(line) {
  return /^#{1,6}\s+\S/.test(line);
}

function sectionSlice(lines, headingPattern) {
  const start = lines.findIndex((line) => headingPattern.test(line));
  if (start === -1) return [];
  let end = lines.length;
  for (let index = start + 1; index < lines.length; index += 1) {
    if (isHeadingLine(lines[index])) { end = index; break; }
  }
  return lines.slice(start, end);
}

// D-60: the highest-leverage sentence in the body -- names both branches and
// states which to link (provenance) and which to diff (behavior). Detected
// generically (not by hardcoded branch names) so the contract keeps working
// once the branch names change at a future re-cut: a line naming both
// "link" and "diff" alongside at least two inline code spans (the two
// branch names).
function isProvenanceSentence(line) {
  if (!/\blink\b/i.test(line) || !/\bdiff\b/i.test(line)) return false;
  return (line.match(/`[^`]+`/g) || []).length >= 2;
}

function rollbackHasCodeSpan(lines) {
  const rollbackPattern = REQUIRED_HEADINGS.find((item) => item.name === "Rollback").pattern;
  const slice = sectionSlice(lines, rollbackPattern).join("\n");
  return /`[^`]*git[^`]*`/.test(slice) || /```[\s\S]*?git[\s\S]*?```/.test(slice);
}

export function assertSections(lines) {
  const headingIndex = lines.findIndex((line) => isHeadingLine(line));
  if (headingIndex === -1) fail("body has no markdown heading; the first heading must be the risk section");
  const firstHeading = lines[headingIndex].trim();
  if (!RISK_HEADING_PATTERN.test(firstHeading)) fail(`first heading is not the risk section (what a reviewer would reject this for): "${firstHeading}"`);
  for (const required of REQUIRED_HEADINGS) {
    if (!lines.some((line) => required.pattern.test(line))) fail(`required section heading missing: ${required.name}`);
  }
  if (!lines.some((line) => isProvenanceSentence(line))) fail("provenance-versus-behavior sentence is missing (must name both branches and state which to link and which to diff)");
  if (!rollbackHasCodeSpan(lines)) fail("rollback command must appear inline as a fenced or inline code span, not only as a link");
}

// D-59: line count inside the declared density band. An empty body (zero or
// one blank line) is already below the band floor, so this doubles as the
// "a run over an empty body fails rather than passing" behavior for any
// caller that reaches this check directly.
export function assertDensity(lines) {
  const count = lines.length;
  if (count < DENSITY_BAND.min || count > DENSITY_BAND.max) {
    fail(`body line count ${count} is outside the declared density band ${DENSITY_BAND.min}-${DENSITY_BAND.max}`);
  }
}

// T-232-11-01: reuses collect_window_dispositions.mjs's UNSAFE_PATH_PATTERN
// verbatim -- the same pattern collect_hygiene_dispositions.mjs already
// reuses -- rather than defining a third sanitization pattern.
export function assertLeak(lines) {
  lines.forEach((line, index) => {
    if (UNSAFE_PATH_PATTERN.test(line)) fail(`line ${index + 1} contains a local filesystem path or home-directory reference`);
  });
}

// Wired into a real comparison (not parsed-and-ignored): every
// github.com/OWNER/REPO reference in the body must match --expected-repository.
export function assertExpectedRepository(bodyText, expectedRepository) {
  if (!expectedRepository) return;
  const pattern = /github\.com\/([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+?)(?:\.git)?(?=[)\s>"'`]|$)/g;
  for (const match of bodyText.matchAll(pattern)) {
    if (match[1] !== expectedRepository) fail(`body references repository "${match[1]}" which does not match --expected-repository ${expectedRepository}`);
  }
}

// The single entrypoint every scenario and the CLI both funnel through.
// Always runs the leak check and the expected-repository check (safety, not
// opt-in); the three strict checks are gated on their own flags, exactly as
// each is described in the plan's --require-* options.
export function verifyBody(bodyText, { requireSections = false, requireDensity = false, expectedRepository } = {}) {
  if (typeof bodyText !== "string" || !bodyText.trim()) fail("body is empty");
  const normalized = bodyText.endsWith("\n") ? bodyText.slice(0, -1) : bodyText;
  const lines = normalized.split("\n");
  assertLeak(lines);
  assertExpectedRepository(bodyText, expectedRepository);
  if (requireSections) assertSections(lines);
  if (requireDensity) assertDensity(lines);
  return lines.length;
}

// The conforming positive control: satisfies every check at once (risk-first
// heading, both required headings, the provenance sentence, an inline
// rollback code span, an expected-repository-matching link, every bullet
// falsifiable, and a line count inside the density band).
function buildConformingBody() {
  const header = [
    "## What a reviewer would reject this for",
    "",
    "- Two required lanes are waived, not green, at the recorded head SHA: `docs-contracts-shift-left` and `release-gate`. Evidence: `node scripts/ci/verify_window_dispositions.mjs --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism`.",
    "- The admin-ui-ratchet lane stays parked and waived, not fixed. See `.planning/WINDOWS.md` row 11.",
    "- Nothing outside this milestone's requirement set or `232-CLEANUP-FINDINGS.json` is in scope.",
    "",
    "## Provenance",
    "",
    "Link `integration/v1.62-candidate-recut` to see how this got here; diff `review/v1.62-candidate-code-only` to see what source behavior changed.",
    "",
    "## Rollback",
    "",
    "One command: `git revert -m 1 --no-edit 3f42158d5cd3ffb7134685ae2856074cf544e008`.",
    "",
    "## Scope",
    "",
    "- Every referenced change maps to REL-04, REL-05, HYG-01, or HYG-02, or a numbered finding. See [findings 1-8](https://github.com/szTheory/accrue/blob/main/.planning/phases/232-bounded-hygiene-release-handoff/232-CLEANUP-FINDINGS.json)."
  ];
  const filler = Array.from({ length: 40 }, (_, index) => `- Filler evidence line ${index + 1}, backed by a real command: \`node -e "process.exit(0)"\`.`);
  return [...header, "", ...filler, ""].join("\n");
}

function scenarioBadFirstHeading() {
  const lines = ["## Summary of accomplishments", "", "everything went great"];
  assert.throws(() => assertSections(lines), /first heading is not the risk section/);
}
function scenarioMissingProvenance() {
  const lines = [
    "## What a reviewer would reject this for",
    "",
    "- risk one `evidence`",
    "",
    "## Rollback",
    "",
    "`git revert -m 1 --no-edit abc123`",
    "",
    "## Scope",
    "",
    "- nothing else `ok`"
  ];
  assert.throws(() => assertSections(lines), /provenance-versus-behavior sentence is missing/);
}
function scenarioRollbackLinkOnly() {
  const lines = [
    "## What a reviewer would reject this for",
    "",
    "Link `a/b` to see how this got here; diff `c/d` to see what changed.",
    "",
    "## Rollback",
    "",
    "See [the runbook](https://example.invalid/runbook) for the restore command.",
    "",
    "## Scope",
    "",
    "- nothing else `ok`"
  ];
  assert.throws(() => assertSections(lines), /rollback command must appear inline/);
}
function scenarioLeak() {
  assert.throws(() => assertLeak(["captured from /Users/example/project/output.log"]), /local filesystem path/);
}
function scenarioDensity() {
  assert.throws(() => assertDensity(["one", "two", "three"]), /outside the declared density band/);
}
function scenarioEmptyBody() {
  assert.throws(() => verifyBody("", { requireSections: true, requireDensity: true }), /body is empty/);
}
function scenarioExpectedRepositoryMismatch() {
  assert.throws(() => assertExpectedRepository("see https://github.com/other-owner/other-repo for details", "szTheory/accrue"), /does not match --expected-repository/);
}
function scenarioConformingPositive() {
  const body = buildConformingBody();
  assert.doesNotThrow(() => verifyBody(body, {
    requireSections: true,
    requireDensity: true,
    expectedRepository: "szTheory/accrue"
  }));
}

// The negative-control behaviors named in the plan's <behavior> block,
// plus a mismatched-repository control (proves --expected-repository is
// wired, not parsed-and-ignored) and the one conforming positive control.
const SCENARIOS = [
  ["a body whose first heading is not the risk section fails, naming the offending heading", scenarioBadFirstHeading],
  ["a body missing the provenance-versus-behavior sentence fails", scenarioMissingProvenance],
  ["a body whose rollback instruction is only a link rather than a command present inline fails", scenarioRollbackLinkOnly],
  ["a body containing a local filesystem path prefix fails the leak check", scenarioLeak],
  ["a body outside the declared line-count band fails, naming the measured count and the band", scenarioDensity],
  ["a run over an empty body fails rather than passing", scenarioEmptyBody],
  ["a body referencing a mismatched repository fails the expected-repository check", scenarioExpectedRepositoryMismatch],
  ["a conforming, density-fitting body passes every requested strict check, including the expected-repository check", scenarioConformingPositive]
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
}

const BOOLEAN_FLAGS = new Set(["fixtures", "require-sections", "require-density"]);
const VALUE_OPTIONS = new Set(["body", "expected-repository"]);

function options(argv) {
  const flags = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]; if (!token.startsWith("--")) fail(`unexpected argument: ${token}`);
    const key = token.slice(2);
    if (BOOLEAN_FLAGS.has(key)) { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option: --${key}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${key} requires a value`);
    if (key in values) fail(`--${key} may be provided only once`);
    values[key] = argv[++index];
  }
  return { flags, values };
}

function main() {
  const parsed = options(process.argv.slice(2));
  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();

  if (parsed.flags.has("fixtures")) {
    verifyFixtures();
    const suffix = requestedStrictFlags.length
      ? ` (fixtures: ${requestedStrictFlags.join(", ")})`
      : " (fixtures: no strict flags requested)";
    console.log(`pr body contract: PASS${suffix}`);
    return;
  }

  if (!parsed.values.body) fail("--body is required");
  if (!fs.existsSync(parsed.values.body)) fail(`body file does not exist: ${parsed.values.body}`);
  const bodyText = fs.readFileSync(parsed.values.body, "utf8");

  const lineCount = verifyBody(bodyText, {
    requireSections: parsed.flags.has("require-sections"),
    requireDensity: parsed.flags.has("require-density"),
    expectedRepository: parsed.values["expected-repository"]
  });

  const suffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")}; ${lineCount} lines)`
    : ` (schema-only: no strict flags supplied; ${lineCount} lines)`;
  console.log(`pr body contract: PASS${suffix}`);
}

// D-29: isMainModule() throws (never returns a silent false) when there is
// no invoking entrypoint; caught here and treated as "not the entrypoint" so
// a bare import stays side-effect-free (established pattern, 232-01).
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
    console.error(error.message.startsWith("pr body contract:") ? error.message : `pr body contract: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
