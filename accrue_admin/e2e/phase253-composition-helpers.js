const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { isDeepStrictEqual } = require("node:util");
const { expect } = require("@playwright/test");

const REPO_ROOT = path.resolve(__dirname, "..", "..");
const ADMIN_ROOT = path.join(REPO_ROOT, "accrue_admin");
const MANIFEST_PATH = path.join(ADMIN_ROOT, "tmp", "phase253", "manifest.json");
const RESULT_ROOT = path.join(ADMIN_ROOT, "tmp", "phase253");
const RUN_ID = process.env.PHASE252_E2E_NONCE;
const COLLECTION_STATES = Object.freeze([
  "new_host_empty",
  "filtered_empty",
  "queue_empty",
  "one_row",
  "multiple_rows",
  "page_boundary",
  "loading",
  "unavailable",
  "partial_cursor_error",
  "incomplete_projection",
]);
const WIDTHS = Object.freeze([320, 1280]);
const THEMES = Object.freeze(["light", "dark"]);
const PAGE_DETAIL_VARIATIONS = Object.freeze(["active", "scheduled_cancellation", "incomplete_evidence"]);
const PAGE_OVERLAY_VARIATIONS = Object.freeze([
  "review_cancel_now",
  "awaiting_step_up",
  "dispatching",
  "result_confirmed",
  "result_pending",
  "result_failed",
]);
const EXPECTED_COLLECTION_FACT_KEYS = Object.freeze([
  "amount_state",
  "customer_email",
  "customer_name",
  "owner_slug",
  "plan_price_id",
  "plan_quantity",
  "processor_id",
  "status",
  "subscription_id",
]);
const PAGE_VARIATIONS = Object.freeze([...PAGE_DETAIL_VARIATIONS, ...PAGE_OVERLAY_VARIATIONS]);
const PAGE_WIDTHS = Object.freeze([
  { kind: "viewport", width: 320, viewportWidth: 320, containerWidth: null },
  { kind: "viewport", width: 1280, viewportWidth: 1280, containerWidth: null },
  { kind: "breakpoint", width: 767, viewportWidth: 767, containerWidth: null },
  { kind: "breakpoint", width: 768, viewportWidth: 768, containerWidth: null },
  { kind: "container", width: 640, viewportWidth: 1280, containerWidth: 640 },
]);
const GEOMETRY_NEGATIVE_CONTROL_TITLE = "geometry controls detect hidden essential content and page overflow";
const BROWSER_RECONCILIATION_TITLE = "reconciles every compiled collection and whole-page cell against this run and served assets";
const collectionSyntheticTitle = (theme) => `synthetic long text and markup-like filter remain safe at 320px | ${theme}`;
const ASSET_PATHS = Object.freeze([
  "accrue_admin/assets/css/app.css",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/storybook.css",
  "accrue_admin/priv/static/storybook.js",
]);

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function fileDigest(relativePath) {
  return sha256(fs.readFileSync(path.join(REPO_ROOT, relativePath)));
}

function readPhase253Manifest() {
  if (!RUN_ID || !/^[a-f0-9]{24,64}$/i.test(RUN_ID)) {
    throw new Error("Phase 253 browser run has no owned launcher identity");
  }

  const raw = fs.readFileSync(MANIFEST_PATH);
  const manifest = JSON.parse(raw.toString("utf8"));
  if (manifest.schema_version !== 1 || manifest.human_judgment !== false) {
    throw new Error("Phase 253 manifest has an unsupported schema or judgment mode");
  }
  if (!Array.isArray(manifest.collection_variations) || manifest.collection_variations.length === 0) {
    throw new Error("Phase 253 manifest has no compiled collection variation inventory");
  }

  for (const [relativePath, expectedDigest] of Object.entries(manifest.source_digests || {})) {
    if (fileDigest(relativePath) !== expectedDigest) {
      throw new Error(`Phase 253 compiled source digest is stale: ${relativePath}`);
    }
  }

  const ids = manifest.collection_variations.map((entry) => entry.variation_id);
  if (ids.some((id) => typeof id !== "string" || id.length === 0) || new Set(ids).size !== ids.length) {
    throw new Error("Phase 253 compiled collection variation IDs must be non-empty and unique");
  }
  for (const entry of manifest.collection_variations) {
    if (entry.story_path !== "/groups/subscriptions_collection" ||
        entry.variation_id !== entry.collection_state ||
        entry.transport_kind !== "live_component" ||
        entry.production_renderer !== "AccrueAdmin.Live.SubscriptionsLive.subscriptions_collection/1" ||
        entry.fact_source !== `CadenceSubscriptionFacts.fetch!(:${entry.scenario_id})` ||
        !entry.expected || typeof entry.expected !== "object" || Array.isArray(entry.expected) ||
        JSON.stringify(Object.keys(entry.expected).sort()) !== JSON.stringify(EXPECTED_COLLECTION_FACT_KEYS) ||
        entry.proof_lane !== "presentation-only" ||
        entry.direct_path !== `/billing/dev/storybook/groups/subscriptions_collection?variation_id=${entry.variation_id}` ||
        entry.iframe_path !== `/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=${entry.variation_id}`) {
      throw new Error(`Phase 253 compiled collection attribution is incomplete: ${entry.variation_id}`);
    }
  }

  const declared = [...ids].sort();
  if (JSON.stringify(declared) !== JSON.stringify([...COLLECTION_STATES].sort())) {
    throw new Error("Phase 253 compiled collection inventory differs from the ten supported production states");
  }

  const pageEntries = manifest.page_entries;
  if (!Array.isArray(pageEntries) || pageEntries.length !== PAGE_VARIATIONS.length) {
    throw new Error("Phase 253 compiled whole-page manifest has an incomplete variation inventory");
  }
  const pageIds = pageEntries.map((entry) => entry.variation_id);
  if (JSON.stringify([...pageIds].sort()) !== JSON.stringify([...PAGE_VARIATIONS].sort())) {
    throw new Error("Phase 253 compiled whole-page inventory differs from its supported production states");
  }
  for (const entry of pageEntries) {
    if (entry.story_path !== "/pages/subscription" ||
        entry.transport_kind !== "page_story" ||
        entry.route_parameter !== "tab" ||
        entry.production_renderer !== "AccrueAdmin.Live.SubscriptionLive.subscription_page/1" ||
        entry.fact_source !== `CadenceSubscriptionFacts.fetch!(:${entry.expected?.scenario})` ||
        entry.proof_lane !== "presentation-only" ||
        entry.direct_path !== `/billing/dev/storybook/pages/subscription?tab=${entry.variation_id}` ||
        entry.expected?.snapshot !== entry.presentation_snapshot) {
      throw new Error(`Phase 253 compiled whole-page attribution is incomplete: ${entry.variation_id}`);
    }
  }

  return { manifest, manifestDigest: sha256(raw), runId: RUN_ID };
}

function createCollectionCases(manifest) {
  const variations = manifest.collection_variations;
  const cases = [];
  for (const entry of variations) {
    for (const width of WIDTHS) {
      for (const theme of THEMES) {
        cases.push({
          entry,
          kind: "viewport",
          width,
          viewportWidth: width,
          containerWidth: null,
          theme,
          key: `${entry.variation_id}::viewport::${width}::${theme}`,
          title: `${entry.variation_id} | viewport | ${width}px | ${theme}`,
        });
      }
    }
  }

  for (const variationId of ["one_row", "filtered_empty"]) {
    const entry = variations.find((candidate) => candidate.variation_id === variationId);
    if (!entry) throw new Error(`Phase 253 compiled collection is missing ${variationId}`);
    for (const width of [767, 768]) {
      for (const theme of THEMES) {
        cases.push({
          entry,
          kind: "breakpoint",
          width,
          viewportWidth: width,
          containerWidth: null,
          theme,
          key: `${variationId}::breakpoint::${width}::${theme}`,
          title: `${variationId} | breakpoint edge | ${width}px | ${theme}`,
        });
      }
    }
    for (const theme of THEMES) {
      cases.push({
        entry,
        kind: "container",
        width: 640,
        viewportWidth: 1280,
        containerWidth: 640,
        theme,
        key: `${variationId}::container::640::${theme}`,
        title: `${variationId} | constrained 640px content | ${theme}`,
      });
    }
  }
  return cases;
}

function createPageCases(manifest) {
  const cases = [];
  for (const variationId of PAGE_VARIATIONS) {
    const entry = manifest.page_entries.find((candidate) => candidate.variation_id === variationId);
    if (!entry) throw new Error(`Phase 253 compiled whole-page manifest is missing ${variationId}`);
    for (const dimension of PAGE_WIDTHS) {
      for (const theme of THEMES) {
        cases.push({
          entry,
          pageRole: PAGE_DETAIL_VARIATIONS.includes(variationId) ? "detail" : "overlay_result",
          kind: dimension.kind,
          width: dimension.width,
          viewportWidth: dimension.viewportWidth,
          containerWidth: dimension.containerWidth,
          theme,
          key: `page::${variationId}::${dimension.kind}::${dimension.width}::${theme}`,
          title: `${variationId} | ${dimension.kind} | ${dimension.width}px | ${theme}`,
        });
      }
    }
  }
  return cases;
}

function createPageStressCases(manifest) {
  return [
    ["active", "return"],
    ["review_cancel_now", "consequence"],
    ["awaiting_step_up", "recovery"],
  ].flatMap(([variationId, stressKind]) => {
    const entry = manifest.page_entries.find((candidate) => candidate.variation_id === variationId);
    if (!entry) throw new Error(`Phase 253 compiled whole-page manifest is missing ${variationId}`);
    return THEMES.map((theme) => ({
      entry,
      pageRole: PAGE_DETAIL_VARIATIONS.includes(variationId) ? "detail" : "overlay_result",
      kind: "synthetic",
      stressKind,
      width: 320,
      viewportWidth: 320,
      containerWidth: null,
      theme,
      key: `page::${variationId}::synthetic-${stressKind}::320::${theme}`,
      title: `${variationId} | synthetic ${stressKind} text stress | 320px | ${theme}`,
    }));
  });
}

function collectionSourceIdentity(entry) {
  return {
    story_path: entry.story_path,
    renderer: entry.production_renderer,
    fact_source: entry.fact_source,
    proof_lane: entry.proof_lane,
    expected_facts: entry.expected,
  };
}

function expectedPageFacts(entry) {
  return {
    story_path: entry.story_path,
    renderer: entry.production_renderer,
    fact_source: entry.fact_source,
    proof_lane: entry.proof_lane,
    presentation_snapshot: entry.presentation_snapshot,
    expected_facts: entry.expected,
  };
}

function collectionCellDefinition(testCase) {
  const { entry } = testCase;
  return {
    key: testCase.key,
    case_kind: testCase.kind,
    executed_test: testCase.title,
    variation_id: entry.variation_id,
    scenario_id: entry.scenario_id,
    width: testCase.width,
    viewport: { width: testCase.viewportWidth, container_width: testCase.containerWidth },
    theme: testCase.theme,
    url: entry.iframe_path,
    source_identity: collectionSourceIdentity(entry),
  };
}

function pageCellDefinition(testCase) {
  const { entry } = testCase;
  const synthetic = testCase.kind === "synthetic";
  return {
    key: testCase.key,
    case_kind: synthetic ? "page_synthetic_text_stress" : "page_composition",
    executed_test: testCase.title,
    variation_id: entry.variation_id,
    scenario_id: entry.expected.scenario,
    snapshot: entry.presentation_snapshot,
    width: testCase.width,
    viewport: { width: testCase.viewportWidth, container_width: testCase.containerWidth },
    theme: testCase.theme,
    url: entry.direct_path,
    source_identity: expectedPageFacts(entry),
  };
}

function createExpectedBrowserCellDefinitions(manifest) {
  const oneRow = manifest.collection_variations.find((entry) => entry.variation_id === "one_row");
  if (!oneRow) throw new Error("Phase 253 compiled collection is missing one_row");

  const collection = createCollectionCases(manifest).map(collectionCellDefinition);
  const collectionStress = ["light", "dark"].map((theme) => ({
    key: `one_row::synthetic-text::320::${theme}`,
    case_kind: "synthetic_text_stress",
    executed_test: collectionSyntheticTitle(theme),
    variation_id: oneRow.variation_id,
    scenario_id: oneRow.scenario_id,
    width: 320,
    viewport: { width: 320, container_width: null },
    theme,
    url: oneRow.iframe_path,
    source_identity: collectionSourceIdentity(oneRow),
  }));
  const geometry = [{
    key: "geometry::negative-controls::320::light",
    case_kind: "geometry_negative_controls",
    executed_test: GEOMETRY_NEGATIVE_CONTROL_TITLE,
    variation_id: oneRow.variation_id,
    scenario_id: oneRow.scenario_id,
    width: 320,
    viewport: { width: 320, container_width: null },
    theme: "light",
    url: oneRow.iframe_path,
    source_identity: collectionSourceIdentity(oneRow),
  }];
  return [
    ...collection,
    ...collectionStress,
    ...geometry,
    ...createPageCases(manifest).map(pageCellDefinition),
    ...createPageStressCases(manifest).map(pageCellDefinition),
  ];
}

function matchesExpectedBrowserCell(row, definition) {
  if (!row || !definition || row.key !== definition.key || row.case_kind !== definition.case_kind) return false;
  return [
    "executed_test",
    "variation_id",
    "scenario_id",
    "snapshot",
    "width",
    "viewport",
    "theme",
    "url",
    "source_identity",
  ].every((field) => !Object.hasOwn(definition, field) || isDeepStrictEqual(row[field], definition[field]));
}

function resultPath(runId) {
  return path.join(RESULT_ROOT, `render-results-${runId}.json`);
}

function currentSourceAndAssetDigests(manifest) {
  const digests = { ...manifest.source_digests };
  for (const relativePath of ASSET_PATHS) digests[relativePath] = fileDigest(relativePath);
  return digests;
}

function writeResults(filePath, results) {
  const temporaryPath = `${filePath}.${process.pid}.tmp`;
  fs.writeFileSync(temporaryPath, `${JSON.stringify(results, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(temporaryPath, filePath);
}

function beginCollectionResults(runId, manifest, manifestDigest, expectedCaseKeys) {
  fs.mkdirSync(RESULT_ROOT, { recursive: true });
  const filePath = resultPath(runId);
  const expectedCases = [...expectedCaseKeys];
  if (new Set(expectedCases).size !== expectedCases.length) throw new Error("Phase 253 expected browser cells are not unique");
  if (fs.existsSync(filePath)) {
    const prior = JSON.parse(fs.readFileSync(filePath, "utf8"));
    if (prior.run_id !== runId || prior.manifest_sha256 !== manifestDigest ||
        JSON.stringify(prior.expected_case_keys) !== JSON.stringify(expectedCases)) {
      throw new Error("Phase 253 result path already belongs to a different run or contract");
    }
    return filePath;
  }
  writeResults(filePath, {
    schema_version: 1,
    run_id: runId,
    manifest_sha256: manifestDigest,
    source_and_asset_sha256: currentSourceAndAssetDigests(manifest),
    human_judgment: false,
    proof_lane: "actual direct browser presentation; no mounted-effect claims",
    expected_case_keys: expectedCases,
    cases: [],
  });
  return filePath;
}

function appendResult(filePath, runId, manifestDigest, row) {
  if (!fs.existsSync(filePath)) throw new Error("Phase 253 current-run result ledger was not initialized");
  const results = JSON.parse(fs.readFileSync(filePath, "utf8"));
  if (results.run_id !== runId || results.manifest_sha256 !== manifestDigest) {
    throw new Error("Phase 253 result ledger identity differs from this browser run");
  }
  const existing = results.cases.findIndex((candidate) => candidate.key === row.key);
  if (existing === -1) results.cases.push(row);
  else results.cases[existing] = row;
  writeResults(filePath, results);
}

function recordNegativeControls(filePath, runId, controls) {
  const results = JSON.parse(fs.readFileSync(filePath, "utf8"));
  if (results.run_id !== runId) throw new Error("Phase 253 geometry controls belong to another run");
  results.geometry_negative_controls = controls;
  writeResults(filePath, results);
}

function reconcileResults(results, manifest, manifestDigest) {
  const errors = [];
  const expected = results.expected_case_keys || [];
  const actual = results.cases || [];
  const definitions = createExpectedBrowserCellDefinitions(manifest);
  const definitionsByKey = new Map(definitions.map((definition) => [definition.key, definition]));
  const counts = new Map();
  for (const row of actual) counts.set(row.key, (counts.get(row.key) || 0) + 1);
  for (const key of expected) {
    if (!counts.has(key)) errors.push(`missing browser cell: ${key}`);
    if ((counts.get(key) || 0) > 1) errors.push(`duplicate browser cell: ${key}`);
  }
  for (const row of actual) {
    if (!expected.includes(row.key)) errors.push(`unexpected browser cell: ${row.key}`);
    const definition = definitionsByKey.get(row.key);
    if (!definition) errors.push(`browser cell key has no exact compiled test definition: ${row.key}`);
    else if (!matchesExpectedBrowserCell(row, definition)) {
      errors.push(`browser cell test or compiled source attribution differs from its exact definition: ${row.key}`);
    }
    if (row.status !== "passed") errors.push(`browser cell did not pass: ${row.key}`);
    if (row.manifest_sha256 !== manifestDigest || row.run_id !== results.run_id) {
      errors.push(`browser cell run or manifest identity differs: ${row.key}`);
    }
    if (!row.executed_test || !Array.isArray(row.assertion_ids) || row.assertion_ids.length === 0) {
      errors.push(`browser cell lacks executed test identity or assertions: ${row.key}`);
    }
    if (!row.source_identity || !row.served_assets?.verified) {
      errors.push(`browser cell lacks current source or served asset identity: ${row.key}`);
    }
    if (row.width !== row.viewport.width && row.viewport.container_width == null) {
      errors.push(`browser cell width does not match the actual viewport: ${row.key}`);
    }
  }
  if (expected.length === 0 || actual.length !== expected.length) errors.push("browser result coverage is empty or incomplete");
  return errors;
}

function readGeometry(root) {
  return root.evaluate((sandbox) => {
    const documentElement = sandbox.ownerDocument.documentElement;
    const page = sandbox.querySelector(".ax-page, [data-storybook-subscription-collection]") || sandbox;
    const dataTable = sandbox.querySelector('[data-role="data-table"][data-ax-list="subscriptions"]');
    const tableShell = dataTable?.querySelector(".ax-data-table-shell");
    const cards = dataTable?.querySelector(".ax-data-table-cards");
    const required = [
      ["page title", sandbox.querySelector("[data-ax-page-title]")],
      ["filter toolbar", sandbox.querySelector("[data-ax-page-filter-toolbar]")],
      ["subscription results", dataTable],
    ];
    const hiddenEssential = required.filter(([, element]) => {
      if (!element) return true;
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return style.display === "none" || style.visibility === "hidden" ||
        Number(style.opacity) === 0 || rect.width === 0 || rect.height === 0;
    }).map(([name]) => name);
    const localScrollWidth = tableShell?.scrollWidth || 0;
    const localClientWidth = tableShell?.clientWidth || 0;
    const isVisible = (element) => {
      if (!element) return false;
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return style.display !== "none" && style.visibility !== "hidden" &&
        Number(style.opacity) !== 0 && rect.width > 0 && rect.height > 0;
    };
    return {
      viewport_width: sandbox.ownerDocument.defaultView.innerWidth,
      document_client_width: documentElement.clientWidth,
      document_scroll_width: documentElement.scrollWidth,
      page_client_width: page.clientWidth,
      page_scroll_width: page.scrollWidth,
      hidden_essential: hiddenEssential,
      table_shell_visible: isVisible(tableShell),
      cards_visible: isVisible(cards),
      table_local_overflow: localScrollWidth > localClientWidth + 1,
      table_local_overflow_x: tableShell ? getComputedStyle(tableShell).overflowX : null,
      table_local_client_width: localClientWidth,
      table_local_scroll_width: localScrollWidth,
    };
  });
}

function assertGeometryClean(geometry, label) {
  if (geometry.hidden_essential.length) {
    throw new Error(`${label}: hidden essential content: ${geometry.hidden_essential.join(", ")}`);
  }
  if (geometry.document_scroll_width > geometry.document_client_width + 1) {
    throw new Error(`${label}: document page overflow ${geometry.document_scroll_width}/${geometry.document_client_width}`);
  }
  if (geometry.page_scroll_width > geometry.page_client_width + 1) {
    throw new Error(`${label}: composition page overflow ${geometry.page_scroll_width}/${geometry.page_client_width}`);
  }
  if (geometry.table_local_overflow && geometry.table_local_overflow_x !== "auto") {
    throw new Error(`${label}: table content overflows outside its local scroll boundary`);
  }
}

async function locateCollectionStory(page, entry) {
  const story = page.locator(".psb-sandbox").first();
  await expect(story, `compiled ${entry.variation_id} iframe route renders the connected production collection`).toBeVisible();
  return { story };
}

async function setTheme(story, theme) {
  await story.evaluate((sandbox, selectedTheme) => {
    sandbox.classList.add("accrue-admin");
    sandbox.classList.toggle("ax-theme-dark-shim", selectedTheme === "dark");
  }, theme);
  await story.evaluate(async () => {
    if (document.fonts?.ready) await document.fonts.ready;
    await Promise.all([...document.images].map((image) => image.decode().catch(() => undefined)));
  });
}

async function serveAndVerifyAssets(page, route) {
  const assets = await page.evaluate(() => {
    const stylesheets = [...document.querySelectorAll('link[rel="stylesheet"]')].map((link) => link.href);
    const imports = [...document.querySelectorAll("style")].flatMap((style) =>
      [...style.textContent.matchAll(/@import\s+(?:url\()?['"]([^'")]+)['"]/g)].map((match) => new URL(match[1], document.baseURI).href),
    );
    const scripts = [...document.querySelectorAll("script[src]")].map((element) => element.src);
    return { stylesheets: [...stylesheets, ...imports], scripts };
  });
  const stylesheet = assets.stylesheets.find((asset) => asset.includes("storybook-css-"));
  const script = assets.scripts.find((asset) => asset.includes("storybook-js-"));
  if (!stylesheet || !script) {
    throw new Error(`direct Storybook route did not load compiled CSS and JS assets: ${JSON.stringify(assets)}`);
  }
  const [cssResponse, jsResponse] = await Promise.all([
    page.request.get(new URL(stylesheet, page.url()).href),
    page.request.get(new URL(script, page.url()).href),
  ]);
  if (!cssResponse.ok() || !jsResponse.ok()) throw new Error("current Storybook CSS or JS asset request failed");
  const [servedCss, servedJs] = await Promise.all([cssResponse.text(), jsResponse.text()]);
  const expectedCss = fs.readFileSync(path.join(ADMIN_ROOT, "priv/static/storybook.css"), "utf8");
  const expectedJs = fs.readFileSync(path.join(ADMIN_ROOT, "priv/static/storybook.js"), "utf8");
  if (sha256(servedCss) !== sha256(expectedCss) || sha256(servedJs) !== sha256(expectedJs)) {
    throw new Error("served Storybook assets differ from the current compiled files");
  }
  return {
    route,
    css_href: stylesheet,
    css_sha256: sha256(servedCss),
    js_href: script,
    js_sha256: sha256(servedJs),
    verified: true,
  };
}

async function constrainContent(pageRoot, width) {
  await pageRoot.evaluate((element, containerWidth) => {
    Object.assign(element.style, {
      boxSizing: "border-box",
      inlineSize: `${containerWidth}px`,
      maxInlineSize: `${containerWidth}px`,
      marginInline: "auto",
    });
  }, width);
}

async function assertCollectionContent(story, entry, manifest) {
  const state = entry.collection_state;
  await expect(story.locator("h1[data-ax-page-title]")).toHaveText("Subscriptions");
  await expect(story.locator("[data-ax-page-filter-toolbar]")).toBeVisible();
  await expect(story.getByLabel("Search subscriptions")).toBeVisible();
  const dataTable = story.locator('[data-role="data-table"][data-ax-list="subscriptions"]');
  await expect(dataTable).toBeVisible();
  await expect(story.locator(`[data-storybook-subscription-state="${state}"]`)).toBeVisible();

  const order = await story.evaluate((sandbox) => {
    const title = sandbox.querySelector("[data-ax-page-title]");
    const toolbar = sandbox.querySelector("[data-ax-page-filter-toolbar]");
    const results = sandbox.querySelector('[data-role="data-table"][data-ax-list="subscriptions"]');
    if (!title || !toolbar || !results) return { titleBeforeToolbar: false, toolbarBeforeResults: false };
    return {
      titleBeforeToolbar: Boolean(title.compareDocumentPosition(toolbar) & Node.DOCUMENT_POSITION_FOLLOWING),
      toolbarBeforeResults: Boolean(toolbar.compareDocumentPosition(results) & Node.DOCUMENT_POSITION_FOLLOWING),
    };
  });
  expect(order, `${state}: page title, filter toolbar, and results remain in production order`).toEqual({
    titleBeforeToolbar: true,
    toolbarBeforeResults: true,
  });

  const expectedCopy = {
    new_host_empty: ["No subscriptions yet.", "Subscriptions appear after a customer completes checkout."],
    filtered_empty: ["No subscriptions match these filters.", "Clear filters or adjust the search to see subscriptions."],
    queue_empty: ["Nothing at risk."],
    loading: ["Loading subscriptions."],
    unavailable: ["History unavailable", "This history could not be loaded. Try again."],
    partial_cursor_error: ["Some results could not be loaded. The rows shown may be incomplete. Try again."],
  }[state] || [];
  for (const text of expectedCopy) {
    const copy = story.getByText(text, { exact: true }).first();
    if (state === "loading") await expect(copy).toBeAttached();
    else await expect(copy).toBeVisible();
  }

  if (state === "filtered_empty") {
    const clear = dataTable.locator('[data-role="clear-filters"]');
    await expect(clear).toHaveCount(1);
    await expect(clear).toHaveAttribute("href", /subscriptions/);
  }
  if (state === "queue_empty") {
    await expect(story.getByText("No past-due or canceling subscriptions. View All to see every subscription.", { exact: true })).toBeVisible();
    const viewAll = story.getByRole("link", { name: "View all subscriptions" });
    await expect(viewAll).toBeVisible();
  }
  if (state === "loading") {
    await expect(dataTable.getByRole("status")).toHaveText("Loading subscriptions.");
  }
  if (state === "unavailable") {
    const retry = dataTable.getByRole("button", { name: "Retry" });
    await expect(dataTable.getByRole("alert")).toBeVisible();
    await expect(retry).toBeEnabled();
    await expect(retry).toHaveAttribute("phx-target", /.+/);
  }
  if (state === "partial_cursor_error") {
    const retry = dataTable.getByRole("button", { name: "Retry loading remaining rows" });
    await expect(dataTable.getByRole("alert")).toBeVisible();
    await expect(retry).toBeEnabled();
    await expect(retry).toHaveAttribute("phx-target", /.+/);
  }

  if (["one_row", "multiple_rows", "page_boundary", "incomplete_projection"].includes(state)) {
    const tableVisible = await dataTable.locator(".ax-data-table-shell").evaluate((el) => {
      const style = getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      return style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
    });
    const rowRoot = tableVisible ? dataTable.locator(".ax-data-table-shell") : dataTable.locator(".ax-data-table-cards");
    const rows = tableVisible
      ? rowRoot.locator("tbody > tr[data-row-id]")
      : rowRoot.locator(".ax-data-table-card");
    const count = await rows.count();
    if (count < 1) throw new Error(`${state}: the current visible DataTable layout has no source-derived row`);
    if (state === "multiple_rows" && count < 2) throw new Error("multiple_rows: current visible DataTable layout has fewer than two rows");
    if (tableVisible) {
      const table = dataTable.locator(".ax-data-table-shell table").first();
      await expect(table).toBeVisible();
      if (await table.locator("thead th[scope=col]").count() < 4) throw new Error(`${state}: production table column headers are missing native scope`);
    } else if (await rows.first().locator("dt").count() < 1 || await rows.first().locator("dd").count() < 1) {
      throw new Error(`${state}: mobile DataTable cards lost native definition-list facts`);
    }
    const rowText = await rows.first().innerText();
    if (/\$\s?\d|\b(?:USD|EUR|GBP)\s?\d/.test(rowText) && !/[0-9]+(?:\.[0-9]{2})/.test(rowText)) {
      throw new Error(`${state}: displayed money is not an exact available amount`);
    }
    if (["one_row", "incomplete_projection"].includes(state)) {
      await expect(rows.first()).toContainText(/(?:Amount unavailable|Plan and amount unavailable)/);
    }
    if (state === "page_boundary") {
      const loadMore = dataTable.locator('[data-role="load-more"]');
      await expect(loadMore).toHaveCount(1);
      await expect(loadMore).toBeEnabled();
      await expect(loadMore).toHaveAttribute("phx-target", /.+/);
    }
  }

  if (state === "one_row") {
    const row = manifest.entries.find((candidate) => candidate.variation_id === "one_row");
    if (!row) throw new Error("one_row transport fact is missing from the compiled manifest");
    const tableVisible = await dataTable.locator(".ax-data-table-shell").evaluate((el) => {
      const style = getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      return style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
    });
    const visibleRows = tableVisible
      ? dataTable.locator(".ax-data-table-shell tbody > tr[data-row-id]")
      : dataTable.locator(".ax-data-table-cards .ax-data-table-card");
    const link = visibleRows.first().locator(`a[href^="/billing/subscriptions/${row.expected.subscription_id}"]`).first();
    await expect(link).toBeVisible();
    await expect(link).toHaveText(row.expected.customer_name);
    await expect(link).toHaveAttribute("href", new RegExp(`^/billing/subscriptions/${row.expected.subscription_id}(?:\\?|$)`));
    const visibleText = await dataTable.innerText();
    for (const exactFact of [row.expected.processor_id, row.expected.plan_price_id, "Active"]) {
      if (!visibleText.includes(exactFact)) throw new Error(`one_row: current visible presentation omitted ${exactFact}`);
    }
    if (!/(?:Amount unavailable|Plan and amount unavailable)/i.test(visibleText)) {
      throw new Error("one_row: the unavailable amount projection is missing its source-owned caveat");
    }
  }

  const [tableVisible, cardsVisible, emptyVisible, loadingVisible, unavailableVisible] = await Promise.all([
    dataTable.locator(".ax-data-table-shell").isVisible(),
    dataTable.locator(".ax-data-table-cards").isVisible(),
    dataTable.locator('[data-role="empty-state"]').isVisible(),
    dataTable.locator('[data-role="loading-skeleton"]').isVisible(),
    dataTable.locator('[data-role="unavailable-state"]').isVisible(),
  ]);
  const visibleLayout = tableVisible ? "table" : cardsVisible ? "cards" : emptyVisible ? "empty" :
    loadingVisible ? "loading" : unavailableVisible ? "unavailable" : "no-results-container";

  return {
    collection_state: state,
    data_table_state: await dataTable.getAttribute("data-ax-state"),
    visible_layout: visibleLayout,
    semantic_elements: {
      h1: await story.locator("h1[data-ax-page-title]").count(),
      search_label: await story.getByLabel("Search subscriptions").count(),
      native_links: await dataTable.locator("a[href]").count(),
      native_buttons: await dataTable.locator("button").count(),
    },
    proof_lane: "presentation-only",
  };
}

async function runCollectionCase(page, testCase, identity, testInfo) {
  const { entry, width, viewportWidth, containerWidth, theme, kind, key } = testCase;
  const row = {
    key,
    run_id: identity.runId,
    executed_test: testInfo.title,
    variation_id: entry.variation_id,
    scenario_id: entry.scenario_id,
    width,
    viewport: { width: viewportWidth, container_width: containerWidth },
    theme,
    case_kind: kind,
    url: entry.iframe_path,
    source_identity: collectionSourceIdentity(entry),
    assertion_ids: ["compiled_direct_route", "ordered_collection_content", "source_facts_and_state_controls", "theme_and_served_asset_identity", "no_hidden_essential_or_page_overflow"],
    status: "failed",
  };
  try {
    // Keep the first-page boundary below the observer's 160px root margin.
    // The partial-error fixture needs a tall viewport to exercise its real next-page read.
    const viewportHeight = entry.collection_state === "page_boundary" ? 200 :
      entry.collection_state === "partial_cursor_error" ? 1000 : 480;
    await page.setViewportSize({ width: viewportWidth, height: viewportHeight });
    await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
    await page.goto(`/__e2e__/login?to=${encodeURIComponent(entry.iframe_path)}`);
    await expect.poll(() => {
      const current = new URL(page.url());
      return `${current.pathname}${current.search}`;
    }).toBe(entry.iframe_path);

    const { story } = await locateCollectionStory(page, entry);
    await setTheme(story, theme);

    const pageRoot = story.locator("[data-storybook-subscription-collection]").first();
    await expect(pageRoot, "production composition has its own page container").toBeVisible();
    if (containerWidth != null) {
      await constrainContent(pageRoot, containerWidth);
      const actualWidth = await pageRoot.evaluate((element) => Math.round(element.getBoundingClientRect().width));
      expect(actualWidth, "640px constrains the content container while the viewport remains 1280px").toBe(containerWidth);
      expect(await story.evaluate((element) => element.ownerDocument.defaultView.innerWidth)).toBe(viewportWidth);
    }

    await expect(story.locator("h1").first()).toBeVisible();
    row.served_assets = await serveAndVerifyAssets(page, entry.iframe_path);
    row.content = await assertCollectionContent(story, entry, identity.manifest);
    const geometry = await readGeometry(story);
    assertGeometryClean(geometry, key);
    expect(geometry.viewport_width).toBe(viewportWidth);
    if (kind === "breakpoint" && entry.variation_id === "one_row") {
      expect(geometry.cards_visible, `cards are visible at ${width}px`).toBe(width < 768);
      expect(geometry.table_shell_visible, `the table is visible at ${width}px`).toBe(width >= 768);
      if (geometry.table_local_overflow) expect(geometry.table_local_overflow_x).toBe("auto");
      row.assertion_ids.push("actual_767_768_card_table_transition", "table_local_scroll_is_separate");
    }
    if (kind === "breakpoint" && entry.variation_id === "filtered_empty") {
      expect(row.content.visible_layout).toBe("empty");
      expect(geometry.table_shell_visible).toBe(false);
      expect(geometry.cards_visible).toBe(false);
      row.assertion_ids.push("filtered_empty_is_visible_without_inventing_empty_table_or_cards");
    }
    if (kind === "viewport" && entry.variation_id === "one_row") {
      expect(geometry.cards_visible, `cards are visible at ${width}px`).toBe(width < 768);
      expect(geometry.table_shell_visible, `the table is visible at ${width}px`).toBe(width >= 768);
    }

    row.geometry = geometry;
    row.status = "passed";
  } catch (error) {
    row.error = String(error?.message || error).split("\n")[0];
    throw error;
  } finally {
    row.completed_at = new Date().toISOString();
    row.manifest_sha256 = identity.manifestDigest;
    appendResult(identity.resultPath, identity.runId, identity.manifestDigest, row);
  }
}

async function runSyntheticTextStress(page, entry, identity, theme, testInfo) {
  const viewportWidth = 320;
  const syntheticName = `<svg onload=alert(1)>${"synthetic-customer-".repeat(12)}</svg>`;
  const syntheticId = `sub_<script>${"long-id-253-".repeat(12)}</script>`;
  const syntheticFilter = `<img src=x onerror=alert(1)> ${"held-out-filter-".repeat(8)}`;
  const row = {
    key: `one_row::synthetic-text::320::${theme}`,
    run_id: identity.runId,
    executed_test: testInfo.title,
    variation_id: entry.variation_id,
    scenario_id: entry.scenario_id,
    width: viewportWidth,
    viewport: { width: viewportWidth, container_width: null },
    theme,
    case_kind: "synthetic_text_stress",
    url: entry.iframe_path,
    source_identity: collectionSourceIdentity(entry),
    stress_label: "separately labelled synthetic browser-only layout stress; not customer evidence",
    assertion_ids: ["synthetic_name_and_id_wrap", "filter_value_remains_text_without_page_overflow", "essential_actions_remain_available"],
    status: "failed",
  };
  try {
    await page.setViewportSize({ width: viewportWidth, height: 1000 });
    await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
    await page.goto(`/__e2e__/login?to=${encodeURIComponent(entry.iframe_path)}`);
    await expect.poll(() => `${new URL(page.url()).pathname}${new URL(page.url()).search}`).toBe(entry.iframe_path);
    const { story } = await locateCollectionStory(page, entry);
    await setTheme(story, theme);

    const dataTable = story.locator('[data-role="data-table"][data-ax-list="subscriptions"]');
    const tableVisible = await dataTable.locator(".ax-data-table-shell").isVisible();
    const visibleRows = tableVisible
      ? dataTable.locator(".ax-data-table-shell tbody > tr[data-row-id]")
      : dataTable.locator(".ax-data-table-cards .ax-data-table-card");
    const link = visibleRows.first().locator('a[href^="/billing/subscriptions/"]').first();
    await expect(link).toBeVisible();
    await link.evaluate((element, values) => {
      element.textContent = values.name;
      const id = document.createElement("span");
      id.dataset.phase253SyntheticId = "true";
      id.className = "ax-data-table-identity-secondary";
      id.textContent = values.id;
      element.parentElement.appendChild(id);
    }, { name: syntheticName, id: syntheticId });
    await expect(link).toHaveText(syntheticName);
    await expect(story.locator('[data-phase253-synthetic-id="true"]')).toHaveText(syntheticId);
    const nameMetrics = await link.evaluate((element) => ({
      clientWidth: element.clientWidth,
      scrollWidth: element.scrollWidth,
      overflow: getComputedStyle(element).overflow,
      whiteSpace: getComputedStyle(element).whiteSpace,
      textOverflow: getComputedStyle(element).textOverflow,
    }));
    if (nameMetrics.scrollWidth > nameMetrics.clientWidth + 1 &&
        (nameMetrics.overflow === "hidden" || nameMetrics.whiteSpace === "nowrap" || nameMetrics.textOverflow === "ellipsis")) {
      throw new Error("synthetic customer name is clipped inside its essential identity link");
    }
    const idMetrics = await story.locator('[data-phase253-synthetic-id="true"]').evaluate((element) => ({
      clientWidth: element.clientWidth,
      scrollWidth: element.scrollWidth,
      overflow: getComputedStyle(element).overflow,
      whiteSpace: getComputedStyle(element).whiteSpace,
      textOverflow: getComputedStyle(element).textOverflow,
    }));
    if (idMetrics.scrollWidth > idMetrics.clientWidth + 1 &&
        (idMetrics.overflow === "hidden" || idMetrics.whiteSpace === "nowrap" || idMetrics.textOverflow === "ellipsis")) {
      throw new Error("synthetic subscription identifier is clipped inside its rendered boundary");
    }

    const search = story.getByLabel("Search subscriptions");
    await search.fill(syntheticFilter);
    await expect(search).toHaveValue(syntheticFilter);
    const resetFilters = story.getByRole("link", { name: "Reset filters" });
    await expect(resetFilters).toBeVisible();
    await expect(resetFilters).toHaveAttribute("href", "/billing/subscriptions");
    const filterMetrics = await search.evaluate((element) => ({
      clientWidth: element.clientWidth,
      scrollWidth: element.scrollWidth,
      documentWidth: element.ownerDocument.documentElement.scrollWidth,
      viewportWidth: element.ownerDocument.defaultView.innerWidth,
    }));
    if (filterMetrics.clientWidth <= 0 || filterMetrics.documentWidth > filterMetrics.viewportWidth) {
      throw new Error("synthetic filter text has no visible input or causes page overflow");
    }
    await expect(story.locator("img[src='x'], svg[onload], script")).toHaveCount(0);
    row.synthetic_inputs = { name: syntheticName, id: syntheticId, filter: syntheticFilter };
    row.name_metrics = nameMetrics;
    row.id_metrics = idMetrics;
    row.filter_metrics = filterMetrics;
    row.served_assets = await serveAndVerifyAssets(page, entry.iframe_path);
    row.geometry = await readGeometry(story);
    assertGeometryClean(row.geometry, row.key);
    row.status = "passed";
  } catch (error) {
    row.error = String(error?.message || error).split("\n")[0];
    throw error;
  } finally {
    row.completed_at = new Date().toISOString();
    row.manifest_sha256 = identity.manifestDigest;
    appendResult(identity.resultPath, identity.runId, identity.manifestDigest, row);
  }
}

async function runGeometryNegativeControls(page, entry, identity, testInfo) {
  const row = {
    key: "geometry::negative-controls::320::light",
    run_id: identity.runId,
    executed_test: testInfo.title,
    variation_id: entry.variation_id,
    scenario_id: entry.scenario_id,
    width: 320,
    viewport: { width: 320, container_width: null },
    theme: "light",
    case_kind: "geometry_negative_controls",
    url: entry.iframe_path,
    source_identity: collectionSourceIdentity(entry),
    assertion_ids: ["hidden_essential_control_is_detected", "page_overflow_control_is_detected", "restored_actual_layout_passes"],
    status: "failed",
  };
  try {
    await page.setViewportSize({ width: 320, height: 1000 });
    await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
    await page.goto(`/__e2e__/login?to=${encodeURIComponent(entry.iframe_path)}`);
    await expect.poll(() => `${new URL(page.url()).pathname}${new URL(page.url()).search}`).toBe(entry.iframe_path);
    const { story } = await locateCollectionStory(page, entry);
    await setTheme(story, "light");
    const title = story.locator("h1[data-ax-page-title]");
    const baseline = await readGeometry(story);
    assertGeometryClean(baseline, "geometry positive control");

    await title.evaluate((element) => { element.dataset.phase253PriorDisplay = element.style.display; element.style.display = "none"; });
    const hidden = await readGeometry(story);
    let hiddenCaught = false;
    try { assertGeometryClean(hidden, "injected hidden essential content"); } catch (error) { hiddenCaught = /hidden essential content/.test(error.message); }
    await title.evaluate((element) => { element.style.display = element.dataset.phase253PriorDisplay || ""; delete element.dataset.phase253PriorDisplay; });
    if (!hiddenCaught) throw new Error("geometry checker did not reject the injected hidden essential heading");

    const pageRoot = story.locator("[data-storybook-subscription-collection]").first();
    const probe = await pageRoot.evaluate((element) => {
      const child = document.createElement("div");
      child.dataset.phase253OverflowProbe = "true";
      Object.assign(child.style, { display: "block", width: "2000px", height: "2px" });
      element.appendChild(child);
      return child.dataset.phase253OverflowProbe;
    });
    const overflow = await readGeometry(story);
    let overflowCaught = false;
    try { assertGeometryClean(overflow, "injected page overflow"); } catch (error) { overflowCaught = /overflow/.test(error.message); }
    await pageRoot.locator(`[data-phase253-overflow-probe="${probe}"]`).evaluate((element) => element.remove());
    if (!overflowCaught) throw new Error("geometry checker did not reject the injected page overflow");

    row.negative_controls = { hidden_essential_detected: hiddenCaught, page_overflow_detected: overflowCaught };
    row.geometry = await readGeometry(story);
    assertGeometryClean(row.geometry, "restored actual layout");
    row.served_assets = await serveAndVerifyAssets(page, entry.iframe_path);
    row.status = "passed";
  } catch (error) {
    row.error = String(error?.message || error).split("\n")[0];
    throw error;
  } finally {
    row.completed_at = new Date().toISOString();
    row.manifest_sha256 = identity.manifestDigest;
    appendResult(identity.resultPath, identity.runId, identity.manifestDigest, row);
  }
}

async function readPageGeometry(page) {
  return page.evaluate(() => {
    const documentElement = document.documentElement;
    const root = document.querySelector(".psb-sandbox .ax-subscription-detail-page");
    const isVisible = (element) => {
      if (!element) return false;
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return style.display !== "none" && style.visibility !== "hidden" && Number(style.opacity) !== 0 &&
        rect.width > 0 && rect.height > 0;
    };
    const required = [
      ["page heading", root?.querySelector("h1")],
      ["summary facts", root?.querySelector("[data-ax-summary-list]")],
      ["action band", root?.querySelector("[data-ax-action-band]")],
      ["return navigation", root?.querySelector(".ax-detail-back-link a")],
      ["related resources", root?.querySelector("[data-ax-related-resources]")],
    ];
    const hiddenEssential = required.filter(([, element]) => !isVisible(element)).map(([name]) => name);
    const rootRect = root?.getBoundingClientRect();
    return {
      viewport_width: window.innerWidth,
      document_client_width: documentElement.clientWidth,
      document_scroll_width: documentElement.scrollWidth,
      page_client_width: root?.clientWidth || 0,
      page_scroll_width: root?.scrollWidth || 0,
      page_rendered_width: rootRect ? Math.round(rootRect.width) : 0,
      hidden_essential: hiddenEssential,
    };
  });
}

function assertPageGeometryClean(geometry, label) {
  if (geometry.hidden_essential.length) {
    throw new Error(`${label}: hidden essential content: ${geometry.hidden_essential.join(", ")}`);
  }
  if (geometry.document_scroll_width > geometry.document_client_width + 1) {
    throw new Error(`${label}: document page overflow ${geometry.document_scroll_width}/${geometry.document_client_width}`);
  }
  if (geometry.page_scroll_width > geometry.page_client_width + 1) {
    throw new Error(`${label}: subscription page overflow ${geometry.page_scroll_width}/${geometry.page_client_width}`);
  }
}

async function assertPageContent(page, story, entry) {
  const facts = entry.expected;
  const root = story.locator(".ax-subscription-detail-page").first();
  await expect(root, "the direct route uses the compiled whole-page renderer").toBeVisible();
  await expect(root.locator("h1")).toHaveCount(1);
  await expect(root.locator("h1")).toContainText(facts.customer_name);

  const copyId = root.locator("#subscription-summary-id");
  await expect(copyId).toBeVisible();
  await expect(copyId).toHaveAttribute("data-clipboard-text", facts.processor_id || facts.subscription_id);
  await expect(copyId).toContainText(facts.processor_id || facts.subscription_id);

  const factRows = await root.locator("[data-ax-summary-list] .ax-summary-list-row").evaluateAll((rows) =>
    Object.fromEntries(rows.map((row) => [
      row.querySelector("dt")?.innerText.trim(),
      row.querySelector("dd.ax-summary-list-value")?.innerText.trim(),
    ])),
  );
  expect(factRows["Lifecycle state"], `${entry.variation_id}: source lifecycle remains visible`).toBe(
    facts.status === "active" ? "Active" : facts.status,
  );
  expect(factRows["Plan / price"], `${entry.variation_id}: exact plan identifier or unavailable caveat`).toBe(
    facts.plan_price_id || "Price unavailable",
  );
  expect(factRows["Amount (MRR)"], `${entry.variation_id}: no invented price or amount`).toBe("Unavailable");
  if (facts.plan_quantity != null) {
    expect(factRows["Seats / quantity"]).toBe(String(facts.plan_quantity));
  }
  expect(await root.locator("[data-ax-summary-list] .ax-summary-list-row").count()).toBeGreaterThanOrEqual(6);
  await expect(root).toContainText("Charge amount unavailable");

  if (entry.variation_id === "scheduled_cancellation") {
    expect(factRows.Cancellation).toContain("Scheduled for");
  }
  if (entry.variation_id === "incomplete_evidence") {
    expect(factRows["Renews / ends"] || Object.values(factRows).join(" ")).toContain("Renewal date unavailable");
    expect(Object.values(factRows).join(" ")).toContain("Price unavailable");
    expect(Object.values(factRows).join(" ")).toContain("Charge amount unavailable");
  }

  const returnLink = root.locator(".ax-detail-back-link a");
  await expect(returnLink).toBeVisible();
  const returnHref = await returnLink.getAttribute("href");
  const returnUrl = new URL(returnHref, page.url());
  expect(returnUrl.pathname).toBe("/billing/subscriptions");
  expect(returnUrl.searchParams.get("org")).toBe(facts.owner_slug);

  const related = root.locator("[data-ax-related-resources]");
  await expect(related).toBeVisible();
  const relatedHrefs = await related.locator("a[href]").evaluateAll((links) => links.map((link) => link.getAttribute("href")));
  expect(relatedHrefs.length, "related resources retain destination links").toBeGreaterThan(0);
  expect(relatedHrefs.every((href) => href && href.startsWith("/billing/"))).toBe(true);
  await expect(root.locator("[data-ax-action-band]")).toBeVisible();
  await expect(root.locator("[data-ax-drill-section]")).toHaveCount(3);
  await expect(root.locator("[data-ax-drill-section] summary")).toHaveCount(3);
  await expect(root.locator("[data-ax-lazy-activity]")).toHaveCount(1);
  await expect(root.locator("[data-ax-lazy-json]")).toHaveCount(1);

  const activity = root.getByRole("link", { name: "Open Events audit log with subscription filter" });
  await expect(activity).toBeVisible();
  const activityUrl = new URL(await activity.getAttribute("href"), page.url());
  expect(activityUrl.pathname).toBe("/billing/events");
  expect(activityUrl.searchParams.get("org")).toBe(facts.owner_slug);
  expect(activityUrl.searchParams.get("subject_type")).toBe("Subscription");
  expect(activityUrl.searchParams.get("subject_id")).toBe(facts.subscription_id);

  const pageText = await root.innerText();
  expect(pageText).toContain(facts.customer_name);
  expect(pageText).toContain(facts.processor_id);
  expect(pageText).not.toMatch(/\$\s?\d|\b(?:USD|EUR|GBP)\s?\d/);

  return {
    heading: await root.locator("h1").innerText(),
    summary_facts: factRows,
    copy_id: await copyId.getAttribute("data-clipboard-text"),
    return_href: returnHref,
    related_hrefs: relatedHrefs,
    activity_href: await activity.getAttribute("href"),
    disclosure_names: await root.locator("[data-ax-drill-section]").evaluateAll((sections) =>
      sections.map((section) => section.getAttribute("data-ax-drill-section")),
    ),
    amount_assertion: "amount unavailable; no numeric amount projected",
  };
}

async function assertPageSnapshot(page, story, entry) {
  const variationId = entry.variation_id;
  const expected = entry.expected;
  if (variationId === "review_cancel_now" || variationId === "awaiting_step_up" || variationId === "dispatching") {
    const drawer = page.locator("#subscription-action-drawer");
    await expect(drawer, `${variationId}: open review drawer is visible`).toBeVisible();
    const panel = drawer.locator('[data-role="confirm-panel"]');
    await expect(panel).toBeVisible();
    await expect(panel).toContainText(expected.subscription_id);
    await expect(panel).toContainText(expected.processor_id);
    await expect(panel).toContainText("Unavailable; no estimate is shown.");
    await expect(panel).toContainText("Current state");
    const confirm = drawer.locator('[data-role="confirm-action"]');
    await expect(confirm).toBeVisible();
    if (variationId === "review_cancel_now") await expect(confirm).toBeEnabled();
    else await expect(confirm).toBeDisabled();
    await expect(drawer.getByRole("button", { name: "Back to subscription" }).first()).toBeVisible();
    await expect(drawer.getByRole("heading", { level: 2 })).toBeVisible();

    if (variationId === "awaiting_step_up") {
      const modal = page.locator("#accrue-admin-step-up-dialog");
      await expect(modal).toBeVisible();
      await expect(modal).toContainText("Verify admin action");
      await expect(modal.locator("#step-up-code")).toBeVisible();
      await expect(modal.locator('[data-role="step-up-cancel"]')).toBeVisible();
      await expect(modal.locator('[data-role="step-up-submit"]')).toBeVisible();
    }
    return {
      composition: variationId,
      consequence: (await panel.innerText()).replace(/\s+/g, " ").trim(),
      confirm_disabled: await confirm.isDisabled(),
      dismiss_label: "Back to subscription",
      step_up_visible: variationId === "awaiting_step_up",
    };
  }

  if (variationId.startsWith("result_")) {
    const result = story.locator('[data-role="subscription-action-result"]');
    await expect(result).toBeVisible();
    await expect(result).toHaveAttribute("role", "status");
    await expect(result).toHaveAttribute("aria-live", "polite");
    const expectedMessage = {
      result_confirmed: "Subscription action recorded.",
      result_pending: "A completed subscription change is not confirmed",
      result_failed: "The provider rejected the action. No change was accepted.",
    }[variationId];
    await expect(result).toContainText(expectedMessage);
    const activity = result.getByRole("link", { name: "Open scoped subscription activity" });
    await expect(activity).toBeVisible();
    const destination = new URL(await activity.getAttribute("href"), page.url());
    expect(destination.pathname).toBe("/billing/events");
    expect(destination.searchParams.get("org")).toBe(expected.owner_slug);
    expect(destination.searchParams.get("subject_type")).toBe("Subscription");
    expect(destination.searchParams.get("subject_id")).toBe(expected.subscription_id);
    return {
      composition: variationId,
      result_role: await result.getAttribute("role"),
      aria_live: await result.getAttribute("aria-live"),
      result_copy: await result.innerText(),
      activity_href: await activity.getAttribute("href"),
    };
  }

  return { composition: variationId, composition_type: "canonical detail page" };
}

async function addPageSyntheticStress(page, variationId) {
  const root = page.locator(".psb-sandbox .ax-subscription-detail-page").first();
  const longValue = `phase253 synthetic validated origin ${"context remains scoped ".repeat(16)}`.trim();
  let host;
  let label;
  if (variationId === "active") {
    host = root.locator(".ax-detail-back-link");
    label = "Synthetic return-label and encoded-origin stress only";
  } else if (variationId === "review_cancel_now") {
    host = page.locator("#subscription-action-drawer [data-role='confirm-panel']");
    label = "Synthetic consequence stress only";
  } else {
    host = page.locator("#accrue-admin-step-up-dialog .ax-step-up-modal-body");
    label = "Synthetic recovery stress only";
  }
  const before = await host.innerText();
  const returnHref = variationId === "active" ? await root.locator(".ax-detail-back-link a").getAttribute("href") : null;
  const stress = await host.evaluate((element, values) => {
    const content = document.createElement("span");
    content.className = "ax-body";
    content.style.display = "block";
    content.dataset.phase253SyntheticStress = values.label;
    content.textContent = `${values.label}: ${values.value}`;
    element.appendChild(content);
    let link = null;
    if (values.href) {
      link = document.createElement("a");
      link.className = "ax-link";
      link.dataset.phase253SyntheticOrigin = "true";
      link.textContent = `${values.label}: ${values.value}`;
      link.href = values.href;
      link.style.display = "block";
      element.appendChild(link);
    }
    const style = getComputedStyle(content);
    const metrics = {
      content_width: content.clientWidth,
      content_scroll_width: content.scrollWidth,
      parent_width: element.clientWidth,
      parent_scroll_width: element.scrollWidth,
      overflow: style.overflow,
      white_space: style.whiteSpace,
      text_overflow: style.textOverflow,
      after_text: element.innerText,
      encoded_link_href: link?.href || null,
      link_width: link?.clientWidth || null,
      link_scroll_width: link?.scrollWidth || null,
    };
    return metrics;
  }, {
    label,
    value: longValue,
    href: returnHref ? `${returnHref}&phase253_origin=${encodeURIComponent(longValue)}` : null,
  });
  if (!stress.after_text.includes(before) || !stress.after_text.includes(label)) {
    throw new Error(`${variationId}: synthetic stress text displaced actual source copy`);
  }
  if (stress.content_width <= 0 || stress.content_scroll_width > stress.content_width + 1 ||
      (stress.link_width != null && stress.link_scroll_width > stress.link_width + 1)) {
    throw new Error(`${variationId}: long synthetic text is clipped in its source layout boundary`);
  }
  if (stress.parent_scroll_width > stress.parent_width + 1) {
    throw new Error(`${variationId}: long synthetic text overflows its parent composition`);
  }
  if (variationId === "active") {
    const parsed = new URL(stress.encoded_link_href);
    expect(parsed.searchParams.get("org")).toBe("cadence-demo");
    expect(parsed.searchParams.get("phase253_origin")).toBe(longValue);
  }
  return { label, synthetic_value: longValue, metrics: stress, retained_source_text: true };
}

async function runPageCase(page, testCase, identity, testInfo) {
  const { entry, width, viewportWidth, containerWidth, theme, kind, key } = testCase;
  const row = {
    key,
    run_id: identity.runId,
    executed_test: testInfo.title,
    variation_id: entry.variation_id,
    scenario_id: entry.expected.scenario,
    snapshot: entry.presentation_snapshot,
    width,
    viewport: { width: viewportWidth, container_width: containerWidth },
    theme,
    case_kind: kind === "synthetic" ? "page_synthetic_text_stress" : "page_composition",
    url: entry.direct_path,
    source_identity: expectedPageFacts(entry),
    stress_label: kind === "synthetic" ? `separately labelled synthetic ${entry.variation_id} stress only; not customer evidence` : undefined,
    assertion_ids: [
      "compiled_direct_whole_page_route",
      "production_source_identity_and_fact_content",
      "exact_ids_amount_caveats_state_and_destinations",
      "native_disclosures_activity_and_related_links",
      "theme_and_served_asset_identity",
      "no_hidden_essential_content_or_page_overflow",
    ],
    status: "failed",
  };
  try {
    await page.setViewportSize({ width: viewportWidth, height: 1000 });
    await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
    await page.goto(`/__e2e__/login?to=${encodeURIComponent(entry.direct_path)}`);
    await expect.poll(() => `${new URL(page.url()).pathname}${new URL(page.url()).search}`).toBe(entry.direct_path);

    const story = page.locator(".psb-sandbox").first();
    await expect(story).toBeVisible();
    await setTheme(story, theme);
    const root = story.locator(".ax-subscription-detail-page").first();
    await expect(root).toBeVisible();
    if (containerWidth != null) {
      await constrainContent(root, containerWidth);
      const actualWidth = await root.evaluate((element) => Math.round(element.getBoundingClientRect().width));
      expect(actualWidth, "the actual page content container is constrained to 640px").toBe(containerWidth);
      expect(await page.evaluate(() => window.innerWidth)).toBe(viewportWidth);
    }

    row.served_assets = await serveAndVerifyAssets(page, entry.direct_path);
    row.content = await assertPageContent(page, story, entry);
    row.snapshot_content = await assertPageSnapshot(page, story, entry);
    if (kind === "synthetic") {
      row.synthetic_stress = await addPageSyntheticStress(page, entry.variation_id);
      row.assertion_ids.push("long_source_preserving_synthetic_stress_is_visible_and_unclipped");
    }
    row.geometry = await readPageGeometry(page);
    assertPageGeometryClean(row.geometry, key);
    expect(row.geometry.viewport_width).toBe(viewportWidth);
    if (containerWidth != null) expect(row.geometry.page_rendered_width).toBe(containerWidth);
    row.status = "passed";
  } catch (error) {
    row.error = String(error?.message || error).split("\n")[0];
    throw error;
  } finally {
    row.completed_at = new Date().toISOString();
    row.manifest_sha256 = identity.manifestDigest;
    appendResult(identity.resultPath, identity.runId, identity.manifestDigest, row);
  }
}

module.exports = {
  COLLECTION_STATES,
  GEOMETRY_NEGATIVE_CONTROL_TITLE,
  BROWSER_RECONCILIATION_TITLE,
  THEMES,
  WIDTHS,
  appendResult,
  beginCollectionResults,
  createCollectionCases,
  createExpectedBrowserCellDefinitions,
  createPageCases,
  createPageStressCases,
  collectionSyntheticTitle,
  currentSourceAndAssetDigests,
  matchesExpectedBrowserCell,
  readPhase253Manifest,
  reconcileResults,
  recordNegativeControls,
  resultPath,
  runCollectionCase,
  runGeometryNegativeControls,
  runPageCase,
  runSyntheticTextStress,
};
