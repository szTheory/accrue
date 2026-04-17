---
phase: 18-stripe-tax-core
plan: 03
subsystem: payments
tags: [stripe-tax, subscriptions, invoices, ecto, exunit]
requires:
  - phase: 18-01
    provides: public subscription automatic-tax intent normalization
  - phase: 18-02
    provides: deterministic Fake automatic-tax payload parity for subscriptions and invoices
provides:
  - Narrow automatic-tax storage on subscription and invoice rows
  - Subscription and invoice projection of automatic-tax enabled/status state
  - Invoice tax amount derivation from canonical processor tax fields with forward-compatible fallback
affects: [19, TAX-01, billing projections]
tech-stack:
  added: []
  patterns: [narrow tax observability columns, projection from canonical processor tax fields]
key-files:
  created:
    - .planning/phases/18-stripe-tax-core/18-03-SUMMARY.md
    - accrue/priv/repo/migrations/20260417180000_add_automatic_tax_columns_to_billing_tables.exs
    - accrue/test/accrue/billing/subscription_projection_tax_test.exs
  modified:
    - accrue/lib/accrue/billing/subscription.ex
    - accrue/lib/accrue/billing/invoice.ex
    - accrue/lib/accrue/billing/subscription_projection.ex
    - accrue/lib/accrue/billing/invoice_projection.ex
    - accrue/test/accrue/billing/invoice_projection_test.exs
    - .planning/STATE.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
key-decisions:
  - "Persisted only `automatic_tax` and `automatic_tax_status` on subscriptions and invoices; richer Stripe tax payloads stay in `data`."
  - "Derived invoice `tax_minor` only from canonical processor tax fields (`tax` then `total_details.amount_tax`) and defaulted to `0` only when automatic tax is enabled but Stripe/Fake has no amount yet."
patterns-established:
  - "Billing projections expose a narrow query surface while retaining the full processor payload in `data` for forward compatibility."
  - "Automatic-tax projection helpers must accept both string-keyed Stripe payloads and atom-keyed Fake payloads."
requirements-completed: [TAX-01]
duration: 3 min
completed: 2026-04-17
---

# Phase 18 Plan 03: Subscription and Invoice Tax Observability Summary

**Narrow subscription and invoice automatic-tax persistence with projection of enabled/status state and forward-compatible invoice tax totals**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-17T17:10:00Z
- **Completed:** 2026-04-17T17:12:53Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- Added additive subscription and invoice columns for `automatic_tax` and `automatic_tax_status` without expanding local billing tables into a Stripe tax mirror.
- Updated subscription and invoice projections to persist automatic-tax enabled/status state while keeping the full upstream payload in `data`.
- Added focused projection coverage for enabled and disabled cases, `total_details.amount_tax` fallback, and string-keyed versus atom-keyed payload parity.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add narrow automatic-tax storage for subscriptions and invoices** - `a4d6b19` (feat)
2. **Task 2: Project automatic-tax state and tax amount from processor payloads** - `d04e7dc` (feat)

## Files Created/Modified
- `.planning/phases/18-stripe-tax-core/18-03-SUMMARY.md` - Plan execution summary and verification record.
- `accrue/priv/repo/migrations/20260417180000_add_automatic_tax_columns_to_billing_tables.exs` - Additive migration for subscription and invoice automatic-tax observability.
- `accrue/lib/accrue/billing/subscription.ex` - Subscription schema fields and cast surface for automatic-tax state.
- `accrue/lib/accrue/billing/invoice.ex` - Invoice schema fields and cast surface for automatic-tax state.
- `accrue/lib/accrue/billing/subscription_projection.ex` - Automatic-tax enabled/status projection helper and subscription row attrs.
- `accrue/lib/accrue/billing/invoice_projection.ex` - Automatic-tax projection and invoice tax amount fallback logic.
- `accrue/test/accrue/billing/invoice_projection_test.exs` - Coverage for automatic-tax state and tax amount fallback behavior.
- `accrue/test/accrue/billing/subscription_projection_tax_test.exs` - New subscription projection tax observability coverage.
- `.planning/STATE.md` - Advanced planning state past Phase 18 completion.
- `.planning/ROADMAP.md` - Marked Plan 18-03 and Phase 18 complete.
- `.planning/REQUIREMENTS.md` - Marked TAX-01 complete in the active milestone requirements.

## Decisions Made
- Kept invoice tax observability anchored to the existing `tax_minor` numeric column instead of introducing new Stripe-specific amount columns.
- Reused `SubscriptionProjection.get/2` and a shared automatic-tax helper so Stripe wire payloads and Fake payloads keep the same projection semantics.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 18 is complete and TAX-01 is fully shipped across subscription, invoice, and checkout flows. The next milestone work is Phase 19 planning for tax location validation, invalid-location recovery, and rollout safety.

## Verification

- `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs`
- `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs`

## Self-Check: PASSED

- Found `.planning/phases/18-stripe-tax-core/18-03-SUMMARY.md`
- Found commit `a4d6b19`
- Found commit `d04e7dc`
