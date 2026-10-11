// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

const repoRoot = path.resolve(__dirname, "../../..");
const orgQuery = (fixture) => `org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function seedCustomerUpdatedEvent(fixture) {
  const customerId = fixture.admin_denial_customer_id;
  const script = `
    alias Accrue.Events.Event
    alias Accrue.Repo
    event = Repo.insert!(%Event{
      type: "customer.updated",
      schema_version: 1,
      actor_type: "admin",
      actor_id: "phase244-browser",
      subject_type: "Customer",
      subject_id: "${customerId}",
      data: %{},
      inserted_at: ~U[2026-10-10 23:59:59.123456Z]
    })
    IO.write(event.id)
  `;
  const output = execFileSync("mix", ["run", "-e", script], {
    cwd: path.join(repoRoot, "examples/accrue_host"),
    encoding: "utf8",
    env: { ...process.env, MIX_ENV: "test" }
  }).trim();
  return output.split(/\s+/).at(-1);
}

async function captureAdminAssets(page) {
  const entries = [
    ["css", 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin/priv/static/accrue_admin.css"],
    ["js", 'script[src*="/admin/assets/js-"]', "accrue_admin/priv/static/accrue_admin.js"]
  ];
  const rows = [];

  for (const [kind, selector, packagePath] of entries) {
    const href = await page.locator(selector).getAttribute(kind === "css" ? "href" : "src");
    expect(href).toMatch(new RegExp(`/admin/assets/${kind}-[a-f0-9]{32}$`));
    const response = await page.request.get(href);
    expect(response.status()).toBe(200);
    const served = await response.body();
    const packageBytes = fs.readFileSync(path.join(repoRoot, packagePath));
    const compiledPath = path.join(
      process.env.MIX_BUILD_PATH,
      "lib/accrue_admin/priv",
      packagePath.replace("accrue_admin/priv/", "")
    );
    const compiledBytes = fs.readFileSync(compiledPath);
    expect(sha256(served)).toBe(sha256(packageBytes));
    expect(sha256(compiledBytes)).toBe(sha256(packageBytes));
    rows.push({ kind, url: new URL(href, page.url()).href, sha256: sha256(served), bytes: served.length });
  }
  return rows;
}

test("Phase 244 customer update retains exact scoped event evidence @phase244-desktop", async ({ page, sandboxId }, testInfo) => {
  const fixture = readFixture();
  const eventId = seedCustomerUpdatedEvent(fixture);
  expect(eventId).toMatch(/^\d+$/);

  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.goto("/app/billing");
  await waitForLiveView(page);
  await page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`).click();
  await waitForLiveView(page);
  await page.goto(`/admin?${orgQuery(fixture)}`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  const eventRow = page.locator(".ax-timeline-item").filter({ hasText: "Customer updated" });
  await expect(eventRow).toBeVisible();
  await expect(eventRow).toContainText(fixture.admin_denial_customer_id);
  const eventLink = eventRow.getByRole("link", { name: "Open event" });
  await expect(eventLink).toHaveAttribute("href", new RegExp(`/admin/events/${eventId}\\?org=`));
  await eventLink.click();
  await waitForLiveView(page);
  await expect(page).toHaveURL(new RegExp(`/admin/events/${eventId}\\?org=`));
  await expect(page.getByText("customer.updated", { exact: true }).first()).toBeVisible();
  await expect(page.getByText(fixture.admin_denial_customer_id, { exact: true }).first()).toBeVisible();
  await expect(page.getByText("2026-10-10T23:59:59.123456Z", { exact: true }).first()).toBeVisible();

  const assets = await captureAdminAssets(page);
  const evidence = {
    checkoutHead: execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim(),
    fixture: "disposable HOST-BROWSER-VERIFY01 fixture; scoped customer.updated event",
    route: page.url(),
    viewport: page.viewportSize(),
    theme: await page.locator("html").getAttribute("data-theme"),
    assets
  };
  console.log(`[phase244-asset-evidence] ${JSON.stringify(evidence)}`);
  await testInfo.attach("phase244-asset-evidence.json", {
    body: Buffer.from(JSON.stringify(evidence, null, 2)),
    contentType: "application/json"
  });
});
