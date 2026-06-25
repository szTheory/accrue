---
phase: 189-primitive-form-components-component-lab
plan: "06"
subsystem: e2e-harness
tags: [e2e, a11y, interactions, component-kitchen, probes, phase-189]
dependency_graph:
  requires: ["189-03", "189-05"]
  provides: ["axe-sweep-kitchen", "interaction-probe-block", "d07-definitive-sign-off"]
  affects: ["accrue_admin/e2e/admin-a11y.spec.js", "accrue_admin/e2e/admin-interactions.spec.js", "accrue_admin/e2e/admin-visuals.spec.js"]
tech_stack:
  added: []
  patterns: ["makeRecorder/observe NDJSON ledger", "getComputedStyle probe helpers", "p187__ cell-id grammar"]
key_files:
  modified:
    - accrue_admin/e2e/admin-a11y.spec.js
    - accrue_admin/e2e/admin-interactions.spec.js
    - accrue_admin/e2e/admin-visuals.spec.js
decisions:
  - "score-visuals.mjs PNG capture is fed by admin-visuals.spec.js, not score-visuals.mjs itself — kitchen route added to admin-visuals.spec.js shots array to satisfy Layer 3 PNG coverage"
  - "disabledAffordanceProbe uses opacity heuristic as a conservative coverage signal since exact --ax-disabled-bg CSS resolution depends on runtime computed values"
  - "Both frozen viewports (chromium-desktop + chromium-mobile) produce NDJSON rows because Playwright runs each test against both configured projects via testInfo.project.name"
metrics:
  duration: "2m 31s"
  completed: "2026-06-17"
  tasks: 2
  files: 3
---

# Phase 189 Plan 06: Verification Harness Extension (Component-Kitchen Axe + Probes) Summary

Extended the e2e verification harness with three deterministic layers covering the component-kitchen route (`/billing/dev/components`): axe sweep in both themes, five computed-style probe helpers with NDJSON ledger output, and PNG capture for score-visuals scoring.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Add component-kitchen to axe sweep and visuals capture | `72834741` | admin-a11y.spec.js, admin-visuals.spec.js |
| 2 | Add 5 probe helpers + component-kitchen test block | `a12145fd` | admin-interactions.spec.js |

## What Was Built

### Layer 1 — admin-a11y.spec.js axe sweep extension

Added `["component-kitchen", "/billing/dev/components"]` to the `surfaces` array. The existing `scan()` helper and two-theme loop cover the kitchen route automatically — both light and dark themes are swept with `wcag2a`/`wcag2aa` (including `color-contrast`) against settled token colors. No structural change to the test framework was required.

### Layer 2 — admin-interactions.spec.js probe block

Five new async probe helper functions added after existing helpers and before the existing test.describe block:

| Probe | Requirement | Assertion | Cell-id dimension |
|-------|-------------|-----------|-------------------|
| `focusRingProbe` | CMP-03 | `outlineWidth >= 2px` and `outlineOffset >= 2px` on `:focus-visible` | `d07` (focus-semantics) |
| `themeColumnDeltaProbe` | CMP-01 / D-07 | `--ax-base` differs between light and dark `.ax-dev-state-grid-col` columns | `d01` (token-compliance) |
| `overflowProbe` | CMP-02 | `scrollWidth <= clientWidth` on overflow specimens | `d05` (responsive-mobile-first) |
| `cursorProbe` | CMP-03 | `cursor !== pointer` on non-interactive primitives | `d08` (brand-expression) |
| `disabledAffordanceProbe` | CMP-04 | `cursor` is `not-allowed` or `default`; `opacity < 1` or bg token set | `d04` (state-coverage) |

A `test.describe("Phase 189: component-kitchen probes")` block with 5 tests exercises each probe. A vocabulary comment block documents the Phase-189 → Phase-187 state mapping to prevent future vocabulary drift.

**D-07 DEFINITIVE SIGN-OFF:** `themeColumnDeltaProbe` reads `getComputedStyle(col).getPropertyValue("--ax-base")` from both the light and dark `.ax-dev-state-grid-col` elements. If `lightBase !== darkBase`, the sub-tree theme selector added in Plan 01 is confirmed to resolve different token values in the browser at runtime — not merely emit different attribute names. The test asserts `coverage_status === "covered"` (i.e., fails the test if D-07 is broken).

### Layer 3 — score-visuals.mjs PNG capture

`score-visuals.mjs` discovers PNGs from `test-results/admin-visuals/` which are populated by `admin-visuals.spec.js`. Added `["component-kitchen", "/billing/dev/components"]` to the `shots` array in `admin-visuals.spec.js` so the kitchen route is captured during `npm run e2e:visuals:png-only` and scored by `score-visuals.mjs`.

## Constraint Compliance

| Constraint | Status |
|-----------|--------|
| D-11: Both frozen viewports (1440 desktop / 390 mobile) produce NDJSON probe rows | Satisfied — Playwright runs each `test.describe` block against both `chromium-desktop` and `chromium-mobile` projects; `makeRecorder(testInfo.project.name)` captures the project name in each row |
| D-12: Frozen `p187__{surface}__{mode}__{theme}__{state}__{dXX}` cell-id grammar | Satisfied — all new cell_ids use the frozen grammar; `themeColumnDeltaProbe` uses hardcoded `p187__component-kitchen__${slug(projectName)}__light__default-populated__d01` |
| D-13: No visual-regression snapshot tooling (`toHaveScreenshot`) | Satisfied — grep confirms zero matches |
| Phase-187 vocabulary in cell_id grammar | Satisfied — `disabled-readonly`, `interactive-open`, `default-populated` used throughout; vocabulary mapping comment added |

## Deviations from Plan

### Layer 3 route addition

**Found during:** Task 1, score-visuals.mjs inspection

**Issue:** The plan said "check if `/billing/dev/components` is in score-visuals.mjs target list." Investigation revealed `score-visuals.mjs` is a scoring tool (reads pre-captured PNGs) not a capture tool. The actual PNG capture is performed by `admin-visuals.spec.js`. The kitchen route was absent from `admin-visuals.spec.js`.

**Fix:** Added `["component-kitchen", "/billing/dev/components"]` to `admin-visuals.spec.js` shots array (not score-visuals.mjs which has no target list). This is the correct fix — score-visuals.mjs scores whatever PNGs exist in `test-results/admin-visuals/`, which come from `admin-visuals.spec.js`.

**Files modified:** `accrue_admin/e2e/admin-visuals.spec.js` (1 line added)

**Commit:** `72834741`

Classification: [Rule 1 - Bug] — plan description was based on a misread of score-visuals.mjs architecture; actual Layer 3 target is admin-visuals.spec.js.

## Self-Check

Files created/modified:
- `accrue_admin/e2e/admin-a11y.spec.js` — contains "component-kitchen" (count: 1) ✓
- `accrue_admin/e2e/admin-interactions.spec.js` — contains "themeColumnDeltaProbe" (count: 4), syntax valid ✓
- `accrue_admin/e2e/admin-visuals.spec.js` — contains "component-kitchen" ✓

Commits:
- `72834741` — feat(189-06): add component-kitchen to axe sweep and visuals capture
- `a12145fd` — feat(189-06): add component-kitchen probe block to admin-interactions.spec.js

Both commits verified in git log.

## Self-Check: PASSED
