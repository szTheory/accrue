// @ts-check
const { defineConfig } = require("@playwright/test");

const port = process.env.ACCRUE_HOST_BROWSER_PORT || "4102";
if (port !== "4102") throw new Error("Phase 247 held-out tracer must use port 4102");

const base = require("./playwright.config.js");

module.exports = defineConfig({
  ...base,
  testMatch: ["phase247-time-tracer.spec.js"],
  reporter: "list",
  use: { ...base.use, trace: "off", screenshot: "off" }
});
