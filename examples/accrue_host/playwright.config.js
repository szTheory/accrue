// @ts-check
const path = require("node:path");
const { defineConfig, devices } = require("@playwright/test");

const port = process.env.ACCRUE_HOST_BROWSER_PORT || "4101";
const baseURL = `http://127.0.0.1:${port}`;

/** Full-session recordings for maintainer demos (`npm run e2e:visuals`). CI leaves this unset. */
const trustWalkthroughVideo =
  process.env.ACCRUE_HOST_PLAYWRIGHT_VIDEO === "1"
    ? { video: { mode: "on", size: { width: 1280, height: 720 } } }
    : {};

module.exports = defineConfig({
  testDir: "./e2e",
  globalSetup: path.join(__dirname, "e2e/global-setup.js"),
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  workers: 1,
  reporter: process.env.CI
    ? [["github"], ["html", { open: "never", outputFolder: "playwright-report" }]]
    : [["list"]],
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  webServer: {
    command: `PORT=${port} PHX_SERVER=true MIX_ENV=test mix phx.server`,
    url: `${baseURL}/`,
    reuseExistingServer: process.env.ACCRUE_HOST_REUSE_SERVER === "1",
    timeout: 120_000
  },
  projects: [
    {
      name: "chromium-desktop",
      use: {
        ...devices["Desktop Chrome"],
        ...trustWalkthroughVideo,
        viewport: { width: 1280, height: 900 }
      }
    },
    {
      name: "chromium-mobile",
      use: { ...devices["Pixel 5"], ...trustWalkthroughVideo }
    },
    // CI can run `npx playwright test --project=chromium-mobile-tagged` for @mobile-only checks.
    {
      name: "chromium-mobile-tagged",
      grep: /@mobile/,
      use: {
        ...devices["Desktop Chrome"],
        ...trustWalkthroughVideo,
        viewport: { width: 1280, height: 900 }
      }
    }
  ],
  outputDir: "test-results"
});
