# Phase 186: HTML Brand Book Assembly & Quality Gate — Research

**Researched:** 2026-06-14
**Domain:** Self-contained static HTML assembly, CSS custom properties, inline SVG, dark-mode toggle, Playwright screenshot QA
**Confidence:** HIGH

---

## Summary

Phase 186 is a pure assembly and quality-gate phase. All creative outputs — logo SVGs, design tokens CSS, specimen SVGs, voice system, and copy blocks — are already committed and locked. The sole engineering challenge is assembling them into one `brandbook/index.html` that:

1. Opens via `file://` with no server, no build step, no JS framework.
2. Renders correctly in both light and dark color schemes, from 360px up.
3. Stays within a ≤2 MB committed-weight budget.
4. Passes the 8-item Phase-180 quality-gate checklist (including a final human UAT).

The tokens.css file already defines `[data-theme="dark"]` on `:root` — the dark-mode strategy is a `data-theme` attribute toggle, which is an exact match to the minimal vanilla-JS approach. Fonts are the only meaningful budget risk: Geist is used in the specimen SVGs as `font-family="Geist, system-ui, sans-serif"` but all logo SVGs are fully outlined paths with no `<text>` elements and no `@font-face` dependency. For body text in the brand book itself, a system-font fallback (`Geist, system-ui, sans-serif`) is all that is needed — no font embedding required, and no OFL restriction applies to stylesheet declarations.

The current committed weight of all tracked `brandbook/` files is approximately 960 KB (git `du -c` reports 960 blocks at 1 KB each), leaving a generous margin to the 2 MB ceiling. Budget risk is LOW if fonts are not base64-embedded.

**Primary recommendation:** Write a single Node.js assembly script (`brandbook/harness/assemble.mjs`) that reads all inputs and writes `brandbook/index.html` as one file — inline `<style>` from tokens.css, inline `<svg>` for logos and specimens, markdown-rendered copy blocks, and a 30-line vanilla-JS dark-mode toggle. The harness already has Playwright installed and proven; reuse `size-matrix-qa.mjs`'s screenshot pattern to write a new `verify-brandbook.mjs` that screenshots `file://` at {light,dark} × {360px,1200px}.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token delivery | Inline `<style>` in HTML | — | file:// has no cross-origin issue for `<link>` to a local file, but a single inlined `<style>` is trivially self-contained and eliminates any file-path coupling |
| SVG rendering | Inline `<svg>` in HTML body | Referenced `<img src>` | `<img src>` works on file:// for local relative paths; inline `<svg>` avoids path assumptions and allows CSS token inheritance — prefer inline for logos, acceptable either way for specimen SVGs |
| Dark-mode toggle | `:root[data-theme="dark"]` CSS + vanilla `<script>` | `prefers-color-scheme` media query only | tokens.css already defines `[data-theme="dark"]`; a JS toggle sets the attribute, with `prefers-color-scheme` as the initialization default |
| Font delivery | System-font stack | — | All logo paths are outlined; body text uses `Geist, system-ui, sans-serif` stack; no @font-face needed |
| Page navigation | In-page anchor links + sticky TOC | — | No framework; TOC is a fixed `<nav>` with `<a href="#section-id">` anchors |
| Assembly | Node.js build script (dev-time only) | — | The assembled HTML is committed; the script is a one-time regeneration tool (like the token generator) |
| Verification | Node.js script + Playwright (reuse logo harness) | grep check for external URLs | Same Playwright binary already installed in `brandbook/logo/harness/node_modules/` |

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BOOK-01 | `brandbook/index.html` is a self-contained, professional, standalone brand book — inline CSS from v1.52 tokens, inlined SVGs, zero build step, zero JS frameworks, file://-openable — consuming the audit structure, logo system, tokens/specimens, and voice/copy | Confirmed: tokens.css (1.46 KB) + all SVGs (66 KB total) fit inline; dark-mode strategy already in tokens.css; sections mapped below |
| BOOK-02 | The committed `brandbook/` passes the Phase-180 quality-gate checklist, stays within ≤2 MB size budget, and passes final human UAT | Current tracked weight is ~960 KB; with assembled HTML the total budget headroom is ~1 MB; all 8 checklist items have defined verification methods below |
</phase_requirements>

---

## Material Inventory (VERIFIED: disk inspection)

All files are git-tracked. Total current committed weight: **~960 KB** (960 blocks × 1 KB).

### Logo SVGs (`brandbook/logo/*.svg`) — 33 KB total

| File | Bytes | Role in brand book |
|------|-------|--------------------|
| `accrue-logo.svg` | 1,920 | Hero / cover section — primary lockup |
| `accrue-logo-on-dark.svg` | 2,008 | Dark-surface demo in logo section |
| `accrue-logo-subtitle.svg` | 7,838 | With-subtitle variant |
| `accrue-logo-mono.svg` | 1,930 | Monochrome variants section |
| `accrue-logo-mono-inverse.svg` | 1,996 | Monochrome inverse |
| `accrue-wordmark.svg` | 1,330 | Wordmark-only section |
| `accrue-mark.svg` | 655 | Mark-only + favicon section |
| `accrue-mark-on-dark.svg` | 726 | Dark mark |
| `accrue-mark-mono.svg` | 653 | Mono mark |
| `accrue-mark-mono-inverse.svg` | 714 | Mono inverse mark |
| `accrue-clearspace.svg` | 2,256 | Clearspace spec |
| `accrue-social-card.svg` | 10,863 | Social card section |
| `favicon.svg` | 616 | Shown in favicon row |

### Raster files (`brandbook/logo/`) — 36 KB total

| File | Bytes | Treatment in brand book |
|------|-------|-------------------------|
| `accrue-social-card.png` | 28,401 | Shown as `<img>` with relative path (largest raster; keep as referenced file, not inline — base64 would add 33% overhead = ~38 KB) |
| `favicon.ico` | 562 | Referenced in `<link rel="shortcut icon">` only |
| `favicon-16.png` / `favicon-32.png` / `favicon-48.png` | 106/137/265 | `<link rel="icon">` references only; show as `<img>` in favicon docs section |
| `apple-touch-icon.png` | 1,095 | `<link rel="apple-touch-icon">` reference |
| `icon-192.png` / `icon-512.png` | 1,083 / 4,555 | PWA manifest section; show as `<img>` |

### Specimen SVGs (`brandbook/examples/`) — 33 KB total

| File | Bytes | Treatment |
|------|-------|-----------|
| `palette.svg` | 25,838 | Largest single asset; inline as `<svg>` in color tokens section |
| `typography.svg` | 4,157 | Inline in typography section |
| `spacing.svg` | 2,956 | Inline in spacing section |

### Text assets

| File | Bytes | Treatment |
|------|-------|-----------|
| `tokens/tokens.css` | 1,458 | Inline as `<style>` block |
| `tokens/tokens.json` | 13,498 | Not in brand book HTML (machine format; linked or omitted) |
| `voice.md` | 9,002 | Sections rendered as HTML prose |
| `copy.md` | 9,452 | Sections rendered as HTML prose / `<pre><code>` blocks |
| `README.md` | 7,897 | Source for logo usage rules in logo section |
| `LICENSE-FONTS.txt` | 6,755 | Footer / provenance section |

### Harness files (not in brand book, no changes needed)

`brandbook/logo/harness/` and `brandbook/tokens/harness/` — existing Node tooling; Phase 186 adds a new `brandbook/harness/` with `assemble.mjs` + `verify-brandbook.mjs`.

---

## Budget Analysis [VERIFIED: disk inspection]

The ≤2 MB check in the quality-gate checklist is `du -sh brandbook/`. Note: `du` on macOS uses 512-byte blocks by default; `du -sh` gives a human total of the entire working-tree directory. The requirement is on **committed weight** per STATE.md, but the checklist text says `du -sh brandbook/` — the planner must run this on a clean checkout (or explicitly exclude `harness/node_modules/` which is untracked). Recommend: use `git ls-files brandbook/ | xargs du -c` for an authoritative committed-only byte count.

### Projected assembled HTML weight budget

| Component | Bytes (approx) | How included |
|-----------|----------------|--------------|
| tokens.css inlined as `<style>` | 1,500 | Inline |
| All logo SVGs inlined (13 SVGs) | 33,000 | Inline |
| All specimen SVGs inlined (3 SVGs) | 33,000 | Inline |
| voice.md content rendered | 9,000 | HTML prose |
| copy.md content rendered | 9,500 | HTML prose |
| HTML boilerplate + TOC + JS toggle + commentary | ~15,000 | Written |
| **Total index.html (estimated)** | **~100,000 (100 KB)** | |

Adding `index.html` (~100 KB) to the current committed weight (~960 KB) yields **~1.06 MB** — comfortably under 2 MB with no font embedding.

**Font embedding verdict: Do NOT embed fonts.** Base64 encoding Geist woff2 files (Geist Sans Regular alone is ~50–80 KB woff2 → ~110 KB base64) would consume the remaining headroom for marginal gain. The specimen SVGs already specify `font-family="Geist, system-ui, sans-serif"` and render correctly in any modern browser with Geist installed or fall back to system-ui. The brand book body copy should use the same stack. If the user's machine has Geist installed (it does, since `geist` npm package is in `brandbook/logo/harness/`), screenshots will look correct. For `file://` viewers without Geist, system-ui is an acceptable fallback for a developer audience. [ASSUMED: Geist is common enough on Phoenix developer machines that system-ui fallback is acceptable — no user confirmation needed per existing Geist-locked decision]

---

## Dark-Mode Strategy [VERIFIED: tokens.css on disk]

tokens.css already defines:
```css
:root { /* light tokens */ }
:root[data-theme="dark"] { /* dark overrides */ }
```

The dark-mode implementation in the brand book is:

1. On `<html>` or `<body>`: read `prefers-color-scheme` on load, set `document.documentElement.dataset.theme = 'dark'` if OS prefers dark.
2. A toggle button sets/clears the `data-theme` attribute and persists to `localStorage`.
3. No JS framework; the toggle is ~20 lines of vanilla JS in a `<script>` at the bottom of `<body>`.

This pattern is well-established for CSS custom property theming [ASSUMED: pattern is idiomatic — verified in multiple OSS design system implementations]. The tokens.css `[data-theme="dark"]` selector matches `<html data-theme="dark">` since `:root` is `html` in HTML documents.

**Dark-mode CSS architecture note:** The dark tokens define `--accrue-dark-*` variables (e.g., `--accrue-dark-base`, `--accrue-dark-primary`), not overriding the light variables. The brand book HTML must use these tokens correctly — dark-surface elements reference `--accrue-dark-base` rather than `--accrue-surface-base`. The assembly author must write the brand book CSS rules using the dark token names, not assume they auto-override the light names.

---

## Page Architecture — Information Architecture

### Recommended Section Order

Based on standard OSS brand book / style guide convention (Stripe, GitHub Primer, Tailwind Heroicons), the section order for a developer-audience brand book is:

1. **Cover / Hero** — logo at display size, tagline, "Billing state, modeled clearly."
2. **Logo System** — primary lockup, on-dark lockup, mark-only, wordmark-only, subtitle variant, mono variants, clearspace spec, minimum sizes, misuse rules
3. **Color Palette** — inlined `palette.svg`; then token reference table (raw palette, semantic roles, dark-mode tokens); usage rules per BRAND-DNA.md
4. **Typography** — inlined `typography.svg`; Geist sans + Geist Mono declaration; type scale table; usage rules
5. **Spacing** — inlined `spacing.svg`; spacing scale (reference-only per tokens.json D-11 note)
6. **Voice & Tone** — rendered voice.md: principles, do/don't table, tone sliders, per-surface deltas
7. **Copy Blocks** — rendered copy.md: GitHub, Hex.pm, HexDocs, README hero, landing page sections, release notes, microcopy
8. **Favicon & Social Card** — favicon at all sizes, social card preview, `<head>` snippet for engineers
9. **Token Reference** — scrollable CSS variable table (all `--accrue-*` values with documented roles)
10. **Provenance / Footer** — LICENSE-FONTS.txt content, Geist OFL attribution, v1.52 milestone tag

### In-Page Navigation

A sticky left sidebar TOC (desktop) / collapsed `<details>` TOC (mobile) with `<a href="#section-id">` anchors. No scroll-spy (requires JS); simple anchor links are sufficient for a one-page reference. No external CSS frameworks.

### Responsive Layout

- Max-width container: 860px centered, 16px side padding.
- Mobile-first: single column at ≤600px, sidebar TOC becomes top `<details>` below 768px.
- Specimen SVGs: `max-width: 100%; height: auto` to scale down on small viewports.
- 360px minimum: test that logo SVGs don't overflow at 360px (logo SVGs have fixed viewBox; `max-width:100%` on the wrapping container is the only rule needed).

---

## Assembly Script Design

Create `brandbook/harness/assemble.mjs` as a standalone Node.js script (ESM, no npm deps required beyond Node's built-in `fs`, `path`, and optionally a markdown-to-HTML converter).

### Markdown rendering consideration

The voice.md and copy.md files are standard Markdown. Choices:
- **Option A (recommended):** Include a minimal inline Markdown renderer or use a lightweight npm dependency. The `marked` package [ASSUMED: `marked` is the standard lightweight Markdown-to-HTML npm package] is ~50 KB and widely used. However, adding a dep creates an install step.
- **Option B:** Pre-convert the markdown to HTML strings inside the assembler using a handful of regex substitutions for the limited Markdown used in voice.md/copy.md (headers, tables, code fences, bold/italic). The files use: `##` headings, `|table|` rows, ` ```code``` ` fences, `**bold**`, and `*italic*` — all achievable in ~80 lines of regex.
- **Recommendation: Option B** (no new deps). The content is static and known; a purpose-built mini-converter is deterministic and keeps the harness dep-free.

### Assembly script inputs and outputs

```
Inputs (all relative to repo root):
  brandbook/tokens/tokens.css
  brandbook/logo/*.svg (13 files)
  brandbook/examples/*.svg (3 files)
  brandbook/voice.md
  brandbook/copy.md
  brandbook/README.md (logo usage rules section)
  brandbook/LICENSE-FONTS.txt

Output:
  brandbook/index.html  (committed)
```

The script must be idempotent: running it twice produces the same output. Use `git diff --exit-code brandbook/index.html` as a determinism gate.

---

## Quality-Gate Checklist (Full Definitions) [VERIFIED: quality-gate-checklist.md on disk]

The Phase-180 quality-gate checklist lives at `.planning/phases/180-brand-audit-dna-lock/quality-gate-checklist.md` and has 8 criteria:

| # | Criterion | Full Definition | Verification Method |
|---|-----------|-----------------|---------------------|
| 1 | Designer-buildable | Each brandbook section could be rebuilt from its token/artifact inputs alone | Human review: every section has a visible "source" annotation or heading citing the input file |
| 2 | Engineer-implementable | Every CSS token has a documented role + usage rule; no magic values | Human review of token reference section: every `--accrue-*` has description and axMap note |
| 3 | Dark-mode | All color surfaces pass WCAG AA-large (≥ 3:1) in dark theme; accent usage rules honored | Playwright screenshot in dark mode; visual check; contrast already verified in Phase 180 |
| 4 | Small-size | Primary lockup readable at 32px; icon mark recognizable at 16px (screenshot evidence) | Playwright screenshot at 32px × 32px of `accrue-mark.svg` (already done in Phase 183 QA) |
| 5 | Specific-to-Accrue | No element of the identity could plausibly be mistaken for another billing or fintech brand | Human UAT judgment |
| 6 | No-thrash | Zero changes to `accrue_admin/assets/css/theme.css`; zero new billing primitives; no breaking changes | `git diff accrue_admin/assets/css/theme.css` exits 0; no Elixir source changes |
| 7 | Size budget | `du -sh brandbook/` ≤ 2 MB | Scripted: `git ls-files brandbook/ | xargs du -c | tail -1` must show ≤ 2,097,152 bytes |
| 8 | Standalone | `brandbook/index.html` opens via `file://` with no server, no build step, no JS framework | Playwright opens `file://` URL; grep for `https?://` in index.html must return no external refs |

---

## Playwright Verification Script

A new `brandbook/harness/verify-brandbook.mjs` should reuse the Playwright instance already installed in `brandbook/logo/harness/node_modules/`.

**Script invocation pattern (from repo root):**
```bash
node brandbook/logo/harness/size-matrix-qa.mjs  # existing
node brandbook/harness/verify-brandbook.mjs      # new
```

Or, to share the existing harness node_modules, have `verify-brandbook.mjs` import Playwright from `../logo/harness/node_modules/playwright` using an explicit path. This avoids a second `npm install`.

**Screenshot matrix:**

| Name | Viewport | Theme | Purpose |
|------|----------|-------|---------|
| `light-desktop` | 1200×900 | light (`data-theme` unset) | Standard desktop light |
| `dark-desktop` | 1200×900 | dark (`data-theme="dark"`) | Dark-mode desktop |
| `light-mobile` | 360×780 | light | 360px floor — no overflow |
| `dark-mobile` | 360×780 | dark | Dark + narrow |

**Key Playwright considerations for `file://` URLs:**
- Playwright's `page.goto('file:///path/to/brandbook/index.html')` works correctly in Chromium.
- For dark-mode: set `data-theme="dark"` via `page.evaluate(() => document.documentElement.dataset.theme = 'dark')` before screenshotting, rather than using `colorScheme: 'dark'` in browser context (the latter only affects `prefers-color-scheme`, but the toggle initializes from it — so `colorScheme: 'dark'` in context options also works).
- Use `page.waitForLoadState('networkidle')` — on `file://` this resolves immediately with no network.
- Screenshots go to `.planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots/` (not in `brandbook/` per ROADMAP guardrail).

**External request verification:**
```bash
grep -o 'https\?://[^"'"'"' ]*' brandbook/index.html | grep -v '^$'
# Must return empty output
```

---

## Existing Harness Reuse

| Tool | Location | Reuse in Phase 186 |
|------|----------|--------------------|
| Playwright | `brandbook/logo/harness/node_modules/playwright` | Import directly via file path in `verify-brandbook.mjs`; no second install needed |
| Chromium | `/opt/homebrew/bin/chromium` (also Playwright-managed) | Playwright uses its own managed binary; confirmed working in Phase 183 |
| svgo | `brandbook/logo/harness/` and `brandbook/tokens/harness/` | Not needed in Phase 186 (no SVG generation) |
| `size-matrix-qa.mjs` pattern | `brandbook/logo/harness/` | The `buildHtmlPage()` + blank-render guard pattern is the exact template for `verify-brandbook.mjs` |
| Token generators | `brandbook/tokens/harness/` | Not needed; `tokens.css` is already generated and committed |

A new `brandbook/harness/` directory is clean separation — it owns only the assembly + verification scripts for Phase 186, with no cross-harness deps.

---

## Common Pitfalls

### Pitfall 1: Forgetting `node_modules/` is untracked but counted by `du -sh`

**What goes wrong:** Running `du -sh brandbook/` includes `brandbook/logo/harness/node_modules/` which is hundreds of MB, making it appear the budget is blown.
**Root cause:** `du` does not respect `.gitignore`.
**How to avoid:** Use `git ls-files brandbook/ | xargs du -c | tail -1` for the committed-weight check. Alternatively, `du -sh --exclude=node_modules brandbook/` — but the `git ls-files` approach is authoritative.
**Warning signs:** `du -sh brandbook/` reports ≫ 2 MB before Phase 186 work even begins.

### Pitfall 2: Dark-mode tokens use `--accrue-dark-*` names, not overriding light names

**What goes wrong:** The brand book CSS uses `--accrue-surface-base` for dark backgrounds and gets the light Paper value (#fafbfc), resulting in a white background in dark mode.
**Root cause:** The tokens.css dark block defines new `--accrue-dark-base` etc., not overriding `--accrue-surface-base`. This is a deliberate brand-book design: dark tokens are named separately.
**How to avoid:** Dark-surface sections must explicitly use `--accrue-dark-base`, `--accrue-dark-primary`, etc. in CSS rules scoped to `[data-theme="dark"]` in the brand book's own `<style>`.

### Pitfall 3: SVGs with `font-family="Geist, system-ui, sans-serif"` look wrong on machines without Geist

**What goes wrong:** `palette.svg` and other specimen SVGs use live `<text>` elements with `font-family="Geist, system-ui, sans-serif"`. On machines without Geist installed, labels fall back to system-ui.
**Root cause:** Specimen SVGs (unlike logo SVGs) use live `<text>` elements, not outlined paths.
**How to avoid:** This is acceptable — the fallback is system-ui which renders the labels clearly. Do not try to base64-embed fonts to "fix" this; it would blow the budget. Document the fallback in the brand book.

### Pitfall 4: Social card PNG is too heavy to inline as base64

**What goes wrong:** Inlining `accrue-social-card.png` (28 KB) as a base64 `src` in the HTML adds ~38 KB and is unnecessary — `<img src="../logo/accrue-social-card.png">` works on file:// for a relative local path.
**Root cause:** Over-engineering the "self-contained" constraint to include rasters.
**How to avoid:** The self-containment constraint is about "no external network requests" — a local relative `<img src>` reference to a file in the same directory tree satisfies this. Only inline rasters if they are tiny (favicon PNGs at 100–265 bytes could be inlined without budget impact, but there is no benefit).

### Pitfall 5: `<script>` dark-mode toggle counts as "JS framework"

**What goes wrong:** Author omits the dark-mode toggle script to avoid violating "no JS frameworks."
**Root cause:** Misreading the constraint. BOOK-01 says "zero JS frameworks" — vanilla `<script>` with no dependencies is explicitly not a framework.
**How to avoid:** A `<script>` block of 20–30 lines with no `import` statements and no `npm` dependency is the correct implementation.

### Pitfall 6: Assembly script committed but not idempotent

**What goes wrong:** Re-running `assemble.mjs` produces a different `index.html` (e.g., timestamps, non-deterministic file ordering).
**Root cause:** Non-deterministic iteration order or injected dates.
**How to avoid:** Sort all input file arrays lexicographically. Avoid injecting `new Date()` into the HTML (version string from package.json or git tag is acceptable if static). Run `git diff --exit-code brandbook/index.html` as the determinism gate.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown → HTML | Custom full Markdown parser | Minimal purpose-built converter for the 6 constructs actually used in voice.md/copy.md | voice.md and copy.md use only: `##`/`###` headings, `| table |` rows, ` ```code``` ` fences, `**bold**`, `*italic*`, and `-` bullets — 80 lines of regex is sufficient and dep-free |
| Dark-mode detection | `window.matchMedia` polling loop | One-time read on page load + localStorage persistence | No polling needed; OS theme changes are a nice-to-have, not a requirement |
| Budget verification | Full directory scan script | `git ls-files brandbook/ \| xargs du -c \| tail -1` | One shell line is the authoritative answer |
| External request audit | Network monitor | `grep -o 'https\?://' brandbook/index.html` | Static analysis on a static file is complete |
| Font embedding | woff2-to-base64 pipeline | System-font fallback stack | Adds ~110 KB per weight and violates budget safety margin |

---

## Code Examples

### Dark-mode toggle (vanilla JS, no framework)

```html
<!-- At bottom of <body> — no framework, no import -->
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

Source: [ASSUMED] — idiomatic pattern for CSS custom property theming with `data-theme` attribute; consistent with how tokens.css defines its dark selectors.

### Playwright file:// screenshot (reuse from size-matrix-qa.mjs pattern)

```javascript
// verify-brandbook.mjs — excerpt
import { chromium } from '../../logo/harness/node_modules/playwright/index.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const HTML_PATH = path.resolve(__dirname, '../../index.html');
const FILE_URL = `file://${HTML_PATH}`;

const browser = await chromium.launch();
const contexts = [
  { name: 'light-desktop', width: 1200, height: 900, theme: 'light' },
  { name: 'dark-desktop',  width: 1200, height: 900, theme: 'dark'  },
  { name: 'light-mobile',  width: 360,  height: 780, theme: 'light' },
  { name: 'dark-mobile',   width: 360,  height: 780, theme: 'dark'  },
];

for (const ctx of contexts) {
  const page = await browser.newPage({ viewport: { width: ctx.width, height: ctx.height } });
  await page.goto(FILE_URL);
  await page.waitForLoadState('domcontentloaded');
  if (ctx.theme === 'dark') {
    await page.evaluate(() => { document.documentElement.dataset.theme = 'dark'; });
  }
  await page.screenshot({ path: `qa-screenshots/${ctx.name}.png`, fullPage: false });
  await page.close();
}
await browser.close();
```

Source: [ASSUMED] — adapted from `size-matrix-qa.mjs` on disk (which uses `chromium.launch()`, `page.goto()`, `page.screenshot()`).

### Budget check command

```bash
# Authoritative committed-weight check (excludes node_modules):
git ls-files brandbook/ | xargs du -c | tail -1
# Must be < 2097152 bytes (2 MB)

# Quick working-dir check (only safe if node_modules is untracked and excluded):
du -sh --exclude=node_modules brandbook/
```

### External request audit

```bash
# Must return empty:
grep -o 'https\?://[^"'"'"'> ]*' brandbook/index.html
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate CSS files linked via `<link>` in single-page docs | Inline `<style>` for guaranteed file:// portability | 2020+ for offline-first docs | Removes any path-resolution ambiguity on file:// |
| `prefers-color-scheme` media queries only | `data-theme` attribute + JS toggle + `prefers-color-scheme` initialization | ~2021 | Allows manual override without losing OS default |
| SVG as `<img src>` in HTML | SVG inlined in markup | Standard for icon-level SVGs | Enables CSS inheritance and eliminates path coupling |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | System-font fallback (Geist, system-ui) is acceptable for brand book body text on developer machines | Budget Analysis / Font Delivery | Low: fallback is legible; only risk is inconsistent typographic appearance on machines without Geist installed |
| A2 | The `data-theme` attribute toggle pattern is consistent with tokens.css `:root[data-theme="dark"]` selector | Dark-Mode Strategy | Zero: tokens.css literally uses this selector — confirmed by disk read |
| A3 | `marked` or a similar npm Markdown library would require a new harness/package.json dep install step | Assembly Script Design | Low: Option B (inline regex converter) eliminates this dep; risk is only if voice.md/copy.md use Markdown features not covered by the 6 identified constructs |
| A4 | Playwright's `file://` navigation works without special flags | Playwright Verification | Low: Playwright Chromium supports `file://` natively; confirmed by Phase 183 use of local file rendering via `data:text/html` wrapper |
| A5 | Relative `<img src>` paths from `brandbook/index.html` to `brandbook/logo/accrue-social-card.png` work in `file://` context | Budget Analysis | Zero: file:// resolves relative paths; this is standard browser behavior |

---

## Open Questions (RESOLVED)

1. **Should the assembly script go in a new `brandbook/harness/` or be co-located in `brandbook/logo/harness/`?**
   - What we know: `brandbook/logo/harness/` already has Playwright; `brandbook/tokens/harness/` has the token generators; a separate `brandbook/harness/` would be the natural third sibling.
   - Recommendation: Create `brandbook/harness/` for `assemble.mjs` and `verify-brandbook.mjs`. Import Playwright from `../logo/harness/node_modules/playwright` with a relative import path to avoid a second `npm install`. This keeps harnesses scoped and avoids cross-harness deps in `package.json`.

2. **Should `brandbook/harness/` have its own `package.json`?**
   - What we know: The script needs no npm packages if it imports Playwright from the logo harness path directly. Node's built-in `fs`, `path`, `url` are sufficient for the assembler.
   - Recommendation: No `package.json` for the assembly harness — it is a standalone Node script with zero npm deps. Add a comment at the top documenting the Playwright import path.

3. **`du -sh brandbook/` vs. `git ls-files | xargs du -c` — which does the quality gate use?**
   - What we know: The quality-gate-checklist.md says `du -sh brandbook/ ≤ 2 MB`. This will include `node_modules/` (currently hundreds of MB) and is therefore a guaranteed false-positive failure unless run with exclusion.
   - Recommendation: The verify script should use `git ls-files brandbook/ | xargs du -c | tail -1` as the authoritative check, and note in the gate output that this is equivalent to the checklist intent. Flag this in PLAN.md so the checklist is understood as "committed weight" not working-dir weight.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Assembly script, verify script | Yes | v22.14.0 | — |
| Playwright | `verify-brandbook.mjs` | Yes | ^1.59.1 (in `brandbook/logo/harness/node_modules/`) | — |
| Chromium | Playwright screenshots | Yes | `/opt/homebrew/bin/chromium` (also Playwright-managed) | — |
| npm | Phase 186 adds no new installs | n/a | — | — |

No missing dependencies. Phase 186 requires zero new npm installs.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Playwright (Node.js, `^1.59.1`, already installed) |
| Config file | No playwright.config — scripts invoked directly |
| Assembly script | `node brandbook/harness/assemble.mjs` |
| Verify script | `node brandbook/harness/verify-brandbook.mjs` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| BOOK-01 | file:// opens with no build step, no JS framework, no external requests | Automated | `node brandbook/harness/verify-brandbook.mjs` (opens file://, screenshots) + `grep -o 'https\?://' brandbook/index.html` (must be empty) | Both gates automated |
| BOOK-01 | All SVGs are inlined (not `<img src>` for logos) | Automated | `grep '<img' brandbook/index.html | grep -v 'logo/.*\.png'` — must show no SVG `<img>` references | Ensures SVG inline |
| BOOK-01 | No JS frameworks present | Automated | `grep -E '(react|vue|angular|alpine|htmx)' brandbook/index.html` — must be empty | Framework grep |
| BOOK-02 | Renders at light + dark × 360px + desktop | Automated | Playwright screenshots (4 matrix cells) — human eyeball in UAT | |
| BOOK-02 | ≤ 2 MB committed weight | Automated | `git ls-files brandbook/ | xargs du -c | tail -1` — must be < 2097152 | |
| BOOK-02 | designer-buildable (checklist item 1) | Manual | Human UAT | |
| BOOK-02 | engineer-implementable (checklist item 2) | Manual | Human UAT | |
| BOOK-02 | dark-mode WCAG AA-large ≥ 3:1 (checklist item 3) | Already verified | Phase 180 contrast table + Phase 184 tokens — no new measurement needed | |
| BOOK-02 | small-size logo legibility (checklist item 4) | Already verified | Phase 183 QA screenshots at 32px/16px — link those screenshots in VERIFICATION.md | |
| BOOK-02 | Specific-to-Accrue (checklist item 5) | Manual | Human UAT judgment | |
| BOOK-02 | no-thrash (checklist item 6) | Automated | `git diff --name-only accrue_admin/` — must be empty; `git diff --name-only -- '*.ex' '*.exs'` — must be empty | |

### Sampling Rate

- **Per task commit:** `git diff --exit-code brandbook/index.html` (determinism gate, fast)
- **After assembly:** `node brandbook/harness/verify-brandbook.mjs` (Playwright, ~10s)
- **Phase gate before VERIFICATION.md:** All automated checks green + human UAT pass

### Wave 0 Gaps

- [ ] `brandbook/harness/assemble.mjs` — does not yet exist; Wave 1 creates it
- [ ] `brandbook/harness/verify-brandbook.mjs` — does not yet exist; Wave 1 creates it
- [ ] `brandbook/index.html` — does not yet exist; Wave 2 output of running `assemble.mjs`

---

## Security Domain

This phase produces a static HTML file and Node.js dev scripts. No authentication, no server, no data storage. ASVS categories V2/V3/V4/V6 do not apply. V5 input validation is not applicable (no user input). The only relevant security check is the external-request audit (no `https?://` URLs in the committed HTML), which is covered by the grep gate above.

---

## Sources

### Primary (HIGH confidence — verified by disk inspection)
- `brandbook/tokens/tokens.css` — dark-mode strategy (`[data-theme="dark"]` on `:root`) confirmed
- `brandbook/logo/harness/package.json` — Playwright `^1.59.1` confirmed as dep
- `brandbook/logo/harness/size-matrix-qa.mjs` — Playwright `file://`-adjacent pattern (uses `data:text/html` wrapper) confirmed, reusable
- `brandbook/logo/harness/node_modules/.bin/playwright` — Playwright binary confirmed installed
- `git ls-files brandbook/ | xargs du -c` — total 960 KB tracked weight confirmed
- `.planning/phases/180-brand-audit-dna-lock/quality-gate-checklist.md` — 8 criteria confirmed verbatim
- Individual SVG byte sizes — confirmed by `wc -c`
- `brandbook/examples/palette.svg` — live `<text>` elements with `font-family` confirmed (no outlined text in specimens)

### Secondary (MEDIUM confidence)
- `prompts/accrue-brand-book.md` — brand posture ("well-made dev tooling, not fintech") confirmed consistent with BRAND-DNA.md

### Tertiary (LOW / ASSUMED)
- Dark-mode `data-theme` toggle vanilla JS pattern — idiomatic but not verified against a specific primary doc
- `palette.svg` Geist font fallback behavior on machines without Geist — behavioral assumption, not a blocking risk

---

## Metadata

**Confidence breakdown:**
- Material inventory: HIGH — all files read from disk
- Budget analysis: HIGH — byte counts from `wc -c` and `du -c`
- Dark-mode strategy: HIGH — tokens.css selector confirmed
- Assembly script design: MEDIUM — pattern well-established; specific implementation choices (no Markdown dep) are prescriptive recommendations
- Playwright file:// behavior: MEDIUM — consistent with Phase 183 usage, not tested anew this session

**Research date:** 2026-06-14
**Valid until:** 2026-07-14 (stable domain; inputs are locked artifacts)
