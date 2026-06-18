const fs = require("fs");
const path = require("path");

const { test, expect } = require("@playwright/test");

const REPO_ROOT = path.resolve(__dirname, "..", "..");
const LEDGER_PATH = path.join(
  REPO_ROOT,
  ".planning/phases/190-navigation-data-display-meta-component-cohesion/190-GROUP-CONTRACTS.md"
);

const REQUIRED_SLUGS = [
  "page-header-actions-breadcrumbs",
  "toolbar-search-filter-sort",
  "table-empty-loading-error-pagination",
  "kpi-chart-table",
  "detail-header-metadata-actions",
  "modal-confirm",
  "drawer-form",
  "tabs-subviews",
];

const PHASE_191_HANDOFF_TAGS = [
  "focus-trap",
  "focus-restore",
  "escape",
  "click-outside",
  "scroll-reachability",
  "overlay-position",
  "liveview-patch-focus",
  "fixture-gaps",
  "microcopy",
];

const DECISION_IDS = Array.from({ length: 30 }, (_value, index) => {
  return `D-${String(index + 1).padStart(2, "0")}`;
});

const UI_SPEC_WIDTHS = [320, 375, 768, 1024, 1440];

const representativeRoutes = [
  { group: "page-header-actions-breadcrumbs", path: "/billing" },
  { group: "toolbar-search-filter-sort", path: "/billing/invoices" },
  { group: "table-empty-loading-error-pagination", path: "/billing/invoices" },
  { group: "kpi-chart-table", path: "/billing/analytics/recovery" },
  { group: "detail-header-metadata-actions", path: "/billing/invoices/:invoice_id" },
  { group: "modal-confirm", path: "/billing/webhooks/:webhook_id" },
  { group: "drawer-form", path: "/billing/dev/components" },
  { group: "tabs-subviews", path: "/billing/customers/:customer_id" },
];

function groupLocator(page, slug) {
  return page.locator(`[data-component-group="${slug}"]`);
}

async function openComponentKitchen(_page) {
  throw new Error("TODO: open the authenticated component kitchen before browser probes");
}

async function setTheme(_page, _theme) {
  throw new Error("TODO: set the global data-theme value before locator checks");
}

async function assertAllGroupRootsVisible(_page) {
  throw new Error("TODO: assert all required data-component-group roots are visible exactly once");
}

async function assertResponsiveModeContract(_page, _width) {
  throw new Error("TODO: assert table/card responsive modes do not expose duplicate active DOM");
}

async function assertPaginationStates(_page) {
  throw new Error("TODO: assert no-pagination and has-pagination controls differ");
}

async function assertNamedActiveStates(_page) {
  throw new Error("TODO: assert filter, selected row, tab/window, and sort cues are visible and named");
}

async function assertNoOffscreenActions(_page, _width) {
  throw new Error("TODO: assert long-content group actions stay inside the viewport");
}

async function visibleFocusableCount(locator) {
  const focusable = locator.locator(
    [
      "a[href]",
      "button:not([disabled])",
      "input:not([disabled])",
      "select:not([disabled])",
      "textarea:not([disabled])",
      "[tabindex]:not([tabindex='-1'])",
    ].join(", ")
  );

  let count = 0;
  const total = await focusable.count();

  for (let index = 0; index < total; index += 1) {
    if (await focusable.nth(index).isVisible().catch(() => false)) count += 1;
  }

  return count;
}

async function assertSingleResponsiveMode(page, tableRoot) {
  const desktopTable = tableRoot.locator("table:visible");
  const mobileCards = tableRoot.locator("[data-role='card-list']:visible");
  const visibleModes = Number((await desktopTable.count()) > 0) + Number((await mobileCards.count()) > 0);

  await expect(visibleModes, "exactly one table responsive mode should be visible").toBe(1);
  await expect(page.locator("body")).toBeVisible();
}

async function assertActiveStateVisible(page, selector) {
  const active = page.locator(selector).first();

  await expect(active).toBeVisible();

  const hasActiveCue = await active.evaluate((element) => {
    return (
      element.getAttribute("aria-current") === "page" ||
      element.getAttribute("aria-pressed") === "true" ||
      Boolean(element.getAttribute("data-state")) ||
      element.classList.contains("ax-tab-active") ||
      element.classList.contains("ax-filter-chip-active") ||
      element.classList.contains("ax-sidebar-link-active")
    );
  });

  expect(hasActiveCue, `${selector} should expose a visible active-state cue`).toBeTruthy();
}

test("group contract ledger lists required slugs, decisions, and Phase 191 handoff tags", async () => {
  const ledger = fs.readFileSync(LEDGER_PATH, "utf8");

  for (const slug of REQUIRED_SLUGS) {
    expect(ledger, `missing group slug ${slug}`).toContain(`\`${slug}\``);
  }

  for (const tag of PHASE_191_HANDOFF_TAGS) {
    expect(ledger, `missing Phase 191 handoff tag ${tag}`).toContain(tag);
  }

  for (const decisionId of DECISION_IDS) {
    expect(ledger, `missing decision citation ${decisionId}`).toContain(decisionId);
  }
});

test.describe("Phase 190 group contract browser probes", () => {
  test.beforeEach(async ({ page }) => {
    await openComponentKitchen(page);
  });

  test("exposes every group locator in light and dark themes", async ({ page }) => {
    for (const theme of ["light", "dark"]) {
      await setTheme(page, theme);
      await assertAllGroupRootsVisible(page);
    }
  });

  test("table and card responsive roots expose one active mode at each breakpoint", async ({ page }) => {
    for (const width of [375, 1024]) {
      await assertResponsiveModeContract(page, width);
    }
  });

  test("pagination states expose load-more only when more data exists", async ({ page }) => {
    await assertPaginationStates(page);
  });

  test("active filter, selection, sort, and subview cues are visible and named", async ({ page }) => {
    await assertNamedActiveStates(page);
  });

  test("long-content actions stay reachable at UI-spec widths", async ({ page }) => {
    for (const width of UI_SPEC_WIDTHS) {
      await assertNoOffscreenActions(page, width);
    }
  });
});

module.exports = {
  groupLocator,
  visibleFocusableCount,
  assertSingleResponsiveMode,
  assertActiveStateVisible,
  representativeRoutes,
};
