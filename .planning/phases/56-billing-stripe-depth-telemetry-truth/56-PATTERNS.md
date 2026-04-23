# Phase 56 — Pattern map

## PATTERN MAPPING COMPLETE

| Intent | Target (new/change) | Analog (read first) |
|--------|---------------------|---------------------|
| Billing façade + span | `accrue/lib/accrue/billing.ex` | `attach_payment_method/3` + `span_billing(:payment_method, :attach, …)` |
| Action module read | `accrue/lib/accrue/billing/payment_method_actions.ex` | Writes in same module (`attach_payment_method/3` transaction pattern — list is read-only, no `Repo.transact` required unless later dedup) |
| Processor call | `Processor.__impl__().list_payment_methods(params, opts)` | `accrue/lib/accrue/processor/stripe.ex` ~L410; `accrue/lib/accrue/processor/fake.ex` ~L1180 |
| Fake integration test | `accrue/test/accrue/processor/fake_phase3_test.exs` | `describe "payment method"` — `Fake.list_payment_methods(%{customer: cus.id}, [])` |
| BillingCase test | New `payment_method_list_test.exs` | Other `accrue/test/accrue/billing/*_test.exs` using `BillingCase` |
| Span inventory | `accrue/test/accrue/telemetry/billing_span_coverage_test.exs` | Greps `Accrue.Telemetry.span` in `billing.ex` |
| Telemetry doc | `accrue/guides/telemetry.md` | Existing `accrue.billing.meter_event.report_usage` example block |

## Excerpt — span wrapper

```elixir
defp span_billing(resource, action, subject, opts, fun) do
  Accrue.Telemetry.span(
    [:accrue, :billing, resource, action],
    billing_metadata(resource, action, subject, opts),
    fun
  )
end
```

## Excerpt — Fake list handler

```elixir
{{:ok, %{object: "list", data: data, has_more: false}}, state}
```
