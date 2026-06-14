# Phase 181: SVG Pipeline + Tournament Round 1 — Divergent - Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 11 new files (all in `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/`)
**Analogs found:** 9 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `harness/package.json` | config | — | `accrue_admin/package.json` (Node project config, devDependencies only) | role-match |
| `harness/generate.mjs` | utility/orchestrator | batch, event-driven | `accrue_admin/e2e/score-visuals.mjs` (ESM CLI, main() loop, exit-code discipline) | role-match |
| `harness/geist-spine.mjs` | utility/transform | transform | `accrue_admin/e2e/score-visuals.mjs` lines 110–145 (discovery + transform loop) | partial-match |
| `harness/assemble-lockup.mjs` | utility/transform | transform | `accrue_admin/e2e/score-visuals.mjs` (data enrichment + output assembly pattern) | partial-match |
| `harness/dirs/a-strata.mjs` | utility/generator | transform | `accrue_admin/e2e/score-visuals.mjs` (parametric config object → output) | partial-match |
| `harness/dirs/b-step.mjs` | utility/generator | transform | same as a-strata.mjs | partial-match |
| `harness/dirs/c-arcs.mjs` | utility/generator | transform | same as a-strata.mjs | partial-match |
| `harness/dirs/d-typemark.mjs` | utility/generator | transform | same as a-strata.mjs | partial-match |
| `harness/lint.mjs` | utility/validator | batch | `accrue_admin/e2e/score-visuals.mjs` (pass/fail scoring loop, NDJSON emit, exit discipline) | role-match |
| `harness/render-matrix.mjs` | utility/script | request-response | `accrue_admin/e2e/score-visuals.mjs` (Playwright launch + per-file loop pattern) | exact |
| `harness/build-gallery.mjs` | utility/transform | batch, transform | `accrue_admin/e2e/score-visuals.mjs` (file discovery + aggregation + write pattern) | role-match |
| `round-1-gallery.html` | artifact/static-html | — | no analog | none |
| `TOURNAMENT.md` | planning artifact/ledger | — | `.planning/milestones/v1.51-MILESTONE-AUDIT.md` (structured verdict doc) | role-match |
| `self-review.ndjson` | artifact/output | — | `accrue_admin/test-results/admin-visuals/findings.ndjson` (NDJSON findings output) | exact |

---

## Pattern Assignments

### `harness/package.json` (config)

**Analog:** `accrue_admin/package.json` (lines 1–16)

**Full analog** (`accrue_admin/package.json` lines 1–16):
```json
{
  "name": "accrue-admin-e2e",
  "private": true,
  "scripts": {
    "e2e": "env -u NO_COLOR playwright test",
    "e2e:visuals:png-only": "env -u NO_COLOR playwright test e2e/admin-visuals.spec.js",
    "score-visuals": "node e2e/score-visuals.mjs"
  },
  "devDependencies": {
    "@anthropic-ai/sdk": "^0.100.1",
    "@playwright/test": "^1.57.0"
  }
}
```

**Copy this shape for the harness package.json.** Key differences:
- Name: `"accrue-logo-harness"`, `"private": true`
- Scripts: `"generate": "node generate.mjs"`, `"smoke": "node generate.mjs --smoke"`, `"lint-test": "node lint.mjs --test"`
- Dependencies (not devDependencies — these are the harness runtime): `opentype.js ^2.0.0`, `pngjs ^7.0.0`, `svgo ^4.0.1`, `geist ^1.7.2`, `wawoff2 ^2.0.1`, `@xmldom/xmldom ^0.9.0`
- Supporting: `playwright ^1.59.1` (pinned to match `accrue_admin`'s installed version — do not re-install chromium)
- `"type": "module"` — all harness files are `.mjs` (ESM)

---

### `harness/generate.mjs` (orchestrator, batch)

**Analog:** `accrue_admin/e2e/score-visuals.mjs`

This is the repo's only standalone Node CLI script with a full async `main()` orchestration loop. It establishes every convention the harness entry point must copy.

**ESM file header + `__dirname` shim** (`score-visuals.mjs` lines 24–28):
```javascript
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
```

**Early-exit guard pattern** (`score-visuals.mjs` lines 35–38) — adapt this for `--smoke` flag:
```javascript
if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[score-visuals] ANTHROPIC_API_KEY not set — skipping (human/CI gate only)");
  process.exit(0);
}
```
For `generate.mjs`, the early-exit pattern becomes:
```javascript
const SMOKE = process.argv.includes('--smoke');
// In smoke mode: run only font-load + one per-direction candidate, skip screenshots
```

**Configuration block** (`score-visuals.mjs` lines 47–50):
```javascript
const model = process.env.SCORE_MODEL || "claude-sonnet-4-5";
const RESULTS_DIR = path.join(__dirname, "../test-results/admin-visuals");
const MAX_B64_BYTES = 5 * 1024 * 1024;
const TO_STDOUT = process.argv.includes("--stdout");
```
Copy this const-block pattern. Harness version:
```javascript
const PHASE_DIR  = path.resolve(__dirname, '..');             // ../ = phase root
const CANDIDATES = path.join(PHASE_DIR, 'candidates');
const SCREENSHOTS = path.join(PHASE_DIR, 'screenshots');
const REJECTED   = path.join(PHASE_DIR, 'rejected');
```

**Async main() + top-level await** (`score-visuals.mjs` lines 150–280, bottom call on line 280):
```javascript
async function main() {
  // ... loop body ...
}
await main();
```
`generate.mjs` must follow this exact shape. `await main()` at bottom of file.

**Progress logging conventions** (`score-visuals.mjs` lines 157, 186):
```javascript
console.log(`[score-visuals] Found ${pngs.length} PNG(s) to score using model: ${model}`);
console.log(`[score-visuals] Scoring ${viewport}/${screen} (${theme})…`);
```
Use bracketed prefix `[generate]`, `[lint]`, `[render-matrix]` etc. per script name. Use `…` (ellipsis, not `...`) for in-progress messages.

**Error handling: continue-on-error within loop, exit(1) on fatal** (`score-visuals.mjs` lines 216–231, 259–262):
```javascript
} catch (parseErr) {
  console.error(`[score-visuals] Failed to parse ... ${parseErr.message}`);
  continue; // skip this image, don't abort the run
}
// ...
} catch (err) {
  console.error(`[score-visuals] API error: ${err.message}`);
  process.exit(1);
}
```
Lint failures are per-candidate `continue` (keep processing others). Fatal errors (`chromium not found`, `font not loaded`) call `process.exit(1)` with an explanatory message.

**Summary line at script end** (`score-visuals.mjs` lines 268–278):
```javascript
console.log(`[score-visuals] Scored ${pngs.length - skipped} PNGs → ${totalFindings} findings (${belowBar} below bar)${skippedNote}`);
```
`generate.mjs` ends with: `console.log(\`[generate] Done: ${passed} passed / ${failed} failed / ${culled} culled → gallery at ${GALLERY_PATH}\`);`

---

### `harness/geist-spine.mjs` (utility/transform)

**Analog:** `accrue_admin/e2e/score-visuals.mjs` — specifically its file-discovery + transform-per-item pattern.

**Module shape:** `geist-spine.mjs` is a **pure ESM module** (no `main()`, no CLI behavior) that exports two functions. Consumers (`generate.mjs`) call them. This mirrors how `score-visuals.mjs` separates `discoverPngs()` (lines 111–145) as a pure helper from the `main()` loop.

**Exports to provide:**
```javascript
// geist-spine.mjs — Geist font loading + per-glyph path extraction
export async function loadGeistFont() { /* ... returns opentype Font object */ }
export function extractGlyphs(font, text, fontSize = 1000) { /* ... returns [{ char, d, advanceWidth }] */ }
```

**Critical: `flipY: false`** — must be present on every `toPathData()` call:
```javascript
// Pattern from RESEARCH.md Pattern 1 + Issue #724
const path = font.getPath(char, 0, 0, fontSize);
return path.toPathData({ decimalPlaces: 3, flipY: false });
//                                          ^^^^^^^^^^^^ mandatory
```

**Font loading try/fallback** — mirrors the skip/warn pattern of `score-visuals.mjs` line 178–184:
```javascript
// Primary: static TTF from geist npm
try {
  const ttfPath = require.resolve('geist/dist/fonts/geist-sans/GeistSans-Regular.ttf');
  return opentype.parse(fs.readFileSync(ttfPath).buffer);
} catch {
  console.warn('[geist-spine] geist npm TTF not found — falling back to wawoff2');
  return loadFromWoff2();  // async fallback
}
```

**Smoke test flag** — when `--test` is passed (RESEARCH.md Validation Architecture):
```javascript
if (process.argv.includes('--test')) {
  const font = await loadGeistFont();
  const glyphs = extractGlyphs(font, 'accrue');
  console.assert(glyphs.length === 6, `Expected 6 glyphs, got ${glyphs.length}`);
  console.log('[geist-spine] smoke: OK');
  process.exit(0);
}
```

---

### `harness/assemble-lockup.mjs` (utility/transform)

**Analog:** `accrue_admin/e2e/score-visuals.mjs` — data enrichment pattern (lines 232–257), where per-item metadata is merged into a canonical output object.

**Module shape:** Pure ESM module, exports `assembleLockup(markPathD, glyphs, config)` → SVG string. No CLI behavior.

**Lockup gap-ratio enforcement** — the gap is validated here, not in `lint.mjs`. The assembler enforces the canonical gap via config knob; `lint.mjs` then verifies the committed SVG post-hoc:
```javascript
// Gap spec: 0.08–0.35 × capHeight (RESEARCH.md Pattern 5 lintLockupGapRatio)
export function assembleLockup(markPathD, glyphs, config) {
  const { markWidth, capHeight, gapRatio = 0.15, fontSize = 1000, viewboxH } = config;
  const gap = capHeight * gapRatio;
  // ... build SVG string with mark at x=0, logotype starting at x=(markWidth + gap)
}
```

**Direction D exception** — Direction D typemarks are fully integrated (no spatial gap). `assemble-lockup.mjs` accepts a `{ markIsTypemark: true }` flag that skips gap enforcement and produces a single unified path group.

---

### `harness/dirs/a-strata.mjs`, `b-step.mjs`, `c-arcs.mjs`, `d-typemark.mjs` (generators, transform)

**Analog:** `accrue_admin/e2e/score-visuals.mjs` DIMENSIONS array + per-dimension config object pattern (lines 56–67):
```javascript
const DIMENSIONS = [
  { id: 1, name: "token-compliance" },
  { id: 2, name: "visual-hierarchy" },
  // ...
];
```

Each direction generator exports:
1. A **CONFIGS array** — the 5–6 candidate parameter sets for that direction (each is a plain object with 3–4 knobs).
2. A **`generate(config)`** function that takes one config and returns an SVG path string (the mark geometry only; lockup assembly is `assemble-lockup.mjs`'s job).

**Shared shape all 4 generators must use:**
```javascript
// e.g. harness/dirs/a-strata.mjs
export const CONFIGS = [
  { id: 'A1', layers: 4, amplitude: 0.3, strokeWeight: 1.5, spacing: 0.25 },
  { id: 'A2', layers: 6, amplitude: 0.5, strokeWeight: 1.0, spacing: 0.20 },
  // ... 3-4 more
];

export function generate(config) {
  // Returns: { markPathD: string, markWidth: number, markHeight: number }
  // markPathD is the SVG <path d="..."> value for the mark geometry only
}
```

**Candidate metadata schema** — each generator produces candidates with this shape (matches the NDJSON output convention from `score-visuals.mjs`):
```javascript
{
  id: 'A1',           // stable ID per D-11 schema
  direction: 'A',
  config: { /* knobs */ },
  markPathD: '...',   // SVG path data for mark only
  lockupSvg: '...',   // full assembled lockup SVG (from assemble-lockup.mjs)
  rationale: '...',   // one-line rationale shown in gallery
}
```

**Direction D special case:** `d-typemark.mjs` returns `{ markIsTypemark: true, fullSvg: string }` — the full SVG is the typemark itself (no separate lockup assembly needed).

---

### `harness/lint.mjs` (validator, batch)

**Analog:** `accrue_admin/e2e/score-visuals.mjs` — this is the closest structural match.

**NDJSON output shape** — copy exactly from `score-visuals.mjs` enrichment block (lines 232–257):
```javascript
// score-visuals.mjs writes findings as NDJSON:
const enriched = {
  screen, viewport, theme,
  dimension, dimension_name, score,
  defect: finding.defect ?? null,
  suggested_fix: finding.suggested_fix ?? null,
};
const line = JSON.stringify(enriched) + "\n";
fs.appendFileSync(findingsPath, line);
```

**Harness lint NDJSON — one line per lint check per candidate:**
```javascript
const result = {
  candidateId: 'A1',                  // stable ID
  lint: 'no-rect-background',          // lint check name
  pass: true,                          // boolean
  reason: null,                        // string if fail, null if pass
};
fs.appendFileSync(lintLogPath, JSON.stringify(result) + '\n');
```

**Culling output conventions** (`score-visuals.mjs` lines 174–183 — skip-and-warn):
```javascript
// score-visuals.mjs: large image → skip with warning, not abort
if (b64.length > MAX_B64_BYTES) {
  console.warn(`[score-visuals] Skipping ${pngPath} — base64 size ${b64.length} exceeds 5 MB limit`);
  skipped++;
  continue;
}
```
For `lint.mjs`: lint failure → move SVG to `rejected/` with a reason file, log warning, `continue`.

**Self-test mode** (`--test` flag, per RESEARCH.md Validation Architecture):
```javascript
// When run with: node harness/lint.mjs --test
// Feed known-bad fixtures and assert the expected lint fires
if (process.argv.includes('--test')) {
  const rectBgSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" fill="white"/></svg>`;
  const result = lintNoRectBackground(rectBgSvg);
  console.assert(result === false, 'no-rect-background should fire on full-viewBox rect');
  console.log('[lint] smoke: OK');
  process.exit(0);
}
```

**Gap-ratio lint scope exception** — Direction D candidates set `skipGapRatio: true` in their metadata. `lint.mjs` reads this flag and skips the gap-ratio check with a logged note (not a failure).

---

### `harness/render-matrix.mjs` (utility/script, request-response)

**Analog:** `accrue_admin/e2e/score-visuals.mjs` — exact match. This file IS the Playwright standalone screenshot harness, which is exactly what `score-visuals.mjs` is (Playwright launch + per-file screenshot loop).

**Playwright standalone launch pattern** (`score-visuals.mjs` lines 186–213):
```javascript
// score-visuals.mjs uses @anthropic-ai/sdk after Playwright captures PNGs.
// render-matrix.mjs uses Playwright the same way score-visuals does: launched from Node,
// not from @playwright/test runner.
const response = await client.messages.create({ ... });
```

The Playwright pattern to copy is the _context_ of how score-visuals is invoked as a standalone node script. The actual Playwright API calls come from RESEARCH.md Pattern 3:
```javascript
import { chromium } from 'playwright';
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
  await browser.close();  // always close — mirrors score-visuals.mjs's try/finally
}
```

**Context matrix: 8 tiles per candidate.** One Playwright browser launch per candidate (not per tile) — open multiple pages or reuse context across tiles:

| Tile ID | Viewport | Background | Device Scale | Selector |
|---------|----------|------------|--------------|----------|
| `paper-light` | 320×80 | `#FAFBFC` | 1 | `svg` |
| `ink-dark` | 320×80 | `#111418` | 1 | `svg` |
| `32px-favicon` | 32×32 | `#FAFBFC` | 2 | `svg` |
| `16px-favicon` | 16×16 | `#FAFBFC` | 4 | `svg` |
| `avatar-circle` | 96×96 | `#FAFBFC` | 2 | `svg` |
| `readme-header` | 800×120 | `#FAFBFC` | 1 | `svg` |
| `social-card` | 600×315 | `#FAFBFC` | 1 | `svg` (OG 1200×630 aspect, half scale) |
| `mono` | 320×80 | `#FAFBFC` | 1 | `svg` |

**Output path convention** — mirrors `score-visuals.mjs`'s `test-results/admin-visuals/{project}/{name}.png`:
```
screenshots/{candidateId}/{tileId}.png
// e.g.: screenshots/A1/16px-favicon.png
//       screenshots/A1/paper-light.png
```

---

### `harness/build-gallery.mjs` (utility/transform, batch)

**Analog:** `accrue_admin/e2e/score-visuals.mjs` — file discovery + aggregation + write pattern.

**File discovery pattern** (`score-visuals.mjs` lines 111–145):
```javascript
function discoverPngs() {
  if (!fs.existsSync(RESULTS_DIR)) {
    console.log(`[score-visuals] RESULTS_DIR not found: ${RESULTS_DIR}`);
    return [];
  }
  const files = fs.readdirSync(projectDir).filter((f) => f.endsWith(".png"));
  // ...
}
```
`build-gallery.mjs` uses the same guard: if `candidates/` dir is missing or empty, exit with a clear message.

**Output write pattern** (`score-visuals.mjs` lines 165–168):
```javascript
findingsPath = path.join(RESULTS_DIR, "findings.ndjson");
fs.writeFileSync(findingsPath, ""); // truncate before appending
// later: fs.appendFileSync(findingsPath, line);
```
`build-gallery.mjs` writes the entire gallery in one `fs.writeFileSync(galleryPath, htmlString)` call — no append needed.

**Gallery HTML structure** — inline all candidate SVGs. The gallery file is the only place that has no analog in the codebase. The RESEARCH.md Pattern 6 excerpt is the canonical template. Key structural rules:
- Each candidate tile has `class="candidate"` and `data-id="A1"` attributes
- Winner checkbox: `<input type="checkbox" class="winner-cb">`
- Notes: `<textarea class="keep-note">` and `<textarea class="change-note">`
- Copy button: `<button id="copy-btn">` (one global button)
- Verdict pre: `<pre id="verdict-pre">` (always visible — never hide)
- The verdict-block JS (~60 lines vanilla, no deps) lives in a single `<script>` tag at bottom of `<body>`

---

### `TOURNAMENT.md` (planning artifact/ledger)

**Analog:** `.planning/milestones/v1.51-MILESTONE-AUDIT.md` (structured verdict document) and `accrue_admin/test-results/admin-visuals/findings.ndjson` (output artifact with stable schema).

**File location:** `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/TOURNAMENT.md` — phase-dir root, not inside `harness/`. Phases 182–183 append to this path by name.

**Schema (D-11):**
```markdown
## Round 1 — {YYYY-MM-DD}
**Winners:** B2, C4
**Killed:** A1 A2 A3 A4 B1 B3 B4 C1 C2 C3 D1 D2 D3 D4

### B2
- keep: "<verbatim user prose>"
- change: "<verbatim user prose>"

### C4
- keep: "<verbatim user prose>"
- change: "<verbatim user prose>"

### Constraints (extracted by agent, user-confirmed)
- R1-C1: <normalized constraint statement>
- R1-C2: <normalized constraint statement>
```

The verdict block JS emits this schema verbatim. The agent appends the user-pasted block unmodified. The `### Constraints` section is added by the agent post-paste by extracting and normalizing the keep/change notes — it does NOT overwrite the user's prose sections.

---

### `self-review.ndjson` (artifact/output)

**Analog:** `accrue_admin/test-results/admin-visuals/findings.ndjson` — exact NDJSON findings schema.

**NDJSON line schema** — extends the `score-visuals.mjs` enriched-finding shape (lines 232–252):
```javascript
// score-visuals.mjs finding shape:
{ screen, viewport, theme, dimension, dimension_name, score, defect, suggested_fix }

// self-review.ndjson finding shape — adapted for logo candidates:
{
  "candidateId": "A1",
  "dimension": "legibility-16px",      // one of 4 rubric dimensions
  "score": 2,                           // 0-3 (pass >= 2)
  "pass": true,
  "defect": null,                       // string if score < 2
  "suggested_fix": null                 // string if score < 2
}
```

**Four rubric dimensions** (D-08, replacing score-visuals.mjs's 10 UI dimensions):
1. `"legibility-16px"` — readable at 16px favicon size
2. `"monochrome-survival"` — survives grayscale (no hue-only information)
3. `"avatar-crop-integrity"` — reads as distinct mark in 96×96 circle crop
4. `"brand-fit"` — aligns with DNA visual personality (accumulation/timelines/state; no finance clichés)

---

## Shared Patterns

### Node CLI Script Structure
**Source:** `accrue_admin/e2e/score-visuals.mjs` (lines 1–280)
**Apply to:** `generate.mjs`, `lint.mjs`, `render-matrix.mjs`, `build-gallery.mjs`

Every harness script that has a CLI entry point must follow this exact structure:
```javascript
// 1. JSDoc header comment block (lines 1-22)
/**
 * <filename> — <one-line description>
 * Usage: node harness/<filename> [--flags]
 */

// 2. ESM imports + __dirname shim (lines 24-28)
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// 3. Config consts block (lines 47-50)
const PHASE_DIR = path.resolve(__dirname, '..');
const FLAG = process.argv.includes('--flag');

// 4. Helper functions (named, not inline lambdas)

// 5. async function main() { ... }

// 6. await main();   ← top-level await, last line of file
```

### NDJSON Findings Output
**Source:** `accrue_admin/e2e/score-visuals.mjs` (lines 165–168, 232–257, 264–270)
**Apply to:** `lint.mjs` (lint results), `self-review.ndjson` (agent self-review)

NDJSON conventions:
- Truncate the output file with `fs.writeFileSync(path, "")` before the loop begins
- Append each line with `fs.appendFileSync(path, JSON.stringify(obj) + '\n')`
- `null` (not `undefined`) for absent optional fields — see `finding.defect ?? null`
- `--stdout` flag routes output to `process.stdout.write(line)` instead of file

### Bracketed Log Prefix Convention
**Source:** `accrue_admin/e2e/score-visuals.mjs` (lines 157, 162, 179, 186, 268–275)
**Apply to:** All harness scripts

```javascript
console.log(`[generate] ...`);   // generate.mjs
console.log(`[lint] ...`);       // lint.mjs
console.log(`[render] ...`);     // render-matrix.mjs
console.log(`[gallery] ...`);    // build-gallery.mjs
console.warn(`[geist-spine] ...`); // warnings always console.warn
console.error(`[lint] ...`);    // errors always console.error
```

### Playwright Try/Finally Browser Close
**Source:** `accrue_admin/e2e/score-visuals.mjs` (implicit — the script exits after the API loop; the Playwright pattern is from RESEARCH.md Pattern 3)
**Apply to:** `render-matrix.mjs`, `lint.mjs` (16px legibility lint)

```javascript
const browser = await chromium.launch({ headless: true });
try {
  // ... all screenshot work ...
} finally {
  await browser.close();
}
```
Never let `browser.close()` be skipped on error. Always use `try/finally`.

### ESM Module Pattern (pure helpers — no CLI)
**Source:** `accrue_admin/e2e/score-visuals.mjs` `discoverPngs()` function (lines 111–145) — a pure helper extracted from `main()`
**Apply to:** `geist-spine.mjs`, `assemble-lockup.mjs`, `dirs/a-strata.mjs`, `dirs/b-step.mjs`, `dirs/c-arcs.mjs`, `dirs/d-typemark.mjs`

Pure modules: no `main()`, no `await main()` at bottom. Export named functions only. CLI behavior (smoke test) is gated behind `process.argv.includes('--test')` early-exit guard.

### Evidence-on-Record for Rejected Candidates
**Source:** Phase 180 established convention; `score-visuals.mjs` `skipped++` / warning pattern (lines 178–184)
**Apply to:** `lint.mjs`, `generate.mjs`

Every culled candidate gets:
1. Its SVG moved (or copied) to `rejected/<candidateId>.svg`
2. A sidecar `rejected/<candidateId>.reason.txt` with: lint name that failed, measured value, threshold, timestamp

```
Candidate: A2
Lint: 16px-legibility
Reason: contrast ratio 1.83 < 3.0
Measured: { contrastRatio: 1.83, edgeDensityRatio: 0.41 }
Culled: 2026-06-12T...Z
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `round-1-gallery.html` | static-html | — | No self-contained HTML gallery with inline SVGs + vanilla JS verdict capture exists in the codebase. RESEARCH.md Pattern 6 is the canonical template. |

---

## Metadata

**Analog search scope:** `accrue_admin/e2e/`, `accrue_admin/package.json`, `.planning/phases/180-brand-audit-dna-lock/artifacts/`
**Files scanned:** 7 (score-visuals.mjs, playwright.config.js, accrue_admin/package.json, admin-visuals.spec.js, admin-a11y.spec.js, contrast.js, 180-PATTERNS.md)
**Pattern extraction date:** 2026-06-12
