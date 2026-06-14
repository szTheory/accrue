/**
 * generate-tokens-css.mjs — Deterministic CSS custom property emitter
 *
 * Reads brandbook/tokens/tokens.json (DTCG SSOT) and writes tokens.css.
 * Imports shared helpers from ./lib.mjs (flattenTokens / deriveCssVar).
 *
 * Usage:
 *   node brandbook/tokens/harness/generate-tokens-css.mjs
 *
 * Output: brandbook/tokens/tokens.css
 *   - GENERATED banner (first line)
 *   - :root { light tokens } sorted by cssVar (localeCompare)
 *   - :root[data-theme="dark"] { dark tokens } sorted the same way
 *   - /* brand-only: no --ax-* counterpart *\/ comment for axMap:null tokens (D-09b)
 *   - Exactly one trailing newline; LF line endings (D-17 determinism)
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { flattenTokens } from "./lib.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const TOKENS_PATH = path.resolve(__dirname, "../tokens.json");
const OUTPUT_PATH = path.resolve(__dirname, "../tokens.css");

const BANNER = "/* GENERATED from tokens.json — do not edit. Run: npm run generate */";
const BRAND_ONLY = "/* brand-only: no --ax-* counterpart */";

function buildBlock(rows) {
  return rows
    .slice()
    .sort((a, b) => a.cssVar.localeCompare(b.cssVar, "en", { sensitivity: "variant" }))
    .map(r => {
      const note = r.axMap === null ? `  ${BRAND_ONLY}\n` : "";
      return `${note}  ${r.cssVar}: ${r.hex};`;
    })
    .join("\n");
}

function generate() {
  const json = JSON.parse(fs.readFileSync(TOKENS_PATH, "utf8"));
  const all = flattenTokens(json);

  const light = all.filter(r => r.scope === "light");
  const dark  = all.filter(r => r.scope === "dark");

  const lightBlock = buildBlock(light);
  const darkBlock  = buildBlock(dark);

  const css = [
    BANNER,
    ":root {",
    lightBlock,
    "}",
    "",
    `:root[data-theme="dark"] {`,
    darkBlock,
    "}",
    "", // trailing newline sentinel (join adds \n between items, this gives final \n)
  ].join("\n");

  fs.writeFileSync(OUTPUT_PATH, css, "utf8");
  console.log(`[generate-tokens-css] wrote ${OUTPUT_PATH}`);
}

generate();
