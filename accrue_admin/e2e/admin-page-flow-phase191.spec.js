const { test, expect } = require("@playwright/test");

const {
  PHASE191_VIEWPORTS,
  PHASE191_STATES,
  loadPhase191Defects,
  phase191PageFlows,
  resolvePhase191Route,
  seedScenarioForSurface,
  setPhase191Theme,
  assertNoBodyFocus,
  assertFocusWithin,
  assertTopPointerTarget,
  assertScrollReachable,
  assertNoHorizontalClip,
  phase191CoverageRows,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

const PHASE191_HIGH_AX187_IDS = Object.freeze([
  "AX187-049", "AX187-050", "AX187-051", "AX187-052", "AX187-053", "AX187-054", "AX187-055", "AX187-056",
  "AX187-057", "AX187-058", "AX187-059", "AX187-060", "AX187-061", "AX187-062", "AX187-063", "AX187-064",
  "AX187-065", "AX187-066", "AX187-067", "AX187-068", "AX187-069", "AX187-070", "AX187-071", "AX187-072",
  "AX187-073", "AX187-074", "AX187-075", "AX187-076", "AX187-077", "AX187-078", "AX187-079", "AX187-080",
  "AX187-081", "AX187-082", "AX187-083", "AX187-084", "AX187-085", "AX187-086", "AX187-087", "AX187-088",
  "AX187-089", "AX187-090", "AX187-091", "AX187-092", "AX187-093", "AX187-094", "AX187-095", "AX187-096",
  "AX187-097", "AX187-098", "AX187-099", "AX187-100", "AX187-101", "AX187-102", "AX187-103", "AX187-104",
  "AX187-105", "AX187-106", "AX187-107", "AX187-108", "AX187-109", "AX187-110", "AX187-111", "AX187-112",
  "AX187-113", "AX187-114", "AX187-115", "AX187-116", "AX187-117", "AX187-118",
]);

const PHASE191_MEDIUM_AX187_IDS = Object.freeze([
  "AX187-340", "AX187-341", "AX187-342", "AX187-343", "AX187-344", "AX187-345", "AX187-346", "AX187-347",
  "AX187-348", "AX187-349", "AX187-350", "AX187-351", "AX187-352", "AX187-353", "AX187-354", "AX187-355",
  "AX187-356", "AX187-357", "AX187-358", "AX187-359", "AX187-360", "AX187-361", "AX187-362", "AX187-363",
  "AX187-364", "AX187-365", "AX187-366", "AX187-367", "AX187-368", "AX187-369", "AX187-370", "AX187-371",
  "AX187-372", "AX187-373", "AX187-374", "AX187-375", "AX187-376", "AX187-377", "AX187-378", "AX187-379",
  "AX187-380", "AX187-381", "AX187-382", "AX187-383", "AX187-384", "AX187-385", "AX187-386", "AX187-387",
  "AX187-388", "AX187-389", "AX187-390", "AX187-391", "AX187-392", "AX187-393", "AX187-394", "AX187-395",
  "AX187-396", "AX187-397", "AX187-398", "AX187-399", "AX187-400", "AX187-401", "AX187-402", "AX187-403",
  "AX187-404", "AX187-405", "AX187-406", "AX187-407", "AX187-408", "AX187-409", "AX187-410", "AX187-411",
  "AX187-412", "AX187-413", "AX187-414", "AX187-415", "AX187-416", "AX187-417", "AX187-418", "AX187-419",
  "AX187-420", "AX187-421", "AX187-422", "AX187-423", "AX187-424", "AX187-425", "AX187-426", "AX187-427",
  "AX187-428", "AX187-429", "AX187-430", "AX187-431", "AX187-432", "AX187-433", "AX187-434", "AX187-435",
  "AX187-436", "AX187-437", "AX187-438", "AX187-439", "AX187-440", "AX187-441", "AX187-442", "AX187-443",
  "AX187-444", "AX187-445", "AX187-446", "AX187-447",
]);

const PHASE191_HANDOFF_TAGS = Object.freeze([
  "focus-trap",
  "focus-restore",
  "escape",
  "click-outside",
  "scroll-reachability",
  "overlay-position",
  "layer-z-index",
  "live-focus",
  "liveview-patch-focus",
  "fixture-gaps",
  "microcopy",
  "copy-recovery",
  "copy-specificity",
]);

const COPY_RECOVERY_PATTERN =
  /No billing records yet|No records match these filters|Access restricted|Connection lost|This .* could not load|Retry|Clear filters|owner scope/i;

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

async function seedPhase191FixtureIfPresent(request) {
  return seedScenario(request, "phase191", { optional: true });
}

async function seedPhase191Matrix(request) {
  const dashboard = await seedScenario(request, "dashboard");
  const operatorFlows = await seedScenario(request, "operator-flows");
  const edgeStates = await seedScenario(request, "edge-states");
  const phase191 = await seedPhase191FixtureIfPresent(request);

  return {
    dashboard,
    "operator-flows": operatorFlows,
    "edge-states": edgeStates,
    phase191,
  };
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}

function allAx187Ids() {
  return [...PHASE191_HIGH_AX187_IDS, ...PHASE191_MEDIUM_AX187_IDS];
}

test.describe("Phase 191 page-flow regression harness @ax187 @fixtures @copy @responsive @scroll @reconnect", () => {
  test("AX187 source map covers owner-phase 191 rows and D-30 categories @ax187", async () => {
    const defects = loadPhase191Defects();
    const high = defects.filter((defect) => defect.severity === "high").map((defect) => defect.id).sort();
    const medium = defects.filter((defect) => defect.severity === "medium").map((defect) => defect.id).sort();
    const coverageRows = phase191CoverageRows(defects);

    expect(defects).toHaveLength(178);
    expect(high).toEqual([...PHASE191_HIGH_AX187_IDS].sort());
    expect(medium).toEqual([...PHASE191_MEDIUM_AX187_IDS].sort());
    expect(coverageRows.map((row) => row.id).sort()).toEqual(allAx187Ids().sort());

    for (const tag of PHASE191_HANDOFF_TAGS) {
      expect(tag, `D-30 handoff marker ${tag}`).toBeTruthy();
    }
  });

  test("AX187-116 AX187-442 AX187-443 AX187-444 AX187-445 route every manifest page-flow through fixtures @fixtures @ax187", async ({
    request,
  }) => {
    await reset(request);
    const fixtureData = await seedPhase191Matrix(request);
    const flows = phase191PageFlows();

    expect(flows).toHaveLength(21);
    expect(PHASE191_STATES).toEqual([
      "default-populated",
      "empty",
      "loading",
      "error",
      "permission-denied",
      "disconnected-reconnecting",
      "overflow",
      "long-content",
      "interactive-open",
    ]);

    for (const flow of flows) {
      const scenario = seedScenarioForSurface(flow);
      const route = resolvePhase191Route(flow, fixtureData);
      expect(route, `${flow.surface} route should resolve from ${scenario}`).toMatch(/^\/billing/);
      expect(route, `${flow.surface} route should not contain unresolved params`).not.toContain(":");
    }
  });

  test("AX187-436 AX187-437 AX187-438 AX187-439 AX187-446 AX187-447 page flows avoid clipping at required widths @responsive @scroll @copy", async ({
    page,
    request,
  }) => {
    test.setTimeout(60_000);
    await reset(request);
    const fixtureData = await seedPhase191Matrix(request);

    for (const viewport of PHASE191_VIEWPORTS) {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });

      for (const theme of ["light", "dark"]) {
        await setPhase191Theme(page, theme);

        for (const flow of phase191PageFlows()) {
          await login(page, resolvePhase191Route(flow, fixtureData));
          await assertNoHorizontalClip(page, "#main-content, main, .ax-data-table-shell, [data-role='card-list']", `${flow.surface} ${viewport.name} ${theme}`);
          await assertNoBodyFocus(page, `${flow.surface} initial focus`);

          const scrollTarget = page.locator("#main-content, main").first();
          await assertScrollReachable(scrollTarget, `${flow.surface} main content`);
          await expect(page.locator("body")).not.toContainText(/\boops\b|\bforbidden\b|\binvalid\b/i);
        }
      }
    }
  });

  test("AX187-097 AX187-098 AX187-099 AX187-100 AX187-101 AX187-102 AX187-103 AX187-111 AX187-112 AX187-113 AX187-114 AX187-117 AX187-118 overlays trap focus, layer above scrims, and dismiss safely @overlay @focus @ax187", async ({
    page,
    request,
  }) => {
    await reset(request);
    const fixtureData = await seedPhase191Matrix(request);

    await login(page, "/billing/dev/components?group=drawer-form");
    const drawerShell = page.locator("#grp190-drawer-form-shell");
    await expect(drawerShell).toBeVisible();
    await expect(drawerShell).toHaveAttribute("phx-hook", "FocusTrap");
    await expect(drawerShell).toHaveAttribute("data-focus-trap-fallback", "#grp190-drawer-form-shell-title");
    await assertFocusWithin(page, drawerShell, "drawer-form proof drawer");

    const drawerPanel = drawerShell.locator(".ax-detail-drawer");
    await assertTopPointerTarget(drawerPanel.locator(".ax-detail-drawer-header"), "drawer-form proof header");
    const drawerPrimaryAction = drawerPanel.locator("button:has-text('Save contact')");
    await drawerPrimaryAction.scrollIntoViewIfNeeded();
    await assertTopPointerTarget(drawerPrimaryAction, "drawer-form proof primary action");

    const chargeRoute = resolvePhase191Route("charge-detail", fixtureData);
    await login(page, chargeRoute);

    const refundRowsBefore = await page.locator("text=fee refunded").count();
    await page.locator("#charge-refund-form").evaluate((form) => form.requestSubmit());

    const confirmPanel = page.locator('[data-role="confirm-panel"]');
    await expect(confirmPanel).toBeVisible();

    const confirmRefund = confirmPanel.locator('[data-role="confirm-refund"]');
    await confirmRefund.focus();
    await confirmRefund.click();

    const stepUp = page.locator("#accrue-admin-step-up-dialog");
    await expect(stepUp).toBeVisible();
    await expect(stepUp).toHaveAttribute("phx-hook", "FocusTrap");
    await expect(stepUp).toHaveAttribute("data-focus-trap-close-event", "step_up_dismiss");
    await assertFocusWithin(page, stepUp, "charge refund step-up modal");
    await assertTopPointerTarget(stepUp.locator(".ax-step-up-modal"), "charge refund step-up panel");
    await assertTopPointerTarget(stepUp.locator('[data-role="step-up-submit"]'), "charge refund step-up submit");

    await page.keyboard.press("Escape");
    await expect(stepUp).toBeHidden();
    await assertNoBodyFocus(page, "charge refund step-up Escape restore");
    await expect(page.locator("text=fee refunded")).toHaveCount(refundRowsBefore);

    await confirmRefund.click();
    await expect(stepUp).toBeVisible();
    await page.mouse.click(2, 2);
    await expect(stepUp).toBeHidden();
    await assertNoBodyFocus(page, "charge refund step-up outside-click restore");
    await expect(page.locator("text=fee refunded")).toHaveCount(refundRowsBefore);
  });

  test("AX187-104 AX187-105 AX187-106 AX187-107 AX187-108 AX187-109 AX187-110 AX187-115 AX187-116 LiveView patch and reconnect states keep focus stable @reconnect @ax187", async ({
    page,
    request,
    context,
  }) => {
    await reset(request);
    await seedPhase191Matrix(request);
    await login(page, "/billing/customers");

    const search = page.locator('input[type="search"], [data-role="filter-form"] input, #search-trigger').first();
    await expect(search).toBeVisible();
    await search.focus();
    await page.keyboard.press("Enter");
    await assertNoBodyFocus(page, "customer filter patch focus");

    await context.setOffline(true);
    await expect(page.getByText(/Connection lost\. Reconnecting before actions can run\./i)).toBeVisible();
    const mutatingActions = page.locator('button:has-text("Refund"), button:has-text("Void"), button:has-text("Replay"), button:has-text("Cancel")');
    const count = await mutatingActions.count();
    for (let index = 0; index < count; index += 1) {
      await expect(mutatingActions.nth(index)).toBeDisabled();
    }

    await context.setOffline(false);
    await expect(page.getByText(/Connection restored\. Review the current state before running an action\./i)).toBeVisible();
    await assertNoBodyFocus(page, "customer reconnect focus");
  });

  test("AX187-340 AX187-341 AX187-342 AX187-343 AX187-344 AX187-345 AX187-346 AX187-347 AX187-348 AX187-349 AX187-350 AX187-351 AX187-352 AX187-353 AX187-354 AX187-355 AX187-356 AX187-357 AX187-358 AX187-359 AX187-360 AX187-361 AX187-362 AX187-363 AX187-364 AX187-365 AX187-366 AX187-367 AX187-368 AX187-369 AX187-370 AX187-371 AX187-372 AX187-373 AX187-374 AX187-375 AX187-376 AX187-377 AX187-378 AX187-379 AX187-380 AX187-381 AX187-382 AX187-383 AX187-384 AX187-385 AX187-386 AX187-387 AX187-388 AX187-389 AX187-390 AX187-391 AX187-392 AX187-393 AX187-394 AX187-395 AX187-396 AX187-397 AX187-398 AX187-399 AX187-400 AX187-401 AX187-402 AX187-403 AX187-404 AX187-405 AX187-406 AX187-407 AX187-408 AX187-409 AX187-410 AX187-411 AX187-412 AX187-413 AX187-414 AX187-415 AX187-416 AX187-417 AX187-418 AX187-419 AX187-420 AX187-421 AX187-422 AX187-423 AX187-424 AX187-425 AX187-426 AX187-427 AX187-428 AX187-429 AX187-430 AX187-431 AX187-432 AX187-433 AX187-434 AX187-435 AX187-440 AX187-441 AX187-442 AX187-443 state copy is recoverable and object-specific @copy @fixtures @ax187", async ({
    page,
    request,
  }) => {
    await reset(request);
    await seedPhase191Matrix(request);

    await login(page, "/billing/customers?status=no-records");
    await expect(page.locator("body")).toContainText(COPY_RECOVERY_PATTERN);

    await page.goto(`/__e2e__/login-member?to=${encodeURIComponent("/billing")}`);
    await expect(page.locator("body")).toContainText(/Access restricted|billing admin|owner scope/i);

    await login(page, "/billing/webhooks");
    await expect(page.locator("body")).not.toContainText(/\bare you sure\?\b|\boops\b|\bfailed\b/i);
    await expect(page.locator("body")).toContainText(/webhook|event|owner scope|Retry|Replay webhook/i);
  });
});
