---
phase: 218-apple-observation-and-repair
plan: 01
subsystem: entitlements
tags: [apple, postgres, projector, reconciliation]
dependency_graph:
  requires: [217-01]
  provides: [apple-lineage-intake, transactional-apple-projection]
  affects: [218-02, 218-05]
tech_stack:
  added: [Ecto migrations]
  patterns: [row-lock ownership claim, transactional outbox, bounded evidence]
key_files:
  created:
    - accrue/priv/repo/migrations/20260803030000_create_accrue_apple_lineages_and_intakes.exs
    - accrue/lib/accrue/entitlements/apple/lineage.ex
    - accrue/lib/accrue/entitlements/apple/intake.ex
    - accrue/lib/accrue/entitlements/apple/reconciliation_wakeup.ex
  modified:
    - accrue/lib/accrue/entitlements/projector.ex
    - accrue/lib/accrue/entitlements.ex
decisions:
  - Apple lineage claims compare the verified opaque account token under a PostgreSQL row lock.
  - The projector retains sole ownership of grants and revisions through an in-transaction seam.
metrics:
  tasks_completed: 1
status: complete
---

# Phase 218 Plan 01: Apple Observation Tracer Summary

Verified Apple evidence now binds one environment-qualified lineage, enters the canonical projector transaction, and produces a revisioned snapshot with a durable reconciliation wakeup.

## Completed Work

- Added bounded lineage, intake, and coalesced reconciliation-wakeup persistence.
- Added closed Apple evidence and outcome values with privacy-safe unbound and ownership-conflict paths.
- Refactored the existing projector into a transaction-owning public wrapper and an internal composition seam.
- Added real Repo tracer coverage for happy path, duplicate, unbound, conflict, and total rollback.

## Verification

- `cd accrue && mix test test/accrue/entitlements/apple_observation_tracer_test.exs`
- `cd accrue && mix test test/accrue/entitlements/projector_test.exs test/accrue/entitlements/apple_observation_tracer_test.exs`

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Task commits exist: `d245550f`, `d77310f7`.
- All planned Apple persistence, facade, projector, and tracer files exist.
