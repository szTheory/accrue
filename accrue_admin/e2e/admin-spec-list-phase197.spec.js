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
    chips: ["All customers", "Missing default method"],
    defaultParams: {},
    resetOnDefault: false,
    loadingText: "Loading customers.",
  },
  {
    name: "Invoices",
    route: "/billing/invoices",
    listId: "invoices",
    resourceLabel: "invoices",
    viewNav: ["Needs collection", "All invoices"],
    defaultParams: { status: "open,uncollectible" },
    resetOnDefault: false,
    loadingText: "Loading invoices.",
  },
  {
    name: "Payments",
    route: "/billing/payments",
    listId: "payments",
    resourceLabel: "payments",
    viewNav: ["Failed payments", "All payments"],
    defaultParams: { status: "failed" },
    rowParams: { view: "all" },
    mobileParams: { view: "all" },
    allowQueueEmpty: true,
    queueEmptyText: "No failed payments.",
    resetOnDefault: false,
    loadingText: "Loading payments.",
  },
  {
    name: "Coupons",
    route: "/billing/coupons",
    listId: "coupons",
    resourceLabel: "coupons",
    // The default validity is carried by the toolbar's segmented control, not a chip.
    defaultParams: { valid: "true" },
    resetOnDefault: true,
    loadingText: "Loading coupons.",
  },
  {
    name: "Promotion codes",
    route: "/billing/promotion-codes",
    listId: "promotion-codes",
    resourceLabel: "promotion codes",
    chips: ["Active codes", "All promotion codes"],
    defaultParams: { active: "true" },
    resetOnDefault: true,
    loadingText: "Loading promotion codes.",
  },
  {
    name: "Webhooks",
    route: "/billing/webhooks",
    listId: "webhooks",
    resourceLabel: "webhook deliveries",
    chips: ["Needs replay", "All deliveries"],
    defaultParams: { status: "failed,dead" },
    resetOnDefault: false,
    loadingText: "Loading webhook deliveries.",
  },
  {
    name: "Events",
    route: "/billing/events",
    listId: "events",
    resourceLabel: "events",
    resultLabelPattern: /Showing \d+ (billing\s+)?events?/,
    chips: ["All events", "Admin actions"],
    defaultParams: {},
    resetOnDefault: false,
    loadingText: "Loading billing events.",
  },
  {
    name: "Connect accounts",
    route: "/billing/connect",
    listId: "connect-accounts",
    resourceLabel: "connected accounts",
    chips: ["Needs attention", "All accounts"],
    defaultParams: { needs_attention: "true" },
    rowParams: { view: "all" },
    mobileParams: { view: "all" },
    allowQueueEmpty: true,
    queueEmptyText: "No connected accounts need attention.",
    resetOnDefault: true,
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
  const entries = Object.entries(contract.defaultParams);

  for (const [key, value] of entries) {
    await expect
      .poll(() => new URL(page.url()).searchParams.get(key), {
        message: `${label}: default URL param ${key}`,
      })
      .toBe(value);
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
  const listState = await list.getAttribute("data-ax-state");

  if (listState !== "populated") {
    expect(
      contract.allowQueueEmpty && listState === "filtered-empty",
      `${label}: default queue may be empty only when contract allows it`
    ).toBeTruthy();
    await expect(list, `${label}: queue empty reason`).toHaveAttribute("data-ax-empty-reason", "queue");
    await expect(list, `${label}: queue empty copy`).toContainText(contract.queueEmptyText);
  }

  // 66d5b3ce/b4a7eeac: list views are either a "view" nav (invoices, payments) or
  // the shared chip row (applied filters plus an All escape hatch).
  if (contract.viewNav) {
    const viewNav = page.locator("[data-ax-view-nav]").first();
    await expect(viewNav, `${label}: view nav`).toBeVisible();
    await expect(viewNav.locator("a").first(), `${label}: default view is current`).toHaveAttribute(
      "aria-current",
      "page"
    );
    for (const view of contract.viewNav) {
      await expect(viewNav, `${label}: view ${view}`).toContainText(view);
    }
  }

  if (contract.chips) {
    const chips = page.locator("[data-ax-filter-chips]").first();
    await expect(chips, `${label}: filter chip row`).toBeVisible();
    for (const chip of contract.chips) {
      await expect(chips, `${label}: chip ${chip}`).toContainText(chip);
    }
  }

  const resultLabelPattern =
    contract.resultLabelPattern ||
    new RegExp(`Showing \\d+ ${contract.resourceLabel.replace(/\s+/g, "\\s+")}?`);
  await expect(page.locator("[data-ax-result-count]"), `${label}: result count`).toContainText(resultLabelPattern);

  // One toolbar "Reset filters" restores the page default (it does not target view=all);
  // pages whose default is already unfiltered or hides a no-op reset render none.
  const reset = page.locator("[data-ax-clear-all]").first();
  if (contract.resetOnDefault) {
    await expect(reset, `${label}: reset filters`).toBeVisible();
    await expect(reset, `${label}: reset returns to the page default`).toHaveAttribute(
      "href",
      new RegExp(`${contract.route}$`)
    );
  } else {
    await expect(reset, `${label}: no default reset`).toHaveCount(0);
  }

  return listState;
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
      for (const theme of ["light", "dark"]) {
        await login(page, contract.route);
        await assertDefaultParams(page, contract, `${contract.name} default`);
        await setPhase191Theme(page, theme);

        await assertPageHeaderContract(page, `${contract.name} ${theme}`);
        const state = await assertListChrome(page, contract, `${contract.name} ${theme}`);

        if (state === "populated") {
          await assertDesktopListRendering(page, contract, `${contract.name} ${theme}`);
        } else {
          await assertNoHorizontalClip(page, "#main-content, main, [data-role='empty-state']", `${contract.name} ${theme} empty`);
        }

        if (contract.rowParams) {
          await login(page, targetWithQuery(contract.route, contract.rowParams));
          await setPhase191Theme(page, theme);
          await assertPageHeaderContract(page, `${contract.name} ${theme} row route`);
          await assertDesktopListRendering(page, contract, `${contract.name} ${theme} row route`);
        }
      }
    });
  }

  test("mobile cards preserve LIST markers for all propagated pages", async ({ page, request }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-mobile");

    await page.setViewportSize({ width: 375, height: 844 });
    await reset(request);
    await seedListBaseline(request);

    for (const contract of LIST_CONTRACTS) {
      const mobileParams = contract.mobileParams || {};
      await login(page, targetWithQuery(contract.route, mobileParams));

      if (contract.mobileParams) {
        await assertDefaultParams(page, { defaultParams: contract.mobileParams }, `${contract.name} mobile row route`);
      } else {
        await assertDefaultParams(page, contract, `${contract.name} mobile default`);
      }

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
    await expect(page.locator("[data-ax-filter-chips] a")).toContainText("Missing default method");
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
    const viewNav = page.locator("[data-ax-view-nav]").first();
    await expect(viewNav.getByRole("link", { name: "Needs collection" })).toHaveAttribute("aria-current", "page");
    await expect(viewNav.getByRole("link", { name: "All invoices" })).toHaveAttribute(
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
    await page.locator('[data-role="toggle-all"]').click();
    await expect(page.locator('[data-role="bulk-action"]')).toBeVisible();
    await page.locator('[data-role="bulk-action"]').click();
    await expect(page.locator('[data-role="bulk-replay-confirm"]')).toBeVisible();
    await expect(page.locator('[data-role="confirm-retry-selected"]')).toBeVisible();
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

    await expect(page.locator("[data-ax-filter-chips]")).toContainText("All events");
    await expect(page.locator("[data-ax-filter-chips] a")).toContainText("Admin actions");
    await expect(listLocator(page, events)).toContainText("Customer updated"); // 66d5b3ce: known event keys render as labels
  });

  test("connect needs_attention lens matches any readiness blocker", async ({ page, request }, testInfo) => {
    skipUnlessProject(testInfo, "chromium-desktop");

    const connect = LIST_CONTRACTS.find((contract) => contract.listId === "connect-accounts");

    await reset(request);
    await seedScenario(request, "phase191-matrix");
    await login(page, connect.route);

    await assertDefaultParams(page, connect, "Connect attention");
    await expect(page.locator("[data-ax-filter-chips]")).toContainText("Needs attention");
    await expect(listLocator(page, connect)).toContainText("acct_e2e_phase191");
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
