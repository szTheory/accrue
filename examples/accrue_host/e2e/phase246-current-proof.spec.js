// @ts-check
const crypto = require("node:crypto");
const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const { test: ordinaryTest, expect } = require("@playwright/test");
const { test: heldoutTest } = require("./support/test.js");
const { login, readFixture, waitForLiveView } = require("./support/fixture.js");

const root = path.resolve(__dirname, "../../..");
const captureDir = path.join(root, ".planning/phases/246-collection-controls-and-search/captures/phase246-current-proof");
const ordinaryBase = "http://accrue-host-phase245-ordinary.localhost/";
const sources = [
  "accrue_admin/lib/accrue_admin/live/invoices_live.ex",
  "accrue_admin/lib/accrue_admin/live/charges_live.ex",
  "accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex",
  "accrue_admin/lib/accrue_admin/live/coupons_live.ex",
  "accrue_admin/lib/accrue_admin/live/events_live.ex",
  "accrue_admin/lib/accrue_admin/live/webhooks_live.ex",
  "accrue_admin/lib/accrue_admin/components/data_table.ex",
  "accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex",
  "accrue_admin/lib/accrue_admin/components/id_badge.ex",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/assets/js/hooks/clipboard.js",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/accrue_admin.js",
  "examples/accrue_host/e2e/phase246-current-proof.spec.js",
  "examples/accrue_host/playwright.phase246.config.js",
  "examples/accrue_host/playwright.config.js",
  "scripts/ci/accrue_host_seed_e2e.exs"
];
const digest = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const sourceSha = () => execFileSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" }).trim();
const sourceDigests = () => Object.fromEntries(sources.map((p) => [p, digest(fs.readFileSync(path.join(root, p)))]));

async function fetchAsset(page, selector, source) {
  const href = await page.locator(selector).getAttribute(selector.startsWith("script") ? "src" : "href");
  expect(href).toBeTruthy();
  const response = await page.request.get(href);
  expect(response.status()).toBe(200);
  const bytes = await response.body();
  const sha256 = digest(bytes);
  expect(sha256).toBe(digest(fs.readFileSync(path.join(root, source))));
  return { path: source, served_path: new URL(href, page.url()).pathname, sha256, bytes: bytes.length };
}

async function setTheme(page, theme) {
  const radio = page.getByRole("radio", { name: new RegExp(theme, "i") }).first();
  if (await radio.count()) await radio.check();
  else await page.locator("html").evaluate((el, value) => { el.dataset.theme = value; }, theme);
  await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
}

async function signInOrdinary(page) {
  const password = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD;
  if (!password) throw new Error("ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD must be set for the ordinary proof");
  await page.goto("/users/log-in");
  const csrf = await page.locator("meta[name='csrf-token']").getAttribute("content");
  expect(csrf).toBeTruthy();
  const response = await page.request.post("/users/log-in", { form: {
    _csrf_token: csrf,
    "user[email]": process.env.ACCRUE_HOST_PREVIEW_OPERATOR_EMAIL || "admin@example.com",
    "user[password]": password
  } });
  expect(response.ok()).toBeTruthy();
}

async function assertConnected(page, listId) {
  await waitForLiveView(page);
  await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
  await expect(page.locator(`[data-ax-list='${listId}']`)).toBeVisible();
}

async function assertIdentityAndCopy(page, listId) {
  const list = page.locator(`[data-ax-list='${listId}']`);
  const button = list.locator("[data-clipboard-text]").first();
  await expect(button, `${listId} must have a real identity copy control`).toBeVisible();
  const exactId = await button.getAttribute("data-clipboard-text");
  expect(exactId).toBeTruthy();
  const identity = button.locator("xpath=ancestor::*[contains(@class,'ax-data-table-identity')][1]");
  await expect(identity).toContainText(exactId);
  const bbox = await button.boundingBox();
  expect(bbox?.height, `${listId} copy target height`).toBeGreaterThanOrEqual(44);
  await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
  await button.click();
  await expect(button).toHaveAttribute("data-copied", "true");
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(exactId);
  const geometry = await page.evaluate(() => ({ width: document.documentElement.clientWidth, scroll: document.documentElement.scrollWidth }));
  expect(geometry.scroll, `${listId} has no horizontal page overflow`).toBeLessThanOrEqual(geometry.width);
  return { exact_id_visible: true, copied: true, target_height: bbox.height, no_overflow: true };
}

async function capture(page, lane, route, scenario, assets) {
  if (process.env.PHASE246_CAPTURE !== "1") return;
  fs.mkdirSync(captureDir, { recursive: true, mode: 0o700 });
  const file = `${lane}-${scenario}.png`;
  const fullPath = path.join(captureDir, file);
  if (fs.existsSync(fullPath)) throw new Error(`Refusing to overwrite current proof capture: ${file}`);
  const bytes = await page.screenshot({ path: fullPath, fullPage: true, animations: "disabled" });
  const entry = {
    file, origin_lane: lane, scenario, route, viewport: page.viewportSize(),
    theme: await page.locator("html").getAttribute("data-theme"), source_sha: sourceSha(),
    source_digests: sourceDigests(), browser: { name: "chromium", version: page.context().browser()?.version() },
    assets, screenshot: { sha256: digest(bytes), bytes: bytes.length }
  };
  const manifestPath = path.join(captureDir, "manifest.json");
  const manifest = fs.existsSync(manifestPath) ? JSON.parse(fs.readFileSync(manifestPath, "utf8")) : { phase: "246", captures: [] };
  if (manifest.captures.some((row) => row.file === file)) throw new Error(`Refusing duplicate manifest capture: ${file}`);
  manifest.captures.push(entry);
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600, flag: "w" });
}

async function captureMatrix(page, lane, route, scenario, assets) {
  for (const [width, height, size] of [[1280, 900, "wide"], [320, 820, "narrow"]]) {
    await page.setViewportSize({ width, height });
    for (const theme of ["light", "dark"]) {
      await setTheme(page, theme);
      await capture(page, lane, route, `${scenario}-${size}-${theme}`, assets);
    }
  }
}

ordinaryTest("@phase246-current-ordinary current invoices toolbar and payment/coupon/event identities", async ({ page }) => {
  testOrdinaryGuard();
  await signInOrdinary(page);
  await page.goto("/admin/invoices?view=all");
  await assertConnected(page, "invoices");
  await expect(page.locator("[data-ax-view-nav] a[aria-current='page']")).toBeVisible();
  await page.locator("[data-ax-view-nav]").getByRole("link").first().click();
  await expect.poll(() => new URL(page.url()).searchParams.get("view")).toBeNull();
  await expect(page.locator("[data-ax-filter-chips] .ax-filter-chip").first()).toBeVisible();
  await expect(page.locator("[data-ax-result-count]")).toContainText(/Showing \d+/);
  await expect.poll(() => page.locator("[data-ax-list='invoices'] tbody tr[data-row-id]").count()).toBeGreaterThan(0);
  await page.locator("[data-ax-clear-all]").click();
  await expect.poll(() => new URL(page.url()).searchParams.get("view")).toBeNull();
  await expect(page.locator("[data-ax-result-count]")).toBeVisible();
  const assets = {
    css: await fetchAsset(page, 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css"),
    js: await fetchAsset(page, 'script[src*="/admin/assets/js-"]', "accrue_admin/priv/static/accrue_admin.js")
  };
  await captureMatrix(page, "ordinary", "/admin/invoices", "invoices-toolbar", assets);

  for (const [route, id] of [["/admin/payments", "payments"], ["/admin/coupons", "coupons"], ["/admin/events", "events"]]) {
    await page.goto(route);
    await assertConnected(page, id);
    await expect.poll(() => page.locator(`[data-ax-list='${id}'] [data-clipboard-text]`).count()).toBeGreaterThan(0);
    await assertIdentityAndCopy(page, id);
    await captureMatrix(page, "ordinary", route, id, assets);
  }
});

function testOrdinaryGuard() {
  if (process.env.ACCRUE_HOST_ORDINARY_BASE_URL !== ordinaryBase) throw new Error("ordinary host URL did not match guarded Phase 245 instance");
}

heldoutTest("@phase246-current-heldout current production Connect and webhook identities", async ({ page, sandboxId }) => {
  await page.addInitScript(() => { document.documentElement.classList.add("accrue-admin"); });
  const fixture = readFixture();
  await login(page, fixture, fixture.admin_email, sandboxId);
  const assets = {};
  for (const [route, listId] of [[`/admin/connect?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`, "connect-accounts"], [`/admin/webhooks?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`, "webhooks"]]) {
    await page.goto(route);
    await assertConnected(page, listId);
    await expect.poll(() => page.locator(`[data-ax-list='${listId}'] [data-clipboard-text]`).count()).toBeGreaterThan(0);
    await assertIdentityAndCopy(page, listId);
    if (!assets.css) {
      assets.css = await fetchAsset(page, 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css");
      assets.js = await fetchAsset(page, 'script[src*="/admin/assets/js-"]', "accrue_admin/priv/static/accrue_admin.js");
    }
    await captureMatrix(page, "heldout", new URL(route, page.url()).pathname, listId, assets);
  }
});
