---
phase: 218-apple-observation-and-repair
plan: "05"
subsystem: entitlements
tags: [apple, reconciliation, oban, ecto, postgres, retries]
requires:
  - phase: 218-01
    provides: transactional Apple reconciliation wakeups
  - phase: 218-04
    provides: durable Apple intake and lineage repair outcomes
provides:
  - Durable Apple reconciliation checkpoint state
  - Replay-safe host-owned wakeup draining and Oban worker
  - Filter-fingerprinted ascending-history final-page commit
affects: [apple-reconciliation, entitlement-projection, operator-support]
tech-stack:
  added: []
  patterns: [row-locked checkpoint, final-page cursor commit, host-owned Oban adapter]
key-files:
  created:
    - accrue/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs
    - accrue/lib/accrue/entitlements/apple/client.ex
    - accrue/lib/accrue/entitlements/apple/reconciliation.ex
    - accrue/lib/accrue/entitlements/apple/reconcile_worker.ex
    - accrue/test/accrue/entitlements/apple_reconciliation_test.exs
  modified: []
key-decisions:
  - "The checkpoint row, not Oban uniqueness, serializes reconciliation and owns pending versus completed history progress."
  - "A history revision becomes completed only after the final page; retry and repair state remains durable."
requirements-completed: [AAPL-04]
coverage:
  - id: D1
    description: Durable Apple checkpoint and host-owned reconciliation worker with bounded retry and filter fingerprinting.
    requirement: AAPL-04
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/apple_reconciliation_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Ascending history preserves pending progress and only commits its completed revision on the final page.
    requirement: AAPL-04
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/apple_reconciliation_test.exs#history advances the completed revision only after the final ascending page"
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 2
status: complete
---

# Phase 218 Plan 05: Apple Observation and Repair Summary

**Durable Apple reconciliation checkpoints with replay-safe Oban wakeups and final-page-only history completion.**

## Performance

- **Tasks:** 2
- **Files modified:** 5
- **Completed:** 2026-08-03

## Accomplishments

- Added environment-qualified reconciliation checkpoints with database constraints, page and attempt budgets, pending/completed revisions, and durable scheduling fields.
- Added a deterministic Apple client Fake, a host-owned Oban worker, and transactional wakeup draining that only deletes wakeups after job insertion succeeds.
- Added stable filter fingerprints, Retry-After/capped backoff handling, and ascending history processing that preserves pending work until `has_more: false`.

## Task Commits

1. **Task 1: Reconcile current status and coalesce durable host-owned work** — `e7111b06` (`test`), `6ffebf8f` (`feat`)
2. **Task 2: Commit ascending history only after the final page** — `57f3b5dc` (`feat`)

## Decisions Made

- Checkpoint locking remains the concurrency authority; Oban uniqueness is enqueue deduplication only.
- Notification history has no direct projection path; status/history remain reconciliation authority.
- Authentication/configuration failures become durable repair state instead of unbounded job retries.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Returned a valid transaction result from reconciliation runs.**
- **Found during:** Task 2
- **Issue:** The checkpoint update result was returned directly from `Repo.transact/1`, causing Ecto to roll back rather than commit it.
- **Fix:** Wrapped the state-machine result in `{:ok, checkpoint}` inside the transaction.
- **Files modified:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex`
- **Verification:** Focused reconciliation suite passed twice.
- **Commit:** `57f3b5dc`

## Known Stubs

None.

## Next Phase Readiness

The Apple reconciliation lane now has durable state, bounded repair outcomes, and a host-owned execution adapter for subsequent public API and telemetry work.

## Self-Check: PASSED

- Required migration, client, reconciliation service, worker, and focused test file exist.
- Task commits `e7111b06`, `6ffebf8f`, and `57f3b5dc` exist.
- `cd accrue && mix compile --warnings-as-errors` and the focused reconciliation suite passed twice.
