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

test.describe("Phase 7 browser UAT", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("dashboard is responsive and preserves light/dark theme preference", async ({
    page,
    request,
    isMobile
  }) => {
    await seed(request, "dashboard");
    await login(page);

    // The dashboard h1 is the "Recent activity" home intro headline (3d7d949d);
    // "Dashboard" is only a breadcrumb crumb, not a heading (redesign IA).
    await expect(page.getByRole("heading", { name: "Recent activity", level: 1 })).toBeVisible();
    // The breadcrumb leaf follows the same copy as the h1 (Copy.dashboard_breadcrumb_home).
    await expect(page.getByRole("navigation", { name: "Breadcrumb" })).toContainText("Recent activity");
    await expect(page.locator('.ax-home-section[aria-label="Recent billing activity"]')).toBeVisible();

    if (isMobile) {
      await page.evaluate(() => {
        window.localStorage.setItem("accrue_theme", "dark");
        document.cookie = "accrue_theme=dark; path=/; max-age=31536000; samesite=lax";
      });
    } else {
      // The theme picker is a radiogroup; "Dark" is a role="radio" segment.
      await page.getByRole("radio", { name: "Dark" }).click();
      await expect
        .poll(() => page.evaluate(() => window.localStorage.getItem("accrue_theme")))
        .toBe("dark");
      await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    }

    await page.reload();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");

    if (isMobile) {
      await expect(page.getByRole("button", { name: "Menu" })).toBeVisible();
    } else {
      await expect(page.getByRole("complementary", { name: "Admin navigation" })).toBeVisible();
      // The sidebar brand renders as a logo with the app name as its accessible
      // name (e2e brand "Accrue Ops"), not literal "Accrue Admin" body text.
      await expect(page.getByRole("img", { name: "Accrue Ops" })).toBeVisible();
    }
  });

  test("operator can replay one webhook and bulk requeue a DLQ slice", async ({ page, request }) => {
    const data = await seed(request, "operator-flows");

    await login(page, `/billing/webhooks/${data.single_webhook_id}`);
    // e6f39cef: the page title is the delivery's event id; the type is the header description.
    await expect(page.getByRole("heading", { name: "evt_e2e_single", level: 1 })).toBeVisible();
    await expect(page.locator("[data-role='webhook-page-header']")).toContainText("invoice.payment_failed");
    await page.getByRole("button", { name: "Replay webhook" }).click();
    const replayDialog = page.getByRole("dialog", { name: "Confirm webhook replay" });
    await expect(replayDialog).toBeVisible({ timeout: 15_000 });
    await replayDialog.locator("[data-role='confirm-replay']").click();
    const replayStepUp = page.locator("#accrue-admin-step-up-dialog");
    await expect(replayStepUp).toBeVisible();
    await replayStepUp.locator("input[name='code']").fill("123456");
    await replayStepUp.locator("form[phx-submit='step_up_submit']").evaluate((form) => form.requestSubmit());
    await expect(page.getByText(/Replay requested for the active organization|Webhook replay requested/)).toBeVisible({
      timeout: 15_000
    });

    await reset(request);
    await seed(request, "operator-flows");
    await login(page, "/billing/webhooks?type=customer.subscription.updated&status=failed");

    // The filtered replay queue uses a task-oriented h1; "Webhooks" is the
    // breadcrumb/sidebar label and the table keeps the detailed caption.
    await expect(page.getByRole("heading", { name: "Replay failed deliveries", level: 1 })).toBeVisible();

    // Bulk replay is selection-driven (h72): select the visible failed rows, then
    // the bulk-action button appears and opens the confirm panel. The old
    // prepare-bulk-replay / confirm-bulk-replay roles were removed.
    await page.locator("[data-role='toggle-all']").click();
    await page.locator("[data-role='bulk-action']").click();
    await expect(page.locator("[data-role='bulk-replay-confirm']")).toBeVisible();
    const review = page.locator("[data-role='bulk-replay-confirm']");
    await expect(review).toContainText(/Only deliveries still eligible when confirmed will be queued/);
    await expect(review).toContainText(/Queue acceptance does not mean processing is complete/);
    await page.locator("[data-role='confirm-retry-selected']").click();
    const retryStepUp = page.locator("#accrue-admin-step-up-dialog");
    await expect(retryStepUp).toBeVisible();
    await retryStepUp.locator('input[name="code"]').fill("123456");
    await retryStepUp.locator('form[phx-submit="step_up_submit"]').evaluate((form) => form.requestSubmit());
    await expect(page.getByText(/Queued \d+ delivery\. 0 skipped; 0 denied; 0 failed; 0 unknown\./)).toBeVisible({ timeout: 15_000 });

    const countsResponse = await request.get("/__e2e__/counts");
    const counts = await countsResponse.json();
    expect(counts.admin_events).toBeGreaterThanOrEqual(1);
  });

  test("operator refund flow requires step-up and records fee-aware outcome", async ({
    page,
    request
  }) => {
    const data = await seed(request, "operator-flows");

    await login(page, `/billing/payments/${data.charge_id}`);
    await expect(page.getByRole("heading", { name: "ch_e2e_refund" })).toBeVisible();

    await page.getByRole("button", { name: /refund charge/i }).click();
    const refundDrawer = page.getByRole("dialog", { name: "Confirm refund" });
    await expect(refundDrawer).toBeVisible();
    await expect(refundDrawer).toContainText(/Existing fee fields surface after\s+the refund is created/i);

    await refundDrawer.locator("[data-role='refund-form'] input[name='amount_minor']").fill("4000");
    await refundDrawer.locator("[data-role='refund-form'] input[name='reason']").fill("requested_by_customer");
    await refundDrawer.locator("[data-role='refund-form'] select[name='source_event_id']").selectOption(
      String(data.source_event_id)
    );
    await refundDrawer.locator("[data-role='refund-form']").evaluate((form) => form.requestSubmit());

    await expect(refundDrawer.locator("[data-role='confirm-panel']")).toContainText("Confirm refund");
    await refundDrawer.locator("[data-role='confirm-refund']").click();
    const stepUp = page.locator("#accrue-admin-step-up-dialog");
    await expect(stepUp).toBeVisible();
    await expect(stepUp).toContainText("Step-up required");

    await stepUp.locator("input[name='code']").fill("123456");
    await stepUp.locator("form[phx-submit='step_up_submit']").evaluate((form) => form.requestSubmit());

    await expect(page.getByText("Refund created with fee-aware fields")).toBeVisible();

    const countsResponse = await request.get("/__e2e__/counts");
    const counts = await countsResponse.json();
    expect(counts.admin_events).toBeGreaterThanOrEqual(2);
  });
});
