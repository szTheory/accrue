// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");
const AxeBuilder = require("@axe-core/playwright").default;

const repoRoot = path.resolve(__dirname, "../../..");
const phase = "234-admin-customers-subscriptions";

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

async function assertBaselineIsImmutable() {
  const { resolvePhaseEvidencePath } = await import("../../../scripts/ci/phase_evidence_path.mjs");
  const resolve = (name) => resolvePhaseEvidencePath(phase, `captures/pre-layout/${name}`, { root: repoRoot });
  const baseline = JSON.parse(fs.readFileSync(resolve("manifest.json"), "utf8"));
  for (const [name, expected] of Object.entries(baseline.images)) {
    const bytes = fs.readFileSync(resolve(name));
    expect(bytes.length).toBe(expected.bytes);
    expect(sha256(bytes)).toBe(expected.sha256);
  }
  return baseline;
}

async function assertStoredCaptureIsIntact() {
  const { resolvePhaseEvidencePath } = await import("../../../scripts/ci/phase_evidence_path.mjs");
  const manifestPath = resolvePhaseEvidencePath(phase, "captures/post-layout/234-06-final/manifest.json", { root: repoRoot });
  // Resolve the evidence set once. Independently resolving each image could mix
  // an archived manifest with output from a later active-phase browser run.
  const resolve = (name) => path.join(path.dirname(manifestPath), name);
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  expect(manifest.phase).toBe(phase);
  for (const [name, expected] of Object.entries(manifest.images)) {
    const bytes = fs.readFileSync(resolve(name));
    expect(bytes.length).toBe(expected.bytes);
    expect(sha256(bytes)).toBe(expected.sha256);
  }
  return manifest;
}

async function assertNoPageOverflow(page) {
  const size = await page.evaluate(() => ({ viewport: document.documentElement.clientWidth, page: document.documentElement.scrollWidth }));
  expect(size.page, `page overflow at ${size.viewport}px`).toBeLessThanOrEqual(size.viewport);
}

async function assertDomIntegrity(page) {
  const result = await page.evaluate(() => {
    const ids = Array.from(document.querySelectorAll("[id]"), (element) => element.id);
    const duplicateIds = ids.filter((id, index) => ids.indexOf(id) !== index);
    const focused = document.activeElement;
    const hiddenFocus = Boolean(focused?.closest?.('[hidden], [aria-hidden="true"], [inert]'));
    return { duplicateIds: [...new Set(duplicateIds)], hiddenFocus };
  });
  expect(result.duplicateIds).toEqual([]);
  expect(result.hiddenFocus).toBe(false);
}

async function assertNoSeriousA11yViolations(page, label) {
  const results = await new AxeBuilder({ page }).analyze();
  const serious = results.violations.filter((violation) => ["critical", "serious"].includes(violation.impact));
  expect(serious, `${label}: ${JSON.stringify(serious.map(({ id, nodes }) => ({ id, count: nodes.length })))}`).toEqual([]);
}

async function assertSubscriptionDetailReadability(page) {
  const metrics = await page.locator(".ax-subscription-detail-page").evaluate((root) => {
    return Array.from(
      root.querySelectorAll(".ax-summary-list-value, .ax-summary-list-action, .ax-field-label, .ax-field-value")
    )
      .filter((element) => element.getClientRects().length > 0)
      .map((element) => {
        const style = getComputedStyle(element);
        const fontSize = Number.parseFloat(style.fontSize);
        const lineHeight = Number.parseFloat(style.lineHeight);
        return { text: element.textContent?.trim(), fontSize, lineHeight };
      });
  });

  expect(metrics.length, "subscription detail should expose readable primary facts").toBeGreaterThan(0);
  expect(metrics.filter(({ text }) => text).every(({ fontSize }) => fontSize >= 14)).toBeTruthy();
  expect(metrics.filter(({ text }) => text).every(({ fontSize, lineHeight }) => lineHeight / fontSize >= 1.2)).toBeTruthy();
}

async function servedStylesheet(page) {
  const href = await page.locator('link[rel="stylesheet"][href*="/admin/assets/css-"]').getAttribute("href");
  expect(href).toMatch(/\/admin\/assets\/css-[a-f0-9]{32}$/);
  const response = await page.request.get(href);
  expect(response.ok()).toBeTruthy();
  const served = await response.body();
  const built = fs.readFileSync(path.join(repoRoot, "accrue_admin/priv/static/accrue_admin.css"));
  expect(sha256(served)).toBe(sha256(built));
  expect(served.equals(built)).toBeTruthy();
  return { href, bytes: served.length, sha256: sha256(served) };
}

async function capture(page, name, records, testInfo) {
  const bytes = await page.screenshot({ fullPage: true });
  records[name] = { bytes, route: page.url() };
  await testInfo.attach(`phase234-${name}`, { body: bytes, contentType: "image/png" });
}

test("Phase 234 served Admin journeys preserve scope, focus, reflow, theme and asset provenance", async ({ page, sandboxId }, testInfo) => {
  test.setTimeout(90_000);
  const baseline = await assertBaselineIsImmutable();
  const fixture = readFixture();
  const owner = encodeURIComponent(fixture.admin_org_alpha_slug);
  const screenshots = {};

  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.locator('[data-testid="workspace-billing-link"]').click();
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  await page.goto(`/admin?org=${owner}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.locator("html.accrue-admin")).toHaveCount(1);
  await expect(page.getByRole("heading", { name: /billing operations/i }).first()).toBeVisible();
  await capture(page, "home.png", screenshots, testInfo);
  await servedStylesheet(page);

  const searchTrigger = page.locator("[data-command-palette-trigger]").first();
  await searchTrigger.focus();
  await page.keyboard.press("Enter");
  const searchDialog = page.getByRole("dialog", { name: /global search/i });
  await expect(searchDialog).toBeVisible();
  const searchInput = page.locator("#global-search-input");
  await expect(searchInput).toBeFocused();
  await page.keyboard.press("Shift+Tab");
  await expect(searchDialog).toContainText(/Customers: name, email/i);
  await expect(searchInput).not.toBeFocused();
  await page.keyboard.press("Tab");
  await expect(searchInput).toBeFocused();
  await searchInput.fill("admin-e2e-alpha-customer@example.test");
  await expect(searchInput).toHaveValue("admin-e2e-alpha-customer@example.test");
  await expect(searchDialog).toHaveAttribute("aria-modal", "true");
  await capture(page, "search.png", screenshots, testInfo);
  await page.keyboard.press("Escape");
  await expect(searchDialog).toBeHidden();
  await expect(searchTrigger).toBeFocused();

  await page.goto(`/admin/customers?org=${owner}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: /find a customer/i })).toBeVisible();
  await assertDomIntegrity(page);
  await capture(page, "customer-list.png", screenshots, testInfo);
  const customerLink = page.locator(`a[href*="/admin/customers/${fixture.admin_denial_customer_id}"]`).first();
  await expect(customerLink).toBeVisible();
  await customerLink.click();
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: "admin-e2e-alpha-customer@example.test" })).toBeVisible();
  await assertDomIntegrity(page);
  await assertNoSeriousA11yViolations(page, "customer detail, light theme");
  await capture(page, "customer-detail.png", screenshots, testInfo);

  const relatedSubscription = page.locator('a[href*="/admin/subscriptions/"]').first();
  await expect(relatedSubscription).toBeVisible();
  const relatedSubscriptionHref = await relatedSubscription.getAttribute("href");
  if (!relatedSubscriptionHref) throw new Error("customer detail did not contain its subscription path");
  await relatedSubscription.click();
  await waitForLiveView(page);
  await expect(page).toHaveURL(/return_to=.*admin%2Fcustomers/);
  const contextualReturn = page.getByRole("link", { name: /back to customers/i });
  await expect(contextualReturn).toBeVisible();
  await expect(contextualReturn).toHaveAttribute(
    "href",
    new RegExp(`^/admin/customers/${fixture.admin_denial_customer_id}\\?`)
  );
  await contextualReturn.click();
  await waitForLiveView(page);
  await expect(page).toHaveURL(new RegExp(`/admin/customers/${fixture.admin_denial_customer_id}\\?`));

  await page.goto(`/admin/subscriptions?view=all&org=${owner}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: /subscriptions/i }).first()).toBeVisible();
  await assertDomIntegrity(page);
  await capture(page, "subscription-list.png", screenshots, testInfo);
  await page.goto(relatedSubscriptionHref, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.locator("main")).toContainText("admin-e2e-alpha-customer@example.test");
  await assertDomIntegrity(page);
  await assertSubscriptionDetailReadability(page);
  await assertNoSeriousA11yViolations(page, "subscription detail, light theme");
  await capture(page, "subscription-detail.png", screenshots, testInfo);

  const actionMenu = page.locator("#subscription-action-menu");
  await actionMenu.locator("summary").click();
  await actionMenu.getByRole("menuitem", { name: /cancel immediately/i }).click();
  const drawer = page.locator("#subscription-action-drawer");
  await expect(drawer).toBeVisible();
  await expect(drawer.locator('[role="dialog"][aria-modal="true"]')).toBeVisible();
  await expect(drawer.locator('form[data-action-type="cancel_now"]')).toBeVisible();
  await capture(page, "subscription-drawer.png", screenshots, testInfo);
  await drawer.locator('form[data-action-type="cancel_now"] button[type="submit"]').click();
  await expect(drawer.locator('[data-role="confirm-panel"]')).toBeVisible();
  const confirmAction = drawer.locator('[data-role="confirm-action"]:visible');
  await confirmAction.click();

  const stepUp = page.locator("#accrue-admin-step-up-dialog");
  await expect(stepUp).toBeVisible();
  await expect(page.locator("#step-up-code")).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(stepUp.getByRole("button", { name: /cancel/i })).toBeFocused();
  await page.keyboard.press("Tab");
  const submitStepUp = stepUp.getByRole("button", { name: /verify/i });
  await expect(submitStepUp).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(page.locator("#step-up-code")).toBeFocused();
  await page.keyboard.press("Shift+Tab");
  await expect(submitStepUp).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(stepUp).toBeHidden();
  await expect(drawer.locator('[data-role="confirm-panel"]')).toBeVisible();
  await expect(confirmAction).toBeFocused();
  await expect(page.locator('[data-role="subscription-action-result"]')).toHaveCount(0);
  await page.reload({ waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.locator("main")).toContainText("Active");
  await expect(page.locator('[data-role="subscription-action-result"]')).toHaveCount(0);

  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await page.locator("html").evaluate((element) => element.setAttribute("data-theme", "dark"));
  await assertSubscriptionDetailReadability(page);
  await assertNoSeriousA11yViolations(page, "subscription detail, dark theme");
  await assertNoPageOverflow(page);
  const reducedMotion = await page.locator("body").evaluate((element) => getComputedStyle(element).transitionDuration);
  expect(reducedMotion.split(",").every((duration) => parseFloat(duration) <= 0.01)).toBeTruthy();

  // Historical captures stay immutable; current served assets are checked above.
  await assertStoredCaptureIsIntact();
  expect(baseline.phase).toBe(phase);
});

test.describe("Phase 234 coarse pointer", () => {
  test.use({ viewport: { width: 320, height: 800 }, isMobile: true, hasTouch: true });

  test("customer and subscription facts and actions remain reachable at 320px", async ({ page, sandboxId }) => {
    const fixture = readFixture();
    const owner = encodeURIComponent(fixture.admin_org_alpha_slug);
    await login(page, fixture, fixture.admin_email, sandboxId);
    const workspaceLink = page.locator('[data-testid="workspace-billing-link"]');
    await workspaceLink.focus();
    await page.keyboard.press("Enter");
    await waitForLiveView(page);
    const organizationButton = page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`);
    await organizationButton.focus();
    await page.keyboard.press("Enter");
    await waitForLiveView(page);
    await expect(page.getByRole("heading", { name: "Workspace billing" })).toBeVisible();
    await expect(page).toHaveURL(/\/app\/billing/);
    await page.goto(`/admin/customers?org=${owner}`, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);
    await assertNoPageOverflow(page);
    await assertDomIntegrity(page);
    await expect(page.locator("main")).toContainText("admin-e2e-alpha-customer@example.test");
    await page.goto(`/admin/customers/${fixture.admin_denial_customer_id}?org=${owner}`, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);
    await assertNoPageOverflow(page);
    await assertDomIntegrity(page);
    await expect(page.getByRole("heading", { name: "admin-e2e-alpha-customer@example.test" })).toBeVisible();
    await page.goto(`/admin/subscriptions?view=all&org=${owner}`, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);
    await assertNoPageOverflow(page);
    await assertDomIntegrity(page);
    const target = page.locator("main .ax-button:visible").first();
    await expect(target).toBeVisible();
    const box = await target.boundingBox();
    expect(box?.height ?? 0).toBeGreaterThanOrEqual(44);
    const subscriptionLink = page.locator('main a[href*="/admin/subscriptions/"]:visible').first();
    await expect(subscriptionLink).toBeVisible();
    await subscriptionLink.click();
    await waitForLiveView(page);
    await assertNoPageOverflow(page);
    await assertDomIntegrity(page);
    await assertSubscriptionDetailReadability(page);
  });
});
