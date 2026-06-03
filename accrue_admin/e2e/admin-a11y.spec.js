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

  test("no critical/serious axe violations across primary surfaces", async ({ page, request }) => {
    // Reduced-motion zeroes the admin's theme transition (see theme.css), so a
    // data-theme toggle is instant and axe reads settled colours instead of a
    // mid-fade blend. CSP forbids injecting a style tag, so emulate the media query.
    await page.emulateMedia({ reducedMotion: "reduce" });
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
