# Operator runbooks

This guide is the **RUN-01** procedural companion to [`guides/telemetry.md`](telemetry.md). That file owns the **ops event catalog** for `[:accrue, :ops, :*]` — Accrue does **not** duplicate that table here. Use this document for **ordered triage**, **Oban queue defaults**, **expanded Stripe verification**, and the four **mini-playbooks** where sequence matters.

**Library vs host:** Accrue ships workers and suggested queue names; **your host application configures and starts Oban** (queues, concurrency, pruning). Queue names below are **defaults** Accrue documents in code — you may remap them in host config; treat symptoms and checks as patterns, not hard-coded production names.

## Oban queue topology

Queue names are **host-configurable**; the table lists Accrue’s **documented defaults** from `use Oban.Worker` in `accrue/lib` today.

| Queue (default name) | Worker module | Role / when to look | Typical symptoms | Safe first checks |
|----------------------|----------------|---------------------|------------------|-------------------|
| `:accrue_webhooks` | `Accrue.Webhook.DispatchWorker` | Async webhook handler dispatch after ingest | Webhooks stuck `:processing`, DLQ growth, dead-letter ops | Inspect `accrue_webhook_events`, Oban retries for this queue, handler logs (no raw bodies) |
| `:accrue_mailers` | `Accrue.Workers.Mailer` | Transactional email delivery | Mail backlog, PDF/email failures surfacing as ops | Oban job args shape, mailer adapter, ChromicPDF availability |
| `:accrue_meters` | `Accrue.Jobs.MeterEventsReconciler` | Meter usage reconciliation | `meter_reporting_failed` ops, stale meter rows | Reconciler jobs, Stripe meter API health, `accrue_meter_events` |
| `:accrue_dunning` | `Accrue.Jobs.DunningSweeper` | Subscription dunning sweeps | Unexpected dunning transitions | Scheduled runs, subscription state vs Stripe |
| `:accrue_reconcilers` | `Accrue.Jobs.ReconcileChargeFees` | Fee reconciliation for charges | Fee drift vs Stripe balance | Reconciler errors, Stripe charge/balance transaction lookups |
| `:accrue_reconcilers` | `Accrue.Jobs.ReconcileRefundFees` | Fee reconciliation for refunds | Refund fee mismatches | Same as above for refund path |
| `:accrue_scheduled` | `Accrue.Jobs.DetectExpiringCards` | Card expiry notices / hygiene | Missing expiry emails, card warnings | Job schedule, customer PM metadata (PII-safe) |
| `:accrue_maintenance` | `Accrue.Webhook.Pruner` | Webhook event retention pruning | Prune telemetry anomalies | Retention config, maintenance window, dry-run if offered |

## Stripe verification pattern

Use a **two-layer** mental model whenever Stripe is involved:

1. **Accrue layer (operational):** local rows (`accrue_*` tables), telemetry and `operation_id`, foreign keys and Stripe ids stored by Accrue (`cus_*`, `sub_*`, `pi_*`, Connect account ids, etc.). This is **application state** for billing workflows — useful for triage, not a substitute for Stripe’s financial records. For **customer billing portal** failures, correlate `[:accrue, :billing, :billing_portal, :create]` **`:stop`** / **`:exception`** latency with **`accrue.customer.id`** and **`operation_id`** per [`telemetry.md`](telemetry.md) — **do not** paste `%Accrue.BillingPortal.Session{}` inspect output into tickets.
2. **Stripe layer (verification):** confirm each issue against the **Stripe resource type + id** using **canonical documentation** (e.g. [Webhooks](https://stripe.com/docs/webhooks), [Testing webhooks](https://stripe.com/docs/webhooks/test), [Billing meter events](https://stripe.com/docs/billing/subscriptions/usage-based/recording-usage)) and **functional Dashboard paths** (e.g. Developers → Webhooks → event deliveries) rather than brittle deep links.

For finance and tax reporting, use **Stripe Dashboard / reporting products** as your source of truth; Accrue focuses on **state, webhooks, and replay** in your app.

## Mini-playbook: [:accrue, :ops, :webhook_dlq, :dead_lettered]

1. Confirm scope: identify `event_id` / `processor_event_id` from telemetry or admin (do **not** paste full webhook payloads or secrets into tickets).
2. Inspect the `accrue_webhook_events` row and last error; decide fix vs replay **before** mutating data.
3. Check **Oban** for `Accrue.Webhook.DispatchWorker` on `:accrue_webhooks` (see [Oban queue topology](#oban-queue-topology)); ensure the host queue is running and not wedged.
4. If replay is required, prefer **admin-gated** or documented replay flows; use **dry-run** when available — avoid destructive deletes from this path.
5. Cross-check the same event type in Stripe via Developers → Webhooks → recent deliveries ([Webhook docs](https://stripe.com/docs/webhooks)).
6. After fix, enqueue or allow retry; watch `[:accrue, :ops, :webhook_dlq, :replay]` and related metrics for confirmation.

## Mini-playbook: [:accrue, :ops, :events_upcast_failed]

1. Record `event_id`, `type`, and `schema_version` from the ops metadata (identifiers only).
2. Determine whether a **deployed upcaster** is missing vs bad persisted data — do not replay until the schema path is understood.
3. Inspect `Accrue.Events` / event storage per your host (see catalog row in `telemetry.md`); align with code version in the running release.
4. Verify Oban or inline retry behavior will not amplify a bad version skew; pause automated replay if unsure.
5. Queue topology for indirect jobs: see [Oban queue topology](#oban-queue-topology) if downstream dispatch is involved.
6. Validate against Stripe only if the failing payload is a **Stripe-sourced** event; use [Event object](https://stripe.com/docs/api/events/object) docs for shape, not as ledger truth.

## Mini-playbook: [:accrue, :ops, :meter_reporting_failed]

Always read the **contract** (when the tuple fires and what each `source` means) at [`telemetry.md#meter-reporting-semantics`](telemetry.md#meter-reporting-semantics) before changing alert thresholds—this runbook is **procedure** only.

1. Read `source` (`:sync`, `:webhook`, `:reconciler`) plus `meter_event_id` / `event_name` from metadata (identifiers only—no raw payloads).
2. Load the matching `accrue_meter_events` row and note `stripe_status`, `stripe_error`, and timestamps so you know whether the failure epoch is already terminal.

### `:sync` (host request path)

1. Correlate with the host request or job that called `Accrue.Billing.report_usage/3` in the same transaction window; inspect logs around `Accrue.Billing.MeterEventActions` for processor errors surfaced synchronously.
2. Fix configuration or upstream Stripe errors, then retry the host operation with a fresh `operation_id` only when the business case requires a new attempt—idempotent replays should converge on the stored terminal row.

### `:reconciler` (Oban `:accrue_meters`)

1. Inspect Oban jobs for `Accrue.Jobs.MeterEventsReconciler` on `:accrue_meters` ([Oban queue topology](#oban-queue-topology)); confirm the queue is running and not wedged behind retries.
2. After correcting Stripe meter setup or credentials, allow the reconciler to dequeue; watch `[:accrue, :ops, :meter_reporting_failed]` and default metrics for confirmation.

### `:webhook` (meter error report path)

1. Trace the event through `accrue_webhook_events` into `Accrue.Webhook.DefaultHandler` and the async `Accrue.Webhook.DispatchWorker` path; verify signature + dispatch health before mutating rows ([Oban queue topology](#oban-queue-topology)).
2. Resolve the upstream Stripe meter error, then replay or wait for the next reconciler pass; confirm the row leaves terminal `failed` only when business logic intentionally clears it.

Shared verification (all sources):

3. Confirm API keys and Stripe meter configuration for the environment (no key material in logs).
4. Cross-check Stripe usage reporting with [Metered billing](https://stripe.com/docs/billing/subscriptions/usage-based/recording-usage) — operational alignment, not accounting close.
5. After code or config fix, allow reconciler retry where applicable; watch ops counters and host metrics.

## Mini-playbook: [:accrue, :ops, :revenue_loss]

1. Capture `reason`, `subject_type`, `subject_id`, and currency amounts from telemetry (aggregates / IDs only — no customer narrative in shared logs).
2. Triage Accrue rows (invoice, credit note, adjustment) that triggered the signal; avoid manual balance edits without a controlled procedure.
3. Check related async work on `:accrue_reconcilers` and `:accrue_webhooks` if the loss correlates with webhook or fee reconciliation ([Oban queue topology](#oban-queue-topology)).
4. In Stripe, locate the **same business object** (charge, refund, dispute) via Dashboard search or list filters; use [Balance transactions](https://stripe.com/docs/reports/balance-transaction-types) categories as reference for **classification**, not as instructions to reproduce Sigma in-app.
5. Document outcome in your ticketing system; escalate finance questions on Stripe’s side, not via Accrue as a ledger substitute.

## RUN-01 coverage

- **Full ops tuple list and one-line first actions** live under **`## Operator runbooks (first actions)`** in [`telemetry.md`](telemetry.md) — bookmark that table for **every** RUN-01 class, including `:connect_account_deauthorized`, `:connect_payout_failed`, `:dunning_exhaustion`, `:charge_failed`, `:incomplete_expired`, `:pdf_adapter_unavailable`, replay (`:webhook_dlq, :replay`), and prune (`:webhook_dlq, :prune`).
- **This file** adds **depth** only for the four mini-playbooks above (`:webhook_dlq, :dead_lettered`, `:events_upcast_failed`, `:meter_reporting_failed`, `:revenue_loss`).

## See also

- [`guides/telemetry.md`](telemetry.md) — ops catalog SSOT and **Operator runbooks (first actions)** table
- `Accrue.Telemetry.Ops` — `emit/3` contract (`lib/accrue/telemetry/ops.ex` in the repo; published API on [Hexdocs](https://hexdocs.pm/accrue/))
- Hexdocs path pattern: `https://hexdocs.pm/accrue/` (pin the version to your `mix.lock`)
