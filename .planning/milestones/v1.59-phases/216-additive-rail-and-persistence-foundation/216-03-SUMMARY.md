---
phase: 216-additive-rail-and-persistence-foundation
plan: 03
subsystem: entitlements-persistence
tags: [ecto, postgresql, entitlements, privacy]
dependency_graph:
  requires: [216-01]
  provides: [qualified-observations, current-grants, account-devices]
  affects: [217, 218, 219]
tech_stack:
  added: []
  patterns: [Accrue.Migration, Ecto changesets, partial unique indexes]
key_files:
  created:
    - accrue/lib/accrue/entitlements/observation.ex
    - accrue/lib/accrue/entitlements/grant.ex
    - accrue/lib/accrue/entitlements/device.ex
  modified:
    - accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs
    - accrue/test/accrue/entitlements/persistence_test.exs
decisions:
  - PostgreSQL partial unique indexes remain the authority for durable identity races.
  - Observation rows retain only normalized bounded metadata, a digest, and paired opaque evidence references.
metrics:
  duration: 18m
  completed: 2026-08-02
status: complete
---

# Phase 216 Plan 03: Durable Entitlement Persistence Summary

Rail-qualified observations, grants, and devices now persist under the billing prefix with privacy-bounded provenance, current-row uniqueness, and retained history.

## Completed Tasks

1. Added observation ingestion with event-first and transaction-plus-kind idempotency, bounded metadata validation, and paired evidence-reference enforcement.
2. Added qualified grants with a complete current-row key while preserving superseded and source-item history.
3. Added account-scoped device registrations with independent current installation and thumbprint indexes plus revocation history.

## Verification

- `mix test test/accrue/entitlements/persistence_test.exs` — passed (8 tests).
- Task-tagged observation, grant, and device persistence tests passed during their respective GREEN steps.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Used `is_nil/1` in the fallback Ecto query.
- **Found during:** Task 1
- **Issue:** Ecto rejects `field == nil` query comparisons.
- **Fix:** Switched the fallback identity query to `is_nil(field)`.
- **Files modified:** `accrue/lib/accrue/entitlements/observation.ex`
- **Commit:** 3a069b91

2. [Rule 1 - Test correction] Corrected the missing-identity assertion.
- **Found during:** Task 1
- **Issue:** The fixture removed only the event ID while retaining a valid transaction identity.
- **Fix:** Removed both identifiers in the negative case.
- **Files modified:** `accrue/test/accrue/entitlements/persistence_test.exs`
- **Commit:** 3a069b91

## Deferred Issues

`mix format --check-formatted` reports pre-existing formatting drift in unrelated test files. The plan’s modified files are formatted; unrelated files were not changed.

## Self-Check: PASSED

- Required schema modules, migration, and persistence test file exist.
- Task commits `597b34ce`, `3a069b91`, `260d9768`, `4943b03e`, `52e53481`, and `391d531a` exist.
