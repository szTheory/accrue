// @ts-check
const { test, expect } = require("@playwright/test");
const { readFixture, reseedFixture, login, waitForLiveView } = require("./support/fixture.js");

test("tax-enabled subscribe surfaces tax location recovery copy", async ({ page }) => {
  reseedFixture();
  const fixture = readFixture();

  await login(page, fixture, fixture.normal_email);
  await page.getByRole("link", { name: "Go to billing" }).click();
  await expect(page.getByRole("heading", { name: "Choose a plan" })).toBeVisible();
  await waitForLiveView(page);

  await page.getByRole("button", { name: "Start organization subscription" }).first().click();
  await waitForLiveView(page);

  await expect(page.getByTestId("e2e-tax-invalid-headline")).toContainText("Tax location needs attention");
});
