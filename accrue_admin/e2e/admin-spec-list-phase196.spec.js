/**
 * Phase 196 - SPEC-LIST and PageHeader validation scaffold.
 *
 * This is the browser contract for the Subscriptions LIST exemplar. It uses
 * the existing e2e server, reset, seed, login, and Phase 191 helper patterns.
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
        /Showing \d+ subscriptions?/
      );

      await assertColumnOrder(page, [
        "Customer details",
        "State",
        "Plan / amount",
        "Renews / ends",
        "Signals",
      ]);

      await assertTextOrder(page, "E2E Dashboard Customer", "sub_e2e_dashboard");
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

    const allChip = page.locator("[data-ax-filter-chips] a[aria-label='Apply All filter']").first();
    await expect(allChip, "All chip/link should be one action away").toBeVisible();
    await expect(allChip).toContainText("All");
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
    await expect(loading.locator(".ax-skeleton[aria-hidden='true']:visible").first(), "decorative skeleton").toBeVisible();
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
      await expect(firstCard, `${theme}: customer identity`).toContainText("E2E Dashboard Customer");
      await expect(firstCard, `${theme}: subscription identity`).toContainText("sub_e2e_dashboard");
      await expect(firstCard, `${theme}: state label`).toContainText(/Active|Trialing|At risk/);
      await expect(firstCard, `${theme}: plan amount label`).toContainText("Plan / amount");
      await expect(firstCard, `${theme}: renews label`).toContainText("Renews / ends");
      await expect(firstCard, `${theme}: signals label`).toContainText("Signals");

      await assertNoHorizontalClip(page, "#main-content, main, [data-role='card-list']", `${theme} mobile`);
    }
  });
});

test.describe("Phase 240 invoice list responsive contract", () => {
  test("keeps seeded invoice identity, exact money, status, and target reachable at width boundaries", async ({
    page,
    request,
  }) => {
    const response = await request.post("/__e2e__/reset");
    expect(response.ok()).toBeTruthy();
    const seeded = await seedScenario(request, "phase191-matrix");
    await login(page, "/billing/invoices?view=all");

    const invoiceId = seeded.phase191_invoice_id;
    const widths = [320, 600, 767, 768, 1024, 1280];
    for (const width of widths) {
      await page.setViewportSize({ width, height: 1000 });
      const item = page.locator(`[data-row-id="${invoiceId}"]:visible`).first();
      await expect(item, `invoice fixture at ${width}px`).toBeVisible();
      await expect(item, `invoice number at ${width}px`).toContainText("E2E-191-JPY-001");
      await expect(item, `customer identity at ${width}px`).toContainText(
        "E2E Phase 191 株式会社 Café Boundary Customer"
      );
      await expect(item, `exact JPY amount at ${width}px`).toContainText("100,000");
      await expect(item, `status at ${width}px`).toContainText("Open");

      const invoiceLink = item.locator(`a[href="/billing/invoices/${invoiceId}"]`).first();
      await expect(invoiceLink, `invoice target at ${width}px`).toBeVisible();
      await invoiceLink.scrollIntoViewIfNeeded();
      const geometry = await invoiceLink.evaluate((element) => {
        const rect = element.getBoundingClientRect();
        const style = getComputedStyle(element);
        return {
          width: rect.width,
          height: rect.height,
          outlineStyle: style.outlineStyle,
          outlineWidth: style.outlineWidth,
          textClientWidth: element.clientWidth,
          textScrollWidth: element.scrollWidth,
        };
      });
      expect(geometry.width, `visible target width at ${width}px`).toBeGreaterThan(0);
      expect(geometry.height, `visible target height at ${width}px`).toBeGreaterThan(0);
      expect(geometry.textScrollWidth, `identity does not clip at ${width}px`).toBeLessThanOrEqual(
        geometry.textClientWidth
      );
      await invoiceLink.focus();
      const focus = await invoiceLink.evaluate((element) => ({
        style: getComputedStyle(element).outlineStyle,
        width: getComputedStyle(element).outlineWidth,
      }));
      expect(focus.style, `visible keyboard focus at ${width}px`).not.toBe("none");
      expect(Number.parseFloat(focus.width), `focus thickness at ${width}px`).toBeGreaterThan(0);
      await assertNoHorizontalClip(page, "#main-content, main, [data-ax-list='invoices']", `invoice list ${width}px`);
    }
  });

  test("records separate CSS text-enlargement, text-spacing, and page-scale evidence", async ({ page, request }) => {
    const response = await request.post("/__e2e__/reset");
    expect(response.ok()).toBeTruthy();
    const seeded = await seedScenario(request, "phase191-matrix");
    await login(page, "/billing/invoices?view=all");
    await page.setViewportSize({ width: 320, height: 1000 });
    const item = page.locator(`[data-row-id="${seeded.phase191_invoice_id}"]:visible`).first();

    await page.evaluate(() => {
      document.documentElement.style.fontSize = "200%";
    });
    await expect(item, "CSS root-font enlargement retains invoice identity").toContainText("E2E-191-JPY-001");
    await expect(item, "CSS root-font enlargement retains exact amount").toContainText("100,000");
    await expect(item.locator(`a[href="/billing/invoices/${seeded.phase191_invoice_id}"]`).first()).toBeVisible();
    await assertNoHorizontalClip(page, "#main-content, main, [data-ax-list='invoices']", "200% CSS font-size simulation");
    await page.evaluate(() => {
      document.documentElement.style.removeProperty("font-size");
    });

    await page.evaluate(() => {
      const source = document.querySelector("style[nonce], script[nonce]");
      const style = document.createElement("style");
      style.nonce = source?.nonce || "";
      style.dataset.phase240TextSpacing = "true";
      style.textContent = `
        :where(*) { line-height: 1.5 !important; letter-spacing: .12em !important; word-spacing: .16em !important; }
        :where(p) { margin-block-end: 2em !important; }
      `;
      document.head.append(style);
    });
    await expect(item, "WCAG text-spacing CSS simulation retains identity").toContainText("E2E-191-JPY-001");
    await expect(item, "WCAG text-spacing CSS simulation retains exact amount").toContainText("100,000");
    await expect(item.locator(`a[href="/billing/invoices/${seeded.phase191_invoice_id}"]`).first()).toBeVisible();
    await assertNoHorizontalClip(page, "#main-content, main, [data-ax-list='invoices']", "text-spacing CSS simulation");

    let zoomEvidence;
    try {
      const session = await page.context().newCDPSession(page);
      await session.send("Emulation.setPageScaleFactor", { pageScaleFactor: 4 });
      zoomEvidence = await page.evaluate(() => ({
        visualScale: window.visualViewport?.scale,
        cssViewportWidth: window.innerWidth,
      }));
      await session.send("Emulation.setPageScaleFactor", { pageScaleFactor: 1 });
      await session.detach();
    } catch (error) {
      zoomEvidence = { unavailable: String(error.message || error) };
    }
    console.log(
      `Phase 240 zoom evidence: ${JSON.stringify(zoomEvidence)}; CDP page scale is pinch/visual scaling, not browser page zoom. A faithful 400% browser zoom control is unavailable in this headless Playwright run.`
    );
  });
});

test.describe("Phase 240 intermediate coarse-pointer invoice list", () => {
  test.use({ viewport: { width: 768, height: 1024 }, isMobile: true, hasTouch: true });

  test("keeps identity, money, status, and action reachable with coarse pointer", async ({ page, request }) => {
    const response = await request.post("/__e2e__/reset");
    expect(response.ok()).toBeTruthy();
    const seeded = await seedScenario(request, "phase191-matrix");
    await login(page, "/billing/invoices?view=all");
    expect(await page.evaluate(() => matchMedia("(pointer: coarse)").matches)).toBe(true);

    const item = page.locator(`[data-row-id="${seeded.phase191_invoice_id}"]:visible`).first();
    await expect(item).toContainText("E2E Phase 191 株式会社 Café Boundary Customer");
    await expect(item).toContainText("100,000");
    await expect(item).toContainText("Open");
    const action = item.locator(`a[href="/billing/invoices/${seeded.phase191_invoice_id}"]`).first();
    await expect(action).toBeVisible();
    const target = await action.evaluate((element) => {
      const rect = element.getBoundingClientRect();
      return { width: rect.width, height: rect.height };
    });
    expect(target.width, "invoice action target width at coarse pointer").toBeGreaterThan(0);
    expect(target.height, "invoice action target height at coarse pointer").toBeGreaterThanOrEqual(44);
    await assertNoHorizontalClip(page, "#main-content, main, [data-ax-list='invoices']", "768px coarse-pointer invoice list");
  });
});
