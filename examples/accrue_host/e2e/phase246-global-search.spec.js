// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { test: ordinaryTest, expect } = require("@playwright/test");
const { test: heldoutTest } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const captureDir = path.join(repoRoot, ".planning/phases/246-collection-controls-and-search/captures/phase246-global-search");
const sourcePaths = [
  "accrue_admin/lib/accrue_admin/components/global_search.ex",
  "accrue_admin/lib/accrue_admin/components/topbar.ex",
  "accrue_admin/assets/js/hooks/command_palette.js",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/accrue_admin.js",
  "examples/accrue_host/lib/accrue_host_web/router.ex",
  "examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex",
  "examples/accrue_host/e2e/phase246-global-search.spec.js"
];

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function sourceDigests() {
  return Object.fromEntries(sourcePaths.map((relativePath) => [
    relativePath,
    sha256(fs.readFileSync(path.join(repoRoot, relativePath)))
  ]));
}

async function servedAsset(page, selector, sourcePath) {
  const href = await page.locator(selector).getAttribute(selector.startsWith("script") ? "src" : "href");
  expect(href, `served asset URL for ${sourcePath}`).toBeTruthy();
  const response = await page.evaluate(async (url) => {
    const result = await fetch(url, { cache: "no-store" });
    const bytes = await result.arrayBuffer();
    const digest = await crypto.subtle.digest("SHA-256", bytes);
    return {
      status: result.status,
      bytes: bytes.byteLength,
      sha256: Array.from(new Uint8Array(digest), (value) => value.toString(16).padStart(2, "0")).join("")
    };
  }, href);
  const local = fs.readFileSync(path.join(repoRoot, sourcePath));
  expect(response.status, `${sourcePath} status`).toBe(200);
  expect(response.sha256, `${sourcePath} served digest`).toBe(sha256(local));
  return { path: new URL(href, page.url()).pathname, sha256: response.sha256, bytes: response.bytes };
}

async function saveCapture(page, filename, metadata) {
  fs.mkdirSync(captureDir, { recursive: true, mode: 0o700 });
  const screenshot = await page.screenshot({
    path: path.join(captureDir, filename),
    fullPage: true,
    animations: "disabled",
    timeout: 20_000
  });
  const manifestPath = path.join(captureDir, "manifest.json");
  let manifest = { phase: "246", captures: [] };
  if (fs.existsSync(manifestPath)) manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  manifest.captures = manifest.captures.filter((capture) => capture.file !== filename);
  manifest.captures.push({
    file: filename,
    route: new URL(page.url()).pathname,
    captured_at: new Date().toISOString(),
    browser: { name: "chromium", version: page.context().browser()?.version() },
    viewport: page.viewportSize(),
    theme: await page.locator("html").getAttribute("data-theme"),
    source_digests: sourceDigests(),
    assets: metadata.assets,
    screenshot: { sha256: sha256(screenshot), bytes: screenshot.length }
  });
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600 });
}

async function signInOrdinary(page) {
  const operatorPassword = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD;
  ordinaryTest.skip(!operatorPassword, "set the local Phase 245 preview operator password in the test environment");
  await page.goto("/users/log-in");
  const csrfToken = await page.locator("meta[name='csrf-token']").getAttribute("content");
  expect(csrfToken).toBeTruthy();
  await Promise.all([
    page.waitForURL((url) => url.pathname === "/", { waitUntil: "domcontentloaded" }),
    page.evaluate(({ token, email, password }) => {
      const form = document.createElement("form");
      form.method = "post";
      form.action = "/users/log-in";
      for (const [name, value] of Object.entries({
        _csrf_token: token,
        "user[email]": email,
        "user[password]": password
      })) {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = name;
        input.value = value;
        form.append(input);
      }
      document.body.append(form);
      form.submit();
    }, {
      token: csrfToken,
      email: process.env.ACCRUE_HOST_PREVIEW_OPERATOR_EMAIL || "admin@example.com",
      password: operatorPassword
    })
  ]);
}

ordinaryTest("@phase246-ordinary global billing search keeps one pointer, keyboard, ARIA, and Enter target", async ({ page }) => {
  await signInOrdinary(page);
  await page.goto("/admin");
  await waitForLiveView(page);

  const trigger = page.getByRole("button", { name: /Search billing: customers, invoices, and subscriptions/i });
  await trigger.click();
  await waitForLiveView(page);
  let input = page.locator("#global-search-input");
  await expect(input).toBeFocused();
  await input.press("Escape");
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await expect(trigger).toBeFocused();

  await trigger.click();
  await waitForLiveView(page);
  input = page.locator("#global-search-input");
  await input.fill("example.com");
  const items = page.locator(".ax-command-palette-item[data-path]");
  await expect.poll(() => items.count()).toBeGreaterThan(1);
  await expect(items.filter({ hasText: "admin@example.com" }).first()).toBeVisible();
  await expect(items.filter({ hasText: /Phase 191/ })).toHaveCount(0);
  await expect(page.locator("#search-spinner")).toBeHidden();

  const cssAsset = await servedAsset(page, 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css");
  const jsAsset = await servedAsset(page, 'script[src*="/admin/assets/js-"]', "accrue_admin/priv/static/accrue_admin.js");
  await saveCapture(page, "ordinary-search-results.png", { assets: { css: cssAsset, js: jsAsset } });

  await items.first().hover();
  await input.focus();
  await input.press("ArrowDown");
  await expect(input).toBeFocused();
  const secondId = await items.nth(1).getAttribute("id");
  await expect(input).toHaveAttribute("aria-activedescendant", secondId);
  await expect(page.locator(".ax-command-palette-item.ax-active")).toHaveCount(1);
  await expect(items.nth(1)).toHaveAttribute("aria-selected", "true");
  const hoverAndActivePaint = await page.evaluate(() => {
    const active = document.querySelector(".ax-command-palette-item.ax-active");
    const hovered = document.querySelector(".ax-command-palette-item:hover");
    return {
      activeId: active?.id,
      activeBackground: active && getComputedStyle(active).backgroundColor,
      hoverId: hovered?.id,
      hoverBackground: hovered && getComputedStyle(hovered).backgroundColor,
      selectedToken: getComputedStyle(document.documentElement).getPropertyValue("--ax-interactive-selected").trim()
    };
  });
  expect(hoverAndActivePaint.activeId).toBe(secondId);
  expect(hoverAndActivePaint.hoverId).not.toBe(secondId);
  expect(hoverAndActivePaint.activeBackground).not.toBe(hoverAndActivePaint.hoverBackground);

  const firstId = await items.first().getAttribute("id");
  const expectedPath = await items.first().getAttribute("data-path");
  await items.first().hover();
  await expect(input).toHaveAttribute("aria-activedescendant", firstId);
  await expect(items.first()).toHaveAttribute("aria-selected", "true");
  await input.press("Enter");
  await expect(page).toHaveURL(new RegExp(expectedPath.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
});

heldoutTest("@phase246-heldout authenticated fixtures prove loading, failures, groups, and long identities", async ({ page, sandboxId }) => {
  await page.addInitScript(() => {
    document.documentElement.classList.add("accrue-admin");
    document.documentElement.dataset.theme = "light";
  });
  const fixture = readFixture();
  await login(page, fixture, fixture.admin_email, sandboxId);
  const fixtureResponse = await page.goto("/admin/__phase246/states");
  expect(fixtureResponse?.status(), "authenticated held-out fixture route").toBe(200);
  await waitForLiveView(page);
  await expect(page.getByTestId("phase246-states")).toBeVisible();

  await page.getByRole("button", { name: "Table loading" }).click();
  await expect(page.locator('[data-role="loading-skeleton"]')).toBeVisible();
  await page.getByRole("button", { name: "Table initial-error" }).click();
  await expect(page.locator('[data-role="unavailable-state"]')).toBeVisible();
  await page.getByRole("button", { name: "Table partial-error" }).click();
  await expect(page.locator('[data-role="partial-read-error"]')).toBeVisible();
  await expect(page.getByRole("cell", { name: "Retained result" })).toBeVisible();
  await page.getByRole("button", { name: "Table success" }).click();
  await expect(page.locator("#phase246-state-table").getByRole("cell", { name: "Ada Lovelace" })).toBeVisible();

  await page.setViewportSize({ width: 320, height: 820 });
  await page.getByRole("button", { name: "Search loading" }).click();
  const dialog = page.getByRole("dialog", { name: "Global search" });
  await expect(dialog).toBeVisible();
  const spinner = page.locator("#search-spinner");
  await expect(spinner).toBeVisible();
  const spinnerSize = await spinner.evaluate((element) => ({
    width: getComputedStyle(element).width,
    height: getComputedStyle(element).height,
    display: getComputedStyle(element).display
  }));
  expect(spinnerSize).toEqual({ width: "20px", height: "20px", display: "block" });

  // Fixture drivers remain behind the real backdrop; activate their LiveView event directly.
  await page.getByRole("button", { name: "Search partial" }).evaluate((button) => button.click());
  await expect(page.getByTestId("search-state")).toHaveText("partial");
  await expect(spinner).toBeHidden();
  await expect(page.getByText("Results couldn't be loaded. Successful groups remain available.")).toBeVisible();
  await expect(page.locator('[data-search-group="customers"] .ax-command-palette-item').first()).toContainText("Ada Lovelace");
  await expect(page.getByRole("button", { name: "Retry failed groups" })).toBeVisible();
  const cssAsset = await servedAsset(page, 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css");
  await saveCapture(page, "heldout-partial-search-320.png", { assets: { css: cssAsset } });

  await page.getByRole("button", { name: "Search zero" }).evaluate((button) => button.click());
  await expect(page.getByTestId("search-state")).toHaveText("zero");
  await expect(page.getByText(/No billing records match/)).toBeVisible();
  await page.getByRole("button", { name: "Search one" }).evaluate((button) => button.click());
  await expect(page.getByTestId("search-state")).toHaveText("one");
  await expect(page.locator('[data-search-group="customers"] .ax-command-palette-item')).toHaveCount(1);
  await page.getByRole("button", { name: "Search many" }).evaluate((button) => button.click());
  await expect(page.getByTestId("search-state")).toHaveText("many");
  await expect(page.locator('[data-search-group="customers"] .ax-command-palette-item')).toHaveCount(2);
  await page.getByRole("button", { name: "Search long" }).evaluate((button) => button.click());
  await expect(page.getByTestId("search-state")).toHaveText("long");
  await expect(page.locator('[data-search-group="customers"] .ax-command-palette-item').filter({ hasText: /Zoë 世界 — 世界 世界/ })).toBeVisible();
  await page.emulateMedia({ colorScheme: "dark" });
  await page.evaluate(() => { document.documentElement.dataset.theme = "dark"; });
  const geometry = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    page: document.documentElement.scrollWidth,
    dialog: document.querySelector(".ax-command-palette").getBoundingClientRect().width,
    theme: document.documentElement.dataset.theme
  }));
  expect(geometry.theme).toBe("dark");
  expect(geometry.page).toBeLessThanOrEqual(geometry.viewport);
  expect(geometry.dialog).toBeLessThanOrEqual(geometry.viewport - 32);
  await page.setViewportSize({ width: 1440, height: 900 });
  await expect(page.getByRole("dialog")).toBeVisible();
});
