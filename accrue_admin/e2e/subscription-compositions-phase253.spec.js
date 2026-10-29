const { test } = require("@playwright/test");
const {
  beginCollectionResults,
  createCollectionCases,
  GEOMETRY_NEGATIVE_CONTROL_TITLE,
  createPageCases,
  createPageStressCases,
  collectionSyntheticTitle,
  isOwnedPhase253Run,
  readPhase253Manifest,
  resultPath,
  runCollectionCase,
  runGeometryNegativeControls,
  runPageCase,
  runSyntheticTextStress,
} = require("./phase253-composition-helpers.js");

// An unowned load (a dependency load from another lane's run) registers no tests; see
// isOwnedPhase253Run in the helpers.
if (isOwnedPhase253Run()) {
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

  // Phase 254 D-13: cells only write their own per-case result file. Reconciliation is the
  // dependent `phase254-reconcile` project (subscription-compositions-reconcile-phase254.spec.js).
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
  });
}
