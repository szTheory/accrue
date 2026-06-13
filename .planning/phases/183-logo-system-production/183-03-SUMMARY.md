---
phase: 183-logo-system-production
plan: "03"
subsystem: brandbook/logo
tags: [logo, rasters, favicon, resvg, ico-packer, apple-touch-icon, social-card]

dependency_graph:
  requires:
    - phase: 183-01
      provides: "harness bootstrap — package.json (@resvg/resvg-js), ico-packer.mjs"
    - phase: 183-02
      provides: "All 13 SVG brand artifacts, including fixed accrue-mark.svg and accrue-social-card.svg"
  provides:
    - "brandbook/logo/harness/generate-rasters.mjs — deterministic resvg raster generator"
    - "brandbook/logo/favicon-16.png — 16×16 favicon (transparent)"
    - "brandbook/logo/favicon-32.png — 32×32 favicon (transparent)"
    - "brandbook/logo/favicon-48.png — 48×48 favicon (transparent)"
    - "brandbook/logo/favicon.ico — multi-resolution ICO (16/32/48)"
    - "brandbook/logo/apple-touch-icon.png — 180×180 opaque iOS homescreen icon"
    - "brandbook/logo/icon-192.png — 192×192 PWA icon (transparent)"
    - "brandbook/logo/icon-512.png — 512×512 PWA icon (transparent)"
    - "brandbook/logo/accrue-social-card.png — 1200×630 OpenGraph social card (opaque)"
  affects:
    - "183-04 (size-matrix QA — may embed rasters in QA sheet)"
    - "186 (HTML brand book — embeds raster artifacts)"

tech_stack:
  added: []
  patterns:
    - "resvg render-at-size: fresh Resvg instance per target size, never downscale — D-09 compliance"
    - "Apple-touch-icon inline SVG wrap: opaque #FAFBFC rect + mark paths scaled to 148×148 (180−2×16) — iOS transparency guard"
    - "Blank-render guard: darkPixelCoverage check (color-distance > 30 from #FAFBFC, 0.5% threshold) applied to favicon-32.png and apple-touch-icon.png before write"
    - "Determinism assertion: re-render favicon-16.png, Buffer.equals compare — Resvg byte-stability confirmed"
    - "ICO header assertion: readUInt16LE at 0/2/4 must equal 0/1/3 — applied after packIco()"

key_files:
  created:
    - brandbook/logo/harness/generate-rasters.mjs
    - brandbook/logo/favicon-16.png
    - brandbook/logo/favicon-32.png
    - brandbook/logo/favicon-48.png
    - brandbook/logo/favicon.ico
    - brandbook/logo/apple-touch-icon.png
    - brandbook/logo/icon-192.png
    - brandbook/logo/icon-512.png
    - brandbook/logo/accrue-social-card.png
  modified: []

decisions:
  - "2026-06-13 (183-03): Apple-touch-icon composition uses inline SVG wrapper (opaque #FAFBFC rect + mark paths under scale transform) rendered as single Resvg pass — avoids native compositing, ensures opaque corners, tested with 4-corner alpha check"
  - "2026-06-13 (183-03): Blank-render guard targets color-distance from Paper (#FAFBFC) not luminance — consistent with 183-PATTERNS §pngjs blank-render guard (luminance incorrectly culled Moss in Phase 181)"
  - "2026-06-13 (183-03): Determinism assertion uses Buffer.equals on same-session re-render (buf16 === second) and verified byte-identical"

metrics:
  duration: "8min"
  completed_date: "2026-06-13"
  tasks_completed: 1
  files_created: 9
---

# Phase 183 Plan 03: Raster Export Summary

**Deterministic resvg-based raster pipeline committed — all 8 brand raster artifacts (favicon 16/32/48, favicon.ico, apple-touch-icon, icon-192, icon-512, accrue-social-card) generated, verified, and committed with full guard coverage.**

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | generate-rasters.mjs — deterministic resvg raster + ICO pipeline | 85001492 | generate-rasters.mjs + 8 binary artifacts |

## Verification Results

All plan success criteria met:

1. `ls brandbook/logo/*.png brandbook/logo/*.ico` — 9 files present: PASS
2. Dimension checks for all 7 PNGs (pngjs): PASS
   - favicon-16.png: 16×16
   - favicon-32.png: 32×32
   - favicon-48.png: 48×48
   - apple-touch-icon.png: 180×180
   - icon-192.png: 192×192
   - icon-512.png: 512×512
   - accrue-social-card.png: 1200×630
3. favicon.ico header bytes [0x00 0x00, 0x01 0x00, 0x03 0x00]: PASS
4. Blank-render guard on favicon-32.png: PASS (dark coverage >> 0.5%)
5. apple-touch-icon.png opaque bg (4-corner alpha check): PASS
6. Byte-determinism assertion (Buffer.equals on re-render): PASS
7. `generate-rasters.mjs --verify` exits 0: PASS
8. Total PNG+ICO artifact weight: 60K (well under 2MB) — PASS

## Visual Verification

- **accrue-social-card.png**: Social card reads "Billing for Elixir apps" with both `i` characters in "Elixir" intact (upstream 183-02 fix confirmed propagated). 4-step Ink/Moss mark + "accrue" wordmark centered on dark background correct.
- **favicon-32.png**: 4-step mark visible — Ink (steps 1-3) + Moss accent (step 4/top-right).
- **apple-touch-icon.png**: Mark centered on opaque #FAFBFC background with ~16px padding on all sides. No transparent corners.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All 8 binary artifacts are fully complete production rasters.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes.

Security mitigations applied (from threat model):
- T-183-09 (Resvg binary non-determinism): Mitigated — determinism assertion byte-compares on re-render; PASS.
- T-183-10 (Blank favicon raster committed): Mitigated — blank-render guard (darkPixelCoverage > 0.5%) applied to favicon-32.png before write; PASS.
- T-183-11 (Transparent apple-touch-icon): Mitigated — composition wraps mark in opaque-bg SVG; 4-corner alpha check confirms no transparency; PASS.
- T-183-12 (Raster artifacts drift between runs): Mitigated — determinism assertion built in; byte-identical on re-render; PASS.

## Self-Check: PASSED

- [x] brandbook/logo/harness/generate-rasters.mjs exists
- [x] brandbook/logo/favicon-16.png exists (16×16)
- [x] brandbook/logo/favicon-32.png exists (32×32)
- [x] brandbook/logo/favicon-48.png exists (48×48)
- [x] brandbook/logo/favicon.ico exists (3 entries)
- [x] brandbook/logo/apple-touch-icon.png exists (180×180, opaque)
- [x] brandbook/logo/icon-192.png exists (192×192)
- [x] brandbook/logo/icon-512.png exists (512×512)
- [x] brandbook/logo/accrue-social-card.png exists (1200×630)
- [x] Commit 85001492 exists in git log
- [x] --verify exits 0
- [x] Determinism check: PASS
- [x] Social-card subtitle "Billing for Elixir apps" visually verified — both i glyphs intact
- [x] apple-touch-icon opaque background visually verified
