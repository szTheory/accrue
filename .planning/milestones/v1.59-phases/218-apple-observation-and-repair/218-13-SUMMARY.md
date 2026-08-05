---
phase: 218-apple-observation-and-repair
plan: 13
subsystem: entitlements
tags: [elixir, apple, reconciliation, intake, projector]
requires:
  - phase: 218-12
    provides: Per-record signed-date verification for Apple reconciliation
provides:
  - Verified unmapped Apple history reaches durable terminal quarantine.
  - Reconciliation continues to later terminal evidence and retracts stale Apple access.
affects: [apple-reconciliation, entitlement-projection, AAPL-03, AAPL-04]
tech-stack:
  added: []
  patterns: [nil logical-plan terminal quarantine, record-local reconciliation continuation]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/apple/admission.ex
    - accrue/test/accrue/entitlements/apple_reconciliation_test.exs
key-decisions:
  - "Preserve missing product mappings as logical_plan: nil so the existing Intake unmapped_product terminal path remains the only non-granting handler."
  - "Keep reconciliation admission unchanged because its existing successful Intake outcome handling continues only after strict verification and bound-lineage checks."
patterns-established:
  - "A verified but unmapped Apple product is durable terminal quarantine, not a verification/configuration retry."
requirements-completed: [AAPL-03, AAPL-04]
coverage:
  - id: D1
    description: Verified unmapped history is quarantined once without creating an observation or grant, while later revoked evidence retracts the stale Apple grant.
    requirement: AAPL-03
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/apple_reconciliation_test.exs#unmapped history quarantines once and allows later terminal evidence to retract a grant
        status: pass
    human_judgment: false
  - id: D2
    description: Replay retains a completed checkpoint and stable observation/grant counts for the same unmapped and terminal history page.
    requirement: AAPL-04
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/apple_reconciliation_test.exs#unmapped history quarantines once and allows later terminal evidence to retract a grant
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-03
status: complete
---

# Phase 218 Plan 13: Unmapped Apple History Repair Summary

**Verified unmapped Apple history now reaches the existing durable quarantine path, allowing later terminal facts to remove stale Apple access without retrying the scan.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-03T18:54:00Z
- **Completed:** 2026-08-03T18:59:00Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Removed the upstream non-nil product-map guard so verified unmatched products enter Intake as `logical_plan: nil`.
- Added an end-to-end Fake reconciliation regression for prior grant → unmapped quarantine → later revocation, including final cursor completion and replay stability.
- Preserved strict verification, bound lineage checks, signed-date reconciliation configuration, and the sole Projector grant writer.

## Task Commits

1. **Task 1: Trace unmapped verified history past quarantine to terminal stale-grant repair** - `01d47f5b` (test), `01aa6e32` (feat)

## Files Created/Modified

- `accrue/lib/accrue/entitlements/apple/admission.ex` - Carries verified unmapped product IDs to Intake with a nil logical plan.
- `accrue/test/accrue/entitlements/apple_reconciliation_test.exs` - Proves terminal quarantine continuation, stale-grant retraction, and replay idempotency.

## Decisions Made

- Use the existing `Intake.persist_terminal/4` unmapped-product outcome rather than add a reconciliation-specific disposition; the pre-existing admission success path already continues only after exact verification and ownership gates.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- AAPL-03/AAPL-04 unmapped history continuation is covered by the full Apple regression suite.
- No schema, public API, lifecycle, identity, Stripe-path, dependency, or coverage-matrix changes were made.

## Self-Check: PASSED

- Confirmed both task commits exist and the two plan-scoped files are present.
- Full Apple suite passed: 1 property, 47 tests, 0 failures; `mix compile --warnings-as-errors` passed.

---
*Phase: 218-apple-observation-and-repair*
*Completed: 2026-08-03*
