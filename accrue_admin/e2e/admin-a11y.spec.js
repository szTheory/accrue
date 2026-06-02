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

// Scan in a theme. We run full axe (incl. color-contrast) in light, where the
// canvas is deterministic; in dark we disable `color-contrast` because axe can't
// resolve our themed/layered backgrounds through the snapshot (it falls back to a
// white canvas and reports phantom ratios). Dark contrast is governed instead by
// the deliberate `--ax-*-readable` token pairs + manual review; every other a11y
// rule (names, roles, labels, landmarks, focus order) still runs in both themes.
async function scan(page, theme, { contrast }) {
  await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
  let builder = new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]);
  if (!contrast) builder = builder.disableRules(["color-contrast"]);
  const results = await builder.analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

test.describe("Admin accessibility (axe)", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("no critical/serious axe violations across primary surfaces", async ({ page, request }) => {
    const data = await seed(request, "operator-flows");

    const surfaces = [
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

    const failures = [];

    for (const [name, path] of surfaces) {
      await login(page, path);
      await expect(page.locator("#main-content")).toBeVisible();

      const passes = [
        ["light", { contrast: true }],
        ["dark", { contrast: false }]
      ];

      for (const [theme, opts] of passes) {
        const violations = await scan(page, theme, opts);
        for (const v of violations) {
          failures.push(`${name} [${theme}] ${v.id} (${v.impact}): ${v.nodes[0]?.target.join(" ")}`);
        }
      }
    }

    expect(failures, `axe violations:\n${failures.join("\n")}`).toEqual([]);
  });
});
