# Braintree metered billing

Braintree does not expose Stripe-native meter objects. In Accrue, Braintree metering is therefore a **local aggregation** system with Braintree used only for external settlement.

## Shared ingress

Hosts still report raw usage through `Accrue.Billing.report_usage/3`:

```elixir
Accrue.Billing.report_usage(customer, "ai_tokens", value: 1200)
```

That API stays host-light. The raw event is durable input, not the final billing contract.

## Local meter definitions

Accrue binds each billable `event_name` to a local meter definition. That definition points at a concrete subscription item and stores the billing snapshot needed to explain the charge later.

This is the key processor distinction:

- Stripe can meter natively.
- Braintree needs Accrue-owned local truth to decide what is billable.

## Renewal window lifecycle

The primary trigger is webhook-first. When Braintree proves a subscription advanced to the next period, Accrue opens one immutable **renewal window** for the closed period.

If the webhook-primary path misses that close, `Accrue.Jobs.MeteredRenewalReconciler` provides a narrow repair backstop after a grace period. It exists to repair stale windows, not to replace the webhook clock.

## Local invoice first

At period close, Accrue aggregates matched usage into local invoice items before any external settlement happens.

That local invoice is the canonical explanation of the bill:

- matched events become priced invoice items
- unmatched events remain explicit operator-visible exceptions
- unusable events keep their error state instead of disappearing

## External settlement

After local invoice authoring, Accrue settles the closed window with one Braintree `Transaction.sale` against the customer's current default vaulted payment method.

The explanation should stay simple: Accrue calculated the bill locally, then used Braintree only to collect the payment.

## Recovery states

Metered settlement keeps one replay-safe charge unit per renewal window.

- `awaiting-payment-method`: the renewal is blocked until the customer repairs the default payment method.
- `failed-exhausted`: the renewal reached a terminal operator-visible failure state.

Recovery reuses the same renewal window instead of inventing a second bill.

If the surrounding webhook path needed repair first, do that work through the
same operator story documented in [`webhooks.md`](webhooks.md) and
[`operator-runbooks.md`](operator-runbooks.md): replay the persisted event
stream, let local projections converge, then retry settlement against the
existing renewal window.

## Operator signals

Watch these ops tuples and matching counters:

- `[:accrue, :ops, :metered_renewal_stale_repaired]`
- `[:accrue, :ops, :metered_missing_definition]`
- `[:accrue, :ops, :metered_charge_awaiting_payment_method]`
- `[:accrue, :ops, :metered_charge_failed_exhausted]`

See [`telemetry.md`](telemetry.md) for the exact metadata and metric names, and [`operator-runbooks.md`](operator-runbooks.md) for ordered triage.
