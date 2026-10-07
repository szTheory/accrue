// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { test, expect } = require("./support/test.js");
const {
  readFixture,
  login,
  workspaceBillingLink,
  waitForLiveView
} = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const captureDir = path.join(
  repoRoot,
  ".planning/phases/233-shared-direction-portal-contract/captures"
);

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
  const digest = md5(source);

  expect(assetUrl).toContain(digest);
  expect(md5(served)).toBe(digest);
  expect(served.equals(source)).toBeTruthy();
  return { url: assetUrl, md5: digest, bytes: served.length };
}

test("capture current served Admin and Portal baseline with asset provenance", async ({
  page,
  sandboxId
}, testInfo) => {
  fs.mkdirSync(captureDir, { recursive: true });
  const fixture = readFixture();
  const provenance = {};

  await login(page, fixture, fixture.admin_email, sandboxId);
  await workspaceBillingLink(page).click();
  await waitForLiveView(page);
  await expect(page.getByTestId("organization-switcher")).toBeVisible();
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  await page.goto(`/admin?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`);
  await waitForLiveView(page);
  await expect(page.getByRole("main")).toBeVisible();
  await expect(page.locator("html.accrue-admin")).toHaveCount(1);
  provenance.adminCss = await assertServedAsset(
    page,
    'link[rel="stylesheet"][href*="/admin/assets/css-"]',
    "accrue_admin/priv/static/accrue_admin.css"
  );
  provenance.adminJs = await assertServedAsset(
    page,
    'script[src*="/admin/assets/js-"]',
    "accrue_admin/priv/static/accrue_admin.js"
  );
  await page.screenshot({ path: path.join(captureDir, "admin-overview.png"), fullPage: true });

  await login(page, fixture, fixture.normal_email, sandboxId);
  await page.setViewportSize({ width: 390, height: 844 });
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await page.goto("/billing");
  await waitForLiveView(page);
  await expect(page.locator("main.portal-shell")).toBeVisible();
  provenance.portalBrand = await assertServedAsset(
    page,
    'link[rel="stylesheet"][href*="/billing/assets/brand-"]',
    "accrue/priv/static/brand.css"
  );
  provenance.portalCss = await assertServedAsset(
    page,
    'link[rel="stylesheet"][href*="/billing/assets/css-"]',
    "accrue_portal/priv/static/accrue_portal.css"
  );
  provenance.portalJs = await assertServedAsset(
    page,
    'script[src*="/billing/assets/js-"]',
    "accrue_portal/priv/static/accrue_portal.js"
  );
  await expect(page.getByRole("heading").first()).toBeVisible();
  await page.screenshot({ path: path.join(captureDir, "portal-home.png"), fullPage: true });

  await page.goto("/billing/subscriptions");
  await waitForLiveView(page);
  await expect(page.locator("main.portal-shell")).toBeVisible();
  await page.screenshot({ path: path.join(captureDir, "portal-state.png"), fullPage: true });

  await testInfo.attach("phase233-asset-provenance.json", {
    body: Buffer.from(JSON.stringify(provenance, null, 2)),
    contentType: "application/json"
  });
});
