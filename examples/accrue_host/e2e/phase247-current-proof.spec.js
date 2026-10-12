// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { test: ordinaryTest, expect } = require("@playwright/test");
const { test: heldoutTest } = require("./support/test.js");
const { login, readFixture, waitForLiveView, workspaceBillingLink } = require("./support/fixture.js");

const root = path.resolve(__dirname, "../../..");
const captureDir = path.join(root, ".planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof");
const ordinaryBase = "http://accrue-host-phase245-ordinary.localhost/";
const sourceFiles = [
  "accrue_admin/lib/accrue_admin/components/app_shell.ex",
  "accrue_admin/lib/accrue_admin/components/detail.ex",
  "accrue_admin/lib/accrue_admin/components/detail_drawer.ex",
  "accrue_admin/lib/accrue_admin/components/json_viewer.ex",
  "accrue_admin/lib/accrue_admin/components/kpi_card.ex",
  "accrue_admin/lib/accrue_admin/components/window_selector.ex",
  "accrue_admin/lib/accrue_admin/components/topbar.ex",
  "accrue_admin/lib/accrue_admin/components/timestamp.ex",
  "accrue_admin/lib/accrue_admin/copy.ex",
  "accrue_admin/lib/accrue_admin/nav.ex",
  "accrue_admin/lib/accrue_admin/live/invoice_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "accrue_admin/lib/accrue_admin/live/webhook_live.ex",
  "accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/assets/css/theme.css",
  "accrue_admin/assets/js/app.js",
  "accrue_admin/assets/js/hooks/clipboard.js",
  "accrue_admin/assets/js/hooks/time_display.js",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/accrue_admin.js",
  "examples/accrue_host/e2e/phase247-time-tracer.spec.js",
  "examples/accrue_host/e2e/phase247-current-proof.spec.js",
  "examples/accrue_host/e2e/support/fixture.js",
  "examples/accrue_host/e2e/support/test.js",
  "examples/accrue_host/playwright.config.js",
  "examples/accrue_host/playwright.phase247.config.js",
  "examples/accrue_host/playwright.phase247-ordinary.config.js",
  "examples/accrue_host/priv/repo/seeds/ordinary.exs",
  "scripts/ci/seed_phase245_ordinary.sh",
  "scripts/ci/accrue_host_seed_e2e.exs",
  "scripts/ci/verify_phase247_render_proof.mjs"
];
const digest = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const sourceSha = () => execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim();
const sourceDigests = () => Object.fromEntries(sourceFiles.map((file) => [file, digest(fs.readFileSync(path.join(root, file)))]));

function seedHeldoutWebhookEvidence(webhookId) {
  const processorEventId = "evt_host_browser_replay_second";
  const rawBody = JSON.stringify({
    id: processorEventId,
    type: "invoice.payment_failed",
    data: { object: {
      id: "in_host_browser_replay",
      object: "invoice",
      customer: "cus_host_browser_replay_owner",
      subscription: "sub_host_browser_replay",
      attempt_count: 3,
      amount_due: 12500,
      currency: "usd"
    } }
  });
  const script = `
    import Ecto.Query
    alias Accrue.Events
    alias Accrue.Billing.Customer
    alias Accrue.Repo
    alias Accrue.Webhook.WebhookEvent
    [webhook_id, processor_event_id, raw_body] = System.argv()
    webhook = Repo.get!(WebhookEvent, webhook_id)
    customer = Repo.get_by!(Customer, processor_id: "cus_host_browser_replay_owner")
    now = DateTime.utc_now()
    webhook
    |> Ecto.Changeset.change(%{
      type: "invoice.payment_failed",
      raw_body: raw_body,
      data: Jason.decode!(raw_body),
      received_at: now
    })
    |> Repo.update!()
    {:ok, _event} = Events.record(%{
      type: "customer.updated",
      subject_type: "Customer",
      subject_id: customer.id,
      actor_type: "webhook",
      actor_id: processor_event_id,
      caused_by_webhook_event_id: webhook.id,
      idempotency_key: "phase247-populated-proof:" <> webhook.id,
      data: %{"source" => "heldout Phase247 render fixture"},
      inserted_at: now
    })
    args = %{"webhook_event_id" => webhook.id}
    existing_job_id = Repo.one(from job in Oban.Job,
      where: job.worker == "Accrue.Webhook.DispatchWorker" and
        job.args == ^args and job.state == "discarded",
      select: job.id,
      limit: 1)
    if is_nil(existing_job_id) do
      Repo.insert!(%Oban.Job{
        state: "discarded",
        queue: "accrue_webhooks",
        worker: "Accrue.Webhook.DispatchWorker",
        args: %{"webhook_event_id" => webhook.id},
        errors: [%{"attempt" => 3, "error" => "processor timeout"}],
        attempt: 3,
        max_attempts: 25,
        inserted_at: now,
        attempted_at: now,
        discarded_at: now
      })
    end
    IO.write("phase247-heldout-evidence-ready")
  `;
  const output = execFileSync("mix", ["run", "-e", script, "--", webhookId, processorEventId, rawBody], {
    cwd: path.join(root, "examples/accrue_host"),
    encoding: "utf8",
    env: { ...process.env, MIX_ENV: "test" }
  });
  if (!output.includes("phase247-heldout-evidence-ready")) {
    throw new Error("held-out webhook fixture did not report its isolated setup marker");
  }
  return rawBody;
}

async function assertExpandedWebhookEvidence(page, rawBody) {
  const activity = page.locator("details[data-ax-lazy-activity]");
  const activitySummary = activity.locator(":scope > summary");
  await activitySummary.focus();
  await activitySummary.press("Enter");
  await expect(activity).toHaveJSProperty("open", true);
  await expect(activity).toContainText("Attempt 3/25");
  await expect(activity).toContainText("customer.updated");

  const payload = page.locator("#webhook-raw-payload");
  const payloadSummary = payload.locator(":scope > summary");
  await payloadSummary.focus();
  await payloadSummary.press("Enter");
  await expect(payload).toHaveJSProperty("open", true);
  const tabs = payload.getByRole("tab");
  await expect(tabs).toHaveCount(2);
  const treeTab = tabs.filter({ hasText: "Tree" });
  const rawTab = tabs.filter({ hasText: "Raw" });
  await treeTab.focus();
  await expect(treeTab).toBeFocused();
  await page.keyboard.press("ArrowRight");
  await expect(rawTab).toBeFocused();
  await page.keyboard.press("Enter");
  const rawView = payload.locator("[role='tabpanel']:visible");
  await expect(rawView).toContainText('"attempt_count": 3');
  await expect(rawView).toContainText('"customer": "cus_host_browser_replay_owner"');
  const displayedRaw = (await rawView.textContent()).trim();
  expect(JSON.parse(displayedRaw)).toEqual(JSON.parse(rawBody));

  await page.context().grantPermissions(["clipboard-read", "clipboard-write"], { origin: new URL(page.url()).origin });
  const copyButton = payload.getByRole("button", { name: /copy/i });
  await copyButton.focus();
  await copyButton.press("Enter");
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).toBe(displayedRaw);
  return {
    activity_attempt: "3/25",
    derived_event: "customer.updated",
    raw_tab_keyboard_selected: true,
    exact_raw_copy: true
  };
}

async function setTheme(page, theme) {
  const radio = page.getByRole("radio", { name: new RegExp(theme, "i") }).first();
  if (await radio.count()) await radio.evaluate((button) => button.click());
  else await page.locator("html").evaluate((element, value) => { element.dataset.theme = value; }, theme);
  await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
}

async function fetchAssets(page) {
  const fetchOne = async (selector, source) => {
    const attribute = selector.startsWith("script") ? "src" : "href";
    const url = await page.locator(selector).getAttribute(attribute);
    expect(url, `expected rendered URL for ${source}`).toBeTruthy();
    const response = await page.request.get(url);
    expect(response.status(), `${source} response status`).toBe(200);
    const bytes = await response.body();
    const sha256 = digest(bytes);
    expect(sha256, `${source} served bytes match the built package`).toBe(digest(fs.readFileSync(path.join(root, source))));
    return { path: source, served_path: new URL(url, page.url()).pathname, sha256, bytes: bytes.length };
  };
  return {
    css: await fetchOne('link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css"),
    js: await fetchOne('script[src*="/admin/assets/js-"]', "accrue_admin/priv/static/accrue_admin.js")
  };
}

async function captureMatrix(page, lane, route, scenario, assets, checks) {
  const captures = [];
  for (const [width, height, size] of [[1280, 900, "wide"], [320, 820, "narrow"]]) {
    await page.setViewportSize({ width, height });
    for (const theme of ["light", "dark"]) {
      await setTheme(page, theme);
      await page.mouse.move(width - 1, height - 1);
      const clearedProgrammaticMainFocus = await page.evaluate(() => {
        const main = document.getElementById("main-content");
        if (main === document.activeElement) {
          main.blur();
          return true;
        }
        return false;
      });
      const focusState = await page.evaluate(() => {
        const active = document.activeElement;
        const main = document.getElementById("main-content");
        const style = active ? getComputedStyle(active) : null;
        return {
          active_tag: active?.tagName?.toLowerCase() || null,
          active_id: active?.id || null,
          main_focused: active === main,
          main_focus_visible: active === main && active.matches(":focus-visible"),
          cleared_programmatic_main_focus: false,
          pointer_target: (() => {
            const target = document.elementFromPoint(innerWidth - 1, innerHeight - 1);
            return target ? `${target.tagName.toLowerCase()}${target.id ? `#${target.id}` : ""}` : null;
          })(),
          active_outline: style ? { style: style.outlineStyle, width: style.outlineWidth, color: style.outlineColor } : null
        };
      });
      focusState.cleared_programmatic_main_focus = clearedProgrammaticMainFocus;
      if (focusState.main_focused || focusState.main_focus_visible) {
        throw new Error("capture must not retain programmatic main focus from route navigation");
      }
      const file = `${lane}-${scenario}-${size}-${theme}.png`;
      const fullPath = path.join(captureDir, file);
      const bytes = await page.screenshot({ path: fullPath, fullPage: true, animations: "disabled" });
      const dimensions = {
        width: bytes.readUInt32BE(16),
        height: bytes.readUInt32BE(20)
      };
      captures.push({
        file,
        origin_lane: lane,
        scenario,
        route,
        viewport: { width, height },
        screenshot_dimensions: dimensions,
        theme,
        source_sha: sourceSha(),
        source_digests: sourceDigests(),
        browser: { name: "chromium", version: page.context().browser()?.version() },
        capture_mode: "full_page",
        focus_state: focusState,
        assets,
        checks,
        evidence_at: new Date().toISOString(),
        inspection_status: "pending",
        screenshot: { sha256: digest(bytes), bytes: bytes.length }
      });
    }
  }
  const manifestPath = path.join(captureDir, "manifest.json");
  const manifest = fs.existsSync(manifestPath)
    ? JSON.parse(fs.readFileSync(manifestPath, "utf8"))
    : { phase: "247", captures: [] };
  const replacements = new Set(captures.map((capture) => capture.file));
  manifest.captures = manifest.captures.filter((entry) => !replacements.has(entry.file));
  manifest.captures.push(...captures);
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600, flag: "w" });
}

async function assertTimePreference(page, { copy = false } = {}) {
  await page.setViewportSize({ width: 320, height: 820 });
  await page.evaluate(() => window.scrollTo(0, 0));
  const control = page.locator("#admin-time-preference");
  const label = page.locator("label[for='admin-time-preference']");
  await expect(label).toBeVisible();
  await expect(control).toBeVisible();
  const geometry = await control.evaluate((element) => {
    const rect = element.getBoundingClientRect();
    return {
      left: rect.left,
      right: rect.right,
      top: rect.top,
      bottom: rect.bottom,
      height: rect.height,
      viewportWidth: document.documentElement.clientWidth,
      viewportHeight: document.documentElement.clientHeight
    };
  });
  expect(geometry.left, "Local/UTC control starts inside the viewport").toBeGreaterThanOrEqual(0);
  expect(geometry.right, "Local/UTC control ends inside the viewport").toBeLessThanOrEqual(geometry.viewportWidth);
  expect(geometry.top, "Local/UTC control is reachable in the viewport").toBeGreaterThanOrEqual(0);
  expect(geometry.bottom, "Local/UTC control is reachable in the viewport").toBeLessThanOrEqual(geometry.viewportHeight);
  expect(geometry.height, "Local/UTC control retains a 44px touch target").toBeGreaterThanOrEqual(44);

  await control.selectOption("utc");
  await expect(control).toHaveValue("utc");
  expect(await page.evaluate(() => localStorage.getItem("accrue_admin_time_display"))).toBe("utc");
  if (copy) {
    const timestamp = page.locator(".ax-timestamp-copy").first();
    await expect(timestamp).toBeVisible();
    const iso = await timestamp.getAttribute("data-clipboard-text");
    expect(iso).toMatch(/^\d{4}-\d\d-\d\dT.*(?:Z|[+-]\d\d:\d\d)$/);
    await expect(timestamp.locator("time")).toHaveAttribute("datetime", iso);
    await page.context().grantPermissions(["clipboard-read", "clipboard-write"], { origin: new URL(page.url()).origin });
    await timestamp.click();
    await expect(timestamp.locator("xpath=..").locator("[data-time-copy-status]")).toHaveText("Timestamp copied.");
  }
  await control.selectOption("local");
  await expect(control).toHaveValue("local");
  expect(await page.evaluate(() => localStorage.getItem("accrue_admin_time_display"))).toBe("local");
  return geometry;
}

async function assertDisclosureCueAndKeyboard(page) {
  const evidence = {};
  for (const [name, selector] of [
    ["activity", "details[data-ax-lazy-activity]"],
    ["payload", "#webhook-raw-payload"]
  ]) {
    const disclosure = page.locator(selector);
    const summary = disclosure.locator(":scope > summary");
    await expect(summary).toBeVisible();
    const geometry = await summary.boundingBox();
    expect(geometry.height, `${name} disclosure keeps a 44px target`).toBeGreaterThanOrEqual(44);
    const closedCue = await summary.evaluate((element) => getComputedStyle(element, "::after").content);
    expect(closedCue).not.toBe("none");
    expect(closedCue).not.toBe("normal");
    const heading = await summary.locator(".ax-detail-section-title").evaluate((element) => ({
      size: getComputedStyle(element).fontSize,
      weight: getComputedStyle(element).fontWeight
    }));
    expect(heading, `${name} heading follows the detail type contract`).toEqual({ size: "20px", weight: "600" });
    await summary.focus();
    await summary.press("Enter");
    await expect.poll(() => disclosure.evaluate((element) => element.open)).toBe(true);
    const openCue = await summary.evaluate((element) => getComputedStyle(element, "::after").content);
    expect(openCue).not.toBe(closedCue);
    await summary.press("Enter");
    await expect.poll(() => disclosure.evaluate((element) => element.open)).toBe(false);
    await summary.evaluate((element) => element.blur());
    evidence[name] = { closed_cue: closedCue, open_cue: openCue, target_height: geometry.height, heading };
  }
  return evidence;
}

async function openWorkspace(page, fixture, sandboxId) {
  await login(page, fixture, fixture.admin_email, sandboxId);
  await workspaceBillingLink(page).click();
  await waitForLiveView(page);
  const workspace = page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`);
  await expect(workspace, "alpha organization must be selectable in this held-out fixture").toBeVisible();
  await workspace.click();
  await waitForLiveView(page);
}

ordinaryTest("@phase247-current-ordinary invoice action review and recovery analytics render on the ordinary host", async ({ page }) => {
  if (process.env.PHASE247_PROOF_LANE !== "ordinary") test.skip();
  if (process.env.ACCRUE_HOST_ORDINARY_BASE_URL !== ordinaryBase) throw new Error("ordinary base URL did not match the guarded Phase 245 host");
  const password = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD;
  if (!password) throw new Error("ordinary proof requires the README-documented local operator credential in process memory");

  await page.goto("/users/log-in");
  const csrf = await page.locator("meta[name='csrf-token']").getAttribute("content");
  expect(csrf).toBeTruthy();
  const response = await page.request.post("/users/log-in", { form: {
    _csrf_token: csrf,
    "user[email]": process.env.ACCRUE_HOST_PREVIEW_OPERATOR_EMAIL || "admin@example.com",
    "user[password]": password
  } });
  expect(response.ok(), `ordinary operator login returned ${response.status()}`).toBeTruthy();

  await page.goto("/admin/invoices?view=all");
  await waitForLiveView(page);
  const detailLinks = page.locator('a[href^="/admin/invoices/"]');
  let actionRoute = null;
  for (let index = 0; index < await detailLinks.count(); index += 1) {
    const href = await detailLinks.nth(index).getAttribute("href");
    if (!href || href.includes("/admin/invoices/new")) continue;
    await page.goto(href);
    await waitForLiveView(page);
    const action = page.locator("[data-ax-primary-action]:visible").first();
    if (await action.count()) {
      await assertTimePreference(page);
      await action.click();
      const review = page.locator("[data-ax-action-drawer-form]:visible").first();
      await expect(review, "invoice action opens its review form before confirmation").toBeVisible();
      actionRoute = new URL(page.url()).pathname;
      const assets = await fetchAssets(page);
      await captureMatrix(page, "ordinary", actionRoute, "invoice-action-review", assets, {
        action_review_open: true,
        confirmation_not_submitted: true
      });
      break;
    }
  }
  expect(actionRoute, "ordinary fixture contains an invoice with a reviewable existing action").toBeTruthy();

  await page.goto("/admin/analytics/recovery");
  await waitForLiveView(page);
  await expect(page.locator("#admin-time-preference")).toHaveValue("local");
  await expect(page.locator("aside[aria-label='Admin navigation']")).toContainText("Payment recovery");
  await expect(page.locator("[data-ax-recovery-hero], [data-ax-recovery-work-queue]").first()).toBeVisible();
  await expect(page.locator("[data-ax-recovery-supporting-funnel]")).toBeVisible();
  const recoveryLayout = {};
  for (const [width, height, key, expectedGroups, expectedCards] of [
    [1280, 900, "wide", 1, 2],
    [320, 820, "narrow", 1, 1]
  ]) {
    await page.setViewportSize({ width, height });
    const geometry = await page.evaluate(() => {
      const groups = document.querySelector("[data-ax-recovery-hero]");
      const pair = groups?.querySelector("[data-ax-currency-pair]");
      const tracks = (element) => element ? getComputedStyle(element).gridTemplateColumns.trim().split(/\s+/).filter(Boolean).length : 0;
      return {
        groupColumns: tracks(groups),
        pairColumns: tracks(pair),
        viewportWidth: document.documentElement.clientWidth,
        pageWidth: document.documentElement.scrollWidth
      };
    });
    expect(geometry.groupColumns, `${key} recovery currency groups`).toBe(expectedGroups);
    expect(geometry.pairColumns, `${key} recovery metric pair`).toBe(expectedCards);
    expect(geometry.pageWidth, `${key} recovery has no horizontal page overflow`).toBeLessThanOrEqual(geometry.viewportWidth);
    recoveryLayout[key] = geometry;
  }
  await page.setViewportSize({ width: 1280, height: 900 });
  const assets = await fetchAssets(page);
  await captureMatrix(page, "ordinary", "/admin/analytics/recovery", "payment-recovery", assets, {
    route_connected: true,
    currency_states: await page.locator("[data-ax-currency-pair]").count(),
    coverage_visible: await page.getByText(/coverage/i).count() > 0,
    recovery_layout: recoveryLayout
  });
});

heldoutTest("@phase247-current-heldout populated webhook detail and replay review stay scoped", async ({ page, sandboxId }, testInfo) => {
  testInfo.setTimeout(90_000);
  if (process.env.PHASE247_PROOF_LANE !== "heldout") test.skip();
  await page.addInitScript(() => { document.documentElement.classList.add("accrue-admin"); });
  const fixture = readFixture();
  const expectedPayload = seedHeldoutWebhookEvidence(fixture.second_webhook_id);
  await openWorkspace(page, fixture, sandboxId);

  const route = `/admin/webhooks?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
  await page.goto(route);
  await waitForLiveView(page);
  const eligibleDetail = `/admin/webhooks/${fixture.second_webhook_id}?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
  await expect(page.locator(`a[href^="/admin/webhooks/${fixture.second_webhook_id}"]`).first(), "isolated held-out evidence fixture is owner-scoped and eligible for replay review").toBeVisible();

  await page.goto(eligibleDetail);
  await waitForLiveView(page);
  await expect(page.locator("[data-role='webhook-observed-status']")).toBeVisible();
  await expect(page.locator("[data-ax-action-band]")).toContainText("Replay webhook");
  await expect(page.locator("[data-role='replay-single']")).toBeVisible();
  const detailAssets = await fetchAssets(page);
  const preferenceGeometry = await assertTimePreference(page, { copy: true });
  await page.setViewportSize({ width: 1280, height: 900 });
  const disclosureEvidence = await assertDisclosureCueAndKeyboard(page);
  await page.mouse.move(0, 0);
  await captureMatrix(page, "heldout", new URL(eligibleDetail, page.url()).pathname, "webhook-populated-detail", detailAssets, {
    observed_status_visible: true,
    exact_secondary_evidence_available: true,
    replay_action_available: true,
    time_preference_geometry: preferenceGeometry,
    disclosure_keyboard_cue: disclosureEvidence
  });

  const populatedEvidenceChecks = await assertExpandedWebhookEvidence(page, expectedPayload);
  await captureMatrix(page, "heldout", new URL(eligibleDetail, page.url()).pathname, "webhook-populated-evidence", detailAssets, {
    activity_expanded: true,
    raw_payload_expanded: true,
    exact_deep_payload_values: true,
    ...populatedEvidenceChecks
  });

  await page.locator("[data-role='replay-single']").click();
  const replayReview = page.locator("[data-role='replay-confirm']:visible").first();
  await expect(replayReview, "replay opens review before step-up/confirmation").toBeVisible();
  await expect(replayReview.getByRole("button", { name: /confirm replay/i })).toBeVisible();
  const confirmButton = replayReview.getByRole("button", { name: /confirm replay/i });
  expect(await confirmButton.isVisible()).toBe(true);
  await captureMatrix(page, "heldout", new URL(eligibleDetail, page.url()).pathname, "webhook-replay-review", detailAssets, {
    review_open: true,
    confirmation_available: true,
    replay_submitted: false
  });
  const cancel = replayReview.getByRole("button", { name: /cancel replay/i });
  await expect(cancel, "replay review exposes one clear dismissal action").toHaveCount(1);
  await cancel.focus();
  await cancel.press("Enter");
  await expect(page.locator("#webhook-replay-drawer-portal")).toHaveCount(0);
  await expect(page.locator("[data-role='replay-single']"), "dismissal restores focus to the replay opener").toBeFocused();

  await page.goto(route);
  await waitForLiveView(page);
  let blockedDetail = null;
  const listRows = page.locator("article");
  for (let index = 0; index < await listRows.count(); index += 1) {
    const candidate = listRows.nth(index);
    const rowLink = candidate.locator('a[href*="/admin/webhooks/"]').first();
    const href = await rowLink.getAttribute("href");
    const rowText = await candidate.innerText();
    if (href && rowText && !/failed|dead/i.test(rowText)) { blockedDetail = href; break; }
  }
  if (blockedDetail) {
    await page.goto(blockedDetail);
    await waitForLiveView(page);
    await expect(page.locator("[data-role='replay-single']")).toHaveCount(0);
    await expect(page.locator("[data-ax-action-band]")).toContainText(/Replay webhook/);
    expect(await page.locator("[data-role='replay-blocked-copy']").count()).toBeGreaterThan(0);
  }
});
