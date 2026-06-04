const { test, expect } = require("@playwright/test");

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}

// Reads the computed transition-duration of the first .ax-button on the page.
// .ax-button { transition: var(--ax-transition-base); } at app.css:1000.
// --ax-transition-base is a 5-property bundle, so transitionDuration computes
// to a 5-segment comma list (one per property). We split on commas and trim.
async function buttonTransitionDurations(page) {
  await expect(page.locator(".ax-button").first()).toBeVisible();
  return page.evaluate(() => {
    const el = document.querySelector(".ax-button");
    if (!el) return null;
    return window
      .getComputedStyle(el)
      .transitionDuration.split(",")
      .map((seg) => seg.trim());
  });
}

test.describe("Reduced motion — bundle override collapses transitions to instant (D-15)", () => {
  test("with prefers-reduced-motion:reduce, .ax-button transition-duration collapses to 0s on every segment", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const durations = await buttonTransitionDurations(page);

    expect(durations, ".ax-button must be present on /billing/dev/components").not.toBeNull();
    expect(
      durations.length,
      `--ax-transition-base is a multi-property bundle — expected a comma-list of durations, got ${JSON.stringify(durations)}`
    ).toBeGreaterThan(0);

    // Every comma-segment of the shorthand must resolve to instant (0s) under the
    // reduced-motion bundle override (theme.css:206 → var(--ax-dur-instant: 0ms)).
    for (const seg of durations) {
      expect(
        seg,
        `under reduced-motion, every .ax-button transition segment must be "0s" (instant) — got segments ${JSON.stringify(durations)}; the @media (prefers-reduced-motion: reduce) override of --ax-transition-base failed to collapse to --ax-dur-instant`
      ).toBe("0s");
    }
  });

  test("WITHOUT reduced-motion the same .ax-button has a NON-zero transition-duration (proves the override is the cause of the collapse)", async ({ page }) => {
    // No emulateMedia → media defaults (no reduced-motion). This guards against a
    // false-positive where .ax-button simply has no transition at all.
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const durations = await buttonTransitionDurations(page);

    expect(durations, ".ax-button must be present on /billing/dev/components").not.toBeNull();

    // At least one segment must be non-zero — the base bundle uses --ax-dur-2 (180ms).
    const hasNonZero = durations.some((seg) => seg !== "0s");
    expect(
      hasNonZero,
      `WITHOUT reduced-motion, .ax-button must animate (at least one non-zero transition segment) — got ${JSON.stringify(durations)}; if all segments are 0s the reduced-motion test is a false positive (the element never had a transition to collapse)`
    ).toBe(true);
  });
});
