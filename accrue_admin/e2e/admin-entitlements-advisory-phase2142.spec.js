const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

async function seedAdvisory(request) {
  const response = await request.post("/__e2e__/seed/advisory-entitlements");
  expect(response.ok(), "Phase 214.2 fixture should seed through the real writer").toBeTruthy();
  return response.json();
}

async function login(page, target) {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}

async function seriousOrCriticalViolations(page, theme) {
  await page.evaluate((value) => {
    document.documentElement.setAttribute("data-theme", value);
    document.documentElement.dataset.theme = value;
  }, theme);
  await page.waitForTimeout(50);

  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa"])
    .analyze();

  return results.violations.filter(
    (violation) => violation.impact === "critical" || violation.impact === "serious"
  );
}

test.describe("Phase 214.2 advisory entitlement diagnostic", () => {
  test("is complete, keyboard reachable, accessible, and responsive without changing local access", async ({
    page,
    request,
  }) => {
    test.setTimeout(60_000);
    await page.emulateMedia({ reducedMotion: "reduce" });

    const fixture = await seedAdvisory(request);
    await login(page, `/billing/customers/${fixture.customer_id}?tab=entitlements`);

    const accessSection = page.locator('[data-ax-drill-section="access-entitlements"]');
    const accessSummary = accessSection.locator("summary");
    await expect(accessSummary).toBeVisible();
    await accessSummary.focus();
    await expect(accessSummary).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(accessSection).toHaveAttribute("open", "");

    const canonical = accessSection.locator('[data-role="accrue-access-canonical"]');
    const advisory = accessSection.locator('[data-role="stripe-observation-advisory"]');
    await expect(canonical).toContainText("Accrue access (canonical)");
    await expect(canonical).toContainText("Reports");
    await expect(canonical).toContainText("seats: 1");
    await expect(page.locator("[data-ax-summary-list]")).toContainText("2 active access grants");
    await expect(advisory).toContainText("Stripe observation (advisory)");
    await expect(advisory).toContainText("Stripe advisory snapshot — does not change access.");
    await expect(advisory).toContainText("Incomplete snapshot.");
    await expect(advisory).toContainText("10 entitlements observed");
    await expect(advisory).toContainText("Webhook");
    await expect(advisory).toContainText("Incomplete");
    await expect(advisory).toContainText("+2 more");

    const canonicalBeforeAdvisory = await page.evaluate(() => {
      const canonicalNode = document.querySelector('[data-role="accrue-access-canonical"]');
      const advisoryNode = document.querySelector('[data-role="stripe-observation-advisory"]');
      return Boolean(
        canonicalNode.compareDocumentPosition(advisoryNode) & Node.DOCUMENT_POSITION_FOLLOWING
      );
    });
    expect(canonicalBeforeAdvisory).toBeTruthy();

    for (const key of fixture.preview_keys) await expect(advisory).toContainText(key);
    for (const key of fixture.hidden_keys) await expect(advisory).not.toContainText(key);

    const advisoryState = advisory.locator('[data-role="stripe-advisory-state"]');
    await expect(advisoryState.locator('[role="status"]')).toHaveCount(0);
    await expect(advisory).not.toContainText(/\b(match|mismatch|in sync|healthy)\b/i);

    const rawSection = page.locator("[data-ax-lazy-json]");
    const rawSummary = rawSection.locator("summary");
    await expect(page.locator("#customer-raw-data")).toHaveCount(0);
    await rawSummary.scrollIntoViewIfNeeded();
    await rawSummary.focus();
    await expect(rawSummary).toBeFocused();
    await page.keyboard.press("Enter");

    const rawData = page.locator("#customer-raw-data");
    await expect(rawData).toBeVisible();
    await expect(rawData).toContainText("stripe_advisory");
    for (const key of fixture.lookup_keys) await expect(rawData).toContainText(key);
    await expect(rawData).not.toContainText("last_stripe_event_id");

    for (const theme of ["light", "dark"]) {
      const violations = await seriousOrCriticalViolations(page, theme);
      expect(violations, `${theme} axe violations`).toEqual([]);
    }

    const overflow = await page.evaluate(() => ({
      document: document.documentElement.scrollWidth - document.documentElement.clientWidth,
      main: document.querySelector("#main-content, main").scrollWidth -
        document.querySelector("#main-content, main").clientWidth,
    }));
    expect(overflow.document).toBeLessThanOrEqual(1);
    expect(overflow.main).toBeLessThanOrEqual(1);
  });
});
