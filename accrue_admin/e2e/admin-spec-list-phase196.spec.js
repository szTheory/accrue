/**
 * Phase 196 - SPEC-LIST and PageHeader validation scaffold.
 *
 * This is a RED contract for the Subscriptions LIST exemplar. It uses the
 * existing e2e server, reset, seed, login, and Phase 191 helper patterns.
 */

const { test, expect } = require("@playwright/test");

const {
  setPhase191Theme,
  assertNoHorizontalClip,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seedScenario(request, scenario) {
  const response = await request.post(`/__e2e__/seed/${scenario}`);
  expect(response.ok(), `seed ${scenario} should return 2xx`).toBeTruthy();
  return response.json();
}

async function login(page, target = "/billing/subscriptions") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}

function subscriptionsList(page) {
  return page.locator('[data-ax-list="subscriptions"]').first();
}

async function assertPageHeaderContract(page, label) {
  await expect(page.locator("h1"), `${label}: exactly one h1`).toHaveCount(1);
  await expect(page.locator("[data-ax-page-header]"), `${label}: PageHeader marker`).toBeVisible();
  await expect(page.locator("[data-ax-page-title]"), `${label}: title marker`).toBeVisible();
  await expect(
    page.locator('[data-component-group="page-header-actions-breadcrumbs"]'),
    `${label}: component group marker`
  ).toBeVisible();
  await expect(page.locator("[data-ax-page-filter-toolbar]"), `${label}: filter toolbar slot`).toBeVisible();
  await expect(page.locator("[data-ax-page-actions]"), `${label}: actions slot`).toBeVisible();
}

async function assertColumnOrder(page, labels) {
  const text = await page.locator("th").evaluateAll((nodes) =>
    nodes.map((node) => node.textContent || "").join(" ")
  );

  const missing = labels.filter((label) => !text.includes(label));
  expect(missing, `missing LIST columns in ${JSON.stringify(text)}`).toEqual([]);

  const positions = labels.map((label) => [label, text.indexOf(label)]);
  for (let index = 0; index < positions.length - 1; index += 1) {
    expect(
      positions[index][1],
      `${positions[index][0]} should render before ${positions[index + 1][0]}`
    ).toBeLessThan(positions[index + 1][1]);
  }
}

async function assertTextOrder(page, left, right) {
  const text = await page.locator("body").innerText();
  expect(text, `${left} should be present`).toContain(left);
  expect(text, `${right} should be present`).toContain(right);
  expect(text.indexOf(left), `${left} should render before ${right}`).toBeLessThan(text.indexOf(right));
}

test.describe("Phase 196 Subscriptions LIST contract", () => {
  test("desktop LIST contract renders PageHeader, chips, count, and prioritized columns", async ({
    page,
    request,
  }) => {
    await reset(request);
    await seedScenario(request, "dashboard");
    await login(page, "/billing/subscriptions?view=all");

    for (const theme of ["light", "dark"]) {
      await setPhase191Theme(page, theme);

      await assertPageHeaderContract(page, `${theme} desktop`);

      const list = subscriptionsList(page);
      await expect(list, `${theme}: subscriptions list marker`).toBeVisible();
      await expect(list, `${theme}: populated state`).toHaveAttribute("data-ax-state", "populated");

      await expect(page.locator("[data-ax-filter-chips]"), `${theme}: chip row`).toBeVisible();
      await expect(page.locator("[data-ax-result-count]"), `${theme}: result count`).toContainText(
        /Showing \d+ subscriptions/
      );
      await expect(page.locator("[data-ax-clear-all]"), `${theme}: clear-all affordance`).toBeVisible();

      await assertColumnOrder(page, [
        "Customer / subscription",
        "State",
        "Plan / amount",
        "Renews / ends",
        "Signals",
      ]);

      await assertTextOrder(page, "dashboard-e2e@example.com", "sub_e2e_dashboard");
      await assertNoHorizontalClip(page, "#main-content, main, [data-ax-list='subscriptions']", `${theme} desktop`);
    }
  });

  test("default At risk queue is URL-backed with an All escape hatch", async ({ page, request }) => {
    await reset(request);
    await seedScenario(request, "edge-states");
    await login(page, "/billing/subscriptions");

    await expect(page, "bare route should patch to the default queue").toHaveURL(
      /\/billing\/subscriptions\?status=past_due%2Ccanceling$/
    );

    await expect(page.locator("form[phx-change='data_table_filter'][phx-submit='data_table_filter']")).toBeVisible();
    await expect(page.locator("[data-ax-filter-chips]")).toContainText("At risk");

    const allChip = page.getByRole("link", { name: /^All$/ }).first();
    await expect(allChip, "All chip/link should be one action away").toBeVisible();
    await expect(allChip).toHaveAttribute("href", /\/billing\/subscriptions\?view=all$/);

    const clearAll = page.locator("[data-ax-clear-all]").first();
    await expect(clearAll, "clear-all should target the view=all escape hatch").toBeVisible();
    await expect(clearAll).toHaveAttribute("href", /\/billing\/subscriptions\?view=all$/);
  });

  test("empty and loading states expose exact markers, reasons, copy, and skeleton accessibility", async ({
    page,
    request,
  }) => {
    const cases = [
      {
        name: "first-run empty",
        seed: null,
        route: "/billing/subscriptions?view=all",
        state: "first-run-empty",
        reason: "first-run",
        title: "No subscriptions yet.",
        body: "Subscriptions appear after a customer completes checkout.",
        clearAll: false,
      },
      {
        name: "filtered empty",
        seed: "dashboard",
        route: "/billing/subscriptions?view=all&q=___phase196_no_match___",
        state: "filtered-empty",
        reason: "filter",
        title: "No subscriptions match these filters.",
        body: "Clear filters or adjust the search to see subscriptions.",
        clearAll: true,
      },
      {
        name: "queue empty",
        seed: "dashboard",
        route: "/billing/subscriptions?status=past_due,canceling",
        state: "filtered-empty",
        reason: "queue",
        title: "Nothing at risk.",
        body: "View All to see every subscription.",
        clearAll: true,
      },
    ];

    for (const contract of cases) {
      await reset(request);
      if (contract.seed) await seedScenario(request, contract.seed);
      await login(page, contract.route);

      const list = subscriptionsList(page);
      await expect(list, contract.name).toHaveAttribute("data-ax-state", contract.state);
      await expect(list, contract.name).toHaveAttribute("data-ax-empty-reason", contract.reason);
      await expect(list, contract.name).toContainText(contract.title);
      await expect(list, contract.name).toContainText(contract.body);

      if (contract.clearAll) {
        await expect(page.locator("[data-ax-clear-all]"), `${contract.name}: clear-all`).toBeVisible();
      } else {
        await expect(page.locator("[data-ax-clear-all]"), `${contract.name}: no clear-all`).toHaveCount(0);
      }
    }

    await reset(request);
    await seedScenario(request, "dashboard");
    await login(page, "/billing/subscriptions?phase196_state=loading-skeleton");

    const loading = subscriptionsList(page);
    await expect(loading, "loading skeleton state").toHaveAttribute("data-ax-state", "loading-skeleton");
    await expect(loading, "loading list should be busy").toHaveAttribute("aria-busy", "true");
    await expect(loading.getByRole("status"), "one loading status").toHaveCount(1);
    await expect(loading.locator(".ax-skeleton[aria-hidden='true']").first(), "decorative skeleton").toBeVisible();
    await expect(loading).toContainText("Loading subscriptions.");
  });

  test("mobile cards preserve LIST priority without horizontal clipping", async ({ page, request }) => {
    await page.setViewportSize({ width: 375, height: 844 });
    await reset(request);
    await seedScenario(request, "dashboard");
    await login(page, "/billing/subscriptions?view=all");

    for (const theme of ["light", "dark"]) {
      await setPhase191Theme(page, theme);

      const list = subscriptionsList(page);
      await expect(list, `${theme}: mobile list marker`).toHaveAttribute("data-ax-state", "populated");
      await expect(page.locator("[data-role='card-list']").first(), `${theme}: mobile cards`).toBeVisible();
      await expect(page.locator(".ax-data-table-shell").first(), `${theme}: desktop table hidden`).toBeHidden();

      const firstCard = page.locator("[data-role='card-list'] article").first();
      await expect(firstCard, `${theme}: customer identity`).toContainText("dashboard-e2e@example.com");
      await expect(firstCard, `${theme}: state label`).toContainText(/Active|Trialing|At risk/);
      await expect(firstCard, `${theme}: plan amount label`).toContainText("Plan / amount");
      await expect(firstCard, `${theme}: renews label`).toContainText("Renews / ends");
      await expect(firstCard, `${theme}: signals label`).toContainText("Signals");

      await assertNoHorizontalClip(page, "#main-content, main, [data-role='card-list']", `${theme} mobile`);
    }
  });
});
