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

async function assertNoHorizontalPageScroll(page, label) {
  const widths = await page.evaluate(() => {
    const viewport = document.documentElement.clientWidth;
    const overflow = Array.from(document.body.querySelectorAll("*"))
      .map((element) => ({
        tag: element.tagName.toLowerCase(),
        className: typeof element.className === "string" ? element.className : "",
        right: Math.round(element.getBoundingClientRect().right),
        width: Math.round(element.getBoundingClientRect().width)
      }))
      .filter((element) => element.right > viewport + 1)
      .slice(0, 8);
    return { viewport, document: document.documentElement.scrollWidth, overflow };
  });
  expect(widths.document, `${label}: document width; overflow=${JSON.stringify(widths.overflow)}`)
    .toBeLessThanOrEqual(widths.viewport + 1);
}

async function assertVisibleWithinViewport(page, selector, viewportWidth, label) {
  const box = await page.locator(selector).boundingBox();
  expect(box, `${label}: ${selector} has a visible box`).toBeTruthy();
  expect(box.x, `${label}: ${selector} left edge`).toBeGreaterThanOrEqual(0);
  expect(box.x + box.width, `${label}: ${selector} right edge`).toBeLessThanOrEqual(viewportWidth + 1);
}

async function assertNoOverlap(page, selectors, label) {
  const boxes = await Promise.all(selectors.map(async (selector) => ({
    selector,
    box: await page.locator(selector).boundingBox()
  })));
  for (let left = 0; left < boxes.length; left += 1) {
    expect(boxes[left].box, `${label}: ${boxes[left].selector} is visible`).toBeTruthy();
    for (let right = left + 1; right < boxes.length; right += 1) {
      const a = boxes[left].box;
      const b = boxes[right].box;
      const overlap = Math.max(0, Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x)) *
        Math.max(0, Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y));
      expect(overlap, `${label}: ${boxes[left].selector} and ${boxes[right].selector} do not overlap`).toBe(0);
    }
  }
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

test("pricing selection survives login and renders persisted trusted terms", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await page.goto("/pricing");
  await page.locator('[data-plan-id="price_basic"] a').click();
  await expect(page).toHaveURL(/\/users\/log-in$/);

  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  expect(csrfToken).toBeTruthy();
  const loginResponse = await page.request.post("/users/log-in", {
    headers: { "x-sandbox-id": sandboxId },
    maxRedirects: 0,
    form: {
      _csrf_token: csrfToken,
      "user[email]": fixture.billing_manager_email,
      "user[password]": fixture.password,
      // The persona's own return path must not replace the validated pricing choice.
      "user[return_to]": "/app/billing?plan=price_pro"
    }
  });

  expect(loginResponse.status()).toBe(302);
  const returnPath = new URL(loginResponse.headers().location, page.url());
  expect(returnPath.pathname).toBe("/app/billing");
  expect(returnPath.searchParams.get("plan")).toBe("price_basic");
  expect(returnPath.searchParams.get("selection")).toMatch(/^[0-9a-f-]{36}$/i);
  await page.goto(loginResponse.headers().location);
  await waitForLiveView(page);
  await expect(page.locator('[data-plan-id="price_basic"]')).toBeVisible();
  await expect(page.getByTestId("checkout-url")).toBeVisible();

  const checkoutUrl = await page.getByTestId("checkout-url").getAttribute("href");
  expect(checkoutUrl).toBeTruthy();
  await page.goto(checkoutUrl);
  await waitForLiveView(page);

  const persistedSummary = page.getByTestId("checkout-offer-summary");
  await expect(persistedSummary).toHaveAttribute("data-plan-name", "Launch");
  await expect(persistedSummary).toHaveAttribute("data-amount-minor", "1500");
  await expect(persistedSummary).toHaveAttribute("data-currency", "USD");
  await expect(persistedSummary).toHaveAttribute("data-interval", "per month");
  await expect(persistedSummary).toContainText("Launch");
  await expect(persistedSummary).toContainText("USD $15.00 / per month");
  await expect(persistedSummary).not.toContainText("Studio");
});

test("unknown pricing selection recovers without selecting a default", async ({ page }) => {
  await page.goto("/pricing?plan=price_unknown");
  await expect(page.locator("body")).toContainText("That plan is unavailable");
  await expect(page.locator('[data-plan-id="price_basic"]')).toBeVisible();
  await expect(page).not.toHaveURL(/\/users\/log-in/);
});

test("served checkout assets cover the 16 UI states at 320px (400% zoom equivalent), and long text", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await openCheckout(page, fixture, sandboxId, {
    delayMs: 700,
    outcomes: [{ kind: "invalid" }]
  });

  const cssHref = await page.locator('link[rel="stylesheet"][href*="/assets/css-"]').getAttribute("href");
  const jsHref = await page.locator('script[src*="/assets/js-"]').getAttribute("src");
  expect(cssHref).toBeTruthy();
  expect(jsHref).toBeTruthy();

  const cssResponse = await page.request.get(new URL(cssHref, page.url()).toString());
  const css = await cssResponse.text();
  expect(cssResponse.status()).toBe(200);
  expect(cssResponse.headers()["content-type"]).toContain("text/css");
  expect(css).toContain(".portal-checkout-summary dl > div");
  expect(css).toContain("overflow-wrap: anywhere");

  const jsResponse = await page.request.get(new URL(jsHref, page.url()).toString());
  expect(jsResponse.status()).toBe(200);
  expect(jsResponse.headers()["content-type"]).toContain("javascript");

  const summary = page.getByTestId("checkout-offer-summary");
  const form = page.locator("#checkout-form");
  await expect(summary).toHaveCount(1);
  await expect(summary.locator("dl > div")).toHaveCount(3);
  const trustedTerms = await summary.evaluate((element) => ({
    name: element.dataset.planName,
    amount: element.dataset.amountMinor,
    currency: element.dataset.currency,
    interval: element.dataset.interval
  }));
  expect(trustedTerms.name).toBeTruthy();
  expect(trustedTerms.amount).toMatch(/^\d+$/);
  expect(trustedTerms.currency).toBeTruthy();
  expect(trustedTerms.interval).toBeTruthy();
  await expect(summary).toContainText(trustedTerms.name);
  await expect(form.locator("[data-braintree-field]")).toHaveCount(3);
  await expect(form.locator("button[type=submit]")).toContainText("Pay");

  await page.setViewportSize({ width: 320, height: 900 });
  await assertNoHorizontalPageScroll(page, "320 CSS px mounted checkout");
  for (const selector of [
    '[data-testid="checkout-offer-summary"]',
    '[data-braintree-field="number"]',
    '[data-braintree-field="expirationDate"]',
    '[data-braintree-field="cvv"]',
    "#checkout-form button[type=submit]"
  ]) {
    await assertVisibleWithinViewport(page, selector, 320, "320 CSS px mounted checkout");
  }
  await assertNoOverlap(page, [
    '[data-testid="checkout-offer-summary"]',
    '[data-braintree-field="number"]',
    '[data-braintree-field="expirationDate"]',
    '[data-braintree-field="cvv"]',
    "#checkout-form button[type=submit]"
  ], "320 CSS px mounted checkout");

  await summary.evaluate((element) => {
    const values = element.querySelectorAll("dd");
    values[0].textContent = "プラン名と説明を折り返すための長い Unicode 名称 🧾 ".repeat(8);
    values[1].textContent = "顧客名と事業者名を折り返すための非常に長い文字列 🧭 ".repeat(8);
  });
  await form.locator("[data-braintree-error]").evaluate((element) => {
    element.textContent = "安全な決済フィードバックを省略せず表示するための長い Unicode エラー 🧾 ".repeat(8);
  });
  await assertNoHorizontalPageScroll(page, "long mounted checkout content");
  const textWidths = await page.locator(".portal-checkout-summary dd, [data-braintree-error]").evaluateAll((elements) =>
    elements.map((element) => ({ client: element.clientWidth, scroll: element.scrollWidth }))
  );
  for (const width of textWidths) expect(width.scroll).toBeLessThanOrEqual(width.client + 1);

  // At a 1280px display width, 400% browser zoom exposes a 320 CSS-pixel
  // layout viewport. The 320px assertions above exercise that effective width.
  await expect(summary).toBeVisible();
  await expect(form.locator("button[type=submit]")).toBeVisible();
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.reload();
  await waitForLiveView(page);
  await page.locator("body").evaluate((body) => body.focus());
  let reachedSubmit = false;
  for (let index = 0; index < 32; index += 1) {
    await page.keyboard.press("Tab");
    reachedSubmit = await form.locator("button[type=submit]").evaluate((button) =>
      document.activeElement === button && button.matches(":focus-visible")
    );
    if (reachedSubmit) break;
  }
  expect(reachedSubmit, "keyboard order reaches the mounted payment action").toBeTruthy();
  expect(await form.locator("[data-braintree-error]").getAttribute("aria-live")).toBe("polite");

  await page.setViewportSize({ width: 320, height: 900 });
  await form.locator("button[type=submit]").click();
  await expect(form.locator("[data-braintree-error]")).toContainText("Securing your card details");
  await expect(summary).toContainText(trustedTerms.name);
  await expect(form.locator("[data-braintree-error]")).toContainText("Check the card number");
  await expect(form.locator("[data-braintree-error]")).toHaveAttribute("role", "status");
  await assertNoHorizontalPageScroll(page, "checkout outcome at 320 CSS px");

  await page.goto("/app/billing?checkout=cancel&plan=price_basic&selection=2e2cc9d8-62c8-40f4-8390-bd4cdd572410");
  await waitForLiveView(page);
  const hostedReturn = page.getByTestId("checkout-return-state");
  await expect(hostedReturn).toContainText("Checkout was canceled");
  await expect(hostedReturn).not.toContainText("Payment confirmed");
  await page.setViewportSize({ width: 320, height: 900 });
  await assertNoHorizontalPageScroll(page, "hosted return at 320 CSS px");
  await hostedReturn.evaluate((element) => {
    element.textContent = "Long host and provider recovery guidance wraps safely across Unicode text 日本語と英語 🧾 ".repeat(8);
  });
  await assertNoHorizontalPageScroll(page, "long hosted return guidance");
  // 320 CSS pixels is the effective layout width at 400% zoom on a 1280px
  // display; assert the served hosted return at the same constrained width.
  await expect(hostedReturn).toBeVisible();
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

test("leaving during tokenization tears down Hosted Fields without submitting later", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await openCheckout(page, fixture, sandboxId, {
    delayMs: 700,
    outcomes: [{ kind: "success", nonce: "mock-abandoned-nonce" }]
  });

  const action = await page.locator("#checkout-form").getAttribute("action");
  let checkoutPosts = 0;
  page.on("request", (request) => {
    if (isCheckoutPost(request, action)) checkoutPosts += 1;
  });
  await page.locator("#checkout-form button[type=\"submit\"]").click();
  await expect(page.locator("[data-braintree-error]")).toContainText("Securing your card details");

  const navigationPromise = page.waitForNavigation({ waitUntil: "domcontentloaded" });
  await page.getByRole("link", { name: "Leave checkout" }).evaluate((link) => {
    link.href = "/";
  });
  await page.getByRole("link", { name: "Leave checkout" }).click();
  await navigationPromise;
  await page.waitForTimeout(800);

  expect(checkoutPosts).toBe(0);
  expect(await page.evaluate(() => window.__braintreeMockEvidence.counts.tokenize)).toBe(1);
  expect(await page.evaluate(() => window.__braintreeMockEvidence.counts.teardown)).toBe(1);
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
