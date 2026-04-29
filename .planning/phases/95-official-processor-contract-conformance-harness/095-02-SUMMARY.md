---
phase: 095-official-processor-contract-conformance-harness
plan: 02
subsystem: api
tags: [billing, processor-support, subscription, payment-methods]

# Dependency graph
requires:
  - phase: 095-official-processor-contract-conformance-harness
    provides: explicit capability labels and adapter support truth from Plan 01
provides:
  - Tuple-returning unsupported-operation guard for `subscribe/3`
  - Tuple-returning unsupported-operation guard for `list_payment_methods/2`
  - Isolated direct-subscription request builder for the staged thin slice
affects: [phase-95-03, billing facade tests, processor contract docs]

# Tech tracking
tech-stack:
  added: []
  patterns: [facade-guard-symmetry, bounded-subscribe-request-seam]

key-files:
  created:
    - accrue/test/accrue/billing/subscription_actions_test.exs
    - accrue/test/accrue/billing/payment_method_actions_test.exs
  modified:
    - accrue/lib/accrue/billing.ex
    - accrue/lib/accrue/billing/subscription_actions.ex
    - accrue/lib/accrue/billing/payment_method_actions.ex
    - accrue/test/accrue/billing/payment_method_list_test.exs

key-decisions:
  - "Public non-bang billing APIs should return `{:error, %Accrue.APIError{code: \"processor_operation_unsupported\"}}` instead of spreading raise-first behavior."
  - "Processor-side payment-method listing is intentionally out of slice even when Fake or Stripe can technically answer it."
  - "The direct-subscription request assembly should be isolated behind one seam rather than broadly abstracted in Phase 95."

requirements-completed: [PROC-11]

# Metrics
duration: ~35m
completed: 2026-04-29
---

# Phase 95 Plan 02: Harden the public billing seam

**`Accrue.Billing` now fails unsupported processor operations clearly and early for the staged contract: `subscribe/3` respects the official direct-create slice, `list_payment_methods/2` is explicitly out of slice, and the Stripe-shaped request assembly for direct subscription creation is isolated behind one bounded seam.**

## Accomplishments
- Added direct-create support gating in `SubscriptionActions` so non-bang calls return the canonical unsupported-operation tuple and bang calls raise the same exception.
- Added out-of-slice gating for `list_payment_methods/2` and aligned the old payment-method happy-path test and module docs with the new contract.
- Isolated the direct-subscription request assembly in `build_subscription_request/4` instead of letting Stripe-shaped params leak through the whole action body.
- Added focused guard tests for supported Fake subscribe, unsupported direct-create processors, and out-of-slice payment-method listing.

## Verification
- `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/billing/payment_method_actions_test.exs --max-cases 1`
- `cd accrue && mix test test/accrue/billing/payment_method_list_test.exs test/accrue/billing/subscription_test.exs --max-cases 1`

## Task Commits

1. **Task 1: Add first-party slice guards at the public facade boundary** — `1ca55ec`
2. **Task 2: Isolate the minimum direct-subscription request seam** — `1ca55ec`

## Self-Check: PASSED

---
*Phase: 095-official-processor-contract-conformance-harness*
*Completed: 2026-04-29*
