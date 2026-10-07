// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

test("personal-only Portal mount needs no account picker and renders secure card entry", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);

  // The personal-only mount remains useful without any organization selector.
  await page.goto("/billing/payment-methods/new");
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-identity")).toHaveCount(0);
  await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toBeVisible();
  await expect(page.locator('input[name="payment_method_nonce"]')).toHaveCount(1);

});

test("host-selected member context shows its billable and blocks payment collection", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);

  // Host-owned organization switching establishes a distinct context. This normal
  // member can review the organization but cannot initialize payment collection.
  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const selected = await page.request.post("/app/organization-scope", {
    headers: { "x-sandbox-id": sandboxId },
    form: { _csrf_token: csrfToken, organization_slug: fixture.org_alpha_slug }
  });
  expect(selected.ok()).toBeTruthy();

  const response = await page.goto("/shared-billing/payment-methods/new");
  expect(response.status()).toBe(200);
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-name")).toHaveText(fixture.org_alpha_name);
  await expect(page.locator(".portal-billable-detail")).toHaveText("Workspace billing");
  await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toHaveCount(0);
  await expect(page.locator('#payment-method-form button[type="submit"]')).toHaveCount(0);
  await expect(page.getByRole("status")).toContainText(/can't|cannot|not allowed|managed/i);

  // The host switch link is an existing local navigation path, not Portal policy.
  await expect(page.locator('.portal-billable-identity a[href="/app/billing"]')).toBeVisible();
});
