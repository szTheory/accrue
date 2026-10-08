// This lane compiles the host with SQL Sandbox disabled so async search
// workers use real pooled Repo connections.
process.env.ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX = "1";
process.env.ACCRUE_HOST_BROWSER_PORT ||= "4102";

const base = require("./playwright.config.js");

module.exports = {
  ...base,
  testMatch: /phase234-search-completion\.spec\.js/,
  testIgnore: ["**/phase102-portal-checkout.spec.js", "**/phase233-braintree-checkout.spec.js"],
  projects: [base.projects[0]]
};
