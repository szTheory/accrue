/**
 * lib.test.mjs — RED phase: assertions for lib.mjs exports.
 * Run BEFORE implementing lib.mjs to confirm these fail (RED gate).
 * After implementation, `node brandbook/tokens/harness/lib.mjs --test` is the canonical gate.
 *
 * TDD RED commit — this file exists only to prove the test fails before implementation.
 */

// This import will fail (MODULE_NOT_FOUND) until lib.mjs exists — that IS the RED failure.
import { flattenTokens, deriveCssVar, resolveColor, iterAxMappedTokens } from "./lib.mjs";

const tokens = JSON.parse(
  (await import("fs")).default.readFileSync(
    new URL("../tokens.json", import.meta.url),
    "utf8"
  )
);

let passed = 0;
let failed = 0;

function assert(condition, label) {
  if (condition) {
    console.log(`  PASS: ${label}`);
    passed++;
  } else {
    console.error(`  FAIL: ${label}`);
    failed++;
  }
}

function assertThrows(fn, label) {
  try {
    fn();
    console.error(`  FAIL: ${label} (expected throw, got no error)`);
    failed++;
  } catch (_) {
    console.log(`  PASS: ${label}`);
    passed++;
  }
}

// deriveCssVar
console.log("\n--- deriveCssVar ---");
assert(deriveCssVar(["color", "brand", "moss"]) === "--accrue-moss", 'brand leaf → --accrue-moss');
assert(deriveCssVar(["color", "brand", "ink"]) === "--accrue-ink", 'brand leaf → --accrue-ink');
assert(deriveCssVar(["color", "surface", "base"]) === "--accrue-surface-base", 'role → --accrue-surface-base');
assert(deriveCssVar(["color", "feedback", "danger"]) === "--accrue-feedback-danger", 'feedback → --accrue-feedback-danger');
assert(deriveCssVar(["color", "content", "muted"]) === "--accrue-content-muted", 'content role → --accrue-content-muted');

// resolveColor
console.log("\n--- resolveColor ---");
assert(resolveColor("#FFF", {}, {}) === "#ffffff", 'normalize short hex to #ffffff');
assert(resolveColor("#fafbfc", {}, {}) === "#fafbfc", 'pass-through lowercase hex');
assert(resolveColor("#111418", {}, {}) === "#111418", 'pass-through dark hex');
assert(
  resolveColor("var(--accrue-paper)", {}, { "--accrue-paper": "#fafbfc" }) === "#fafbfc",
  'resolve var() from brandRaw'
);
assert(
  resolveColor("var(--accrue-moss)", { "--accrue-moss": "#5e9e84" }, {}) === "#5e9e84",
  'resolve var() from vars map'
);

// resolveColor throws on unresolved var
console.log("\n--- resolveColor throws on unresolved ---");
assertThrows(
  () => resolveColor("var(--accrue-nonexistent)", {}, {}),
  'throws on unresolved var()'
);
assertThrows(
  () => resolveColor("notacolor", {}, {}),
  'throws on unparseable color string'
);

// flattenTokens
console.log("\n--- flattenTokens ---");
const rows = flattenTokens(tokens);
assert(Array.isArray(rows), 'returns array');
assert(rows.length > 0, 'returns non-empty array');
const mossRow = rows.find(r => r.cssVar === "--accrue-moss");
assert(!!mossRow, 'flattenTokens includes --accrue-moss');
assert(mossRow?.hex === "#5e9e84", '--accrue-moss hex is #5e9e84');
assert(mossRow?.scope === "light", '--accrue-moss scope is light');
assert(typeof mossRow?.axMap === "string", '--accrue-moss axMap is string');
const darkRows = rows.filter(r => r.scope === "dark");
assert(darkRows.length > 0, 'flattenTokens includes dark-scope rows');

// iterAxMappedTokens
console.log("\n--- iterAxMappedTokens ---");
const axRows = [...iterAxMappedTokens(tokens)];
assert(Array.isArray(axRows), 'returns iterable');
assert(axRows.length > 0, 'yields at least one entry');
assert(axRows.every(r => "axMap" in r), 'all entries have axMap field');
assert(axRows.every(r => "brandHex" in r), 'all entries have brandHex field');
// Unlike filter (which is caller's job), iterAxMappedTokens yields ALL including null-axMap
const nullAxMapEntries = axRows.filter(r => r.axMap === null);
assert(nullAxMapEntries.length > 0, 'yields brand-only (axMap=null) entries (caller filters)');

console.log(`\n--- Results: ${passed} passed, ${failed} failed ---`);
process.exit(failed === 0 ? 0 : 1);
