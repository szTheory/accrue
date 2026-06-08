// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, reseedFixture, login, workspaceBillingLink, waitForLiveView } = require("./support/fixture.js");
const { expectNoHorizontalOverflow } = require("./support/overflow.js");

test.describe("@mobile mounted admin shell and customers", () => {
  test.beforeEach(({}, testInfo) => {
    test.skip(
      testInfo.project.name !== "chromium-mobile",
      "MOB layout proofs require real Pixel 5 project"
    );
  });

  test.beforeEach(() => {
    // When global setup already seeded the fixture, skip per-test reseed for parity with CI.
    if (process.env.ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED !== "1") {
      reseedFixture();
    }
  });

  test("MOB-01 MOB-03 org-scoped customers journey without horizontal overflow", async ({ page, sandboxId }) => {
    const fixture = readFixture();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    const orgButton = page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`);
    await orgButton.scrollIntoViewIfNeeded();
    await orgButton.click();
    await waitForLiveView(page);

    const customersUrl = `/admin/customers?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(customersUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.getByText("Active organization", { exact: true })).toBeVisible({ timeout: 15_000 });
    await expectNoHorizontalOverflow(page, "customers index");

    await page.goto(
      `/admin/customers/${fixture.admin_denial_customer_id}?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`,
      { waitUntil: "domcontentloaded" }
    );
    await waitForLiveView(page);
    await expectNoHorizontalOverflow(page, "customer detail");
  });

  test("MOB-02 Menu opens primary nav links; Escape closes drawer", async ({ page, sandboxId }) => {
    const fixture = readFixture();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    const orgButton = page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`);
    await orgButton.scrollIntoViewIfNeeded();
    await orgButton.click();
    await waitForLiveView(page);

    const customersUrl = `/admin/customers?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(customersUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expectNoHorizontalOverflow(page, "customers index");

    await page.getByRole("button", { name: "Menu" }).click();
    const sidebar = page.locator(".ax-sidebar");
    await expect(sidebar.getByRole("link", { name: /Home/i })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: /Customers/i })).toBeVisible();
    await expect(sidebar.getByRole("link", { name: /Subscriptions/i })).toBeVisible();

    await page.keyboard.press("Escape");
    // Drawer state is `html.accrue-admin.ax-shell-nav-open` (class ax-shell-nav-open on documentElement).
    const closed = await page.evaluate(() => !document.documentElement.classList.contains("ax-shell-nav-open"));
    expect(closed).toBe(true);
  });
});
