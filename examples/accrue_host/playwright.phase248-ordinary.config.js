// @ts-check
const path = require("node:path");
const { defineConfig, devices } = require("@playwright/test");

const expectedBaseURL = "http://accrue-host-phase245-ordinary.localhost/";
if (process.env.ACCRUE_HOST_ORDINARY_BASE_URL !== expectedBaseURL) {
  throw new Error(`ACCRUE_HOST_ORDINARY_BASE_URL must equal ${expectedBaseURL}`);
}
if (process.env.PHASE248_PROOF_LANE !== "ordinary") {
  throw new Error("PHASE248_PROOF_LANE must equal ordinary");
}

module.exports = defineConfig({
  testDir: "./e2e",
  testMatch: ["phase248-scenarios.spec.js"],
  timeout: 90_000,
  expect: { timeout: 10_000 },
  fullyParallel: false,
  workers: 1,
  reporter: "list",
  outputDir: path.join("/tmp", "accrue-host-phase248-ordinary-results"),
  use: {
    baseURL: expectedBaseURL,
    trace: "off",
    screenshot: "off",
    ...devices["Desktop Chrome"]
  }
});
