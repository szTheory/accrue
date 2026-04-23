// @ts-check
const { test, expect } = require("@playwright/test");
const { readFixture, reseedFixture, login, waitForLiveView } = require("./support/fixture.js");

test("mounted admin customers index shows tenant chrome and billing signals", async ({ page }, testInfo) => {
  reseedFixture();
  const fixture = readFixture();

  expect(fixture.admin_org_alpha_slug).toBeTruthy();

  await login(page, fixture, fixture.admin_email);
  await page.getByRole("link", { name: "Go to billing" }).click();
  await waitForLiveView(page);

  await expect(page.getByTestId("organization-switcher")).toBeVisible();

  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);

  const customersUrl = `/billing/customers?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
  await page.goto(customersUrl, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  await expect(page.getByText("Active organization", { exact: true })).toBeVisible({ timeout: 15_000 });

  if (testInfo.project.name.includes("mobile")) {
    // Card rows wrap label/value pairs in generic groups; assert the card shows the billing chip pair.
    await expect(page.locator("article").filter({ hasText: "Billing signals" }).filter({ hasText: "Org" })).toBeVisible({
      timeout: 15_000
    });
  } else {
    await expect(page.getByRole("columnheader", { name: "Billing signals", exact: true })).toBeVisible({
      timeout: 15_000
    });
  }
});
