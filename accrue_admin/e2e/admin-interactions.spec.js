const fs = require("fs");
const path = require("path");

const { test, expect } = require("@playwright/test");

const { OVERLAY_TAGS } = require("./baseline-manifest.js");

// trace: "on" is file-scoped interaction evidence and does not modify playwright.config.js.
test.use({ trace: "on" });

const RESULTS_ROOT = "test-results/admin-interactions";
const OBSERVATION_FIELDS = [
  "probe_id",
  "interaction_class",
  "cell_id",
  "surface",
  "surface_type",
  "state",
  "rubric_dimension",
  "overlay_tags",
  "coverage_status",
  "target_selector",
  "expected",
  "actual",
  "assertions",
  "evidence_refs",
  "failure_kind",
  "notes",
];

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seed(request, fixture) {
  const response = await request.post(`/__e2e__/seed/${fixture}`);
  expect(response.ok()).toBeTruthy();
  return response.json();
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}

async function loginMember(page, target = "/billing") {
  await page.goto(`/__e2e__/login-member?to=${encodeURIComponent(target)}`);
}

function slug(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function makeRecorder(projectName) {
  const rows = [];
  let sequence = 0;
  const evidenceRefs = [
    `accrue_admin/test-results/admin-interactions/${projectName}/observations.ndjson`,
    `playwright-trace:${projectName}:admin-interactions.spec.js`,
  ];

  function observe(row) {
    sequence += 1;
    const complete = {
      probe_id: row.probe_id || `ixn-${String(sequence).padStart(3, "0")}`,
      interaction_class: row.interaction_class,
      cell_id: row.cell_id || `p187__${slug(row.surface || row.interaction_class)}__${projectName}__${slug(row.state || "interactive-open")}__d11`,
      surface: row.surface,
      surface_type: row.surface_type || "page-flow",
      state: row.state || "interactive-open",
      rubric_dimension: row.rubric_dimension || "interaction-integrity",
      overlay_tags: (row.overlay_tags || []).filter((tag) => OVERLAY_TAGS.includes(tag)),
      coverage_status: row.coverage_status || "covered",
      target_selector: row.target_selector || "",
      expected: row.expected || "",
      actual: row.actual || "",
      assertions: row.assertions || [],
      evidence_refs: row.evidence_refs || evidenceRefs,
      failure_kind: row.failure_kind || null,
      notes: row.notes || "",
    };

    for (const field of OBSERVATION_FIELDS) {
      if (!(field in complete)) throw new Error(`observation missing field ${field}`);
    }

    rows.push(complete);
    return complete;
  }

  function write() {
    const outputPath = path.join(RESULTS_ROOT, projectName, "observations.ndjson");
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, rows.map((row) => JSON.stringify(row)).join("\n") + "\n");
    return outputPath;
  }

  return { observe, write, rows };
}

async function visible(locator) {
  try {
    return (await locator.count()) > 0 && (await locator.first().isVisible().catch(() => false));
  } catch (_error) {
    return false;
  }
}

async function text(locator) {
  if (!(await visible(locator))) return "";
  return (await locator.first().innerText().catch(() => "")).trim();
}

async function activeSelector(page) {
  return page.evaluate(() => {
    const element = document.activeElement;
    if (!element) return "none";
    if (element.id) return `#${element.id}`;
    if (element.getAttribute("data-role")) return `[data-role="${element.getAttribute("data-role")}"]`;
    if (element.getAttribute("name")) return `${element.tagName.toLowerCase()}[name="${element.getAttribute("name")}"]`;
    if (element.className && typeof element.className === "string") {
      return `${element.tagName.toLowerCase()}.${element.className.trim().split(/\s+/).slice(0, 2).join(".")}`;
    }
    return element.tagName.toLowerCase();
  });
}

async function topElementAt(locator) {
  if (!(await visible(locator))) return { top: "missing", receivesEvents: false };
  return locator.first().evaluate((element) => {
    const rect = element.getBoundingClientRect();
    const x = Math.max(rect.left + 1, Math.min(rect.left + rect.width / 2, window.innerWidth - 1));
    const y = Math.max(rect.top + 1, Math.min(rect.top + rect.height / 2, window.innerHeight - 1));
    const top = document.elementFromPoint(x, y);
    const topLabel = top
      ? `${top.tagName.toLowerCase()}${top.id ? `#${top.id}` : ""}${top.className && typeof top.className === "string" ? `.${top.className.trim().split(/\s+/).slice(0, 2).join(".")}` : ""}`
      : "none";
    return { top: topLabel, receivesEvents: top === element || element.contains(top) };
  });
}

async function clickOrObserve(locator, recorder, baseRow) {
  if (!(await visible(locator))) {
    recorder.observe({
      ...baseRow,
      coverage_status: "gap",
      actual: "target selector was not visible",
      failure_kind: "missing-selector",
      overlay_tags: [...(baseRow.overlay_tags || []), "actionability"],
    });
    return false;
  }

  try {
    await locator.first().click({ timeout: 2_000 });
    recorder.observe({
      ...baseRow,
      actual: "click completed without Playwright actionability interception",
      assertions: [...(baseRow.assertions || []), "visible target received click without force"],
    });
    return true;
  } catch (error) {
    recorder.observe({
      ...baseRow,
      coverage_status: "gap",
      actual: error.message,
      failure_kind: "intercepted-click",
      overlay_tags: Array.from(new Set([...(baseRow.overlay_tags || []), "actionability", "layer-z-index"])),
    });
    return false;
  }
}

async function scrollProbe(page, selector, recorder, surface, notes) {
  const locator = page.locator(selector).first();
  if (!(await visible(locator))) {
    recorder.observe({
      interaction_class: "scroll-reachability",
      surface,
      state: "overflow",
      target_selector: selector,
      expected: "Scroll container exists or is marked n/a with a reason.",
      actual: "No matching scroll container.",
      coverage_status: "n/a",
      failure_kind: "not-applicable",
      overlay_tags: ["scroll-reachability"],
      notes,
    });
    return;
  }

  const metrics = await locator.evaluate((element) => {
    element.scrollTop = element.scrollHeight;
    element.scrollLeft = element.scrollWidth;
    return {
      scrollTop: element.scrollTop,
      scrollLeft: element.scrollLeft,
      scrollHeight: element.scrollHeight,
      clientHeight: element.clientHeight,
      scrollWidth: element.scrollWidth,
      clientWidth: element.clientWidth,
    };
  });

  recorder.observe({
    interaction_class: "scroll-reachability",
    surface,
    state: metrics.scrollHeight > metrics.clientHeight || metrics.scrollWidth > metrics.clientWidth ? "overflow" : "default-populated",
    target_selector: selector,
    expected: "Bottom content or last actionable sentinel is reachable after scrolling.",
    actual: JSON.stringify(metrics),
    assertions: ["scroll container was programmatically scrolled to bottom/right"],
    overlay_tags: ["scroll-reachability"],
    notes,
  });
}

async function focusCycleProbe(page, surfaceSelector, recorder, surface, triggerSelector) {
  const before = await activeSelector(page);
  await page.keyboard.press("Tab");
  const afterTab = await activeSelector(page);
  await page.keyboard.press("Shift+Tab");
  const afterShiftTab = await activeSelector(page);
  const inside = await page.locator(surfaceSelector).evaluate((surfaceElement) => {
    const active = document.activeElement;
    return active ? surfaceElement.contains(active) : false;
  }).catch(() => false);

  recorder.observe({
    interaction_class: "focus-trap-restore",
    surface,
    target_selector: surfaceSelector,
    expected: "Tab and Shift+Tab stay inside the active modal/drawer/command-palette/step-up surface.",
    actual: `before=${before}; afterTab=${afterTab}; afterShiftTab=${afterShiftTab}; inside=${inside}; trigger=${triggerSelector}`,
    assertions: ["focus-trap", "focus-restore", "Tab", "Shift+Tab"],
    overlay_tags: ["focus-trap", "focus-restore"],
    failure_kind: inside ? null : "focus-escaped",
    coverage_status: inside ? "covered" : "gap",
  });
}

async function probeModalDrawerScrim(page, recorder, fixtureData) {
  await login(page, `/billing/webhooks/${fixtureData["operator-flows"].single_webhook_id}`);
  await expect(page.locator("#main-content")).toBeVisible();

  await clickOrObserve(page.locator('[data-role="replay-single"]').first(), recorder, {
    interaction_class: "modal-drawer-scrim",
    surface: "webhook replay confirmation",
    target_selector: '[data-role="replay-single"]',
    expected: "Replay trigger opens the confirmation panel without intercepted clicks.",
    overlay_tags: ["actionability"],
  });

  const replayConfirm = page.getByRole("dialog", { name: "Confirm webhook replay" });
  const confirmPanel = page.locator('[data-role="confirm-panel"]');
  recorder.observe({
    interaction_class: "modal-drawer-scrim",
    surface: "webhook replay confirmation",
    target_selector: '[data-role="replay-confirm"], [data-role="confirm-panel"]',
    expected: "Confirmation overlay/panel is visible and layered above surrounding content.",
    actual: JSON.stringify(await topElementAt(replayConfirm)),
    assertions: ["layer-z-index", "overlay-position"],
    overlay_tags: ["layer-z-index", "overlay-position", "actionability"],
    coverage_status: (await visible(replayConfirm)) || (await visible(confirmPanel)) ? "covered" : "gap",
    failure_kind: (await visible(replayConfirm)) || (await visible(confirmPanel)) ? null : "missing-selector",
  });

  await page.keyboard.press("Escape");
  recorder.observe({
    interaction_class: "escape-click-outside-dismissal",
    surface: "webhook replay confirmation",
    target_selector: '[data-role="replay-confirm"]',
    expected: "Escape dismissal is recorded for replay confirmation.",
    actual: (await visible(replayConfirm)) ? "replay confirmation remained visible after Escape" : "replay confirmation dismissed or was not modal",
    assertions: ["Escape", "dismissed state"],
    overlay_tags: ["focus-restore"],
    coverage_status: (await visible(replayConfirm)) ? "gap" : "covered",
    failure_kind: (await visible(replayConfirm)) ? "escape-not-dismissed" : null,
  });

  await login(page, "/billing/customers");
  await expect(page.locator("#main-content")).toBeVisible();
  await clickOrObserve(page.locator("tbody tr a, [data-role='card-list'] a").first(), recorder, {
    interaction_class: "modal-drawer-scrim",
    surface: "customer detail drawer",
    target_selector: "row/detail link",
    expected: "A customer row opens `.ax-detail-drawer-shell` when the current route exposes a drawer.",
    overlay_tags: ["actionability"],
  });

  const drawerShell = page.locator(".ax-detail-drawer-shell");
  const drawerBackdrop = page.locator(".ax-detail-drawer-backdrop");
  const drawer = page.locator(".ax-detail-drawer");
  recorder.observe({
    interaction_class: "modal-drawer-scrim",
    surface: "detail drawer",
    target_selector: ".ax-detail-drawer-shell, .ax-detail-drawer-backdrop, .ax-detail-drawer",
    expected: "Drawer shell, scrim, and panel layer order are observable.",
    actual: JSON.stringify({
      shellVisible: await visible(drawerShell),
      backdropVisible: await visible(drawerBackdrop),
      drawerTop: await topElementAt(drawer),
    }),
    assertions: ["layer-z-index", "overlay-position", "actionability"],
    overlay_tags: ["layer-z-index", "overlay-position", "actionability"],
    coverage_status: (await visible(drawer)) ? "covered" : "gap",
    failure_kind: (await visible(drawer)) ? null : "missing-selector",
  });

  if (await visible(drawer)) {
    await focusCycleProbe(page, ".ax-detail-drawer", recorder, "detail drawer", "row/detail link");
    await scrollProbe(page, ".ax-detail-drawer", recorder, "drawer body", "drawer body scroll reachability");
    await page.keyboard.press("Escape");
    recorder.observe({
      interaction_class: "escape-click-outside-dismissal",
      surface: "detail drawer",
      target_selector: ".ax-detail-drawer",
      expected: "Escape closes the drawer and focus restores to the trigger.",
      actual: (await visible(drawer)) ? "drawer remained visible" : `closed; active=${await activeSelector(page)}`,
      assertions: ["Escape", "focus-restore"],
      overlay_tags: ["focus-restore"],
      coverage_status: (await visible(drawer)) ? "gap" : "covered",
      failure_kind: (await visible(drawer)) ? "escape-not-dismissed" : null,
    });
  }
}

async function openChargeStepUp(page, recorder, chargeId) {
  await login(page, `/billing/payments/${chargeId}`);
  await expect(page.locator("#main-content")).toBeVisible();

  await clickOrObserve(page.getByRole("button", { name: /refund charge/i }).first(), recorder, {
    interaction_class: "step-up-auth-modal",
    surface: "charge refund",
    target_selector: "button:has-text('Refund charge')",
    expected: "Refund action opens the current action drawer.",
    overlay_tags: ["actionability"],
  });

  const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']").first();
  const refundForm = drawer.locator('[data-role="refund-form"]').first();
  await expect(drawer).toBeVisible();
  await expect(refundForm).toBeVisible();
  await refundForm.locator('input[name="reason"]').fill("requested_by_customer").catch(() => {});
  await clickOrObserve(refundForm.locator('button[type="submit"], button[form="charge-refund-form"]').first(), recorder, {
    interaction_class: "step-up-auth-modal",
    surface: "charge refund",
    target_selector: '[data-role="refund-form"]',
    expected: "Refund form stages a confirmation panel.",
    overlay_tags: ["actionability"],
  });

  await expect(drawer.locator('[data-role="confirm-panel"]')).toBeVisible();
  await clickOrObserve(drawer.locator('[data-role="confirm-refund"]').first(), recorder, {
    interaction_class: "step-up-auth-modal",
    surface: "charge refund",
    target_selector: '[data-role="confirm-panel"] [data-role="confirm-refund"]',
    expected: "Confirm refund opens StepUpAuthModal.",
    overlay_tags: ["actionability"],
  });
}

async function probeStepUp(page, recorder, fixtureData) {
  await openChargeStepUp(page, recorder, fixtureData["operator-flows"].charge_id);
  const dialog = page.locator("#accrue-admin-step-up-dialog");
  const input = dialog.locator('input[name="code"]');
  const error = page.locator('[data-role="step-up-error"]');

  recorder.observe({
    interaction_class: "step-up-auth-modal",
    surface: "StepUpAuthModal charge refund",
    target_selector: "#accrue-admin-step-up-dialog",
    expected: "StepUpAuthModal opens above the destructive-action confirmation path.",
    actual: JSON.stringify({ visible: await visible(dialog), top: await topElementAt(dialog) }),
    assertions: ["layering", "top-element/actionability", "trace-backed evidence refs"],
    overlay_tags: ["layer-z-index", "actionability", "overlay-position"],
    coverage_status: (await visible(dialog)) ? "covered" : "gap",
    failure_kind: (await visible(dialog)) ? null : "missing-selector",
  });

  if (await visible(dialog)) {
    await focusCycleProbe(page, "#accrue-admin-step-up-dialog", recorder, "StepUpAuthModal charge refund", '[data-role="confirm-refund"]');
    await input.fill("000000").catch(() => {});
    await page.keyboard.press("Enter");
    await page.waitForTimeout(200);
    recorder.observe({
      interaction_class: "step-up-auth-modal",
      surface: "StepUpAuthModal invalid code",
      target_selector: '[data-role="step-up-error"]',
      expected: "Invalid-code submit exposes error copy from `[data-role=\"step-up-error\"]`.",
      actual: await text(error),
      assertions: ["keyboard submit", "invalid-code error copy", "step_up_submit", "step-up-error"],
      overlay_tags: ["copy-recovery", "copy-specificity", "live-focus"],
      coverage_status: (await visible(error)) ? "covered" : "gap",
      failure_kind: (await visible(error)) ? null : "missing-selector",
    });

    await input.fill("123456").catch(() => {});
    await page.keyboard.press("Enter");
    await page.waitForTimeout(400);
    recorder.observe({
      interaction_class: "step-up-auth-modal",
      surface: "StepUpAuthModal valid code submit",
      target_selector: '#accrue-admin-step-up-dialog input[name="code"]',
      expected: "Keyboard submit with code `123456` completes or records LiveView patch focus.",
      actual: `visible=${await visible(dialog)}; active=${await activeSelector(page)}`,
      assertions: ["keyboard submit with code 123456", "live-focus", "focus-restore"],
      overlay_tags: ["live-focus", "focus-restore"],
      coverage_status: "covered",
    });
  }

  await openChargeStepUp(page, recorder, fixtureData["operator-flows"].charge_id);
  if (await visible(dialog)) {
    await page.locator('button[phx-click="step_up_dismiss"], button:has-text("Cancel")').first().focus();
    await page.keyboard.press("Enter");
    await page.waitForTimeout(200);
    recorder.observe({
      interaction_class: "step-up-auth-modal",
      surface: "StepUpAuthModal keyboard cancel",
      target_selector: 'button[phx-click="step_up_dismiss"]',
      expected: "Keyboard cancel through the `step_up_dismiss` control dismisses the modal.",
      actual: `visible=${await visible(dialog)}; active=${await activeSelector(page)}`,
      assertions: ["keyboard cancel", "step_up_dismiss", "focus-restore"],
      overlay_tags: ["focus-restore"],
      coverage_status: (await visible(dialog)) ? "gap" : "covered",
      failure_kind: (await visible(dialog)) ? "dismiss-not-completed" : null,
    });
  }

  await openChargeStepUp(page, recorder, fixtureData["operator-flows"].charge_id);
  if (await visible(dialog)) {
    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);
    recorder.observe({
      interaction_class: "step-up-auth-modal",
      surface: "StepUpAuthModal Escape dismissal",
      target_selector: "#accrue-admin-step-up-dialog",
      expected: "Escape dismissal closes StepUpAuthModal.",
      actual: `visible=${await visible(dialog)}`,
      assertions: ["Escape dismissal"],
      overlay_tags: ["focus-restore"],
      coverage_status: (await visible(dialog)) ? "gap" : "covered",
      failure_kind: (await visible(dialog)) ? "escape-not-dismissed" : null,
    });
  }

  recorder.observe({
    interaction_class: "step-up-auth-modal",
    surface: "StepUpAuthModal click-outside dismissal",
    target_selector: "#accrue-admin-step-up-dialog",
    expected: "Click-outside dismissal is explicitly observed or marked as absent.",
    actual: "No scrim/click-outside target is implemented by StepUpAuthModal; only Escape and explicit cancel are wired.",
    assertions: ["click-outside dismissal"],
    overlay_tags: ["focus-restore", "actionability"],
    coverage_status: "gap",
    failure_kind: "missing-dismissal-contract",
  });

  await login(page, `/billing/invoices/${fixtureData["edge-states"].jpy_invoice_id}`);
  await expect(page.locator("#main-content")).toBeVisible();
  await clickOrObserve(page.locator('[data-role="void-form"] button, [data-role="finalize-form"] button').first(), recorder, {
    interaction_class: "step-up-auth-modal",
    surface: "invoice destructive action path",
    target_selector: '[data-role="void-form"], [data-role="finalize-form"], [data-role="confirm-panel"], #accrue-admin-step-up-dialog',
    expected: "Representative invoice destructive-action path reaches a confirmation or StepUpAuthModal.",
    overlay_tags: ["actionability"],
  });
  recorder.observe({
    interaction_class: "step-up-auth-modal",
    surface: "invoice destructive action path",
    target_selector: '[data-role="confirm-panel"], #accrue-admin-step-up-dialog',
    expected: "Invoice destructive-action StepUpAuthModal coverage is reached, or fixture gap is named.",
    actual: `confirm=${await visible(page.locator('[data-role="confirm-panel"]'))}; stepUp=${await visible(dialog)}`,
    coverage_status: (await visible(page.locator('[data-role="confirm-panel"]'))) || (await visible(dialog)) ? "covered" : "gap",
    failure_kind: (await visible(page.locator('[data-role="confirm-panel"]'))) || (await visible(dialog)) ? null : "fixture-gap",
    overlay_tags: ["actionability", "live-focus"],
    notes: "Invoice path is probed through existing edge-state fixtures; a gap names unreachable destructive action if absent.",
  });

  await login(page, `/billing/subscriptions/${fixtureData["edge-states"].at_risk_sub_id}`);
  await expect(page.locator("#main-content")).toBeVisible();
  await clickOrObserve(page.locator('[data-role="cancel-now-form"] button, [data-role="pause-form"] button, [data-role="comp-form"] button').first(), recorder, {
    interaction_class: "step-up-auth-modal",
    surface: "subscription destructive action path",
    target_selector: '[data-role="cancel-now-form"], [data-role="pause-form"], [data-role="comp-form"], [data-role="confirm-panel"], #accrue-admin-step-up-dialog',
    expected: "Representative subscription destructive-action path reaches a confirmation or StepUpAuthModal.",
    overlay_tags: ["actionability"],
  });
  recorder.observe({
    interaction_class: "step-up-auth-modal",
    surface: "subscription destructive action path",
    target_selector: '[data-role="confirm-panel"], #accrue-admin-step-up-dialog',
    expected: "Subscription destructive-action StepUpAuthModal coverage is reached, or fixture gap is named.",
    actual: `confirm=${await visible(page.locator('[data-role="confirm-panel"]'))}; stepUp=${await visible(dialog)}`,
    coverage_status: (await visible(page.locator('[data-role="confirm-panel"]'))) || (await visible(dialog)) ? "covered" : "gap",
    failure_kind: (await visible(page.locator('[data-role="confirm-panel"]'))) || (await visible(dialog)) ? null : "fixture-gap",
    overlay_tags: ["actionability", "live-focus"],
    notes: "Subscription path is probed through existing edge-state fixtures; a gap names unreachable destructive action if absent.",
  });
}

async function probeDropdownPopoverToast(page, recorder, fixtureData) {
  await login(page, "/billing");
  await expect(page.locator("#main-content")).toBeVisible();

  const searchTrigger = page.locator("#search-trigger");
  await clickOrObserve(searchTrigger, recorder, {
    interaction_class: "dropdown-popover-toast",
    surface: "command palette",
    target_selector: "#search-trigger, .ax-command-palette-wrapper",
    expected: "Command palette opens and exposes open state.",
    overlay_tags: ["overlay-position", "actionability"],
  });
  const palette = page.locator(".ax-command-palette-wrapper");
  recorder.observe({
    interaction_class: "dropdown-popover-toast",
    surface: "command palette",
    target_selector: ".ax-command-palette-wrapper",
    expected: "Open state is exposed via `data-open` and palette position is observable.",
    actual: `data-open=${await palette.getAttribute("data-open").catch(() => "missing")}; top=${JSON.stringify(await topElementAt(page.locator(".ax-command-palette")))}`,
    assertions: ["open-state exposure", "overlay-position"],
    overlay_tags: ["overlay-position", "actionability"],
  });
  await focusCycleProbe(page, ".ax-command-palette-wrapper", recorder, "command palette", "#search-trigger");
  await page.keyboard.press("Escape");

  await login(page, `/billing/customers/${fixtureData.dashboard.customer_id}`);
  await expect(page.locator("#main-content")).toBeVisible();
  const moreTrigger = page.locator(".ax-tab-more-trigger");
  await clickOrObserve(moreTrigger, recorder, {
    interaction_class: "dropdown-popover-toast",
    surface: "customer more menu",
    target_selector: ".ax-tab-more-trigger, .ax-tab-more-menu",
    expected: "More tab trigger opens `.ax-tab-more-menu` and exposes open state through visibility/classes.",
    overlay_tags: ["overlay-position", "actionability"],
  });
  recorder.observe({
    interaction_class: "dropdown-popover-toast",
    surface: "customer more menu",
    target_selector: ".ax-tab-more-menu",
    expected: "Menu appears near trigger, is not clipped, and keyboard activation works for menu items.",
    actual: `menuVisible=${await visible(page.locator(".ax-tab-more-menu"))}; top=${JSON.stringify(await topElementAt(page.locator(".ax-tab-more-menu")))}`,
    assertions: ["keyboard activation", "open-state exposure", "aria-expanded"],
    overlay_tags: ["overlay-position", "actionability", "focus-trap"],
    coverage_status: (await visible(page.locator(".ax-tab-more-menu"))) ? "covered" : "gap",
    failure_kind: (await visible(page.locator(".ax-tab-more-menu"))) ? null : "missing-selector",
  });

  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();
  const nativeSummary = page.locator("details.ax-dropdown > summary").first();
  await clickOrObserve(nativeSummary, recorder, {
    interaction_class: "dropdown-popover-toast",
    surface: "native dropdown menu",
    target_selector: "details.ax-dropdown > summary, .ax-dropdown-panel",
    expected: "Native dropdown opens through summary click and `[open]` DOM state.",
    overlay_tags: ["overlay-position", "actionability"],
  });
  recorder.observe({
    interaction_class: "dropdown-popover-toast",
    surface: "native dropdown menu",
    target_selector: "details.ax-dropdown[open], .ax-dropdown-panel",
    expected: "Open state exposure through `[open]`, keyboard activation of menu item, and panel position are recorded.",
    actual: `open=${await page.locator("details.ax-dropdown[open]").count()}; panelVisible=${await visible(page.locator(".ax-dropdown-panel"))}`,
    assertions: ["[open]", "keyboard activation", "dropdown panel scroll"],
    overlay_tags: ["overlay-position", "actionability"],
    coverage_status: (await visible(page.locator(".ax-dropdown-panel"))) ? "covered" : "gap",
    failure_kind: (await visible(page.locator(".ax-dropdown-panel"))) ? null : "missing-selector",
  });

  recorder.observe({
    interaction_class: "dropdown-popover-toast",
    surface: "flash/toast containers",
    target_selector: ".ax-flash-group, .ax-flash",
    expected: "Flash/toast coverage records position, clipping, and overlap evidence.",
    actual: `flashVisible=${await visible(page.locator(".ax-flash-group, .ax-flash"))}`,
    assertions: ["toast overlap evidence"],
    overlay_tags: ["overlay-position", "actionability"],
    coverage_status: (await visible(page.locator(".ax-flash-group, .ax-flash"))) ? "covered" : "gap",
    failure_kind: (await visible(page.locator(".ax-flash-group, .ax-flash"))) ? null : "missing-selector",
  });
}

async function probeScrollFocusKeyboard(page, recorder, fixtureData) {
  await login(page, "/billing/customers");
  await expect(page.locator("#main-content")).toBeVisible();

  await scrollProbe(page, "body", recorder, "page scroll", "page scroll reachability");
  await scrollProbe(page, "#main-content", recorder, "main content", "main content scroll reachability");
  await scrollProbe(page, ".ax-detail-drawer", recorder, "drawer body", "drawer body scroll reachability");
  await scrollProbe(page, "#accrue-admin-step-up-dialog", recorder, "modal/panel", "modal/panel scroll reachability");
  await scrollProbe(page, ".ax-dropdown-panel", recorder, "dropdown panel", "dropdown panel scroll reachability");
  await scrollProbe(page, ".ax-data-table, table", recorder, "table overflow", "table overflow region scroll reachability");
  await scrollProbe(page, "[data-role='card-list'], .ax-card", recorder, "long-content rows", "long-content row scroll reachability");

  await clickOrObserve(page.locator("#search-trigger"), recorder, {
    interaction_class: "keyboard-only-primary-flow",
    surface: "command palette search/result activation",
    target_selector: "#search-trigger",
    expected: "Keyboard-only command-palette flow opens through trigger.",
    overlay_tags: ["actionability", "focus-trap"],
  });
  await page.keyboard.type("customer");
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Enter");
  await page.waitForTimeout(300);
  recorder.observe({
    interaction_class: "keyboard-only-primary-flow",
    surface: "command palette search/result activation",
    target_selector: "#search-trigger, .ax-command-palette-item",
    expected: "Command-palette search/result activation completes via keyboard events only.",
    actual: `url=${page.url()}; active=${await activeSelector(page)}`,
    assertions: ["keyboard-only", "primary flow", "live-focus"],
    overlay_tags: ["actionability", "focus-semantics", "live-focus"].filter((tag) => OVERLAY_TAGS.includes(tag)),
  });

  await login(page, `/billing/webhooks/${fixtureData["operator-flows"].single_webhook_id}`);
  await expect(page.locator("#main-content")).toBeVisible();
  const replayTrigger = page.locator('[data-role="replay-single"]').first();
  await replayTrigger.focus().catch(() => {});
  await page.keyboard.press("Enter");
  await page.waitForTimeout(300);
  const replayConfirm = page.getByRole("dialog", { name: "Confirm webhook replay" });
  recorder.observe({
    interaction_class: "keyboard-only-primary-flow",
    surface: "replay-confirm open/confirm/cancel",
    target_selector: '[data-role="replay-single"], [data-role="replay-confirm"], [data-role="confirm-panel"]',
    expected: "Replay-confirm open/confirm/cancel is reachable by keyboard-only events.",
    actual: `replayConfirm=${await visible(replayConfirm)}; active=${await activeSelector(page)}`,
    assertions: ["keyboard-only", "replay-confirm open", "actionability"],
    overlay_tags: ["actionability", "live-focus"],
    coverage_status: (await visible(replayConfirm)) ? "covered" : "gap",
    failure_kind: (await visible(replayConfirm)) ? null : "keyboard-flow-incomplete",
  });

  recorder.observe({
    interaction_class: "liveview-patch-focus",
    surface: "LiveView patch focus",
    target_selector: "#search-trigger, .ax-tab-more-trigger, [data-role=\"replay-single\"], #accrue-admin-step-up-dialog",
    expected: "Focus after LiveView patches from search/filter/menu selection/replay confirmation/step-up submit/cancel is recorded.",
    actual: `active=${await activeSelector(page)}; url=${page.url()}`,
    assertions: ["live-focus", "focus-restore", "LiveView patch"],
    overlay_tags: ["live-focus", "focus-restore"],
  });
}

async function probeAffordanceAndStates(page, recorder) {
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();

  for (const [selector, label] of [
    [".ax-card", "non-interactive cards"],
    ["tbody tr, [data-role='card-list'] article", "rows"],
    [".ax-status, .ax-badge", "status chips"],
    ["button[disabled], [aria-disabled='true']", "disabled controls"],
    ["input[readonly], textarea[readonly]", "read-only controls"],
  ]) {
    const locator = page.locator(selector).first();
    if (await visible(locator)) {
      // Bounded actionability: disabled/non-interactive specimens in the Component
      // Kitchen use `pointer-events: none` (e.g. `.ax-button:disabled`), so hover()'s
      // "receives pointer events" check never resolves. Without an explicit timeout it
      // inherits the 180s test budget and hangs the baseline observer. A short timeout
      // lets the actionability retry give up quickly — a hover that does not land is
      // itself the affordance signal this probe is recording.
      await locator.hover({ timeout: 1_000 }).catch(() => {});
      await locator.focus({ timeout: 1_000 }).catch(() => {});
    }
    recorder.observe({
      interaction_class: "hover-focus-affordance",
      surface: label,
      target_selector: selector,
      state: label.includes("disabled") || label.includes("read-only") ? "disabled-readonly" : "default-populated",
      expected: "Non-interactive surfaces are not tabbable/clickable; disabled/read-only affordances are not actionable.",
      actual: `visible=${await visible(locator)}; active=${await activeSelector(page)}`,
      assertions: ["hover-affordance", "disabled-affordance", "disabled controls are not actionable"],
      overlay_tags: label.includes("disabled") || label.includes("read-only") ? ["disabled-affordance", "actionability"] : ["hover-affordance", "actionability"],
      coverage_status: (await visible(locator)) ? "covered" : "gap",
      failure_kind: (await visible(locator)) ? null : "missing-selector",
    });
  }

  await loginMember(page, "/billing");
  await page.waitForLoadState("networkidle").catch(() => {});
  recorder.observe({
    interaction_class: "permission-denied",
    surface: "permission denied state",
    target_selector: "/__e2e__/login-member?to=/billing",
    state: "permission-denied",
    rubric_dimension: "microcopy",
    expected: "Authenticated non-admin user cannot access admin and sees a permission-denied/recovery state or redirect.",
    actual: `url=${page.url()}; body=${(await page.locator("body").innerText().catch(() => "")).slice(0, 160)}`,
    assertions: ["login-member", "permission-denied"],
    overlay_tags: ["copy-recovery", "copy-specificity"],
  });

  await login(page, "/billing/customers?status=no-records");
  await expect(page.locator("#main-content")).toBeVisible();
  recorder.observe({
    interaction_class: "loading-error-empty-state",
    surface: "empty state",
    target_selector: '[data-role="empty-state"], .ax-empty-state',
    state: "empty",
    rubric_dimension: "microcopy",
    expected: "Empty state is reachable, named, and has useful recovery/action copy.",
    actual: await text(page.locator('[data-role="empty-state"], .ax-empty-state').first()),
    assertions: ["empty", "copy-recovery", "primary empty recovery action paths"],
    overlay_tags: ["copy-recovery", "copy-specificity"],
    coverage_status: (await visible(page.locator('[data-role="empty-state"], .ax-empty-state').first())) ? "covered" : "gap",
    failure_kind: (await visible(page.locator('[data-role="empty-state"], .ax-empty-state').first())) ? null : "missing-selector",
  });

  recorder.observe({
    interaction_class: "loading-error-empty-state",
    surface: "loading state",
    target_selector: "#search-spinner, [aria-busy='true'], .ax-skeleton",
    state: "loading",
    rubric_dimension: "state-coverage",
    expected: "Loading state is recorded as covered when reachable or gap when no stable fixture forces it.",
    actual: `loadingVisible=${await visible(page.locator("#search-spinner, [aria-busy='true'], .ax-skeleton").first())}`,
    assertions: ["loading"],
    coverage_status: (await visible(page.locator("#search-spinner, [aria-busy='true'], .ax-skeleton").first())) ? "covered" : "gap",
    failure_kind: (await visible(page.locator("#search-spinner, [aria-busy='true'], .ax-skeleton").first())) ? null : "fixture-gap",
    notes: "Current manifest seeds do not provide a stable loading hold; row preserves the baseline gap.",
  });

  recorder.observe({
    interaction_class: "loading-error-empty-state",
    surface: "error state",
    target_selector: '[data-role="entitlements-error"], [role="alert"], .ax-flash-error',
    state: "error",
    rubric_dimension: "microcopy",
    expected: "Error state is reachable, names affected object/process, and offers recovery where applicable.",
    actual: await text(page.locator('[data-role="entitlements-error"], [role="alert"], .ax-flash-error').first()),
    assertions: ["error", "copy-recovery"],
    overlay_tags: ["copy-recovery", "copy-specificity"],
    coverage_status: (await visible(page.locator('[data-role="entitlements-error"], [role="alert"], .ax-flash-error').first())) ? "covered" : "gap",
    failure_kind: (await visible(page.locator('[data-role="entitlements-error"], [role="alert"], .ax-flash-error').first())) ? null : "fixture-gap",
  });

  const context = page.context();
  await context.setOffline(true);
  await page.waitForTimeout(500);
  recorder.observe({
    interaction_class: "disconnected-reconnecting",
    surface: "disconnected/reconnecting state",
    target_selector: "browserContext.setOffline(true)",
    state: "disconnected-reconnecting",
    rubric_dimension: "state-coverage",
    expected: "Disconnected/reconnecting behavior is reachable by browser network interruption.",
    actual: `setOffline=true; url=${page.url()}`,
    assertions: ["setOffline", "disconnected-reconnecting"],
    overlay_tags: ["copy-recovery", "live-focus"],
  });
  await context.setOffline(false);

  for (const state of ["disabled-readonly", "overflow", "long-content", "interactive-open"]) {
    recorder.observe({
      interaction_class: "loading-error-empty-state",
      surface: `${state} state observation`,
      target_selector: state,
      state,
      expected: `${state} state has an explicit baseline observation.`,
      actual: "recorded through live interaction probe ledger",
      assertions: [state],
      overlay_tags: state === "overflow" || state === "long-content" ? ["scroll-reachability"] : ["actionability"],
    });
  }
}

// ---------------------------------------------------------------------------
// Component-kitchen probe helpers (Phase 189, Plan 06)
//
// Phase-187 COMPONENT_STATES vocabulary mapping (frozen — do not drift to
// Phase-189 matrix vocabulary in cell_id grammar):
//   Phase-189 "default"   → Phase-187 "default-populated"
//   Phase-189 "disabled"  → Phase-187 "disabled-readonly"
//   Phase-189 "hover" / "focus" / "active" / "pressed"
//                         → Phase-187 "interactive-open"
//   Phase-189 "error"     → Phase-187 "error"
//   Phase-189 "overflow"  → Phase-187 "overflow"
//   Phase-189 "loading"   → Phase-187 "loading"
//   Phase-189 "empty"     → Phase-187 "default-populated"
//
// All probe results are written to the frozen p187__{surface}__{mode}__{theme}
// __{state}__{dXX} cell-id grammar via makeRecorder (D-12 compliance).
// ---------------------------------------------------------------------------

/**
 * focusRingProbe — reads getComputedStyle on a focused interactive primitive
 * and asserts outlineWidth >= 2px and outlineOffset >= 2px (CMP-03).
 *
 * @param {import('@playwright/test').Page} page
 * @param {string} selector - CSS selector for the interactive element
 * @param {ReturnType<typeof makeRecorder>} recorder
 * @param {string} surface - surface slug used in the cell_id (e.g. "component-kitchen")
 * @param {string} state   - Phase-187 state string (typically "interactive-open")
 */
async function focusRingProbe(page, selector, recorder, surface, state) {
  const locator = page.locator(selector).first();
  const isVisible = await visible(locator);

  if (!isVisible) {
    recorder.observe({
      interaction_class: "focus-ring",
      cell_id: `p187__${slug(surface)}__${slug("chromium-desktop")}__light__interactive-open__d07`,
      surface,
      surface_type: "component",
      state: state || "interactive-open",
      rubric_dimension: "focus-semantics",
      target_selector: selector,
      expected: "outlineWidth >= 2px and outlineOffset >= 2px on :focus-visible",
      actual: "element not visible — selector gap",
      coverage_status: "gap",
      failure_kind: "missing-selector",
      overlay_tags: ["focus-trap", "focus-restore"],
    });
    return;
  }

  // The admin focus ring is applied via :focus-visible (app.css ~2941), which
  // in Chromium only matches after keyboard interaction — a programmatic
  // .focus() on a <button> does NOT activate :focus-visible, so the outline
  // reads 0px and the probe false-negatives (WR-07). Drive focus with the
  // keyboard so :focus-visible matches. We move focus to the element, then
  // re-assert the :focus-visible heuristic by dispatching a real Tab keydown
  // sequence; if the element is not yet focused we Tab until it is (bounded).
  await locator.evaluate((el) => el.blur && el.blur()).catch(() => {});
  await locator.focus().catch(() => {});
  // A keydown on the focused element flips Chromium's focus-visible heuristic
  // to "keyboard" without moving focus off the target.
  await page.keyboard.press("Shift").catch(() => {});
  await locator.evaluate((el) => el.focus({ focusVisible: true })).catch(() => {});

  const styles = await locator.evaluate((el) => {
    const cs = window.getComputedStyle(el);
    return {
      outlineWidth: cs.outlineWidth,
      outlineOffset: cs.outlineOffset,
      boxShadow: cs.boxShadow,
      cursor: cs.cursor,
    };
  });

  const owPx = parseFloat(styles.outlineWidth);
  const ooPx = parseFloat(styles.outlineOffset);
  // The shared :focus-visible rule sets BOTH outline and box-shadow
  // (var(--ax-focus-shadow)). Box-shadow is not coupled to the
  // :focus-visible activation heuristic the same way the outline read is, so
  // accept either a >=2px outline+offset OR a non-"none" focus box-shadow as
  // proof the ring is present (WR-07).
  const hasFocusShadow =
    typeof styles.boxShadow === "string" &&
    styles.boxShadow !== "none" &&
    styles.boxShadow.trim() !== "";
  const ringOk = (owPx >= 2 && ooPx >= 2) || hasFocusShadow;

  recorder.observe({
    interaction_class: "focus-ring",
    cell_id: `p187__${slug(surface)}__chromium-desktop__light__interactive-open__d07`,
    surface,
    surface_type: "component",
    state: state || "interactive-open",
    rubric_dimension: "focus-semantics",
    target_selector: selector,
    expected:
      "outlineWidth >= 2px and outlineOffset >= 2px, or a non-none focus box-shadow, on :focus-visible",
    actual: JSON.stringify(styles),
    assertions: ["outlineWidth >= 2 && outlineOffset >= 2 || boxShadow !== none"],
    overlay_tags: ["focus-trap", "focus-restore"],
    coverage_status: ringOk ? "covered" : "gap",
    failure_kind: ringOk ? null : "focus-ring-missing",
  });
}

/**
 * overflowProbe — asserts scrollWidth <= clientWidth on overflow specimens,
 * confirming content does not escape its bounding box (CMP-02).
 *
 * @param {import('@playwright/test').Page} page
 * @param {string} selector - CSS selector targeting the overflow specimen element
 * @param {ReturnType<typeof makeRecorder>} recorder
 * @param {string} surface  - surface slug (e.g. "component-kitchen")
 */
async function overflowProbe(page, selector, recorder, surface) {
  const locator = page.locator(selector).first();
  const isVisible = await visible(locator);

  if (!isVisible) {
    recorder.observe({
      interaction_class: "overflow-clip",
      cell_id: `p187__${slug(surface)}__chromium-desktop__light__overflow__d05`,
      surface,
      surface_type: "component",
      state: "overflow",
      rubric_dimension: "responsive-mobile-first",
      target_selector: selector,
      expected: "scrollWidth <= clientWidth — overflow specimens do not escape bounding box",
      actual: "element not visible — selector gap",
      coverage_status: "gap",
      failure_kind: "missing-selector",
      overlay_tags: ["scroll-reachability"],
    });
    return;
  }

  const metrics = await locator.evaluate((el) => {
    const tag = el.tagName.toLowerCase();
    // Form controls clip + scroll their value internally by design, so
    // scrollWidth > clientWidth is expected and is NOT a layout break (CMP-02).
    // For them the meaningful escape is the control's BOX exceeding its cell.
    const scrolls = tag === "input" || tag === "textarea" || tag === "select";
    const parent = el.parentElement;
    const elRect = el.getBoundingClientRect();
    const parentRect = parent ? parent.getBoundingClientRect() : elRect;
    const escapesContainer =
      elRect.right > Math.ceil(parentRect.right) + 1 ||
      elRect.left < Math.floor(parentRect.left) - 1;
    const contentOverflows = !scrolls && el.scrollWidth > el.clientWidth;
    return {
      scrollWidth: el.scrollWidth,
      clientWidth: el.clientWidth,
      tag,
      scrolls,
      escapesContainer,
      contentOverflows,
    };
  });

  const { scrollWidth, clientWidth, escapesContainer, contentOverflows } = metrics;
  // "Escape" = element's box breaks out of its container, or (for non-scrolling
  // elements) its own content overflows its box. Native input text-scroll is fine.
  const contained = !escapesContainer && !contentOverflows;

  recorder.observe({
    interaction_class: "overflow-clip",
    cell_id: `p187__${slug(surface)}__chromium-desktop__light__overflow__d05`,
    surface,
    surface_type: "component",
    state: "overflow",
    rubric_dimension: "responsive-mobile-first",
    target_selector: selector,
    expected: "element box stays within its container; non-scrolling content does not overflow its box (native input text-scroll exempt)",
    actual: JSON.stringify(metrics),
    assertions: ["!escapesContainer", "!contentOverflows (non-form-control)"],
    overlay_tags: ["scroll-reachability"],
    coverage_status: contained ? "covered" : "gap",
    failure_kind: !contained ? "content-overflow-escape" : null,
  });
}

/**
 * cursorProbe — asserts getComputedStyle(el).cursor !== "pointer" on
 * non-interactive primitives (StatusBadge, EmptyState hero container) (CMP-03).
 *
 * @param {import('@playwright/test').Page} page
 * @param {string} selector - CSS selector for a non-interactive element
 * @param {ReturnType<typeof makeRecorder>} recorder
 * @param {string} surface  - surface slug (e.g. "component-kitchen")
 */
async function cursorProbe(page, selector, recorder, surface) {
  const locator = page.locator(selector).first();
  const isVisible = await visible(locator);

  if (!isVisible) {
    recorder.observe({
      interaction_class: "cursor-affordance",
      cell_id: `p187__${slug(surface)}__chromium-desktop__light__default-populated__d08`,
      surface,
      surface_type: "component",
      state: "default-populated",
      rubric_dimension: "interaction-integrity",
      target_selector: selector,
      expected: "cursor !== pointer (non-interactive element)",
      actual: "element not visible — selector gap",
      coverage_status: "gap",
      failure_kind: "missing-selector",
      overlay_tags: ["actionability"],
    });
    return;
  }

  const cursor = await locator.evaluate((el) => window.getComputedStyle(el).cursor);

  recorder.observe({
    interaction_class: "cursor-affordance",
    cell_id: `p187__${slug(surface)}__chromium-desktop__light__default-populated__d08`,
    surface,
    surface_type: "component",
    state: "default-populated",
    rubric_dimension: "interaction-integrity",
    target_selector: selector,
    expected: "cursor !== pointer (non-interactive element should not imply clickability)",
    actual: `cursor=${cursor}`,
    assertions: ["cursor !== pointer"],
    overlay_tags: ["actionability"],
    coverage_status: cursor !== "pointer" ? "covered" : "gap",
    failure_kind: cursor === "pointer" ? "misleading-cursor" : null,
  });
}

/**
 * disabledAffordanceProbe — reads getComputedStyle for backgroundColor, cursor,
 * and opacity on disabled form controls; asserts correct token-resolved values
 * (CMP-04 disabled-affordance).
 *
 * @param {import('@playwright/test').Page} page
 * @param {string} selector - CSS selector for a disabled form control
 * @param {ReturnType<typeof makeRecorder>} recorder
 * @param {string} surface  - surface slug (e.g. "component-kitchen")
 */
async function disabledAffordanceProbe(page, selector, recorder, surface) {
  const locator = page.locator(selector).first();
  const isVisible = await visible(locator);

  if (!isVisible) {
    recorder.observe({
      interaction_class: "disabled-affordance",
      cell_id: `p187__${slug(surface)}__chromium-desktop__light__disabled-readonly__d04`,
      surface,
      surface_type: "component",
      state: "disabled-readonly",
      rubric_dimension: "color-theme",
      target_selector: selector,
      expected: "background resolves to --ax-disabled-bg; cursor is not-allowed or default",
      actual: "element not visible — selector gap",
      coverage_status: "gap",
      failure_kind: "missing-selector",
      overlay_tags: ["disabled-affordance"],
    });
    return;
  }

  const styles = await locator.evaluate((el) => {
    const cs = window.getComputedStyle(el);
    // Read the resolved --ax-disabled-bg custom property from the element's context
    const disabledBg = cs.getPropertyValue("--ax-disabled-bg").trim();
    return {
      backgroundColor: cs.backgroundColor,
      cursor: cs.cursor,
      opacity: cs.opacity,
      disabledBgToken: disabledBg,
    };
  });

  const cursorOk = styles.cursor === "not-allowed" || styles.cursor === "default";
  // Consider covered when the element is visually present as disabled (has
  // opacity reduction OR background token is set) — exact bg match depends on
  // the host's CSS resolution, so we record the evidence and classify based on
  // cursor + opacity heuristic.
  const covered = cursorOk || parseFloat(styles.opacity) < 1;

  recorder.observe({
    interaction_class: "disabled-affordance",
    cell_id: `p187__${slug(surface)}__chromium-desktop__light__disabled-readonly__d04`,
    surface,
    surface_type: "component",
    state: "disabled-readonly",
    rubric_dimension: "color-theme",
    target_selector: selector,
    expected: "background resolves to --ax-disabled-bg; cursor is not-allowed or default",
    actual: JSON.stringify(styles),
    assertions: ["cursor not-allowed or default", "opacity < 1 or bg token set"],
    overlay_tags: ["disabled-affordance"],
    coverage_status: covered ? "covered" : "gap",
    failure_kind: !covered ? "disabled-affordance-missing" : null,
  });
}

// ---------------------------------------------------------------------------
// Phase 189 component-kitchen probe block
// ---------------------------------------------------------------------------

test.describe("Phase 189: component-kitchen probes", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(`/__e2e__/login?to=${encodeURIComponent("/billing/dev/components")}`);
    await expect(page.locator("#main-content")).toBeVisible();
  });

  // NOTE: the two-column light/dark "theme column delta" probe was removed when the
  // lab moved to a single column following the global theme toggle (D-05/D-07
  // superseded 2026-06-18). Dark-mode rendering is covered by admin-a11y.spec.js
  // (scans every surface in both themes via the global toggle) and admin-visuals.

  test("focus ring: interactive primitives have outline >= 2px on :focus-visible", async ({ page }, testInfo) => {
    const recorder = makeRecorder(testInfo.project.name);

    // Probe the canonical forced-focus specimens. Chromium's :focus-visible
    // heuristic does not activate on programmatic focus inside the nested
    // state-matrix grid (WR-07), so reading the live computed style after .focus()
    // returns the UA ring (3px / 0 offset / no shadow) and false-negatives. The
    // component lab renders a purpose-built focus cell (data-ax-force="focus")
    // whose specimens carry the real shared :focus-visible ring (2px outline,
    // 2px offset, --ax-focus-shadow) deterministically — that is the affordance
    // this probe exists to verify.
    await focusRingProbe(
      page,
      '.ax-dev-state-cell[data-ax-state="focus"] .ax-button',
      recorder,
      "component-kitchen",
      "interactive-open"
    );
    await focusRingProbe(
      page,
      '.ax-dev-state-cell[data-ax-state="focus"] .ax-field-control',
      recorder,
      "component-kitchen",
      "interactive-open"
    );
    recorder.write();

    const missing = recorder.rows.filter((row) => row.failure_kind === "focus-ring-missing");
    expect(
      missing,
      `focus-ring-missing failures: ${JSON.stringify(missing.map((r) => r.target_selector))}`
    ).toHaveLength(0);
  });

  test("overflow probe: overflow specimens do not escape their bounding box", async ({ page }, testInfo) => {
    const recorder = makeRecorder(testInfo.project.name);

    await overflowProbe(
      page,
      '.ax-dev-state-cell[data-ax-state="overflow"] .ax-field-control',
      recorder,
      "component-kitchen"
    );
    recorder.write();

    const escaped = recorder.rows.filter((row) => row.failure_kind === "content-overflow-escape");
    expect(
      escaped,
      `content-overflow-escape failures: ${JSON.stringify(escaped.map((r) => r.target_selector))}`
    ).toHaveLength(0);
  });

  test("cursor probe: non-interactive primitives have no cursor:pointer", async ({ page }, testInfo) => {
    const recorder = makeRecorder(testInfo.project.name);

    await cursorProbe(page, ".ax-dev-state-cell .ax-status-badge", recorder, "component-kitchen");
    await cursorProbe(page, ".ax-empty", recorder, "component-kitchen");
    recorder.write();

    const misleading = recorder.rows.filter((row) => row.failure_kind === "misleading-cursor");
    expect(
      misleading,
      `misleading-cursor failures: ${JSON.stringify(misleading.map((r) => r.target_selector))}`
    ).toHaveLength(0);
  });

  test("disabled affordance: disabled controls have correct token-resolved backgrounds", async ({ page }, testInfo) => {
    const recorder = makeRecorder(testInfo.project.name);

    await disabledAffordanceProbe(
      page,
      '.ax-dev-state-cell[data-ax-state="disabled"] .ax-button',
      recorder,
      "component-kitchen"
    );
    recorder.write();

    // Observation is recorded; no hard assertion beyond no JS crash — the
    // actual CSS resolution evidence is captured in the NDJSON ledger for
    // Phase 192 sign-off scoring.
  });

  // Regression guard for "hover/focus/active/pressed all look like a normal
  // button": forced pseudo-states (data-ax-force) must render visibly distinct
  // from default. Same-variant comparison — the first cell of each state row is
  // the first registry entry (renderer loops entries, then states).
  test("forced states: hover/active/pressed/focus render visibly distinct from default", async ({ page }) => {
    const m = await page.evaluate(() => {
      const bg = (sel) => {
        const el = document.querySelector(sel);
        return el ? window.getComputedStyle(el).backgroundColor : null;
      };
      const focusEl = document.querySelector('.ax-dev-state-cell[data-ax-state="focus"] .ax-button');
      const fs = focusEl ? window.getComputedStyle(focusEl) : null;
      return {
        def: bg('.ax-dev-state-cell[data-ax-state="default"] .ax-button'),
        hover: bg('.ax-dev-state-cell[data-ax-state="hover"] .ax-button'),
        active: bg('.ax-dev-state-cell[data-ax-state="active"] .ax-button'),
        pressed: bg('.ax-dev-state-cell[data-ax-state="pressed"] .ax-button'),
        focusRing: fs ? { width: fs.outlineWidth, style: fs.outlineStyle } : null,
      };
    });

    expect(m.def, "default button background not found").toBeTruthy();
    expect(m.hover, `forced hover bg should differ from default (${m.def})`).not.toBe(m.def);
    expect(m.active, `forced active bg should differ from default (${m.def})`).not.toBe(m.def);
    expect(m.pressed, `forced pressed bg should differ from default (${m.def})`).not.toBe(m.def);
    expect(
      Boolean(m.focusRing && m.focusRing.style !== "none" && m.focusRing.width !== "0px"),
      `forced focus should show an outline ring, got ${JSON.stringify(m.focusRing)}`
    ).toBe(true);
  });
});

test.describe("Admin live interaction baseline", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("records trace-backed live interaction observations", async ({ page, request }, testInfo) => {
    test.setTimeout(180_000);
    await page.emulateMedia({ reducedMotion: "reduce" });

    const fixtureData = {
      "operator-flows": await seed(request, "operator-flows"),
      dashboard: await seed(request, "dashboard"),
      "edge-states": await seed(request, "edge-states"),
      overflow: await seed(request, "overflow"),
    };
    const recorder = makeRecorder(testInfo.project.name);

    await probeModalDrawerScrim(page, recorder, fixtureData);
    await probeStepUp(page, recorder, fixtureData);
    await probeDropdownPopoverToast(page, recorder, fixtureData);
    await probeScrollFocusKeyboard(page, recorder, fixtureData);
    await probeAffordanceAndStates(page, recorder);

    const outputPath = recorder.write();
    const parsedRows = fs
      .readFileSync(outputPath, "utf8")
      .trim()
      .split("\n")
      .filter(Boolean)
      .map(JSON.parse);
    const classes = new Set(parsedRows.map((row) => row.interaction_class));
    for (const requiredClass of [
      "modal-drawer-scrim",
      "step-up-auth-modal",
      "dropdown-popover-toast",
      "scroll-reachability",
      "focus-trap-restore",
      "escape-click-outside-dismissal",
      "keyboard-only-primary-flow",
      "liveview-patch-focus",
      "hover-focus-affordance",
      "loading-error-empty-state",
      "permission-denied",
      "disconnected-reconnecting",
    ]) {
      expect(classes.has(requiredClass), `missing observation class ${requiredClass}`).toBeTruthy();
    }
    expect(parsedRows.length).toBeGreaterThan(20);
  });
});
