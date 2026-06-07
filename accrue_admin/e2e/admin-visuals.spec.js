const { test, expect } = require("@playwright/test");

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

// Capture the screen in both themes. Light keeps the historical `${name}.png`
// filename; dark is a sibling `${name}-dark.png`. Theme is applied by setting
// the data-theme attribute the admin chrome keys off (same hook the toggle uses).
async function captureThemes(page, name, project) {
  await expect(page.locator("#main-content")).toBeVisible();
  const dir = `test-results/admin-visuals/${project}`;
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "light"));
  await page.screenshot({ path: `${dir}/${name}.png`, fullPage: true });
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "dark"));
  await page.screenshot({ path: `${dir}/${name}-dark.png`, fullPage: true });
}

test.describe("Admin visual inventory", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("captures every primary admin surface in light and dark", async ({
    page,
    request
  }, testInfo) => {
    test.setTimeout(120_000);

    // Three merged fixtures — operator-flows, dashboard, edge-states — seeded
    // without intermediate reset(). Fixtures use System.unique_integer processor
    // IDs and accumulate safely. Detail surfaces use ids returned from each fixture.
    const opFlows = await seed(request, "operator-flows");
    const dash    = await seed(request, "dashboard");
    const edge    = await seed(request, "edge-states");
    const project = testInfo.project.name;

    const shots = [
      ["dashboard",           "/billing"],
      ["customers",           "/billing/customers"],
      ["customer-detail",     `/billing/customers/${dash.customer_id}`],
      ["subscriptions",       "/billing/subscriptions"],
      ["subscription-detail", `/billing/subscriptions/${dash.subscription_id}`],
      ["invoices",            "/billing/invoices"],
      ["invoice-detail",      `/billing/invoices/${edge.jpy_invoice_id}`],
      ["payments",            "/billing/payments"],           // NOTE: /payments not /charges
      ["charge-detail",       `/billing/payments/${opFlows.charge_id}`],
      ["coupons",             "/billing/coupons"],
      ["coupon-detail",       `/billing/coupons/${edge.coupon_id}`],
      ["promotion-codes",     "/billing/promotion-codes"],
      ["promo-code-detail",   `/billing/promotion-codes/${edge.promo_code_id}`],
      ["connect",             "/billing/connect"],             // NOTE: /connect not /connect-accounts
      ["connect-detail",      `/billing/connect/${edge.connect_account_id}`],
      ["events",              "/billing/events"],
      ["event-detail",        `/billing/events/${opFlows.source_event_id}`],
      ["webhooks",            "/billing/webhooks"],
      ["webhook-detail",      `/billing/webhooks/${opFlows.single_webhook_id}`],
      ["recovery",            "/billing/analytics/recovery"],
      ["campaign-detail",     `/billing/analytics/recovery/subscriptions/${edge.at_risk_sub_id}`],
      // NOTE: route is /analytics/recovery/subscriptions/:id (not /campaigns/:id)
    ];

    for (const [name, path] of shots) {
      await login(page, path);
      await captureThemes(page, name, project);
    }
  });
});
