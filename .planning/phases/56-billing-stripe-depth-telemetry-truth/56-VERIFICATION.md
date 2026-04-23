---
status: passed
phase: 56-billing-stripe-depth-telemetry-truth
verified: 2026-04-23
---

# Phase 56 — Verification

## Must-haves (BIL-01)

| Criterion | Evidence |
|-----------|----------|
| Public `list_payment_methods/2` and `!/2` delegate through `span_billing(:payment_method, :list, …)` | `rg "payment_method, :list" accrue/lib/accrue/billing.ex`; `PaymentMethodActions` invoked |
| Processor invoked with `customer.processor_id` + optional validated filters | `list_params_for_processor/2`, `NimbleOptions.validate!/2` |
| Fake-backed test proves listed PM after attach | `mix test test/accrue/billing/payment_method_list_test.exs` |
| Span inventory | `mix test test/accrue/telemetry/billing_span_coverage_test.exs` |

## Must-haves (BIL-02)

| Criterion | Evidence |
|-----------|----------|
| `guides/telemetry.md` documents `[:accrue, :billing, :payment_method, :list]` / dotted name | New bullet under billing examples |
| `CHANGELOG.md` Unreleased | `### Billing` bullet for `list_payment_methods` |
| `billing.ex.eex` delegates | `def list_payment_methods` / `def list_payment_methods!` |

## Automated commands run

```bash
cd accrue && mix test test/accrue/billing/payment_method_list_test.exs test/accrue/telemetry/billing_span_coverage_test.exs
cd accrue && mix compile --warnings-as-errors
```

## human_verification

None required for this phase.
