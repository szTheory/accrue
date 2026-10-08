// @ts-check
const { test, expect } = require("./support/test.js");
const AxeBuilder = require("@axe-core/playwright").default;
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

test.skip(
  process.env.ACCRUE_HOST_BROWSER_USE_BRAINTREE !== "1",
  "Phase 236 Portal browser contract uses the seeded Braintree owner in the blocking Braintree lane"
);

async function recordCoverage(testInfo, categories) {
  await testInfo.attach("phase236-ui-considerations.json", {
    body: Buffer.from(JSON.stringify({ categories, evidence: "served Chromium assertions" }, null, 2)),
    contentType: "application/json"
  });
}

/** @param {import('@playwright/test').Page} page */
async function installHostedFieldsMock(page, options = {}) {
  await page.addInitScript((mockOptions) => {
    const storageKey = "__phase236HostedFieldsCounts";
    let counts;
    try {
      counts = JSON.parse(sessionStorage.getItem(storageKey) || "null");
    } catch (_error) {
      counts = null;
    }
    counts = counts || { clientCreate: 0, clientTeardown: 0, hostedFieldsCreate: 0, tokenize: 0, teardown: 0 };
    counts.clientTeardown = counts.clientTeardown || 0;
    const saveCounts = () => sessionStorage.setItem(storageKey, JSON.stringify(counts));
    const pendingClientCallbacks = [];
    const pendingHostedFieldsCallbacks = [];
    const outcomes = mockOptions.outcomes || [{ kind: "invalid" }];
    const sdk = {
      client: {
        create(_options, callback) {
          counts.clientCreate += 1;
          saveCounts();
          const complete = () => callback(null, {
            teardown(done) {
              counts.clientTeardown += 1;
              saveCounts();
              if (done) done(mockOptions.failFirstClientTeardown && counts.clientTeardown === 1
                ? new Error("mock client teardown failed")
                : null);
            }
          });
          if (mockOptions.holdFirstClientCreate && counts.clientCreate === 1) {
            pendingClientCallbacks.push(complete);
          } else {
            window.setTimeout(complete, mockOptions.setupDelayMs || 0);
          }
        }
      },
      hostedFields: {
        create(_options, callback) {
          counts.hostedFieldsCreate += 1;
          window.__phase236HostedFieldsEvidence.styles = _options.styles;
          saveCounts();
          const instance = {
            tokenize(done) {
              counts.tokenize += 1;
              saveCounts();
              const outcome = outcomes.shift() || { kind: "invalid" };
              window.setTimeout(() => {
                if (outcome.kind === "invalid") {
                  done({
                    code: "HOSTED_FIELDS_FIELDS_INVALID",
                    details: { invalidFieldKeys: ["number"] }
                  });
                  return;
                }
                done(null, { nonce: outcome.nonce || "phase236-one-time-nonce" });
              }, mockOptions.tokenizeDelayMs || 0);
            },
            teardown(done) {
              counts.teardown += 1;
              saveCounts();
              if (done) done(mockOptions.failFirstHostedFieldsTeardown && counts.teardown === 1
                ? new Error("mock Hosted Fields teardown failed")
                : null);
            }
          };
          const complete = () => callback(null, instance);
          if (mockOptions.holdFirstHostedFieldsCreate && counts.hostedFieldsCreate === 1) {
            pendingHostedFieldsCallbacks.push(complete);
          } else {
            window.setTimeout(complete, mockOptions.setupDelayMs || 0);
          }
        }
      }
    };

    Object.defineProperty(window, "__phase236HostedFieldsEvidence", {
      configurable: false,
      value: {
        counts,
        kind: "deterministic injected Hosted Fields SDK; not live provider proof"
        ,styles: null
      }
    });
    Object.defineProperty(window, "__phase236HostedFieldsControl", {
      configurable: false,
      value: {
        pendingClientCallbacks: () => pendingClientCallbacks.length,
        releaseClientCreate() {
          const callback = pendingClientCallbacks.shift();
          if (!callback) return false;
          callback();
          return true;
        },
        releaseHostedFieldsCreate() {
          const callback = pendingHostedFieldsCallbacks.shift();
          if (!callback) return false;
          callback();
          return true;
        },
        triggerPostMountUpdate() {
          const form = document.querySelector('[data-portal-hosted-fields="payment-method"]');
          const sockets = [window.liveSocket, window.accruePortalLiveSocket];
          for (const socket of sockets) {
            const views = Object.values((socket && socket.roots) || {});
            for (const view of views) {
              const hook = view.getHook && view.getHook(form);
              if (hook && hook.el === form && typeof hook.__updated === "function") {
                hook.__updated();
                return true;
              }
            }
          }
          return false;
        }
      }
    });
    Object.defineProperty(window, "braintree", {
      configurable: false,
      get() { return sdk; },
      set() {}
    });
    if (mockOptions.malformedTokens) {
      const setMalformedTokens = () => {
        document.documentElement.style.setProperty("--accrue-ink", "not-a-color");
        document.documentElement.style.setProperty("--accrue-slate", "still-not-a-color");
      };
      if (document.documentElement) setMalformedTokens();
      else document.addEventListener("DOMContentLoaded", setMalformedTokens, { once: true });
    }
  }, options);
}

test("Hosted Fields hand off readable semantic styles on direct add-card navigation", async ({ page, sandboxId }) => {
  await installHostedFieldsMock(page);
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.emulateMedia({ colorScheme: "dark" });
  const response = await page.goto("/billing/payment-methods/new");
  expect(response && response.status()).toBe(200);
  await waitForLiveView(page);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.styles)).not.toBeNull();
  const evidence = await page.evaluate(() => {
    const form = document.querySelector('[data-portal-hosted-fields="payment-method"]');
    const fields = Array.from(form.querySelectorAll("[data-braintree-field]")).map((field) => ({
      name: field.dataset.braintreeField,
      background: getComputedStyle(field).backgroundColor,
      label: getComputedStyle(field.closest("label")).color,
      help: getComputedStyle(document.querySelector(".portal-help")).color
    }));
    return { fields, styles: window.__phase236HostedFieldsEvidence.styles, label: window.__phase236HostedFieldsEvidence.kind };
  });
  expect(evidence.label).toContain("not live provider proof");
  expect(evidence.fields).toHaveLength(3);
  for (const field of evidence.fields) {
    expect(contrastRatio(evidence.styles[`.${field.name}`].color, field.background)).toBeGreaterThanOrEqual(4.5);
    expect(contrastRatio(evidence.styles["::placeholder"].color, field.background)).toBeGreaterThanOrEqual(4.5);
    expect(contrastRatio(evidence.styles[".invalid"].color, field.background)).toBeGreaterThanOrEqual(4.5);
    expect(contrastRatio(field.label, field.background)).toBeGreaterThanOrEqual(4.5);
    expect(contrastRatio(field.help, field.background)).toBeGreaterThanOrEqual(4.5);
  }
});

test("Hosted Fields keep malformed-token fallback styles readable on every field", async ({ page, sandboxId }) => {
  await installHostedFieldsMock(page, { malformedTokens: true });
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  const response = await page.goto("/billing/payment-methods/new");
  expect(response && response.status()).toBe(200);
  await waitForLiveView(page);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.styles)).not.toBeNull();

  const evidence = await page.evaluate(() => {
    const form = document.querySelector('[data-portal-hosted-fields="payment-method"]');
    return {
      styles: window.__phase236HostedFieldsEvidence.styles,
      fields: Array.from(form.querySelectorAll("[data-braintree-field]")).map((field) => ({
        name: field.dataset.braintreeField,
        background: getComputedStyle(field).backgroundColor
      }))
    };
  });

  expect(evidence.fields).toHaveLength(3);
  for (const field of evidence.fields) {
    expect(contrastRatio(evidence.styles[`.${field.name}`].color, field.background)).toBeGreaterThanOrEqual(4.5);
    expect(contrastRatio(evidence.styles["::placeholder"].color, field.background)).toBeGreaterThanOrEqual(4.5);
    expect(contrastRatio(evidence.styles[".invalid"].color, field.background)).toBeGreaterThanOrEqual(4.5);
  }
});

test("Hosted Fields retry after a post-mount LiveView update invalidates client creation", async ({ page, sandboxId }) => {
  await installHostedFieldsMock(page, { holdFirstClientCreate: true });
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  const response = await page.goto("/billing/payment-methods/new");
  expect(response && response.status()).toBe(200);
  await waitForLiveView(page);

  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.clientCreate)).toBe(1);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsControl.pendingClientCallbacks())).toBe(1);
  await expect.poll(() => new URL(page.url()).searchParams.get("context_pin")).toBeTruthy();

  const form = page.locator('[data-portal-hosted-fields="payment-method"]');
  const submit = form.locator("[data-checkout-submit]");
  await expect(submit).toBeDisabled();
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
  expect(await page.evaluate(() => window.__phase236HostedFieldsControl.triggerPostMountUpdate())).toBe(true);
  await page.evaluate(() => window.__phase236HostedFieldsControl.releaseClientCreate());

  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.clientCreate)).toBe(2);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.hostedFieldsCreate)).toBe(1);
  await expect(submit).toBeEnabled();
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
  const counts = await page.evaluate(() => window.__phase236HostedFieldsEvidence.counts);
  expect(counts.clientCreate).toBe(2);
  expect(counts.hostedFieldsCreate).toBe(1);
  expect(counts.clientTeardown).toBe(1);
  expect(counts.teardown).toBe(0);
});

test("Hosted Fields tear down stale fields and retry after a post-mount LiveView update", async ({ page, sandboxId }) => {
  await installHostedFieldsMock(page, { holdFirstHostedFieldsCreate: true });
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.goto("/billing/payment-methods/new");
  await waitForLiveView(page);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.hostedFieldsCreate)).toBe(1);

  const form = page.locator('[data-portal-hosted-fields="payment-method"]');
  const submit = form.locator("[data-checkout-submit]");
  await expect(submit).toBeDisabled();
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
  expect(await page.evaluate(() => window.__phase236HostedFieldsControl.triggerPostMountUpdate())).toBe(true);
  await page.evaluate(() => window.__phase236HostedFieldsControl.releaseHostedFieldsCreate());

  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.clientCreate)).toBe(2);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.hostedFieldsCreate)).toBe(2);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.teardown)).toBe(1);
  await expect(submit).toBeEnabled();
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
  const counts = await page.evaluate(() => window.__phase236HostedFieldsEvidence.counts);
  expect(counts.clientTeardown).toBe(1);
  expect(counts.hostedFieldsCreate).toBe(2);
  expect(counts.teardown).toBe(1);
});

test("Hosted Fields stay disabled when stale-resource teardown fails", async ({ page, sandboxId }) => {
  await installHostedFieldsMock(page, {
    holdFirstHostedFieldsCreate: true,
    failFirstHostedFieldsTeardown: true
  });
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.goto("/billing/payment-methods/new");
  await waitForLiveView(page);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.hostedFieldsCreate)).toBe(1);

  const form = page.locator('[data-portal-hosted-fields="payment-method"]');
  const submit = form.locator("[data-checkout-submit]");
  expect(await page.evaluate(() => window.__phase236HostedFieldsControl.triggerPostMountUpdate())).toBe(true);
  await page.evaluate(() => window.__phase236HostedFieldsControl.releaseHostedFieldsCreate());

  await expect(form.locator("[data-braintree-error]")).toHaveText(
    "Secure card fields could not be safely reset. Refresh this page to try again."
  );
  await expect(submit).toBeDisabled();
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
  const counts = await page.evaluate(() => window.__phase236HostedFieldsEvidence.counts);
  expect(counts.clientCreate).toBe(1);
  expect(counts.hostedFieldsCreate).toBe(1);
  expect(counts.teardown).toBe(1);
  expect(counts.clientTeardown).toBe(1);
});

if (!process.env.ACCRUE_HOST_PORTAL_THEME) test("Hosted Fields do not recreate after theme-refresh teardown fails", async ({ page, sandboxId }) => {
  await installHostedFieldsMock(page, { failFirstHostedFieldsTeardown: true });
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.goto("/billing/payment-methods/new");
  await waitForLiveView(page);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.hostedFieldsCreate)).toBe(1);

  const form = page.locator('[data-portal-hosted-fields="payment-method"]');
  const submit = form.locator("[data-checkout-submit]");
  await expect(submit).toBeEnabled();
  const currentTheme = await page.locator("html").getAttribute("data-theme");
  const nextTheme = currentTheme === "dark" ? "light" : "dark";
  await page.getByRole("button", { name: nextTheme === "dark" ? "Dark theme" : "Light theme" }).click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", nextTheme);

  await expect(form.locator("[data-braintree-error]")).toHaveText(
    "Secure card fields could not be safely reset. Refresh this page to try again."
  );
  await expect(submit).toBeDisabled();
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
  const counts = await page.evaluate(() => window.__phase236HostedFieldsEvidence.counts);
  expect(counts.hostedFieldsCreate).toBe(1);
  expect(counts.teardown).toBe(1);
});

test("Hosted Fields do not revive after pagehide during client creation", async ({ page, sandboxId }) => {
  await installHostedFieldsMock(page, { holdFirstClientCreate: true });
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.goto("/billing/payment-methods/new");
  await waitForLiveView(page);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsControl.pendingClientCallbacks())).toBe(1);

  const form = page.locator('[data-portal-hosted-fields="payment-method"]');
  await expect(form.locator("[data-checkout-submit]")).toBeDisabled();
  await page.evaluate(() => window.dispatchEvent(new Event("pagehide")));
  await page.evaluate(() => window.__phase236HostedFieldsControl.releaseClientCreate());
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.clientTeardown)).toBe(1);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.hostedFieldsCreate)).toBe(0);
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
  await expect(form.locator("[data-checkout-submit]")).toBeDisabled();
});

if (!process.env.ACCRUE_HOST_PORTAL_THEME) test("Hosted Fields refresh after the direct-route context pin and theme changes", async ({ page, sandboxId }) => {
  await installHostedFieldsMock(page);
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.goto("/billing/payment-methods/new");
  await waitForLiveView(page);
  await expect.poll(() => new URL(page.url()).searchParams.get("context_pin")).toBeTruthy();
  const form = page.locator('[data-portal-hosted-fields="payment-method"]');
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.hostedFieldsCreate)).toBe(1);
  await page.getByRole("button", { name: "Dark theme" }).click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.hostedFieldsCreate)).toBe(2);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.teardown)).toBe(1);
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
});

if (process.env.ACCRUE_HOST_PORTAL_THEME) test("host-forced theme locks the picker on the served add-card route", async ({ page, sandboxId }) => {
  await installHostedFieldsMock(page);
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  const response = await page.goto("/billing/payment-methods/new");
  expect(response && response.status()).toBe(200);
  await waitForLiveView(page);
  await expect(page.locator("html")).toHaveAttribute("data-theme", process.env.ACCRUE_HOST_PORTAL_THEME);
  await expect(page.locator("[data-portal-theme]")).toHaveCount(0);
  await expect.poll(() => page.evaluate(() => window.__phase236HostedFieldsEvidence.styles)).not.toBeNull();
});

/** @param {import('@playwright/test').Page} page */
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

  expect(
    widths.document,
    `${label}: document width; overflow=${JSON.stringify(widths.overflow)}`
  ).toBeLessThanOrEqual(widths.viewport + 1);
}

function contrastRatio(foreground, background) {
  const rgb = (value) => {
    const match = value.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/i);
    const srgbMatch = value.match(/color\(srgb\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i);
    const hexMatch = value.match(/^#([\da-f]{3}|[\da-f]{6})$/i);
    if (!match && !srgbMatch && !hexMatch) throw new Error(`Unsupported computed color: ${value}`);
    const channels = match
      ? [Number(match[1]) / 255, Number(match[2]) / 255, Number(match[3]) / 255]
      : srgbMatch
        ? [Number(srgbMatch[1]), Number(srgbMatch[2]), Number(srgbMatch[3])]
        : hexMatch[1].length === 3
          ? hexMatch[1].split("").map((channel) => parseInt(channel + channel, 16) / 255)
          : [0, 2, 4].map((index) => parseInt(hexMatch[1].slice(index, index + 2), 16) / 255);
    return channels.map((normalized) => {
      return normalized <= 0.04045
        ? normalized / 12.92
        : ((normalized + 0.055) / 1.055) ** 2.4;
    });
  };
  const luminance = (value) => {
    const [red, green, blue] = rgb(value);
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
  };
  const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
  return (values[0] + 0.05) / (values[1] + 0.05);
}

test("seven served Portal routes keep their billed identity, facts, and actions in view", async ({
  page,
  sandboxId
}, testInfo) => {
  await recordCoverage(testInfo, ["populated", "partial", "overflow", "zero-one-many"]);
  await installHostedFieldsMock(page);
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.setViewportSize({ width: 320, height: 844 });

  const routes = [
    { path: "/billing", heading: "Account overview" },
    { path: "/billing/subscriptions", heading: "Subscriptions" },
    {
      path: `/billing/subscriptions/${encodeURIComponent(fixture.portal_subscription_id)}`,
      heading: "Subscription details"
    },
    { path: "/billing/payment-methods", heading: "Payment methods" },
    { path: "/billing/payment-methods/new", heading: "Add payment method" },
    { path: "/billing/invoices", heading: "Invoices" },
    { path: fixture.portal_checkout_url, heading: "Checkout" }
  ];

  for (const route of routes) {
    const response = await page.goto(route.path, { waitUntil: "domcontentloaded" });
    expect(response && response.status(), `${route.path} response`).toBe(200);
    await waitForLiveView(page);
    await expect(page.locator("main.portal-shell h1").first()).toContainText(route.heading);
    await expect(page.locator(".portal-wordmark")).toHaveText("Cadence");
    await expect(page.locator(".portal-billable-name")).toHaveText(fixture.normal_email);
    await assertNoHorizontalPageScroll(page, route.path);
  }

  await expect(page.locator('[data-portal-hosted-fields="checkout"]')).toBeVisible();
  await page.goto("/billing/invoices");
  await waitForLiveView(page);
  await expect(page.getByRole("link", { name: "Open invoice" })).toHaveAttribute(
    "href",
    fixture.portal_invoice_url
  );

  await page.goto(`/billing/subscriptions/${encodeURIComponent(fixture.portal_partial_subscription_id)}`);
  await waitForLiveView(page);
  await expect(page.getByText("Current period ends")).toBeVisible();
  await expect(page.getByText("Not available", { exact: true })).toBeVisible();
});

test("personal and workspace views show empty collections and only their own hosted invoices", async ({
  page,
  sandboxId
}, testInfo) => {
  await recordCoverage(testInfo, ["empty", "populated", "zero-one-many"]);
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);

  await page.goto("/billing/invoices");
  await waitForLiveView(page);
  await expect(page.getByRole("link", { name: "Open invoice" })).toHaveAttribute(
    "href",
    fixture.portal_invoice_url
  );
  await expect(page.locator("body")).not.toContainText(fixture.org_portal_invoice_url);

  const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute("content");
  const selected = await page.request.post("/app/organization-scope", {
    headers: { "x-sandbox-id": sandboxId },
    form: { _csrf_token: csrfToken, organization_slug: fixture.org_alpha_slug }
  });
  expect(selected.ok()).toBeTruthy();

  await page.goto("/shared-billing/subscriptions");
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-name")).toHaveText(fixture.org_alpha_name);
  await expect(page.getByText("No active subscriptions", { exact: true })).toBeVisible();
  await expect(page.locator(".portal-list")).toHaveCount(0);
  const workspaceContextPin = new URL(page.url()).searchParams.get("context_pin");
  expect(workspaceContextPin).toBeTruthy();

  await page.goto(`/shared-billing/payment-methods?context_pin=${encodeURIComponent(workspaceContextPin)}`);
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-name")).toHaveText(fixture.org_alpha_name);
  await expect(page.getByText("No payment methods on file", { exact: true })).toBeVisible();

  await page.goto(`/shared-billing/invoices?context_pin=${encodeURIComponent(workspaceContextPin)}`);
  await waitForLiveView(page);
  await expect(page.locator(".portal-billable-name")).toHaveText(fixture.org_alpha_name);
  await expect(page.getByRole("link", { name: "Open invoice" })).toHaveAttribute(
    "href",
    fixture.org_portal_invoice_url
  );
  await expect(page.locator("body")).not.toContainText(fixture.portal_invoice_url);
});

test("themes, bright host accents, keyboard focus, reduced motion, and long text stay readable", async ({
  page,
  sandboxId
}, testInfo) => {
  await recordCoverage(testInfo, ["theme", "contrast", "focus", "reduced-motion", "overflow", "long-text"]);
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 320, height: 844 });
  await page.goto("/billing");
  await waitForLiveView(page);

  const systemTheme = page.getByRole("button", { name: "Match system theme" });
  const lightTheme = page.getByRole("button", { name: "Light theme" });
  const darkTheme = page.getByRole("button", { name: "Dark theme" });
  await expect(systemTheme).toHaveAttribute("aria-pressed", "true");
  const systemDarkSurface = await page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue("--accrue-surface-muted").trim()
  );

  await lightTheme.click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
  await expect(lightTheme).toHaveAttribute("aria-pressed", "true");
  const lightSurface = await page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue("--accrue-surface-muted").trim()
  );
  expect(lightSurface).not.toBe(systemDarkSurface);

  await darkTheme.click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await expect(darkTheme).toHaveAttribute("aria-pressed", "true");
  await systemTheme.click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "system");
  const systemSurface = await page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue("--accrue-surface-muted").trim()
  );
  expect(systemSurface).toBe(systemDarkSurface);

  await page.evaluate(() => {
    document.documentElement.style.setProperty("--accrue-brand-accent", "#f7ff00");
    document.documentElement.style.setProperty("--accrue-brand-secondary", "#ffff00");
    const identity = document.querySelector(".portal-billable-name");
    if (identity) identity.textContent = `LongWorkspaceName${"x".repeat(160)}`;
  });
  await expect(page.locator(".portal-billable-name")).toContainText("LongWorkspaceName");
  await assertNoHorizontalPageScroll(page, "home with long billed identity");

  const contrast = await page.evaluate(() => {
    const primary = document.querySelector(".portal-hero a.portal-button-primary");
    const contentLink = document.querySelector(".portal-list li > a");
    if (!primary || !contentLink) throw new Error("Expected primary and content links on home");
    return {
      primaryForeground: getComputedStyle(primary).color,
      primaryBackground: getComputedStyle(primary).backgroundColor,
      linkForeground: getComputedStyle(contentLink).color,
      surface: getComputedStyle(document.documentElement).getPropertyValue("--accrue-surface").trim()
    };
  });
  expect(contrastRatio(contrast.primaryForeground, contrast.primaryBackground)).toBeGreaterThanOrEqual(4.5);
  expect(contrastRatio(contrast.linkForeground, "rgb(16, 20, 26)")).toBeGreaterThanOrEqual(4.5);

  await page.keyboard.press("Tab");
  await page.keyboard.press("Tab");
  await expect(darkTheme).toBeFocused();
  const themeTargetSize = await darkTheme.boundingBox();
  expect(themeTargetSize && themeTargetSize.width).toBeGreaterThanOrEqual(40);
  expect(themeTargetSize && themeTargetSize.height).toBeGreaterThanOrEqual(40);
  const focusOutline = await darkTheme.evaluate((element) => getComputedStyle(element).outlineStyle);
  expect(focusOutline).toBe("solid");

  const transitionDurations = await page.locator(".portal-hero a.portal-button-primary")
    .evaluate((element) => getComputedStyle(element).transitionDuration.split(",").map((value) => value.trim()));
  expect(transitionDurations.every((duration) => Number.parseFloat(duration) === 0)).toBeTruthy();

  await page.emulateMedia({ forcedColors: "active" });
  await expect(page.locator(".portal-hero a.portal-button-primary")).toBeVisible();
  const forcedFocusStyle = await darkTheme.evaluate((element) => getComputedStyle(element).outlineStyle);
  expect(forcedFocusStyle).toBe("solid");
});

test("Hosted Fields show pending and validation states, clear failed nonce data, and teardown on exit", async ({
  page,
  sandboxId
}, testInfo) => {
  await recordCoverage(testInfo, ["loading", "error", "partial"]);
  await installHostedFieldsMock(page, { tokenizeDelayMs: 500, outcomes: [{ kind: "invalid" }] });
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.setViewportSize({ width: 320, height: 844 });

  const response = await page.goto("/billing/payment-methods/new");
  expect(response && response.status()).toBe(200);
  await waitForLiveView(page);
  const form = page.locator('[data-portal-hosted-fields="payment-method"]');
  await expect(form).toBeVisible();
  await expect(page.locator('link[rel="stylesheet"][href*="/billing/assets/css-"]')).toHaveCount(1);
  await expect(page.locator('script[src*="/billing/assets/js-"]')).toHaveCount(1);
  await expect(page.getByText("Card number", { exact: true })).toBeVisible();
  await expect(page.getByText("Expiration", { exact: true })).toBeVisible();
  await expect(page.getByText("CVV", { exact: true })).toBeVisible();
  await expect.poll(() => form.getAttribute("data-hosted-fields-bound")).toBe("1");
  await expect(page.getByRole("button", { name: "Save card" })).toBeEnabled();

  await form.locator('input[name="context_pin"]').evaluate((input) => {
    input.value = "deliberately-stale-context-pin";
  });
  let paymentMethodPosts = 0;
  page.on("request", (request) => {
    if (request.method() === "POST" && new URL(request.url()).pathname === "/billing/payment-methods") {
      paymentMethodPosts += 1;
    }
  });

  await page.getByRole("button", { name: "Save card" }).click();
  await expect(page.getByText("Securing your card details...")).toBeVisible();
  await expect(page.getByRole("button", { name: "Save card" })).toBeDisabled();
  await expect(page.getByText("Check the card number, expiration, and security code, then try again.")).toBeVisible();
  await expect(page.getByRole("button", { name: "Save card" })).toBeEnabled();
  await expect(form.locator("[data-braintree-nonce-input]")).toHaveValue("");
  expect(paymentMethodPosts).toBe(0);
  expect(await page.evaluate(() => window.__phase236HostedFieldsEvidence.kind)).toContain(
    "not live provider proof"
  );
  expect(await page.evaluate(() => window.__phase236HostedFieldsEvidence.counts.tokenize)).toBe(1);

  await page.goto("/billing");
  await waitForLiveView(page);
  await expect.poll(() => page.evaluate(() => {
    const counts = JSON.parse(sessionStorage.getItem("__phase236HostedFieldsCounts") || "{}");
    return counts.teardown;
  })).toBe(1);
});

test("Escape closes subscription confirmation and restores focus without sending a provider mutation", async ({
  page,
  sandboxId
}, testInfo) => {
  await recordCoverage(testInfo, ["keyboard", "focus", "error"]);
  const fixture = readFixture();
  await login(page, fixture, fixture.normal_email, sandboxId);
  const path = `/billing/subscriptions/${encodeURIComponent(fixture.portal_subscription_id)}`;
  await page.goto(path);
  await waitForLiveView(page);

  const trigger = page.getByRole("button", { name: "Cancel now" });
  await trigger.focus();
  const triggerId = await trigger.getAttribute("id");
  expect(triggerId).toBeTruthy();
  await trigger.click();

  const confirm = page.getByRole("button", { name: "Cancel now" });
  const keep = page.getByRole("button", { name: "Keep subscription" });
  await expect(confirm).toBeVisible();
  await expect.poll(() => page.evaluate(() => document.activeElement && document.activeElement.id))
    .toBe(`cancel-confirm-${fixture.portal_subscription_id}`);

  await page.keyboard.press("Tab");
  await expect(keep).toBeFocused();
  await page.keyboard.press("Shift+Tab");
  await expect(confirm).toBeFocused();
  await page.keyboard.press("Escape");

  await expect(keep).toHaveCount(0);
  await expect(page.locator(`#${triggerId}`)).toBeFocused();
  await expect(page.getByRole("group", { name: "Cancel subscription confirmation" })).toHaveCount(0);
});
