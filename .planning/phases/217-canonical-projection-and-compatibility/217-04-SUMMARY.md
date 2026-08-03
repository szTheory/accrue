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
  - canonical Snapshot resolver projection and mapped Stripe backfill seam
affects: [entitlements, gates, canonical-projection, multi-rail-adoption]
tech-stack:
  added: []
  patterns: [fail-closed compatibility configuration, resolver-compatible snapshot projection, idempotent current-grant writes]
key-files:
  created:
    - accrue/lib/accrue/entitlements/compatibility.ex
    - accrue/lib/accrue/entitlements/resolver/canonical.ex
  modified:
    - accrue/lib/accrue/config.ex
    - accrue/lib/accrue/entitlements/resolver.ex
    - accrue/test/accrue/entitlements/compatibility_test.exs
key-decisions:
  - "A present multi_rail configuration dispatches through Compatibility so every request selects one authority once."
  - "Backfill is restricted to entitling Stripe subscription rows with a locally mapped price and writes only durable account/grant records."
patterns-established:
  - "Compatibility telemetry uses a bounded application metadata allowlist and hashes actor IDs."
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
duration: 17min
completed: 2026-08-03
status: complete
---

# Phase 217 Plan 04: Canonical Projection and Compatibility Summary

**Fail-closed LocalMap/canonical authority lane with canonical snapshot resolution and idempotent mapped Stripe backfill.**

## Performance

- **Duration:** 17 min
- **Completed:** 2026-08-03T01:21:36Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added validated `multi_rail` modes, explicit cohort requirements, and half-open clean-window validation.
- Added a Resolver-compatible canonical Snapshot projection and compatibility telemetry spans for comparison, authority, enablement, backfill, and rollback paths.
- Added stable, mapped Stripe backfill with account/current-grant database identities and repeat/cursor coverage.

## Task Commits

1. **Task 1: Lock deterministic resolver authority and normalized shadow parity** - `97e40381`, `348ffa85`
2. **Task 2: Backfill mapped Stripe truth idempotently and prove evidence-preserving cutover rollback** - `dd24c162`

## Verification

- `mix compile --warnings-as-errors` — pass
- Focused compatibility/resolver/isolation suite — 20 tests, 0 failures
- `mix test test/accrue/entitlements --exclude live_stripe` — 184 tests, 0 failures (run 1)
- `mix test test/accrue/entitlements --exclude live_stripe` — 184 tests, 0 failures (run 2)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the backfill entitlement query binding**
- **Found during:** Task 2
- **Issue:** Applying the entitlement query fragment after joining customers applied subscription fields to the customer binding.
- **Fix:** Start from `Subscription`, apply the entitlement fragment before joins, then join customer/items.
- **Files modified:** `accrue/lib/accrue/entitlements/compatibility.ex`
- **Verification:** mapped Stripe backfill repeat test passes.
- **Committed in:** `348ffa85`

## Known Stubs

None.

## Self-Check: PASSED

- Required source and test files exist.
- Task commits `97e40381`, `348ffa85`, and `dd24c162` exist in git history.

## User Setup Required

None — all authority boundaries and regression coverage are automated.
