// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, reseedFixture, login, workspaceBillingLink, waitForLiveView } = require("./support/fixture.js");

test("tax-enabled subscribe surfaces tax location recovery copy", async ({ page, sandboxId }) => {
  reseedFixture();
  const fixture = readFixture();

  await login(page, fixture, fixture.normal_email, sandboxId);
  await workspaceBillingLink(page).click();
  await expect(page.getByRole("heading", { name: "Workspace billing" })).toBeVisible();
  await waitForLiveView(page);

  await page.getByRole("button", { name: "Choose Launch" }).click();
  await waitForLiveView(page);

  await expect(page.getByTestId("e2e-tax-invalid-headline")).toContainText("Tax location needs attention");
});
