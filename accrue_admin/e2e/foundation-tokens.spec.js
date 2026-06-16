const { test, expect } = require("@playwright/test");

const statusSolidTokenExamples = [
  "--ax-status-success-on-solid",
  "--ax-status-warning-on-solid",
  "--ax-status-danger-on-solid",
  "--ax-status-info-on-solid",
  "--ax-status-neutral-on-solid"
];

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}

function parseColor(value) {
  const match = value.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([0-9.]+))?\)/);
  if (!match) throw new Error(`Unsupported color: ${value}`);
  return match.slice(1, 4).map(Number);
}

function relativeLuminance(rgb) {
  const [r, g, b] = rgb.map((channel) => {
    const value = channel / 255;
    return value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrastRatio(foreground, background) {
  const [lighter, darker] = [relativeLuminance(foreground), relativeLuminance(background)].sort(
    (a, b) => b - a
  );
  return (lighter + 0.05) / (darker + 0.05);
}

function expectContrastAtLeast(foreground, background, min, label) {
  const ratio = contrastRatio(parseColor(foreground), parseColor(background));
  expect(ratio, `${label} contrast ${ratio.toFixed(2)} must be >= ${min}`).toBeGreaterThanOrEqual(min);
}

async function setTheme(page, theme) {
  await page.evaluate((nextTheme) => {
    document.documentElement.dataset.theme = nextTheme;
  }, theme);
  await page.waitForTimeout(50);
}

async function styleOf(locator, property) {
  return locator.evaluate((el, prop) => window.getComputedStyle(el)[prop], property);
}

async function rootToken(page, token) {
  return page.evaluate((name) => {
    const probe = document.createElement("span");
    probe.style.color = `var(${name})`;
    document.body.appendChild(probe);
    const color = window.getComputedStyle(probe).color;
    probe.remove();
    return color;
  }, token);
}

test.describe("foundation tokens - computed styles", () => {
  test("foundation tokens resolve and meet contrast in light and dark", async ({ page }) => {
    test.setTimeout(90_000);

    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page, "/billing/dev/components");
    await expect(page.locator("#main-content")).toBeVisible();

    const body = page.locator('[data-ax-foundation-specimen="type-body"] p').first();
    const display = page.locator('[data-ax-foundation-specimen="type-display"] p').first();
    const measure = page.locator('[data-ax-foundation-specimen="measure-prose"] p').first();
    const focus = page.locator('[data-ax-foundation-specimen="focus-control"]').first();
    const disabled = page.locator('[data-ax-foundation-specimen="disabled-control"]').first();
    const readonly = page.locator('[data-ax-foundation-specimen="readonly-control"]').first();
    const hover = page.locator('[data-ax-foundation-specimen="interactive-hover"]').first();
    const active = page.locator('[data-ax-foundation-specimen="interactive-active"]').first();
    const selected = page.locator('[data-ax-foundation-specimen="interactive-selected"]').first();
    const scrollbar = page.locator('[data-ax-foundation-specimen="scrollbar"]').first();

    for (const theme of ["light", "dark"]) {
      await setTheme(page, theme);

      expect(await styleOf(body, "fontSize")).not.toBe(await styleOf(display, "fontSize"));
      expect(await styleOf(body, "letterSpacing")).not.toBe("");
      expect(await styleOf(display, "letterSpacing")).not.toBe("");
      expect(await styleOf(measure, "maxWidth")).not.toBe("none");
      expect(await rootToken(page, "--ax-measure")).not.toBe("");

      const layerValues = { sticky: "100", dropdown: "200", popover: "300", drawer: "400", modal: "500", toast: "600" };
      for (const [layer, value] of Object.entries(layerValues)) {
        await expect(page.locator(`[data-ax-foundation-layer="${layer}"]`).first()).toHaveCSS("z-index", value);
      }

      await focus.focus();
      await expect(focus).toHaveCSS("outline-width", "2px");
      expect(await styleOf(focus, "outlineStyle")).not.toBe("none");
      expectContrastAtLeast(
        await styleOf(focus, "outlineColor"),
        await styleOf(focus, "backgroundColor"),
        3,
        `${theme} focus ring`
      );

      expectContrastAtLeast(await styleOf(disabled, "color"), await styleOf(disabled, "backgroundColor"), 3, `${theme} disabled`);
      expect(await styleOf(disabled, "cursor")).toBe("not-allowed");
      expect(Number.parseFloat(await styleOf(disabled, "opacity"))).toBeLessThanOrEqual(0.62);
      expectContrastAtLeast(await styleOf(readonly, "color"), await styleOf(readonly, "backgroundColor"), 4.5, `${theme} readonly`);

      await hover.hover();
      expect(await styleOf(hover, "backgroundColor")).toBe(await rootToken(page, "--ax-interactive-hover"));
      expectContrastAtLeast(await styleOf(hover, "color"), await styleOf(hover, "backgroundColor"), 4.5, `${theme} hover`);

      const activeBox = await active.boundingBox();
      await page.mouse.move(activeBox.x + 4, activeBox.y + 4);
      await page.mouse.down();
      expect(await styleOf(active, "backgroundColor")).toBe(await rootToken(page, "--ax-interactive-active"));
      expectContrastAtLeast(await styleOf(active, "color"), await styleOf(active, "backgroundColor"), 4.5, `${theme} active`);
      await page.mouse.up();

      expect(await styleOf(selected, "backgroundColor")).toBe(await rootToken(page, "--ax-interactive-selected"));
      expectContrastAtLeast(await styleOf(selected, "color"), await styleOf(selected, "backgroundColor"), 4.5, `${theme} selected`);

      const thumb = await rootToken(page, "--ax-scrollbar-thumb");
      const track = await rootToken(page, "--ax-scrollbar-track");
      const thumbHover = await rootToken(page, "--ax-scrollbar-thumb-hover");
      expect(thumb).not.toBe("");
      expect(track).not.toBe("");
      expect(thumbHover).not.toBe("");
      expect(await styleOf(scrollbar, "overflowY")).toMatch(/auto|scroll/);
      expectContrastAtLeast(thumb, track, 3, `${theme} scrollbar`);

      for (const status of ["success", "warning", "danger", "info", "neutral"]) {
        const specimen = page.locator(`[data-ax-foundation-status="${status}"]`).first();
        expectContrastAtLeast(
          await styleOf(specimen, "color"),
          await styleOf(specimen, "backgroundColor"),
          4.5,
          `${theme} ${status} status`
        );
        expectContrastAtLeast(
          await rootToken(page, `--ax-status-${status}-on-solid`),
          await rootToken(page, `--ax-status-${status}-solid`),
          4.5,
          `${theme} ${status} solid`
        );
      }
    }
  });
});
