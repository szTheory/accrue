const fs = require("fs");
const path = require("path");

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
    cell_id: cell.cell_id,
    surface: cell.surface,
    surface_type: cell.surface_type,
    mode: cell.mode,
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

async function writeScreenshotCopies(page, projectName, cells) {
  const buffer = await page.screenshot({ fullPage: true });
  const evidenceRefs = [];

  for (const cell of cells) {
    const relativePath = path.join(RESULTS_ROOT, projectName, `${cell.cell_id}.png`);
    fs.mkdirSync(path.dirname(relativePath), { recursive: true });
    fs.writeFileSync(relativePath, buffer);
    evidenceRefs.push(path.join("accrue_admin", relativePath).split(path.sep).join("/"));
  }

  return evidenceRefs;
}

async function captureCanonicalSurface(page, surface, route, projectName, observations) {
  await login(page, route);
  await expect(page.locator("#main-content")).toBeVisible();

  const visible = await visibleSurface(page, surface);
  const cells = cellsForSurface(surface).filter((cell) => cell.mode === projectMode(projectName));

  for (const theme of THEMES) {
    await page.evaluate((value) => document.documentElement.setAttribute("data-theme", value), theme);
    await page.waitForTimeout(50);

    const themeCells = cells.filter((cell) => cell.theme === theme);
    const coveredCells = themeCells.filter((cell) => coverageForCell(cell, surface, visible).coverage_status === "covered");
    const evidenceRefs = await writeScreenshotCopies(page, projectName, coveredCells);
    const violations = visible ? await axeViolations(page) : [];

    for (const cell of themeCells) {
      const coverage = coverageForCell(cell, surface, visible);
      observations.push(
        observationFromCell({
          cell,
          surface,
          coverage,
          evidenceRefs: evidenceRefs.filter((ref) => ref.endsWith(`${cell.cell_id}.png`)),
          axeViolations: violations,
        })
      );
    }
  }
}

test.describe("Admin static baseline", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("captures manifest-driven static cells", async ({ page, request }, testInfo) => {
    test.setTimeout(240_000);
    await page.emulateMedia({ reducedMotion: "reduce" });

    const fixtureData = {
      "operator-flows": await seed(request, "operator-flows"),
      dashboard: await seed(request, "dashboard"),
      "edge-states": await seed(request, "edge-states"),
      overflow: await seed(request, "overflow"),
    };

    const projectName = testInfo.project.name;
    const observations = [];
    const selectedSurfaces = SURFACES.filter((surface) => surface.projects.includes(projectName));

    for (const surface of selectedSurfaces) {
      const route = routeForSurface(surface, fixtureData);
      await captureCanonicalSurface(page, surface, route, projectName, observations);
    }

    const outputPath = path.join(RESULTS_ROOT, projectName, "cells.json");
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, `${JSON.stringify(observations, null, 2)}\n`);

    const gaps = observations.filter((row) => row.coverage_status === "gap");
    const invalid = observations.filter((row) => {
      if (!["covered", "gap", "n/a"].includes(row.coverage_status)) return true;
      if (row.coverage_status === "covered") return row.evidence_refs.length === 0 || !Array.isArray(row.axe_violations);
      return !row.reason;
    });

    expect(invalid, "all baseline observations must carry coverage evidence or a reason").toEqual([]);
    expect(observations.length).toBeGreaterThan(DIMENSIONS.length);
    expect(gaps.every((gap) => gap.defect_candidate || gap.reason)).toBeTruthy();
  });
});
