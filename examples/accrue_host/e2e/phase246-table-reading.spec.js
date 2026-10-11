// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { test: ordinaryTest, expect } = require("@playwright/test");
const { test: heldoutTest } = require("./support/test.js");
const { login, readFixture, waitForLiveView } = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const captureDir = path.join(repoRoot, ".planning/phases/246-collection-controls-and-search/captures/phase246-table-reading");
const sourcePaths = [
  "accrue_admin/lib/accrue_admin/components/data_table.ex",
  "accrue_admin/lib/accrue_admin/components/empty_state.ex",
  "accrue_admin/lib/accrue_admin/live/invoices_live.ex",
  "accrue_admin/lib/accrue_admin/live/customers_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
  "accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/accrue_admin.js",
  "examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex",
  "examples/accrue_host/e2e/phase246-table-reading.spec.js"
];

const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const sourceDigests = () => Object.fromEntries(sourcePaths.map((file) => [file, sha256(fs.readFileSync(path.join(repoRoot, file)))]));

async function servedAsset(page, selector, sourcePath) {
  const href = await page.locator(selector).getAttribute(selector.startsWith("script") ? "src" : "href");
  expect(href, `served URL for ${sourcePath}`).toBeTruthy();
  const served = await page.evaluate(async (url) => {
    const response = await fetch(url, { cache: "no-store" });
    const bytes = await response.arrayBuffer();
    const digest = await crypto.subtle.digest("SHA-256", bytes);
    return {
      status: response.status,
      bytes: bytes.byteLength,
      sha256: Array.from(new Uint8Array(digest), (value) => value.toString(16).padStart(2, "0")).join("")
    };
  }, href);
  expect(served.status).toBe(200);
  expect(served.sha256).toBe(sha256(fs.readFileSync(path.join(repoRoot, sourcePath))));
  return { path: new URL(href, page.url()).pathname, sha256: served.sha256, bytes: served.bytes };
}

async function capture(page, name, assets) {
  fs.mkdirSync(captureDir, { recursive: true, mode: 0o700 });
  const bytes = await page.screenshot({ path: path.join(captureDir, name), fullPage: true, animations: "disabled" });
  const manifestPath = path.join(captureDir, "manifest.json");
  const manifest = fs.existsSync(manifestPath) ? JSON.parse(fs.readFileSync(manifestPath, "utf8")) : { phase: "246", captures: [] };
  manifest.captures = manifest.captures.filter((entry) => entry.file !== name);
  manifest.captures.push({
    file: name,
    route: new URL(page.url()).pathname,
    captured_at: new Date().toISOString(),
    browser: { name: "chromium", version: page.context().browser()?.version() },
    viewport: page.viewportSize(),
    theme: await page.locator("html").getAttribute("data-theme"),
    source_sha: await page.evaluate(() => document.documentElement.dataset.phase246SourceSha || null),
    source_digests: sourceDigests(),
    assets,
    screenshot: { sha256: sha256(bytes), bytes: bytes.length }
  });
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600 });
}

ordinaryTest("@phase246-ordinary scoped customer and invoice list journeys remain usable", async ({ page }) => {
  const password = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD;
  ordinaryTest.skip(!password, "local preview operator password is required for the ordinary host");
  await page.goto("/users/log-in");
  await page.getByLabel(/email/i).fill(process.env.ACCRUE_HOST_PREVIEW_OPERATOR_EMAIL || "admin@example.com");
  await page.getByLabel(/password/i).fill(password);
  await page.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL(/\/$/);
  await page.goto("/admin/customers");
  await waitForLiveView(page);
  await expect(page.locator("[data-connection-state='connected']")).toBeVisible();
  await expect(page.locator("[data-ax-list='customers']")).toBeVisible();
  await page.goto("/admin/invoices");
  await waitForLiveView(page);
  await expect(page.locator("[data-ax-list='invoices']")).toBeVisible();
  await expect(page.locator(".ax-data-table-identity").first()).toBeVisible();
});

heldoutTest("@phase246-heldout table state fixtures retain identity, order, and responsive geometry", async ({ page, sandboxId }) => {
  await page.addInitScript(() => {
    document.documentElement.classList.add("accrue-admin");
    document.documentElement.dataset.theme = "light";
  });
  const fixture = readFixture();
  await login(page, fixture, fixture.admin_email, sandboxId);
  const response = await page.goto("/admin/__phase246/states");
  expect(response?.status()).toBe(200);
  await waitForLiveView(page);

  const css = await servedAsset(page, 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css");
  const js = await servedAsset(page, 'script[src*="/admin/assets/js-"]', "accrue_admin/priv/static/accrue_admin.js");
  await page.evaluate((sha) => { document.documentElement.dataset.phase246SourceSha = sha; }, sha256(JSON.stringify(sourceDigests())));

  await page.getByRole("button", { name: "Table loading" }).click();
  await expect(page.locator('[data-role="loading-skeleton"]')).toBeVisible();
  await page.getByRole("button", { name: "Table initial-error" }).click();
  await expect(page.locator('[data-role="unavailable-state"]')).toBeVisible();
  await page.getByRole("button", { name: "Table partial-error" }).click();
  await expect(page.locator('[data-role="partial-read-error"]')).toBeVisible();
  await expect(page.getByRole("cell", { name: "Retained result" })).toBeVisible();
  await page.getByRole("button", { name: "Table zero" }).click();
  await expect(page.locator('[data-ax-state="first-run-empty"]')).toBeVisible();
  await page.getByRole("button", { name: "Table one" }).click();
  await expect(page.locator("#phase246-state-table tbody > tr[data-row-id]")).toHaveCount(1);
  await page.getByRole("button", { name: "Table many" }).click();
  await expect(page.locator("#phase246-state-table tbody > tr[data-row-id]")).toHaveCount(3);

  for (const [width, height, suffix] of [[1280, 900, "wide"], [320, 820, "320"]]) {
    await page.setViewportSize({ width, height });
    for (const theme of ["light", "dark"]) {
      await page.goto("/admin/__phase246/states?table=long");
      await waitForLiveView(page);
      await page.getByRole("radio", { name: theme === "dark" ? "Dark" : "Light" }).click();
      await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
      await expect(page.getByTestId("table-state")).toHaveText("long");
      const identitySelector = suffix === "wide"
        ? "#phase246-state-table tbody > tr[data-row-id] .ax-data-table-identity"
        : "#phase246-state-table .ax-data-table-card-header .ax-data-table-identity";
      const identity = page.locator(identitySelector).first();
      await expect(identity).toContainText("Zoë 世界");
      await expect(page.locator(identitySelector + " [data-clipboard-text='cus_" + "unbroken".repeat(18) + "']").first()).toBeVisible();
      const geometry = await page.evaluate(() => ({
        viewport: document.documentElement.clientWidth,
        page: document.documentElement.scrollWidth,
        identity: [...document.querySelectorAll("#phase246-state-table .ax-data-table-identity")]
          .find((element) => element.getClientRects().length > 0)?.getBoundingClientRect().width,
        theme: document.documentElement.dataset.theme
      }));
      expect(geometry.theme).toBe(theme);
      expect(geometry.page).toBeLessThanOrEqual(geometry.viewport);
      expect(geometry.identity).toBeGreaterThan(0);
      const assets = { css, js };
      if (process.env.PHASE246_CAPTURE === "1") {
        await capture(page, `heldout-${suffix}-${theme}.png`, assets);
      }
    }
  }
});
