// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

test("global search completes real scoped database queries and removes stale matches", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  const email = "admin-e2e-alpha-customer@example.test";
  const org = fixture.admin_org_alpha_slug;
  const customerId = fixture.admin_denial_customer_id;

  expect(process.env.ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX).toBe("1");
  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.locator('[data-testid="workspace-billing-link"]').click();
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${org}"]`).click();
  await waitForLiveView(page);
  await page.goto(`/admin?org=${encodeURIComponent(org)}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  await page.locator("[data-command-palette-trigger]").first().click();
  const dialog = page.getByRole("dialog", { name: /global search/i });
  const input = dialog.locator("#global-search-input");
  await expect(dialog).toBeVisible();
  await input.fill(email);

  const result = dialog.locator('[data-search-group="customers"] a').filter({ hasText: email });
  await expect(result).toBeVisible({ timeout: 10_000 });
  await expect(result).toContainText(`Customer ID: ${customerId}`);
  const activeStatus = dialog.locator("[data-active-result-status]");
  await expect(activeStatus).toContainText(email);
  await expect(result).toHaveClass(/ax-active/);

  const href = await result.getAttribute("href");
  expect(href).toBeTruthy();
  const target = new URL(href, page.url());
  expect(target.pathname).toBe(`/admin/customers/${customerId}`);
  expect(target.searchParams.get("org")).toBe(org);

  await input.fill("no-such-customer-234@example.test");
  await expect(result).toHaveCount(0);
  await expect(dialog).toContainText('No billing records match "no-such-customer-234@example.test"');
  await input.fill(email);
  await expect(result).toBeVisible({ timeout: 10_000 });
  await expect(result).toHaveClass(/ax-active/);
  await result.hover();
  await expect(result).toHaveClass(/ax-active/);
  await expect(activeStatus).toContainText(email);
  await input.focus();
  const matches = dialog.locator("[data-search-group] a");
  const matchCount = await matches.count();
  expect(matchCount).toBeGreaterThan(0);
  // Other mounted owners may have added an invoice for this customer. Arrow
  // navigation follows every matching group, then returns to the customer.
  await page.keyboard.press("ArrowDown");
  if (matchCount > 1) {
    await expect(result).not.toHaveClass(/ax-active/);
    await expect(matches.nth(1)).toHaveClass(/ax-active/);
    await expect(activeStatus).toHaveText(await matches.nth(1).innerText());
    await page.keyboard.press("ArrowUp");
  }
  await expect(result).toHaveClass(/ax-active/);
  await expect(activeStatus).toContainText(`Customer ID: ${customerId}`);
  await page.keyboard.press("Enter");
  await waitForLiveView(page);
  await expect(page).toHaveURL(new RegExp(`/admin/customers/${customerId}\\?`));

  await page.goto(`/admin?org=${encodeURIComponent(org)}`);
  await waitForLiveView(page);
  await page.locator("[data-command-palette-trigger]").first().click();
  const reopened = page.getByRole("dialog", { name: /global search/i });
  const reopenedInput = reopened.locator("#global-search-input");
  await reopenedInput.fill("no-such-customer-234@example.test");
  const reopenedResult = reopened.locator('[data-search-group="customers"] a').filter({ hasText: email });
  await expect(reopenedResult).toHaveCount(0);
  await expect(reopened).toContainText('No billing records match "no-such-customer-234@example.test"');
  await reopenedInput.fill(email);
  await expect(reopenedResult).toBeVisible({ timeout: 10_000 });
  await expect(reopenedResult).toHaveClass(/ax-active/);
  await reopenedResult.click();
  await waitForLiveView(page);
  await expect(page).toHaveURL(new RegExp(`/admin/customers/${customerId}\\?`));
  await expect(page.getByRole("heading", { name: email })).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`[?&]org=${encodeURIComponent(org)}(?:&|$)`));
});
