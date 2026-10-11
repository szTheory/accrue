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
  testMatch: ["phase245-admin-baseline.spec.js"],
  timeout: 60_000,
  expect: { timeout: 10_000 },
  fullyParallel: false,
  workers: 1,
  reporter: "list",
  outputDir: path.join("/tmp", "accrue-host-phase245-playwright-results"),
  use: {
    baseURL,
    // Do not persist browser storage, form bodies or auth headers on failure.
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
