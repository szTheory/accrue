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
    counts = counts || { clientCreate: 0, hostedFieldsCreate: 0, tokenize: 0, teardown: 0 };
    const saveCounts = () => sessionStorage.setItem(storageKey, JSON.stringify(counts));
    const outcomes = mockOptions.outcomes || [{ kind: "invalid" }];
    const sdk = {
      client: {
        create(_options, callback) {
          counts.clientCreate += 1;
          saveCounts();
          window.setTimeout(() => callback(null, {}), mockOptions.setupDelayMs || 0);
        }
      },
      hostedFields: {
        create(_options, callback) {
          counts.hostedFieldsCreate += 1;
          saveCounts();
          window.setTimeout(() => {
            callback(null, {
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
                if (done) done();
              }
            });
          }, mockOptions.setupDelayMs || 0);
        }
      }
    };

    Object.defineProperty(window, "__phase236HostedFieldsEvidence", {
      configurable: false,
      value: {
        counts,
        kind: "deterministic injected Hosted Fields SDK; not live provider proof"
      }
    });
    Object.defineProperty(window, "braintree", {
      configurable: false,
      get() { return sdk; },
      set() {}
    });
  }, options);
}

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
    if (!match && !srgbMatch) throw new Error(`Unsupported computed color: ${value}`);
    const channels = match
      ? [Number(match[1]) / 255, Number(match[2]) / 255, Number(match[3]) / 255]
      : [Number(srgbMatch[1]), Number(srgbMatch[2]), Number(srgbMatch[3])];
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
