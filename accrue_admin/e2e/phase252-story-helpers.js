const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { expect } = require("@playwright/test");
const {
  assertStorybookAssetsLoaded,
  setSettledThemeForScan,
} = require("./phase200-storybook-helpers.js");

const REPO_ROOT = path.resolve(__dirname, "..", "..");
const MANIFEST_PATH = path.join(REPO_ROOT, "storybook", "phase252-manifest.json");
const RESULT_DIR = path.join(REPO_ROOT, "accrue_admin", "tmp", "phase252");
const RESULT_PATH = path.join(RESULT_DIR, "render-results.json");
const CANONICAL_STATES = ["active", "scheduled_cancellation", "incomplete_evidence"];
const WIDTHS = [320, 1280];
const THEMES = ["light", "dark"];

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function readManifest() {
  const raw = fs.readFileSync(MANIFEST_PATH);
  const manifest = JSON.parse(raw.toString("utf8"));
  if (!Array.isArray(manifest.entries) || !manifest.source_digests) {
    throw new Error("Phase 252 manifest is missing entries or source digests");
  }

  const keys = manifest.entries.map((entry) => entry.key);
  if (keys.some((key) => typeof key !== "string") || new Set(keys).size !== keys.length) {
    throw new Error("Phase 252 manifest keys must be non-empty and unique");
  }

  for (const state of CANONICAL_STATES) {
    const matches = manifest.entries.filter(
      (entry) => entry.scenario_id === state && entry.variation_id === state
    );
    if (matches.length !== 1) {
      throw new Error(`Phase 252 manifest must declare exactly one canonical ${state} variation`);
    }
  }

  for (const [relativePath, expectedDigest] of Object.entries(manifest.source_digests)) {
    const sourcePath = path.join(REPO_ROOT, relativePath);
    if (!fs.existsSync(sourcePath)) {
      throw new Error(`Phase 252 manifest source is missing: ${relativePath}`);
    }
    const actualDigest = sha256(fs.readFileSync(sourcePath));
    if (actualDigest !== expectedDigest) {
      throw new Error(`Phase 252 manifest source digest differs: ${relativePath}`);
    }
  }

  return { manifest, manifestDigest: sha256(raw) };
}

function createCases(manifest) {
  const canonical = [];
  for (const state of CANONICAL_STATES) {
    const entry = manifest.entries.find(
      (candidate) => candidate.scenario_id === state && candidate.variation_id === state
    );
    for (const width of WIDTHS) {
      for (const theme of THEMES) {
        canonical.push({
          entry,
          width,
          theme,
          kind: "canonical",
          key: `${entry.key}::${width}::${theme}`,
          title: `${state} | ${width}px | ${theme}`,
        });
      }
    }
  }

  const compatibility = manifest.entries
    .filter((entry) => !CANONICAL_STATES.includes(entry.variation_id))
    .map((entry) => ({
      entry,
      width: 1280,
      theme: "light",
      kind: "compatibility",
      key: `${entry.key}::compatibility::1280::light`,
      title: `${entry.variation_id} | compatibility | 1280px | light`,
    }));

  return [...canonical, ...compatibility];
}

function mountedStoryPath(entry) {
  const generated = new URL(entry.url, "http://phase252.local");
  const pathname = generated.pathname.startsWith("/dev/storybook/")
    ? `/billing${generated.pathname}`
    : generated.pathname;
  return `${pathname}${generated.search}`;
}

function beginResults(runId, manifestDigest) {
  if (!runId) throw new Error("Phase 252 browser run has no owned launcher identity");
  fs.mkdirSync(RESULT_DIR, { recursive: true });
  if (fs.existsSync(RESULT_PATH)) {
    const current = readResults();
    if (current.run_id === runId && current.manifest_sha256 === manifestDigest) return;
  }
  writeResults({
    schema_version: 1,
    run_id: runId,
    manifest_sha256: manifestDigest,
    generated_at: new Date().toISOString(),
    cases: [],
  });
}

function writeResults(results) {
  const temporaryPath = `${RESULT_PATH}.${process.pid}.tmp`;
  fs.writeFileSync(temporaryPath, `${JSON.stringify(results, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(temporaryPath, RESULT_PATH);
}

function appendResult(runId, row) {
  if (!fs.existsSync(RESULT_PATH)) {
    throw new Error("Phase 252 browser result ledger was not initialized for this run");
  }
  const results = JSON.parse(fs.readFileSync(RESULT_PATH, "utf8"));
  if (results.run_id !== runId) {
    throw new Error("Phase 252 browser result ledger belongs to a different launcher run");
  }
  results.cases.push(row);
  writeResults(results);
}

function readResults() {
  return JSON.parse(fs.readFileSync(RESULT_PATH, "utf8"));
}

function normalizeText(value) {
  return String(value || "").replace(/\s+/g, " ").trim();
}

function normalizeTimestamp(value) {
  const milliseconds = Date.parse(value);
  return Number.isNaN(milliseconds) ? value : new Date(milliseconds).toISOString();
}

async function readFactRows(story) {
  return story.locator(".ax-summary-list-row").evaluateAll((elements) =>
    elements.map((element) => {
      const term = element.querySelector("dt");
      const value = element.querySelector("dd.ax-summary-list-value");
      const actions = [...element.querySelectorAll("dd.ax-summary-list-actions a, dd.ax-summary-list-actions button")];
      return {
        label: term?.textContent.replace(/\s+/g, " ").trim() || "",
        value: value?.textContent.replace(/\s+/g, " ").trim() || "",
        times: value
          ? [...value.querySelectorAll("time[datetime]")].map((time) => time.getAttribute("datetime"))
          : [],
        actions: actions.map((action) => ({
          text: action.innerText.replace(/\s+/g, " ").trim(),
          name: action.getAttribute("aria-label"),
          href: action.getAttribute("href"),
        })),
      };
    })
  );
}

function statusLabel(status) {
  const labels = {
    active: "Active",
    past_due: "Past due",
    unpaid: "Unpaid",
    incomplete: "Incomplete",
    incomplete_expired: "Incomplete expired",
    trialing: "Trialing",
    paused: "Paused",
    canceled: "Canceled",
  };
  return labels[status] || status.replaceAll("_", " ");
}

function expectedCaveats(entry) {
  const caveats = [];
  if (!entry.expected.lifecycle.current_period_end) caveats.push("Renewal date unavailable");
  if (!(entry.expected.facts.price_ids || []).some(Boolean)) caveats.push("Price unavailable");
  caveats.push("Charge amount unavailable");
  return caveats;
}

async function assertStoryFacts(story, entry) {
  const expected = entry.expected;
  const identity = expected.identity;
  const facts = await readFactRows(story);
  const fact = (label) => facts.find((row) => row.label === label);

  await expect(story.locator("h1").first()).toContainText(identity.customer_name);
  await expect(story.locator(".ax-status-badge").first()).toContainText(statusLabel(expected.lifecycle.status));

  const copyButton = story.locator('button[aria-label="Copy subscription ID"]');
  await expect(copyButton).toBeVisible();
  const displayedSubscriptionId = identity.subscription_processor_id || identity.subscription_id;
  expect(await copyButton.getAttribute("data-clipboard-text")).toBe(displayedSubscriptionId);
  await expect(copyButton).toContainText(displayedSubscriptionId);

  const customer = fact("Customer");
  expect(customer?.value).toBe(identity.customer_name);
  expect(customer?.actions.some((action) => action.href?.includes(`/customers/${identity.customer_id}`))).toBe(true);

  const prices = (expected.facts.price_ids || []).filter(Boolean);
  const plan = fact("Plan / price");
  expect(plan, "production summary must retain its required plan/price fact").toBeTruthy();
  expect(plan.value).toBe(prices[0] || "Price unavailable");

  const period = fact("Current period");
  expect(period, "production summary must retain its required current-period fact").toBeTruthy();
  if (expected.lifecycle.current_period_start && expected.lifecycle.current_period_end) {
    expect(period.times.map(normalizeTimestamp)).toEqual([
      expected.lifecycle.current_period_start,
      expected.lifecycle.current_period_end,
    ].map(normalizeTimestamp));
  } else {
    expect(period.value).toBe("Current period unavailable");
  }

  const cancellation = fact("Cancellation");
  expect(cancellation, "production summary must retain its required cancellation fact").toBeTruthy();
  if (expected.lifecycle.cancel_at_period_end && expected.lifecycle.current_period_end) {
    expect(cancellation.value).toContain("Scheduled for");
    expect(cancellation.times.map(normalizeTimestamp)).toContain(normalizeTimestamp(expected.lifecycle.current_period_end));
  } else if (expected.lifecycle.cancel_at_period_end) {
    expect(cancellation.value).toBe("Scheduled; effective date not shown");
  } else {
    expect(cancellation.value).toBe("No cancellation scheduled");
  }

  const renewal = fact("Renews / ends");
  expect(renewal, "production summary must retain its required renewal fact").toBeTruthy();
  if (expected.lifecycle.current_period_end) {
    expect(renewal.times.map(normalizeTimestamp)).toContain(normalizeTimestamp(expected.lifecycle.current_period_end));
  } else {
    expect(renewal.value).toBe("Renewal date unavailable");
  }

  expect(fact("Amount (MRR)")?.value).toBe("Unavailable");
  const caveats = expectedCaveats(entry);
  const evidence = fact("Billing evidence");
  if (caveats.length) expect(evidence?.value).toBe(caveats.join(", "));
  else expect(evidence).toBeUndefined();

  const quantities = expected.facts.quantities || [];
  const seats = fact("Seats / quantity");
  if (quantities.length) expect(seats?.value).toBe(String(quantities[0]));
  else expect(seats).toBeUndefined();

  if (entry.variation_id === "dunning_active") {
    expect(fact("Dunning")).toBeTruthy();
  } else {
    expect(fact("Dunning")).toBeUndefined();
  }

  return {
    facts,
    displayed_subscription_id: displayedSubscriptionId,
    status_label: statusLabel(expected.lifecycle.status),
  };
}

async function assertActionAvailability(story, entry) {
  const primary = (await story.locator("[data-ax-action-band] [data-ax-primary-action]").allInnerTexts())
    .map(normalizeText);
  const more = story.locator("#subscription-action-menu");
  await expect(more.locator("summary")).toHaveText(/More actions/);
  await more.locator("summary").click();
  await expect(more).toHaveAttribute("open", "");
  const menuItems = await more.getByRole("menuitem").allInnerTexts();
  const itemStartsWith = (label) => menuItems.some((text) => normalizeText(text).startsWith(label));

  if (["active", "incomplete_evidence", "populated"].includes(entry.variation_id)) {
    expect(primary).toContain("Change plan");
    expect(primary).toContain("Cancel renewal");
  }
  if (entry.variation_id === "scheduled_cancellation") {
    expect(primary).not.toContain("Cancel renewal");
    expect(itemStartsWith("Resume subscription")).toBe(true);
    const renewal = await readFactRows(story).then((facts) => facts.find((row) => row.label === "Renews / ends"));
    expect(renewal?.actions.some((action) => action.text.startsWith("Change") && action.name ===
      `Change renewal for subscription ${entry.expected.identity.subscription_processor_id}`)).toBe(true);
  }
  if (entry.variation_id === "braintree_pruned") {
    expect(primary).not.toContain("Change plan");
    expect(primary).not.toContain("Cancel renewal");
  }

  return { primary_actions: primary, menu_items: menuItems.map(normalizeText) };
}

async function runRenderCase(page, testCase, manifestDigest, runId, testInfo) {
  const { entry, width, theme, kind, key } = testCase;
  const browserDiagnostics = { consoleErrors: [], failedRequests: [], storybookCssResponses: [] };
  page.on("console", (message) => {
    if (message.type() === "error") browserDiagnostics.consoleErrors.push(message.text());
  });
  page.on("requestfailed", (request) => {
    browserDiagnostics.failedRequests.push({ url: request.url(), error: request.failure()?.errorText || "unknown" });
  });
  page.on("response", (response) => {
    if (response.url().includes("/dev/storybook/assets/storybook-css-")) {
      browserDiagnostics.storybookCssResponses.push({ url: response.url(), status: response.status() });
    }
  });
  const route = mountedStoryPath(entry);
  const row = {
    key,
    test_id: testInfo.title,
    variation_key: entry.key,
    generated_url: entry.url,
    url: route,
    scenario_id: entry.scenario_id,
    state: entry.scenario_id,
    width,
    theme,
    case_kind: kind,
    actor: entry.actor,
    job: entry.job,
    source: entry.input_source,
    renderer: entry.production_renderer,
    lane: entry.proof_lane,
    route_variation_id: entry.route_variation_id,
    status: "failed",
    assertions: {},
  };

  try {
    await page.setViewportSize({ width, height: 900 });
    await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
    await page.goto(`/__e2e__/login?to=${encodeURIComponent(route)}`);
    await expect.poll(() => {
      const current = new URL(page.url());
      return `${current.pathname}${current.search}`;
    }).toBe(route);

    const previewId = `${entry.variation_id.replaceAll("_", "-")}-component`;
    const preview = page.locator(`#${previewId}`);
    await expect(preview, `generated variation preview ${previewId} should render`).toBeVisible();
    const story = preview.locator(".psb-sandbox").first();
    await expect(story, "the direct Storybook variation should render actual production content").toBeVisible();
    await setSettledThemeForScan(page, theme);
    await page.locator("html").evaluate((element) => element.classList.add("accrue-admin"));
    await page.evaluate(async () => {
      if (document.fonts?.ready) await document.fonts.ready;
      await Promise.all([...document.images].map((image) => image.decode().catch(() => undefined)));
    });
    await expect(story.locator("h1").first()).toBeVisible();
    const assets = await assertStorybookAssetsLoaded(page, route);

    const viewport = await page.evaluate(() => ({ width: window.innerWidth, clientWidth: document.documentElement.clientWidth }));
    expect(viewport.width).toBe(width);
    const themeState = await story.evaluate((element) => {
      const summary = element.querySelector(".ax-summary-card");
      const summaryStyle = summary ? getComputedStyle(summary) : null;
      return {
        dataTheme: element.getAttribute("data-theme"),
        sandboxClasses: element.className,
        darkShim: element.classList.contains("ax-theme-dark-shim"),
        base: getComputedStyle(element).getPropertyValue("--ax-base").trim().toLowerCase(),
        summaryBackground: summaryStyle?.backgroundColor || "",
        summaryColor: summaryStyle?.color || "",
        summaryFontSize: summaryStyle?.fontSize || "",
        summaryDisplay: summaryStyle?.display || "",
        rootClasses: document.documentElement.className,
        matchingStyles: [...document.styleSheets].flatMap((sheet) => {
          try {
            return [...sheet.cssRules].filter((rule) => rule.cssText.includes(".ax-summary-card")).map((rule) => rule.cssText);
          } catch (_error) {
            return [];
          }
        }),
        inlineStyles: [...document.querySelectorAll("style")].map((style) => ({
          nonce: style.nonce,
          text: style.textContent,
        })),
        stylesheets: [...document.styleSheets].map((sheet) => ({
          href: sheet.href,
          loaded: Boolean(sheet.cssRules),
        })),
      };
    });
    row.applied_theme = themeState;
    expect(themeState.dataTheme).toBe(theme);
    expect(themeState.darkShim).toBe(theme === "dark");
    expect(themeState.summaryDisplay, "committed subscription CSS must apply to the actual summary").toBe("flex");
    row.fact_rows = await readFactRows(story);

    const content = await assertStoryFacts(story, entry);
    const actions = await assertActionAvailability(story, entry);
    const actualRoute = new URL(page.url());
    expect(actualRoute.searchParams.get("variation_id")).toBe(entry.route_variation_id);
    expect(actualRoute.pathname).toContain("/billing/dev/storybook/");

    const visibleText = await story.innerText();
    row.actual_content = {
      text_sha256: sha256(visibleText),
      text_length: visibleText.length,
      title: normalizeText(await story.locator("h1").first().innerText()),
      displayed_subscription_id: content.displayed_subscription_id,
      status_label: content.status_label,
      facts: content.facts,
    };
    row.viewport = viewport;
    row.applied_theme = themeState;
    row.served_assets = assets;
    row.browser_diagnostics = browserDiagnostics;
    row.actions = actions;
    row.assertions = {
      direct_route: true,
      actual_content: true,
      identity: true,
      facts: true,
      actions: true,
      theme: true,
      served_assets: true,
    };
    row.status = "passed";
  } catch (error) {
    row.error = String(error?.message || error).split("\n")[0];
    throw error;
  } finally {
    row.browser_diagnostics = browserDiagnostics;
    row.completed_at = new Date().toISOString();
    row.manifest_sha256 = manifestDigest;
    appendResult(runId, row);
  }
}

function reconcileResults(manifest, cases, manifestDigest) {
  const errors = [];
  const entries = new Map(manifest.entries.map((entry) => [entry.key, entry]));
  const expectedCases = createCases(manifest);
  const expectedKeys = expectedCases.map((testCase) => testCase.key);
  const actualKeys = cases.map((row) => row.key);
  const counts = new Map();
  for (const key of actualKeys) counts.set(key, (counts.get(key) || 0) + 1);

  for (const key of expectedKeys) {
    if (!counts.has(key)) errors.push(`missing browser result: ${key}`);
    if ((counts.get(key) || 0) > 1) errors.push(`duplicate browser result: ${key}`);
  }
  for (const key of actualKeys) {
    if (!expectedKeys.includes(key)) errors.push(`unexpected browser result: ${key}`);
  }

  const actualVariationKeys = new Set(cases.map((row) => row.variation_key));
  for (const key of entries.keys()) {
    if (!actualVariationKeys.has(key)) errors.push(`manifest variation was not rendered: ${key}`);
  }
  for (const key of actualVariationKeys) {
    if (!entries.has(key)) errors.push(`rendered variation is absent from manifest: ${key}`);
  }

  for (const row of cases) {
    const entry = entries.get(row.variation_key);
    if (!entry) continue;
    if (row.status !== "passed") errors.push(`browser result did not pass: ${row.key}`);
    if (row.manifest_sha256 !== manifestDigest) errors.push(`manifest digest mismatch: ${row.key}`);
    if (row.scenario_id !== entry.scenario_id || row.source !== entry.input_source ||
      row.renderer !== entry.production_renderer || row.lane !== entry.proof_lane) {
      errors.push(`attribution mismatch: ${row.key}`);
    }
    if (!row.assertions?.direct_route || !row.assertions?.actual_content ||
      !row.assertions?.identity || !row.assertions?.facts || !row.assertions?.served_assets) {
      errors.push(`actual browser content evidence is missing: ${row.key}`);
    }
    if (!/^[a-f0-9]{64}$/.test(row.actual_content?.text_sha256 || "")) {
      errors.push(`rendered DOM content digest is missing: ${row.key}`);
    }
    if (row.viewport?.width !== row.width || row.applied_theme?.dataTheme !== row.theme) {
      errors.push(`viewport or rendered theme mismatch: ${row.key}`);
    }
    try {
      const actualUrl = new URL(row.url, "http://phase252.local");
      if (actualUrl.searchParams.get("variation_id") !== entry.route_variation_id) {
        errors.push(`wrong direct variation route: ${row.key}`);
      }
    } catch {
      errors.push(`invalid rendered route: ${row.key}`);
    }
  }

  for (const state of CANONICAL_STATES) {
    for (const width of WIDTHS) {
      const light = cases.find((row) => row.state === state && row.width === width && row.theme === "light");
      const dark = cases.find((row) => row.state === state && row.width === width && row.theme === "dark");
      if (light && dark && light.applied_theme && dark.applied_theme) {
        if (light.applied_theme.darkShim || !dark.applied_theme.darkShim) {
          errors.push(`light/dark theme selection is incorrect: ${state} at ${width}px`);
        }
      }
    }
  }

  return errors;
}

module.exports = {
  CANONICAL_STATES,
  RESULT_PATH,
  WIDTHS,
  THEMES,
  appendResult,
  beginResults,
  createCases,
  mountedStoryPath,
  readManifest,
  readResults,
  reconcileResults,
  runRenderCase,
};
