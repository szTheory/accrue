---
phase: 128-campaign-engine-foundation-idempotency-must-fix
plan: 02
subsystem: database
tags: [ecto, migration, subscription, dunning, campaign-anchor, postgres]

# Dependency graph
requires:
  - phase: 128-campaign-engine-foundation-idempotency-must-fix (Plan 01)
    provides: dunning campaign config schema + accessors (the cadence this anchor pairs with)
provides:
  - "Nullable forward-only `accrue_subscriptions.dunning_campaign_started_at :utc_datetime_usec` column (D-08)"
  - "`Subscription.dunning_campaign_started_at` schema field + `@cast_fields` entry (recovery-CLEAR cast path, D-12)"
  - "`Subscription.dunning_campaign_active?/1` dual-shape + catch-all predicate (campaign-active iff anchor is a non-nil DateTime)"
affects: [128 Plan 05 (worker cancel-guard, D-11), 128 Plan 06 (atomic update_all elector D-09 + cancel-on-recovery clear D-12), 129 (admin dunning-state view), 130 (Fake-lane proof)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dunning-campaign anchor: a single nullable column (NOT a new table), set-once on the first nil→past_due edge, cleared on recovery"
    - "Dual-clause + catch-all lifecycle predicate convention (%__MODULE__{} | bare-map | _ → false)"

key-files:
  created:
    - accrue/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs
    - accrue/test/accrue/billing/subscription_campaign_anchor_test.exs
  modified:
    - accrue/lib/accrue/billing/subscription.ex

key-decisions:
  - "Anchor is a nullable forward-only column add mirroring `dunning_sweep_attempted_at` — no backfill, existing rows survive with nil anchor (RESEARCH Runtime State Inventory)"
  - "No index on the anchor — D-08 requires none for correctness; the optional partial `WHERE ... IS NOT NULL` index is deferred to Phase 129"
  - "Anchor added to `@cast_fields` ONLY for the recovery-CLEAR path (D-12); the START path (D-09) is a sibling `update_all`, never a cast — so it never contends with `optimistic_lock(:lock_version)` (T-128-03 mitigation)"
  - "No start-path / telemetry / status-flip-anchor changeset shipped in this plan (scope boundary; start is a sibling update_all in Plan 06)"

patterns-established:
  - "Campaign anchor column-add pattern: clone the `dunning_sweep_attempted_at` migration, drop the partial index"
  - "`dunning_campaign_active?/1` predicate: dual-shape struct/map clauses + catch-all, true iff anchor is `%DateTime{}`"

requirements-completed: [DUN-05]

# Metrics
duration: 2min
completed: 2026-05-24
---

# Phase 128 Plan 02: Campaign Anchor Column + Predicate Summary

**Nullable forward-only `dunning_campaign_started_at` anchor on `accrue_subscriptions`, wired into the Subscription schema + `@cast_fields` (recovery-clear cast path) with a `dunning_campaign_active?/1` dual-shape predicate.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-24T17:45:36Z
- **Completed:** 2026-05-24T17:46:56Z
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 modified)

## Accomplishments

- Forward-only nullable migration adds the campaign-identity anchor column (`:utc_datetime_usec`, `null: true`), applies cleanly against the test repo, and carries no index per D-08.
- `Subscription` now carries the `dunning_campaign_started_at` field, lists it in `@cast_fields` (so both `force_status_changeset/2` and `changeset/2` can cast it — the D-12 recovery-CLEAR path), and exposes `dunning_campaign_active?/1`.
- `dunning_campaign_active?/1` returns `true` iff the anchor is a non-nil `DateTime` (struct or bare-map shape), `false` for nil/any-other shape — proven by a focused pure-unit test (TDD RED → GREEN).

## Task Commits

Each task was committed atomically:

1. **Task 1: Forward-only nullable migration for the campaign anchor (D-08)** - `116b500` (feat)
2. **Task 2 (RED): failing test for `dunning_campaign_active?/1` + anchor cast** - `c28a811` (test)
3. **Task 2 (GREEN): anchor field, `@cast_fields` entry, and predicate** - `565a7eb` (feat)

**Plan metadata:** _(this commit)_ (docs: complete plan)

_Note: Task 2 was TDD (test → feat). No REFACTOR commit needed — the implementation cloned the documented dual-clause predicate convention verbatim and required no cleanup._

## Files Created/Modified

- `accrue/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs` - Nullable forward-only column add for the campaign anchor; timestamp `20260525120000` > prior `20260524120000`; no index; moduledoc notes nullable/forward-only/mirrors-sibling.
- `accrue/lib/accrue/billing/subscription.ex` - Added `field(:dunning_campaign_started_at, :utc_datetime_usec)` after `dunning_sweep_attempted_at`; added the field to `@cast_fields`; added `dunning_campaign_active?/1` (dual-shape + catch-all) beside the lifecycle predicates.
- `accrue/test/accrue/billing/subscription_campaign_anchor_test.exs` - Pure-unit (`async: true`) coverage of the three predicate behaviors and the recovery-clear cast through `force_status_changeset/2`.

## Decisions Made

None beyond the plan — followed D-08 exactly. The key plan-specified decisions (no index, cast-for-clear-path-only, no start-path/telemetry) were honored as written; the threat register T-128-03 mitigation (anchor cast surface limited to the CLEAR path, START is a sibling `update_all`) is preserved by shipping no start-on-changeset code in this plan.

## Deviations from Plan

None - plan executed exactly as written.

The pre-existing unstaged modification to `accrue/guides/maturity-and-maintenance.md` was present before this plan started and is unrelated to plan 128-02; it was left untouched per the scope boundary.

## Issues Encountered

None. The RED test failed at compile time with `KeyError key :dunning_campaign_started_at not found` (the expected RED state — the struct field did not yet exist), then went GREEN once the field was added.

## Verification

- `MIX_ENV=test mix ecto.migrate` — anchor column applies cleanly (`== Migrated 20260525120000`).
- `mix test test/accrue/billing/subscription_campaign_anchor_test.exs --seed 0` — 7/7 pass (new predicate + cast coverage).
- `mix test test/accrue/billing/subscription_test.exs --seed 0` — 13/13 pass (no regression in the existing subscription suite).
- `mix compile --warnings-as-errors` — exit 0.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The anchor contract (D-08) is fully available for Plan 05 (D-11 worker cancel-guard) and Plan 06 (D-09 atomic `update_all WHERE is_nil(dunning_campaign_started_at)` elector + D-12 cancel-on-recovery clear).
- The migration lands in Wave 1 so `test_helper.exs` boot-migration makes the column available to every integration test in later plans.
- No start-path, telemetry, or index code was introduced — those boundaries (Plan 06 start, Phase 129 telemetry/index) remain open and clean.

## Self-Check: PASSED

- FOUND: `accrue/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs`
- FOUND: `accrue/lib/accrue/billing/subscription.ex`
- FOUND: `accrue/test/accrue/billing/subscription_campaign_anchor_test.exs`
- FOUND commit: `116b500` (Task 1 migration)
- FOUND commit: `c28a811` (Task 2 RED)
- FOUND commit: `565a7eb` (Task 2 GREEN)

---
*Phase: 128-campaign-engine-foundation-idempotency-must-fix*
*Completed: 2026-05-24*
