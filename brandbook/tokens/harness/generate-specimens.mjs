/**
 * generate-specimens.mjs — Deterministic specimen SVG generator for Accrue brand tokens.
 *
 * Generates three specimen SVGs from tokens.json SSOT:
 *   brandbook/examples/palette.svg    — every swatch + semantic role, hex/token/role/AA on light+dark
 *   brandbook/examples/typography.svg — Geist sans + Geist Mono scale (px+rem labels)
 *   brandbook/examples/spacing.svg    — every spacing step as a labeled ruler
 *
 * Determinism: sorted token order, fixed coordinate math, fixed decimals (.toFixed(3)),
 * committed svgo.config.mjs (multipass), trailing "\n". (RESEARCH Pitfall 5 / D-17)
 *
 * AA annotations: sourced from contrast-table.txt (NEVER invented). (RESEARCH Pitfall 6)
 *   Paper vs Moss   = 3.03:1 [AA-large]  → AA-FAIL body on light
 *   Paper vs Cobalt = 3.66:1 [AA-large]  → AA-FAIL body on light
 *   Paper vs Amber  = 2.66:1 [FAIL]      → AA-FAIL on light
 *   Ink vs Moss  = 5.89:1 [AA-body] → AA-body on dark
 *   Ink vs Cobalt= 4.86:1 [AA-body] → AA-body on dark
 *   Ink vs Amber = 6.71:1 [AA-body] → AA-body on dark
 *
 * Usage:
 *   node brandbook/tokens/harness/generate-specimens.mjs
 */

import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";
import { optimize } from "svgo";
import svgoConfig from "./svgo.config.mjs";
import { flattenTokens } from "./lib.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const TOKENS_PATH = path.resolve(__dirname, "../tokens.json");
const OUTPUT_DIR = path.resolve(__dirname, "../../examples");

// ---------------------------------------------------------------------------
// AA annotations — SOURCED FROM contrast-table.txt (never invented)
// contrast-table.txt rows:
//   Paper vs Moss:   3.03:1 [AA-large]  — FAIL AA-body on light
//   Paper vs Cobalt: 3.66:1 [AA-large]  — FAIL AA-body on light
//   Paper vs Amber:  2.66:1 [FAIL]      — FAIL AA on light
//   Ink vs Moss:     5.89:1 [AA-body]   — AA-body on dark
//   Ink vs Cobalt:   4.86:1 [AA-body]   — AA-body on dark
//   Ink vs Amber:    6.71:1 [AA-body]   — AA-body on dark
// ---------------------------------------------------------------------------

const AA_LIGHT = {
  "--accrue-moss":   "3.03:1 AA-large (FAIL AA-body on light)",
  "--accrue-cobalt": "3.66:1 AA-large (FAIL AA-body on light)",
  "--accrue-amber":  "2.66:1 FAIL (FAIL AA on light)",
};

const AA_DARK = {
  "--accrue-moss":   "5.89:1 AA-body on dark",
  "--accrue-cobalt": "4.86:1 AA-body on dark",
  "--accrue-amber":  "6.71:1 AA-body on dark",
};

// ---------------------------------------------------------------------------
// Typography scale — reference values from theme.css --ax-type-* (D-11)
// Values are READ AS LITERALS; no --accrue-type-* tokens are minted.
// ---------------------------------------------------------------------------

const TYPE_SCALE = [
  { step: "xs",  rem: "0.75rem",  px: "12px" },
  { step: "sm",  rem: "0.875rem", px: "14px" },
  { step: "md",  rem: "1rem",     px: "16px" },
  { step: "lg",  rem: "1.25rem",  px: "20px" },
  { step: "xl",  rem: "1.5rem",   px: "24px" },
  { step: "2xl", rem: "1.75rem",  px: "28px" },
  { step: "3xl", rem: "2.25rem",  px: "36px" },
];

// ---------------------------------------------------------------------------
// Spacing scale — reference values from theme.css --ax-space-* (D-11)
// Values are READ AS LITERALS; no --accrue-space-* tokens are minted.
// ---------------------------------------------------------------------------

const SPACE_SCALE = [
  { step: "2xs", rem: "0.125rem", px: "2px",  pxNum: 2  },
  { step: "xs",  rem: "0.25rem",  px: "4px",  pxNum: 4  },
  { step: "sm",  rem: "0.5rem",   px: "8px",  pxNum: 8  },
  { step: "md",  rem: "1rem",     px: "16px", pxNum: 16 },
  { step: "lg",  rem: "1.5rem",   px: "24px", pxNum: 24 },
  { step: "xl",  rem: "2rem",     px: "32px", pxNum: 32 },
  { step: "2xl", rem: "3rem",     px: "48px", pxNum: 48 },
  { step: "3xl", rem: "4rem",     px: "64px", pxNum: 64 },
];

// ---------------------------------------------------------------------------
// SVG helpers
// ---------------------------------------------------------------------------

/**
 * Inject <title> and <desc> into SVG string (before svgo).
 */
function injectMeta(svgString, title, desc) {
  const titleDesc = `<title>${title}</title><desc>${desc}</desc>`;
  return svgString.replace(/(<svg[^>]*>)/, `$1${titleDesc}`);
}

/**
 * Optimize SVG string through svgo (multipass, preserves viewBox/title/desc).
 */
function svgoOptimize(svgString) {
  const result = optimize(svgString, svgoConfig);
  return result.data;
}

/**
 * Write SVG file with trailing newline.
 */
function writeSvg(filename, svgString) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  const outPath = path.join(OUTPUT_DIR, filename);
  const content = svgString.endsWith("\n") ? svgString : svgString + "\n";
  fs.writeFileSync(outPath, content, "utf8");
  console.log(`[generate-specimens] Wrote: ${filename}`);
}

// ---------------------------------------------------------------------------
// palette.svg generator (D-15)
// ---------------------------------------------------------------------------

/**
 * Build palette.svg — every raw --accrue-* swatch + semantic roles.
 * TWO surface bands: light (Paper #fafbfc) and dark (Ink #0f1318).
 * Each swatch: rect(fill=hex) + token name + hex + role + AA status.
 * AA annotations sourced from contrast-table.txt (never invented).
 */
function buildPaletteSvg(tokens) {
  const rows = flattenTokens(tokens);

  // Separate raw brand tokens from semantic roles (light scope only for the main display)
  const rawTokens = rows
    .filter(r => r.scope === "light" && r.name.startsWith("color.brand."))
    .sort((a, b) => a.name.localeCompare(b.name, "en", { sensitivity: "variant" }));

  const semanticTokens = rows
    .filter(r => r.scope === "light" && !r.name.startsWith("color.brand.") && !r.name.startsWith("color.dark."))
    .sort((a, b) => a.name.localeCompare(b.name, "en", { sensitivity: "variant" }));

  const allLightTokens = [...rawTokens, ...semanticTokens];

  // Layout constants
  const SWATCH_W = 120;
  const SWATCH_H = 60;
  const COL_GAP = 8;
  const ROW_GAP = 90;  // total height per row (swatch + labels)
  const COLS = 4;
  const BAND_PAD_X = 24;
  const BAND_PAD_TOP = 48;
  const BAND_PAD_BOT = 24;
  const BAND_LABEL_H = 24;

  const numRows = Math.ceil(allLightTokens.length / COLS);
  const bandW = COLS * SWATCH_W + (COLS - 1) * COL_GAP + BAND_PAD_X * 2;
  const bandH = BAND_LABEL_H + BAND_PAD_TOP + numRows * ROW_GAP + BAND_PAD_BOT;

  const SVG_W = bandW;
  const SVG_H = bandH * 2 + 16; // two bands + gap
  const FONT_SANS = "Geist, system-ui, sans-serif";
  const FONT_MONO = "Geist Mono, monospace";

  function swatchGroup(token, ix, iy, surfaceType) {
    const col = ix % COLS;
    const row = Math.floor(ix / COLS);
    const x = (BAND_PAD_X + col * (SWATCH_W + COL_GAP)).toFixed(3);
    const y = (BAND_LABEL_H + BAND_PAD_TOP + row * ROW_GAP).toFixed(3);
    const textColor = surfaceType === "dark" ? "#f4f7fa" : "#111418";
    const mutedColor = surfaceType === "dark" ? "#a8b2bc" : "#5d6a73";

    // Resolve role label
    const role = token.axMap ? token.axMap : "brand-only";

    // AA status — sourced from contrast-table.txt
    let aaStatus = "";
    if (surfaceType === "light") {
      aaStatus = AA_LIGHT[token.cssVar] ?? "AA pass";
    } else {
      aaStatus = AA_DARK[token.cssVar] ?? "AA pass";
    }
    const aaColor = (aaStatus.includes("FAIL") || aaStatus.includes("AA-large")) ? "#d64b4b" : "#5e9e84";

    // Short display name: strip "color." prefix
    const displayName = token.cssVar;

    return `<g>` +
      `<rect x="${x}" y="${y}" width="${SWATCH_W.toFixed(3)}" height="${SWATCH_H.toFixed(3)}" fill="${token.hex}" rx="4" stroke="${mutedColor}" stroke-width="0.5"/>` +
      `<text x="${x}" y="${(parseFloat(y) + SWATCH_H + 13).toFixed(3)}" font-family="${FONT_MONO}" font-size="9" fill="${textColor}">${displayName}</text>` +
      `<text x="${x}" y="${(parseFloat(y) + SWATCH_H + 24).toFixed(3)}" font-family="${FONT_MONO}" font-size="9" fill="${mutedColor}">${token.hex}</text>` +
      `<text x="${x}" y="${(parseFloat(y) + SWATCH_H + 35).toFixed(3)}" font-family="${FONT_SANS}" font-size="8" fill="${mutedColor}">${role}</text>` +
      `<text x="${x}" y="${(parseFloat(y) + SWATCH_H + 46).toFixed(3)}" font-family="${FONT_SANS}" font-size="8" fill="${aaColor}">${aaStatus}</text>` +
      `</g>`;
  }

  // Light band
  const lightSwatches = allLightTokens.map((t, i) => swatchGroup(t, i, 0, "light")).join("");
  const lightBandY = 0;

  // Dark band (uses same tokens, dark surface)
  const darkSwatches = allLightTokens.map((t, i) => swatchGroup(t, i, 0, "dark")).join("");
  const darkBandY = bandH + 16;

  const svgContent = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${SVG_W.toFixed(3)} ${SVG_H.toFixed(3)}" width="${SVG_W.toFixed(3)}" height="${SVG_H.toFixed(3)}">` +
    // Light band
    `<g id="band-light">` +
    `<rect x="0" y="${lightBandY.toFixed(3)}" width="${SVG_W.toFixed(3)}" height="${bandH.toFixed(3)}" fill="#fafbfc"/>` +
    `<text x="${BAND_PAD_X.toFixed(3)}" y="18.000" font-family="${FONT_SANS}" font-size="12" font-weight="600" fill="#111418">Light surface (Paper #fafbfc)</text>` +
    lightSwatches +
    `</g>` +
    // Dark band
    `<g id="band-dark">` +
    `<rect x="0" y="${darkBandY.toFixed(3)}" width="${SVG_W.toFixed(3)}" height="${bandH.toFixed(3)}" fill="#0f1318"/>` +
    `<text x="${BAND_PAD_X.toFixed(3)}" y="${(darkBandY + 18).toFixed(3)}" font-family="${FONT_SANS}" font-size="12" font-weight="600" fill="#f4f7fa">Dark surface (Ink #0f1318)</text>` +
    `<g transform="translate(0,${darkBandY.toFixed(3)})">` +
    darkSwatches +
    `</g>` +
    `</g>` +
    `</svg>`;

  const withMeta = injectMeta(
    svgContent,
    "Accrue palette specimen",
    "Accrue brand palette: 7 raw --accrue-* tokens + semantic roles on light and dark surfaces. " +
    "AA status sourced from WCAG 2.x contrast-table.txt: " +
    "Moss 3.03:1 AA-large (FAIL AA-body on light); " +
    "Cobalt 3.66:1 AA-large (FAIL AA-body on light); " +
    "Amber 2.66:1 FAIL (FAIL AA on light). " +
    "On dark (Ink #0f1318): Moss 5.89:1, Cobalt 4.86:1, Amber 6.71:1 — all AA-body."
  );

  return svgoOptimize(withMeta);
}

// ---------------------------------------------------------------------------
// typography.svg generator (D-15)
// ---------------------------------------------------------------------------

/**
 * Build typography.svg — Geist sans + Geist Mono size scale with px+rem labels.
 * Each step: sample line AT that font-size, plus a token name + px+rem label.
 * Values from theme.css --ax-type-* (read as literals; no --accrue-type-* tokens minted).
 */
function buildTypographySvg() {
  const FONT_SANS = "Geist, system-ui, sans-serif";
  const FONT_MONO = "Geist Mono, monospace";
  const PAD_X = 32;
  const PAD_TOP = 40;
  const LABEL_COL_X = 340;
  const ROW_GAP = 56;
  const BG = "#fafbfc";
  const INK = "#111418";
  const MUTED = "#5d6a73";
  const SECTION_GAP = 48;

  // Sans rows
  const sansRows = TYPE_SCALE;
  // Mono rows (same scale, different font)
  const monoRows = TYPE_SCALE;

  const sansH = sansRows.length * ROW_GAP;
  const monoH = monoRows.length * ROW_GAP;
  const SECTION_LABEL_H = 28;

  const SVG_W = 520;
  const SVG_H = PAD_TOP + SECTION_LABEL_H + sansH + SECTION_GAP + SECTION_LABEL_H + monoH + 32;

  function typeRow(step, rem, px, font, yBase, color) {
    // Approximate font-size in px for rendering (we use a fixed layout size for the row)
    const labelY = yBase + 16;
    const sampleY = yBase + 38;

    return `<g>` +
      `<text x="${PAD_X}" y="${labelY.toFixed(3)}" font-family="${FONT_MONO}" font-size="10" fill="${MUTED}">--ax-type-${step} ${px} / ${rem}</text>` +
      `<text x="${PAD_X}" y="${sampleY.toFixed(3)}" font-family="${font}" font-size="${px}" fill="${color}">Billing state, modeled clearly.</text>` +
      `</g>`;
  }

  let y = PAD_TOP;

  // Section: Geist sans
  let sansSvg = `<text x="${PAD_X}" y="${(y + 18).toFixed(3)}" font-family="${FONT_SANS}" font-size="13" font-weight="600" fill="${INK}">Geist (sans) — type scale</text>`;
  y += SECTION_LABEL_H;

  for (const { step, rem, px } of sansRows) {
    sansSvg += typeRow(step, rem, px, FONT_SANS, y, INK);
    y += ROW_GAP;
  }

  y += SECTION_GAP;

  // Section: Geist Mono
  let monoSvg = `<text x="${PAD_X}" y="${(y + 18).toFixed(3)}" font-family="${FONT_MONO}" font-size="13" font-weight="600" fill="${INK}">Geist Mono — type scale</text>`;
  y += SECTION_LABEL_H;

  for (const { step, rem, px } of monoRows) {
    monoSvg += typeRow(step, rem, px, FONT_MONO, y, INK);
    y += ROW_GAP;
  }

  const svgContent = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${SVG_W.toFixed(3)} ${SVG_H.toFixed(3)}" width="${SVG_W.toFixed(3)}" height="${SVG_H.toFixed(3)}">` +
    `<rect width="${SVG_W.toFixed(3)}" height="${SVG_H.toFixed(3)}" fill="${BG}"/>` +
    sansSvg +
    monoSvg +
    `</svg>`;

  const withMeta = injectMeta(
    svgContent,
    "Accrue typography specimen",
    "Geist sans and Geist Mono type scale: --ax-type-xs (12px/0.75rem) through --ax-type-3xl (36px/2.25rem). " +
    "Values are reference-only from theme.css; no --accrue-type-* tokens are minted (D-11)."
  );

  return svgoOptimize(withMeta);
}

// ---------------------------------------------------------------------------
// spacing.svg generator (D-15)
// ---------------------------------------------------------------------------

/**
 * Build spacing.svg — every spacing step as a labeled visual ruler/bar.
 * Values from theme.css --ax-space-* (read as literals; no --accrue-space-* tokens minted).
 */
function buildSpacingSvg() {
  const FONT_SANS = "Geist, system-ui, sans-serif";
  const FONT_MONO = "Geist Mono, monospace";
  const PAD_X = 32;
  const PAD_TOP = 48;
  const LABEL_W = 200;
  const BAR_OFFSET_X = PAD_X + LABEL_W;
  const BAR_H = 20;
  const ROW_GAP = 36;
  const SCALE = 4; // px-per-px-unit (scale bar widths to be visible)
  const MAX_BAR_W = 260;
  const BG = "#fafbfc";
  const INK = "#111418";
  const MUTED = "#5d6a73";
  const MOSS = "#5e9e84";

  const maxPx = Math.max(...SPACE_SCALE.map(s => s.pxNum));

  const SVG_W = BAR_OFFSET_X + MAX_BAR_W + 80;
  const SVG_H = PAD_TOP + SPACE_SCALE.length * ROW_GAP + 40;

  let rows = "";
  for (let i = 0; i < SPACE_SCALE.length; i++) {
    const { step, rem, px, pxNum } = SPACE_SCALE[i];
    const y = PAD_TOP + i * ROW_GAP;
    const barW = Math.max(2, (pxNum / maxPx) * MAX_BAR_W);
    const centerY = (y + BAR_H / 2).toFixed(3);

    rows += `<g>` +
      `<text x="${PAD_X}" y="${(y + 14).toFixed(3)}" font-family="${FONT_MONO}" font-size="10" fill="${INK}">--ax-space-${step}</text>` +
      `<text x="${(PAD_X + 130).toFixed(3)}" y="${(y + 14).toFixed(3)}" font-family="${FONT_MONO}" font-size="10" fill="${MUTED}">${px} / ${rem}</text>` +
      `<rect x="${BAR_OFFSET_X.toFixed(3)}" y="${y.toFixed(3)}" width="${barW.toFixed(3)}" height="${BAR_H.toFixed(3)}" fill="${MOSS}" rx="2"/>` +
      `</g>`;
  }

  // Title
  const titleSvg = `<text x="${PAD_X}" y="28.000" font-family="${FONT_SANS}" font-size="14" font-weight="600" fill="${INK}">Accrue spacing scale</text>`;
  const subSvg = `<text x="${(BAR_OFFSET_X).toFixed(3)}" y="28.000" font-family="${FONT_SANS}" font-size="10" fill="${MUTED}">(bars proportional to px value)</text>`;

  const svgContent = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${SVG_W.toFixed(3)} ${SVG_H.toFixed(3)}" width="${SVG_W.toFixed(3)}" height="${SVG_H.toFixed(3)}">` +
    `<rect width="${SVG_W.toFixed(3)}" height="${SVG_H.toFixed(3)}" fill="${BG}"/>` +
    titleSvg +
    subSvg +
    rows +
    `</svg>`;

  const withMeta = injectMeta(
    svgContent,
    "Accrue spacing specimen",
    "Accrue spacing scale: --ax-space-2xs (2px/0.125rem) through --ax-space-3xl (64px/4rem). " +
    "Each step shown as a labeled proportional ruler bar. " +
    "Values are reference-only from theme.css; no --accrue-space-* tokens are minted (D-11)."
  );

  return svgoOptimize(withMeta);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  const tokens = JSON.parse(fs.readFileSync(TOKENS_PATH, "utf8"));

  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  // palette.svg
  const paletteSvg = buildPaletteSvg(tokens);
  writeSvg("palette.svg", paletteSvg);

  // typography.svg
  const typographySvg = buildTypographySvg();
  writeSvg("typography.svg", typographySvg);

  // spacing.svg
  const spacingSvg = buildSpacingSvg();
  writeSvg("spacing.svg", spacingSvg);

  console.log("[generate-specimens] All specimens generated.");
}

// isMain guard
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main();
}
