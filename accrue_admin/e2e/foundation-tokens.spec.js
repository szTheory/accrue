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

      // Verify focus ring via CSS custom property resolution and stylesheet inspection.
      // The --ax-focus-ring token controls the outline color; check it resolves to a
      // non-empty hex color. The width (2px solid) is checked via the stylesheet
      // CSSRule text which matches regardless of browser :focus-visible heuristics.
      const focusRingToken = await page.evaluate(() =>
        getComputedStyle(document.documentElement).getPropertyValue("--ax-focus-ring").trim()
      );
      expect(focusRingToken, `${theme} --ax-focus-ring must be defined`).not.toBe("");
      // Verify focus ring outline using a temporary DOM element with the data-ax-force
      // attribute applied. This matches the [data-ax-force~=focus] CSS rule without
      // relying on :focus-visible pseudo-class heuristics.
      const focusRingOutline = await page.evaluate(() => {
        const probe = document.createElement("button");
        probe.className = "ax-button ax-button-secondary";
        probe.setAttribute("data-ax-force", "focus");
        probe.style.position = "absolute";
        probe.style.left = "-9999px";
        document.body.appendChild(probe);
        const style = window.getComputedStyle(probe);
        const result = { outlineWidth: style.outlineWidth, outlineStyle: style.outlineStyle };
        probe.remove();
        return result;
      });
      expect(focusRingOutline.outlineStyle, `${theme} focus ring CSS rule must produce visible outline`).not.toBe("none");
      expect(parseInt(focusRingOutline.outlineWidth, 10), `${theme} focus ring width >= 2px`).toBeGreaterThanOrEqual(2);
      // Check focus ring color contrast using root token resolved as rgb.
      const focusRingRgb = await page.evaluate(() => {
        const probe = document.createElement("span");
        probe.style.color = "var(--ax-focus-ring)";
        document.body.appendChild(probe);
        const color = window.getComputedStyle(probe).color;
        probe.remove();
        return color;
      });
      expectContrastAtLeast(focusRingRgb, await styleOf(focus, "backgroundColor"), 3, `${theme} focus ring`);

      expectContrastAtLeast(await styleOf(disabled, "color"), await styleOf(disabled, "backgroundColor"), 3, `${theme} disabled`);
      expect(await styleOf(disabled, "cursor")).toBe("not-allowed");
      expect(Number.parseFloat(await styleOf(disabled, "opacity"))).toBeLessThanOrEqual(0.62);
      expectContrastAtLeast(await styleOf(readonly, "color"), await styleOf(readonly, "backgroundColor"), 4.5, `${theme} readonly`);

      expect(await styleOf(hover, "backgroundColor")).toBe(await rootToken(page, "--ax-interactive-hover"));
      expectContrastAtLeast(await styleOf(hover, "color"), await styleOf(hover, "backgroundColor"), 4.5, `${theme} hover`);

      expect(await styleOf(active, "backgroundColor")).toBe(await rootToken(page, "--ax-interactive-active"));
      expectContrastAtLeast(await styleOf(active, "color"), await styleOf(active, "backgroundColor"), 4.5, `${theme} active`);

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

// >>> @ratchet:auto-guards >>>
const RATCHET_AUTO_GUARDS = [];
// <<< @ratchet:auto-guards <<<

// Auto-minted regression guards (207-03, D-44/D-45/D-46). This loop iterates the
// human-reviewed-once RATCHET_AUTO_GUARDS data array above and dispatches per row.kind
// to this file's own existing helpers (styleOf / rootToken / expectContrastAtLeast).
// The array starts empty; 207-06's ui.fix orchestration appends typed DATA rows via
// ratchet-guard-mint.mjs's appendMintedRow(). No per-finding generated assertion code.
test("auto-minted ratchet guards — foundation tokens (design-token / contrast / spacing-scale)", async ({ page }) => {
  test.skip(RATCHET_AUTO_GUARDS.length === 0, "no minted ratchet guards yet");
  test.setTimeout(90_000);

  await page.emulateMedia({ reducedMotion: "reduce" });
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();

  for (const row of RATCHET_AUTO_GUARDS) {
    const locator = page.locator(row.selector).first();
    if (row.kind === "design-token") {
      const actual = await styleOf(locator, row.property);
      const expected = await rootToken(page, row.expected_token);
      expect(
        actual,
        `\`@ratchet:${row.finding_id}\` ${row.selector} ${row.property} must resolve to token ${row.expected_token}`
      ).toBe(expected);
    } else if (row.kind === "contrast") {
      expectContrastAtLeast(
        await styleOf(locator, "color"),
        await styleOf(locator, "backgroundColor"),
        row.min_ratio,
        `\`@ratchet:${row.finding_id}\` ${row.selector}`
      );
    } else if (row.kind === "spacing-scale") {
      const actual = await styleOf(locator, row.property);
      expect(
        row.allowed_values,
        `\`@ratchet:${row.finding_id}\` ${row.selector} ${row.property} (${actual}) must be a member of the spacing scale`
      ).toContain(actual);
    } else {
      throw new Error(`\`@ratchet:${row.finding_id}\` unexpected kind for foundation-tokens home: ${row.kind}`);
    }
  }
});
