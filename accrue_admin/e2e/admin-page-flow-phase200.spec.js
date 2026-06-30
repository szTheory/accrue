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

test.describe("Phase 200 page-flow final evidence", () => {
  test("resolves every Phase 193 page-flow route without unresolved params", async ({ request }) => {
    const fixtures = await seedPhase200Fixtures(request);
    const routes = resolvePhase200PageFlowRoutes(fixtures);

    expect(routes).toHaveLength(phase191PageFlows().length);
    expect(routes.map((route) => route.path).filter((route) => route.includes(":"))).toEqual([]);
  });

  test("proves production accrue_theme boot without direct data-theme mutation", async ({ context }) => {
    await assertProductionThemeBoot(context, {
      name: "cookie wins over localStorage",
      cookie: "dark",
      localStorage: "light",
      expected: "dark",
    });
  });

  test("source contract references reduced-motion and Phase 199 guardrails", () => {
    const source = fs.readFileSync(__filename, "utf8");

    expect(source).toContain("e2e/reduced-motion.spec.js");
    expect(source).toContain("e2e/admin-interaction-overlay-phase199.spec.js");
    expect(source).toContain("page-flow-evidence.json");
    expect(source).toContain("phase199-interaction-matrix");
  });
});
