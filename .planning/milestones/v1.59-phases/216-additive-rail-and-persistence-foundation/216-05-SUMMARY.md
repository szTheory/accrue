---
phase: 216-additive-rail-and-persistence-foundation
plan: "05"
subsystem: entitlement persistence
tags: [postgresql, ecto, entitlements, privacy]
dependency_graph:
  requires: [216-03, 216-04]
  provides: [bounded evidence locators, scoped observation provenance, database durable-domain checks]
  affects: [phase-217 projector]
tech_stack:
  added: []
  patterns: [prefix-qualified reversible migration, named Ecto constraint mappings]
key_files:
  created: [accrue/priv/repo/migrations/20260802180000_harden_accrue_entitlement_persistence.exs]
  modified: [accrue/lib/accrue/entitlements/account.ex, accrue/lib/accrue/entitlements/observation.ex, accrue/lib/accrue/entitlements/grant.ex, accrue/lib/accrue/entitlements/device.ex, accrue/test/accrue/entitlements/persistence_test.exs, accrue/test/mix/tasks/accrue_install_test.exs]
decisions:
  - "Evidence references accept only 255-byte opaque:// slash-segment locators."
  - "Optional grant provenance remains nullable but is scope-bound when supplied."
metrics:
  duration: 5m
  completed: 2026-08-02
status: complete
---

# Phase 216 Plan 05: Persistence Hardening Summary

RAIL-03 durable evidence now has privacy-bounded locators, normalized idempotent identities, and PostgreSQL-enforced provenance/domain invariants.

## Tasks Completed

1. Added RED coverage then implemented blank identity normalization, opaque evidence validation, and composite source-observation provenance.
2. Added RED coverage then mapped all durable database checks and verified installer migration propagation.

## Verification

- `cd accrue && mix test test/accrue/entitlements/persistence_test.exs test/accrue/entitlements/fake_fixture_test.exs test/mix/tasks/accrue_install_test.exs` — passed.
- `cd accrue && mix test.all` — blocked by pre-existing formatting drift in unrelated documentation test files; no task files were changed to address it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected a test helper’s atom/string constraint-name comparison.**
- **Found during:** Task 2
- **Fix:** Compare Ecto’s stored constraint names as strings.
- **Files modified:** `accrue/test/accrue/entitlements/persistence_test.exs`
- **Commit:** `84acc104`

## Deferred Issues

- Full `mix test.all` remains blocked by unrelated formatting drift reported in documentation tests; focused persistence, fixture, and installer suites pass.

## Self-Check: PASSED

- Hardening migration exists and all four task commits are present in Git history.
