// @ts-check
const path = require("node:path");
const os = require("node:os");
const { execFileSync } = require("node:child_process");
const { defineConfig, devices } = require("@playwright/test");

const port = process.env.ACCRUE_HOST_BROWSER_PORT || "4101";
const previewBaseURL = process.env.ACCRUE_HOST_PREVIEW_BASE_URL;
const baseURL = previewBaseURL || `http://127.0.0.1:${port}`;
const proofRunId = process.env.ACCRUE_HOST_PROOF_RUN_ID || `${process.pid}-${Date.now()}`;
process.env.ACCRUE_HOST_PROOF_RUN_ID = proofRunId;
process.env.MIX_BUILD_PATH ||= path.join(__dirname, "tmp", `accrue-host-proof-${proofRunId}`, "test");
process.env.ACCRUE_HOST_PLAYWRIGHT_OUTPUT_DIR ||= path.join(os.tmpdir(), `accrue-host-proof-${proofRunId}`, "playwright-results");
process.env.ACCRUE_HOST_PLAYWRIGHT_REPORT_DIR ||= path.join(os.tmpdir(), `accrue-host-proof-${proofRunId}`, "playwright-report");
execFileSync("node", [path.resolve(__dirname, "../../scripts/ci/accrue_host_preview_custody.sh"), "preflight", "browser"], { stdio: "inherit" });
const workers = process.env.ACCRUE_HOST_PLAYWRIGHT_WORKERS
  ? Number.parseInt(process.env.ACCRUE_HOST_PLAYWRIGHT_WORKERS, 10)
  : process.env.CI
    ? 1
    : 1;

/** Full-session recordings for maintainer demos (`npm run e2e:visuals`). CI leaves this unset. */
const trustWalkthroughVideo =
  process.env.ACCRUE_HOST_PLAYWRIGHT_VIDEO === "1"
    ? { video: { mode: "on", size: { width: 1280, height: 720 } } }
    : {};

module.exports = defineConfig({
  testDir: "./e2e",
  // Local checkout sessions are Braintree-specific. Run those specs against
  // the matching adapter in the explicit Braintree checkout lane.
  testIgnore: [
    "**/phase102-portal-checkout.spec.js",
    "**/phase233-braintree-checkout.spec.js",
    "**/phase234-search-completion.spec.js"
  ],
  globalSetup: path.join(__dirname, "e2e/global-setup.js"),
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  workers,
  reporter: process.env.CI
    ? [["github"], ["html", { open: "never", outputFolder: process.env.ACCRUE_HOST_PLAYWRIGHT_REPORT_DIR }]]
    : [["list"]],
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  webServer: previewBaseURL ? undefined : {
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
      testMatch: /verify01-admin-mobile\.spec\.js/,
      use: { ...devices["Pixel 5"] }
    }
  ],
  outputDir: process.env.ACCRUE_HOST_PLAYWRIGHT_OUTPUT_DIR
});
