# Phase 183: Logo System Production - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 183-Logo System Production
**Areas discussed:** File naming & layout, Subtitle variant content, Raster/.ico toolchain, Clearspace/min-size spec sheet
**Mode:** Advisor (minimal_decisive tier, technical owner — no plain-language reframe). Two research passes: an initial advisor-researcher pass, then a deeper general-purpose research pass at the user's request (full ecosystem-idiom / cross-language-lessons / DX / brand-book / creative-direction lens), synthesized into a single cohesive locked package.

---

## File naming & directory layout

| Option | Description | Selected |
|--------|-------------|----------|
| Flat + naming convention | All ~20 assets in `brandbook/logo/` with a strict prefix grammar + README manifest | ✓ |
| Nested by category | `lockup/ mark/ favicon/ social/ spec/` subdirs | |

**User's choice:** Flat — then requested deeper research on all four areas.
**Notes:** Deep research (Prisma, Phoenix, Oban, Base repos verified) resolved the `logo-*` (design-source prior) vs `accrue-*` (copy-out self-description) prefix tension **in favor of `accrue-*`** — every mature in-repo brand kit prefixes the project name because files get copied out of the brand folder. Grammar locked: `accrue-<role>[-mono|-mono-inverse][-on-dark].svg`; favicon set stays bare per web convention.

---

## Subtitle variant content

| Option | Description | Selected |
|--------|-------------|----------|
| "Billing for Elixir apps" (descriptor) | Functional descriptor, left-aligned, Geist Mono, neutral grey | ✓ |
| "Billing state, modeled clearly." (tagline) | Brand tagline | |

**User's choice:** Recommended descriptor (confirmed via deeper research).
**Notes:** Descriptor over tagline because the with-subtitle lockup's JTBD is stranger-orientation (slide cards, docs headers, social cards). Elixir-first per the **LOCKED BRAND-DNA qualifier rule** — the first advisor pass had recommended "Billing for Phoenix." but lacked the BRAND-DNA grounding; corrected to "Billing for Elixir apps" (brand book's #1 canonical descriptor). Tagline stays editorial, never welded to the mark. Full type spec captured in CONTEXT D-07.

---

## Raster + favicon.ico toolchain

| Option | Description | Selected |
|--------|-------------|----------|
| Playwright render-at-size + zero-dep ICO packer | Reuse Chromium, hand-written ICO container | partial |
| Add png-to-ico (pure-JS) | Pure-JS .ico packing | |
| Add @resvg/resvg-js | Byte-stable cross-arch rasterizer | ✓ (deeper research) |

**User's choice:** Deeper research changed the recommendation.
**Notes:** Initial pick was Playwright-only (zero new deps). Deep research surfaced that **Chromium screenshots are not byte-stable across machines/CI** — disqualifying for SC-1's "deterministic, re-runnable, committed" rasters. `@resvg/resvg-js` (zero runtime deps, prebuilt binaries, byte-identical cross-arch) adopted for committed rasters; hand-written zero-dep ICO packer retained; Playwright kept only for QA screenshots; `sharp` rejected. Flagged in CONTEXT as a notable-but-reversible deviation.

---

## Clearspace / minimum-size spec sheet

| Option | Description | Selected |
|--------|-------------|----------|
| USAGE.md + annotated clearspace.svg | Markdown table = numbers, SVG = diagram | ✓ (refined) |
| USAGE.md only | Markdown, no diagram | |

**User's choice:** Hybrid (refined by deeper research).
**Notes:** Refined to: `accrue-clearspace.svg` = diagram (ratio illustration, no authoritative digits); the **"Logo usage" section of `brandbook/README.md`** = single source of truth for min-size numbers (no separate `USAGE.md`). Clearspace = one step-height (`sh`) of the mark all sides (ratio, from frozen `viewBox 0 0 40 40`). Min-sizes: mark 16px, lockup 120px, with-subtitle 168px. AsyncAPI/Gatsby lean-brand pattern.

## Claude's Discretion

- Harness file org for the raster/ico step, phase-dir path parameterization, plan/wave breakdown.
- Whether clearspace SVG includes build-substituted px captions or stays geometry-only.
- `<desc>` copy, README manifest columns, OFL provenance wording, final `.ico` size set.

## Deferred Ideas

- Maskable PWA icon (optional, not SC-1).
- Tagline-bearing hero asset → editorial page typography in copy work (Phase 185+), not a logo file.
- Remaining 181-harness REVIEW warnings → only pipeline-exercised fixes here (D-182-13).
