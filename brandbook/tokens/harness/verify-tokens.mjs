/**
 * verify-tokens.mjs — SC#1 structural completeness assertion for tokens.css
 *
 * Asserts:
 *   - All 7 raw --accrue-* palette tokens with expected hexes
 *   - Semantic role groups (surface, content, feedback, interactive)
 *   - Dark block (:root[data-theme="dark"])
 *   - Brand-only code-block and callout tokens
 *
 * Usage:
 *   node brandbook/tokens/harness/verify-tokens.mjs
 *
 * Exits 0 if complete, non-zero (naming each missing token) otherwise.
 *
 * Environment:
 *   CSS_PATH_OVERRIDE  — path to an alternative tokens.css (used by tests for negative checks)
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const CSS_PATH = process.env.CSS_PATH_OVERRIDE
  ? path.resolve(process.env.CSS_PATH_OVERRIDE)
  : path.resolve(__dirname, "../tokens.css");

// ---------------------------------------------------------------------------
// Required CSS variables and their expected hex values (raw palette + key roles)
// ---------------------------------------------------------------------------

const REQUIRED_TOKENS = [
  // Raw palette (7 brand tokens)
  { cssVar: "--accrue-ink",    hex: "#111418" },
  { cssVar: "--accrue-slate",  hex: "#24303b" },
  { cssVar: "--accrue-fog",    hex: "#e9eef2" },
  { cssVar: "--accrue-paper",  hex: "#fafbfc" },
  { cssVar: "--accrue-moss",   hex: "#5e9e84" },
  { cssVar: "--accrue-cobalt", hex: "#5d79f6" },
  { cssVar: "--accrue-amber",  hex: "#c8923b" },

  // Surface group
  { cssVar: "--accrue-surface-base",     hex: "#fafbfc" },
  { cssVar: "--accrue-surface-elevated", hex: "#ffffff" },
  { cssVar: "--accrue-surface-sunken",   hex: "#f1f5f8" },

  // Content group
  { cssVar: "--accrue-content-primary", hex: "#111418" },
  { cssVar: "--accrue-content-muted",   hex: "#5d6a73" },
  { cssVar: "--accrue-content-subtle",  hex: "#24303b" },

  // Feedback group
  { cssVar: "--accrue-feedback-success", hex: "#5e9e84" },
  { cssVar: "--accrue-feedback-warning", hex: "#c8923b" },
  { cssVar: "--accrue-feedback-danger",  hex: "#d64b4b" },
  { cssVar: "--accrue-feedback-info",    hex: "#3878a6" },

  // Interactive group (brand-only)
  { cssVar: "--accrue-interactive-accent",    hex: "#5d79f6" },
  { cssVar: "--accrue-interactive-focus-ring", hex: "#5d79f6" },

  // Brand-only tokens (D-09b)
  { cssVar: "--accrue-code-block-surface", hex: "#e9eef2" },
  { cssVar: "--accrue-code-block-text",    hex: "#24303b" },
  { cssVar: "--accrue-callout-surface",    hex: "#f1f5f8" },
  { cssVar: "--accrue-callout-text",       hex: "#111418" },
];

// ---------------------------------------------------------------------------
// Structural assertions (non-token patterns)
// ---------------------------------------------------------------------------

const REQUIRED_PATTERNS = [
  {
    pattern: /:root\[data-theme="dark"\]/,
    label: "dark block (:root[data-theme=\"dark\"])",
  },
];

// ---------------------------------------------------------------------------
// Verification
// ---------------------------------------------------------------------------

function main() {
  if (!fs.existsSync(CSS_PATH)) {
    console.error(`[verify-tokens] FATAL: tokens.css not found at ${CSS_PATH}`);
    console.error("[verify-tokens] Run: node brandbook/tokens/harness/generate-tokens-css.mjs");
    process.exit(1);
  }

  const css = fs.readFileSync(CSS_PATH, "utf8");
  let failures = 0;

  // Check each required token
  for (const { cssVar, hex } of REQUIRED_TOKENS) {
    // Accept both "var: hex;" and "var: hex;" with trailing comment on same line
    const pattern = new RegExp(`${cssVar}:\\s*${hex}`, "i");
    if (!pattern.test(css)) {
      console.error(`[verify-tokens] MISSING: ${cssVar}: ${hex}`);
      failures++;
    }
  }

  // Check structural patterns
  for (const { pattern, label } of REQUIRED_PATTERNS) {
    if (!pattern.test(css)) {
      console.error(`[verify-tokens] MISSING pattern: ${label}`);
      failures++;
    }
  }

  if (failures > 0) {
    console.error(`\n[verify-tokens] FAIL — ${failures} token(s)/pattern(s) missing`);
    process.exit(1);
  }

  console.log(`[verify-tokens] OK — ${REQUIRED_TOKENS.length} tokens + ${REQUIRED_PATTERNS.length} structural patterns verified`);
  process.exit(0);
}

// isMain guard — mirrors geist-spine-mono.mjs pattern
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main();
}
