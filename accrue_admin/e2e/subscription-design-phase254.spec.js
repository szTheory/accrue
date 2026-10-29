// Phase 254 UXQ-04 / D-35: computed-style and source tests for the reviewed design corrections.
//
// Every test title starts with a key `<finding_id>:<kind>` (kind `computed` or `source`) that the
// red-evidence tooling parses from the Playwright JSON report (verify_phase254_design_review.mjs
// --record-red). Computed values are compared as exact resolved px strings from getComputedStyle: the
// token side is never hard-coded, it is resolved by the browser through a probe element that reads the
// very custom property the corrected rule must use. Readiness waits use locator.waitFor (a setup
// problem is not an assertion failure and must never be mistaken for red); the design assertions use
// expect() with the finding id in the message.
//
// Owner: the Phase 252 lab (playwright.phase252.config.js, project phase254-design). The pages read are
// the compiled Storybook story routes, which render the production components with the production
// stylesheet recomposed into storybook.css; DR-254-02:source reads the served accrue_admin.css itself.

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { test, expect } = require("@playwright/test");

const ADMIN_ROOT = path.resolve(__dirname, "..");
const COLLECTION_ROUTE = "/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=multiple_rows";
const PAGE_ROUTE = "/billing/dev/storybook/pages/subscription?tab=active";

const THEMES = ["light", "dark"];

async function openStory(page, route, width, theme) {
  await page.setViewportSize({ width, height: 900 });
  await page.emulateMedia({ colorScheme: theme });
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(route)}`);
  const sandbox = page.locator(".psb-sandbox").first();
  await sandbox.waitFor({ state: "visible" });
  await sandbox.evaluate((element, selected) => {
    element.classList.add("accrue-admin");
    element.classList.toggle("ax-theme-dark-shim", selected === "dark");
  }, theme);
  await page.evaluate(async () => {
    if (document.fonts?.ready) await document.fonts.ready;
  });
  return sandbox;
}

// Resolve CSS declarations through the browser: a probe element inside the sandbox (so the Accrue
// custom properties are in scope) receives the declarations through the CSSOM and its computed values
// are returned. The probe is removed afterwards.
async function resolve(page, declarations, read) {
  return page.evaluate(
    ({ declarations: pairs, read: properties }) => {
      const host = document.querySelector(".psb-sandbox");
      const probe = document.createElement("div");
      for (const [property, value] of Object.entries(pairs)) probe.style.setProperty(property, value);
      host.appendChild(probe);
      const computed = getComputedStyle(probe);
      const out = Object.fromEntries(properties.map((property) => [property, computed.getPropertyValue(property)]));
      probe.remove();
      return out;
    },
    { declarations, read },
  );
}

async function computedOf(page, selector, properties) {
  const rows = await page.evaluate(
    ({ selector: query, properties: names }) =>
      [...document.querySelectorAll(query)].map((element) => {
        const computed = getComputedStyle(element);
        return Object.fromEntries(names.map((name) => [name, computed.getPropertyValue(name)]));
      }),
    { selector, properties },
  );
  expect(rows.length, `the story renders at least one ${selector}`).toBeGreaterThan(0);
  return rows;
}

// DR-254-01 (page tier): the page-tier 1px / 3px / 0 gap overrides are gone, so the stacks and field
// lists resolve the component-tier spacing tokens.
for (const width of [320, 1280]) {
  for (const theme of THEMES) {
    test(`DR-254-01:computed detail stacks and field lists use component spacing tokens at ${width}px ${theme}`, async ({ page }) => {
      await openStory(page, PAGE_ROUTE, width, theme);
      await page.locator(".ax-subscription-detail-page").first().waitFor({ state: "visible" });
      const md = await resolve(page, { display: "grid", "row-gap": "var(--ax-space-md)", "column-gap": "var(--ax-space-md)" }, ["row-gap", "column-gap"]);
      const xs = await resolve(page, { display: "grid", "row-gap": "var(--ax-space-xs)", "column-gap": "var(--ax-space-xs)" }, ["row-gap", "column-gap"]);

      const mdStacks = await computedOf(page, ".ax-subscription-detail-page .ax-stack-md", ["row-gap", "column-gap"]);
      for (const row of mdStacks) expect(row["row-gap"], "DR-254-01 .ax-stack-md rowGap is --ax-space-md").toBe(md["row-gap"]);

      const smStacks = await computedOf(page, ".ax-subscription-detail-page .ax-stack-sm", ["row-gap", "column-gap"]);
      for (const row of smStacks) expect(row["row-gap"], "DR-254-01 .ax-stack-sm rowGap is the global .ax-stack-sm value (--ax-space-md)").toBe(md["row-gap"]);

      const lists = await computedOf(page, ".ax-subscription-detail-page .ax-field-list", ["row-gap"]);
      for (const row of lists) expect(row["row-gap"], "DR-254-01 .ax-field-list rowGap is --ax-space-xs").toBe(xs["row-gap"]);

      const fields = await computedOf(page, ".ax-subscription-detail-page .ax-field", ["row-gap", "column-gap"]);
      for (const row of fields) {
        expect(row["row-gap"], "DR-254-01 .ax-field rowGap is --ax-space-xs").toBe(xs["row-gap"]);
        expect(row["column-gap"], "DR-254-01 .ax-field columnGap is --ax-space-xs").toBe(xs["column-gap"]);
      }
    });
  }
}

// DR-254-03 (component tier): detail field labels equal the summary keys at --ax-type-xs; form labels
// and the numeric figures of the values are unchanged.
for (const width of [320, 1280]) {
  for (const theme of THEMES) {
    test(`DR-254-03:computed detail field labels equal summary keys, form labels and value figures are unchanged at ${width}px ${theme}`, async ({ page }) => {
      await openStory(page, PAGE_ROUTE, width, theme);
      await page.locator(".ax-subscription-detail-page").first().waitFor({ state: "visible" });
      const label = await resolve(page, { font: "var(--ax-type-label-sm-font)" }, ["font-size", "font-weight", "line-height"]);
      const formLabel = await resolve(page, { "font-size": "var(--ax-type-sm)", "font-weight": "600" }, ["font-size", "font-weight"]);

      const keys = await computedOf(page, ".ax-summary-list-key", ["font-size", "font-weight", "line-height"]);
      for (const row of keys) expect(row["font-size"], "DR-254-03 summary keys render at --ax-type-xs").toBe(label["font-size"]);

      const labels = await computedOf(page, ".ax-subscription-detail-page .ax-field-list .ax-field-label", ["font-size", "font-weight", "line-height"]);
      for (const row of labels) {
        expect(row["font-size"], "DR-254-03 detail field labels equal the summary keys (--ax-type-xs)").toBe(label["font-size"]);
        expect(row["font-weight"], "DR-254-03 detail field label weight").toBe(label["font-weight"]);
        expect(row["line-height"], "DR-254-03 detail field label line-height stays --ax-leading-normal").toBe(label["line-height"]);
      }

      // A bare .ax-field-label (the form label) keeps --ax-type-sm: the six form controls share the rule.
      const formSample = await page.evaluate(() => {
        const host = document.querySelector(".psb-sandbox");
        const wrapper = document.createElement("div");
        wrapper.className = "ax-field";
        const element = document.createElement("label");
        element.className = "ax-field-label";
        wrapper.appendChild(element);
        host.appendChild(wrapper);
        const computed = getComputedStyle(element);
        const out = { size: computed.fontSize, weight: computed.fontWeight };
        wrapper.remove();
        return out;
      });
      expect(formSample.size, "DR-254-03 a form .ax-field-label keeps --ax-type-sm").toBe(formLabel["font-size"]);
      expect(formSample.weight, "DR-254-03 a form .ax-field-label keeps its weight").toBe(formLabel["font-weight"]);

      const values = await computedOf(page, ".ax-subscription-detail-page .ax-field-value", ["font-variant-numeric"]);
      for (const row of values) expect(row["font-variant-numeric"], "DR-254-03 .ax-field-value keeps tabular figures").toContain("tabular-nums");
    });
  }
}

// DR-254-02 (contract amendment): the shared display rule is already responsive; it is asserted at the
// 767 / 768 CSS px boundary and stays identical before and after the token swap (zero visual change).
for (const width of [767, 768]) {
  for (const theme of THEMES) {
    test(`DR-254-02:computed collection heading is ${width === 767 ? "--ax-type-xl" : "--ax-type-2xl"} at ${width}px ${theme}`, async ({ page }) => {
      await openStory(page, COLLECTION_ROUTE, width, theme);
      expect(await page.evaluate(() => window.innerWidth), "the viewport is exactly the boundary width").toBe(width);
      const token = width === 767 ? "--ax-type-xl" : "--ax-type-2xl";
      const expected = await resolve(page, { "font-size": `var(${token})` }, ["font-size"]);
      const headings = await computedOf(page, "h1.ax-display", ["font-size", "font-weight"]);
      for (const row of headings) expect(row["font-size"], `DR-254-02 the heading is ${token} at ${width}px`).toBe(expected["font-size"]);
    });
  }
}

// DR-254-02:source - red-able on the pre-fix rem literals. The served accrue_admin.css is fetched from
// the admin mount (the md5 route the design record pins), loaded into a constructed stylesheet and
// walked through the CSSOM: the declared font-size of the base display rule and of its min-width 768px
// media rule must be the type tokens, not literals.
test("DR-254-02:source declared display font-size is var(--ax-type-xl) and var(--ax-type-2xl) in the served accrue_admin.css", async ({ page }) => {
  await openStory(page, COLLECTION_ROUTE, 1280, "light");
  const css = fs.readFileSync(path.join(ADMIN_ROOT, "priv/static/accrue_admin.css"));
  const route = `/billing/assets/css-${crypto.createHash("md5").update(css).digest("hex")}`;
  const response = await page.request.get(route);
  if (!response.ok()) throw new Error(`the served accrue_admin.css was not found at ${route} (HTTP ${response.status()})`);
  const served = await response.text();
  if (crypto.createHash("sha256").update(served).digest("hex") !== crypto.createHash("sha256").update(css).digest("hex")) {
    throw new Error("the served accrue_admin.css differs from priv/static/accrue_admin.css");
  }
  const declared = await page.evaluate((text) => {
    const sheet = new CSSStyleSheet();
    sheet.replaceSync(text);
    const base = [];
    const wide = [];
    const visit = (rules, media) => {
      for (const rule of rules) {
        if (rule.type === CSSRule.STYLE_RULE) {
          const selectors = rule.selectorText.split(",").map((selector) => selector.trim());
          const size = rule.style.getPropertyValue("font-size");
          if (selectors.includes(".ax-display") && size) (media === "wide" ? wide : base).push(size);
        } else if (rule.cssRules) {
          visit(rule.cssRules, rule.media && /min-width:\s*768px/.test(rule.media.mediaText) ? "wide" : media);
        }
      }
    };
    visit(sheet.cssRules, "base");
    return { base, wide };
  }, served);
  expect(declared.base.length, "DR-254-02 the base .ax-display rule with a font-size is found").toBeGreaterThan(0);
  expect(declared.wide.length, "DR-254-02 the min-width 768px .ax-display rule with a font-size is found").toBeGreaterThan(0);
  // Joined strings keep the report's Expected and Received lines as plain values.
  expect(declared.base.join(" | "), "DR-254-02 base display font-size is declared with the type token").toBe(declared.base.map(() => "var(--ax-type-xl)").join(" | "));
  expect(declared.wide.join(" | "), "DR-254-02 wide display font-size is declared with the type token").toBe(declared.wide.map(() => "var(--ax-type-2xl)").join(" | "));
});
