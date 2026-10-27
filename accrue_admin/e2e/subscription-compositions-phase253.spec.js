const fs = require("node:fs");
const path = require("node:path");
const { test, expect } = require("@playwright/test");

const repoRoot = path.resolve(__dirname, "../..");
const manifestPath = path.join(repoRoot, "accrue_admin/tmp/phase253/manifest.json");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const entries = manifest.entries.filter(
  (entry) => entry.story_path === "/groups/subscriptions_collection" && entry.variation_id === "one_row",
);

if (manifest.schema_version !== 1 || entries.length !== 1) {
  throw new Error("Phase 253 manifest must declare exactly one compiled one_row collection composition");
}

const [entry] = entries;

test("compiled one_row subscription collection renders real production content and DataTable state", async ({ page }) => {
  const directPath = entry.direct_path;
  expect(directPath).toMatch(/^\/billing\/dev\/storybook\/groups\/subscriptions_collection\?/);

  await page.goto(`/__e2e__/login?to=${encodeURIComponent(directPath)}`);
  await expect.poll(() => {
    const current = new URL(page.url());
    return `${current.pathname}${current.search}`;
  }).toBe(directPath);

  const previewId = `${entry.variation_id.replaceAll("_", "-")}-component`;
  const preview = page.locator(`#${previewId}`);
  await expect(preview, "the generated collection variation is directly reachable").toBeVisible();

  const story = preview.locator(".psb-sandbox").first();
  await expect(story, "Storybook mounts the connected production collection").toBeVisible();
  await expect(story.locator('[data-storybook-subscription-collection="launch"]')).toBeVisible();
  await expect(story.locator("[data-ax-page-header]")).toBeVisible();
  await expect(story.locator("[data-ax-page-title]")).toHaveText("Subscriptions");
  await expect(story.locator("[data-ax-page-filter-toolbar]")).toBeVisible();
  await expect(story.getByLabel("Search subscriptions")).toBeVisible();

  const dataTable = story.locator('[data-role="data-table"][data-ax-list="subscriptions"]');
  await expect(dataTable).toHaveAttribute("data-ax-state", "populated");

  const rows = dataTable.locator("tbody > tr[data-row-id]");
  await expect.poll(() => rows.count()).toBeGreaterThan(0);

  const firstRow = rows.first();
  await expect(firstRow).toHaveAttribute("data-row-id", entry.expected.subscription_id);
  const subscriptionLink = firstRow.locator(
    `a[href^="/billing/subscriptions/${entry.expected.subscription_id}"]`,
  );
  await expect(subscriptionLink).toHaveAttribute(
    "href",
    new RegExp(`^/billing/subscriptions/${entry.expected.subscription_id}(?:\\?|$)`),
  );
  await expect(subscriptionLink).toHaveText(entry.expected.customer_name);
  await expect(firstRow.locator("td").nth(0)).toContainText(entry.expected.processor_id);
  await expect(firstRow.locator("td").nth(1)).toContainText("Active");
  await expect(firstRow.locator("td").nth(2)).toContainText(entry.expected.plan_price_id);
  await expect(firstRow.locator("td").nth(2)).toContainText("Amount unavailable");

  await expect(dataTable.locator("[data-pagination-target]")).toHaveAttribute(
    "data-pagination-target",
    /^\d+$/,
  );
});
