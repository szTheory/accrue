/**
 * Phase 199 - cross-cutting interaction, overlay, fixture, and copy contract.
 *
 * This spec is intentionally explicit: target arrays name the representative
 * routes and surfaces instead of introducing a broad interaction abstraction.
 */

const { test, expect } = require("@playwright/test");

const {
  assertFocusWithin,
  assertFloatingAdjacentToTrigger,
  assertNoBodyFocus,
  assertNoHorizontalClip,
  assertScrollReachable,
  assertTopPointerTarget,
  setPhase191Theme,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

const PHASE199_ROUTE_FLOWS = Object.freeze([
  {
    name: "Customer to invoice detail and back",
    route: ({ dashboard }) => `/billing/customers/${dashboard.customer_id}`,
    beforeLink: /Invoices \d+/i,
    link: /E2E-001|in_e2e_dashboard/i,
    expectedAfterClick: /\/billing\/invoices\//,
  },
  {
    name: "Webhook to related event drill",
    route: ({ operatorFlows }) => `/billing/webhooks/${operatorFlows.single_webhook_id}`,
    link: /charge\.succeeded|Activity feed|Events/i,
    expectedAfterClick: /\/billing\/events|source_webhook_event_id=/,
    optionalLink: true,
  },
  {
    name: "Recovery to campaign detail",
    route: () => "/billing/analytics/recovery",
    linkSelector: "main table a",
    expectedAfterClick: /\/billing\/analytics\/recovery\/subscriptions\//,
  },
  {
    name: "Connect account detail to platform-fee drawer",
    route: ({ edgeStates }) => `/billing/connect/${edgeStates.connect_account_id}`,
    openDrawer: /edit platform fee override|platform fee override/i,
  },
]);

const OVERLAY_FLOW_TARGETS = Object.freeze([
  {
    name: "Subscription",
    route: ({ dashboard }) => `/billing/subscriptions/${dashboard.subscription_id}`,
    trigger: /update quantity|add item|update item quantity|remove item|pause collection|resume/i,
    preferMenu: true,
  },
  {
    name: "Invoice",
    route: ({ edgeStates }) => `/billing/invoices/${edgeStates.jpy_invoice_id}`,
    trigger: /void invoice|mark uncollectible/i,
    preferMenu: true,
  },
  {
    name: "Charge",
    route: ({ operatorFlows }) => `/billing/payments/${operatorFlows.charge_id}`,
    trigger: /refund charge/i,
  },
  {
    name: "Webhook",
    route: ({ operatorFlows }) => `/billing/webhooks/${operatorFlows.single_webhook_id}`,
    trigger: /replay webhook|replay delivery/i,
  },
  {
    name: "Connect",
    route: ({ edgeStates }) => `/billing/connect/${edgeStates.connect_account_id}`,
    trigger: /edit platform fee override|platform fee override/i,
  },
  {
    name: "Customer payment-method",
    route: ({ dashboard }) => `/billing/customers/${dashboard.customer_id}`,
    trigger: /set default payment method|delete payment method/i,
    requiresPhase199Fixture: true,
  },
  {
    name: "Command palette",
    route: () => "/billing",
    kind: "command-palette",
  },
  {
    name: "StepUp representative",
    route: ({ operatorFlows }) => `/billing/webhooks/${operatorFlows.single_webhook_id}`,
    trigger: /replay webhook|replay delivery/i,
    kind: "step-up",
  },
]);

const FLOATING_TARGETS = Object.freeze([
  {
    name: "Action menu dropdown",
    route: ({ dashboard }) => `/billing/subscriptions/${dashboard.subscription_id}`,
    trigger: "[data-ax-action-overflow-menu]",
    panel: "[data-floating-panel='dropdown']",
  },
  {
    name: "Theme picker",
    route: () => "/billing",
    trigger: "[data-theme-target='system']",
    panel: ".ax-theme-picker",
    alreadyOpen: true,
  },
  {
    name: "Command palette",
    route: () => "/billing",
    trigger: "[data-command-palette-trigger]",
    panel: ".ax-command-palette",
  },
]);

const PHASE199_FLOATING_VIEWPORTS = Object.freeze([
  { name: "phone-320", width: 320, height: 844 },
  { name: "phone-375", width: 375, height: 844 },
  { name: "tablet-768", width: 768, height: 1024 },
  { name: "desktop-1024", width: 1024, height: 900 },
  { name: "desktop-1440", width: 1440, height: 1000 },
]);

const THEME_CASES = Object.freeze([
  {
    name: "cookie wins over localStorage",
    cookie: "dark",
    localStorage: "light",
    expected: "dark",
  },
  {
    name: "localStorage applies when cookie is absent",
    localStorage: "light",
    expected: "light",
  },
  {
    name: "system persists without legacy key",
    localStorage: "system",
    expected: "system",
  },
]);

const COPY_TARGETS = Object.freeze([
  {
    name: "Customers filtered empty",
    route: "/billing/customers?q=phase199-no-match",
    locator: "[data-role='empty-state'], .ax-empty-state",
  },
  {
    name: "Invoices filtered empty",
    route: "/billing/invoices?view=all&q=phase199-no-match",
    locator: "[data-role='empty-state'], .ax-empty-state",
  },
  {
    name: "Command palette no-results",
    route: "/billing",
    query: "phase199-no-match",
    locator: ".ax-command-palette-no-results",
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

async function seedPhase199(request) {
  await reset(request);
  const phase191 = await seedScenario(request, "phase191-matrix");
  const operatorFlows = await seedScenario(request, "operator-flows");
  const dashboard = await seedScenario(request, "dashboard");
  const edgeStates = await seedScenario(request, "edge-states");
  const overflow = await seedScenario(request, "overflow");

  return { dashboard, edgeStates, operatorFlows, overflow, phase191 };
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}

async function openPhase199Route(page, request, routeBuilder) {
  const fixtures = await seedPhase199(request);
  const route = routeBuilder(fixtures);
  await login(page, route);
  return { fixtures, route };
}

async function assertOverlayRoot(page) {
  await expect(page.locator("#ax-overlay-root"), "exactly one overlay root").toHaveCount(1);

  const root = await page.locator("#ax-overlay-root").evaluate((element) => ({
    parent: element.parentElement?.tagName,
    nestedInShell: Boolean(element.closest("#accrue-admin-shell")),
  }));

  expect(root.parent, "overlay root should be body-level").toBe("BODY");
  expect(root.nestedInShell, "overlay root should not live inside the inert shell").toBe(false);
}

async function assertNoGhostOverlay(page, label = "overlay close") {
  await expect(
    page.locator("#ax-overlay-root [data-ax-overlay-shell]"),
    `${label}: no overlay shell remains`
  ).toHaveCount(0);
  await expect(
    page.locator("#ax-overlay-root [data-ax-overlay-backdrop]"),
    `${label}: no backdrop remains`
  ).toHaveCount(0);
  await expect(
    page.locator("#accrue-admin-shell"),
    `${label}: shell inert is restored`
  ).not.toHaveAttribute("inert", "");
}

async function assertDrawerGeometry(page, drawer, label = "drawer") {
  const geometry = await drawer.locator("[data-ax-overlay-panel]").first().evaluate((panel) => {
    const rect = panel.getBoundingClientRect();
    return {
      left: rect.left,
      right: rect.right,
      top: rect.top,
      bottom: rect.bottom,
      width: rect.width,
      height: rect.height,
      viewport: { width: window.innerWidth, height: window.innerHeight },
    };
  });

  if (geometry.viewport.width < 768) {
    expect(geometry.bottom, `${label}: mobile drawer should bottom-dock`).toBeCloseTo(
      geometry.viewport.height,
      0
    );
    expect(geometry.width, `${label}: mobile drawer should span most of the viewport`).toBeGreaterThan(
      geometry.viewport.width * 0.9
    );
    expect(geometry.top, `${label}: mobile sheet should leave a visible top gutter`).toBeGreaterThanOrEqual(0);
  } else {
    expect(geometry.right, `${label}: desktop drawer should right-dock`).toBeCloseTo(
      geometry.viewport.width,
      0
    );
    expect(geometry.left, `${label}: desktop drawer should not cover the full page`).toBeGreaterThan(0);
    expect(geometry.height, `${label}: desktop drawer should fill vertical space`).toBeGreaterThan(
      geometry.viewport.height * 0.9
    );
  }
}

async function floatingBounds(target) {
  return target.evaluate((element) => {
    const rect = element.getBoundingClientRect();
    const style = window.getComputedStyle(element);
    return {
      visible: style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0,
      left: rect.left,
      top: rect.top,
      right: rect.right,
      bottom: rect.bottom,
      viewport: { width: window.innerWidth, height: window.innerHeight },
      transformOrigin: style.transformOrigin,
    };
  });
}

async function assertFloatingBounds(page, target, label = "floating panel") {
  await expect
    .poll(
      async () => {
        const result = await floatingBounds(target);
        return (
          result.visible &&
          result.left >= 0 &&
          result.top >= 0 &&
          result.right <= result.viewport.width &&
          result.bottom <= result.viewport.height
        );
      },
      { message: `${label}: geometry settles inside viewport` }
    )
    .toBe(true);

  const result = await floatingBounds(target);

  expect(result.visible, `${label}: visible`).toBe(true);
  expect(result.left, `${label}: not clipped left`).toBeGreaterThanOrEqual(0);
  expect(result.top, `${label}: not clipped top`).toBeGreaterThanOrEqual(0);
  expect(result.right, `${label}: not clipped right`).toBeLessThanOrEqual(result.viewport.width);
  expect(result.bottom, `${label}: not clipped bottom`).toBeLessThanOrEqual(result.viewport.height);
  expect(result.transformOrigin, `${label}: transform-origin declared`).not.toBe("");
}

async function pinDropdownTriggerNearLowerRight(page, trigger) {
  await trigger.evaluate((element) => {
    Object.assign(element.style, {
      position: "fixed",
      right: "0",
      bottom: "8px",
      width: "auto",
      zIndex: "9999",
    });
  });
}

async function assertThemePersistence(page, themeCase) {
  await page.context().clearCookies();
  await page.addInitScript((value) => {
    window.localStorage.removeItem("accrue_admin_theme");
    window.localStorage.removeItem("accrue_theme");
    if (value) window.localStorage.setItem("accrue_theme", value);
  }, themeCase.localStorage || null);

  if (themeCase.cookie) {
    await page.context().addCookies([
      {
        name: "accrue_theme",
        value: themeCase.cookie,
        url: `http://127.0.0.1:${process.env.ACCRUE_ADMIN_E2E_PORT || "4017"}`,
      },
    ]);
  }

  await page.emulateMedia({ colorScheme: themeCase.expected === "system" ? "dark" : null });
  await login(page, "/billing/customers");

  await expect(page.locator("html"), `${themeCase.name}: html data-theme`).toHaveAttribute(
    "data-theme",
    themeCase.expected
  );
  await expect
    .poll(() => page.evaluate(() => window.localStorage.getItem("accrue_theme")), {
      message: `${themeCase.name}: production theme key persisted`,
    })
    .toBe(themeCase.expected);
  await expect
    .poll(() => page.evaluate(() => window.localStorage.getItem("accrue_admin_theme")), {
      message: `${themeCase.name}: legacy visual-test key is not used`,
    })
    .toBeNull();

  if (themeCase.expected === "system") {
    await expect
      .poll(() => page.locator("html").evaluate((element) => getComputedStyle(element).colorScheme), {
        message: `${themeCase.name}: system dark emulation resolves through CSS`,
      })
      .toContain("dark");
  }
}

async function assertThemePickerReloadPersistence(page) {
  await page.context().clearCookies();
  await login(page, "/billing/customers");
  await page.evaluate(() => {
    window.localStorage.removeItem("accrue_admin_theme");
    window.localStorage.removeItem("accrue_theme");
    document.cookie = "accrue_theme=; path=/; max-age=0";
  });
  await page.reload();

  await page.locator("[data-theme-target='dark']").click();
  await expect(page.locator("html"), "theme picker sets html data-theme").toHaveAttribute(
    "data-theme",
    "dark"
  );
  await expect
    .poll(() => page.evaluate(() => window.localStorage.getItem("accrue_theme")), {
      message: "theme picker writes production localStorage key",
    })
    .toBe("dark");

  const themeCookie = (await page.context().cookies()).find((cookie) => cookie.name === "accrue_theme");
  expect(themeCookie?.value, "theme picker writes production cookie key").toBe("dark");

  await page.reload();
  await expect(page.locator("html"), "theme picker choice survives reload").toHaveAttribute(
    "data-theme",
    "dark"
  );
}

async function assertRouteFocusAndScroll(page, label) {
  await assertNoBodyFocus(page, `${label}: route focus`);
  await assertNoHorizontalClip(page, "#main-content, main, .ax-page", `${label}: route clipping`);

  const scrollContainers = page.locator(
    ".ax-detail-drawer-body:visible, .ax-data-table-shell:visible, [data-role='card-list']:visible, main:visible"
  );
  const first = scrollContainers.first();
  if ((await first.count()) > 0) {
    await assertScrollReachable(first, `${label}: primary scroll container`);
  }
}

async function assertActionContextLabels(page, label = "action labels") {
  const compactActions = await page.locator("a, button, [role='menuitem']").evaluateAll((elements) =>
    elements
      .filter((element) => {
        const rect = element.getBoundingClientRect();
        const style = window.getComputedStyle(element);
        return style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
      })
      .map((element) => ({
        text: (element.textContent || "").replace(/\s+/g, " ").trim(),
        aria: element.getAttribute("aria-label") || "",
      }))
      .filter((item) => /^(Change|View)$/i.test(item.text) && !item.aria)
  );

  expect(compactActions, `${label}: compact Change/View labels include hidden or aria context`).toEqual([]);
}

async function bodyScrollTop(page) {
  return page.evaluate(() => document.scrollingElement?.scrollTop || window.scrollY || 0);
}

async function assertBodyScrollStable(page, label) {
  const before = await bodyScrollTop(page);
  await page.mouse.wheel(0, 640);
  const after = await bodyScrollTop(page);
  expect(after, `${label}: body scroll should remain locked while overlay is open`).toBe(before);
}

async function clickActionTrigger(page, target) {
  const direct = page.getByRole("button", { name: target.trigger }).first();
  if (!target.preferMenu && (await direct.count()) > 0 && (await direct.isVisible())) {
    await direct.click();
    return;
  }

  const menu = page.locator("[data-ax-action-overflow-menu]").first();
  await expect(menu, `${target.name}: overflow action menu`).toBeVisible();
  await menu.click();

  const item = page.getByRole("menuitem", { name: target.trigger }).first();
  await expect(item, `${target.name}: menu item`).toBeVisible();
  await item.click();
}

async function openDrawerTarget(page, target) {
  await clickActionTrigger(page, target);
  const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
  await expect(drawer, `${target.name}: drawer opens`).toBeVisible();
  return drawer;
}

async function assertOverlayPanel(page, target, overlay) {
  await assertOverlayRoot(page);
  await expect(page.locator("#accrue-admin-shell"), `${target.name}: shell inert`).toHaveAttribute("inert", "");
  await assertBodyScrollStable(page, target.name);

  const panel = overlay.locator("[data-ax-overlay-panel]").first();
  const firstFocusable = overlay.locator("input, select, textarea, button, a[href]").first();
  await expect(panel, `${target.name}: overlay panel`).toBeVisible();
  await expect(firstFocusable, `${target.name}: focusable control`).toBeVisible();
  await firstFocusable.focus();
  await assertTopPointerTarget(firstFocusable, `${target.name}: focusable control`);
  await assertFocusWithin(page, overlay, `${target.name}: overlay focus`);
}

async function assertDismissalParity(page, target) {
  const drawer = await openDrawerTarget(page, target);
  await assertOverlayPanel(page, target, drawer);

  await page.keyboard.press("Escape");
  await assertNoGhostOverlay(page, `${target.name}: Escape`);

  const reopened = await openDrawerTarget(page, target);
  await assertOverlayPanel(page, target, reopened);
  const backdrop = page.locator("#ax-overlay-root [data-ax-overlay-backdrop]").first();
  await expect(backdrop, `${target.name}: backdrop`).toBeVisible();
  await backdrop.click({ position: { x: 8, y: 8 } });
  await assertNoGhostOverlay(page, `${target.name}: backdrop`);
}

async function openCommandPalette(page) {
  await page.locator("[data-command-palette-trigger]").first().click();
  const palette = page.locator(".ax-command-palette").first();
  await expect(palette, "command palette opens").toBeVisible();
  return palette;
}

test.describe("Phase 199 interaction and overlay contract", () => {
  test("@phase199 @overlay overlay targets declare the required cross-page representatives", async () => {
    expect(OVERLAY_FLOW_TARGETS.map((target) => target.name)).toEqual([
      "Subscription",
      "Invoice",
      "Charge",
      "Webhook",
      "Connect",
      "Customer payment-method",
      "Command palette",
      "StepUp representative",
    ]);
  });

  for (const target of OVERLAY_FLOW_TARGETS.filter(
    (candidate) => !candidate.requiresPhase199Fixture && !candidate.kind
  )) {
    test(`@phase199 @overlay ${target.name} drawer is portaled, hit-testable, inert, and dismisses cleanly`, async ({
      page,
      request,
    }, testInfo) => {
      test.skip(testInfo.project.name !== "chromium-desktop", "drawer matrix runs once on desktop");

      await openPhase199Route(page, request, target.route);
      await setPhase191Theme(page, "light");
      await assertDismissalParity(page, target);
    });
  }

  test("@phase199 @overlay command palette behaves as an overlay-equivalent named wrapper", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "command palette overlay check runs once");

    await openPhase199Route(page, request, () => "/billing");
    const trigger = page.locator("[data-command-palette-trigger]").first();
    await trigger.focus();
    const palette = await openCommandPalette(page);
    await assertFloatingBounds(page, palette, "Command palette");
    await assertTopPointerTarget(palette.locator("input").first(), "Command palette input");
    await assertFocusWithin(page, palette, "Command palette");

    await page.keyboard.press("Escape");
    await expect(palette, "command palette closes on Escape").toBeHidden();
    await expect(trigger, "command palette restores trigger focus").toBeFocused();
  });

  test("@phase199 @overlay step-up modal uses the overlay root and restores cleanly", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "step-up representative runs once");

    const target = OVERLAY_FLOW_TARGETS.find((candidate) => candidate.kind === "step-up");
    await openPhase199Route(page, request, target.route);
    await setPhase191Theme(page, "light");

    const drawer = await openDrawerTarget(page, target);
    const confirm = drawer
      .locator("[data-role='confirm-action'], [data-role='confirm-replay'], [data-ax-action-drawer-confirm]")
      .first();
    await expect(confirm, "drawer confirm action").toBeVisible();
    await confirm.scrollIntoViewIfNeeded();
    await confirm.click();

    const modal = page.locator("#ax-overlay-root [data-presentation='modal']").first();
    await expect(modal, "step-up modal opens").toBeVisible();
    await assertOverlayPanel(page, { name: "StepUp" }, modal);
    await page.keyboard.press("Escape");
    await assertNoGhostOverlay(page, "StepUp Escape");
  });

  test("@phase199 @motion drawer geometry matches desktop right-dock and mobile bottom-sheet contracts", async ({
    page,
    request,
  }) => {
    const target = OVERLAY_FLOW_TARGETS[0];
    await openPhase199Route(page, request, target.route);
    await setPhase191Theme(page, "light");

    const drawer = await openDrawerTarget(page, target);
    await assertDrawerGeometry(page, drawer, "Subscription drawer");
    await assertFocusWithin(page, drawer, "Subscription drawer focus");
  });

  test("@phase199 @theme production accrue_theme persistence has no legacy-key dependency", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "theme persistence matrix runs once");

    await seedPhase199(request);
    for (const themeCase of THEME_CASES) {
      await assertThemePersistence(page, themeCase);
    }
  });

  test("@phase199 @theme theme picker writes accrue_theme and survives reload", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "theme picker persistence runs once");

    await seedPhase199(request);
    await assertThemePickerReloadPersistence(page);
  });

  test("@phase199 @affordance floating panels stay viewport-bound and non-modal controls stay non-interactive", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "affordance matrix runs once");

    const fixtures = await seedPhase199(request);

    for (const target of FLOATING_TARGETS) {
      await login(page, target.route(fixtures));
      await setPhase191Theme(page, "light");

      if (!target.alreadyOpen) {
        await page.locator(target.trigger).first().click();
      }

      const panel = page.locator(target.panel).first();
      await expect(panel, `${target.name}: floating panel`).toBeVisible();
      await assertFloatingBounds(page, panel, target.name);
    }

    await login(page, "/billing/customers?q=phase199-no-match");
    const empty = page.locator("[data-role='empty-state'], .ax-empty-state").first();
    await expect(empty, "filtered-empty hero").toBeVisible();
    const affordance = await empty.evaluate((element) => {
      const style = window.getComputedStyle(element);
      return {
        role: element.getAttribute("role"),
        cursor: style.cursor,
        phxClick: element.getAttribute("phx-click"),
      };
    });

    expect(affordance.role, "empty hero should not masquerade as a button").not.toBe("button");
    expect(affordance.cursor, "empty hero should not use pointer cursor").not.toBe("pointer");
    expect(affordance.phxClick, "empty hero should not carry click handler").toBeNull();
  });

  test("@phase199 @affordance action menu stays adjacent and bounded at locked viewport edges", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "viewport matrix is driven manually");

    const fixtures = await seedPhase199(request);

    for (const viewport of PHASE199_FLOATING_VIEWPORTS) {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });
      await login(page, `/billing/subscriptions/${fixtures.dashboard.subscription_id}`);
      await setPhase191Theme(page, "light");

      const trigger = page.locator("[data-ax-action-overflow-menu]").first();
      await expect(trigger, `${viewport.name}: action menu trigger`).toBeVisible();
      await pinDropdownTriggerNearLowerRight(page, trigger);
      await trigger.locator("summary").click();

      const panel = page.locator("[data-floating-panel='dropdown']").first();
      await expect(panel, `${viewport.name}: dropdown panel`).toBeVisible();
      await expect
        .poll(
          () => trigger.evaluate((element) => element.dataset.floatingPlacement || ""),
          { message: `${viewport.name}: dropdown placement settles` }
        )
        .toMatch(/^(top|bottom)$/);
      await assertFloatingBounds(page, panel, `${viewport.name}: action menu`);
      await assertFloatingAdjacentToTrigger(page, trigger, panel, `${viewport.name}: action menu`);

      await page.keyboard.press("Escape");
      await expect(panel, `${viewport.name}: dropdown panel closes`).toBeHidden();
    }
  });

  test("@phase199 @fixture deterministic route flows preserve focus, scroll, clipping, and back navigation", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "fixture route flows run once");

    const fixtures = await seedPhase199(request);

    for (const flow of PHASE199_ROUTE_FLOWS) {
      await login(page, flow.route(fixtures));
      await setPhase191Theme(page, "light");
      await assertRouteFocusAndScroll(page, flow.name);

      if (flow.openDrawer) {
        await clickActionTrigger(page, {
          name: flow.name,
          trigger: flow.openDrawer,
        });
        const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
        await expect(drawer, `${flow.name}: drawer`).toBeVisible();
        await assertOverlayPanel(page, { name: flow.name }, drawer);
        await page.keyboard.press("Escape");
        await assertNoGhostOverlay(page, `${flow.name}: drawer close`);
        continue;
      }

      if (flow.beforeLink) {
        const nav = page.getByRole("link", { name: flow.beforeLink }).first();
        await expect(nav, `${flow.name}: peer navigation`).toBeVisible();
        await nav.click();
      }

      const beforeDrillUrl = page.url();
      const link = flow.linkSelector
        ? page.locator(flow.linkSelector).first()
        : page.getByRole("link", { name: flow.link }).first();
      if (flow.optionalLink && (await link.count()) === 0) continue;

      await expect(link, `${flow.name}: drill link`).toBeVisible();
      await link.click();
      await expect(page, `${flow.name}: routed to related detail`).toHaveURL(flow.expectedAfterClick);
      await assertRouteFocusAndScroll(page, `${flow.name}: related detail`);
      await page.goBack();
      await expect(page, `${flow.name}: browser back restores route`).toHaveURL(
        new RegExp(beforeDrillUrl.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
      );
      await assertRouteFocusAndScroll(page, `${flow.name}: after back`);
    }
  });

  test("@phase199 @copy empty-state and repeated action labels use state-specific copy and hidden context", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "copy contract runs once");

    await seedPhase199(request);

    for (const target of COPY_TARGETS) {
      await login(page, target.route);
      await setPhase191Theme(page, "light");

      if (target.query) {
        const palette = await openCommandPalette(page);
        await palette.locator("input").fill(target.query);
      }

      const copySurface = page.locator(target.locator).first();
      await expect(copySurface, `${target.name}: copy surface`).toBeVisible();
      await expect(copySurface, `${target.name}: avoid generic no-results copy`).not.toContainText(
        /^No results(?: found)?/i
      );
    }

    const fixtures = await seedPhase199(request);
    await login(page, `/billing/subscriptions/${fixtures.dashboard.subscription_id}`);
    await setPhase191Theme(page, "light");
    await page.locator("[data-ax-action-overflow-menu]").first().click();
    await assertActionContextLabels(page, "Subscription repeated actions");
  });
});
