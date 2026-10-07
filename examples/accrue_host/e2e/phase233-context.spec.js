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

  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const personalSelection = await page.request.post("/app/organization-scope", {
    headers: { "x-sandbox-id": sandboxId },
    form: { _csrf_token: csrfToken, organization_slug: "personal" }
  });
  expect(personalSelection.ok()).toBeTruthy();

  // Resolve a personal context in the adapter mount and retain its signed pin
  // in another tab before changing the host's active organization.
  await page.goto("/shared-billing/payment-methods/new");
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-name")).toHaveText(fixture.normal_email);
  await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toBeVisible();
  const personalPin = new URL(page.url()).searchParams.get("context_pin");
  expect(personalPin).toBeTruthy();

  const oldTab = await page.context().newPage();
  await oldTab.goto(`/shared-billing/payment-methods/new?context_pin=${encodeURIComponent(personalPin)}`);
  await waitForLiveView(oldTab);
  await expect(oldTab.locator(".portal-billable-name")).toHaveText(fixture.normal_email);

  // Host-owned organization switching establishes a distinct context. This normal
  // member can review the organization but cannot initialize payment collection.
  const orgCsrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const selected = await page.request.post("/app/organization-scope", {
    headers: { "x-sandbox-id": sandboxId },
    form: { _csrf_token: orgCsrfToken, organization_slug: fixture.org_alpha_slug }
  });
  expect(selected.ok()).toBeTruthy();

  const response = await page.goto("/shared-billing/payment-methods/new");
  expect(response.status()).toBe(200);
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-name")).toHaveText(fixture.org_alpha_name);
  await expect(page.locator(".portal-billable-detail")).toHaveText("Workspace billing");
  await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toHaveCount(0);
  await expect(page.locator('#payment-method-form button[type="submit"]')).toHaveCount(0);
  await expect(page.getByRole("status")).toContainText(/permission|not allowed|managed/i);

  // The host switch link is an existing local navigation path, not Portal policy.
  await expect(page.locator('.portal-billable-identity a[href="/app/billing"]')).toBeVisible();

  // A retained personal tab keeps its own identity and form locator after the
  // host's selected organization changes in another tab.
  await expect(oldTab.locator(".portal-billable-name")).toHaveText(fixture.normal_email);
  await expect(oldTab.locator('input[name="context_pin"]')).toHaveValue(personalPin);

  await page.goto("/admin");
  await expect(page).toHaveURL(/\/$/);
  await oldTab.close();
});

test("an authorized organization manager completes a real Portal payment method mutation", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.admin_email, sandboxId);

  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const selected = await page.request.post("/app/organization-scope", {
    headers: { "x-sandbox-id": sandboxId },
    form: { _csrf_token: csrfToken, organization_slug: fixture.admin_org_alpha_slug }
  });
  expect(selected.ok()).toBeTruthy();

  await page.goto("/shared-billing/payment-methods/new");
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-name")).toHaveText("Admin E2E Alpha Org");
  await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toBeVisible();
  const pin = new URL(page.url()).searchParams.get("context_pin");
  expect(pin).toBeTruthy();

  // The deterministic test nonce passes through the mounted Portal POST and
  // Fake processor; no external processor or live-card result is involved.
  const response = await page.request.post("/shared-billing/payment-methods", {
    maxRedirects: 0,
    headers: { "x-sandbox-id": sandboxId },
    form: {
      _csrf_token: await page.locator('meta[name="csrf-token"]').getAttribute("content"),
      context_pin: pin,
      payment_method_nonce: "fake-valid-nonce"
    }
  });
  expect(response.status()).toBe(302);
  const location = response.headers().location;
  expect(location).toContain("/shared-billing/payment-methods?context_pin=");
  await page.goto(location);
  await waitForLiveView(page);
  await expect(page.getByText("visa ending in 4242").first()).toBeVisible();

  // Confirm the persisted event names a human actor in the mounted Admin ledger.
  await page.goto("/admin/events?q=payment_method.added");
  await waitForLiveView(page);
  const mutationRow = page.getByRole("row").filter({ hasText: "payment_method.added" });
  await expect(mutationRow).toHaveCount(1);
  await expect(mutationRow).toContainText("User ");
});
