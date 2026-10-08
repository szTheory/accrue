// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { test, expect } = require("./support/test.js");
const { readFixture, login, workspaceBillingLink, waitForLiveView } = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const phase = "234-admin-customers-subscriptions";
const captureDestination = ".planning/phases/234-admin-customers-subscriptions/captures/pre-layout"; // archive-sweep-exempt: capture destination
const sourcePaths = [
  "accrue_admin/lib/accrue_admin/live/customer_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
  "accrue_admin/assets/css/app.css"
];

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

async function readAndVerifyBaseline() {
  const { resolvePhaseEvidencePath } = await import("../../../scripts/ci/phase_evidence_path.mjs");
  const evidencePath = (file) => resolvePhaseEvidencePath(phase, `captures/pre-layout/${file}`, { root: repoRoot });
  const manifestBytes = fs.readFileSync(evidencePath("manifest.json"));
  const manifest = JSON.parse(manifestBytes.toString("utf8"));
  for (const [name, expected] of Object.entries(manifest.images)) {
    const bytes = fs.readFileSync(evidencePath(name));
    expect(bytes.length).toBe(expected.bytes);
    expect(sha256(bytes)).toBe(expected.sha256);
  }
  return manifest;
}

test("Phase 234 pre-layout served Admin details baseline is immutable", async ({ page, sandboxId }, testInfo) => {
  const captureMode = process.env.PHASE234_CAPTURE_BASELINE === "1";
  const destination = path.join(repoRoot, captureDestination);
  const manifestPath = path.join(destination, "manifest.json");
  const imageNames = ["customer-detail.png", "subscription-detail.png", "subscription-drawer.png"];

  if (captureMode) {
    const existing = [manifestPath, ...imageNames.map((name) => path.join(destination, name))]
      .find((candidate) => fs.existsSync(candidate));
    if (existing) throw new Error(`baseline capture is write-once; refusing existing destination: ${existing}`);
  } else {
    const manifest = await readAndVerifyBaseline();
    expect(manifest.phase).toBe(phase);
    return;
  }

  const fixture = readFixture();
  const beforeSourceSha = execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim();
  const sourceDigests = Object.fromEntries(sourcePaths.map((source) => {
    const bytes = fs.readFileSync(path.join(repoRoot, source));
    return [source, { sha256: sha256(bytes), bytes: bytes.length }];
  }));
  await login(page, fixture, fixture.admin_email, sandboxId);
  const owner = encodeURIComponent(fixture.admin_org_alpha_slug);
  let subscriptionId;
  let customerId;
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
  subscriptionId = subscriptionPath.split("?")[0].split("/").pop();
  await page.goto(subscriptionPath, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  await expect(page.getByRole("heading").first()).toBeVisible();
  const subscription = await page.screenshot({ fullPage: true });

  const customerLink = page.locator('a[href*="/admin/customers/"]').first();
  await expect(customerLink).toBeVisible();
  const customerPath = await customerLink.getAttribute("href");
  if (!customerPath) throw new Error("subscription detail did not expose its customer link");
  customerId = customerPath.split("?")[0].split("/").pop();
  await page.goto(customerPath, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);
  const customer = await page.screenshot({ fullPage: true });

  await page.goto(subscriptionPath, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  const drawerTrigger = page.getByRole("button", { name: /cancel|pause|resume|more/i }).first();
  if (await drawerTrigger.count()) await drawerTrigger.click();
  const drawer = await page.screenshot({ fullPage: true });
  const captures = [customer, subscription, drawer];
  fs.mkdirSync(destination, { recursive: true });
  const imageManifest = {};
  for (const [index, name] of imageNames.entries()) {
    const bytes = captures[index];
    fs.writeFileSync(path.join(destination, name), bytes, { flag: "wx" });
    imageManifest[name] = { sha256: sha256(bytes), bytes: bytes.length };
  }

  const servedAssetUrl = await page.locator('link[rel="stylesheet"][href*="/admin/assets/css-"]').getAttribute("href");
  if (!servedAssetUrl) throw new Error("served Admin stylesheet link was not found");
  const servedAssetResponse = await page.request.get(servedAssetUrl);
  expect(servedAssetResponse.ok()).toBeTruthy();
  const servedAsset = await servedAssetResponse.body();
  const sourceAsset = fs.readFileSync(path.join(repoRoot, "accrue_admin/priv/static/accrue_admin.css"));
  const manifest = {
    phase,
    captured_at: new Date().toISOString(),
    pre_edit_source_sha: beforeSourceSha,
    sources: sourceDigests,
    assets: {
      built: { sha256: sha256(sourceAsset), bytes: sourceAsset.length },
      served: { sha256: sha256(servedAsset), bytes: servedAsset.length, url: servedAssetUrl }
    },
    fixture: { owner: fixture.admin_org_alpha_slug, customer_id: customerId, subscription_id: subscriptionId },
    viewport: testInfo.project.use.viewport,
    theme: "default host theme",
    states: {
      "customer-detail.png": { route: `/admin/customers/${customerId}?org=${owner}`, state: "customer detail" },
      "subscription-detail.png": { route: `/admin/subscriptions/${subscriptionId}?org=${owner}`, state: "subscription detail" },
      "subscription-drawer.png": { route: `/admin/subscriptions/${subscriptionId}?org=${owner}`, state: "subscription detail action drawer if available" }
    },
    capture_command: "PHASE234_CAPTURE_BASELINE=1 npm run e2e -- e2e/phase234-pre-layout.spec.js --workers=1",
    images: imageManifest
  };
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, { flag: "wx" });
  await readAndVerifyBaseline();
});
