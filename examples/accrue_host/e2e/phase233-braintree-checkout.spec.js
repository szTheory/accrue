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

test("configured Braintree personal checkout initializes Hosted Fields", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await installBraintreeInitializationProbe(page);
  await login(page, fixture, fixture.normal_email, sandboxId);

  await page.goto(fixture.portal_checkout_url);
  await waitForLiveView(page);

  await expect(page.locator('[data-portal-hosted-fields="checkout"]')).toBeVisible();
  await expect(page.locator("#checkout-form button[type=\"submit\"]")).toBeVisible();
  await expect.poll(() => page.evaluate(() => window.__braintreeInitializationCounts)).toEqual({
    clientCreate: 1,
    hostedFieldsCreate: 1
  });
});

test("matching Braintree organization checkout still enforces the host action grant", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await installBraintreeInitializationProbe(page);
  await login(page, fixture, fixture.normal_email, sandboxId);

  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const selected = await page.request.post("/app/organization-scope", {
    headers: { "x-sandbox-id": sandboxId },
    form: { _csrf_token: csrfToken, organization_slug: fixture.org_alpha_slug }
  });
  expect(selected.ok()).toBeTruthy();

  await page.goto(fixture.org_portal_checkout_url);
  await waitForLiveView(page);

  await expect(page.getByRole("status")).toContainText(
    "Checkout access is unavailable. No payment was submitted."
  );
  await expect(page.locator('[data-portal-hosted-fields="checkout"]')).toHaveCount(0);
  await expect(page.locator("#checkout-form")).toHaveCount(0);
  await expect.poll(() => page.evaluate(() => window.__braintreeInitializationCounts)).toEqual({
    clientCreate: 0,
    hostedFieldsCreate: 0
  });
});
