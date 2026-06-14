/**
 * verify-specimens.mjs — SC#3 content-coverage assertion for Accrue specimen SVGs.
 *
 * Verifies that the three generated specimen SVGs cover their locked D-15 checklists:
 *
 *   palette.svg:
 *     - Every raw --accrue-* token name appears in the SVG
 *     - Light surface band (Paper #fafbfc background) present
 *     - Dark surface band (Ink #0f1318 background) present
 *     - Moss/Cobalt/Amber AA-FAIL flag on light present (sourced from contrast-table.txt)
 *
 *   typography.svg:
 *     - Each --ax-type-<step> label present (xs through 3xl)
 *     - Geist font-family referenced
 *     - Geist Mono font-family referenced
 *
 *   spacing.svg:
 *     - Each --ax-space-<step> label present (2xs through 3xl)
 *
 * Exits 0 when all content present; exits 1 naming the first missing item.
 *
 * Usage:
 *   node brandbook/tokens/harness/verify-specimens.mjs
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { flattenTokens } from "./lib.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const TOKENS_PATH = path.resolve(__dirname, "../tokens.json");
const EXAMPLES_DIR = path.resolve(__dirname, "../../examples");

// Reference scale step names (from theme.css --ax-type-* / --ax-space-*)
const TYPE_STEPS = ["xs", "sm", "md", "lg", "xl", "2xl", "3xl"];
const SPACE_STEPS = ["2xs", "xs", "sm", "md", "lg", "xl", "2xl", "3xl"];

// ---------------------------------------------------------------------------
// AA-FAIL strings sourced from contrast-table.txt
// These MUST appear in palette.svg on the light band.
// contrast-table.txt: Paper vs Moss 3.03:1 [AA-large], Paper vs Cobalt 3.66:1 [AA-large],
//                     Paper vs Amber 2.66:1 [FAIL]
// ---------------------------------------------------------------------------
const REQUIRED_AA_FAIL_STRINGS = [
  "FAIL AA-body on light",   // covers both Moss (3.03:1) and Cobalt (3.66:1)
  "FAIL AA on light",        // covers Amber (2.66:1 FAIL)
];

// ---------------------------------------------------------------------------
// Assertion runner
// ---------------------------------------------------------------------------

let failures = 0;

function assert(condition, label) {
  if (!condition) {
    console.error(`[verify-specimens] MISSING: ${label}`);
    failures++;
  }
}

function assertContains(content, needle, label) {
  assert(content.includes(needle), label);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  // Load tokens to enumerate expected --accrue-* raw token names
  const tokens = JSON.parse(fs.readFileSync(TOKENS_PATH, "utf8"));
  const rows = flattenTokens(tokens);

  // Filter raw brand tokens only (color.brand.* → --accrue-<leaf>)
  const rawTokenVars = rows
    .filter(r => r.name.startsWith("color.brand."))
    .map(r => r.cssVar)
    .sort();

  // Read specimen SVGs
  const palettePath = path.join(EXAMPLES_DIR, "palette.svg");
  const typographyPath = path.join(EXAMPLES_DIR, "typography.svg");
  const spacingPath = path.join(EXAMPLES_DIR, "spacing.svg");

  // Assert files exist
  assert(fs.existsSync(palettePath), "brandbook/examples/palette.svg exists");
  assert(fs.existsSync(typographyPath), "brandbook/examples/typography.svg exists");
  assert(fs.existsSync(spacingPath), "brandbook/examples/spacing.svg exists");

  if (failures > 0) {
    console.error(`\n[verify-specimens] FAIL: ${failures} assertion(s) failed — SVG files missing`);
    process.exit(1);
  }

  const paletteSvg = fs.readFileSync(palettePath, "utf8");
  const typographySvg = fs.readFileSync(typographyPath, "utf8");
  const spacingSvg = fs.readFileSync(spacingPath, "utf8");

  // ---------------------------------------------------------------------------
  // palette.svg assertions
  // ---------------------------------------------------------------------------

  // 1. Each raw --accrue-* brand token name appears
  for (const cssVar of rawTokenVars) {
    assertContains(paletteSvg, cssVar, `palette.svg contains raw token: ${cssVar}`);
  }

  // 2. Light surface band (Paper #fafbfc) present
  assertContains(paletteSvg, "Light surface", "palette.svg has light surface band label");
  assertContains(paletteSvg, "#fafbfc", "palette.svg contains Paper #fafbfc (light surface background)");

  // 3. Dark surface band (Ink #0f1318) present
  assertContains(paletteSvg, "Dark surface", "palette.svg has dark surface band label");
  assertContains(paletteSvg, "#0f1318", "palette.svg contains Ink #0f1318 (dark surface background)");

  // 4. Moss/Cobalt/Amber AA-FAIL flag on light (sourced from contrast-table.txt)
  for (const needle of REQUIRED_AA_FAIL_STRINGS) {
    assertContains(paletteSvg, needle, `palette.svg contains AA-FAIL flag: "${needle}"`);
  }

  // 5. <title> and <desc> present
  assertContains(paletteSvg, "<title>", "palette.svg has <title>");
  assertContains(paletteSvg, "<desc>", "palette.svg has <desc>");

  // ---------------------------------------------------------------------------
  // typography.svg assertions
  // ---------------------------------------------------------------------------

  // 1. Each type step label
  for (const step of TYPE_STEPS) {
    assertContains(typographySvg, `--ax-type-${step}`, `typography.svg contains --ax-type-${step}`);
  }

  // 2. Geist font-family referenced
  assertContains(typographySvg, "Geist,", "typography.svg references Geist font-family (Geist,)");

  // 3. Geist Mono font-family referenced
  assertContains(typographySvg, "Geist Mono", "typography.svg references Geist Mono font-family");

  // 4. px and rem labels
  assertContains(typographySvg, "px", "typography.svg has px labels");
  assertContains(typographySvg, "rem", "typography.svg has rem labels");

  // 5. <title> and <desc> present
  assertContains(typographySvg, "<title>", "typography.svg has <title>");
  assertContains(typographySvg, "<desc>", "typography.svg has <desc>");

  // ---------------------------------------------------------------------------
  // spacing.svg assertions
  // ---------------------------------------------------------------------------

  // 1. Each spacing step label
  for (const step of SPACE_STEPS) {
    assertContains(spacingSvg, `--ax-space-${step}`, `spacing.svg contains --ax-space-${step}`);
  }

  // 2. px and rem labels
  assertContains(spacingSvg, "px", "spacing.svg has px labels");
  assertContains(spacingSvg, "rem", "spacing.svg has rem labels");

  // 3. <title> and <desc> present
  assertContains(spacingSvg, "<title>", "spacing.svg has <title>");
  assertContains(spacingSvg, "<desc>", "spacing.svg has <desc>");

  // ---------------------------------------------------------------------------
  // Result
  // ---------------------------------------------------------------------------

  if (failures > 0) {
    console.error(`\n[verify-specimens] FAIL: ${failures} assertion(s) failed`);
    process.exit(1);
  }

  console.log(`[verify-specimens] OK: all ${rawTokenVars.length} raw tokens present in palette.svg`);
  console.log(`[verify-specimens] OK: light + dark surface bands + AA-FAIL flags present in palette.svg`);
  console.log(`[verify-specimens] OK: all ${TYPE_STEPS.length} type steps present in typography.svg (Geist + Geist Mono)`);
  console.log(`[verify-specimens] OK: all ${SPACE_STEPS.length} spacing steps present in spacing.svg`);
  console.log("[verify-specimens] VERIFY_SPECIMENS_OK — SC#3 content coverage passed");
  process.exit(0);
}

// isMain guard — prevents execution when imported as a module
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main();
}
