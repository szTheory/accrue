"use strict";

/**
 * region-tags.js — deterministic identity SSOT for the UI ratchet (Phase 205, v1.56).
 *
 * This module is the load-bearing gate for DEDUP-01/DEDUP-02. It defines the closed
 * enum vocabularies (region_tag, overlay_tags) plus the PURE `claimKey()`/`findingId()`/
 * normalizer functions from which the proposer re-derives every identity field — the
 * LLM output is advisory only (D-04/D-16). Identity NEVER trusts model prose.
 *
 * SDK-free by contract: it imports ONLY `node:crypto` so the `runSelfTest()` proof runs
 * with no ANTHROPIC_API_KEY and no live model (twins `phase200-scorecard.mjs`).
 *
 * CommonJS (mirrors `baseline-manifest.js`) so it is importable both by the ESM harness
 * (`await import("./region-tags.js")`, cjs-interop default) and standalone via
 * `node accrue_admin/e2e/ratchet/region-tags.js` (runs the self-test).
 *
 * Locked decisions (205-CONTEXT.md D-01..D-23) — binding, do not re-litigate:
 *  - D-01: claim_key = `${slug(surface)}__d${NN}__${region||'noregion'}__ov-${sorted(overlays).join('+')||'none'}`
 *  - D-04: sort = DEFAULT codepoint `.sort()` (NEVER localeCompare); dedup; empties → sentinels
 *  - D-06: REGION_TAGS is a fixed 14-value closed enum; `content-body` is the mandatory fallback
 *  - D-10: this is the single shared SSOT (enum + subset map + synonym table) with orthogonal axes
 */

const { createHash } = require("node:crypto");

// -----------------------------------------------------------------------------
// Closed vocabularies (D-06, D-04)
// -----------------------------------------------------------------------------

/**
 * REGION_TAGS — the exact 14 values from D-06, in order. `content-body` is the
 * mandatory fallback; `layer` (NOT "overlay") covers all floating layers
 * (modal/drawer/dropdown/command-palette/toast) — the name deliberately avoids
 * colliding with the `overlay-position` overlay tag.
 */
const REGION_TAGS = [
  "topbar",
  "primary-nav",
  "page-header",
  "toolbar",
  "tab-bar",
  "kpi-row",
  "attention-rail",
  "data-table",
  "detail-panel",
  "related-panel",
  "timeline",
  "payload-viewer",
  "content-body",
  "layer",
];

/**
 * OVERLAY_TAGS — mirrors the 14 values from `baseline-manifest.js:29-44` exactly.
 * This is the closed identity vocab for `overlay_tags`. Kept in sync deliberately;
 * region-tags.js stays SDK-free (and manifest-free) so the self-test is pure, so the
 * list is mirrored here rather than imported.
 */
const OVERLAY_TAGS = [
  "layer-z-index",
  "live-focus",
  "focus-restore",
  "focus-trap",
  "scroll-reachability",
  "overlay-position",
  "actionability",
  "disabled-affordance",
  "hover-affordance",
  "copy-recovery",
  "copy-vocabulary",
  "copy-specificity",
  "dark-mode-role",
  "reduced-motion",
];

/**
 * REGION_SELECTORS — map from each REGION_TAGS value to its live `ax-*` DOM selector.
 * Consumed by plan 05's bbox capture (D-09) and the optional presence cross-check.
 * A `null`/absent selector is the intended safe fallback (never a crash): region_tag
 * is derived from model output via `normalizeRegion`, never from this map, so a wrong
 * or missing selector cannot affect identity/claim-key (RESEARCH Open Q2 disposition).
 */
const REGION_SELECTORS = {
  topbar: "ax-topbar",
  "primary-nav": "ax-primary-nav",
  "page-header": "ax-page-header",
  toolbar: "ax-toolbar", // TODO: confirm selector
  "tab-bar": "ax-tabs", // TODO: confirm selector
  "kpi-row": "ax-kpi-row", // TODO: confirm selector
  "attention-rail": "ax-attention-rail", // TODO: confirm selector
  "data-table": "ax-data-table",
  "detail-panel": "ax-detail", // TODO: confirm selector
  "related-panel": "ax-related-resources", // TODO: confirm selector
  timeline: "ax-timeline", // TODO: confirm selector
  "payload-viewer": "ax-json-viewer", // TODO: confirm selector
  "content-body": "ax-content", // TODO: confirm selector
  layer: "ax-layer", // TODO: confirm selector
};

/**
 * ALLOWED_SUBSET — static `archetype → allowed region subset` map (D-08). Shrinks the
 * model's choice set per surface. List surfaces expose the 8-value base; detail surfaces
 * additionally expose the object-detail regions (tab-bar/detail-panel/related-panel/
 * timeline/payload-viewer). `allowedSubsetFor()` resolves a surface name or surface_type
 * to one of these. Exact contents are Claude's discretion (non-identity; only gates
 * `normalizeRegion`), within the D-08 shape.
 */
const ALLOWED_SUBSET = {
  list: [
    "topbar",
    "primary-nav",
    "page-header",
    "toolbar",
    "kpi-row",
    "data-table",
    "content-body",
    "layer",
  ],
  detail: [
    "topbar",
    "primary-nav",
    "page-header",
    "tab-bar",
    "kpi-row",
    "attention-rail",
    "data-table",
    "detail-panel",
    "related-panel",
    "timeline",
    "payload-viewer",
    "content-body",
    "layer",
  ],
  dashboard: [
    "topbar",
    "primary-nav",
    "page-header",
    "kpi-row",
    "attention-rail",
    "data-table",
    "content-body",
    "layer",
  ],
  component: [
    "page-header",
    "toolbar",
    "data-table",
    "detail-panel",
    "content-body",
    "layer",
  ],
  "component-group": [
    "page-header",
    "toolbar",
    "tab-bar",
    "kpi-row",
    "data-table",
    "detail-panel",
    "content-body",
    "layer",
  ],
};

/**
 * SYNONYM_TABLE — fixed normalization map (D-08). Coerces common aliases to a canonical
 * REGION_TAGS value. NEVER expands the vocabulary (every value ∈ REGION_TAGS).
 */
const SYNONYM_TABLE = {
  sidebar: "primary-nav",
  nav: "primary-nav",
  navigation: "primary-nav",
  header: "page-header",
  "page-title": "page-header",
  title: "page-header",
  modal: "layer",
  drawer: "layer",
  toast: "layer",
  dropdown: "layer",
  popover: "layer",
  "command-palette": "layer",
  overlay: "layer",
  table: "data-table",
  list: "data-table",
  grid: "data-table",
  toolbar: "toolbar",
  filters: "toolbar",
  filter: "toolbar",
  search: "toolbar",
  kpi: "kpi-row",
  kpis: "kpi-row",
  metrics: "kpi-row",
  stats: "kpi-row",
  tabs: "tab-bar",
  detail: "detail-panel",
  "detail-panel": "detail-panel",
  related: "related-panel",
  payload: "payload-viewer",
  json: "payload-viewer",
  body: "content-body",
  main: "content-body",
  content: "content-body",
};

// -----------------------------------------------------------------------------
// Pure identity functions (D-01, D-04)
// -----------------------------------------------------------------------------

/**
 * slug(value) — reimplemented BYTE-IDENTICALLY to `baseline-manifest.js:192-197`
 * (lowercase → `[^a-z0-9]+` to `-` → strip leading/trailing `-`). Deliberately NOT
 * imported from the frozen manifest (it is module-private there, not exported —
 * RESEARCH Pitfall 3). The Task 2 self-test asserts byte-for-byte parity against the
 * manifest cell grammar.
 */
function slug(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

/**
 * allowedSubsetFor(surfaceOrType) — resolve a surface name OR surface_type string to
 * its allowed region subset. Never throws; defaults to the `list` archetype. SDK-free
 * (does not consult baseline-manifest.js) so the self-test stays pure.
 */
function allowedSubsetFor(surfaceOrType) {
  const key = String(surfaceOrType == null ? "" : surfaceOrType)
    .toLowerCase()
    .trim();
  if (ALLOWED_SUBSET[key]) return ALLOWED_SUBSET[key];
  if (key === "dashboard") return ALLOWED_SUBSET.dashboard;
  if (key.includes("detail")) return ALLOWED_SUBSET.detail;
  if (key === "component") return ALLOWED_SUBSET.component;
  if (key === "component-group") return ALLOWED_SUBSET["component-group"];
  // page-flow list surfaces + any unknown → list archetype (safe default).
  return ALLOWED_SUBSET.list;
}

/**
 * assertDimension(d) — return `d` if an integer in 1..12, else throw. There are exactly
 * 12 rubric dimensions (no 13th — milestone guardrail).
 */
function assertDimension(d) {
  if (typeof d === "number" && Number.isInteger(d) && d >= 1 && d <= 12) return d;
  throw new Error(`dimension ∉ 1..12: ${JSON.stringify(d)}`);
}

/**
 * normalizeOverlays(tags) — closed-enum-validate each overlay tag (throw if ∉
 * OVERLAY_TAGS), dedup, then sort with the DEFAULT codepoint `.sort()` (NEVER
 * localeCompare — locale-sensitivity is a determinism bug, RESEARCH anti-patterns).
 * empty/undefined → [].
 */
function normalizeOverlays(tags) {
  if (tags == null) return [];
  if (!Array.isArray(tags)) {
    throw new Error(`overlay_tags must be an array: ${JSON.stringify(tags)}`);
  }
  for (const tag of tags) {
    if (!OVERLAY_TAGS.includes(tag)) {
      throw new Error(`overlay_tag ∉ OVERLAY_TAGS: ${JSON.stringify(tag)}`);
    }
  }
  return Array.from(new Set(tags)).sort();
}

/**
 * normalizeRegion(surfaceOrType, region_tag) — validate against the per-surface allowed
 * subset; if not in subset, apply SYNONYM_TABLE; if still unknown, coerce to
 * `content-body`. NEVER throws, NEVER invents a token outside REGION_TAGS.
 */
function normalizeRegion(surfaceOrType, region_tag) {
  const subset = allowedSubsetFor(surfaceOrType);
  const raw = String(region_tag == null ? "" : region_tag)
    .toLowerCase()
    .trim();
  if (!raw) return "content-body";
  if (subset.includes(raw)) return raw;
  const syn = SYNONYM_TABLE[raw];
  if (syn && subset.includes(syn)) return syn;
  if (syn && REGION_TAGS.includes(syn)) return syn;
  return "content-body";
}

/**
 * claimKey(surface, dimension, region_tag, overlay_tags) — canonical D-01 identity
 * string. Overlays are enum-validated + deduped + codepoint-sorted via normalizeOverlays;
 * empty overlays → `ov-none`; absent/"" region → `noregion`.
 */
function claimKey(surface, dimension, region_tag, overlay_tags) {
  const nn = String(dimension).padStart(2, "0");
  const region = region_tag || "noregion";
  const ov = normalizeOverlays(overlay_tags).join("+");
  const ovStr = ov || "none";
  return `${slug(surface)}__d${nn}__${region}__ov-${ovStr}`;
}

/**
 * findingId(claim_key) — `"f-" + sha256(claim_key utf8 hex).slice(0,16)`.
 * Matches the sha256 pattern at `phase200-scorecard.mjs:238`.
 */
function findingId(claim_key) {
  return "f-" + createHash("sha256").update(claim_key, "utf8").digest("hex").slice(0, 16);
}

/**
 * isAdmissibleToken(token) — true iff token is exactly `rubric-dim-below-bar`,
 * `token-bypass`, or matches `persona-job-miss:<job>` (prefix `persona-job-miss:` with a
 * non-empty job). Used by the D-16 parse-time drop gate.
 */
function isAdmissibleToken(token) {
  if (typeof token !== "string") return false;
  if (token === "rubric-dim-below-bar" || token === "token-bypass") return true;
  const prefix = "persona-job-miss:";
  return token.startsWith(prefix) && token.length > prefix.length;
}

module.exports = {
  REGION_TAGS,
  OVERLAY_TAGS,
  REGION_SELECTORS,
  ALLOWED_SUBSET,
  SYNONYM_TABLE,
  slug,
  allowedSubsetFor,
  assertDimension,
  normalizeOverlays,
  normalizeRegion,
  claimKey,
  findingId,
  isAdmissibleToken,
};
