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
const RESULT_ID = process.env.PHASE252_RESULT_ID;
if (RESULT_ID && !/^[a-z0-9-]{1,96}$/.test(RESULT_ID)) {
  throw new Error("PHASE252_RESULT_ID must be a short lowercase alphanumeric run id");
}
const RESULT_PATH = path.join(RESULT_DIR, RESULT_ID ? "render-results-" + RESULT_ID + ".json" : "render-results.json");
const CANONICAL_STATES = ["active", "scheduled_cancellation", "incomplete_evidence"];
const WIDTHS = [320, 1280];
const THEMES = ["light", "dark"];
const UI_PREDICATE_ASSERTION_REFERENCES = {
  "UI-E1-loading": ["settled_content_visible", "loading_artifacts_absent"],
  "UI-E1-error": ["negative_controls.invalid_route", "negative_controls.missing_variation", "negative_controls.metadata_only", "authority_regression"],
  "UI-E1-overflow": ["document_and_required_content_geometry", "keyboard_focus_visible"],
  "UI-E1-long-text": ["ordinary_content_complete", "held_out_long_text_complete", "full_id_copy"],
  "UI-E2-empty": ["required_facts_present", "optional_rows_omitted", "scoped_not_found_regression"],
  "UI-E2-loading": ["settled_content_visible", "loading_artifacts_absent"],
  "UI-E2-error": ["negative_controls.invalid_route", "negative_controls.missing_variation", "negative_controls.metadata_only", "authority_regression"],
  "UI-E2-populated": ["canonical_render_attribution", "actual_facts_and_actions"],
  "UI-E2-partial": ["unavailable_values_and_ordered_caveats"],
  "UI-E2-overflow": ["document_and_required_content_geometry", "keyboard_focus_visible"],
  "UI-E2-zero-one-many": ["optional_rows_and_action_groups_follow_inputs"],
  "UI-E2-long-text": ["ordinary_content_complete", "held_out_long_text_complete", "full_id_copy"],
  "UI-E3-empty": ["required_facts_present", "optional_rows_omitted", "scoped_not_found_regression"],
  "UI-E3-loading": ["settled_content_visible", "loading_artifacts_absent"],
  "UI-E3-error": ["negative_controls.invalid_route", "negative_controls.missing_variation", "negative_controls.metadata_only", "authority_regression"],
  "UI-E3-populated": ["canonical_render_attribution", "actual_facts_and_actions"],
  "UI-E3-partial": ["unavailable_values_and_ordered_caveats"],
  "UI-E3-overflow": ["document_and_required_content_geometry", "keyboard_focus_visible"],
  "UI-E3-zero-one-many": ["optional_rows_and_action_groups_follow_inputs"],
  "UI-E3-long-text": ["ordinary_content_complete", "held_out_long_text_complete", "full_id_copy"],
};

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
    human_judgment: false,
    generated_at: new Date().toISOString(),
    ui_predicate_catalog: UI_PREDICATE_ASSERTION_REFERENCES,
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

async function assertCurrentStorybookAssets(page, assets) {
  const cssResponse = await page.request.get(assets.cssHref);
  const jsResponse = await page.request.get(assets.jsHref);
  const servedCss = await cssResponse.text();
  const servedJs = await jsResponse.text();
  const expectedCss = fs.readFileSync(path.join(REPO_ROOT, "accrue_admin/priv/static/storybook.css"), "utf8");
  const expectedJs = fs.readFileSync(path.join(REPO_ROOT, "accrue_admin/priv/static/storybook.js"), "utf8");

  expect(cssResponse.ok(), "current Storybook CSS asset responds successfully").toBe(true);
  expect(jsResponse.ok(), "current Storybook JS asset responds successfully").toBe(true);
  expect(servedCss, "served Storybook CSS matches the committed bundle exactly").toBe(expectedCss);
  expect(servedJs, "served Storybook JS matches the committed bundle exactly").toBe(expectedJs);
  return { storybook_css_sha256: sha256(servedCss), storybook_js_sha256: sha256(servedJs) };
}

async function assertUiPredicateContract(page, preview, story, entry, testCase) {
  const ui = await story.evaluate((element) => {
    const viewportWidth = window.innerWidth;
    const probe = (node, label) => {
      const rect = node.getBoundingClientRect();
      const style = getComputedStyle(node);
      let clippingAncestor = null;
      const contentBounds = (element) => {
        const bounds = element.getBoundingClientRect();
        const left = bounds.left + element.clientLeft;
        const top = bounds.top + element.clientTop;
        return {
          left,
          right: left + element.clientWidth,
          top,
          bottom: top + element.clientHeight,
        };
      };
      for (let current = node.parentElement; current; current = current.parentElement) {
        const ancestorStyle = getComputedStyle(current);
        const bounds = contentBounds(current);
        const clipsX = current.clientWidth > 0 && ["hidden", "clip"].includes(ancestorStyle.overflowX) &&
          (rect.left < bounds.left - 1 || rect.right > bounds.right + 1);
        const clipsY = current.clientHeight > 0 && ["hidden", "clip"].includes(ancestorStyle.overflowY) &&
          (rect.top < bounds.top - 1 || rect.bottom > bounds.bottom + 1);
        if (clipsX || clipsY) {
          clippingAncestor = current.className || current.tagName.toLowerCase();
          break;
        }
      }
      const textClipped =
        (node.scrollWidth > node.clientWidth + 1 && ["hidden", "clip"].includes(style.overflowX)) ||
        (node.scrollHeight > node.clientHeight + 1 && ["hidden", "clip"].includes(style.overflowY)) ||
        (node.scrollWidth > node.clientWidth + 1 && style.textOverflow === "ellipsis");
      return {
        label,
        text: node.textContent.replace(/\s+/g, " ").trim(),
        left: rect.left,
        right: rect.right,
        width: rect.width,
        height: rect.height,
        clientWidth: node.clientWidth,
        scrollWidth: node.scrollWidth,
        clientHeight: node.clientHeight,
        scrollHeight: node.scrollHeight,
        textClipped,
        clippingAncestor,
        outsideViewport: rect.left < -1 || rect.right > viewportWidth + 1,
      };
    };
    const summaryRows = [...element.querySelectorAll(".ax-summary-list-row")];
    const summary = element.querySelector(".ax-summary-card");
    const idButton = element.querySelector('button[aria-label="Copy subscription ID"]');
    const menu = element.querySelector("#subscription-action-menu");
    const menuTrigger = menu?.querySelector("summary");
    const menuPanel = menu?.querySelector('[role="menu"]');
    const actionBand = element.querySelector("[data-ax-action-band]");
    const required = [
      ...element.querySelectorAll("h1, .ax-id-badge-text, .ax-summary-list-key, .ax-summary-list-value, .ax-summary-list-actions a, .ax-summary-list-actions button, [data-ax-action-band] [data-ax-primary-action], [data-ax-action-band] summary, [role=menuitem]"),
    ];
    const actionTargets = actionBand
      ? [...actionBand.querySelectorAll(".ax-button, summary")].map((target) => probe(target, target.getAttribute("aria-label") || target.textContent.trim()))
      : [];
    const grid = summaryRows[0] ? getComputedStyle(summaryRows[0]) : null;
    const root = document.documentElement;
    const body = document.body;
    const statusDot = element.querySelector(".ax-status-dot");
    const rowActions = [...element.querySelectorAll(".ax-summary-list-actions a, .ax-summary-list-actions button")].map((action) => ({
      visibleText: action.innerText.replace(/\s+/g, " ").trim(),
      accessibleName: action.getAttribute("aria-label") || "",
      type: action.getAttribute("type"),
      tag: action.tagName.toLowerCase(),
    }));
    const actionGroups = [...element.querySelectorAll('[role="group"]')].map((group) => ({
      label: group.getAttribute("aria-label") || "",
      items: group.querySelectorAll('[role="menuitem"]').length,
    }));
    const ratio = (foreground, background) => {
      const luminance = (color) => {
        const values = color.match(/[\d.]+/g)?.slice(0, 3).map(Number);
        if (!values || values.length !== 3) return null;
        const channels = values.map((value) => {
          const normalized = value / 255;
          return normalized <= 0.04045 ? normalized / 12.92 : ((normalized + 0.055) / 1.055) ** 2.4;
        });
        return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
      };
      const first = luminance(foreground);
      const second = luminance(background);
      if (first === null || second === null) return 0;
      const [lighter, darker] = [first, second].sort((left, right) => right - left);
      return (lighter + 0.05) / (darker + 0.05);
    };
    const title = element.querySelector("h1");
    const idText = element.querySelector(".ax-id-badge-text");
    const firstKey = element.querySelector(".ax-summary-list-key");
    const firstValue = element.querySelector(".ax-summary-list-value");
    const titleStyle = title ? getComputedStyle(title) : null;
    const keyStyle = firstKey ? getComputedStyle(firstKey) : null;
    const valueStyle = firstValue ? getComputedStyle(firstValue) : null;
    const summaryBackground = summary ? getComputedStyle(summary).backgroundColor : "";
    return {
      viewportWidth,
      document: { clientWidth: root.clientWidth, scrollWidth: Math.max(root.scrollWidth, body.scrollWidth) },
      story: probe(element, "story"),
      title: probe(element.querySelector("h1"), "subscription title"),
      required: required.map((node) => probe(node, node.className || node.tagName.toLowerCase())),
      actionTargets,
      summaryColumns: grid ? grid.gridTemplateColumns.trim().split(/\s+/).length : 0,
      summaryRowCount: summaryRows.length,
      headings: {
        h1: element.querySelectorAll("h1").length,
        h2: element.querySelectorAll("h2").length,
        h2Text: element.querySelector("h2")?.textContent.replace(/\s+/g, " ").trim() || "",
      },
      definitionLists: element.querySelectorAll("dl").length,
      terms: element.querySelectorAll("dl dt").length,
      definitions: element.querySelectorAll("dl dd").length,
      loadingArtifacts: [...element.querySelectorAll(".ax-skeleton, progress, [role=progressbar]")].length,
      statusDotHidden: statusDot?.getAttribute("aria-hidden") === "true",
      copyButton: idButton
        ? { type: idButton.type, name: idButton.getAttribute("aria-label"), value: idButton.dataset.clipboardText, visible: idButton.querySelector(".ax-id-badge-text")?.textContent || "" }
        : null,
      rowActions,
      menu: menu && menuTrigger && menuPanel
        ? {
            triggerName: menuTrigger.innerText.replace(/\s+/g, " ").trim(),
            haspopup: menuTrigger.getAttribute("aria-haspopup"),
            role: menuPanel.getAttribute("role"),
            label: menuPanel.getAttribute("aria-label"),
            groups: actionGroups,
            items: [...menuPanel.querySelectorAll('[role="menuitem"]')].map((item) => item.innerText.replace(/\s+/g, " ").trim()),
            panel: probe(menuPanel, "More actions menu"),
          }
        : null,
      themeTokens: {
        base: getComputedStyle(element).getPropertyValue("--ax-base").trim().toLowerCase(),
        elevated: getComputedStyle(element).getPropertyValue("--ax-elevated").trim().toLowerCase(),
        primary: getComputedStyle(element).getPropertyValue("--ax-primary").trim().toLowerCase(),
      },
      typography: {
        bodyFont: getComputedStyle(element).fontFamily,
        titleFont: titleStyle?.fontFamily || "",
        identifierFont: idText ? getComputedStyle(idText).fontFamily : "",
        bodySize: getComputedStyle(element).fontSize,
        titleSize: titleStyle?.fontSize || "",
        titleWeight: titleStyle?.fontWeight || "",
        titleLineHeight: titleStyle?.lineHeight || "",
        labelSize: keyStyle?.fontSize || "",
        valueSize: valueStyle?.fontSize || "",
      },
      contrast: {
        title: titleStyle ? ratio(titleStyle.color, summaryBackground) : 0,
        factValue: valueStyle ? ratio(valueStyle.color, summaryBackground) : 0,
      },
      summaryDisplay: summary ? getComputedStyle(summary).display : "",
    };
  });
  const previewWidth = await preview.evaluate((element) => element.getBoundingClientRect().width);

  expect(ui.document.scrollWidth, "UI-E1-overflow / UI-E2-overflow / UI-E3-overflow: document has no horizontal overflow").toBeLessThanOrEqual(ui.document.clientWidth + 1);
  expect(ui.story.outsideViewport, "production summary remains within the browser viewport").toBe(false);
  expect(ui.story.width, "the subscription preview keeps usable width at each viewport").toBeGreaterThanOrEqual(testCase.width === 1280 ? 640 : 250);
  expect(ui.required.filter((item) => item.outsideViewport || item.textClipped || item.clippingAncestor), "required title, IDs, facts, labels, and menu content are not clipped").toEqual([]);
  expect(ui.summaryColumns, "summary rows use the agreed responsive column count").toBe(testCase.width < 600 ? 1 : 3);
  expect(ui.summaryRowCount).toBeGreaterThan(0);
  expect(previewWidth, "the Storybook preview column uses the story's full-width layout").toBeGreaterThanOrEqual(testCase.width === 1280 ? 680 : 250);
  expect(ui.actionTargets.length).toBeGreaterThan(0);
  expect(ui.actionTargets.filter((target) => target.height < 44), "UI action targets retain a 44px minimum at both widths").toEqual([]);
  expect(ui.headings).toMatchObject({ h1: 1, h2: 1, h2Text: "Subscription actions" });
  expect(ui.definitionLists).toBe(1);
  expect(ui.terms).toBeGreaterThan(0);
  expect(ui.definitions).toBeGreaterThanOrEqual(ui.terms);
  expect(ui.loadingArtifacts, "settled stories do not fabricate loading state").toBe(0);
  expect(ui.statusDotHidden).toBe(true);
  expect(ui.copyButton).toMatchObject({ type: "button", name: "Copy subscription ID" });
  expect(ui.copyButton.visible).toBe(entry.expected.identity.subscription_processor_id || entry.expected.identity.subscription_id);
  expect(ui.copyButton.value).toBe(entry.expected.identity.subscription_processor_id || entry.expected.identity.subscription_id);
  expect(ui.menu).toMatchObject({ triggerName: "More actions ▾", haspopup: "menu", role: "menu", label: "More actions" });
  expect(ui.menu.groups.every((group) => group.label && group.items > 0), "empty action groups are omitted and every menu group is named").toBe(true);

  const expectedBase = testCase.theme === "light" ? "#fafbfc" : "#0f1318";
  expect(ui.themeTokens, `current Storybook CSS resolves the ${testCase.theme} Accrue base token`).toMatchObject({ base: expectedBase });
  expect(ui.typography.bodyFont).toContain("Geist");
  expect(ui.typography.titleFont).toContain("Geist");
  expect(ui.typography.identifierFont).toContain("Geist Mono");
  expect(ui.typography).toMatchObject({ bodySize: "16px", titleSize: "28px", titleWeight: "600", labelSize: "12px", valueSize: "14px" });
  expect(Number.parseFloat(ui.typography.titleLineHeight)).toBeGreaterThanOrEqual(33);
  expect(ui.contrast.title, "subscription heading meets readable text contrast").toBeGreaterThanOrEqual(4.5);
  expect(ui.contrast.factValue, "subscription facts meet readable text contrast").toBeGreaterThanOrEqual(4.5);

  const copyButton = story.locator('button[aria-label="Copy subscription ID"]');
  await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
  const copyValue = await copyButton.getAttribute("data-clipboard-text");
  await copyButton.click();
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).toBe(copyValue);

  const firstRowAction = story.locator(".ax-summary-list-actions a, .ax-summary-list-actions button").first();
  await copyButton.focus();
  await page.keyboard.press("Tab");
  await expect(firstRowAction, "keyboard tab order follows the rendered summary order").toBeFocused();
  await page.keyboard.press("Shift+Tab");
  await expect(copyButton).toBeFocused();
  const focusStyle = await copyButton.evaluate((button) => {
    const style = getComputedStyle(button);
    const rect = button.getBoundingClientRect();
    return {
      visible: button.matches(":focus-visible"),
      outlineWidth: Number.parseFloat(style.outlineWidth),
      outlineOffset: Number.parseFloat(style.outlineOffset),
      boxShadow: style.boxShadow,
      left: rect.left,
      right: rect.right,
    };
  });
  expect(focusStyle.visible).toBe(true);
  expect(focusStyle.outlineWidth).toBeGreaterThanOrEqual(2);
  expect(focusStyle.outlineOffset).toBeGreaterThanOrEqual(2);
  expect(focusStyle.left - focusStyle.outlineOffset).toBeGreaterThanOrEqual(-1);
  expect(focusStyle.right + focusStyle.outlineOffset).toBeLessThanOrEqual(testCase.width + 1);

  const metrics = { ...ui, focusStyle };
  if (entry.variation_id === "active" && testCase.width === 320) {
    metrics.heldOut = await assertHeldOutLongText(page, story, testCase.theme);
  }
  return metrics;
}

async function assertHeldOutLongText(page, ordinaryStory, theme) {
  const heldOut = await ordinaryStory.evaluate((element) => {
    const clone = element.cloneNode(true);
    clone.dataset.phase252HeldOut = "long-text";
    const longName = "Acme Research Cooperative for Federated Interoperability and International Subscription Operations";
    const longId = `sub_${"held_out_identifier_segment_".repeat(4)}end`;
    clone.querySelector("h1").textContent = longName;
    const customerRow = [...clone.querySelectorAll(".ax-summary-list-row")].find((row) =>
      row.querySelector("dt")?.textContent.trim() === "Customer"
    );
    customerRow.querySelector("dd.ax-summary-list-value").textContent = longName;
    const idButton = clone.querySelector('button[aria-label="Copy subscription ID"]');
    idButton.id = "subscription-summary-id-phase252-held-out";
    idButton.dataset.clipboardText = longId;
    idButton.title = longId;
    idButton.querySelector(".ax-id-badge-text").textContent = longId;
    element.after(clone);
    return { longName, longId };
  });
  const clone = page.locator('[data-phase252-held-out="long-text"]');
  await expect(clone.locator("h1")).toHaveText(heldOut.longName);
  await expect(clone.locator(".ax-summary-list-row").first().locator("dt")).toBeVisible();
  const customer = clone.locator(".ax-summary-list-row").filter({ hasText: "Customer" }).locator("dd.ax-summary-list-value");
  await expect(customer).toContainText(heldOut.longName);
  const copyButton = clone.locator('button[aria-label="Copy subscription ID"]');
  await expect(copyButton.locator(".ax-id-badge-text")).toHaveText(heldOut.longId);
  expect(await copyButton.getAttribute("data-clipboard-text")).toBe(heldOut.longId);
  await copyButton.evaluate((button) => window.storybook.Hooks.Clipboard.mounted.call({ el: button }));
  await copyButton.click();
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).toBe(heldOut.longId);
  const metrics = await clone.evaluate((element) => {
    const title = element.querySelector("h1");
    const customerValue = [...element.querySelectorAll(".ax-summary-list-row")].find((row) => row.querySelector("dt")?.textContent.trim() === "Customer").querySelector("dd.ax-summary-list-value");
    const id = element.querySelector(".ax-id-badge-text");
    return [title, customerValue, id].map((node, index) => {
      const rect = node.getBoundingClientRect();
      return {
        field: ["long title", "long customer", "long identifier"][index],
        left: rect.left,
        right: rect.right,
        clientWidth: node.clientWidth,
        scrollWidth: node.scrollWidth,
        clientHeight: node.clientHeight,
        scrollHeight: node.scrollHeight,
        whiteSpace: getComputedStyle(node).whiteSpace,
        textOverflow: getComputedStyle(node).textOverflow,
      };
    });
  });
  expect(metrics.every((metric) => metric.scrollWidth <= metric.clientWidth + 1)).toBe(true);
  expect(metrics.every((metric) => metric.whiteSpace !== "nowrap")).toBe(true);
  expect(metrics.every((metric) => metric.left >= -1 && metric.right <= 321)).toBe(true);
  return { theme, label: "held-out long text (not manifest fixture)", name: heldOut.longName, id: heldOut.longId, metrics };
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

async function captureCanonicalScreenshot(preview, testCase) {
  const configuredDirectory = process.env.PHASE252_SCREENSHOT_DIR;
  if (!configuredDirectory || testCase.kind !== "canonical") return null;

  const captureRoot = path.resolve(REPO_ROOT, "accrue_admin/tmp/phase252/ci-results");
  const directory = path.resolve(configuredDirectory);
  const expectedDirectory = path.join(captureRoot, RESULT_ID, "screenshots");
  if (directory !== expectedDirectory) {
    throw new Error("Phase 252 screenshots must stay inside the unique private CI result directory");
  }

  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  const name = `${testCase.entry.scenario_id}-${testCase.width}-${testCase.theme}.png`;
  const destination = path.join(directory, name);
  const bytes = await preview.screenshot({ path: destination, animations: "disabled" });
  return {
    path: path.relative(REPO_ROOT, destination).split(path.sep).join("/"),
    sha256: sha256(bytes),
    state: testCase.entry.scenario_id,
    width: testCase.width,
    theme: testCase.theme,
  };
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
  const browserDiagnostics = { consoleErrors: [], failedRequests: [], storybookCssResponses: [], storybookFontResponses: [] };
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
    if (response.url().includes("/dev/storybook/assets/geist-")) {
      browserDiagnostics.storybookFontResponses.push({ url: response.url(), status: response.status() });
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
    await page.evaluate(async () => {
      if (document.fonts?.ready) await document.fonts.ready;
      await Promise.all([...document.images].map((image) => image.decode().catch(() => undefined)));
    });
    await expect(story.locator("h1").first()).toBeVisible();
    const assets = await assertStorybookAssetsLoaded(page, route);
    const assetIdentity = await assertCurrentStorybookAssets(page, assets);
    const fonts = await page.evaluate(() => ({
      status: document.fonts.status,
      sans: document.fonts.check('400 16px "Geist"'),
      mono: document.fonts.check('400 12px "Geist Mono"'),
    }));
    expect(fonts, "Storybook uses the current self-hosted Geist font faces").toMatchObject({ status: "loaded", sans: true, mono: true });
    expect(browserDiagnostics.storybookFontResponses.map((response) => response.status).sort()).toEqual([200, 200]);

    const viewport = await page.evaluate(() => ({ width: window.innerWidth, clientWidth: document.documentElement.clientWidth }));
    expect(viewport.width).toBe(width);
    await expect.poll(async () => story.evaluate((element) => ({
      mode: element.classList.contains("ax-theme-dark-shim") ? "dark" : "light",
      sandboxHasAdminClass: element.classList.contains("accrue-admin"),
      documentRootHasAdminClass: document.documentElement.classList.contains("accrue-admin"),
      darkShim: element.classList.contains("ax-theme-dark-shim"),
    })), { message: `settled Storybook wrapper theme ${theme}` }).toEqual({
      mode: theme,
      sandboxHasAdminClass: true,
      documentRootHasAdminClass: false,
      darkShim: theme === "dark",
    });
    const themeState = await story.evaluate((element) => {
      const summary = element.querySelector(".ax-summary-card");
      const summaryStyle = summary ? getComputedStyle(summary) : null;
      const title = element.querySelector("h1");
      const titleStyle = title ? getComputedStyle(title) : null;
      return {
        mode: element.classList.contains("ax-theme-dark-shim") ? "dark" : "light",
        dataTheme: element.classList.contains("ax-theme-dark-shim") ? "dark" : "light",
        sandboxHasAdminClass: element.classList.contains("accrue-admin"),
        documentRootHasAdminClass: document.documentElement.classList.contains("accrue-admin"),
        sandboxClasses: [...element.classList],
        darkShim: element.classList.contains("ax-theme-dark-shim"),
        base: getComputedStyle(element).getPropertyValue("--ax-base").trim().toLowerCase(),
        summaryBackground: summaryStyle?.backgroundColor || "",
        summaryColor: summaryStyle?.color || "",
        summaryFontSize: summaryStyle?.fontSize || "",
        summaryDisplay: summaryStyle?.display || "",
        titleColor: titleStyle?.color || "",
        titleFontFamily: titleStyle?.fontFamily || "",
        titleFontSize: titleStyle?.fontSize || "",
        titleFontWeight: titleStyle?.fontWeight || "",
      };
    });
    row.applied_theme = themeState;
    expect(themeState.mode).toBe(theme);
    expect(themeState.dataTheme).toBe(theme);
    expect(themeState.sandboxHasAdminClass).toBe(true);
    expect(themeState.documentRootHasAdminClass, "the direct route must not receive a helper-added root class").toBe(false);
    expect(themeState.darkShim).toBe(theme === "dark");
    expect(themeState.summaryDisplay, "committed subscription CSS must apply to the actual summary").toBe("flex");
    expect(themeState.titleFontFamily).toContain("Geist");
    expect(themeState.titleFontSize).toBe("28px");
    expect(themeState.titleFontWeight).toBe("600");
    const screenshot = await captureCanonicalScreenshot(preview, testCase);
    if (screenshot) row.screenshot = screenshot;
    row.fact_rows = await readFactRows(story);

    const content = await assertStoryFacts(story, entry);
    const actions = await assertActionAvailability(story, entry);
    const uiMetrics = await assertUiPredicateContract(page, preview, story, entry, testCase);
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
    row.fonts = fonts;
    row.browser_diagnostics = browserDiagnostics;
    row.actions = actions;
    row.ui_metrics = uiMetrics;
    row.ui_predicate_ids = Object.keys(UI_PREDICATE_ASSERTION_REFERENCES);
    row.asset_identity = assetIdentity;
    row.assertions = {
      direct_route: true,
      actual_content: true,
      identity: true,
      facts: true,
      actions: true,
      theme: true,
      served_assets: true,
      fonts_loaded: true,
      settled_content_visible: true,
      loading_artifacts_absent: true,
      document_and_required_content_geometry: true,
      action_targets_44px: true,
      semantic_structure: true,
      keyboard_focus_visible: true,
      full_id_copy: true,
      optional_rows_and_action_groups_follow_inputs: true,
      unavailable_values_and_ordered_caveats: true,
      canonical_render_attribution: kind === "canonical",
      ordinary_content_complete: true,
      held_out_long_text_complete: kind === "canonical" && entry.variation_id === "active" && width === 320,
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
      !row.assertions?.identity || !row.assertions?.facts || !row.assertions?.served_assets ||
      !row.assertions?.fonts_loaded) {
      errors.push(`actual browser content evidence is missing: ${row.key}`);
    }
    if (!/^[a-f0-9]{64}$/.test(row.actual_content?.text_sha256 || "")) {
      errors.push(`rendered DOM content digest is missing: ${row.key}`);
    }
    if (row.viewport?.width !== row.width || row.applied_theme?.dataTheme !== row.theme) {
      errors.push(`viewport or rendered theme mismatch: ${row.key}`);
    }
    if (row.case_kind === "canonical" && row.ui_predicate_ids?.length !== Object.keys(UI_PREDICATE_ASSERTION_REFERENCES).length) {
      errors.push(`UI predicate assertion references are missing: ${row.key}`);
    }
    const requiredUiAssertions = [
      "settled_content_visible", "loading_artifacts_absent", "document_and_required_content_geometry",
      "action_targets_44px", "semantic_structure", "keyboard_focus_visible", "full_id_copy",
      "ordinary_content_complete", "optional_rows_and_action_groups_follow_inputs",
    ];
    if (row.case_kind === "canonical" && requiredUiAssertions.some((assertion) => !row.assertions?.[assertion])) {
      errors.push(`UI predicate assertions did not pass: ${row.key}`);
    }
    if (row.case_kind === "canonical" && row.state === "active" && row.width === 320 &&
      !row.assertions?.held_out_long_text_complete) {
      errors.push(`held-out long-text evidence is missing: ${row.key}`);
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

function runReconcilerNegativeControls(manifest, manifestDigest) {
  const completeRows = createCases(manifest).map((testCase) => {
    const entry = testCase.entry;
    return {
      key: testCase.key,
      variation_key: entry.key,
      url: mountedStoryPath(entry),
      scenario_id: entry.scenario_id,
      state: entry.scenario_id,
      width: testCase.width,
      theme: testCase.theme,
      case_kind: testCase.kind,
      source: entry.input_source,
      renderer: entry.production_renderer,
      lane: entry.proof_lane,
      status: "passed",
      manifest_sha256: manifestDigest,
      viewport: { width: testCase.width },
      applied_theme: { dataTheme: testCase.theme, darkShim: testCase.theme === "dark" },
      ui_predicate_ids: Object.keys(UI_PREDICATE_ASSERTION_REFERENCES),
      assertions: {
        direct_route: true,
        actual_content: true,
        identity: true,
        facts: true,
        actions: true,
        served_assets: true,
        fonts_loaded: true,
        settled_content_visible: true,
        loading_artifacts_absent: true,
        document_and_required_content_geometry: true,
        action_targets_44px: true,
        semantic_structure: true,
        keyboard_focus_visible: true,
        full_id_copy: true,
        ordinary_content_complete: true,
        optional_rows_and_action_groups_follow_inputs: true,
        held_out_long_text_complete: entry.variation_id !== "active" || testCase.width !== 320 || testCase.kind !== "canonical" || testCase.theme === "light" || testCase.theme === "dark",
      },
      actual_content: { text_sha256: "a".repeat(64) },
    };
  });
  const baselineErrors = reconcileResults(manifest, completeRows, manifestDigest);
  if (baselineErrors.length) throw new Error(`valid reconciler control fixture was rejected: ${baselineErrors.join("; ")}`);

  const canonical = completeRows.find((row) => row.case_kind === "canonical");
  const invalidRouteRows = structuredClone(completeRows);
  const invalidRoute = invalidRouteRows.find((row) => row.key === canonical.key);
  invalidRoute.url = `${invalidRoute.url.split("?")[0]}?variation_id=not_a_declared_variation`;
  const invalidRouteErrors = reconcileResults(manifest, invalidRouteRows, manifestDigest);

  const missingRows = completeRows.filter((row) => row.key !== canonical.key);
  const missingErrors = reconcileResults(manifest, missingRows, manifestDigest);

  const metadataOnlyRows = structuredClone(completeRows);
  const metadataOnly = metadataOnlyRows.find((row) => row.key === canonical.key);
  metadataOnly.actual_content = { title: "Acme Research" };
  metadataOnly.assertions.actual_content = false;
  const metadataOnlyErrors = reconcileResults(manifest, metadataOnlyRows, manifestDigest);

  return {
    baseline_accepted: baselineErrors.length === 0,
    invalid_route: { rejected: invalidRouteErrors.some((error) => error.startsWith("wrong direct variation route:")), reasons: invalidRouteErrors },
    missing_variation: { rejected: missingErrors.some((error) => error.startsWith("missing browser result:")), reasons: missingErrors },
    metadata_only: {
      rejected: metadataOnlyErrors.some((error) => error.startsWith("actual browser content evidence is missing:")) &&
        metadataOnlyErrors.some((error) => error.startsWith("rendered DOM content digest is missing:")),
      reasons: metadataOnlyErrors,
    },
  };
}

function recordNegativeControls(runId, controls) {
  const results = readResults();
  if (results.run_id !== runId) throw new Error("Phase 252 browser result ledger belongs to a different launcher run");
  results.negative_controls = controls;
  const canonicalCases = results.cases.filter((row) => row.case_kind === "canonical");
  const allCanonicalCells = canonicalCases.map((row) => row.key);
  const incompleteCells = canonicalCases.filter((row) => row.state === "incomplete_evidence").map((row) => row.key);
  const longTextCells = canonicalCases.filter((row) => row.state === "active" && row.width === 320).map((row) => row.key);
  const errorControls = ["invalid_route", "missing_variation", "metadata_only"];
  results.ui_predicate_coverage = Object.fromEntries(
    Object.entries(UI_PREDICATE_ASSERTION_REFERENCES).map(([id, assertions]) => {
      const stateSensitive = id.endsWith("-partial") ? incompleteCells : allCanonicalCells;
      return [id, {
        assertions,
        cells: id.endsWith("-long-text") ? longTextCells : stateSensitive,
        controls: id.endsWith("-error") ? [...errorControls, "authority_regression"] : [],
      }];
    })
  );
  writeResults(results);
}

module.exports = {
  CANONICAL_STATES,
  RESULT_PATH,
  WIDTHS,
  THEMES,
  UI_PREDICATE_ASSERTION_REFERENCES,
  appendResult,
  beginResults,
  createCases,
  mountedStoryPath,
  readManifest,
  readResults,
  recordNegativeControls,
  reconcileResults,
  runReconcilerNegativeControls,
  runRenderCase,
};
