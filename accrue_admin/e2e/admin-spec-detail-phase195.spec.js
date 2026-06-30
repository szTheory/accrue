/**
 * Phase 195 — SPEC-DETAIL and IXN-01 final gate.
 *
 * Exercises the Subscription detail exemplar against the locked DETAIL
 * invariants and the canonical overlay behavior instantiated in Phase 195.
 */

const fs = require("fs");
const path = require("path");

const { test, expect } = require("@playwright/test");

const {
  assertFocusWithin,
  assertTopPointerTarget,
  setPhase191Theme,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

const REPO_ROOT = path.resolve(__dirname, "..", "..");
const BASELINE_PAGE_FLOW_CELLS = path.join(
  REPO_ROOT,
  ".planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json"
);

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seedScenario(request, scenario, { optional = false } = {}) {
  const response = await request.post(`/__e2e__/seed/${scenario}`);
  if (optional && response.status() === 404) return {};
  expect(response.ok(), `seed ${scenario} should return 2xx`).toBeTruthy();
  return response.json();
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}

async function openSubscriptionDetail(page, request) {
  await reset(request);
  const fixture = await seedScenario(request, "dashboard");
  const route = `/billing/subscriptions/${fixture.subscription_id}`;
  await login(page, route);
  await setPhase191Theme(page, "light");
  return { fixture, route };
}

async function bodyScrollTop(page) {
  return page.evaluate(() => document.scrollingElement?.scrollTop || window.scrollY || 0);
}

async function assertBodyScrollStable(page, label) {
  const before = await bodyScrollTop(page);
  await page.mouse.wheel(0, 640);
  const after = await bodyScrollTop(page);
  expect(after, `${label}: body scroll should remain locked while drawer is open`).toBe(before);
}

async function openSafeActionDrawer(page) {
  const actionMenu = page.locator("[data-ax-action-overflow-menu]").first();
  await expect(actionMenu).toBeVisible();
  await actionMenu.click();

  const safeItem = page
    .getByRole("menuitem", {
      name: /update quantity|add item|update item quantity|remove item|pause collection|resume/i,
    })
    .first();
  await expect(safeItem).toBeVisible();
  await safeItem.click();

  const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
  await expect(drawer).toBeVisible();
  await expect(page.locator("#accrue-admin-shell")).toHaveAttribute("inert", "");

  return drawer;
}

async function assertDrawerGeometry(page, drawer) {
  const geometry = await drawer.locator("[data-ax-overlay-panel]").first().evaluate((panel) => {
    const rect = panel.getBoundingClientRect();
    const viewport = { width: window.innerWidth, height: window.innerHeight };
    return {
      left: rect.left,
      right: rect.right,
      top: rect.top,
      bottom: rect.bottom,
      width: rect.width,
      height: rect.height,
      viewport,
    };
  });

  if (geometry.viewport.width < 768) {
    expect(geometry.bottom, "mobile drawer should present as a bottom sheet").toBeCloseTo(
      geometry.viewport.height,
      0
    );
    expect(geometry.width, "mobile drawer should span most of the viewport").toBeGreaterThan(
      geometry.viewport.width * 0.9
    );
  } else {
    expect(geometry.right, "desktop drawer should be right docked").toBeCloseTo(
      geometry.viewport.width,
      0
    );
    expect(geometry.left, "desktop drawer should not cover the full page width").toBeGreaterThan(0);
  }
}

async function assertDrawerInteractive(page, drawer) {
  const primary = drawer.locator("form[data-ax-action-drawer-form] button[type='submit']").first();
  const field = drawer.locator("input, select, textarea, button").first();

  await expect(primary).toBeVisible();
  await expect(field).toBeVisible();
  await field.focus();

  await assertTopPointerTarget(primary, "Phase 195 drawer primary action");
  await assertTopPointerTarget(field, "Phase 195 drawer focusable control");
  await assertFocusWithin(page, drawer, "Phase 195 action drawer");
}

async function assertInitialDetailInvariants(page, label) {
  await expect(page.locator("h1"), `${label}: exactly one h1`).toHaveCount(1);

  const actionBand = page.locator("[data-ax-action-band]");
  await expect(actionBand, `${label}: action band`).toBeVisible();
  await expect(actionBand.locator("form:visible"), `${label}: no action-band forms`).toHaveCount(0);
  await expect(page.locator("[data-ax-action-drawer-form]:visible"), `${label}: no drawer forms on load`).toHaveCount(0);

  const primaryActions = page.locator("[data-ax-primary-action]");
  expect(await primaryActions.count(), `${label}: DETAIL pages may expose at most two primary actions`).toBeLessThanOrEqual(2);

  await expect(page.locator("[data-ax-action-overflow-menu]"), `${label}: overflow menu`).toHaveCount(1);
  await expect(page.locator("[data-ax-related-resources]"), `${label}: one related strip`).toHaveCount(1);
  await expect(page.locator("[data-role='subscription-related-billing']"), `${label}: duplicate related card removed`).toHaveCount(0);
  await expect(page.locator("[data-ax-summary-list]"), `${label}: summary list`).toHaveCount(1);
  await expect(page.locator("[data-ax-drill-section]"), `${label}: drill sections`).toHaveCount(3);
  await expect(page.locator("[data-ax-lazy-activity]"), `${label}: lazy activity`).toHaveCount(1);
  await expect(page.locator("[data-ax-lazy-json]"), `${label}: lazy raw JSON`).toHaveCount(1);
}

function subscriptionDetailBaselineRows() {
  const source = fs.readFileSync(BASELINE_PAGE_FLOW_CELLS, "utf8");
  return (source.match(/p193__subscription-detail/g) || []).length;
}

test.describe("Phase 195 SPEC-DETAIL and overlay invariants", () => {
  test("Page-flow baseline includes p193 subscription-detail rows", async () => {
    expect(fs.existsSync(BASELINE_PAGE_FLOW_CELLS), "baseline.page-flow.cells.json should exist").toBeTruthy();
    expect(subscriptionDetailBaselineRows(), "p193__subscription-detail rows should be present").toBeGreaterThan(0);
  });

  test("Subscription detail initial render holds SPEC-DETAIL structure in light and dark themes", async ({
    page,
    request,
  }) => {
    await openSubscriptionDetail(page, request);

    for (const theme of ["light", "dark"]) {
      await setPhase191Theme(page, theme);
      await assertInitialDetailInvariants(page, theme);
    }
  });

  test("Subscription action drawer portals, locks background scroll, traps focus, and closes by Escape", async ({
    page,
    request,
  }) => {
    await openSubscriptionDetail(page, request);

    const drawer = await openSafeActionDrawer(page);
    await assertDrawerGeometry(page, drawer);
    await assertDrawerInteractive(page, drawer);
    await assertBodyScrollStable(page, "Escape close flow");

    await page.keyboard.press("Escape");
    await expect(drawer).toBeHidden();
    await expect(page.locator("#accrue-admin-shell")).not.toHaveAttribute("inert", "");
  });

  test("Subscription action drawer closes by backdrop click without leaving a ghost overlay", async ({
    page,
    request,
  }) => {
    await openSubscriptionDetail(page, request);

    const drawer = await openSafeActionDrawer(page);
    await assertDrawerGeometry(page, drawer);

    const backdrop = page.locator("#ax-overlay-root [data-ax-overlay-backdrop]").first();
    await expect(backdrop).toBeVisible();
    await backdrop.click({ position: { x: 8, y: 8 } });

    await expect(drawer).toBeHidden();
    await expect(page.locator("#ax-overlay-root [data-presentation='drawer']")).toHaveCount(0);
    await expect(page.locator("#accrue-admin-shell")).not.toHaveAttribute("inert", "");
  });
});
