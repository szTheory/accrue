const { test, expect } = require("@playwright/test");

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}

test.describe("Kitchen banner — danger token cascade (computed style)", () => {
  test("ax-banner-danger paints non-transparent background and token-driven text color in both themes", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const banner = page.locator("[data-ax-kitchen-banner='danger']");
    await expect(banner).toBeVisible();

    const colors = {};
    for (const theme of ["light", "dark"]) {
      await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
      // Wait for settled state (transitions are zeroed by reduced-motion).
      await page.waitForTimeout(50);

      const bg = await page.evaluate(
        (el) => window.getComputedStyle(el).backgroundColor,
        await banner.elementHandle()
      );
      const color = await page.evaluate(
        (el) => window.getComputedStyle(el).color,
        await banner.elementHandle()
      );
      colors[theme] = { bg, color };
    }

    // Surface token resolved and painted — not transparent (0,0,0,0) in either theme.
    expect(
      colors.light.bg,
      `[light] ax-banner-danger background must not be transparent — got ${colors.light.bg}`
    ).not.toBe("rgba(0, 0, 0, 0)");
    expect(
      colors.dark.bg,
      `[dark] ax-banner-danger background must not be transparent — got ${colors.dark.bg}`
    ).not.toBe("rgba(0, 0, 0, 0)");

    // --ax-danger-readable differs light (#9b1c1c) vs dark (#ffaaaa) — if the token
    // cascade drives the painted text color, the two values will differ.
    expect(
      colors.light.color,
      `ax-banner-danger text color must differ between light and dark themes — both are ${colors.light.color} — this means the token cascade is not driving the painted color`
    ).not.toBe(colors.dark.color);
  });
});
