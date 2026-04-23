// @ts-check
const fs = require("node:fs");
const path = require("node:path");
const { test, expect } = require("@playwright/test");
const { readFixture, reseedFixture, login, waitForLiveView } = require("./support/fixture.js");
const { expectNoHorizontalOverflow, expectVisibleInViewport } = require("./support/overflow.js");
const { DASHBOARD_DISPLAY_HEADLINE } = require("./support/copy_dashboard.js");

async function captureState(page, testInfo, name) {
  const screenshotDir = path.join(process.cwd(), "test-results", "phase15-trust", testInfo.project.name);
  const screenshotPath = path.join(screenshotDir, `${name}.png`);

  fs.mkdirSync(screenshotDir, { recursive: true });
  await page.screenshot({ path: screenshotPath, fullPage: true });
  await testInfo.attach(`${testInfo.project.name}-${name}`, { path: screenshotPath, contentType: "image/png" });
}

async function assertResponsiveState(page, label, checks) {
  await expectNoHorizontalOverflow(page, label);

  for (const check of checks) {
    await expectVisibleInViewport(check.locator, check.label);
  }
}

async function measureVisibleTransition(page, label, action, visibleLocator) {
  const budget_ms = 1500;
  const startedAt = Date.now();

  await action();
  await expect(visibleLocator).toBeVisible();

  const elapsed_ms = Date.now() - startedAt;

  expect(
    elapsed_ms,
    `release-blocking ${label} transition exceeded ${budget_ms}ms`
  ).toBeLessThanOrEqual(budget_ms);

  return elapsed_ms;
}

async function postSignedWebhook(page, fixture) {
  const webhook = fixture.first_run_webhook;
  const response = await page.evaluate(async ({ payload, signature }) => {
    const result = await fetch("/webhooks/stripe", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "stripe-signature": signature
      },
      body: payload
    });

    return {
      ok: result.ok,
      status: result.status,
      statusText: result.statusText,
      body: await result.text()
    };
  }, webhook);

  expect(response.ok, `signed webhook POST failed: ${response.status} ${response.statusText}\n${response.body}`).toBe(
    true
  );
  expect(JSON.parse(response.body)).toEqual({ ok: true });
}

/** Desktop events table uses `<td>` cells; mobile card rows surface the type as body copy. */
function replayAuditEventLocator(page, testInfo) {
  if (testInfo.project.name === "chromium-mobile") {
    return page.locator("article").filter({ hasText: "admin.webhook.replay.completed" });
  }

  return page.getByRole("cell", { name: "admin.webhook.replay.completed" });
}

test("@phase15-trust canonical first-run and admin replay walkthrough stays release-blocking", async ({
  page,
  context
}, testInfo) => {
  reseedFixture();
  const fixture = readFixture();
  const alphaSlug = fixture.org_alpha_slug;
  if (typeof alphaSlug === "string" && alphaSlug.length > 0) {
    expect(alphaSlug).toContain("host-e2e");
  }

  const adminNavigationLocator =
    testInfo.project.name === "chromium-mobile"
      ? page.getByRole("button", { name: "Menu" })
      : page.getByRole("link", { name: /Webhooks/i }).first();

  page.on("pageerror", (error) => console.error(`browser page error: ${error.message}`));
  page.on("requestfailed", (request) => {
    console.error(`browser request failed: ${request.method()} ${request.url()} ${request.failure()?.errorText}`);
  });

  await login(page, fixture, fixture.normal_email);
  await expect(page.getByRole("link", { name: "Go to billing" })).toBeVisible();
  await page.getByRole("link", { name: "Go to billing" }).click();
  await expect(page.getByRole("heading", { name: "Choose a plan" })).toBeVisible();
  await waitForLiveView(page);
  await expect(page.getByText("No organization billing activity yet")).toBeVisible();
  await assertResponsiveState(page, "first-run billing empty state", [
    {
      locator: page.getByRole("button", { name: "Start organization subscription" }).first(),
      label: "primary action"
    },
    {
      locator: page.getByText("No organization billing activity yet"),
      label: "empty state copy"
    }
  ]);
  await captureState(page, testInfo, "first-run-billing-empty");

  // Organization subscribe uses automatic_tax; host Billing requires a saved tax location first.
  const taxForm = page.locator("#tax-location-form");
  await taxForm.locator('[name="tax_location[line1]"]').fill("27 Fredrick Ave");
  await taxForm.locator('[name="tax_location[city]"]').fill("Albany");
  await taxForm.locator('[name="tax_location[state]"]').fill("NY");
  await taxForm.locator('[name="tax_location[postal_code]"]').fill("12207");
  await taxForm.locator('[name="tax_location[country]"]').fill("US");
  await taxForm.getByRole("button", { name: "Save tax location" }).click();
  await expect(page.getByText(/Tax location saved/)).toBeVisible();
  await waitForLiveView(page);
  await expect(taxForm.locator('[name="tax_location[line1]"]')).toHaveValue("27 Fredrick Ave");

  await page
    .locator("[data-plan-id='price_basic']")
    .getByRole("button", { name: "Start organization subscription" })
    .click();

  try {
    await expect(page.getByText("Subscription started.")).toBeVisible({ timeout: 15_000 });
  } catch (error) {
    console.error("subscription start did not reach expected browser state");
    console.error(`url: ${page.url()}`);
    console.error((await page.locator("body").innerText()).slice(0, 2000));
    throw error;
  }

  await expect(page.getByRole("heading", { name: "Current subscription" })).toBeVisible();
  await expect(page.getByText("Basic (price_basic)")).toBeVisible();
  await postSignedWebhook(page, fixture);
  await assertResponsiveState(page, "first-run subscription started state", [
    {
      locator: page.getByRole("heading", { name: "Current subscription" }),
      label: "subscription started heading"
    },
    {
      locator: page.getByText("Basic (price_basic)"),
      label: "subscription started details"
    }
  ]);
  await captureState(page, testInfo, "first-run-subscription-started");

  await context.clearCookies();
  await login(page, fixture, fixture.admin_email);

  const billingElapsedMs = await measureVisibleTransition(
    page,
    "/billing admin dashboard",
    () => page.goto("/billing"),
    page.getByText(DASHBOARD_DISPLAY_HEADLINE)
  );

  expect(billingElapsedMs).toBeGreaterThanOrEqual(0);
  await assertResponsiveState(page, "admin dashboard", [
    {
      locator: page.getByText(DASHBOARD_DISPLAY_HEADLINE),
      label: "admin dashboard summary"
    },
    {
      locator: adminNavigationLocator,
      label: "admin navigation"
    }
  ]);
  await captureState(page, testInfo, "admin-dashboard");

  const webhookElapsedMs = await measureVisibleTransition(
    page,
    "/billing/webhooks/:id detail",
    () => page.goto(`/billing/webhooks/${fixture.webhook_id}`),
    page.getByRole("heading", { name: "invoice.payment_failed" })
  );

  expect(webhookElapsedMs).toBeGreaterThanOrEqual(0);
  await expect(page).toHaveURL(new RegExp(`/billing/webhooks/${fixture.webhook_id}$`));
  await assertResponsiveState(page, "webhook replay detail", [
    {
      locator: page.getByRole("heading", { name: "invoice.payment_failed" }),
      label: "webhook detail heading"
    },
    {
      locator: page.locator("[data-role='replay-single']"),
      label: "replay control"
    }
  ]);
  await captureState(page, testInfo, "admin-webhook-detail");

  await page.locator("[data-role='replay-single']").click();
  await expect(page.getByText("Replay webhook for the active organization?")).toBeVisible({
    timeout: 15_000
  });
  await page.locator("[data-role='confirm-replay']").click();
  await waitForLiveView(page);
  await expect(
    page
      .getByText("Replay requested for the active organization.")
      .or(page.getByText("Webhook replay requested."))
  ).toBeVisible({ timeout: 15_000 });

  const auditElapsedMs = await measureVisibleTransition(
    page,
    "admin replay audit",
    () => page.goto(`/billing/events?source_webhook_event_id=${fixture.webhook_id}&actor_type=admin`),
    replayAuditEventLocator(page, testInfo)
  );

  expect(auditElapsedMs).toBeGreaterThanOrEqual(0);
  await assertResponsiveState(page, "admin replay audit event", [
    {
      locator: replayAuditEventLocator(page, testInfo),
      label: "replay audit row"
    },
    {
      locator: page.getByText("Append-only billing and admin activity"),
      label: "audit heading"
    }
  ]);
  await captureState(page, testInfo, "admin-replay-audit");

  if (process.env.ACCRUE_HOST_PLAYWRIGHT_VIDEO === "1") {
    const recording = page.video();

    if (recording) {
      const destDir = path.join(process.cwd(), "test-results", "phase15-trust-videos", testInfo.project.name);
      const dest = path.join(destDir, "admin-billing-walkthrough.webm");
      fs.mkdirSync(destDir, { recursive: true });
      // Playwright only finalizes `.webm` after the context closes; `saveAs` waits for that.
      await context.close();
      await recording.saveAs(dest);
    }
  }
});
