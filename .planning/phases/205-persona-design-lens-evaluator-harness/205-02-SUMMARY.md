---
phase: 205-persona-design-lens-evaluator-harness
plan: 02
subsystem: design-lens-calibration-assets
tags: [ratchet, design-lens, exemplars, rubric, brandbook, dev-test-only]
dependency_graph:
  requires:
    - "region-tags.js SSOT (plan 01) — DIMENSIONS/severity/justification-token vocab referenced by the rubric"
  provides:
    - "DESIGN-LENS-RUBRIC.md — comparative sub-rubric anchored to brandbook/ (dims 2/3/5/8 + 1/6)"
    - "5 own-render exemplar PNGs (2 good, 3 bad covering both density poles + off-register)"
    - "exemplars/PROVENANCE.json — one version-pinned auditable entry per PNG"
  affects:
    - "Phase 205 plan 04 (design lens) attaches 1 archetype-matched good + 1 bad per call from this set"
    - "Phase 206 operator-density-defender consumes the direction: air|cramped self-flag defined here"
tech_stack:
  added: []
  patterns:
    - "own-render exemplars (MIT repo screenshots) — license-clean by construction (D-19)"
    - "fixed-viewport playwright capture (1280px) — <=1600px wide by construction, no downscale/sharp dep"
    - "CSSOM setProperty distortion for bad poles (strict nonce-only CSP blocks <style> injection)"
    - "closed-shape provenance manifest mirroring baseline-cell.schema.json discipline"
key_files:
  created:
    - accrue_admin/e2e/ratchet/DESIGN-LENS-RUBRIC.md
    - accrue_admin/e2e/ratchet/exemplars/PROVENANCE.json
    - accrue_admin/e2e/ratchet/exemplars/good/dashboard.png
    - accrue_admin/e2e/ratchet/exemplars/good/dev-components.png
    - accrue_admin/e2e/ratchet/exemplars/bad/cramped.png
    - accrue_admin/e2e/ratchet/exemplars/bad/wasteful.png
    - accrue_admin/e2e/ratchet/exemplars/bad/off-register.png
  modified: []
decisions:
  - "off-register shipped as a license-clean own-render PNG (synthesized fintech-glossy on the own admin) rather than the D-19 textual-only fallback — keeps the full 5-image set"
  - "cramped pole synthesized on the current admin via CSSOM tighten (old-SHA baf593f3 boot impractical in this working tree) — D-18/D-19 fallback path, recorded in PROVENANCE"
  - "bad poles injected via element.style.setProperty(...,'important') because the admin's strict nonce-only CSP blocks addStyleTag/<style>"
  - "captured at a fixed 1280px viewport (not fullPage) so every PNG is <=1600px wide with no sharp/sips downscale step and no new npm dep"
metrics:
  duration: "~13m"
  completed: "2026-07-03"
  tasks: 2
  files: 7
status: complete
---

# Phase 205 Plan 02: Design-Lens Calibration Assets Summary

Produced the design-lens calibration anchor set: a committed `DESIGN-LENS-RUBRIC.md` sub-rubric anchored to the current `brandbook/`, a curated 5-image own-render good/bad exemplar set covering both density poles plus an off-register negative, and a version-pinned `exemplars/PROVENANCE.json` with one auditable entry per PNG.

## What Was Built

- **5 own-render exemplar PNGs (Task 1):** captured against the freshly-rebuilt committed CSS bundle (`mix accrue_admin.assets.build` produced no diff, confirming the bundle was already current) via the admin e2e server + Playwright. `good/dashboard.png` (data-dense-operator, the primary density-footgun suppressor) and `good/dev-components.png` (foundation). `bad/cramped.png` + `bad/wasteful.png` cover BOTH density poles; `bad/off-register.png` is a fintech-glossy brand negative. Each is 1280px wide (<=1600 by construction) and encodes well under the 5 MB base64 guard (largest is off-register at ~786 KB base64). No `sharp` / no new npm dependency; no downscale step needed.
- **`DESIGN-LENS-RUBRIC.md` (Task 2):** the D-22 section outline — Purpose & scope; Brand DNA anchor with the verbatim `brandbook/` precedence note; textual comparative tier anchors (Linear/Vercel/Prisma/Tailscale/Oban brand-positive, Stripe density/IA-only under an explicit anti-fintech caveat); sharpened sub-criteria for dims 2/3/5/8 with 1/6 support and NO 13th dimension; d3 penalizing BOTH cramped and wasteful; exemplar-set reference with `surface_type`-keyed archetype matching; a defect-only output contract with the `direction: air|cramped` self-flag; the justification-token vocab; and an anti-patterns/footgun table.
- **`exemplars/PROVENANCE.json` (Task 2):** version-pinned manifest, one entry per PNG with `source_commit_sha`, `bundle_sha256`, capture route/command, viewport, theme, `max_dimensions`, and a curator note (role, density pole, why). Records the CSSOM-distortion method for the bad poles and the re-baseline-only refresh policy.

## Task Commits

| Task | Name | Type | Commit | Files |
| ---- | ---- | ---- | ------ | ----- |
| 1 | Capture + curate 5 own-render exemplar PNGs | feat | `8ccc39d7` | exemplars/good/{dashboard,dev-components}.png, exemplars/bad/{cramped,wasteful,off-register}.png |
| 2 | DESIGN-LENS-RUBRIC.md + exemplars/PROVENANCE.json | feat | `c358f43e` | DESIGN-LENS-RUBRIC.md, exemplars/PROVENANCE.json |

## Verification

- Task 1 automated verify: `exemplar bytes ok` — the 4 mandatory PNGs (and the 5th) all under the 5 MB base64 guard. `off-register.png` shipped as a real PNG (not textual-only).
- Each PNG confirmed 1280px wide via `sips -g pixelWidth` (<=1600 acceptance).
- All 5 PNGs visually inspected: good/dashboard reads correctly-dense; cramped is visibly under-spaced; wasteful is extreme over-whitespace (data pushed below the fold); off-register is unmistakably fintech-glossy (gradients, pill CTAs, serif).
- Task 2 automated verify: `rubric+provenance ok` — rubric contains the `brandbook/` anchor, is `comparative, not absolute`, and names the Linear..Oban tier anchors; PROVENANCE.json parses.
- Provenance-to-PNG cross-check: all 5 entries map to a committed PNG (`every provenance entry maps to a committed PNG`).
- No new npm dependency: `accrue_admin/package.json` unchanged.

## Requirements Delivered

- **EVAL-02** (comparative design lens vs named quiet-dev-tooling exemplars, not an absolute award score): delivered — the rubric is comparative-only, forbids an award/0–100 score, and anchors to textual tier exemplars.
- **EVAL-04** (committed license-clean good/bad exemplar set + committed sub-rubric anchor the lens to brand DNA): delivered — 5 own-render PNGs + `DESIGN-LENS-RUBRIC.md` + `PROVENANCE.json`, all anchored to `brandbook/`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Strict CSP blocked `<style>`/`addStyleTag` injection for the bad exemplars**
- **Found during:** Task 1 (first capture run failed on `page.addStyleTag`)
- **Issue:** The admin serves a strict nonce-only CSP (`style-src 'self' 'nonce-...'`), so Playwright's `addStyleTag` (which injects a `<style>` element) is rejected.
- **Fix:** Switched the bad-pole distortion to deterministic CSSOM mutation — `element.style.setProperty(prop, val, 'important')` over a bounded selector set — which CSP's `style-src` does not govern. Same visual result, CSP-clean.
- **Files modified:** capture-only (throwaway spec, not committed); no committed source changed.
- **Commit:** captured into `8ccc39d7`.

### Plan-allowed choices (not deviations, but recorded)

- **off-register shipped as a PNG, not textual-only.** D-19 permitted a textual-only fallback if no clean own-render existed; a license-clean own-render (fintech-glossy CSSOM distortion of the own admin) was achievable, so the full 5-image set ships.
- **cramped synthesized on the current admin** rather than an old-SHA (`baf593f3`) re-boot, which was impractical in this working tree — the plan's explicit fallback for this case. Method recorded in PROVENANCE.
- **No downscale tool used.** Captured at a fixed 1280px viewport (the plan's "fixed-width playwright capture" option), so PNGs are <=1600px wide by construction — no `sips`/ImageMagick/`sharp` step and no new npm dep.

## Notes for Next Plans

- Plan 04 (design lens): read `DESIGN-LENS-RUBRIC.md` §5 for the `surface_type`-keyed archetype map and attach exactly 2 exemplar images per call (one good + one bad). The rubric's §6 output contract and §7 justification-token vocab match `region-tags.js`.
- The `direction: air|cramped` self-flag (rubric §6) is consumed by the Phase-206 operator-density-defender to apply a higher confirm bar to air-ward findings.
- Capture is reproducible: the recipe (server, route, viewport, CSSOM distortion rules) is recorded in `PROVENANCE.json.capture_recipe`; the reusable capture code with git history is `e2e/admin-visuals.spec.js`. The throwaway capture spec was intentionally not committed.

## Self-Check: PASSED

- FOUND: accrue_admin/e2e/ratchet/DESIGN-LENS-RUBRIC.md
- FOUND: accrue_admin/e2e/ratchet/exemplars/PROVENANCE.json
- FOUND: accrue_admin/e2e/ratchet/exemplars/good/dashboard.png
- FOUND: accrue_admin/e2e/ratchet/exemplars/good/dev-components.png
- FOUND: accrue_admin/e2e/ratchet/exemplars/bad/cramped.png
- FOUND: accrue_admin/e2e/ratchet/exemplars/bad/wasteful.png
- FOUND: accrue_admin/e2e/ratchet/exemplars/bad/off-register.png
- FOUND commit: 8ccc39d7 (Task 1)
- FOUND commit: c358f43e (Task 2)
