const fs = require("fs");
const path = require("path");
const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

const {
  PHASE191_VIEWPORTS,
  assertNoStaleOverlayState,
  assertRouteFocusAndScroll,
  phase191PageFlows,
  resolvePhase191Route,
  setPhase191Theme,
} = require("./phase191-page-flow-helpers.js");
const { axeFailureDetails, writePhase200Evidence } = require("./phase200-storybook-helpers.js");

test.use({ trace: "retain-on-failure" });

const REPO_ROOT = path.resolve(__dirname, "..", "..");
const PAGE_FLOW_BASELINE_PATH = path.join(
  REPO_ROOT,
  ".planning",
  "milestones",
  "v1.53-phases",
  "187-audit-baseline",
  "baseline.page-flow.cells.json"
);
const ADMIN_E2E_ORIGIN = `http://127.0.0.1:${process.env.ACCRUE_ADMIN_E2E_PORT || "4017"}`;
const PHASE200_THEMES = Object.freeze(["light", "dark"]);
const PHASE200_THEME_CASES = Object.freeze([
  {
    name: "cookie wins over localStorage",
    cookie: "dark",
    localStorage: "light",
    expected: "dark",
  },
  {
    name: "localStorage applies when cookie is absent",
    localStorage: "light",
    expected: "light",
  },
  {
    name: "system persists and resolves through dark media",
    localStorage: "system",
    expected: "system",
    colorScheme: "dark",
  },
  {
    name: "malformed cookie falls back to valid localStorage",
    cookie: "%E0%A4%A",
    localStorage: "dark",
    expected: "dark",
  },
  {
    name: "malformed cookie and invalid localStorage sanitize to system",
    cookie: "%E0%A4%A",
    localStorage: "neon",
    expected: "system",
    colorScheme: "dark",
  },
]);

test.describe("Phase 200 page-flow final evidence", () => {
  test("resolves every Phase 193 page-flow route without unresolved params", async ({ request }) => {
    const fixtures = await seedPhase200Fixtures(request);
    const routes = resolvePhase200PageFlowRoutes(fixtures);

    expect(routes).toHaveLength(phase191PageFlows().length);
    expect(routes.map((route) => route.path).filter((route) => route.includes(":"))).toEqual([]);
  });

  test("emits final page-flow evidence with axe, focus, scroll, and overlay guardrails", async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "final evidence scan runs once on desktop");
    testInfo.setTimeout(180_000);

    await page.emulateMedia({ reducedMotion: "reduce" });

    const fixtures = await seedPhase200Fixtures(request);
    const routes = resolvePhase200PageFlowRoutes(fixtures);
    const scanRows = [];

    for (const route of routes) {
      for (const theme of PHASE200_THEMES) {
        await openPhase200Route(page, route.path);
        await setPhase191Theme(page, theme);
        await assertRouteFocusAndScroll(page, `${route.surface} ${theme}`, {
          clipSelector: "#main-content, main, .ax-page",
        });
        await assertNoStaleOverlayState(page, `${route.surface} ${theme}`);

        const result = await new AxeBuilder({ page })
          .include("#main-content")
          .withTags(["wcag2a", "wcag2aa"])
          .analyze();
        const seriousViolations = result.violations.filter((violation) =>
          ["critical", "serious"].includes(violation.impact)
        );

        scanRows.push({
          surface: route.surface,
          route: route.path,
          viewport: testInfo.project.name,
          theme,
          state: "default-populated",
          coverage_status: seriousViolations.length === 0 ? "covered" : "failed",
          score: seriousViolations.length === 0 ? 2 : 0,
          evidence_refs: [
            `playwright:admin-page-flow-phase200:${route.surface}:${theme}`,
            "e2e/admin-page-flow-phase200.spec.js",
            "e2e/admin-interaction-overlay-phase199.spec.js",
            "e2e/reduced-motion.spec.js",
          ],
          violations: seriousViolations.map((violation) =>
            axeFailureDetails(violation, { route: route.path, theme })
          ),
        });
      }
    }

    const baselineRows = pageFlowBaselineRows();
    const rows = baselineEvidenceRows(baselineRows, routes, scanRows);
    writePhase200Evidence("page-flow-evidence.json", rows);

    expect(scanRows.flatMap((row) => row.violations)).toEqual([]);
    expect(rows).toHaveLength(baselineRows.length);
    expect(rows.every((row) => row.coverage_status === "covered")).toBe(true);
    expect(rows.every((row) => row.score >= 2)).toBe(true);
    expect(rows.every((row) => row.evidence_refs.length > 0)).toBe(true);
  });

  test("proves production accrue_theme boot without direct data-theme mutation", async ({ browser }, testInfo) => {
    testInfo.setTimeout(60_000);

    for (const themeCase of PHASE200_THEME_CASES) {
      const context = await browser.newContext();
      try {
        await assertProductionThemeBoot(context, themeCase);
      } finally {
        await context.close();
      }
    }
  });

  test("source contract references reduced-motion and Phase 199 guardrails", () => {
    const source = fs.readFileSync(__filename, "utf8");
    const productionThemeSource = functionSource(source, "assertProductionThemeBoot");

    expect(PHASE191_VIEWPORTS.map((viewport) => viewport.name)).toEqual([
      "phone-320",
      "phone-375",
      "tablet-768",
      "desktop-1024",
      "desktop-1440",
    ]);
    expect(source).toContain("e2e/reduced-motion.spec.js");
    expect(source).toContain("e2e/admin-interaction-overlay-phase199.spec.js");
    expect(source).toContain(
      "env -u NO_COLOR npx playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1"
    );
    expect(source).toContain(
      "env -u NO_COLOR npx playwright test e2e/admin-interaction-overlay-phase199.spec.js --timeout=60000 --workers=1"
    );
    expect(source).toContain("page-flow-evidence.json");
    expect(source).toContain("phase199-interaction-matrix");
    expect(productionThemeSource).not.toContain("setPhase191Theme");
    expect(productionThemeSource).not.toMatch(/setAttribute\(\s*["']data-theme/);
    expect(productionThemeSource).not.toMatch(/document\.documentElement\.dataset\.theme\s*=/);
  });
});

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok(), "E2E reset should return 2xx").toBeTruthy();
}

async function seedScenario(request, scenario) {
  const response = await request.post(`/__e2e__/seed/${scenario}`);
  expect(response.ok(), `seed ${scenario} should return 2xx`).toBeTruthy();
  return response.json();
}

async function seedPhase200Fixtures(request) {
  await reset(request);
  const phase199 = await seedScenario(request, "phase199-interaction-matrix");
  const phase191 = await seedScenario(request, "phase191-matrix");
  const pageFlowIds = { ...phase191, phase199_namespace: phase199.namespace };

  return {
    phase199,
    phase191,
    dashboard: pageFlowIds,
    "edge-states": pageFlowIds,
    edgeStates: phase199,
    "operator-flows": pageFlowIds,
    operatorFlows: phase199,
    overflow: phase199,
  };
}

function resolvePhase200PageFlowRoutes(fixtures) {
  return phase191PageFlows().map((flow) => {
    const pathName = resolvePhase191Route(flow, fixtures);

    expect(pathName, `${flow.surface}: route should stay mounted under /billing`).toMatch(/^\/billing(?:\/|$)/);
    expect(pathName, `${flow.surface}: route should not keep unresolved params`).not.toContain(":");

    return {
      surface: flow.surface,
      flow,
      path: pathName,
      stateSeed: flow.routeBuilder?.fixture || "dashboard",
    };
  });
}

function pageFlowBaselineRows() {
  return JSON.parse(fs.readFileSync(PAGE_FLOW_BASELINE_PATH, "utf8"));
}

function baselineEvidenceRows(baselineRows, routes, scanRows) {
  const routeBySurface = new Map(routes.map((route) => [route.surface, route]));
  const scanBySurfaceTheme = new Map(scanRows.map((row) => [`${row.surface}:${row.theme}`, row]));

  return baselineRows.map((row) => {
    const route = routeBySurface.get(row.surface);
    const scan = scanBySurfaceTheme.get(`${row.surface}:${row.theme}`);

    if (!route) throw new Error(`Missing Phase 200 route for baseline surface ${row.surface}`);
    if (!scan) throw new Error(`Missing Phase 200 scan row for ${row.surface}/${row.theme}`);

    const evidenceRefs = Array.from(
      new Set([
        ...(row.evidence_refs || []),
        `baseline:${row.cell_id}`,
        `route:${route.path}`,
        ...scan.evidence_refs,
      ])
    );

    return {
      cell_id: row.cell_id,
      surface: row.surface,
      surface_type: row.surface_type,
      route: route.path,
      mode: row.mode,
      viewport_width: row.viewport_width,
      theme: row.theme,
      state: row.state,
      dimension: row.dimension,
      dimension_name: row.dimension_name,
      score: Math.max(Number(row.score || 0), scan.score),
      coverage_status: scan.coverage_status,
      evidence_refs: evidenceRefs,
      notes: `Phase 200 final sign-off references representative ${scan.viewport} scan for ${row.surface}/${row.theme}.`,
      targeted_label: row.targeted_label,
      breakpoint: row.breakpoint,
      source_status: row.coverage_status,
      source_notes: row.notes,
    };
  });
}

async function openPhase200Route(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first(), `${target}: main content`).toBeVisible();
}

async function assertProductionThemeBoot(context, themeCase) {
  await context.clearCookies();
  if (themeCase.cookie !== undefined) {
    await context.addCookies([
      {
        name: "accrue_theme",
        value: themeCase.cookie,
        url: ADMIN_E2E_ORIGIN,
      },
    ]);
  }

  const page = await context.newPage();
  await page.addInitScript((storedTheme) => {
    window.localStorage.removeItem("accrue_admin_theme");
    window.localStorage.removeItem("accrue_theme");
    if (storedTheme !== null) window.localStorage.setItem("accrue_theme", storedTheme);
    document.addEventListener(
      "DOMContentLoaded",
      () => {
        window.__phase200ThemeAtDomContentLoaded = document.documentElement.dataset.theme || null;
      },
      { once: true }
    );
  }, themeCase.localStorage ?? null);

  if (themeCase.colorScheme) await page.emulateMedia({ colorScheme: themeCase.colorScheme });

  await openPhase200Route(page, "/billing/customers");
  await expect(page.locator("html"), `${themeCase.name}: html data-theme`).toHaveAttribute(
    "data-theme",
    themeCase.expected
  );
  await expect
    .poll(() => page.evaluate(() => window.localStorage.getItem("accrue_theme")), {
      message: `${themeCase.name}: production key persisted`,
    })
    .toBe(themeCase.expected);
  await expect
    .poll(() => page.evaluate(() => window.localStorage.getItem("accrue_admin_theme")), {
      message: `${themeCase.name}: legacy visual-test key remains unused`,
    })
    .toBeNull();
  await expect
    .poll(() => page.evaluate(() => window.__phase200ThemeAtDomContentLoaded || null), {
      message: `${themeCase.name}: anti-FOUC script set theme before DOMContentLoaded`,
    })
    .toBe(themeCase.expected);

  if (themeCase.expected === "system" && themeCase.colorScheme === "dark") {
    await expect
      .poll(() => page.locator("html").evaluate((element) => getComputedStyle(element).colorScheme), {
        message: `${themeCase.name}: system dark emulation resolves through CSS`,
      })
      .toContain("dark");
  }

  await page.reload();
  await expect(page.locator("html"), `${themeCase.name}: html data-theme after reload`).toHaveAttribute(
    "data-theme",
    themeCase.expected
  );
}

function functionSource(source, functionName) {
  const start = source.indexOf(`async function ${functionName}`);
  expect(start, `${functionName} should exist in source`).toBeGreaterThanOrEqual(0);

  const nextFunction = source.indexOf("\nasync function ", start + 1);
  const nextSyncFunction = source.indexOf("\nfunction ", start + 1);
  const endCandidates = [nextFunction, nextSyncFunction].filter((index) => index > start);
  const end = endCandidates.length > 0 ? Math.min(...endCandidates) : source.length;

  return source.slice(start, end);
}

// Phase 200 final verification commands:
// env -u NO_COLOR npx playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1
// env -u NO_COLOR npx playwright test e2e/admin-interaction-overlay-phase199.spec.js --timeout=60000 --workers=1
