// @ts-check
const baseConfig = require("./playwright.config.js");

module.exports = {
  ...baseConfig,
  testIgnore: [],
  webServer: {
    ...baseConfig.webServer,
    command: `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ${baseConfig.webServer.command}`
  }
};
