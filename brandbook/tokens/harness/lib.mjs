/**
 * lib.mjs — Shared helpers for the Accrue tokens harness.
 *
 * Exports:
 *   flattenTokens(json)             → [{ cssVar, hex, axMap, divergesFrom?, reason?, name, scope }]
 *   deriveCssVar(pathSegs)          → "--accrue-<…>"
 *   resolveColor(raw, vars, brandRaw) → lowercase "#rrggbb" (throws on unresolved — never returns undefined)
 *   iterAxMappedTokens(json)        → iterable of { axMap, brandHex, divergesFrom, reason, name, scope }
 *
 * Throw-don't-return-undefined discipline (RESEARCH Pitfall 1):
 *   culori returns undefined for color-mix() — a silent undefined makes parity checks falsely pass.
 *   resolveColor() always throws a clear Error on any unresolved color.
 *
 * Usage (smoke test):
 *   node brandbook/tokens/harness/lib.mjs --test
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { parse as parseColor, formatHex, interpolate } from "culori";
import valueParser from "postcss-value-parser";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// CSS var-name derivation (RESEARCH Pattern 1)
// ---------------------------------------------------------------------------

/**
 * Derive a CSS custom property name from DTCG path segments.
 *
 * Rule:
 *   - Drop the leading segment (e.g. "color" or "dimension").
 *   - If rest[0] === "brand": emit --accrue-<rest.slice(1).join("-")>
 *   - Else: emit --accrue-<rest.join("-")>
 *   - Always lowercase.
 *
 * Examples:
 *   ["color","brand","moss"]     → "--accrue-moss"
 *   ["color","surface","base"]   → "--accrue-surface-base"
 *   ["color","dark","primary"]   → "--accrue-dark-primary"
 *
 * @param {string[]} pathSegs - Full path from DTCG root (e.g. ["color","brand","moss"])
 * @returns {string}
 */
export function deriveCssVar(pathSegs) {
  const [, ...rest] = pathSegs; // drop leading "color"/"dimension"
  if (rest[0] === "brand") {
    return `--accrue-${rest.slice(1).join("-")}`.toLowerCase();
  }
  return `--accrue-${rest.join("-")}`.toLowerCase();
}

// ---------------------------------------------------------------------------
// Color resolution (RESEARCH Pitfall 1 + 2)
// ---------------------------------------------------------------------------

/**
 * Resolve a raw CSS color value (var(), color-mix(), hex, rgb, etc.) to a
 * canonical lowercase "#rrggbb" string.
 *
 * Throw-don't-return-undefined: throws a clear Error if the color cannot be
 * resolved rather than silently returning undefined (which would cause parity
 * checks to falsely pass).
 *
 * @param {string} raw - The raw CSS value to resolve
 * @param {Record<string, string>} vars - Admin scope custom properties (--ax-*, --accrue-*)
 * @param {Record<string, string>} brandRaw - Brand raw palette (--accrue-* → hex)
 * @returns {string} lowercase "#rrggbb"
 * @throws {Error} if the color cannot be resolved
 */
export function resolveColor(raw, vars, brandRaw) {
  const ast = valueParser(raw.trim());

  // Case 1: bare var(--x) — resolve against vars then brandRaw
  if (
    ast.nodes.length === 1 &&
    ast.nodes[0].type === "function" &&
    ast.nodes[0].value === "var"
  ) {
    const propNode = ast.nodes[0].nodes.find(n => n.type === "word");
    if (!propNode) throw new Error(`[lib.mjs] resolveColor: malformed var() in: ${raw}`);
    const propName = propNode.value;
    const next = vars[propName] ?? brandRaw[propName];
    if (next == null) {
      throw new Error(`[lib.mjs] resolveColor: unresolved var(${propName})`);
    }
    return resolveColor(next, vars, brandRaw);
  }

  // Case 2: color-mix(in <space>, A p%, B) — evaluate via culori interpolate
  // (culori 4.0.2 cannot parse color-mix() — returns undefined. RESEARCH Pitfall 1.)
  const mixNode = ast.nodes.find(
    n => n.type === "function" && n.value === "color-mix"
  );
  if (mixNode) {
    return _resolveColorMix(mixNode, vars, brandRaw);
  }

  // Case 3: bare hex/rgb/rgba/named color — culori formatHex normalizes case + 3-digit expand
  const parsed = parseColor(raw);
  if (!parsed) {
    throw new Error(`[lib.mjs] resolveColor: culori could not parse: ${raw}`);
  }
  const result = formatHex(parsed);
  if (!result) {
    throw new Error(`[lib.mjs] resolveColor: formatHex returned undefined for: ${raw}`);
  }
  return result; // always lowercase #rrggbb from culori
}

/**
 * Evaluate a color-mix() AST node via culori interpolate.
 *
 * color-mix(in <space>, A p%, B)  →  interpolate([B, A], space)(p/100)
 *
 * RESEARCH Pitfall 2 — percentage direction:
 *   interpolate([B, A])(t=0) = B, (t=1) = A
 *   so t = firstPercent/100 walks correctly from B toward A.
 *
 * @param {object} node - postcss-value-parser function node for color-mix
 * @param {Record<string, string>} vars
 * @param {Record<string, string>} brandRaw
 * @returns {string} lowercase "#rrggbb"
 */
// Map CSS color-mix space names to culori mode names
// culori uses "rgb" for sRGB, "oklch" for OKLCh, "hsl" for HSL, etc.
const CSS_SPACE_TO_CULORI = {
  "srgb": "rgb",
  "rgb": "rgb",
  "oklch": "oklch",
  "oklab": "oklab",
  "hsl": "hsl",
  "hwb": "hwb",
  "lab": "lab",
  "lch": "lch",
};

function _resolveColorMix(node, vars, brandRaw) {
  // Filter out separator nodes (div = comma, space = whitespace)
  const args = node.nodes.filter(n => n.type !== "div" && n.type !== "space");
  // Expected structure after filtering: [word:"in", word:<space>, <A-nodes...>, <B-nodes...>]
  // Find "in" keyword index
  const inIdx = args.findIndex(n => n.type === "word" && n.value === "in");
  if (inIdx === -1) throw new Error(`[lib.mjs] resolveColorMix: no "in" keyword found`);
  const cssSpace = args[inIdx + 1]?.value;
  const colorSpace = CSS_SPACE_TO_CULORI[cssSpace] ?? cssSpace;
  if (!colorSpace) throw new Error(`[lib.mjs] resolveColorMix: no color space after "in"`);

  // Remaining args after "in <space>": first color (+ optional %), second color (+ optional %)
  const rest = args.slice(inIdx + 2);

  // Parse first color + optional percentage
  let firstPercent = 50; // default
  let firstColorStr;
  let secondColorStr;

  // Stringify each arg node back to raw text for resolution
  const stringifyNode = n => {
    if (n.type === "function") return valueParser.stringify(n);
    return n.value;
  };

  // Detect if second-to-last or last node is a word ending in "%"
  // Supported structures:
  //   [colorA, "p%", colorB]             → firstPercent=p, secondColorStr=colorB
  //   [colorA, "p%", colorB, "q%"]       → firstPercent=p, secondColorStr=colorB (q% ignored — implied)
  //   [colorA, colorB, "q%"]             → secondPercent=q, firstPercent=100-q, secondColorStr=colorB
  //   [colorA, colorB]                   → 50/50
  if (rest.length >= 3 && rest[1].type === "word" && rest[1].value.endsWith("%")) {
    // [colorA, "p%", colorB] or [colorA, "p%", colorB, "q%"] (two-sided)
    firstPercent = parseFloat(rest[1].value);
    firstColorStr = stringifyNode(rest[0]);
    // Build secondColorStr from rest[2..], then strip a trailing percentage word if present.
    // This handles both "blue" and "blue 60%" as the second color part.
    const secondParts = rest.slice(2).map(stringifyNode);
    const lastPart = secondParts[secondParts.length - 1];
    if (lastPart && /^\d+(\.\d+)?%$/.test(lastPart)) {
      secondParts.pop(); // discard explicit second percentage (100-firstPercent implied)
    }
    secondColorStr = secondParts.join(" ").trim();
  } else if (rest.length >= 2) {
    // [colorA, colorB] (50/50) or [colorA, colorB, "q%"] (second-only percentage)
    const restParts = rest.map(stringifyNode);
    const lastPart = restParts[restParts.length - 1];
    if (restParts.length >= 3 && /^\d+(\.\d+)?%$/.test(lastPart)) {
      // e.g. [A, B, "60%"] — interpret as A (100-60)%, B 60%
      const secondPercent = parseFloat(lastPart);
      firstPercent = 100 - secondPercent;
      firstColorStr = restParts[0];
      secondColorStr = restParts.slice(1, -1).join(" ").trim();
    } else {
      firstColorStr = restParts[0];
      secondColorStr = restParts.slice(1).join(" ").trim();
    }
  } else {
    throw new Error(`[lib.mjs] resolveColorMix: unexpected color-mix argument structure`);
  }

  // Resolve each color recursively
  const resolvedA = resolveColor(firstColorStr, vars, brandRaw);
  const resolvedB = resolveColor(secondColorStr, vars, brandRaw);

  // Evaluate: interpolate([B, A], space)(firstPercent/100)
  // Pitfall 2: t=0→B, t=1→A, so t=firstPercent/100 gives p% of A
  const colorFn = interpolate([resolvedB, resolvedA], colorSpace);
  const mixed = colorFn(firstPercent / 100);
  const result = formatHex(mixed);
  if (!result) {
    throw new Error(
      `[lib.mjs] resolveColorMix: interpolate returned undefined for color-mix(in ${colorSpace}, ${firstColorStr} ${firstPercent}%, ${secondColorStr})`
    );
  }
  return result;
}

// ---------------------------------------------------------------------------
// DTCG tree flattening
// ---------------------------------------------------------------------------

/**
 * Resolve a DTCG alias reference like "{color.brand.paper}" to a hex string.
 *
 * @param {string} aliasStr - e.g. "{color.brand.paper}"
 * @param {object} root - the full tokens JSON root
 * @returns {string|null} lowercase hex or null if unresolvable
 */
function _resolveAlias(aliasStr, root, seen = new Set()) {
  if (seen.has(aliasStr)) {
    throw new Error(
      `[lib.mjs] _resolveAlias: circular alias detected: ${[...seen, aliasStr].join(" → ")}`
    );
  }
  seen.add(aliasStr);
  const path = aliasStr.slice(1, -1).split("."); // strip { } and split
  let node = root;
  for (const seg of path) {
    if (node == null || typeof node !== "object") return null;
    node = node[seg];
  }
  if (node == null || !node.$value) return null;
  const v = node.$value;
  if (typeof v === "string" && v.startsWith("{")) {
    return _resolveAlias(v, root, seen); // nested alias — pass seen set for cycle detection
  }
  if (typeof v === "object" && v.hex) return v.hex.toLowerCase();
  return null;
}

/**
 * Walk a DTCG token tree and collect one flat row per concrete color token.
 *
 * Each row: { cssVar, hex, axMap, divergesFrom?, reason?, name, scope }
 *   - cssVar: derived CSS custom property name (--accrue-*)
 *   - hex: lowercase #rrggbb (resolved through aliases)
 *   - axMap: string or null (from $extensions.org.accrue.ax.axMap)
 *   - divergesFrom: optional string (from $extensions.org.accrue.ax.divergesFrom)
 *   - reason: optional string (from $extensions.org.accrue.ax.reason)
 *   - name: human-readable dot-path (e.g. "color.brand.moss")
 *   - scope: "light" | "dark" (color.dark.* tokens get scope "dark", all others "light")
 *
 * Only emits rows for nodes with a $value (leaf tokens). Skips dimension tokens.
 * Does not skip any axMap value (caller filters axMap === null if needed).
 *
 * @param {object} json - Full DTCG tokens JSON
 * @returns {Array<{cssVar: string, hex: string, axMap: string|null, name: string, scope: string}>}
 */
export function flattenTokens(json) {
  const rows = [];
  _walkTokenNode(json, [], rows, json);
  return rows;
}

function _walkTokenNode(node, pathSegs, rows, root) {
  for (const [key, val] of Object.entries(node)) {
    if (key.startsWith("$")) continue; // skip DTCG meta keys
    if (val == null || typeof val !== "object") continue;

    const segs = [...pathSegs, key];

    if ("$value" in val) {
      // Leaf token: only process color tokens (skip dimension tokens for flattenTokens)
      const type = val.$type ?? _inheritedType(root, segs);
      if (type !== "color") continue;

      const v = val.$value;
      let hex = null;
      if (typeof v === "string" && v.startsWith("{")) {
        hex = _resolveAlias(v, root);
      } else if (typeof v === "object" && v.hex) {
        hex = v.hex.toLowerCase();
      }
      if (!hex) continue; // skip non-color or unresolvable

      const ext = val.$extensions?.["org.accrue.ax"] ?? {};
      const axMap = ext.axMap ?? null;
      const divergesFrom = ext.divergesFrom ?? undefined;
      const reason = ext.reason ?? undefined;
      const scope = segs[1] === "dark" ? "dark" : "light";
      const cssVar = deriveCssVar(segs);
      const name = segs.join(".");

      const row = { cssVar, hex, axMap, name, scope };
      if (divergesFrom !== undefined) row.divergesFrom = divergesFrom;
      if (reason !== undefined) row.reason = reason;
      rows.push(row);
    } else {
      // Group node: recurse
      _walkTokenNode(val, segs, rows, root);
    }
  }
}

/**
 * Walk up the path to find the nearest inherited $type (for group-level $type).
 * Returns "color" as default for DTCG color groups.
 */
function _inheritedType(root, segs) {
  // Walk from root along path, collect $type from each group node
  let node = root;
  let inherited = null;
  for (const seg of segs) {
    if (node == null || typeof node !== "object") break;
    if (node.$type) inherited = node.$type;
    node = node[seg];
    if (node && node.$type) inherited = node.$type;
  }
  return inherited;
}

// ---------------------------------------------------------------------------
// Ax-mapped token iterator
// ---------------------------------------------------------------------------

/**
 * Iterate over all tokens that carry an axMap extension, yielding:
 *   { axMap, brandHex, divergesFrom?, reason?, name, scope }
 *
 * Yields ALL tokens (including axMap:null) — caller filters axMap===null.
 * This matches the parity-check pattern: `for (const { axMap, brandHex, ... } of iter) { if (!axMap) continue; ... }`
 *
 * @param {object} json - Full DTCG tokens JSON
 * @returns {Iterable<{axMap: string|null, brandHex: string, name: string, scope: string}>}
 */
export function* iterAxMappedTokens(json) {
  const rows = flattenTokens(json);
  for (const row of rows) {
    yield {
      axMap: row.axMap,
      brandHex: row.hex,
      divergesFrom: row.divergesFrom,
      reason: row.reason,
      name: row.name,
      scope: row.scope,
    };
  }
}

// ---------------------------------------------------------------------------
// Smoke test (--test flag) + isMain guard
// ---------------------------------------------------------------------------

async function main() {
  const tokensPath = path.resolve(__dirname, "../tokens.json");
  const tokens = JSON.parse(fs.readFileSync(tokensPath, "utf8"));

  let failures = 0;

  function check(condition, label) {
    if (!condition) {
      console.error(`[lib.mjs] smoke FAIL: ${label}`);
      failures++;
    } else {
      console.log(`[lib.mjs] smoke OK:   ${label}`);
    }
  }

  function checkThrows(fn, label) {
    try {
      fn();
      console.error(`[lib.mjs] smoke FAIL: ${label} (expected throw, no error thrown)`);
      failures++;
    } catch (_) {
      console.log(`[lib.mjs] smoke OK:   ${label}`);
    }
  }

  // --- deriveCssVar ---
  check(deriveCssVar(["color", "brand", "moss"]) === "--accrue-moss", 'deriveCssVar brand → --accrue-moss');
  check(deriveCssVar(["color", "surface", "base"]) === "--accrue-surface-base", 'deriveCssVar role → --accrue-surface-base');
  check(deriveCssVar(["color", "dark", "primary"]) === "--accrue-dark-primary", 'deriveCssVar dark → --accrue-dark-primary');

  // --- resolveColor: normalization ---
  check(resolveColor("#FFF", {}, {}) === "#ffffff", 'resolveColor: #FFF → #ffffff');
  check(resolveColor("#fafbfc", {}, {}) === "#fafbfc", 'resolveColor: pass-through lowercase hex');
  check(resolveColor("#111418", {}, {}) === "#111418", 'resolveColor: pass-through dark hex');

  // --- resolveColor: var() indirection ---
  check(
    resolveColor("var(--accrue-paper)", {}, { "--accrue-paper": "#fafbfc" }) === "#fafbfc",
    'resolveColor: var() from brandRaw'
  );
  check(
    resolveColor("var(--accrue-moss)", { "--accrue-moss": "#5e9e84" }, {}) === "#5e9e84",
    'resolveColor: var() from vars map'
  );

  // --- resolveColor: color-mix via interpolate (Pitfall 1+2) ---
  // Verified in-session: interpolate(["#ffffff","#5D79F6"],"rgb")(0.08) ≈ #f2f4fe
  const mixResult = resolveColor("color-mix(in srgb, #5D79F6 8%, #ffffff)", {}, {});
  check(typeof mixResult === "string" && /^#[0-9a-f]{6}$/.test(mixResult), 'resolveColor: color-mix → #rrggbb');

  // --- resolveColor: color-mix two-sided percentage form (WR-01) ---
  // color-mix(in srgb, red 40%, blue 60%) — both sides carry explicit percentages
  const mixTwoSided = resolveColor("color-mix(in srgb, red 40%, blue 60%)", {}, {});
  check(typeof mixTwoSided === "string" && /^#[0-9a-f]{6}$/.test(mixTwoSided), 'resolveColor: color-mix two-sided % → #rrggbb');

  // --- resolveColor: color-mix second-only percentage form (WR-01) ---
  // color-mix(in srgb, red, blue 60%) — only second color carries an explicit percentage
  const mixSecondOnly = resolveColor("color-mix(in srgb, red, blue 60%)", {}, {});
  check(typeof mixSecondOnly === "string" && /^#[0-9a-f]{6}$/.test(mixSecondOnly), 'resolveColor: color-mix second-only % → #rrggbb');

  // Both forms should produce the same result as the equivalent first-only form:
  // color-mix(in srgb, red 40%, blue 60%) == color-mix(in srgb, red 40%, blue)
  const mixFirstOnly = resolveColor("color-mix(in srgb, red 40%, blue)", {}, {});
  check(mixTwoSided === mixFirstOnly, 'resolveColor: two-sided % equals first-only % form');
  check(mixSecondOnly === mixFirstOnly, 'resolveColor: second-only % equals first-only % form (40%+60% symmetric)');

  // --- resolveColor: throw-on-unresolved (THREAT T-184-01) ---
  checkThrows(
    () => resolveColor("var(--accrue-nonexistent)", {}, {}),
    'resolveColor THROWS on unresolved var()'
  );
  checkThrows(
    () => resolveColor("notavalidcolor", {}, {}),
    'resolveColor THROWS on unparseable color'
  );

  // --- _resolveAlias: cycle detection (WR-02) ---
  // Build a synthetic token tree with a circular alias: A → {B}, B → {A}
  checkThrows(
    () => {
      const cyclicTokens = {
        color: {
          $type: "color",
          a: { $value: "{color.b}", $type: "color" },
          b: { $value: "{color.a}", $type: "color" },
        },
      };
      flattenTokens(cyclicTokens); // _resolveAlias is called inside flattenTokens
    },
    '_resolveAlias THROWS on circular alias A→B→A'
  );

  // --- flattenTokens ---
  const rows = flattenTokens(tokens);
  check(Array.isArray(rows) && rows.length > 0, 'flattenTokens returns non-empty array');
  const mossRow = rows.find(r => r.cssVar === "--accrue-moss");
  check(!!mossRow, 'flattenTokens includes --accrue-moss');
  check(mossRow?.hex === "#5e9e84", '--accrue-moss hex is #5e9e84');
  check(mossRow?.scope === "light", '--accrue-moss scope is light');
  check(mossRow?.axMap === "--ax-success", '--accrue-moss axMap is --ax-success');

  // Alias resolution: surface.base aliases color.brand.paper → #fafbfc
  const surfaceBaseRow = rows.find(r => r.cssVar === "--accrue-surface-base");
  check(!!surfaceBaseRow, 'flattenTokens includes --accrue-surface-base');
  check(surfaceBaseRow?.hex === "#fafbfc", '--accrue-surface-base resolves alias to #fafbfc');

  // Dark scope tokens
  const darkRows = rows.filter(r => r.scope === "dark");
  check(darkRows.length > 0, 'flattenTokens includes dark-scope rows');
  const darkBaseRow = rows.find(r => r.cssVar === "--accrue-dark-base");
  check(darkBaseRow?.hex === "#0f1318", 'dark base hex is #0f1318');
  check(darkBaseRow?.scope === "dark", 'dark base scope is dark');

  // Brand-only tokens (axMap:null)
  const fogRow = rows.find(r => r.cssVar === "--accrue-fog");
  check(fogRow?.axMap === null, 'fog is brand-only (axMap:null)');
  const cobaltRow = rows.find(r => r.cssVar === "--accrue-cobalt");
  check(cobaltRow?.axMap === null, 'cobalt is brand-only (axMap:null)');

  // --- iterAxMappedTokens ---
  const axRows = [...iterAxMappedTokens(tokens)];
  check(axRows.length > 0, 'iterAxMappedTokens yields entries');
  check(axRows.every(r => "axMap" in r), 'all entries have axMap field');
  check(axRows.every(r => "brandHex" in r), 'all entries have brandHex field');
  const nullAxEntries = axRows.filter(r => r.axMap === null);
  check(nullAxEntries.length > 0, 'iterAxMappedTokens yields brand-only (axMap:null) entries (caller filters)');

  if (failures > 0) {
    console.error(`\n[lib.mjs] smoke: FAIL (${failures} assertion(s) failed)`);
    process.exit(1);
  }
  console.log("\n[lib.mjs] smoke: OK");
  process.exit(0);
}

// isMain guard — prevents smoke test execution when imported as a module
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.includes("--test")) {
    main().catch((err) => {
      console.error("[lib.mjs] FATAL:", err);
      process.exit(1);
    });
  }
}
