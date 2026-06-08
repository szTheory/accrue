// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, reseedFixture, login, workspaceBillingLink, waitForLiveView } = require("./support/fixture.js");

test("host billing switches active organization between fixture orgs", async ({ page, sandboxId }) => {
  reseedFixture();
  const fixture = readFixture();

  expect(fixture.org_alpha_slug).toBeTruthy();
  expect(fixture.org_beta_slug).toBeTruthy();

  await login(page, fixture, fixture.normal_email, sandboxId);
  await workspaceBillingLink(page).click();
  await expect(page.getByRole("heading", { name: "Workspace billing" })).toBeVisible();
  await waitForLiveView(page);

  await expect(page.getByTestId("organization-switcher")).toBeVisible();

  await expect(page.getByRole("heading", { level: 2, name: fixture.org_beta_name })).toBeVisible();

  await page.locator(`button[data-organization-slug="${fixture.org_alpha_slug}"]`).click();
  await waitForLiveView(page);

  await expect(page.getByRole("heading", { level: 2, name: fixture.org_alpha_name })).toBeVisible();
});
