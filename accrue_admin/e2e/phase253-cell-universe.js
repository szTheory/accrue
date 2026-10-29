"use strict";

// Phase 254 CIQ-02 (D-09/D-10): the pure Phase 253 browser-cell universe. This module has no
// side effects at import time (no Playwright, no filesystem, no environment reads), so both the
// Playwright lane (phase253-composition-helpers.js) and the Node selector
// (scripts/ci/phase254_selection.mjs) derive one identical case-key function from a manifest.

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
const PAGE_VARIATIONS = Object.freeze([...PAGE_DETAIL_VARIATIONS, ...PAGE_OVERLAY_VARIATIONS]);
const PAGE_WIDTHS = Object.freeze([
  { kind: "viewport", width: 320, viewportWidth: 320, containerWidth: null },
  { kind: "viewport", width: 1280, viewportWidth: 1280, containerWidth: null },
  { kind: "breakpoint", width: 767, viewportWidth: 767, containerWidth: null },
  { kind: "breakpoint", width: 768, viewportWidth: 768, containerWidth: null },
  { kind: "container", width: 640, viewportWidth: 1280, containerWidth: 640 },
]);
const GEOMETRY_NEGATIVE_CONTROL_TITLE = "geometry controls detect hidden essential content and page overflow";
const collectionSyntheticTitle = (theme) => `synthetic long text and markup-like filter remain safe at 320px | ${theme}`;

const PAGE_STORY_PATH = "/pages/subscription";

// The one key function for a browser cell. A cell is identified by its compiled entry, the
// viewport/container width, the theme and the case kind ("viewport" by default; "breakpoint",
// "container", "synthetic-text", "synthetic-<stress>" otherwise). Whole-page entries carry the
// "page::" prefix so a collection and a page variation can never collide.
function cellKey(entry, width, theme, kind = "viewport", page = entry.story_path === PAGE_STORY_PATH) {
  const prefix = page ? "page::" : "";
  return `${prefix}${entry.variation_id}::${kind}::${width}::${theme}`;
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
          key: cellKey(entry, width, theme, "viewport"),
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
          key: cellKey(entry, width, theme, "breakpoint"),
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
        key: cellKey(entry, 640, theme, "container"),
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
          key: cellKey(entry, dimension.width, theme, dimension.kind, true),
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
      key: cellKey(entry, 320, theme, `synthetic-${stressKind}`, true),
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
    key: cellKey(oneRow, 320, theme, "synthetic-text"),
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

module.exports = {
  COLLECTION_STATES,
  GEOMETRY_NEGATIVE_CONTROL_TITLE,
  PAGE_DETAIL_VARIATIONS,
  PAGE_OVERLAY_VARIATIONS,
  PAGE_STORY_PATH,
  PAGE_VARIATIONS,
  PAGE_WIDTHS,
  THEMES,
  WIDTHS,
  cellKey,
  collectionCellDefinition,
  collectionSourceIdentity,
  collectionSyntheticTitle,
  createCollectionCases,
  createExpectedBrowserCellDefinitions,
  createPageCases,
  createPageStressCases,
  expectedPageFacts,
  pageCellDefinition,
};
