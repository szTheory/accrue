import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import {
  GEOMETRY_CONTROL_KEY,
  OWNER_FILES,
  REQUIRED_CONTROLS,
  SCENARIOS,
  loadRegister,
  scanOwnerSources,
  validateRegister,
  verifyFixtures,
  verifyOwnerSources,
  verifyResults
} from "./verify_a11y_dispositions.mjs";
import * as validator from "./verify_a11y_dispositions.mjs";

const require = createRequire(import.meta.url);
const probes = require("../../accrue_admin/e2e/phase254-a11y-probes.js");

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

// ---------------------------------------------------------------------------------------
// Task 254-11-02: alpha-correct contrast, the encoding contract and the deep probes
// ---------------------------------------------------------------------------------------

test("parseColor keeps alpha for rgba(), space-separated rgb() and color(srgb ... / a)", () => {
  assert.deepEqual(probes.parseColor("rgba(10, 20, 30, 0.25)"), [10, 20, 30, 0.25]);
  assert.deepEqual(probes.parseColor("rgb(10 20 30 / 40%)"), [10, 20, 30, 0.4]);
  assert.deepEqual(probes.parseColor("color(srgb 1 0 0 / 0.5)"), [255, 0, 0, 0.5]);
  assert.deepEqual(probes.parseColor("rgb(1, 2, 3)"), [1, 2, 3, 1]);
  assert.deepEqual(probes.parseColor("transparent"), [0, 0, 0, 0]);
});

test("parseColor reads the oklch() values the dark overlay pages compute", () => {
  assert.deepEqual(probes.parseColor("oklch(0.208 0.042 265.755)").slice(0, 3), [15, 23, 43]);
  assert.throws(() => probes.parseColor("hsl(10 20% 30%)"), /Unsupported colour/);
});

test("contrast: a translucent foreground fails only when alpha is honored (positive control)", () => {
  const white = "rgb(255, 255, 255)";
  const translucent = "rgba(0, 0, 0, 0.3)";
  // Dropping alpha reads black on white, 21:1, which would pass; honoring it gives a light grey.
  const alphaDropped = probes.contrastRatio(probes.parseColor(translucent).slice(0, 3).concat(1), white);
  const alphaHonored = probes.contrastRatio(translucent, white);
  assert.ok(alphaDropped > 20, `alpha dropped ${alphaDropped}`);
  assert.ok(alphaHonored < 4.5, `alpha honored ${alphaHonored}`);
  // Control: an opaque dark foreground still passes.
  assert.ok(probes.contrastRatio("rgb(0, 0, 0)", white) > 20);
});

test("compositeColor blends a translucent stack onto the canvas top to bottom", () => {
  const [r, g, b, a] = probes.compositeColor([[0, 0, 0, 0.5], [255, 255, 255, 1]]);
  assert.equal(Math.round(r), 128);
  assert.equal(Math.round(g), 128);
  assert.equal(Math.round(b), 128);
  assert.equal(a, 1);
  // A fully transparent layer leaves the layer below untouched.
  assert.deepEqual(probes.compositeColor([[9, 9, 9, 0], [10, 20, 30, 1]]).slice(0, 3), [10, 20, 30]);
});

test("resolveBackgroundCandidates stops at an opaque layer, reads gradient stops and refuses a url() image", () => {
  const opaque = probes.resolveBackgroundCandidates([
    { color: "rgb(255, 255, 255)", opacity: 1, image: "none" },
    { color: "rgb(0, 0, 0)", opacity: 1, image: "linear-gradient(rgb(255, 0, 0), rgb(0, 0, 255))" },
  ]);
  assert.equal(opaque.candidates.length, 1, "a gradient below an opaque layer cannot show through");
  const gradient = probes.resolveBackgroundCandidates([
    { color: "rgba(0, 0, 0, 0)", opacity: 1, image: "linear-gradient(rgb(255, 0, 0), rgb(0, 0, 255))" },
  ]);
  assert.ok(gradient.candidates.length >= 3, "the base and each colour stop are candidates");
  assert.equal(probes.resolveBackgroundCandidates([{ color: "rgba(0, 0, 0, 0)", opacity: 1, image: 'url("x.png")' }]).unresolved, "background-image");
});

// UXQ-02 encoding: accessible-name equality is exact after whitespace normalisation only.
test("encoding: names that differ only in ASCII whitespace normalize equal", () => {
  assert.equal(probes.normalizeAccessibleName("Pay  now\n"), "Pay now");
  assert.equal(probes.normalizeAccessibleName("Pay now"), "Pay now");
  assert.equal(probes.normalizeAccessibleName("\t Pay\r\n now "), "Pay now");
});

test("encoding: NFC and NFD forms of the same text stay distinct under code point comparison", () => {
  const nfc = "Caf\u00e9";
  const nfd = "Cafe\u0301";
  assert.notEqual(nfc, nfd);
  assert.equal(probes.normalizeAccessibleName(nfc), nfc, "no Unicode normalization is applied");
  assert.deepEqual(probes.findDuplicateNames([nfc, nfd]), []);
  assert.equal(probes.findDuplicateNames([nfc, "Caf\u00e9"]).length, 1);
});

test("encoding: long synthetic Unicode identities differing only in the last code point are distinct", () => {
  const base = `${"synthetic-customer-".repeat(12)}\u{1F600}`;
  const first = `${base}\u{1F601}`;
  const second = `${base}\u{1F602}`;
  assert.deepEqual(probes.findDuplicateNames([first, second]), []);
  assert.equal(probes.findDuplicateNames([first, first]).length, 1);
});

test("encoding: two identical normalized row-link names are reported as duplicates, empty names are not", () => {
  const found = probes.findDuplicateNames(["Customer details", "Acme", "Customer  details\n", "", ""]);
  assert.equal(found.length, 1);
  assert.deepEqual(found[0].indexes, [0, 2]);
  assert.equal(found[0].count, 2);
});

test("parseAriaSnapshot reads roles, names and unnamed controls", () => {
  const entries = probes.parseAriaSnapshot('- link "Pay now":\n  - /url: /x\n- button\n- textbox "Search"\n- link "Caf\\u00e9 \\"q\\""');
  assert.deepEqual(entries.map((entry) => [entry.role, entry.name]), [["link", "Pay now"], ["button", null], ["textbox", "Search"], ["link", 'Caf\u00e9 "q"']]);
});

const target = (overrides) => ({ selector: "a", x: 0, y: 0, width: 100, height: 40, disabled: false, obscured: false, inline_in_text: false, native_control: false, control: false, ...overrides });

test("target size: two overlapping undersized controls are both defects (positive control)", () => {
  const result = probes.evaluateTargetSize([
    target({ selector: "#a", x: 8, y: 8, width: 10, height: 10, control: true }),
    target({ selector: "#b", x: 14, y: 8, width: 10, height: 10, control: true }),
  ]);
  assert.deepEqual(result.defects.map((defect) => defect.selector).sort(), ["#a", "#b"]);
});

test("target size: an undersized control with clear space passes by the spacing exception, a 24px control passes outright", () => {
  const spaced = probes.evaluateTargetSize([
    target({ selector: "#small", x: 0, y: 0, width: 16, height: 16 }),
    target({ selector: "#far", x: 200, y: 0, width: 100, height: 40 }),
  ]);
  assert.deepEqual(spaced.defects, []);
  assert.deepEqual(spaced.classified, [{ selector: "#small", exception: "spacing" }]);
  assert.deepEqual(probes.evaluateTargetSize([target({ width: 24, height: 24 })]).defects, []);
});

test("target size: an undersized control beside a large target is a defect; inline, native, hidden, disabled and obscured targets are classified or ignored", () => {
  const beside = probes.evaluateTargetSize([
    target({ selector: "#small", x: 0, y: 0, width: 16, height: 16 }),
    target({ selector: "#big", x: 18, y: 0, width: 100, height: 40 }),
  ]);
  assert.equal(beside.defects.length, 1);
  assert.equal(beside.defects[0].selector, "#small");
  const exempt = probes.evaluateTargetSize([
    target({ selector: "#inline", width: 30, height: 12, inline_in_text: true }),
    target({ selector: "#native", width: 13, height: 13, native_control: true }),
    target({ selector: "#hidden", width: 1, height: 1 }),
    target({ selector: "#disabled", width: 10, height: 10, disabled: true }),
    target({ selector: "#obscured", width: 10, height: 10, obscured: true }),
  ]);
  assert.deepEqual(exempt.defects, []);
  assert.deepEqual(exempt.classified.map((item) => item.exception).sort(), ["inline", "user-agent-control", "visually-hidden"]);
});

test("focus: no indicator, a faint ring and an obscured control are each reported; a strong ring passes", () => {
  const facts = { outline_style: "solid", outline_width: 2, outline_color: "rgb(0, 0, 0)", box_shadow: "none", background_stack: ["rgb(255, 255, 255)"], obscured: false, in_viewport: true, focus_visible: true, keyboard_reached: true };
  assert.deepEqual(probes.evaluateFocus(facts).problems, []);
  assert.ok(probes.evaluateFocus({ ...facts, outline_style: "none", outline_width: 0 }).problems.includes("no-focus-indicator"));
  assert.ok(probes.evaluateFocus({ ...facts, outline_color: "rgb(230, 230, 230)" }).problems.some((problem) => problem.startsWith("ring-contrast")));
  assert.ok(probes.evaluateFocus({ ...facts, obscured: true }).problems.includes("obscured"));
  const shadow = probes.evaluateFocus({ ...facts, outline_style: "none", outline_width: 0, box_shadow: "rgb(0, 0, 0) 0px 0px 0px 2px" });
  assert.deepEqual(shadow.problems, []);
  assert.equal(shadow.shadow, true);
});

test("text spacing and motion helpers", () => {
  assert.equal(probes.spacingMatches(1.68, 14), true);
  assert.equal(probes.spacingMatches(0, 14), false);
  assert.equal(probes.isIdentityTransform("none"), true);
  assert.equal(probes.isIdentityTransform("matrix(1, 0, 0, 1, 0, 0)"), true);
  assert.equal(probes.isIdentityTransform("matrix(1, 0, 0, 1, 12, 0)"), false);
  assert.deepEqual(probes.secondsList("0.18s, 120ms"), [0.18, 0.12]);
  assert.equal(probes.REQUIRED_TEXT_SCALE, 1.95);
  assert.match(probes.AAA_PROJECT_TARGETS["2.3.3"], /AAA/);
});

test("targets are stable across runs and geometry findings name a kind of failure", () => {
  assert.equal(probes.stableTarget('a[data-phx-id="m11-phx-GOLzvnGqaZOVPVQB"]'), "a[data-phx-id]");
  assert.equal(probes.stableTarget("#ax-id-badge-subscription-card-c134aee0-b71a-44f5-a030-f6146577dba5 > span"), "#ax-id-badge-subscription-card-UUID > span");
  assert.equal(probes.stableTarget("#phx-GOLzvnGqaZOVPVQB > div"), "#phx-ID > div");
  assert.equal(probes.geometryTarget("k: document page overflow 441/320"), "geometry:document-overflow");
  assert.equal(probes.geometryTarget("k: subscription page overflow 682/608"), "geometry:page-overflow");
  assert.equal(probes.geometryTarget("k: hidden essential content: summary facts, page heading"), "geometry:hidden-essential(page heading|summary facts)");
});

test("the deep-probe subset is exactly the named collection and page states at 320 and 1280, light and dark", () => {
  const collection = ["one_row", "multiple_rows", "page_boundary", "unavailable", "partial_cursor_error", "filtered_empty"];
  const page = ["active", "review_cancel_now", "awaiting_step_up", "result_failed"];
  let count = 0;
  for (const state of collection) for (const width of [320, 1280]) for (const theme of ["light", "dark"]) {
    assert.equal(probes.isDeepProbeKey(`${state}::viewport::${width}::${theme}`), true);
    count += 1;
  }
  for (const variation of page) for (const width of [320, 1280]) for (const theme of ["light", "dark"]) {
    assert.equal(probes.isDeepProbeKey(`page::${variation}::viewport::${width}::${theme}`), true);
    count += 1;
  }
  assert.equal(count, 40);
  for (const key of ["new_host_empty::viewport::320::light", "one_row::breakpoint::768::light", "one_row::container::640::dark", "one_row::synthetic-text::320::dark", "page::active::breakpoint::767::light", "page::dispatching::viewport::320::light", "page::active::synthetic-return::320::light", GEOMETRY_CONTROL_KEY]) {
    assert.equal(probes.isDeepProbeKey(key), false, key);
  }
});

// The results bundle: deep-probe rows, the seven injected controls and an unsupported text scale.
const DEEP_KEY = "filtered_empty::viewport::320::light";
const okProbe = () => ({ status: "checked", defects: [] });
const deepRow = (overrides = {}) => ({
  key: DEEP_KEY,
  a11y: {
    deep: true, rules_evaluated: 40, observations: [], matched_dispositions: [],
    probes: {
      names: okProbe(), target_size: okProbe(), focus: okProbe(), spacing: okProbe(),
      scale: { status: "checked", supported: true, defects: [] },
      motion: { reduce: okProbe(), no_preference: { status: "not_applicable", not_applicable_reason: "no drawer is open in this composition" } },
    },
    ...overrides
  }
});

test("results: a deep-probe row with every probe passes (control)", () => {
  assert.equal(verifyResults({ cases: [deepRow()] }, registerOf(), { today: TODAY }).deep_cells, 1);
});

test("results: a deep-probe cell that did not run the deep probes is rejected", () => {
  assert.throws(() => verifyResults({ cases: [deepRow({ deep: false })] }, registerOf(), { today: TODAY }), /did not run the deep probes/);
});

for (const name of ["names", "target_size", "focus", "spacing", "scale", "motion"]) {
  test(`results: a deep-probe cell missing its ${name} probe is rejected`, () => {
    const row = deepRow();
    delete row.a11y.probes[name];
    assert.throws(() => verifyResults({ cases: [row] }, registerOf(), { today: TODAY }), new RegExp(`no ${name} probe result`));
  });
}

test("results: motion needs a result under both reduce and no-preference", () => {
  const row = deepRow();
  delete row.a11y.probes.motion.no_preference;
  assert.throws(() => verifyResults({ cases: [row] }, registerOf(), { today: TODAY }), /no motion result under no_preference/);
});

test("results: not_applicable needs a reason and is accepted only for an allowed pair", () => {
  const noReason = deepRow();
  noReason.a11y.probes.names = { status: "not_applicable" };
  assert.throws(() => verifyResults({ cases: [noReason] }, registerOf(), { today: TODAY }), /without a reason/);
  const notAllowed = deepRow();
  notAllowed.a11y.probes.names = { status: "not_applicable", not_applicable_reason: "no row links" };
  assert.throws(() => verifyResults({ cases: [notAllowed] }, registerOf(), { today: TODAY }), /not an allowed pair/);
  assert.ok(Array.isArray(validator.ALLOWED_NOT_APPLICABLE));
});

test("results: a text scale the browser could not apply needs an unsupported-mechanism disposition, not a routed defect", () => {
  const scaleObservation = { cell_id: DEEP_KEY, rule_id: "probe-text-scale", result_type: "violation", incomplete_reason: null, target: "mechanism:text-scale" };
  const unsupported = entry({ rule_id: "probe-text-scale", target: "mechanism:text-scale", cell_ids: [DEEP_KEY], sc: "1.4.4", exception_class: "unsupported-mechanism" });
  const row = deepRow({ observations: [scaleObservation], matched_dispositions: [{ id: unsupported.id, nodes: 1 }] });
  row.a11y.probes.scale = { status: "checked", supported: false, defects: [{ selector: "mechanism:text-scale" }] };
  assert.equal(verifyResults({ cases: [row] }, registerOf(unsupported), { today: TODAY }).observations, 1);
  const routed = { ...unsupported, exception_class: "routed-defect" };
  assert.throws(() => verifyResults({ cases: [row] }, registerOf(routed), { today: TODAY }), /unsupported-mechanism disposition/);
});

test("results: the geometry cell must report all seven injected controls as detected", () => {
  assert.deepEqual([...REQUIRED_CONTROLS].sort(), ["motion_under_reduce", "outline_none", "undersized_overlapping_target", "undispositioned_incomplete", "unapplied_scaling", "unapplied_spacing", "unnamed_button"].sort());
  const controls = Object.fromEntries(REQUIRED_CONTROLS.map((name) => [name, { detected: true }]));
  const geometry = (map) => ({ key: GEOMETRY_CONTROL_KEY, a11y: { rules_evaluated: 10, observations: [], matched_dispositions: [], probes: {}, injected_controls: map } });
  assert.equal(verifyResults({ cases: [geometry(controls)] }, registerOf(), { today: TODAY }).cells, 1);
  for (const name of REQUIRED_CONTROLS) {
    assert.throws(
      () => verifyResults({ cases: [geometry({ ...controls, [name]: { detected: false } })] }, registerOf(), { today: TODAY }),
      new RegExp(`${name} was not detected`),
      name
    );
  }
});

// The D-29 keyboard journey checkpoints: entries for them are decided by admin-interactions.spec.js.
const journeyEntry = (overrides = {}) => entry({
  id: "A11Y-254-29", rule_id: "probe-focus-restore", target: "journey:escape-restores-focus", sc: "2.4.3",
  cell_ids: ["journey::D-29::escape-restores-focus"], ...overrides
});

test("a journey entry is exempt from the cell-ran and zero-node rules but is still validated", () => {
  const summary = validateRegister(registerOf(journeyEntry()), [], { today: TODAY, cells: [ranCell()] });
  assert.equal(summary.entries, 1);
  assert.throws(() => validateRegister(registerOf(journeyEntry({ rationale: "" })), [], { today: TODAY, cells: [ranCell()] }), /entry/);
  assert.throws(() => validateRegister(registerOf(journeyEntry({ review_by: "2026-10-01" })), [], { today: TODAY, cells: [ranCell()] }), /expired/);
});

test("a journey entry may not mix composition cells and must use a well formed checkpoint id", () => {
  assert.throws(
    () => validateRegister(registerOf(journeyEntry({ cell_ids: ["journey::D-29::escape-restores-focus", CELL] })), [observation()], { today: TODAY, cells: [ranCell()] }),
    /must not also name composition cells/
  );
  assert.throws(
    () => validateRegister(registerOf(journeyEntry({ cell_ids: ["journey::D-29::Escape Restores"] })), [], { today: TODAY, cells: [ranCell()] }),
    /journey cell id must look like/
  );
});

test("the committed register's journey entries name only the two focus-restore checkpoints", () => {
  const journey = loadRegister(ROOT).entries.filter((item) => item.cell_ids.some((id) => id.startsWith("journey::")));
  assert.deepEqual(journey.flatMap((item) => item.cell_ids).sort(), ["journey::D-29::back-restores-focus", "journey::D-29::escape-restores-focus"]);
  for (const item of journey) {
    assert.equal(item.rule_id, "probe-focus-restore");
    assert.equal(item.exception_class, "routed-defect");
  }
});
