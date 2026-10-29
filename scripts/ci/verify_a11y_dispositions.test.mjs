import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  OWNER_FILES,
  SCENARIOS,
  loadRegister,
  scanOwnerSources,
  validateRegister,
  verifyFixtures,
  verifyOwnerSources
} from "./verify_a11y_dispositions.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const SCRIPT = path.join(ROOT, "scripts/ci/verify_a11y_dispositions.mjs");
const TODAY = "2026-10-29";
const CELL = "multiple_rows::viewport::320::light";

function entry(overrides = {}) {
  return {
    id: "A11Y-254-01",
    rule_id: "button-name",
    result_type: "violation",
    incomplete_reason: null,
    cell_ids: [CELL],
    target: ".ax-data-table-shell tbody > tr:nth-child(1) > td:nth-child(5) > button",
    expected_node_count: 1,
    sc: "4.1.2",
    exception_class: "routed-defect",
    rationale: "A seeded fixture entry.",
    follow_up_assertion_id: "254-12-fix-button-name",
    review_by: "2026-12-31",
    ...overrides
  };
}

function observation(overrides = {}) {
  return {
    cell_id: CELL,
    rule_id: "button-name",
    result_type: "violation",
    incomplete_reason: null,
    target: ".ax-data-table-shell tbody > tr:nth-child(1) > td:nth-child(5) > button",
    ...overrides
  };
}

const ranCell = (overrides = {}) => ({ cell_id: CELL, rules_evaluated: 41, ...overrides });
const registerOf = (...entries) => ({ schema_version: 1, entries });

function run(args) {
  const env = { ...process.env };
  delete env.NODE_TEST_CONTEXT;
  return spawnSync(process.execPath, [SCRIPT, ...args], { encoding: "utf8", cwd: ROOT, env });
}

for (const [name, scenario] of SCENARIOS) test(`fixture: ${name}`, scenario);

test("every rejection scenario passes together (verifyFixtures)", () => {
  assert.equal(verifyFixtures(), SCENARIOS.length);
  assert.ok(SCENARIOS.length >= 12);
});

test("a matched observation passes and records its entry (control)", () => {
  const summary = validateRegister(registerOf(entry()), [observation()], { today: TODAY, cells: [ranCell()] });
  assert.equal(summary.matched, 1);
  assert.equal(summary.entries, 1);
});

test("an unmatched observation is rejected as undispositioned", () => {
  assert.throws(
    () => validateRegister(registerOf(), [observation()], { today: TODAY, cells: [ranCell()] }),
    /undispositioned.*button-name/
  );
});

test("an undispositioned incomplete is rejected even when a violation with the same rule is dispositioned", () => {
  const incomplete = observation({ result_type: "incomplete", incomplete_reason: "bgOverlap", rule_id: "color-contrast", target: ".ax-x" });
  assert.throws(
    () => validateRegister(registerOf(entry()), [observation(), incomplete], { today: TODAY, cells: [ranCell()] }),
    /undispositioned.*color-contrast/
  );
});

test("an entry whose cell ran but matched zero nodes is rejected", () => {
  assert.throws(
    () => validateRegister(registerOf(entry()), [], { today: TODAY, cells: [ranCell()] }),
    /matched zero nodes/
  );
});

test("an entry naming only cells that did not run is rejected unless unrun cells are allowed", () => {
  const other = { cell_id: "one_row::viewport::1280::dark", rules_evaluated: 41 };
  assert.throws(() => validateRegister(registerOf(entry()), [], { today: TODAY, cells: [other] }), /did not run/);
  validateRegister(registerOf(entry()), [], { today: TODAY, cells: [other], allowUnrun: true });
});

for (const target of ["*", "html", "body", "#main-content", ".psb-sandbox", "div", "button", ""]) {
  test(`a broad target ${JSON.stringify(target)} is rejected`, () => {
    assert.throws(
      () => validateRegister(registerOf(entry({ target })), [observation({ target })], { today: TODAY, cells: [ranCell()] }),
      /target/
    );
  });
}

test("a node-count mismatch is rejected in both directions", () => {
  assert.throws(
    () => validateRegister(registerOf(entry({ expected_node_count: 2 })), [observation()], { today: TODAY, cells: [ranCell()] }),
    /expected 2 nodes.*matched 1/
  );
  assert.throws(
    () => validateRegister(registerOf(entry()), [observation(), observation()], { today: TODAY, cells: [ranCell()] }),
    /expected 1 nodes.*matched 2/
  );
});

test("wildcard cell ids are rejected", () => {
  for (const cellIds of [["*"], ["multiple_rows::viewport::*::light"], ["multiple_rows::viewport::320::?"]]) {
    assert.throws(
      () => validateRegister(registerOf(entry({ cell_ids: cellIds })), [observation()], { today: TODAY, cells: [ranCell()] }),
      /wildcard/
    );
  }
});

test("an expired review_by is rejected and a review_by of today passes", () => {
  assert.throws(
    () => validateRegister(registerOf(entry({ review_by: "2026-10-28" })), [observation()], { today: TODAY, cells: [ranCell()] }),
    /expired/
  );
  validateRegister(registerOf(entry({ review_by: TODAY })), [observation()], { today: TODAY, cells: [ranCell()] });
});

test("malformed entries are rejected field by field", () => {
  const bad = [
    entry({ id: "A11Y-1" }),
    entry({ rule_id: "" }),
    entry({ result_type: "pass" }),
    entry({ result_type: "incomplete", incomplete_reason: null }),
    entry({ result_type: "violation", incomplete_reason: "bgOverlap" }),
    entry({ cell_ids: [] }),
    entry({ expected_node_count: 0 }),
    entry({ exception_class: "ignore" }),
    entry({ rationale: "" }),
    entry({ follow_up_assertion_id: "" }),
    entry({ review_by: "soon" })
  ];
  for (const candidate of bad) {
    assert.throws(
      () => validateRegister(registerOf(candidate), [observation()], { today: TODAY, cells: [ranCell()] }),
      /entry/,
      JSON.stringify(candidate)
    );
  }
});

test("duplicate ids and overlapping entries are rejected", () => {
  assert.throws(
    () => validateRegister(registerOf(entry(), entry()), [observation()], { today: TODAY, cells: [ranCell()] }),
    /duplicate/
  );
  assert.throws(
    () => validateRegister(registerOf(entry(), entry({ id: "A11Y-254-02" })), [observation()], { today: TODAY, cells: [ranCell()] }),
    /overlap/
  );
});

// UXQ-02 empty: an empty register is acceptable only as a measurement, never as an absence of evidence.
test("empty register: passes when every cell that ran evaluated at least one rule", () => {
  const summary = validateRegister(registerOf(), [], { today: TODAY, cells: [ranCell(), ranCell({ cell_id: "one_row::viewport::320::dark", rules_evaluated: 1 })] });
  assert.equal(summary.entries, 0);
  assert.equal(summary.cells, 2);
});

test("empty register: fails when one cell reports zero rules evaluated", () => {
  assert.throws(
    () => validateRegister(registerOf(), [], { today: TODAY, cells: [ranCell(), ranCell({ cell_id: "one_row::viewport::320::dark", rules_evaluated: 0 })] }),
    /evaluated 0 rules.*one_row::viewport::320::dark/
  );
});

test("empty register: fails when no cell ran at all", () => {
  assert.throws(() => validateRegister(registerOf(), [], { today: TODAY, cells: [] }), /no cell/);
});

test("empty register: an absent register file fails closed", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "a11y-register-"));
  try {
    assert.throws(() => loadRegister(dir), /register is absent/);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("empty register: an unparsable register file fails closed", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "a11y-register-"));
  try {
    fs.mkdirSync(path.join(dir, "accrue_admin/e2e"), { recursive: true });
    fs.writeFileSync(path.join(dir, "accrue_admin/e2e/a11y-dispositions.json"), "{ not json");
    assert.throws(() => loadRegister(dir), /unparsable/);
    fs.writeFileSync(path.join(dir, "accrue_admin/e2e/a11y-dispositions.json"), JSON.stringify({ schema_version: 2, entries: [] }));
    assert.throws(() => loadRegister(dir), /schema_version/);
    fs.writeFileSync(path.join(dir, "accrue_admin/e2e/a11y-dispositions.json"), JSON.stringify({ schema_version: 1 }));
    assert.throws(() => loadRegister(dir), /entries/);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("the committed register parses", () => {
  const register = loadRegister(ROOT);
  assert.equal(register.schema_version, 1);
  assert.ok(Array.isArray(register.entries));
});

// Source contract (D-30): no suppression in the owners.
const SEEDED_BANNED = [
  ["disableRules", "const results = await new AxeBuilder({ page }).disableRules(['color-contrast']).analyze();"],
  ["exclude", "const results = await new AxeBuilder({ page }).exclude('.ax-flash').analyze();"],
  ["impact", "return results.violations.filter((v) => v.impact === 'critical' || v.impact === 'serious');"],
  ["withRules", "new AxeBuilder({ page }).withRules(['button-name']).analyze();"],
  ["configure", "builder.options({ rules: { 'color-contrast': { enabled: false } } });"]
];

for (const [token, source] of SEEDED_BANNED) {
  test(`owner scan flags a seeded ${token} suppression`, () => {
    const findings = scanOwnerSources([{ path: "seeded.js", source }]);
    assert.ok(findings.length >= 1, `${token} was not flagged`);
    assert.equal(findings[0].path, "seeded.js");
    assert.equal(findings[0].line, 1);
  });
}

test("owner scan ignores comments and passes a clean AxeBuilder", () => {
  const clean = [
    "// no disableRules, no .exclude( and no impact filter here",
    "/* the old filter used v.impact === 'serious' */",
    "const results = await new AxeBuilder({ page }).withTags(['wcag2a']).include('.psb-sandbox').analyze();"
  ].join("\n");
  assert.deepEqual(scanOwnerSources([{ path: "clean.js", source: clean }]), []);
});

test("the real owner files exist and pass the source contract", () => {
  assert.ok(OWNER_FILES.length >= 3);
  for (const file of OWNER_FILES) assert.ok(fs.existsSync(path.join(ROOT, file)), `${file} is an owner`);
  verifyOwnerSources(ROOT);
});

test("the CLI self-test runs the empty-register and owner-source scenarios", () => {
  const result = run(["--self-test"]);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /empty register/);
  assert.match(result.stdout, /owner source/);
  assert.match(result.stdout, /self-test: PASS/);
});

test("the CLI rejects an unknown option and a missing mode", () => {
  assert.notEqual(run(["--bogus"]).status, 0);
  assert.notEqual(run([]).status, 0);
});
