// @ts-check
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

const defaultFixturePath = path.join(os.tmpdir(), "accrue-host-e2e-fixture.json");

function readFixture() {
  const fixturePath = process.env.ACCRUE_HOST_E2E_FIXTURE || defaultFixturePath;

  if (!fs.existsSync(fixturePath)) {
    throw new Error(`ACCRUE_HOST_E2E_FIXTURE is missing at ${fixturePath}`);
  }

  return JSON.parse(fs.readFileSync(path.resolve(fixturePath), "utf8"));
}

function reseedFixture() {
  const fixturePath = process.env.ACCRUE_HOST_E2E_FIXTURE || defaultFixturePath;
  const repoRoot = path.resolve(process.cwd(), "..", "..");

  execFileSync("mix", ["run", path.join(repoRoot, "scripts/ci/accrue_host_seed_e2e.exs")], {
    cwd: process.cwd(),
    stdio: "inherit",
    env: {
      ...process.env,
      MIX_ENV: "test",
      ACCRUE_HOST_E2E_FIXTURE: fixturePath
    }
  });

  process.env.ACCRUE_HOST_E2E_FIXTURE = fixturePath;
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
  const screenshotDir = path.join(process.cwd(), "test-results", "phase15-trust", testInfo.project.name);
  const screenshotPath = path.join(screenshotDir, `${name}.png`);

  fs.mkdirSync(screenshotDir, { recursive: true });
  await page.screenshot({ path: screenshotPath, fullPage: true });
  await testInfo.attach(`${testInfo.project.name}-${name}`, { path: screenshotPath, contentType: "image/png" });
}

async function expectVisibleInViewport(locator, label) {
  await locator.scrollIntoViewIfNeeded();
  await expect(locator, `${label} should be visible`).toBeVisible();

  const box = await locator.boundingBox();
  expect(box, `${label} should have a bounding box`).not.toBeNull();

  if (!box) {
    return;
  }

  const viewport = locator.page().viewportSize();
  expect(viewport, `${label} should have a viewport`).not.toBeNull();

  if (!viewport) {
    return;
  }

  expect(box.x, `${label} should not be clipped on the left`).toBeGreaterThanOrEqual(0);
  expect(box.y, `${label} should not be clipped above the viewport`).toBeGreaterThanOrEqual(0);
}

async function expectNoHorizontalOverflow(page, label) {
  const overflow = await page.evaluate(() => ({
    documentWidth: document.documentElement.scrollWidth,
    viewportWidth: window.innerWidth
  }));

  expect(
    overflow.documentWidth,
    `${label} should not hide text or actions behind horizontal overflow`
  ).toBeLessThanOrEqual(overflow.viewportWidth + 1);
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

test("@phase15-trust canonical first-run and admin replay walkthrough stays release-blocking", async ({
  page,
  context
}, testInfo) => {
  reseedFixture();
  const fixture = readFixture();
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
  await expect(page.getByText("No billing activity yet")).toBeVisible();
  await assertNoSeriousAccessibilityViolations(page, "first-run billing empty state");
  await assertResponsiveState(page, "first-run billing empty state", [
    {
      locator: page.locator("[data-plan-id='price_basic'] button", { hasText: "Start subscription" }),
      label: "primary action"
    },
    {
      locator: page.getByText("No billing activity yet"),
      label: "empty state copy"
    }
  ]);
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
    page.getByText("Local billing projections at a glance")
  );

  expect(billingElapsedMs).toBeGreaterThanOrEqual(0);
  await assertNoSeriousAccessibilityViolations(page, "admin dashboard");
  await assertResponsiveState(page, "admin dashboard", [
    {
      locator: page.getByText("Local billing projections at a glance"),
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
  await assertNoSeriousAccessibilityViolations(page, "webhook replay detail");
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
  await expect(page.getByText("Webhook replay requested.")).toBeVisible();

  const auditElapsedMs = await measureVisibleTransition(
    page,
    "admin replay audit",
    () => page.goto(`/billing/events?source_webhook_event_id=${fixture.webhook_id}&actor_type=admin`),
    page.getByRole("cell", { name: "admin.webhook.replay.completed" })
  );

  expect(auditElapsedMs).toBeGreaterThanOrEqual(0);
  await assertNoSeriousAccessibilityViolations(page, "admin replay audit event");
  await assertResponsiveState(page, "admin replay audit event", [
    {
      locator: page.getByRole("cell", { name: "admin.webhook.replay.completed" }),
      label: "replay audit row"
    },
    {
      locator: page.getByText("Append-only billing and admin activity"),
      label: "audit heading"
    }
  ]);
  await captureState(page, testInfo, "admin-replay-audit");
});
