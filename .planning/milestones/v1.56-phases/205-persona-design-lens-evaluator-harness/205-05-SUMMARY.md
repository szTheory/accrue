---
phase: 205-persona-design-lens-evaluator-harness
plan: 05
subsystem: admin-ui-ratchet
tags: [e2e, playwright, capture, bbox, geometry, region-tags, D-09]
status: complete
requires:
  - "205-01: REGION_SELECTORS SSOT (region_tag → ax-* selector map) in ratchet/region-tags.js"
provides:
  - "Capture-time .bbox.json sidecars (per surface/viewport/theme) recording each region_tag's ax-* selector boundingBox or null"
affects:
  - "Phase 207: digest region overlay consumes .bbox.json geometry"
  - "Phase 207/206: optional presence cross-check (region tagged but selector absent → downgrade to content-body)"
tech-stack:
  added: []
  patterns:
    - "Defensive CommonJS require of ratchet module — capture harness is broader than the ratchet, so the bbox emit is additive and no-ops if region-tags.js is absent"
    - "boundingBox() geometry is capture-time EVIDENCE only; excluded from every deterministic identity field (D-09)"
key-files:
  created: []
  modified:
    - accrue_admin/e2e/admin-visuals.spec.js
decisions:
  - "Bbox capture is inlined into captureThemes so geometry is recorded in the same data-theme state as the PNG it accompanies (light → ${name}.bbox.json, dark → ${name}-dark.bbox.json)"
  - "Selector resolution is try-wrapped with a count() guard so a wrong/unconfirmed/absent ax-* selector yields a null box, never an exception that aborts the sweep"
metrics:
  duration: 4m
  completed: 2026-07-03
---

# Phase 205 Plan 05: Capture-time selector bounding-box emitter Summary

Extended the existing `accrue_admin/e2e/admin-visuals.spec.js` capture harness with a capture-time `.bbox.json` emitter (D-09) that records each `REGION_TAGS` region's `ax-*` selector bounding box (or `null` when absent) as a sibling of every PNG, feeding the Phase-207 digest overlay and the optional presence cross-check — with geometry excluded from the deterministic claim-key.

## What Was Built

- **`captureBBoxes(page, name, project, theme)` helper** alongside `captureThemes`. It iterates the `REGION_SELECTORS` map (region_tag → `ax-*` selector) imported from `ratchet/region-tags.js`, resolves `page.locator('.' + selector).first()`, and records `boundingBox()` when `count()` is truthy, else `null`. Output object is keyed by `region_tag` and written to the `.bbox.json` sibling.
- **Filename/dir convention reused**: `test-results/admin-visuals/${project}/${name}.bbox.json` (light) and `${name}-dark.bbox.json` (dark), matching the existing `-dark` PNG suffix so each sidecar sits beside its PNG.
- **Per surface × viewport × theme**: `captureBBoxes` is called inside `captureThemes` immediately after each themed screenshot, so the geometry is recorded in the same `data-theme` state as the PNG it accompanies. The 23-surface sweep therefore produces a bbox sidecar for every capture point across the Playwright project (viewport) matrix.
- **Defensive import**: `REGION_SELECTORS` is `require`d in a `try`/`catch`; if the ratchet module is absent the spec still runs and the emit no-ops (`captureBBoxes` early-returns), since the capture harness is a broader tool than the ratchet.

## Binding constraints honored (D-09 / T-205-05)

- **Geometry is `.bbox.json`-only** — it never touches `claim_key`, `finding_id`, or any `candidates.ndjson` identity field. This spec writes no identity anywhere; it only shoots PNGs and now sidecar geometry.
- **Absent selector → null box, never a crash** — the selector loop is `try`-wrapped with a `count()` guard, so the `// TODO: confirm selector` markers still carried by `REGION_SELECTORS` from Plan 01 are safe: an unconfirmed/absent/wrong selector yields `null` (the intended presence cross-check fallback).
- **Additive** — existing PNG capture behavior, filenames, and the surface sweep are unchanged; the bbox emit is layered on without altering the screenshot flow.

## Verification

- `node --check accrue_admin/e2e/admin-visuals.spec.js` passes.
- Plan grep gate passes: file contains `bbox`, `boundingBox`, and consumes `region-tags`.
- Ratchet import path confirmed: `require('./ratchet/region-tags.js')` resolves `REGION_SELECTORS` with all 14 region keys.
- Full capture run (`npm --prefix accrue_admin run e2e:visuals:png-only`) is a maintainer step; `.bbox.json` files will appear beside the PNGs.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None. (`REGION_SELECTORS` retains `// TODO: confirm selector` markers from Plan 01 by design — the null-box fallback makes unconfirmed selectors safe, and confirming them is not in this plan's scope.)

## Self-Check: PASSED

- FOUND: accrue_admin/e2e/admin-visuals.spec.js (modified, `captureBBoxes` present)
- FOUND: commit 63d3fc33
