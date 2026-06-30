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
  assertNoHorizontalClip,
  assertNoStaleOverlayState,
  assertRouteFocusAndScroll,
  assertTopPointerTarget,
  setPhase191Theme,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

const PHASE199_ROUTE_FLOWS = Object.freeze([
  {
    name: "Customer list to detail to invoice detail and back",
    route: () => "/billing/customers",
    steps: [
      { link: /E2E Phase 199 Boundary Customer/i, expectedAfterClick: /\/billing\/customers\/19900000-/ },
      { assertText: /status past_due/i },
      { link: /^Invoices 1$/i, expectedAfterClick: /tab=invoices/ },
      { link: /E2E-199-JPY-001/i, expectedAfterClick: /\/billing\/invoices\/19900000-/ },
      { assertText: /¥55,000|JPY/i },
      { back: /tab=invoices/ },
      { back: /\/billing\/customers\/19900000-/ },
    ],
  },
  {
    name: "Invoice list to detail to step-up and back",
    route: () => "/billing/invoices?view=all",
    steps: [
      { link: /E2E-199-JPY-001/i, expectedAfterClick: /\/billing\/invoices\/19900000-/ },
      { assertText: /¥55,000|JPY/i },
      { drawerStepUp: /Void invoice/i },
      { back: /\/billing\/invoices/ },
    ],
  },
  {
    name: "Webhook list to event drill to replay step-up and back",
    route: () => "/billing/webhooks?view=all",
    steps: [
      { link: /evt_e2e_phase199_dead/i, expectedAfterClick: /\/billing\/webhooks\/19900000-/ },
      { assertText: /Raw payload|Derived ledger rows/i },
      { link: /Event charge\.succeeded/i, expectedAfterClick: /\/billing\/events\/\d+/ },
      { assertText: /Source webhook|Charge 19900000-/i },
      { back: /\/billing\/webhooks\/19900000-/ },
      { drawerStepUp: /Replay webhook|Replay delivery/i },
      { back: /\/billing\/webhooks/ },
    ],
  },
  {
    name: "Recovery list to campaign to subscription detail and back",
    route: () => "/billing/analytics/recovery",
    steps: [
      { link: /phase199\.route-edge/i, expectedAfterClick: /\/billing\/analytics\/recovery\/subscriptions\/19900000-/ },
      { assertText: /Dunning Timeline|No dunning history/i },
      { link: /subscription detail/i, expectedAfterClick: /\/billing\/subscriptions\/19900000-/ },
      { assertText: /past_due|Payment methods|Subscription/i },
      { back: /\/billing\/analytics\/recovery\/subscriptions\/19900000-/ },
      { back: /\/billing\/analytics\/recovery/ },
    ],
  },
  {
    name: "Connect list to account detail to platform-fee step-up and back",
    route: () => "/billing/connect?view=all",
    steps: [
      { link: /acct_e2e_phase199_attention/i, expectedAfterClick: /\/billing\/connect\/19900000-/ },
      { assertText: /Needs attention|currently due: external_account/i },
      { drawerStepUp: /Edit platform fee override|Change platform fee override/i },
      { back: /\/billing\/connect/ },
    ],
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
]);

const COPY_ACTION_CONTEXT_TARGETS = Object.freeze([
  {
    name: "Invoice action menu",
    route: ({ edgeStates }) => `/billing/invoices/${edgeStates.jpy_invoice_id}`,
    openMenu: true,
    actions: [
      {
        visible: /Void invoice|Mark uncollectible/i,
        context: /E2E-199-JPY-001/i,
      },
    ],
  },
  {
    name: "Charge refund action",
    route: ({ operatorFlows }) => `/billing/payments/${operatorFlows.charge_id}`,
    actions: [
      {
        visible: /Refund charge/i,
        context: /ch_e2e_phase199_refund/i,
      },
    ],
  },
  {
    name: "Webhook replay action",
    route: ({ operatorFlows }) => `/billing/webhooks/${operatorFlows.single_webhook_id}`,
    actions: [
      {
        visible: /Replay webhook|Replay delivery/i,
        context: /evt_e2e_phase199_dead/i,
      },
    ],
  },
  {
    name: "Connect platform-fee action",
    route: ({ edgeStates }) => `/billing/connect/${edgeStates.connect_account_id}`,
    actions: [
      {
        visible: /Edit platform fee override|Change platform fee override/i,
        context: /acct_e2e_phase199_attention/i,
      },
    ],
  },
  {
    name: "Subscription action menu",
    route: ({ dashboard }) => `/billing/subscriptions/${dashboard.subscription_id}`,
    openMenu: true,
    actions: [
      {
        visible: /Update quantity|Add item|Pause collection|Cancel renewal/i,
        context: /sub_e2e_phase199_active/i,
      },
    ],
  },
  {
    name: "Read-only event detail",
    route: ({ phase199 }) => `/billing/events/${phase199.event_id}`,
    readOnly: true,
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
  const phase199 = await seedScenario(request, "phase199-interaction-matrix");

  return {
    phase199,
    dashboard: phase199,
    edgeStates: phase199,
    operatorFlows: phase199,
    overflow: phase199,
    phase191: phase199,
  };
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

async function assertActionHasObjectContext(page, action, label = "action") {
  const candidates = await page.locator("a, button, [role='menuitem']").evaluateAll((elements) =>
    elements
      .filter((element) => {
        const rect = element.getBoundingClientRect();
        const style = window.getComputedStyle(element);
        return style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
      })
      .map((element) => ({
        visibleText: (element.innerText || "").replace(/\s+/g, " ").trim(),
        fullText: (element.textContent || "").replace(/\s+/g, " ").trim(),
        aria: element.getAttribute("aria-label") || "",
      }))
  );

  const match = candidates.find(
    (candidate) =>
      action.visible.test(candidate.visibleText) ||
      action.visible.test(candidate.fullText) ||
      action.visible.test(candidate.aria)
  );

  expect(match, `${label}: visible action ${action.visible} exists`).toBeTruthy();
  expect(`${match.aria} ${match.fullText}`, `${label}: object/action context`).toMatch(action.context);
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
  if (!target.preferMenu) {
    if ((await direct.count()) > 0 && (await direct.isVisible().catch(() => false))) {
      await direct.click();
      return;
    }

    const textButton = page.locator("button").filter({ hasText: target.trigger }).first();
    if ((await textButton.count()) > 0 && (await textButton.isVisible().catch(() => false))) {
      await textButton.click();
      return;
    }
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

function assertPhase199FixtureContract(fixtures) {
  expect(fixtures.phase199.namespace, "Phase 199 fixture namespace").toBe("e2e_phase199");
  expect(fixtures.phase199.edge_data.long_email, "Phase 199 long route email").toContain("route-edge");
  expect(fixtures.phase199.edge_data.long_processor_id, "Phase 199 long processor id").toContain("proc_phase199_");
  expect(fixtures.phase199.edge_data.raw_payload_bytes, "Phase 199 overflow payload size").toBeGreaterThan(1024);
}

async function visible(locator) {
  return (await locator.count()) > 0 && (await locator.isVisible().catch(() => false));
}

async function drawerPrimaryAction(drawer, step) {
  let button = drawer
    .locator("[data-role='confirm-action'], [data-role='confirm-replay'], [data-ax-action-drawer-confirm]")
    .first();
  if (!(await visible(button))) {
    button = drawer
      .getByRole("button", {
        name: step.confirm || /^(?!Close$)(?!Cancel$).+/i,
      })
      .first();
  }

  return button;
}

async function assertDrawerStepUp(page, flow, step) {
  await clickActionTrigger(page, {
    name: flow.name,
    trigger: step.drawerStepUp,
  });

  const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
  await expect(drawer, `${flow.name}: drawer opens`).toBeVisible();
  await assertOverlayPanel(page, { name: flow.name }, drawer);

  let confirm = await drawerPrimaryAction(drawer, step);
  await expect(confirm, `${flow.name}: drawer confirm action`).toBeVisible();
  await confirm.scrollIntoViewIfNeeded();
  await confirm.click();

  const modal = page.locator("#ax-overlay-root [data-presentation='modal']").first();
  let modalOpened = true;
  try {
    await expect(modal, `${flow.name}: step-up modal opens`).toBeVisible({ timeout: 1_000 });
  } catch (_error) {
    modalOpened = false;
  }

  if (!modalOpened) {
    await expect(drawer, `${flow.name}: staged confirmation`).toContainText(/Confirm action|Step-up required/i);
    confirm = await drawerPrimaryAction(drawer, { confirm: /Confirm|Replay|Void invoice|Save|Update/i });
    await expect(confirm, `${flow.name}: staged drawer confirm action`).toBeVisible();
    await confirm.click();
  }
  await expect(modal, `${flow.name}: step-up modal opens`).toBeVisible();
  await assertOverlayPanel(page, { name: `${flow.name}: step-up` }, modal);
  await page.keyboard.press("Escape");
  try {
    await assertNoStaleOverlayState(page, `${flow.name}: step-up close`);
  } catch (error) {
    const close = page.locator("#ax-overlay-root").getByRole("button", { name: /Close|Cancel/i }).first();
    if (!(await visible(close))) throw error;

    await close.click();
    await assertNoStaleOverlayState(page, `${flow.name}: drawer cleanup`);
  }
}

async function runRouteFlowStep(page, flow, step) {
  if (step.assertText) {
    await expect(page.locator("main"), `${flow.name}: route text`).toContainText(step.assertText);
    return;
  }

  if (step.drawerStepUp) {
    await assertDrawerStepUp(page, flow, step);
    await assertRouteFocusAndScroll(page, `${flow.name}: after step-up close`);
    return;
  }

  if (step.back) {
    await page.goBack();
    await expect(page, `${flow.name}: browser back restores route`).toHaveURL(step.back);
    await assertRouteFocusAndScroll(page, `${flow.name}: after back`);
    return;
  }

  const link = step.linkSelector
    ? page.locator(step.linkSelector).first()
    : page.getByRole("link", { name: step.link }).first();
  await expect(link, `${flow.name}: drill link`).toBeVisible();
  await link.click();
  await expect(page, `${flow.name}: routed to related detail`).toHaveURL(step.expectedAfterClick);
  await assertRouteFocusAndScroll(page, `${flow.name}: related detail`);
}

async function assertDismissalParity(page, target) {
  const drawer = await openDrawerTarget(page, target);
  await assertOverlayPanel(page, target, drawer);

  await page.keyboard.press("Escape");
  await assertNoStaleOverlayState(page, `${target.name}: Escape`);

  const reopened = await openDrawerTarget(page, target);
  await assertOverlayPanel(page, target, reopened);
  const backdrop = page.locator("#ax-overlay-root [data-ax-overlay-backdrop]").first();
  await expect(backdrop, `${target.name}: backdrop`).toBeVisible();
  await backdrop.click({ position: { x: 8, y: 8 } });
  await assertNoStaleOverlayState(page, `${target.name}: backdrop`);
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
    await assertNoStaleOverlayState(page, "StepUp Escape");
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
    assertPhase199FixtureContract(fixtures);

    for (const flow of PHASE199_ROUTE_FLOWS) {
      await login(page, flow.route(fixtures));
      await setPhase191Theme(page, "light");
      await assertRouteFocusAndScroll(page, flow.name);

      for (const step of flow.steps) {
        await runRouteFlowStep(page, flow, step);
      }
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

    for (const target of COPY_ACTION_CONTEXT_TARGETS) {
      await login(page, target.route(fixtures));
      await setPhase191Theme(page, "light");

      if (target.readOnly) {
        await expect(page.locator("[data-ax-action-band]"), `${target.name}: no action band`).toHaveCount(0);
        await expect(page.locator("[data-ax-action-overflow-menu]"), `${target.name}: no action menu`).toHaveCount(0);
        await assertActionContextLabels(page, target.name);
        continue;
      }

      if (target.openMenu) {
        const menu = page.locator("[data-ax-action-overflow-menu]").first();
        await expect(menu, `${target.name}: action menu`).toBeVisible();
        await menu.click();
      }

      for (const action of target.actions) {
        await assertActionHasObjectContext(page, action, target.name);
      }

      if (target.openMenu) {
        await page.keyboard.press("Escape");
      }
    }
  });
});
