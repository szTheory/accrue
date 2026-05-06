---
phase: 101-accrue-portal-foundation-checkout
plan: 01
subsystem: payments
tags: [braintree, checkout, ecto, postgres, config, testing]
requires: []
provides:
  - "Braintree-only persisted local checkout session validation"
  - "Absolute portal URL contract for local checkout and billing portal redirects"
  - "Repo-backed fixture and expiry-window coverage for checkout session rows"
affects: [braintree, checkout, portal, config, testing]
tech-stack:
  added: []
  patterns:
    - "Persisted local checkout rows are constrained to the Braintree portal flow"
    - "Local portal URLs fail closed without an explicit absolute base URL"
key-files:
  created:
    - ".planning/phases/101-accrue-portal-foundation-checkout/101-01-SUMMARY.md"
  modified:
    - "accrue/lib/accrue/checkout/local_session.ex"
    - "accrue/lib/accrue/config.ex"
    - "accrue/test/support/checkout_session_fixture.ex"
    - "accrue/test/accrue/checkout/local_session_test.exs"
key-decisions:
  - "Persisted local checkout sessions reject non-Braintree processor values instead of relying on callers to behave."
  - "Portal URL synthesis remains nil-tolerant at config lookup time but raises at generation time unless an absolute base URL is configured."
patterns-established:
  - "Checkout-session fixtures should expose canonical attrs separately from insertion helpers for reuse across adapter and portal tests."
  - "DB-backed checkout-session tests should assert expiry-window semantics, not only that an expires_at value exists."
requirements-completed: [BT-02]
duration: 4min
completed: 2026-05-01
---

# Phase 101 Plan 01: Portal Checkout Session Contract Summary

**Braintree-only persisted checkout sessions with absolute portal URL enforcement and repo-backed expiry-window coverage**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-02T01:48:20Z
- **Completed:** 2026-05-02T01:52:23Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Locked `Accrue.Checkout.LocalSession` to Braintree rows while preserving `operation_id` reuse and opaque `chk_local_` tokens.
- Tightened `Accrue.Config` documentation so local portal checkout and billing URLs are explicitly rooted in `:portal_base_url` and fail closed when unset.
- Verified the migration against `Accrue.TestRepo` and expanded repo-backed tests/fixtures to cover the persisted expiry window.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock the local checkout-session schema and runtime URL contract** - `8696052` (test), `e3fc56a` (feat)
2. **Task 2: [BLOCKING] Apply the checkout-session migration and prove the DB-backed contract** - `5b8bfcc` (test)

## Files Created/Modified

- `accrue/lib/accrue/checkout/local_session.ex` - Enforces the Braintree-only persisted session contract.
- `accrue/lib/accrue/config.ex` - Clarifies the absolute-host requirement for local portal URL synthesis.
- `accrue/test/support/checkout_session_fixture.ex` - Exposes canonical checkout-session attrs for reuse in later plans.
- `accrue/test/accrue/checkout/local_session_test.exs` - Covers processor restrictions, idempotent reuse, unique indexes, completion, and expiry-window semantics.

## Decisions Made

- Enforced the Braintree-only constraint in the schema layer so invalid local checkout rows fail before persistence.
- Kept `portal_base_url/0` permissive for unset config reads, but treated `portal_url/1` as the hard gate for returned absolute URLs.

## Deviations from Plan

None in implementation scope. Verification used the repo's supported migration path: `MIX_ENV=test mix ecto.migrate -r Accrue.TestRepo`, and the plan's `mix test ... -x` command was updated to `--trace` because current Mix no longer accepts `-x`.

## Issues Encountered

- `cd accrue && mix ecto.migrate` in the default environment only emitted an `ecto_repos` warning because `Accrue` is a library and the repo-backed migration path lives in `MIX_ENV=test` on `Accrue.TestRepo`. The test-env migrate command succeeded with `Migrations already up`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Adapter and portal work can rely on a stricter persisted checkout-session contract, canonical fixture attrs, and repo-backed schema coverage.
- No blockers remain for downstream Phase 101 plans.

## Self-Check: PASSED

- Found summary file: `.planning/phases/101-accrue-portal-foundation-checkout/101-01-SUMMARY.md`
- Found commits: `8696052`, `e3fc56a`, `5b8bfcc`

---
*Phase: 101-accrue-portal-foundation-checkout*
*Completed: 2026-05-01*
