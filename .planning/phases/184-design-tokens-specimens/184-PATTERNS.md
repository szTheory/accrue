# Phase 184: Design Tokens & Specimens - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 11 new/modified
**Analogs found:** 10 / 11 (1 new-but-precedented: the CI gate has shape-analogs only, no existing brandbook CI wiring)

> **Critical orientation:** Phase 184 deliberately mirrors `brandbook/logo/harness/` (Phases 181-183).
> That harness is the single strongest analog for **every** new file: committed `.mjs` + `package.json` +
> `package-lock.json`, `node_modules` gitignored (repo-root rule), `svgo.config.mjs` for byte-stable SVG,
> deterministic emit, `--test` smoke gates, and an `isMain` guard. The new tokens harness is the *lean*
> sibling: pure-JS deps only (`postcss`, `postcss-value-parser`, `culori`) — NO native-build deps
> (`@resvg/resvg-js`, `playwright`, `wawoff2`) that the logo harness carries.
>
> **Notable gap:** the logo harness is **NOT wired into any CI workflow today** (`grep brandbook .github/workflows/`
> = zero hits). So there is no existing "regenerate brandbook + git diff --exit-code" CI step to copy
> verbatim. The CI gate (file 11) is genuinely new; its *shape* analogs are
> `.github/workflows/ci.yml:392-396` (Elixir asset determinism gate) for the `git diff --exit-code` step and
> `ci.yml:457-478` for the `setup-node@v6` + `npm ci` pattern.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `brandbook/tokens/tokens.json` | config (DTCG SSOT) | transform-source | (no in-repo DTCG analog) — RESEARCH skeleton | partial |
| `brandbook/tokens/tokens.css` | config (generated) | transform-output | `brandbook/logo/*.svg` (generated, gated) | role-match |
| `brandbook/tokens/harness/package.json` | config | — | `brandbook/logo/harness/package.json` | exact |
| `brandbook/tokens/harness/package-lock.json` | config | — | `brandbook/logo/harness/package-lock.json` | exact |
| `brandbook/tokens/harness/lib.mjs` | utility | transform | `brandbook/logo/harness/geist-spine-mono.mjs` (pure-ESM lib + `--test`) | role-match |
| `brandbook/tokens/harness/generate-tokens-css.mjs` | utility (generator) | transform (JSON→CSS) | `brandbook/logo/harness/generate-logo-suite.mjs` | role-match |
| `brandbook/tokens/harness/parity-check.mjs` | test/verifier | request-response (read→AST→exit code) | `geist-spine-mono.mjs` (`--test` exit-code) + `ico-packer.mjs --test` | role-match |
| specimen generator `.mjs` (palette/typography/spacing) | utility (generator) | transform (JSON→SVG) | `brandbook/logo/harness/generate-logo-suite.mjs` | exact |
| `brandbook/examples/{palette,typography,spacing}.svg` | config (generated artifact) | transform-output | `brandbook/logo/*.svg` | exact |
| `.gitignore` | config | — | repo-root `.gitignore:23` (`node_modules/`) | exact (already covers it) |
| CI workflow step (regen + `git diff --exit-code` + parity) | config (CI) | — | `ci.yml:392-396` (diff gate) + `ci.yml:457-478` (node setup) | role-match (shape only) |

---

## Pattern Assignments

### `brandbook/tokens/harness/package.json` (config)

**Analog:** `brandbook/logo/harness/package.json` (read in full, 22 lines)

**Copy this shape exactly** — `private`, `type: "module"`, a `scripts` block per pipeline command, a `dependencies` block. Strip the native-build deps; keep only the three pure-JS ones from RESEARCH.

Logo harness (`brandbook/logo/harness/package.json:1-22`):
```json
{
  "name": "accrue-logo-production-harness",
  "private": true,
  "type": "module",
  "scripts": {
    "generate": "node generate-logo-suite.mjs",
    "rasters": "node generate-rasters.mjs",
    "qa": "node size-matrix-qa.mjs",
    "ico-test": "node ico-packer.mjs --test",
    "spine-test": "node geist-spine-mono.mjs --test"
  },
  "dependencies": {
    "@resvg/resvg-js": "^2.6.0",
    "@xmldom/xmldom": "^0.9.0",
    "geist": "^1.7.2",
    "opentype.js": "^2.0.0",
    "playwright": "^1.59.1",
    "pngjs": "^7.0.0",
    "svgo": "^4.0.1",
    "wawoff2": "^2.0.1"
  }
}
```

**Tokens harness target shape** (per D-16 + RESEARCH "Validation Architecture" scripts table):
```json
{
  "name": "accrue-tokens-harness",
  "private": true,
  "type": "module",
  "scripts": {
    "generate": "node generate-tokens-css.mjs",
    "specimens": "node generate-specimens.mjs",
    "parity": "node parity-check.mjs",
    "parity-test": "node parity-check.mjs --test"
  },
  "dependencies": {
    "postcss": "^8.5.15",
    "postcss-value-parser": "^4.2.0",
    "culori": "^4.0.2"
  }
}
```
> Add `svgo` (`^4.0.1`) to deps ONLY if specimens are run through `svgo.config.mjs` (recommended for byte-stable SVG diff). Add `geist` + `opentype.js` ONLY if the type specimen embeds glyph outlines (RESEARCH recommends NOT — use `<text font-family>` labels).

---

### `brandbook/tokens/harness/package-lock.json` (config)

**Analog:** `brandbook/logo/harness/package-lock.json` (49 KB committed lockfile)

**Pattern:** the lockfile is **committed** (not gitignored) and reinstalled in CI. Generated by `npm install` in the harness dir. This is the load-bearing half of the D-17 determinism contract — `npm ci` in CI consumes it. Per RESEARCH "Package Legitimacy Audit", the planner **must gate the `npm install` that creates this file behind a `checkpoint:human-verify` task** (slopcheck was unavailable; all three deps are `[ASSUMED]` legit).

---

### `brandbook/tokens/harness/lib.mjs` (utility — shared helpers)

**Analog:** `brandbook/logo/harness/geist-spine-mono.mjs` (read in full, 169 lines) — the canonical "pure-ESM library module with exports + a `--test` smoke main behind an `isMain` guard".

**Pure-ESM module header + `__dirname` pattern** (`geist-spine-mono.mjs:16-21`):
```js
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import opentype from "opentype.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
```

**Exported-helpers + throw-on-failure pattern** (never return silent `undefined`) (`geist-spine-mono.mjs:38-56`):
```js
export async function loadGeistMonoFont() {
  const ttfPath = path.join(__dirname, "node_modules/geist/dist/fonts/geist-mono/GeistMono-Regular.ttf");
  try {
    if (!fs.existsSync(ttfPath)) {
      throw new Error(`TTF not found at: ${ttfPath}`);
    }
    const buf = fs.readFileSync(ttfPath);
    return opentype.parse(buf.buffer);
  } catch (err) {
    throw new Error(`[geist-spine-mono] Failed to load Geist Mono Regular font: ${err.message}`);
  }
}
```
> Apply this throw-don't-return-undefined discipline to `lib.mjs`'s `resolveColor()` — RESEARCH Pitfall 1 (culori returns `undefined` for `color-mix()`) means a silent undefined would make the parity check falsely pass. Throw a clear error on any unresolved color.

**`isMain` guard + `--test` smoke main** (`geist-spine-mono.mjs:127-169`) — copy this exact shape for any `lib.mjs` self-test:
```js
async function main() {
  // ... run the helper, assert a sane result ...
  if (/* failure */) {
    console.error("[geist-spine-mono] smoke: FAIL — ...");
    process.exit(1);
  }
  console.log("[geist-spine-mono] smoke: OK");
  process.exit(0);
}

// isMain guard — prevents pipeline execution when imported as a module
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.includes("--test")) {
    main().catch((err) => {
      console.error("[geist-spine-mono] FATAL:", err);
      process.exit(1);
    });
  }
}
```

`lib.mjs` should export: `flattenTokens(json)`, `deriveCssVar(pathSegs)`, `resolveColor(raw, vars, brandRaw)` (var + color-mix + culori `formatHex` normalize), `iterAxMappedTokens(json)` — imported by the generator, parity check, AND specimens (RESEARCH "Component Responsibilities").

---

### `brandbook/tokens/harness/generate-tokens-css.mjs` (utility — generator)

**Analog:** `brandbook/logo/harness/generate-logo-suite.mjs` (read lines 1-202) — the deterministic-emit orchestrator.

**OUTPUT_DIR relative to harness** (`generate-logo-suite.mjs:41,56`):
```js
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = path.resolve(__dirname, "../");   // emit one dir up from harness/
```
> For tokens: write `tokens.css` to `path.resolve(__dirname, "../tokens.css")` (one dir up, into `brandbook/tokens/`). Read source from `path.resolve(__dirname, "../tokens.json")`.

**Determinism contract** (RESEARCH Pitfall 5 + D-17): sort keys with a stable comparator before emit, `\n` line endings, exactly one trailing newline. The RESEARCH "generate-tokens-css.mjs" code example (184-RESEARCH.md:356-398) is the authoritative skeleton — `flatten` → `rows.sort((a,b)=>a.cssVar.localeCompare(b.cssVar))` → `:root{…}\n`. Read `$value.hex` for colors (DTCG 2025.10 object shape, NOT bare string — Pitfall 4).

**Generated-file banner** (mirror the logo suite's "do not edit" intent; RESEARCH example line 395):
```js
const css = `/* GENERATED from tokens.json — do not edit. Run: npm run generate */\n:root {\n${body}\n}\n`;
```
> Emit a second `:root[data-theme="dark"] { … }` block from dark `$value` overrides (BRAND-AUDIT §7 requires dark counterparts; RESEARCH Open Question 2 recommends a parallel `color.dark.*` group). Same sort. Add `/* brand-only: no --ax-* counterpart */` notes for `axMap:null` tokens (D-09b).

---

### `brandbook/tokens/harness/parity-check.mjs` (test/verifier)

**Analog:** `geist-spine-mono.mjs` (`--test` exit-code pattern, lines 127-169) for the exit-code/`--test` shape; `ico-packer.mjs --test` (referenced in `package.json:9`) for the same convention. The *parsing/color* logic has no in-repo analog — it comes from the RESEARCH "parity-check.mjs" verified pipeline (184-RESEARCH.md:400-474).

**Exit-code contract** (D-08) — same `process.exit(0|1)` discipline as the logo `--test` mains:
```js
process.exit(failures === 0 ? 0 : 1);   // 0 = all match/documented, non-zero = undocumented drift
```

**Input shape (theme.css scopes)** — the parity target. theme.css is scoped to `html.accrue-admin`, NOT `:root` (RESEARCH Pitfall 3). Build per-scope decl maps with `postcss.parse → walkRules → walkDecls(/^--/)`. The three scopes to read:
- **Light:** `html.accrue-admin` (`accrue_admin/assets/css/theme.css:12`) — semantic roles bind via `var(--accrue-*)`:
  ```css
  --ax-base: var(--accrue-paper);     /* :105 */
  --ax-primary: var(--accrue-ink);    /* :108 */
  --ax-subtle: var(--accrue-slate);   /* :110 */
  --ax-success: var(--accrue-moss);   /* :113 */
  --ax-warning: var(--accrue-amber);  /* :115 */
  --ax-elevated: #ffffff;             /* :106 — standalone hex */
  --ax-sunken: #f1f5f8;               /* :107 */
  --ax-danger: #d64b4b;               /* :117 */
  --ax-info: #3878a6;                 /* :125 */
  --ax-focus-ring: color-mix(in oklch, var(--ax-accent) 70%, white);  /* :141 — NOT brand-mapped, skip */
  ```
- **Dark:** `html.accrue-admin[data-theme="dark"]` (`theme.css:145`) — standalone hexes, value-to-value:
  ```css
  --ax-base: #0f1318;     /* :146 */
  --ax-elevated: #171d24; /* :147 */
  --ax-primary: #f4f7fa;  /* :149 */
  --ax-subtle: #d7dde3;   /* :151 */
  ```
- **System dark** (`@media (prefers-color-scheme: dark) html.accrue-admin[data-theme="system"]`, `theme.css:164-183`) carries **identical** values to the `[data-theme="dark"]` block — pick one consistently (RESEARCH A4; `[data-theme="dark"]` is simplest).

**Key resolution facts** (from theme.css read):
- The raw `--accrue-*` tokens are **NOT defined anywhere in theme.css** (only referenced). The parity check resolves `var(--accrue-paper)` etc. against the brandbook's OWN `tokens.json` raw palette (`brandRaw` map). This is GAP-C2 — `tokens.css` is what completes the cascade (CONTEXT.md:105).
- `color-mix()` only appears on tokens that are NOT in the D-09 brand-mapped set (`--ax-danger-surface`, `--ax-accent-*`, `--ax-focus-ring`). The parity hot path is pure hex/var resolution. Implement the `interpolate`-based color-mix evaluator anyway for robustness (RESEARCH Pitfall 1+2), but it should never fire on a brand-mapped token today.

**`--test` injected-drift fixture mode** (RESEARCH "How the parity check ITSELF is tested", lines 569-580) — this is SC#2's proof, both directions: copy theme.css to temp, mutate one ax-mapped value, assert non-zero; then add a matching `$extensions.divergesFrom + reason` and assert zero. Mirror the logo harness `--test` smoke convention (`package.json` `*-test` scripts).

---

### specimen generator `.mjs` → `examples/{palette,typography,spacing}.svg` (utility → generated artifact)

**Analog:** `brandbook/logo/harness/generate-logo-suite.mjs` — EXACT analog for "read source → emit deterministic standalone `<svg>` with `<title>`/`<desc>` → optionally svgo → write".

**`<title>`/`<desc>` injection then svgo** (`generate-logo-suite.mjs:135-152`):
```js
function injectMeta(svgString, key) {
  const meta = SVG_META[key];
  if (!meta) throw new Error(`No SVG_META entry for key: ${key}`);
  const titleDesc = `<title>${meta.title}</title><desc>${meta.desc}</desc>`;
  return svgString.replace(/(<svg[^>]*>)/, `$1${titleDesc}`);
}
function svgoOptimize(svgString) {
  const result = optimize(svgString, svgoConfig);
  return result.data;
}
```

**svgo + config import** (`generate-logo-suite.mjs:62-63`):
```js
import { optimize } from "svgo";
import svgoConfig from "./svgo.config.mjs";
```

**Background-rect for dark surfaces** (palette.svg needs both light AND dark bands per D-15) — `addBgRect` (`generate-logo-suite.mjs:169-179`):
```js
function addBgRect(svgString, color) {
  const vbMatch = svgString.match(/viewBox="([^"]+)"/);
  if (!vbMatch) return svgString;
  const [, , , w, h] = vbMatch[1].split(/\s+/).map(Number);
  if (!w || !h) return svgString;
  const bgRect = `<rect width="${w}" height="${h}" fill="${color}"/>`;
  return svgString.replace(/(<\/(?:title|desc)>)/, `$1${bgRect}`);
}
```

**write helper** (`generate-logo-suite.mjs:158-162`):
```js
function writeSvg(filename, svgString) {
  const outPath = path.join(OUTPUT_DIR, filename);
  fs.writeFileSync(outPath, svgString, "utf8");
  console.log(`[generate-logo-suite] Wrote: ${filename}`);
}
```
> For specimens, `OUTPUT_DIR` resolves to `brandbook/examples/` — i.e. `path.resolve(__dirname, "../../examples")` if the harness stays at `brandbook/tokens/harness/`. The RESEARCH specimen skeleton (184-RESEARCH.md:476-495) gives the per-swatch `<g>/<rect>/<text>` shape; use `<text font-family="Geist, system-ui">` labels (NOT opentype.js outlines — RESEARCH Discretion). AA annotations MUST come from `contrast-table.txt` rows (Pitfall 6): Moss/Cobalt/Amber FAIL AA-body on light.

---

### `brandbook/examples/{palette,typography,spacing}.svg` (generated artifacts)

**Analog:** `brandbook/logo/*.svg` (13 committed, gated artifacts). **Directory does not exist yet** — `brandbook/examples/` must be created. These are committed and `git diff --exit-code`-gated exactly like the logo SVGs.

---

### `.gitignore` (MODIFIED — likely no-op)

**Analog:** repo-root `.gitignore:23`:
```
node_modules/
```

**Pattern:** the repo-root rule **already covers** `brandbook/tokens/harness/node_modules/` (verified — RESEARCH "Runtime State Inventory"). The logo harness has **no local `.gitignore`** (verified: `brandbook/logo/harness/.gitignore` does not exist) and relies on the root rule. **Follow the same convention: do NOT add a local `.gitignore`** unless the planner wants belt-and-suspenders. If anything, this file is unmodified — flag it as "already satisfied".

---

### CI workflow step — regenerate + `git diff --exit-code` + parity (MODIFIED — NEW gate)

**No existing brandbook CI wiring** (`grep brandbook .github/workflows/` = 0 hits). The logo harness is run locally only. This gate is new; two shape-analogs to copy from:

**(a) `git diff --exit-code` determinism gate** — `accrue_admin_assets.yml:29-30` and identically `ci.yml:392-396`:
```yaml
      - name: Ensure committed bundle is fresh
        run: git diff --exit-code -- accrue_admin/priv/static/accrue_admin.css accrue_admin/priv/static/accrue_admin.js
```
> Tokens equivalent: `git diff --exit-code -- brandbook/tokens/tokens.css brandbook/examples/*.svg` AFTER `npm run generate && npm run specimens`.

**(b) Node setup + `npm ci`** — `ci.yml:457-478`:
```yaml
      - name: Set up Node
        uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: npm
          cache-dependency-path: examples/accrue_host/package-lock.json
      # ...
      - name: Install browser deps
        run: |
          cd examples/accrue_host && npm ci
```
> Tokens equivalent: `setup-node@v6`, `node-version: '22'`, `cache-dependency-path: brandbook/tokens/harness/package-lock.json`, then `cd brandbook/tokens/harness && npm ci`.

**Recommended CI home:** add steps to the **`docs-contracts-shift-left`** job (`ci.yml:31`), which already aggregates bash/doc contract gates and has no native deps. The full gate (from RESEARCH "Full suite command", line 560):
```yaml
      - name: Regenerate tokens + specimens (determinism gate, D-17)
        run: |
          cd brandbook/tokens/harness
          npm ci
          npm run generate
          npm run specimens
      - name: Tokens/specimens are reproducible
        run: git diff --exit-code -- brandbook/tokens/tokens.css brandbook/examples/palette.svg brandbook/examples/typography.svg brandbook/examples/spacing.svg
      - name: Brand↔admin token parity (SC#2)
        run: cd brandbook/tokens/harness && node parity-check.mjs
```
> Two distinct gates (D-17): the `git diff --exit-code` proves *reproducibility*; `parity-check.mjs` proves *correctness*. Also wire `npm run parity-test` (the `--test` injected-drift fixture) to prove SC#2 both directions.

---

## Shared Patterns

### Deterministic emit (applies to: generate-tokens-css.mjs, all 3 specimen generators)
**Source:** `brandbook/logo/harness/generate-logo-suite.mjs` + `svgo.config.mjs` (RESEARCH Pitfall 5)
- Sort all key/token iteration with a stable comparator (`localeCompare`) before emit.
- `\n` line endings; exactly one trailing newline.
- Round computed numbers to fixed decimals (`.toFixed(3)` is the logo-suite convention, e.g. `generate-logo-suite.mjs:406`).
- If running specimens through svgo, reuse `svgo.config.mjs` verbatim (multipass, preserves `viewBox`/`<title>`/`<desc>`).

### svgo.config.mjs (applies to: specimen generators, IF optimizing)
**Source:** `brandbook/logo/harness/svgo.config.mjs:13-34` — copy verbatim. Preserves `viewBox`, `<title>`, `<desc>` (accessibility); `multipass: true` for byte-stability:
```js
export default {
  multipass: true,
  plugins: [
    "removeDoctype", "removeXMLProcInst", "removeComments", "removeMetadata",
    "removeEditorsNSData", "cleanupAttrs", "removeNonInheritableGroupAttrs",
    "removeUselessStrokeAndFill", "cleanupNumericValues", "collapseGroups",
    "convertPathData", "convertTransform", "removeEmptyAttrs",
    "removeEmptyContainers", "mergePaths", "sortAttrs", "cleanupIds",
  ],
};
```

### `--test` smoke + `isMain` guard (applies to: lib.mjs, parity-check.mjs)
**Source:** `geist-spine-mono.mjs:127-169` (full pattern shown above under lib.mjs). Every harness `.mjs` that is both importable and runnable uses `if (process.argv[1] === fileURLToPath(import.meta.url))` to avoid executing on import, and a `--test` flag for the smoke gate. Mirrored in `package.json` `*-test` scripts.

### Committed-script + committed-lockfile + gitignored-node_modules (applies to: whole harness)
**Source:** `brandbook/logo/harness/` directory layout (`.mjs` + `package.json` + `package-lock.json` committed; `node_modules/` ignored via repo-root `.gitignore:23`). This IS the D-17 determinism convention. No local `.gitignore` in the logo harness — rely on the root rule.

### Throw-don't-return-undefined on resolution failure (applies to: lib.mjs resolveColor, parity-check)
**Source:** `geist-spine-mono.mjs:45-55` (throw on missing font). Load-bearing for parity correctness: RESEARCH Pitfall 1 (culori returns `undefined` for `color-mix()`) means a silent undefined makes drift falsely pass. Always `throw new Error("unresolved …")`; never compare an `undefined`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `brandbook/tokens/tokens.json` | DTCG config | transform-source | No existing DTCG-format token file in the repo. The authoritative skeleton is 184-RESEARCH.md:296-354 (DTCG 2025.10 object-shaped `$value`, `$extensions["org.accrue.ax"]`). Values from BRAND-AUDIT §7 / BRAND-DNA §Palette. `code-block`/`callout` values are net-new (D-09b, RESEARCH Open Question 1 — flag for ratification). |

> Partial-only: `parity-check.mjs` and `lib.mjs` color/CSS-AST logic has NO in-repo precedent — it is entirely new (postcss + culori). Only their *file structure* (`--test`, exit-code, isMain, throw-on-fail) is analog-backed. Use the verified RESEARCH pipeline (184-RESEARCH.md:400-474, "all calls verified in-session") as the implementation source.

---

## Metadata

**Analog search scope:** `brandbook/logo/harness/`, `brandbook/`, `accrue_admin/assets/css/theme.css`, `.github/workflows/`, repo-root `.gitignore`
**Files scanned:** 8 read in full or in targeted ranges (logo harness package.json, svgo.config.mjs, geist-spine-mono.mjs, generate-logo-suite.mjs §1-202; theme.css §12-194; ci.yml §30-74, §370-489; accrue_admin_assets.yml full)
**Pattern extraction date:** 2026-06-13
