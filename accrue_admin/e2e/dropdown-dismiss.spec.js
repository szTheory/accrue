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

    // Open the native disclosure. The component-kitchen renders an always-open,
    // focus-trapped drawer specimen (DetailDrawer phx-hook="FocusTrap") that grabs
    // focus page-wide and auto-scrolls to itself; that churn makes a synthesized
    // pointer click on this summary land on the wrong element. Dispatch the click
    // on the summary directly to exercise the native <details> toggle reliably —
    // the behaviour under test is the outside-click dismissal below, not the open.
    await dropdown.locator("summary").dispatchEvent("click");
    expect(await dropdown.evaluate((el) => el.open)).toBe(true);

    // Closes when a real click lands outside the dropdown (least-surprise). The
    // document-level dismissal hook (initDropdowns) closes any open ax-dropdown on
    // outside-click; the top-left corner is reliably outside this dropdown.
    await page.mouse.click(5, 5);
    expect(await dropdown.evaluate((el) => el.open)).toBe(false);
  });
});
