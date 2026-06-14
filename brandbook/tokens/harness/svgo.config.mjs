/**
 * svgo.config.mjs — Committed SSOT for deterministic SVG optimization.
 *
 * This config is committed so CI re-runs produce byte-identical SVG output (D-11).
 *
 * DELIBERATELY EXCLUDED PLUGINS (do not add these):
 *   - removeViewBox    — viewBox is required for browser scaling of brand SVGs
 *   - removeTitle      — <title> elements required for accessibility (D-13, UI-SPEC)
 *   - removeDesc       — <desc> elements required for accessibility (D-13, UI-SPEC)
 *
 * Any plugin not in this list is also excluded by default.
 */
export default {
  multipass: true,
  plugins: [
    "removeDoctype",
    "removeXMLProcInst",
    "removeComments",
    "removeMetadata",
    "removeEditorsNSData",
    "cleanupAttrs",
    "removeNonInheritableGroupAttrs",
    "removeUselessStrokeAndFill",
    "cleanupNumericValues",
    "collapseGroups",
    "convertPathData",
    "convertTransform",
    "removeEmptyAttrs",
    "removeEmptyContainers",
    "mergePaths",
    "sortAttrs",
    "cleanupIds",
  ],
};
