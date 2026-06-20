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

const GROUP_FINDABILITY = {
  "page-header-actions-breadcrumbs": [
    /Quarter close/i,
    /Review subscriptions/i,
    /Export review/i,
    /Open runbook/i,
  ],
  "toolbar-search-filter-sort": [
    /Search/i,
    /Status/i,
    /Open/i,
    /Apply filters/i,
    /Clear filters/i,
    /Oldest first/i,
  ],
  "table-empty-loading-error-pagination": [
    /Invoice queue proof table/i,
    /Past due/i,
    /Filtered empty/i,
    /Retry/i,
    /No pagination/i,
    /Load more/i,
  ],
  "kpi-chart-table": [
    /Recovered MRR/i,
    /At risk/i,
    /Retry scheduled/i,
    /Annual enterprise renewal/i,
  ],
  "detail-header-metadata-actions": [
    /Subscription sub_group_visibility_demo/i,
    /Status active/i,
    /Owner scope/i,
    /Review subscription/i,
  ],
  "modal-confirm": [
    /Confirm action/i,
    /Cancel renewal schedule/i,
    /Cancel renewal/i,
  ],
  "drawer-form": [
    /Edit billing contact/i,
    /Billing email/i,
    /Owner scope is required/i,
    /Save contact/i,
  ],
  "tabs-subviews": [
    /Webhook delivery attempts/i,
    /30 days UTC/i,
    /Overview/i,
  ],
};

const representativeRoutes = [
  { category: "shell-nav-tabs", group: "page-header-actions-breadcrumbs", path: "/billing/dev/components" },
  { category: "list-table", group: "table-empty-loading-error-pagination", path: "/billing/invoices" },
  { category: "detail", group: "detail-header-metadata-actions", path: "/billing/invoices/:invoice_id" },
  { category: "recovery-kpi", group: "kpi-chart-table", path: "/billing/analytics/recovery" },
  { category: "overlay-path", group: "detail-header-metadata-actions", path: "/billing/webhooks/:webhook_id" },
];

function groupLocator(page, slug) {
  return page.locator(`[data-component-group="${slug}"]`);
}

function proofRoot(page, slug) {
  return page.locator(`#grp190-${slug}[data-component-group="${slug}"]`);
}

function focusableSelector() {
  return [
    "a[href]",
    "button:not([disabled])",
    "input:not([disabled])",
    "select:not([disabled])",
    "summary",
    "textarea:not([disabled])",
    "[tabindex]:not([tabindex='-1'])",
  ].join(", ");
}

function actionSelector() {
  return ["a[href]", "button:not([disabled])", "summary"].join(", ");
}

function scopedProofFocusableSelector() {
  return focusableSelector()
    .split(", ")
    .map((selector) => `section.ax-dev-group-specimen[id^='grp190-'][data-component-group] ${selector}`)
    .join(", ");
}

async function openComponentKitchen(page) {
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Component Groups" })).toBeVisible();
}

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seed(request, fixture) {
  const response = await request.post(`/__e2e__/seed/${fixture}`);
  expect(response.ok()).toBeTruthy();
  return response.json();
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}

function resolveRepresentativeRoutes(fixtureData) {
  const edge = fixtureData["edge-states"];
  const opFlows = fixtureData["operator-flows"];

  return representativeRoutes.map((route) => {
    if (route.path.includes(":invoice_id")) {
      return { ...route, path: route.path.replace(":invoice_id", encodeURIComponent(edge.jpy_invoice_id)) };
    }

    if (route.path.includes(":webhook_id")) {
      return { ...route, path: route.path.replace(":webhook_id", encodeURIComponent(opFlows.single_webhook_id)) };
    }

    return route;
  });
}

async function setTheme(page, theme) {
  await page.evaluate((value) => {
    document.documentElement.setAttribute("data-theme", value);
    document.documentElement.dataset.theme = value;
  }, theme);

  await expect
    .poll(() => page.evaluate(() => document.documentElement.getAttribute("data-theme")))
    .toBe(theme);
  await page.waitForTimeout(50);
}

async function assertAllGroupRootsVisible(page) {
  for (const slug of REQUIRED_SLUGS) {
    const root = proofRoot(page, slug);
    await expect(root, `${slug} proof root`).toHaveCount(1);
    await expect(root, `${slug} proof root`).toBeVisible();
    await expect(root.locator("[data-group-state]").first(), `${slug} state chips`).toBeVisible();
  }
}

async function assertOperatorStressFindability(page) {
  for (const slug of REQUIRED_SLUGS) {
    const root = proofRoot(page, slug);
    await expect(root, `${slug} proof root`).toBeVisible();
    await expect(root.locator(".ax-dev-group-header h4.ax-heading"), `${slug} identity heading`).toBeVisible();
    await expect(root.locator(".ax-dev-group-state-chip").first(), `${slug} state summary`).toBeVisible();
    expect(await visibleFocusableCount(root), `${slug} has an immediately reachable action/control`).toBeGreaterThan(0);

    for (const expectedText of GROUP_FINDABILITY[slug]) {
      await expect(root, `${slug} exposes ${expectedText}`).toContainText(expectedText);
    }
  }
}

async function assertResponsiveModeContract(page, width) {
  await page.setViewportSize({ width, height: 900 });
  await page.waitForTimeout(50);

  const tableRoot = proofRoot(page, "table-empty-loading-error-pagination");
  await tableRoot.scrollIntoViewIfNeeded();
  await assertSingleResponsiveMode(page, tableRoot);

  const desktopShell = tableRoot.locator(".ax-data-table-shell");
  const mobileCards = tableRoot.locator(".ax-data-table-cards");

  if (width < 768) {
    await expect(desktopShell, "desktop table shell is inactive below md").not.toBeVisible();
    expect(await visibleFocusableCount(desktopShell), "inactive desktop table focusables").toBe(0);
    await expect(mobileCards, "mobile cards are active below md").toBeVisible();
  } else {
    await expect(desktopShell, "desktop table shell is active at md and above").toBeVisible();
    await expect(mobileCards, "mobile card list is inactive at md and above").not.toBeVisible();
    expect(await visibleFocusableCount(mobileCards), "inactive mobile card focusables").toBe(0);
  }
}

async function assertPaginationStates(page) {
  const tableRoot = proofRoot(page, "table-empty-loading-error-pagination");
  const noPagination = tableRoot.locator('.ax-dev-group-state-row[data-group-state="no-pagination"]');
  const hasPagination = tableRoot.locator('.ax-dev-group-state-row[data-group-state="has-pagination"]');

  await expect(noPagination).toBeVisible();
  await expect(hasPagination).toBeVisible();
  await expect(noPagination.getByRole("button", { name: /load more/i })).toHaveCount(0);
  await expect(hasPagination.getByRole("button", { name: /load more/i })).toBeVisible();
  expect(await visibleFocusableCount(noPagination), "no-pagination row has no load-more focus target").toBe(0);
  expect(await visibleFocusableCount(hasPagination), "has-pagination row exposes load-more").toBeGreaterThan(0);
}

async function assertNamedActiveStates(page) {
  const toolbarRoot = proofRoot(page, "toolbar-search-filter-sort");
  await expect(toolbarRoot.locator("#grp190-toolbar-search")).toHaveValue(/enterprise annual renewal/);
  await expect(toolbarRoot.locator("#grp190-toolbar-status")).toHaveValue("Open");
  await expect(toolbarRoot.locator('.ax-filter-chip[data-filter="status"]')).toContainText("Open");
  await expect(toolbarRoot.locator('.ax-filter-chip[data-filter="sort"]')).toContainText("Oldest first");
  await expect(toolbarRoot.locator("details.ax-dropdown summary")).toContainText("Sort");
  await expect(toolbarRoot.locator(".ax-empty-title", { hasText: "Filtered empty" })).toBeVisible();

  const tableRoot = proofRoot(page, "table-empty-loading-error-pagination");
  const selectedRow = tableRoot.locator('[aria-selected="true"][data-group-state="selected-filter-active"]');
  if (await selectedRow.isVisible().catch(() => false)) {
    await expect(selectedRow).toContainText(/Past\s+Due/i);
  } else {
    const selectedCard = tableRoot.locator('.ax-data-table-cards[data-group-state="mobile-card-list-degradation"]');
    await expect(selectedCard).toBeVisible();
    await expect(selectedCard).toContainText(/Past\s+due/i);
  }

  const tabsRoot = proofRoot(page, "tabs-subviews");
  const currentSubview = tabsRoot.locator('nav[aria-label="Page sections"] [aria-current="page"]');
  const currentWindow = tabsRoot.locator('nav[aria-label="Time window (UTC)"] [aria-current="page"]');
  await expect(currentSubview).toBeVisible();
  await expect(currentSubview).toContainText("Webhook delivery attempts");
  await expect(currentWindow).toBeVisible();
  await expect(currentWindow).toContainText("30 days UTC");
}

async function assertNoOffscreenActions(page, width) {
  await page.setViewportSize({ width, height: 900 });
  await page.waitForTimeout(50);

  const result = await page.evaluate((selector) => {
    const failures = [];
    const roots = Array.from(
      document.querySelectorAll("section.ax-dev-group-specimen[id^='grp190-'][data-component-group]")
    );
    const rootSlugs = roots.map((root) => root.getAttribute("data-component-group"));
    const phase191Boundary = [
      ".ax-dropdown-panel",
      ".ax-tabs",
      ".ax-dev-group-drawer-specimen",
      ".ax-dev-group-modal",
    ].join(", ");

    for (const root of roots) {
      for (const element of root.querySelectorAll(selector)) {
        if (element.closest(phase191Boundary)) continue;

        const style = window.getComputedStyle(element);
        const rect = element.getBoundingClientRect();
        const visible =
          style.display !== "none" &&
          style.visibility !== "hidden" &&
          rect.width > 0 &&
          rect.height > 0;
        if (!visible) continue;
        if (rect.left < -1 || rect.right > window.innerWidth + 1) {
          failures.push({
            group: root.getAttribute("data-component-group"),
            label: element.textContent.trim().replace(/\s+/g, " ").slice(0, 80),
            left: rect.left,
            right: rect.right,
            viewport: window.innerWidth,
          });
        }
      }
    }

    return {
      rootSlugs,
      scrollWidth: document.documentElement.scrollWidth,
      clientWidth: document.documentElement.clientWidth,
      failures,
    };
  }, actionSelector());

  expect(result.rootSlugs.sort(), "proof roots exist before width probe").toEqual([...REQUIRED_SLUGS].sort());
  expect(result.failures, `offscreen focusable actions at ${width}px`).toEqual([]);

  const focusables = page.locator(scopedProofFocusableSelector());
  const total = await focusables.count();
  const focusFailures = [];

  for (let index = 0; index < total; index += 1) {
    const focusable = focusables.nth(index);
    if (!(await focusable.isVisible().catch(() => false))) continue;

    try {
      await focusable.focus({ timeout: 500 });
    } catch (error) {
      focusFailures.push(`${index}: ${error.message}`);
    }
  }

  expect(focusFailures, `focusable action failures at ${width}px`).toEqual([]);
}

async function assertOperatorStressLayout(page, width, theme) {
  await page.setViewportSize({ width, height: 900 });
  await setTheme(page, theme);

  const result = await page.evaluate(
    ({ slugs, selector }) => {
      const failures = [];
      const roots = Array.from(
        document.querySelectorAll("section.ax-dev-group-specimen[id^='grp190-'][data-component-group]")
      );
      const rootSlugs = roots.map((root) => root.getAttribute("data-component-group"));

      const visible = (element) => {
        const style = window.getComputedStyle(element);
        const rect = element.getBoundingClientRect();
        return style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
      };

      const label = (element) =>
        (element.getAttribute("aria-label") || element.textContent || element.id || element.tagName)
          .trim()
          .replace(/\s+/g, " ")
          .slice(0, 80);

      const overlaps = (a, b) => {
        const left = Math.max(a.left, b.left);
        const right = Math.min(a.right, b.right);
        const top = Math.max(a.top, b.top);
        const bottom = Math.min(a.bottom, b.bottom);
        return right - left > 3 && bottom - top > 3;
      };

      for (const root of roots) {
        const group = root.getAttribute("data-component-group");
        const header = root.querySelector(".ax-dev-group-header");
        const body = root.querySelector(".ax-dev-group-body");
        const rootRect = root.getBoundingClientRect();

        if (!slugs.includes(group)) {
          failures.push({ type: "unexpected-group", group });
        }

        if (rootRect.left < -1 || rootRect.right > window.innerWidth + 1) {
          failures.push({
            type: "proof-root-horizontal-overflow",
            group,
            left: rootRect.left,
            right: rootRect.right,
            viewport: window.innerWidth,
          });
        }

        if (!header || !body || !visible(header) || !visible(body)) {
          failures.push({ type: "missing-header-body", group });
        } else {
          const headerRect = header.getBoundingClientRect();
          const bodyRect = body.getBoundingClientRect();
          if (bodyRect.top < headerRect.bottom - 1) {
            failures.push({
              type: "hierarchy-overlap",
              group,
              headerBottom: headerRect.bottom,
              bodyTop: bodyRect.top,
            });
          }
        }

        for (const card of root.querySelectorAll(".ax-card")) {
          if (card === root) continue;
          const containingCard = card.parentElement?.closest(".ax-card");
          if (!containingCard || containingCard === root) continue;
          if (card.closest(".ax-dev-group-state-grid")) continue;
          failures.push({
            type: "nested-card",
            group,
            outer: label(containingCard),
            inner: label(card),
          });
        }

        const actions = Array.from(root.querySelectorAll(selector)).filter((element) => {
          if (!visible(element)) return false;
          if (element.closest(".ax-dropdown-panel")) return false;
          return true;
        });

        for (let index = 0; index < actions.length; index += 1) {
          for (let otherIndex = index + 1; otherIndex < actions.length; otherIndex += 1) {
            const first = actions[index];
            const second = actions[otherIndex];
            if (first.contains(second) || second.contains(first)) continue;
            if (overlaps(first.getBoundingClientRect(), second.getBoundingClientRect())) {
              failures.push({
                type: "action-overlap",
                group,
                first: label(first),
                second: label(second),
              });
            }
          }
        }
      }

      return { rootSlugs, failures };
    },
    { slugs: REQUIRED_SLUGS, selector: actionSelector() }
  );

  expect(result.rootSlugs.sort(), "proof roots exist before operator-stress layout scan").toEqual(
    [...REQUIRED_SLUGS].sort()
  );
  expect(result.failures, `operator-stress layout failures at ${width}px in ${theme}`).toEqual([]);
}

async function assertRepresentativeRoute(page, route) {
  await login(page, route.path);
  await expect(page.locator("#main-content")).toBeVisible();

  if (route.category === "shell-nav-tabs") {
    await expect(proofRoot(page, "page-header-actions-breadcrumbs")).toBeVisible();
    await expect(proofRoot(page, "tabs-subviews")).toBeVisible();
    await expect(groupLocator(page, "toolbar-search-filter-sort").first()).toBeVisible();
    return;
  }

  if (route.category === "list-table") {
    await expect(groupLocator(page, "table-empty-loading-error-pagination").first()).toBeVisible();
    await expect(page.locator('[data-role="filter-form"]').first()).toBeVisible();
    await expect(page.getByRole("heading", { name: /Invoices/i }).first()).toBeVisible();
    return;
  }

  if (route.category === "detail") {
    await expect(groupLocator(page, "detail-header-metadata-actions").first()).toBeVisible();
    await expect(page.getByRole("heading", { name: /Invoice/i }).first()).toBeVisible();
    return;
  }

  if (route.category === "recovery-kpi") {
    await expect(groupLocator(page, "kpi-chart-table").first()).toBeVisible();
    await expect(page.locator(".ax-kpi-card").first()).toBeVisible();
    await expect(page.locator(".ax-funnel-chart").first()).toBeVisible();
    await expect(groupLocator(page, "table-empty-loading-error-pagination").first()).toBeVisible();
    await expect(groupLocator(page, "tabs-subviews").first()).toBeVisible();
    return;
  }

  if (route.category === "overlay-path") {
    await expect(groupLocator(page, "detail-header-metadata-actions").first()).toBeVisible();
    await expect(page.locator('[data-role="replay-single"]').first()).toBeVisible();
    await expect(page.getByText(/Requeue this webhook row|Replay is unavailable/i).first()).toBeVisible();
    return;
  }

  throw new Error(`Unhandled representative route category: ${route.category}`);
}

async function visibleFocusableCount(locator) {
  const focusable = locator.locator(
    [
      "a[href]",
      "button:not([disabled])",
      "input:not([disabled])",
      "select:not([disabled])",
      "summary",
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
  const desktopShell = tableRoot.locator(".ax-data-table-shell");
  const mobileCards = tableRoot.locator(".ax-data-table-cards");
  const visibleModes =
    Number(await desktopShell.isVisible().catch(() => false)) +
    Number(await mobileCards.isVisible().catch(() => false));

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

  test("operator-stress group scan is deterministic across themes and breakpoints", async ({ page }) => {
    for (const theme of ["light", "dark"]) {
      await setTheme(page, theme);
      await assertOperatorStressFindability(page);

      for (const width of UI_SPEC_WIDTHS) {
        await assertOperatorStressLayout(page, width, theme);
      }
    }
  });
});

test.describe("Phase 190 representative live probes", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("samples one list, detail, recovery, overlay, and shell/tabs surface", async ({ page, request }) => {
    const fixtureData = {
      "operator-flows": await seed(request, "operator-flows"),
      dashboard: await seed(request, "dashboard"),
      "edge-states": await seed(request, "edge-states"),
    };

    const routes = resolveRepresentativeRoutes(fixtureData);
    expect(routes.map((route) => route.category).sort()).toEqual(
      ["detail", "list-table", "overlay-path", "recovery-kpi", "shell-nav-tabs"].sort()
    );

    for (const route of routes) {
      await assertRepresentativeRoute(page, route);
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
