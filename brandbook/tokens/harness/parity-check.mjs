/**
 * parity-check.mjs — Brand ↔ Admin token parity gate.
 *
 * Reads accrue_admin/assets/css/theme.css (READ-ONLY, never written),
 * resolves each ax-mapped brand token to canonical lowercase #rrggbb in
 * BOTH light and dark scopes, and compares against tokens.json.
 *
 * Exit contract (D-08): process.exit(0) when all ax-mapped tokens match
 * (or carry a documented $extensions divergence), non-zero on any undocumented drift.
 *
 * Usage:
 *   node brandbook/tokens/harness/parity-check.mjs          # live parity gate
 *   node brandbook/tokens/harness/parity-check.mjs --test   # SC#2 fixture mode (both directions)
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import postcss from "postcss";
import { resolveColor, iterAxMappedTokens, flattenTokens } from "./lib.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const THEME_PATH = path.resolve(__dirname, "../../../accrue_admin/assets/css/theme.css");
const TOKENS_PATH = path.resolve(__dirname, "../tokens.json");

// ---------------------------------------------------------------------------
// Scope selectors (RESEARCH Pitfall 3 — tokens are scoped to html.accrue-admin)
// ---------------------------------------------------------------------------

const LIGHT_SELECTOR = "html.accrue-admin";
const DARK_SELECTOR = 'html.accrue-admin[data-theme="dark"]';

// ---------------------------------------------------------------------------
// buildScopes: parse theme.css into a per-selector custom-property map
// ---------------------------------------------------------------------------

/**
 * Parse CSS text into a map of { [selector]: { [propName]: rawValue } }.
 * Only captures --* custom properties.
 *
 * @param {string} css - Raw CSS text
 * @returns {Record<string, Record<string, string>>}
 */
function buildScopes(css) {
  const root = postcss.parse(css);
  const scopes = {};
  root.walkRules(rule => {
    const map = (scopes[rule.selector] ??= {});
    rule.walkDecls(/^--/, d => {
      map[d.prop] = d.value;
    });
  });
  return scopes;
}

// ---------------------------------------------------------------------------
// buildBrandRaw: build the --accrue-* → hex map from tokens.json raw palette
// (theme.css does NOT define raw --accrue-* tokens — only references them via var())
// ---------------------------------------------------------------------------

/**
 * Build a map of "--accrue-<name>" → lowercase hex for every raw brand token
 * (color.brand.*) in the tokens JSON. This is the fallback used when resolveColor
 * encounters var(--accrue-*) inside the admin scope maps.
 *
 * @param {object} tokens - Full DTCG tokens JSON
 * @returns {Record<string, string>}
 */
function buildBrandRaw(tokens) {
  const rows = flattenTokens(tokens);
  const map = {};
  for (const row of rows) {
    // Include all rows — both raw brand tokens and semantic roles may appear as var() targets.
    // The cssVar is already in "--accrue-*" form.
    map[row.cssVar] = row.hex;
  }
  return map;
}

// ---------------------------------------------------------------------------
// runParity: core comparison engine (callable from live mode + --test mode)
// ---------------------------------------------------------------------------

/**
 * Run the parity check given raw CSS text and a tokens JSON object.
 * Returns the failure count so --test can drive it with fixture inputs.
 *
 * @param {{ themeCss: string, tokens: object, verbose?: boolean }} opts
 * @returns {number} failure count (0 = all matched or documented)
 */
export function runParity({ themeCss, tokens, verbose = true }) {
  const scopes = buildScopes(themeCss);
  const lightScope = scopes[LIGHT_SELECTOR] ?? {};
  const darkScope = scopes[DARK_SELECTOR] ?? {};
  const brandRaw = buildBrandRaw(tokens);

  let failures = 0;

  for (const { axMap, brandHex, divergesFrom, reason, name, scope } of iterAxMappedTokens(tokens)) {
    // Skip brand-only tokens (D-09b)
    if (axMap == null) continue;

    // Determine which admin scopes to check for this token
    // scope field: "light" or "dark" (from flattenTokens — color.dark.* → "dark", others → "light")
    const scopePairs = scope === "dark"
      ? [["dark", darkScope]]
      : [["light", lightScope]];

    for (const [label, adminScope] of scopePairs) {
      const adminRaw = adminScope[axMap];

      // Token not defined in this scope — skip (not an error; dark block omits some tokens)
      if (adminRaw == null) continue;

      let adminHex;
      try {
        adminHex = resolveColor(adminRaw, adminScope, brandRaw);
      } catch (err) {
        if (verbose) {
          console.error(`ERROR  ${name} ${label}: failed to resolve ${axMap} value "${adminRaw}" — ${err.message}`);
        }
        failures++;
        continue;
      }

      if (adminHex !== brandHex.toLowerCase()) {
        // Check documented divergence tolerance (D-10)
        if (divergesFrom === axMap && reason) {
          if (verbose) {
            console.log(`OK     (documented divergence) ${name} ${label}: ${reason}`);
          }
        } else {
          if (verbose) {
            console.error(`DRIFT  ${name} ${label}: brand=${brandHex} admin(${axMap})=${adminHex}`);
          }
          failures++;
        }
      } else {
        if (verbose) {
          console.log(`OK     ${name} ${label}: ${adminHex}`);
        }
      }
    }
  }

  return failures;
}

// ---------------------------------------------------------------------------
// Live mode (no --test flag)
// ---------------------------------------------------------------------------

function runLive() {
  const themeCss = fs.readFileSync(THEME_PATH, "utf8");
  const tokens = JSON.parse(fs.readFileSync(TOKENS_PATH, "utf8"));

  const failures = runParity({ themeCss, tokens, verbose: true });

  if (failures === 0) {
    console.log("\nPARITY_CLEAN_OK");
  } else {
    console.error(`\nPARITY FAILED: ${failures} undocumented drift(s)`);
  }

  process.exit(failures === 0 ? 0 : 1);
}

// ---------------------------------------------------------------------------
// --test mode: SC#2 fixture cases (both directions)
// ---------------------------------------------------------------------------

/**
 * Load the real CSS and mutate ONE ax-mapped declaration for fixture testing.
 * Replaces the first occurrence of `--ax-success: var(--accrue-moss)` with a
 * known-different hex so the parity engine sees undocumented drift.
 *
 * @param {string} realCss - The committed theme.css text
 * @returns {{ mutatedCss: string, driftedProp: string, originalValue: string, injectedValue: string }}
 */
function buildDriftFixture(realCss) {
  // Target: --ax-success (light scope maps to var(--accrue-moss) = #5e9e84)
  // Inject a different hex so the parity engine reports drift.
  const driftedProp = "--ax-success";
  const originalValue = "var(--accrue-moss)";
  const injectedValue = "#ff0000"; // a red hex — clearly wrong
  const mutatedCss = realCss.replace(
    `${driftedProp}: ${originalValue}`,
    `${driftedProp}: ${injectedValue}`
  );
  if (mutatedCss === realCss) {
    throw new Error(`[parity-check] fixture setup: could not find "${driftedProp}: ${originalValue}" in theme.css`);
  }
  return { mutatedCss, driftedProp, originalValue, injectedValue };
}

/**
 * Inject a $extensions divergesFrom+reason on the first ax-mapped token that
 * maps to driftedProp (color.feedback.success → --ax-success) so the parity
 * engine tolerates the mutation in case (c).
 *
 * @param {object} realTokens - The committed tokens JSON (deep-copied internally)
 * @param {string} driftedProp - The --ax-* property that carries injected drift
 * @returns {object} A new tokens object with the divergence extension injected
 */
function buildDivergenceFixture(realTokens, driftedProp) {
  // Deep copy to avoid mutating the original object
  const tokens = JSON.parse(JSON.stringify(realTokens));
  // Inject divergesFrom+reason on color.feedback.success (maps --ax-success)
  const target = tokens?.color?.feedback?.success;
  if (!target) {
    throw new Error(`[parity-check] fixture setup: color.feedback.success not found in tokens`);
  }
  target.$extensions = {
    "org.accrue.ax": {
      axMap: driftedProp,
      divergesFrom: driftedProp,
      reason: "test-fixture: intentional injected divergence for SC#2 validation",
    },
  };
  return tokens;
}

async function runTests() {
  const realCss = fs.readFileSync(THEME_PATH, "utf8");
  const realTokens = JSON.parse(fs.readFileSync(TOKENS_PATH, "utf8"));

  let testFailures = 0;

  function assertCase(label, actualFailures, expectedFailures) {
    const ok = expectedFailures === "nonzero"
      ? actualFailures > 0
      : actualFailures === expectedFailures;
    if (ok) {
      console.log(`CASE PASS  ${label}: failures=${actualFailures} (expected ${expectedFailures === "nonzero" ? ">0" : expectedFailures})`);
    } else {
      console.error(`CASE FAIL  ${label}: failures=${actualFailures} (expected ${expectedFailures === "nonzero" ? ">0" : expectedFailures})`);
      testFailures++;
    }
  }

  // (a) Positive: real theme.css + real tokens.json → 0 failures
  {
    const failures = runParity({ themeCss: realCss, tokens: realTokens, verbose: false });
    assertCase("(a) positive — real inputs", failures, 0);
  }

  // (b) Injected drift: mutated theme.css → >0 failures (drift detected, token named in stderr)
  {
    const { mutatedCss, driftedProp } = buildDriftFixture(realCss);
    // Capture output to verify the drift is named
    const capturedErrors = [];
    const origConsoleError = console.error;
    console.error = (...args) => {
      capturedErrors.push(args.join(" "));
      origConsoleError(...args);
    };
    const failures = runParity({ themeCss: mutatedCss, tokens: realTokens, verbose: true });
    console.error = origConsoleError;

    assertCase("(b) injected-drift — non-zero failures", failures, "nonzero");
    // Verify the named drifted token appears in the error output
    const driftNamed = capturedErrors.some(line => line.includes(driftedProp) || line.includes("success"));
    if (driftNamed) {
      console.log(`CASE PASS  (b) drift-named — drift output names the drifted prop`);
    } else {
      console.error(`CASE FAIL  (b) drift-named — drift output did NOT name the drifted prop`);
      testFailures++;
    }
  }

  // (c) Documented divergence: same mutation + $extensions { divergesFrom, reason } → 0 failures
  {
    const { mutatedCss, driftedProp } = buildDriftFixture(realCss);
    const tokensWithDivergence = buildDivergenceFixture(realTokens, driftedProp);
    const failures = runParity({ themeCss: mutatedCss, tokens: tokensWithDivergence, verbose: false });
    assertCase("(c) documented-divergence — tolerated (0 failures)", failures, 0);
  }

  // (d) Sanity: mutation to a NON-ax-mapped property does not cause failures
  {
    // Mutate a non-color property (--ax-font-sans) — not color-compared, so parity ignores it
    const harmlessMutatedCss = realCss.replace(
      "--ax-font-sans:",
      "--ax-font-sans-MUTATED:"
    );
    const failures = runParity({ themeCss: harmlessMutatedCss, tokens: realTokens, verbose: false });
    assertCase("(d) sanity — unrelated mutation causes 0 failures", failures, 0);
  }

  // Verify committed files are untouched (enforced at the verify command level via git diff)
  if (testFailures === 0) {
    console.log("\nPARITY_TEST_OK");
  } else {
    console.error(`\nPARITY --test FAILED: ${testFailures} case(s) failed`);
  }

  process.exit(testFailures === 0 ? 0 : 1);
}

// ---------------------------------------------------------------------------
// isMain guard (RESEARCH isMain pattern — mirrors geist-spine-mono.mjs)
// ---------------------------------------------------------------------------

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.includes("--test")) {
    runTests().catch(err => {
      console.error("[parity-check] FATAL:", err);
      process.exit(1);
    });
  } else {
    runLive();
  }
}
