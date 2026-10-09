// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { test, expect } = require("./support/test.js");
const { readFixture, login, workspaceBillingLink, waitForLiveView } = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const phase = "234-admin-customers-subscriptions";
const destination = ".planning/phases/234-admin-customers-subscriptions/captures/post-layout"; // archive-sweep-exempt: capture destination
const sourcePaths = [
  "accrue_admin/lib/accrue_admin/live/customer_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
  "accrue_admin/assets/css/app.css"
];
const imageNames = ["customer-detail.png", "subscription-detail.png", "subscription-drawer.png"];

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

test("Phase 234 post-layout served Admin details evidence", async ({ page, sandboxId }, testInfo) => {
  const captureMode = process.env.PHASE234_CAPTURE_POST_LAYOUT === "1";
  const { resolvePhaseEvidencePath } = await import("../../../scripts/ci/phase_evidence_path.mjs");
  const baselinePath = resolvePhaseEvidencePath(phase, "captures/pre-layout/manifest.json", { root: repoRoot });
  const baselineBytes = fs.readFileSync(baselinePath);
  const baseline = JSON.parse(baselineBytes.toString("utf8"));
  expect(baseline.phase).toBe(phase);
  const capturePath = path.join(repoRoot, destination);
  if (captureMode && fs.existsSync(capturePath) && fs.readdirSync(capturePath).length > 0) {
    throw new Error(`post-layout evidence is write-once: ${capturePath}`);
  }

  if (!captureMode) {
    const manifestPath = resolvePhaseEvidencePath(phase, "captures/post-layout/manifest.json", { root: repoRoot });
    const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    expect(manifest.phase).toBe(phase);
    for (const [name, expected] of Object.entries(manifest.images)) {
      const imagePath = resolvePhaseEvidencePath(phase, `captures/post-layout/${name}`, { root: repoRoot });
      const bytes = fs.readFileSync(imagePath);
      expect(bytes.length).toBe(expected.bytes);
      expect(sha256(bytes)).toBe(expected.sha256);
    }
  }

  const fixture = readFixture();
  const sourceDigests = captureMode ? Object.fromEntries(sourcePaths.map((source) => {
    const bytes = fs.readFileSync(path.join(repoRoot, source));
    return [source, { sha256: sha256(bytes), bytes: bytes.length }];
  })) : undefined;
  const sourceHeadSha = captureMode
    ? execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim()
    : undefined;

  await login(page, fixture, fixture.admin_email, sandboxId);
  const owner = encodeURIComponent(fixture.admin_org_alpha_slug);
  await workspaceBillingLink(page).click();
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  await page.goto(`/admin/subscriptions?view=all&org=${owner}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  const subscriptionLink = page.locator('a[href*="/admin/subscriptions/"]').first();
  await expect(subscriptionLink).toBeVisible();
  const subscriptionPath = await subscriptionLink.getAttribute("href");
  if (!subscriptionPath) throw new Error("subscription result did not expose its identity link");
  const subscriptionId = subscriptionPath.split("?")[0].split("/").pop();
  await page.goto(subscriptionPath, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  const subscriptionImage = captureMode ? await page.screenshot({ fullPage: true }) : undefined;

  const customerLink = page.locator('a[href*="/admin/customers/"]').first();
  await expect(customerLink).toBeVisible();
  const customerPath = await customerLink.getAttribute("href");
  if (!customerPath) throw new Error("subscription detail did not expose its customer link");
  const customerId = customerPath.split("?")[0].split("/").pop();
  await page.goto(customerPath, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  const customerImage = captureMode ? await page.screenshot({ fullPage: true }) : undefined;

  await page.goto(subscriptionPath, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  let drawerImage;
  if (captureMode) {
    const drawerTrigger = page.getByRole("button", { name: /cancel|pause|resume|more/i }).first();
    if (await drawerTrigger.count()) await drawerTrigger.click();
    drawerImage = await page.screenshot({ fullPage: true });
  }

  await page.setViewportSize({ width: 320, height: 800 });
  await page.goto(customerPath, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  const customerOverflow = await page.evaluate(() => ({ viewport: document.documentElement.clientWidth, document: document.documentElement.scrollWidth, elements: [...document.querySelectorAll("body *")].map((el) => ({ tag: el.tagName, className: typeof el.className === "string" ? el.className : "", id: el.id, left: el.getBoundingClientRect().left, right: el.getBoundingClientRect().right, width: el.getBoundingClientRect().width })).filter((box) => box.right > document.documentElement.clientWidth + 1 || box.left < -1).sort((a, b) => b.right - a.right).slice(0, 12) }));
  expect(customerOverflow.document <= customerOverflow.viewport).toBeTruthy();
  await expect(page.locator(".ax-customer-detail-page .ax-summary-card")).toBeVisible();
  const peerTabs = page.locator(".ax-customer-peer-tabs .ax-tab");
  await expect(peerTabs).toHaveCount(3);
  for (const tab of await peerTabs.all()) {
    expect((await tab.boundingBox())?.height ?? 0).toBeGreaterThanOrEqual(44);
  }

  await page.goto(subscriptionPath, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  const subscriptionOverflow = await page.evaluate(() => ({ viewport: document.documentElement.clientWidth, document: document.documentElement.scrollWidth }));
  expect(subscriptionOverflow.document <= subscriptionOverflow.viewport).toBeTruthy();
  await expect(page.locator(".ax-subscription-detail-page .ax-summary-card")).toBeVisible();
  await expect(page.getByText("Subscription is active", { exact: true })).toBeVisible();
  // This seeded record has a persisted price identity, but no confirmed amount.
  // Keep those independent facts truthful instead of demanding a missing-price state.
  await expect(page.locator(".ax-summary-facts")).toContainText("price_basic");
  await expect(page.getByText("Amount is not confirmed in admin", { exact: true }).first()).toBeVisible();
  await expect(page.locator(".ax-subscription-detail-page [data-ax-action-band] .ax-button:visible").first()).toBeVisible();
  expect(await page.locator(".ax-subscription-detail-page [data-ax-action-band] .ax-button:visible").first().evaluate((button) => button.getBoundingClientRect().height)).toBeGreaterThanOrEqual(44);

  const assetUrl = await page.locator('link[rel="stylesheet"][href*="/admin/assets/css-"]').getAttribute("href");
  if (!assetUrl) throw new Error("served Admin stylesheet link was not found");
  const assetResponse = await page.request.get(assetUrl);
  expect(assetResponse.ok()).toBeTruthy();
  const servedAsset = await assetResponse.body();
  const builtAsset = fs.readFileSync(path.join(repoRoot, "accrue_admin/priv/static/accrue_admin.css"));

  const manifest = {
    phase,
    captured_at: new Date().toISOString(),
    source_head_sha: sourceHeadSha,
    sources: sourceDigests,
    baseline_manifest_sha256: sha256(baselineBytes),
    assets: {
      built: { sha256: sha256(builtAsset), bytes: builtAsset.length },
      served: { sha256: sha256(servedAsset), bytes: servedAsset.length, url: assetUrl }
    },
    fixture: { owner: fixture.admin_org_alpha_slug, customer_id: customerId, subscription_id: subscriptionId },
    viewport: testInfo.project.use.viewport,
    theme: "default host theme",
    states: {
      "customer-detail.png": { route: `/admin/customers/${customerId}?org=${owner}`, state: "customer detail" },
      "subscription-detail.png": { route: `/admin/subscriptions/${subscriptionId}?org=${owner}`, state: "subscription detail" },
      "subscription-drawer.png": { route: `/admin/subscriptions/${subscriptionId}?org=${owner}`, state: "subscription detail action drawer if available" }
    },
    capture_command: "PHASE234_CAPTURE_POST_LAYOUT=1 npm run e2e -- e2e/phase234-post-layout.spec.js --workers=1",
    images: {}
  };
  if (captureMode) {
    fs.mkdirSync(capturePath, { recursive: true });
    const imageBytes = [customerImage, subscriptionImage, drawerImage];
    for (const [index, name] of imageNames.entries()) {
      const bytes = imageBytes[index];
      fs.writeFileSync(path.join(capturePath, name), bytes, { flag: "wx" });
      manifest.images[name] = { sha256: sha256(bytes), bytes: bytes.length };
    }
    fs.writeFileSync(path.join(capturePath, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`, { flag: "wx" });
  }
});
