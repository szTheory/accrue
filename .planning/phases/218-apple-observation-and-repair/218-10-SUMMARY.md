---
phase: 218-apple-observation-and-repair
plan: 10
subsystem: entitlements
tags: [apple, reconciliation, oban, postgres, cron, repair]
requires:
  - phase: 218-06
    provides: persisted Apple reconciliation checkpoints and strict admission
provides:
  - locked, bounded dispatch of due Apple reconciliation checkpoints
  - host-owned Oban Cron worker for missed-notification repair
  - durable needs-repair transition for invalid scheduled-worker configuration
affects: [220-first-adopter-proof, apple-host-integrations]
tech-stack:
  added: []
  patterns: [checkpoint row lock as scheduler authority, atomic job insertion and reservation]
key-files:
  created: [accrue/lib/accrue/entitlements/apple/reconciliation_sweeper.ex]
  modified:
    - accrue/lib/accrue/entitlements/apple/reconciliation.ex
    - accrue/lib/accrue/entitlements/apple/reconcile_worker.ex
    - accrue/test/accrue/entitlements/apple_reconciliation_test.exs
    - accrue/guides/entitlements.md
key-decisions:
  - "Due checkpoint locks and state transitions, rather than Oban uniqueness, are the scheduled-dispatch authority."
  - "Malformed host configuration transitions a claimed checkpoint to needs_repair before its job is cancelled."
requirements-completed: [AAPL-04]
coverage:
  - id: D1
    description: Missed-notification Apple checkpoints dispatch a scalar worker and repair canonical state through strict admission.
    requirement: AAPL-04
    verification:
      - kind: integration
        ref: "mix test test/accrue/entitlements/apple_reconciliation_test.exs test/accrue/entitlements/apple_source_isolation_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Apple due-cycle dispatch remains durable, bounded, and compatible with reconciliation convergence behavior.
    requirement: AAPL-04
    verification:
      - kind: integration
        ref: "mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs"
        status: pass
    human_judgment: false
duration: 7m
completed: 2026-08-03
status: complete
---

# Phase 218 Plan 10: Scheduled Apple Reconciliation Summary

**Host-scheduled, row-locked Apple reconciliation repairs missed notifications without making Oban or timers entitlement authority.**

## Accomplishments

- Added bounded `FOR UPDATE SKIP LOCKED` due-checkpoint dispatch that atomically inserts privacy-safe `ReconcileWorker` jobs and reserves each checkpoint.
- Added the host-owned `ReconciliationSweeper` Oban worker and runnable queue, Cron, configuration, and safe-disable guidance.
- Made missing or malformed reconciliation configuration persist `needs_repair` before job cancellation, avoiding stranded running checkpoints.

## Verification

- `cd accrue && mix test test/accrue/entitlements/apple_reconciliation_test.exs test/accrue/entitlements/apple_source_isolation_test.exs` — passed twice (19 tests).
- `cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` — passed (37 tests, 1 property).
- `cd accrue && mix compile --warnings-as-errors` — passed.
- `mix format --check-formatted` could not pass because unrelated pre-existing formatting drift remains in Apple lineage/intake/verifier and docs test files; plan-owned files were formatted.

## Task Commits

1. **Task 1: Sweep one missed-notification checkpoint through status/history repair** — `ef46dc17` (TDD RED), `07e3b6a4` (TDD GREEN).

## Decisions Made

- A due checkpoint must be locked and transitioned to `running` in the same transaction that inserts its worker; Oban uniqueness is not the execution lock.
- A configuration failure consumes no provider attempt and only cancels after the durable `needs_repair` transition succeeds.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected an Ecto changeset argument while implementing due dispatch.**
- **Found during:** Task 1
- **Issue:** The initial reservation update passed keyword attributes to a changeset that requires a map.
- **Fix:** Passed a map, preserving atomic job insertion and reservation semantics.
- **Files modified:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex`
- **Verification:** Focused reconciliation suite passed.
- **Committed in:** `07e3b6a4`

## Known Stubs

None.

## Self-Check: PASSED

- All five plan-owned production, test, and guide files exist.
- Both TDD commits (`ef46dc17`, `07e3b6a4`) exist.
