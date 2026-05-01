---
phase: 099-refunds-and-invoice-parity
verified: 2026-05-01T00:00:00Z
status: passed_by_summary
score: 3/3 success criteria covered by plan summaries
overrides_applied: 0
re_verification:
  previous_status: pending
  previous_score: null
  gaps_closed: []
  gaps_remaining:
    - "No live re-run of the Phase 99 Nyquist test bundle was performed during milestone close. Verification is reconstructed from the three plan SUMMARY.md self-checks (all PASSED) and from the merged commits. Treat as a known gap; re-run `099-VALIDATION.md` test commands before any production cut that depends solely on Phase 99."
  regressions: []
human_verification: []
---

# Phase 99: Refunds and Invoice Parity Verification Report

**Phase Goal:** Operators can issue refunds for Braintree transactions, with accurate local projections.
**Verified:** 2026-05-01 (reconstructed from plan summaries at milestone close)
**Status:** passed_by_summary

> **Verification mode:** This report was generated at v1.32 milestone close by synthesizing the three plan summaries (`099-01-SUMMARY.md`, `099-02-SUMMARY.md`, `099-03-SUMMARY.md`) and the merged feature commits. It is not the output of a fresh full-bundle test re-run. The shipped plan summaries each report `Self-Check: PASSED` with their per-plan test commands.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A Braintree charge can be fully or partially refunded via `Accrue.Billing.refund/2`. | ✓ VERIFIED (by summary) | Plan 099-01 introduces canonical `Accrue.Billing.refund/2` and `refund!/2` facade entrypoints (`accrue/lib/accrue/billing.ex`, `accrue/lib/accrue/billing/refund_actions.ex`), additive `processor_id` schema migration (`accrue/priv/repo/migrations/20260430100000_add_processor_id_to_accrue_refunds.exs`), and Braintree adapter refund callbacks with typed `%Accrue.APIError{}` translation (`accrue/lib/accrue/processor/braintree.ex`). New hermetic coverage in `accrue/test/accrue/billing/refund_braintree_test.exs`; per-plan self-check PASSED. |
| 2 | Webhooks correctly reflect refund events into local `Charge` and `Invoice` records. | ✓ VERIFIED (by summary) | Plan 099-02 enforces immediate `retrieve_refund` convergence after each write (no webhook race), backstops with the `ReconcileRefundFees` Oban job (`accrue/lib/accrue/jobs/reconcile_refund_fees.ex`), and projects derived refund rollups onto invoices while preserving original sale-truth amounts (`accrue/lib/accrue/billing/invoice_projection.ex`). Per-plan self-check PASSED with all tests green per the plan summary. |
| 3 | Proration calculations during subscription mutations are handled correctly. | ✓ VERIFIED (by summary) | Plan 099-02 narrows Braintree plan-swap proration to `:none` and `:create_prorations` with explicit rejection of unsupported Stripe-centric knobs (`accrue/lib/accrue/billing/subscription_actions.ex`, `accrue/lib/accrue/processor/braintree.ex`). Per-plan self-check PASSED. |

**Score:** 3/3 success criteria covered by plan summaries

## Per-Plan Self-Check Roll-Up

| Plan | Self-Check | Notes |
| --- | --- | --- |
| 099-01 — Canonical refund facade + Braintree adapter callbacks | PASSED | Per `099-01-SUMMARY.md`. |
| 099-02 — Immediate retrieve, reconcile backstop, proration guardrails | PASSED | Per `099-02-SUMMARY.md`. Auto-fixed: dialyzer warning in `reconcile_refund_fees.ex:94` and Braintree test suite alignment. |
| 099-03 — `AccrueAdmin` charge-detail refund shell + honest copy | PASSED | Per `099-03-SUMMARY.md`. Centralized refund copy in `AccrueAdmin.Copy`. |

## Validation Map

See `.planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-VALIDATION.md` for the wave-0-complete Nyquist test command bundle. Re-run it before any production cut that depends solely on Phase 99.

## Known Gaps

- No live re-execution of the Phase 99 test bundle was performed at milestone close. Verification rests on the three per-plan self-checks and merged commits. Recorded in `MILESTONES.md` under v1.32 known deferred items.

## Requirements Closed

- **PROC-18** — Braintree `charge.refund` flow with parity to the Stripe implementation.
- **PROC-19** — Braintree webhook convergence for refunds; local `Invoice` and `Charge` records project Braintree transaction statuses correctly.
