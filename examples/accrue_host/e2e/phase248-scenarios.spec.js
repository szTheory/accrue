// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { test: ordinaryTest, expect } = require("@playwright/test");
const { test: heldoutTest } = require("./support/test.js");
const { login, readFixture, waitForLiveView, workspaceBillingLink } = require("./support/fixture.js");

const root = path.resolve(__dirname, "../../..");
const captureDir = path.join(root, ".planning/phases/248-reproducible-scenarios-and-integrated-proof/captures/phase248-current-proof");
const ordinaryBase = "http://accrue-host-phase245-ordinary.localhost/";
const sourceFiles = [
  "accrue_admin/lib/accrue_admin/components/app_shell.ex",
  "accrue_admin/lib/accrue_admin/components/empty_state.ex",
  "accrue_admin/lib/accrue_admin/live/customer_live.ex",
  "accrue_admin/lib/accrue_admin/live/invoice_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "accrue_admin/lib/accrue_admin/live/webhook_live.ex",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/assets/css/theme.css",
  "accrue_admin/assets/js/app.js",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/accrue_admin.js",
  "examples/accrue_host/e2e/phase248-scenarios.spec.js",
  "examples/accrue_host/e2e/phase248-heldout-setup.js",
  "examples/accrue_host/e2e/support/fixture.js",
  "examples/accrue_host/e2e/support/test.js",
  "examples/accrue_host/playwright.phase248-ordinary.config.js",
  "examples/accrue_host/playwright.phase248-heldout.config.js",
  "scripts/ci/accrue_host_seed_e2e.exs",
  "scripts/ci/seed_phase245_ordinary.sh",
  "scripts/ci/verify_phase248_render_proof.mjs"
];
const digest = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const sourceSha = () => execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim();
const sourceDigests = () => Object.fromEntries(sourceFiles.map((file) => [file, digest(fs.readFileSync(path.join(root, file)))]));

async function loginOrdinary(page) {
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
  await page.goto("/admin");
  await expect(page.locator("aside[aria-label='Admin navigation']"), "the configured operator session reaches mounted Admin").toBeVisible();
}

async function loginHeldout(page, fixture, sandboxId, organizationSlug = fixture.admin_org_alpha_slug) {
  await page.addInitScript(() => { document.documentElement.classList.add("accrue-admin"); });
  await login(page, fixture, fixture.admin_email, sandboxId);
  await workspaceBillingLink(page).click();
  await waitForLiveView(page);
  const workspace = page.locator(`button[data-organization-slug="${organizationSlug}"]`);
  await expect(workspace, "the selected admin owner is available to this authenticated fixture").toBeVisible();
  await workspace.click();
  await waitForLiveView(page);
}

async function servedAssets(page) {
  const one = async (selector, source) => {
    const attr = selector.startsWith("script") ? "src" : "href";
    const url = await page.locator(selector).getAttribute(attr);
    expect(url, `rendered ${source} URL`).toBeTruthy();
    const response = await page.request.get(url);
    expect(response.status()).toBe(200);
    const bytes = await response.body();
    const sha256 = digest(bytes);
    expect(sha256, `${source} bytes match the committed static asset`).toBe(digest(fs.readFileSync(path.join(root, source))));
    return { path: source, served_path: new URL(url, page.url()).pathname, sha256, bytes: bytes.length };
  };
  return {
    css: await one('link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css"),
    js: await one('script[src*="/admin/assets/js-"]', "accrue_admin/priv/static/accrue_admin.js")
  };
}

async function setTheme(page, theme) {
  await page.locator("html").evaluate((element, value) => { element.dataset.theme = value; }, theme);
  await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
}

async function captureState(page, { lane, scenario, route, assets, checks, matrix }) {
  fs.mkdirSync(captureDir, { recursive: true });
  const captures = [];
  for (const { width, height, size, theme } of matrix) {
    await page.setViewportSize({ width, height });
    await setTheme(page, theme);
    await page.mouse.move(width - 1, height - 1);
    const file = `${lane}-${scenario}-${size}-${theme}.png`;
    // Keep the evidence framed to the actual review viewport. Full-page captures
    // extend beyond fixed drawers/bottom sheets and show page content that was
    // not visible beside the active confirmation review.
    const bytes = await page.screenshot({ path: path.join(captureDir, file), fullPage: false, animations: "disabled" });
    captures.push({
      file, origin_lane: lane, scenario, route,
      state: checks.state,
      viewport: { width, height },
      screenshot_dimensions: { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) },
      theme,
      source_sha: sourceSha(),
      source_digests: sourceDigests(),
      browser: { name: "chromium", version: page.context().browser()?.version() },
      capture_mode: "viewport",
      assets,
      checks,
      evidence_at: new Date().toISOString(),
      inspection_status: "pending",
      screenshot: { sha256: digest(bytes), bytes: bytes.length }
    });
  }
  const manifestPath = path.join(captureDir, "manifest.json");
  const manifest = fs.existsSync(manifestPath) ? JSON.parse(fs.readFileSync(manifestPath, "utf8")) : { phase: "248", captures: [] };
  const files = new Set(captures.map((capture) => capture.file));
  manifest.captures = manifest.captures.filter((capture) => !files.has(capture.file));
  manifest.captures.push(...captures);
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600, flag: "w" });
}

async function noPageOverflow(page) {
  const dimensions = await page.evaluate(() => ({ client: document.documentElement.clientWidth, scroll: document.documentElement.scrollWidth }));
  expect(dimensions.scroll, "page has no horizontal overflow").toBeLessThanOrEqual(dimensions.client);
  return dimensions;
}

ordinaryTest("@phase248-ordinary @phase248-heldout ordinary Fake invoice action review is explicitly selected and read-only", async ({ page }) => {
  if (process.env.PHASE248_PROOF_LANE !== "ordinary") ordinaryTest.skip();
  await loginOrdinary(page);
  await page.goto("/admin/invoices?view=all");
  await waitForLiveView(page);
  const links = page.locator('a[href^="/admin/invoices/"]');
  let route = null;
  for (let index = 0; index < await links.count(); index += 1) {
    const href = await links.nth(index).getAttribute("href");
    if (!href || href.includes("/admin/invoices/new")) continue;
    await page.goto(href);
    await waitForLiveView(page);
    const identity = page.locator("main h1").first();
    const action = page.locator("[data-ax-primary-action]:visible").first();
    if (await identity.count() && await action.count()) {
      const visibleIdentity = (await identity.innerText()).trim();
      expect(visibleIdentity.length).toBeGreaterThan(0);
      await action.click();
      const review = page.locator("[data-ax-action-drawer-form]:visible").first();
      await expect(review, "review is visible before confirmation and no action is submitted").toBeVisible();
      const currentUrl = new URL(page.url());
      route = `${currentUrl.pathname}${currentUrl.search}`;
      const assets = await servedAssets(page);
      await captureState(page, {
        lane: "ordinary", scenario: "ordinary-invoice-review", route, assets,
        checks: { state: "action-review-open", record_identity_visible: true, confirmation_not_submitted: true },
        matrix: [
          { width: 1280, height: 900, size: "wide", theme: "light" },
          { width: 320, height: 820, size: "narrow", theme: "dark" }
        ]
      });
      break;
    }
  }
  expect(route, "ordinary Fake preview has a rendered invoice eligible for action review").toBeTruthy();
});

heldoutTest("@phase248-heldout @phase248-empty dedicated empty subscriptions scenario is genuinely zero-record and owner-scoped", async ({ page, sandboxId }) => {
  if (process.env.PHASE248_PROOF_LANE !== "heldout") heldoutTest.skip();
  const fixture = readFixture();
  await loginHeldout(page, fixture, sandboxId, fixture.admin_org_beta_slug);
  const countScript = `
    import Ecto.Query
    alias Accrue.Billing.{Customer, Subscription}
    alias Accrue.Repo
    [organization_id] = System.argv()
    count = Repo.one(from(subscription in Subscription,
      join: customer in Customer, on: customer.id == subscription.customer_id,
      where: customer.owner_type == "Organization" and customer.owner_id == ^organization_id,
      select: count(subscription.id)))
    IO.puts("__PHASE248_SCOPED_COUNT__=" <> Integer.to_string(count))
  `;
  const rawCount = execFileSync("mix", ["run", "-e", countScript, "--", fixture.admin_org_beta_id], {
    cwd: path.join(root, "examples/accrue_host"), encoding: "utf8", env: { ...process.env, MIX_ENV: "test" }
  }).trim();
  const countMatches = [...rawCount.matchAll(/__PHASE248_SCOPED_COUNT__=(\d+)/g)].map((match) => match[1]);
  expect(countMatches, "the scoped record-count query returned one unambiguous machine-readable result").toEqual(["0"]);
  const route = `/admin/subscriptions?org=${encodeURIComponent(fixture.admin_org_beta_slug)}&view=all`;
  await page.goto(route);
  await waitForLiveView(page);
  const table = page.locator('[data-role="data-table"]');
  await expect(table).toHaveAttribute("data-ax-state", "first-run-empty");
  await expect(table).toHaveAttribute("data-ax-empty-reason", "first-run");
  await expect(page.locator("body")).not.toContainText(/access denied|unauthorized|internal server error/i);
  const assets = await servedAssets(page);
  await captureState(page, {
    lane: "heldout", scenario: "empty-subscriptions", route: `${new URL(route, page.url()).pathname}${new URL(route, page.url()).search}`,
    assets, checks: { state: "genuinely-empty", underlying_scoped_record_count: 0, unfiltered: new URL(page.url()).searchParams.get("view") === "all", owner_scope: fixture.admin_org_beta_slug },
    matrix: [
      { width: 1280, height: 900, size: "wide", theme: "light" },
      { width: 320, height: 820, size: "narrow", theme: "dark" }
    ]
  });
});

heldoutTest("@phase248-heldout @phase248-failure scoped discarded webhook renders an observed failure and supported next step", async ({ page, sandboxId }) => {
  if (process.env.PHASE248_PROOF_LANE !== "heldout") heldoutTest.skip();
  const fixture = readFixture();
  await loginHeldout(page, fixture, sandboxId);
  const route = `/admin/webhooks/${fixture.second_webhook_id}?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
  await page.goto(route);
  await waitForLiveView(page);
  const status = page.locator("[data-role='webhook-observed-status']");
  await expect(status).toBeVisible();
  await expect(status).toContainText(/dead|discarded|failed/i);
  const actionBand = page.locator("[data-ax-action-band]");
  await expect(actionBand).toContainText(/replay webhook/i);
  await expect(page.locator("[data-role='replay-single']")).toBeVisible();
  const assets = await servedAssets(page);
  const actualStatus = (await status.innerText()).trim();
  await captureState(page, {
    lane: "heldout", scenario: "failed-webhook", route: `${new URL(page.url()).pathname}${new URL(page.url()).search}`,
    assets, checks: { state: "observed-webhook-failure", observed_status: actualStatus, owner_scope: fixture.admin_org_alpha_slug, supported_next_step_visible: true, action_submitted: false },
    matrix: [
      { width: 1280, height: 900, size: "wide", theme: "dark" },
      { width: 320, height: 820, size: "narrow", theme: "light" }
    ]
  });
});

heldoutTest("@phase248-heldout @phase248-boundary existing long-name Unicode customer fits a narrow viewport", async ({ page, sandboxId }) => {
  if (process.env.PHASE248_PROOF_LANE !== "heldout") heldoutTest.skip();
  const fixture = readFixture();
  await loginHeldout(page, fixture, sandboxId);
  const target = "edge-longname@example.test";
  await page.goto("/admin/customers?view=all");
  await waitForLiveView(page);
  const row = page.locator("article, tr").filter({ hasText: target }).first();
  await expect(row, "the test-owned long-name boundary customer is present").toBeVisible();
  const link = row.locator('a[href^="/admin/customers/"]').first();
  const href = await link.getAttribute("href");
  expect(new URL(href, page.url()).pathname).toMatch(/^\/admin\/customers\/[0-9a-f-]+$/i);
  await page.goto(href);
  await waitForLiveView(page);
  await expect(row.getByText(target, { exact: true })).toBeVisible();
  await expect(row.getByText(/E2E Edge LongName/)).toBeVisible();
  const longName = page.getByText(/E2E Edge LongName/).first();
  await expect(longName).toBeVisible();
  await page.setViewportSize({ width: 320, height: 820 });
  const narrow = await noPageOverflow(page);
  const assets = await servedAssets(page);
  await captureState(page, {
    lane: "heldout", scenario: "long-name-boundary", route: `${new URL(page.url()).pathname}${new URL(page.url()).search}`,
    assets, checks: { state: "long-name-unicode-boundary", exact_identity_accessible: true, narrow_page_dimensions: narrow },
    matrix: [
      { width: 1280, height: 900, size: "wide", theme: "dark" },
      { width: 320, height: 820, size: "narrow", theme: "light" }
    ]
  });
});
