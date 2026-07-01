---
phase: 194-exemplar-a-dashboard
plan: "01"
subsystem: accrue_admin
tags: [dashboard, spec-overview, data-ax-markers, css, empty-state, kpi-demotion]
requires: []
provides: [spec-overview-machine-hooks, ax-attention-rail-empty-hero, kpi-demotion-css, committed-css-bundle]
affects: [accrue_admin/lib/accrue_admin/live/dashboard_live.ex, accrue_admin/assets/css/app.css, accrue_admin/priv/static/accrue_admin.css]
tech_stack:
  added: []
  patterns: [additive-data-ax-markers, token-only-css, committed-bundle-pattern]
key_files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
decisions:
  - "data-ax-zone markers are additive attributes alongside existing aria-label (no section reordering — D-05 index invariant held by source DOM order)"
  - "data-command-palette-trigger unchanged; data-ax-command-palette-trigger added as sibling marker (command_palette.js binding preserved)"
  - "KPI demotion scoped via [data-ax-zone='kpi-cluster'] to avoid touching shared .ax-kpi-card rules globally"
  - ".ax-attention-rail--empty uses --ax-success fallback to --ax-accent for icon color (no new tokens)"
metrics:
  duration: 322s
  completed_date: "2026-06-25"
  tasks_completed: 3
  files_modified: 3
status: complete
---

# Phase 194 Plan 01: Dashboard SPEC-OVERVIEW Machine Hooks Summary

Dashboard refined to conform to the SPEC-OVERVIEW contract: four `data-ax-zone` markers on zone sections, additive `data-ax-command-palette-trigger` on the ⌘K button, elevated non-interactive empty-state hero class, light KPI demotion CSS, and a regenerated committed bundle — all without moving any zone section.

## What Was Built

Three additive changes to the Dashboard LiveView and one CSS + bundle rebuild:

**Task 1 — Data-ax-* markers (7bd24641):**
- `data-ax-zone="attention-rail"` on Zone 1 `<section aria-label="Billing exceptions">`
- `data-ax-zone="task-launcher"` on Zone 2 `<section aria-label="Tasks">`
- `data-ax-zone="kpi-cluster"` on Zone 3 `<section aria-label={Copy.dashboard_kpi_section_aria_label()}>`
- `data-ax-zone="recent-activity"` on Zone 4 `<section class="ax-grid ax-grid-2">`
- `data-ax-command-palette-trigger="true"` added alongside existing `data-command-palette-trigger="true"` on ⌘K button

**Task 2 — Empty-state hero + KPI demotion CSS (cea57ce2):**
- `ax-attention-rail--empty` class added to the empty card div in LiveView (alongside `ax-card ax-empty`)
- No `role="button"`, no `on-click`, no interactive affordance added
- `.ax-attention-rail--empty` CSS rule added in `app.css` beside the `.ax-empty` block:
  - `gap: var(--ax-space-lg)` and `padding: var(--ax-space-3xl) var(--ax-space-2xl)` (space tokens only, no raw px)
  - Icon color elevated to `var(--ax-success, var(--ax-accent))` (existing tokens, no new tokens)
  - Title elevated to `var(--ax-type-heading-font)` for stronger visual hierarchy
  - No `cursor: pointer`, no `:hover` rule (D-06 non-interactivity guard satisfied)
- KPI demotion scoped via `[data-ax-zone="kpi-cluster"]`:
  - Card border `color-mix`ed to 60% visibility (reads subordinate)
  - Label color set to `var(--ax-muted)` (reduces KPI cluster framing weight relative to attention rail)

**Task 3 — Committed bundle rebuild (2d57cdfd):**
- `mix accrue_admin.assets.build` run from `accrue_admin/`
- `priv/static/accrue_admin.css` regenerated and committed (1 line changed — minified delta confirmed)
- JS bundle not touched (D-04 / command_palette.js unchanged)

## Verification Results

- `mix compile --warnings-as-errors`: clean (storybook asset warning is pre-existing dev-mode noise, not new)
- All 4 `data-ax-zone` enum values present exactly once each in `dashboard_live.ex`
- `data-ax-command-palette-trigger` present on ⌘K button; original `data-command-palette-trigger` unchanged
- `.ax-attention-rail--empty` in LiveView class list (1), `app.css` (4 occurrences — rule + 2 sub-selectors + comment), `priv/static/accrue_admin.css` (1 — minified bundle)
- No `cursor: pointer` on `.ax-attention-rail--empty` (perl guard passed)
- `bash scripts/ci/verify_package_docs.sh`: passed — no RES-04 spacing/focus/ellipsis regression
- All existing `Copy.*` functions retained (no inline strings introduced)

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 | 7bd24641 | feat(194-01): add additive data-ax-* zone markers and ⌘K trigger marker to Dashboard |
| Task 2 | cea57ce2 | feat(194-01): elevate empty-state to non-interactive hero and apply light KPI demotion CSS |
| Task 3 | 2d57cdfd | chore(194-01): rebuild and commit served CSS bundle with Phase 194 deltas |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All data is live (dashboard stats from DB, empty-state copy from `Copy.*` functions).

## Threat Surface Scan

No new auth paths, routes, network endpoints, or schema changes introduced. `data-ax-zone` and `data-ax-command-palette-trigger` markers carry static enum literals only (no PII, no record IDs) — T-194-01 disposition: mitigated as designed. `.ax-attention-rail--empty` is non-interactive (no `cursor:pointer`, no `role="button"`, no `phx-click`) — T-194-02 disposition: mitigated as designed.

## Self-Check: PASSED

- [x] `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — modified (verified via grep/compile)
- [x] `accrue_admin/assets/css/app.css` — modified (verified: `.ax-attention-rail--empty` rule present, no cursor:pointer)
- [x] `accrue_admin/priv/static/accrue_admin.css` — regenerated (verified: bundle contains `.ax-attention-rail--empty`)
- [x] Commit 7bd24641 exists (Task 1)
- [x] Commit cea57ce2 exists (Task 2)
- [x] Commit 2d57cdfd exists (Task 3)
- [x] verify_package_docs.sh passes
