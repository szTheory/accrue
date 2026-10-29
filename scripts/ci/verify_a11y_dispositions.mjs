#!/usr/bin/env node
// Phase 254 UXQ-02 / D-27..D-30: the accessibility disposition register validator and the owner
// source contract.
//
//   --check                Validate the committed register's shape and the owner source contract.
//   --results-latest       Check the newest reconciled Phase 253 results bundle against the
//                          register: every observation matched, every entry matched in a cell that
//                          ran, every cell carrying an a11y block that evaluated at least one rule.
//   --results <path>       The same, for one named results bundle.
//   --self-test            Run every rejection scenario, each paired with a passing control.
//
// The register (accrue_admin/e2e/a11y-dispositions.json) is deliberately narrow: an entry names
// one rule, one result type, one exact target and the exact cells it applies to. The validator
// fails on an unmatched observation, an entry whose cells ran but matched zero nodes (the census
// idiom: a pattern that matches nothing cannot be evidence of anything), a broad target, a node
// count mismatch, a wildcard cell id and an expired review_by. The source contract fails any
// disableRules, exclude or impact filter in the owner files, so suppression is mechanically
// impossible there.

import assert from "node:assert/strict";
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { repositoryRoot } from "./phase_evidence_path.mjs";

const require = createRequire(import.meta.url);
const probes = require("../../accrue_admin/e2e/phase254-a11y-probes.js");

export const REGISTER_PATH = "accrue_admin/e2e/a11y-dispositions.json";
export const RESULTS_ROOT = "accrue_admin/tmp/phase253";
export const OWNER_FILES = Object.freeze([
  "accrue_admin/e2e/phase254-a11y-probes.js",
  "accrue_admin/e2e/phase253-composition-helpers.js",
  "accrue_admin/e2e/subscription-compositions-phase253.spec.js",
]);
export const EXCEPTION_CLASSES = Object.freeze(["routed-defect", "unsupported-mechanism", "axe-limitation", "accepted-exception"]);
export const RESULT_TYPES = Object.freeze(["violation", "incomplete"]);
export const REQUIRED_CONTROLS = Object.freeze([
  "unnamed_button",
  "undersized_overlapping_target",
  "outline_none",
  "unapplied_spacing",
  "unapplied_scaling",
  "motion_under_reduce",
  "undispositioned_incomplete",
]);
export const GEOMETRY_CONTROL_KEY = "geometry::negative-controls::320::light";
// A probe that has no target element in a given cell may report not_applicable for that probe
// and cell only. The list is deliberately empty until a cell is shown to need it.
export const ALLOWED_NOT_APPLICABLE = Object.freeze([]);

const BROAD_TARGETS = new Set(["*", "html", "body", "#main-content", ".psb-sandbox", "main", "#ax-overlay-root"]);

function fail(message) {
  return new Error(`Phase 254 a11y: ${message}`);
}

export function isBroadTarget(target) {
  if (typeof target !== "string") return true;
  const text = target.trim();
  if (text === "" || BROAD_TARGETS.has(text)) return true;
  // A bare tag name (div, button) selects every such element, however many there are.
  return /^[a-z][a-z0-9-]*$/i.test(text);
}

// A journey cell is a checkpoint of the mounted keyboard journey in admin-interactions.spec.js.
// That spec reads the register itself and decides the checkpoint, so these cells never appear in
// a composition results bundle and are exempt from the "cell ran" rules below.
export function isJourneyCell(cellId) {
  return typeof cellId === "string" && cellId.startsWith("journey::");
}

function validDate(text) {
  return typeof text === "string" && /^\d{4}-\d{2}-\d{2}$/.test(text) && !Number.isNaN(Date.parse(`${text}T00:00:00Z`));
}

/** Validates the shape of every entry; returns nothing and throws on the first problem. */
export function validateEntries(register, { today }) {
  if (!validDate(today)) throw fail("validateEntries needs today as YYYY-MM-DD");
  const ids = new Set();
  for (const entry of register.entries) {
    const label = `entry ${entry?.id ?? "(no id)"}`;
    if (!entry || typeof entry !== "object") throw fail("register entry is not an object");
    if (typeof entry.id !== "string" || !/^A11Y-254-\d{2}$/.test(entry.id)) throw fail(`${label}: id must look like A11Y-254-NN`);
    if (ids.has(entry.id)) throw fail(`${label}: duplicate id`);
    ids.add(entry.id);
    if (typeof entry.rule_id !== "string" || entry.rule_id === "") throw fail(`${label}: rule_id is required`);
    if (!RESULT_TYPES.includes(entry.result_type)) throw fail(`${label}: result_type must be violation or incomplete`);
    if (entry.result_type === "incomplete" && (typeof entry.incomplete_reason !== "string" || entry.incomplete_reason === "")) {
      throw fail(`${label}: an incomplete entry needs its incomplete_reason`);
    }
    if (entry.result_type === "violation" && entry.incomplete_reason != null) {
      throw fail(`${label}: a violation entry must not carry an incomplete_reason`);
    }
    if (!Array.isArray(entry.cell_ids) || entry.cell_ids.length === 0 || entry.cell_ids.some((id) => typeof id !== "string" || id === "")) {
      throw fail(`${label}: cell_ids must be a non-empty list of exact cell ids`);
    }
    if (entry.cell_ids.some((id) => /[*?]/.test(id))) throw fail(`${label}: cell_ids must not use a wildcard`);
    if (new Set(entry.cell_ids).size !== entry.cell_ids.length) throw fail(`${label}: cell_ids repeats a cell`);
    const journey = entry.cell_ids.filter(isJourneyCell);
    if (journey.length && journey.length !== entry.cell_ids.length) throw fail(`${label}: a journey entry must not also name composition cells`);
    if (journey.some((id) => !/^journey::D-29::[a-z-]+$/.test(id))) throw fail(`${label}: a journey cell id must look like journey::D-29::<checkpoint>`);
    if (isBroadTarget(entry.target)) throw fail(`${label}: target ${JSON.stringify(entry.target)} is empty or too broad; name the exact node`);
    if (!Number.isInteger(entry.expected_node_count) || entry.expected_node_count < 1) throw fail(`${label}: expected_node_count must be an integer of at least 1`);
    if (typeof entry.sc !== "string" || !/^(\d\.\d\.\d+|best-practice)$/.test(entry.sc)) throw fail(`${label}: sc must be a success criterion number or best-practice`);
    if (!EXCEPTION_CLASSES.includes(entry.exception_class)) throw fail(`${label}: exception_class must be one of ${EXCEPTION_CLASSES.join(", ")}`);
    if (typeof entry.rationale !== "string" || entry.rationale.trim() === "") throw fail(`${label}: rationale is required`);
    if (typeof entry.follow_up_assertion_id !== "string" || entry.follow_up_assertion_id.trim() === "") throw fail(`${label}: follow_up_assertion_id is required`);
    if (!validDate(entry.review_by)) throw fail(`${label}: review_by must be a YYYY-MM-DD date`);
    if (entry.review_by < today) throw fail(`${label}: review_by ${entry.review_by} has expired (today is ${today})`);
  }
}

/**
 * Validates the register against what the cells actually reported.
 *   observations: [{ cell_id, rule_id, result_type, incomplete_reason, target }]
 *   cells:        [{ cell_id, rules_evaluated }] for every cell that ran
 */
export function validateRegister(register, observations, { today, cells, allowUnrun = false } = {}) {
  if (!register || !Array.isArray(register.entries)) throw fail("the register has no entries array");
  validateEntries(register, { today });
  if (!Array.isArray(cells) || cells.length === 0) throw fail("no cell ran, so there is no evidence for or against the register");
  for (const cell of cells) {
    if (!Number.isInteger(cell.rules_evaluated) || cell.rules_evaluated < 1) {
      throw fail(`a cell evaluated ${cell.rules_evaluated ?? 0} rules (${cell.cell_id}); an empty result is evidence only after axe evaluated at least one rule`);
    }
  }
  const ran = new Set(cells.map((cell) => cell.cell_id));

  const byCell = new Map();
  for (const observation of observations) {
    if (!byCell.has(observation.cell_id)) byCell.set(observation.cell_id, []);
    byCell.get(observation.cell_id).push(observation);
  }
  const counts = new Map();
  let matched = 0;
  for (const [cellId, cellObservations] of byCell) {
    if (!ran.has(cellId)) throw fail(`observations name a cell that did not report: ${cellId}`);
    const result = probes.matchDispositions(cellObservations, register, cellId);
    if (result.unmatched.length) {
      const first = result.unmatched[0];
      throw fail(`undispositioned observation in ${cellId}: ${probes.describeObservation(first)} (${result.unmatched.length} unmatched in this cell)`);
    }
    for (const pair of result.matched) {
      if (pair.entry_ids.length > 1) throw fail(`entries ${pair.entry_ids.join(", ")} overlap on ${cellId}: ${probes.describeObservation(pair.observation)}`);
      matched += 1;
    }
    for (const [entryId, count] of Object.entries(result.counts)) counts.set(`${entryId}|${cellId}`, count);
  }

  for (const entry of register.entries) {
    if (entry.cell_ids.every(isJourneyCell)) continue;
    const ranCells = entry.cell_ids.filter((cellId) => ran.has(cellId));
    if (ranCells.length === 0) {
      if (allowUnrun) continue;
      throw fail(`entry ${entry.id} names only cells that did not run, so nothing proves it still matches`);
    }
    for (const cellId of ranCells) {
      const count = counts.get(`${entry.id}|${cellId}`) || 0;
      if (count === 0) {
        throw fail(`entry ${entry.id} matched zero nodes in ${cellId}, a cell that ran -- an entry that matches nothing cannot be evidence of anything; delete it`);
      }
      if (count !== entry.expected_node_count) {
        throw fail(`entry ${entry.id} expected ${entry.expected_node_count} nodes in ${cellId} but matched ${count}`);
      }
    }
  }
  return { entries: register.entries.length, observations: observations.length, matched, cells: cells.length };
}

export function loadRegister(root = repositoryRoot) {
  return probes.readRegister(path.join(root, REGISTER_PATH));
}

// ---------------------------------------------------------------------------------------
// Owner source contract
// ---------------------------------------------------------------------------------------

const BANNED = Object.freeze([
  ["disableRules", /\bdisableRules\b/],
  [".exclude(", /\.exclude\s*\(/],
  ["impact filter", /\bimpact\b/],
  ["withRules", /\bwithRules\s*\(/],
  [".options(", /\.options\s*\(/],
  ["axe.configure", /\baxe\.configure\s*\(/],
]);

function stripComments(source) {
  const withoutBlocks = source.replace(/\/\*[\s\S]*?\*\//g, (block) => block.replace(/[^\n]/g, " "));
  return withoutBlocks.split("\n").map((line) => line.replace(/(^|\s)\/\/.*$/, "$1"));
}

/** Scans owner sources; returns [{ path, line, token }] (empty when clean). */
export function scanOwnerSources(files) {
  const findings = [];
  for (const file of files) {
    stripComments(file.source).forEach((line, index) => {
      for (const [token, pattern] of BANNED) {
        if (pattern.test(line)) findings.push({ path: file.path, line: index + 1, token });
      }
    });
  }
  return findings;
}

export function verifyOwnerSources(root = repositoryRoot) {
  const files = OWNER_FILES.map((relative) => {
    const absolute = path.join(root, relative);
    if (!fs.existsSync(absolute)) throw fail(`owner file is missing: ${relative}`);
    return { path: relative, source: fs.readFileSync(absolute, "utf8") };
  });
  const findings = scanOwnerSources(files);
  if (findings.length) {
    const first = findings[0];
    throw fail(`owner source contract: ${first.token} at ${first.path}:${first.line} (${findings.length} finding(s)); suppression is not allowed in these owners`);
  }
  return files.length;
}

// ---------------------------------------------------------------------------------------
// Results bundle
// ---------------------------------------------------------------------------------------

export function latestResultsFile(root = repositoryRoot) {
  const directory = path.join(root, RESULTS_ROOT);
  if (!fs.existsSync(directory)) throw fail(`no results directory at ${RESULTS_ROOT}`);
  const candidates = fs.readdirSync(directory).filter((name) => /^render-results-[a-f0-9]+\.json$/.test(name))
    .map((name) => ({ name, mtime: fs.statSync(path.join(directory, name)).mtimeMs }))
    .sort((a, b) => b.mtime - a.mtime);
  for (const candidate of candidates) {
    let results;
    try {
      results = JSON.parse(fs.readFileSync(path.join(directory, candidate.name), "utf8"));
    } catch {
      continue;
    }
    if (Array.isArray(results.cases) && results.cases.length > 0 && results.cases.length === (results.expected_case_keys || []).length) {
      return path.join(directory, candidate.name);
    }
  }
  throw fail("no reconciled Phase 253 results bundle was found; run the composition lane first");
}

function requireProbe(row, name) {
  const probe = row.a11y.probes?.[name];
  if (!probe || typeof probe !== "object") throw fail(`deep-probe cell ${row.key} has no ${name} probe result`);
  if (name === "motion") {
    for (const mode of ["reduce", "no_preference"]) {
      const part = probe[mode];
      if (!part || !["checked", "not_applicable"].includes(part.status)) throw fail(`deep-probe cell ${row.key} has no motion result under ${mode}`);
      checkApplicability(row.key, `motion.${mode}`, part);
    }
    return probe;
  }
  if (!["checked", "not_applicable"].includes(probe.status)) throw fail(`deep-probe cell ${row.key} has an unreadable ${name} probe status`);
  checkApplicability(row.key, name, probe);
  if (probe.status === "checked" && !Array.isArray(probe.defects)) throw fail(`deep-probe cell ${row.key} ${name} probe reports no defects list`);
  return probe;
}

function checkApplicability(key, name, probe) {
  if (probe.status !== "not_applicable") return;
  const reason = probe.not_applicable_reason || probe.reason;
  if (typeof reason !== "string" || reason.trim() === "") throw fail(`deep-probe cell ${key} marks ${name} not applicable without a reason`);
  const allowed = ALLOWED_NOT_APPLICABLE.some((item) => item.cell_id === key && item.probe === name);
  // Motion under no-preference legitimately has nothing to measure when no overlay is open.
  const motionException = name === "motion.no_preference";
  if (!allowed && !motionException) throw fail(`deep-probe cell ${key} reports ${name} not applicable, which is not an allowed pair`);
}

/**
 * Checks a reconciled results bundle against the register. Every row must carry an a11y block;
 * every observation must be matched; every deep-probe cell must report every probe; the
 * geometry cell must report each injected control as detected; and a text scale the browser
 * could not apply must be dispositioned as an unsupported mechanism, never as a defect to fix.
 */
export function verifyResults(results, register, { today }) {
  if (!results || !Array.isArray(results.cases) || results.cases.length === 0) throw fail("the results bundle has no cases");
  const observations = [];
  const cells = [];
  for (const row of results.cases) {
    if (!row.a11y || typeof row.a11y !== "object") throw fail(`cell ${row.key} has no a11y block`);
    if (!Number.isInteger(row.a11y.rules_evaluated) || row.a11y.rules_evaluated < 1) {
      throw fail(`cell ${row.key} evaluated ${row.a11y.rules_evaluated ?? 0} rules; axe must evaluate at least one rule in every cell`);
    }
    if (!Array.isArray(row.a11y.observations) || !Array.isArray(row.a11y.matched_dispositions) || typeof row.a11y.probes !== "object") {
      throw fail(`cell ${row.key} has a malformed a11y block`);
    }
    cells.push({ cell_id: row.key, rules_evaluated: row.a11y.rules_evaluated });
    for (const observation of row.a11y.observations) observations.push({ ...observation, cell_id: row.key });
    if (probes.isDeepProbeKey(row.key)) {
      if (row.a11y.deep !== true) throw fail(`cell ${row.key} belongs to the D-28 deep-probe subset but did not run the deep probes`);
      for (const name of probes.DEEP_PROBES) requireProbe(row, name);
    }
    if (row.key === GEOMETRY_CONTROL_KEY) {
      const controls = row.a11y.injected_controls || {};
      for (const name of REQUIRED_CONTROLS) {
        if (controls[name]?.detected !== true) throw fail(`injected control ${name} was not detected in ${row.key}`);
      }
    }
  }
  const allowUnrun = results.selection?.mode === "affected";
  const summary = validateRegister(register, observations, { today, cells, allowUnrun });

  const byId = new Map(register.entries.map((entry) => [entry.id, entry]));
  for (const row of results.cases) {
    const scale = row.a11y.probes?.scale;
    if (scale?.status === "checked" && scale.supported === false) {
      const unsupported = row.a11y.matched_dispositions.some((item) => byId.get(item.id)?.exception_class === "unsupported-mechanism" && byId.get(item.id)?.rule_id === "probe-text-scale");
      if (!unsupported) throw fail(`cell ${row.key}: the browser could not apply text scaling and no unsupported-mechanism disposition names it`);
    }
  }
  return { ...summary, deep_cells: results.cases.filter((row) => probes.isDeepProbeKey(row.key)).length };
}

// ---------------------------------------------------------------------------------------
// Self-test scenarios
// ---------------------------------------------------------------------------------------

const TODAY = "2026-10-29";
const CELL = "multiple_rows::viewport::320::light";
const TARGET = ".ax-data-table-shell tbody > tr:nth-child(1) > td:nth-child(5) > button";

const fixtureEntry = (overrides = {}) => ({
  id: "A11Y-254-01", rule_id: "button-name", result_type: "violation", incomplete_reason: null, cell_ids: [CELL], target: TARGET,
  expected_node_count: 1, sc: "4.1.2", exception_class: "routed-defect", rationale: "fixture", follow_up_assertion_id: "254-12-fix", review_by: "2026-12-31",
  ...overrides,
});
const fixtureObservation = (overrides = {}) => ({ cell_id: CELL, rule_id: "button-name", result_type: "violation", incomplete_reason: null, target: TARGET, ...overrides });
const fixtureCells = (overrides = {}) => [{ cell_id: CELL, rules_evaluated: 41, ...overrides }];
const registerOf = (...entries) => ({ schema_version: 1, entries });
const options = (extra = {}) => ({ today: TODAY, cells: fixtureCells(), ...extra });

export const SCENARIOS = [
  ["matched observation passes (control)", () => {
    assert.equal(validateRegister(registerOf(fixtureEntry()), [fixtureObservation()], options()).matched, 1);
  }],
  ["unmatched observation is undispositioned", () => {
    assert.throws(() => validateRegister(registerOf(), [fixtureObservation()], options()), /undispositioned/);
  }],
  ["unmatched incomplete is undispositioned beside a matched violation", () => {
    const incomplete = fixtureObservation({ rule_id: "color-contrast", result_type: "incomplete", incomplete_reason: "bgOverlap", target: ".ax-x" });
    assert.throws(() => validateRegister(registerOf(fixtureEntry()), [fixtureObservation(), incomplete], options()), /undispositioned.*color-contrast/);
  }],
  ["entry whose cell ran but matched zero nodes fails", () => {
    assert.throws(() => validateRegister(registerOf(fixtureEntry()), [], options()), /matched zero nodes/);
  }],
  ["broad targets are rejected", () => {
    for (const target of ["*", "html", "body", "#main-content", ".psb-sandbox", "div", ""]) {
      assert.throws(() => validateRegister(registerOf(fixtureEntry({ target })), [fixtureObservation({ target })], options()), /target/);
    }
    assert.equal(isBroadTarget(TARGET), false);
  }],
  ["node-count mismatch fails", () => {
    assert.throws(() => validateRegister(registerOf(fixtureEntry({ expected_node_count: 2 })), [fixtureObservation()], options()), /expected 2 nodes.*matched 1/);
  }],
  ["wildcard cell ids are rejected", () => {
    assert.throws(() => validateRegister(registerOf(fixtureEntry({ cell_ids: ["multiple_rows::viewport::*::light"] })), [fixtureObservation()], options()), /wildcard/);
  }],
  ["expired review_by fails and today passes", () => {
    assert.throws(() => validateRegister(registerOf(fixtureEntry({ review_by: "2026-10-28" })), [fixtureObservation()], options()), /expired/);
    validateRegister(registerOf(fixtureEntry({ review_by: TODAY })), [fixtureObservation()], options());
  }],
  ["empty register passes only when every cell evaluated a rule", () => {
    assert.equal(validateRegister(registerOf(), [], options()).entries, 0);
  }],
  ["empty register fails when one cell evaluated zero rules", () => {
    assert.throws(() => validateRegister(registerOf(), [], options({ cells: fixtureCells({ rules_evaluated: 0 }) })), /evaluated 0 rules/);
  }],
  ["empty register fails when no cell ran", () => {
    assert.throws(() => validateRegister(registerOf(), [], options({ cells: [] })), /no cell ran/);
  }],
  ["empty register fails when the register file is absent or unparsable", () => {
    const directory = fs.mkdtempSync(path.join(process.env.TMPDIR || "/tmp", "a11y-register-"));
    try {
      assert.throws(() => loadRegister(directory), /absent/);
      fs.mkdirSync(path.join(directory, "accrue_admin/e2e"), { recursive: true });
      fs.writeFileSync(path.join(directory, REGISTER_PATH), "{ nope");
      assert.throws(() => loadRegister(directory), /unparsable/);
    } finally {
      fs.rmSync(directory, { recursive: true, force: true });
    }
  }],
  ["owner source scan flags seeded suppressions and passes a clean builder", () => {
    for (const source of [
      "builder.disableRules(['color-contrast']);",
      "builder.exclude('.ax-flash');",
      "return results.violations.filter((v) => v.impact === 'critical');",
    ]) {
      assert.equal(scanOwnerSources([{ path: "seeded.js", source }]).length >= 1, true, source);
    }
    assert.deepEqual(scanOwnerSources([{ path: "clean.js", source: "// disableRules is banned\nnew AxeBuilder({ page }).withTags(['wcag2a']).include('.psb-sandbox');" }]), []);
  }],
  ["owner source contract passes the real owner files", () => {
    assert.ok(verifyOwnerSources(repositoryRoot) >= 3);
  }],
  ["results bundle needs an a11y block and the injected controls", () => {
    const row = { key: CELL, a11y: { rules_evaluated: 0, observations: [], matched_dispositions: [], probes: {} } };
    assert.throws(() => verifyResults({ cases: [row] }, registerOf(), { today: TODAY }), /evaluated 0 rules/);
    assert.throws(() => verifyResults({ cases: [{ key: CELL }] }, registerOf(), { today: TODAY }), /no a11y block/);
    const controls = Object.fromEntries(REQUIRED_CONTROLS.map((name) => [name, { detected: true }]));
    const geometry = { key: GEOMETRY_CONTROL_KEY, a11y: { rules_evaluated: 10, observations: [], matched_dispositions: [], probes: {}, injected_controls: controls } };
    assert.equal(verifyResults({ cases: [geometry] }, registerOf(), { today: TODAY }).cells, 1);
    const missing = { ...geometry, a11y: { ...geometry.a11y, injected_controls: { ...controls, outline_none: { detected: false } } } };
    assert.throws(() => verifyResults({ cases: [missing] }, registerOf(), { today: TODAY }), /outline_none was not detected/);
  }],
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

function parseArgs(argv) {
  const flags = new Set();
  const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) throw fail(`unexpected argument: ${token}`);
    const key = token.slice(2);
    if (["check", "results-latest", "self-test"].includes(key)) flags.add(key);
    else if (key === "results") {
      if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) throw fail("--results requires a path");
      values.results = argv[++index];
      flags.add("results");
    } else throw fail(`unknown option: --${key}`);
  }
  return { flags, values };
}

function todayUtc() {
  return new Date().toISOString().slice(0, 10);
}

function main(argv = process.argv.slice(2), root = repositoryRoot) {
  const { flags, values } = parseArgs(argv);
  if (flags.size !== 1) throw fail("exactly one of --check, --results-latest, --results <path>, --self-test is required");
  if (flags.has("self-test")) {
    for (const [name, scenario] of SCENARIOS) {
      scenario();
      console.log(`ok - ${name}`);
    }
    console.log(`Phase 254 a11y self-test: PASS (${SCENARIOS.length} scenarios, each with a passing control)`);
    return;
  }
  const register = loadRegister(root);
  const today = todayUtc();
  if (flags.has("check")) {
    validateEntries(register, { today });
    const owners = verifyOwnerSources(root);
    console.log(`Phase 254 a11y: PASS (${register.entries.length} register entries well formed; ${owners} owner files carry no suppression)`);
    return;
  }
  const file = flags.has("results") ? path.resolve(root, values.results) : latestResultsFile(root);
  const results = JSON.parse(fs.readFileSync(file, "utf8"));
  verifyOwnerSources(root);
  const summary = verifyResults(results, register, { today });
  console.log(
    `Phase 254 a11y: PASS (${summary.cells} cells reported, ${summary.deep_cells} deep-probe cells, ${summary.observations} observations all matched, ${summary.entries} register entries each matched in a cell that ran; ${path.relative(root, file)})`
  );
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
// A spawn with arguments is a real CLI run even when NODE_TEST_CONTEXT is inherited.
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT && process.argv.length <= 2) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  try {
    main();
  } catch (error) {
    console.error(error.message.startsWith("Phase 254") ? error.message : `Phase 254 a11y: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
