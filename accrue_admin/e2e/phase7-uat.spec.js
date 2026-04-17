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

    await expect(page.getByRole("heading", { name: "Dashboard" })).toBeVisible();
    await expect(page.getByText("Local billing projections at a glance")).toBeVisible();
    await expect(page.getByText("Open invoice balance")).toBeVisible();
    await expect(page.getByText("$42.50")).toBeVisible();
    await expect(page.getByText("Webhook backlog")).toBeVisible();
    await expect(page.getByText("invoice.payment_failed")).toBeVisible();

    if (isMobile) {
      await page.evaluate(() => {
        window.localStorage.setItem("accrue_theme", "dark");
        document.cookie = "accrue_theme=dark; path=/; max-age=31536000; samesite=lax";
      });
    } else {
      await page.getByRole("button", { name: "Dark" }).click();
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
      await expect(page.getByText("Internal billing operations")).toBeVisible();
    }
  });

  test("operator can replay one webhook and bulk requeue a DLQ slice", async ({ page, request }) => {
    const data = await seed(request, "operator-flows");

    await login(page, `/billing/webhooks/${data.single_webhook_id}`);
    await expect(page.getByRole("heading", { name: "invoice.payment_failed" })).toBeVisible();
    await page.getByRole("button", { name: "Replay webhook" }).click();
    await expect(page.getByText("Replay webhook for the active organization?")).toBeVisible({
      timeout: 15_000
    });
    await page.locator("[data-role='confirm-replay']").click();
    await expect(
      page
        .getByText("Replay requested for the active organization.")
        .or(page.getByText("Webhook replay requested."))
    ).toBeVisible({ timeout: 15_000 });

    await reset(request);
    await seed(request, "operator-flows");
    await login(page, "/billing/webhooks?type=customer.subscription.updated&status=failed");

    await expect(page.getByText("Replay, inspect, and trace webhook delivery")).toBeVisible();
    await page.locator("[data-role='prepare-bulk-replay']").click();
    await expect(page.locator("[data-role='bulk-replay-confirm']")).toContainText(
      "Replay 1 failed or dead webhook rows for the active organization?"
    );
    await page.locator("[data-role='confirm-bulk-replay']").click();
    await expect(
      page
        .getByText("Replay requested for the active organization.")
        .or(page.getByText("Bulk replay requested"))
    ).toBeVisible({ timeout: 15_000 });

    const countsResponse = await request.get("/__e2e__/counts");
    const counts = await countsResponse.json();
    expect(counts.admin_events).toBeGreaterThanOrEqual(1);
  });

  test("operator refund flow requires step-up and records fee-aware outcome", async ({
    page,
    request
  }) => {
    const data = await seed(request, "operator-flows");

    await login(page, `/billing/charges/${data.charge_id}`);
    await expect(page.getByRole("heading", { name: "ch_e2e_refund" })).toBeVisible();
    await expect(page.getByText("Fee-aware refund review")).toBeVisible();

    await page.locator("[data-role='refund-form'] input[name='amount_minor']").fill("4000");
    await page.locator("[data-role='refund-form'] input[name='reason']").fill("requested_by_customer");
    await page.locator("[data-role='refund-form'] select[name='source_event_id']").selectOption(
      String(data.source_event_id)
    );
    await page.locator("[data-role='refund-form']").evaluate((form) => form.requestSubmit());

    await expect(page.locator("[data-role='confirm-panel']")).toContainText("Confirm refund");
    await page.locator("[data-role='confirm-refund']").click();
    await expect(page.getByText("Step-up required")).toBeVisible();

    await page.locator("form[phx-submit='step_up_submit'] input[name='code']").fill("123456");
    await page.locator("form[phx-submit='step_up_submit']").evaluate((form) => form.requestSubmit());

    await expect(page.getByText("Refund created with fee-aware fields")).toBeVisible();

    const countsResponse = await request.get("/__e2e__/counts");
    const counts = await countsResponse.json();
    expect(counts.admin_events).toBeGreaterThanOrEqual(2);
  });
});
