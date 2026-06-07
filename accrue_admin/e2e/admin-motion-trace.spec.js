/**
 * admin-motion-trace.spec.js — Playwright trace capture for animated motion surfaces
 *
 * Captures full Playwright traces for the 4 animated surfaces in Accrue Admin
 * to allow manual and automated review of enter/exit transitions, CSS animation
 * correctness, and motion token compliance.
 *
 * TRACE REVIEW:
 *   Artifacts: test-results/<test-name>/trace.zip
 *   Review with: npx playwright show-trace test-results/.../trace.zip
 *
 * SURFACES COVERED:
 *   1. Command palette  — #search-trigger (phx-click="open")
 *   2. Dropdown         — details.ax-dropdown > summary (native <details> disclosure)
 *   3. Nav group collapse — [data-collapse-toggle="true"] (sidebar group toggle)
 *   4. Webhook replay drawer — [data-role="replay-single"] (phx-click="prepare_replay")
 *
 * trace: "on" is FILE-SCOPED via test.use() — does NOT modify playwright.config.js.
 * The global config retains trace: "retain-on-failure"; this override forces trace
 * recording for every test in this file for motion capture purposes only.
 */

const { test, expect } = require("@playwright/test");

// trace: "on" — file-scoped override for motion capture (global config has "retain-on-failure")
test.use({ trace: "on" });

// ----------------------------------------------------------------------------
// Helpers — copied verbatim from admin-visuals.spec.js
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Motion trace suite
// ----------------------------------------------------------------------------
test.describe("Motion trace — animated surface capture", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  // --------------------------------------------------------------------------
  // 1. Command palette open/close
  // Surface: global_search.ex — .ax-command-palette-wrapper data-open="true/false"
  // Trigger: #search-trigger button (topbar.ex line 25-26), phx-click="open"
  // --------------------------------------------------------------------------
  test("motion trace — command palette open/close", async ({ page, request }) => {
    // Trace artifact: test-results/motion-trace-command-palette-open-close/trace.zip
    // Review with: npx playwright show-trace test-results/.../trace.zip

    await seed(request, "operator-flows");
    await login(page, "/billing");
    await expect(page.locator("#main-content")).toBeVisible();

    // Open the command palette via the search trigger in the topbar
    await page.click("#search-trigger");

    // The palette wrapper is always in the DOM; data-open toggles to "true" when open
    const palette = page.locator(".ax-command-palette-wrapper");
    await expect(palette).toBeVisible();
    await expect(palette).toHaveAttribute("data-open", "true");

    // Close via Escape (standard keyboard dismiss for command palettes)
    await page.keyboard.press("Escape");
    await expect(palette).toHaveAttribute("data-open", "false");
  });

  // --------------------------------------------------------------------------
  // 2. Customer overflow menu open/close
  // Surface: customer_live.ex — .ax-tab-more-menu
  // Trigger: .ax-tab-more-trigger
  // --------------------------------------------------------------------------
  test("motion trace — customer more menu open/close", async ({ page, request }) => {
    // Trace artifact: test-results/motion-trace-customer-more-menu-open-close/trace.zip
    // Review with: npx playwright show-trace test-results/.../trace.zip

    const dash = await seed(request, "dashboard");
    await login(page, `/billing/customers/${dash.customer_id}`);
    await expect(page.locator("#main-content")).toBeVisible();

    const trigger = page.locator(".ax-tab-more-trigger");
    await expect(trigger).toBeVisible();

    await trigger.click();

    const panel = page.locator(".ax-tab-more-menu");
    await expect(panel).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(panel).toBeHidden();
  });

  // --------------------------------------------------------------------------
  // 3. Nav group collapse/expand
  // Surface: sidebar.ex — ax-sidebar-group-toggle, aria-controls → sidebar-group-links-{slug}
  // Trigger: [data-collapse-toggle="true"] button (Recovery, Developer, or Catalog groups)
  // --------------------------------------------------------------------------
  test("motion trace — nav group collapse/expand", async ({ page, request }) => {
    // Trace artifact: test-results/motion-trace-nav-group-collapse-expand/trace.zip
    // Review with: npx playwright show-trace test-results/.../trace.zip

    await seed(request, "operator-flows");
    await login(page, "/billing");
    await expect(page.locator("#main-content")).toBeVisible();

    const toggleButton = page.locator('[data-collapse-toggle="true"]').first();
    await expect(toggleButton).toBeVisible();

    // Read which list element this toggle controls
    const controlledId = await toggleButton.getAttribute("aria-controls");
    // Fail loudly if the attribute is absent rather than silently skipping assertions
    expect(controlledId, "collapse toggle must have data-controls attribute").toBeTruthy();

    const controlledList = page.locator(`#${controlledId}`);

    if ((await toggleButton.getAttribute("aria-expanded")) !== "true") {
      await toggleButton.click();
      await expect(toggleButton).toHaveAttribute("aria-expanded", "true");
      await expect(controlledList).toBeVisible();
    }

    // Collapse the group; the hook applies hidden after the short opacity
    // transition so assistive technology skips the links once closed.
    await toggleButton.click();
    await expect(toggleButton).toHaveAttribute("aria-expanded", "false");
    await expect(controlledList).toBeHidden();

    // Re-expand the group (second click reveals the link list)
    await toggleButton.click();

    await expect(controlledList).toBeVisible();
  });

  // --------------------------------------------------------------------------
  // 4. Webhook replay confirmation open
  // Surface: webhook_live.ex — [data-role="replay-confirm"]
  // Trigger: [data-role="replay-single"] (webhook_live.ex line 162-164, phx-click="prepare_replay")
  // --------------------------------------------------------------------------
  test("motion trace — webhook replay confirmation open", async ({ page, request }) => {
    // Trace artifact: test-results/motion-trace-webhook-replay-confirmation-open/trace.zip
    // Review with: npx playwright show-trace test-results/.../trace.zip

    const opFlows = await seed(request, "operator-flows");
    await login(page, `/billing/webhooks/${opFlows.single_webhook_id}`);
    await expect(page.locator("#main-content")).toBeVisible();

    // Click the replay trigger — triggers phx-click="prepare_replay" event
    const replayTrigger = page.locator('[data-role="replay-single"]').first();
    await expect(replayTrigger).toBeVisible();
    await replayTrigger.click();

    const confirmation = page.locator('[data-role="replay-confirm"]');
    await expect(confirmation).toBeVisible();
  });
});
