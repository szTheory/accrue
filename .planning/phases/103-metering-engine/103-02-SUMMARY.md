---
phase: 103-metering-engine
plan: 02
subsystem: payments
tags: [braintree, metering, invoices, oban, ecto]
requires:
  - phase: 103-metering-engine
    provides: "Plan 01 meter-definition truth and immutable renewal-window anchors"
provides:
  - "Worker-owned renewal aggregation that authors one canonical local invoice per closed window"
  - "Durable meter-event billing outcomes for matched, unmatched, and unusable usage rows"
  - "Renewal rows linked to authored invoices through replay-safe local references"
affects: [phase-103-plan-03, metered-billing, operator-recovery]
tech-stack:
  added: []
  patterns: [local-invoice-first, renewal-owned-idempotency, explicit-event-resolution]
key-files:
  created:
    - accrue/lib/accrue/billing/metered_renewal_invoice.ex
    - accrue/lib/accrue/jobs/process_metered_renewal.ex
    - accrue/priv/repo/migrations/20260503101000_add_billing_resolution_fields_to_meter_events_and_renewals.exs
  modified:
    - accrue/lib/accrue/billing/meter_event.ex
    - accrue/lib/accrue/billing/metered_renewal.ex
    - accrue/lib/accrue/billing/metered_renewal_actions.ex
    - accrue/test/accrue/billing/metered_renewal_invoice_test.exs
    - accrue/test/accrue/billing/meter_event_resolution_test.exs
    - accrue/test/accrue/jobs/process_metered_renewal_test.exs
key-decisions:
  - "Each metered renewal owns a synthetic local invoice processor_id so invoice authoring can replay without duplicating ledger rows."
  - "Meter events are resolved explicitly to matched, unmatched, or unusable outcomes and linked back to the renewal row for operator auditability."
  - "Local invoice items are authored from the renewal snapshot, so later subscription-item edits cannot rewrite the explanation for a closed billing window."
patterns-established:
  - "Use a renewal-owned worker to turn one closed window into one local invoice before any gateway settlement attempt."
  - "Persist invoice refs on the renewal row and synthetic item ids on invoice items to make replay-safe local authoring deterministic."
requirements-completed: [BT-06]
duration: 21 min
completed: 2026-05-03
---

# Phase 103 Plan 02 Summary

**Closed Braintree renewal windows now aggregate local usage into one canonical Accrue invoice before any external settlement path runs.**

## Performance

- **Duration:** 21 min
- **Completed:** 2026-05-03T01:14:19Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Added `Accrue.Billing.MeteredRenewalInvoice` to aggregate one renewal window from the Plan 01 snapshot, author one local invoice, and decompose the bill into stable invoice items.
- Added `Accrue.Jobs.ProcessMeteredRenewal` as the Oban-owned BT-06 execution path and kept replay idempotent by anchoring invoice persistence to the renewal row.
- Extended `Accrue.Billing.MeterEvent` and `Accrue.Billing.MeteredRenewal` with durable billing-resolution and invoice-reference fields so unmatched and unusable usage never disappears silently.
- Added focused TDD coverage for invoice authoring, meter-event resolution, and worker replay semantics.

## Task Commits

1. **Task 1: Add tests for renewal-window aggregation and explicit meter-event outcomes** - `564b4f4` (`test`)
2. **Task 2: Implement worker-owned aggregation, invoice-item authoring, and explicit event-resolution state** - `bc77e2d` (`feat`)

## Files Created/Modified

- `accrue/lib/accrue/billing/metered_renewal_invoice.ex` - local aggregation and invoice authoring for one renewal window.
- `accrue/lib/accrue/jobs/process_metered_renewal.ex` - worker shell that restores Oban middleware and runs renewal invoice authoring.
- `accrue/priv/repo/migrations/20260503101000_add_billing_resolution_fields_to_meter_events_and_renewals.exs` - migration for meter-event billing outcomes and renewal invoice references.
- `accrue/lib/accrue/billing/meter_event.ex` - meter-definition / renewal refs plus durable billing outcome fields.
- `accrue/lib/accrue/billing/metered_renewal.ex` - renewal invoice refs and authored-at state.
- `accrue/lib/accrue/billing/metered_renewal_actions.ex` - wrapper and bookkeeping for renewal invoice authoring completion.
- `accrue/test/accrue/billing/metered_renewal_invoice_test.exs` - invoice authoring and snapshot-stability coverage.
- `accrue/test/accrue/billing/meter_event_resolution_test.exs` - matched / unmatched / unusable outcome coverage.
- `accrue/test/accrue/jobs/process_metered_renewal_test.exs` - worker replay and duplicate-prevention coverage.

## Decisions Made

- Kept invoice authoring local-first with synthetic `processor_id` values on invoices and items so the same renewal can replay cleanly without duplicate ledger rows.
- Used the renewal snapshot as the pricing explanation source instead of current subscription-item state, preserving period-accurate invoice items after later plan changes.
- Recorded invoice authoring completion on the renewal row and in the event ledger before any future Braintree settlement work.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed RED fixtures to use microsecond UTC timestamps**
- **Found during:** Task 1 verification
- **Issue:** Two new RED fixtures used `~U[...]` values without microsecond precision, which failed before reaching the intended missing-module assertions.
- **Fix:** Updated the new test fixtures to use `:utc_datetime_usec` literals with explicit `.000000Z` precision.
- **Files modified:** `accrue/test/accrue/billing/meter_event_resolution_test.exs`, `accrue/test/accrue/jobs/process_metered_renewal_test.exs`
- **Commit:** `564b4f4`

## Issues Encountered

- `gsd-sdk` is unavailable in this workspace (`No executable gsd-sdk found for current version`). Shared `.planning/STATE.md`, `.planning/ROADMAP.md`, and requirement-tracking updates were not executed because the tool was unavailable and `STATE.md` already had unrelated user edits before this plan started.

## Next Phase Readiness

- Plan 03 can now add Braintree settlement and recovery semantics on top of stable local invoices, explicit event outcomes, and replay-safe renewal anchors.
- The renewal row already carries the invoice reference and authored status needed for settlement idempotency.

## Self-Check

PASSED

- Summary file exists at `.planning/phases/103-metering-engine/103-02-SUMMARY.md`.
- Commit `564b4f4` exists for the RED test gate.
- Commit `bc77e2d` exists for the GREEN implementation gate.
