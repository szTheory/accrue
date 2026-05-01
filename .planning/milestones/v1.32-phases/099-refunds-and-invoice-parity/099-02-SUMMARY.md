---
phase: 099-refunds-and-invoice-parity
plan: 02
subsystem: refunds
tags:
  - refunds
  - braintree
  - proration
  - invoice_projection
depends_on:
  - 099-01
requires:
  - PROC-18
  - PROC-19
provides:
  - Immediate Braintree refund convergence via retrieve hook
  - Reconcile-backed Braintree card-refund truth backstop
  - Refund rollups on invoice projections
  - Strict Braintree proration validation
affects:
  - accrue/lib/accrue/billing/refund_actions.ex
  - accrue/lib/accrue/webhook/default_handler.ex
  - accrue/lib/accrue/jobs/reconcile_refund_fees.ex
  - accrue/lib/accrue/billing/invoice_projection.ex
  - accrue/lib/accrue/billing/subscription_actions.ex
  - accrue/lib/accrue/processor/braintree.ex
key_decisions:
  - Immediate retrieve: Webhook-free Braintree refund convergence is enforced by immediately fetching canonical refund truth on write.
  - Reconcile backstop: ReconcileRefundFees handles Braintree fee re-fetching as a clean fallback for any out-of-order or missing webhook.
  - Read model separation: Invoices retain sale truth and surface refund rollups rather than mutating parent amounts directly.
  - Narrow proration support: Braintree plan swaps restrict proration semantics to `:none` and `:create_prorations` explicitly.
metrics:
  duration: 5s
  tasks_completed: 3
  files_modified: 25
---

# Phase 099 Plan 02: Braintree Refund Convergence and Proration Parity Summary

Refund truth on Braintree now converges deterministically through an immediate post-write `retrieve_refund` and an idempotent reconcile backstop. Invoice projections expose derived refund rollups while preserving the original parent sale amounts. Braintree proration behavior is now strictly guarded to the explicit supported semantics, failing clearly for unsupported Stripe-centric knobs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed dialyzer warning and Braintree test suite**
- **Found during:** User test execution
- **Issue:** Dialyzer warning in `reconcile_refund_fees.ex:94` and various test failures in `braintree_test.exs` and `plug_test.exs`.
- **Fix:** Addressed the warnings and aligned the test fixtures and global setup to pass with the new validations.
- **Files modified:** `reconcile_refund_fees.ex`, `plug_test.exs`, `braintree_test.exs`, `e2e` helpers, and checkout logic.
- **Commit:** `b1df372`

## Self-Check: PASSED
All tests run green. The immediate-retrieve logic, Braintree-specific invoice projection decompose mapping, and strict swap\_plan validation branch are integrated.
