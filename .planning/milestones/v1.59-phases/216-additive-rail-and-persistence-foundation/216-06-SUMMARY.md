---
phase: 216-additive-rail-and-persistence-foundation
plan: 06
subsystem: entitlements-persistence
tags: [postgresql, ecto, idempotency, security]
status: complete
human_judgment: false
requires: [216-05]
provides: [account-safe-global-observation-idempotency, provider-byte-boundaries]
affects: [217-canonical-projection, 218-apple-observation]
tech_stack:
  added: []
  patterns: [global-index-plus-account-ownership-check, byte-counted-changesets, named-postgresql-checks]
key_files:
  created:
    - accrue/priv/repo/migrations/20260802200000_bound_accrue_entitlement_provider_identity.exs
  modified:
    - accrue/lib/accrue/entitlements/observation.ex
    - accrue/lib/accrue/entitlements/grant.ex
    - accrue/test/accrue/entitlements/persistence_test.exs
    - accrue/test/mix/tasks/accrue_install_test.exs
decisions:
  - Provider identity remains globally rail/environment-qualified; foreign-account collisions receive an opaque ownership error.
metrics:
  duration: 6m
  completed: 2026-08-02
---

# Phase 216 Plan 06: Provider Identity Hardening Summary

Global provider idempotency is account-safe, byte-bounded at Ecto and PostgreSQL boundaries, and verified with raw SQL constraint evidence.

## Completed Tasks

1. Added failing then passing tracer coverage for global event idempotency, opaque foreign-account collisions, and byte limits.
2. Extended the same ownership result to transaction fallback identities; added grant provenance bounds, named database checks, raw-write proofs, and installer propagation coverage.

## Key Decisions

- Global identity indexes remain the concurrency authority; `insert_idempotently/2` fetches the durable winner and returns it only to its owning account.
- Provider identity columns use `text` with explicit `octet_length` checks, ensuring direct 256-byte writes fail by the stable named constraint rather than an implicit varchar error.

## Verification

- `cd accrue && MIX_ENV=test mix ecto.migrate --quiet`
- `cd accrue && mix test test/accrue/config_entitlements_test.exs test/accrue/entitlements/persistence_test.exs test/accrue/entitlements/fake_fixture_test.exs test/mix/tasks/accrue_install_test.exs test/accrue/docs/entitlements_guide_test.exs` — 77 tests, 0 failures.
- `cd accrue && mix test --warnings-as-errors` — completed successfully.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Made named byte checks reachable for direct SQL proof.
- **Found during:** Task 2
- **Issue:** PostgreSQL `varchar(255)` rejected 256-byte values before the named `octet_length` constraints could run.
- **Fix:** Converted the seven provider identity/provenance columns to `text` in the new reversible migration; the explicit byte checks remain the authoritative limit.
- **Files modified:** `accrue/priv/repo/migrations/20260802200000_bound_accrue_entitlement_provider_identity.exs`
- **Commit:** `b80e5fef`

## Known Stubs

None.

## Self-Check: PASSED

All four task commits exist and the observation, grant, migration, and persistence-test files are present.
