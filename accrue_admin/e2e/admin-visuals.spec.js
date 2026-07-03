const { test, expect } = require("@playwright/test");
const fs = require("fs");

// REGION_SELECTORS is the region_tag → `ax-*` selector SSOT from plan 01
// (accrue_admin/e2e/ratchet/region-tags.js). The capture harness is broader than
// the ratchet, so the import is defensive: if the ratchet module is absent the
// spec still runs and simply skips the additive .bbox.json emit (D-09).
let REGION_SELECTORS = null;
try {
  ({ REGION_SELECTORS } = require("./ratchet/region-tags.js"));
} catch {
  REGION_SELECTORS = null;
}

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
  await captureBBoxes(page, name, project, "light");
  await page.evaluate(() => document.documentElement.setAttribute("data-theme", "dark"));
  await page.screenshot({ path: `${dir}/${name}-dark.png`, fullPage: true });
  await captureBBoxes(page, name, project, "dark");
}

// captureBBoxes — capture-time selector bounding-box emitter (D-09). Per
// surface/viewport/theme it writes a sibling `${name}.bbox.json` (light) /
// `${name}-dark.bbox.json` (dark) next to the PNG, keyed by region_tag, recording
// each REGION_SELECTORS `ax-*` selector's boundingBox() — or `null` when the
// selector is absent on the surface.
//
// This geometry feeds ONLY the Phase-207 digest region overlay and the optional
// presence cross-check (a region the model tagged but whose selector is absent →
// downgrade to `content-body`). It is capture-time evidence: it is written to the
// `.bbox.json` sidecar ONLY and NEVER enters the deterministic claim_key /
// finding_id / any candidates.ndjson identity field (D-09, T-205-05).
//
// An absent or unresolvable selector yields a `null` box — never a thrown error
// that aborts the capture sweep. The whole emit is additive: it does not change the
// PNG capture behavior, filenames, or the surface sweep, and it no-ops entirely if
// the ratchet region-tags module was not importable above.
async function captureBBoxes(page, name, project, theme) {
  if (!REGION_SELECTORS) return; // ratchet module absent → skip additively
  const dir = `test-results/admin-visuals/${project}`;
  const suffix = theme === "dark" ? "-dark" : "";
  const boxes = {};
  for (const [regionTag, selector] of Object.entries(REGION_SELECTORS)) {
    let box = null;
    try {
      if (selector) {
        const loc = page.locator("." + selector).first();
        if (await loc.count()) {
          box = await loc.boundingBox();
        }
      }
    } catch {
      // A wrong/absent selector must NEVER crash the capture — null box fallback.
      box = null;
    }
    boxes[regionTag] = box || null;
  }
  await fs.promises.writeFile(
    `${dir}/${name}${suffix}.bbox.json`,
    JSON.stringify(boxes, null, 2)
  );
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
      ["component-kitchen",   "/billing/dev/components"],
    ];

    for (const [name, path] of shots) {
      await login(page, path);
      await captureThemes(page, name, project);
    }
  });
});
