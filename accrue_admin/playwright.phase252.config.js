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
  testMatch: /(?:phase252-review|subscription-stories-phase252|subscription-compositions-phase253|subscription-compositions-reconcile-phase254|subscription-design-phase254)\.spec\.js/,
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
  projects: [
    // Playwright runs a dependency project in full even when file filters select other
    // specs, so the project the reconcile step depends on holds only the composition
    // cells. The story and review specs live in their own project and stay selectable by
    // file filter without dragging 150+ cells (or the reconcile step) into their runs.
    {
      name: "phase252-owned-review",
      testMatch: /subscription-compositions-phase253\.spec\.js/,
      // Phase 254 CIQ-02 (D-13): these cells are pure-story. The review lane answers every reset
      // and seed with 403 and each cell writes its own result file, so the cells may run on
      // separate workers when the aggregate passes --workers. The top-level worker count stays 1,
      // so every other run of this config is serial exactly as before.
      fullyParallel: true,
    },
    {
      name: "phase252-owned-stories",
      testMatch: /(?:phase252-review|subscription-stories-phase252)\.spec\.js/,
    },
    // Phase 254 D-13/D-14: merges the per-case composition result files. It depends on
    // the cells project, so a failed or skipped cell leaves this project not passed. Same
    // single worker and single server; it adds no parallelism, shards or retries.
    {
      name: "phase254-reconcile",
      testMatch: /subscription-compositions-reconcile-phase254\.spec\.js/,
      dependencies: ["phase252-owned-review"],
    },
    // Phase 254 D-35: computed-style and source tests for the reviewed design corrections. Pure
    // story: it reads the Storybook routes and the served stylesheet and never resets or seeds.
    {
      name: "phase254-design",
      testMatch: /subscription-design-phase254\.spec\.js/,
    },
  ],
  outputDir: process.env.PLAYWRIGHT_OUTPUT_DIR || "test-results/phase252-review",
});
