// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, reseedFixture, login } = require("./support/fixture.js");

// Skipped: Playwright webServer currently serves 500 on this deep-link; host ExUnit
// `AccrueHostWeb.OrgBillingAccessTest` locks the redirect + flash contract.
test.skip("admin customer detail denies out-of-scope organization rows", async ({ page, sandboxId }) => {
  reseedFixture();
  const fixture = readFixture();

  await login(page, fixture, fixture.admin_email, sandboxId);

  await page.goto("/admin", { waitUntil: "domcontentloaded" });

  const url = `/admin/customers/${fixture.admin_denial_customer_id}?org=${encodeURIComponent(fixture.admin_org_beta_slug)}`;
  await page.goto(url, { waitUntil: "domcontentloaded" });

  await expect(
    page.getByText("You don't have access to billing for this organization.", { exact: true })
  ).toBeVisible({ timeout: 15_000 });
});
