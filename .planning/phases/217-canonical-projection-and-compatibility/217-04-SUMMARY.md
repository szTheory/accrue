---
phase: 217-canonical-projection-and-compatibility
plan: 04
subsystem: entitlements
tags: [elixir, ecto, entitlement, compatibility, canonical-projection, telemetry]
requires:
  - phase: 217-01
    provides: canonical entitlement snapshots and persistence identities
provides:
  - disabled/shadow/enabled authority selection with explicit cohort validation
  - durable clean-window/blocker evidence and account-scoped authority transitions
  - canonical Snapshot resolver projection and mapped Stripe backfill seam
affects: [entitlements, gates, canonical-projection, multi-rail-adoption]
tech-stack:
  added: []
  patterns: [fail-closed compatibility configuration, resolver-compatible snapshot projection, idempotent current-grant writes]
key-files:
  created:
    - accrue/lib/accrue/entitlements/compatibility.ex
    - accrue/lib/accrue/entitlements/resolver/canonical.ex
    - accrue/lib/accrue/entitlements/compatibility_audit.ex
    - accrue/lib/accrue/entitlements/compatibility_state.ex
    - accrue/priv/repo/migrations/20260803013000_create_accrue_entitlement_compatibility_evidence.exs
  modified:
    - accrue/lib/accrue/config.ex
    - accrue/lib/accrue/entitlements/resolver.ex
    - accrue/test/accrue/entitlements/compatibility_test.exs
key-decisions:
  - "A present multi_rail configuration dispatches through Compatibility so every request selects one authority once."
  - "Backfill is restricted to entitling Stripe subscription rows with a locally mapped price and writes only durable account/grant records."
  - "Clean-window comparisons, blockers, enablement, and rollback are persisted as privacy-bounded audit/state evidence rather than process-local state."
patterns-established:
  - "Compatibility telemetry uses a bounded application metadata allowlist, hashes actor IDs, and is recursively privacy-negative tested for every span phase."
requirements-completed: [ACCT-04]
coverage:
  - id: D1
    description: Disabled authority, missing shadow/enabled cohort rejection, and clean-window precision.
    requirement: ACCT-04
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/compatibility_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Mapped Stripe backfill remains resumable and does not duplicate account/current-grant rows on repeat.
    requirement: ACCT-04
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/compatibility_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Existing resolver and advisory-isolation regressions remain green after compatibility dispatch.
    requirement: ACCT-04
    verification:
      - kind: integration
        ref: cd accrue && mix test test/accrue/entitlements --exclude live_stripe (twice)
        status: pass
    human_judgment: false
duration: 19min
completed: 2026-08-03
status: complete
---

# Phase 217 Plan 04: Canonical Projection and Compatibility Summary

**Fail-closed LocalMap/canonical authority lane with durable clean-window evidence, rollback-only authority state, privacy-safe telemetry, and idempotent mapped Stripe backfill.**

## Performance

- **Duration:** 19 min
- **Completed:** 2026-08-03T01:40:00Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Added normalized account cohorts, MFA fail-closed handling, and digest-bound half-open clean-window validation.
- Persisted comparison/blocker evidence plus account-scoped canonical/LocalMap transitions; rollback changes only authority state and leaves canonical rows byte-equivalent.
- Added recursive privacy-negative telemetry proof for every start/stop/exception event, advisory isolation, and concurrent backfill convergence.

## Task Commits

1. **Task 1: Lock deterministic resolver authority and normalized shadow parity** - `97e40381`, `348ffa85`
2. **Task 2: Backfill mapped Stripe truth idempotently and prove evidence-preserving cutover rollback** - `dd24c162`
3. **Audit remediation: authority/evidence hardening** - `31a34a32`, `558871a5`
4. **Durable compatibility evidence and state** - `8f1e9e31`, `567a4715`, `c0c148b8`

## Verification

- `mix compile --warnings-as-errors` — pass
- Direct compatibility suite — 11 tests, 0 failures
- Required compatibility/resolver/advisory isolation matrix — 27 tests, 0 failures
- `mix test test/accrue/entitlements --exclude live_stripe` — 191 tests, 0 failures (run 1)
- `mix test test/accrue/entitlements --exclude live_stripe` — 191 tests, 0 failures (run 2)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the backfill entitlement query binding**
- **Found during:** Task 2
- **Issue:** Applying the entitlement query fragment after joining customers applied subscription fields to the customer binding.
- **Fix:** Start from `Subscription`, apply the entitlement fragment before joins, then join customer/items.
- **Files modified:** `accrue/lib/accrue/entitlements/compatibility.ex`
- **Verification:** mapped Stripe backfill repeat test passes.
- **Committed in:** `348ffa85`

**2. [Rule 2 - Critical correctness/privacy] Added durable compatibility evidence and authority state**
- **Found during:** completion audit
- **Issue:** Clean-window approval and rollback authority were process-local, and backfill returned an owner-derived cursor; none supplied durable, privacy-bounded proof of cutover.
- **Fix:** Added compatibility state/audit schemas and migration, persisted digest-only comparison/blocker/transition evidence, required clean matching evidence with zero blockers before enablement, and returned only opaque customer cursors.
- **Files modified:** `accrue/lib/accrue/entitlements/compatibility.ex`, `accrue/lib/accrue/entitlements/compatibility_audit.ex`, `accrue/lib/accrue/entitlements/compatibility_state.ex`, `accrue/priv/repo/migrations/20260803013000_create_accrue_entitlement_compatibility_evidence.exs`, `accrue/test/accrue/entitlements/compatibility_test.exs`
- **Verification:** direct matrix (27/0), full entitlement suite twice (191/0 each), compile and format pass.
- **Committed in:** `567a4715`, `c0c148b8`

## Known Stubs

None.

## Self-Check: PASSED

- Required source, state/audit schema, migration, and test files exist.
- Task commits `97e40381`, `348ffa85`, `dd24c162`, `567a4715`, and `c0c148b8` exist in git history.

## User Setup Required

None — all authority boundaries and regression coverage are automated.
