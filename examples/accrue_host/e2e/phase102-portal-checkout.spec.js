// @ts-check
const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;
const { readFixture, reseedFixture, login, waitForLiveView } = require("./support/fixture.js");

function reseedFixtureIfNeeded() {
  if (process.env.ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED !== "1") {
    reseedFixture();
  }
}

/**
 * @param {import("@playwright/test").Page} page
 */
async function scanAxe(page) {
  const results = await new AxeBuilder({ page }).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

/**
 * @param {import("@playwright/test").Page} page
 * @param {string} code
 */
async function applyPromoCode(page, code) {
  const input = page.locator("#promo-code-input");

  await input.click();
  await input.press(process.platform === "darwin" ? "Meta+A" : "Control+A");
  await input.press("Backspace");
  await input.pressSequentially(code);
  await input.blur();
}

test("portal checkout promo preview updates totals in a real browser", async ({ page }) => {
  reseedFixtureIfNeeded();
  const fixture = readFixture();

  await login(page, fixture, fixture.normal_email);
  await page.goto(fixture.portal_checkout_url, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  await expect(page.getByRole("button", { name: "Pay $49.00" })).toBeVisible();

  await applyPromoCode(page, "SPRING25");

  await expect(page.getByText("Discount ready.")).toBeVisible();
  await expect(page.getByText("Estimated savings: $25.00")).toBeVisible();
  await expect(page.getByText("Estimated total: $24.00")).toBeVisible();
  await expect(
    page.getByText("Preview only. Final total is confirmed after secure submit.")
  ).toBeVisible();
  await expect(page.getByRole("button", { name: "Pay $24.00" })).toBeVisible();
});

test("portal checkout promo invalid and drift copy stays accessible and customer-safe", async ({ page }) => {
  reseedFixtureIfNeeded();
  const fixture = readFixture();

  await login(page, fixture, fixture.normal_email);
  await page.goto(fixture.portal_checkout_url, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  await applyPromoCode(page, "missing");
  await expect(page.getByText("This code is unavailable. Check the code and try again.")).toBeVisible();
  await expect(page.getByRole("button", { name: "Pay $49.00" })).toBeVisible();

  let violations = await scanAxe(page);
  expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);

  await applyPromoCode(page, "BROKEN");
  await expect(page.getByText("This promotion is temporarily unavailable.")).toBeVisible();

  violations = await scanAxe(page);
  expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
});
