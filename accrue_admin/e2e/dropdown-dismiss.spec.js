const { test, expect } = require("@playwright/test");

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}

test.describe("Dropdown menu — outside-click dismissal", () => {
  test("native ax-dropdown closes when clicking off it", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const dropdown = page
      .locator("details.ax-dropdown")
      .filter({ hasText: "More actions" })
      .first();
    await expect(dropdown).toBeVisible();

    // Opens on summary click (native disclosure).
    await dropdown.locator("summary").click();
    expect(await dropdown.evaluate((el) => el.open)).toBe(true);

    // Closes when clicking an element outside the dropdown (least-surprise).
    await page.getByText("Status badges").first().click();
    expect(await dropdown.evaluate((el) => el.open)).toBe(false);
  });
});
