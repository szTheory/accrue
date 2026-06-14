/**
 * lint.mjs — Pre-gate lint suite for SVG logo candidates
 *
 * Implements 6 deterministic checks that must pass before any candidate
 * enters the gallery. Designed per D-04 (overgenerate-and-cull), D-07
 * (deterministic pixel heuristics), D-09 (reproducible harness).
 *
 * Usage:
 *   node harness/lint.mjs              # runs all SVGs in candidates/ dir
 *   node harness/lint.mjs --test       # smoke test with inline fixtures, exits 0
 *
 * Exports:
 *   lintCandidate(candidate, opts)    — orchestrator: runs all 6 checks on one candidate
 *   lintValidParse(svgString)         — parse check
 *   lintNoRectBackground(svgString)   — no full-viewBox rect
 *   lintNoSubtitle(svgString)         — no subtitle/tagline text elements
 *   lintMonochromeDeriv(svgString)    — all colors map to Ink/Paper (no saturated hues)
 *   lintLockupGapRatio(mark, logo, cap) — gap in spec range (skipped for Direction D)
 *   lint16pxLegibility(p16, p32)      — contrast ratio + edge density pixel heuristics
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { DOMParser } from "@xmldom/xmldom";
import { PNG } from "pngjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const argOutputDir = (() => {
  const i = process.argv.indexOf("--output-dir");
  return i !== -1 ? path.resolve(process.argv[i + 1]) : null;
})();
const PHASE_DIR = argOutputDir ?? path.resolve(__dirname, "..");
const CANDIDATES_DIR = path.join(PHASE_DIR, "candidates");
const REJECTED_DIR = path.join(PHASE_DIR, "rejected");
const LINT_LOG = path.join(PHASE_DIR, "lint-results.ndjson");

// ---------------------------------------------------------------------------
// Lint 1: Valid SVG parse
// ---------------------------------------------------------------------------

/**
 * Fail if the SVG string is not a valid XML document or contains parsererror.
 * @param {string} svgString
 * @returns {boolean} true = pass
 */
function lintValidParse(svgString) {
  try {
    const doc = new DOMParser().parseFromString(svgString, "image/svg+xml");
    const errs = doc.getElementsByTagName("parsererror");
    return errs.length === 0;
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Lint 2: No rectangular background
// ---------------------------------------------------------------------------

/**
 * Fail if any <rect> element covers >= 80% of the viewBox area.
 * Hard logo constraint #1: marks breathe / break boundaries.
 * @param {string} svgString
 * @returns {boolean} true = pass
 */
function lintNoRectBackground(svgString) {
  try {
    const doc = new DOMParser().parseFromString(svgString, "image/svg+xml");
    const svg = doc.documentElement;
    const vbAttr = svg.getAttribute("viewBox");
    const vb = vbAttr ? vbAttr.split(/[\s,]+/).map(Number) : [0, 0, 100, 100];
    const [, , vbW, vbH] = vb;
    const threshold = 0.8 * vbW * vbH;

    const rects = doc.getElementsByTagName("rect");
    for (let i = 0; i < rects.length; i++) {
      const rect = rects.item(i);
      const w = parseFloat(rect.getAttribute("width") ?? "0");
      const h = parseFloat(rect.getAttribute("height") ?? "0");
      if (w * h >= threshold) {
        return false;
      }
    }
    return true;
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Lint 3: No subtitle
// ---------------------------------------------------------------------------

/**
 * Fail if the SVG has > 1 <text> element (subtitle heuristic), or if any
 * single text content exceeds 30 chars (tagline heuristic).
 * Hard logo constraint #3: main lockup carries no subtitle.
 * @param {string} svgString
 * @returns {boolean} true = pass
 */
function lintNoSubtitle(svgString) {
  try {
    const doc = new DOMParser().parseFromString(svgString, "image/svg+xml");
    const texts = doc.getElementsByTagName("text");
    if (texts.length > 1) return false;
    for (let i = 0; i < texts.length; i++) {
      const content = texts.item(i).textContent ?? "";
      if (content.length > 30) return false;
    }
    return true;
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Lint 4: Monochrome-derivable
// ---------------------------------------------------------------------------

/**
 * Fail if any hex color in the SVG has HSV saturation > 0.15.
 * NOTE: #111418 (sat≈0.29) and #24303B (sat≈0.39) exceed this threshold.
 * Generated SVGs use #181818 (sat=0) for Ink. Color variants (e.g. Moss #5E9E84,
 * sat≈0.40) must pass this lint via their mono-derived SVG (monoSvgString override),
 * not the color SVG itself.
 * @param {string} svgString
 * @returns {boolean} true = pass
 */
function lintMonochromeDeriv(svgString) {
  const colorRe = /#([0-9a-fA-F]{3,6})\b/g;
  const matches = [...svgString.matchAll(colorRe)];
  for (const m of matches) {
    const hex = m[1];
    const full = hex.length === 3
      ? hex.split("").map((c) => c + c).join("")
      : hex;
    const r = parseInt(full.slice(0, 2), 16);
    const g = parseInt(full.slice(2, 4), 16);
    const b = parseInt(full.slice(4, 6), 16);
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const saturation = max === 0 ? 0 : (max - min) / max;
    if (saturation > 0.15) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Lint 5: Lockup gap ratio
// ---------------------------------------------------------------------------

/**
 * Check that the gap between mark right edge and logotype left edge is
 * within spec: 0.08–0.35 × capHeight.
 *
 * Direction D (integrated typemarks) skips this check — callers should pass
 * skipGapRatio: true via the candidate metadata.
 *
 * @param {{ xMax: number }} markBbox
 * @param {{ xMin: number }} logotypeBbox
 * @param {number} capHeight
 * @returns {{ pass: boolean, ratio: number, reason: string }}
 */
function lintLockupGapRatio(markBbox, logotypeBbox, capHeight) {
  const gap = logotypeBbox.xMin - markBbox.xMax;
  const ratio = gap / capHeight;
  const pass = ratio >= 0.08 && ratio <= 0.35;
  let reason;
  if (ratio < 0.08) {
    reason = `gap too tight (ratio ${ratio.toFixed(4)} < 0.08)`;
  } else if (ratio > 0.35) {
    reason = `gap too wide — optically separated (ratio ${ratio.toFixed(4)} > 0.35)`;
  } else {
    reason = "pass";
  }
  return { pass, ratio, reason };
}

// ---------------------------------------------------------------------------
// Lint 6: 16px legibility (pixel heuristics via pngjs)
// ---------------------------------------------------------------------------

/**
 * WCAG 2.0 relative luminance from sRGB components.
 * @param {number} r 0-255
 * @param {number} g 0-255
 * @param {number} b 0-255
 * @returns {number} 0.0-1.0
 */
function luminance(r, g, b) {
  const toLinear = (v) => {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
}

/**
 * Compute WCAG contrast ratio for a decoded PNG.
 * Background is sampled from the four corner pixels; foreground is the darkest
 * non-transparent pixel (most ink).
 * @param {{ data: Buffer, width: number, height: number }} png
 * @returns {number}
 */
function contrastRatio(png) {
  const { data, width, height } = png;
  const getPixel = (x, y) => {
    const i = (width * y + x) << 2;
    return { r: data[i], g: data[i + 1], b: data[i + 2], a: data[i + 3] };
  };
  const corners = [
    getPixel(0, 0),
    getPixel(width - 1, 0),
    getPixel(0, height - 1),
    getPixel(width - 1, height - 1),
  ];
  const bgLum =
    corners.reduce((s, p) => s + luminance(p.r, p.g, p.b), 0) / corners.length;
  let fgLum = 1;
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] > 128) {
      const l = luminance(data[i], data[i + 1], data[i + 2]);
      if (l < fgLum) fgLum = l;
    }
  }
  const L1 = Math.max(bgLum, fgLum);
  const L2 = Math.min(bgLum, fgLum);
  return (L1 + 0.05) / (L2 + 0.05);
}

/**
 * Sobel-lite edge density: fraction of pixels with gradient magnitude > 0.15.
 * @param {{ data: Buffer, width: number, height: number }} png
 * @returns {number}
 */
function edgeDensity(png) {
  const { data, width, height } = png;
  const gray = (x, y) => {
    const i = (width * y + x) << 2;
    return luminance(data[i], data[i + 1], data[i + 2]);
  };
  let edgeCount = 0;
  for (let y = 1; y < height - 1; y++) {
    for (let x = 1; x < width - 1; x++) {
      const gx = gray(x + 1, y) - gray(x - 1, y);
      const gy = gray(x, y + 1) - gray(x, y - 1);
      const mag = Math.sqrt(gx * gx + gy * gy);
      if (mag > 0.15) edgeCount++;
    }
  }
  return edgeCount / (width * height);
}

/**
 * Deterministic 16px legibility check using pngjs pixel heuristics.
 * Requires two PNG files: 16px render and 32px render of the same candidate.
 *
 * Thresholds (D-07 — tuned empirically):
 *   - Contrast ratio >= 3.0 (WCAG AA-large threshold; re-instated after coordinate-space
 *     bugs caused all candidates to render as "a few dots" — the 1.75 tuning was based
 *     on broken renders and is now invalidated. Post-fix renders produce full glyph+mark
 *     ink, so CR 3.0 is achievable for all well-formed candidates.)
 *   - Edge density ratio (16px / 32px) >= 0.35 (structure must survive downscale)
 *
 * Threshold history: lowered 3.0 → 1.75 during Plan 06 to explain "thin marks" that were
 * actually near-invisible due to the coordinate-space bugs. Reverted to 3.0 in post-completion
 * fix once the root cause was identified and fixed. If the re-run still culls a large fraction
 * at CR 3.0, report numbers honestly — do NOT silently re-tune again.
 *
 * @param {string} png16Path  path to 16px PNG
 * @param {string} png32Path  path to 32px PNG
 * @returns {{ pass: boolean, contrastRatio: number, edgeDensityRatio: number, reason: string }}
 */
function lint16pxLegibility(png16Path, png32Path) {
  const png16 = PNG.sync.read(fs.readFileSync(png16Path));
  const png32 = PNG.sync.read(fs.readFileSync(png32Path));
  const cr = contrastRatio(png16);
  const ed16 = edgeDensity(png16);
  const ed32 = edgeDensity(png32);
  const edRatio = ed32 > 0 ? ed16 / ed32 : 1;
  // Threshold: 3.0 contrast ratio (WCAG AA-large; reverted from 1.75 — see jsdoc above)
  const CR_THRESHOLD = 3.0;
  const pass = cr >= CR_THRESHOLD && edRatio >= 0.35;
  let reason;
  if (cr < CR_THRESHOLD) {
    reason = `contrast ratio ${cr.toFixed(2)} < ${CR_THRESHOLD} (icon legibility threshold)`;
  } else if (edRatio < 0.35) {
    reason = `edge density collapses at 16px (ratio ${edRatio.toFixed(2)} < 0.35)`;
  } else {
    reason = "pass";
  }
  return { pass, contrastRatio: cr, edgeDensityRatio: edRatio, reason };
}

// ---------------------------------------------------------------------------
// Top-level orchestrator
// ---------------------------------------------------------------------------

/**
 * Run all applicable lint checks on a single candidate.
 *
 * @param {{
 *   id: string,
 *   direction: string,
 *   svgString: string,
 *   monoSvgString?: string,
 *   skipGapRatio?: boolean,
 *   markBbox?: { xMax: number },
 *   logotypeBbox?: { xMin: number },
 *   capHeight?: number,
 *   png16Path?: string,
 *   png32Path?: string,
 * }} candidate
 * @param {{ writeLog?: boolean }} [opts]
 * @returns {{ pass: boolean, failures: string[] }}
 */
function lintCandidate(candidate, opts = {}) {
  const { id, svgString, monoSvgString, skipGapRatio, markBbox, logotypeBbox, capHeight, png16Path, png32Path } = candidate;
  const { writeLog = false } = opts;
  const failures = [];

  function record(lint, pass, reason) {
    if (writeLog) {
      const entry = { candidateId: id, lint, pass, reason: pass ? null : reason };
      fs.appendFileSync(LINT_LOG, JSON.stringify(entry) + "\n");
    }
  }

  // 1. Valid parse
  const parsePassed = lintValidParse(svgString);
  record("valid-parse", parsePassed, "SVG parse failed or contains parsererror");
  if (!parsePassed) failures.push("valid-parse");

  // 2. No rect background
  const rectPassed = lintNoRectBackground(svgString);
  record("no-rect-background", rectPassed, "rect element covers >= 80% of viewBox area");
  if (!rectPassed) failures.push("no-rect-background");

  // 3. No subtitle
  const subtitlePassed = lintNoSubtitle(svgString);
  record("no-subtitle", subtitlePassed, "> 1 text elements or tagline text > 30 chars");
  if (!subtitlePassed) failures.push("no-subtitle");

  // 4. Monochrome-derivable
  // For color variants, lint against the mono-derived SVG (monoSvgString override)
  // rather than the color SVG itself — the color SVG is intentionally saturated.
  const svgForMonoLint = monoSvgString ?? svgString;
  const monoPassed = lintMonochromeDeriv(svgForMonoLint);
  record("monochrome-derivable", monoPassed, "saturated fill — if color variant, check monoMap config produces a low-saturation SVG");
  if (!monoPassed) failures.push("monochrome-derivable");

  // 5. Lockup gap ratio — skip for Direction D integrated typemarks
  if (skipGapRatio === true) {
    console.log(`[lint] ${id}: skipping gap-ratio for Direction D integrated typemark`);
    record("lockup-gap-ratio", true, null);
  } else if (markBbox && logotypeBbox && capHeight) {
    const gapResult = lintLockupGapRatio(markBbox, logotypeBbox, capHeight);
    record("lockup-gap-ratio", gapResult.pass, gapResult.reason);
    if (!gapResult.pass) failures.push("lockup-gap-ratio");
  }

  // 6. 16px legibility (only if PNG paths provided)
  if (png16Path && png32Path && fs.existsSync(png16Path) && fs.existsSync(png32Path)) {
    const legResult = lint16pxLegibility(png16Path, png32Path);
    record("16px-legibility", legResult.pass, legResult.reason);
    if (!legResult.pass) failures.push("16px-legibility");
  }

  return { pass: failures.length === 0, failures };
}

// ---------------------------------------------------------------------------
// CLI main()
// ---------------------------------------------------------------------------

async function main() {
  const TEST_MODE = process.argv.includes("--test");

  if (TEST_MODE) {
    // Smoke test: 5 inline fixture assertions
    let allPassed = true;

    // Fixture 1: full-viewBox rect → should fail no-rect-background
    const fullRectSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" fill="white"/></svg>`;
    const r1 = lintNoRectBackground(fullRectSvg);
    if (r1 !== false) {
      console.error("[lint] smoke: FAIL — full-viewBox rect should have been rejected");
      allPassed = false;
    }

    // Fixture 2: small rect → should pass no-rect-background
    const smallRectSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="20" height="20" fill="white"/></svg>`;
    const r2 = lintNoRectBackground(smallRectSvg);
    if (r2 !== true) {
      console.error("[lint] smoke: FAIL — small rect (20×20 in 100×100) should have passed");
      allPassed = false;
    }

    // Fixture 3: two-text SVG → should fail no-subtitle
    const twoTextSvg = `<svg xmlns="http://www.w3.org/2000/svg"><text>accrue</text><text>billing</text></svg>`;
    const r3 = lintNoSubtitle(twoTextSvg);
    if (r3 !== false) {
      console.error("[lint] smoke: FAIL — two-text SVG should have been rejected");
      allPassed = false;
    }

    // Fixture 4: saturated color → should fail monochrome-derivable
    // #5E9E84: R=94, G=158, B=132; max=158, min=94; sat=(158-94)/158=0.405 > 0.15
    const saturatedSvg = `<svg xmlns="http://www.w3.org/2000/svg"><path fill="#5E9E84" d="M 0 0 L 10 0 Z"/></svg>`;
    const r4 = lintMonochromeDeriv(saturatedSvg);
    if (r4 !== false) {
      console.error("[lint] smoke: FAIL — saturated color #5E9E84 should have been rejected");
      allPassed = false;
    }

    // Fixture 5: valid minimal SVG → should pass all string-based checks
    // Use a pure grey (#181818) to ensure monochrome-derivable passes.
    // Note: brand darks like #111418 have HSV sat ~0.29 (blue tint) and would fail the
    // strict >0.15 threshold — generated SVGs use palette.ink but the lint is intentionally
    // conservative; palette colors are validated at generator config time, not here.
    const validSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50"><path d="M 10 10 L 50 10 L 50 40 Z" fill="#181818"/></svg>`;
    const r5a = lintValidParse(validSvg);
    const r5b = lintNoRectBackground(validSvg);
    const r5c = lintNoSubtitle(validSvg);
    const r5d = lintMonochromeDeriv(validSvg);
    if (!r5a || !r5b || !r5c || !r5d) {
      console.error(`[lint] smoke: FAIL — valid SVG should have passed all string checks (parse=${r5a}, noRect=${r5b}, noSub=${r5c}, mono=${r5d})`);
      allPassed = false;
    }

    // Fixture 6: brand-neutral dark color → should pass monochrome-derivable
    // #111418: R=17, G=20, B=24; max=24, min=17; sat=(24-17)/24=0.292... wait
    // Let's recheck: R=0x11=17, G=0x14=20, B=0x18=24; max=24, min=17; sat=7/24=0.29
    // Hmm, that's > 0.15. Let me verify the brand color manually.
    // Actually for #111418: R=17,G=20,B=24. sat=(24-17)/24=0.292 which > 0.15.
    // But the plan says brand colors pass with sat < 0.15. Let me re-examine.
    // #111418: R=0x11=17, G=0x14=20, B=0x18=24
    // max=24, min=17, diff=7, sat=7/24=0.2916 > 0.15
    // This means the plan comment is incorrect about #111418 — it does have mild saturation.
    // Pure near-black like #111111 would have sat=0.
    // For the smoke test, use a definitive near-neutral: #333333 (sat=0)
    const neutralSvg = `<svg xmlns="http://www.w3.org/2000/svg"><path fill="#333333" d="M 0 0 Z"/></svg>`;
    const r6 = lintMonochromeDeriv(neutralSvg);
    if (r6 !== true) {
      console.error("[lint] smoke: FAIL — #333333 (pure grey) should pass monochrome-derivable");
      allPassed = false;
    }

    // Fixture 7: malformed XML → should fail valid-parse
    const malformedSvg = `<svg xmlns="http://www.w3.org/2000/svg"><path d="M 0 0 L 10 0"</svg>`;
    const r7 = lintValidParse(malformedSvg);
    if (r7 !== false) {
      console.error("[lint] smoke: FAIL — malformed XML should have been rejected by valid-parse");
      allPassed = false;
    }

    // Gap-ratio test: gap=15/capHeight=700 → ratio=0.021 → should fail (below 0.08 floor)
    const gapTight = lintLockupGapRatio({ xMax: 100 }, { xMin: 115 }, 700);
    if (gapTight.pass !== false || gapTight.ratio > 0.022) {
      console.error(`[lint] smoke: FAIL — tight gap should fail (ratio=${gapTight.ratio})`);
      allPassed = false;
    }

    // Gap-ratio test: gap=100/capHeight=700 → ratio=0.143 → should pass (0.08–0.35 range)
    const gapOk = lintLockupGapRatio({ xMax: 100 }, { xMin: 200 }, 700);
    if (gapOk.pass !== true || gapOk.ratio < 0.14 || gapOk.ratio > 0.15) {
      console.error(`[lint] smoke: FAIL — ok gap should pass (ratio=${gapOk.ratio})`);
      allPassed = false;
    }

    if (allPassed) {
      console.log("[lint] smoke: OK");
      process.exit(0);
    } else {
      process.exit(1);
    }
  }

  // Normal mode: lint all candidates/ SVGs
  if (!fs.existsSync(CANDIDATES_DIR)) {
    console.log(`[lint] No candidates directory at ${CANDIDATES_DIR} — nothing to lint`);
    process.exit(0);
  }

  // Ensure output dirs exist
  if (!fs.existsSync(REJECTED_DIR)) {
    fs.mkdirSync(REJECTED_DIR, { recursive: true });
  }

  // Truncate lint log at start of run
  fs.writeFileSync(LINT_LOG, "");

  const svgFiles = fs.readdirSync(CANDIDATES_DIR).filter((f) => f.endsWith(".svg"));
  if (svgFiles.length === 0) {
    console.log("[lint] No SVG files found in candidates/ — nothing to lint");
    process.exit(0);
  }

  console.log(`[lint] Linting ${svgFiles.length} candidate(s)…`);

  let passed = 0;
  let failed = 0;

  for (const file of svgFiles) {
    const candidateId = path.basename(file, ".svg");
    const svgPath = path.join(CANDIDATES_DIR, file);
    const svgString = fs.readFileSync(svgPath, "utf8");

    // Derive Direction from ID prefix (D prefix = Direction D integrated typemark)
    const direction = candidateId.charAt(0).toUpperCase();
    const skipGapRatio = direction === "D";

    const candidate = {
      id: candidateId,
      direction,
      svgString,
      skipGapRatio,
    };

    const result = lintCandidate(candidate, { writeLog: true });

    if (result.pass) {
      passed++;
    } else {
      failed++;
      const reason = result.failures.join(", ");
      console.warn(`[lint] ${candidateId}: FAILED — ${reason}`);

      // Copy to rejected/ with reason sidecar
      fs.copyFileSync(svgPath, path.join(REJECTED_DIR, file));
      const reasonText = [
        `Candidate: ${candidateId}`,
        `Lint failures: ${result.failures.join(", ")}`,
        `Culled: ${new Date().toISOString()}`,
      ].join("\n");
      fs.writeFileSync(
        path.join(REJECTED_DIR, `${candidateId}.reason.txt`),
        reasonText + "\n"
      );
    }
  }

  console.log(`[lint] ${passed} passed / ${failed} failed`);

  if (failed > 0) {
    process.exit(1);
  }
}

// Named exports — importable by generate.mjs and other harness scripts
export { lintCandidate, lintValidParse, lintNoRectBackground, lintNoSubtitle, lintMonochromeDeriv, lintLockupGapRatio, lint16pxLegibility };

// Only run main() when executed directly (not when imported as a module).
// This guards against the CLI side-effect running on import by generate.mjs.
const isMain = process.argv[1] === fileURLToPath(import.meta.url);
if (isMain) {
  await main();
}
