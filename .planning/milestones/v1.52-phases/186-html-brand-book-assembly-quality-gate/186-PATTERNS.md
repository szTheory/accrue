# Phase 186: HTML Brand Book Assembly & Quality Gate — Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 4 new files
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `brandbook/index.html` | output artifact | transform (assembly output) | `brandbook/examples/palette.svg` (committed output) | role-match (both are committed build outputs from a harness script) |
| `brandbook/harness/assemble.mjs` | generator script | file-I/O + transform | `brandbook/tokens/harness/generate-tokens-css.mjs` | exact (reads source files, transforms content, writes one committed output file) |
| `brandbook/harness/verify-brandbook.mjs` | verifier script | file-I/O + Playwright screenshot | `brandbook/tokens/harness/verify-specimens.mjs` + `brandbook/logo/harness/size-matrix-qa.mjs` | exact split: verify-specimens for assertion/exit pattern; size-matrix-qa for Playwright browser/page usage |
| `brandbook/harness/package.json` | config | n/a | `brandbook/logo/harness/package.json` | exact (same `"type": "module"`, `"private": true`, scripts block shape) |

---

## Pattern Assignments

### `brandbook/harness/assemble.mjs` (generator, file-I/O + transform)

**Primary analog:** `brandbook/tokens/harness/generate-tokens-css.mjs`
**Secondary analog:** `brandbook/tokens/harness/generate-specimens.mjs`

**Imports pattern** (`generate-tokens-css.mjs` lines 18–22):
```javascript
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
```
No npm deps — Node built-ins only. `assemble.mjs` follows the same zero-dep pattern. The tokens harness adds `svgo` only when generating SVGs; `assemble.mjs` reads SVGs as raw strings (no SVGO needed).

**`__dirname` + path resolution pattern** (`generate-tokens-css.mjs` lines 23–27):
```javascript
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const TOKENS_PATH = path.resolve(__dirname, "../tokens.json");
const OUTPUT_PATH = path.resolve(__dirname, "../tokens.css");
```
Copy this pattern for `assemble.mjs` — all input paths computed from `__dirname` via `path.resolve`. Analogous:
```javascript
// In brandbook/harness/assemble.mjs:
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TOKENS_CSS  = path.resolve(__dirname, "../tokens/tokens.css");
const LOGO_DIR    = path.resolve(__dirname, "../logo");
const EXAMPLES_DIR = path.resolve(__dirname, "../examples");
const VOICE_MD    = path.resolve(__dirname, "../voice.md");
const COPY_MD     = path.resolve(__dirname, "../copy.md");
const README_MD   = path.resolve(__dirname, "../README.md");
const LICENSE_TXT = path.resolve(__dirname, "../LICENSE-FONTS.txt");
const OUTPUT_PATH = path.resolve(__dirname, "../index.html");
```

**Read + transform + write pattern** (`generate-tokens-css.mjs` lines 43–65):
```javascript
function generate() {
  const json = JSON.parse(fs.readFileSync(TOKENS_PATH, "utf8"));
  // ... transform ...
  const css = [ BANNER, ":root {", lightBlock, "}", ... ].join("\n");
  fs.writeFileSync(OUTPUT_PATH, css, "utf8");
  console.log(`[generate-tokens-css] wrote ${OUTPUT_PATH}`);
}

generate();
```
`assemble.mjs` follows the same single-pass shape: read all inputs at the top of `main()`, build the HTML string with array-join, `fs.writeFileSync` one output. The log prefix convention is `[assemble-brandbook]`.

**Sorted file iteration pattern** (`generate-specimens.mjs` lines 132–136 and `generate-logo-suite.mjs` lines 126–127):
```javascript
// generate-logo-suite.mjs lines 126-127:
const allFiles = fs.readdirSync(LOGO_DIR).filter((f) => f.endsWith(".svg"));
allFiles.sort();
```
Use the same `readdirSync` + `.sort()` pattern when iterating `brandbook/logo/*.svg` and `brandbook/examples/*.svg` to guarantee deterministic output ordering (avoids Pitfall 6 — non-deterministic assembly).

**`writeSvg` trailing-newline pattern** (`generate-specimens.mjs` lines 113–118):
```javascript
function writeSvg(filename, svgString) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  const outPath = path.join(OUTPUT_DIR, filename);
  const content = svgString.endsWith("\n") ? svgString : svgString + "\n";
  fs.writeFileSync(outPath, content, "utf8");
  console.log(`[generate-specimens] Wrote: ${filename}`);
}
```
Apply the same trailing-newline guarantee to `index.html` output.

**isMain guard pattern** (all harness scripts, e.g. `generate-logo-suite.mjs` lines 736–741):
```javascript
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error("[generate-logo-suite] FATAL:", err);
    process.exit(1);
  });
}
```
All harness scripts use this guard so they are safe to import as modules. Copy verbatim into `assemble.mjs` (change tag to `[assemble-brandbook]`). The sync variant (no `.catch`) is used by `generate-tokens-css.mjs` and `generate-specimens.mjs` for synchronous `main()`. Use the async+catch form if `assemble.mjs` needs any async file reads.

**FATAL error + `process.exit(1)` pattern** (`generate-logo-suite.mjs` lines 240–244):
```javascript
try {
  markResult = generate({ ... });
} catch (err) {
  console.error(`[generate-logo-suite] FATAL: generate() failed — ${err.message}`);
  process.exit(1);
}
```
Use the same `[tag] FATAL: <context> — <err.message>` string format for any failure in `assemble.mjs`.

**Inline SVG reading** (`size-matrix-qa.mjs` lines 141–142):
```javascript
const svgPath = path.join(LOGO_DIR, svgFile);
const svgContent = fs.readFileSync(svgPath, "utf-8");
```
Read SVG files as UTF-8 strings with `fs.readFileSync(..., "utf-8")`. When embedding inline in HTML, strip the `<?xml ...?>` declaration if present (SVGs committed by `generate-logo-suite.mjs` are already clean — no XML declaration) and insert directly into HTML body.

---

### `brandbook/harness/verify-brandbook.mjs` (verifier, file-I/O + Playwright)

**Primary analog for assertion/exit pattern:** `brandbook/tokens/harness/verify-specimens.mjs`
**Primary analog for Playwright usage:** `brandbook/logo/harness/size-matrix-qa.mjs`

#### Assertion / exit-code pattern (`verify-specimens.mjs` lines 55–68, 72–95, 172–182):

```javascript
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
```
Copy this `failures` counter + `assert()` + `assertContains()` helper trio into `verify-brandbook.mjs`. Change prefix to `[verify-brandbook]`.

**File-exists check before reading** (`verify-specimens.mjs` lines 89–96):
```javascript
assert(fs.existsSync(palettePath), "brandbook/examples/palette.svg exists");
// ... more existsSync checks ...
if (failures > 0) {
  console.error(`\n[verify-specimens] FAIL: ${failures} assertion(s) failed — SVG files missing`);
  process.exit(1);
}
```
Apply same early-exit pattern for `brandbook/index.html` existence check before reading it.

**Final result block** (`verify-specimens.mjs` lines 171–182):
```javascript
if (failures > 0) {
  console.error(`\n[verify-specimens] FAIL: ${failures} assertion(s) failed`);
  process.exit(1);
}

console.log(`[verify-specimens] OK: ...`);
// ... per-section OK lines ...
console.log("[verify-specimens] VERIFY_SPECIMENS_OK — SC#3 content coverage passed");
process.exit(0);
```
Use same structure: accumulate all failures, one final `if (failures > 0)` block, `process.exit(1)` on failure, explicit `process.exit(0)` on success. Use a machine-parseable terminal tag: `[verify-brandbook] VERIFY_BRANDBOOK_OK`.

**verify-tokens.mjs environment override** (`verify-tokens.mjs` lines 25–28):
```javascript
const CSS_PATH = process.env.CSS_PATH_OVERRIDE
  ? path.resolve(process.env.CSS_PATH_OVERRIDE)
  : path.resolve(__dirname, "../tokens.css");
```
Adopt same env-override pattern for `HTML_PATH_OVERRIDE` in `verify-brandbook.mjs` to allow testing against a fixture file.

#### Playwright browser/page pattern (`size-matrix-qa.mjs` lines 132–194):

**Browser launch and context creation** (lines 132–176):
```javascript
const browser = await chromium.launch({ headless: true });
// ...
const ctx = await browser.newContext({
  viewport: { width: tile.w, height: tile.h },
  deviceScaleFactor: tile.dpr,
});
const page = await ctx.newPage();
await page.goto(`file://${tmpHtml}`);
const pngBuffer = await page.screenshot({ fullPage: false });
await ctx.close();
```
`verify-brandbook.mjs` uses the same `chromium.launch({ headless: true })` + `browser.newContext({ viewport })` + `page.goto('file://...')` + `page.screenshot()` chain. Difference: use `browser.newPage()` with a viewport option set directly on the page instead of creating a context per-page (either form works; context-per-page is fine for the 4-screenshot matrix).

**Playwright import via explicit relative path** (RESEARCH.md lines 357–358 and the research recommendation):
```javascript
import { chromium } from "../../logo/harness/node_modules/playwright/index.js";
```
This avoids a second `npm install` in `brandbook/harness/`. Use this explicit relative path import. Note: `size-matrix-qa.mjs` imports from the bare `"playwright"` specifier because it lives inside the logo harness itself (the `package.json` there has `playwright` as a dep). `verify-brandbook.mjs` lives in a different directory (`brandbook/harness/`) with no `package.json`, so it must use the explicit relative path.

**`file://` navigation pattern** (`size-matrix-qa.mjs` line 171):
```javascript
await page.goto(`file://${tmpHtml}`);
```
For `verify-brandbook.mjs`, the `index.html` is a real committed file (not a temp file), so:
```javascript
const HTML_PATH = path.resolve(__dirname, "../index.html");
const FILE_URL  = `file://${HTML_PATH}`;
// ...
await page.goto(FILE_URL);
await page.waitForLoadState("domcontentloaded");
```
`waitForLoadState("domcontentloaded")` is correct for `file://` — `"networkidle"` works too but is redundant since there is no network on file://.

**Dark-mode attribute injection** (RESEARCH.md lines 378–380):
```javascript
if (ctx.theme === "dark") {
  await page.evaluate(() => { document.documentElement.dataset.theme = "dark"; });
}
```
This sets `data-theme="dark"` on `<html>` via JS after page load, which triggers the `:root[data-theme="dark"]` CSS block in `tokens.css`. Use this exact pattern (not `colorScheme: 'dark'` on browser context — that only affects `prefers-color-scheme`, which is less direct than setting the attribute the tokens.css already uses).

**Screenshot output path** (`size-matrix-qa.mjs` lines 33–37):
```javascript
const QA_SCREENSHOTS_DIR = path.resolve(
  __dirname,
  "../../../.planning/phases/183-logo-system-production/qa-screenshots"
);
```
For Phase 186, screenshots go to `.planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots/`. Analogous:
```javascript
const QA_SCREENSHOTS_DIR = path.resolve(
  __dirname,
  "../../.planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots"
);
```
(Two `..` from `brandbook/harness/` to repo root, then into `.planning/phases/186-.../qa-screenshots/`.)

**`mkdirSync` before writing screenshots** (`size-matrix-qa.mjs` line 123):
```javascript
fs.mkdirSync(QA_SCREENSHOTS_DIR, { recursive: true });
```
Copy verbatim.

**try/finally browser cleanup** (`size-matrix-qa.mjs` lines 138–194):
```javascript
try {
  for (const svgFile of allFiles) {
    // ... render loop ...
  }
} finally {
  await browser.close();
  fs.rmSync(tmpDir, { recursive: true, force: true });
}
```
Use the same `try/finally { await browser.close(); }` pattern so the browser always closes even on assertion failure.

**isMain guard (async form)** (`size-matrix-qa.mjs` lines 210–215):
```javascript
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error("[size-matrix-qa] FATAL:", err);
    process.exit(1);
  });
}
```
`verify-brandbook.mjs` has an async `main()` (Playwright), so use this async+catch form.

---

### `brandbook/harness/package.json` (config)

**Analog:** `brandbook/logo/harness/package.json` (lines 1–22)

```json
{
  "name": "accrue-logo-production-harness",
  "private": true,
  "type": "module",
  "scripts": {
    "generate": "node generate-logo-suite.mjs",
    "qa": "node size-matrix-qa.mjs"
  },
  "dependencies": {
    "playwright": "^1.59.1"
  }
}
```

**DECISION from RESEARCH.md (Open Question 2):** `brandbook/harness/` has **no npm deps** — Playwright is imported via explicit relative path from `../logo/harness/node_modules/playwright/index.js`. No `npm install` is needed. Therefore:

- If `brandbook/harness/package.json` is created at all, it has **zero `dependencies`** and only a `"scripts"` block pointing to the two scripts.
- The tokens harness `package.json` shows the minimal shape for a harness with only `"scripts"`:

```json
// brandbook/tokens/harness/package.json — shape when scripts are the only entry:
{
  "name": "accrue-tokens-harness",
  "private": true,
  "type": "module",
  "scripts": {
    "generate": "node generate-tokens-css.mjs",
    "verify":   "node verify-tokens.mjs",
    "specimens": "node generate-specimens.mjs",
    "verify-specimens": "node verify-specimens.mjs"
  },
  "dependencies": { ... }
}
```

For `brandbook/harness/package.json` copy the `"private": true, "type": "module"` shape with no `dependencies` block:
```json
{
  "name": "accrue-brandbook-harness",
  "private": true,
  "type": "module",
  "scripts": {
    "assemble": "node assemble.mjs",
    "verify":   "node verify-brandbook.mjs"
  }
}
```

---

### `brandbook/index.html` (output artifact)

No direct code analog exists — this is a hand-authored HTML file produced by `assemble.mjs`. The closest structural analogs are the specimen SVGs (committed output artifacts produced by a harness script) and the `buildHtmlPage()` helper in `size-matrix-qa.mjs`.

**HTML boilerplate shape** (`size-matrix-qa.mjs` lines 98–116 — `buildHtmlPage()`):
```javascript
function buildHtmlPage(svgContent, tile) {
  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: ${tile.bg}; ... }
  svg { max-width: 100%; max-height: 100%; display: block; }
</style>
</head>
<body>${svgContent}</body>
</html>`;
}
```
`assemble.mjs` builds a much larger HTML document using the same template-literal pattern. Key structural additions not in `buildHtmlPage()`: `<meta name="viewport" content="width=device-width, initial-scale=1">`, inline `<style>` block containing `tokens.css` content, `<html lang="en">`, `data-theme` attribute support, sticky TOC `<nav>`.

**Dark-mode toggle script** (RESEARCH.md lines 335–350):
```html
<script>
  (function() {
    var root = document.documentElement;
    var stored = localStorage.getItem('accrue-theme');
    var prefers = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    root.dataset.theme = stored || prefers;

    document.getElementById('theme-toggle').addEventListener('click', function() {
      var next = root.dataset.theme === 'dark' ? 'light' : 'dark';
      root.dataset.theme = next;
      localStorage.setItem('accrue-theme', next);
    });
  })();
</script>
```
This is the exact vanilla-JS toggle to embed at the bottom of `<body>`. No `import` statements, no npm deps. The IIFE form is correct (avoids polluting `window` with locals).

**Dark-mode token naming** (from `brandbook/tokens/tokens.css` — confirmed by RESEARCH.md):
```css
:root { /* light tokens: --accrue-surface-base, --accrue-content-primary, etc. */ }
:root[data-theme="dark"] { /* dark tokens: --accrue-dark-base, --accrue-dark-primary, etc. */ }
```
The dark block uses NEW variable names (`--accrue-dark-*`), NOT overrides of light names. `assemble.mjs` must generate brand-book CSS rules that reference `--accrue-dark-base` etc. in a `[data-theme="dark"]` scoped block — it must NOT assume light variable names auto-override.

---

## Shared Patterns

### isMain Guard
**Source:** All harness scripts (`size-matrix-qa.mjs` line 210, `generate-logo-suite.mjs` line 736, `verify-specimens.mjs` line 185, `generate-tokens-css.mjs` line 68 — sync variant)
**Apply to:** `assemble.mjs`, `verify-brandbook.mjs`
```javascript
// Async form (for scripts with await in main()):
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error("[script-name] FATAL:", err);
    process.exit(1);
  });
}

// Sync form (for fully synchronous main()):
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main();
}
```

### `__dirname` Idiom
**Source:** Every harness script, e.g. `generate-tokens-css.mjs` line 23
**Apply to:** `assemble.mjs`, `verify-brandbook.mjs`
```javascript
const __dirname = path.dirname(fileURLToPath(import.meta.url));
```
Required in every ESM script that uses `path.resolve(__dirname, ...)`. This replaces the CommonJS `__dirname` which does not exist in `"type": "module"` scripts.

### Sorted Determinism
**Source:** `generate-logo-suite.mjs` lines 126–127; `generate-tokens-css.mjs` `buildBlock()` sort call (line 33)
**Apply to:** `assemble.mjs` — any place where multiple files are read from a directory
```javascript
const files = fs.readdirSync(dir).filter(f => f.endsWith(".svg"));
files.sort(); // Lexicographic — guarantees deterministic output across runs
```

### Failure Counter + `process.exit` Contract
**Source:** `verify-specimens.mjs` lines 55–68 + 171–182; `verify-tokens.mjs` lines 85–119
**Apply to:** `verify-brandbook.mjs`
```javascript
let failures = 0;
// ... assertions increment failures ...
if (failures > 0) {
  console.error(`\n[verify-brandbook] FAIL — ${failures} check(s) failed`);
  process.exit(1);
}
console.log("[verify-brandbook] VERIFY_BRANDBOOK_OK");
process.exit(0);
```
The explicit `process.exit(0)` at the end (not just falling off) mirrors the `verify-tokens.mjs` line 119 pattern and makes CI exit-code interpretation unambiguous.

### Console Log Prefix Convention
**Source:** All harness scripts
**Apply to:** `assemble.mjs`, `verify-brandbook.mjs`

Every `console.log` / `console.error` / `console.warn` line begins with `[script-name]`:
- `[assemble-brandbook]` for `assemble.mjs`
- `[verify-brandbook]` for `verify-brandbook.mjs`

FATAL errors: `[tag] FATAL: <what failed> — <err.message>`
OK lines: `[tag] OK — <what was verified>`
Wrote lines: `[tag] Wrote: <filename>`

---

## No Analog Found

No files in this phase lack analogs. All four new files have concrete harness analogs in `brandbook/*/harness/`.

---

## Key Pattern Decisions

1. **`assemble.mjs` has no npm deps.** Read all inputs with `fs.readFileSync`. Build HTML with template literals + array joins. Write with `fs.writeFileSync`. Mirrors `generate-tokens-css.mjs` exactly.

2. **Playwright import in `verify-brandbook.mjs` uses an explicit relative path** (`../../logo/harness/node_modules/playwright/index.js`), not a bare `"playwright"` specifier. This avoids a second `npm install` and is safe since the Playwright version (`^1.59.1`) in the logo harness is already confirmed working.

3. **Dark-mode in Playwright is set via `page.evaluate`** (set `document.documentElement.dataset.theme = "dark"` after `page.goto`) not via `colorScheme: 'dark'` in browser context options. The `data-theme` attribute is what `tokens.css` selectors actually key on.

4. **QA screenshots go to `.planning/phases/186-.../qa-screenshots/`**, not `brandbook/` — consistent with the Phase 183 `size-matrix-qa.mjs` pattern (exploration artifacts in `.planning/`, not in committed source dirs).

5. **`brandbook/harness/package.json` has zero `dependencies`** — it only contains `"scripts"` entries. The `"type": "module"` and `"private": true` fields are mandatory (mirrors both logo and tokens harness `package.json`).

6. **Markdown rendering in `assemble.mjs` is Option B (inline regex converter)** — no `marked` or other npm dep. The RESEARCH.md identifies exactly 6 Markdown constructs used in `voice.md`/`copy.md`: `##`/`###` headings, `| table |` rows, code fences, `**bold**`, `*italic*`, and `-` bullets. An ~80-line purpose-built converter is sufficient and keeps the harness dep-free.

---

## Metadata

**Analog search scope:** `brandbook/logo/harness/`, `brandbook/tokens/harness/`
**Files read:** `size-matrix-qa.mjs`, `generate-logo-suite.mjs`, `generate-tokens-css.mjs`, `generate-specimens.mjs`, `verify-tokens.mjs`, `verify-specimens.mjs`, `parity-check.mjs`, `brandbook/logo/harness/package.json`, `brandbook/tokens/harness/package.json`
**Pattern extraction date:** 2026-06-14
