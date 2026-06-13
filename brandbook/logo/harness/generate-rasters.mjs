/**
 * generate-rasters.mjs — Deterministic resvg-based raster generator
 *
 * Produces all committed PNG + .ico artifacts for the Accrue brand system.
 * Uses @resvg/resvg-js for byte-stable, Playwright-free rendering (D-08).
 * Render-at-size: each target is a fresh Resvg render at its exact pixel
 * width — never downscale from a large raster (D-09).
 *
 * Artifacts produced in brandbook/logo/:
 *   favicon-16.png     — 16×16, transparent bg
 *   favicon-32.png     — 32×32, transparent bg
 *   favicon-48.png     — 48×48, transparent bg
 *   favicon.ico        — multi-resolution ICO (16/32/48 packed)
 *   apple-touch-icon.png — 180×180, OPAQUE #FAFBFC bg + safe padding
 *   icon-192.png       — 192×192, transparent bg
 *   icon-512.png       — 512×512, transparent bg
 *   accrue-social-card.png — 1200×630, OPAQUE
 */

import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";
import { Resvg } from "@resvg/resvg-js";
import { PNG } from "pngjs";
import { packIco } from "./ico-packer.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = path.resolve(__dirname, "..");  // brandbook/logo/

// ---------------------------------------------------------------------------
// Render helpers
// ---------------------------------------------------------------------------

/**
 * Render an SVG string to a PNG Buffer at the given target width.
 * Height is determined by the viewBox aspect ratio.
 * @param {string} svgString
 * @param {number} targetWidth
 * @returns {Buffer}
 */
function renderSvgToPng(svgString, targetWidth) {
  const resvg = new Resvg(svgString, {
    fitTo: { mode: "width", value: targetWidth },
  });
  const pngData = resvg.render();
  return pngData.asPng();
}

/**
 * Assert PNG buffer dimensions match expectations.
 * Throws on mismatch.
 * @param {Buffer} buf
 * @param {number} expectedW
 * @param {number} expectedH
 * @param {string} label
 */
function assertDimensions(buf, expectedW, expectedH, label) {
  const png = PNG.sync.read(buf);
  if (png.width !== expectedW || png.height !== expectedH) {
    throw new Error(
      `[generate-rasters] Dimension mismatch for ${label}: ` +
      `expected ${expectedW}×${expectedH}, got ${png.width}×${png.height}`
    );
  }
}

/**
 * Blank-render guard: throw if fewer than 0.5% of pixels are "dark"
 * (color-distance > 30 from Paper bg #FAFBFC).
 * A blank render means SVG ink is outside the viewBox.
 * @param {Buffer} buf
 * @param {string} label
 */
function assertNotBlank(buf, label) {
  const png = PNG.sync.read(buf);
  const { data, width, height } = png;
  const BG_R = 250, BG_G = 251, BG_B = 252;
  const COLOR_DIST_THRESHOLD = 30;
  let inkCount = 0;
  for (let i = 0; i < data.length; i += 4) {
    const a = data[i + 3];
    if (a < 64) continue; // skip near-transparent pixels
    const dr = data[i] - BG_R;
    const dg = data[i + 1] - BG_G;
    const db = data[i + 2] - BG_B;
    if (Math.sqrt(dr * dr + dg * dg + db * db) > COLOR_DIST_THRESHOLD) {
      inkCount++;
    }
  }
  const coverage = inkCount / (width * height);
  if (coverage < 0.005) {
    throw new Error(
      `[generate-rasters] BLANK-RENDER: ${label} dark coverage=${(coverage * 100).toFixed(3)}% ` +
      `— SVG ink outside viewBox or rendered as blank`
    );
  }
}

/**
 * Check that apple-touch-icon has no transparent corners.
 * iOS clips transparency, showing black corners if alpha is present.
 * Samples the four corner pixels (2×2 region each).
 * @param {Buffer} buf
 */
function assertOpaqueBg(buf) {
  const png = PNG.sync.read(buf);
  const { data, width } = png;
  // Check the four corners: (0,0), (w-1,0), (0,h-1), (w-1,h-1)
  const corners = [
    0,
    (width - 1) * 4,
    (png.height - 1) * width * 4,
    (png.height - 1) * width * 4 + (width - 1) * 4,
  ];
  for (const offset of corners) {
    const alpha = data[offset + 3];
    if (alpha < 250) {
      throw new Error(
        `[generate-rasters] apple-touch-icon has transparent corner at offset ${offset} ` +
        `(alpha=${alpha}) — iOS will show black corners`
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Apple-touch-icon composition
// ---------------------------------------------------------------------------

/**
 * Compose the mark SVG on an opaque #FAFBFC background with 16px safe padding.
 * The mark viewBox is "0 0 40 40". We inline it into a 180×180 wrapper SVG
 * so Resvg renders the composition in a single pass.
 *
 * Available canvas: 180 - 2*16 = 148 units for the mark.
 * scale = 148/40 = 3.7
 *
 * @param {string} markSvgString - The full mark SVG source
 * @returns {string} - The composed wrapper SVG string
 */
function composeAppleTouchIconSvg(markSvgString) {
  // Extract the inner path elements from the mark SVG (everything between first > and </svg>)
  // We strip the outer <svg ...> wrapper and inject paths into our own wrapper.
  const pathsMatch = markSvgString.match(/<svg[^>]*>([\s\S]*)<\/svg>/);
  if (!pathsMatch) {
    throw new Error("[generate-rasters] Cannot extract paths from mark SVG");
  }
  const innerPaths = pathsMatch[1];

  // Compute scale: 148px available (180 - 2*16 padding), mark viewBox is 40×40
  const markSize = 40;
  const canvasSize = 180;
  const padding = 16;
  const available = canvasSize - 2 * padding;
  const scale = available / markSize;  // 148/40 = 3.7

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${canvasSize} ${canvasSize}">`,
    `  <title>Accrue logomark</title>`,
    `  <rect width="${canvasSize}" height="${canvasSize}" fill="#FAFBFC"/>`,
    `  <g transform="translate(${padding},${padding}) scale(${scale})">`,
    innerPaths,
    `  </g>`,
    `</svg>`,
  ].join("\n");
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const isVerify = process.argv.includes("--verify");

  // Read source SVGs
  const markSvgPath = path.join(OUTPUT_DIR, "accrue-mark.svg");
  const socialCardSvgPath = path.join(OUTPUT_DIR, "accrue-social-card.svg");

  if (!fs.existsSync(markSvgPath)) {
    throw new Error(`[generate-rasters] Missing source: ${markSvgPath}`);
  }
  if (!fs.existsSync(socialCardSvgPath)) {
    throw new Error(`[generate-rasters] Missing source: ${socialCardSvgPath}`);
  }

  const markSvgString = fs.readFileSync(markSvgPath, "utf8");
  const socialCardSvgString = fs.readFileSync(socialCardSvgPath, "utf8");

  // Verify source viewBoxes
  if (!markSvgString.includes('viewBox="0 0 40 40"')) {
    throw new Error(`[generate-rasters] accrue-mark.svg does not have expected viewBox "0 0 40 40"`);
  }
  if (!socialCardSvgString.includes('viewBox="0 0 1200 630"')) {
    throw new Error(`[generate-rasters] accrue-social-card.svg does not have expected viewBox "0 0 1200 630"`);
  }

  console.log("[generate-rasters] Rendering PNG artifacts...");

  // --- Favicon variants (transparent bg, render-at-size) ---
  const buf16 = renderSvgToPng(markSvgString, 16);
  assertDimensions(buf16, 16, 16, "favicon-16.png");

  const buf32 = renderSvgToPng(markSvgString, 32);
  assertDimensions(buf32, 32, 32, "favicon-32.png");

  const buf48 = renderSvgToPng(markSvgString, 48);
  assertDimensions(buf48, 48, 48, "favicon-48.png");

  // --- Blank-render guard on favicon-32.png (representative square raster) ---
  assertNotBlank(buf32, "favicon-32.png");

  // --- Icon variants (transparent bg) ---
  const buf192 = renderSvgToPng(markSvgString, 192);
  assertDimensions(buf192, 192, 192, "icon-192.png");

  const buf512 = renderSvgToPng(markSvgString, 512);
  assertDimensions(buf512, 512, 512, "icon-512.png");

  // --- Apple-touch-icon (opaque bg, composed) ---
  const appleTouchSvg = composeAppleTouchIconSvg(markSvgString);
  const bufApple = renderSvgToPng(appleTouchSvg, 180);
  assertDimensions(bufApple, 180, 180, "apple-touch-icon.png");
  assertOpaqueBg(bufApple);
  assertNotBlank(bufApple, "apple-touch-icon.png");

  // --- Social card (opaque bg — social card SVG already has opaque rect) ---
  const bufSocial = renderSvgToPng(socialCardSvgString, 1200);
  assertDimensions(bufSocial, 1200, 630, "accrue-social-card.png");
  assertNotBlank(bufSocial, "accrue-social-card.png");

  // --- Pack favicon.ico ---
  const icoBuffer = packIco([buf16, buf32, buf48], [16, 32, 48]);

  // Verify ICO header
  if (icoBuffer.readUInt16LE(0) !== 0 || icoBuffer.readUInt16LE(2) !== 1 || icoBuffer.readUInt16LE(4) !== 3) {
    throw new Error("[generate-rasters] favicon.ico header invalid after packing");
  }

  // --- Write all artifacts ---
  if (!isVerify) {
    fs.writeFileSync(path.join(OUTPUT_DIR, "favicon-16.png"), buf16);
    fs.writeFileSync(path.join(OUTPUT_DIR, "favicon-32.png"), buf32);
    fs.writeFileSync(path.join(OUTPUT_DIR, "favicon-48.png"), buf48);
    fs.writeFileSync(path.join(OUTPUT_DIR, "favicon.ico"), icoBuffer);
    fs.writeFileSync(path.join(OUTPUT_DIR, "apple-touch-icon.png"), bufApple);
    fs.writeFileSync(path.join(OUTPUT_DIR, "icon-192.png"), buf192);
    fs.writeFileSync(path.join(OUTPUT_DIR, "icon-512.png"), buf512);
    fs.writeFileSync(path.join(OUTPUT_DIR, "accrue-social-card.png"), bufSocial);
  } else {
    // --verify mode: read back written files and compare dimensions
    console.log("[generate-rasters] --verify mode: checking existing artifacts...");
    const checks = [
      ["favicon-16.png", 16, 16],
      ["favicon-32.png", 32, 32],
      ["favicon-48.png", 48, 48],
      ["apple-touch-icon.png", 180, 180],
      ["icon-192.png", 192, 192],
      ["icon-512.png", 512, 512],
      ["accrue-social-card.png", 1200, 630],
    ];
    for (const [name, w, h] of checks) {
      const filePath = path.join(OUTPUT_DIR, name);
      if (!fs.existsSync(filePath)) {
        throw new Error(`[generate-rasters] --verify: missing artifact: ${filePath}`);
      }
      const fileBuf = fs.readFileSync(filePath);
      assertDimensions(fileBuf, w, h, name);
      console.log(`  [ok] ${name} — ${w}×${h}`);
    }
    // Verify favicon.ico header
    const icoPath = path.join(OUTPUT_DIR, "favicon.ico");
    if (!fs.existsSync(icoPath)) {
      throw new Error(`[generate-rasters] --verify: missing artifact: ${icoPath}`);
    }
    const icoFile = fs.readFileSync(icoPath);
    if (icoFile.readUInt16LE(0) !== 0 || icoFile.readUInt16LE(2) !== 1 || icoFile.readUInt16LE(4) !== 3) {
      throw new Error("[generate-rasters] --verify: favicon.ico header invalid");
    }
    console.log("  [ok] favicon.ico — 3 entries (16/32/48)");
  }

  // --- Determinism check: re-render favicon-16.png and compare byte-for-byte ---
  {
    const second = renderSvgToPng(markSvgString, 16);
    const first = isVerify
      ? fs.readFileSync(path.join(OUTPUT_DIR, "favicon-16.png"))
      : buf16;
    if (!first.equals(second)) {
      throw new Error(
        "[generate-rasters] DETERMINISM FAIL: favicon-16.png is not byte-identical on re-render"
      );
    }
    console.log("[generate-rasters] Determinism check: PASS (favicon-16.png byte-identical on re-render)");
  }

  // --- Completion summary ---
  if (!isVerify) {
    const artifacts = [
      "favicon-16.png",
      "favicon-32.png",
      "favicon-48.png",
      "favicon.ico",
      "apple-touch-icon.png",
      "icon-192.png",
      "icon-512.png",
      "accrue-social-card.png",
    ];
    console.log("[generate-rasters] Rasters written:");
    for (const name of artifacts) {
      const fp = path.join(OUTPUT_DIR, name);
      const size = fs.statSync(fp).size;
      console.log(`  ${name} — ${size} bytes`);
    }
    console.log("[generate-rasters] All done.");
  } else {
    console.log("[generate-rasters] --verify: all checks PASSED");
  }
}

// ---------------------------------------------------------------------------
// isMain guard
// ---------------------------------------------------------------------------
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error("[generate-rasters] FATAL:", err.message);
    process.exit(1);
  });
}
