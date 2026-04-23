---
phase: 56-billing-stripe-depth-telemetry-truth
plan: "01"
subsystem: payments
tags: [stripe, billing, telemetry, nimble_options]

requires: []
provides:
  - Accrue.Billing.list_payment_methods/2 and !/2
  - PaymentMethodActions list implementation + validated list opts
affects: []

tech-stack:
  added: []
  patterns:
    - "Read-through processor list with span_billing(:payment_method, :list, …)"

key-files:
  created:
    - accrue/test/accrue/billing/payment_method_list_test.exs
  modified:
    - accrue/lib/accrue/billing/payment_method_actions.ex
    - accrue/lib/accrue/billing.ex

key-decisions:
  - "NimbleOptions schema covers type, limit, starting_after, ending_before, operation_id; empty opts valid."

patterns-established:
  - "List params merge into %{customer: processor_id} before Processor.list_payment_methods/2."

requirements-completed: [BIL-01]

duration: 15min
completed: 2026-04-23
---

# Phase 56 Plan 01 Summary

**Shipped processor-backed payment method listing on the Billing façade with Fake regression coverage and billing telemetry span.**

## Performance

- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `PaymentMethodActions.list_payment_methods/2` and `!/2` calling `Processor.__impl__().list_payment_methods/2` with validated optional Stripe list filters.
- Wrapped public API in `span_billing(:payment_method, :list, …)` alongside existing payment method operations.
- Added `payment_method_list_test.exs` proving `{:ok, %{data: _}}` after `attach_payment_method` using non-scripted Fake PM lifecycle.

## Task Commits

1. **Task 1: PaymentMethodActions — list + options schema** — `a11abb2`
2. **Task 2: Accrue.Billing façade + span** — `e822bab`
3. **Task 3: ExUnit — Billing list happy path + span coverage** — `8076d97`

## Files Created/Modified

- `accrue/lib/accrue/billing/payment_method_actions.ex` — list + NimbleOptions + moduledoc table
- `accrue/lib/accrue/billing.ex` — public list functions + telemetry
- `accrue/test/accrue/billing/payment_method_list_test.exs` — happy path

## Verification

- `cd accrue && mix test test/accrue/billing/payment_method_list_test.exs test/accrue/telemetry/billing_span_coverage_test.exs` — PASS
- `mix compile --warnings-as-errors` — PASS

## Self-Check: PASSED
