// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const captureDir = path.join(repoRoot, ".planning/phases/237-admin-invoices-payments-recovery/captures/237-08");
const sourcePaths = [
  "accrue_admin/assets/css/app.css",
  "accrue_admin/assets/css/theme.css",
  "accrue_admin/lib/accrue_admin/live/invoices_live.ex",
  "accrue_admin/lib/accrue_admin/live/invoice_live.ex",
  "accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex",
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

async function assertCurrentStylesheet(page) {
  const href = await page.locator('link[rel="stylesheet"][href*="/admin/assets/css-"]').getAttribute("href");
  expect(href).toMatch(/\/admin\/assets\/css-[a-f0-9]{32}$/);
  const response = await page.request.get(href);
  expect(response.ok()).toBeTruthy();
  const served = await response.body();
  const built = fs.readFileSync(path.join(repoRoot, "accrue_admin/priv/static/accrue_admin.css"));
  expect(sha256(served)).toBe(sha256(built));
  return { href, bytes: served.length, sha256: sha256(served) };
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

test("Phase 237 served invoice and recovery journeys stay scoped and read-only", async ({ page, sandboxId }, testInfo) => {
  test.setTimeout(90_000);
  const fixture = readFixture();
  const owner = encodeURIComponent(fixture.admin_org_alpha_slug);
  const sourceHead = execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim();
  const sources = Object.fromEntries(sourcePaths.map((source) => {
    const bytes = fs.readFileSync(path.join(repoRoot, source));
    return [source, { sha256: sha256(bytes), bytes: bytes.length }];
  }));
  const sourceSha = sha256(Buffer.from(JSON.stringify(sources)));
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
      resources
    };
  });
  const asset = await assertCurrentStylesheet(page);
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
  await page.keyboard.press("Enter");
  const reviewForm = page.locator('#invoice-action-drawer form[data-action-type="pay"]');
  await expect(reviewForm).toBeVisible();
  await reviewForm.getByRole("button", { name: /pay invoice/i }).click();
  const review = page.locator('#invoice-action-drawer [data-role="confirm-panel"]');
  await expect(review).toBeVisible();
  await expect(review).toContainText(fixture.invoice_id);
  await expect(review).toContainText("admin-e2e-alpha-customer@example.test");
  await expect(review).toContainText(fixture.admin_org_alpha_slug);
  await expect(review).toContainText(/1,?000|10\.00/);
  await expect(review).toContainText(/attempt manual payment/i);
  await expect(page.locator('#invoice-action-drawer').getByRole("button", { name: "Pay invoice", exact: true })).toBeVisible();
  const cancel = page.locator('#invoice-action-drawer').getByRole("button", { name: /cancel/i });
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

  await page.goto(`/admin/analytics/recovery?org=${owner}&window=30d`, { waitUntil: "domcontentloaded" });
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
  await expect(recoveryRow).toHaveAttribute("href", /window%3D30d/);
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
  expect(recoveryReturn.searchParams.get("window")).toBe("30d");
  const returnLink = page.getByRole("link", { name: /back to results/i });
  await expect(returnLink).toBeVisible();
  await returnLink.click();
  await waitForLiveView(page);
  const returnedUrl = new URL(page.url());
  expect(returnedUrl.pathname).toBe("/admin/analytics/recovery");
  expect(returnedUrl.searchParams.get("org")).toBe(fixture.admin_org_alpha_slug);
  expect(returnedUrl.searchParams.get("window")).toBe("30d");
  await assertNoOverflow(page);

  expect(fixture.admin_org_beta_slug).not.toBe(fixture.admin_org_alpha_slug);
  expect(fixture.admin_beta_invoice_id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
  expect(fixture.admin_beta_invoice_id).not.toBe(fixture.invoice_id);
  await page.goto(`/admin/invoices/${fixture.admin_beta_invoice_id}?org=${owner}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByLabel("Notifications")).toContainText(/Access restricted/i);
  await expect(page.locator("body")).not.toContainText(fixture.admin_beta_invoice_id);
  await expect(page.locator("body")).not.toContainText("HOST-BROWSER-FOREIGN01");

  fs.mkdirSync(captureDir, { recursive: true });
  const manifest = {
    phase: "237-admin-invoices-payments-recovery",
    evidence: "seeded deterministic host fixtures; not live-provider settlement",
    layout_stress: "long identity and failure reason were injected in-memory, checked for wrapping, then restored before capture",
    captured_at: new Date().toISOString(),
    source_head: sourceHead,
    source_sha: sourceSha,
    sources,
    stylesheet: asset,
    first_fresh_invoice_diagnostics: {
      fixture: "disposable host Ecto sandbox; seeded Admin Alpha invoice",
      route: `/admin/invoices?org=${owner}`,
      liveview_ready_ms: Number(firstInvoiceRouteLiveViewReadyMs.toFixed(2)),
      task_ready_ms: Number(firstInvoiceRouteTaskReadyMs.toFixed(2)),
      resources: initialResourceDiagnostics
    },
    viewport_and_theme: Object.fromEntries(Object.entries(screenshots).map(([name, shot]) => [name, { route: shot.route, viewport: shot.viewport, theme: shot.theme, sha256: sha256(shot.bytes), bytes: shot.bytes.length }])),
    read_only: true,
    confirmed_or_dispatched: false
  };
  for (const [name, shot] of Object.entries(screenshots)) {
    fs.writeFileSync(path.join(captureDir, name), shot.bytes);
  }
  fs.writeFileSync(path.join(captureDir, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
  await testInfo.attach("phase237-capture-manifest.json", { body: Buffer.from(JSON.stringify(manifest, null, 2)), contentType: "application/json" });
});
