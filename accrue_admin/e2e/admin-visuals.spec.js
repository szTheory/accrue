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

test.describe("Admin visual inventory", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("captures the command center and primary operations surfaces", async ({
    page,
    request
  }) => {
    const data = await seed(request, "operator-flows");

    const shots = [
      ["dashboard", "/billing"],
      ["customers", "/billing/customers"],
      ["subscriptions", "/billing/subscriptions"],
      ["invoices", "/billing/invoices"],
      ["payments", "/billing/charges"],
      ["recovery", "/billing/analytics/recovery"],
      ["webhook-detail", `/billing/webhooks/${data.single_webhook_id}`]
    ];

    for (const [name, path] of shots) {
      await login(page, path);
      await expect(page.locator("#main-content")).toBeVisible();
      await page.screenshot({
        path: `test-results/admin-visuals/${name}.png`,
        fullPage: true
      });
    }
  });
});
