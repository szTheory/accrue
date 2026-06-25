---
phase: 191-page-flow-interaction-pass-fixture-stress-microcopy
plan: 02
subsystem: testing
tags: [e2e, fixtures, exunit, admin-ui, page-flow]

requires:
  - phase: 191-page-flow-interaction-pass-fixture-stress-microcopy
    provides: Manifest-driven Phase 191 browser harness from Plan 01
provides:
  - Deterministic Phase 191 E2E fixture matrix with route IDs for every manifest detail placeholder
  - Test-only phase191-matrix seed endpoints under the E2E plug
  - ExUnit coverage for namespace, boundary, non-ASCII, null-field, high-count, webhook failure, and recovery fixture cells
affects: [phase-191, phase-192, admin-e2e, fixture-stress]

tech-stack:
  added: []
  patterns:
    - TDD RED/GREEN fixture contracts in existing ExUnit support
    - Static test-only UUIDs for deterministic route-backed E2E records
    - E2E plug seed endpoints kept under test/support only

key-files:
  created:
    - .planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-02-SUMMARY.md
  modified:
    - accrue_admin/test/accrue_admin/e2e_fixtures_test.exs
    - accrue_admin/test/support/e2e_fixtures.ex
    - accrue_admin/test/support/e2e_plug.ex

key-decisions:
  - "Phase 191 matrix route records use static test-only UUIDs so reset plus reseed returns stable detail route IDs."
  - "The phase191-matrix endpoint remains in test/support E2E plug routes only; no production router or auth paths changed."

patterns-established:
  - "seed_phase191_matrix!/0 calls reset!/0 before inserting namespaced e2e_phase191_* records."
  - "Fixture matrix payload returns both manifest route keys and plan-scoped phase191_* aliases."

requirements-completed: [PAGE-01, PAGE-02, PAGE-03, PAGE-04, SEED-01, SEED-02]

duration: 7 min
completed: 2026-06-19
status: complete
---

# Phase 191 Plan 02: Deterministic E2E Fixture Matrix Summary

**Test-only Phase 191 fixture matrix with deterministic route IDs, boundary state rows, and one-click seed endpoints.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-19T14:42:25Z
- **Completed:** 2026-06-19T14:48:50Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added RED ExUnit coverage for the Phase 191 fixture contract before implementation.
- Implemented `AccrueAdmin.E2E.Fixtures.seed_phase191_matrix!/0` with reset-backed deterministic route IDs and namespaced synthetic data.
- Added `POST /seed/phase191-matrix` and `POST /__e2e__/seed/phase191-matrix` to the test support E2E plug.

## Task Commits

1. **Task 1: Add Phase 191 E2E fixture tests first** - `85197f2b` (test)
2. **Task 2: Implement seed_phase191_matrix! and E2E endpoints** - `c9b134bf` (feat)

## Files Created/Modified

- `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs` - Phase 191 RED/GREEN fixture contract coverage.
- `accrue_admin/test/support/e2e_fixtures.ex` - Deterministic `seed_phase191_matrix!/0` helper and deterministic ID support in existing insert helpers.
- `accrue_admin/test/support/e2e_plug.ex` - Test-only phase191-matrix seed endpoints.

## Decisions Made

- Used static test-only UUIDs for the primary route records so reset plus reseed keeps route IDs stable.
- Returned both manifest route keys (`customer_id`, `jpy_invoice_id`, etc.) and plan-scoped aliases (`phase191_customer_id`, `phase191_invoice_id`, etc.) so browser route resolvers and later plans can consume the same payload.
- Kept all reachability inside `accrue_admin/test/support`; production routes and auth remain unchanged.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep.

## Issues Encountered

- A standalone `mix run` plug probe without `MIX_ENV=test` hit the normal app boot config guard. Reran the probe with `MIX_ENV=test` and an explicitly started `AccrueAdmin.TestRepo`; the endpoint returned the expected payload.

## Known Stubs

None. Stub scan found only test wording/assertions, not UI-rendered placeholder data or unwired fixture values.

## Authentication Gates

None.

## Verification

- RED: `cd accrue_admin && mix test test/accrue_admin/e2e_fixtures_test.exs` failed before implementation with `UndefinedFunctionError` for `seed_phase191_matrix!/0` and 404 for `/__e2e__/seed/phase191-matrix`.
- GREEN/final: `cd accrue_admin && mix test test/accrue_admin/e2e_fixtures_test.exs` passed: 13 tests, 0 failures.
- Endpoint probe: `cd accrue_admin && MIX_ENV=test mix run -e 'Application.ensure_all_started(:postgrex); {:ok, _} = AccrueAdmin.TestRepo.start_link(); ... /seed/phase191-matrix ...'` passed and printed `phase191 matrix endpoint ok`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 can rely on route-backed Phase 191 fixture IDs, boundary counts, non-ASCII data, null optional fields, failed webhook, and at-risk recovery rows without manual database edits.

## Self-Check: PASSED

- Created/modified files exist: `accrue_admin/test/support/e2e_plug.ex`, `accrue_admin/test/support/e2e_fixtures.ex`, and `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs`.
- Task commits found: `85197f2b`, `c9b134bf`.
- Verification rerun passed: `cd accrue_admin && mix test test/accrue_admin/e2e_fixtures_test.exs`.

---
*Phase: 191-page-flow-interaction-pass-fixture-stress-microcopy*
*Completed: 2026-06-19*
