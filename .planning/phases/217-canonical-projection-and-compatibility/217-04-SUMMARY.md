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

**Fail-closed LocalMap/canonical authority lane with canonical legacy projection, clean-window evidence, rollback authority state, and idempotent mapped Stripe backfill.**

## Performance

- **Duration:** 17 min
- **Completed:** 2026-08-03T01:21:36Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added normalized account cohorts, MFA fail-closed handling, and clean-window digest validation.
- Added legacy logical-plan canonical Snapshot projection and LocalMap rollback authority restoration without deleting evidence.
- Added direct authority, rollback, telemetry, and backfill coverage; full entitlement regression passes twice.

## Task Commits

1. **Task 1: Lock deterministic resolver authority and normalized shadow parity** - `97e40381`, `348ffa85`
2. **Task 2: Backfill mapped Stripe truth idempotently and prove evidence-preserving cutover rollback** - `dd24c162`
3. **Audit remediation: authority/evidence hardening** - `31a34a32`, `558871a5`

## Verification

- `mix compile --warnings-as-errors` — pass
- Direct compatibility suite — 8 tests, 0 failures
- `mix test test/accrue/entitlements --exclude live_stripe` — 188 tests, 0 failures (run 1)
- `mix test test/accrue/entitlements --exclude live_stripe` — 188 tests, 0 failures (run 2)

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

The remaining D-19 privacy-negative, advisory-isolation, and concurrent-backfill matrix cases require additional direct assertions before an independent audit can treat every locked detail as proved.

## Self-Check: PASSED

- Required source and test files exist.
- Task commits `97e40381`, `348ffa85`, and `dd24c162` exist in git history.

## User Setup Required

None — all authority boundaries and regression coverage are automated.
