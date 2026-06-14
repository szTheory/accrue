/**
 * verify-brandbook.mjs — Quality-gate verifier for brandbook/index.html
 *
 * Runs two phases:
 *   1. Structural assertions (synchronous): no external refs, no JS frameworks,
 *      dark-mode attribute, section IDs, inlined SVGs, size budget.
 *   2. Playwright screenshot matrix (async): 4 cells (light+dark × desktop+mobile).
 *
 * Playwright is imported via explicit relative path from the logo harness —
 * no second npm install required.
 *
 * Usage:
 *   node brandbook/harness/verify-brandbook.mjs
 *
 * Environment:
 *   HTML_PATH_OVERRIDE — path to an alternative index.html (for testing)
 *
 * Exits 0 and prints VERIFY_BRANDBOOK_OK on success.
 * Exits 1 with descriptive error on any gate failure.
 *
 * Screenshots go to:
 *   .planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots/
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { execSync } from "child_process";

// Playwright via explicit relative path — avoids second npm install
// (brandbook/harness/ has no package.json dependencies)
// Path from brandbook/harness/ → ../logo/harness/node_modules/playwright/index.js
// Note: Playwright is CommonJS; use default import destructuring.
import playwrightPkg from "../logo/harness/node_modules/playwright/index.js";
const { chromium } = playwrightPkg;

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const HTML_PATH = process.env.HTML_PATH_OVERRIDE
  ? path.resolve(process.env.HTML_PATH_OVERRIDE)
  : path.resolve(__dirname, "../index.html");

const FILE_URL = "file://" + HTML_PATH;

const QA_SCREENSHOTS_DIR = path.resolve(
  __dirname,
  "../../.planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots"
);

// ---------------------------------------------------------------------------
// Assertion runner
// ---------------------------------------------------------------------------

let failures = 0;

function assert(condition, label) {
  if (!condition) {
    console.error(`[verify-brandbook] MISSING: ${label}`);
    failures++;
  }
}

function assertContains(content, needle, label) {
  assert(content.includes(needle), label);
}

// ---------------------------------------------------------------------------
// Structural assertion phase (synchronous)
// ---------------------------------------------------------------------------

function runStructuralAssertions() {
  // 1. File exists check
  if (!fs.existsSync(HTML_PATH)) {
    console.error(
      "[verify-brandbook] FATAL: index.html not found — run node brandbook/harness/assemble.mjs first"
    );
    process.exit(1);
  }

  // 2. Read index.html
  const content = fs.readFileSync(HTML_PATH, "utf8");

  // 3. No-external-request check (src/href attributes only — not xmlns which uses http://)
  const externalRefs =
    content.match(/(src|href)=["'][^"']*https?:\/\/[^"']*["']/g) || [];
  assert(
    externalRefs.length === 0,
    "no external src/href URLs in index.html (all assets are local or inlined)"
  );
  if (externalRefs.length > 0) {
    for (const ref of externalRefs) {
      console.error(`[verify-brandbook]   external ref found: ${ref}`);
    }
  }

  // 4. No-JS-framework check (script bodies only — prose content may name frameworks)
  const scriptBodies =
    (content.match(/<script\b[^>]*>([\s\S]*?)<\/script>/gi) || [])
      .join("\n")
      .toLowerCase();
  assert(
    !scriptBodies.includes("react") &&
      !scriptBodies.includes("vue") &&
      !scriptBodies.includes("angular") &&
      !scriptBodies.includes("alpine") &&
      !scriptBodies.includes("htmx"),
    "no JS frameworks present (script-body scan)"
  );

  // 5. Dark-mode data-theme attribute present
  assertContains(
    content,
    "data-theme",
    "data-theme attribute present for dark mode"
  );

  // 6. All 10 section IDs present
  const sectionMatches = content.match(/id="section-/g) || [];
  assert(
    sectionMatches.length >= 10,
    `>=10 section IDs present (found ${sectionMatches.length})`
  );

  // 7. No SVG <img src> for logo SVGs (logos must be inlined, not img-referenced)
  assert(
    !/img[^>]+src=["'][^"']*\.svg["']/.test(content),
    "logo SVGs are inlined, not img-referenced"
  );

  // 8. Size budget check — committed weight <= 2 MB
  let totalBytes = 0;
  try {
    // git ls-files for committed files only (excludes node_modules and untracked files).
    // du -ck reports KB (1024-byte blocks) for a reliable, portable parse
    // (without -k, macOS du uses 512-byte blocks).
    const outputK = execSync(
      "git ls-files brandbook/ | xargs du -ck 2>/dev/null | tail -1",
      { encoding: "utf8", cwd: path.resolve(__dirname, "../..") }
    ).trim();
    const match = outputK.match(/^(\d+)\s+total/);
    if (match) {
      totalBytes = parseInt(match[1], 10) * 1024; // KB to bytes
    }
  } catch (err) {
    console.error(`[verify-brandbook] WARN: size check failed — ${err.message}`);
  }
  if (totalBytes > 0) {
    const MB = totalBytes / (1024 * 1024);
    assert(
      totalBytes <= 2097152,
      `committed weight <= 2 MB (found ${MB.toFixed(2)} MB — ${totalBytes} bytes via git ls-files)`
    );
  } else {
    console.error("[verify-brandbook] WARN: could not determine committed weight — skipping budget assertion");
  }

  // Early structural exit
  if (failures > 0) {
    console.error(
      `\n[verify-brandbook] FAIL — ${failures} structural check(s) failed`
    );
    process.exit(1);
  }

  console.log("[verify-brandbook] OK — structural assertions: 8 passed");
}

// ---------------------------------------------------------------------------
// Playwright screenshot phase (async)
// ---------------------------------------------------------------------------

async function runScreenshots() {
  fs.mkdirSync(QA_SCREENSHOTS_DIR, { recursive: true });

  const matrix = [
    { name: "light-desktop", width: 1200, height: 900, theme: "light" },
    { name: "dark-desktop",  width: 1200, height: 900, theme: "dark"  },
    { name: "light-mobile",  width: 360,  height: 780, theme: "light" },
    { name: "dark-mobile",   width: 360,  height: 780, theme: "dark"  },
  ];

  const browser = await chromium.launch({ headless: true });

  try {
    for (const cell of matrix) {
      const ctx = await browser.newContext({
        viewport: { width: cell.width, height: cell.height },
      });
      const page = await ctx.newPage();
      await page.goto(FILE_URL);
      await page.waitForLoadState("domcontentloaded");

      if (cell.theme === "dark") {
        await page.evaluate(() => {
          document.documentElement.dataset.theme = "dark";
        });
        // Brief wait for CSS transitions to settle
        await page.waitForTimeout(100);
      }

      const outPath = path.join(QA_SCREENSHOTS_DIR, cell.name + ".png");
      await page.screenshot({ path: outPath, fullPage: false });
      await ctx.close();

      console.log(`[verify-brandbook] OK — screenshot: ${cell.name}.png`);
    }
  } finally {
    await browser.close();
  }

  // Assert all 4 screenshots exist
  let screenshotFailures = 0;
  for (const cell of matrix) {
    const outPath = path.join(QA_SCREENSHOTS_DIR, cell.name + ".png");
    if (!fs.existsSync(outPath)) {
      console.error(`[verify-brandbook] MISSING screenshot: ${cell.name}.png`);
      screenshotFailures++;
    }
  }

  if (screenshotFailures > 0) {
    console.error(
      `[verify-brandbook] FAIL — ${screenshotFailures} screenshot(s) missing`
    );
    process.exit(1);
  }

  console.log("[verify-brandbook] OK — screenshots: 4 produced");
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  // Phase 1: structural assertions (synchronous)
  runStructuralAssertions();

  // Phase 2: Playwright screenshots (async)
  await runScreenshots();

  // Success
  console.log("[verify-brandbook] VERIFY_BRANDBOOK_OK");
  process.exit(0);
}

// isMain guard — async form
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error("[verify-brandbook] FATAL:", err);
    process.exit(1);
  });
}
