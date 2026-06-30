const fs = require("fs");
const path = require("path");

const { SURFACES, OVERLAY_TAGS, cellsForSurface } = require("./baseline-manifest.js");

const REPO_ROOT = path.resolve(__dirname, "..", "..");
const PHASE191_DEFECTS_PATH = path.join(REPO_ROOT, ".planning/phases/187-audit-baseline/defects.ndjson");

const PHASE191_VIEWPORTS = Object.freeze([
  { name: "phone-320", width: 320, height: 844 },
  { name: "phone-375", width: 375, height: 844 },
  { name: "tablet-768", width: 768, height: 1024 },
  { name: "desktop-1024", width: 1024, height: 900 },
  { name: "desktop-1440", width: 1440, height: 1000 },
]);

const PHASE191_STATES = Object.freeze([
  "default-populated",
  "empty",
  "loading",
  "error",
  "permission-denied",
  "disconnected-reconnecting",
  "overflow",
  "long-content",
  "interactive-open",
]);

const TAG_ALIASES = Object.freeze({
  "liveview-patch-focus": "live-focus",
  "live-patch-focus": "live-focus",
  "focus-semantics": "focus-trap",
  "copy": "microcopy",
  "copy-recovery": "copy-recovery",
  "copy-specificity": "copy-specificity",
});

function normalizeTag(value) {
  if (!value) return null;

  const normalized = String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

  return TAG_ALIASES[normalized] || normalized || null;
}

function readNdjson(filePath) {
  return fs
    .readFileSync(filePath, "utf8")
    .split(/\r?\n/)
    .filter(Boolean)
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`${filePath}:${index + 1}: ${error.message}`);
      }
    });
}

function stateFromCellId(cellId) {
  return String(cellId || "").split("__")[4] || null;
}

function normalizeDefect(row) {
  const overlayTags = Array.from(
    new Set([...(row.overlay_tags || []), ...(row.tags || [])].map(normalizeTag).filter(Boolean))
  );

  return {
    ...row,
    id: row.id || row.defect_id || row.ax187_id,
    owner_phase: String(row.owner_phase),
    state: row.state || stateFromCellId(row.cell_id),
    overlay_tags: overlayTags,
  };
}

function loadPhase191Defects(filePath = PHASE191_DEFECTS_PATH) {
  return readNdjson(filePath)
    .filter((row) => String(row.owner_phase) === "191")
    .map(normalizeDefect);
}

function phase191PageFlows() {
  return SURFACES.filter((surface) => surface.surface_type === "page-flow");
}

function coercePageFlow(surface) {
  if (typeof surface !== "string") return surface;

  const found = phase191PageFlows().find((flow) => flow.surface === surface);
  if (!found) throw new Error(`Unknown Phase 191 page-flow surface: ${surface}`);
  return found;
}

function seedScenarioForSurface(surface) {
  const flow = coercePageFlow(surface);
  return flow.routeBuilder?.fixture || "dashboard";
}

function resolvePhase191Route(surface, fixtureData = {}) {
  const flow = coercePageFlow(surface);
  const scenario = seedScenarioForSurface(flow);

  return flow.route.replace(/:([a-z_]+)/g, (_match, key) => {
    const value = fixtureData[key] ?? fixtureData[scenario]?.[key] ?? fixtureData[flow.surface]?.[key];
    if (!value) {
      throw new Error(`Missing fixture value "${key}" for Phase 191 route ${flow.surface}`);
    }

    return encodeURIComponent(String(value));
  });
}

async function setPhase191Theme(page, theme) {
  if (!["light", "dark"].includes(theme)) {
    throw new Error(`Unsupported Phase 191 theme: ${theme}`);
  }

  await page.evaluate((value) => {
    document.documentElement.setAttribute("data-theme", value);
    document.documentElement.dataset.theme = value;
    window.localStorage?.setItem("accrue_admin_theme", value);
  }, theme);

  if (typeof page.waitForTimeout === "function") await page.waitForTimeout(50);
}

async function assertNoBodyFocus(page, label = "active element") {
  const active = await page.evaluate(() => {
    const element = document.activeElement;
    return {
      isBody: element === document.body,
      tagName: element?.tagName || "none",
      id: element?.id || "",
      role: element?.getAttribute?.("role") || "",
      text: (element?.textContent || "").trim().replace(/\s+/g, " ").slice(0, 80),
    };
  });

  if (active.isBody) {
    throw new Error(`Phase 191 focus assertion failed: ${label} resolved to document.body`);
  }

  return active;
}

async function assertFocusWithin(page, target, label = "active overlay") {
  const evaluate =
    typeof target === "string"
      ? (callback) => page.locator(target).first().evaluate(callback)
      : (callback) => target.evaluate(callback);

  const result = await evaluate((element) => {
    const active = document.activeElement;
    return {
      containsActive: Boolean(active && element.contains(active)),
      activeLabel: active
        ? `${active.tagName.toLowerCase()}${active.id ? `#${active.id}` : ""}`
        : "none",
    };
  });

  if (!result.containsActive) {
    throw new Error(
      `Phase 191 focus assertion failed: ${label} does not contain active element ${result.activeLabel}`
    );
  }

  return result;
}

async function assertTopPointerTarget(locator, label = "primary control") {
  const result = await locator.evaluate((element) => {
    const rect = element.getBoundingClientRect();
    const style = window.getComputedStyle(element);
    const visible =
      style.display !== "none" &&
      style.visibility !== "hidden" &&
      rect.width > 0 &&
      rect.height > 0;
    const offscreen =
      rect.left < 0 ||
      rect.top < 0 ||
      rect.right > window.innerWidth ||
      rect.bottom > window.innerHeight;

    if (!visible || offscreen) {
      return {
        visible,
        offscreen,
        receivesEvents: false,
        rect: { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom },
        topLabel: "not-tested",
      };
    }

    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    const top = document.elementFromPoint(x, y);

    return {
      visible,
      offscreen,
      receivesEvents: top === element || element.contains(top),
      rect: { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom },
      topLabel: top
        ? `${top.tagName.toLowerCase()}${top.id ? `#${top.id}` : ""}`
        : "none",
    };
  });

  if (!result.visible || result.offscreen || !result.receivesEvents) {
    throw new Error(
      `Phase 191 pointer assertion failed: ${label} is not the top reachable target (${JSON.stringify(result)})`
    );
  }

  return result;
}

async function assertScrollReachable(locator, label = "scroll container") {
  const result = await locator.evaluate((element) => {
    const before = {
      top: element.scrollTop,
      left: element.scrollLeft,
    };
    const overflowY = element.scrollHeight > element.clientHeight;
    const overflowX = element.scrollWidth > element.clientWidth;

    element.scrollTop = element.scrollHeight;
    element.scrollLeft = element.scrollWidth;

    const after = {
      top: element.scrollTop,
      left: element.scrollLeft,
    };

    return {
      before,
      after,
      overflowY,
      overflowX,
      scrollHeight: element.scrollHeight,
      clientHeight: element.clientHeight,
      scrollWidth: element.scrollWidth,
      clientWidth: element.clientWidth,
    };
  });

  if (result.overflowY && result.after.top <= result.before.top) {
    throw new Error(`Phase 191 scroll assertion failed: ${label} cannot scroll vertically`);
  }

  if (result.overflowX && result.after.left <= result.before.left) {
    throw new Error(`Phase 191 scroll assertion failed: ${label} cannot scroll horizontally`);
  }

  return result;
}

async function assertNoHorizontalClip(page, selector = "body", label = selector) {
  const result = await page.evaluate((targetSelector) => {
    const failures = [];
    const documentOverflow = document.documentElement.scrollWidth - document.documentElement.clientWidth;

    for (const element of document.querySelectorAll(targetSelector)) {
      const rect = element.getBoundingClientRect();
      const style = window.getComputedStyle(element);
      if (style.display === "none" || style.visibility === "hidden" || rect.width === 0 || rect.height === 0) {
        continue;
      }

      if (rect.left < -1 || rect.right > window.innerWidth + 1) {
        failures.push({
          text: (element.textContent || element.getAttribute("aria-label") || element.tagName)
            .trim()
            .replace(/\s+/g, " ")
            .slice(0, 80),
          left: rect.left,
          right: rect.right,
          viewport: window.innerWidth,
        });
      }
    }

    return { documentOverflow, failures };
  }, selector);

  if (result.documentOverflow > 1 || result.failures.length > 0) {
    throw new Error(`Phase 191 clipping assertion failed for ${label}: ${JSON.stringify(result)}`);
  }

  return result;
}

async function assertFloatingAdjacentToTrigger(page, trigger, panel, label = "floating panel") {
  const result = await page.evaluate(
    ({ triggerSelector, panelSelector }) => {
      const triggerElement = document.querySelector(triggerSelector);
      const panelElement = document.querySelector(panelSelector);

      if (!triggerElement || !panelElement) {
        return { found: false };
      }

      const triggerRect = triggerElement.getBoundingClientRect();
      const panelRect = panelElement.getBoundingClientRect();
      const verticalGap = Math.min(
        Math.abs(panelRect.top - triggerRect.bottom),
        Math.abs(triggerRect.top - panelRect.bottom)
      );
      const horizontalGap = Math.min(
        Math.abs(panelRect.left - triggerRect.right),
        Math.abs(triggerRect.left - panelRect.right)
      );
      const overlapsX = panelRect.left <= triggerRect.right && panelRect.right >= triggerRect.left;
      const overlapsY = panelRect.top <= triggerRect.bottom && panelRect.bottom >= triggerRect.top;

      return {
        found: true,
        adjacent: (overlapsX && verticalGap <= 16) || (overlapsY && horizontalGap <= 16),
        verticalGap,
        horizontalGap,
        overlapsX,
        overlapsY,
        transformOrigin: window.getComputedStyle(panelElement).transformOrigin,
        trigger: {
          left: triggerRect.left,
          top: triggerRect.top,
          right: triggerRect.right,
          bottom: triggerRect.bottom,
        },
        panel: {
          left: panelRect.left,
          top: panelRect.top,
          right: panelRect.right,
          bottom: panelRect.bottom,
        },
      };
    },
    {
      triggerSelector: typeof trigger === "string" ? trigger : await trigger.evaluate((node) => {
        node.dataset.phase191FloatingTrigger = "true";
        return "[data-phase191-floating-trigger='true']";
      }),
      panelSelector: typeof panel === "string" ? panel : await panel.evaluate((node) => {
        node.dataset.phase191FloatingPanel = "true";
        return "[data-phase191-floating-panel='true']";
      }),
    }
  );

  if (!result.found || !result.adjacent || !result.transformOrigin) {
    throw new Error(`Phase 191 floating assertion failed for ${label}: ${JSON.stringify(result)}`);
  }

  return result;
}

function phase191CoverageRows(defects = loadPhase191Defects()) {
  return defects.map((defect) => ({
    id: defect.id,
    severity: defect.severity,
    surface: defect.surface,
    state: defect.state,
    rubric_dimension: defect.rubric_dimension,
    direct_marker: defect.id,
    overlay_tags: defect.overlay_tags,
    normalized_overlay_tags: defect.overlay_tags.filter((tag) => OVERLAY_TAGS.includes(tag) || tag === "microcopy"),
    source_cell: defect.cell_id,
  }));
}

module.exports = {
  PHASE191_VIEWPORTS,
  PHASE191_STATES,
  loadPhase191Defects,
  phase191PageFlows,
  resolvePhase191Route,
  seedScenarioForSurface,
  setPhase191Theme,
  assertNoBodyFocus,
  assertFocusWithin,
  assertTopPointerTarget,
  assertScrollReachable,
  assertNoHorizontalClip,
  assertFloatingAdjacentToTrigger,
  phase191CoverageRows,
  normalizeTag,
  cellsForSurface,
};
