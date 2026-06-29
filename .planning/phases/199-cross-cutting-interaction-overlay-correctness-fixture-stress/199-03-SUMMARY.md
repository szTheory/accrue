---
phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
plan: "03"
subsystem: testing
tags: [exunit, overlay, theme, fixtures, copy, command-palette, phase199]

requires:
  - phase: 199
    provides: Plan 01 Playwright RED contracts for Phase 199 cross-cutting browser behavior.
  - phase: 199
    provides: Plan 02 Node hook RED contracts for scroll, focus, dropdown, and command-palette lifecycle behavior.
provides:
  - ExUnit source contracts for overlay wrapper structure, hidden test mirrors, command-palette overlay equivalence, theme persistence, deterministic fixtures, and CPY-01 copy helpers.
  - RED evidence for command-palette overlay markers, command-palette no-results copy, Phase 199 fixture seed endpoint/helper, and CPY-01 copy helper APIs.
  - Passing regressions for existing overlay wrappers, dropdown non-modal behavior, production `accrue_theme` persistence source, and anti-FOUC ordering.
affects: [phase199, phase200, admin-ui, overlay, fixtures, copy, theme]

tech-stack:
  added: []
  patterns:
    - Mechanical ExUnit source-contract tests over component markup, CSS/source strings, fixture return maps, and copy helper outputs.
    - Validation-scaffolding RED tests that fail only on missing Phase 199 production behavior or helper APIs.

key-files:
  created:
    - .planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-03-SUMMARY.md
  modified:
    - accrue_admin/test/accrue_admin/components/overlay_components_test.exs
    - accrue_admin/test/accrue_admin/components/global_search_test.exs
    - accrue_admin/test/accrue_admin/components/theme_picker_test.exs
    - accrue_admin/test/accrue_admin/theme_test.exs
    - accrue_admin/test/accrue_admin/e2e_fixtures_test.exs
    - accrue_admin/test/accrue_admin/copy_test.exs

key-decisions:
  - "Plan 199-03 remains validation scaffolding: production component, fixture, and copy changes are left to later Phase 199 implementation plans."
  - "The command palette may either migrate to Overlay or declare explicit overlay-equivalent focus/portal markers; the current source satisfies neither contract."
  - "Phase 199 fixture stress expects a narrow deterministic seed helper and endpoint instead of a generic fixture DSL."

patterns-established:
  - "Phase 199 ExUnit source contracts use string-level assertions for wrapper routing, hidden mirrors, anti-FOUC ordering, and production key persistence."
  - "RED failures are acceptable only when they identify missing behavior/helper APIs, not compile, route setup, or import failures."

requirements-completed: [IXN-01, IXN-02, IXN-03, IXN-04, FIX-01, FIX-02, CPY-01]

duration: 30m 06s
completed: 2026-06-29
status: complete
---

# Phase 199 Plan 03: ExUnit Contract Summary

**ExUnit contracts for Phase 199 overlay source structure, production theme persistence, deterministic fixture stress, and CPY-01 copy behavior**

## Performance

- **Duration:** 30m 06s
- **Started:** 2026-06-29T21:40:33Z
- **Completed:** 2026-06-29T22:10:39Z
- **Tasks:** 1
- **Files modified:** 6 test files plus planning closeout metadata

## Accomplishments

- Added Phase 199 overlay source contracts proving drawer and step-up clients continue to route through `DetailDrawer` / `StepUpAuthModal` and that test mirrors stay hidden plus `aria-hidden`.
- Added command-palette ExUnit contracts for Overlay-backed or overlay-equivalent source markers and domain-specific no-results copy.
- Added production theme contracts for the `accrue_theme` JS hook, cookie/localStorage persistence, roving tabindex, and anti-FOUC cookie-over-localStorage ordering.
- Added Phase 199 fixture contracts for deterministic route IDs, edge data, idempotency, and a `/__e2e__/seed/phase199-interaction-matrix` endpoint.
- Added CPY-01 copy contracts for a global-search no-results helper and repeated action hidden-context helper.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ExUnit contracts for source structure, theme, fixtures, and copy** - `d1fa9d8b` (test)

**Plan metadata:** committed after summary and state closeout.

## Files Created/Modified

- `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` - Added Phase 199 wrapper, hidden mirror, and transformed-ancestor source contracts.
- `accrue_admin/test/accrue_admin/components/global_search_test.exs` - Added command-palette overlay-equivalence and no-results copy contracts.
- `accrue_admin/test/accrue_admin/components/theme_picker_test.exs` - Added production theme hook persistence and roving-tabindex source contracts.
- `accrue_admin/test/accrue_admin/theme_test.exs` - Added anti-FOUC production key and cookie precedence contract.
- `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs` - Added Phase 199 deterministic fixture helper and endpoint contracts.
- `accrue_admin/test/accrue_admin/copy_test.exs` - Added CPY-01 global-search no-results and hidden-context copy helper contracts.
- `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-03-SUMMARY.md` - Execution summary and verification record.

## Decisions Made

- Kept this plan test-only because the objective is to lock non-browser proof points before production component, fixture, and copy changes.
- Treated command-palette overlay compliance as either canonical `Overlay` usage or explicit overlay-equivalent markers for focus/portal behavior.
- Required a narrow Phase 199 fixture seed helper and endpoint rather than expanding fixture infrastructure.

## Verification Results

- Baseline before edits: `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/components/global_search_test.exs test/accrue_admin/components/theme_picker_test.exs test/accrue_admin/theme_test.exs test/accrue_admin/e2e_fixtures_test.exs test/accrue_admin/copy_test.exs --max-failures 10` - passed, 47 tests, 0 failures.
- Formatting: `cd accrue_admin && mix format test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/components/global_search_test.exs test/accrue_admin/components/theme_picker_test.exs test/accrue_admin/theme_test.exs test/accrue_admin/e2e_fixtures_test.exs test/accrue_admin/copy_test.exs` - passed after correcting one assertion-string delimiter.
- RED gate after edits: same focused `mix test` command - executed successfully, 58 tests total, 52 passed, 6 failed.

Current RED failures:

1. `GlobalSearchTest` - command palette does not use `Overlay` and does not declare overlay-equivalent focus/portal source markers.
2. `GlobalSearchTest` - command palette still renders generic `No results found for "missing-acme"` copy.
3. `CopyTest` - `AccrueAdmin.Copy.global_search_no_results_copy/1` is missing.
4. `CopyTest` - `AccrueAdmin.Copy.action_hidden_context/2` is missing.
5. `E2EFixturesTest` - `AccrueAdmin.E2E.Fixtures.seed_phase199_interaction_matrix!/0` is missing.
6. `E2EFixturesTest` - `/__e2e__/seed/phase199-interaction-matrix` returns 404.

Acceptance scans:

- Phase markers scan found Phase 199 / CPY-01 assertions in all six planned ExUnit files.
- Modified-file scan confirmed only the six planned test files changed in the task commit.
- Stub scan found only test assertions/comments containing empty-string, nil, or placeholder terms; no UI-rendered stubs were introduced.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

One assertion string used a delimiter that conflicted with Elixir `~s(...)` syntax. It was corrected before verification and before the task commit.

## Auth Gates

None.

## Known Stubs

None. Stub-pattern hits were existing or new test assertions/comments, not UI-rendered placeholder data.

## Threat Flags

None. This plan modified test files only and introduced no new network endpoints, auth paths, file access patterns, schema changes, package installs, or runtime trust-boundary surface.

## TDD Gate Compliance

Task-level RED coverage is present via `d1fa9d8b`. No GREEN commit was made because this plan is validation scaffolding: the acceptance criteria explicitly allow remaining RED failures when they are missing Phase 199 behavior or missing fixture/copy functions rather than compile errors.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `199-04-PLAN.md`, `199-05-PLAN.md`, and `199-11-PLAN.md` to drive the new ExUnit contracts green for command-palette overlay behavior, deterministic Phase 199 fixtures, and CPY-01 copy helpers.

## Self-Check: PASSED

- Found all six modified ExUnit files.
- Found `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-03-SUMMARY.md`.
- Found task commit `d1fa9d8b`.
- Verification log at `/tmp/gsd-199-03-exunit.log` reports 58 tests, 6 expected RED failures.

---
*Phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress*
*Completed: 2026-06-29*
