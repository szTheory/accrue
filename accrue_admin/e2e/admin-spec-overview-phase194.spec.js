/**
 * Phase 194 — SPEC-OVERVIEW Invariant Assertion Spec
 *
 * First machine-enforcer of the SPEC-OVERVIEW contract (Phase 193 locked the spec;
 * Phase 194 wires the assertions). Reuses Phase-191 page-flow helpers — no new helper
 * library. Asserts the machine-checkable invariants on both Dashboard and Recovery.
 *
 * Covers:
 *   - SC1: one h1 per page
 *   - SC2: ⌘K trigger visible + focusable (data-command-palette-trigger)
 *   - D-05: Current Home header precedes its recent-activity section
 *   - D-06: Empty recent activity state has no action controls
 *   - D-01: Recovery hero metric pair < work queue < supporting funnel
 */

const { test, expect } = require("@playwright/test");

const {
  PHASE191_VIEWPORTS,
  setPhase191Theme,
  assertFocusWithin,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

// ---------------------------------------------------------------------------
// Shared helpers (mirror phase191 spec scaffold)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// SPEC-OVERVIEW assertions
// ---------------------------------------------------------------------------

test.describe("Phase 194 SPEC-OVERVIEW invariants", () => {
  // -------------------------------------------------------------------------
  // Dashboard invariants
  // -------------------------------------------------------------------------

  test("Dashboard: one h1, ⌘K visible+focusable, Home section order (D-05) — populated state", async ({
    page,
    request,
  }) => {
    await reset(request);
    await seedScenario(request, "dashboard");
    await login(page, "/billing");

    // SC1 — one h1 per page
    await expect(page.locator("h1")).toHaveCount(1);

    // SC2 — ⌘K trigger visible + focusable (3d7d949d: the shell topbar owns the trigger)
    const kbd = page.locator("[data-command-palette-trigger]");
    await expect(kbd).toBeVisible();
    await kbd.focus();
    await assertFocusWithin(page, kbd, "command palette trigger");

    const homeHeader = page.locator(".ax-home > .ax-page-header");
    const activity = page.locator('.ax-home-section[aria-label="Recent billing activity"]');
    await expect(homeHeader).toBeVisible();
    await expect(activity).toBeVisible();
    const order = await page.evaluate(() => {
      const header = document.querySelector(".ax-home > .ax-page-header");
      const activity = document.querySelector('.ax-home-section[aria-label="Recent billing activity"]');
      return Boolean(header && activity && (header.compareDocumentPosition(activity) & Node.DOCUMENT_POSITION_FOLLOWING));
    });
    expect(order, "Home header precedes recent activity").toBe(true);
  });

  test("Dashboard: empty recent activity has no action controls (D-06)", async ({
    page,
    request,
  }) => {
    // Empty attention state: reset only, no seeding — no blocked webhooks,
    // no past-due subscriptions, no failed meter events → @attention == []
    await reset(request);
    await login(page, "/billing");

    const activity = page.locator('.ax-home-section[aria-label="Recent billing activity"]');
    const empty = activity.locator(".ax-timeline-empty");
    await expect(empty).toBeVisible();
    await expect(empty.locator("a, button, [role='button']")).toHaveCount(0);
  });

  test("Dashboard: Home section order preserved across light/dark themes", async ({ page, request }) => {
    await reset(request);
    await seedScenario(request, "dashboard");
    await login(page, "/billing");

    for (const theme of ["light", "dark"]) {
      await setPhase191Theme(page, theme);

      const order = await page.evaluate(() => {
        const header = document.querySelector(".ax-home > .ax-page-header");
        const activity = document.querySelector('.ax-home-section[aria-label="Recent billing activity"]');
        return Boolean(header && activity && (header.compareDocumentPosition(activity) & Node.DOCUMENT_POSITION_FOLLOWING));
      });
      expect(order, `[${theme}] Home header precedes activity`).toBe(true);
    }
  });

  // -------------------------------------------------------------------------
  // Recovery invariants
  // -------------------------------------------------------------------------

  test("Recovery: one h1, hero metric pair < work queue < supporting funnel (D-01)", async ({
    page,
    request,
  }) => {
    await reset(request);
    await seedScenario(request, "phase191-matrix");
    await login(page, "/billing/analytics/recovery");

    // SC1 — one h1 per page
    await expect(page.locator("h1")).toHaveCount(1);

    await expect(page.locator('[data-ax-overview="recovery"]')).toHaveCount(1);
    await expect(page.locator("[data-ax-recovery-hero]")).toHaveCount(1);
    await expect(page.locator("[data-ax-recovery-work-queue]")).toHaveCount(1);
    await expect(page.locator("[data-ax-recovery-supporting-funnel]")).toHaveCount(1);

    // D-01 — Recovery has its own overview grammar. It is not judged by the
    // Dashboard attention-rail -> task-launcher -> kpi-cluster order.
    const order = await page.evaluate(() => {
      const root = document.querySelector('[data-ax-overview="recovery"]');
      if (!root) return [];

      return [
        ...root.querySelectorAll(
          "[data-ax-recovery-hero], [data-ax-recovery-work-queue], [data-ax-recovery-supporting-funnel]"
        ),
      ].map((node) => {
        if (node.hasAttribute("data-ax-recovery-hero")) return "hero";
        if (node.hasAttribute("data-ax-recovery-work-queue")) return "work-queue";
        if (node.hasAttribute("data-ax-recovery-supporting-funnel")) return "supporting-funnel";
        return "unknown";
      });
    });

    expect(order, "Recovery overview DOM order").toEqual(["hero", "work-queue", "supporting-funnel"]);
  });

  test("Recovery: work queue is Recovery-specific and not a Dashboard task-launcher clone", async ({
    page,
    request,
  }) => {
    await reset(request);
    await seedScenario(request, "phase191-matrix");
    await login(page, "/billing/analytics/recovery");

    await expect(page.locator('[data-ax-overview="recovery"] [data-ax-zone]')).toHaveCount(0);

    const workQueueContent = await page.locator("[data-ax-recovery-work-queue]").textContent();
    expect(workQueueContent?.trim().length, "Recovery work queue must not be empty").toBeGreaterThan(0);
  });
});
