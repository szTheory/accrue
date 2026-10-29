const { test, expect } = require("@playwright/test");
const {
  reset,
  seed,
  login,
  hideCaptureOnlyChrome
} = require("./support/admin-visual-helpers");
const TIMESTAMP_RE = /\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},\s+\d{4}(?:,?\s+\d{1,2}:\d{2}(?::\d{2})?(?:\s+[AP]M)?(?:\s+UTC)?)?|\b\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}(?::\d{2})?(Z| UTC)?)?\b/;

// Phase 211 deterministic visual-regression gate.
//
// This spec replaces the two human-only visual UAT checkpoints (211-02 D4,
// 211-04 D5) with Playwright's native `toHaveScreenshot` pixel-diff against
// committed Linux baselines. No LLM, no API key, no human on the path.
//
// Desktop-only: baselines are OS/font-stack specific and are minted on Linux CI
// only. The mobile project is skipped so we never bake a second baseline set.
//
// Non-determinism strategy: fixtures render ABSOLUTE datetimes (DB auto-timestamps
// / DateTime.utc_now() offsets), not relative "X ago" strings. Rather than freeze
// the clock (which would require rewriting the shared test/support/e2e_fixtures.ex),
// we mask the datetime-bearing regions per surface with `maskColor: "#FF00FF"`.

test.use({ reducedMotion: "reduce" });

// Per-surface semantic anchors identify only text that is expected to contain
// volatile absolute timestamps. The actual timestamp substring is wrapped and
// masked so labels, money, identity, state and action copy remain visible.
function timestampAnchors(page, name) {
  switch (name) {
    case "dashboard":
      // The selected dashboard fixture seeds an audit event, so the current Home
      // timeline must render a volatile timestamp for this capture. Since 247-03
      // timeline instants render through the shared Timestamp control, whose
      // TimeDisplay hook writes the browser-zone text into its <time>.
      return [page.locator(".ax-timeline [data-time-display] time").filter({ hasText: TIMESTAMP_RE })];
    case "subscriptions":
      // The time value is only volatile under the table explicitly labelled
      // "Renews / ends"; other cells carry identity, money and state.
      return [
        page
          .locator("table")
          .filter({ has: page.getByRole("columnheader", { name: "Renews / ends" }) })
          .locator("tbody tr td")
          .filter({ hasText: TIMESTAMP_RE })
      ];
    case "subscription-detail":
      return [
        // "Activity audit log" section — all three render `subscription.inserted_at`
        // (seed-time now(), drifts every run). The selected fixture mounts this
        // audit summary even when there are no loaded timeline events; detail
        // overview dates are intentionally static unavailable copy for this record.
        page
          .locator(".ax-audit-summary-row span")
          .filter({ hasText: "Timestamp" })
          .locator("em"),
        // Audit-list data-row <time> cells, excluding its static header row.
        page
          .locator(".ax-audit-list .ax-audit-row:not(.ax-audit-row-head) time")
          .filter({ hasText: TIMESTAMP_RE })
      ];
    case "component-kitchen":
    case "invoices":
    case "invoice-detail":
      // The selected invoice fixtures have no due/finalized boundary (the Due date column renders
      // its static unavailable copy rather than a date), and invoice detail leaves its lazy
      // activity section closed; no volatile value is shown.
      return [];
    default:
      return [];
  }
}

async function maskLocators(page, name) {
  const anchors = timestampAnchors(page, name);
  let wrapped = 0;
  let renderedAnchors = 0;
  for (const anchor of anchors) {
    const anchorCount = await anchor.count();
    expect(anchorCount, `${name}: rendered timestamp anchor`).toBeGreaterThan(0);
    if (anchorCount === 0) continue;
    renderedAnchors += anchorCount;
    const sourceText = await anchor.evaluateAll((elements) => elements.map((element) => element.textContent));
    const counts = await anchor.evaluateAll((elements) => elements.map((element) => {
      const pattern = /\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},\s+\d{4}(?:,?\s+\d{1,2}:\d{2}(?::\d{2})?(?:\s+[AP]M)?(?:\s+UTC)?)?|\b\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}(?::\d{2})?(?:Z| UTC)?)?\b/g;
      const existingMasks = element.querySelectorAll("[data-ax-visual-timestamp-mask]");
      if (existingMasks.length > 0) {
        return Array.from(existingMasks).filter((mask) => {
          pattern.lastIndex = 0;
          return pattern.test(mask.textContent || "");
        }).length;
      }
      const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT);
      const nodes = [];
      while (walker.nextNode()) {
        pattern.lastIndex = 0;
        if (pattern.test(walker.currentNode.nodeValue || "")) nodes.push(walker.currentNode);
      }
      for (const node of nodes) {
        pattern.lastIndex = 0;
        const text = node.nodeValue || "";
        const fragment = document.createDocumentFragment();
        let cursor = 0;
        for (const match of text.matchAll(pattern)) {
          fragment.append(document.createTextNode(text.slice(cursor, match.index)));
          const span = document.createElement("span");
          span.setAttribute("data-ax-visual-timestamp-mask", "true");
          span.textContent = match[0];
          fragment.append(span);
          cursor = match.index + match[0].length;
        }
        fragment.append(document.createTextNode(text.slice(cursor)));
        node.replaceWith(fragment);
      }
      return nodes.length;
    }));
    for (const count of counts) {
      expect(count, `${name}: anchor contains a rendered volatile timestamp`).toBeGreaterThan(0);
      wrapped += count;
    }
    const preservedText = await anchor.evaluateAll((elements) => elements.map((element) => element.textContent));
    expect(preservedText, `${name}: timestamp wrapping preserves all rendered target text`).toEqual(sourceText);
  }
  if (renderedAnchors > 0) expect(wrapped, `${name}: at least one timestamp is masked`).toBeGreaterThan(0);
  return await page.locator("[data-ax-visual-timestamp-mask]").all();
}

// D-19: the protected facts (identity, amount, state, actions) are located by geometry, never by the
// text of the masks. Each fact is a visible leaf element; a violation is any fact whose rectangle
// overlaps a mask rectangle (the timestamp wrappers, plus any extra rectangle a control supplies).
// The in-page function is a plain function so a negative control can run the very same code.
function protectedFactViolationsInPage({ extraMaskRects }) {
  // What remains of a control's text once its masked timestamp is removed (a time zone label at most).
  const textOutsideMasks = (element) => {
    const clone = element.cloneNode(true);
    clone.querySelectorAll("[data-ax-visual-timestamp-mask]").forEach((mask) => mask.remove());
    return (clone.textContent || "").replace(/\s+/g, " ").trim();
  };
  const timestampControl = (element) => element.querySelector("[data-ax-visual-timestamp-mask]") !== null && /^(?:[A-Z]{2,5}(?: [A-Z]{2,5})?)?$/.test(textOutsideMasks(element));
  const visible = (element) => {
    const style = getComputedStyle(element);
    const rect = element.getBoundingClientRect();
    return style.display !== "none" && style.visibility !== "hidden" && Number(style.opacity) !== 0 && rect.width > 0 && rect.height > 0 && !element.closest("[hidden],[aria-hidden='true']");
  };
  const rectOf = (element) => {
    const rect = element.getBoundingClientRect();
    return { x: rect.x + window.scrollX, y: rect.y + window.scrollY, width: rect.width, height: rect.height };
  };
  const leaves = (pattern) => [...document.querySelectorAll("body *")].filter((element) =>
    element.children.length === 0 && pattern.test((element.textContent || "").trim()) && visible(element) && !element.closest("script,style,[data-ax-visual-timestamp-mask]"));
  const bySelector = (selector) => [...document.querySelectorAll(selector)].filter(visible);
  const categories = {
    identity: bySelector("h1, [data-ax-page-title], #subscription-summary-id, a[href^='/billing/subscriptions/'], a[href^='/billing/invoices/'], a[href^='/billing/customers/']"),
    amount: leaves(/^(?:[¥$€£]\s?[\d,.]+|\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+\.\d{2}|Amount unavailable|Unavailable)$/),
    status: leaves(/^(?:Open|Active|Past due|Paid|Void|Canceled|Succeeded|Failed|Dead|Replayed|Pending|Draft)$/i),
    // A control whose whole text is a masked timestamp is the time display's copy button: it is the masked
    // value itself, not an action, so it is the one thing allowed to sit under a mask.
    action: bySelector("button, [role='button'], [role='menuitem'], a.ax-button, [data-ax-primary-action]")
      .filter((element) => !timestampControl(element)),
  };
  const masks = [...document.querySelectorAll("[data-ax-visual-timestamp-mask]")].filter(visible).map(rectOf).concat(extraMaskRects || []);
  const overlaps = (a, b) => a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height;
  const violations = [];
  const counts = {};
  const rects = {};
  for (const [category, elements] of Object.entries(categories)) {
    counts[category] = elements.length;
    rects[category] = elements.slice(0, 3).map(rectOf);
    for (const element of elements) {
      const rect = rectOf(element);
      if (masks.some((mask) => overlaps(rect, mask))) violations.push({ category, text: (element.textContent || "").trim().slice(0, 40) });
    }
  }
  return { counts, rects, mask_count: masks.length, violations };
}

async function protectedFactGeometry(page, extraMaskRects = []) {
  return page.evaluate(protectedFactViolationsInPage, { extraMaskRects });
}

async function assertMaskExcludesProtectedFacts(page, name, masks) {
  if (masks.length === 0) {
    expect(name, "surfaces without rendered volatile values have no timestamp anchors").toMatch(
      /^(component-kitchen|invoices|invoice-detail)$/
    );
  } else {
    const text = (await Promise.all(masks.map((mask) => mask.innerText()))).join(" ");
    expect(text, `${name}: timestamp masks match volatile date text`).toMatch(TIMESTAMP_RE);
  }
  const geometry = await protectedFactGeometry(page);
  expect(geometry.counts.identity, `${name}: identity is visible`).toBeGreaterThan(0);
  expect(geometry.mask_count, `${name}: the geometry check saw every mask rectangle`).toBe(masks.length);
  expect(geometry.violations, `${name}: no mask rectangle intersects identity, amount, state or action elements`).toEqual([]);
}

test.describe("Phase 211 visual regression", () => {
  // Scoping is enforced at the config level: this spec matches ONLY the dedicated
  // `visual-desktop` project (testMatch) and is excluded from the two base projects
  // (testIgnore) and the default `npm run e2e` run. No runtime project guard needed —
  // a describe-level `test.skip(fn)` receives only the fixtures object (no testInfo),
  // so a `testInfo.project` guard there throws.

  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("matches committed baselines for the selected admin surfaces", async ({
    page,
    request
  }) => {
    test.setTimeout(120_000);

    // Phase 191 resets once, then the existing fixtures are merged without
    // another reset so the chosen invoice ID and dashboard compositions coexist.
    const phase191 = await seed(request, "phase191-matrix");
    await seed(request, "operator-flows");
    const dash = await seed(request, "dashboard");
    await seed(request, "edge-states");

    const surfaces = [
      { name: "dashboard", route: "/billing", fullPage: true },
      { name: "subscriptions", route: "/billing/subscriptions", fullPage: true },
      {
        name: "subscription-detail",
        route: `/billing/subscriptions/${dash.subscription_id}`,
        fullPage: true
      },
      { name: "component-kitchen", route: "/billing/dev/components", fullPage: false },
      { name: "invoices", route: "/billing/invoices?view=all", fullPage: true },
      {
        name: "invoice-detail",
        route: `/billing/invoices/${phase191.phase191_invoice_id}`,
        fullPage: true
      }
    ];

    for (const { name, route, fullPage } of surfaces) {
      await login(page, route);
      await hideCaptureOnlyChrome(page);
      await expect(page.locator("#main-content")).toBeVisible();

      if (name === "invoice-detail") {
        const detail = page.locator(".ax-page").first();
        await expect(detail).toContainText("E2E-191-JPY-001");
        await expect(detail).toContainText("E2E Phase 191 株式会社 Café Boundary Customer");
        await expect(detail).toContainText("100,000");
        await expect(detail).toContainText("Open");
        const menu = page.locator("[data-ax-action-overflow-menu]").first();
        await expect(menu).toBeVisible();
        await menu.locator("summary").click();
        await page.getByRole("menuitem", { name: /Void invoice/i }).first().click();
        const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']:visible").first();
        await expect(drawer).toBeVisible();
        await drawer.locator('[data-role="void-form"]').evaluate((form) => form.requestSubmit());
        const review = page.locator("#ax-overlay-root [data-role='confirm-panel']:visible").first();
        await expect(review).toBeVisible();
        await expect(review).toContainText(phase191.phase191_invoice_id);
        await expect(review).toContainText("100,000");
        await expect(review).toContainText("Owner target");
        await expect(drawer.locator("[data-ax-action-drawer-confirm]")).toBeVisible();
      }
      for (const theme of ["light", "dark"]) {
        await page.evaluate(
          (t) => document.documentElement.setAttribute("data-theme", t),
          theme
        );
        // Assert mounted values separately in both visual compositions. The
        // second pass recognizes existing wrappers without changing the DOM.
        const masks = await maskLocators(page, name);
        await assertMaskExcludesProtectedFacts(page, name, masks);
        const file = theme === "dark" ? `${name}-dark.png` : `${name}.png`;
        if (name === "invoices") {
          const row = page.locator(`[data-row-id="${phase191.phase191_invoice_id}"]:visible`).first();
          await expect(row).toContainText("E2E-191-JPY-001");
          await expect(row).toContainText("E2E Phase 191 株式会社 Café Boundary Customer");
          await expect(row).toContainText("100,000");
          await expect(row).toContainText("Open");
          await expect(row.locator(`a[href="/billing/invoices/${phase191.phase191_invoice_id}"]`).first()).toBeVisible();
        }
        await expect(page).toHaveScreenshot(file, {
          fullPage,
          animations: "disabled",
          mask: masks,
          maskColor: "#FF00FF"
        });
      }
    }
  });

  test("geometry check negative control: a mask over the amount is detected and the real masks pass", async ({ page, request }) => {
    test.setTimeout(60_000);
    const phase191 = await seed(request, "phase191-matrix");
    await login(page, `/billing/invoices/${phase191.phase191_invoice_id}`);
    await expect(page.locator("#main-content")).toBeVisible();
    const clean = await protectedFactGeometry(page);
    expect(clean.counts.amount, "the invoice detail renders an amount fact").toBeGreaterThan(0);
    expect(clean.counts.status, "the invoice detail renders a state fact").toBeGreaterThan(0);
    expect(clean.counts.action, "the invoice detail renders an action").toBeGreaterThan(0);
    expect(clean.violations, "positive control: with no mask nothing is violated").toEqual([]);
    const hiddenAmount = await protectedFactGeometry(page, [clean.rects.amount[0]]);
    expect(hiddenAmount.violations.map((item) => item.category), "a mask placed over the amount fails the check").toContain("amount");
    const hiddenIdentity = await protectedFactGeometry(page, [clean.rects.identity[0]]);
    expect(hiddenIdentity.violations.map((item) => item.category)).toContain("identity");
  });
});
