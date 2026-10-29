"use strict";

// Phase 254 UXQ-02 (D-26..D-30): the accessibility layer for the Phase 253 composition cells.
//
// Two kinds of function live here and the split is deliberate:
//   * pure helpers (colour math, name normalisation, the disposition matcher, the target-size
//     and focus evaluators) that run in Node with no browser, so the register validator and
//     its unit tests import exactly the code the cells run;
//   * page probes that collect raw facts in the browser and hand them to the pure evaluators.
//
// Nothing in this file narrows, excludes or filters what axe reports (D-30). Every violation
// and every incomplete is either auto-resolved by a measured computation, recorded as a
// finding of a probe, or matched to an entry of accrue_admin/e2e/a11y-dispositions.json. The
// source contract in scripts/ci/verify_a11y_dispositions.mjs scans this file to keep it so.

const fs = require("node:fs");

const A11Y_TAGS = Object.freeze(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"]);
const DEFAULT_ROOTS = Object.freeze([".psb-sandbox", "#ax-overlay-root", "#subscription-action-drawer", "#accrue-admin-step-up-dialog"]);
const HIDDEN_MIRROR_PATTERN = /drawer-test-mirror/;
const REQUIRED_TEXT_SCALE = 1.95;
const TEXT_SCALE_STANDARD_FONT = 32; // 200% of Chromium's 16px default
const TEXT_SCALE_FIXED_FONT = 26;
const DEFAULT_STANDARD_FONT = 16;
const DEFAULT_FIXED_FONT = 13;
const TARGET_MINIMUM = 24;
const MOTION_REDUCE_LIMIT_SECONDS = 0.001;
const AAA_PROJECT_TARGETS = Object.freeze({
  "2.3.3": "AAA project target (Animation from Interactions); not an AA conformance claim",
});

// The D-28 deep-probe subset: the named collection and page states, 320/1280 x light/dark.
const DEEP_COLLECTION_STATES = Object.freeze(["one_row", "multiple_rows", "page_boundary", "unavailable", "partial_cursor_error", "filtered_empty"]);
const DEEP_PAGE_VARIATIONS = Object.freeze(["active", "review_cancel_now", "awaiting_step_up", "result_failed"]);
const DEEP_PROBES = Object.freeze(["names", "target_size", "focus", "spacing", "scale", "motion"]);

/** True when a cell key belongs to the D-28 deep-probe subset. */
function isDeepProbeKey(key) {
  const parts = String(key).split("::");
  if (parts[0] === "page") {
    const [, variation, kind, width, theme] = parts;
    return parts.length === 5 && DEEP_PAGE_VARIATIONS.includes(variation) && kind === "viewport" &&
      ["320", "1280"].includes(width) && ["light", "dark"].includes(theme);
  }
  const [variation, kind, width, theme] = parts;
  return parts.length === 4 && DEEP_COLLECTION_STATES.includes(variation) && kind === "viewport" &&
    ["320", "1280"].includes(width) && ["light", "dark"].includes(theme);
}

// ---------------------------------------------------------------------------------------
// Colour (alpha-correct)
// ---------------------------------------------------------------------------------------

/**
 * Parses a computed CSS colour to [r, g, b, a] (0-255 channels, 0-1 alpha). Alpha is kept for
 * rgb()/rgba() in comma and space syntax and for color(srgb r g b / a). A translucent colour
 * is never silently treated as opaque.
 */
function parseColor(value) {
  const text = String(value).trim();
  if (text === "transparent") return [0, 0, 0, 0];
  const legacy = text.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+%?)\s*)?\)$/i);
  const modern = text.match(/^rgba?\(\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s*(?:\/\s*([\d.]+%?)\s*)?\)$/i);
  const rgb = legacy || modern;
  if (rgb) return [Number(rgb[1]), Number(rgb[2]), Number(rgb[3]), parseAlpha(rgb[4])];
  // Modern Chrome serialises color-mix()/relative-colour results as color(srgb r g b [/ a]).
  const srgb = text.match(/^color\(\s*srgb\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s*(?:\/\s*([\d.]+%?)\s*)?\)$/i);
  if (srgb) return [Math.round(Number(srgb[1]) * 255), Math.round(Number(srgb[2]) * 255), Math.round(Number(srgb[3]) * 255), parseAlpha(srgb[4])];
  const oklab = text.match(/^oklab\(\s*([\d.]+%?)\s+([-\d.]+)\s+([-\d.]+)\s*(?:\/\s*([\d.]+%?)\s*)?\)$/i);
  if (oklab) return [...oklabToSrgb(parseLightness(oklab[1]), Number(oklab[2]), Number(oklab[3])), parseAlpha(oklab[4])];
  const oklch = text.match(/^oklch\(\s*([\d.]+%?)\s+([-\d.]+)\s+([-\d.]+)(?:deg)?\s*(?:\/\s*([\d.]+%?)\s*)?\)$/i);
  if (oklch) {
    const hue = (Number(oklch[3]) * Math.PI) / 180;
    return [...oklabToSrgb(parseLightness(oklch[1]), Number(oklch[2]) * Math.cos(hue), Number(oklch[2]) * Math.sin(hue)), parseAlpha(oklch[4])];
  }
  throw new Error(`Unsupported colour: ${value}`);
}

function parseLightness(token) {
  return token.endsWith("%") ? Number(token.slice(0, -1)) / 100 : Number(token);
}

/** Converts OKLab to gamut-clamped 0-255 sRGB channels (Bjorn Ottosson's matrices). */
function oklabToSrgb(lightness, a, b) {
  const l = (lightness + 0.3963377774 * a + 0.2158037573 * b) ** 3;
  const m = (lightness - 0.1055613458 * a - 0.0638541728 * b) ** 3;
  const s = (lightness - 0.0894841775 * a - 1.291485548 * b) ** 3;
  const linear = [
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
  ];
  return linear.map((channel) => {
    const clamped = Math.min(1, Math.max(0, channel));
    const encoded = clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * clamped ** (1 / 2.4) - 0.055;
    return Math.round(encoded * 255);
  });
}

function parseAlpha(token) {
  if (token == null) return 1;
  const value = token.endsWith("%") ? Number(token.slice(0, -1)) / 100 : Number(token);
  return Math.min(1, Math.max(0, value));
}

/** Source-over blend of one [r,g,b,a] colour onto another. */
function blend(top, bottom) {
  const topAlpha = top[3] ?? 1;
  const bottomAlpha = bottom[3] ?? 1;
  const alpha = topAlpha + bottomAlpha * (1 - topAlpha);
  if (alpha === 0) return [0, 0, 0, 0];
  const channel = (index) => (top[index] * topAlpha + bottom[index] * bottomAlpha * (1 - topAlpha)) / alpha;
  return [channel(0), channel(1), channel(2), alpha];
}

/**
 * Composites a stack of colours ordered from the topmost layer to the bottommost onto an
 * opaque canvas (white unless stated) and returns the single resulting [r,g,b,a].
 */
function compositeColor(stack, { canvas = [255, 255, 255, 1] } = {}) {
  let result = canvas;
  for (let index = stack.length - 1; index >= 0; index -= 1) {
    const layer = Array.isArray(stack[index]) ? stack[index] : parseColor(stack[index]);
    result = blend(layer, result);
  }
  return result;
}

function relativeLuminance(rgb) {
  const [r, g, b] = rgb.slice(0, 3).map((channel) => {
    const value = channel / 255;
    return value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/**
 * WCAG contrast of a foreground over a background. A foreground with alpha below 1 is first
 * composited over the (itself composited) background, so a translucent colour cannot read as
 * more contrasty than it renders.
 */
function contrastRatio(foreground, background) {
  const fg = Array.isArray(foreground) ? foreground : parseColor(foreground);
  const bg = compositeColor([Array.isArray(background) ? background : parseColor(background)]);
  const rendered = compositeColor([fg], { canvas: bg });
  const [lighter, darker] = [relativeLuminance(rendered), relativeLuminance(bg)].sort((a, b) => b - a);
  return (lighter + 0.05) / (darker + 0.05);
}

/** Large text per WCAG 1.4.3: at least 24px, or at least 18.66px and bold. */
function isLargeText(fontSizePx, fontWeight) {
  return fontSizePx >= 24 || (fontSizePx >= 18.66 && Number(fontWeight) >= 700);
}

const GRADIENT_COLOR = /rgba?\([^)]*\)|color\([^)]*\)|transparent/gi;

/**
 * Resolves the possible rendered backgrounds behind an element from its ancestor layers,
 * topmost first. Each layer is { color, opacity, image } as computed. Layers are walked until
 * an opaque colour with no image stops the stack; a translucent layer is composited over what
 * lies below it. A gradient contributes one candidate per colour stop (each composited over
 * the base beneath it) plus the base itself, so the ratio can be taken at the worst point.
 * A url() image, or a gradient with no readable stops, cannot be measured and is reported
 * unresolved instead of being guessed.
 */
function resolveBackgroundCandidates(layers, index = 0) {
  if (index >= layers.length) return { candidates: [[255, 255, 255, 1]] };
  const layer = layers[index];
  const color = parseColor(layer.color);
  color[3] *= layer.opacity;
  const image = layer.image && layer.image !== "none" ? layer.image : null;
  if (image && /url\(/.test(image)) return { unresolved: "background-image" };
  const opaque = color[3] >= 0.999;
  let base;
  if (opaque) base = [color];
  else {
    const below = resolveBackgroundCandidates(layers, index + 1);
    if (below.unresolved) return below;
    base = below.candidates.map((candidate) => blend(color, candidate));
  }
  if (!image) return { candidates: base };
  const stops = (image.match(GRADIENT_COLOR) || []).map((token) => {
    const stop = token === "transparent" ? [0, 0, 0, 0] : parseColor(token);
    stop[3] *= layer.opacity;
    return stop;
  });
  if (stops.length === 0) return { unresolved: "background-image" };
  const candidates = [...base];
  for (const stop of stops) for (const underlying of base) candidates.push(blend(stop, underlying));
  return { candidates: candidates.slice(0, 64) };
}

/**
 * Reads the foreground and the ancestor background layers of an element in the browser and
 * computes the contrast against the resolved backgrounds (alpha-correct). Returns
 * { resolved: false, reason } when the background cannot be measured honestly.
 */
async function contrastAgainstComposited(element, { text = true } = {}) {
  const facts = await element.evaluate((node) => {
    const chain = [];
    for (let current = node; current && current.nodeType === 1; current = current.parentElement) chain.push(current);
    const own = chain.map((item) => Number(getComputedStyle(item).opacity));
    // An element's paint is dimmed by its own opacity and by every ancestor's.
    const up = own.map((_, index) => own.slice(index).reduce((product, value) => product * value, 1));
    const style = getComputedStyle(node);
    return {
      color: style.color,
      font_size: parseFloat(style.fontSize),
      font_weight: style.fontWeight,
      own_opacity: up[0],
      layers: chain.map((item, index) => {
        const layer = getComputedStyle(item);
        return { color: layer.backgroundColor, opacity: up[index], image: layer.backgroundImage };
      }),
    };
  });
  const resolution = resolveBackgroundCandidates(facts.layers);
  if (resolution.unresolved) return { resolved: false, reason: resolution.unresolved };
  const foreground = parseColor(facts.color);
  foreground[3] *= facts.own_opacity;
  const ratio = Math.min(...resolution.candidates.map((candidate) => contrastRatio(foreground, candidate)));
  const large = isLargeText(facts.font_size, facts.font_weight);
  const required = text ? (large ? 3 : 4.5) : 3;
  return { resolved: true, ratio, required, large, foreground, candidates: resolution.candidates.length };
}

// ---------------------------------------------------------------------------------------
// Accessible names
// ---------------------------------------------------------------------------------------

/** Collapses runs of ASCII whitespace to one space and trims. No Unicode normalisation. */
function normalizeAccessibleName(name) {
  return String(name ?? "").replace(/[ \t\r\n\f]+/g, " ").replace(/^ | $/g, "");
}

function codePointKey(text) {
  return Array.from(text, (character) => character.codePointAt(0)).join(",");
}

/**
 * Finds names that occur more than once. Names are normalised for whitespace only and then
 * compared code point by code point, so U+00E9 and e + U+0301 stay distinct and two long
 * identities that differ only in their final code point never collapse. Empty names are not
 * duplicates of each other (an empty name is its own finding).
 */
function findDuplicateNames(names) {
  const groups = new Map();
  names.forEach((name, index) => {
    const normalized = normalizeAccessibleName(name);
    if (normalized === "") return;
    const key = codePointKey(normalized);
    if (!groups.has(key)) groups.set(key, { name: normalized, indexes: [] });
    groups.get(key).indexes.push(index);
  });
  return [...groups.values()].filter((group) => group.indexes.length > 1)
    .map((group) => ({ name: group.name, indexes: group.indexes, count: group.indexes.length }));
}

const NAMED_ROLES = Object.freeze(["button", "link", "textbox", "combobox", "checkbox", "radio", "switch", "menuitem", "tab", "searchbox", "spinbutton", "slider", "option"]);

/** Parses Playwright's ariaSnapshot YAML into { role, name } entries (name null when absent). */
function parseAriaSnapshot(text) {
  const entries = [];
  for (const line of String(text).split("\n")) {
    const match = line.match(/^\s*- ([a-z]+)(?: "((?:[^"\\]|\\.)*)")?/);
    if (!match) continue;
    let name = match[2] ?? null;
    if (name !== null) {
      try {
        name = JSON.parse(`"${name}"`);
      } catch {
        name = match[2];
      }
    }
    entries.push({ role: match[1], name });
  }
  return entries;
}

// ---------------------------------------------------------------------------------------
// Observations and the disposition matcher
// ---------------------------------------------------------------------------------------

function successCriterion(tags) {
  for (const tag of tags || []) {
    const match = /^wcag(\d)(\d)(\d+)$/.exec(tag);
    if (match) return `${match[1]}.${match[2]}.${match[3]}`;
  }
  return "best-practice";
}

function axeTarget(node) {
  return (node.target || []).map((part) => (Array.isArray(part) ? part.join(" ") : part)).join(" >>> ");
}

/**
 * Run-specific identifiers (LiveView element ids, UUIDs inside ids) change on every mount, so a
 * target that carried them could never be matched twice. They are replaced by a stable token;
 * the raw target stays available as the locator for the run that produced it.
 */
function stableTarget(target) {
  return target
    .replace(/\[data-phx-id="[^"]*"\]/g, "[data-phx-id]")
    .replace(/#phx-[\w-]+/g, "#phx-ID")
    .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, "UUID");
}

function incompleteReason(node) {
  const checks = [...(node.any || []), ...(node.all || []), ...(node.none || [])];
  const keys = checks.map((check) => check?.data?.messageKey).filter(Boolean);
  return keys[0] || checks.find((check) => check?.id)?.id || "unspecified";
}

/** Flattens axe results to one observation per violating or incomplete node. */
function flattenAxeResults(results) {
  const observations = [];
  for (const rule of results.violations || []) {
    for (const node of rule.nodes || []) {
      const locator = axeTarget(node);
      observations.push({ rule_id: rule.id, result_type: "violation", incomplete_reason: null, target: stableTarget(locator), sc: successCriterion(rule.tags), locator });
    }
  }
  for (const rule of results.incomplete || []) {
    for (const node of rule.nodes || []) {
      const locator = axeTarget(node);
      observations.push({ rule_id: rule.id, result_type: "incomplete", incomplete_reason: incompleteReason(node), target: stableTarget(locator), sc: successCriterion(rule.tags), locator });
    }
  }
  return observations;
}

function rulesEvaluated(results) {
  return ["passes", "violations", "incomplete", "inapplicable"].reduce((sum, key) => sum + (results[key] || []).length, 0);
}

function observationMatches(entry, observation) {
  return entry.rule_id === observation.rule_id && entry.result_type === observation.result_type &&
    (entry.incomplete_reason ?? null) === (observation.incomplete_reason ?? null) && entry.target === observation.target;
}

/**
 * Matches the observations of one cell against the register. An observation is matched by an
 * entry only when the entry names this cell and its rule, result type, incomplete reason and
 * exact target are equal. Returns the matched pairs, the unmatched observations and the number
 * of nodes each entry matched in this cell.
 */
function matchDispositions(observations, register, cellId) {
  const entries = (register?.entries || []).filter((entry) => (entry.cell_ids || []).includes(cellId));
  const matched = [];
  const unmatched = [];
  const counts = {};
  for (const observation of observations) {
    const hits = entries.filter((entry) => observationMatches(entry, observation));
    if (hits.length === 0) {
      unmatched.push(observation);
      continue;
    }
    for (const entry of hits) counts[entry.id] = (counts[entry.id] || 0) + 1;
    matched.push({ observation, entry_ids: hits.map((entry) => entry.id) });
  }
  return { matched, unmatched, counts };
}

function describeObservation(observation) {
  const reason = observation.incomplete_reason ? ` (${observation.incomplete_reason})` : "";
  return `${observation.result_type} ${observation.rule_id}${reason} at ${observation.target}`;
}

function readRegister(filePath) {
  let raw;
  try {
    raw = fs.readFileSync(filePath, "utf8");
  } catch (error) {
    throw new Error(`Phase 254 a11y: the disposition register is absent or unreadable (${error.code || error.message}): ${filePath}`);
  }
  let register;
  try {
    register = JSON.parse(raw);
  } catch (error) {
    throw new Error(`Phase 254 a11y: the disposition register is unparsable: ${error.message}`);
  }
  if (!register || register.schema_version !== 1 || !Array.isArray(register.entries)) {
    throw new Error("Phase 254 a11y: the disposition register must be { schema_version: 1, entries: [] }");
  }
  return register;
}

// ---------------------------------------------------------------------------------------
// Browser: axe
// ---------------------------------------------------------------------------------------

/** The roots present on the page, with any root contained in another dropped. */
async function presentRoots(page, candidates = DEFAULT_ROOTS) {
  return page.evaluate((selectors) => {
    const found = selectors.map((selector) => ({ selector, element: document.querySelector(selector) })).filter(({ element }) => {
      if (!element) return false;
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return style.display !== "none" && style.visibility !== "hidden" && (rect.width > 0 || rect.height > 0 || element.children.length > 0);
    });
    return found.filter(({ element }) => !found.some((other) => other.element !== element && other.element.contains(element)))
      .map(({ selector }) => selector);
  }, [...candidates]);
}

/**
 * Runs axe over the story sandbox and any open overlay or drawer root. The scan is narrowed
 * only by include; nothing is excluded, no rule is switched off and no severity is ignored.
 * Incomplete contrast results are resolved by compositing the real background stack; anything
 * that cannot be resolved stays an observation.
 */
async function runAxeForCell(page, { roots } = {}) {
  const { AxeBuilder } = require("@axe-core/playwright");
  // Colours are read from the rendered page, so a theme or state transition still running would
  // be measured mid-flight. Wait until no transition or animation is in progress.
  await page.waitForFunction(() => document.getAnimations()
    .filter((animation) => animation.effect && Number.isFinite(animation.effect.getComputedTiming().endTime))
    .every((animation) => !["running", "pending"].includes(animation.playState)), null, { timeout: 5000 }).catch(() => undefined);
  const present = await presentRoots(page, roots || DEFAULT_ROOTS);
  if (present.length === 0) throw new Error("Phase 254 a11y: no axe root is present on the page");
  let builder = new AxeBuilder({ page }).withTags([...A11Y_TAGS]);
  for (const root of present) builder = builder.include(root);
  const results = await builder.analyze();
  const raw = flattenAxeResults(results);
  const mirror = raw.find((observation) => HIDDEN_MIRROR_PATTERN.test(observation.target));
  if (mirror) throw new Error(`Phase 254 a11y: axe reached the hidden test mirror: ${mirror.target}`);

  const observations = [];
  const autoResolved = [];
  for (const { locator, ...observation } of raw) {
    if (observation.rule_id === "color-contrast" && observation.result_type === "incomplete" && !locator.includes(">>>")) {
      const measured = await contrastAgainstComposited(page.locator(locator).first()).catch((error) => ({ resolved: false, reason: String(error.message).split("\n")[0] }));
      if (measured.resolved && measured.ratio >= measured.required) {
        autoResolved.push({ ...observation, basis: "composited-contrast", ratio: Number(measured.ratio.toFixed(2)), required: measured.required });
        continue;
      }
      if (measured.resolved) {
        observations.push({ ...observation, result_type: "violation", incomplete_reason: null, detail: `composited contrast ${measured.ratio.toFixed(2)} below ${measured.required}` });
        continue;
      }
    }
    observations.push(observation);
  }
  return {
    tags: [...A11Y_TAGS],
    roots: present,
    rules_evaluated: rulesEvaluated(results),
    observations,
    auto_resolved: autoResolved,
  };
}

// ---------------------------------------------------------------------------------------
// Browser: shared collector
// ---------------------------------------------------------------------------------------

const INTERACTIVE_SELECTOR = [
  "a[href]", "button", "input:not([type=hidden])", "select", "textarea", "summary",
  "[role=button]", "[role=link]", "[role=menuitem]", "[role=tab]", "[tabindex]:not([tabindex='-1'])",
].join(",");

/** Collects the visible interactive controls inside the given roots with their geometry. */
async function collectInteractive(page, roots) {
  return page.evaluate(({ rootSelectors, interactive }) => {
    // An id is a stable selector only when nothing run-specific is in it.
    const stableId = (node) => node.id && !/phx-|[0-9a-f]{8}|\d/i.test(node.id) && document.querySelectorAll(`#${CSS.escape(node.id)}`).length === 1;
    const selectorOf = (element) => {
      const parts = [];
      let node = element;
      while (node && node.nodeType === 1 && node !== document.documentElement && parts.length < 8) {
        if (stableId(node)) {
          parts.unshift(`#${CSS.escape(node.id)}`);
          break;
        }
        let part = node.localName;
        const parent = node.parentElement;
        if (parent) {
          const same = [...parent.children].filter((child) => child.localName === node.localName);
          if (same.length > 1) part += `:nth-of-type(${same.indexOf(node) + 1})`;
        }
        parts.unshift(part);
        node = parent;
      }
      return parts.join(" > ");
    };
    const seen = new Set();
    const out = [];
    for (const rootSelector of rootSelectors) {
      const root = document.querySelector(rootSelector);
      if (!root) continue;
      for (const element of root.querySelectorAll(interactive)) {
        if (seen.has(element) || element.closest("[hidden], [aria-hidden=true], [data-phase254-ignore]")) continue;
        seen.add(element);
        const style = getComputedStyle(element);
        const rect = element.getBoundingClientRect();
        if (style.display === "none" || style.visibility === "hidden" || (rect.width === 0 && rect.height === 0)) continue;
        const parent = element.parentElement;
        const ownText = parent ? [...parent.childNodes].filter((child) => child.nodeType === 3 && child.textContent.trim() !== "").length : 0;
        out.push({
          selector: selectorOf(element),
          tag: element.localName,
          control: element.hasAttribute("data-phase254-control"),
          x: rect.x, y: rect.y, width: rect.width, height: rect.height,
          display: style.display,
          inline_in_text: element.localName === "a" && style.display === "inline" && ownText > 0,
          disabled: element.disabled === true || element.getAttribute("aria-disabled") === "true",
          obscured: (() => {
            const top = document.elementFromPoint(Math.min(Math.max(rect.x + rect.width / 2, 0), innerWidth - 1), Math.min(Math.max(rect.y + rect.height / 2, 0), innerHeight - 1));
            // A target under an open modal or drawer is not operable; one off screen cannot be hit-tested.
            const inView = rect.bottom > 0 && rect.right > 0 && rect.top < innerHeight && rect.left < innerWidth;
            return inView && Boolean(top) && !(top === element || element.contains(top) || top.contains(element));
          })(),
          native_control: ["checkbox", "radio"].includes(element.getAttribute("type") || "") || element.localName === "select",
        });
      }
    }
    return out;
  }, { rootSelectors: roots, interactive: INTERACTIVE_SELECTOR });
}

// ---------------------------------------------------------------------------------------
// Target size (2.5.8) - pure evaluator plus collector
// ---------------------------------------------------------------------------------------

function circleIntersectsRect(cx, cy, radius, rect) {
  const nearestX = Math.max(rect.x, Math.min(cx, rect.x + rect.width));
  const nearestY = Math.max(rect.y, Math.min(cy, rect.y + rect.height));
  return (cx - nearestX) ** 2 + (cy - nearestY) ** 2 < radius ** 2;
}

/**
 * WCAG 2.5.8: a target must be at least 24x24 CSS px unless it meets an exception. The
 * spacing exception is computed here: a 24px circle centred on the undersized target must not
 * intersect any other target, nor the circle of another undersized target. The inline
 * exception (a link inside a sentence), a disabled control and a user-agent-owned native
 * control are classified inline; every other exception exists only as a register entry.
 */
function evaluateTargetSize(targets) {
  const defects = [];
  const classified = [];
  const live = targets.filter((target) => !target.disabled && !target.obscured);
  const undersized = (target) => target.width < TARGET_MINIMUM || target.height < TARGET_MINIMUM;
  for (const target of live) {
    if (!undersized(target)) continue;
    if (target.width <= 1 && target.height <= 1) {
      // A visually hidden control (clipped to a pixel) is not a pointer target.
      classified.push({ selector: target.selector, exception: "visually-hidden" });
      continue;
    }
    if (target.inline_in_text) {
      classified.push({ selector: target.selector, exception: "inline" });
      continue;
    }
    if (target.native_control) {
      classified.push({ selector: target.selector, exception: "user-agent-control" });
      continue;
    }
    const cx = target.x + target.width / 2;
    const cy = target.y + target.height / 2;
    const radius = TARGET_MINIMUM / 2;
    const blocker = live.find((other) => {
      if (other === target) return false;
      if (undersized(other)) {
        const ox = other.x + other.width / 2;
        const oy = other.y + other.height / 2;
        return Math.hypot(cx - ox, cy - oy) < TARGET_MINIMUM;
      }
      return circleIntersectsRect(cx, cy, radius, other);
    });
    if (blocker) {
      defects.push({ selector: target.selector, control: Boolean(target.control), width: Math.round(target.width * 10) / 10, height: Math.round(target.height * 10) / 10, blocked_by: blocker.selector, problem: `${Math.round(target.width)}x${Math.round(target.height)} is below 24x24 and its spacing circle meets another target` });
    } else {
      classified.push({ selector: target.selector, exception: "spacing" });
    }
  }
  return { checked: live.length, defects, classified };
}

async function probeTargetSize(page, { roots } = {}) {
  const present = await presentRoots(page, roots || DEFAULT_ROOTS);
  const targets = await collectInteractive(page, present);
  const result = evaluateTargetSize(targets);
  return { status: "checked", sc: "2.5.8", ...result, target_count: targets.length };
}

// ---------------------------------------------------------------------------------------
// Focus visible and not obscured (2.4.7, 2.4.11, 1.4.11)
// ---------------------------------------------------------------------------------------

const FOCUS_RING_MINIMUM = 3;

/** Pulls the first visible ring colour out of a computed box-shadow value. */
function shadowRing(boxShadow) {
  if (!boxShadow || boxShadow === "none") return null;
  const parts = boxShadow.match(/(?:rgba?\([^)]*\)|color\([^)]*\))\s+[-\d.]+px\s+[-\d.]+px\s+[-\d.]+px(?:\s+[-\d.]+px)?(?:\s+inset)?/g) || [];
  for (const part of parts) {
    if (/inset/.test(part)) continue;
    const color = part.match(/^(?:rgba?\([^)]*\)|color\([^)]*\))/)[0];
    const lengths = part.slice(color.length).match(/[-\d.]+px/g).map((length) => parseFloat(length));
    const spread = lengths[3] || 0;
    const blur = lengths[2] || 0;
    if (spread > 0 || (blur > 0 && lengths[0] === 0 && lengths[1] === 0)) return { color, spread: spread || blur };
  }
  return null;
}

/**
 * Decides one focused control from the facts the page reported. The ring must exist, be at
 * least 3:1 against the composited background around it and the control must not be hidden
 * behind another element at its centre (2.4.11).
 */
function evaluateFocus(facts) {
  const problems = [];
  const outlineVisible = facts.outline_style !== "none" && facts.outline_width > 0;
  const shadow = shadowRing(facts.box_shadow);
  if (!outlineVisible && !shadow) problems.push("no-focus-indicator");
  let ratio = null;
  const background = compositeColor((facts.background_stack || []).map((color) => parseColor(color)));
  const ring = outlineVisible ? parseColor(facts.outline_color) : shadow ? parseColor(shadow.color) : null;
  if (ring) {
    ratio = contrastRatio(ring, background);
    if (ratio < FOCUS_RING_MINIMUM) problems.push(`ring-contrast-${ratio.toFixed(2)}`);
  }
  if (facts.obscured) problems.push("obscured");
  if (!facts.in_viewport) problems.push("outside-viewport");
  if (!facts.focus_visible && facts.keyboard_reached) problems.push("not-focus-visible");
  return { problems, ring_ratio: ratio == null ? null : Number(ratio.toFixed(2)), outline: outlineVisible, shadow: Boolean(shadow) };
}

// Collected in the page: styles, the background stack around the control and a hit test.
const MEASURE_FOCUS = (element) => {
  const style = getComputedStyle(element);
  const chain = [];
  let node = element.parentElement;
  while (node && node.nodeType === 1) {
    const layer = getComputedStyle(node);
    if (layer.backgroundColor) chain.push(layer.backgroundColor);
    node = node.parentElement;
  }
  const rect = element.getBoundingClientRect();
  const topAt = (x, y) => document.elementFromPoint(x, y);
  const center = topAt(rect.x + rect.width / 2, rect.y + rect.height / 2);
  const obscured = !center || !(center === element || element.contains(center) || center.contains(element));
  const own = style.outlineOffset && parseFloat(style.outlineOffset) < 0 ? [style.backgroundColor, ...chain] : chain;
  return {
    outline_style: style.outlineStyle,
    outline_width: parseFloat(style.outlineWidth) || 0,
    outline_color: style.outlineColor,
    box_shadow: style.boxShadow,
    background_stack: own,
    obscured,
    in_viewport: rect.bottom > 0 && rect.right > 0 && rect.top < innerHeight && rect.left < innerWidth,
    focus_visible: element.matches(":focus-visible"),
  };
};

async function focusFacts(locator, keyboardReached) {
  const facts = await locator.evaluate(MEASURE_FOCUS);
  return { ...facts, keyboard_reached: keyboardReached };
}

/**
 * Tabs through the visible controls of the roots and evaluates each as it receives keyboard
 * focus. With only set, the control is focused programmatically after a Tab key so keyboard
 * modality is active (used by the injected outline:none control).
 */
async function probeFocusVisible(page, { roots, only, limit = 60 } = {}) {
  const present = await presentRoots(page, roots || DEFAULT_ROOTS);
  const checked = [];
  const defects = [];
  if (only) {
    await page.keyboard.press("Tab");
    const locator = page.locator(only).first();
    await locator.focus();
    const facts = await focusFacts(locator, true);
    const verdict = evaluateFocus(facts);
    checked.push({ selector: only, ...verdict });
    if (verdict.problems.length) defects.push({ selector: only, problems: verdict.problems });
    return { status: "checked", sc: "2.4.7/2.4.11/1.4.11", checked: checked.length, defects, evaluated: checked };
  }
  const controls = await collectInteractive(page, present);
  const expected = new Set(controls.map((control) => control.selector));
  await page.evaluate(() => { if (document.activeElement && document.activeElement !== document.body) document.activeElement.blur(); });
  const visited = new Set();
  for (let step = 0; step < Math.min(limit, expected.size + 4); step += 1) {
    await page.keyboard.press("Tab");
    const info = await page.evaluate((rootSelectors) => {
      const active = document.activeElement;
      if (!active || active === document.body) return { body: true };
      const inside = rootSelectors.some((selector) => document.querySelector(selector)?.contains(active));
      return { body: false, inside };
    }, present);
    if (info.body || !info.inside) continue;
    const locator = page.locator(":focus");
    const selector = await locator.evaluate((element) => {
      const parts = [];
      let node = element;
      while (node && node.nodeType === 1 && node !== document.documentElement && parts.length < 8) {
        if (node.id && !/phx-|[0-9a-f]{8}|\d/i.test(node.id) && document.querySelectorAll(`#${CSS.escape(node.id)}`).length === 1) { parts.unshift(`#${CSS.escape(node.id)}`); break; }
        let part = node.localName;
        const parent = node.parentElement;
        if (parent) {
          const same = [...parent.children].filter((child) => child.localName === node.localName);
          if (same.length > 1) part += `:nth-of-type(${same.indexOf(node) + 1})`;
        }
        parts.unshift(part);
        node = parent;
      }
      return parts.join(" > ");
    });
    if (visited.has(selector)) break;
    visited.add(selector);
    const facts = await focusFacts(locator, true);
    const verdict = evaluateFocus(facts);
    checked.push({ selector, ...verdict });
    if (verdict.problems.length) defects.push({ selector, problems: verdict.problems });
  }
  await page.evaluate(() => { if (document.activeElement && document.activeElement !== document.body) document.activeElement.blur(); });
  return { status: "checked", sc: "2.4.7/2.4.11/1.4.11", checked: checked.length, defects, expected_controls: expected.size };
}

// ---------------------------------------------------------------------------------------
// Text spacing (1.4.12)
// ---------------------------------------------------------------------------------------

const TEXT_SPACING_CSS = "*, *::before, *::after { line-height: 1.5 !important; letter-spacing: 0.12em !important; word-spacing: 0.16em !important; } p { margin-block-end: 2em !important; }";

function spacingMatches(letterSpacingPx, fontSizePx) {
  return Math.abs(letterSpacingPx - fontSizePx * 0.12) <= 0.05 + fontSizePx * 0.005;
}

async function measureLetterSpacing(page, selector) {
  return page.evaluate((rootSelector) => {
    const root = document.querySelector(rootSelector);
    const candidate = root.querySelector("h1, p, a, button, span, label") || root;
    const style = getComputedStyle(candidate);
    return { letter_spacing: parseFloat(style.letterSpacing) || 0, font_size: parseFloat(style.fontSize), element: candidate.localName };
  }, selector);
}

/**
 * Applies WCAG 1.4.12 text spacing through a constructed stylesheet, verifies that the
 * computed letter-spacing reached 0.12em before trusting anything else, and reports clipped
 * text. With sabotage the stylesheet is never attached: the verification must then fail,
 * which is the injected "unapplied spacing" control. recheck runs the geometry checks while
 * the spacing is applied and returns a list of failure messages.
 */
async function probeTextSpacing(page, { roots, sabotage = false, recheck } = {}) {
  const present = await presentRoots(page, roots || DEFAULT_ROOTS);
  const rootSelector = present[0];
  if (!sabotage) {
    await page.evaluate((css) => {
      const sheet = new CSSStyleSheet();
      sheet.replaceSync(css);
      window.__phase254SpacingSheet = sheet;
      document.adoptedStyleSheets = [...document.adoptedStyleSheets, sheet];
    }, TEXT_SPACING_CSS);
  }
  try {
    const measured = await measureLetterSpacing(page, rootSelector);
    const applied = spacingMatches(measured.letter_spacing, measured.font_size);
    const defects = [];
    let geometry = [];
    if (applied) {
      const clipped = await page.evaluate((rootSelectorInPage) => {
        const root = document.querySelector(rootSelectorInPage);
        const out = [];
        for (const element of root.querySelectorAll("*")) {
          const style = getComputedStyle(element);
          const rect = element.getBoundingClientRect();
          if (rect.width <= 1 || rect.height <= 1) continue;
          if (!["hidden", "clip"].includes(style.overflowX) && !["hidden", "clip"].includes(style.overflowY)) continue;
          if (element.scrollWidth > element.clientWidth + 1 || element.scrollHeight > element.clientHeight + 1) {
            if ((element.textContent || "").trim() === "") continue;
            out.push(element.localName + (element.id ? `#${element.id}` : "") + (element.className && typeof element.className === "string" ? `.${element.className.split(" ")[0]}` : ""));
          }
        }
        return out.slice(0, 20);
      }, rootSelector);
      for (const selector of clipped) defects.push({ selector, problem: "clipped-under-text-spacing" });
      if (recheck) geometry = await recheck();
      for (const message of geometry) defects.push({ selector: geometryTarget(message), problem: message });
    }
    return {
      status: "checked", sc: "1.4.12", applied,
      measured_letter_spacing_px: Number(measured.letter_spacing.toFixed(3)),
      expected_letter_spacing_px: Number((measured.font_size * 0.12).toFixed(3)),
      defects,
    };
  } finally {
    if (!sabotage) {
      await page.evaluate(() => {
        const sheet = window.__phase254SpacingSheet;
        document.adoptedStyleSheets = document.adoptedStyleSheets.filter((item) => item !== sheet);
        delete window.__phase254SpacingSheet;
      });
    }
  }
}

// ---------------------------------------------------------------------------------------
// Text scale (1.4.4)
// ---------------------------------------------------------------------------------------

async function sampleTextSizes(page, rootSelector) {
  return page.evaluate((selector) => {
    const root = document.querySelector(selector);
    const probe = document.createElement("span");
    probe.setAttribute("data-phase254-probe", "true");
    probe.style.cssText = "font-size:1rem;position:absolute;left:-9999px;top:0;";
    probe.textContent = "x";
    document.body.appendChild(probe);
    const probeSize = parseFloat(getComputedStyle(probe).fontSize);
    probe.remove();
    const samples = [];
    for (const element of root.querySelectorAll("h1, h2, h3, p, a, button, label, th, td, dt, dd, summary, input")) {
      const rect = element.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const own = [...element.childNodes].some((child) => child.nodeType === 3 && child.textContent.trim() !== "") || element.localName === "input";
      if (!own) continue;
      samples.push({ id: element.localName + (element.id ? `#${element.id}` : "") + (element.getAttribute("data-role") ? `[data-role=${element.getAttribute("data-role")}]` : ""), size: parseFloat(getComputedStyle(element).fontSize) });
      if (samples.length >= 30) break;
    }
    return { probe: probeSize, samples };
  }, rootSelector);
}

/**
 * Scales text to 200% through the browser's own font-size setting (CDP Page.setFontSizes) and
 * measures the result. The measured scale must reach 1.95x on a rem probe element and on the
 * page text; a multiplier written to the root font is never accepted as proof. With sabotage
 * the setting is not applied, which is the injected "unapplied scaling" control. recheck runs
 * the geometry checks at the enlarged size.
 */
async function probeTextScale(page, cdp, { roots, sabotage = false, recheck } = {}) {
  const present = await presentRoots(page, roots || DEFAULT_ROOTS);
  const rootSelector = present[0];
  const before = await sampleTextSizes(page, rootSelector);
  if (!sabotage) await cdp.send("Page.setFontSizes", { fontSizes: { standard: TEXT_SCALE_STANDARD_FONT, fixed: TEXT_SCALE_FIXED_FONT } });
  try {
    const after = await sampleTextSizes(page, rootSelector);
    const probeScale = after.probe / before.probe;
    const defects = [];
    const supported = probeScale >= REQUIRED_TEXT_SCALE;
    if (!supported) defects.push({ selector: "mechanism:text-scale", problem: `rem text scaled ${probeScale.toFixed(2)}x, below ${REQUIRED_TEXT_SCALE}x` });
    let minimum = null;
    if (supported) {
      before.samples.forEach((sample, index) => {
        const scaled = after.samples[index];
        if (!scaled || sample.id !== scaled.id) return;
        const scale = scaled.size / sample.size;
        minimum = minimum == null ? scale : Math.min(minimum, scale);
        if (scale < REQUIRED_TEXT_SCALE) defects.push({ selector: sample.id, problem: `text scaled ${scale.toFixed(2)}x, below ${REQUIRED_TEXT_SCALE}x` });
      });
      if (recheck) for (const message of await recheck()) defects.push({ selector: geometryTarget(message), problem: message });
    }
    return {
      status: "checked", sc: "1.4.4", mechanism: "cdp-page-set-font-sizes",
      supported, probe_scale: Number(probeScale.toFixed(3)), minimum_text_scale: minimum == null ? null : Number(minimum.toFixed(3)),
      samples: before.samples.length, defects,
    };
  } finally {
    if (!sabotage) await cdp.send("Page.setFontSizes", { fontSizes: { standard: DEFAULT_STANDARD_FONT, fixed: DEFAULT_FIXED_FONT } });
  }
}

// ---------------------------------------------------------------------------------------
// Motion (2.3.3 is an AAA project target)
// ---------------------------------------------------------------------------------------

function secondsList(value) {
  return String(value || "0s").split(",").map((part) => {
    const text = part.trim();
    if (text.endsWith("ms")) return parseFloat(text) / 1000;
    return parseFloat(text) || 0;
  });
}

function isIdentityTransform(transform) {
  if (!transform || transform === "none") return true;
  const match = transform.match(/^matrix\(([^)]*)\)$/);
  if (!match) return false;
  const values = match[1].split(",").map(Number);
  return values.length === 6 && values[0] === 1 && values[1] === 0 && values[2] === 0 && values[3] === 1 && values[4] === 0 && values[5] === 0;
}

/**
 * Evaluates motion under one preference. Reduce: every transition and animation in the roots
 * lasts at most 1ms and the overlay panel rests at an identity transform. No-preference: an
 * open drawer panel keeps a non-zero transition and focus is not left on the document body.
 * The label 2.3.3 AAA is carried in the output so the criterion is never read as AA.
 */
async function probeMotion(page, mode, { roots, limit = 20 } = {}) {
  const present = await presentRoots(page, roots || DEFAULT_ROOTS);
  await page.emulateMedia({ reducedMotion: mode });
  try {
    const facts = await page.evaluate((rootSelectors) => {
      // A signature names the kind of element (tag plus first class, with the parent's
      // signature for a classless element): ids are run-specific and a bare tag is too broad.
      const own = (element) => element.localName + (element.id && element.id.startsWith("phase254-") ? `#${element.id}` : "") + (element.className && typeof element.className === "string" && element.className.trim() ? `.${element.className.trim().split(/\s+/)[0]}` : "");
      const signature = (element) => {
        const text = own(element);
        if (text.includes(".") || text.includes("#") || !element.parentElement) return text;
        return `${own(element.parentElement)} > ${text}`;
      };
      const elements = [];
      for (const selector of rootSelectors) {
        const root = document.querySelector(selector);
        if (!root) continue;
        elements.push(root, ...root.querySelectorAll("*"));
      }
      const rows = [];
      for (const element of new Set(elements)) {
        // The hidden test mirror and anything else removed from the rendered page is not measured.
        if (element.closest("[hidden], [aria-hidden=true]")) continue;
        const style = getComputedStyle(element);
        rows.push({
          id: signature(element),
          transition_property: style.transitionProperty,
          transition_duration: style.transitionDuration,
          transition_delay: style.transitionDelay,
          animation_name: style.animationName,
          animation_duration: style.animationDuration,
          animation_delay: style.animationDelay,
          transform: style.transform,
          panel: element.hasAttribute("data-ax-overlay-panel"),
        });
      }
      // The drawer's enter transition exists only while the overlay hook applies the entering
      // class, so it is read by applying that class to each drawer shell and removing it again.
      const drawers = [];
      for (const shell of document.querySelectorAll('[data-ax-overlay-shell][data-presentation="drawer"]')) {
        if (shell.closest("[hidden], [aria-hidden=true]")) continue;
        shell.classList.add("ax-drawer-entering");
        const style = getComputedStyle(shell);
        drawers.push({ id: signature(shell), transition_property: style.transitionProperty, transition_duration: style.transitionDuration, transition_delay: style.transitionDelay });
        shell.classList.remove("ax-drawer-entering");
      }
      const active = document.activeElement;
      return { rows, drawers, focus_on_body: !active || active === document.body };
    }, present);
    const defects = [];
    const timing = (row) => {
      const transitions = row.transition_property === "none" ? [0] : secondsList(row.transition_duration).map((duration, index) => duration + (secondsList(row.transition_delay)[index] ?? 0));
      const animations = !row.animation_name || row.animation_name === "none" ? [0] : secondsList(row.animation_duration).map((duration, index) => duration + (secondsList(row.animation_delay)[index] ?? 0));
      return Math.max(0, ...transitions, ...animations);
    };
    const reported = new Set();
    const panels = facts.rows.filter((row) => row.panel);
    for (const row of facts.rows) {
      if (mode !== "reduce") break;
      const seconds = timing(row);
      if (seconds > MOTION_REDUCE_LIMIT_SECONDS && !reported.has(`t|${row.id}`)) {
        reported.add(`t|${row.id}`);
        defects.push({ selector: row.id, problem: `motion lasts ${(seconds * 1000).toFixed(1)}ms under reduce` });
      }
      if (row.panel && !isIdentityTransform(row.transform) && !reported.has(`x|${row.id}`)) {
        reported.add(`x|${row.id}`);
        defects.push({ selector: row.id, problem: `panel rests at non-identity transform ${row.transform}` });
      }
    }
    let drawerTransition = 0;
    for (const drawer of facts.drawers) {
      const seconds = timing(drawer);
      drawerTransition = Math.max(drawerTransition, seconds);
      if (mode === "reduce" && seconds > MOTION_REDUCE_LIMIT_SECONDS && !reported.has(`d|${drawer.id}`)) {
        reported.add(`d|${drawer.id}`);
        defects.push({ selector: `${drawer.id} (entering)`, problem: `drawer enter transition lasts ${(seconds * 1000).toFixed(1)}ms under reduce` });
      }
    }
    let notApplicable = null;
    if (mode === "no-preference") {
      if (facts.drawers.length === 0) notApplicable = "no drawer is open in this composition";
      else if (drawerTransition <= MOTION_REDUCE_LIMIT_SECONDS) defects.push({ selector: "[data-ax-overlay-shell][data-presentation=drawer] (entering)", problem: "drawer has no enter transition under no-preference" });
    }
    return {
      status: notApplicable ? "not_applicable" : "checked",
      not_applicable_reason: notApplicable,
      sc: "2.3.3", conformance_note: AAA_PROJECT_TARGETS["2.3.3"],
      mode, panels: panels.length, drawers: facts.drawers.length, drawer_transition_s: Number(drawerTransition.toFixed(3)),
      focus_on_body: facts.focus_on_body,
      defects: defects.slice(0, limit),
    };
  } finally {
    await page.emulateMedia({ reducedMotion: "reduce" });
  }
}

// ---------------------------------------------------------------------------------------
// Names
// ---------------------------------------------------------------------------------------

/**
 * Checks accessible names with Playwright's own computed names. Every interactive control in
 * the roots must have a name; each expectation (role + exact name, after whitespace
 * normalisation) must match exactly the stated number of controls; and links in the repeated
 * data-table region must have unique names compared code point by code point.
 */
async function probeNames(page, { roots, expectations = [], uniqueWithin = '[data-role="data-table"]' } = {}) {
  const present = await presentRoots(page, roots || DEFAULT_ROOTS);
  const defects = [];
  let controls = 0;
  for (const root of present) {
    const entries = parseAriaSnapshot(await page.locator(root).first().ariaSnapshot());
    let ordinal = 0;
    for (const entry of entries) {
      if (!NAMED_ROLES.includes(entry.role)) continue;
      controls += 1;
      ordinal += 1;
      if (entry.name == null || normalizeAccessibleName(entry.name) === "") {
        defects.push({ selector: `${root} role:${entry.role}#${ordinal}`, problem: `${entry.role} has no accessible name` });
      }
    }
  }
  for (const expectation of expectations) {
    const scope = expectation.scope ? page.locator(expectation.scope) : page;
    const count = await scope.getByRole(expectation.role, { name: normalizeAccessibleName(expectation.name), exact: true }).count();
    const wanted = expectation.count ?? 1;
    const ok = expectation.min != null ? count >= expectation.min : count === wanted;
    if (!ok) defects.push({ selector: `role:${expectation.role} "${expectation.name}"`, problem: `expected ${expectation.min != null ? `at least ${expectation.min}` : wanted} control(s) with this exact name, found ${count}` });
  }
  let rowLinks = 0;
  const region = page.locator(uniqueWithin).first();
  if (await region.count() > 0) {
    const links = parseAriaSnapshot(await region.ariaSnapshot()).filter((entry) => entry.role === "link");
    rowLinks = links.length;
    for (const duplicate of findDuplicateNames(links.map((entry) => entry.name))) {
      defects.push({ selector: `${uniqueWithin} role:link ${JSON.stringify(duplicate.name)}`, problem: `${duplicate.count} links share this accessible name` });
    }
  }
  return { status: "checked", sc: "2.4.4/4.1.2", controls, row_links: rowLinks, expectations: expectations.length, defects };
}

/**
 * A geometry re-check message names a kind of failure, never a node, so its target is the kind
 * (geometry:page-overflow) rather than the sandbox root, which the register rightly refuses as
 * too broad.
 */
function geometryTarget(message) {
  const text = String(message);
  const hidden = text.match(/hidden essential content: (.*)$/);
  if (hidden) return `geometry:hidden-essential(${hidden[1].split(",").map((name) => name.trim()).sort().join("|")})`;
  if (/document page overflow/.test(text)) return "geometry:document-overflow";
  if (/page overflow/.test(text)) return "geometry:page-overflow";
  if (/outside its local scroll boundary/.test(text)) return "geometry:table-overflow";
  return "geometry:other";
}

const PROBE_RULES = Object.freeze({
  names: { rule_id: "probe-names", sc: "4.1.2" },
  target_size: { rule_id: "probe-target-size", sc: "2.5.8" },
  focus: { rule_id: "probe-focus-visible", sc: "2.4.7" },
  spacing: { rule_id: "probe-text-spacing", sc: "1.4.12" },
  scale: { rule_id: "probe-text-scale", sc: "1.4.4" },
  motion_reduce: { rule_id: "probe-motion-reduce", sc: "2.3.3" },
  motion_no_preference: { rule_id: "probe-motion-no-preference", sc: "2.3.3" },
});

/**
 * A probe finding is an observation exactly like an axe finding: one rule id (probe-<name>),
 * one result type and one exact target, so the same register and the same matcher decide it.
 * A mechanism the browser could not provide (text scaling) is also an observation, which only
 * an unsupported-mechanism entry can disposition.
 */
function probeObservations(name, result) {
  const rule = PROBE_RULES[name];
  if (!rule || !result || result.status === "not_applicable") return [];
  const out = [];
  for (const defect of result.defects || []) {
    out.push({ rule_id: rule.rule_id, result_type: "violation", incomplete_reason: null, target: defect.selector, sc: rule.sc, detail: defect.problem || (defect.problems || []).join(", ") || null });
  }
  if (name === "scale" && result.supported === false && !out.some((item) => item.target === "mechanism:text-scale")) {
    out.push({ rule_id: rule.rule_id, result_type: "violation", incomplete_reason: null, target: "mechanism:text-scale", sc: rule.sc, detail: "the browser did not scale rem text" });
  }
  return out;
}

module.exports = {
  PROBE_RULES,
  geometryTarget,
  probeObservations,
  A11Y_TAGS,
  AAA_PROJECT_TARGETS,
  DEEP_PROBES,
  DEFAULT_ROOTS,
  REQUIRED_TEXT_SCALE,
  blend,
  compositeColor,
  contrastAgainstComposited,
  contrastRatio,
  describeObservation,
  evaluateFocus,
  evaluateTargetSize,
  findDuplicateNames,
  flattenAxeResults,
  isDeepProbeKey,
  isIdentityTransform,
  isLargeText,
  matchDispositions,
  normalizeAccessibleName,
  parseAriaSnapshot,
  parseColor,
  presentRoots,
  resolveBackgroundCandidates,
  stableTarget,
  probeFocusVisible,
  probeMotion,
  probeNames,
  probeTargetSize,
  probeTextScale,
  probeTextSpacing,
  readRegister,
  relativeLuminance,
  rulesEvaluated,
  runAxeForCell,
  secondsList,
  spacingMatches,
};
