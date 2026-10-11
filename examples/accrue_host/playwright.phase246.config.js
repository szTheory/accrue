// @ts-check
const path = require("node:path");
const { defineConfig, devices } = require("@playwright/test");

const expectedBaseURL = "http://accrue-host-phase245-ordinary.localhost/";
const baseURL = process.env.ACCRUE_HOST_ORDINARY_BASE_URL;

if (baseURL !== expectedBaseURL) {
  throw new Error(`ACCRUE_HOST_ORDINARY_BASE_URL must equal ${expectedBaseURL}`);
}

module.exports = defineConfig({
  testDir: "./e2e",
  testMatch: ["phase246-invoice-filters.spec.js", "phase246-collection-filters.spec.js", "phase246-global-search.spec.js", "phase246-table-reading.spec.js"],
  timeout: 60_000,
  expect: { timeout: 10_000 },
  fullyParallel: false,
  workers: 1,
  reporter: "list",
  outputDir: path.join("/tmp", "accrue-host-phase246-playwright-results"),
  use: {
    baseURL,
    // Avoid persisting credentials, form bodies, cookies, or auth headers.
    trace: "off",
    screenshot: "off"
  },
  projects: [
    {
      name: "chromium-desktop",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1280, height: 900 },
        colorScheme: "light"
      }
    }
  ]
});
