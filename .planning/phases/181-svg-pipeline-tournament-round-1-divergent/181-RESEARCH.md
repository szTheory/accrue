# Phase 181: SVG Pipeline + Tournament Round 1 — Divergent - Research

**Researched:** 2026-06-11
**Domain:** Node.js SVG generation pipeline — opentype.js font outline extraction, parametric logo generation, Playwright screenshot harness, pixel-heuristic legibility linting, self-contained HTML gallery
**Confidence:** HIGH (primary tool APIs verified via official docs; package versions confirmed via npm registry; environment state verified locally)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Per-direction mini-generators (hybrid parametric). Each of the 4 directions gets its own small Node geometry module with 3–4 knobs; each candidate is a config of knobs. Shared across directions: opentype.js Geist spine, lockup assembly, lint suite, renderer.
- **D-02:** Direction D (integrated typemarks) additionally gets bespoke glyph-outline surgery on the extracted Geist paths (the `cc` pair as echoed layers, stepped `e` crossbar, `u` as filling interval). Its generator is thinner; hand-work is expected there.
- **D-03:** Rationale on record: Phase 182 variation rounds sweep exactly the dimensions the parametric model exposes — variations become parameter re-renders, not path surgery.
- **D-04:** Overgenerate and cull. Generate ~20–24 raw candidates, run pre-gate lints + agent self-scoring as one deterministic pass, cull to the best 12–16 that pass. Lint failures are culled, never repaired in-loop.
- **D-05:** Per-direction floor: ≥3 candidates per direction in the final gallery. If a direction drops below the floor after culling, do capped targeted regeneration for that direction only (no unbounded retries).
- **D-06:** Rejected/culled candidates are preserved with their failure/score reasons in a `rejected/` area within the phase artifacts.
- **D-07:** Split judge. The 16px legibility pre-gate lint is a deterministic pixel heuristic: decode the 16px Playwright PNG (pngjs) and fail on measurable proxies — fg/bg contrast ratio below threshold, connected-component/distinct-feature count outside band, edge-density collapse vs the 32px render. No API key, reproducible, CI-safe.
- **D-08:** The pre-checkpoint self-review is agent vision against a fixed rubric: the executing agent Reads every context-matrix screenshot and scores each candidate on legibility, monochrome survival, avatar-crop integrity, brand fit — using the 0–3 score / pass-≥2 / NDJSON conventions from `accrue_admin/e2e/score-visuals.mjs` but WITHOUT the API dependency.
- **D-09:** Uniform LLM judging of the gate was rejected: nondeterministic hard gate breaks the "reproducible harness" contract.
- **D-10:** Interactive gallery. `round-1-gallery.html` includes lightweight vanilla JS (~60 lines, no deps, still file://-openable): per-candidate winner checkbox + keep/change note textareas + a "copy verdict block" button that emits a structured markdown block.
- **D-11:** The emitted verdict block and the `TOURNAMENT.md` round-1 entry share one schema: round heading + date; `**Winners:**` ID list; explicit `**Killed:**` ID list; per-winner `### {ID}` sections with verbatim keep/change quotes; then a separate `### Constraints` section with stable `R1-C{n}` IDs.
- **D-12:** The constraint IDs (`R{round}-C{n}`) are the handles Phase 182 uses for the monotonic never-re-litigate invariant.

### Claude's Discretion

- Exact knob set per direction generator and module layout of the harness.
- Pixel-heuristic thresholds for the 16px lint (tune to avoid false-fails on intentionally minimal marks); exact lockup gap-ratio spec value.
- Geist sourcing: fetch TTF from `vercel/geist` (SIL OFL 1.1) as primary; fallback converting in-repo `accrue_admin/priv/static/fonts/geist-sans-vf.woff2` → TTF via wawoff2 (per design source).
- Exact location of the harness, gallery, screenshots, and `TOURNAMENT.md` within `.planning/`.
- Plan breakdown (~5 plans per design source: Wave 1 pipeline; Waves 2–3 generation; gallery + checkpoint).

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOGO-01 | A reproducible SVG generation pipeline emits exact Geist letterform outlines (opentype.js, one path per glyph) and runs automated pre-gate lints — valid SVG parse, no-rect-background, lockup gap ratio within spec, 16px legibility screenshot, monochrome derivable, no subtitle in main lockup — before any candidate reaches the user. | opentype.js 2.0.0 API verified; Playwright screenshot harness documented; pngjs pixel heuristics documented; lint algorithms specified below |
| LOGO-02 | User picks 1–3 round-1 winners from a self-contained, file://-openable HTML gallery of 12–16 candidates across 4 conceptual directions, each rendered in a fixed context matrix. | file:// secure context confirmed; clipboard API availability confirmed with fallback; gallery HTML pattern documented |

</phase_requirements>

---

## Summary

Phase 181 is a pure Node.js artifact-generation phase: it builds a harness that extracts exact Geist letterform outlines using opentype.js, generates 12–16 SVG logo candidates across 4 parametric directions, runs automated pre-gate lints (including Playwright screenshot-based 16px legibility checks), and assembles a self-contained HTML gallery for a user-judged checkpoint.

The primary technical question was opentype.js 2.0.0 API correctness. Version 2.0.0 was published 2026-05-06 and introduces variable font support via a `VariationManager`, but has a known y-axis double-flip issue when using `font.getPath()` then `path.toPathData()` together — because both stages attempt the SVG coordinate inversion. The correct workaround is to call `path.toPathData({ flipY: false })` after `font.getPath()` (which already flips coordinates internally). Alternatively, use `Glyph.getPath()` directly and pass `flipY: true` at the `toPathData()` stage.

The Geist font sourcing question is resolved: the `geist` npm package (v1.7.2, Vercel, SIL OFL 1.1) includes static TTF instances at `dist/fonts/geist-sans/` for all 9 weights including Regular and Medium. Loading `GeistSans-Regular.ttf` via `fs.readFileSync` + `opentype.parse(buffer)` gives a static instance opentype.js can read without variable font axis juggling. This is simpler and more reliable than the variable font path. The wawoff2 fallback (decompress in-repo woff2 → TTF buffer) remains available if the npm TTF path fails.

Playwright 1.59.1 is already installed in `accrue_admin/node_modules` and Chromium binaries exist at `~/Library/Caches/ms-playwright/chromium-1223`. The standalone script pattern (no test runner) using `const { chromium } = require('playwright')` + `browser.newContext({ viewport, deviceScaleFactor })` + `page.goto('file://' + absPath)` + `page.locator(selector).screenshot()` is the correct approach. This requires `playwright` (not `@playwright/test`) — verify the bare `playwright` package is installed in accrue_admin.

**Primary recommendation:** Use `opentype.js` 2.0.0 with static Geist TTF instances (from `geist` npm package or fallback via wawoff2), standalone Playwright screenshot for 16px/32px renders, pngjs for pixel heuristics, and a pure HTML/JS gallery with `navigator.clipboard.writeText()` (file:// is a secure context per W3C spec — confirmed).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Geist outline extraction | Node.js script (harness) | — | opentype.js is a Node module; font math lives entirely in the harness, never in the browser |
| SVG generation (per-direction) | Node.js script (generator modules) | — | Parametric geometry logic produces SVG strings; no browser needed |
| Pre-gate linting (parse, rect-bg, gap, subtitle) | Node.js script (lint suite) | — | Pure string/DOM analysis; @xmldom/xmldom for parse in Node |
| 16px legibility lint (pixel heuristic) | Node.js script → Playwright → pngjs | Chromium browser (subprocess) | Playwright launches headless Chromium to render SVG at exact px; pngjs decodes the PNG buffer in Node |
| Context-matrix screenshots | Node.js script → Playwright | Chromium browser (subprocess) | Same Playwright harness renders each candidate in every context tile |
| Agent self-review | Agent vision (reads PNG files) | — | No API call; agent's built-in vision scores rubric dimensions |
| Gallery rendering | Static HTML (file://) | — | Pure HTML with inlined SVGs; no server, no build step |
| Verdict capture | Browser (vanilla JS in gallery) | — | Clipboard write + select-on-click pre fallback |
| TOURNAMENT.md append | Agent file write | — | Agent appends user's pasted verdict block verbatim |

---

## Standard Stack

### Core (new `package.json` for the harness — separate from accrue_admin e2e)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `opentype.js` | `^2.0.0` | Font parsing; per-glyph path extraction | Only production-ready JS font parser with full path extraction API; 2.0.0 adds variable font support [VERIFIED: npm registry + opentypejs/opentype.js GitHub] |
| `pngjs` | `^7.0.0` | PNG decode for pixel heuristics | Synchronous read API; used in the existing Playwright ecosystem; pure JS, no native binaries [VERIFIED: npm registry] |
| `svgo` | `^4.0.1` | SVG optimization (path cleanup, decimal precision) | Ecosystem standard for SVG optimization; used in most SVG toolchains [VERIFIED: npm registry] |
| `geist` | `^1.7.2` | Geist font TTF static instances (SIL OFL 1.1) | Official Vercel package; includes `dist/fonts/geist-sans/GeistSans-Regular.ttf` etc. [VERIFIED: npm registry + deepwiki.com/vercel/geist-font] |
| `wawoff2` | `^2.0.1` | WOFF2 → TTF decompression (fallback only) | WebAssembly build of Google's woff2 utility; works in Node without native rebuild [VERIFIED: npm registry + fontello/wawoff2 GitHub] |

### Supporting (already in accrue_admin node_modules — reuse, do not re-install)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `playwright` | `^1.59.1` (installed) | Headless Chromium screenshots | 16px/32px legibility lint + context-matrix rendering; bare `playwright` package needed (not just `@playwright/test`) |
| `@playwright/test` | `^1.59.1` (installed) | Chromium binary distribution | Binary already present at `~/Library/Caches/ms-playwright/chromium-1223` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `geist` npm TTF | In-repo woff2 + wawoff2 decompress | TTF from npm is simpler (no async decompress step); woff2 fallback if npm install fails |
| `opentype.js` static TTF | Variable font + `font.variation.set()` | Variable font VariationManager API is documented but issue #722 confirms it's buggy in 1.3.4 and insufficiently documented in 2.0.0; static TTF instances are reliable and produce identical outlines to the Regular named instance |
| `pngjs` | `sharp` or `jimp` | pngjs is synchronous, zero native deps, fits a lint script; sharp is faster but requires native binaries (CI footgun) |
| `svgo` | Hand-written path serialization | svgo handles decimal precision, redundant commands, and path data normalization — all needed for clean final SVG output |
| Playwright standalone | `puppeteer` | Playwright chromium is already installed; no additional download needed |

**Installation (harness package.json):**
```bash
npm install opentype.js pngjs svgo geist wawoff2
```
The `playwright` binary reuse from `accrue_admin/node_modules` or a global playwright install — **do not re-install in harness** if the harness `package.json` lives inside `accrue_admin/`. If harness lives in `.planning/milestones/v1.52-phases/` (separate), install `playwright` there too.

**Version verification:**
```
opentype.js  2.0.0  (2026-05-06)  ✓
pngjs        7.0.0  (2023-02-20)  ✓
svgo         4.0.1  (2026-03-04)  ✓
geist        1.7.2  (2026-06-01)  ✓
wawoff2      2.0.1  (2022-ish)    ✓
```

---

## Package Legitimacy Audit

> slopcheck could not be installed (auto-install blocked by sandbox). Manual verification performed via npm registry + official GitHub repository confirmation.

| Package | Registry | Age | Source Repo | Evidence | Disposition |
|---------|----------|-----|-------------|----------|-------------|
| `opentype.js` | npm | ~13 yrs (2013) | github.com/opentypejs/opentype.js | 757k+ weekly downloads, 5k GitHub stars, active releases [CITED: npmtrends.com] | Approved |
| `pngjs` | npm | ~14 yrs (2012) | github.com/pngjs/pngjs | Core PNG library, widely used in Playwright ecosystem | Approved |
| `svgo` | npm | ~14 yrs (2012) | github.com/svg/svgo | Industry-standard SVG optimizer, used in virtually every SVG toolchain | Approved |
| `geist` | npm | ~11 yrs pkg, 2023 Vercel adoption | github.com/vercel/geist-font | Official Vercel font package, 2026-06-01 last modified [VERIFIED: npm registry] | Approved |
| `wawoff2` | npm | ~8 yrs (2018) | github.com/fontello/wawoff2 | Fontello org (maintainers of fontello), WebAssembly woff2 port [VERIFIED: npm registry] | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck was unavailable at research time. All packages above are tagged `[ASSUMED]` for legitimacy. The planner should add a `checkpoint:human-verify` task before the first `npm install` to confirm these packages against their GitHub repos and download counts.*

---

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                      HARNESS ENTRY POINT                            │
│                  generate.mjs (Node.js)                             │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
         ┌─────────────▼─────────────┐
         │   Font Spine Module        │
         │   geist-spine.mjs          │
         │                            │
         │  opentype.parse(ttfBuf)    │
         │  font.charToGlyph(char)    │
         │  glyph.getPath(x, y, sz)  │
         │  path.toPathData({         │
         │    flipY: false,           │  ← critical: font.getPath() already flipped
         │    decimalPlaces: 3 })     │
         └─────────────┬─────────────┘
                       │ per-glyph path data + metrics
         ┌─────────────▼──────────────────────────────────────┐
         │              Lockup Assembler                       │
         │   assemble-lockup.mjs                              │
         │                                                     │
         │  mark-path + glyph-paths → <svg> string            │
         │  gap ratio enforcement (mark bbox + cap-height)    │
         └─────────────┬───────────────────────────────────────┘
                       │
        ┌──────────────┼───────────────────────────────────┐
        │              │                                   │
  ┌─────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐  ┌────────▼───────┐
  │ Dir A gen  │ │ Dir B gen  │ │ Dir C gen  │  │ Dir D gen       │
  │ strata.mjs │ │ step.mjs   │ │ arcs.mjs   │  │ typemark.mjs    │
  │ (parametric│ │ (parametric│ │ (parametric│  │ (path surgery)  │
  │ 3-4 knobs) │ │ 3-4 knobs) │ │ 3-4 knobs) │  │ + minimal knobs │
  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘  └────────┬────────┘
        └──────────────┴───────────────┴───────────────────┘
                       │ ~20-24 raw SVG candidate strings
         ┌─────────────▼──────────────────────────────────────┐
         │              Pre-Gate Lint Suite                    │
         │   lint.mjs                                          │
         │                                                     │
         │  1. valid-parse: @xmldom/xmldom.DOMParser           │
         │  2. no-rect-bg: check for <rect> fills the viewBox  │
         │  3. gap-ratio: mark bbox vs cap-height × factor     │
         │  4. no-subtitle: text element count / content check │
         │  5. monochrome-derivable: no non-greyscale-mappable │
         │     fill values (all fills must map to Ink/Paper)   │
         │  6. 16px-legibility: → Playwright → pngjs           │
         └───────────────┬───────────────────┬────────────────┘
                PASS (keep)                FAIL (reject)
                   │                          │
         ┌─────────▼──────┐          ┌────────▼────────┐
         │  Culled gallery │          │  rejected/ dir  │
         │  12–16 SVGs     │          │  (with reason)  │
         └─────────┬───────┘          └─────────────────┘
                   │
         ┌─────────▼─────────────────────────────────────────┐
         │       Context-Matrix Renderer                      │
         │   render-matrix.mjs                                │
         │                                                     │
         │  Playwright: page.goto('file://' + htmlPath)       │
         │  page.locator('#candidate-A1').screenshot()        │
         │  7 tiles per candidate × 12-16 candidates          │
         │  → screenshots/ dir                                 │
         └─────────┬───────────────────────────────────────────┘
                   │
         ┌─────────▼──────────────────────────────────────────┐
         │       Gallery Generator                             │
         │   build-gallery.mjs                                 │
         │                                                     │
         │  Inlines all SVGs into round-1-gallery.html        │
         │  Generates verdict-block JS (~60 lines)             │
         │  Stable IDs (A1..D4) + rationale per candidate     │
         └─────────┬───────────────────────────────────────────┘
                   │
         ┌─────────▼──────────────────────────────────────────┐
         │  ✋ Agent Self-Review (before user sees gallery)    │
         │                                                     │
         │  Agent reads each screenshot, applies 4-dimension  │
         │  rubric (legibility, monochrome, avatar, brand fit) │
         │  emits NDJSON per candidate → self-review.ndjson   │
         └─────────┬───────────────────────────────────────────┘
                   │
         ┌─────────▼──────────────────────────────────────────┐
         │  ✋ CHECKPOINT: User opens round-1-gallery.html    │
         │  Picks 1–3 winners, enters keep/change notes       │
         │  Clicks "Copy verdict block"                        │
         │  Pastes into TOURNAMENT.md                          │
         └────────────────────────────────────────────────────┘
```

### Recommended Project Structure

The harness lives in `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/` (kept in the phase dir per "active-phase artifacts live in the phase dir" convention). `TOURNAMENT.md` lives one level up at `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/TOURNAMENT.md` so that Phases 182–183 can append to it with a stable path.

```
.planning/phases/181-svg-pipeline-tournament-round-1-divergent/
├── TOURNAMENT.md                          ← ledger, stable path for 182/183
├── harness/
│   ├── package.json                       ← opentype.js, pngjs, svgo, geist, wawoff2
│   ├── generate.mjs                       ← entry: runs all generators → lint → gallery
│   ├── geist-spine.mjs                    ← opentype.js font loading + per-glyph path emit
│   ├── assemble-lockup.mjs                ← mark + glyph lockup assembly, gap enforcement
│   ├── dirs/
│   │   ├── a-strata.mjs                   ← Dir A: accumulation strata generator
│   │   ├── b-step.mjs                     ← Dir B: stepped interval generator
│   │   ├── c-arcs.mjs                     ← Dir C: layered arcs generator
│   │   └── d-typemark.mjs                 ← Dir D: path surgery on Geist outlines
│   ├── lint.mjs                           ← pre-gate lint suite (6 checks)
│   ├── render-matrix.mjs                  ← Playwright context-matrix screenshot runner
│   └── build-gallery.mjs                  ← assemble round-1-gallery.html
├── candidates/                            ← generated SVGs (A1..D4+overgen)
├── screenshots/                           ← context-matrix PNGs
├── rejected/                              ← culled candidates with failure reasons
├── self-review.ndjson                     ← agent self-review scores
└── round-1-gallery.html                   ← user-facing gallery (committed)
```

### Pattern 1: opentype.js Font Loading + Per-Glyph Path Extraction

**What:** Load a static TTF from the `geist` npm package into a buffer, parse with opentype.js, extract per-character glyph paths as SVG `d` attribute strings.

**Critical y-axis note:** In opentype.js 2.0.0, `font.getPath(text, x, y, fontSize)` performs the Cartesian→SVG y-axis flip internally. Calling `path.toPathData({ flipY: true })` (the default) then flips *again*, producing upside-down output. **Pass `flipY: false` when using `font.getPath()`.** [VERIFIED: github.com/opentypejs/opentype.js/issues/724]

**When to use:** Every call that needs exact Geist letterform outlines.

```javascript
// Source: opentype.js README (github.com/opentypejs/opentype.js/blob/master/README.md)
//         + Issue #724 for the flipY fix
import opentype from 'opentype.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);

// Primary path: static TTF from geist npm package
function loadGeistTTF() {
  try {
    const geistDir = path.dirname(require.resolve('geist/dist/fonts/geist-sans/GeistSans-Regular.ttf'));
    const ttfPath = path.join(geistDir, 'GeistSans-Regular.ttf');
    const buf = fs.readFileSync(ttfPath);
    return opentype.parse(buf.buffer);
  } catch {
    // Fallback: wawoff2 decompress of in-repo woff2
    return null; // caller handles async fallback
  }
}

// Extract a single glyph path as SVG path data
// Returns: { d: string, advanceWidth: number, xMin, yMin, xMax, yMax }
function glyphPathData(font, char, fontSize = 1000) {
  const glyph = font.charToGlyph(char);
  // font.getPath() scales + flips y internally; use flipY:false in toPathData
  const path = font.getPath(char, 0, 0, fontSize);
  return {
    d: path.toPathData({ decimalPlaces: 3, flipY: false }),
    advanceWidth: glyph.advanceWidth,
    xMin: glyph.xMin, yMin: glyph.yMin,
    xMax: glyph.xMax, yMax: glyph.yMax,
  };
}

// Get all glyphs for "accrue" as an ordered array
function accrueGlyphs(font, fontSize = 1000) {
  const text = 'accrue';
  const paths = font.getPaths(text, 0, 0, fontSize);
  // getPaths returns one Path per glyph (respecting ligatures etc.)
  return paths.map((p, i) => ({
    char: text[i],
    d: p.toPathData({ decimalPlaces: 3, flipY: false }),
  }));
}
```

### Pattern 2: wawoff2 Fallback — WOFF2 → TTF

**What:** If the `geist` npm TTF path fails, decompress the in-repo woff2 to a TTF buffer for opentype.parse.

```javascript
// Source: github.com/fontello/wawoff2 README
import { readFileSync } from 'fs';
import wawoff2 from 'wawoff2';

async function loadGeistFromWoff2(woff2Path) {
  const woff2Buf = readFileSync(woff2Path); // e.g. accrue_admin/priv/static/fonts/geist-sans-vf.woff2
  const ttfBuf = await wawoff2.decompress(woff2Buf);
  return opentype.parse(ttfBuf.buffer);
}
// Caller: const font = await loadGeistFromWoff2('../../../accrue_admin/priv/static/fonts/geist-sans-vf.woff2');
// NOTE: the in-repo font is a VARIABLE font (geist-sans-vf.woff2). opentype.js 2.0.0 can parse it
// but variable axis handling is unreliable (Issue #722). Prefer the static TTF from the geist package.
```

### Pattern 3: Playwright Standalone Screenshot Harness

**What:** Launch headless Chromium from a Node.js script (no test runner), navigate to a local HTML file containing the SVG at exact viewport size, take element screenshots.

**When to use:** 16px and 32px legibility lint renders; context-matrix tile screenshots.

```javascript
// Source: playwright.dev/docs/screenshots + playwright.dev/docs/api/class-browsertype
import { chromium } from 'playwright';
import { writeFileSync } from 'fs';
import path from 'path';

async function screenshotSVGAtSize(svgString, outputPath, sizeConfig) {
  // sizeConfig = { viewportW, viewportH, deviceScaleFactor, elementSelector }
  const { viewportW, viewportH, deviceScaleFactor = 1, elementSelector = '#mark' } = sizeConfig;

  // Write SVG into a minimal HTML wrapper
  const html = `<!DOCTYPE html><html><body style="margin:0;background:${sizeConfig.bg || '#FAFBFC'}">
  ${svgString}</body></html>`;
  const htmlPath = path.join(path.dirname(outputPath), '_tmp_render.html');
  writeFileSync(htmlPath, html);

  const browser = await chromium.launch({ headless: true });
  try {
    const ctx = await browser.newContext({
      viewport: { width: viewportW, height: viewportH },
      deviceScaleFactor,
    });
    const page = await ctx.newPage();
    await page.goto('file://' + htmlPath);
    const locator = page.locator(elementSelector);
    await locator.screenshot({ path: outputPath });
  } finally {
    await browser.close();
  }
}

// Usage — 16px favicon render:
await screenshotSVGAtSize(svgStr, 'screenshots/A1-16px.png', {
  viewportW: 16, viewportH: 16, deviceScaleFactor: 4,  // render 4× for clarity in legibility analysis
  elementSelector: 'svg', bg: '#FAFBFC'
});
```

**Note:** The `playwright` bare package (not `@playwright/test`) exports `{ chromium }` directly and is needed for standalone scripts. `accrue_admin/package.json` has `@playwright/test` which re-exports it. If the harness `package.json` is separate, install `playwright` as a dep.

### Pattern 4: 16px Legibility Pixel Heuristics (pngjs)

**What:** Decode a 16px PNG and apply deterministic measurable thresholds. Fail on: (1) fg/bg contrast below WCAG AA-large threshold; (2) too few distinct connected features (mark is featureless soup); (3) edge density collapses relative to 32px render (mark loses structure at small size).

**Recommended thresholds (Claude's Discretion — tune during implementation):**
- Contrast ratio: minimum 3:1 (WCAG AA-large for icons/non-text). Formula: `(L1+0.05)/(L2+0.05)`.
- Connected components at 16px: minimum 1, maximum 6. Below 1 = no mark visible; above 6 = too fragmented.
- Edge-density ratio (16px vs 32px): fail if 16px edge density < 0.35× the 32px edge density (mark loses too much detail when scaled down).

```javascript
// Source: github.com/pngjs/pngjs README (sync API)
// Source: W3C WCAG 2.0 G17/G18 for luminance formula
import { PNG } from 'pngjs';
import { readFileSync } from 'fs';

function decodePNG(pngPath) {
  const buf = readFileSync(pngPath);
  return PNG.sync.read(buf); // { data: Buffer, width, height }
}

function luminance(r, g, b) {
  const toLinear = (v) => {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
}

function contrastRatio(png) {
  // Sample foreground (darkest cluster) and background (lightest cluster)
  // Simplified: use median pixel luminance vs. corner pixels (assumed bg)
  const { data, width, height } = png;
  const getPixel = (x, y) => {
    const i = (width * y + x) << 2;
    return { r: data[i], g: data[i+1], b: data[i+2], a: data[i+3] };
  };
  // Background sample: corner pixels
  const corners = [getPixel(0,0), getPixel(width-1,0), getPixel(0,height-1), getPixel(width-1,height-1)];
  const bgLum = corners.reduce((s, p) => s + luminance(p.r, p.g, p.b), 0) / corners.length;
  // Foreground sample: scan for darkest pixel (most ink)
  let fgLum = 1;
  for (let i = 0; i < data.length; i += 4) {
    const l = luminance(data[i], data[i+1], data[i+2]);
    if (data[i+3] > 128 && l < fgLum) fgLum = l;
  }
  const L1 = Math.max(bgLum, fgLum), L2 = Math.min(bgLum, fgLum);
  return (L1 + 0.05) / (L2 + 0.05);
}

function edgeDensity(png) {
  // Count pixels with high luminance gradient (Sobel-lite)
  const { data, width, height } = png;
  const gray = (x, y) => {
    const i = (width * y + x) << 2;
    return luminance(data[i], data[i+1], data[i+2]);
  };
  let edgeCount = 0;
  for (let y = 1; y < height - 1; y++) {
    for (let x = 1; x < width - 1; x++) {
      const gx = gray(x+1,y) - gray(x-1,y);
      const gy = gray(x,y+1) - gray(x,y-1);
      const mag = Math.sqrt(gx*gx + gy*gy);
      if (mag > 0.15) edgeCount++;
    }
  }
  return edgeCount / (width * height);
}

function lint16pxLegibility(png16, png32) {
  const cr = contrastRatio(png16);
  const ed16 = edgeDensity(png16);
  const ed32 = edgeDensity(png32);
  const edRatio = ed32 > 0 ? ed16 / ed32 : 1;
  return {
    pass: cr >= 3.0 && edRatio >= 0.35,
    contrastRatio: cr,
    edgeDensityRatio: edRatio,
    reason: cr < 3.0
      ? `contrast ratio ${cr.toFixed(2)} < 3.0`
      : edRatio < 0.35
        ? `edge density collapses at 16px (ratio ${edRatio.toFixed(2)} < 0.35)`
        : 'pass',
  };
}
```

### Pattern 5: Pre-Gate Lint Suite

**What:** Six deterministic checks; all must pass before a candidate enters the gallery.

```javascript
// Source: W3C SVG spec; opentype.js bounding box conventions
import { DOMParser } from '@xmldom/xmldom';

function lintValidParse(svgString) {
  try {
    const doc = new DOMParser().parseFromString(svgString, 'image/svg+xml');
    const errs = doc.getElementsByTagName('parsererror');
    return errs.length === 0;
  } catch { return false; }
}

function lintNoRectBackground(svgString) {
  // Fail if any <rect> element fills ≥ 80% of the viewBox area
  const doc = new DOMParser().parseFromString(svgString, 'image/svg+xml');
  const svg = doc.documentElement;
  const vb = svg.getAttribute('viewBox')?.split(/[\s,]+/).map(Number) ?? [0, 0, 100, 100];
  const [,, vbW, vbH] = vb;
  const rects = doc.getElementsByTagName('rect');
  for (const rect of Array.from(rects)) {
    const w = parseFloat(rect.getAttribute('width') ?? '0');
    const h = parseFloat(rect.getAttribute('height') ?? '0');
    if (w * h >= 0.8 * vbW * vbH) return false; // rect fills viewBox — fails
  }
  return true;
}

function lintNoSubtitle(svgString) {
  // Fail if any <text> element exists outside the primary logotype text node
  // (main lockup must not carry subtitle — see D-11 / logo-brief constraint 3)
  const doc = new DOMParser().parseFromString(svgString, 'image/svg+xml');
  const texts = Array.from(doc.getElementsByTagName('text'));
  // Logotype text nodes are expected (spelled out "accrue"); fail on >1 text group
  // More precisely: all <text> elements must represent the logotype, not a tagline
  // Heuristic: fail if >1 distinct text elements or if any text content looks tagline-like
  return texts.length <= 1;
}

function lintMonochromeDeriv(svgString) {
  // Fail if any fill or stroke uses a hue that cannot map to Ink/Paper grayscale
  // Allow: #111418, #24303B, #FAFBFC, #E9EEF2, black, white, and any greyscale
  // Fail if: non-greyscale color that is a hue (not a grey shade) appears in fill/stroke
  const colorRe = /#([0-9a-fA-F]{3,6})\b/g;
  const colors = [...svgString.matchAll(colorRe)].map(m => m[1]);
  for (const hex of colors) {
    const full = hex.length === 3 ? hex.split('').map(c => c+c).join('') : hex;
    const r = parseInt(full.slice(0,2),16), g = parseInt(full.slice(2,4),16), b = parseInt(full.slice(4,6),16);
    const max = Math.max(r,g,b), min = Math.min(r,g,b);
    const saturation = max === 0 ? 0 : (max - min) / max;
    if (saturation > 0.15) return false; // has hue — not monochrome-derivable
  }
  return true;
}

function lintLockupGapRatio(markBbox, logotypeBbox, capHeight) {
  // gap = distance between mark right edge and logotype left edge
  // spec: gap should be between 0.08× and 0.35× capHeight
  // capHeight from opentype.js: font.tables.os2.sCapHeight / font.unitsPerEm × fontSize
  const gap = logotypeBbox.xMin - markBbox.xMax;
  const ratio = gap / capHeight;
  return {
    pass: ratio >= 0.08 && ratio <= 0.35,
    ratio,
    reason: ratio < 0.08 ? 'gap too tight' : ratio > 0.35 ? 'gap too wide (optically separated)' : 'pass',
  };
}
```

### Pattern 6: Gallery HTML + Verdict Block JS

**What:** Self-contained HTML with inlined SVGs, per-candidate winner checkboxes + notes, "copy verdict block" button. `navigator.clipboard.writeText()` works on `file://` because `file://` is a **potentially trustworthy origin** per W3C Secure Contexts spec (confirmed at MDN — `window.isSecureContext === true` on file:// pages). [VERIFIED: developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts]

```html
<!-- round-1-gallery.html pattern (condensed) -->
<script>
  // ~60 lines vanilla JS
  function buildVerdictBlock() {
    const winners = [], killed = [];
    const notes = {};
    document.querySelectorAll('.candidate').forEach(el => {
      const id = el.dataset.id;
      if (el.querySelector('.winner-cb').checked) {
        winners.push(id);
        notes[id] = {
          keep: el.querySelector('.keep-note').value.trim(),
          change: el.querySelector('.change-note').value.trim(),
        };
      } else {
        killed.push(id);
      }
    });
    const today = new Date().toISOString().split('T')[0];
    const lines = [`## Round 1 — ${today}`, `**Winners:** ${winners.join(', ')}`,
      `**Killed:** ${killed.join(' ')}`, ''];
    for (const id of winners) {
      lines.push(`### ${id}`);
      lines.push(`- keep: "${notes[id].keep}"`);
      lines.push(`- change: "${notes[id].change}"`);
      lines.push('');
    }
    return lines.join('\n');
  }

  document.getElementById('copy-btn').addEventListener('click', () => {
    const block = buildVerdictBlock();
    document.getElementById('verdict-pre').textContent = block;
    if (navigator.clipboard) {
      navigator.clipboard.writeText(block).catch(() => {
        // Clipboard permission denied in some browsers on file:// — pre fallback is always visible
      });
    }
  });
</script>
```

**Clipboard browser compatibility note:** Chrome allows clipboard write on file:// without permission prompt in practice. Firefox may require explicit user gesture but the `click` event handler satisfies that. The visible `<pre>` select-on-click fallback (D-10) ensures the verdict block is always copyable even if the clipboard API is restricted.

### Anti-Patterns to Avoid

- **Using `path.toPathData()` with default `flipY: true` after `font.getPath()`:** Results in y-axis double-flip — glyphs appear upside-down. Always pass `flipY: false`.
- **Trying to set variable font instances via `font.variation.set()`:** The VariationManager in opentype.js 2.0.0 is documented but issue #722 shows it's unreliable (undefined errors). Use static TTF instances from the `geist` npm package instead.
- **Running `chromium.launch()` before ensuring chromium binary is accessible:** The harness must resolve to the same Playwright version that installed the binary. Reuse `accrue_admin/node_modules/playwright` or ensure the harness `playwright` dep version matches the installed browser.
- **Installing fonttools / woff2 Python tooling for the primary path:** Unnecessary if `geist` npm package is available. Reserve the wawoff2 fallback for environments without npm access to the geist package.
- **Storing TOURNAMENT.md inside the harness/ subdirectory:** Phases 182 and 183 need a stable, harness-independent path. Keep `TOURNAMENT.md` in the phase dir root.
- **Monochrome check via CSS filter screenshot:** Cannot be done reliably in Node without a browser. Use the hex-value scan heuristic (Pattern 5 above) which checks fills/strokes directly in SVG source.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Font file parsing + path extraction | Custom TTF parser, hand-traced SVG paths | `opentype.js` | Handles kern tables, hinting, variable axes, all glyph table formats |
| PNG pixel access | Custom PNG decoder | `pngjs` (sync API) | Handles 8-bit RGBA correctly; existing ecosystem standard |
| SVG path data serialization precision | Manual `d` attribute string building | `opentype.js` `path.toPathData({ decimalPlaces: 3 })` | Handles implicit/explicit command optimization, rounding, move-to suppression |
| SVG optimization | Custom whitespace removal | `svgo` | Handles redundant commands, precision normalization, transform collapsing |
| WCAG contrast ratio | Custom luminance formula | Inline formula (25 lines, well-specified) | Formula is small and stable; using a library for 25 lines adds a dep |
| Headless screenshot rendering | puppeteer, raw CDP, canvas | `playwright` (already installed) | Chromium binary already present; Playwright API is cleaner; no new downloads |

**Key insight:** The hardest parts of this phase (exact font outlines, pixel-accurate rendering) are fully covered by existing packages. The actual creative work lives in the per-direction generator logic and the harness wiring — not in the infrastructure.

---

## Common Pitfalls

### Pitfall 1: opentype.js y-axis double-flip (Issue #724)

**What goes wrong:** `font.getPath(text, 0, 0, fontSize)` already converts from font Cartesian coordinates (y-up, baseline at 0) to SVG coordinates (y-down). Calling `.toPathData({ flipY: true })` — the default — flips again. Result: glyphs render with y-axis inverted (ascenders point downward).

**Why it happens:** opentype.js 2.0.0 moved coordinate conversion into `getPath()` but `toPathData()` still defaults to `flipY: true`.

**How to avoid:** Always call `.toPathData({ flipY: false })` when the path was produced by `font.getPath()` or `font.getPaths()`. Use `flipY: true` only when working with `Glyph.getPath()` directly (which does *not* internally flip).

**Warning signs:** Generated SVG shows letters hanging below the baseline; the entire lockup appears mirrored vertically.

### Pitfall 2: Variable font → opentype.js unreliability

**What goes wrong:** Attempting to load the variable `geist-sans-vf.woff2` (in-repo) via wawoff2 decompress + opentype.parse, then calling `font.variation.set({ wght: 400 })` to activate the Regular named instance, fails with `Cannot read properties of undefined (reading 'getInstance')`.

**Why it happens:** opentype.js 2.0.0 variable font VariationManager is partially implemented; named instance activation is undocumented and fragile.

**How to avoid:** Use the static TTF `GeistSans-Regular.ttf` from the `geist` npm package. Only fall back to variable font if the static TTF path is unavailable.

**Warning signs:** Runtime errors mentioning `variation`, `getInstance`, or `fvar` during font load.

### Pitfall 3: Playwright binary not found from harness package.json

**What goes wrong:** The harness's `package.json` declares `"playwright": "^1.59.1"` but `npm install` fetches a different chromium revision than what's already cached at `~/Library/Caches/ms-playwright/chromium-1223`.

**Why it happens:** Playwright's browser binary is versioned per playwright package version. Different versions expect different binary revisions.

**How to avoid:** Either (a) run the harness from within `accrue_admin/` so it resolves `playwright` from the existing `node_modules`, or (b) use the same version as `accrue_admin/package.json` (`^1.59.1` → installed `1.59.1`) and run `npx playwright install chromium` if the cache doesn't match. Do not use `@playwright/test` — the harness needs the bare `playwright` package.

**Warning signs:** `browserType.launch: Executable doesn't exist` error.

### Pitfall 4: file:// clipboard write fails in some browser profiles

**What goes wrong:** `navigator.clipboard.writeText()` throws `NotAllowedError` in Firefox on file:// even though spec says file:// is potentially trustworthy.

**Why it happens:** Firefox's clipboard permission model has additional restrictions; behavior is browser-implementation-dependent even when spec says "potentially trustworthy."

**How to avoid:** The `<pre>` select-on-click fallback in the gallery HTML (D-10) must always be visible. Display both the copy button *and* the pre-block simultaneously; don't hide the pre until a successful write.

**Warning signs:** User reports "Copy verdict block" button does nothing; no text appears.

### Pitfall 5: Lockup gap ratio false-failures on icon-forward marks

**What goes wrong:** The gap-ratio lint rejects Direction D typemarks where the mark IS the letterform (no separate icon) because the bounding-box logic assumes a spatial gap between a discrete mark and logotype text.

**Why it happens:** Direction D candidates are fully-integrated typemarks — the mark and type are one unified element. No gap exists.

**How to avoid:** The gap-ratio lint should only apply to Directions A/B/C (discrete mark + logotype). Direction D candidates should skip the gap-ratio lint or define it as "bounding box of decorative element vs logotype baseline" — planner decides the exact scope.

**Warning signs:** All Direction D candidates fail gap-ratio lint.

### Pitfall 6: `@xmldom/xmldom` namespace errors on SVG namespaced attributes

**What goes wrong:** Parsing `xmlns:xlink="..."` attributes with `@xmldom/xmldom` triggers namespace warnings that look like parse errors.

**Why it happens:** @xmldom/xmldom is strict about XML namespaces.

**How to avoid:** For the lint suite, use the `'image/svg+xml'` MIME type in `DOMParser.parseFromString()` to enable namespace-aware parsing. Alternatively, strip `xmlns:xlink` declarations from generated SVGs since opentype.js output doesn't need them.

---

## Code Examples

### Loading Font + Extracting "accrue" Path Data

```javascript
// Source: opentype.js README + Issue #724 (y-axis workaround)
import opentype from 'opentype.js';
import fs from 'fs';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);

const ttfPath = require.resolve('geist/dist/fonts/geist-sans/GeistSans-Regular.ttf');
const font = opentype.parse(fs.readFileSync(ttfPath).buffer);

// Get per-glyph path data for each character of "accrue"
// Note: flipY: false because font.getPaths() already flips y
const chars = 'accrue'.split('');
const paths = font.getPaths('accrue', 0, 0, 1000); // fontSize=1000 → coords in em units
const glyphData = paths.map((p, i) => ({
  char: chars[i],
  d: p.toPathData({ decimalPlaces: 3, flipY: false }),
}));

// Cap height for gap-ratio lint (units: em units at fontSize=1000)
const capHeight = font.tables.os2?.sCapHeight ?? 700;
console.log('capHeight (em units at 1000px):', capHeight);
// → Geist Regular: approximately 730–750 em units at unitsPerEm=1000
```

### Minimal SVG Lockup Assembly

```javascript
// Assemble mark SVG + "accrue" text paths into a single lockup SVG
function assembleLockup(markPathD, glyphData, config) {
  const { markWidth, gap, fontSize, viewboxH } = config;
  // glyphData = [{ char, d, advanceWidth }, ...]
  // Shift each glyph path to start at markWidth + gap
  let xOffset = markWidth + gap;
  const shiftedPaths = glyphData.map(({ d, advanceWidth }) => {
    const shifted = `<path d="${shiftPathX(d, xOffset)}" fill="#111418"/>`;
    xOffset += advanceWidth * (fontSize / 1000);
    return shifted;
  });
  const totalW = xOffset;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${totalW} ${viewboxH}">
  <path d="${markPathD}" fill="#111418"/>
  ${shiftedPaths.join('\n  ')}
</svg>`;
}
// shiftPathX: translate all M/L/C/Q commands by dx — use svgo or manual regex replacement
```

### Playwright Screenshot (standalone)

```javascript
// Source: playwright.dev/docs/api/class-browsertype + playwright.dev/docs/screenshots
import { chromium } from 'playwright';
import { writeFileSync } from 'fs';

async function renderSVGToPNG(svgString, outputPath, { w, h, dpr = 1, bg = '#FAFBFC' }) {
  const html = `<!DOCTYPE html><html><body style="margin:0;width:${w}px;height:${h}px;overflow:hidden;background:${bg}">${svgString}</body></html>`;
  const tmpHtml = outputPath.replace('.png', '_tmp.html');
  writeFileSync(tmpHtml, html);
  const browser = await chromium.launch({ headless: true });
  try {
    const ctx = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: dpr });
    const page = await ctx.newPage();
    await page.goto('file://' + tmpHtml);
    await page.locator('svg').screenshot({ path: outputPath });
  } finally {
    await browser.close();
    require('fs').unlinkSync(tmpHtml);
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| opentype.js 1.x: single parse + getPath | opentype.js 2.0.0: variable font support via VariationManager, COLRv0, CFF2 | 2026-05-06 | Variable font APIs added but have known bugs; static instance approach is more reliable for Phase 181 |
| Fonttools Python for WOFF2→TTF | wawoff2 (WebAssembly, Node.js) | ~2018 | No Python dep; works in any Node environment |
| navigator.clipboard only on HTTPS | file:// is "potentially trustworthy" per W3C Secure Contexts | 2018 (spec), ~2020 (browsers) | Gallery can use clipboard API without a local server |
| Playwright only for full test suites | Playwright standalone scripts (`chromium.launch()`) | Playwright 1.x | Screenshot harness can be a plain `generate.mjs` without test framework wiring |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `geist` npm package includes `dist/fonts/geist-sans/GeistSans-Regular.ttf` at the path resolvable via `require.resolve()` | Standard Stack / Code Examples | Harness fails to load font; fallback path via wawoff2 required |
| A2 | Playwright v1.59.1 in accrue_admin can be imported from the harness as `require('playwright')` or `import { chromium } from 'playwright'` | Architecture / Patterns | Harness needs its own playwright install if it cannot resolve from accrue_admin node_modules |
| A3 | `navigator.clipboard.writeText()` works in Chrome on file:// in the user's browser without a permission prompt | Pattern 6 | User must manually copy from the `<pre>` fallback; minor UX inconvenience only |
| A4 | opentype.js 2.0.0 `getPaths()` returns one Path per input character (not one per glyph after ligature substitution) | Pattern 1 | "accrue" might return fewer than 6 paths if ligatures fire; verify `paths.length === 6` |
| A5 | `font.tables.os2.sCapHeight` is present in Geist Regular and gives a reliable cap-height value in font units | Pattern 5 / Lockup Gap Lint | Gap-ratio lint uses fallback value (700/1000 em) if absent |
| A6 | All 5 recommended npm packages are legitimate (slopcheck unavailable at research time) | Package Legitimacy Audit | Supply chain risk; human-verify before first install |

---

## Open Questions

1. **Harness location: phase dir vs milestone dir**
   - What we know: CONTEXT.md says "exploration artifacts in `.planning/milestones/v1.52-phases/`" (design source), but also "active-phase artifacts conventionally live in the phase dir." Phase dir is `.planning/phases/181-...`; milestone dir would be `.planning/milestones/v1.52-phases/181-harness/`.
   - What's unclear: where `TOURNAMENT.md` should live for Phase 182/183 stability (they need to find it without code changes).
   - Recommendation: Put the harness in `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/` and TOURNAMENT.md at `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/TOURNAMENT.md`. Phase 182/183 can use a relative path from their own context. This is the simplest stable contract. [Claude's Discretion — planner decides]

2. **Gap-ratio lint scope for Direction D typemarks**
   - What we know: Direction D candidates have no separate mark — the typemark IS the letterform. The gap-ratio lint assumes a spatial gap between mark and text.
   - What's unclear: whether gap-ratio lint should apply to D candidates at all, or should be redefined as an intra-letterform metric.
   - Recommendation: Skip gap-ratio lint for Direction D (mark-identity flag in candidate metadata). Add a lint note explaining the omission.

3. **`font.getPaths()` and ligature behavior**
   - What we know: "accrue" contains `cc` which some fonts treat as a ligature.
   - What's unclear: whether Geist Regular defines a cc-ligature glyph that opentype.js would return as a single path (reducing paths.length below 6).
   - Recommendation: Test `font.getPaths('accrue', ...).length === 6` immediately after font load. If a ligature fires, use `font.charToGlyph(char)` per-character loop instead.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Harness scripts | ✓ | v22.14.0 | — |
| npm | Package install | ✓ | 11.1.0 | — |
| Chromium (Playwright) | Screenshot lint + context matrix | ✓ | chromium-1223 (cached) | `npx playwright install chromium` |
| `@playwright/test` (package) | Chromium binary + API | ✓ | 1.59.1 in accrue_admin | — |
| Python 3 | Fonttools fallback | ✓ | 3.14.4 | Not needed — wawoff2 is Node-native |
| Geist TTF (`geist` npm) | Font loading | Needs install | 1.7.2 | In-repo woff2 + wawoff2 decompress |

**Missing dependencies with no fallback:** None — all have either viable alternatives or are already installed.

**Missing dependencies with fallback:**
- `geist` npm package (TTF): fallback is `wawoff2.decompress(in-repo-woff2)`, which works but loads a variable font (less reliable with opentype.js).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node.js built-in `assert` + manual end-to-end smoke assertions in `generate.mjs` |
| Config file | none — harness is not a test-runner project |
| Quick run command | `node .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/generate.mjs --smoke` |
| Full suite command | `node .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/generate.mjs` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOGO-01 | Geist outline extraction works (paths.length === 6) | unit-smoke | `node harness/geist-spine.mjs --test` | ❌ Wave 0 |
| LOGO-01 | Pre-gate lints reject known-bad SVG (rect background) | unit | `node harness/lint.mjs --test` | ❌ Wave 0 |
| LOGO-01 | 16px legibility lint runs and produces pass/fail | integration | `node harness/lint.mjs --test-16px` | ❌ Wave 0 |
| LOGO-01 | All 12–16 gallery candidates pass all lints | e2e | `node harness/generate.mjs` exit 0 | ❌ Wave 0 |
| LOGO-02 | `round-1-gallery.html` opens via file:// and shows all candidates | manual | open file + visual inspect | ❌ Wave 0 |
| LOGO-02 | Verdict block JS produces correct markdown schema | manual/e2e | Open gallery, check all, copy, diff schema | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `node harness/geist-spine.mjs --test && node harness/lint.mjs --test`
- **Per wave merge:** `node harness/generate.mjs` (full pipeline, exits 0)
- **Phase gate:** Full pipeline green + gallery manual open + TOURNAMENT.md verdict appended before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `harness/geist-spine.mjs` — covers LOGO-01 font loading + path extraction
- [ ] `harness/lint.mjs` — covers LOGO-01 lint suite (needs test fixtures: known-bad SVGs)
- [ ] `harness/package.json` — bootstrap the harness Node project
- [ ] `harness/generate.mjs` — end-to-end orchestration entry point

*(These are implementation artifacts, not separate test files — the harness IS the validation for this phase)*

---

## Security Domain

> `security_enforcement` key absent from config.json — treating as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase has no authentication layer |
| V3 Session Management | no | No sessions |
| V4 Access Control | no | Local development artifacts only |
| V5 Input Validation | yes | SVG strings parsed by xmldom — treat all generator output as untrusted; parse in try/catch |
| V6 Cryptography | no | No crypto |

### Known Threat Patterns for Node.js Script Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed SVG crashing DOMParser | Tampering (self-generated) | Wrap `DOMParser.parseFromString()` in try/catch; treat parseerror as lint failure |
| Path traversal in output file paths | Tampering | All output paths are constructed from `__dirname`-anchored constants, not user input |
| npm package supply chain | Tampering | Human-verify 5 packages before first `npm install` (see Package Legitimacy Audit) |
| Clipboard exfiltration via file:// | Information Disclosure | Not a concern — file:// pages are local-machine-only; clipboard writes are user-initiated |

---

## Sources

### Primary (HIGH confidence)
- `github.com/opentypejs/opentype.js/blob/master/README.md` — font loading, getPath(), getPaths(), Path.toPathData() options, glyph metrics
- `github.com/opentypejs/opentype.js/issues/724` — y-axis double-flip in opentype.js 2.0.0, confirmed workaround
- `developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts` — file:// is a potentially trustworthy origin; clipboard API available on file://
- `playwright.dev/docs/screenshots` + `playwright.dev/docs/api/class-browsertype` — standalone chromium launch, viewport/dpr, element screenshot
- `github.com/pngjs/pngjs` — `PNG.sync.read()` API, pixel data format (RGBA flat buffer)
- `developer.mozilla.org/en-US/docs/Web/API/Clipboard/writeText` — Clipboard API secure context requirement; file:// confirmed
- `github.com/fontello/wawoff2` — `wawoff2.decompress()` API (WOFF2 → TTF buffer)
- `deepwiki.com/vercel/geist-font/3.1-npm-package` — geist npm package contains static TTF instances at `dist/fonts/geist-sans/`, 9 weights

### Secondary (MEDIUM confidence)
- `github.com/vercel/geist-font/releases/tag/1.8.0` + tree browse — confirmed `fonts/Geist/ttf/` directory exists with static TTF files (32 files: 9 weights × 2 styles + variable)
- `W3C WCAG 2.0 G17/G18` — luminance formula and contrast ratio calculation
- `github.com/opentypejs/opentype.js/issues/722` — variable font VariationManager unreliability

### Tertiary (LOW confidence / training knowledge)
- Lockup gap-ratio thresholds (0.08–0.35× cap-height) — [ASSUMED] based on general logo design conventions; no authoritative spec found; planner should treat these as starting defaults tunable during implementation
- Connected-component count thresholds for 16px legibility (1–6) — [ASSUMED] reasonable heuristic; needs empirical validation against generated candidates

---

## Metadata

**Confidence breakdown:**
- opentype.js API: HIGH — verified via official README + issue tracker
- Geist font sourcing: HIGH — verified via npm registry + vercel/geist-font repo structure
- Playwright standalone pattern: HIGH — verified via official docs
- pngjs decode API: HIGH — verified via GitHub README
- Clipboard on file://: HIGH — verified via MDN W3C Secure Contexts
- wawoff2 API: HIGH — verified via GitHub README
- Pixel heuristic thresholds: LOW — assumed; tune empirically
- Gap-ratio numeric thresholds: LOW — assumed; tune empirically

**Research date:** 2026-06-11
**Valid until:** 2026-07-11 (opentype.js 2.0.0 is very new — check for patch releases before execution)
