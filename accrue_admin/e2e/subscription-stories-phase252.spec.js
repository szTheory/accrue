const fs = require("fs");
const path = require("path");
const { test, expect } = require("@playwright/test");

const RESULT_PATH = path.join(__dirname, "..", "tmp", "phase252", "render-results.json");
const ACTIVE_URL = "/billing/dev/storybook/components/subscription_detail?variation_id=active";

test.describe("Phase 252 direct subscription story renders", () => {
  test("active at 320px in light theme renders the actual subscription facts", async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 900 });
    await page.goto(`/__e2e__/login?to=${encodeURIComponent(ACTIVE_URL)}`);

    const story = page.locator(".psb-sandbox").first();
    await expect(story, "the direct Storybook variation should render").toBeVisible();
    await expect(story).toContainText("Acme Research");
    await expect(story).toContainText("Active");
    await expect(page).toHaveURL(/variation_id=active/);
  });

  test("generated render ledger contains this direct variation", async () => {
    const rows = fs.existsSync(RESULT_PATH)
      ? JSON.parse(fs.readFileSync(RESULT_PATH, "utf8")).cases
      : [];

    expect(
      rows,
      "every direct render must produce an attributed browser evidence row"
    ).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          key: "/components/subscription_detail||active::320::light",
          status: "passed",
        }),
      ])
    );
  });
});
