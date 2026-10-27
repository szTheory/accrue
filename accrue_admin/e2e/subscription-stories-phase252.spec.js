const { test, expect } = require("@playwright/test");
const {
  RESULT_PATH,
  beginResults,
  createCases,
  readManifest,
  readResults,
  reconcileResults,
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
    const results = readResults();
    expect(results.run_id).toBe(runId);
    expect(results.manifest_sha256).toBe(manifestDigest);
    expect(reconcileResults(manifest, results.cases, manifestDigest), RESULT_PATH).toEqual([]);
  });
});
