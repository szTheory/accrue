const fs = require("node:fs");
const { test, expect } = require("@playwright/test");
const {
  beginCollectionResults,
  createCollectionCases,
  BROWSER_RECONCILIATION_TITLE,
  GEOMETRY_NEGATIVE_CONTROL_TITLE,
  createPageCases,
  createPageStressCases,
  collectionSyntheticTitle,
  readPhase253Manifest,
  reconcileResults,
  resultPath,
  runCollectionCase,
  runGeometryNegativeControls,
  runPageCase,
  runSyntheticTextStress,
} = require("./phase253-composition-helpers.js");

const identity = readPhase253Manifest();
const cases = createCollectionCases(identity.manifest);
const pageCases = createPageCases(identity.manifest);
const pageStressCases = createPageStressCases(identity.manifest);
const resultFile = resultPath(identity.runId);
const oneRow = identity.manifest.collection_variations.find((entry) => entry.variation_id === "one_row");
const extraKeys = [
  "one_row::synthetic-text::320::light",
  "one_row::synthetic-text::320::dark",
  "geometry::negative-controls::320::light",
];
if (!oneRow) throw new Error("Phase 253 compiled collection manifest is missing one_row");

test.beforeAll(() => {
  beginCollectionResults(
    identity.runId,
    identity.manifest,
    identity.manifestDigest,
    [...cases.map((testCase) => testCase.key), ...extraKeys,
      ...pageCases.map((testCase) => testCase.key),
      ...pageStressCases.map((testCase) => testCase.key)],
  );
});

test.describe("Phase 253 compiled production subscription collection", () => {
  for (const testCase of cases) {
    test(testCase.title, async ({ page }, testInfo) => {
      await runCollectionCase(page, testCase, { ...identity, resultPath: resultFile }, testInfo);
    });
  }

  for (const theme of ["light", "dark"]) {
    test(collectionSyntheticTitle(theme), async ({ page }, testInfo) => {
      await runSyntheticTextStress(page, oneRow, { ...identity, resultPath: resultFile }, theme, testInfo);
    });
  }

  test(GEOMETRY_NEGATIVE_CONTROL_TITLE, async ({ page }, testInfo) => {
    await runGeometryNegativeControls(page, oneRow, { ...identity, resultPath: resultFile }, testInfo);
  });

  for (const testCase of [...pageCases, ...pageStressCases]) {
    test(testCase.title, async ({ page }, testInfo) => {
      await runPageCase(page, testCase, { ...identity, resultPath: resultFile }, testInfo);
    });
  }

  test(BROWSER_RECONCILIATION_TITLE, () => {
    const results = JSON.parse(fs.readFileSync(resultFile, "utf8"));
    expect(results.run_id).toBe(identity.runId);
    expect(results.manifest_sha256).toBe(identity.manifestDigest);
    expect(results.human_judgment).toBe(false);
    expect(results.proof_lane).toBe("actual direct browser presentation; no mounted-effect claims");
    expect(results.source_and_asset_sha256["accrue_admin/assets/css/app.css"]).toMatch(/^[a-f0-9]{64}$/);
    expect(results.source_and_asset_sha256["accrue_admin/priv/static/accrue_admin.css"]).toMatch(/^[a-f0-9]{64}$/);
    expect(results.source_and_asset_sha256["accrue_admin/priv/static/storybook.css"]).toMatch(/^[a-f0-9]{64}$/);
    expect(results.cases).toHaveLength(cases.length + extraKeys.length + pageCases.length + pageStressCases.length);
    expect(reconcileResults(results, identity.manifest, identity.manifestDigest)).toEqual([]);
    const controls = results.cases.find((row) => row.case_kind === "geometry_negative_controls");
    expect(controls?.negative_controls).toEqual({ hidden_essential_detected: true, page_overflow_detected: true });
    expect(results.cases.filter((row) => row.case_kind === "viewport")).toHaveLength(40);
    expect(results.cases.filter((row) => row.case_kind === "breakpoint")).toHaveLength(8);
    expect(results.cases.filter((row) => row.case_kind === "container")).toHaveLength(4);
    expect(results.cases.filter((row) => row.case_kind === "synthetic_text_stress")).toHaveLength(2);
    expect(results.cases.filter((row) => row.case_kind === "page_composition")).toHaveLength(90);
    expect(results.cases.filter((row) => row.case_kind === "page_synthetic_text_stress")).toHaveLength(6);
  });
});
