// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { test, expect } = require("./support/test.js");
const { readFixture, login, workspaceBillingLink, waitForLiveView } = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const captureDir = path.join(repoRoot, ".planning/phases/233-shared-direction-portal-contract/captures");

function md5(body) {
  return crypto.createHash("md5").update(body).digest("hex");
}

async function assertServedAsset(page, selector, sourcePath) {
  const assetUrl = await page.locator(selector).evaluate((element) =>
    element.getAttribute("href") || element.getAttribute("src")
  );
  expect(assetUrl).toMatch(/\/assets\/(?:brand|css|js)-[a-f0-9]{32}$/);
  const response = await page.request.get(assetUrl);
  expect(response.ok()).toBeTruthy();
  const served = await response.body();
  const source = fs.readFileSync(path.join(repoRoot, sourcePath));
  expect(assetUrl).toContain(md5(source));
  expect(md5(served)).toBe(md5(source));
  expect(served.equals(source)).toBeTruthy();
}

async function contrast(page, foreground, background) {
  return page.evaluate(({ foreground, background }) => {
    const rgb = (value) => {
      const channels = value.match(/[\d.]+/g).map(Number);
      return channels.slice(0, 3).map((channel) =>
        value.startsWith("color(srgb") ? channel * 255 : channel
      );
    };
    const luminance = (value) => {
      const channels = rgb(value).map((channel) => {
        const srgb = channel / 255;
        return srgb <= 0.04045 ? srgb / 12.92 : ((srgb + 0.055) / 1.055) ** 2.4;
      });
      return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
    };
    const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
    return (values[0] + 0.05) / (values[1] + 0.05);
  }, { foreground, background });
}

async function assertNoHorizontalOverflow(page) {
  const width = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    document: document.documentElement.scrollWidth
  }));
  expect(width.document, `horizontal overflow at ${width.viewport}px`).toBeLessThanOrEqual(width.viewport);
}

test("current served Admin and Portal controls retain semantic contrast, focus, and 320px reflow", async ({
  page,
  sandboxId
}, testInfo) => {
  const fixture = readFixture();
  const adminTheme = fs.readFileSync(path.join(repoRoot, "accrue_admin/assets/css/theme.css"), "utf8");
  const publicBrand = fs.readFileSync(path.join(repoRoot, "accrue/priv/static/brand.css"), "utf8");
  const portalCss = fs.readFileSync(path.join(repoRoot, "accrue_portal/priv/static/accrue_portal.css"), "utf8");
  expect(adminTheme).toContain("--ax-status-success-text");
  expect(adminTheme).toContain("--ax-focus-ring");
  expect(publicBrand).toContain("--accrue-brand-accent");
  expect(publicBrand).toContain("--accrue-brand-accent-text");
  expect(portalCss).toContain("var(--accrue-brand-accent-text)");

  await login(page, fixture, fixture.admin_email, sandboxId);
  await workspaceBillingLink(page).click();
  await waitForLiveView(page);
  await expect(page.getByTestId("organization-switcher")).toBeVisible();
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  await page.goto(`/admin?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`);
  await waitForLiveView(page);
  await expect(page.locator("html.accrue-admin")).toHaveCount(1);
  await assertServedAsset(page, 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css");
  await expect(page.locator(".ax-status-badge, .ax-badge").first()).toBeVisible();
  await page.keyboard.press("Tab");
  const adminFocus = await page.evaluate(() => {
    const style = getComputedStyle(document.activeElement);
    return { outline: style.outlineStyle, width: style.outlineWidth, color: style.outlineColor };
  });
  expect(adminFocus.outline).not.toBe("none");
  expect(adminFocus.width).not.toBe("0px");
  await page.setViewportSize({ width: 320, height: 800 });
  await assertNoHorizontalOverflow(page);
  fs.mkdirSync(captureDir, { recursive: true });
  const adminCapture = await page.screenshot({ fullPage: true });
  fs.writeFileSync(path.join(captureDir, "semantic-admin-320.png"), adminCapture);
  await testInfo.attach("phase233-admin-semantic.png", { body: adminCapture, contentType: "image/png" });

  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.goto("/billing/payment-methods");
  await waitForLiveView(page);
  await expect(page.locator("main.portal-shell")).toBeVisible();
  await assertServedAsset(page, 'link[rel="stylesheet"][href*="/billing/assets/brand-"]', "accrue/priv/static/brand.css");
  await assertServedAsset(page, 'link[rel="stylesheet"][href*="/billing/assets/css-"]', "accrue_portal/priv/static/accrue_portal.css");
  const status = page.locator(".portal-status-active").first();
  await expect(status).toBeVisible();
  await expect(status).toContainText(/default/i);
  expect(await status.evaluate((node) => getComputedStyle(node, "::before").content)).toContain("✓");

  const action = page.locator(".portal-button-primary").first();
  const actionColors = await action.evaluate((node) => {
    const style = getComputedStyle(node);
    return { foreground: style.color, background: style.backgroundColor };
  });
  expect(await contrast(page, actionColors.foreground, actionColors.background)).toBeGreaterThanOrEqual(4.5);

  // Exercise an arbitrary, very light host accent. The text/focus bridge must remain readable.
  await page.locator("html").evaluate((node) => {
    node.style.setProperty("--accrue-brand-accent", "#ffffff");
    node.setAttribute("data-theme", "light");
  });
  const accentLink = page.locator(".portal-breadcrumb-link").first();
  await accentLink.hover();
  const accentText = await accentLink.evaluate((node) => {
    const style = getComputedStyle(node);
    return { foreground: style.color, background: getComputedStyle(document.body).backgroundColor };
  });
  expect(await contrast(page, accentText.foreground, accentText.background)).toBeGreaterThanOrEqual(4.5);

  await page.keyboard.press("Tab");
  const portalFocus = await page.evaluate(() => {
    const style = getComputedStyle(document.activeElement);
    return { outline: style.outlineStyle, width: style.outlineWidth, color: style.outlineColor };
  });
  expect(portalFocus.outline).not.toBe("none");
  expect(portalFocus.width).not.toBe("0px");
  const cardBackground = await page.locator(".portal-card").first().evaluate((node) => getComputedStyle(node).backgroundColor);
  expect(await contrast(page, portalFocus.color, cardBackground)).toBeGreaterThanOrEqual(3);

  await page.emulateMedia({ colorScheme: "dark" });
  await page.locator("html").evaluate((node) => node.setAttribute("data-theme", "dark"));
  const darkAccentLink = page.locator(".portal-breadcrumb-link").first();
  await darkAccentLink.hover();
  const darkAccent = await darkAccentLink.evaluate((node) => {
    const style = getComputedStyle(node);
    return { foreground: style.color, background: getComputedStyle(document.body).backgroundColor };
  });
  const darkAccentRatio = await contrast(page, darkAccent.foreground, darkAccent.background);
  expect(darkAccentRatio, `${darkAccent.foreground} on ${darkAccent.background}`).toBeGreaterThanOrEqual(4.5);
  await page.setViewportSize({ width: 320, height: 800 });
  await assertNoHorizontalOverflow(page);
  const portalCapture = await page.screenshot({ fullPage: true });
  fs.writeFileSync(path.join(captureDir, "semantic-portal-320-dark.png"), portalCapture);
  await testInfo.attach("phase233-portal-semantic.png", { body: portalCapture, contentType: "image/png" });
});
