---
phase: 217-canonical-projection-and-compatibility
plan: 02
subsystem: entitlements
tags: [elixir, ecto, postgresql, stream-data, property-testing]
requires:
  - phase: 217-canonical-projection-and-compatibility
    provides: row-locked canonical projection tracer
provides:
  - deterministic deduplicated snapshot source summaries
  - PostgreSQL-backed projection idempotency and serialized concurrency proofs
  - executable Phase-215 survivor revision conformance
affects: [entitlement projection, compatibility, offline proofs]
tech-stack:
  added: []
  patterns: [deterministic grant-fold properties, unboxed PostgreSQL concurrency barrier, revision-stable survivor retractions]
key-files:
  created: [accrue/test/property/entitlement_projection_property_test.exs]
  modified: [accrue/lib/accrue/entitlements/snapshot.ex, accrue/lib/accrue/entitlements/projector.ex, accrue/test/accrue/entitlements/projector_test.exs, accrue/test/accrue/entitlements/decision_cases_test.exs]
key-decisions:
  - "Snapshot source summaries deduplicate logical equivalents before public serialization and signature comparison."
  - "A source retraction that preserves the same plan-level authorization bounds is a revision-stable no-op."
coverage:
  - id: D1
    description: Canonical snapshots are deterministic across grant order, logical duplicates, incidental metadata, quantity maxima, and expiry cutoffs.
    requirement: ACCT-01
    verification:
      - kind: property
        ref: "cd accrue && mix test test/accrue/entitlements/snapshot_test.exs test/property/entitlement_projection_property_test.exs --exclude live_stripe"
        status: pass
    human_judgment: false
  - id: D2
    description: Repeated and concurrent PostgreSQL projections converge on one current revision without duplicate state.
    requirement: ACCT-02
    verification:
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/projector_test.exs test/property/entitlement_projection_property_test.exs --exclude live_stripe"
        status: pass
    human_judgment: false
metrics:
  duration: "~24m"
  completed_date: "2026-08-03"
status: complete
---

# Phase 217 Plan 02: Canonical Projection and Compatibility Summary

Canonical entitlement snapshots now remain deterministic across grant permutations, logical duplicates, incidental metadata, exact quantity maxima, and cutoff adjacency; PostgreSQL projection repeats and races converge on a single revisioned account truth.

## Completed Work

- Added bounded StreamData properties for deterministic permutation, duplicate, metadata-signature, integer-maximum, cutoff, and empty-snapshot behavior.
- Added PostgreSQL-backed idempotency and unboxed concurrent-projection coverage with a synchronization barrier.
- Re-read persisted account revisions for snapshot reads, preventing stale account structs from reporting obsolete revisions.
- Made equivalent survivor retractions revision-stable while retaining deterministic diagnostic source summaries.
- Bound the projector-visible Phase-215 corpus cases to closed revision/reason outcomes without adding a competing vocabulary.

## Verification

- `mix test test/accrue/entitlements/snapshot_test.exs test/accrue/entitlements/projector_test.exs test/property/entitlement_projection_property_test.exs test/accrue/entitlements/decision_cases_test.exs` — 29 tests, 4 properties, 0 failures.
- Focused `mix format --check-formatted` on all Plan 217-02 source and test files — exit 0.
- `mix test test/accrue/entitlements --exclude live_stripe` run twice consecutively — 160 tests, 0 failures on each run. Post-run SQL confirmed zero matching `concurrent-owner-*` residue.
- Repository-wide `mix format --check-formatted` — blocked by unrelated pre-existing formatting drift outside Plan 217-02.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Read the persisted account revision when a stale account struct is supplied.
   - **Found during:** Task 2 idempotency property.
   - **Fix:** `Snapshot.fetch/2` now reloads the account revision before folding current grants.
   - **Files modified:** `accrue/lib/accrue/entitlements/snapshot.ex`
   - **Commit:** ef464979

2. [Rule 1 - Bug] Prevented a surviving equivalent rail from advancing revision on source-only retraction.
   - **Found during:** Task 2 Phase-215 survivor conformance.
   - **Fix:** Projector compares plan-level effective authorization bounds for retractions while source summaries remain diagnostic-only.
   - **Files modified:** `accrue/lib/accrue/entitlements/projector.ex`
   - **Commit:** ef464979

## Known Stubs

None.

## Self-Check: PASSED

- Task commits `d73fadf0`, `ef464979`, and `e7888a65` exist.
- Snapshot, projector, property, decision-case, and projector test files exist.
