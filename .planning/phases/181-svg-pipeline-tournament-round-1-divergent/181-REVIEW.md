---
phase: 181-svg-pipeline-tournament-round-1-divergent
reviewed: 2026-06-13T01:15:17Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/geist-spine.mjs
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/assemble-lockup.mjs
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/a-strata.mjs
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/b-step.mjs
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/c-arcs.mjs
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/d-typemark.mjs
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/generate.mjs
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/lint.mjs
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/render-matrix.mjs
  - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/build-gallery.mjs
findings:
  critical: 1
  warning: 9
  info: 8
  total: 18
status: issues_found
---

# Phase 181: Code Review Report

**Reviewed:** 2026-06-13T01:15:17Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Reviewed the 10 Node ESM modules of the Phase 181 SVG logo-tournament harness, cross-referencing the 181-06/181-07 SUMMARYs and the four post-completion fixes. The pipeline's overall architecture (generate → lint pre-gate → render-matrix → cull → gallery) is sound, the four documented fixes are in place, and threats T-181-14/T-181-15 are genuinely mitigated. However, the review found one Critical integration defect: Direction C's stroke-based arc geometry (`markGroupSvg`) is never consumed — the arcs were rendered as *filled* chord shapes, making the `strokeWidth` knob inert and causing the gallery to show C candidates that contradict their own displayed rationales (the Round 1 verdict killed Direction C based on these misrenders). The post-completion fixes also left measurable residue: the gap-ratio lint is now tautological (can never fail), the D-direction floor-regeneration path is dead code, a smoke-mode cull can clobber `candidates/index.json`, and several dead exports/constants/comments are stale. The known forward-looking item (hardcoded phase paths, Phase 182 work) was NOT flagged per instructions.

## Critical Issues

### CR-01: Direction C arcs render as filled chord shapes — stroke geometry contract never consumed

**File:** `harness/dirs/c-arcs.mjs:118-166`, `harness/generate.mjs:150-155`, `harness/assemble-lockup.mjs:182`
**Issue:** `c-arcs.mjs generate()` returns both `markPathD` (bare path data) and `markGroupSvg` — a complete `<path d="…" stroke="#181818" fill="none" stroke-width="…" stroke-linecap="round"/>` element documented as "ready to embed in an SVG `<g>` group by assemble-lockup.mjs". Nothing ever consumes `markGroupSvg`. `generate.mjs buildStandardCandidate()` destructures only `{ markPathD, markWidth, markHeight }` and `assembleLockup()` embeds it as `<path d="${markPathD}" fill="${palette.ink}"/>` — fill, no stroke. Confirmed in the shipped artifact: `candidates/C2.svg` contains `<path d="M 5.858,34.142 A 20,20 … M 10.101,29.899 A 14,14 …" fill="#181818"/>`. Consequences:
- Open arc subpaths are filled to their chord, producing solid "dome" shapes instead of concentric stroke rings (181-06-SUMMARY's own spot-check describes "solid dome arc").
- The `strokeWidth` knob (varies 1.5–3.0 across C1–C5) has zero effect on output.
- Inner arcs are mostly invisible — same-winding filled subpaths nest under nonzero fill rule, so `arcCount`/`radiiSpread` barely differentiate candidates.
- The gallery displayed rationales ("Two concentric wide arcs…", "Four short arcs… visible as separate arcs") describing geometry that was not rendered; the Round 1 verdict (R1-C1: "Direction C is dead") was made against misrendered candidates.

**Fix:** Make `assembleLockup` accept an optional pre-built mark element (or a `markStroke` config) and have `generate.mjs` pass `markGroupSvg` through for Direction C:
```js
// assemble-lockup.mjs — accept markElement override
const markEl = config.markElement ?? `<path d="${markPathD}" fill="${palette.ink}"/>`;
// …
`  <g id="mark" transform="translate(${markTx},${markTy}) scale(${s.toFixed(6)})">`,
`    ${markEl}`,
```
Note: stroke-width is in mark-local units and scales with the group transform, which is the desired behavior. If Direction C stays dead per R1-C1 this can be recorded as a known-invalid round input instead, but the dead `markGroupSvg` contract must then be removed so the misrender cannot recur in Phase 182's harness reuse.

## Warnings

### WR-01: Smoke-mode cull rewrites candidates/index.json with only the smoke subset

**File:** `harness/render-matrix.mjs:205-213, 319-323`
**Issue:** In `--smoke` mode, `candidates` is filtered to one candidate per direction (max 4). The blank-render guard "runs always, even in smoke mode" (line 249-253) and adds to `culledIds`. Step 4 then computes `surviving = candidates.filter(...)` — from the *smoke-filtered subset* — and when `culledIds.size > 0` writes that subset over `candidates/index.json`, silently destroying the index entries for all candidates not rendered in the smoke run (e.g., 19 entries collapse to 3). One blank render in a smoke run corrupts the pipeline's source-of-truth index.
**Fix:** In smoke mode, never rewrite the index; or compute `surviving` from the full index read from disk:
```js
const fullIndex = JSON.parse(fs.readFileSync(indexPath, "utf8"));
let surviving = fullIndex.filter(c => !culledIds.has(c.id));
```

### WR-02: lockup-gap-ratio lint is tautological — it can never fail after Fix 3

**File:** `harness/generate.mjs:157-164`, `harness/lint.mjs:164-177`
**Issue:** `buildStandardCandidate` synthesizes `markBbox = { …, xMax: markWidth * s }` and `logotypeBbox = { xMin: markWidth * s + gap }` where `gap = capHeight * 0.15` — the *same formula* `assembleLockup` uses to place the elements. The lint then computes `(logotypeBbox.xMin - markBbox.xMax) / capHeight`, which is always exactly `0.15` by construction, permanently inside the 0.08–0.35 band. The lint no longer measures any geometry (real optical gap also includes the first glyph's left side bearing, which is ignored) and provides false assurance in `lint-results.ndjson`. The measurement function that previously fed it, `computeMarkBbox`, is now imported but never called (see IN-02). Additionally the synthesized `markBbox.yMin/yMax` (0..capHeight) does not match the actual placement (0.1–1.1 × capHeight).
**Fix:** Either measure the rendered geometry (mark scaled bbox xMax vs. first glyph's `xMin + glyphTx` from `extractGlyphs` bounding boxes — already available per glyph), or delete the lint for A/B/C and document that gap is enforced by construction.

### WR-03: Direction D floor-regeneration path is dead code with an undefined-variable latent bug

**File:** `harness/generate.mjs:384-394`
**Issue:** In the Step 5 retry loop, the D-direction branch is `else { /* Direction D — try a different CONFIGS entry */ continue; }`, so for `dir === "D"` every config iteration continues. The subsequent `if (dir === "D") { candidate = buildTypemarkCandidate(variantConfig, font); }` (lines 390-391) is unreachable — and if it were ever reached, `variantConfig` would be `undefined` (it is only assigned in the A/B/C branches), throwing inside `buildTypemarkCandidate`. Net behavior: when Direction D is below the D-05 floor, the code logs "running targeted regeneration" but performs none — the log message is misleading and the comment ("try a different CONFIGS entry") describes behavior that does not exist.
**Fix:** Remove the unreachable `dir === "D"` dispatch and the misleading log for D, or implement D regeneration (e.g., mutate `echoOpacity`/`fillLevel` and call `buildTypemarkCandidate`). At minimum:
```js
if (dir === "D") {
  console.warn(`[generate] WARN: Direction D below floor — no regeneration strategy; add configs in dirs/d-typemark.mjs`);
  break;
}
```

### WR-04: D1/D4 echo offset is imperceptible — motif knobs in the wrong coordinate space

**File:** `harness/dirs/d-typemark.mjs:43, 74`
**Issue:** Glyphs are extracted at `FONT_SIZE = 1000` (cap height ≈ 714–730 units), but `echoOffset` is `{ dx: 4, dy: 4 }` (D1) and `{ dx: 3, dy: 3 }` (D4) — an offset of ~0.4% of the em. In a 320px-wide gallery tile of the ~3300-unit-wide viewBox, the echo is shifted under half a device pixel: the "cc echoed layers" motif is invisible and D1 renders as effectively plain "accrue" with a coincident 0.35-opacity duplicate underneath. The knob values look authored for the ~40-unit mark-local space used by Directions A/B/C (where 4 units = 10% of mark height). The self-review and Round 1 verdict therefore judged D1/D4 without the motif they claim to demonstrate. (`stepDepth: 28`/`stepWidth: 60` are also small relative to em — ~11% of the e's width — but at least visible.)
**Fix:** Scale echo offsets to font units, e.g. `echoOffset: { dx: 40, dy: 40 }` (~5.5% of cap height), or define knobs as fractions of capHeight and multiply at build time: `const dx = config.echoOffsetRatio * capHeight;`

### WR-05: Monochrome lint jsdoc is factually wrong, and assemble-lockup's default palette would fail its own pipeline's lint

**File:** `harness/lint.mjs:122-126`, `harness/assemble-lockup.mjs:126`
**Issue:** `lintMonochromeDeriv`'s jsdoc states "Brand colors (#111418, #24303B, #FAFBFC, #E9EEF2) all have saturation < 0.15." This is false: #111418 has sat = 7/24 ≈ 0.29 and #24303B has sat = 23/59 ≈ 0.39 — both exceed the 0.15 threshold and would be culled. The file's own smoke-test comments (lines 427-437) work this out and contradict the jsdoc four screens above. Meanwhile `assembleLockup`'s default palette is `{ ink: "#111418", … }` — any caller relying on the default (instead of explicitly passing `#181818`, as `generate.mjs:99` does) would have 100% of standard candidates culled with a confusing "saturated fill color" reason. The c-arcs/d-typemark headers document the conflict correctly; the lint's own API doc does not.
**Fix:** Correct the jsdoc to state #111418/#24303B exceed the threshold, and change `assembleLockup`'s default ink to `#181818` (or remove the palette default entirely and require it).

### WR-06: a-strata `amplitude` knob semantics inverted relative to rationales and code comment

**File:** `harness/dirs/a-strata.mjs:94-97` and `CONFIGS` (lines 18-59)
**Issue:** `w = BASE_WIDTH * (amplitude + (1 - amplitude) * t)` makes `amplitude` the *top-bar width fraction*: higher amplitude = wider top bar = **less** taper (amplitude 1.0 = no taper at all). The rationales claim the opposite — A2 (0.5) is "strong taper" vs A1 (0.3) "moderate taper" (A1 actually tapers more), and A5 (0.6) "aggressive taper" actually has the *least* taper in the set. The comment on line 94 ("layer 0 (top) is narrowest when amplitude > 0") is also wrong — top is narrowest as amplitude approaches 0. These rationales are displayed verbatim in the gallery and recorded in `candidates/*.json`, misdescribing what the judge sees and what Phase 182 would refine from.
**Fix:** Either rename the knob to `topWidthFraction` and rewrite the five rationales to match the actual geometry, or invert the formula to match the intent: `w = BASE_WIDTH * (1 - amplitude * (1 - t))`.

### WR-07: avatar-circle tile has no circular crop — judged dimension never exercised

**File:** `harness/render-matrix.mjs:49, 124-155`
**Issue:** The `avatar-circle` tile is defined as a 96×96 square and `buildTileHtml` special-cases only `mono` (grayscale filter) and `ink-dark` (color swap). No `border-radius: 50%`/clip is ever applied, so the "avatar circle" screenshot is just a small square render — identical in kind to paper-light. The self-review's `avatar-crop-integrity` dimension (scored per 181-07-SUMMARY, e.g. B4's "boxy at avatar crop" note) was scored against PNGs in which no circular crop exists, so corner-clipping risk — the entire point of the tile — was never visible.
**Fix:**
```js
const circleStyle = tile.id === "avatar-circle"
  ? `<style>body { border-radius: 50%; overflow: hidden; }</style>` // or wrap svg in a clipped div
  : "";
```
(Clip a wrapper div, then screenshot the div rather than the svg element.)

### WR-08: T-181-13 mitigation is provenance-only — gallery inlines SVGs with no active-content guard

**File:** `harness/build-gallery.mjs:441-445, 71-79`
**Issue:** `buildGallery` inlines `candidates/{id}.svg` file contents verbatim into `round-1-gallery.html`. The T-181-13 threat ("gallery inlines SVGs — should be path-only, no scripts/event handlers") is mitigated only by the assumption that the files came from the local generators; there is no enforcement anywhere in the pipeline — neither lint.mjs nor build-gallery rejects `<script>`, `on*=` attributes, `<foreignObject>`, or external `href`s. A hand-edited or stale candidate file flows straight into a file:// page that the user is instructed to open. Additionally, `renderCandidate` HTML-escapes `rationale` but interpolates `id` and `direction` unescaped into attribute and element context (`data-id="${id}"`, `<h2>${id}</h2>`).
**Fix:** Add a cheap guard before inlining and fail the build on match:
```js
if (/<script|\son\w+\s*=|<foreignObject|href\s*=\s*["']?(?!#)/i.test(svgContent)) {
  throw new Error(`[gallery] active content detected in ${c.id}.svg — refusing to inline`);
}
```
and pass `id`/`direction` through `escapeHtml`.

### WR-09: Gallery clipboard fallback `<pre onclick="this.select()">` throws TypeError on every click

**File:** `harness/build-gallery.mjs:486`
**Issue:** `select()` is not a method on `HTMLPreElement` (it exists on input/textarea), so the inline handler throws `TypeError: this.select is not a function` on every click of the verdict box. The fallback only works by accident because the CSS sets `user-select: all` (line 338), which selects the content on click anyway. This is the designated Pitfall-4 fallback path for browsers that block `navigator.clipboard` on file:// pages — its JS half is broken.
**Fix:** Replace the inline handler with a Range-based selection (and move it into VERDICT_JS):
```js
var r = document.createRange(); r.selectNodeContents(this);
var s = getSelection(); s.removeAllRanges(); s.addRange(r);
```

## Info

### IN-01: Nonsense unused computation in generate.mjs summary

**File:** `harness/generate.mjs:466`
**Issue:** `const failed = rawCandidates.length - (rawCandidates.length - culled);` simplifies to `culled` and the variable is never used (the log on 467-469 uses `passed`/`culled`).
**Fix:** Delete the line.

### IN-02: Dead exports/imports/constants left by post-completion fixes; unused npm dependency

**File:** `harness/generate.mjs:28, 53`; `harness/assemble-lockup.mjs:49-77, 194`; `harness/package.json:17`
**Issue:** Fix 2 removed generate.mjs's size cull but left `TARGET_GALLERY_SIZE` (line 53) unused. Fix 3 replaced bbox measurement with synthesized bboxes but left `computeMarkBbox` imported (generate.mjs:28) and exported yet never called anywhere — and its alternating-x/y parsing is wrong for the `h`/`v`/`a` commands the generators emit (arc flags parsed as coordinates), so it would mis-measure if revived. `svgo` is declared in package.json but never imported by any harness module.
**Fix:** Remove the unused import/constant/dependency; delete or rewrite `computeMarkBbox` (with a real path parser) if Phase 182 needs measured bboxes for WR-02.

### IN-03: D3 emits an unreferenced `<clipPath>` def; D2 doc claims clipPath/mask implementation that doesn't exist

**File:** `harness/dirs/d-typemark.mjs:226-228, 350-362`
**Issue:** `buildUFillingInterval` builds `<defs><clipPath id="d3-u-clip-u">…</clipPath></defs>` but nothing references the clip (the code comment itself explains the render-order approach used instead) — dead markup shipped in every D3 SVG, with a non-namespaced id that would collide if multiple copies were ever inlined. `buildSteppedECrossbar`'s jsdoc says "Implemented via SVG clipPath… via SVG masking" while the implementation is a Paper-colored overlay path.
**Fix:** Delete the `defs` block; correct both jsdocs to describe the overlay/render-order technique.

### IN-04: Stale/contradictory comments left by the fix sequence

**File:** `harness/render-matrix.mjs:56, 105-110, 287`; `harness/dirs/b-step.mjs:107-108`
**Issue:** (a) Blank-render doc says coverage is checked on "the paper-light or 32px-favicon tile" — only paper-light is checked. (b) `applyInkDarkColors` doc says "Uses a two-pass approach" while the very next comment and the code describe/implement a single-pass alternation regex. (c) Comment "Move SVG to rejected/" — the code *copies*; culled candidates' `.svg`/`.json` remain in `candidates/` (only index.json is updated), so a later standalone `node lint.mjs` run will lint stale culled files. (d) b-step: "Top corners only: rounded top-left and top-right…" immediately followed by "Full rounded rect for simplicity (all 4 corners)".
**Fix:** Update the comments; optionally `fs.rmSync` the culled `.svg`/`.json` from `candidates/` to keep the directory consistent with index.json.

### IN-05: Blank-render culls counted in the 16px-lint counter

**File:** `harness/render-matrix.mjs:271, 407-409`
**Issue:** `culled16px++; // reuse counter` on the blank-render path makes the final summary line ("culled by 16px lint") misattribute blank-render rejections.
**Fix:** Separate `culledBlank` counter; report both.

### IN-06: geist-spine `--test` smoke runs at import time without an entry-point guard; fallback warning misreports errors

**File:** `harness/geist-spine.mjs:71-73, 143-157`
**Issue:** The smoke block triggers on `process.argv.includes("--test")` with no `isMain` check (lint.mjs:551 does this correctly). Any future importer invoked with a `--test` flag would run the smoke and `process.exit(0)` mid-import, silently aborting the caller. Separately, `loadGeistFont`'s catch logs "geist npm TTF not found" for *any* failure including a corrupt-TTF `opentype.parse` error, masking the real cause.
**Fix:** Gate on `process.argv[1] === fileURLToPath(import.meta.url)`; log `err.message` in the fallback warning.

### IN-07: Float artifact in viewBox; duplicate element ids across inlined gallery SVGs

**File:** `harness/assemble-lockup.mjs:175-184`; `harness/generate.mjs:91`
**Issue:** `viewboxH` is interpolated unformatted, producing `viewBox="0 0 3974.500 993.9999999999999"` in shipped SVGs (totalW is `.toFixed(3)` but viewboxH is not). Also every lockup uses `id="mark"`, `id="logotype"`, `id="glyph-a-0"`… — once 16 SVGs are inlined into one gallery document these ids are duplicated (invalid HTML; harmless today since nothing references them). Related: `opentype.parse(buf.buffer)` (geist-spine.mjs:70) passes the Buffer's backing ArrayBuffer without `byteOffset`/`byteLength` — safe only because `readFileSync` of >4 KB files returns unpooled buffers; the module documents this exact hazard for the woff2 path yet repeats the pattern for the TTF path.
**Fix:** `viewboxH.toFixed(3)`; prefix ids with the candidate id (or drop them); use `buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength)`.

### IN-08: lint.mjs CLI mode silently runs only 4 of the advertised 6 checks; parsererror lookup is dead code

**File:** `harness/lint.mjs:9, 48-56, 352-363, 500-516`
**Issue:** The header claims the CLI "runs all 6 checks", but standalone CLI invocations construct candidates without `markBbox`/`logotypeBbox`/`capHeight` or PNG paths, so gap-ratio and 16px-legibility are silently skipped for every A/B/C candidate (no log, no record entry). Also `doc.getElementsByTagName("parsererror")` never matches — @xmldom/xmldom (0.9.10 installed) does not synthesize browser-style `parsererror` nodes; only the thrown-fatal-error catch path does the work, so non-fatal XML problems pass.
**Fix:** Log a "skipped (no inputs)" record for the two data-dependent lints in CLI mode and correct the header; drop the parsererror lookup or register an `onError` handler that flags non-fatal errors.

---

_Reviewed: 2026-06-13T01:15:17Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
