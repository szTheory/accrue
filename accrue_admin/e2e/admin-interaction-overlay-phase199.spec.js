/**
 * Phase 199 - cross-cutting interaction, overlay, fixture, and copy contract.
 *
 * This spec is intentionally explicit: target arrays name the representative
 * routes and surfaces instead of introducing a broad interaction abstraction.
 */

const fs = require("fs");
const path = require("path");
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

const COPY_STRINGS = JSON.parse(
  fs.readFileSync(
    path.join(
      __dirname,
      "..",
      "..",
      "examples",
      "accrue_host",
      "e2e",
      "generated",
      "copy_strings.json"
    ),
    "utf8"
  )
);

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
      {
        linkHref: ({ edgeStates }) => `/billing/analytics/recovery/subscriptions/${edgeStates.recovery_subscription_id}`,
        linkAccessibleName: /phase199\.route-edge/i,
        expectedAfterClick: /\/billing\/analytics\/recovery\/subscriptions\/19900000-/,
      },
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
  {
    name: "invalid localStorage uses the system fallback",
    localStorage: "neon",
    expected: "system",
  },
  {
    name: "absent preference uses the system fallback",
    expected: "system",
  },
]);

const COPY_TARGETS = Object.freeze([
  {
    name: "Customers filtered empty",
    route: "/billing/customers?q=phase199-no-match",
    locator: "[data-role='empty-state'], .ax-empty-state",
    fixtureKey: "data_table_clear_filters_label",
  },
  {
    name: "Invoices filtered empty",
    route: "/billing/invoices?view=all&q=phase199-no-match",
    locator: "[data-role='empty-state'], .ax-empty-state",
    fixtureKey: "data_table_clear_filters_label",
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

async function seedPhase241Reviews(request) {
  const response = await request.post("/__e2e__/seed/phase241-review-matrix");
  expect(response.ok(), "Phase 241 disposable review matrix seeds").toBeTruthy();
  return response.json();
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
  if (themeCase.expected !== "forced") {
    await expect(page.locator(`[data-theme-target='${themeCase.expected}']`), `${themeCase.name}: one selected preference`)
      .toHaveAttribute("aria-checked", "true");
  }
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

async function assertSystemThemeTracksAppearance(page) {
  const systemOption = page.locator("[data-theme-target='system']");
  const effectiveCanvas = () =>
    page.locator("html").evaluate((element) => getComputedStyle(element).backgroundColor);

  await page.emulateMedia({ colorScheme: "light" });
  await systemOption.click();
  await expect(systemOption).toHaveAttribute("aria-checked", "true");
  await expect(page.locator("html")).toHaveAttribute("data-theme", "system");
  const lightCanvas = await effectiveCanvas();

  await page.emulateMedia({ colorScheme: "dark" });
  await expect.poll(effectiveCanvas, { message: "System preference applies the dark canvas" }).not.toBe(lightCanvas);
  await expect(systemOption).toHaveAttribute("aria-checked", "true");
  await expect.poll(() => page.evaluate(() => window.localStorage.getItem("accrue_theme"))).toBe("system");

  const darkCanvas = await effectiveCanvas();
  const staleCanvas = await page.locator("html").evaluate((element) => {
    element.dataset.theme = "light";
    return getComputedStyle(element).backgroundColor;
  });
  expect(staleCanvas, "negative control: a stale light selection keeps the light canvas").toBe(lightCanvas);
  expect(staleCanvas, "negative control: a stale light selection differs from System dark").not.toBe(darkCanvas);
  await page.locator("html").evaluate((element) => { element.dataset.theme = "system"; });
  await expect.poll(effectiveCanvas, { message: "System dark canvas is restored after negative control" }).toBe(darkCanvas);

  await page.emulateMedia({ colorScheme: "light" });
  await expect.poll(effectiveCanvas, { message: "System preference returns to the light canvas" }).not.toBe(darkCanvas);
  await expect(page.locator("html")).toHaveAttribute("data-theme", "system");
  await expect(systemOption).toHaveAttribute("aria-checked", "true");

  // This link uses LiveView navigation, so the preference must survive a patch as well as reload.
  await page.locator("a[href='/billing/invoices']").first().click();
  await expect(page).toHaveURL(/\/billing\/invoices/);
  await expect(page.locator("html")).toHaveAttribute("data-theme", "system");
  await expect(page.locator("[data-theme-target='system']")).toHaveAttribute("aria-checked", "true");
  await expect.poll(effectiveCanvas, { message: "light OS palette remains active after LiveView patch" }).toBe(lightCanvas);

  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "system");
  await expect(page.locator("[data-theme-target='system']")).toHaveAttribute("aria-checked", "true");
  await expect.poll(() => page.evaluate(() => window.localStorage.getItem("accrue_theme"))).toBe("system");
  await expect.poll(effectiveCanvas, { message: "light OS palette remains active after reload" }).toBe(lightCanvas);
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

async function runRouteFlowStep(page, flow, step, fixtures) {
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

  const link = step.linkHref
    ? page.locator(`a[href^="${step.linkHref(fixtures)}"]`).first()
    : step.linkSelector
      ? page.locator(step.linkSelector).first()
      : page.getByRole("link", { name: step.link }).first();
  await expect(link, `${flow.name}: drill link`).toBeVisible();
  if (step.linkAccessibleName) {
    await expect(link, `${flow.name}: accessible drill link name`).toHaveAccessibleName(step.linkAccessibleName);
  }
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

  test("@phase199 @keyboard invoice review contains focus, exposes associated validation, and restores after rapid dismissal", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "invoice review keyboard sequence runs once");

    const fixtures = await seedPhase199(request);
    await login(page, `/billing/invoices/${fixtures.edgeStates.jpy_invoice_id}`);
    await setPhase191Theme(page, "light");
    await page.emulateMedia({ reducedMotion: "reduce" });

    const openInvoiceReview = async () => {
      const menu = page.locator("[data-ax-action-overflow-menu]").first();
      await expect(menu, "invoice action menu trigger").toBeVisible();
      await menu.locator("summary").focus();
      await page.keyboard.press("Enter");
      const item = page.getByRole("menuitem", { name: /Void invoice/i }).first();
      await expect(item, "Void invoice review option").toBeVisible();
      await item.focus();
      await page.keyboard.press("Enter");
      const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
      await expect(drawer, "invoice review drawer").toBeVisible();
      return drawer;
    };

    const drawer = await openInvoiceReview();
    const focusable = drawer.locator("button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), a[href]");
    const first = focusable.first();
    const last = focusable.last();
    await first.focus();
    await page.keyboard.press("Shift+Tab");
    await expect(last, "Shift+Tab wraps to the last review control").toBeFocused();
    await page.keyboard.press("Tab");
    await expect(first, "Tab wraps to the first review control").toBeFocused();

    await page.keyboard.press("Escape");
    await assertNoStaleOverlayState(page, "rapid reduced-motion invoice review dismissal");
    await expect(page.locator("#main-content"), "removed review opener uses logical page focus").toBeFocused();
    await assertTopPointerTarget(page.locator("[data-theme-target='system']"), "theme control after drawer teardown");

    const reopened = await openInvoiceReview();
    const prepareAction = reopened.getByRole("button", { name: /Void invoice/i }).first();
    await prepareAction.focus();
    await page.keyboard.press("Enter");
    const stagedConfirm = reopened.getByRole("button", { name: /Confirm Void invoice/i });
    await expect(stagedConfirm, "review action stages confirmation").toBeVisible();
    await stagedConfirm.focus();
    await page.keyboard.press("Enter");

    const modal = page.locator("#accrue-admin-step-up-dialog");
    const code = modal.locator("input[name='code']");
    await expect(modal, "step-up modal opens from keyboard review").toBeVisible();
    await expect(code, "step-up input receives initial focus").toBeFocused();
    await expect(code).toHaveAttribute("aria-invalid", "false");
    await code.fill("000000");
    await page.keyboard.press("Enter");
    const error = modal.locator("[data-role='step-up-error']");
    await expect(error, "invalid code exposes an associated error").toBeVisible();
    await expect(code).toHaveAttribute("aria-invalid", "true");
    await expect(code).toHaveAttribute("aria-describedby", /step-up-error/);
    await expect(code, "correction stays inside the active modal").toBeFocused();

    await code.fill("123456");
    await page.keyboard.press("Enter");
    await expect(modal, "corrected submission closes step-up").toBeHidden();
    await assertNoStaleOverlayState(page, "invoice review submission");
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

  test("@phase199 @theme System keeps one stored choice while effective colors follow OS through patch and reload", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "System appearance lifecycle runs once");

    await seedPhase199(request);
    await login(page, "/billing/customers");
    await assertSystemThemeTracksAppearance(page);
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
        await runRouteFlowStep(page, flow, step, fixtures);
      }
    }
  });

  test("@phase241 subscription open-invoice destination preserves customer scope and contextual return", async ({
    page,
    request,
  }) => {
    const fixtures = await seedPhase199(request);
    const subscriptionId = fixtures.dashboard.subscription_id;
    const customerId = fixtures.dashboard.customer_id;
    await page.setViewportSize({ width: 320, height: 844 });
    await login(page, `/billing/subscriptions/${subscriptionId}`);
    await setPhase191Theme(page, "dark");

    const customerInvoices = page.getByRole("link", { name: "Open invoices for this customer" });
    await expect(customerInvoices).toBeVisible();
    const destination = new URL(await customerInvoices.getAttribute("href"), page.url());
    expect(destination.pathname).toBe("/billing/invoices");
    expect(destination.searchParams.get("customer_id")).toBe(customerId);
    expect(destination.searchParams.get("status")).toBe("open");
    expect(destination.searchParams.has("subscription_id")).toBe(false);
    expect(destination.searchParams.get("return_to")).toBe("/billing/subscriptions");

    await customerInvoices.click();
    await expect(page).toHaveURL(/\/billing\/invoices\?/);
    await expect(page.locator("main")).toContainText("Showing 1 invoice");
    const invoiceLinks = page.locator("main a[href^='/billing/invoices/']");
    await expect(invoiceLinks).toHaveCount(2);
    const resultIds = await invoiceLinks.evaluateAll((links) =>
      [...new Set(links.map((link) => new URL(link.href).pathname.split("/").pop()))]
    );
    expect(resultIds).toEqual([fixtures.edgeStates.jpy_invoice_id]);

    await login(page, `/billing/customers/${customerId}?tab=invoices`);
    const customerInvoice = page.getByRole("link", { name: "E2E-199-JPY-001" });
    await expect(customerInvoice).toBeVisible();
    await customerInvoice.click();
    await expect(page).toHaveURL(/\/billing\/invoices\/[0-9a-f-]+\?/i);
    const returnLink = page.getByRole("link", { name: "Back to customer invoices" });
    await expect(returnLink).toBeVisible();
    const returnDestination = new URL(await returnLink.getAttribute("href"), page.url());
    expect(returnDestination.pathname).toBe(`/billing/customers/${customerId}`);
    expect(returnDestination.searchParams.get("tab")).toBe("invoices");
    await returnLink.click();
    await expect(page).toHaveURL(new RegExp(`/billing/customers/${customerId}\\?tab=invoices`));
    await expect(page.locator("main")).toContainText("E2E-199-JPY-001");
  });

  test("@phase241 action spacing uses the 4px token and stays reachable at narrow/coarse sizes", async ({
    page,
    request,
    browser,
  }) => {
    const fixtures = await seedPhase199(request);
    const surfaces = [
      {
        name: "invoice",
        route: `/billing/invoices/${fixtures.edgeStates.jpy_invoice_id}`,
        selector: ".ax-detail-action-band .ax-page-actions",
      },
      {
        name: "subscription action band",
        route: `/billing/subscriptions/${fixtures.dashboard.subscription_id}`,
        selector: ".ax-detail-action-band .ax-page-actions",
        checkHitTargets: true,
      },
      {
        name: "subscription dunning action row",
        route: `/billing/subscriptions/${fixtures.edgeStates.recovery_subscription_id}`,
        selector: ".ax-detail-actions-row",
        checkHitTargets: false,
      },
    ];

    const measurements = [];
    for (const surface of surfaces) {
      await page.setViewportSize({ width: 320, height: 844 });
      await login(page, surface.route);
      const geometry = await page.locator(surface.selector).evaluate((group) => {
        const style = getComputedStyle(group);
        const tokenProbe = document.createElement("div");
        tokenProbe.style.cssText = "display:flex;gap:var(--ax-space-xs);position:absolute;visibility:hidden";
        document.body.append(tokenProbe);
        const tokenGap = getComputedStyle(tokenProbe).gap;
        tokenProbe.remove();
        const controls = [...group.querySelectorAll("button, a")].filter((control) => {
          const rect = control.getBoundingClientRect();
          return rect.width > 0 && rect.height > 0;
        });
        const hitTargets = [...group.querySelectorAll("[data-ax-primary-action]")].filter((control) => {
          const rect = control.getBoundingClientRect();
          return rect.width > 0 && rect.height > 0;
        });
        return {
          gap: style.gap,
          tokenGap,
          controlCount: controls.length,
          controlHeights: hitTargets.map((control) => control.getBoundingClientRect().height),
          pageOverflows: document.documentElement.scrollWidth > document.documentElement.clientWidth,
        };
      });

      measurements.push({ ...surface, geometry });
    }

    console.log("Phase 241 action spacing measurements", JSON.stringify(measurements.map(({ name, geometry }) => ({
      name,
      gap: geometry.gap,
      tokenGap: geometry.tokenGap,
      controlHeights: geometry.controlHeights,
      pageOverflows: geometry.pageOverflows,
    }))));

    for (const { name, geometry } of measurements) {
      expect(geometry.controlCount, `${name} action controls are present`).toBeGreaterThan(0);
      expect(geometry.gap, `${name} action gap equals the computed token`).toBe(geometry.tokenGap);
      expect(geometry.gap, `${name} action gap computes to 4px`).toBe("4px");
      expect(geometry.pageOverflows, `${name} has no ordinary page overflow at 320px`).toBe(false);
      if (measurements.find((measurement) => measurement.name === name).checkHitTargets) {
        expect(geometry.controlHeights.length, `${name} has measured primary action controls`).toBeGreaterThan(0);
        expect(
          geometry.controlHeights.every((height) => height >= 44),
          `${name} action controls retain 44px hit height`,
        ).toBe(true);
      }
    }

    const coarseContext = await browser.newContext({
      viewport: { width: 320, height: 844 },
      isMobile: true,
      hasTouch: true,
    });
    try {
      const coarsePage = await coarseContext.newPage();
      await login(coarsePage, surfaces[1].route);
      const coarse = await coarsePage.locator(surfaces[1].selector).evaluate((group) => ({
        coarsePointer: matchMedia("(pointer: coarse)").matches,
        gap: getComputedStyle(group).gap,
        controlHeights: [...group.querySelectorAll("[data-ax-primary-action]")]
          .filter((control) => control.getBoundingClientRect().height > 0)
          .map((control) => control.getBoundingClientRect().height),
        pageOverflows: document.documentElement.scrollWidth > document.documentElement.clientWidth,
      }));
      expect(coarse.coarsePointer, "independent mobile context uses a coarse pointer").toBe(true);
      expect(coarse.gap, "coarse-pointer action gap computes to 4px").toBe("4px");
      expect(coarse.pageOverflows, "coarse-pointer layout has no ordinary page overflow").toBe(false);
      expect(coarse.controlHeights.length, "coarse-pointer context has measured primary action controls").toBeGreaterThan(0);
      expect(
        coarse.controlHeights.every((height) => height >= 44),
        "coarse-pointer action controls retain 44px hit height",
      ).toBe(true);
    } finally {
      await coarseContext.close();
    }
  });

  test("@phase241 200% text, WCAG text spacing, and 400% reflow simulation keep changed billing consumers reachable", async ({
    page,
    request,
  }) => {
    test.setTimeout(120_000);
    const fixtures = await seedPhase241Reviews(request);
    const zoomPage = await page.context().newPage();
    await page.setViewportSize({ width: 1280, height: 900 });
    await zoomPage.setViewportSize({ width: 320, height: 844 });
    const routes = [
      ["subscription detail", `/billing/subscriptions/${fixtures.subscription_id}`],
      ["invoice results", `/billing/invoices?customer_id=${fixtures.customer_id}`],
      ["invoice detail", `/billing/invoices/${fixtures.invoice_id}`],
      ["payment detail", `/billing/payments/${fixtures.charge_id}`],
      ["customer payment methods", `/billing/customers/${fixtures.customer_id}?tab=payment_methods`],
      ["Recovery list", "/billing/analytics/recovery?window=30d"],
      ["campaign detail", `/billing/analytics/recovery/subscriptions/${fixtures.recovery_subscription_id}`],
    ];

    for (const [surface, route] of routes) {
      await login(page, route);
      await page.evaluate(() => {
        const style = document.createElement("style");
        style.dataset.phase241TextStress = "true";
        style.nonce = document.querySelector("style[nonce]")?.nonce || "";
        style.textContent = `
          p, li, dt, dd, th, td, button, a, label, input, select, textarea {
            line-height: 1.5 !important;
            letter-spacing: .12em !important;
            word-spacing: .16em !important;
          }
          p { margin-bottom: 2em !important; }
        `;
        document.head.append(style);
      });

      const enlarged = await page.evaluate(() => ({
        headingScale: (() => {
          const elements = [...document.querySelectorAll("body *")];
          const fontSizes = elements.map((element) => Number.parseFloat(getComputedStyle(element).fontSize));
          elements.forEach((element, index) => {
            const fontSize = fontSizes[index];
            if (Number.isFinite(fontSize) && fontSize > 0) {
              element.dataset.phase241BaseFontSize = String(fontSize);
              element.style.setProperty("font-size", `${fontSize * 2}px`, "important");
            }
          });
          const heading = document.querySelector("#main-content, main");
          const baseFontSize = Number.parseFloat(heading?.dataset.phase241BaseFontSize || "");
          const enlargedFontSize = Number.parseFloat(getComputedStyle(heading).fontSize);
          if (!Number.isFinite(baseFontSize) || !Number.isFinite(enlargedFontSize) || baseFontSize <= 0) {
            throw new Error("Phase 241 200% text instrumentation did not capture a finite main font size");
          }
          return enlargedFontSize / baseFontSize;
        })(),
        pageWidth: document.documentElement.scrollWidth,
        viewportWidth: window.innerWidth,
        overflowDescendants: [...document.querySelectorAll("body *")]
          .map((element) => {
            const rect = element.getBoundingClientRect();
            const style = getComputedStyle(element);
            return {
              tag: element.tagName.toLowerCase(),
              id: element.id,
              className: String(element.className || "").slice(0, 100),
              role: element.getAttribute("role"),
              left: Math.round(rect.left),
              right: Math.round(rect.right),
              width: Math.round(rect.width),
              scrollWidth: element.scrollWidth,
              clientWidth: element.clientWidth,
              overflowX: style.overflowX,
              text: (element.textContent || "").trim().replace(/\s+/g, " ").slice(0, 45),
            };
          })
          .filter((element) => element.right > window.innerWidth + 1 || element.left < -1)
          .slice(0, 12),
      }));
      expect(enlarged.headingScale, `${surface}: 200% text enlargement applied`).toBeCloseTo(2, 1);
      if (enlarged.pageWidth > enlarged.viewportWidth + 1) {
        throw new Error(`${surface}: 200% text layout overflow ${JSON.stringify(enlarged)}`);
      }
      // At a 1280 CSS-pixel reference width, a 400% browser zoom exposes a
      // 320 CSS-pixel layout viewport. A separate page keeps this reflow
      // simulation independent of the text enlargement override and does not
      // claim to exercise the browser zoom control.
      await login(zoomPage, route);
      const reflow = await zoomPage.evaluate(() => ({
        pageWidth: document.documentElement.scrollWidth,
        viewportWidth: window.innerWidth,
        width: window.innerWidth,
        main: (() => {
          const rect = document.querySelector("#main-content, main").getBoundingClientRect();
          return { left: Math.round(rect.left), right: Math.round(rect.right) };
        })(),
      }));
      expect(reflow.width, `${surface}: 400% zoom equivalent viewport`).toBe(320);
      expect(reflow.pageWidth, `${surface}: 400% reflow has no page overflow`).toBeLessThanOrEqual(
        reflow.viewportWidth + 1
      );
      expect(reflow.main.left, `${surface}: 400% main content remains onscreen`).toBeGreaterThanOrEqual(-1);
      expect(reflow.main.right, `${surface}: 400% main content remains within viewport`).toBeLessThanOrEqual(
        reflow.viewportWidth + 1
      );
    }
    await zoomPage.close();
  });

  test("@phase242 mounted CSS stress stays scoped across changed routes and input modes", async ({
    page,
    request,
  }, testInfo) => {
    const fixtures = await seedPhase199(request);
    await page.setViewportSize({ width: 320, height: 844 });
    await login(page, "/billing");
    const coarsePointer = await page.evaluate(() => window.matchMedia("(pointer: coarse)").matches);
    expect(coarsePointer, "mobile project emulates coarse pointer input; no physical-device claim").toBe(
      testInfo.project.name === "chromium-mobile"
    );

    const routes = [
      ["events", "/billing/events"],
      ["webhook delivery", `/billing/webhooks/${fixtures.phase199.single_webhook_id}`],
      ["Connect account", `/billing/connect/${fixtures.phase199.connect_account_id}`],
      ["Home and shell", "/billing"],
    ];

    for (const [surface, route] of routes) {
      await page.setViewportSize({ width: 320, height: 844 });
      await login(page, route);
      for (const theme of ["light", "dark", "system"]) {
        await page.emulateMedia({ colorScheme: theme === "dark" ? "dark" : "light" });
        await page.evaluate((value) => {
          document.documentElement.dataset.theme = value;
          document.documentElement.setAttribute("data-theme", value);
        }, theme);
        await expect(page.locator("html")).toHaveAttribute("data-theme", theme);

        const stress = await page.evaluate(() => {
          const main = document.querySelector("#main-content, main");
          if (!main) throw new Error("Phase 242 text stress could not find the mounted main region");
          const base = [main, ...main.querySelectorAll("*")].map((element) => [element, getComputedStyle(element).fontSize]);
          const baseline = Number.parseFloat(getComputedStyle(main).fontSize);
          if (!Number.isFinite(baseline) || baseline <= 0) throw new Error("Phase 242 baseline font size is not finite");
          const style = document.createElement("style");
          style.dataset.phase242TextSpacing = "true";
          style.textContent = "#main-content *, main * { line-height: 1.5 !important; letter-spacing: .12em !important; word-spacing: .16em !important; } #main-content p, main p { margin-bottom: 2em !important; }";
          document.head.append(style);
          for (const [element, size] of base) {
            const parsed = Number.parseFloat(size);
            if (Number.isFinite(parsed) && parsed > 0) element.style.setProperty("font-size", `${parsed * 2}px`, "important");
          }
          const enlarged = Number.parseFloat(getComputedStyle(main).fontSize);
          const result = {
            scale: enlarged / baseline,
            width: document.documentElement.scrollWidth,
            viewport: window.innerWidth,
            text: main.innerText.slice(0, 120),
          };
          style.remove();
          for (const [element] of base) element.style.removeProperty("font-size");
          return result;
        });
        expect(stress.scale, `${surface}/${theme}: 200% text captured atomically`).toBeCloseTo(2, 1);
        expect(stress.width, `${surface}/${theme}: 320 CSS px text-spacing reflow`).toBeLessThanOrEqual(stress.viewport + 1);
        expect(stress.text.length, `${surface}/${theme}: mounted content exists`).toBeGreaterThan(0);
      }
      if (surface === "Home and shell") {
        await page.emulateMedia({ colorScheme: "dark" });
        await page.evaluate(() => document.documentElement.setAttribute("data-theme", "dark"));
        await testInfo.attach("phase242-home-dark-320.png", {
          body: await page.screenshot({ fullPage: true }),
          contentType: "image/png",
        });
      }
      await page.setViewportSize({ width: 768, height: 1024 });
      expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(769);
      if (surface === "Home and shell" && coarsePointer) {
        const shortcutHeights = await page
          .locator(".ax-home .ax-page-header-actions > .ax-button")
          .evaluateAll((buttons) => buttons.map((button) => button.getBoundingClientRect().height));
        expect(shortcutHeights, "Home customer, search and subscription shortcuts are mounted").toHaveLength(3);
        for (const height of shortcutHeights) {
          expect(height, "intermediate-width coarse-pointer shortcut hit target is at least 44 CSS px").toBeGreaterThanOrEqual(44);
        }
      }
      await page.setViewportSize({ width: 1280, height: 900 });
      expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(1281);
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

      if (target.fixtureKey) {
        const expectedCopy = COPY_STRINGS[target.fixtureKey];
        expect(expectedCopy, `${target.name}: generated copy fixture ${target.fixtureKey}`).toBeTruthy();
        await expect(copySurface, `${target.name}: generated fixture copy`).toContainText(expectedCopy);
      }
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

// >>> @ratchet:auto-guards >>>
const RATCHET_AUTO_GUARDS = [
  {"finding_id":"f-0f90c9ba4473cf8e","kind":"focus-ring","selector":".ax-content"}, // @ratchet:f-0f90c9ba4473cf8e
  {"finding_id":"f-186adbbbf86b57ce","kind":"focus-ring","selector":".ax-content"}, // @ratchet:f-186adbbbf86b57ce
  {"finding_id":"f-29171df0f331750c","kind":"focus-ring","selector":".ax-topbar"}, // @ratchet:f-29171df0f331750c
  {"finding_id":"f-387aa6ba03f90988","kind":"focus-ring","selector":".ax-page-header"}, // @ratchet:f-387aa6ba03f90988
  {"finding_id":"f-45f7a0e8db0e3b03","kind":"focus-ring","selector":".ax-page-header"}, // @ratchet:f-45f7a0e8db0e3b03
  {"finding_id":"f-4f474e99919ee505","kind":"focus-ring","selector":".ax-topbar"}, // @ratchet:f-4f474e99919ee505
  {"finding_id":"f-5b4fde509c9846f7","kind":"focus-ring","selector":".ax-content"}, // @ratchet:f-5b4fde509c9846f7
  {"finding_id":"f-66ff3aa97d803c81","kind":"focus-ring","selector":".ax-toolbar"}, // @ratchet:f-66ff3aa97d803c81
  {"finding_id":"f-68d2bf118467b34a","kind":"focus-ring","selector":".ax-home [data-command-palette-trigger]","route":"/billing"}, // @ratchet:f-68d2bf118467b34a
  {"finding_id":"f-8b82f34db2fd2d70","kind":"focus-ring","selector":".ax-content"}, // @ratchet:f-8b82f34db2fd2d70
  {"finding_id":"f-8d4e761ccec068a7","kind":"focus-ring","selector":".ax-primary-nav:visible, [data-sidebar-toggle='true']:visible"}, // @ratchet:f-8d4e761ccec068a7
  {"finding_id":"f-90ff4aae38ba2085","kind":"focus-ring","selector":".ax-toolbar"}, // @ratchet:f-90ff4aae38ba2085
  {"finding_id":"f-988d2a9808195b53","kind":"focus-ring","selector":".ax-detail"}, // @ratchet:f-988d2a9808195b53
  {"finding_id":"f-9e6f3e53a835a6d5","kind":"focus-ring","selector":".ax-home [data-command-palette-trigger]","route":"/billing"}, // @ratchet:f-9e6f3e53a835a6d5
  {"finding_id":"f-9f433603cde72097","kind":"focus-ring","selector":".ax-kpi-card"}, // @ratchet:f-9f433603cde72097
  {"finding_id":"f-a276757f4dcd510c","kind":"focus-ring","selector":".ax-related-resources"}, // @ratchet:f-a276757f4dcd510c
  {"finding_id":"f-a3421a7901c75b6b","kind":"focus-ring","selector":".ax-layer"}, // @ratchet:f-a3421a7901c75b6b
  {"finding_id":"f-a5a8e0d926d2214c","kind":"focus-ring","selector":".ax-kpi-card"}, // @ratchet:f-a5a8e0d926d2214c
  {"finding_id":"f-b6c27cee85892dd2","kind":"focus-ring","selector":".ax-layer"}, // @ratchet:f-b6c27cee85892dd2
  {"finding_id":"f-ca8eabe5458b44f5","kind":"focus-ring","selector":".ax-page-header"}, // @ratchet:f-ca8eabe5458b44f5
  {"finding_id":"f-d43539c599a42ac9","kind":"focus-ring","selector":".ax-topbar"}, // @ratchet:f-d43539c599a42ac9 (.ax-primary-nav sidebar is hidden on mobile by design — nav is reached via the topbar Menu toggle; retargeted to the both-viewport .ax-topbar chrome)
  {"finding_id":"f-e3deb40c0e41d060","kind":"focus-ring","selector":".ax-layer"}, // @ratchet:f-e3deb40c0e41d060
  {"finding_id":"f-f1be6ae0d866ce1b","kind":"focus-ring","selector":".ax-page-header"}, // @ratchet:f-f1be6ae0d866ce1b
  {"finding_id":"f-f6641ba530cd6c0b","kind":"focus-ring","selector":".ax-topbar"}, // @ratchet:f-f6641ba530cd6c0b
  {"finding_id":"f-f91517ae68a2adec","kind":"focus-ring","selector":".ax-data-table","route":"/billing/invoices"}, // @ratchet:f-f91517ae68a2adec
];
// <<< @ratchet:auto-guards <<<

// Auto-minted regression guards (207-03, D-44/D-45/D-46). Iterates the human-reviewed-once
// RATCHET_AUTO_GUARDS data array above; each "focus-ring" row focuses row.selector (reusing
// this file's login helper for navigation) and asserts the focused element paints a visible
// outline (outlineStyle !== "none"). row.route is optional — defaults to the components lab.
// Starts empty (loop no-ops).
test("auto-minted ratchet guards — interaction focus-ring", async ({ page }) => {
  test.skip(RATCHET_AUTO_GUARDS.length === 0, "no minted ratchet guards yet");

  for (const row of RATCHET_AUTO_GUARDS) {
    if (row.kind !== "focus-ring") {
      throw new Error(`\`@ratchet:${row.finding_id}\` unexpected kind for interaction-overlay home: ${row.kind}`);
    }
    await login(page, row.route || "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const locator = page.locator(row.selector).first();
    await expect(locator, `\`@ratchet:${row.finding_id}\` ${row.selector} must exist`).toBeVisible();
    const outlineStyle = await locator.evaluate((el) => {
      const focusableSelector = [
        "button:not([disabled])",
        "a[href]",
        "input:not([disabled])",
        "select:not([disabled])",
        "textarea:not([disabled])",
        "[tabindex]:not([tabindex='-1'])",
      ].join(",");
      const candidates = [
        el.matches(focusableSelector) ? el : null,
        ...el.querySelectorAll(focusableSelector),
      ].filter(Boolean);
      const target =
        candidates.find((candidate) => candidate.getClientRects().length > 0) || el;
      if (target === el && !target.hasAttribute("tabindex")) {
        target.setAttribute("tabindex", "0");
      }
      const priorForce = target.getAttribute("data-ax-force") || "";
      target.setAttribute("data-ax-force", `${priorForce} focus`.trim());
      target.focus({ preventScroll: true });
      return window.getComputedStyle(target).outlineStyle;
    });
    expect(
      outlineStyle,
      `\`@ratchet:${row.finding_id}\` ${row.selector} must paint a visible focus outline (outline-style !== "none")`
    ).not.toBe("none");
  }
});
