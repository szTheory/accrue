/**
 * Phase 198 - SPEC-DETAIL and analytics propagation contract.
 *
 * Wave 0 contract for the remaining detail and analytics pages. These tests
 * are expected to stay red until the Phase 198 page migrations land; failures
 * should identify missing DETAIL/overview conformance, not route, seed, import,
 * or command wiring problems.
 */

const { test, expect } = require("@playwright/test");

const {
  setPhase191Theme,
  assertFocusWithin,
  assertTopPointerTarget,
  assertNoHorizontalClip,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

const DETAIL_TARGETS = Object.freeze([
  {
    name: "Customer",
    route: ({ dashboard }) => `/billing/customers/${dashboard.customer_id}`,
    customerPeerNav: true,
  },
  {
    name: "Invoice",
    route: ({ edgeStates }) => `/billing/invoices/${edgeStates.jpy_invoice_id}`,
  },
  {
    name: "Charge",
    route: ({ operatorFlows }) => `/billing/payments/${operatorFlows.charge_id}`,
  },
  {
    name: "Coupon",
    route: ({ edgeStates }) => `/billing/coupons/${edgeStates.coupon_id}`,
    readOnly: true,
  },
  {
    name: "Promotion code",
    route: ({ edgeStates }) => `/billing/promotion-codes/${edgeStates.promo_code_id}`,
    readOnly: true,
  },
  {
    name: "Connect account",
    route: ({ edgeStates }) => `/billing/connect/${edgeStates.connect_account_id}`,
  },
  {
    name: "Webhook",
    route: ({ operatorFlows }) => `/billing/webhooks/${operatorFlows.single_webhook_id}`,
  },
  {
    name: "Event",
    route: ({ phase191 }) => `/billing/events/${phase191.source_event_id}`,
    readOnly: true,
  },
]);

const ANALYTICS_TARGETS = Object.freeze([
  {
    name: "Recovery",
    route: () => "/billing/analytics/recovery",
    assertion: assertRecoveryOrder,
  },
  {
    name: "Campaign",
    route: ({ edgeStates }) => `/billing/analytics/recovery/subscriptions/${edgeStates.at_risk_sub_id}`,
    assertion: assertCampaignDetail,
  },
]);

const DRAWER_FLOW_TARGETS = Object.freeze([
  {
    name: "Invoice",
    route: ({ edgeStates }) => `/billing/invoices/${edgeStates.jpy_invoice_id}`,
    trigger: /void invoice|mark uncollectible/i,
    confirm: /confirm|void|mark uncollectible|continue/i,
    preferMenu: true,
  },
  {
    name: "Charge",
    route: ({ edgeStates }) => `/billing/payments/${edgeStates.jpy_charge_id}`,
    trigger: /refund charge/i,
    confirm: /confirm|refund|continue/i,
    prepare: "refund",
    allowOffscreenConfirm: true,
  },
  {
    name: "Webhook",
    route: ({ operatorFlows }) => `/billing/webhooks/${operatorFlows.single_webhook_id}`,
    trigger: /replay webhook|replay delivery/i,
    confirm: /confirm|replay|continue/i,
  },
  {
    name: "Connect account",
    route: ({ edgeStates }) => `/billing/connect/${edgeStates.connect_account_id}`,
    trigger: /edit platform fee override|platform fee override/i,
    confirm: /confirm|save|update|continue/i,
  },
]);

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seedScenario(request, scenario) {
  const response = await request.post(`/__e2e__/seed/${scenario}`);
  expect(response.ok(), `seed ${scenario} should return 2xx`).toBeTruthy();
  return response.json();
}

async function seedPhase198(request) {
  const phase191 = await seedScenario(request, "phase191-matrix");
  const operatorFlows = await seedScenario(request, "operator-flows");
  const dashboard = await seedScenario(request, "dashboard");
  const edgeStates = await seedScenario(request, "edge-states");

  return { operatorFlows, dashboard, edgeStates, phase191 };
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}

async function openPhase198Route(page, request, routeBuilder) {
  await reset(request);
  const fixtures = await seedPhase198(request);
  const route = routeBuilder(fixtures);
  await login(page, route);
  return { fixtures, route };
}

async function assertNoHorizontalClipping(page, label) {
  await assertNoHorizontalClip(page, "#main-content, main, .ax-page", label);
}

async function assertLazyBottom(page, label) {
  await expect(page.locator("[data-ax-lazy-activity]"), `${label}: lazy Activity marker`).toHaveCount(1);
  await expect(page.locator("[data-ax-lazy-json]"), `${label}: lazy Raw data marker`).toHaveCount(1);

  await expect(
    page.locator("[data-ax-lazy-activity] .ax-timeline-list:visible"),
    `${label}: Activity does not eagerly render timeline rows`
  ).toHaveCount(0);
  await expect(
    page.locator("[data-ax-lazy-json] pre:visible"),
    `${label}: Raw data does not eagerly render JSON`
  ).toHaveCount(0);
}

async function assertInitialDetailInvariants(page, target) {
  const label = target.name;
  await expect(page.locator("h1"), `${label}: exactly one h1`).toHaveCount(1);
  await expect(page.locator("[data-ax-summary-list]"), `${label}: summary list`).toHaveCount(1);
  await expect(page.locator("[data-ax-related-resources]"), `${label}: one related strip`).toHaveCount(1);
  await assertLazyBottom(page, label);

  const actionBand = page.locator("[data-ax-action-band]");
  await expect(actionBand.locator("form:visible"), `${label}: no visible action-band forms`).toHaveCount(0);
  await expect(page.locator("[data-ax-action-drawer-form]:visible"), `${label}: no drawer forms on load`).toHaveCount(0);

  const primaryActions = page.locator("[data-ax-primary-action]:visible");
  expect(
    await primaryActions.count(),
    `${label}: DETAIL pages may expose at most two visible primary actions`
  ).toBeLessThanOrEqual(2);

  const overflowMenus = await page.locator("[data-ax-action-overflow-menu]:visible").count();
  expect(overflowMenus, `${label}: at most one visible action overflow menu`).toBeLessThanOrEqual(1);

  await expect(page.locator(".ax-kpi-grid").first(), `${label}: no top-level KPI grid`).toHaveCount(0);
  await assertNoHorizontalClipping(page, label);
}

async function assertCustomerPeerNav(page) {
  const observed = await page.evaluate(() => {
    const allowed = new Set(["Subscriptions", "Invoices", "Payments"]);
    const forbidden = new Set(["More", "Payment methods", "Entitlements", "Events", "Metadata"]);
    const peerNav = document.querySelector("nav[aria-label='Customer peer record sets']");
    if (!peerNav) return { found: false, labels: [], forbiddenLabels: [] };

    function visible(element) {
      const rect = element.getBoundingClientRect();
      const style = window.getComputedStyle(element);
      return style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
    }

    const visibleLabels = [...peerNav.querySelectorAll("a, button, [role='tab']")]
      .filter(visible)
      .map((element) => (element.textContent || "").replace(/\s+/g, " ").trim())
      .filter(Boolean);

    const labels = visibleLabels
      .map((label) => [...allowed].find((allowedLabel) => label === allowedLabel || label.startsWith(`${allowedLabel} `)))
      .filter(Boolean);

    return {
      found: true,
      labels,
      forbiddenLabels: visibleLabels.filter((label) =>
        [...forbidden].some((forbiddenLabel) => label === forbiddenLabel || label.startsWith(`${forbiddenLabel} `))
      ),
    };
  });

  expect(observed.found, "Customer peer navigation exists").toBe(true);
  expect(observed.labels, "Customer peer navigation labels").toEqual(["Subscriptions", "Invoices", "Payments"]);
  expect(observed.forbiddenLabels, "Customer peer navigation omits non-peer sets").toEqual([]);
}

async function assertRecoveryOrder(page) {
  await expect(page.locator("h1"), "Recovery: exactly one h1").toHaveCount(1);
  await expect(page.locator("[data-ax-recovery-hero]"), "Recovery: hero metric pair").toHaveCount(1);
  await expect(page.locator("[data-ax-recovery-work-queue]"), "Recovery: work queue").toHaveCount(1);
  await expect(page.locator("[data-ax-recovery-supporting-funnel]"), "Recovery: supporting funnel").toHaveCount(1);

  const order = await page.evaluate(() => {
    const hero = document.querySelector("[data-ax-recovery-hero]");
    const queue = document.querySelector("[data-ax-recovery-work-queue]");
    const funnel = document.querySelector("[data-ax-recovery-supporting-funnel]");

    if (!hero || !queue || !funnel) return { hasAll: false };

    return {
      hasAll: true,
      heroBeforeQueue: Boolean(hero.compareDocumentPosition(queue) & Node.DOCUMENT_POSITION_FOLLOWING),
      queueBeforeFunnel: Boolean(queue.compareDocumentPosition(funnel) & Node.DOCUMENT_POSITION_FOLLOWING),
    };
  });

  expect(order.hasAll, "Recovery markers should all be present").toBe(true);
  expect(order.heroBeforeQueue, "Recovery hero should precede work queue").toBe(true);
  expect(order.queueBeforeFunnel, "Recovery work queue should precede supporting funnel").toBe(true);
  await assertNoHorizontalClipping(page, "Recovery");
}

async function assertCampaignDetail(page) {
  await expect(page.locator("h1"), "Campaign: exactly one h1").toHaveCount(1);
  await expect(page.locator("[data-ax-summary-list]"), "Campaign: summary list").toHaveCount(1);
  await expect(page.locator(".ax-campaign-timeline"), "CampaignTimeline content").toBeVisible();
  await expect(page.locator(".ax-kpi-grid"), "Campaign: no top-level KPI grid").toHaveCount(0);
  await assertNoHorizontalClipping(page, "Campaign");
}

async function clickActionTrigger(page, flow) {
  const direct = page.getByRole("button", { name: flow.trigger }).first();
  if (!flow.preferMenu && (await direct.count()) > 0 && (await direct.isVisible())) {
    await direct.click();
    return;
  }

  const menu = page.locator("[data-ax-action-overflow-menu]").first();
  await expect(menu, `${flow.name}: overflow menu for secondary actions`).toBeVisible();
  await menu.click();

  const item = page.getByRole("menuitem", { name: flow.trigger }).first();
  await expect(item, `${flow.name}: matching menu item`).toBeVisible();
  await item.click();
}

async function confirmPointerClickMode(confirm, flow) {
  try {
    await assertTopPointerTarget(confirm, `${flow.name}: drawer confirm action`);
    return "pointer";
  } catch (error) {
    if (!flow.allowOffscreenConfirm || !String(error.message).includes('"offscreen":true')) {
      throw error;
    }

    return "dom";
  }
}

async function assertDrawerFlow(page, flow) {
  await expect(page.locator("[data-ax-action-band] form:visible"), `${flow.name}: no initial forms`).toHaveCount(0);

  await clickActionTrigger(page, flow);

  const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
  await expect(drawer, `${flow.name}: drawer opens after intent`).toBeVisible();

  if (flow.prepare === "refund") {
    const refundForm = drawer.locator("form[data-role='refund-form']").first();
    await expect(refundForm, `${flow.name}: refund preparation form`).toBeVisible();
    await refundForm.locator("input[name='amount_minor']").fill("1000");
    await refundForm.locator("input[name='reason']").fill("requested_by_customer");
    await refundForm.getByRole("button", { name: /review refund|continue/i }).click();
  }

  const confirm = drawer.getByRole("button", { name: flow.confirm }).first();
  await expect(confirm, `${flow.name}: drawer confirm action`).toBeVisible();
  await drawer.locator(".ax-detail-drawer-body").evaluate((body) => {
    body.scrollTop = body.scrollHeight;
  });
  await confirm.scrollIntoViewIfNeeded();
  const clickMode = await confirmPointerClickMode(confirm, flow);
  if (clickMode === "dom") {
    await confirm.focus();
  }
  await assertFocusWithin(page, drawer, `${flow.name}: drawer`);

  if (clickMode === "dom") {
    await confirm.evaluate((element) => element.click());
  } else {
    await confirm.click();
  }
  await expect(page.locator("body"), `${flow.name}: step-up challenge`).toContainText(
    /confirm your identity|verify your identity|step-up|verification code/i
  );
}

test.describe("Phase 198 propagated DETAIL contract", () => {
  for (const target of DETAIL_TARGETS) {
    test(`${target.name} initial render follows DETAIL markers in light and dark`, async ({
      page,
      request,
    }) => {
      await openPhase198Route(page, request, target.route);

      for (const theme of ["light", "dark"]) {
        await setPhase191Theme(page, theme);
        await assertInitialDetailInvariants(page, target);

        if (target.customerPeerNav) {
          await assertCustomerPeerNav(page);
        }
      }
    });
  }

  for (const flow of DRAWER_FLOW_TARGETS) {
    test(`${flow.name} action opens drawer and requires step-up before execution`, async ({
      page,
      request,
    }, testInfo) => {
      test.skip(
        testInfo.project.name !== "chromium-desktop",
        "Representative drawer flow checks run once on desktop"
      );

      await openPhase198Route(page, request, flow.route);
      await setPhase191Theme(page, "light");
      await assertDrawerFlow(page, flow);
    });
  }
});

test.describe("Phase 198 analytics propagation contract", () => {
  for (const target of ANALYTICS_TARGETS) {
    test(`${target.name} follows locked analytics/detail grammar`, async ({ page, request }) => {
      await openPhase198Route(page, request, target.route);
      await setPhase191Theme(page, "light");
      await target.assertion(page);
    });
  }
});
