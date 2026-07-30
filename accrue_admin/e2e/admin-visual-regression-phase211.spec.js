const { test, expect } = require("@playwright/test");
const {
  reset,
  seed,
  login,
  hideCaptureOnlyChrome
} = require("./support/admin-visual-helpers");

// Phase 211 deterministic visual-regression gate.
//
// This spec replaces the two human-only visual UAT checkpoints (211-02 D4,
// 211-04 D5) with Playwright's native `toHaveScreenshot` pixel-diff against
// committed Linux baselines. No LLM, no API key, no human on the path.
//
// Desktop-only: baselines are OS/font-stack specific and are minted on Linux CI
// only. The mobile project is skipped so we never bake a second baseline set.
//
// Non-determinism strategy: fixtures render ABSOLUTE datetimes (DB auto-timestamps
// / DateTime.utc_now() offsets), not relative "X ago" strings. Rather than freeze
// the clock (which would require rewriting the shared test/support/e2e_fixtures.ex),
// we mask the datetime-bearing regions per surface with `maskColor: "#FF00FF"`.

test.use({ reducedMotion: "reduce" });

// Per-surface mask locators — mask ONLY non-deterministic absolute datetimes so
// the diff stays sensitive to real color/spacing/layout regressions elsewhere.
function maskLocators(page, name) {
  switch (name) {
    case "dashboard":
      return [
        // Timeline event timestamps.
        page.locator("time.ax-timeline-time"),
        // Audit-summary "Timestamp" <em>. The row renders three <em> (Actor,
        // Action, Timestamp); only Timestamp is non-deterministic, so scope the
        // mask to the Timestamp span (the plan's ambiguity note) — do NOT mask
        // the deterministic Actor/Action <em> or the KPI counts.
        page
          .locator(".ax-dashboard-audit-summary span")
          .filter({ hasText: "Timestamp" })
          .locator("em")
      ];
    case "subscriptions":
      // GROUNDED: the subscriptions data_table is not `selectable` (no leading
      // checkbox column). Columns are Customer details (1), State (2),
      // Plan / amount (3), Renews / ends (4), Signals (5) — so the datetime
      // "Renews / ends" cell is genuinely td:nth-child(4); no offset needed.
      return [page.locator("tbody tr td:nth-child(4)")];
    case "subscription-detail":
      return [
        // Timeline event timestamps.
        page.locator("time.ax-timeline-time"),
        // Overview summary-list value cells that render absolute datetimes.
        // GROUNDED CORRECTION: these render in <dd class="ax-summary-list-value">
        // (Detail.summary_list markup), NOT `.ax-body` as the plan first guessed.
        // Filter the row by its deterministic <dt> label, then mask the value cell.
        page
          .locator(".ax-summary-list-row")
          .filter({ hasText: /Current period|Renews \/ ends/ })
          .locator(".ax-summary-list-value"),
        // Header "Renewal" summary fact repeats the same renews/ends datetime.
        page.locator(".ax-summary-fact").filter({ hasText: /Renewal/ }),
        // Dunning campaign-"Started" line + any period `.ax-body` copy carrying a
        // datetime (the plan's original `.ax-body` selector, kept as a superset).
        page
          .locator(".ax-body")
          .filter({ hasText: /Renews|Ends|Ended|Campaign started|Started/ })
      ];
    case "component-kitchen":
      // Fully static hardcoded literal timestamps — no mask.
      return [];
    default:
      return [];
  }
}

test.describe("Phase 211 visual regression", () => {
  // Scoping is enforced at the config level: this spec matches ONLY the dedicated
  // `visual-desktop` project (testMatch) and is excluded from the two base projects
  // (testIgnore) and the default `npm run e2e` run. No runtime project guard needed —
  // a describe-level `test.skip(fn)` receives only the fixtures object (no testInfo),
  // so a `testInfo.project` guard there throws.

  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("matches committed baselines for the four Phase-211 surfaces", async ({
    page,
    request
  }) => {
    test.setTimeout(120_000);

    // Same merged-fixture sequence the capture spec relies on: operator-flows,
    // dashboard (carries subscription_id), edge-states — no intermediate reset.
    await seed(request, "operator-flows");
    const dash = await seed(request, "dashboard");
    await seed(request, "edge-states");

    const surfaces = [
      { name: "dashboard", route: "/billing", fullPage: true },
      { name: "subscriptions", route: "/billing/subscriptions", fullPage: true },
      {
        name: "subscription-detail",
        route: `/billing/subscriptions/${dash.subscription_id}`,
        fullPage: true
      },
      { name: "component-kitchen", route: "/billing/dev/components", fullPage: false }
    ];

    for (const { name, route, fullPage } of surfaces) {
      await login(page, route);
      await hideCaptureOnlyChrome(page);
      await expect(page.locator("#main-content")).toBeVisible();

      for (const theme of ["light", "dark"]) {
        await page.evaluate(
          (t) => document.documentElement.setAttribute("data-theme", t),
          theme
        );
        const file = theme === "dark" ? `${name}-dark.png` : `${name}.png`;
        await expect(page).toHaveScreenshot(file, {
          fullPage,
          animations: "disabled",
          mask: maskLocators(page, name),
          maskColor: "#FF00FF"
        });
      }
    }
  });
});
