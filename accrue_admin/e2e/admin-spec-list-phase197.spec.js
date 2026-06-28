/**
 * Phase 197 - SPEC-LIST propagation validation scaffold.
 *
 * Browser contracts for the eight remaining LIST pages. These tests are RED
 * until the Phase 197 page migrations land; failures should be missing LIST
 * runtime behavior, not Playwright syntax, route, fixture, or command wiring.
 */

const { test, expect } = require("@playwright/test");

const {
  setPhase191Theme,
  assertNoHorizontalClip,
} = require("./phase191-page-flow-helpers.js");

test.use({ trace: "retain-on-failure" });

const LIST_CONTRACTS = Object.freeze([
  {
    name: "Customers",
    route: "/billing/customers",
    listId: "customers",
    resourceLabel: "customers",
    activeChip: "All customers",
    quickChip: "Missing payment method",
    defaultParams: {},
    clearAllOnDefault: false,
    loadingText: "Loading customers.",
  },
  {
    name: "Invoices",
    route: "/billing/invoices",
    listId: "invoices",
    resourceLabel: "invoices",
    activeChip: "Needs collection",
    allChip: "All invoices",
    defaultParams: { status: "open,uncollectible" },
    clearAllOnDefault: true,
    loadingText: "Loading invoices.",
  },
  {
    name: "Payments",
    route: "/billing/payments",
    listId: "payments",
    resourceLabel: "payments",
    activeChip: "Failed payments",
    allChip: "All payments",
    defaultParams: { status: "failed" },
    clearAllOnDefault: true,
    loadingText: "Loading payments.",
  },
  {
    name: "Coupons",
    route: "/billing/coupons",
    listId: "coupons",
    resourceLabel: "coupons",
    activeChip: "Valid coupons",
    allChip: "All coupons",
    defaultParams: { valid: "true" },
    clearAllOnDefault: true,
    loadingText: "Loading coupons.",
  },
  {
    name: "Promotion codes",
    route: "/billing/promotion-codes",
    listId: "promotion-codes",
    resourceLabel: "promotion codes",
    activeChip: "Active codes",
    allChip: "All promotion codes",
    defaultParams: { active: "true" },
    clearAllOnDefault: true,
    loadingText: "Loading promotion codes.",
  },
  {
    name: "Webhooks",
    route: "/billing/webhooks",
    listId: "webhooks",
    resourceLabel: "webhook deliveries",
    activeChip: "Needs replay",
    allChip: "All deliveries",
    defaultParams: { status: "failed,dead" },
    clearAllOnDefault: true,
    loadingText: "Loading webhook deliveries.",
  },
  {
    name: "Events",
    route: "/billing/events",
    listId: "events",
    resourceLabel: "billing events",
    activeChip: "All ledger",
    quickChip: "Admin changes",
    defaultParams: {},
    clearAllOnDefault: false,
    loadingText: "Loading billing events.",
  },
  {
    name: "Connect accounts",
    route: "/billing/connect",
    listId: "connect-accounts",
    resourceLabel: "connected accounts",
    activeChip: "Needs attention",
    allChip: "All accounts",
    defaultParams: { needs_attention: "true" },
    clearAllOnDefault: true,
    loadingText: "Loading connected accounts.",
  },
]);

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seedScenario(request, scenario) {
  const response = await request.post(`/__e2e__/seed/${scenario}`);
  expect(response.ok(), `seed ${scenario} should return 2xx`).toBeTruthy();
  return response.json();
}

async function seedListBaseline(request) {
  const dashboard = await seedScenario(request, "dashboard");
  const edgeStates = await seedScenario(request, "edge-states");
  const operatorFlows = await seedScenario(request, "operator-flows");

  return { dashboard, "edge-states": edgeStates, "operator-flows": operatorFlows };
}

async function login(page, target) {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}

function listLocator(page, contract) {
  return page.locator(`[data-ax-list="${contract.listId}"]`).first();
}

function targetWithQuery(route, params) {
  const search = new URLSearchParams(params);
  const query = search.toString();
  return query ? `${route}?${query}` : route;
}

function skipUnlessProject(testInfo, projectName) {
  test.skip(
    testInfo.project.name !== projectName,
    `Phase 197 contract runs this check only in ${projectName}`
  );
}

async function assertDefaultParams(page, contract, label) {
  const actual = new URL(page.url());

  for (const [key, value] of Object.entries(contract.defaultParams)) {
    expect(actual.searchParams.get(key), `${label}: default URL param ${key}`).toBe(value);
  }
}

async function assertPageHeaderContract(page, label) {
  await expect(page.locator("h1"), `${label}: exactly one h1`).toHaveCount(1);
  await expect(page.locator("[data-ax-page-header]"), `${label}: PageHeader marker`).toBeVisible();
  await expect(page.locator("[data-ax-page-title]"), `${label}: title marker`).toBeVisible();
  await expect(page.locator("[data-ax-page-filter-toolbar]"), `${label}: filter toolbar slot`).toBeVisible();
}

async function assertListChrome(page, contract, label) {
  const list = listLocator(page, contract);
  await expect(list, `${label}: list marker`).toBeVisible();
  await expect(list, `${label}: populated state`).toHaveAttribute("data-ax-state", "populated");

  const chips = page.locator("[data-ax-filter-chips]").first();
  await expect(chips, `${label}: filter chip row`).toBeVisible();
  await expect(chips, `${label}: active chip`).toContainText(contract.activeChip);

  if (contract.quickChip) {
    await expect(chips, `${label}: quick chip`).toContainText(contract.quickChip);
  }

  if (contract.allChip) {
    await expect(chips, `${label}: All escape hatch`).toContainText(contract.allChip);
  }

  await expect(page.locator("[data-ax-result-count]"), `${label}: result count`).toContainText(
    new RegExp(`Showing \\d+ ${contract.resourceLabel.replace(/\s+/g, "\\s+")}?`)
  );

  const clearAll = page.locator("[data-ax-clear-all]").first();
  if (contract.clearAllOnDefault) {
    await expect(clearAll, `${label}: clear-all`).toBeVisible();
    await expect(clearAll, `${label}: view=all escape hatch`).toHaveAttribute("href", /view=all/);
  } else {
    await expect(clearAll, `${label}: no default clear-all`).toHaveCount(0);
  }
}

async function assertDesktopListRendering(page, contract, label) {
  await expect(page.locator(".ax-data-table-shell").first(), `${label}: desktop table`).toBeVisible();
  await expect(page.locator("[data-role='card-list']").first(), `${label}: mobile cards hidden`).toBeHidden();
  await assertNoHorizontalClip(page, "#main-content, main, .ax-data-table-shell", label);
}

async function assertMobileListRendering(page, contract, label) {
  await expect(listLocator(page, contract), `${label}: mobile list marker`).toBeVisible();
  await expect(page.locator("[data-role='card-list']").first(), `${label}: mobile cards`).toBeVisible();
  await expect(page.locator(".ax-data-table-shell").first(), `${label}: desktop table hidden`).toBeHidden();
  await assertNoHorizontalClip(page, "#main-content, main, [data-role='card-list']", label);
}

test.describe("Phase 197 propagated LIST contract", () => {
  for (const contract of LIST_CONTRACTS) {
    test(`${contract.name} desktop smoke renders PageHeader, LIST chrome, chips, and count`, async ({
      page,
      request,
    }, testInfo) => {
      skipUnlessProject(testInfo, "chromium-desktop");

      await page.setViewportSize({ width: 1280, height: 900 });
      await reset(request);
      await seedListBaseline(request);
      await login(page, contract.route);
      await assertDefaultParams(page, contract, `${contract.name} default`);

      for (const theme of ["light", "dark"]) {
        await setPhase191Theme(page, theme);

        await assertPageHeaderContract(page, `${contract.name} ${theme}`);
        await assertListChrome(page, contract, `${contract.name} ${theme}`);
        await assertDesktopListRendering(page, contract, `${contract.name} ${theme}`);
      }
    });
  }

  test("mobile cards preserve LIST markers for all propagated pages", async ({ page, request }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-mobile");

    await page.setViewportSize({ width: 375, height: 844 });
    await reset(request);
    await seedListBaseline(request);

    for (const contract of LIST_CONTRACTS) {
      await login(page, contract.route);
      await assertDefaultParams(page, contract, `${contract.name} mobile default`);

      for (const theme of ["light", "dark"]) {
        await setPhase191Theme(page, theme);
        await assertPageHeaderContract(page, `${contract.name} ${theme} mobile`);
        await assertMobileListRendering(page, contract, `${contract.name} ${theme} mobile`);
      }
    }
  });

  test("customers keep the reference All default and expose the missing-payment-method lens", async ({
    page,
    request,
  }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-desktop");

    await reset(request);
    await seedScenario(request, "dashboard");
    await login(page, "/billing/customers");

    await expect(page.locator("[data-ax-filter-chips]")).toContainText("All customers");
    await expect(page.locator("[data-ax-filter-chips] a")).toContainText("Missing payment method");
    await expect(page.locator("[data-ax-clear-all]")).toHaveCount(0);
    await expect(listLocator(page, LIST_CONTRACTS[0])).toContainText("E2E Dashboard Customer");
  });

  test("invoices default queue is URL-backed and one action away from All", async ({ page, request }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-desktop");

    const invoices = LIST_CONTRACTS.find((contract) => contract.listId === "invoices");

    await reset(request);
    await seedScenario(request, "dashboard");
    await login(page, invoices.route);

    await assertDefaultParams(page, invoices, "Invoices queue");
    await expect(page.locator("[data-ax-filter-chips]")).toContainText("Needs collection");
    await expect(page.locator("[data-ax-filter-chips] a[aria-label='Apply All invoices filter']")).toHaveAttribute(
      "href",
      /\/billing\/invoices\?view=all$/
    );
    await expect(page.locator("[data-ax-clear-all]").first()).toHaveAttribute(
      "href",
      /\/billing\/invoices\?view=all$/
    );
  });

  test("webhooks replay queue preserves bulk retry controls", async ({ page, request }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-desktop");

    const webhooks = LIST_CONTRACTS.find((contract) => contract.listId === "webhooks");

    await reset(request);
    await seedScenario(request, "operator-flows");
    await login(page, targetWithQuery(webhooks.route, webhooks.defaultParams));

    await expect(page.locator("[data-ax-filter-chips]")).toContainText("Needs replay");
    await expect(listLocator(page, webhooks)).toContainText("evt_e2e_bulk");
    await expect(listLocator(page, webhooks)).toContainText("evt_e2e_single");
    await expect(page.getByRole("button", { name: /Retry selected/i })).toBeVisible();
  });

  test("events keep the full ledger default and expose the Admin changes lens", async ({
    page,
    request,
  }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-desktop");

    const events = LIST_CONTRACTS.find((contract) => contract.listId === "events");

    await reset(request);
    await seedScenario(request, "dashboard");
    await login(page, events.route);

    await expect(page.locator("[data-ax-filter-chips]")).toContainText("All ledger");
    await expect(page.locator("[data-ax-filter-chips] a")).toContainText("Admin changes");
    await expect(listLocator(page, events)).toContainText("customer.updated");
  });

  test("connect needs_attention lens matches any readiness blocker", async ({ page, request }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-desktop");

    const connect = LIST_CONTRACTS.find((contract) => contract.listId === "connect-accounts");

    await reset(request);
    await seedScenario(request, "edge-states");
    await login(page, connect.route);

    await assertDefaultParams(page, connect, "Connect attention");
    await expect(page.locator("[data-ax-filter-chips]")).toContainText("Needs attention");
    await expect(listLocator(page, connect)).toContainText("acct_e2e_edge");
  });

  test("loading fixture exposes skeleton markers and accessible status copy", async ({ page, request }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-desktop");

    await reset(request);
    await seedScenario(request, "dashboard");

    for (const contract of LIST_CONTRACTS) {
      await login(page, `${contract.route}?phase197_state=loading-skeleton`);

      const list = listLocator(page, contract);
      await expect(list, `${contract.name}: loading state`).toHaveAttribute("data-ax-state", "loading-skeleton");
      await expect(list, `${contract.name}: busy flag`).toHaveAttribute("aria-busy", "true");
      await expect(list.getByRole("status"), `${contract.name}: one loading status`).toHaveCount(1);
      await expect(list.locator(".ax-skeleton[aria-hidden='true']:visible").first()).toBeVisible();
      await expect(list).toContainText(contract.loadingText);
    }
  });
});
