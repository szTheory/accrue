// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const orgQuery = (fixture) => `org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function seedCustomerUpdatedEvent(fixture) {
  const customerId = fixture.admin_denial_customer_id;
  const script = `
    alias Accrue.Events.Event
    alias Accrue.Repo
    event = Repo.insert!(%Event{
      type: "customer.updated",
      schema_version: 1,
      actor_type: "admin",
      actor_id: "phase244-browser",
      subject_type: "Customer",
      subject_id: "${customerId}",
      data: %{"phase244" => "disclosure proof"},
      inserted_at: ~U[2026-10-10 23:59:59.123456Z]
    })
    IO.write(event.id)
  `;
  const output = execFileSync("mix", ["run", "-e", script], {
    cwd: path.join(repoRoot, "examples/accrue_host"),
    encoding: "utf8",
    env: { ...process.env, MIX_ENV: "test" }
  }).trim();
  return output.split(/\s+/).at(-1);
}

function seedRelatedWebhookEvent(fixture) {
  const script = `
    alias Accrue.Events.Event
    alias Accrue.Repo
    event = Repo.insert!(%Event{
      type: "customer.updated",
      schema_version: 1,
      actor_type: "webhook",
      actor_id: "phase244-webhook-evidence",
      subject_type: "Customer",
      subject_id: "${fixture.admin_denial_customer_id}",
      caused_by_webhook_event_id: "${fixture.webhook_id}",
      data: %{},
      inserted_at: ~U[2026-10-10 23:59:59.123456Z]
    })
    IO.write(event.id)
  `;
  const output = execFileSync("mix", ["run", "-e", script], {
    cwd: path.join(repoRoot, "examples/accrue_host"),
    encoding: "utf8",
    env: { ...process.env, MIX_ENV: "test" }
  }).trim();
  return output.split(/\s+/).at(-1);
}

function readWebhookReplayFacts(webhookId) {
  const script = `
    import Ecto.Query
    alias Accrue.Events.Event
    alias Accrue.Repo
    alias Accrue.Webhook.WebhookEvent
    alias Oban.Job

    [webhook_id] = System.argv()
    webhook = Repo.get!(WebhookEvent, webhook_id)
    jobs = Repo.all(
      from job in Job,
        where:
          job.worker == "Accrue.Webhook.DispatchWorker" and
            fragment("?->>'webhook_event_id' = ?", job.args, ^webhook_id),
        order_by: [asc: job.inserted_at, asc: job.id],
        select: %{id: job.id, state: job.state}
    )
    events = Repo.all(
      from event in Event,
        where:
          event.caused_by_webhook_event_id == ^webhook_id and
            event.type in ["webhook.replay_requested", "admin.webhook.replay.completed"],
        order_by: [asc: event.inserted_at, asc: event.id],
        select: event.type
    )

    IO.write("[phase244-replay-facts]" <> Jason.encode!(%{
      webhook_status: Atom.to_string(webhook.status),
      dispatch_jobs: jobs,
      replay_and_audit_events: events
    }))
  `;
  const output = execFileSync("mix", ["run", "-e", script, "--", webhookId], {
    cwd: path.join(repoRoot, "examples/accrue_host"),
    encoding: "utf8",
    env: { ...process.env, MIX_ENV: "test" }
  });
  const match = output.match(/\[phase244-replay-facts\](\{[^\n]+\})/);
  if (!match) throw new Error(`missing replay fact record in Mix output: ${output.slice(-1000)}`);
  return JSON.parse(match[1]);
}

async function captureAdminAssets(page) {
  const entries = [
    ["css", 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css"],
    ["js", 'script[src*="/admin/assets/js-"]', "accrue_admin/priv/static/accrue_admin.js"]
  ];
  const rows = [];

  for (const [kind, selector, packagePath] of entries) {
    const href = await page.locator(selector).getAttribute(kind === "css" ? "href" : "src");
    expect(href).toMatch(new RegExp(`/admin/assets/${kind}-[a-f0-9]{32}$`));
    const response = await page.request.get(href);
    expect(response.status()).toBe(200);
    const served = await response.body();
    const packageBytes = fs.readFileSync(path.join(repoRoot, packagePath));
    const compiledPath = path.join(
      process.env.MIX_BUILD_PATH,
      "lib/accrue_admin/priv",
      packagePath.replace("accrue_admin/priv/", "")
    );
    const compiledBytes = fs.readFileSync(compiledPath);
    expect(sha256(served)).toBe(sha256(packageBytes));
    expect(sha256(compiledBytes)).toBe(sha256(packageBytes));
    rows.push({ kind, url: new URL(href, page.url()).href, sha256: sha256(served), bytes: served.length });
  }
  return rows;
}

async function assertEventDisclosures(page, activation) {
  const activity = page.locator("details[data-ax-lazy-activity]");
  const activitySummary = activity.locator("summary");
  if (activation === "keyboard") {
    await activitySummary.focus();
    await expect(activitySummary).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(activitySummary).toBeFocused();
  } else {
    await activitySummary.tap();
  }
  await expect(activity).toHaveAttribute("open", "");
  await expect(activity.locator(".ax-timeline")).toBeVisible();

  if (activation === "keyboard") {
    await page.keyboard.press("Enter");
  } else {
    await activitySummary.tap();
  }
  await expect(activity).not.toHaveAttribute("open", "");

  const raw = page.locator("details[data-ax-lazy-json]");
  const rawSummary = raw.locator("summary");
  if (activation === "keyboard") {
    await rawSummary.focus();
    await page.keyboard.press("Enter");
    await expect(rawSummary).toBeFocused();
  } else {
    await rawSummary.tap();
  }
  await expect(raw).toHaveAttribute("open", "");
  await expect(raw.locator("#event-payload")).toBeVisible();
  await expect(activity).not.toHaveAttribute("open", "");
}

test("Phase 244 customer update retains exact scoped event evidence @phase244-desktop", async ({ page, sandboxId }, testInfo) => {
  const fixture = readFixture();
  const eventId = seedCustomerUpdatedEvent(fixture);
  expect(eventId).toMatch(/^\d+$/);

  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.goto("/app/billing");
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  await page.goto(`/admin?${orgQuery(fixture)}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  const viewEvents = page.getByRole("link", { name: "View events" });
  await expect(viewEvents).toHaveAttribute("href", `/admin/events?${orgQuery(fixture)}`);
  await viewEvents.click();
  await waitForLiveView(page);
  await expect(page).toHaveURL(new RegExp(`/admin/events\\?org=${fixture.admin_org_alpha_slug}$`));
  await page.goto(`/admin?${orgQuery(fixture)}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  const eventRow = page.locator(".ax-timeline-item").filter({ hasText: "Customer updated" });
  await expect(eventRow).toBeVisible();
  await expect(eventRow).toContainText(fixture.admin_denial_customer_id);
  const eventLink = eventRow.getByRole("link", { name: "Open event" });
  await expect(eventLink).toHaveAttribute("href", new RegExp(`/admin/events/${eventId}\\?org=`));
  await eventLink.click();
  await waitForLiveView(page);
  await expect(page).toHaveURL(new RegExp(`/admin/events/${eventId}\\?org=`));
  await expect(page.getByText("customer.updated", { exact: true }).first()).toBeVisible();
  await expect(page.getByText(fixture.admin_denial_customer_id, { exact: true }).first()).toBeVisible();
  await expect(page.getByText("2026-10-10T23:59:59.123456Z", { exact: true }).first()).toBeVisible();
  await assertEventDisclosures(page, "keyboard");

  const assets = await captureAdminAssets(page);
  const evidence = {
    checkoutHead: execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim(),
    fixture: "disposable HOST-BROWSER-VERIFY01 fixture; scoped customer.updated event",
    route: page.url(),
    viewport: page.viewportSize(),
    theme: await page.locator("html").getAttribute("data-theme"),
    assets
  };
  console.log(`[phase244-asset-evidence] ${JSON.stringify(evidence)}`);
  await testInfo.attach("phase244-asset-evidence.json", {
    body: Buffer.from(JSON.stringify(evidence, null, 2)),
    contentType: "application/json"
  });
});

async function assertRelatedWebhookEvidence(page, fixture, sandboxId, testInfo, activation) {
  const eventId = seedRelatedWebhookEvent(fixture);
  expect(eventId).toMatch(/^\d+$/);

  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.goto("/app/billing");
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  const webhookRoute = `/admin/webhooks/${fixture.webhook_id}?${orgQuery(fixture)}`;
  await page.goto(webhookRoute, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  await expect(page.getByRole("heading", { name: "invoice.payment_failed" })).toBeVisible();
  await expect(page.locator("dd.ax-summary-list-value").filter({ hasText: /^Dead$/ })).toBeVisible();

  const replayFactsBefore = readWebhookReplayFacts(fixture.webhook_id);
  await page.getByRole("button", { name: "Replay webhook" }).click();
  const replayForm = page.locator("[data-ax-action-drawer-form]:visible");
  await expect(replayForm).toContainText("evt_host_browser_replay");
  await replayForm.getByRole("button", { name: "Confirm replay" }).click();
  const stepUp = page.getByRole("dialog", { name: "Step-up required" });
  await expect(stepUp).toBeVisible();
  expect(readWebhookReplayFacts(fixture.webhook_id)).toEqual(replayFactsBefore);
  await stepUp.getByRole("button", { name: "Cancel" }).click();
  await expect(stepUp).toBeHidden();

  const activity = page.locator("details[data-ax-lazy-activity]").first();
  const summary = activity.locator("summary.ax-detail-section-head");
  await expect(summary).toBeVisible();
  if (activation === "keyboard") {
    await summary.focus();
    await expect(summary).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(summary).toBeFocused();
  } else {
    await summary.tap();
  }
  await expect(activity).toHaveAttribute("open", "");
  await expect(activity.locator("section[aria-label='Webhook attempt history']")).toBeVisible();
  await expect(activity.locator("section[aria-label='Derived events']")).toBeVisible();

  const attempts = activity.locator("section[aria-label='Webhook attempt history']");
  const derived = activity.locator("section[aria-label='Derived events']");
  const eventItem = derived.locator(".ax-timeline-item").filter({ hasText: `event #${eventId}` });
  await expect(eventItem).toBeVisible();
  await expect(eventItem.locator(".ax-label")).toHaveText("Customer updated");
  await expect(attempts).toContainText("Discarded");
  await expect(page.locator("dd.ax-summary-list-value").filter({ hasText: /^Dead$/ })).toBeVisible();

  const evidence = eventItem.locator("details.ax-timeline-details");
  const evidenceSummary = evidence.locator("summary");
  await expect(evidenceSummary).toHaveText("Inspect event evidence");
  if (activation === "keyboard") {
    await evidenceSummary.focus();
    await expect(evidenceSummary).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(evidenceSummary).toBeFocused();
  } else {
    await evidenceSummary.tap();
  }
  await expect(evidence).toHaveAttribute("open", "");

  const evidenceText = evidence.locator("pre");
  await expect(evidenceText).toContainText("Stored event key: customer.updated");
  await expect(evidenceText).toContainText(`Event ID: ${eventId}`);
  await expect(evidenceText).toContainText(`Actor ID: phase244-webhook-evidence`);
  await expect(evidenceText).toContainText(`Subject: Customer ${fixture.admin_denial_customer_id}`);
  await expect(evidenceText).toContainText(`Webhook delivery ID: ${fixture.webhook_id}`);
  await expect(evidenceText).toContainText("Recorded: 2026-10-10T23:59:59.123456Z");
  await evidenceText.selectText();
  const selectedText = await page.evaluate(() => window.getSelection()?.toString() || "");
  expect(selectedText).toContain(fixture.webhook_id);
  expect(selectedText).toContain("2026-10-10T23:59:59.123456Z");

  const dimensions = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    document: document.documentElement.scrollWidth,
    evidence: document.querySelector("[aria-label='Derived events'] .ax-timeline-details pre")?.getBoundingClientRect().width
  }));
  expect(dimensions.document, `horizontal overflow at ${dimensions.viewport}px`).toBeLessThanOrEqual(dimensions.viewport);
  expect(dimensions.evidence).toBeGreaterThan(0);

  const themeEvidence = [];
  for (const theme of ["light", "dark"]) {
    await page.locator("html").evaluate((element, value) => element.setAttribute("data-theme", value), theme);
    const computed = await page.locator("html").evaluate((element) => ({
      theme: element.getAttribute("data-theme"),
      canvas: getComputedStyle(element).getPropertyValue("--ax-base").trim(),
      primary: getComputedStyle(element).getPropertyValue("--ax-primary").trim()
    }));
    expect(computed.theme).toBe(theme);
    expect(computed.canvas).toBeTruthy();
    expect(computed.primary).toBeTruthy();
    await expect(evidenceText).toContainText(`Webhook delivery ID: ${fixture.webhook_id}`);
    themeEvidence.push(computed);
  }

  if (activation === "keyboard") {
    await summary.focus();
    await page.keyboard.press("Enter");
    await expect(summary).toBeFocused();
  } else {
    await summary.tap();
  }
  await expect(activity).not.toHaveAttribute("open", "");
  await page.locator("details[data-ax-lazy-json] summary").click();
  await expect(page.locator("details[data-ax-lazy-json]")).toHaveAttribute("open", "");
  await expect(activity).not.toHaveAttribute("open", "");
  await expect(page.locator("details[data-ax-lazy-json] #webhook-payload")).toBeVisible();
  await expect(activity).not.toHaveAttribute("open", "");
  if (activation === "keyboard") {
    await summary.focus();
    await page.keyboard.press("Enter");
  } else {
    await summary.tap();
  }
  await expect(activity).toHaveAttribute("open", "");

  const assets = await captureAdminAssets(page);
  const eventLink = eventItem.getByRole("link", { name: "Open event" });
  const eventHref = await eventLink.getAttribute("href");
  expect(new URL(eventHref, page.url()).pathname).toBe(`/admin/events/${eventId}`);
  expect(new URL(eventHref, page.url()).searchParams.get("org")).toBe(fixture.admin_org_alpha_slug);
  await eventLink.click();
  await waitForLiveView(page);
  await expect(page).toHaveURL(new RegExp(`/admin/events/${eventId}\\?org=`));
  await expect(page.getByText("customer.updated", { exact: true }).first()).toBeVisible();
  const sourceWebhook = page.getByRole("link", { name: new RegExp(`^Source webhook ${fixture.webhook_id}`) });
  await expect(sourceWebhook).toBeVisible();
  expect(new URL(await sourceWebhook.getAttribute("href"), page.url()).pathname).toBe(`/admin/webhooks/${fixture.webhook_id}`);
  expect(new URL(await sourceWebhook.getAttribute("href"), page.url()).searchParams.get("org")).toBe(fixture.admin_org_alpha_slug);

  const proof = {
    checkoutHead: execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim(),
    ownerSpecSha256: sha256(fs.readFileSync(__filename)),
    fixture: "disposable HOST-BROWSER-VERIFY01 fixture; one customer.updated event linked to the existing scoped webhook; no delivery mutation",
    replayConfirmation: { result: "step-up required; no job, status, replay-request, or audit change", facts: replayFactsBefore },
    webhookRoute: new URL(webhookRoute, page.url()).href,
    eventRoute: page.url(),
    viewport: page.viewportSize(),
    themes: themeEvidence,
    assets
  };
  console.log(`[phase244-webhook-evidence] ${JSON.stringify(proof)}`);
  await testInfo.attach("phase244-webhook-evidence.json", {
    body: Buffer.from(JSON.stringify(proof, null, 2)),
    contentType: "application/json"
  });
}

test("Phase 244 webhook activity exposes exact related event evidence @phase244-desktop", async ({ page, sandboxId }, testInfo) => {
  await assertRelatedWebhookEvidence(page, readFixture(), sandboxId, testInfo, "keyboard");
});

test.describe("Phase 244 webhook activity on touch viewport", () => {
  test.use({ viewport: { width: 320, height: 800 }, isMobile: true, hasTouch: true });

  test("Phase 244 event detail keeps exact recorded time readable at 320px @phase244-mobile", async ({ page, sandboxId }, testInfo) => {
    const fixture = readFixture();
    const eventId = seedCustomerUpdatedEvent(fixture);
    expect(eventId).toMatch(/^\d+$/);

    await login(page, fixture, fixture.admin_email, sandboxId);
    await page.goto("/app/billing");
    await waitForLiveView(page);
    await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
    await waitForLiveView(page);
    await page.goto(`/admin/events/${eventId}?${orgQuery(fixture)}`, { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    await expect(page.getByText("customer.updated", { exact: true }).first()).toBeVisible();
    const recordedField = page
      .locator("dl.ax-field-list .ax-field")
      .filter({ has: page.locator("dt.ax-field-label", { hasText: /^Recorded$/ }) })
      .locator("dd.ax-field-value");
    await expect(recordedField).toHaveText("2026-10-10T23:59:59.123456Z");
    await expect(recordedField).toBeVisible();

    await assertEventDisclosures(page, "touch");

    const dimensions = await recordedField.evaluate((value) => {
      const field = value;
      return {
        viewport: document.documentElement.clientWidth,
        document: document.documentElement.scrollWidth,
        valueWidth: field.clientWidth,
        valueScrollWidth: field.scrollWidth
      };
    });
    expect(dimensions.viewport).toBe(320);
    expect(dimensions.document).toBeLessThanOrEqual(dimensions.viewport);
    expect(dimensions.valueWidth).toBeGreaterThan(0);
    expect(dimensions.valueScrollWidth).toBeLessThanOrEqual(dimensions.valueWidth);

    const assets = await captureAdminAssets(page);
    const evidence = {
      checkoutHead: execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim(),
      ownerSpecSha256: sha256(fs.readFileSync(__filename)),
      fixture: "disposable HOST-BROWSER-VERIFY01 fixture; scoped customer.updated event",
      route: page.url(),
      viewport: page.viewportSize(),
      exactRecordedTime: await recordedField.textContent(),
      dimensions,
      assets
    };
    console.log(`[phase244-event-mobile-evidence] ${JSON.stringify(evidence)}`);
    await testInfo.attach("phase244-event-mobile-evidence.json", {
      body: Buffer.from(JSON.stringify(evidence, null, 2)),
      contentType: "application/json"
    });
  });

  test("Phase 244 webhook activity disclosure works by touch @phase244-mobile", async ({ page, sandboxId }, testInfo) => {
    await assertRelatedWebhookEvidence(page, readFixture(), sandboxId, testInfo, "touch");
  });
});
