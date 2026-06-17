const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

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

// Scan in a theme with full axe (incl. color-contrast) in BOTH light and dark.
// Theme surfaces animate `background`, so toggling data-theme mid-fade would make
// axe snapshot blended (false-grey) colours — we kill transitions/animations for
// the scan so it reads settled token colours.
async function scan(page, theme) {
  await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
  await page.waitForTimeout(50);
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

test.describe("Admin accessibility (axe)", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  // Full 21-screen inventory including seeded edge states in both light and dark.
  // Three fixtures are seeded without intermediate reset() — processor IDs use
  // System.unique_integer so accumulation is safe (same pattern as admin-visuals.spec.js).
  test("no critical/serious axe violations across primary surfaces", async ({ page, request }) => {
    test.setTimeout(120_000);

    // Reduced-motion zeroes the admin's theme transition (see theme.css), so a
    // data-theme toggle is instant and axe reads settled colours instead of a
    // mid-fade blend. CSP forbids injecting a style tag, so emulate the media query.
    await page.emulateMedia({ reducedMotion: "reduce" });

    const opFlows = await seed(request, "operator-flows");
    const dash = await seed(request, "dashboard");
    const edge = await seed(request, "edge-states");

    const surfaces = [
      ["dashboard",           "/billing"],
      ["customers",           "/billing/customers"],
      ["customer-detail",     `/billing/customers/${dash.customer_id}`],
      ["subscriptions",       "/billing/subscriptions"],
      ["subscription-detail", `/billing/subscriptions/${dash.subscription_id}`],
      ["invoices",            "/billing/invoices"],
      ["invoice-detail",      `/billing/invoices/${edge.jpy_invoice_id}`],
      ["payments",            "/billing/payments"],
      ["charge-detail",       `/billing/payments/${opFlows.charge_id}`],
      ["coupons",             "/billing/coupons"],
      ["coupon-detail",       `/billing/coupons/${edge.coupon_id}`],
      ["promotion-codes",     "/billing/promotion-codes"],
      ["promo-code-detail",   `/billing/promotion-codes/${edge.promo_code_id}`],
      ["connect",             "/billing/connect"],
      ["connect-detail",      `/billing/connect/${edge.connect_account_id}`],
      ["events",              "/billing/events"],
      ["event-detail",        `/billing/events/${opFlows.source_event_id}`],
      ["webhooks",            "/billing/webhooks"],
      ["webhook-detail",      `/billing/webhooks/${opFlows.single_webhook_id}`],
      ["recovery",            "/billing/analytics/recovery"],
      ["campaign-detail",     `/billing/analytics/recovery/subscriptions/${edge.at_risk_sub_id}`],
      ["component-kitchen",   "/billing/dev/components"]
    ];

    const failures = [];

    for (const [name, path] of surfaces) {
      await login(page, path);
      await expect(page.locator("#main-content")).toBeVisible();

      for (const theme of ["light", "dark"]) {
        const violations = await scan(page, theme);
        for (const v of violations) {
          const d = v.nodes[0] && (v.nodes[0].any[0] || v.nodes[0].all[0]);
          const detail = d && d.data ? ` fg=${d.data.fgColor} bg=${d.data.bgColor} r=${d.data.contrastRatio}` : "";
          failures.push(`${name} [${theme}] ${v.id}: ${v.nodes[0]?.target.join(" ")}${detail}`);
        }
      }
    }

    expect(failures, `axe violations:\n${failures.join("\n")}`).toEqual([]);
  });
});
