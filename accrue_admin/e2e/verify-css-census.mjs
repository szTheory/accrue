/**
 * verify-css-census.mjs — orphan/dangling `ax-*` CSS census guard (Phase 211, D-02).
 *
 * CSS dead-code deletion is invisible to source-text CI: a rule can be deleted (or,
 * worse, left behind) with no failing test. This standalone guard is the mechanical
 * proof that an `.ax-*` selector defined in `assets/css/app.css` is actually dead —
 * i.e. zero exact-token references across `lib/`, `storybook/`, `test/`, `e2e/`.
 *
 * Zero new dependencies by contract: imports ONLY `node:fs`/`node:path`/`node:url`
 * built-ins (twins the SDK-free discipline of `e2e/ratchet/region-tags.js`). The
 * `--self-test` mode runs hand-written in-memory fixtures with no filesystem, CSS,
 * network, or browser access, mirroring `region-tags.js`'s `runSelfTest()` convention.
 *
 * Reports:
 *   (a) orphans  — CSS `.ax-*` selectors with zero references in the source trees
 *                  (exit code 1 if any found; this is the deletion-liveness signal).
 *   (b) missing  — `ax-*` class tokens used in `class="..."`/`class={...}` in `.ex`/
 *                  `.exs` source with no matching CSS selector (informational only,
 *                  does NOT affect exit code).
 *
 * Exact-token matching (211-RESEARCH.md Pitfall 1): a naive substring/`\b` grep gives
 * the wrong answer for hyphen-suffixed and `data-`-prefixed neighbors. This guard uses
 * the validated `(?<![\w-])TOKEN(?![\w-])` lookaround so `ax-launcher` is NOT matched
 * by `ax-launchers` and `ax-launcher-primary` is NOT matched by `data-ax-launcher-primary`.
 *
 * Usage:
 *   node e2e/verify-css-census.mjs             # real scan of assets/css/app.css; exit 1 if orphans
 *   node e2e/verify-css-census.mjs --self-test # pure in-memory fixture assertions; exit 1 on failure
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ADMIN_ROOT = path.join(__dirname, "..");

// -----------------------------------------------------------------------------
// Allowlist for dynamic/interpolated classes.
// -----------------------------------------------------------------------------
// Seed empty: 211-RESEARCH.md re-confirmed no `#{...}`-interpolated `ax-*` class in
// any of the 8 REIGN-04 candidate families reaches dashboard_live.ex / subscriptions_live.ex
// / subscription_live.ex / component_kitchen_live.ex. A future phase that introduces a
// genuinely dynamic prefix (e.g. "ax-foundation-status-") can add it here, OR place a
// `/* verify-css-census:allow */` comment on the line immediately above the selector in
// app.css to silence a single known-dynamic false positive without editing this script.
const KNOWN_DYNAMIC_PREFIXES = [];

const SUPPRESSION_MARKER = "verify-css-census:allow";

// -----------------------------------------------------------------------------
// Pure helpers (exercised directly by --self-test; no fs/network).
// -----------------------------------------------------------------------------

/** Escape regex metacharacters so a class name is matched literally. */
function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Strip `/* ... *​/` block comments so commented-out `.ax-*` text is not mistaken for a selector. */
function stripCssComments(cssSource) {
  return cssSource.replace(/\/\*[\s\S]*?\*\//g, "");
}

/**
 * Extract every `.ax-...` class-selector token from CSS source.
 * Returns a deduped Set of bare class names (no leading dot).
 */
export function extractCssSelectors(cssSource) {
  const re = /\.(ax-[a-zA-Z0-9_-]+)/g;
  const set = new Set();
  let m;
  while ((m = re.exec(cssSource)) !== null) {
    set.add(m[1]);
  }
  return set;
}

/**
 * True if `className` appears as an exact token in `sourceText`, using the
 * `(?<![\w-])CLASS(?![\w-])` lookaround (Pitfall 1). Rejects both hyphen-suffix
 * continuations (`ax-launchers`) and `data-`-prefixed attributes (`data-ax-launcher-primary`).
 */
export function isReferenced(className, sourceText) {
  const re = new RegExp(`(?<![\\w-])${escapeRegex(className)}(?![\\w-])`);
  return re.test(sourceText);
}

/**
 * Extract `ax-*` class tokens appearing inside `class="..."` / `class={...}`
 * attribute values in a source string (for the informational "missing rule" report).
 */
export function extractClassAttrTokens(sourceText) {
  const tokens = new Set();
  const attrRe = /class=(?:"([^"]*)"|\{([\s\S]*?)\})/g;
  let m;
  while ((m = attrRe.exec(sourceText)) !== null) {
    const body = m[1] ?? m[2] ?? "";
    const tokRe = /ax-[a-zA-Z0-9_-]+/g;
    let t;
    while ((t = tokRe.exec(body)) !== null) {
      tokens.add(t[0]);
    }
  }
  return tokens;
}

/**
 * Pure orphan computation shared by the real scan and the self-test.
 * @param {string} cssSource  — CSS to extract selectors from.
 * @param {string[]} sourceTexts — source file contents to search for references.
 * @param {object} [opts]
 * @param {string[]} [opts.knownDynamicPrefixes] — prefixes to exclude from orphan reporting.
 * @returns {string[]} sorted orphan class names.
 */
export function computeOrphans(cssSource, sourceTexts, opts = {}) {
  const knownDynamicPrefixes = opts.knownDynamicPrefixes ?? [];
  const candidates = extractCssSelectors(stripCssComments(cssSource));
  const orphans = [];
  for (const cls of candidates) {
    if (knownDynamicPrefixes.some((p) => cls.startsWith(p))) continue;
    const referenced = sourceTexts.some((txt) => isReferenced(cls, txt));
    if (!referenced) orphans.push(cls);
  }
  return orphans.sort();
}

/**
 * Recursively walk `rootDirs`, returning absolute paths of files whose extension
 * is in `extensions`. Uses Node 20+ `fs.readdirSync(dir, { recursive, withFileTypes })`
 * (confirmed at v22.14.0) — no glob dependency.
 */
export function walkFiles(rootDirs, extensions) {
  const files = [];
  for (const root of rootDirs) {
    if (!fs.existsSync(root)) continue;
    const entries = fs.readdirSync(root, { recursive: true, withFileTypes: true });
    for (const ent of entries) {
      if (!ent.isFile()) continue;
      if (!extensions.includes(path.extname(ent.name))) continue;
      const parent = ent.parentPath || ent.path || root;
      files.push(path.join(parent, ent.name));
    }
  }
  return files;
}

/**
 * Suppression check: true if the selector `.CLASS` is defined on an app.css line
 * immediately preceded by a `/* verify-css-census:allow *​/` comment line.
 */
function isSuppressed(className, cssLines) {
  const selRe = new RegExp(`\\.${escapeRegex(className)}(?![\\w-])`);
  for (let i = 0; i < cssLines.length; i++) {
    if (selRe.test(cssLines[i])) {
      if (i > 0 && cssLines[i - 1].includes(SUPPRESSION_MARKER)) return true;
    }
  }
  return false;
}

// -----------------------------------------------------------------------------
// Real scan
// -----------------------------------------------------------------------------

function runScan() {
  const cssPath = path.join(ADMIN_ROOT, "assets/css/app.css");
  const cssSource = fs.readFileSync(cssPath, "utf8");
  const cssLines = cssSource.split("\n");

  const searchRoots = ["lib", "storybook", "test", "e2e"].map((d) => path.join(ADMIN_ROOT, d));
  const files = walkFiles(searchRoots, [".ex", ".exs", ".js"]);
  const contents = files.map((f) => fs.readFileSync(f, "utf8"));

  const candidates = extractCssSelectors(stripCssComments(cssSource));

  // (a) orphans — zero references anywhere in the searched trees.
  let orphans = computeOrphans(cssSource, contents, { knownDynamicPrefixes: KNOWN_DYNAMIC_PREFIXES });
  const suppressed = orphans.filter((c) => isSuppressed(c, cssLines));
  orphans = orphans.filter((c) => !suppressed.includes(c));

  // (b) missing — class tokens used in .ex/.exs markup with no matching CSS selector.
  const exContents = files
    .filter((f) => f.endsWith(".ex") || f.endsWith(".exs"))
    .map((f) => fs.readFileSync(f, "utf8"));
  const usedTokens = new Set();
  for (const txt of exContents) {
    for (const tok of extractClassAttrTokens(txt)) usedTokens.add(tok);
  }
  const missing = [...usedTokens].filter((tok) => !candidates.has(tok)).sort();

  // Report
  console.log("verify-css-census — orphan/dangling ax-* CSS guard");
  console.log(`  CSS source:        ${path.relative(ADMIN_ROOT, cssPath)}`);
  console.log(`  Searched files:    ${files.length} (.ex/.exs/.js under lib, storybook, test, e2e)`);
  console.log(`  Candidate ax-* selectors: ${candidates.size}`);
  if (suppressed.length) {
    console.log(`  Suppressed (allowlisted): ${suppressed.length} — ${suppressed.join(", ")}`);
  }
  console.log("");
  console.log(`  (a) ORPHAN selectors (zero references) — ${orphans.length}:`);
  for (const c of orphans) console.log(`      ${c}`);
  console.log("");
  console.log(`  (b) MISSING rules (used in markup, no CSS selector) — ${missing.length} [informational]:`);
  for (const c of missing) console.log(`      ${c}`);
  console.log("");

  if (orphans.length > 0) {
    console.log(`RESULT: ${orphans.length} orphan selector(s) found (dead CSS present). Exit 1.`);
    process.exit(1);
  }
  console.log("RESULT: no orphan selectors. Exit 0.");
  process.exit(0);
}

// -----------------------------------------------------------------------------
// Self-test (pure, in-memory fixtures — no fs/CSS/network)
// -----------------------------------------------------------------------------

function runSelfTest() {
  const failures = [];
  const check = (name, cond) => {
    if (cond) {
      console.log(`  PASS ${name}`);
    } else {
      console.log(`  FAIL ${name}`);
      failures.push(name);
    }
  };

  // (i)+(ii): a genuinely orphaned rule is flagged; a genuinely live rule is not.
  {
    const css = ".ax-dead-rule { color: red; }\n.ax-live-rule { color: green; }";
    const src = ['<div class="ax-live-rule ax-card">Live</div>'];
    const orphans = computeOrphans(css, src);
    check("(i) genuinely orphaned rule is flagged", orphans.includes("ax-dead-rule"));
    check("(ii) genuinely live rule is NOT flagged", !orphans.includes("ax-live-rule"));
  }

  // (iii-a): exact-token boundary — .ax-launcher alongside class="ax-launchers"
  //          must flag ax-launcher (substring must NOT count as a reference).
  {
    const css = ".ax-launcher { display: block; }";
    const src = ['<div class="ax-launchers ax-launchers-tri">grid</div>'];
    const orphans = computeOrphans(css, src);
    check("(iii-a) ax-launcher orphaned despite ax-launchers substring", orphans.includes("ax-launcher"));
  }

  // (iii-b): exact-token boundary — .ax-launcher-primary alongside a
  //          data-ax-launcher-primary attribute must flag ax-launcher-primary
  //          (the data-* attribute must NOT count as a reference).
  {
    const css = ".ax-launcher-primary { display: block; }";
    const src = ['<div data-ax-launcher-primary="true">tile</div>'];
    const orphans = computeOrphans(css, src);
    check("(iii-b) ax-launcher-primary orphaned despite data- attribute", orphans.includes("ax-launcher-primary"));
  }

  // (iv) bonus (211-RESEARCH.md Pitfall 2): a comma-grouped rule mixing a dead
  //      branch and a live branch — the dead selector-name is still reported,
  //      the live one is not (branch-level granularity via selector-name census).
  {
    const css =
      ".ax-shell-content:has(> .ax-subscriptions-page),\n" +
      ".ax-shell-content:has(> .ax-home) { padding-top: 0; }";
    const src = ['<main class="ax-shell-content"><section class="ax-home">Home</section></main>'];
    const orphans = computeOrphans(css, src);
    check("(iv) dead comma-branch class flagged", orphans.includes("ax-subscriptions-page"));
    check("(iv) live comma-branch class NOT flagged", !orphans.includes("ax-home"));
  }

  console.log("");
  if (failures.length > 0) {
    console.log(`SELF-TEST FAILED — ${failures.length} assertion(s): ${failures.join("; ")}`);
    process.exit(1);
  }
  console.log("SELF-TEST PASSED — all fixture assertions hold (orphan, live, both exact-token boundary cases).");
  process.exit(0);
}

// -----------------------------------------------------------------------------
// CLI entry
// -----------------------------------------------------------------------------

if (import.meta.url === `file://${process.argv[1]}`) {
  if (process.argv.includes("--self-test")) {
    runSelfTest();
  } else {
    runScan();
  }
}
