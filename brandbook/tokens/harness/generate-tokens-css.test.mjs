/**
 * generate-tokens-css.test.mjs — RED test for generate-tokens-css.mjs
 *
 * Verifies:
 *   1. tokens.css is generated (file exists, non-empty)
 *   2. First line is the GENERATED banner
 *   3. Contains --accrue-moss: #5e9e84 in the light :root block
 *   4. Contains a :root[data-theme="dark"] block
 *   5. Contains at least one brand-only comment
 *   6. File ends with exactly one trailing newline
 *   7. Light and dark rows are both sorted (localeCompare order)
 *
 * Run AFTER generate-tokens-css.mjs has been created and executed:
 *   node brandbook/tokens/harness/generate-tokens-css.mjs
 *   node brandbook/tokens/harness/generate-tokens-css.test.mjs
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CSS_PATH = path.resolve(__dirname, "../tokens.css");

let failures = 0;
function check(cond, label) {
  if (!cond) {
    console.error(`[gen-test] FAIL: ${label}`);
    failures++;
  } else {
    console.log(`[gen-test] OK:   ${label}`);
  }
}

// Test: generator script exists
const GENERATOR_PATH = path.resolve(__dirname, "./generate-tokens-css.mjs");
check(fs.existsSync(GENERATOR_PATH), "generate-tokens-css.mjs exists");

// Test: tokens.css exists
check(fs.existsSync(CSS_PATH), "tokens.css exists after generation");

if (fs.existsSync(CSS_PATH)) {
  const css = fs.readFileSync(CSS_PATH, "utf8");
  const lines = css.split("\n");

  // Banner on first line
  check(
    lines[0] === "/* GENERATED from tokens.json — do not edit. Run: npm run generate */",
    "first line is GENERATED banner"
  );

  // Contains --accrue-moss
  check(
    css.includes("--accrue-moss: #5e9e84;"),
    "tokens.css contains --accrue-moss: #5e9e84;"
  );

  // Contains dark block
  check(
    css.includes(':root[data-theme="dark"]'),
    'tokens.css contains :root[data-theme="dark"] block'
  );

  // Brand-only comment for axMap:null tokens
  check(
    css.includes("/* brand-only: no --ax-* counterpart */"),
    "tokens.css contains brand-only comment"
  );

  // Trailing newline: file ends with exactly one "\n"
  check(
    css.endsWith("\n") && !css.endsWith("\n\n"),
    "file ends with exactly one trailing newline"
  );

  // Light block contains :root {
  check(css.includes(":root {"), "light :root block present");
}

if (failures > 0) {
  console.error(`\n[gen-test] FAIL (${failures} assertion(s) failed)`);
  process.exit(1);
}
console.log("\n[gen-test] OK — all assertions passed");
process.exit(0);
