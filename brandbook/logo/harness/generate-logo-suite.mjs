/**
 * generate-logo-suite.mjs — SVG production orchestrator for the Accrue logo system
 *
 * Generates all 13 brand SVG artifacts from the frozen R2-7 tournament winner config.
 * Outputs to brandbook/logo/ (one directory up from this harness/).
 *
 * Usage:
 *   node brandbook/logo/harness/generate-logo-suite.mjs
 *
 * Outputs (brandbook/logo/):
 *   accrue-logo.svg                — PRIMARY lockup (mark + wordmark, light bg, full color)
 *   accrue-logo-on-dark.svg        — On-dark swap
 *   accrue-logo-subtitle.svg       — With-subtitle lockup ("Billing for Elixir apps")
 *   accrue-wordmark.svg            — Logotype only (glyph paths, no mark)
 *   accrue-mark.svg                — Mark-only (viewBox 0 0 40 40, two-tone)
 *   accrue-mark-on-dark.svg        — Mark-only with on-dark inversion
 *   accrue-logo-mono.svg           — Full lockup, monochrome (#818181 accent)
 *   accrue-logo-mono-inverse.svg   — Monochrome inverse (ink→paper)
 *   accrue-mark-mono.svg           — Mark-only, monochrome
 *   accrue-mark-mono-inverse.svg   — Mark-only, monochrome inverse
 *   accrue-clearspace.svg          — Clearspace diagram with guide rects
 *   accrue-social-card.svg         — 1200×630 social card (dark bg)
 *   favicon.svg                    — Mark-only SVG passthrough (bare filename per D-04)
 *
 * Frozen R2-7 config (from 182-FREEZE.md — NEVER modify):
 *   generate({ steps: 4, stepHeight: 0.25, stepWidth: 0.25, curvature: 0.05, accentStep: true })
 *   → { markPathD, accentPathD, markWidth: 40, markHeight: 40 }
 *
 * Coordinate-space contract (from assemble-lockup.mjs header):
 *   - extractGlyphs() bakes ABSOLUTE X positions into each glyph path, baseline at y=0
 *   - All glyph paths go inside ONE <g transform="translate(markScaledWidth+gap, BASELINE)">
 *   - Mark scaled: s = capHeight / markHeight; placed at (0, BASELINE - capHeight)
 *   - NEVER add per-glyph translate loops — paths already carry x layout
 *   - BASELINE = capHeight * 1.1 inside viewboxH = capHeight * 1.4
 */

import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Path constants
// ---------------------------------------------------------------------------

const HARNESS_181 = path.resolve(
  __dirname,
  "../../../.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness"
);
const HARNESS_182 = path.resolve(
  __dirname,
  "../../../.planning/phases/182-tournament-convergent-refinement/harness"
);

const OUTPUT_DIR = path.resolve(__dirname, "../");

// ---------------------------------------------------------------------------
// Static imports
// ---------------------------------------------------------------------------

import { optimize } from "svgo";
import svgoConfig from "./svgo.config.mjs";

// ---------------------------------------------------------------------------
// Palette constants (frozen — 182-FREEZE.md + 183-PATTERNS.md)
// ---------------------------------------------------------------------------

const PALETTE = {
  ink: "#181818",
  paper: "#FAFBFC",
  accentFill: "#5E9E84",
  slate: "#3A4754",
  inkDark: "#111418",
  monoMap: { "#5E9E84": "#818181" },
};

// On-dark color swap map (from 183-PATTERNS.md)
const INK_DARK_COLOR_MAP = {
  "#181818": "#FAFBFC",
  "#FAFBFC": "#111418",
  "#5E9E84": "#5E9E84",
};

// ---------------------------------------------------------------------------
// SVG title/desc map (from 183-PATTERNS.md §SVG Accessibility)
// ---------------------------------------------------------------------------

const SVG_META = {
  "accrue-logo":              { title: "Accrue logo",                        desc: "The Accrue mark and wordmark. Clearspace: one step-height on all four sides." },
  "accrue-logo-on-dark":      { title: "Accrue logo, dark background",       desc: "The Accrue mark and wordmark on a dark background. Clearspace: one step-height on all four sides." },
  "accrue-logo-subtitle":     { title: "Accrue logo with descriptor",        desc: "The Accrue mark and wordmark with the descriptor 'Billing for Elixir apps'. Clearspace: one step-height on all four sides." },
  "accrue-wordmark":          { title: "Accrue wordmark",                    desc: "The Accrue logotype (wordmark only, no mark)." },
  "accrue-mark":              { title: "Accrue logomark",                    desc: "The Accrue mark (icon only). Clearspace: one step-height on all four sides." },
  "accrue-mark-on-dark":      { title: "Accrue logomark, dark background",   desc: "The Accrue mark on a dark background. Clearspace: one step-height on all four sides." },
  "accrue-logo-mono":         { title: "Accrue logo, monochrome",            desc: "The Accrue mark and wordmark in monochrome (single ink, grey accent step)." },
  "accrue-logo-mono-inverse": { title: "Accrue logo, monochrome inverse",    desc: "The Accrue mark and wordmark in monochrome inverse (light ink on dark background)." },
  "accrue-mark-mono":         { title: "Accrue logomark, monochrome",        desc: "The Accrue mark in monochrome (single ink, grey accent step)." },
  "accrue-mark-mono-inverse": { title: "Accrue logomark, monochrome inverse",desc: "The Accrue mark in monochrome inverse (light ink on dark background)." },
  "accrue-clearspace":        { title: "Accrue logo clearspace diagram",     desc: "Clearspace diagram: one step-height on all four sides. Minimum sizes are documented in brandbook/README.md." },
  "accrue-social-card":       { title: "Accrue social card",                 desc: "Accrue social card — 1200×630. Dark background with wordmark and descriptor." },
  "favicon":                  { title: "Accrue favicon",                     desc: "The Accrue mark for use as a favicon." },
};

// ---------------------------------------------------------------------------
// Helper: on-dark color swap
// ---------------------------------------------------------------------------

function applyInkDarkColors(svgContent) {
  const replacements = Object.entries(INK_DARK_COLOR_MAP);
  const pattern = new RegExp(
    replacements.map(([k]) => k.replace(/#/g, "\\#")).join("|"),
    "g"
  );
  return svgContent.replace(pattern, (match) => INK_DARK_COLOR_MAP[match] ?? match);
}

// ---------------------------------------------------------------------------
// Helper: mono derivation (mirrors generate.mjs buildMonoSvg)
// ---------------------------------------------------------------------------

function buildMonoSvg(svgString, monoMap) {
  if (!monoMap || Object.keys(monoMap).length === 0) return undefined;
  let mono = svgString;
  for (const [from, to] of Object.entries(monoMap)) {
    mono = mono.replaceAll(from, to);
  }
  return mono;
}

// ---------------------------------------------------------------------------
// Helper: inject <title> and <desc> into SVG string (before svgo)
// ---------------------------------------------------------------------------

function injectMeta(svgString, key) {
  const meta = SVG_META[key];
  if (!meta) throw new Error(`No SVG_META entry for key: ${key}`);

  const titleDesc = `<title>${meta.title}</title><desc>${meta.desc}</desc>`;

  // Insert after the opening <svg ...> tag
  return svgString.replace(/(<svg[^>]*>)/, `$1${titleDesc}`);
}

// ---------------------------------------------------------------------------
// Helper: svgo optimize with title/desc guard
// ---------------------------------------------------------------------------

function svgoOptimize(svgString) {
  const result = optimize(svgString, svgoConfig);
  return result.data;
}

// ---------------------------------------------------------------------------
// Helper: write SVG file
// ---------------------------------------------------------------------------

function writeSvg(filename, svgString) {
  const outPath = path.join(OUTPUT_DIR, filename);
  fs.writeFileSync(outPath, svgString, "utf8");
  console.log(`[generate-logo-suite] Wrote: ${filename}`);
}

// ---------------------------------------------------------------------------
// Helper: add background rect to SVG (for on-dark variants)
// Inserts a full-bleed bg rect immediately after <title>/<desc> metadata
// ---------------------------------------------------------------------------

function addBgRect(svgString, color) {
  // Match viewBox to get dimensions
  const vbMatch = svgString.match(/viewBox="([^"]+)"/);
  if (!vbMatch) return svgString;
  const [, , , w, h] = vbMatch[1].split(/\s+/).map(Number);
  if (!w || !h) return svgString;

  const bgRect = `<rect width="${w}" height="${h}" fill="${color}"/>`;
  // Insert after first closing > of opening svg tag, before any content
  return svgString.replace(/(<\/(?:title|desc)>)/, `$1${bgRect}`);
}

// ---------------------------------------------------------------------------
// Helper: extract wordmark glyph group X offset from lockup SVG
// Returns the x-offset of the logotype group (for subtitle left alignment)
// ---------------------------------------------------------------------------

function extractWordmarkX(svgString) {
  // Look for the logotype group translate
  const match = svgString.match(/id="logotype"\s+transform="translate\(([^,]+),/);
  if (!match) return null;
  return parseFloat(match[1]);
}

// ---------------------------------------------------------------------------
// Helper: extract viewBox width from SVG string
// ---------------------------------------------------------------------------

function extractViewBox(svgString) {
  const match = svgString.match(/viewBox="([^"]+)"/);
  if (!match) return null;
  const parts = match[1].split(/\s+/).map(Number);
  return { x: parts[0], y: parts[1], w: parts[2], h: parts[3] };
}

// ---------------------------------------------------------------------------
// main()
// ---------------------------------------------------------------------------

async function main() {
  console.log("[generate-logo-suite] Starting SVG production pipeline…");

  // Ensure output dir exists
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  // Step 1 — Dynamic imports from 181/182 harness primitives
  const { loadGeistFont, extractGlyphs, getCapHeight } = await import(
    path.join(HARNESS_181, "geist-spine.mjs")
  );
  const { assembleLockup } = await import(
    path.join(HARNESS_181, "assemble-lockup.mjs")
  );
  const { generate } = await import(
    path.join(HARNESS_182, "dirs/b-step-r2.mjs")
  );

  // geist-spine-mono from our own harness (Plan 01 artifact)
  const { loadGeistMonoFont, extractGlyphs: extractMonoGlyphs, getCapHeight: getMonoCapHeight } = await import(
    path.join(__dirname, "geist-spine-mono.mjs")
  );

  // Step 2 — Generate mark from frozen R2-7 config (NEVER modify these params)
  console.log("[generate-logo-suite] Generating mark from frozen R2-7 config…");
  let markResult;
  try {
    markResult = generate({
      steps: 4,
      stepHeight: 0.25,
      stepWidth: 0.25,
      curvature: 0.05,
      accentStep: true,
    });
  } catch (err) {
    console.error(`[generate-logo-suite] FATAL: generate() failed — ${err.message}`);
    process.exit(1);
  }
  const { markPathD, accentPathD, markWidth, markHeight } = markResult;
  console.log(`[generate-logo-suite] Mark generated: markWidth=${markWidth}, markHeight=${markHeight}`);

  // Step 3 — Load Geist Sans Regular, extract "accrue" glyphs
  console.log("[generate-logo-suite] Loading Geist Sans Regular…");
  let sansFont;
  try {
    sansFont = await loadGeistFont();
  } catch (err) {
    console.error(`[generate-logo-suite] FATAL: Could not load Geist Sans font — ${err.message}`);
    process.exit(1);
  }
  const capHeight = getCapHeight(sansFont);
  const glyphs = extractGlyphs(sansFont, "accrue", 1000);
  if (glyphs.length !== 6) {
    console.error(`[generate-logo-suite] FATAL: extractGlyphs('accrue') returned ${glyphs.length} glyphs — expected 6`);
    process.exit(1);
  }
  console.log(`[generate-logo-suite] Geist Sans loaded. capHeight=${capHeight}, glyphs=${glyphs.length}`);

  // Step 4 — Load Geist Mono Regular, extract subtitle glyphs
  console.log("[generate-logo-suite] Loading Geist Mono Regular…");
  let monoFont;
  try {
    monoFont = await loadGeistMonoFont();
  } catch (err) {
    console.error(`[generate-logo-suite] FATAL: Could not load Geist Mono font — ${err.message}`);
    process.exit(1);
  }
  const SUBTITLE_TEXT = "Billing for Elixir apps";
  // Subtitle font size = 0.42× capHeight (D-07)
  const subtitleFontSize = capHeight * 0.42;
  // Tracking +0.02em at subtitle font size (D-07)
  const trackingExtra = 0.02 * subtitleFontSize;
  const subtitleGlyphs = extractMonoGlyphs(monoFont, SUBTITLE_TEXT, subtitleFontSize);
  console.log(`[generate-logo-suite] Geist Mono loaded. subtitleGlyphs=${subtitleGlyphs.length}`);

  // Step 5 — Assemble master lockup SVG
  console.log("[generate-logo-suite] Assembling master lockup…");
  let lockupRaw;
  try {
    const assembleResult = assembleLockup(markPathD, glyphs, {
      markWidth,
      markHeight,
      capHeight,
      gapRatio: 0.15,
      viewboxH: capHeight * 1.4,
      markIsTypemark: false,
      accentPathD,
      palette: {
        ink: PALETTE.ink,
        paper: PALETTE.paper,
        accentFill: PALETTE.accentFill,
      },
    });
    lockupRaw = typeof assembleResult === "string" ? assembleResult : assembleResult.svg;
  } catch (err) {
    console.error(`[generate-logo-suite] FATAL: assembleLockup() failed — ${err.message}`);
    process.exit(1);
  }
  console.log("[generate-logo-suite] Master lockup assembled.");

  // Compute mark scaled width and gap for reuse
  const s = capHeight / markHeight;
  const markScaledW = markWidth * s;
  const gap = capHeight * 0.15;
  const wordmarkLeftX = markScaledW + gap;
  const viewboxH = capHeight * 1.4;
  const BASELINE = capHeight * 1.1;

  // ---------------------------------------------------------------------------
  // Mark-only SVG (base — used for mark variants and favicon)
  // ---------------------------------------------------------------------------

  const markSvgRaw = [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${markWidth} ${markHeight}">`,
    `  <path d="${markPathD}" fill="${PALETTE.ink}"/>`,
    `  <path d="${accentPathD}" fill="${PALETTE.accentFill}"/>`,
    `</svg>`,
  ].join("\n");

  // ---------------------------------------------------------------------------
  // 1. accrue-logo.svg — PRIMARY lockup, light bg, full color
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-logo.svg…");
  {
    const withMeta = injectMeta(lockupRaw, "accrue-logo");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-logo.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 2. accrue-logo-on-dark.svg — On-dark swap applied
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-logo-on-dark.svg…");
  {
    const darkSwapped = applyInkDarkColors(lockupRaw);
    // Add full-bleed dark background
    const vb = extractViewBox(lockupRaw);
    let withBg = darkSwapped;
    if (vb) {
      // Insert bg rect after opening svg tag
      withBg = darkSwapped.replace(
        /(<svg[^>]*>)/,
        `$1<rect width="${vb.w.toFixed(3)}" height="${vb.h}" fill="${PALETTE.inkDark}"/>`
      );
    }
    const withMeta = injectMeta(withBg, "accrue-logo-on-dark");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-logo-on-dark.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 3. accrue-logo-subtitle.svg — Lockup + subtitle glyph group below wordmark
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-logo-subtitle.svg…");
  {
    // Subtitle placement (D-07):
    //   - Left-aligned to wordmark left edge (wordmarkLeftX)
    //   - Baseline: wordmarkBaseline + capHeight * 0.55 below wordmark baseline
    //   - Tracking: +0.02em at subtitleFontSize between glyphs
    const subtitleBaselineY = BASELINE + capHeight * 0.55;

    // Apply tracking to subtitle glyphs (extra advance between glyphs)
    // The glyphs from extractMonoGlyphs already carry baked X positions from
    // extractGlyphs(). We need to re-lay them out with tracking added.
    let subtitleX = 0;
    const subtitlePaths = subtitleGlyphs.map((g, i) => {
      // Re-extract at correct position with tracking
      // We rebuild glyph positions with tracking applied as extra inter-glyph spacing
      const monoGlyph = monoFont.charToGlyph(SUBTITLE_TEXT[i]);
      const glyphPath = monoGlyph.getPath(subtitleX, 0, subtitleFontSize);
      const d = glyphPath.toPathData({ decimalPlaces: 3, flipY: false });
      const advWidth = (monoGlyph.advanceWidth / monoFont.unitsPerEm) * subtitleFontSize;
      // Add tracking after each glyph (except spaces, but +0.02em is tiny anyway)
      subtitleX += advWidth + trackingExtra;
      return `    <path d="${d}" fill="${PALETTE.slate}"/>`;
    });
    // subtitleX now holds the total run width (in subtitleFontSize units)
    const subtitleRunWidth = subtitleX;

    const subtitleGroup = [
      `  <g id="subtitle" transform="translate(${wordmarkLeftX.toFixed(3)},${subtitleBaselineY.toFixed(3)})">`,
      ...subtitlePaths,
      `  </g>`,
    ].join("\n");

    // Expand viewBox height to fit subtitle (add 0.3× subtitleFontSize below baseline)
    const expandedViewboxH = Math.max(viewboxH, subtitleBaselineY + subtitleFontSize * 0.3);

    // FIX (Defect 2): Expand viewBox WIDTH to fit subtitle run if it overflows the lockup width.
    // The subtitle left edge is at wordmarkLeftX; its right edge is at wordmarkLeftX + subtitleRunWidth.
    // Add a small right padding (0.5× trackingExtra) so the subtitle doesn't clip at the right edge.
    const vb = extractViewBox(lockupRaw);
    const lockupW = vb ? vb.w : (markScaledW + gap + glyphs.reduce((s, g) => s + g.advanceWidth, 0));
    const subtitleRightEdge = wordmarkLeftX + subtitleRunWidth + trackingExtra * 0.5;
    const expandedViewboxW = Math.max(lockupW, subtitleRightEdge);

    // Reconstruct lockup SVG with expanded viewBox (width AND height expanded as needed)
    const baseLockupExpanded = lockupRaw.replace(
      /viewBox="[^"]+"/,
      `viewBox="0 0 ${expandedViewboxW.toFixed(3)} ${expandedViewboxH.toFixed(3)}"`
    );

    // Insert subtitle group before closing </svg>
    const withSubtitle = baseLockupExpanded.replace("</svg>", `${subtitleGroup}\n</svg>`);
    const withMeta = injectMeta(withSubtitle, "accrue-logo-subtitle");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-logo-subtitle.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 4. accrue-wordmark.svg — Logotype only (mark stripped)
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-wordmark.svg…");
  {
    // Build wordmark-only SVG: just the glyph paths, no mark
    const glyphRunWidth = glyphs.reduce((sum, g) => sum + g.advanceWidth, 0);
    const wmarkH = viewboxH;

    // Glyph paths — same as in lockup but no mark, no X-offset translate
    // The glyph paths from extractGlyphs carry absolute x starting from 0
    const glyphPaths = glyphs
      .map((g, i) => {
        const safeChar = g.char.replace(/[^a-zA-Z0-9]/g, "_");
        return `    <path id="glyph-${safeChar}-${i}" d="${g.d}" fill="${PALETTE.ink}"/>`;
      })
      .join("\n");

    const wordmarkSvg = [
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${glyphRunWidth.toFixed(3)} ${wmarkH}">`,
      `  <g id="logotype" transform="translate(0,${BASELINE.toFixed(3)})">`,
      glyphPaths,
      `  </g>`,
      `</svg>`,
    ].join("\n");

    const withMeta = injectMeta(wordmarkSvg, "accrue-wordmark");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-wordmark.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 5. accrue-mark.svg — Mark-only, two-tone
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-mark.svg…");
  {
    const withMeta = injectMeta(markSvgRaw, "accrue-mark");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-mark.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 6. accrue-mark-on-dark.svg — Mark-only with on-dark inversion
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-mark-on-dark.svg…");
  {
    const darkSwapped = applyInkDarkColors(markSvgRaw);
    // Add dark bg rect
    const withBg = darkSwapped.replace(
      /(<svg[^>]*>)/,
      `$1<rect width="${markWidth}" height="${markHeight}" fill="${PALETTE.inkDark}"/>`
    );
    const withMeta = injectMeta(withBg, "accrue-mark-on-dark");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-mark-on-dark.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 7. accrue-logo-mono.svg — buildMonoSvg(lockupSvg, monoMap)
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-logo-mono.svg…");
  {
    const monoStr = buildMonoSvg(lockupRaw, PALETTE.monoMap);
    if (!monoStr) {
      console.error("[generate-logo-suite] FATAL: buildMonoSvg returned undefined for lockup");
      process.exit(1);
    }
    const withMeta = injectMeta(monoStr, "accrue-logo-mono");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-logo-mono.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 8. accrue-logo-mono-inverse.svg — mono + ink→paper swap
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-logo-mono-inverse.svg…");
  {
    const monoStr = buildMonoSvg(lockupRaw, PALETTE.monoMap);
    if (!monoStr) {
      console.error("[generate-logo-suite] FATAL: buildMonoSvg returned undefined for lockup inverse");
      process.exit(1);
    }
    // For inverse: additionally replace ink color with paper color (light on dark)
    // and #818181 (grey accent) also becomes paper for fully inverted mono look
    const inverseStr = monoStr
      .replaceAll(PALETTE.ink, PALETTE.paper)
      .replaceAll("#818181", PALETTE.paper);
    // Add dark bg
    const vb = extractViewBox(inverseStr);
    const withBg = vb
      ? inverseStr.replace(
          /(<svg[^>]*>)/,
          `$1<rect width="${vb.w.toFixed(3)}" height="${vb.h}" fill="${PALETTE.inkDark}"/>`
        )
      : inverseStr;
    const withMeta = injectMeta(withBg, "accrue-logo-mono-inverse");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-logo-mono-inverse.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 9. accrue-mark-mono.svg — buildMonoSvg(markSvg, monoMap)
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-mark-mono.svg…");
  {
    const monoMark = buildMonoSvg(markSvgRaw, PALETTE.monoMap);
    if (!monoMark) {
      console.error("[generate-logo-suite] FATAL: buildMonoSvg returned undefined for mark");
      process.exit(1);
    }
    const withMeta = injectMeta(monoMark, "accrue-mark-mono");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-mark-mono.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 10. accrue-mark-mono-inverse.svg — mark mono + ink→paper swap
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-mark-mono-inverse.svg…");
  {
    const monoMark = buildMonoSvg(markSvgRaw, PALETTE.monoMap);
    if (!monoMark) {
      console.error("[generate-logo-suite] FATAL: buildMonoSvg returned undefined for mark inverse");
      process.exit(1);
    }
    const inverseStr = monoMark
      .replaceAll(PALETTE.ink, PALETTE.paper)
      .replaceAll("#818181", PALETTE.paper);
    const withBg = inverseStr.replace(
      /(<svg[^>]*>)/,
      `$1<rect width="${markWidth}" height="${markHeight}" fill="${PALETTE.inkDark}"/>`
    );
    const withMeta = injectMeta(withBg, "accrue-mark-mono-inverse");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-mark-mono-inverse.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 11. accrue-clearspace.svg — Lockup with clearspace guide rects
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-clearspace.svg…");
  {
    // Clearspace = 1× step-height (sh) on all four sides
    // sh = markHeight * s * 0.25 = (40 * s * 0.25)
    // In lockup coordinate space: sh_lockup = markHeight_scaled * 0.25 = capHeight * 0.25
    const shLockup = capHeight * 0.25;

    const vb = extractViewBox(lockupRaw);
    const lockupW = vb ? vb.w : (markScaledW + gap + glyphs.reduce((sum, g) => sum + g.advanceWidth, 0));

    // Expanded viewBox to include clearspace margin on all sides
    const csW = lockupW + shLockup * 2;
    const csH = viewboxH + shLockup * 2;

    // Shift lockup content by shLockup to center in expanded space
    const lockupInnerContent = lockupRaw
      .replace(/^<svg[^>]*>/, "")
      .replace(/<\/svg>$/, "")
      .trim();

    const clearspaceSvg = [
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${csW.toFixed(3)} ${csH.toFixed(3)}">`,
      `  <!-- Clearspace guide: one step-height (sh = capHeight×0.25) on all four sides -->`,
      `  <g transform="translate(${shLockup.toFixed(3)},${shLockup.toFixed(3)})">`,
      lockupInnerContent,
      `  </g>`,
      `  <!-- Outer boundary (total area including clearspace) -->`,
      `  <rect x="0" y="0" width="${csW.toFixed(3)}" height="${csH.toFixed(3)}" fill="none" stroke="#5E9E84" stroke-width="0.5" stroke-dasharray="3 2"/>`,
      `  <!-- Inner boundary (logo safe zone boundary) -->`,
      `  <rect x="${shLockup.toFixed(3)}" y="${shLockup.toFixed(3)}" width="${lockupW.toFixed(3)}" height="${viewboxH}" fill="none" stroke="#5E9E84" stroke-width="0.5" stroke-dasharray="3 2"/>`,
      `</svg>`,
    ].join("\n");

    const withMeta = injectMeta(clearspaceSvg, "accrue-clearspace");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-clearspace.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 12. accrue-social-card.svg — 1200×630, dark bg, centered wordmark + subtitle
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating accrue-social-card.svg…");
  {
    const SC_W = 1200;
    const SC_H = 630;

    // Social card uses the on-dark lockup centered in the card
    // Scale the lockup to fit nicely (target ~40% of card width)
    const vb = extractViewBox(lockupRaw);
    const lockupNativeW = vb ? vb.w : (markScaledW + gap + glyphs.reduce((sum, g) => sum + g.advanceWidth, 0));
    const lockupNativeH = viewboxH;

    // Target lockup width = 40% of card width
    const targetLockupW = SC_W * 0.40;
    const lockupScale = targetLockupW / lockupNativeW;
    const scaledLockupH = lockupNativeH * lockupScale;

    // Center the lockup vertically, slightly above center to leave room for subtitle
    const lockupCenterX = (SC_W - targetLockupW) / 2;
    const lockupCenterY = (SC_H - scaledLockupH) / 2 - SC_H * 0.04;

    // Build on-dark lockup (swap colors)
    const darkLockup = applyInkDarkColors(lockupRaw);

    // Subtitle in social card: "Billing for Elixir apps" in Geist Mono paths
    // FIX (Defect 1): Render glyphs at a LARGE font size so SVGO's mergePaths/convertPathData
    // sees large coordinates and does not collapse near-degenerate small contours (like the
    // dot + stem of "i"). Then wrap the subtitle group in a scale() transform to achieve the
    // intended ~28px visual size. Centering X is computed in the LARGE font space, then
    // scaled down by the same factor so it lands correctly in the 1200×630 card.
    //
    // Target visual size = 28px. Render at the same large size as the standalone subtitle
    // (subtitleFontSize = capHeight * 0.42 ≈ 294 font units) to guarantee glyph survival.
    // scSubtitleScale = targetVisual / renderFontSize brings it down to 28px equivalent.
    const scSubtitleTargetPx = 28; // visual size in SVG units in the 1200×630 card
    const scSubtitleRenderSize = subtitleFontSize; // large render size (same as standalone)
    const scSubtitleScale = scSubtitleTargetPx / scSubtitleRenderSize;

    // Re-lay subtitle glyphs at large render size with tracking (tracking also at large size)
    const scTrackingExtra = 0.02 * scSubtitleRenderSize; // tracking at render size
    let scSubX = 0;
    const scSubtitlePaths = [];
    for (let i = 0; i < SUBTITLE_TEXT.length; i++) {
      const monoGlyph = monoFont.charToGlyph(SUBTITLE_TEXT[i]);
      const glyphPath = monoGlyph.getPath(scSubX, 0, scSubtitleRenderSize);
      const d = glyphPath.toPathData({ decimalPlaces: 3, flipY: false });
      const advWidth = (monoGlyph.advanceWidth / monoFont.unitsPerEm) * scSubtitleRenderSize;
      scSubtitlePaths.push(`    <path d="${d}" fill="#FAFBFC" opacity="0.7"/>`);
      scSubX += advWidth + scTrackingExtra;
    }
    // scSubX now holds the total run width in large (render) font units
    const scSubtitleRunWLarge = scSubX;

    // Center: scale the run width back to card units for centering arithmetic
    const scSubtitleRunW = scSubtitleRunWLarge * scSubtitleScale;
    const scSubtitleX = (SC_W - scSubtitleRunW) / 2;

    // Subtitle Y: below the lockup (in card SVG units, unaffected by inner scale)
    const scSubtitleY = lockupCenterY + scaledLockupH + scSubtitleTargetPx * 1.8;

    // Subtle grid motif (brand book direction)
    const gridLines = [];
    const gridSpacing = 60;
    for (let gx = 0; gx <= SC_W; gx += gridSpacing) {
      gridLines.push(`  <line x1="${gx}" y1="0" x2="${gx}" y2="${SC_H}" stroke="#FAFBFC" stroke-width="0.4" opacity="0.06"/>`);
    }
    for (let gy = 0; gy <= SC_H; gy += gridSpacing) {
      gridLines.push(`  <line x1="0" y1="${gy}" x2="${SC_W}" y2="${gy}" stroke="#FAFBFC" stroke-width="0.4" opacity="0.06"/>`);
    }

    // Extract lockup inner paths for embedding at scale
    const darkLockupInner = darkLockup
      .replace(/^<svg[^>]*>/, "")
      .replace(/<\/svg>$/, "")
      .trim();

    const socialCardSvg = [
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${SC_W} ${SC_H}">`,
      `  <!-- Full-bleed dark background -->`,
      `  <rect width="${SC_W}" height="${SC_H}" fill="${PALETTE.inkDark}"/>`,
      `  <!-- Subtle grid motif -->`,
      ...gridLines,
      `  <!-- Lockup (on-dark, scaled and centered) -->`,
      `  <g transform="translate(${lockupCenterX.toFixed(3)},${lockupCenterY.toFixed(3)}) scale(${lockupScale.toFixed(6)})">`,
      darkLockupInner,
      `  </g>`,
      `  <!-- Subtitle: "Billing for Elixir apps" (rendered at large size, scaled down to preserve glyph contours under SVGO) -->`,
      `  <g transform="translate(${scSubtitleX.toFixed(3)},${scSubtitleY.toFixed(3)}) scale(${scSubtitleScale.toFixed(6)})">`,
      ...scSubtitlePaths,
      `  </g>`,
      `</svg>`,
    ].join("\n");

    const withMeta = injectMeta(socialCardSvg, "accrue-social-card");
    const optimized = svgoOptimize(withMeta);
    writeSvg("accrue-social-card.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // 13. favicon.svg — Mark-only SVG passthrough (same content as accrue-mark.svg)
  // ---------------------------------------------------------------------------
  console.log("[generate-logo-suite] Generating favicon.svg…");
  {
    const withMeta = injectMeta(markSvgRaw, "favicon");
    const optimized = svgoOptimize(withMeta);
    writeSvg("favicon.svg", optimized);
  }

  // ---------------------------------------------------------------------------
  // Final verification
  // ---------------------------------------------------------------------------
  const svgFiles = fs.readdirSync(OUTPUT_DIR).filter((f) => f.endsWith(".svg"));
  console.log(`[generate-logo-suite] Done. Generated ${svgFiles.length} SVG files in ${OUTPUT_DIR}`);

  const EXPECTED_FILES = [
    "accrue-logo.svg",
    "accrue-logo-on-dark.svg",
    "accrue-logo-subtitle.svg",
    "accrue-wordmark.svg",
    "accrue-mark.svg",
    "accrue-mark-on-dark.svg",
    "accrue-logo-mono.svg",
    "accrue-logo-mono-inverse.svg",
    "accrue-mark-mono.svg",
    "accrue-mark-mono-inverse.svg",
    "accrue-clearspace.svg",
    "accrue-social-card.svg",
    "favicon.svg",
  ];

  const missing = EXPECTED_FILES.filter((f) => !svgFiles.includes(f));
  if (missing.length > 0) {
    console.error(`[generate-logo-suite] FATAL: Missing expected output files: ${missing.join(", ")}`);
    process.exit(1);
  }

  console.log(`[generate-logo-suite] All ${EXPECTED_FILES.length} expected SVG files present. Pipeline complete.`);
}

// isMain guard — per D-181-05 lesson; importing this module does NOT trigger the pipeline
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error("[generate-logo-suite] FATAL:", err);
    process.exit(1);
  });
}
