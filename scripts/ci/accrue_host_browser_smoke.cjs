#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");
const { chromium, expect } = require("@playwright/test");

const baseURL = process.env.ACCRUE_HOST_BASE_URL || "http://127.0.0.1:4101";
const fixturePath = process.env.ACCRUE_HOST_E2E_FIXTURE;

if (!fixturePath) {
  throw new Error("ACCRUE_HOST_E2E_FIXTURE is required");
}

const fixture = JSON.parse(fs.readFileSync(path.resolve(fixturePath), "utf8"));
const { DASHBOARD_DISPLAY_HEADLINE } = require("../../examples/accrue_host/e2e/support/copy_dashboard.js");

async function login(page, email) {
  await page.goto(`${baseURL}/users/log-in`);
  const csrfToken = await page.locator("meta[name='csrf-token']").getAttribute("content");
  const response = await page.request.post(`${baseURL}/users/log-in`, {
    form: {
      _csrf_token: csrfToken,
      "user[email]": email,
      "user[password]": fixture.password
    }
  });

  if (!response.ok()) {
    throw new Error(`login POST failed for ${email}: ${response.status()} ${response.statusText()}`);
  }

  await page.goto(`${baseURL}/`);
  try {
    await expect(page.getByRole("link", { name: "Go to billing" })).toBeVisible();
  } catch (error) {
    console.error(`login did not reach authenticated home for ${email}`);
    console.error(`url: ${page.url()}`);
    console.error((await page.locator("body").innerText()).slice(0, 2000));
    throw error;
  }
}

async function run() {
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();

  page.on("pageerror", (error) => console.error(`browser page error: ${error.message}`));
  page.on("requestfailed", (request) => {
    console.error(`browser request failed: ${request.method()} ${request.url()} ${request.failure()?.errorText}`);
  });

  try {
    await login(page, fixture.normal_email);
    await expect(page.getByRole("link", { name: "Go to billing" })).toBeVisible();
    await page.getByRole("link", { name: "Go to billing" }).click();
    await expect(page.getByRole("heading", { name: "Choose a plan" })).toBeVisible();
    try {
      await page.waitForFunction(
        () => Boolean(document.querySelector("[data-phx-main].phx-connected")),
        null,
        { timeout: 5000 }
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
    await expect(page.getByText("No billing activity yet")).toBeVisible();

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

    await page.getByRole("button", { name: "Cancel subscription" }).click();
    await expect(page.getByText("Cancel subscription: Confirm cancellation before ending access.")).toBeVisible();
    await page.getByRole("button", { name: "Confirm cancellation" }).click();
    await expect(page.getByText("Subscription canceled.")).toBeVisible();

    await context.clearCookies();
    await login(page, fixture.admin_email);

    await page.goto(`${baseURL}/billing`);
    await expect(page.getByText(DASHBOARD_DISPLAY_HEADLINE)).toBeVisible();

    await page.goto(`${baseURL}/billing/webhooks/${fixture.webhook_id}`);
    await expect(page.getByRole("heading", { name: "invoice.payment_failed" })).toBeVisible();
    await page.locator("[data-role='replay-single']").click();
    await expect(page.locator("[data-role='confirm-replay']")).toBeVisible();
    await page.locator("[data-role='confirm-replay']").click();
    await expect(
      page
        .getByText("Replay requested for the active organization.")
        .or(page.getByText("Webhook replay requested."))
    ).toBeVisible();

    await page.goto(`${baseURL}/billing/events?source_webhook_event_id=${fixture.webhook_id}&actor_type=admin`);
    await expect(page.getByRole("cell", { name: "admin.webhook.replay.completed" })).toBeVisible();
  } finally {
    await browser.close();
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
