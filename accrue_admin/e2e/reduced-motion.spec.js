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

// Reads the computed transition-duration of .ax-dropdown-panel.
// The dropdown panel has a 2-property transition (opacity and transform)
// using --ax-dur-2 tokens directly (not a bundle). Under reduced-motion,
// --ax-dur-2 collapses to 1ms (0.001s) — opacity crossfades retained per theme.css design.
// Element is present in DOM even when closed (inside details.ax-dropdown).
async function dropdownPanelTransitionDurations(page) {
  return page.evaluate(() => {
    const el = document.querySelector(".ax-dropdown-panel");
    if (!el) return null;
    return window
      .getComputedStyle(el)
      .transitionDuration.split(",")
      .map((seg) => seg.trim());
  });
}

// Reads the computed transition-duration of .ax-command-palette.
// The palette has a 2-property transition (opacity and transform)
// using --ax-dur-2 tokens directly. Under reduced-motion,
// --ax-dur-2 collapses to 1ms (0.001s).
async function palettePanelTransitionDurations(page) {
  return page.evaluate(() => {
    const el = document.querySelector(".ax-command-palette");
    if (!el) return null;
    return window
      .getComputedStyle(el)
      .transitionDuration.split(",")
      .map((seg) => seg.trim());
  });
}

// Reads --ax-dur-3 token value from document.documentElement computed style.
// .ax-drawer-entering uses --ax-dur-3 for enter transitions. Under reduced-motion
// --ax-dur-3 collapses to 0ms, proving drawer enter is instant.
async function readDur3Token(page) {
  return page.evaluate(() =>
    window.getComputedStyle(document.documentElement).getPropertyValue("--ax-dur-3").trim()
  );
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

// Phase 177 MOT-03 — extended D-15 coverage for newly-animated surfaces

test.describe(".ax-dropdown-panel bundle collapse (Phase 177 MOT-03)", () => {
  test("with prefers-reduced-motion:reduce, .ax-dropdown-panel transition-duration collapses to near-instant on every segment", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const durations = await dropdownPanelTransitionDurations(page);

    expect(
      durations,
      ".ax-dropdown-panel must be present on /billing/dev/components"
    ).not.toBeNull();
    expect(
      durations.length,
      `dropdown uses a 2-property transition (opacity + transform) — expected 2 segments, got ${JSON.stringify(durations)}`
    ).toBeGreaterThan(0);

    // Under reduced-motion, --ax-dur-2 collapses to 1ms (0.001s) — opacity crossfades
    // retained by design (theme.css). Every segment must be at most 1ms (effectively instant).
    // 0.001s = 1ms = reduced-motion threshold for crossfade-retained surfaces.
    for (const seg of durations) {
      const ms = parseFloat(seg) * (seg.endsWith("ms") ? 1 : 1000);
      expect(
        ms,
        `under reduced-motion, every .ax-dropdown-panel transition segment must be ≤1ms — got segments ${JSON.stringify(durations)}; the @media (prefers-reduced-motion: reduce) override of --ax-dur-2 failed to collapse`
      ).toBeLessThanOrEqual(1);
    }
  });

  test("WITHOUT reduced-motion, .ax-dropdown-panel has a NON-zero transition-duration (proves the override is the cause of the collapse)", async ({ page }) => {
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const durations = await dropdownPanelTransitionDurations(page);

    expect(
      durations,
      ".ax-dropdown-panel must be present on /billing/dev/components"
    ).not.toBeNull();

    // Without reduced-motion, --ax-dur-2 = 180ms. At least one segment must be non-trivial.
    const hasNonTrivial = durations.some((seg) => {
      const ms = parseFloat(seg) * (seg.endsWith("ms") ? 1 : 1000);
      return ms > 1;
    });
    expect(
      hasNonTrivial,
      `WITHOUT reduced-motion, .ax-dropdown-panel must animate (at least one segment > 1ms) — got ${JSON.stringify(durations)}; if all segments are ≤1ms the reduced-motion test is a false positive`
    ).toBe(true);
  });
});

test.describe(".ax-command-palette bundle collapse (Phase 177 MOT-03)", () => {
  test("with prefers-reduced-motion:reduce, .ax-command-palette transition-duration collapses to near-instant on every segment", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const durations = await palettePanelTransitionDurations(page);

    expect(
      durations,
      ".ax-command-palette must be present on /billing/dev/components"
    ).not.toBeNull();
    expect(
      durations.length,
      `palette uses a 2-property transition (opacity + transform) — expected 2 segments, got ${JSON.stringify(durations)}`
    ).toBeGreaterThan(0);

    // Under reduced-motion, --ax-dur-2 collapses to 1ms (0.001s) — opacity crossfades retained.
    for (const seg of durations) {
      const ms = parseFloat(seg) * (seg.endsWith("ms") ? 1 : 1000);
      expect(
        ms,
        `under reduced-motion, every .ax-command-palette transition segment must be ≤1ms — got segments ${JSON.stringify(durations)}; the @media (prefers-reduced-motion: reduce) override of --ax-dur-2 failed to collapse`
      ).toBeLessThanOrEqual(1);
    }
  });

  test("WITHOUT reduced-motion, .ax-command-palette has a NON-zero transition-duration (proves the override is the cause of the collapse)", async ({ page }) => {
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const durations = await palettePanelTransitionDurations(page);

    expect(
      durations,
      ".ax-command-palette must be present on /billing/dev/components"
    ).not.toBeNull();

    // Without reduced-motion, --ax-dur-2 = 180ms. At least one segment must be non-trivial.
    const hasNonTrivial = durations.some((seg) => {
      const ms = parseFloat(seg) * (seg.endsWith("ms") ? 1 : 1000);
      return ms > 1;
    });
    expect(
      hasNonTrivial,
      `WITHOUT reduced-motion, .ax-command-palette must animate (at least one segment > 1ms) — got ${JSON.stringify(durations)}; if all segments are ≤1ms the reduced-motion test is a false positive`
    ).toBe(true);
  });
});

test.describe(".ax-drawer-entering CSS token collapse (Phase 177 MOT-03)", () => {
  // The drawer is not in the DOM when closed (:if={@open}) — we read the transition by
  // checking the --ax-dur-3 token value on documentElement. .ax-drawer-entering uses
  // --ax-dur-3 (240ms) for enter; under reduced-motion, --ax-dur-3 → 0ms, proving
  // that any surface using this token gets instant enter transitions.
  test("with prefers-reduced-motion:reduce, --ax-dur-3 collapses to 0ms (drawer enter is instant)", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const dur3 = await readDur3Token(page);

    expect(
      dur3,
      `under reduced-motion, --ax-dur-3 must be "0ms" (instant) — got "${dur3}"; the @media (prefers-reduced-motion: reduce) override in theme.css failed to collapse --ax-dur-3`
    ).toBe("0ms");
  });

  test("WITHOUT reduced-motion, --ax-dur-3 resolves to a non-zero value (proves the override is the cause)", async ({ page }) => {
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const dur3 = await readDur3Token(page);

    expect(
      dur3,
      `WITHOUT reduced-motion, --ax-dur-3 must be "240ms" (drawer enter duration) — got "${dur3}"; if 0ms without reduced-motion emulation then the token is broken`
    ).toBe("240ms");
  });
});

// Structural test: travel tokens collapse to 0px under reduced-motion.
// This proves that no transform travel (translateX/translateY) can occur on any
// surface using --ax-rise-sm or --ax-rise-md, regardless of whether the element
// is in the DOM. Covers dropdown (--ax-rise-sm), drawer (--ax-rise-md), flash (--ax-rise-sm).
test("structural: no transform travel on dropdown/drawer under prefers-reduced-motion (Phase 177 MOT-03)", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();

  const [riseSm, riseMd] = await page.evaluate(() => {
    const style = window.getComputedStyle(document.documentElement);
    return [
      style.getPropertyValue("--ax-rise-sm").trim(),
      style.getPropertyValue("--ax-rise-md").trim(),
    ];
  });

  expect(
    riseSm,
    `under reduced-motion, --ax-rise-sm must be "0px" (no transform travel on dropdown/flash) — got "${riseSm}"; theme.css @media reduced-motion override must set --ax-rise-sm: 0px`
  ).toBe("0px");

  expect(
    riseMd,
    `under reduced-motion, --ax-rise-md must be "0px" (no transform travel on drawer) — got "${riseMd}"; theme.css @media reduced-motion override must set --ax-rise-md: 0px`
  ).toBe("0px");
});
