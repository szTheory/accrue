// @ts-check
const fs = require("node:fs");
const path = require("node:path");
const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

function readFixture() {
  const fixturePath = process.env.ACCRUE_HOST_E2E_FIXTURE;

  if (!fixturePath) {
    throw new Error("ACCRUE_HOST_E2E_FIXTURE is required");
  }

  return JSON.parse(fs.readFileSync(path.resolve(fixturePath), "utf8"));
}

async function login(page, fixture, email) {
  await page.goto("/users/log-in");

  const csrfToken = await page.locator("meta[name='csrf-token']").getAttribute("content");

  if (!csrfToken) {
    throw new Error(`missing CSRF token on login page for ${email}`);
  }

  const response = await page.request.post("/users/log-in", {
    form: {
      _csrf_token: csrfToken,
      "user[email]": email,
      "user[password]": fixture.password
    }
  });

  if (!response.ok()) {
    throw new Error(`login POST failed for ${email}: ${response.status()} ${response.statusText()}`);
  }

  await page.goto("/");

  try {
    await expect(page.getByRole("link", { name: "Go to billing" })).toBeVisible();
  } catch (error) {
    console.error(`login did not reach authenticated home for ${email}`);
    console.error(`url: ${page.url()}`);
    console.error((await page.locator("body").innerText()).slice(0, 2000));
    throw error;
  }
}

async function waitForLiveView(page) {
  try {
    await page.waitForFunction(
      () => Boolean(document.querySelector("[data-phx-main].phx-connected")),
      null,
      { timeout: 5_000 }
    );
  } catch (error) {
    console.error("LiveView client did not connect");
    console.error(
      await page.evaluate(() => ({
        classes: document.documentElement.className,
        liveSocket: Boolean(window.liveSocket),
        scripts: Array.from(document.scripts).map((script) => script.src || "[inline]")
      }))
    );
    throw error;
  }
}

async function assertNoSeriousAccessibilityViolations(page, label) {
  const results = await new AxeBuilder({ page }).analyze();
  const blocking = results.violations.filter((violation) =>
    ["critical", "serious"].includes(violation.impact || "")
  );

  expect(blocking, `${label} has critical/serious accessibility violations`).toEqual([]);
}

async function captureState(page, testInfo, name) {
  const screenshotDir = path.join(process.cwd(), "test-results", "phase13-screenshots");
  const screenshotPath = path.join(screenshotDir, `${name}.png`);

  fs.mkdirSync(screenshotDir, { recursive: true });
  await page.screenshot({ path: screenshotPath, fullPage: true });
  await testInfo.attach(name, { path: screenshotPath, contentType: "image/png" });
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

test("canonical first-run and admin replay walkthrough stays release-blocking", async ({
  page,
  context
}, testInfo) => {
  const fixture = readFixture();

  page.on("pageerror", (error) => console.error(`browser page error: ${error.message}`));
  page.on("requestfailed", (request) => {
    console.error(`browser request failed: ${request.method()} ${request.url()} ${request.failure()?.errorText}`);
  });

  await login(page, fixture, fixture.normal_email);
  await expect(page.getByRole("link", { name: "Go to billing" })).toBeVisible();
  await page.getByRole("link", { name: "Go to billing" }).click();
  await expect(page.getByRole("heading", { name: "Choose a plan" })).toBeVisible();
  await waitForLiveView(page);
  await expect(page.getByText("No billing activity yet")).toBeVisible();
  await assertNoSeriousAccessibilityViolations(page, "first-run billing empty state");
  await captureState(page, testInfo, "first-run-billing-empty");

  await page.locator("[data-plan-id='price_basic'] button", { hasText: "Start subscription" }).click();

  try {
    await expect(page.getByText("Subscription started.")).toBeVisible();
  } catch (error) {
    console.error("subscription start did not reach expected browser state");
    console.error(`url: ${page.url()}`);
    console.error((await page.locator("body").innerText()).slice(0, 2000));
    throw error;
  }

  await expect(page.getByRole("heading", { name: "Current subscription" })).toBeVisible();
  await expect(page.getByText("Basic (price_basic)")).toBeVisible();
  await postSignedWebhook(page, fixture);
  await captureState(page, testInfo, "first-run-subscription-started");

  await context.clearCookies();
  await login(page, fixture, fixture.admin_email);

  await page.goto("/billing");
  await expect(page.getByText("Local billing projections at a glance")).toBeVisible();
  await assertNoSeriousAccessibilityViolations(page, "admin dashboard");
  await captureState(page, testInfo, "admin-dashboard");

  await page.goto(`/billing/webhooks/${fixture.webhook_id}`);
  await expect(page).toHaveURL(new RegExp(`/billing/webhooks/${fixture.webhook_id}$`));
  await expect(page.getByRole("heading", { name: "invoice.payment_failed" })).toBeVisible();
  await assertNoSeriousAccessibilityViolations(page, "webhook replay detail");
  await captureState(page, testInfo, "admin-webhook-detail");

  await page.locator("[data-role='replay-single']").click();
  await expect(page.getByText("Webhook replay requested.")).toBeVisible();

  await page.goto(`/billing/events?source_webhook_event_id=${fixture.webhook_id}&actor_type=admin`);
  await expect(page.getByRole("cell", { name: "admin.webhook.replay.completed" })).toBeVisible();
  await assertNoSeriousAccessibilityViolations(page, "admin replay audit event");
  await captureState(page, testInfo, "admin-replay-audit");
});
