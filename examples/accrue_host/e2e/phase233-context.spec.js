// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

async function installBraintreeInitializationProbe(page) {
  await page.addInitScript(() => {
    const counts = { clientCreate: 0, hostedFieldsCreate: 0 };
    const sdk = {
      client: {
        create(_options, callback) {
          counts.clientCreate += 1;
          callback(null, {});
        }
      },
      hostedFields: {
        create(_options, callback) {
          counts.hostedFieldsCreate += 1;
          callback(null, { teardown(done) { if (done) done(); } });
        }
      }
    };

    Object.defineProperty(window, "__braintreeInitializationCounts", {
      configurable: false,
      value: counts
    });
    Object.defineProperty(window, "braintree", {
      configurable: false,
      get() { return sdk; },
      set() {}
    });
  });
}

test("personal-only Portal mount needs no account picker and renders secure card entry", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);

  // The personal-only mount remains useful without any organization selector.
  await page.goto("/billing/payment-methods/new");
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-identity")).toHaveCount(0);
  await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toBeVisible();
  await expect(page.locator('input[name="payment_method_nonce"]')).toHaveCount(1);

  const checkoutPage = await page.context().newPage();
  await installBraintreeInitializationProbe(checkoutPage);
  await login(checkoutPage, fixture, fixture.normal_email, sandboxId);
  await checkoutPage.goto(fixture.portal_checkout_url);
  await waitForLiveView(checkoutPage);
  await expect(checkoutPage.locator('[data-portal-hosted-fields="checkout"]')).toBeVisible();
  await expect(checkoutPage.getByRole("button", { name: /^Pay / })).toBeVisible();
  await expect.poll(() => checkoutPage.evaluate(() => window.__braintreeInitializationCounts)).toEqual({
    clientCreate: 1,
    hostedFieldsCreate: 1
  });
  await checkoutPage.close();
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

  // This checkout belongs to the organization. A read-only member can reach the
  // shared mount but receives no payment collection controls.
  await page.goto(fixture.org_portal_checkout_url);
  await waitForLiveView(page);
  await expect(page.locator('[data-portal-hosted-fields="checkout"]')).toHaveCount(0);
  await expect(page.locator('#checkout-form button[type="submit"]')).toHaveCount(0);
  await expect(page.getByRole("status")).toContainText("Checkout access is unavailable. No payment was submitted.");

  // A retained personal tab keeps its own identity and form locator after the
  // host's selected organization changes in another tab.
  await expect(oldTab.locator(".portal-billable-name")).toHaveText(fixture.normal_email);
  await expect(oldTab.locator('input[name="context_pin"]')).toHaveValue(personalPin);

  // A reconnect must revalidate the old signed identity against current host policy.
  await oldTab.reload();
  await waitForLiveView(oldTab);
  await expect(oldTab.locator(".portal-billable-name")).toHaveText(fixture.normal_email);
  await expect(oldTab.locator('input[name="context_pin"]')).toHaveValue(personalPin);
  await expect(oldTab.locator('[data-portal-hosted-fields="payment-method"]')).toBeVisible();

  await page.goto("/admin");
  await expect(page).toHaveURL(/\/$/);
  await oldTab.close();
});

test("host switch rejects invalid or unauthorized slugs while retaining personal selection", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);

  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const personalSelection = await page.request.post("/app/organization-scope", {
    headers: { "x-sandbox-id": sandboxId },
    form: { _csrf_token: csrfToken, organization_slug: "personal" }
  });
  expect(personalSelection.ok()).toBeTruthy();

  for (const unavailableSlug of [
    "does-not-exist",
    fixture.admin_org_alpha_slug,
    fixture.revoked_org_slug,
    fixture.deleted_org_slug
  ]) {
    const response = await page.request.post("/app/organization-scope", {
      headers: { "x-sandbox-id": sandboxId },
      form: { _csrf_token: csrfToken, organization_slug: unavailableSlug }
    });
    expect(response.ok()).toBeTruthy();

    await page.goto("/shared-billing/payment-methods/new");
    await waitForLiveView(page);
    await expect(page.locator(".portal-billable-name")).toHaveText(fixture.normal_email);
    await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toBeVisible();
  }
});

test("revoked organization pin blocks reload and submit without falling back", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.revocable_member_email, sandboxId);

  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const selected = await page.request.post("/app/organization-scope", {
    headers: { "x-sandbox-id": sandboxId },
    form: { _csrf_token: csrfToken, organization_slug: fixture.revocable_member_org_slug }
  });
  expect(selected.ok()).toBeTruthy();

  await page.goto("/shared-billing/payment-methods/new");
  await waitForLiveView(page);
  await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toBeVisible();
  const pin = await page.locator('#payment-method-form input[name="context_pin"]').inputValue();
  expect(pin).toBeTruthy();
  const pinnedPath = `/shared-billing/payment-methods/new?context_pin=${encodeURIComponent(pin)}`;

  const revoked = await page.request.post("/api/e2e/revoke-membership", {
    headers: { "x-sandbox-id": sandboxId },
    form: {
      _csrf_token: await page.locator('meta[name="csrf-token"]').getAttribute("content"),
      organization_slug: fixture.revocable_member_org_slug
    }
  });
  expect(revoked.status()).toBe(204);

  await page.goto(pinnedPath);
  await waitForLiveView(page);
  await expect(page).toHaveURL(/\/shared-billing\/blocked$/);
  await expect(page.getByRole("alert")).toContainText("Billing access unavailable");
  await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toHaveCount(0);
  await expect(page.locator('#payment-method-form button[type="submit"]')).toHaveCount(0);

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
  expect(response.headers().location).toBe("/shared-billing/blocked");
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

test("a billing manager can mutate organization billing without Admin privileges", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.billing_manager_email, sandboxId);

  await page.goto("/admin");
  await expect(page).toHaveURL(/\/$/);

  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const selected = await page.request.post("/app/organization-scope", {
    headers: { "x-sandbox-id": sandboxId },
    form: { _csrf_token: csrfToken, organization_slug: fixture.org_alpha_slug }
  });
  expect(selected.ok()).toBeTruthy();

  await page.goto("/shared-billing/payment-methods/new");
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-name")).toHaveText(fixture.org_alpha_name);
  await expect(page.locator('[data-portal-hosted-fields="payment-method"]')).toBeVisible();
  const pin = new URL(page.url()).searchParams.get("context_pin");
  expect(pin).toBeTruthy();

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
  await page.goto(response.headers().location);
  await waitForLiveView(page);
  await expect(page.getByText("visa ending in 4242").first()).toBeVisible();
});
