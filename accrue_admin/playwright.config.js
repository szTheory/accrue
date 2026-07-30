// @ts-check
const { defineConfig, devices } = require("@playwright/test");

const port = process.env.ACCRUE_ADMIN_E2E_PORT || "4017";
const baseURL = `http://127.0.0.1:${port}`;
const outputDir = process.env.PLAYWRIGHT_OUTPUT_DIR || "test-results";

module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: {
    timeout: 5_000,
    toHaveScreenshot: {
      threshold: 0.2,          // per-pixel color delta for anti-aliasing/font hinting
      maxDiffPixelRatio: 0.01, // tiny jitter budget; real color/spacing breaks still trip it
      animations: "disabled",
      caret: "hide",
      scale: "css",
    },
  },
  snapshotPathTemplate: "e2e/__screenshots__/{projectName}/{arg}{ext}",
  fullyParallel: false,
  workers: 1,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : [["list"]],
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  webServer: {
    command: `MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=${port} mix accrue_admin.e2e.server`,
    url: `${baseURL}/__e2e__/health`,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000
  },
  projects: [
    {
      name: "chromium-desktop",
      // The dedicated visual-regression spec runs only under the `visual-desktop`
      // project (below) so it stays out of the default `npm run e2e` run — a
      // missing pixel baseline fails on CI, and the baselines are minted later.
      testIgnore: /admin-visual-regression-phase211\.spec\.js/,
      use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } }
    },
    {
      name: "chromium-mobile",
      testIgnore: /admin-visual-regression-phase211\.spec\.js/,
      use: { ...devices["Pixel 5"] }
    },
    {
      // Deterministic pixel-diff gate (Phase 211). Isolated in its own project so
      // it is excluded from the default `playwright test` run and only invoked via
      // `npm run e2e:visual-regression` (baseline-guarded in CI) and the CI mint job.
      name: "visual-desktop",
      testMatch: /admin-visual-regression-phase211\.spec\.js/,
      use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } }
    }
  ],
  outputDir
});
