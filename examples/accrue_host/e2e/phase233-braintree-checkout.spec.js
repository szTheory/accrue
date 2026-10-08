// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

/**
 * This injected SDK is deterministic browser-path evidence only. Production
 * checkout still loads the official Braintree client and Hosted Fields iframe
 * scripts from the URLs rendered by CheckoutLive.
 *
 * @param {import("@playwright/test").Page} page
 * @param {{ clientError?: boolean, hostedFieldsError?: boolean, outcomes?: Array<{ kind: string, nonce?: string }>, delayMs?: number }} options
 */
async function installBraintreeMock(page, options = {}) {
  await page.addInitScript((mockOptions) => {
    const counts = JSON.parse(sessionStorage.getItem("__braintreeMockCounts") || "null") || {
      clientCreate: 0,
      hostedFieldsCreate: 0,
      tokenize: 0,
      teardown: 0
    };
    const saveCounts = () => sessionStorage.setItem("__braintreeMockCounts", JSON.stringify(counts));
    const outcomes = mockOptions.outcomes || [{ kind: "success", nonce: "mock-one-time-nonce" }];
    const sdk = {
      client: {
        create(_options, callback) {
          counts.clientCreate += 1;
          saveCounts();
          callback(mockOptions.clientError ? new Error("mock SDK setup failure") : null, {});
        }
      },
      hostedFields: {
        create(_options, callback) {
          counts.hostedFieldsCreate += 1;
          saveCounts();
          if (mockOptions.hostedFieldsError) {
            callback(new Error("mock Hosted Fields setup failure"));
            return;
          }

          callback(null, {
            tokenize(done) {
              counts.tokenize += 1;
              saveCounts();
              const outcome = outcomes.shift() || { kind: "success", nonce: "mock-one-time-nonce" };
              window.setTimeout(() => {
                if (outcome.kind === "invalid") {
                  done({
                    code: "HOSTED_FIELDS_FIELDS_INVALID",
                    details: { invalidFieldKeys: ["number"] }
                  });
                  return;
                }
                if (outcome.kind === "sdk-error") {
                  done(new Error("mock tokenization service interruption"));
                  return;
                }
                done(null, { nonce: outcome.nonce });
              }, mockOptions.delayMs || 0);
            },
            teardown(done) {
              counts.teardown += 1;
              saveCounts();
              if (done) done();
            }
          });
        }
      }
    };

    Object.defineProperty(window, "__braintreeMockEvidence", {
      configurable: false,
      value: { counts, kind: "deterministic injected mock SDK; not live Braintree proof" }
    });
    Object.defineProperty(window, "braintree", {
      configurable: false,
      get() { return sdk; },
      set() {}
    });
  }, options);
}

async function openCheckout(page, fixture, sandboxId, sdkOptions = {}) {
  await installBraintreeMock(page, sdkOptions);
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.goto(fixture.portal_checkout_url);
  await waitForLiveView(page);
  await expect(page.locator('[data-portal-hosted-fields="checkout"]')).toBeVisible();
  await expect(page.locator("#checkout-form button[type=\"submit\"]")).toBeVisible();
  await expect(page.locator("#checkout-form button[type=\"submit\"]")).toBeVisible();
}

function isCheckoutPost(request, action) {
  return request.method() === "POST" &&
    new URL(request.url()).pathname === new URL(action, request.url()).pathname;
}

test("mock SDK visible submit sends one nonce and renders the server disposition", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await openCheckout(page, fixture, sandboxId);

  const form = page.locator("#checkout-form");
  const action = await form.getAttribute("action");
  await form.locator('[name="context_pin"]').evaluate((input) => {
    input.value = "deliberately-stale-context-pin";
  });
  const requestPromise = page.waitForRequest((request) => isCheckoutPost(request, action));
  const responsePromise = page.waitForResponse((response) => isCheckoutPost(response.request(), action));
  const navigationPromise = page.waitForNavigation({ waitUntil: "domcontentloaded" });
  await page.locator("#checkout-form button[type=\"submit\"]").click();

  const request = await requestPromise;
  const response = await responsePromise;
  await navigationPromise;
  const submitted = new URLSearchParams(request.postData() || "");
  expect(submitted.get("payment_method_nonce")).toBe("mock-one-time-nonce");
  expect(submitted.get("context_pin")).toBe("deliberately-stale-context-pin");
  expect(response.status()).toBe(302);
  expect(await page.evaluate(() => window.__braintreeMockEvidence.kind)).toContain("not live Braintree proof");
  await expect(page.locator("body")).toContainText("Billing access unavailable");
  expect((await page.locator("body").innerText()).includes("mock-one-time-nonce")).toBe(false);
  expect(await page.evaluate(() => window.__braintreeMockEvidence.counts.tokenize)).toBe(1);
});

test("invalid card can be retried as a fresh customer action with one transport", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await openCheckout(page, fixture, sandboxId, {
    outcomes: [
      { kind: "invalid" },
      { kind: "sdk-error" },
      { kind: "success", nonce: "mock-retry-nonce" }
    ]
  });

  const action = await page.locator("#checkout-form").getAttribute("action");
  const postRequests = [];
  page.on("request", (request) => {
    if (isCheckoutPost(request, action)) postRequests.push(request);
  });
  await page.locator("#checkout-form button[type=\"submit\"]").click();
  await expect(page.locator("[data-braintree-error]")).toContainText("Check the card number");
  await expect(page.locator("[data-braintree-error]")).toHaveAttribute("role", "status");
  await expect(page.locator('[name="payment_method_nonce"]')).toHaveValue("");
  await expect(page.locator("#checkout-form button[type=\"submit\"]")).toBeEnabled();
  await page.locator("#checkout-form button[type=\"submit\"]").click();
  await expect(page.locator("[data-braintree-error]")).toContainText("Secure card tokenization failed");
  await expect(page.locator('[name="payment_method_nonce"]')).toHaveValue("");
  await expect(page.locator("#checkout-form button[type=\"submit\"]")).toBeEnabled();

  await page.locator("#checkout-form [name=\"context_pin\"]").evaluate((input) => {
    input.value = "deliberately-stale-context-pin";
  });
  const requestPromise = page.waitForRequest((request) => isCheckoutPost(request, action));
  const navigationPromise = page.waitForNavigation({ waitUntil: "domcontentloaded" });
  await page.locator("#checkout-form button[type=\"submit\"]").click();
  const request = await requestPromise;
  await navigationPromise;

  expect(new URLSearchParams(request.postData() || "").get("payment_method_nonce")).toBe("mock-retry-nonce");
  expect(postRequests).toHaveLength(1);
  expect(await page.evaluate(() => window.__braintreeMockEvidence.counts.tokenize)).toBe(3);
  await expect(page.locator("body")).toContainText("Billing access unavailable");
});

test("SDK setup failure disables submission and abandonment sends no payment", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await openCheckout(page, fixture, sandboxId, { hostedFieldsError: true });

  const action = await page.locator("#checkout-form").getAttribute("action");
  let checkoutPosts = 0;
  page.on("request", (request) => {
    if (isCheckoutPost(request, action)) checkoutPosts += 1;
  });
  await expect(page.locator("[data-braintree-error]")).toContainText("Secure card fields could not load");
  await expect(page.locator("#checkout-form button[type=\"submit\"]")).toBeDisabled();
  expect(await page.evaluate(() => window.__braintreeMockEvidence.counts.tokenize)).toBe(0);
  await page.getByRole("link", { name: "Leave checkout" }).click();
  await expect.poll(() => checkoutPosts).toBe(0);
});

test("Braintree client initialization failure fails closed", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await openCheckout(page, fixture, sandboxId, { clientError: true });

  await expect(page.locator("[data-braintree-error]")).toContainText("Secure card entry could not start");
  await expect(page.locator("[data-braintree-error]")).toHaveAttribute("aria-live", "polite");
  await expect(page.locator("#checkout-form button[type=\"submit\"]")).toBeDisabled();
  expect(await page.evaluate(() => window.__braintreeMockEvidence.counts.tokenize)).toBe(0);
});

test("double action and interrupted server transport do not replay a nonce", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await openCheckout(page, fixture, sandboxId, {
    delayMs: 150,
    outcomes: [{ kind: "success", nonce: "mock-interrupted-nonce" }]
  });

  const action = await page.locator("#checkout-form").getAttribute("action");
  let checkoutPosts = 0;
  let releaseRoute;
  const held = new Promise((resolve) => { releaseRoute = resolve; });
  await page.route(`**${new URL(action, page.url()).pathname}`, async (route) => {
    checkoutPosts += 1;
    await held;
    await route.abort("failed");
  });

  const requestPromise = page.waitForRequest((request) => isCheckoutPost(request, action));
  await page.locator("#checkout-form button[type=\"submit\"]").click();
  await expect(page.locator("[data-braintree-error]")).toContainText("Securing your card details");
  await expect.poll(() => page.evaluate(() => window.__braintreeMockEvidence.counts.tokenize)).toBe(1);
  await page.locator("#checkout-form").evaluate((form) => {
    form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
  });
  await expect.poll(() => page.evaluate(() => window.__braintreeMockEvidence.counts.tokenize)).toBe(1);
  const request = await requestPromise;
  expect(new URLSearchParams(request.postData() || "").get("payment_method_nonce")).toBe("mock-interrupted-nonce");
  await expect.poll(() => checkoutPosts).toBe(1);
  expect(await page.evaluate(() => window.__braintreeMockEvidence.counts.tokenize)).toBe(1);
  releaseRoute();
  await expect(page.locator("[data-braintree-error]")).toContainText("We couldn't confirm whether your payment went through");
  await expect(page.locator("[data-braintree-error]")).toContainText("billing status or contact support");
  await expect(page.locator('#checkout-form [name="payment_method_nonce"]')).toHaveValue("");
  await expect(page.locator("#checkout-form button[type=\"submit\"]")).toBeDisabled();
  await page.locator("#checkout-form").evaluate((form) => {
    form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
  });
  await page.waitForTimeout(250);
  expect(checkoutPosts).toBe(1);
  expect(await page.evaluate(() => window.__braintreeMockEvidence.counts.tokenize)).toBe(1);
});

test("matching organization context still denies checkout before mounting secure fields", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await installBraintreeMock(page);
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
  await expect.poll(() => page.evaluate(() => window.__braintreeMockEvidence.counts)).toEqual({
    clientCreate: 0,
    hostedFieldsCreate: 0,
    tokenize: 0,
    teardown: 0
  });
});
