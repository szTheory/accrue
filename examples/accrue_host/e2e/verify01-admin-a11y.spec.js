// @ts-check
const path = require("path");
const fs = require("fs");
const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;
const { readFixture, reseedFixture, login, waitForLiveView } = require("./support/fixture.js");

const copyStrings = JSON.parse(
  fs.readFileSync(path.join(__dirname, "generated", "copy_strings.json"), "utf8")
);

/**
 * @param {import('@playwright/test').Page} page
 */
async function scanAxe(page) {
  const results = await new AxeBuilder({ page }).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

test("mounted admin customers index passes axe in light and dark themes", async ({ page }, testInfo) => {
  test.skip(
    testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
    "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
  );

  reseedFixture();
  const fixture = readFixture();

  expect(fixture.admin_org_alpha_slug).toBeTruthy();

  await login(page, fixture, fixture.admin_email);
  await page.getByRole("link", { name: "Go to billing" }).click();
  await waitForLiveView(page);

  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);

  const customersUrl = `/billing/customers?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
  await page.goto(customersUrl, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  await expect(page.locator("html")).toHaveClass(/accrue-admin/);

  const lightBtn = page.locator('button[data-theme-target="light"]');
  await expect(lightBtn).toBeVisible();
  await lightBtn.click();
  await waitForLiveView(page);
  await expect(page.locator("html")).toHaveAttribute("data-theme", "light");

  let violations = await scanAxe(page);
  expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);

  const darkBtn = page.locator('button[data-theme-target="dark"]');
  await expect(darkBtn).toBeVisible();
  await darkBtn.click();
  await waitForLiveView(page);
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");

  await page.waitForFunction(
    () => {
      const el = document.querySelector("a.ax-sidebar-link-active");
      if (!el) return false;
      const bg = getComputedStyle(el).backgroundColor;
      return bg.includes("31") && bg.includes("40") && bg.includes("61");
    },
    { timeout: 5000 }
  );

  violations = await scanAxe(page);
  expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
});

test("mounted admin subscriptions index passes axe in light theme", async ({ page }, testInfo) => {
  test.skip(
    testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
    "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
  );

  reseedFixture();
  const fixture = readFixture();

  expect(fixture.admin_org_alpha_slug).toBeTruthy();

  await login(page, fixture, fixture.admin_email);
  await page.getByRole("link", { name: "Go to billing" }).click();
  await waitForLiveView(page);

  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);

  const subscriptionsUrl = `/billing/subscriptions?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
  await page.goto(subscriptionsUrl, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  await expect(page.locator("html")).toHaveClass(/accrue-admin/);

  const lightBtn = page.locator('button[data-theme-target="light"]');
  await expect(lightBtn).toBeVisible();
  await lightBtn.click();
  await waitForLiveView(page);
  await expect(page.locator("html")).toHaveAttribute("data-theme", "light");

  await expect(page.getByText(copyStrings.subscriptions_index_empty_title)).toBeVisible();

  const violations = await scanAxe(page);
  expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
});
