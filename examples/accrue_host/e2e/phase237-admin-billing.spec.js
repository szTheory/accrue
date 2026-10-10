// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { devices } = require("@playwright/test");
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const captureDir = process.env.PHASE237_CAPTURE_DIR || path.join(repoRoot, ".planning/phases/240-shared-system-and-real-billing-exemplar/captures/phase237-exemplar");
const sourcePaths = [
  "accrue_admin/assets/css/app.css",
  "accrue_admin/assets/css/theme.css",
  "accrue_admin/assets/js/app.js",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/accrue_admin.js",
  "accrue_admin/priv/static/fonts/geist-sans-vf.woff2",
  "accrue_admin/priv/static/fonts/geist-mono-vf.woff2",
  "accrue_admin/lib/accrue_admin/live/invoices_live.ex",
  "accrue_admin/lib/accrue_admin/live/invoice_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "accrue_admin/lib/accrue_admin/live/charge_live.ex",
  "accrue_admin/lib/accrue_admin/live/customer_live.ex",
  "accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex",
  "accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex",
  "accrue_admin/lib/accrue_admin/scoped_path.ex",
  "accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs",
  "accrue_admin/test/accrue_admin/live/subscription_live_test.exs",
  "accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs",
  "accrue_admin/lib/accrue_admin/components/at_risk_table.ex",
  "scripts/ci/accrue_host_seed_e2e.exs",
  "examples/accrue_host/e2e/phase237-admin-billing.spec.js"
];

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function contrastRatio(foreground, background) {
  const luminance = (value) => {
    const rgb = value.match(/[\d.]+/g).slice(0, 3).map(Number);
    const linear = rgb.map((channel) => {
      const srgb = channel / 255;
      return srgb <= 0.04045 ? srgb / 12.92 : ((srgb + 0.055) / 1.055) ** 2.4;
    });
    return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722;
  };
  const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
  return (values[0] + 0.05) / (values[1] + 0.05);
}

async function assertNoOverflow(page) {
  const widths = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    document: document.documentElement.scrollWidth
  }));
  expect(widths.document, `document overflow at ${widths.viewport}px`).toBeLessThanOrEqual(widths.viewport);
}

async function assertThemeAndMotion(page, theme) {
  await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
  await page.locator("html").evaluate((element, value) => element.setAttribute("data-theme", value), theme);
  const tokens = await page.locator("html.accrue-admin").evaluate((element) => {
    const style = getComputedStyle(element);
    const background = style.backgroundColor;
    const color = getComputedStyle(element.querySelector(".ax-heading")).color;
    const duration = getComputedStyle(element).getPropertyValue("--ax-motion-standard").trim();
    return { background, color, duration };
  });
  expect(tokens.background).not.toBe("rgba(0, 0, 0, 0)");
  expect(contrastRatio(tokens.color, tokens.background)).toBeGreaterThanOrEqual(4.5);
  expect(tokens.duration).toMatch(/^0ms/);
  const focus = page.getByRole("link").first();
  await focus.focus();
  const focusStyle = await focus.evaluate((element) => {
    const style = getComputedStyle(element);
    return { style: style.outlineStyle, width: style.outlineWidth };
  });
  expect(focusStyle.style).not.toBe("none");
  expect(focusStyle.width).not.toBe("0px");
  await focus.evaluate((element) => element.blur());
  await expect(focus).not.toBeFocused();
  return tokens;
}

async function assertAssetBytes(page, href, packagePath) {
  const packageBytes = fs.readFileSync(path.join(repoRoot, packagePath));
  const compiledPath = path.join(repoRoot, "examples/accrue_host/_build/test/lib/accrue_admin/priv", packagePath.replace("accrue_admin/priv/", ""));
  const compiledBytes = fs.readFileSync(compiledPath);
  const response = await page.evaluate(async (assetHref) => {
    const result = await fetch(assetHref, { cache: "no-store" });
    const bytes = Array.from(new Uint8Array(await result.arrayBuffer()));
    const resourcePath = new URL(assetHref, location.href).pathname;
    const loaded = performance.getEntriesByType("resource").some((entry) => new URL(entry.name).pathname === resourcePath);
    return { status: result.status, bytes, loaded };
  }, href);
  expect(response.status, `served asset status for ${href}`).toBe(200);
  const servedBytes = Buffer.from(response.bytes);
  expect(sha256(packageBytes), `package build and compiled host differ for ${href}`).toBe(sha256(compiledBytes));
  expect(sha256(servedBytes), `served response differs from package build for ${href}`).toBe(sha256(packageBytes));
  expect(response.loaded, `browser did not request ${href}`).toBeTruthy();
  expect(sha256(servedBytes), `browser-served bytes differ from package build for ${href}`).toBe(sha256(packageBytes));
  return { path: new URL(href, page.url()).pathname, bytes: servedBytes.length, packageSha256: sha256(packageBytes), compiledSha256: sha256(compiledBytes), servedSha256: sha256(servedBytes), browserRequestSha256: sha256(servedBytes) };
}

async function assertCurrentAssets(page) {
  const cssHref = await page.locator('link[rel="stylesheet"][href*="/admin/assets/css-"]').getAttribute("href");
  expect(cssHref).toMatch(/\/admin\/assets\/css-[a-f0-9]{32}$/);
  const jsHref = await page.locator('script[src*="/admin/assets/js-"]').getAttribute("src");
  expect(jsHref).toMatch(/\/admin\/assets\/js-[a-f0-9]{32}$/);
  const loadedFonts = await page.evaluate(async () => {
    await document.fonts.load('14px "Geist"');
    await document.fonts.load('14px "Geist Mono"');
    await document.fonts.ready;
    return {
      geist: document.fonts.check('14px "Geist"'),
      geistMono: document.fonts.check('14px "Geist Mono"')
    };
  });
  expect(loadedFonts.geist, "Geist font face should be loaded").toBe(true);
  expect(loadedFonts.geistMono, "Geist Mono font face should be loaded").toBe(true);
  const sansPath = "/admin/assets/geist-sans-vf.woff2";
  const monoPath = "/admin/assets/geist-mono-vf.woff2";
  const assets = [
    await assertAssetBytes(page, cssHref, "accrue_admin/priv/static/accrue_admin.css"),
    await assertAssetBytes(page, jsHref, "accrue_admin/priv/static/accrue_admin.js"),
    await assertAssetBytes(page, sansPath, "accrue_admin/priv/static/fonts/geist-sans-vf.woff2"),
    await assertAssetBytes(page, monoPath, "accrue_admin/priv/static/fonts/geist-mono-vf.woff2")
  ];
  return Object.fromEntries(assets.map((asset) => [asset.path, asset]));
}

async function assertLongRecoveryContentWraps(page) {
  const card = page.locator(".ax-at-risk-card").first();
  await expect(card).toBeVisible();
  const identity = card.locator(".ax-at-risk-card-identity .ax-heading");
  const reason = card.locator(".ax-at-risk-card-facts dd").last();
  const original = await Promise.all([identity.textContent(), reason.textContent()]);
  const longIdentity = `customer-${"X".repeat(90)}@example.test`;
  const longReason = `processor-decline-${"R".repeat(100)}`;
  try {
    await identity.evaluate((element, value) => { element.textContent = value; }, longIdentity);
    await reason.evaluate((element, value) => { element.textContent = value; }, longReason);
    for (const locator of [identity, reason]) {
      const metrics = await locator.evaluate((element) => ({
        client: element.clientWidth,
        scroll: element.scrollWidth,
        height: element.getBoundingClientRect().height,
        lineHeight: Number.parseFloat(getComputedStyle(element).lineHeight)
      }));
      expect(metrics.scroll).toBeLessThanOrEqual(metrics.client);
      expect(metrics.height).toBeGreaterThan(metrics.lineHeight);
    }
  } finally {
    await identity.evaluate((element, value) => { element.textContent = value || "—"; }, original[0]);
    await reason.evaluate((element, value) => { element.textContent = value || "—"; }, original[1]);
  }
}

test("Phase 237 served invoice and recovery journeys stay scoped and read-only", async ({ page, browser, sandboxId }, testInfo) => {
  test.setTimeout(90_000);
  const fixture = readFixture();
  const owner = encodeURIComponent(fixture.admin_org_alpha_slug);
  const sourceHead = execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim();
  const sources = Object.fromEntries(sourcePaths.map((source) => {
    const bytes = fs.readFileSync(path.join(repoRoot, source));
    return [source, { sha256: sha256(bytes), bytes: bytes.length }];
  }));
  const sourceSha = sha256(Buffer.from(JSON.stringify(sources)));
  const packageLock = fs.readFileSync(path.join(repoRoot, "examples/accrue_host/package-lock.json"));
  const browserEnvironment = {
    browser: browser.browserType().name(),
    browserVersion: browser.version(),
    os: `${process.platform} ${require("node:os").release()}`,
    node: process.version,
    runner: process.env.CI === "1" ? "CI=1" : "local",
    packageLockSha256: sha256(packageLock),
    packageAssetBuildCommand: "cd accrue_admin && mix accrue_admin.assets.build",
    hostCompileCommand: "cd examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors",
    browserCommand: "CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop"
  };
  const screenshots = {};

  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.goto("/app/billing", { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  const invoiceRouteStarted = process.hrtime.bigint();
  await page.goto(`/admin/invoices?org=${owner}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  const firstInvoiceRouteLiveViewReadyMs = Number(process.hrtime.bigint() - invoiceRouteStarted) / 1_000_000;
  await expect(page.locator("html.accrue-admin")).toHaveCount(1);
  await expect(page.getByRole("heading", { name: /open receivables/i }).first()).toBeVisible();
  const invoiceLink = page.locator(`a[href^="/admin/invoices/${fixture.invoice_id}"]`).first();
  await expect(invoiceLink).toBeVisible();
  await expect(invoiceLink).toContainText("HOST-BROWSER-VERIFY01");
  expect(fixture.admin_beta_invoice_id).toBeTruthy();
  await expect(page.locator(`a[href^="/admin/invoices/${fixture.admin_beta_invoice_id}"]`)).toHaveCount(0);
  await expect(page.locator("body")).not.toContainText("HOST-BROWSER-FOREIGN01");
  const invoiceCard = page.locator(`.ax-data-table-card[data-row-id="${fixture.invoice_id}"]`);
  await expect(invoiceCard).toContainText("Due date unavailable");
  await expect(invoiceCard).toContainText("Automatic");
  await expect(invoiceCard).not.toContainText("charge_automatically");
  await expect(invoiceCard).not.toContainText("False");
  const firstInvoiceRouteTaskReadyMs = Number(process.hrtime.bigint() - invoiceRouteStarted) / 1_000_000;
  const storedTheme = await page.evaluate(() => ({
    localStorage: localStorage.getItem("accrue_theme"),
    cookie: document.cookie.split("; ").find((entry) => entry.startsWith("accrue_theme="))?.split("=").slice(1).join("=") || null,
    rendered: document.documentElement.dataset.theme,
    prefersColorScheme: matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }));
  const initialResourceDiagnostics = await page.evaluate(() => {
    const entries = performance.getEntriesByType("resource");
    const resources = entries.map((entry) => ({
      path: new URL(entry.name, location.href).origin === location.origin
        ? new URL(entry.name, location.href).pathname
        : new URL(entry.name, location.href).origin,
      initiatorType: entry.initiatorType,
      encodedBodyBytes: entry.encodedBodySize,
      decodedBodyBytes: entry.decodedBodySize,
      transferBytes: entry.transferSize,
      durationMs: Number(entry.duration.toFixed(2))
    }));
    return {
      resourceCount: resources.length,
      encodedBodyBytes: resources.reduce((total, item) => total + item.encodedBodyBytes, 0),
      decodedBodyBytes: resources.reduce((total, item) => total + item.decodedBodyBytes, 0),
      transferBytes: resources.reduce((total, item) => total + item.transferBytes, 0),
      layoutShift: {
        supported: PerformanceObserver.supportedEntryTypes.includes("layout-shift"),
        entries: performance.getEntriesByType("layout-shift").length,
        value: performance.getEntriesByType("layout-shift").reduce((total, item) => total + (item.value || 0), 0)
      },
      longTasks: {
        supported: PerformanceObserver.supportedEntryTypes.includes("longtask"),
        entries: performance.getEntriesByType("longtask").length,
        totalDurationMs: performance.getEntriesByType("longtask").reduce((total, item) => total + item.duration, 0)
      },
      resources
    };
  });
  const warmRouteStarted = process.hrtime.bigint();
  await page.goto(page.url(), { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  const warmInvoiceRouteLiveViewReadyMs = Number(process.hrtime.bigint() - warmRouteStarted) / 1_000_000;
  await expect(page.getByRole("heading", { name: /open receivables/i }).first()).toBeVisible();
  const warmInvoiceRouteTaskReadyMs = Number(process.hrtime.bigint() - warmRouteStarted) / 1_000_000;
  const assets = await assertCurrentAssets(page);
  const jsHref = await page.locator('script[src*="/admin/assets/js-"]').getAttribute("src");
  await page.route("**/admin/assets/js-*", async (route) => {
    const response = await route.fetch();
    const staleBytes = Buffer.from(await response.body());
    staleBytes[0] ^= 1;
    await route.fulfill({ response, body: staleBytes });
  });
  let staleAssetRejected = false;
  let staleAssetFailure = "";
  try {
    await assertAssetBytes(page, jsHref, "accrue_admin/priv/static/accrue_admin.js");
  } catch (error) {
    if (!error.message.includes("served response differs from package build")) throw error;
    staleAssetRejected = true;
    staleAssetFailure = error.message.split("\n")[0];
  } finally {
    await page.unroute("**/admin/assets/js-*");
  }
  expect(staleAssetRejected, "stale JavaScript response must be rejected by its byte digest").toBe(true);
  const restoredJs = await assertAssetBytes(page, jsHref, "accrue_admin/priv/static/accrue_admin.js");
  expect(restoredJs.servedSha256).toBe(assets[restoredJs.path].packageSha256);
  const staleAssetEvidence = {
    path: restoredJs.path,
    injectedFirstByteMutation: true,
    expectedFailure: staleAssetFailure,
    restoredServedSha256: restoredJs.servedSha256,
    restoredToPackageSha256: restoredJs.servedSha256 === restoredJs.packageSha256
  };
  expect(staleAssetEvidence.restoredToPackageSha256).toBe(true);
  await page.setViewportSize({ width: 320, height: 800 });
  await assertNoOverflow(page);
  const mobileSearch = await page.locator("#search-trigger").boundingBox();
  expect(mobileSearch).not.toBeNull();
  expect(mobileSearch.x).toBeGreaterThanOrEqual(0);
  await expect(invoiceCard.getByRole("link", { name: /view invoice/i })).toBeVisible();
  const lightTokens = await assertThemeAndMotion(page, "light");
  const collectionShot = await page.screenshot({ fullPage: true });
  screenshots["invoice-collection.png"] = { bytes: collectionShot, route: page.url(), viewport: { width: 320, height: 800 }, theme: "light" };
  await testInfo.attach("phase237-invoice-collection.png", { body: collectionShot, contentType: "image/png" });

  await page.setViewportSize({ width: 1280, height: 900 });
  await page.goto(`/admin/invoices/${fixture.invoice_id}?org=${owner}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: /HOST-BROWSER-VERIFY01/ })).toBeVisible();
  const payAction = page.getByRole("button", { name: /pay.*invoice/i });
  await expect(payAction).toBeVisible();
  const detailShot = await page.screenshot({ fullPage: true });
  await testInfo.attach("phase240-invoice-detail-desktop-before.png", { body: detailShot, contentType: "image/png" });
  const detailGeometry = await page.evaluate(() => ({
    detailSections: Array.from(document.querySelectorAll(".ax-detail-section")).map((element) => {
      const bounds = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      return { title: element.querySelector(".ax-detail-section-title")?.textContent?.trim(), top: bounds.top, height: bounds.height, marginTop: style.marginTop, paddingTop: style.paddingTop };
    }),
    actionBand: (() => {
      const element = document.querySelector("[data-ax-action-band]");
      const bounds = element.getBoundingClientRect();
      return { x: bounds.x, y: bounds.y, width: bounds.width, height: bounds.height };
    })(),
    actionTargets: Array.from(document.querySelectorAll("[data-ax-action-band] button")).map((element) => {
      const bounds = element.getBoundingClientRect();
      return { label: element.textContent.trim(), x: bounds.x, y: bounds.y, width: bounds.width, height: bounds.height };
    })
  }));
  await testInfo.attach("phase240-invoice-detail-geometry.json", { body: Buffer.from(JSON.stringify(detailGeometry, null, 2)), contentType: "application/json" });
  await payAction.focus();
  await expect(payAction).toBeFocused();
  const focusOutline = await payAction.evaluate((element) => getComputedStyle(element).outlineWidth);
  expect(focusOutline).not.toBe("0px");
  const drawerInteractionStarted = process.hrtime.bigint();
  await page.keyboard.press("Enter");
  const reviewForm = page.locator('#invoice-action-drawer form[data-action-type="pay"]');
  await expect(reviewForm).toBeVisible();
  const drawerReadyMs = Number(process.hrtime.bigint() - drawerInteractionStarted) / 1_000_000;
  const reviewInteractionStarted = process.hrtime.bigint();
  await reviewForm.getByRole("button", { name: /pay invoice/i }).click();
  const review = page.locator('#invoice-action-drawer [data-role="confirm-panel"]');
  await expect(review).toBeVisible();
  const reviewReadyMs = Number(process.hrtime.bigint() - reviewInteractionStarted) / 1_000_000;
  await expect(review).toContainText(fixture.invoice_id);
  await expect(review).toContainText("admin-e2e-alpha-customer@example.test");
  await expect(review).toContainText(fixture.admin_org_alpha_slug);
  await expect(review).toContainText(/1,?000|10\.00/);
  await expect(review).toContainText(/attempt manual payment/i);
  await expect(page.locator('#invoice-action-drawer').getByRole("button", { name: "Pay invoice", exact: true })).toBeVisible();
  const cancel = page.locator('#invoice-action-drawer').getByRole("button", { name: "Back to invoice", exact: true });
  await expect(cancel).toBeVisible();
  const reviewShot = await page.screenshot({ fullPage: true });
  screenshots["invoice-review.png"] = { bytes: reviewShot, route: page.url(), viewport: { width: 1280, height: 900 }, theme: "light" };
  await testInfo.attach("phase237-invoice-review.png", { body: reviewShot, contentType: "image/png" });
  await page.keyboard.press("Escape");
  await expect(review).toBeHidden();
  await expect(payAction).toBeFocused();
  await expect(page.locator('[data-role="invoice-action-result"]')).toHaveCount(0);

  await page.setViewportSize({ width: 320, height: 800 });
  await assertNoOverflow(page);
  const darkTokens = await assertThemeAndMotion(page, "dark");
  expect(lightTokens.background).not.toBe(darkTokens.background);

  await page.goto(`/admin/analytics/recovery?org=${owner}&window=7d`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: /recovery/i }).first()).toBeVisible();
  const windowSelector = page.getByRole("navigation", { name: "Time window (UTC)" });
  for (const label of ["7 days UTC", "30 days UTC", "90 days UTC"]) {
    const windowLink = windowSelector.getByRole("link", { name: label, exact: true });
    await expect(windowLink).toBeVisible();
    const bounds = await windowLink.boundingBox();
    expect(bounds).not.toBeNull();
    expect(bounds.x).toBeGreaterThanOrEqual(0);
    expect(bounds.x + bounds.width).toBeLessThanOrEqual(320);
  }
  const windowMetrics = await windowSelector.evaluate((element) => ({
    clientWidth: element.clientWidth,
    scrollWidth: element.scrollWidth
  }));
  expect(windowMetrics.scrollWidth).toBeLessThanOrEqual(windowMetrics.clientWidth);
  const recoveryRow = page.getByRole("link", { name: /admin-e2e-alpha-customer@example\.test/i }).first();
  await expect(recoveryRow).toBeVisible();
  await expect(recoveryRow).toHaveAttribute("href", /window%3D7d/);
  await assertLongRecoveryContentWraps(page);
  const recoveryShot = await page.screenshot({ fullPage: true });
  screenshots["recovery.png"] = { bytes: recoveryShot, route: page.url(), viewport: { width: 320, height: 800 }, theme: "dark" };
  await testInfo.attach("phase237-recovery.png", { body: recoveryShot, contentType: "image/png" });

  const recoveryHref = await recoveryRow.getAttribute("href");
  if (!recoveryHref) throw new Error("recovery row did not provide a scoped campaign link");
  await recoveryRow.click();
  await waitForLiveView(page);
  const campaignUrl = new URL(page.url());
  const recoveryReturn = new URL(campaignUrl.searchParams.get("return_to"), page.url());
  await expect(page.locator("main")).toContainText(fixture.recovery_subscription_id);
  expect(recoveryReturn.pathname).toBe("/admin/analytics/recovery");
  expect(recoveryReturn.searchParams.get("org")).toBe(fixture.admin_org_alpha_slug);
  expect(recoveryReturn.searchParams.get("window")).toBe("7d");
  const returnLink = page.getByRole("link", { name: "Back to Recovery" });
  await expect(returnLink).toBeVisible();
  await returnLink.click();
  await waitForLiveView(page);
  const returnedUrl = new URL(page.url());
  expect(returnedUrl.pathname).toBe("/admin/analytics/recovery");
  expect(returnedUrl.searchParams.get("org")).toBe(fixture.admin_org_alpha_slug);
  expect(returnedUrl.searchParams.get("window")).toBe("7d");
  await assertNoOverflow(page);

  expect(fixture.admin_org_beta_slug).not.toBe(fixture.admin_org_alpha_slug);
  expect(fixture.admin_beta_invoice_id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
  expect(fixture.admin_beta_invoice_id).not.toBe(fixture.invoice_id);
  await page.goto(`/admin/invoices/${fixture.admin_beta_invoice_id}?org=${owner}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByLabel("Notifications")).toContainText(/Access restricted/i);
  await expect(page.locator("body")).not.toContainText(fixture.admin_beta_invoice_id);
  await expect(page.locator("body")).not.toContainText("HOST-BROWSER-FOREIGN01");

  await page.context().clearCookies();
  await login(page, fixture, fixture.normal_email, sandboxId);
  const portalResponse = await page.goto("/billing", { waitUntil: "domcontentloaded" });
  expect(portalResponse && portalResponse.status()).toBe(200);
  await waitForLiveView(page);
  await expect(page.locator("main.portal-shell h1")).toHaveText("Account overview");
  await expect(page.locator("html.accrue-admin")).toHaveCount(0);

  await page.context().clearCookies();
  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.goto("/app/billing", { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  await page.goto(`/admin/subscriptions/${fixture.recovery_subscription_id}?org=${owner}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: "admin-e2e-alpha-customer@example.test" })).toBeVisible();
  await expect(page.locator("body")).toContainText("admin-e2e-alpha-customer@example.test");
  await expect(page.locator("body")).toContainText("Price is not confirmed in admin");
  await expect(page.locator("body")).toContainText("Current period is not shown in admin");
  const healthPresentation = await page.locator(".ax-detail-health-summary").evaluate((summary) => {
    const summaryStyle = getComputedStyle(summary);
    const copyStyle = getComputedStyle(summary.querySelector(".ax-detail-health-copy"));
    const weights = Array.from(summary.querySelectorAll(".ax-detail-health-label, .ax-detail-health-answer, .ax-detail-health-verdict, .ax-detail-health-metric"))
      .map((element) => Number.parseInt(getComputedStyle(element).fontWeight, 10));
    return {
      summaryGap: summaryStyle.rowGap,
      summaryPadding: summaryStyle.padding,
      copyGap: copyStyle.gap,
      copyPadding: copyStyle.padding,
      weights
    };
  });
  expect(healthPresentation.summaryGap, "lifecycle summary separates its task facts").not.toBe("0px");
  expect(healthPresentation.copyGap, "summary copy uses the incumbent spacing ladder").not.toContain("0.5px");
  expect(healthPresentation.copyPadding, "summary copy avoids half-pixel task spacing").not.toContain("0.5px");
  expect(healthPresentation.weights.every((weight) => weight === 400 || weight === 600), "summary uses only approved type weights").toBe(true);
  const scopedCustomerLink = page.getByRole("link", { name: "admin-e2e-alpha-customer@example.test" }).first();
  await expect(scopedCustomerLink).toHaveAttribute("href", new RegExp(`/admin/customers/${fixture.admin_denial_customer_id}\\?org=${fixture.admin_org_alpha_slug}`));
  const subscriptionOverflow = page.locator("[data-ax-action-overflow-menu]:visible");
  await expect(subscriptionOverflow).toHaveCount(1);
  const subscriptionAction = subscriptionOverflow.locator("summary");
  await expect(subscriptionAction).toBeVisible();
  const actionBounds = await subscriptionAction.boundingBox();
  expect(actionBounds).not.toBeNull();
  expect(actionBounds.height).toBeGreaterThanOrEqual(44);
  await subscriptionAction.click();
  await expect(subscriptionOverflow.locator('[role="menu"] [role="menuitem"]').first()).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(subscriptionOverflow.locator('[role="menu"]')).toBeHidden();
  const commandPalette = page.locator(".ax-command-palette");
  if (await commandPalette.isVisible().catch(() => false)) {
    await page.keyboard.press("Escape");
    await expect(commandPalette).toBeHidden();
  }

  const subscriptionIdentity = page.locator(".ax-summary-fact").nth(1);
  const originalIdentity = await subscriptionIdentity.evaluate((element) => ({
    label: element.querySelector("strong")?.textContent?.trim() || "Customer",
    value: element.textContent.replace(element.querySelector("strong")?.textContent || "", "").trim()
  }));
  const longIdentity = `customer-${"C".repeat(120)}@example.test`;
  await page.setViewportSize({ width: 320, height: 800 });
  await subscriptionIdentity.evaluate((element, text) => {
    const label = element.querySelector("strong");
    element.replaceChildren(label, document.createTextNode(text));
  }, longIdentity);
  const longIdentityMetrics = await subscriptionIdentity.evaluate((element) => ({
    clientWidth: element.clientWidth,
    scrollWidth: element.scrollWidth,
    height: element.getBoundingClientRect().height,
    lineHeight: Number.parseFloat(getComputedStyle(element).lineHeight)
  }));
  expect(longIdentityMetrics.scrollWidth).toBeLessThanOrEqual(longIdentityMetrics.clientWidth);
  expect(longIdentityMetrics.height).toBeGreaterThan(longIdentityMetrics.lineHeight);
  await subscriptionIdentity.evaluate((element, original) => {
    const label = element.querySelector("strong");
    element.replaceChildren(label, document.createTextNode(original.value));
  }, originalIdentity);

  const subscriptionResponsiveGeometry = [];
  for (const width of [320, 768, 1280]) {
    await page.setViewportSize({ width, height: 900 });
    await assertNoOverflow(page);
    const geometry = await page.evaluate(() => {
      const action = document.querySelector("[data-ax-action-overflow-menu] summary");
      const bounds = action.getBoundingClientRect();
      return {
        viewport: document.documentElement.clientWidth,
        document: document.documentElement.scrollWidth,
        actionHeight: bounds.height,
        actionLeft: bounds.left,
        actionRight: bounds.right,
        coarsePointer: matchMedia("(pointer: coarse)").matches
      };
    });
    expect(geometry.actionHeight).toBeGreaterThanOrEqual(44);
    expect(geometry.actionLeft).toBeGreaterThanOrEqual(0);
    expect(geometry.actionRight).toBeLessThanOrEqual(width);
    subscriptionResponsiveGeometry.push(geometry);
  }

  const mobileContext = await browser.newContext({
    ...devices["Pixel 5"],
    baseURL: `http://127.0.0.1:${process.env.ACCRUE_HOST_BROWSER_PORT || "4101"}`,
    ...(sandboxId ? { userAgent: sandboxId } : {}),
    extraHTTPHeaders: sandboxId ? { "x-sandbox-id": sandboxId } : {}
  });
  try {
    const mobilePage = await mobileContext.newPage();
    await login(mobilePage, fixture, fixture.admin_email, sandboxId);
    await mobilePage.goto("/app/billing", { waitUntil: "domcontentloaded" });
    await waitForLiveView(mobilePage);
    await mobilePage.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(mobilePage);
    await mobilePage.goto(`/admin/subscriptions/${fixture.recovery_subscription_id}?org=${owner}`, { waitUntil: "domcontentloaded" });
    await waitForLiveView(mobilePage);
    await expect(mobilePage.getByRole("heading", { name: "admin-e2e-alpha-customer@example.test" })).toBeVisible();
    const mobileAction = mobilePage.locator("[data-ax-action-overflow-menu] summary");
    await expect(mobileAction).toBeVisible();
    await mobileAction.click();
    await expect(mobilePage.locator('[role="menu"] [role="menuitem"]').first()).toBeVisible();
    for (const width of [320, 768, 1280]) {
      await mobilePage.setViewportSize({ width, height: 900 });
      await assertNoOverflow(mobilePage);
      const geometry = await mobilePage.evaluate(() => {
        const action = document.querySelector("[data-ax-action-overflow-menu] summary");
        const bounds = action.getBoundingClientRect();
        return {
          viewport: document.documentElement.clientWidth,
          document: document.documentElement.scrollWidth,
          actionHeight: bounds.height,
          actionLeft: bounds.left,
          actionRight: bounds.right,
          coarsePointer: matchMedia("(pointer: coarse)").matches
        };
      });
      expect(geometry.coarsePointer).toBe(true);
      expect(geometry.actionHeight).toBeGreaterThanOrEqual(44);
      expect(geometry.actionLeft).toBeGreaterThanOrEqual(0);
      expect(geometry.actionRight).toBeLessThanOrEqual(width);
      subscriptionResponsiveGeometry.push({ ...geometry, device: "Pixel 5" });
    }
  } finally {
    await mobileContext.close();
  }
  const subscriptionShot = await page.screenshot({ fullPage: true });
  await testInfo.attach("phase240-subscription-detail-desktop.png", { body: subscriptionShot, contentType: "image/png" });
  screenshots["subscription-detail.png"] = { bytes: subscriptionShot, route: page.url(), viewport: { width: 1280, height: 900 }, theme: "dark" };

  fs.mkdirSync(captureDir, { recursive: true });
  const manifest = {
    phase: "237-admin-invoices-payments-recovery",
    evidence: "seeded deterministic host fixtures; not live-provider settlement",
    layout_stress: "long identity and failure reason were injected in-memory, checked for wrapping, then restored before capture",
    captured_at: new Date().toISOString(),
    source_head: sourceHead,
    source_sha: sourceSha,
    sources,
    assets,
    stale_asset_negative: staleAssetEvidence,
    browser_environment: browserEnvironment,
    theme_provenance: {
      stored_theme_before_visual_override: storedTheme,
      effective_theme_checks: [lightTokens, darkTokens].map((tokens) => ({ background: tokens.background, color: tokens.color, reducedMotionDuration: tokens.duration })),
      visual_override_method: "Playwright prefers-color-scheme emulation plus data-theme DOM setter; not a stored preference mutation"
    },
    first_fresh_invoice_diagnostics: {
      fixture: "disposable host Ecto sandbox; seeded Admin Alpha invoice",
      route: `/admin/invoices?org=${owner}`,
      query: `org=${fixture.admin_org_alpha_slug}`,
      cold: {
        liveview_ready_ms: Number(firstInvoiceRouteLiveViewReadyMs.toFixed(2)),
        task_ready_ms: Number(firstInvoiceRouteTaskReadyMs.toFixed(2))
      },
      warm: {
        liveview_ready_ms: Number(warmInvoiceRouteLiveViewReadyMs.toFixed(2)),
        task_ready_ms: Number(warmInvoiceRouteTaskReadyMs.toFixed(2))
      },
      drawer_ready_ms: Number(drawerReadyMs.toFixed(2)),
      action_review_ready_ms: Number(reviewReadyMs.toFixed(2)),
      raw_and_encoded_resource_diagnostics: initialResourceDiagnostics,
      first_fresh_timing_is_diagnostic_only: true
    },
    subscription_crosscheck: {
      fixture: "disposable host Ecto sandbox; seeded Admin Alpha past-due subscription",
      route: `/admin/subscriptions/${fixture.recovery_subscription_id}?org=${owner}`,
      layout_stress: "customer identity was extended in-memory at 320px, checked for wrapping, then restored before capture",
      missing_plan_and_period: "Price not shown in admin; Current period is not shown in admin",
      responsive_geometry: subscriptionResponsiveGeometry,
      long_identity: longIdentityMetrics
    },
    viewport_and_theme: Object.fromEntries(Object.entries(screenshots).map(([name, shot]) => [name, { route: shot.route, viewport: shot.viewport, theme: shot.theme, sha256: sha256(shot.bytes), bytes: shot.bytes.length }])),
    route_and_interaction: {
      route: `/admin/invoices/${fixture.invoice_id}?org=${owner}`,
      action_review_target: fixture.invoice_id,
      action_review_opened: true,
      action_confirmed_or_dispatched: false,
      no_mutation_claim_from_http_method_observation: true
    },
    read_only: true,
    confirmed_or_dispatched: false
  };
  for (const [name, shot] of Object.entries(screenshots)) {
    fs.writeFileSync(path.join(captureDir, name), shot.bytes);
  }
  fs.writeFileSync(path.join(captureDir, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
  await testInfo.attach("phase237-capture-manifest.json", { body: Buffer.from(JSON.stringify(manifest, null, 2)), contentType: "application/json" });
});
