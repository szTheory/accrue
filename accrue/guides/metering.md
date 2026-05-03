# Usage metering

This guide is the **architecture map** for usage metering in Accrue. ExDoc on `Accrue.Billing.report_usage/3` is the source of truth for supported option keys and validation rules—this page does not duplicate that contract.

## Public API

Host applications call **`Accrue.Billing.report_usage/3`** (and **`report_usage!/3`**) to record metered usage for a customer and event name. Open the `Accrue.Billing` module in Hexdocs for the full keyword list and defaults.

## Internal persistence

Each host call creates or advances an **`Accrue.Billing.MeterEvent`** row: the row is written as **`pending`** inside the transactional outbox path, then transitions to **`reported`** or **`failed`** once the processor outcome is known. **`Accrue.Billing.MeterEventActions`** owns the transactional insert and orchestration; **`Accrue.Billing.MeterEvents`** applies guarded updates when reconcilers or webhooks move rows to a durable terminal state.

## Processor

The configured **`Accrue.Processor`** must implement **`report_meter_event/1`**. Tests use **`Accrue.Processor.Fake`** (for example via `Accrue.Test.setup_fake_processor/1`) so meter payloads are captured without network calls; production hosts configure a real processor (typically Stripe-backed) through normal Accrue wiring.

## Processor distinction

Stripe and Braintree share the same ingress seam, but they do **not** share the same settlement model.

- **Stripe** can treat `report_usage/3` as direct meter reporting because Stripe exposes native meter APIs.
- **Braintree** treats `report_usage/3` as the raw event ledger only. Accrue layers **local meter definitions**, **immutable renewal windows**, **local invoice decomposition**, and one external **`Transaction.sale`** settlement per closed window on top of those raw rows.

For the full Braintree-specific flow, read [`braintree-metered-billing.md`](braintree-metered-billing.md).

## Out of scope

**PROC-08** and any narrative about hosting a **second processor** alongside the primary configured seam are intentionally omitted from the v1.10 metering story—only the single processor boundary above matters here.

## When metering fails (ops)

When usage cannot be reported durably, operators rely on **`[:accrue, :ops, :meter_reporting_failed]`** for Stripe-style meter ingestion failures and the Phase 103 Braintree-local metering tuples for renewal repair and settlement recovery:

- `[:accrue, :ops, :metered_renewal_stale_repaired]`
- `[:accrue, :ops, :metered_missing_definition]`
- `[:accrue, :ops, :metered_charge_awaiting_payment_method]`
- `[:accrue, :ops, :metered_charge_failed_exhausted]`

The exact tuple metadata and counter names live in [`telemetry.md`](telemetry.md); ordered triage lives in [`operator-runbooks.md`](operator-runbooks.md).
