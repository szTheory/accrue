---
phase: 174
plan: 01
subsystem: accrue_admin/css
tags: [design-system, tokens, css, theme]
dependency_graph:
  requires: []
  provides: [--ax-leading-*, --ax-tracking-*, --ax-measure, --ax-transition-*]
  affects: [accrue_admin/assets/css/app.css, Plan 02, Plan 03]
tech_stack:
  added: []
  patterns: [CSS custom properties, token composition, reduced-motion overrides]
key_files:
  modified:
    - accrue_admin/assets/css/theme.css
decisions:
  - Use background-color (not background shorthand) in transition bundles to preserve skeleton shimmer's background-position animation
  - Compose all bundle values from existing --ax-dur-2 and --ax-ease-out atoms; no hardcoded ms or curve values
  - Append reduced-motion bundle overrides inside existing prefers-reduced-motion block (not a new block)
  - Insert new token groups before --ax-z-* block following house comment style
metrics:
  duration: 3m
  completed: "2026-06-03"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
---

# Phase 174 Plan 01: Design-System Token Gap Closure (Type Micro-tokens + Transition Bundles) Summary

**One-liner:** Added 9 type micro-tokens (--ax-leading-*, --ax-tracking-*, --ax-measure) and 4 transition-bundle tokens (--ax-transition-*) to theme.css, composed from existing dur/ease atoms, with reduced-motion overrides using --ax-dur-instant.

## What Was Built

Added all missing design-system token definitions to `accrue_admin/assets/css/theme.css`:

**Type micro-tokens (9 new custom properties):**
- `--ax-leading-tight: 1.2` — display, headings
- `--ax-leading-normal: 1.4` — body, labels (the default)
- `--ax-leading-relaxed: 1.5` — prose / long-form copy
- `--ax-tracking-tight: -0.02em` — large display tightening
- `--ax-tracking-normal: 0`
- `--ax-tracking-wide: 0.04em` — smaller uppercase labels
- `--ax-tracking-caps: 0.08em` — uppercase eyebrows / section labels
- `--ax-measure: 68ch` — reading measure

**Transition-bundle tokens (4 new custom properties):**
- `--ax-transition-colors` — color/background-color/border-color bundle
- `--ax-transition-transform` — transform bundle
- `--ax-transition-shadow` — box-shadow bundle
- `--ax-transition-base` — full colors+transform+shadow combo for cards/tiles

**Reduced-motion overrides (4 bundle overrides inside existing block):**
All 4 transition bundles overridden with `--ax-dur-instant linear` inside the existing `@media (prefers-reduced-motion: reduce)` block.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add line-height, letter-spacing, measure, and transition-bundle tokens to theme.css | 2c564916 | accrue_admin/assets/css/theme.css |

## Verification Results

All acceptance criteria passed:

- `--ax-leading-tight`: 1 occurrence (definition)
- `--ax-leading-normal`: 1 occurrence
- `--ax-leading-relaxed`: 1 occurrence
- `--ax-tracking-tight`: 1 occurrence
- `--ax-tracking-normal`: 1 occurrence
- `--ax-tracking-wide`: 1 occurrence
- `--ax-tracking-caps`: 1 occurrence
- `--ax-measure`: 1 occurrence
- `--ax-transition-colors`: 2 occurrences (definition + reduced-motion override)
- `--ax-transition-transform`: 2 occurrences
- `--ax-transition-shadow`: 2 occurrences
- `--ax-transition-base`: 2 occurrences
- `background ` shorthand in transition rules: 0 occurrences (correct)
- `--ax-transition-all` (forbidden token): 0 occurrences (correct)
- Reduced-motion block contains all 4 bundle overrides using `--ax-dur-instant`

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All tokens are fully defined with correct values. Plan 02 will consume these tokens in the literal→token migration of app.css.

## Threat Flags

None. theme.css changes are CSS custom property definitions only — no executable code, no user input, no auth surface.

## Self-Check: PASSED

- [x] `accrue_admin/assets/css/theme.css` exists and contains all 13 new custom properties (9 type + 4 transition) plus 4 reduced-motion overrides
- [x] Commit 2c564916 exists in git log
- [x] No background shorthand used in transition bundles
- [x] No --ax-transition-all token defined (forbidden)
- [x] Back-compat aliases (--ax-motion-fast, --ax-motion-standard, --ax-theme-transition) untouched
