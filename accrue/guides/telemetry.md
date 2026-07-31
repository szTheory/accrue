# Telemetry & Observability

Accrue emits `:telemetry` events for every public entry point. This guide
documents the conventions, the high-signal `[:accrue, :ops, :*]` namespace,
the OpenTelemetry span naming rules, and the default
`Telemetry.Metrics` recipe.

If you only read one section: jump to **Using the default metrics recipe**
below — that's the short host wiring snippet that appends `Accrue.Telemetry.Metrics.defaults/0`
(~20 metric definitions, including every documented ops counter) with minimal glue code.

**Doc contract:** Published Hex docs for `accrue` describe the telemetry
contracts for that package version. The `main` branch may add or rename
events before they appear in a Hex release; operators should prefer the
`guides/telemetry.md` revision that matches the `accrue` version pinned in
their host `mix.lock` (see [Hex](https://hexdocs.pm/accrue) for the published
guide snapshot).

## Namespace split

Accrue divides telemetry into two namespaces:

- **`[:accrue, :*]` — the firehose.** Every public Accrue entry point emits
  `:start` / `:stop` / `:exception` here via `Accrue.Telemetry.span/3`. High
  cardinality. Use for tracing, debug, and traffic shape — **NOT** for paging
  on-call.
- **`[:accrue, :ops, :*]` — SRE-actionable signals.** Low cardinality, high
  value. Every event in this namespace is an alertable condition that should
  wake somebody up (or at least file a ticket). Subscribe handlers here, set
  thresholds, sleep well.

The split exists because Accrue's firehose is too noisy for alerting — a
busy SaaS dispatching webhooks, finalizing invoices, and reporting usage
events emits hundreds of `[:accrue, :*]` events per second. The ops namespace
is curated: every event is a real ops signal, not a heartbeat.

### Firehose and diagnostic events (not in `[:accrue, :ops, :*]`)

These are useful for **tracing, dashboards, and anomaly detection**, not
typically for paging:

- **Billing spans** — `Accrue.Telemetry.span/3` on every public `Accrue.Billing`
  entry point: `[:accrue, :billing, :<resource>, :<action>, :start | :stop | :exception]`
  (see `Accrue.Telemetry` module doc).
- **Webhooks** — `[:accrue, :webhook, :receive]`, handler exceptions, orphan
  reducers under `[:accrue, :webhooks, :orphan_*]`, `[:accrue, :webhooks, :stale_event]`, etc.
- **Entitlements** — `[:accrue, :entitlements, :check]` (per-decision gate
  telemetry) and `[:accrue, :entitlements, :sync]` (advisory Stripe-native
  cache-write span; see the **Entitlement sync events** section below).
- **Mail / PDF** — `[:accrue, :mailer, :deliver, …]`, `[:accrue, :pdf, :render, …]`,
  email fallbacks `[:accrue, :email, :locale_fallback | :timezone_fallback | :format_money_failed]`.

Subscribe in your host `Telemetry` or OpenTelemetry pipeline when you need
latency percentiles, diagnostics, or high-cardinality dashboards — keep
**on-call paging** on `[:accrue, :ops, :*]` above. The firehose stays useful
for tracing and anomaly detection, but its volume is intentionally unsuitable
for wake-the-oncall thresholds.

### Entitlement sync events (optional Stripe-native advisory cache)

These events fire **only** when a host opts into the optional Stripe-native
entitlement sync (`config :accrue, entitlements: [stripe_native_sync:
:advisory]`, default `:disabled`) **and** enables the
`entitlements.active_entitlement_summary.updated` event on their Stripe
Dashboard webhook endpoint. The advisory cache is **observational only** — it
never changes `entitled?` / `has_active_plan?`. See
[Entitlements › Optional Stripe-native sync (advisory)](entitlements.md#optional-stripe-native-sync-advisory)
for the full story. All dimensions are allowlist-safe IDs and counts — the OTel
`@allowed_attributes` allowlist is intentionally **not** widened for
`entitlement_count` / `has_more` (telemetry-only).

| Event | Measurements | Metadata | Notes |
|-------|-------------|----------|-------|
| `[:accrue, :entitlements, :sync]` (`:start` / `:stop` / `:exception`) | span | `customer_id` | The cache-write span. The deliberate **state-change** mirror of `[:accrue, :entitlements, :check]` (per-decision, telemetry-only) — this is the ENT-05 split made visible in two spans. |
| `[:accrue, :entitlements, :summary_synced]` | `count`, `entitlement_count` | `customer_id`, `has_more`, `result` (`:written` \| `:unchanged`) | Fires on every processed summary. `result: :written` = the advisory cache changed (also ledgered as `entitlements.summary.synced`); `result: :unchanged` = a redelivery the reducer processed with no material change (**no** ledger row) — the signal lets you observe idempotent redelivery without an audit row. |
| `[:accrue, :webhooks, :stale_event]` (reused) | — | `object_type: :entitlement_summary`, `stripe_id`, `event_id` | An out-of-order or replayed summary older than the cache watermark was skipped (monotonic guard). The same `:stale_event` used by every other monotonic reducer — not a new variant. |
| `[:accrue, :webhooks, :orphan_entitlement_summary]` (reused shape) | — | `customer_stripe_id` | A summary arrived for a `cus_` with no local customer row; the cache is deferred (`{:ok, :deferred}`), never raising and never creating a customer. |
| `[:accrue, :ops, :entitlement_summary_truncated]` | `count` | `customer_id`, `operation_id` when set | **Ops signal** (see the catalog table below). Identifies a known-incomplete webhook advisory snapshot when `has_more: true`; client-backed pull exhaustively streams active entitlements before persistence. Neither path gates local access. |

## Ops event catalog (`[:accrue, :ops, :*]`)

All ops events fire inside the same `Repo.transact/2` as the state write
they correspond to — they are idempotent under webhook replay via the
`accrue_webhook_events` unique-index short-circuit.

| Event | Measurements | Metadata | Primary owner |
|-------|-------------|----------|---------------|
| `[:accrue, :ops, :revenue_loss]` | `count`, `amount_minor`, `currency` | `subject_type`, `subject_id`, `reason` | `Accrue.Telemetry.Ops` |
| `[:accrue, :ops, :dunning_exhaustion]` | `count` | `subscription_id`, `from_status`, `to_status`, `source` (`:accrue_sweeper \| :stripe_native \| :manual`) | `Accrue.Webhook.DefaultHandler` |
| `[:accrue, :ops, :dunning_campaign_started]` | `count` | `subscription_id`, `step_count` (no `source`) | `Accrue.Webhook.DefaultHandler` |
| `[:accrue, :ops, :dunning_step_sent]` | `count` | `subscription_id`, `step_key`, `step_index` | `Accrue.Workers.DunningStep` |
| `[:accrue, :ops, :dunning_recovered]` | `count` | `subscription_id`, `source` (`:accrue_sweeper \| :stripe_native \| :manual`) | `Accrue.Webhook.DefaultHandler` |
| `[:accrue, :ops, :dunning_exhausted]` | `count` | `subscription_id`, `to_status`, `source` (`:accrue_sweeper \| :stripe_native \| :manual`) | `Accrue.Webhook.DefaultHandler` |
| `[:accrue, :ops, :discount_mapping_invalid]` | `count` | `mapping_id`, `code`, `discount_id`, `reason`, `operation_id` | `Accrue.Billing.SubscriptionActions` |
| `[:accrue, :ops, :incomplete_expired]` | `count` | `subscription_id` | `Accrue.Telemetry.Ops` |
| `[:accrue, :ops, :charge_failed]` | `count` | `charge_id`, `customer_id`, `failure_code` | `Accrue.Telemetry.Ops` |
| `[:accrue, :ops, :customer_projection_sync_failed]` | `count` | `customer_id`, `processor`, `processor_id`, `operation_id`, `changed_fields`, `failure_kind` | `Accrue.Billing` |
| `[:accrue, :ops, :meter_reporting_failed]` | `count` | `meter_event_id`, `event_name`, `source` (`:reconciler \| :webhook \| :sync`) | `Accrue.Webhook.DefaultHandler` / `Accrue.Billing.MeterEventActions` / `Accrue.Jobs.MeterEventsReconciler` |
| `[:accrue, :ops, :metered_renewal_stale_repaired]` | `count` | `source` (`:reconciler`), `processor`, `subscription_id`, `metered_renewal_id` | `Accrue.Jobs.MeteredRenewalReconciler` |
| `[:accrue, :ops, :metered_missing_definition]` | `count` | `processor`, `subscription_id`, `metered_renewal_id`, `unmatched_event_count` | `Accrue.Billing.MeteredRenewalInvoice` |
| `[:accrue, :ops, :metered_charge_awaiting_payment_method]` | `count` | `processor`, `state`, `subscription_id`, `metered_renewal_id`, `failure_class` | `Accrue.Billing.MeteredRenewalActions` |
| `[:accrue, :ops, :metered_charge_failed_exhausted]` | `count` | `processor`, `state`, `subscription_id`, `metered_renewal_id`, `failure_class` | `Accrue.Billing.MeteredRenewalActions` |
| `[:accrue, :ops, :webhook_dlq, :dead_lettered]` | `count` | `event_id`, `processor_event_id`, `type`, `attempt` | `Accrue.Webhook.DispatchWorker` |
| `[:accrue, :ops, :webhook_dlq, :replay]` | `count`, `duration`, `requeued_count`, `skipped_count` | `actor`, `filter`, `dry_run?` | `Accrue.Webhooks.DLQ` |
| `[:accrue, :ops, :webhook_dlq, :prune]` | `dead_deleted`, `succeeded_deleted`, `duration` | `retention_days` | `Accrue.Webhook.Pruner` |
| `[:accrue, :ops, :pdf_adapter_unavailable]` | `count` | `adapter` (`:chromic_pdf`), `surface` (`:invoice_pdf`), `operation_id` when set | `Accrue.Invoices` |
| `[:accrue, :ops, :events_upcast_failed]` | `count` | `event_id`, `type`, `schema_version` | `Accrue.Events` |
| `[:accrue, :ops, :connect_account_deauthorized]` | `count` | `stripe_account_id`, `deauthorized_at` **or** `unresolved: true` | `Accrue.Webhook.ConnectHandler` |
| `[:accrue, :ops, :connect_capability_lost]` | `count` | `stripe_account_id`, `capability`, `from`, `to` | `Accrue.Webhook.ConnectHandler` |
| `[:accrue, :ops, :connect_payout_failed]` | `count` | `stripe_account_id`, `payout_id`, `amount`, `currency`, `failure_code` | `Accrue.Webhook.ConnectHandler` |
| `[:accrue, :ops, :entitlement_summary_truncated]` | `count` | `customer_id`, `operation_id` when set | `Accrue.Webhook.DefaultHandler` |

<a id="meter-reporting-semantics"></a>
## Meter reporting failures: semantics & sources

`[:accrue, :ops, :meter_reporting_failed]` fires on the **first durable** transition of a meter row into terminal **`failed`** (as enforced by `Accrue.Billing.MeterEvents` guarded updates)—**not** once per HTTP retry, Stripe redelivery, webhook replay, or idempotent `report_usage` replay. Treat it as a terminal-epoch signal, not retry noise.

- **`:sync`** — immediate host call path: failures originate in `Accrue.Billing.MeterEventActions` while handling `Accrue.Billing.report_usage/3` inside the same transaction that attempted the processor report.
- **`:reconciler`** — background reconciliation: `Accrue.Jobs.MeterEventsReconciler` on queue `:accrue_meters` retries stuck `pending` rows and emits this ops tuple when a durable `failed` transition is recorded.
- **`:webhook`** — Stripe-reported meter errors: `Accrue.Webhook.DefaultHandler` ingests the billing path and `Accrue.Webhook.DispatchWorker` carries the async context when the handler marks the row `failed` with telemetry.

Read this block before tuning Grafana annotations—alert links should point here (tuple + semantics), then [`operator-runbooks.md`](operator-runbooks.md) for ordered triage.

## Braintree metered billing ops semantics

These tuples are specific to the Braintree-local metering architecture.
They are **durable transition signals**, not per-attempt noise:

- `[:accrue, :ops, :metered_renewal_stale_repaired]` fires when the scheduled backstop opens a renewal window that the webhook-primary path missed after the grace period.
- `[:accrue, :ops, :metered_missing_definition]` fires when local aggregation closes a renewal window with unmatched usage because no local meter definition bound those events to a billable target.
- `[:accrue, :ops, :metered_charge_awaiting_payment_method]` fires on the first durable transition of a renewal window into the customer-repair state.
- `[:accrue, :ops, :metered_charge_failed_exhausted]` fires on the first durable transition of a renewal window into terminal settlement exhaustion.

The matching default counters are:

- `accrue.ops.metered_renewal_stale_repaired.count`
- `accrue.ops.metered_missing_definition.count`
- `accrue.ops.metered_charge_awaiting_payment_method.count`
- `accrue.ops.metered_charge_failed_exhausted.count`

Those counters stay low-cardinality. Identifiers remain in telemetry metadata, not metric tags.

## Webhook replay and local checkout completion semantics

The webhook and portal completion signals used in operator triage are also
provider-honest:

- `[:accrue, :ops, :webhook_dlq, :replay]` describes replay of persisted
  Accrue webhook rows through `Accrue.Webhooks.DLQ`; it is the recovery signal
  for both Stripe delivery failures and Braintree normalization or dispatch
  failures.
- `[:accrue, :portal, :checkout, :completed]` is the local portal-completion
  telemetry event emitted after Accrue persists and reduces
  `accrue.portal.checkout.completed`.

For Braintree, checkout completion is locally persisted and projection-backed.
Do not treat it like a Stripe-style hosted redirect truth. The mounted checkout
flow returns a local URL, and the operator-visible completion proof is the
synthetic `accrue.portal.checkout.completed` event plus the projection updates
it drives.

Connect ops rows above are emitted via `Accrue.Telemetry.Ops.emit/3` from
`Accrue.Webhook.ConnectHandler`. The invoice PDF unavailable signal now emits
through the same helper from `Accrue.Invoices`, while ledger rows still use
`:telemetry.execute/3` directly with the same `[:accrue, :ops]` prefix —
treated as **first-class ops signals** for paging and dashboards.

**Note:** `[:accrue, :ops, :revenue_loss]`, `:incomplete_expired`, and
`:charge_failed` are part of the supported **host + Accrue** ops vocabulary
(`Ops.emit/3` and metrics defaults). Prefer `Ops.emit/3` from host billing
code so `operation_id` merges consistently; search the codebase for concrete
emit sites when wiring alerts.

Every ops event also carries an automatically-merged `operation_id` field
in metadata, sourced from `Accrue.Actor.current_operation_id/0` (the same
seed used for processor idempotency keys). This lets you correlate
ops events with the originating webhook, Oban job, or admin action across
service boundaries.

**Last reconciled with the ops gap audit:** 2026-04-21 — PR #14.
That audit is reflected in the ops catalog table above, including
Connect, PDF, ledger, and DLQ rows.

## Span naming conventions (OpenTelemetry)

Accrue's OpenTelemetry span helpers (gated on the `:opentelemetry` optional
dep) wrap every Billing context function with consistent naming:

```
accrue.<domain>.<resource>.<action>
```

Domains emitted through `Accrue.Telemetry.span/3` today are `:billing`,
`:connect`, `:mailer`, `:pdf`, `:processor`, and `:storage` (see
`Accrue.Telemetry` module doc). **Illustrative, non-exhaustive** billing
examples below — for the enforced billing span inventory, see
[`test/accrue/telemetry/billing_span_coverage_test.exs`](../test/accrue/telemetry/billing_span_coverage_test.exs).

- `accrue.billing.subscription.create`
- `accrue.billing.subscription.cancel`
- `accrue.billing.invoice.finalize`
- `accrue.billing.charge.refund`
- `accrue.billing.meter_event.report_usage` — verified billing span from
  `Accrue.Billing.report_usage/3`; failures surface as the ops signal
  `[:accrue, :ops, :meter_reporting_failed]` (see ops catalog table).
- `accrue.billing.payment_method.list` — `[:accrue, :billing, :payment_method, :list]`
  from `Accrue.Billing.list_payment_methods/2` (processor-backed read; no extra
  ops tuple).
- <a id="billing-billing-portal-create"></a> `accrue.billing.billing_portal.create` —
  `[:accrue, :billing, :billing_portal, :create]`
  from `Accrue.Billing.create_billing_portal_session/2`.
  Interpret this provider-honestly: Stripe emits the span before returning an
  upstream hosted portal URL, while Braintree emits the same span before
  returning a mounted local billing portal URL from `accrue_portal`.
- <a id="billing-checkout-session-create"></a> `accrue.billing.checkout_session.create` —
  `[:accrue, :billing, :checkout_session, :create]` from
  `Accrue.Billing.create_checkout_session/2`. **Checkout-only span metadata** merged
  from validated attrs is exactly **`checkout_mode`**, **`checkout_ui_mode`**,
  and **`checkout_line_items_count`** — no checkout URLs, **`client_secret`**,
  or raw attrs blob (behavioral SSOT: `checkout_session_facade_test.exs` +
  `merge_checkout_session_create_metadata/4`). Prefer these on **spans**;
  **do not** promote them unmodified to **`Telemetry.Metrics` tags** (see
  **Cardinality discipline** below).
  For operators, the important distinction is not the shared event name but the
  returned surface: Stripe checkout resolves to an upstream hosted URL, while
  Braintree checkout resolves to a mounted local URL whose completion is
  persisted locally after the portal flow succeeds. Local discount preview is
  intentionally provisional; watch the final submit path, not preview-only UI,
  when triaging checkout completion.
- `accrue.billing.payment_method.attach` — `[:accrue, :billing, :payment_method, :attach]`
  from `Accrue.Billing.attach_payment_method/3`.
- `accrue.billing.payment_method.detach` — `[:accrue, :billing, :payment_method, :detach]`
  from `Accrue.Billing.detach_payment_method/2`.
- `accrue.billing.payment_method.set_default` — `[:accrue, :billing, :payment_method, :set_default]`
  from `Accrue.Billing.set_default_payment_method/3`.
- `NOT an OTel span name` — `accrue.webhooks.dlq.replay` is the dotted
  **OpenTelemetry span name** only when a host maps the **ops** event
  `[:accrue, :ops, :webhook_dlq, :replay]` (via `Ops.emit/3` / `:telemetry.execute`)
  into OTel separately. It is **not** produced by `Accrue.Telemetry.span/3`.

This mirrors the `:telemetry` event naming
(`[:accrue, :billing, :subscription, :create]`) so a single name maps cleanly
to both the telemetry event and the OTel span — no translation table.

**Last reconciled (billing span examples):** 2026-04-24
(checkout_session catalog row; `billing_span_coverage_test.exs` unchanged).

**Span kind:**
- `INTERNAL` for Accrue context functions
- `CLIENT` for outbound `lattice_stripe` calls (the underlying HTTP layer
  emits these via its own instrumentation)

## Attribute conventions

Accrue spans attach a small, fixed set of business-meaningful attributes.
Hosts adding their own spans on top of Accrue should follow the same
discipline — both for grep-ability across services and for the PII contract
below.

**Allowed attributes** (host-queryable, audit-useful, PII-free):

- `accrue.subscription.id` — Accrue's internal UUID
- `accrue.customer.id` — Accrue's internal UUID
- `accrue.invoice.id`
- `accrue.charge.id`
- `accrue.event_type` — webhook event type string (e.g. `"invoice.paid"`)
- `accrue.processor` — `:stripe` | `:fake`
- `stripe.subscription.id` — upstream Stripe ID (for support bridging)
- `stripe.customer.id`
- `stripe.charge.id`
- `stripe.invoice.id`
- `stripe.payment_intent.id`

**PROHIBITED attributes** (NEVER attach to spans, telemetry events, or
metric tags):

- Any customer email, name, phone, postal address
- Any card PAN, CVC, expiry, fingerprint metadata
- Any Stripe `PaymentMethod` raw response data
- Any webhook raw body or signature
- Any `Accrue.Money` amounts that identify a specific customer's purchase
  history (aggregate amounts at the metric level are fine; per-customer
  amounts at the span/event level are not)
- Any free-text reason fields supplied by end users (refund notes, support
  tickets, etc.)

The rule of thumb: **attach PII-free identifiers ONLY**. If an attribute
could be reversed into a person, don't attach it. This is a host
responsibility too — Accrue cannot inspect your custom span attributes for
PII at runtime, so code review and the grep-able allowlist above are the
enforcement mechanism.

## Using the default metrics recipe

`Accrue.Telemetry.Metrics.defaults/0` returns a list of ready-to-use
`Telemetry.Metrics` definitions covering the billing context, webhook
pipeline, and ops namespace. It is conditionally compiled on the optional
`:telemetry_metrics` dep.

Add the dep to your host app:

```elixir
# mix.exs
{:telemetry_metrics, "~> 1.1"},
{:telemetry_metrics_prometheus, "~> 1.1"}  # or your reporter of choice
```

Then wire it in:

```elixir
defmodule MyApp.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg), do: Supervisor.start_link(__MODULE__, arg, name: __MODULE__)

  @impl true
  def init(_arg) do
    children = [
      {TelemetryMetricsPrometheus, [metrics: metrics()]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics do
    [
      counter("my_app.request.count")
      # ... your other host metrics ...
    ] ++ Accrue.Telemetry.Metrics.defaults()
  end
end
```

This wires in the default metric set covering the billing context, webhook
pipeline, and full ops namespace (including Connect and PDF ops signals).
Distributions and percentile summaries beyond
these are host choice — Accrue doesn't prescribe binning strategies because
appropriate buckets depend heavily on your traffic shape and SLO targets.

The default recipe includes counters for **every** `[:accrue, :ops, :*]` event
documented in the table above (including Connect, PDF fallback, and ledger
upcast failures), so Prometheus-style scrapers stay aligned with the ops
catalog.

### Cardinality discipline

The default metric definitions only attach low-cardinality `tags` (`:status`,
`:source`, `:type`, `:stripe_status`). Customer IDs, subscription IDs, and
other unbounded identifiers are **never** promoted to metric tags — they
belong on spans, not metrics. If you add custom Accrue-derived metrics in
your host app, follow the same rule: anything with more than ~50 distinct
values per day is a span attribute, not a metric tag.

## Emitting custom ops events

If your host app fires billing-adjacent ops events (e.g. a custom revenue
recognition reconciler), prefer `Accrue.Telemetry.Ops.emit/3` over raw
`:telemetry.execute/3` — it enforces the namespace prefix and auto-merges
`operation_id` from the process dict:

```elixir
Accrue.Telemetry.Ops.emit(
  :revenue_loss,
  %{count: 1, amount_minor: 9900, currency: "usd"},
  %{subject_type: "Subscription", subject_id: sub.id, reason: :fraud_refund}
)
# → emits [:accrue, :ops, :revenue_loss] with operation_id auto-merged
```

For multi-segment events (sub-namespaces), pass a list:

```elixir
Accrue.Telemetry.Ops.emit(
  [:webhook_dlq, :replay],
  %{count: 12, requeued_count: 12, skipped_count: 0, duration: 142_000},
  %{actor: :admin, filter: %{type: "invoice.paid"}, dry_run?: false}
)
# → emits [:accrue, :ops, :webhook_dlq, :replay]
```

The `[:accrue, :ops]` prefix is hardcoded — callers cannot inject events
outside the namespace via this helper. If you need to emit
under `[:accrue, :*]` for the firehose, use `Accrue.Telemetry.span/3`
instead.

## Cross-domain host subscription

Phoenix controllers, LiveViews, Channels, and plain processes often need a
**small, high-signal** Accrue hook without subscribing to the full billing
firehose. Use the public modules only — `Accrue.Telemetry` (span naming),
`Accrue.Telemetry.Metrics` (default counters), and `Accrue.Telemetry.Ops`
(`emit/3` contract) — and the same `:telemetry` APIs you already use elsewhere.

Append `Accrue.Telemetry.Metrics.defaults/0` to your host metric list (see
**Using the default metrics recipe** above) so scrapers stay aligned with the
ops catalog. The authoritative tuple list lives in the **Ops event catalog**
table earlier in this guide — **do not fork** that table into a second
inventory here.

### Ops attach (webhook DLQ dead-lettered)

This pattern mirrors the checked-in `examples/accrue_host` app: start a tiny
process once from supervision, call `:telemetry.attach/4` with a stable
handler id, and detach on shutdown so dev hot reload does not stack duplicate
handlers.

```elixir
:telemetry.attach(
  "accrue-host-ops-dlq-dead-lettered",
  [:accrue, :ops, :webhook_dlq, :dead_lettered],
  fn _event, measurements, _metadata, _config ->
    require Logger
    # Low-cardinality only — never log full metadata maps from billing.
    Logger.info("accrue ops webhook_dlq dead_lettered count=#{measurements.count}")
  end,
  nil
)
```

### Optional: billing spans without metric-tag explosions

`Accrue.Telemetry.span/3` on billing entry points emits
`[:accrue, :billing, :*, :start | :stop | :exception]` — **high cardinality**.
If you add a handler, subscribe to **`:stop` and `:exception` only** for
dashboards or logs. **Do not** copy customer IDs, subscription IDs, or other
unbounded fields into **metric tags**; identifiers belong in traces or
scrubbed log lines, not Prometheus labels.

### OpenTelemetry–first hosts

Teams standardizing on **OpenTelemetry** may **skip `Telemetry.Metrics`**
entirely and attach handlers or OTel bridges directly to `:telemetry` events
instead — the ops catalog tuples still apply. Prefer spans for per-customer
detail; keep paging on `[:accrue, :ops, :*]`.

For **ordered triage**, default **Oban** queue placement (anchor **`#oban-queue-topology`** in [`operator-runbooks.md`](operator-runbooks.md)), and **expanded Stripe verification**, use **[Operator runbooks](operator-runbooks.md)**. This section keeps a **compact** signal → first-action table as your **starting point** — adjust for your support model and Stripe objects. Prefer Stripe Dashboard / Sigma for finance reporting; Accrue focuses on **state + webhooks + replay** in your app.

## Operator runbooks (first actions)

| Ops event | Suggested first actions |
|-----------|-------------------------|
| `[:accrue, :ops, :webhook_dlq, :dead_lettered]` | Inspect `accrue_webhook_events` row; fix handler bug or data; use admin **Replay** or DLQ tools; watch replay telemetry; (Oban defaults: [queue topology](operator-runbooks.md#oban-queue-topology)). |
| `[:accrue, :ops, :webhook_dlq, :replay]` | Validate `requeued_count` vs expectation; if dry-run, follow up with real replay. |
| `[:accrue, :ops, :meter_reporting_failed]` | Check `source` (`:sync`, `:webhook`, `:reconciler`); inspect `accrue_meter_events`; verify Stripe meter + API keys; retry after fix; (Oban defaults: [queue topology](operator-runbooks.md#oban-queue-topology)). |
| `[:accrue, :ops, :metered_renewal_stale_repaired]` | Confirm the renewal window was missing locally, then inspect Braintree renewal evidence and `Accrue.Jobs.MeteredRenewalReconciler` cadence before widening the backstop. |
| `[:accrue, :ops, :metered_missing_definition]` | Add or repair the local meter definition, then inspect the affected renewal window and its unmatched events before replaying settlement. |
| `[:accrue, :ops, :metered_charge_awaiting_payment_method]` | Repair the customer’s default payment method, then replay the same renewal window rather than creating a new charge unit. |
| `[:accrue, :ops, :metered_charge_failed_exhausted]` | Treat the renewal as terminal until an operator decides whether to retry, refund, or write off the local invoice. |
| `[:accrue, :ops, :dunning_exhaustion]` | Confirm subscription status transition; notify customer success; verify payment method in Stripe. |
| `[:accrue, :ops, :dunning_campaign_started]` | A dunning campaign began (first `:past_due` failure). Confirm the day-0 step enqueued; no action needed unless campaign_started rate spikes (payment-processor incident). |
| `[:accrue, :ops, :dunning_step_sent]` | A dunning step email was delivered. Use `step_key` + `step_index` to confirm cadence progression; investigate if a `final_notice` rate climbs (recovery is failing upstream). |
| `[:accrue, :ops, :dunning_recovered]` | The subscription recovered out of dunning. Confirm the payment method was updated; the campaign steps are auto-cancelled — no manual cleanup needed. |
| `[:accrue, :ops, :dunning_exhausted]` | Confirm the terminal transition (`to_status` `:unpaid`/`:canceled`) and notify customer success; this is the canonical recovered-vs-lost loss signal. |
| `[:accrue, :ops, :revenue_loss]` | Triage `reason` + `subject_*`; fraud vs refund policy; reconcile with Stripe balance transactions; (Oban defaults: [queue topology](operator-runbooks.md#oban-queue-topology)). |
| `[:accrue, :ops, :charge_failed]` | Map `failure_code`; prompt card update or alternative PM; check Radar rules in Stripe if unexpected. |
| `[:accrue, :ops, :incomplete_expired]` | Incomplete checkout/subscription expired; clean up local rows; marketing follow-up if abandoned cart. |
| `[:accrue, :ops, :pdf_adapter_unavailable]` | Start ChromicPDF (or switch PDF adapter); emails still send with hosted invoice link fallback. |
| `[:accrue, :ops, :events_upcast_failed]` | **Data migration issue** — unknown `schema_version` for `type`; deploy compatible upcaster before replaying events; (Oban defaults: [queue topology](operator-runbooks.md#oban-queue-topology)). |
| `[:accrue, :ops, :connect_account_deauthorized]` | Disconnect Connect account in product UI; stop destination charges; audit open Connect transfers. |
| `[:accrue, :ops, :connect_capability_lost]` | Read `capability` + `to` status; Stripe Connect onboarding / requirements. |
| `[:accrue, :ops, :connect_payout_failed]` | Use `payout_id` + `failure_code` in Stripe; update bank account or resolve restriction. |
| `[:accrue, :ops, :entitlement_summary_truncated]` | Known-incomplete webhook advisory snapshot: `has_more: true` means only the first reported entitlements were received. Client-backed pull exhaustively streams active entitlements before persistence; neither path gates local access. |

## See also

- `Accrue.Telemetry` — `span/3` helper for the firehose namespace
- `Accrue.Telemetry.Ops` — `emit/3` helper for the ops namespace
- `Accrue.Telemetry.Metrics` — default `Telemetry.Metrics` recipe
- [`:telemetry`](https://hexdocs.pm/telemetry) — underlying event library
- [`telemetry_metrics`](https://hexdocs.pm/telemetry_metrics) — metric DSL
