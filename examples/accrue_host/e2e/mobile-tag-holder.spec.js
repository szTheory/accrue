// @ts-check
const { test, expect } = require("@playwright/test");

// Non-blocking hook so `npx playwright test --project=chromium-mobile-tagged` has a stable target.
test("@mobile placeholder reaches host root", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("body")).toBeVisible();
});
