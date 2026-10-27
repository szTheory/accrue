// @ts-check
const { defineConfig, devices } = require("@playwright/test");

const required = [
  "PHASE252_E2E_NONCE",
  "PHASE252_E2E_DATABASE",
  "PHASE252_E2E_ROLE",
  "PHASE252_E2E_ADDRESS",
  "PHASE252_E2E_PORT",
  "PHASE252_E2E_PARTITION",
];
for (const name of required) {
  if (!process.env[name]) throw new Error(`Phase 252 browser launcher is missing ${name}`);
}
if (!/^\d{8,16}$/.test(process.env.PHASE252_E2E_PARTITION)) {
  throw new Error("Phase 252 browser launcher requires an explicit numeric partition");
}

const port = Number(process.env.PHASE252_E2E_PORT);
if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("Phase 252 browser launcher supplied an invalid owned port");
}
const baseURL = `http://127.0.0.1:${port}`;
const launcher = `node ../scripts/dev/phase252_lab.mjs serve --lane admin-review --partition ${process.env.PHASE252_E2E_PARTITION} --port ${port}`;

module.exports = defineConfig({
  testDir: "./e2e",
  testMatch: /(?:phase252-review|subscription-stories-phase252|subscription-compositions-phase253)\.spec\.js/,
  timeout: 30_000,
  fullyParallel: false,
  workers: 1,
  reporter: [["list"]],
  use: {
    ...devices["Desktop Chrome"],
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    viewport: { width: 1280, height: 900 },
  },
  webServer: {
    command: launcher,
    url: `${baseURL}/__e2e__/health`,
    reuseExistingServer: false,
    timeout: 120_000,
    gracefulShutdown: { signal: "SIGTERM", timeout: 30_000 },
  },
  projects: [{ name: "phase252-owned-review", testMatch: /(?:phase252-review|subscription-stories-phase252|subscription-compositions-phase253)\.spec\.js/ }],
  outputDir: process.env.PLAYWRIGHT_OUTPUT_DIR || "test-results/phase252-review",
});
