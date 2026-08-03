---
phase: 218-apple-observation-and-repair
plan: "04"
subsystem: entitlements
tags: [apple, lineage, repair, postgres, retries]
requires:
  - phase: 218-01
    provides: transactional Apple lineage, projection, and reconciliation wakeup seams
  - phase: 218-03
    provides: private closed-result Apple verification boundary
provides:
  - Authorized bind-once repair for verified unbound Apple lineages
  - Durable Apple quarantine and bounded retry exhaustion outcomes
affects: [apple-reconciliation, entitlement-projection, operator-support]
tech-stack:
  added: []
  patterns: [row-locked unbound-only repair, closed retry state transitions]
key-files:
  created:
    - accrue/test/accrue/entitlements/apple_lineage_test.exs
    - accrue/test/accrue/entitlements/apple_intake_test.exs
    - accrue/test/property/apple_lineage_property_test.exs
    - accrue/test/property/apple_convergence_property_test.exs
  modified:
    - accrue/lib/accrue/entitlements.ex
    - accrue/lib/accrue/entitlements/apple/lineage.ex
    - accrue/lib/accrue/entitlements/apple/intake.ex
    - accrue/lib/accrue/entitlements/decision_cases.ex
key-decisions:
  - "Repair authorization runs before re-verification or database access; the local lineage UUID remains opaque to callers."
  - "Retryable intakes stop automatically after twelve attempts and persist needs_repair rather than disappearing."
requirements-completed: [AAPL-01, AAPL-03]
coverage:
  - id: D1
    description: Authorized repair row-locks and binds a verified unbound lineage while preserving idempotent projection.
    requirement: AAPL-01
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/apple_lineage_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Unbound, unmapped, and exhausted-retry Apple evidence stays durable and non-granting.
    requirement: AAPL-03
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/apple_intake_test.exs
        status: pass
      - kind: unit
        ref: accrue/test/property/apple_convergence_property_test.exs
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 2
status: complete
---

# Phase 218 Plan 04: Apple Observation and Repair Summary

**Authorized, row-locked Apple lineage repair with durable terminal quarantine and twelve-attempt retry exhaustion.**

## Performance

- **Tasks:** 2
- **Files modified:** 9
- **Completed:** 2026-08-03

## Accomplishments

- Added the authenticated `repair_apple_lineage/3` facade, with authorization before re-verification and a row-locked unbound-only binding transition.
- Kept repair projection, hashed-actor audit, and reconciliation wakeup in the same database transaction; injected failures roll back the sequence.
- Classified unmapped and unbound evidence as durable, non-granting outcomes and capped retryable work at `needs_repair` after twelve attempts.
- Extended deterministic decision cases and focused integration/property coverage for repair, quarantine, and retry convergence.

## Task Commits

1. **Task 1: Serialize explicit unbound-lineage repair and conflict races** — `dbc3ad3f` (`feat`)
2. **Task 2: Close intake dispositions, retries, and order-independent convergence** — `c271e959` (`feat`)

## Decisions Made

- A supplied authorization callback must affirm `:repair_apple_lineage` before any provider callback or lineage lookup.
- A bound lineage is never reassigned: same-account repeats are idempotent and conflicting ownership stays non-granting.
- Terminal evidence is not automatically retried; transient retry state becomes `needs_repair` at attempt twelve.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored normal observe failure injection after deferring it for repair.**
- **Found during:** Task 2
- **Issue:** Deferring repair's post-write hook initially skipped the existing observation rollback seam.
- **Fix:** Scoped deferral to the repair path so normal observation callbacks still run after their wakeup write.
- **Verification:** Focused Apple suites passed.

**2. [Rule 1 - Bug] Used a valid ledger actor type for the repair audit.**
- **Found during:** Task 1
- **Issue:** The audit ledger rejects an unregistered `host` actor type.
- **Fix:** Recorded the hashed host actor under the supported `admin` actor category.
- **Verification:** Repair integration test passed.

## Known Stubs

None.

## Next Phase Readiness

The Apple lineage and intake boundary now exposes stable, durable repair and retry outcomes for reconciliation and host-facing support flows.

## Self-Check: PASSED

- Required implementation and focused test files exist.
- Task commits `dbc3ad3f` and `c271e959` exist.
- `cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_*_property_test.exs` passed: 13 tests and 2 properties, 0 failures.
