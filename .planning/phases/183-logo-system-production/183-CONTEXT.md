# Phase 183: Logo System Production - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 183 mechanically derives the **locked tournament winner (R2-7 — two-tone B1: 4-step rounded mark, Ink base, Moss `#5E9E84` accent on the top step)** into a complete, production-ready logo system committed at `brandbook/logo/`.

Scope is **production packaging of a frozen design**, not design exploration:
- The mark geometry, generator config, palette, and lockup parameters are **frozen in `182-FREEZE.md`** — regenerate from that config, **never hand-edit path data**.
- Deliverables (ROADMAP SC-1): primary lockup, integrated typemark, icon-only mark, monochrome positive/negative, dark/light versions, favicon (SVG + .ico + PNG), social card (SVG + PNG), with-subtitle variant, clearspace/min-size spec sheet — all outlined paths (no `<text>`, no `@font-face`), svgo-optimized, with accessible `<title>`/`<desc>`.
- `LICENSE-FONTS.txt` documents OFL 1.1 provenance for Geist letterform outlines.
- A size-matrix screenshot validates fidelity across variants/sizes/themes (eyeball checkpoint — fidelity check, not a taste round).

**Out of scope:** any re-litigation of the mark design (locked in Phase 182); design tokens (`brandbook/tokens/` → Phase 184); voice/copy (Phase 185); the standalone HTML brand book (`brandbook/index.html` → Phase 186).

</domain>

<decisions>
## Implementation Decisions

All four discussed areas were researched with parallel deep-research agents (ecosystem-idiom, cross-language lessons, DX, brand-book alignment, creative-direction lenses). The user asked for a cohesive one-shot recommendation set; decisions below are **locked defaults** unless flagged.

### File naming & directory layout
- **D-01:** **Flat `brandbook/logo/` directory** (confirms the v1.52 design-source prior) + a `brandbook/README.md` manifest table (filename · role · when-to-use · format · provenance). No category subdirs — the suite is ~20 files for one mark, well under where nesting earns its keep.
- **D-02:** **Project-prefixed filenames: `accrue-<role>[-<modifier>].svg`**, kebab-case. This **deviates from the design-source's `logo-*` prior** — deliberately. Verified across Prisma (`Prisma-*`), Phoenix (`phoenix*.png`), Oban (`oban-web-logo.svg`), Base (`base-*`): every mature in-repo brand kit prefixes the project name, because these files get **copied OUT** of `brandbook/` into a consumer's `priv/static/images/`, where `logo-primary.svg` is anonymous/collision-prone but `accrue-logo.svg` stays self-describing and greppable.
- **D-03:** **Naming grammar** — `role` ∈ {`logo` = lockup (mark+wordmark), `wordmark` = integrated typemark (type only), `mark` = icon only}. Additive modifiers, ordered tone→background: `-mono` (single-ink positive), `-mono-inverse` (single-ink negative), `-on-dark` (dark-bg artwork). **Default file = light-background, full-color artwork** — only the *exception* (dark bg) earns `-on-dark`; do NOT emit `-on-light` for a file identical to the default. This halves file count and kills the "which is default?" question.
- **D-04:** **Favicon set stays bare/un-prefixed** (`favicon.svg`, `favicon.ico`, `favicon-16.png`, `favicon-32.png`, …) — matches Phoenix's bare `favicon.ico` and universal web-root convention; the prefix would fight host tooling that expects exact names in `<link rel="icon">`.
- **Proposed file tree** (planner may refine, grammar is locked):
  ```
  brandbook/
  ├── README.md                          # manifest + usage rules + provenance
  ├── LICENSE-FONTS.txt                   # OFL 1.1 + Geist provenance
  └── logo/
      ├── accrue-logo.svg                 # PRIMARY lockup (no subtitle)
      ├── accrue-logo-on-dark.svg
      ├── accrue-logo-subtitle.svg        # with-subtitle variant
      ├── accrue-wordmark.svg             # integrated typemark
      ├── accrue-mark.svg                 # icon-only
      ├── accrue-mark-on-dark.svg
      ├── accrue-logo-mono.svg            # monochrome positive
      ├── accrue-logo-mono-inverse.svg    # monochrome negative
      ├── accrue-mark-mono.svg
      ├── accrue-mark-mono-inverse.svg
      ├── accrue-clearspace.svg           # clearspace/min-size diagram
      ├── accrue-social-card.svg / .png   # 1200×630
      ├── favicon.svg / favicon.ico
      ├── favicon-16.png / favicon-32.png / favicon-48.png
      ├── apple-touch-icon.png            # 180×180
      └── icon-192.png / icon-512.png
  ```

### Subtitle variant (with-subtitle lockup)
- **D-05:** **Subtitle string = `Billing for Elixir apps`** — a *functional descriptor*, NOT the tagline. Resolves two tensions coherently: (a) descriptor-over-tagline because the with-subtitle lockup's JTBD is stranger-orientation (slide title cards, docs headers, social cards, conf talks) where recognition beats voice; (b) **Elixir-first per the LOCKED BRAND-DNA qualifier rule** ("always paired with 'Elixir billing library'"). This is verbatim the brand book's #1 canonical short descriptor and its named social-card line.
- **D-06:** The tagline **"Billing state, modeled clearly." stays OUT of the lockup** — it is homepage/editorial typography (Geist sans, Ink), never welded to the mark. Note as a usage rule in `brandbook/README.md`, not a shipped lockup file.
- **D-07:** **Subtitle typographic spec:** Geist **Mono** Regular (400) — mono subordinates it to the Geist *sans* wordmark and reads as a caption/dev-tool label; cap-height **0.42×** the logotype cap-height; color **Slate `#3A4754`** (Ink-family neutral, ~7.8:1 on white, AAA — NOT Moss, which is barred sub-24px on light); **left-aligned to the wordmark's left edge**; stacked **below** the wordmark (baseline ≈ 0.55× logotype cap-height below); tracking **+0.02em**; **sentence case** ("Billing for Elixir apps"). Ship exactly **one** with-subtitle variant.

### Raster + favicon.ico toolchain
- **D-08:** **Add one zero-runtime-dependency tool: `@resvg/resvg-js`** for producing committed PNG/.ico rasters; keep existing `pngjs ^7` + `svgo ^4`. **Rationale (flagged — see note):** the harness's Playwright/Chromium screenshots are **not byte-stable across machines/CI** (documented 1–2px drift, AA/color-profile variance), which is disqualifying for SC-1's "deterministic, re-runnable, committed" raster artifacts. `resvg` renders byte-identical output cross-arch by design, ships prebuilt binaries + WASM, has zero transitive runtime deps, and supports exact render-at-size. **`sharp` rejected** (per-arch native binaries → CI friction; a second rasterizer diverges from the SSOT). Outlined-path masters mean no font-hinting divergence risk.
- **D-09:** **Rasterize at target size** (never downscale a large raster — render-at-size gives crisp pixel hinting at 16/32px). **Hand-write a ~40-line zero-dep ICO packer** over the rendered 16/32/48 PNG buffers (ICO = 6-byte header + 16-byte dir entries + verbatim-embedded PNGs); unit-test header bytes / entry count / offsets / pngjs round-trip. No `png-to-ico`.
- **D-10:** **Keep Playwright/Chromium for the SC-4 size-matrix QA screenshot** (the visual-fidelity eyeball) — it stays the gallery/QA SSOT; it is only removed from the *committed-raster production path*.
- **D-11:** **Emit set:** `favicon.ico` (packs 16/32/48), `favicon-16/-32/-48.png` (transparent), `favicon.svg` (outlined SVG passthrough), `apple-touch-icon.png` 180×180 (**opaque** brand bg + ~16px safe padding — iOS clips transparency), `icon-192.png` + `icon-512.png` (transparent, web manifest), `accrue-social-card.png` 1200×630 (**opaque**, OpenGraph). Pin determinism: committed `svgo.config.mjs`, lockfile pins resvg binary, CI re-run asserts `git diff --exit-code` over the artifact dir.

### Clearspace / minimum-size spec sheet
- **D-12:** **Two deliverables with a strict source-of-truth split** to eliminate number drift: (1) `brandbook/logo/accrue-clearspace.svg` = the annotated **diagram** (illustration of the ratio, no authoritative px digits); (2) a **"Logo usage" section in `brandbook/README.md`** = the **single source of truth** for all hard min-size numbers. No separate `USAGE.md` (one section in the already-required README is least-surprising). Mirrors the AsyncAPI/Gatsby lean-brand pattern (numbers in markdown table, diagram illustrative only).
- **D-13:** **Clearspace = one step-height (`sh`) of the mark on all four sides**, for both the icon-only mark and the full lockup (one mental model, two contexts). Grounded in frozen geometry (`viewBox 0 0 40 40`, `sh = 10` = ¼ of mark height). Expressed as a **ratio**, never absolute px. The SVG's `<title>`/`<desc>` state the ratio rule in words (accessible + self-describing, can't drift).
- **D-14:** **Minimum sizes** (live ONLY in the README table): icon-only mark **16px** (favicon floor — already validated PASS in 182-FREEZE); primary lockup **120px** wide; with-subtitle lockup **168px** wide (subtitle x-height needs ~40% more width; below it, drop subtitle → use primary). These are defensible anchors; the SC-4 size-matrix screenshot is the empirical check — if tight at QA, adjust the **README table only** and the diagram inherits it. The 16px mark floor does not move.

### Claude's Discretion (planner)
- Exact harness file org for the new raster/ico step (`generate-rasters.mjs` etc.), how phase-dir paths are parameterized, plan/wave breakdown.
- Whether `accrue-clearspace.svg` includes build-substituted px captions or stays geometry-only (if substitution is awkward, geometry-only is fine — README owns the digits).
- Exact `<desc>` copy, README manifest table columns, OFL provenance wording in `LICENSE-FONTS.txt`.
- Final favicon `.ico` size set if 48 proves unnecessary (16/32 minimum; SC-1 says multi-resolution).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Frozen design (authoritative — regenerate, never hand-edit)
- `.planning/phases/182-tournament-convergent-refinement/182-FREEZE.md` — **THE authoritative source.** Generator config for R2-7, computed geometry (`viewBox 0 0 40 40`, `accentPathD`), color fills, lockup parameters (gapRatio 0.15, Geist "accrue"), monoMap (`#5E9E84`→`#818181`), and the explicit Phase 183 derivation instructions (import `generate` from `b-step-r2.mjs`, call `assembleLockup`, apply svgo, outline all paths).
- `.planning/phases/182-tournament-convergent-refinement/harness/dirs/b-step-r2.mjs` — the locked-winner generator (SSOT for mark geometry).

### Reusable pipeline
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/` — working pipeline: `geist-spine.mjs` (Geist load + glyph extraction), `assemble-lockup.mjs` (`assembleLockup` — coordinate contract documented in module header; palette supports per-element fills for two-tone), `generate.mjs`, `render-matrix.mjs`, `build-gallery.mjs`, `lint.mjs`. Has `playwright ^1.59`, `pngjs ^7`, `svgo ^4`, `opentype.js ^2`, `geist`, `wawoff2` installed.
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/181-REVIEW.md` — 18 findings; triage policy (D-182-13): fix only what the production pipeline exercises.

### Brand constraints (binding)
- `.planning/phases/180-brand-audit-dna-lock/BRAND-DNA.md` — **LOCKED qualifier rule** ("always paired with 'Elixir billing library'"), palette + usage rules (Moss large-text-only on light), Geist typography, 4 hard logo constraints.
- `.planning/phases/180-brand-audit-dna-lock/logo-brief.md` — 4 hard constraints + the Phase-183 derived-suite target list.
- `prompts/accrue-brand-book.md` — full brand strategy (gitignored, on disk). Canonical short descriptor "Billing for Elixir apps"; tagline "Billing state, modeled clearly."; social-card direction (dark bg, line/grid motif, wordmark, one clean tagline).

### Milestone plan & roadmap
- `.planning/research/v1.52-brand-system-design.md` — target `brandbook/` layout (the `logo-*` prior that D-02 deliberately supersedes), milestone phase shape, repo-bloat ≤2MB budget, SVG-first / PNG-only-where-required posture.
- `.planning/ROADMAP.md` Phase 183 — goal + 4 success criteria.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **181 harness, post-fix verified**: `node_modules` already installed (opentype.js, svgo, playwright, pngjs, geist, wawoff2). Reuse this dir or a copy — version-identical, cheaper than reinstall.
- `assembleLockup(markPathD, glyphs, config)` — glyphs carry baked absolute X, baseline y=0; mark scaled `s = capHeight/markHeight` onto `BASELINE = capHeight*1.1`. Palette config already extended to per-element fills (two-tone) in Phase 182. Coordinate contract documented in module header — **honor it; the 181 coordinate-space bug shipped a broken gallery because nobody looked at the PNGs.**
- `b-step-r2.mjs generate({steps:4, stepHeight:0.25, stepWidth:0.25, curvature:0.05, accentStep:true})` → `{markPathD, accentPathD, markWidth:40, markHeight:40}`.

### Established Patterns
- ESM `*.mjs` harness modules with a `--test` script convention; svgo + pngjs already wired.
- **Visual verification is MANDATORY before the checkpoint** (D-182-10): the agent must Read the rendered PNGs. Blank-render guard stays.
- **No unused rendering contracts** (D-182-11): every generator output field must be consumed by the assembler or not exist — wire color/raster structure end-to-end and verify in a rendered PNG.
- Lint thresholds are not tuned to explain away bad renders (D-182-12); investigate renders first.

### Integration Points
- Outputs land in NEW `brandbook/` at repo root (first committed brand artifacts — no prior `brandbook/` exists). Exploration artifacts stay in `.planning/`.
- `brandbook/` size budget ≤ ~2 MB (enforced at Phase 186) — SVG-first, PNG only where platforms demand it.
- Downstream: Phase 184 (tokens), 185 (copy), 186 (HTML brand book) all consume `brandbook/logo/` + `brandbook/README.md`.

</code_context>

<specifics>
## Specific Ideas

- **The one internal reconciliation:** the clearspace research agent incidentally used "Billing state, modeled clearly." as the subtitle string; the dedicated subtitle research + the locked BRAND-DNA qualifier rule override this — **subtitle = "Billing for Elixir apps"** (D-05). The 168px with-subtitle min-width (D-14) stands regardless of string.
- **Two notable deviations from priors, both deliberate and reversible (flagged for transparency, not re-decision):**
  1. **`accrue-*` filename prefix supersedes the design-source's `logo-*` prior** (D-02) — justified by the copy-out DX argument, verified against Prisma/Phoenix/Oban/Base.
  2. **`@resvg/resvg-js` added + Playwright removed from the committed-raster path** (D-08) — justified by Chromium's non-determinism vs SC-1's "deterministic, re-runnable, committed" requirement. Playwright stays for QA screenshots.
- Brand-book social-card direction to honor: dark background, subtle line/grid motif, wordmark, one clean descriptor line ("Billing for Elixir apps").

</specifics>

<deferred>
## Deferred Ideas

- **Maskable PWA icon** (`icon-maskable-512.png` with 409×409 safe zone) — optional, only if PWA support is later desired. Not required by SC-1.
- **Tagline-bearing hero asset** — if ever needed, ship as editorial page typography (Geist sans, Ink), not a logo lockup file. Belongs to landing-page/copy work (Phase 185+), not this phase.
- Full 181-harness warning cleanup (remaining REVIEW findings) — only pipeline-exercised fixes happen here (carried from D-182-13).

None of the above expands Phase 183 scope — discussion stayed within the production-packaging boundary.

</deferred>

---

*Phase: 183-Logo System Production*
*Context gathered: 2026-06-13*
