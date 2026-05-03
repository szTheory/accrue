---
phase: 103-metering-engine
plan: 01
subsystem: payments
tags: [braintree, metering, oban, webhook, ecto]
requires:
  - phase: 101-accrue-portal-foundation-checkout
    provides: "Braintree-first local portal and webhook normalization patterns"
  - phase: 102-coupon-discount-mapping
    provides: "Explicit local truth pattern for Braintree-only billing data"
provides:
  - "Local meter-definition schema and write/read service bound to subscription items"
  - "Immutable metered-renewal schema keyed by subscription plus closed UTC window"
  - "Webhook-triggered Braintree renewal classification that opens replay-safe renewal anchors"
affects: [phase-103-plan-02, metered-billing, operator-recovery]
tech-stack:
  added: []
  patterns: [local-billability-contract, webhook-first-renewal-anchor, immutable-renewal-window]
key-files:
  created:
    - accrue/lib/accrue/billing/meter_definition.ex
    - accrue/lib/accrue/billing/meter_definitions.ex
    - accrue/lib/accrue/billing/metered_renewal.ex
    - accrue/lib/accrue/billing/metered_renewal_actions.ex
    - accrue/priv/repo/migrations/20260503100000_create_accrue_meter_definitions_and_metered_renewals.exs
  modified:
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/test/accrue/billing/meter_definitions_test.exs
    - accrue/test/accrue/webhook/braintree_metered_renewal_test.exs
key-decisions:
  - "Meter definitions stay local and bind one ingress event_name to one concrete subscription item target."
  - "Braintree renewal windows open only after canonical subscription fetch proves the cycle advanced and the webhook timestamp is at or after the closed period end."
  - "Renewal rows snapshot meter-definition and subscription-item truth at window open so later edits do not rewrite historical billing inputs."
patterns-established:
  - "Use local renewal rows, not Oban uniqueness or gateway duplicate checks, as the canonical idempotency anchor."
  - "Keep Braintree metering local-first: local truth for billability and renewal, gateway only as external lifecycle evidence."
requirements-completed: [BT-06, BT-07]
duration: 11 min
completed: 2026-05-03
---

# Phase 103 Plan 01 Summary

**Local meter definitions and replay-safe Braintree renewal anchors now establish Accrue-owned metering truth before any month-end charge logic exists.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-05-03T00:53:00Z
- **Completed:** 2026-05-03T01:04:02Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `accrue_meter_definitions` and `accrue_metered_renewals` with the immutable uniqueness contract on `subscription_id + period_start + period_end`.
- Implemented `Accrue.Billing.MeterDefinitions` and `Accrue.Billing.MeteredRenewalActions` so billability is tied to explicit subscription-item targets and renewal windows are opened from canonical Braintree fetches.
- Wired the Braintree webhook path to open one renewal anchor per closed UTC window while keeping replay idempotent and preserving historical snapshot data.
- Added focused RED/GREEN coverage for the local meter-definition contract and Braintree renewal replay semantics.

## Task Commits

1. **Task 1: Add tests for local meter definitions and webhook-opened renewal windows** - `d5877fe` (`test`)
2. **Task 2: Implement meter-definition storage and webhook-primary renewal orchestration** - `c80a83c` (`feat`)

## Files Created/Modified

- `accrue/lib/accrue/billing/meter_definition.ex` - schema for one ingress event to one concrete billable target.
- `accrue/lib/accrue/billing/meter_definitions.ex` - upsert/read helpers and active-definition lookup by subscription.
- `accrue/lib/accrue/billing/metered_renewal.ex` - immutable renewal-window schema with state enum and snapshot payload.
- `accrue/lib/accrue/billing/metered_renewal_actions.ex` - canonical Braintree renewal classification, event recording, and enqueue hook.
- `accrue/lib/accrue/webhook/default_handler.ex` - Braintree event hook that opens metered renewal anchors before the normal reducer path.
- `accrue/priv/repo/migrations/20260503100000_create_accrue_meter_definitions_and_metered_renewals.exs` - new tables and supporting indexes.
- `accrue/test/accrue/billing/meter_definitions_test.exs` - meter-definition contract coverage.
- `accrue/test/accrue/webhook/braintree_metered_renewal_test.exs` - Braintree renewal replay and snapshot coverage.

## Decisions Made

- Reused the existing `report_usage/3` seam and did not introduce any host-facing API that requires `subscription_item_id` on each usage write.
- Stored top-level renewal snapshots plus the full meter-definition list so later plans can compute usage or explain charges without reverse-engineering current subscription state.
- Kept the enqueue seam in Plan 01 as a future-worker hook via Oban job insertion without introducing the processor job implementation yet.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `gsd-sdk` is unavailable in this workspace (`No executable gsd-sdk found for current version`). Because `.planning/STATE.md` already has unrelated user edits, shared planning-state updates and the metadata-only docs commit were not performed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 103 can now build usage aggregation and settlement on top of stable local meter-definition and renewal-window truth.
- The next slice can use the renewal snapshot as the idempotent anchor for invoice-item generation and Braintree sale settlement.

## Known Stubs

- `accrue/lib/accrue/billing/metered_renewal_actions.ex` stores a future worker hook (`Accrue.Jobs.ProcessMeteredRenewal`) but this plan does not implement the worker. The queue insertion is intentional and aligned with the next plan’s processing work.

## Self-Check

PASSED

- Summary file exists at `.planning/phases/103-metering-engine/103-01-SUMMARY.md`.
- Commit `d5877fe` exists for the RED test gate.
- Commit `c80a83c` exists for the GREEN implementation gate.
