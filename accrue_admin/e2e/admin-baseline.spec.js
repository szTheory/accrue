const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

const {
  DIMENSIONS,
  SURFACES,
  PROJECTS,
  cellsForSurface,
} = require("./baseline-manifest.js");

const RESULTS_ROOT = "test-results/admin-baseline";
const THEMES = ["light", "dark"];
const COVERED_STATES = new Set(["default-populated", "overflow", "long-content"]);
const TARGETED_BREAKPOINTS = [320, 375, 768, 1024, 1440];
const COMPONENT_KITCHEN_ROUTE = "/billing/dev/components";

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

function slug(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function projectMode(projectName) {
  const project = PROJECTS.find((entry) => entry.name === projectName || entry.mode === projectName);
  if (!project) throw new Error(`Unknown project for baseline capture: ${projectName}`);
  return project.mode;
}

function routeForSurface(surface, fixtureData) {
  if (surface.surface_type !== "page-flow") {
    return "/billing/dev/components";
  }

  if (!surface.routeBuilder?.params) {
    return surface.route;
  }

  const fixtureName = surface.routeBuilder.fixture;
  const fixture = fixtureData[fixtureName] || {};
  return surface.routeBuilder.params.reduce((route, key) => {
    const value = fixture[key];
    if (!value) throw new Error(`Missing fixture value "${key}" for ${surface.surface}`);
    return route.replace(`:${key}`, encodeURIComponent(value));
  }, surface.route);
}

function coverageForCell(cell, surface, visible) {
  if (!visible) {
    return {
      coverage_status: "gap",
      reason: "Surface was not visible in the DOM during static capture.",
      defect_candidate: "seed-or-route-coverage-gap",
    };
  }

  if (COVERED_STATES.has(cell.state)) {
    return { coverage_status: "covered" };
  }

  if (cell.state === "disabled-readonly" && surface.surface_type === "page-flow") {
    return {
      coverage_status: "n/a",
      reason: "disabled-readonly is component-specific and not represented by this page-flow surface.",
    };
  }

  return {
    coverage_status: "gap",
    reason: `State "${cell.state}" is not forced by the static baseline capture.`,
    defect_candidate: "state-fixture-gap",
  };
}

function observationFromCell({ cell, surface, coverage, evidenceRefs, axeViolations, extra = {} }) {
  return {
    cell_id: extra.cell_id || cell.cell_id,
    surface: cell.surface,
    surface_type: cell.surface_type,
    mode: extra.mode || cell.mode,
    viewport_width: Number(extra.viewport_width ?? cell.viewport_width),
    theme: cell.theme,
    state: cell.state,
    dimension: cell.dimension,
    dimension_name: cell.dimension_name,
    persona_job: cell.persona_job,
    owner_phase: cell.owner_phase,
    coverage_status: coverage.coverage_status,
    evidence_refs: coverage.coverage_status === "covered" ? evidenceRefs : [],
    axe_violations: coverage.coverage_status === "covered" ? axeViolations : [],
    ...(coverage.reason ? { reason: coverage.reason } : {}),
    ...(coverage.defect_candidate ? { defect_candidate: coverage.defect_candidate } : {}),
    ...(extra.breakpoint ? { breakpoint: Number(extra.breakpoint) } : {}),
    ...(extra.targeted_label ? { targeted_label: extra.targeted_label } : {}),
    ...(extra.notes ? { notes: extra.notes } : {}),
    ...(surface ? { seed: surface.seed } : {}),
  };
}

async function visibleSurface(page, surface) {
  if (surface.surface_type === "page-flow") {
    return page.locator("#main-content").isVisible();
  }

  const id = surface.routeBuilder?.anchor || surface.routeBuilder?.group || slug(surface.surface);
  const candidates = [
    page.locator(`#${id}`),
    page.locator(`[data-component="${id}"]`),
    page.locator(`[data-component-group="${id}"]`),
    page.getByText(surface.surface, { exact: false }),
  ];

  for (const locator of candidates) {
    if ((await locator.count()) > 0 && (await locator.first().isVisible())) {
      return true;
    }
  }
  return false;
}

async function axeViolations(page) {
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  return results.violations.map((violation) => ({
    id: violation.id,
    impact: violation.impact,
    description: violation.description,
    nodes: violation.nodes.map((node) => ({
      target: node.target,
      failure_summary: node.failureSummary || "",
    })),
  }));
}

function evidenceRef(relativePath) {
  return path.join("accrue_admin", relativePath).split(path.sep).join("/");
}

function elapsedMs(startedAt) {
  return Math.max(0, Date.now() - startedAt);
}

function groupSurfacesByRoute(surfaces, fixtureData) {
  const groups = new Map();

  for (const surface of surfaces) {
    const route = routeForSurface(surface, fixtureData);
    if (!groups.has(route)) groups.set(route, { route, surfaces: [] });
    groups.get(route).surfaces.push(surface);
  }

  return Array.from(groups.values());
}

function baselineStateFor(projectName) {
  if (!baselineStateFor.states) baselineStateFor.states = new Map();
  if (!baselineStateFor.states.has(projectName)) {
    fs.rmSync(path.join(RESULTS_ROOT, projectName), { recursive: true, force: true });
    baselineStateFor.states.set(projectName, {
      observations: [],
      routeCount: 0,
      surfaceCount: 0,
      suiteStartedAt: Date.now(),
      failed: false,
    });
    recordBaselineProgress(projectName, {
      event: "suite-start",
      route: null,
      surface_count: 0,
      elapsed_ms: 0,
    });
  }
  return baselineStateFor.states.get(projectName);
}

function baselineStates() {
  return baselineStateFor.states || new Map();
}

function evidenceFileStem(keyParts) {
  const safeParts = keyParts.map((part) => slug(part) || "root").join("-");
  const digest = crypto.createHash("sha256").update(JSON.stringify(keyParts)).digest("hex").slice(0, 12);
  return `${safeParts.slice(0, 120)}-${digest}`;
}

async function writeSharedScreenshotEvidence(page, projectName, keyParts, options = {}) {
  const relativePath = path.join(
    RESULTS_ROOT,
    projectName,
    "evidence",
    `${evidenceFileStem(keyParts)}.png`
  );
  fs.mkdirSync(path.dirname(relativePath), { recursive: true });
  fs.writeFileSync(relativePath, await page.screenshot({ fullPage: options.fullPage ?? true }));
  return evidenceRef(relativePath);
}

function recordBaselineProgress(projectName, row) {
  const relativePath = path.join(RESULTS_ROOT, projectName, "progress.ndjson");
  fs.mkdirSync(path.dirname(relativePath), { recursive: true });
  fs.appendFileSync(
    relativePath,
    `${JSON.stringify({
      ...row,
      timestamp: row.timestamp || new Date().toISOString(),
      project: projectName,
      route: row.route ?? null,
      surface_count: Number(row.surface_count ?? 0),
      elapsed_ms: Number(row.elapsed_ms ?? 0),
    })}\n`
  );
}

function cacheKey(projectName, keyParts, options = {}) {
  return JSON.stringify([projectName, options.fullPage ?? true, ...keyParts]);
}

async function cachedScreenshotEvidence(page, projectName, evidenceState, keyParts, options = {}) {
  const key = cacheKey(projectName, keyParts, options);
  if (!evidenceState.screenshots.has(key)) {
    evidenceState.screenshots.set(
      key,
      await writeSharedScreenshotEvidence(page, projectName, keyParts, options)
    );
  }
  return evidenceState.screenshots.get(key);
}

async function cachedAxeViolations(page, projectName, evidenceState, keyParts) {
  const key = cacheKey(projectName, keyParts);
  if (!evidenceState.axe.has(key)) {
    evidenceState.axe.set(key, await axeViolations(page));
  }
  return evidenceState.axe.get(key);
}

function targetedRisk(surface) {
  return surface.surface_type === "component-group" && surface.owner_phase === "190";
}

async function captureCanonicalRouteGroup(page, routeGroup, projectName, observations, evidenceState) {
  await login(page, routeGroup.route);
  await expect(page.locator("#main-content")).toBeVisible();

  const mode = projectMode(projectName);
  const surfaceEntries = [];

  for (const surface of routeGroup.surfaces) {
    surfaceEntries.push({
      surface,
      visible: await visibleSurface(page, surface),
      cells: cellsForSurface(surface).filter((cell) => cell.mode === mode),
    });
  }

  for (const theme of THEMES) {
    const themeStartedAt = Date.now();
    recordBaselineProgress(projectName, {
      event: "theme-start",
      route: routeGroup.route,
      surface_count: routeGroup.surfaces.length,
      theme,
      elapsed_ms: 0,
    });

    try {
      await page.evaluate((value) => document.documentElement.setAttribute("data-theme", value), theme);
      await page.waitForTimeout(50);

      const hasCoveredCells = surfaceEntries.some(({ surface, visible, cells }) => {
        return cells
          .filter((cell) => cell.theme === theme)
          .some((cell) => coverageForCell(cell, surface, visible).coverage_status === "covered");
      });
      const keyParts = ["canonical", routeGroup.route, theme];
      const sharedEvidenceRef = hasCoveredCells
        ? await cachedScreenshotEvidence(page, projectName, evidenceState, keyParts)
        : null;
      const violations = hasCoveredCells
        ? await cachedAxeViolations(page, projectName, evidenceState, keyParts)
        : [];

      for (const { surface, visible, cells } of surfaceEntries) {
        const themeCells = cells.filter((cell) => cell.theme === theme);

        for (const cell of themeCells) {
          const coverage = coverageForCell(cell, surface, visible);
          observations.push(
            observationFromCell({
              cell,
              surface,
              coverage,
              evidenceRefs: coverage.coverage_status === "covered" ? [sharedEvidenceRef] : [],
              axeViolations: violations,
            })
          );
        }
      }
    } catch (error) {
      recordBaselineProgress(projectName, {
        event: "stage-error",
        stage: "theme",
        route: routeGroup.route,
        surface_count: routeGroup.surfaces.length,
        theme,
        elapsed_ms: elapsedMs(themeStartedAt),
        message: error.message,
      });
      throw error;
    }
  }
}

async function captureTargetedRouteGroup(page, routeGroup, projectName, observations, evidenceState) {
  const originalViewport = page.viewportSize();
  const mode = projectMode(projectName);
  const surfaceEntries = routeGroup.surfaces
    .filter(targetedRisk)
    .map((surface) => ({
      surface,
      cells: cellsForSurface(surface).filter(
        (cell) =>
          cell.mode === mode &&
          cell.theme === "light" &&
          cell.state === "default-populated" &&
          cell.dimension === 5
      ),
    }))
    .filter((entry) => entry.cells.length > 0);

  if (surfaceEntries.length === 0) return;

  try {
    for (const breakpoint of TARGETED_BREAKPOINTS) {
      const targetedLabel = `targeted-${breakpoint}`;
      const targetedStartedAt = Date.now();
      recordBaselineProgress(projectName, {
        event: "targeted-start",
        route: routeGroup.route,
        surface_count: surfaceEntries.length,
        breakpoint,
        targeted_label: targetedLabel,
        elapsed_ms: 0,
      });

      await page.setViewportSize({ width: breakpoint, height: 900 });
      await login(page, routeGroup.route);
      await expect(page.locator("#main-content")).toBeVisible();
      await page.evaluate(() => document.documentElement.setAttribute("data-theme", "light"));
      await page.waitForTimeout(50);

      try {
        const entries = [];
        for (const entry of surfaceEntries) {
          entries.push({
            ...entry,
            visible: await visibleSurface(page, entry.surface),
          });
        }

        const hasCoveredCells = entries.some((entry) => entry.visible);
        const keyParts = ["targeted", routeGroup.route, targetedLabel, breakpoint];
        const sharedEvidenceRef = hasCoveredCells
          ? await cachedScreenshotEvidence(page, projectName, evidenceState, keyParts, { fullPage: false })
          : null;
        const violations = hasCoveredCells
          ? await cachedAxeViolations(page, projectName, evidenceState, keyParts)
          : [];

        for (const { surface, cells, visible } of entries) {
          const coverage = visible
            ? { coverage_status: "covered" }
            : {
                coverage_status: "gap",
                reason: "Risk-marked manifest surface was not visible during targeted breakpoint probe.",
                defect_candidate: "targeted-breakpoint-coverage-gap",
              };

          for (const cell of cells) {
            observations.push(
              observationFromCell({
                cell,
                surface,
                coverage,
                evidenceRefs: coverage.coverage_status === "covered" ? [sharedEvidenceRef] : [],
                axeViolations: violations,
                extra: {
                  cell_id: `${cell.cell_id}__${targetedLabel}`,
                  mode: "targeted",
                  viewport_width: breakpoint,
                  breakpoint,
                  targeted_label: targetedLabel,
                  notes: `Risk probe for ${surface.surface}: layout-risk/responsive-risk at ${breakpoint}px.`,
                },
              })
            );
          }
        }
      } catch (error) {
        recordBaselineProgress(projectName, {
          event: "stage-error",
          stage: "targeted",
          route: routeGroup.route,
          surface_count: surfaceEntries.length,
          breakpoint,
          targeted_label: targetedLabel,
          elapsed_ms: elapsedMs(targetedStartedAt),
          message: error.message,
        });
        throw error;
      }
    }
  } finally {
    if (originalViewport) {
      await page.setViewportSize(originalViewport);
    }
  }
}

test.describe("baseline helper contracts", () => {
  test("groups selected manifest surfaces by resolved route", () => {
    const surfaces = [
      { surface: "button", surface_type: "component", routeBuilder: { anchor: "component-button" } },
      { surface: "drawer/form", surface_type: "component-group", routeBuilder: { group: "drawer-form" } },
      { surface: "invoice-detail", surface_type: "page-flow", route: "/billing/invoices/:invoice_id", routeBuilder: { fixture: "edge-states", params: ["invoice_id"] } },
      { surface: "invoices", surface_type: "page-flow", route: "/billing/invoices" },
    ];
    const fixtureData = { "edge-states": { invoice_id: "inv_test_123" } };

    expect(groupSurfacesByRoute(surfaces, fixtureData)).toEqual([
      { route: "/billing/dev/components", surfaces: [surfaces[0], surfaces[1]] },
      { route: "/billing/invoices/inv_test_123", surfaces: [surfaces[2]] },
      { route: "/billing/invoices", surfaces: [surfaces[3]] },
    ]);
  });

  test("writes shared screenshot evidence and progress rows under generated baseline output", async () => {
    const projectName = "helper-contract";
    const projectRoot = path.join(RESULTS_ROOT, projectName);
    fs.rmSync(projectRoot, { recursive: true, force: true });

    const fakePage = {
      screenshotCalls: 0,
      async screenshot() {
        this.screenshotCalls += 1;
        return Buffer.from("png");
      },
    };

    const evidenceRef = await writeSharedScreenshotEvidence(fakePage, projectName, [
      "canonical",
      "/billing/dev/components",
      "dark",
    ]);
    recordBaselineProgress(projectName, {
      event: "route-start",
      route: "/billing/dev/components",
      surface_count: 2,
      elapsed_ms: 7,
    });

    expect(fakePage.screenshotCalls).toBe(1);
    expect(evidenceRef).toMatch(
      /^accrue_admin\/test-results\/admin-baseline\/helper-contract\/evidence\/canonical-billing-dev-components-dark-[a-f0-9]{12}\.png$/
    );
    expect(JSON.parse(fs.readFileSync(path.join(projectRoot, "progress.ndjson"), "utf8"))).toMatchObject({
      event: "route-start",
      project: projectName,
      route: "/billing/dev/components",
      surface_count: 2,
      elapsed_ms: 7,
    });

    fs.rmSync(projectRoot, { recursive: true, force: true });
  });
});

async function captureBaselineRouteSet({ page, request, projectName, includeComponentKitchen }) {
  const state = baselineStateFor(projectName);

  await page.emulateMedia({ reducedMotion: "reduce" });

  const fixtureData = {
    "operator-flows": await seed(request, "operator-flows"),
    dashboard: await seed(request, "dashboard"),
    "edge-states": await seed(request, "edge-states"),
    overflow: await seed(request, "overflow"),
  };

  const selectedSurfaces = SURFACES.filter((surface) => surface.projects.includes(projectName));
  const routeGroups = groupSurfacesByRoute(selectedSurfaces, fixtureData).filter((routeGroup) =>
    includeComponentKitchen
      ? routeGroup.route === COMPONENT_KITCHEN_ROUTE
      : routeGroup.route !== COMPONENT_KITCHEN_ROUTE
  );
  const evidenceState = { screenshots: new Map(), axe: new Map() };
  state.routeCount += routeGroups.length;
  state.surfaceCount += routeGroups.reduce((count, routeGroup) => count + routeGroup.surfaces.length, 0);

  for (const routeGroup of routeGroups) {
    const routeStartedAt = Date.now();
    recordBaselineProgress(projectName, {
      event: "route-start",
      route: routeGroup.route,
      surface_count: routeGroup.surfaces.length,
      elapsed_ms: 0,
    });

    try {
      await captureCanonicalRouteGroup(page, routeGroup, projectName, state.observations, evidenceState);
      await captureTargetedRouteGroup(page, routeGroup, projectName, state.observations, evidenceState);
      recordBaselineProgress(projectName, {
        event: "route-complete",
        route: routeGroup.route,
        surface_count: routeGroup.surfaces.length,
        elapsed_ms: elapsedMs(routeStartedAt),
      });
    } catch (error) {
      state.failed = true;
      recordBaselineProgress(projectName, {
        event: "stage-error",
        stage: "route",
        route: routeGroup.route,
        surface_count: routeGroup.surfaces.length,
        elapsed_ms: elapsedMs(routeStartedAt),
        message: error.message,
      });
      throw error;
    }
  }
}

function writeBaselineResults(projectName, state) {
  if (state.failed) return;

  const outputPath = path.join(RESULTS_ROOT, projectName, "cells.json");
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(state.observations, null, 2)}\n`);

  const gaps = state.observations.filter((row) => row.coverage_status === "gap");
  const invalid = state.observations.filter((row) => {
    if (!["covered", "gap", "n/a"].includes(row.coverage_status)) return true;
    if (row.coverage_status === "covered") return row.evidence_refs.length === 0 || !Array.isArray(row.axe_violations);
    return !row.reason;
  });

  expect(invalid, "all baseline observations must carry coverage evidence or a reason").toEqual([]);
  expect(state.observations.length).toBeGreaterThan(DIMENSIONS.length);
  expect(gaps.every((gap) => gap.defect_candidate || gap.reason)).toBeTruthy();
  recordBaselineProgress(projectName, {
    event: "suite-complete",
    route: null,
    surface_count: state.surfaceCount,
    route_count: state.routeCount,
    elapsed_ms: elapsedMs(state.suiteStartedAt),
  });
}

test.describe("Admin static baseline", () => {
  test.describe.configure({ mode: "serial" });

  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("captures manifest-driven static cells for admin routes", async ({ page, request }, testInfo) => {
    await captureBaselineRouteSet({
      page,
      request,
      projectName: testInfo.project.name,
      includeComponentKitchen: false,
    });
  });

  test("captures manifest-driven static cells for the component kitchen", async ({ page, request }, testInfo) => {
    await captureBaselineRouteSet({
      page,
      request,
      projectName: testInfo.project.name,
      includeComponentKitchen: true,
    });
  });

  test.afterAll(() => {
    for (const [projectName, state] of baselineStates()) {
      writeBaselineResults(projectName, state);
    }
  });
});
