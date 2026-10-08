// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

async function selectAdminOrganization(page, fixture, organizationSlug) {
  await page.locator('[data-testid="workspace-billing-link"]').click();
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${organizationSlug}"]`).click();
  await waitForLiveView(page);
}

test("out-of-scope Admin deep links deny safely and retain an authorized positive control", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  const customerEmail = "admin-e2e-alpha-customer@example.test";
  const paymentToken = "pm_host_org_in_use_1111";
  const customerPath = `/admin/customers/${fixture.admin_denial_customer_id}`;

  await login(page, fixture, fixture.admin_email, sandboxId);
  await selectAdminOrganization(page, fixture, fixture.admin_org_alpha_slug);
  const deniedResponse = await page.goto(`${customerPath}?org=${encodeURIComponent(fixture.admin_org_beta_slug)}`, { waitUntil: "domcontentloaded" });
  expect(deniedResponse?.status()).toBeLessThan(500);
  await expect(page).toHaveURL(/\/$/);
  await expect(page.locator("html.accrue-admin")).toHaveCount(0);
  await expect(page.locator("body")).not.toContainText(customerEmail);
  await expect(page.locator("body")).not.toContainText(paymentToken);

  // The authorized counterpart proves the same deep link works in its owning scope.
  await page.goto(`${customerPath}?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: customerEmail })).toBeVisible();
  await expect(page.locator("body")).not.toContainText(paymentToken);

  // Send a forged LiveView event for a payment method owned by another customer.
  await page.evaluate((foreignPaymentMethodId) => {
    const forged = document.createElement("button");
    forged.type = "button";
    forged.textContent = "forged payment action";
    forged.setAttribute("phx-click", "open_payment_method_action");
    forged.setAttribute("phx-value-action_type", "set_default");
    forged.setAttribute("phx-value-payment_method_id", foreignPaymentMethodId);
    document.querySelector("main")?.append(forged);
    forged.click();
  }, fixture.portal_payment_method_ids.default);
  await expect(page.locator("#customer-payment-method-action-drawer")).toBeHidden();
  await expect(page.locator("body")).not.toContainText(fixture.portal_payment_method_ids.default);
  await expect(page.locator("body")).not.toContainText(paymentToken);

  const unknownCustomerId = "00000000-0000-4000-8000-000000000000";
  await page.goto(`/admin/customers/${unknownCustomerId}?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByText(
    "Access restricted. This admin account cannot view billing for this organization. Switch owner scope or ask an administrator to grant billing admin access.",
    { exact: true }
  )).toBeVisible();
  await expect(page.locator("body")).not.toContainText(unknownCustomerId);
  await expect(page.locator("body")).not.toContainText(paymentToken);
});

test("customer billing manager cannot mount Admin or read customer/payment details", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.billing_manager_email, sandboxId);
  const response = await page.goto(`/admin/customers/${fixture.admin_denial_customer_id}`, { waitUntil: "domcontentloaded" });
  expect(response?.status()).toBeLessThan(500);
  await expect(page).toHaveURL(/\/$/);
  await expect(page.locator("html.accrue-admin")).toHaveCount(0);
  await expect(page.locator("body")).not.toContainText("admin-e2e-alpha-customer@example.test");
  await expect(page.locator("body")).not.toContainText("pm_host_org_in_use_1111");
});
