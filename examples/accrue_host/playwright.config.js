// @ts-check
const path = require("node:path");
const os = require("node:os");
const fs = require("node:fs");
const { execFileSync } = require("node:child_process");
const { defineConfig, devices } = require("@playwright/test");

const port = process.env.ACCRUE_HOST_BROWSER_PORT || "4101";
const previewBaseURL = process.env.ACCRUE_HOST_PREVIEW_BASE_URL;
const baseURL = previewBaseURL || `http://127.0.0.1:${port}`;
const proofRunId = process.env.ACCRUE_HOST_PROOF_RUN_ID || `${process.pid}-${Date.now()}`;
delete process.env.ACCRUE_HOST_DIRECT_PROOF_PID;
delete process.env.ACCRUE_HOST_DIRECT_PROOF_PID_FILE;
process.env.ACCRUE_HOST_PROOF_RUN_ID = proofRunId;
process.env.MIX_BUILD_PATH ||= path.join(__dirname, "tmp", `accrue-host-proof-${proofRunId}`, "test");
process.env.ACCRUE_HOST_PLAYWRIGHT_OUTPUT_DIR ||= path.join(os.tmpdir(), `accrue-host-proof-${proofRunId}`, "playwright-results");
process.env.ACCRUE_HOST_PLAYWRIGHT_REPORT_DIR ||= path.join(os.tmpdir(), `accrue-host-proof-${proofRunId}`, "playwright-report");
const directServerPidFile = process.env.ACCRUE_HOST_REUSE_SERVER === "1"
  ? null
  : path.join(os.tmpdir(), `accrue-host-proof-${proofRunId}`, "webserver.pid");
if (directServerPidFile) {
  process.env.ACCRUE_HOST_DIRECT_PROOF_PID_FILE = directServerPidFile;
  if (fs.existsSync(directServerPidFile)) {
    process.env.ACCRUE_HOST_DIRECT_PROOF_PID = fs.readFileSync(directServerPidFile, "utf8").trim();
  }
}
execFileSync("node", [path.resolve(__dirname, "../../scripts/ci/accrue_host_preview_custody.sh"), "preflight", "browser"], { stdio: "inherit" });
if (directServerPidFile) {
  fs.mkdirSync(path.dirname(directServerPidFile), { recursive: true, mode: 0o700 });
  fs.chmodSync(path.dirname(directServerPidFile), 0o700);
}
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
    command: directServerPidFile
      ? `ACCRUE_HOST_DIRECT_PROOF_PID_FILE=${directServerPidFile} PORT=${port} PHX_SERVER=true MIX_ENV=test sh -c 'umask 077; set -C; printf "%s\\n" "$$" > "$ACCRUE_HOST_DIRECT_PROOF_PID_FILE" && exec mix phx.server'`
      : `PORT=${port} PHX_SERVER=true MIX_ENV=test mix phx.server`,
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
