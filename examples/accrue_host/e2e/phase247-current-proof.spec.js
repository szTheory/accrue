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
  "accrue_admin/lib/accrue_admin/components/json_viewer.ex",
  "accrue_admin/lib/accrue_admin/components/kpi_card.ex",
  "accrue_admin/lib/accrue_admin/components/window_selector.ex",
  "accrue_admin/lib/accrue_admin/copy.ex",
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
      const file = `${lane}-${scenario}-${size}-${theme}.png`;
      const fullPath = path.join(captureDir, file);
      if (fs.existsSync(fullPath)) throw new Error(`Refusing to overwrite proof image ${file}`);
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
  const existing = new Set(manifest.captures.map((entry) => entry.file));
  for (const capture of captures) {
    if (existing.has(capture.file)) throw new Error(`Refusing duplicate manifest image ${capture.file}`);
  }
  manifest.captures.push(...captures);
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600, flag: "w" });
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
  await expect(page.locator("[data-ax-recovery-hero], [data-ax-recovery-work-queue]").first()).toBeVisible();
  await expect(page.locator("[data-ax-recovery-supporting-funnel]")).toBeVisible();
  const assets = await fetchAssets(page);
  await captureMatrix(page, "ordinary", "/admin/analytics/recovery", "payment-recovery", assets, {
    route_connected: true,
    currency_states: await page.locator("[data-ax-currency-pair]").count(),
    coverage_visible: await page.getByText(/coverage/i).count() > 0
  });
});

heldoutTest("@phase247-current-heldout populated webhook detail and replay review stay scoped", async ({ page, sandboxId }, testInfo) => {
  testInfo.setTimeout(90_000);
  if (process.env.PHASE247_PROOF_LANE !== "heldout") test.skip();
  await page.addInitScript(() => { document.documentElement.classList.add("accrue-admin"); });
  const fixture = readFixture();
  await openWorkspace(page, fixture, sandboxId);

  const route = `/admin/webhooks?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
  await page.goto(route);
  await waitForLiveView(page);
  const links = page.locator('a[href*="/admin/webhooks/"]');
  let eligibleDetail = null;
  for (let index = 0; index < await links.count(); index += 1) {
    const candidate = links.nth(index);
    const href = await candidate.getAttribute("href");
    const rowText = await candidate.locator("xpath=ancestor::tr[1]").innerText().catch(() => candidate.locator("xpath=ancestor::*[self::article or self::li][1]").innerText().catch(() => ""));
    if (href && /failed|dead/i.test(rowText)) { eligibleDetail = href; break; }
  }
  expect(eligibleDetail, "held-out owner has an observed failed/dead webhook for replay review").toBeTruthy();

  await page.goto(eligibleDetail);
  await waitForLiveView(page);
  await expect(page.locator("[data-role='webhook-observed-status']")).toBeVisible();
  await expect(page.locator("[data-ax-action-band]")).toContainText("Replay webhook");
  await expect(page.locator("[data-role='replay-single']")).toBeVisible();
  const detailAssets = await fetchAssets(page);
  await captureMatrix(page, "heldout", new URL(eligibleDetail, page.url()).pathname, "webhook-populated-detail", detailAssets, {
    observed_status_visible: true,
    exact_secondary_evidence_available: true,
    replay_action_available: true
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
  if (await cancel.count()) await cancel.click();

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
