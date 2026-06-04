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
  // 2. Dropdown open/close
  // Surface: dropdown_menu.ex — details.ax-dropdown disclosure + .ax-dropdown-panel
  // Trigger: details.ax-dropdown > summary (native <details> semantics)
  // --------------------------------------------------------------------------
  test("motion trace — dropdown open/close", async ({ page, request }) => {
    // Trace artifact: test-results/motion-trace-dropdown-open-close/trace.zip
    // Review with: npx playwright show-trace test-results/.../trace.zip

    await seed(request, "operator-flows");
    // Any page that renders a dropdown — the customer detail has action dropdowns
    await login(page, "/billing/customers");
    await expect(page.locator("#main-content")).toBeVisible();

    const dropdownSummary = page.locator("details.ax-dropdown > summary").first();
    await expect(dropdownSummary).toBeVisible();

    // Open the dropdown via the native summary element
    await dropdownSummary.click();

    // The panel becomes visible when the parent <details> is open
    const panel = page.locator(".ax-dropdown-panel").first();
    await expect(panel).toBeVisible();

    // Close by clicking the summary again (native <details> toggle)
    await dropdownSummary.click();
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
    const controlledId = await toggleButton.getAttribute("data-controls");

    // Collapse the group (first click hides the link list)
    await toggleButton.click();

    // The controlled sidebar group links div should now be hidden
    if (controlledId) {
      const groupLinks = page.locator(`#${controlledId}`);
      await expect(groupLinks).toBeHidden();
    }

    // Re-expand the group (second click reveals the link list)
    await toggleButton.click();

    if (controlledId) {
      const groupLinks = page.locator(`#${controlledId}`);
      await expect(groupLinks).toBeVisible();
    }
  });

  // --------------------------------------------------------------------------
  // 4. Webhook replay drawer open
  // Surface: detail_drawer.ex — .ax-detail-drawer-shell with phx-mounted JS.show transition
  // Trigger: [data-role="replay-single"] (webhook_live.ex line 162-164, phx-click="prepare_replay")
  // The drawer uses ax-drawer-entering / ax-drawer-enter-from / ax-drawer-enter-to transitions
  // with --ax-dur-3 (240ms enter, 140ms leave). Under reduced-motion, --ax-dur-3 → 0ms.
  // --------------------------------------------------------------------------
  test("motion trace — webhook replay drawer open", async ({ page, request }) => {
    // Trace artifact: test-results/motion-trace-webhook-replay-drawer-open/trace.zip
    // Review with: npx playwright show-trace test-results/.../trace.zip
    // detail_drawer.ex uses JS.show/JS.hide on .ax-detail-drawer-shell; the trace
    // captures the enter transition frames (ax-drawer-entering CSS class applied for 240ms).

    const opFlows = await seed(request, "operator-flows");
    await login(page, `/billing/webhooks/${opFlows.single_webhook_id}`);
    await expect(page.locator("#main-content")).toBeVisible();

    // Click the replay trigger — triggers phx-click="prepare_replay" event
    const replayTrigger = page.locator('[data-role="replay-single"]').first();
    await expect(replayTrigger).toBeVisible();
    await replayTrigger.click();

    // The drawer shell is conditionally rendered (:if={@open}) and uses phx-mounted
    // JS.show with ax-drawer-entering transition (--ax-dur-3: 240ms)
    const drawerShell = page.locator(".ax-detail-drawer-shell");
    await expect(drawerShell).toBeVisible();
  });
});
