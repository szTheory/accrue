const { test, expect } = require("@playwright/test");
const {
  UI_PREDICATE_ASSERTION_REFERENCES,
  RESULT_PATH,
  beginResults,
  createCases,
  readManifest,
  readResults,
  recordNegativeControls,
  reconcileResults,
  runReconcilerNegativeControls,
  runRenderCase,
} = require("./phase252-story-helpers.js");

const { manifest, manifestDigest } = readManifest();
const runId = process.env.PHASE252_E2E_NONCE;
const cases = createCases(manifest);

test.describe("Phase 252 generated direct subscription story renders", () => {
  test.beforeAll(() => beginResults(runId, manifestDigest));

  for (const testCase of cases) {
    test(testCase.title, async ({ page }, testInfo) => {
      await runRenderCase(page, testCase, manifestDigest, runId, testInfo);
    });
  }

  test("reconciles every declared direct render against the generated manifest", async () => {
    const controls = runReconcilerNegativeControls(manifest, manifestDigest);
    expect(controls).toMatchObject({
      baseline_accepted: true,
      invalid_route: { rejected: true },
      missing_variation: { rejected: true },
      metadata_only: { rejected: true },
    });
    recordNegativeControls(runId, controls);
    const results = readResults();
    expect(results.run_id).toBe(runId);
    expect(results.manifest_sha256).toBe(manifestDigest);
    expect(results.ui_predicate_catalog).toEqual(UI_PREDICATE_ASSERTION_REFERENCES);
    expect(Object.keys(results.ui_predicate_coverage).sort()).toEqual(Object.keys(UI_PREDICATE_ASSERTION_REFERENCES).sort());
    expect(reconcileResults(manifest, results.cases, manifestDigest), RESULT_PATH).toEqual([]);
  });
});
