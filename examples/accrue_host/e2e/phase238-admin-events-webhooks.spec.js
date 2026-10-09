// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");
const AxeBuilder = require("@axe-core/playwright").default;

const orgQuery = (fixture) => `org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;

async function openAdmin(page, fixture, sandboxId, path) {
  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.goto(`/app/billing`);
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  await page.goto(path, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
}

async function expectNoDocumentOverflow(page) {
  const { width, scrollWidth } = await page.evaluate(() => ({
    width: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth
  }));
  expect(scrollWidth, `document overflows at ${width}px`).toBeLessThanOrEqual(width);
}

async function expectNoAxeViolations(page) {
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations, JSON.stringify(results.violations, null, 2)).toEqual([]);
}

test("Phase 238 seeded evidence and billing projections stay scoped and inspection-only", async ({ page, sandboxId }, testInfo) => {
  const fixture = readFixture();
  const owner = orgQuery(fixture);

  await openAdmin(page, fixture, sandboxId, `/admin/webhooks?status=dead&${owner}`);
  const firstRow = page.locator(`input[data-role="toggle-row"][data-row-id="${fixture.webhook_id}"]:visible`).first();
  const secondRow = page.locator(`input[data-role="toggle-row"][data-row-id="${fixture.second_webhook_id}"]:visible`).first();
  await expect(firstRow).toBeVisible();
  await expect(secondRow).toBeVisible();
  await expect(page.locator(`a[href^="/admin/webhooks/${fixture.webhook_id}"]`)).toBeVisible();

  await page.goto(`/admin/webhooks?status=dead&type=does-not-match&${owner}`);
  await waitForLiveView(page);
  await expect(page.getByText(/No webhook deliveries match these filters/)).toBeVisible();
  await expect(page.getByRole("link", { name: /clear filters/i }).first()).toBeVisible();

  await page.goto(`/admin/webhooks/${fixture.webhook_id}?${owner}`);
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: "invoice.payment_failed" })).toBeVisible();
  const payloadDisclosure = page.locator("details").filter({ hasText: /payload/i }).first();
  await expect(payloadDisclosure).toBeVisible();
  await payloadDisclosure.locator("summary").focus();
  await expect(payloadDisclosure.locator("summary")).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(payloadDisclosure).not.toContainText("Open Raw payload to inspect");
  await expect(payloadDisclosure).toContainText("evt_host_browser_replay");
  await payloadDisclosure.evaluate((details) => { details.open = true; });
  await expect(page.locator("#webhook-payload")).toBeVisible();
  await expectNoAxeViolations(page);
  const activity = page.locator("details[data-ax-lazy-activity]").first();
  await expect(activity).toBeVisible();
  await activity.locator("summary").click();
  await expect(activity).not.toContainText("Open Activity to load dispatch attempts");

  await page.goto(`/admin/webhooks?status=dead&${owner}`);
  await waitForLiveView(page);
  const toolbar = page.locator("[data-role='bulk-action']");
  await expect(toolbar).toHaveCount(0);
  await firstRow.check();
  await expect(toolbar).toBeEnabled();
  await toolbar.click();
  const singular = page.locator("[data-role='bulk-replay-confirm']");
  await expect(singular).toContainText("Replay 1 selected delivery?");
  await expect(singular).toContainText("Only deliveries still eligible when confirmed will be queued");
  await expect(singular).toContainText("Queue acceptance does not mean processing is complete");
  await singular.getByRole("button", { name: "Keep deliveries" }).click();
  await expect(singular).toBeHidden();

  await firstRow.check();
  await secondRow.check();
  await toolbar.click();
  const confirmation = page.locator("[data-role='bulk-replay-confirm']");
  await expect(confirmation).toContainText("Replay 2 selected deliveries?");
  await confirmation.getByRole("button", { name: "Queue eligible deliveries" }).click();
  const stepUp = page.getByRole("dialog", { name: "Step-up required" });
  await expect(stepUp).toBeVisible();
  await expectNoAxeViolations(page);
  await expect(stepUp.getByRole("textbox", { name: "Verification code" })).toBeEnabled();
  await stepUp.getByRole("textbox", { name: "Verification code" }).fill("000000");
  await stepUp.getByRole("button", { name: "Verify identity" }).click();
  await expect(stepUp).toBeVisible();
  await expect(stepUp).toContainText(/incorrect|invalid|try again/i);
  await expectNoAxeViolations(page);
  await expect(page.locator("[role='status']").filter({ hasText: /queued/i })).toHaveCount(0);
  await stepUp.getByRole("textbox", { name: "Verification code" }).fill("123456");
  await stepUp.getByRole("button", { name: "Verify identity" }).click();
  await expect(stepUp).toBeHidden();
  await expect(page.locator("[role='status'], [role='alert']").filter({ hasText: /Queued 2 deliveries/i })).toBeVisible();
  await expect(page.locator("body")).not.toContainText(/processed successfully/i);
  await testInfo.attach("phase238-replay-queued.png", { body: await page.screenshot({ fullPage: true }), contentType: "image/png" });

  await page.goto(`/admin/events?${owner}&q=invoice.payment_failed`);
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: "Trace billing activity" })).toBeVisible();
  await expect(page.getByText("invoice.payment_failed", { exact: false }).first()).toBeVisible();
  await page.goto(`/admin/events?${owner}&q=does-not-match-phase238`);
  await waitForLiveView(page);
  await expect(page.getByText("No event ledger rows match these filters.")).toBeVisible();

  await page.goto(`/admin/coupons?${owner}`);
  await waitForLiveView(page);
  const couponLink = page.locator(`a[href^="/admin/coupons/${fixture.coupon_id}"]`).first();
  await expect(couponLink).toBeVisible();
  await expect(couponLink).toContainText("Phase 238 Global Coupon");
  await expect(page.getByRole("button", { name: /create|edit coupon/i })).toHaveCount(0);
  await couponLink.click();
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: /Phase 238 Global Coupon/i })).toBeVisible();
  await expect(page.locator(`a[href^="/admin/promotion-codes/${fixture.promotion_code_id}"]`)).toBeVisible();

  await page.goto(`/admin/promotion-codes?${owner}`);
  await waitForLiveView(page);
  const codeLink = page.locator(`a[href^="/admin/promotion-codes/${fixture.promotion_code_id}"]`).first();
  await expect(codeLink).toContainText("HOST238GLOBAL");
  await codeLink.click();
  await waitForLiveView(page);
  await expect(page.getByRole("heading", { name: /HOST238GLOBAL/i })).toBeVisible();
  await expect(page.locator(`a[href^="/admin/coupons/${fixture.coupon_id}"]`).first()).toBeVisible();
  await expect(page.getByRole("button", { name: /create|edit promotion code/i })).toHaveCount(0);

  await page.goto(`/admin/connect?${owner}`);
  await waitForLiveView(page);
  const accountLink = page.locator(`a[href^="/admin/connect/${fixture.connect_no_snapshot_id}"]`).first();
  await expect(accountLink).toBeVisible();
  await expect(accountLink).toContainText("acct_host_browser_no_snapshot");
  await accountLink.click();
  await waitForLiveView(page);
  await expect(page.getByText("Unknown", { exact: true }).first()).toBeVisible();
  await expect(page.getByText("Local platform fee override", { exact: true }).first()).toBeVisible();
});

test("Phase 238 admin evidence remains keyboard reachable, themed, and contained at narrow widths", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await openAdmin(page, fixture, sandboxId, `/admin/webhooks?status=dead&${orgQuery(fixture)}`);

  const filter = page.getByRole("combobox", { name: "Status" });
  await filter.focus();
  await expect(filter).toBeFocused();
  await expect(page.locator("[data-role='bulk-action']")).toHaveCount(0);
  await expect(page.locator("article").filter({ hasText: "evt_host_browser_replay" }).first()).toContainText("Dead");

  for (const theme of ["light", "dark", "system"]) {
    await page.getByRole("radio", { name: theme, exact: false }).check();
    await waitForLiveView(page);
    await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
    await expect(page.locator("[data-role='selection-bar']")).toBeVisible();
  }
  await page.emulateMedia({ colorScheme: "dark" });
  await page.getByRole("radio", { name: "System", exact: false }).check();
  await waitForLiveView(page);
  await expect(page.locator("html")).toHaveAttribute("data-theme", "system");

  await page.setViewportSize({ width: 640, height: 800 });
  await page.locator("html").evaluate((element) => { element.style.zoom = "2"; });
  await expectNoDocumentOverflow(page);
  await expect(filter).toBeVisible();
  await page.locator("html").evaluate((element) => { element.style.zoom = ""; });
  await page.setViewportSize({ width: 320, height: 800 });
  await expectNoDocumentOverflow(page);
  await expect(filter).toBeVisible();
  const firstIdentity = page.locator(`a[href^="/admin/webhooks/${fixture.webhook_id}"]`).first();
  const original = await firstIdentity.textContent();
  try {
    await firstIdentity.evaluate((node) => { node.textContent = `evt-${"X".repeat(120)}`; });
    const sizes = await firstIdentity.evaluate((node) => ({ client: node.clientWidth, scroll: node.scrollWidth }));
    expect(sizes.scroll).toBeLessThanOrEqual(sizes.client);
    await expectNoDocumentOverflow(page);
  } finally {
    await firstIdentity.evaluate((node, value) => { node.textContent = value || ""; }, original);
  }
});
