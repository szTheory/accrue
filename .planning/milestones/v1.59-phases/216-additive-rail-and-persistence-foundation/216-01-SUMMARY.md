---
phase: 216-additive-rail-and-persistence-foundation
plan: 01
subsystem: payments
tags: [elixir, ecto, postgresql, entitlements, rails, configuration]
requires:
  - phase: 215-research-contracts-and-crosswake-feasibility
    provides: closed Stripe, Apple, and host-fake entitlement source vocabulary
provides:
  - additive Stripe and Apple rail configuration with qualified product catalog access
  - durable UUID entitlement accounts keyed by host owner identity
  - billing-prefix-qualified PostgreSQL persistence migration
affects: [217-canonical-projection-and-compatibility, 218-apple-observation-and-repair, 219-offline-study-contract]
tech-stack:
  added: []
  patterns: [rail-qualified product tuple maps, database-authoritative owner identity upserts]
key-files:
  created:
    - accrue/lib/accrue/entitlements/account.ex
    - accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs
  modified:
    - accrue/lib/accrue/config.ex
    - accrue/test/accrue/config_entitlements_test.exs
key-decisions:
  - "The legacy :processor remains the Stripe default-rail alias and Apple remains processor-free."
  - "Entitlement-account uniqueness is enforced by the named PostgreSQL owner identity index."
patterns-established:
  - "Rail configuration validates source vocabulary at boot and indexes products by {rail, environment, product_id}."
  - "fetch_or_create/3 always reloads after conflict-safe insertion so callers receive the durable UUID."
requirements-completed: [RAIL-01, RAIL-02, RAIL-03]
coverage:
  - id: D1
    description: Stripe default and Apple observer rails normalize a qualified Stripe product catalog.
    requirement: RAIL-01
    verification:
      - kind: integration
        ref: accrue/test/accrue/config_entitlements_test.exs#validates a Stripe default rail with Apple observer and normalizes qualified products
        status: pass
    human_judgment: false
  - id: D2
    description: Legacy processor alias remains the controllable Stripe default rail.
    requirement: RAIL-02
    verification:
      - kind: integration
        ref: accrue/test/accrue/config_entitlements_test.exs#validates a Stripe default rail with Apple observer and normalizes qualified products
        status: pass
    human_judgment: false
  - id: D3
    description: Repeated account fetch/create returns one durable UUID account at revision zero.
    requirement: RAIL-03
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/persistence_test.exs#fetch_or_create persists one opaque UUID account per owner at revision zero
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-02
status: complete
---

# Phase 216 Plan 01: Additive Rail and Persistence Foundation Summary

**Validated Stripe-plus-Apple rail configuration with rail-qualified product lookup and durable, owner-stable PostgreSQL entitlement accounts.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-02T15:30:29Z
- **Completed:** 2026-08-02T15:36:03Z
- **Tasks:** 1/1
- **Files modified:** 5

## Accomplishments

- Added opt-in rail/default-rail configuration while retaining legacy single-processor hosts and `price_ids` behavior.
- Validated registered Stripe/Apple source vocabulary and exposed deterministic `{rail, environment, product_id}` catalog keys.
- Added a billing-prefix-qualified entitlement-account table with opaque UUID identity, revision zero, and database-enforced owner uniqueness.
- Proved the complete tracer against the real PostgreSQL sandbox and the full `mix test` suite.

## Task Commits

1. **Task 1: Prove one multi-rail configuration through durable account identity** - `4f925642` (test RED) and `4e58e326` (feat GREEN)

## Files Created/Modified

- `accrue/lib/accrue/config.ex` - additive rail registration, boot validation, and qualified product catalog.
- `accrue/lib/accrue/entitlements/account.ex` - owner-stable entitlement account schema and idempotent fetch/create boundary.
- `accrue/priv/repo/migrations/20260802150000_create_accrue_entitlement_persistence.exs` - prefix-safe accounts table and owner identity index.
- `accrue/test/accrue/config_entitlements_test.exs` - Stripe/Apple catalog tracer proof.
- `accrue/test/accrue/entitlements/persistence_test.exs` - real PostgreSQL account persistence proof.

## Decisions Made

- Kept `:processor` verbatim as the default Stripe rail alias; Apple has no processor adapter.
- Reload after every conflict-safe account insert so the public result is the persisted UUID, not an attempted UUID.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved legacy catalog behavior and durable conflict results**
- **Found during:** Task 1 GREEN verification
- **Issue:** Catalog validation initially rejected legacy `price_ids` when rails were absent, and an `ON CONFLICT DO NOTHING` result exposed the attempted UUID.
- **Fix:** Ignore unqualified aliases for the new catalog on legacy hosts and reload the account by its database-authoritative owner identity after insert.
- **Files modified:** `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/entitlements/account.ex`
- **Verification:** Targeted tracer suites and full `mix test` passed.
- **Committed in:** `4e58e326`

**Total deviations:** 1 auto-fixed (Rule 1 bug)

## Issues Encountered

The RED test run confirmed the required rails API, nested products configuration, and account module were absent before implementation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 217 can build canonical projection and compatibility behavior on the stable account UUID and rail-qualified catalog without changing the legacy processor contract.

## Self-Check: PASSED

- Confirmed task commits `4f925642` and `4e58e326` exist.
- Confirmed the account schema and migration files exist.
