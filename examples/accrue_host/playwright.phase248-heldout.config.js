// @ts-check
const { defineConfig } = require("@playwright/test");

if (process.env.PHASE248_PROOF_LANE !== "heldout") {
  throw new Error("PHASE248_PROOF_LANE must equal heldout");
}
const port = process.env.ACCRUE_HOST_BROWSER_PORT || "4102";
if (port !== "4102") throw new Error("Phase 248 held-out scenarios must use port 4102");

// Set the port before loading the shared isolated-host lifecycle config. That
// config owns the test database, SQL sandbox fixture, custody guard and server.
process.env.ACCRUE_HOST_BROWSER_PORT = "4102";
const base = require("./playwright.config.js");
module.exports = defineConfig({
  ...base,
  globalSetup: require.resolve("./e2e/phase248-heldout-setup.js"),
  testMatch: ["phase248-scenarios.spec.js"],
  timeout: 90_000,
  expect: { timeout: 10_000 },
  reporter: "list",
  use: { ...base.use, trace: "off", screenshot: "off" },
  webServer: base.webServer && { ...base.webServer, url: "http://127.0.0.1:4102/" }
});
