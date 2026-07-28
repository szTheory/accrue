// @ts-check
const path = require("path");
const fs = require("fs");
const { test, expect } = require("./support/test.js");
const AxeBuilder = require("@axe-core/playwright").default;
const { readFixture, reseedFixture, login, workspaceBillingLink, waitForLiveView } = require("./support/fixture.js");

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

function reseedFixtureIfNeeded() {
  if (process.env.ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED !== "1") {
    reseedFixture();
  }
}

/**
 * @param {import('@playwright/test').Page} page
 * @param {string} paymentMethodId
 */
function paymentMethodRow(page, last4) {
  return page.locator("[data-role='payment-method-action-row']").filter({ hasText: last4 });
}

async function openDeleteConfirmation(page, last4) {
  const row = paymentMethodRow(page, last4);
  await expect(row).toBeVisible();
  await row.getByRole("button", { name: new RegExp(copyStrings.customer_payment_methods_delete_action) }).click();

  const dialog = page.getByRole("dialog", { name: copyStrings.customer_payment_methods_delete_action });
  await expect(dialog).toBeVisible();
  return dialog;
}

/**
 * @param {import('@playwright/test').Page} page
 */
async function waitForDarkThemeSettled(page) {
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");

  // Wait until the dark CSS has actually painted before running axe. Assert the
  // *character* of the dark theme (dark chrome surfaces + light control text)
  // rather than exact rgb literals: the surfaces are cobalt-tinted color-mix()
  // values that (a) drift with token tuning and (b) modern Chrome serializes as
  // `color(srgb r g b)`, not `rgb(...)`. Parse both forms and check darkness.
  await page.waitForFunction(
    () => {
      const parse = (value) => {
        if (!value) return null;
        const rgb = value.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
        if (rgb) return [Number(rgb[1]), Number(rgb[2]), Number(rgb[3])];
        const srgb = value.match(/color\(srgb\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i);
        if (srgb) return srgb.slice(1, 4).map((c) => Math.round(Number(c) * 255));
        return null;
      };
      const search = document.querySelector(".ax-search-trigger");
      const darkButton = document.querySelector('button[data-theme-target="dark"]');
      const activeNav = document.querySelector("a.ax-sidebar-link-active");
      if (!search || !darkButton || !activeNav) return false;

      const searchBg = parse(getComputedStyle(search).backgroundColor);
      const navBg = parse(getComputedStyle(activeNav).backgroundColor);
      const btnColor = parse(getComputedStyle(darkButton).color);
      if (!searchBg || !navBg || !btnColor) return false;

      const isDarkSurface = (c) => c[0] + c[1] + c[2] < 300;
      const isLightText = (c) => c[0] + c[1] + c[2] > 600;
      return isDarkSurface(searchBg) && isDarkSurface(navBg) && isLightText(btnColor);
    },
    { timeout: 5_000 }
  );
}

test("mounted admin customers index passes axe in light and dark themes", async ({ page, sandboxId }, testInfo) => {
  test.skip(
    testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
    "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
  );

  reseedFixtureIfNeeded();
  const fixture = readFixture();

  expect(fixture.admin_org_alpha_slug).toBeTruthy();

  await login(page, fixture, fixture.admin_email, sandboxId);
  await workspaceBillingLink(page).click();
  await waitForLiveView(page);

  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);

  const customersUrl = `/admin/customers?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
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
  await waitForDarkThemeSettled(page);

  violations = await scanAxe(page);
  expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
});

test("mounted admin subscriptions index passes axe in light theme", async ({ page, sandboxId }, testInfo) => {
  test.skip(
    testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
    "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
  );

  reseedFixtureIfNeeded();
  const fixture = readFixture();

  expect(fixture.admin_org_alpha_slug).toBeTruthy();

  await login(page, fixture, fixture.admin_email, sandboxId);
  await workspaceBillingLink(page).click();
  await waitForLiveView(page);

  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);

  const subscriptionsUrl = `/admin/subscriptions?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
  await page.goto(subscriptionsUrl, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  await expect(page.locator("html")).toHaveClass(/accrue-admin/);

  const lightBtn = page.locator('button[data-theme-target="light"]');
  await expect(lightBtn).toBeVisible();
  await lightBtn.click();
  await waitForLiveView(page);
  await expect(page.locator("html")).toHaveAttribute("data-theme", "light");

  const violations = await scanAxe(page);
  expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
});

test.describe("VERIFY-01 admin Connect index (auxiliary)", () => {
  test("mounted admin Connect index passes axe in light theme", async ({ page, sandboxId }, testInfo) => {
    test.skip(
      testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
      "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
    );

    reseedFixtureIfNeeded();
    const fixture = readFixture();

    expect(fixture.admin_org_alpha_slug).toBeTruthy();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);

    const connectUrl = `/admin/connect?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(connectUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.locator("html")).toHaveClass(/accrue-admin/);

    const lightBtn = page.locator('button[data-theme-target="light"]');
    await expect(lightBtn).toBeVisible();
    await lightBtn.click();
    await waitForLiveView(page);
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");

    await expect(page.getByRole("heading", { name: copyStrings.connect_accounts_list_heading })).toBeVisible();
    await expect(page.locator("[data-role='filter-form']")).toBeVisible();

    const violations = await scanAxe(page);
    expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
  });
});

test.describe("VERIFY-01 admin Connect account detail (auxiliary)", () => {
  test("mounted admin Connect account detail passes axe in light theme", async ({ page, sandboxId }, testInfo) => {
    test.skip(
      testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
      "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
    );

    reseedFixtureIfNeeded();
    const fixture = readFixture();

    expect(fixture.connect_account_id).toBeTruthy();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);

    const detailUrl = `/admin/connect/${fixture.connect_account_id}?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(detailUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.locator("html")).toHaveClass(/accrue-admin/);

    const lightBtn = page.locator('button[data-theme-target="light"]');
    await expect(lightBtn).toBeVisible();
    await lightBtn.click();
    await waitForLiveView(page);
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");

    await expect(page.getByText(copyStrings.connect_account_eyebrow)).toBeVisible();
    await expect(page.getByRole("heading", { name: copyStrings.connect_account_actions_heading })).toBeVisible();
    await expect(
      page.locator("button", { hasText: copyStrings.connect_account_action_edit_platform_fee_override })
    ).toBeVisible();

    const violations = await scanAxe(page);
    expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
  });
});

test.describe("VERIFY-01 admin billing events index (auxiliary)", () => {
  test("mounted admin events index passes axe in light theme", async ({ page, sandboxId }, testInfo) => {
    test.skip(
      testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
      "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
    );

    reseedFixtureIfNeeded();
    const fixture = readFixture();

    expect(fixture.admin_org_alpha_slug).toBeTruthy();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);

    const eventsUrl = `/admin/events?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(eventsUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.locator("html")).toHaveClass(/accrue-admin/);

    const lightBtn = page.locator('button[data-theme-target="light"]');
    await expect(lightBtn).toBeVisible();
    await lightBtn.click();
    await waitForLiveView(page);
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");

    await expect(
      page.getByRole("heading", { name: copyStrings.events_list_heading })
    ).toBeVisible();

    const violations = await scanAxe(page);
    expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
  });
});

test.describe("VERIFY-01 admin coupons index (auxiliary)", () => {
  test("mounted admin coupons index passes axe in light theme", async ({ page, sandboxId }, testInfo) => {
    test.skip(
      testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
      "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
    );

    reseedFixtureIfNeeded();
    const fixture = readFixture();

    expect(fixture.admin_org_alpha_slug).toBeTruthy();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);

    const couponsUrl = `/admin/coupons?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(couponsUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.locator("html")).toHaveClass(/accrue-admin/);

    const lightBtn = page.locator('button[data-theme-target="light"]');
    await expect(lightBtn).toBeVisible();
    await lightBtn.click();
    await waitForLiveView(page);
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");

    await expect(page.getByRole("heading", { name: copyStrings.coupons_list_heading })).toBeVisible();

    const violations = await scanAxe(page);
    expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
  });
});

test.describe("VERIFY-01 admin promotion codes index (auxiliary)", () => {
  test("mounted admin promotion codes index passes axe in light theme", async ({ page, sandboxId }, testInfo) => {
    test.skip(
      testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
      "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
    );

    reseedFixtureIfNeeded();
    const fixture = readFixture();

    expect(fixture.admin_org_alpha_slug).toBeTruthy();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);

    const promoUrl = `/admin/promotion-codes?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(promoUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.locator("html")).toHaveClass(/accrue-admin/);

    const lightBtn = page.locator('button[data-theme-target="light"]');
    await expect(lightBtn).toBeVisible();
    await lightBtn.click();
    await waitForLiveView(page);
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");

    await expect(page.getByRole("heading", { name: copyStrings.promotion_codes_list_heading })).toBeVisible();

    const violations = await scanAxe(page);
    expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
  });
});

test.describe("core-admin-invoices-index", () => {
  test("invoice index passes axe in light and dark themes", async ({ page, sandboxId }, testInfo) => {
    test.skip(
      testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
      "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
    );

    reseedFixtureIfNeeded();
    const fixture = readFixture();

    expect(fixture.admin_org_alpha_slug).toBeTruthy();
    expect(fixture.invoice_id).toBeTruthy();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);

    const invoicesUrl = `/admin/invoices?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(invoicesUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.locator("html")).toHaveClass(/accrue-admin/);

    await expect(page.getByRole("heading", { name: copyStrings.invoices_list_heading })).toBeVisible();

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
    await waitForDarkThemeSettled(page);

    violations = await scanAxe(page);
    expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
  });
});

test.describe("core-admin-invoices-detail", () => {
  test("invoice detail shows PDF control enabled (D-07)", async ({ page, sandboxId }, testInfo) => {
    test.skip(
      testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
      "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
    );

    reseedFixtureIfNeeded();
    const fixture = readFixture();

    expect(fixture.invoice_id).toBeTruthy();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);

    const detailUrl = `/admin/invoices/${fixture.invoice_id}?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(detailUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.locator("html")).toHaveClass(/accrue-admin/);

    await expect(page.getByText(copyStrings.invoice_detail_eyebrow)).toBeVisible();

    const taxDocuments = page.locator("[data-ax-drill-section='tax-documents']");

    if ((await taxDocuments.getAttribute("open")) === null) {
      await taxDocuments.locator("summary").click();
    }

    // D-07: primary on-demand PDF affordance is the LiveView button (D-08 download/popup optional).
    const pdfButton = taxDocuments.getByRole("button", { name: copyStrings.invoice_open_pdf_button });
    await expect(pdfButton).toBeVisible();
    await expect(pdfButton).toBeEnabled();
  });
});

test.describe("VERIFY-01 admin customer detail payment_methods tab (v1.24 ADM-15)", () => {
  test("passes axe in light and dark themes on desktop", async ({ page, sandboxId }, testInfo) => {
    test.skip(
      testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
      "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
    );

    reseedFixtureIfNeeded();
    const fixture = readFixture();

    expect(fixture.admin_org_alpha_slug).toBeTruthy();
    expect(fixture.admin_denial_customer_id).toBeTruthy();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);

    const pmUrl = `/admin/customers/${fixture.admin_denial_customer_id}?tab=payment_methods&org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(pmUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.locator("html")).toHaveClass(/accrue-admin/);

    const paymentMethods = page.locator("[data-ax-drill-section='payment-methods']");
    await expect(paymentMethods.getByText(copyStrings.customer_payment_methods_section_heading)).toBeVisible();
    await expect(
      page.getByText(copyStrings.customer_payment_methods_replace_handoff)
    ).toBeVisible();
    await expect(
      page.getByText(copyStrings.customer_payment_methods_section_body)
    ).toContainText("host billing flow");

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
    await waitForDarkThemeSettled(page);

    violations = await scanAxe(page);
    expect(violations, JSON.stringify(violations, null, 2)).toEqual([]);
  });

  test("enforces host-owned capture boundary and guarded delete states", async ({ page, sandboxId }) => {
    reseedFixtureIfNeeded();
    const fixture = readFixture();

    expect(fixture.admin_org_alpha_slug).toBeTruthy();
    expect(fixture.admin_denial_customer_id).toBeTruthy();
    expect(fixture.admin_denial_payment_method_ids).toBeTruthy();

    await login(page, fixture, fixture.admin_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);

    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);

    const pmUrl = `/admin/customers/${fixture.admin_denial_customer_id}?tab=payment_methods&org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
    await page.goto(pmUrl, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.getByText(copyStrings.customer_payment_methods_replace_handoff)).toBeVisible();
    await expect(page.getByText(/drop-in/i)).toHaveCount(0);
    await expect(page.getByText(/hosted fields/i)).toHaveCount(0);
    await expect(page.getByLabel(/card number/i)).toHaveCount(0);
    await expect(page.locator("iframe[name*='braintree']")).toHaveCount(0);
    await expect(page.locator("[data-braintree-client-token]")).toHaveCount(0);

    const inUseRow = paymentMethodRow(page, "1111");
    await expect(inUseRow).toBeVisible();
    await expect(
      inUseRow.getByRole("button", { name: new RegExp(copyStrings.customer_payment_methods_delete_action) })
    ).toHaveCount(0);

    const defaultRow = paymentMethodRow(page, "2222");
    await expect(defaultRow).toBeVisible();
    await expect(
      defaultRow.getByRole("button", { name: new RegExp(copyStrings.customer_payment_methods_delete_action) })
    ).toHaveCount(0);

    const deleteDialog = await openDeleteConfirmation(page, "3333");
    await expect(page.getByText(copyStrings.customer_payment_methods_delete_warning)).toHaveCount(0);
    await expect(deleteDialog.locator("[data-role='payment-method-action-content']")).toBeVisible();
    await expect(deleteDialog.locator("[data-role='confirm-payment-method-action']")).toHaveCount(1);
    await expect(deleteDialog.getByText(copyStrings.customer_payment_methods_delete_blocked_in_use)).toHaveCount(0);
    await expect(
      deleteDialog.getByText(copyStrings.customer_payment_methods_delete_blocked_replacement_required)
    ).toHaveCount(0);
  });
});
