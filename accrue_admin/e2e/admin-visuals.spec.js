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
    const data = await seed(request, "operator-flows");
    const project = testInfo.project.name;

    // Index surfaces render regardless of seed volume (empty states included),
    // so the full nav inventory is safe to sweep. Detail surfaces use only ids
    // the fixture is known to provide.
    const shots = [
      ["dashboard", "/billing"],
      ["customers", "/billing/customers"],
      ["subscriptions", "/billing/subscriptions"],
      ["invoices", "/billing/invoices"],
      ["payments", "/billing/charges"],
      ["recovery", "/billing/analytics/recovery"],
      ["coupons", "/billing/coupons"],
      ["promotion-codes", "/billing/promotion-codes"],
      ["connect", "/billing/connect"],
      ["events", "/billing/events"],
      ["webhooks", "/billing/webhooks"],
      ["webhook-detail", `/billing/webhooks/${data.single_webhook_id}`]
    ];

    for (const [name, path] of shots) {
      await login(page, path);
      await captureThemes(page, name, project);
    }
  });
});
