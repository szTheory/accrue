# Telemetry & Observability

Accrue emits `:telemetry` events for every public entry point. This guide
documents the conventions, the high-signal `[:accrue, :ops, :*]` namespace,
the OpenTelemetry span naming rules, and the default
`Telemetry.Metrics` recipe.

If you only read one section: jump to **Using the default metrics recipe**
below — that's the short host wiring snippet that appends `Accrue.Telemetry.Metrics.defaults/0`
(~20 metric definitions, including every documented ops counter) with minimal glue code.

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
- **Mail / PDF** — `[:accrue, :mailer, :deliver, …]`, `[:accrue, :pdf, :render, …]`,
  email fallbacks `[:accrue, :email, :locale_fallback | :timezone_fallback | :format_money_failed]`.

Subscribe in your host `Telemetry` or OpenTelemetry pipeline when you need
latency percentiles or error rates — keep **on-call** subscriptions on
`[:accrue, :ops, :*]` above.

## Ops events in v1.0

All ops events fire inside the same `Repo.transact/2` as the state write
they correspond to — they are idempotent under webhook replay via the
`accrue_webhook_events` unique-index short-circuit.

| Event | Measurements | Metadata |
|-------|-------------|----------|
| `[:accrue, :ops, :revenue_loss]` | `count`, `amount_minor`, `currency` | `subject_type`, `subject_id`, `reason` |
| `[:accrue, :ops, :dunning_exhaustion]` | `count` | `subscription_id`, `from_status`, `to_status`, `source` (`:accrue_sweeper \| :stripe_native \| :manual`) |
| `[:accrue, :ops, :incomplete_expired]` | `count` | `subscription_id` |
| `[:accrue, :ops, :charge_failed]` | `count` | `charge_id`, `customer_id`, `failure_code` |
| `[:accrue, :ops, :meter_reporting_failed]` | `count` | `meter_event_id`, `event_name`, `source` (`:reconciler \| :webhook \| :sync`) |
| `[:accrue, :ops, :webhook_dlq, :dead_lettered]` | `count` | `event_id`, `processor_event_id`, `type`, `attempt` |
| `[:accrue, :ops, :webhook_dlq, :replay]` | `count`, `duration`, `requeued_count`, `skipped_count` | `actor`, `filter`, `dry_run?` |
| `[:accrue, :ops, :webhook_dlq, :prune]` | `dead_deleted`, `succeeded_deleted`, `duration` | `retention_days` |
| `[:accrue, :ops, :pdf_adapter_unavailable]` | `count` | `type` (email template key), `operation_id` when set |
| `[:accrue, :ops, :events_upcast_failed]` | `count` | `event_id`, `type`, `schema_version` |
| `[:accrue, :ops, :connect_account_deauthorized]` | `count` | `stripe_account_id`, `deauthorized_at` **or** `unresolved: true` |
| `[:accrue, :ops, :connect_capability_lost]` | `count` | `stripe_account_id`, `capability`, `from`, `to` |
| `[:accrue, :ops, :connect_payout_failed]` | `count` | `stripe_account_id`, `payout_id`, `amount`, `currency`, `failure_code` |

Connect ops rows above are emitted via `Accrue.Telemetry.Ops.emit/3` from
`Accrue.Webhook.ConnectHandler`. PDF and ledger rows use `:telemetry.execute/3`
directly with the same `[:accrue, :ops]` prefix — treat them as **first-class
ops signals** for paging and dashboards.

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

## Span naming conventions (OpenTelemetry)

Accrue's OpenTelemetry span helpers (gated on the `:opentelemetry` optional
dep) wrap every Billing context function with consistent naming:

```
accrue.<domain>.<resource>.<action>
```

The domain layer is one of `billing`, `events`, `webhooks`, `mail`, `pdf`,
`processor`, `checkout`, `billing_portal`. Concrete examples:

- `accrue.billing.subscription.create`
- `accrue.billing.subscription.cancel`
- `accrue.billing.invoice.finalize`
- `accrue.billing.charge.refund`
- `accrue.webhooks.dlq.replay`
- `accrue.checkout.session.create`
- `accrue.billing_portal.session.create`

This mirrors the `:telemetry` event naming
(`[:accrue, :billing, :subscription, :create]`) so a single name maps cleanly
to both the telemetry event and the OTel span — no translation table.

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

## Cross-domain example (non-billing Phoenix code)

A LiveView, Channel, or plain GenServer can attach to Accrue ops events the
same way as any other `:telemetry` event — no private Accrue modules required:

```elixir
# e.g. in application.ex after supervisor children start
:telemetry.attach_many(
  "my-app-accrue-ops-log",
  [
    [:accrue, :ops, :webhook_dlq, :dead_lettered],
    [:accrue, :ops, :meter_reporting_failed]
  ],
  fn event, measurements, metadata, _config ->
    require Logger
    Logger.warning("accrue ops #{inspect(event)} count=#{measurements.count} meta=#{inspect(Map.drop(metadata, []))}")
  end,
  nil
)
```

For structured logs or `Telemetry.Metrics`, use the same event names as in the
ops table. Correlate with your own `operation_id` if you seed
`Accrue.Actor` in the same process before calling Accrue.

## Operator runbooks (first actions)

Use this as a **starting point** — adjust for your support model and Stripe
objects. Prefer Stripe Dashboard / Sigma for finance reporting; Accrue focuses
on **state + webhooks + replay** in your app.

| Ops event | Suggested first actions |
|-----------|-------------------------|
| `[:accrue, :ops, :webhook_dlq, :dead_lettered]` | Inspect `accrue_webhook_events` row; fix handler bug or data; use admin **Replay** or DLQ tools; watch replay telemetry. |
| `[:accrue, :ops, :webhook_dlq, :replay]` | Validate `requeued_count` vs expectation; if dry-run, follow up with real replay. |
| `[:accrue, :ops, :meter_reporting_failed]` | Check `source` (`:sync`, `:webhook`, `:reconciler`); inspect `accrue_meter_events`; verify Stripe meter + API keys; retry after fix. |
| `[:accrue, :ops, :dunning_exhaustion]` | Confirm subscription status transition; notify customer success; verify payment method in Stripe. |
| `[:accrue, :ops, :revenue_loss]` | Triage `reason` + `subject_*`; fraud vs refund policy; reconcile with Stripe balance transactions. |
| `[:accrue, :ops, :charge_failed]` | Map `failure_code`; prompt card update or alternative PM; check Radar rules in Stripe if unexpected. |
| `[:accrue, :ops, :incomplete_expired]` | Incomplete checkout/subscription expired; clean up local rows; marketing follow-up if abandoned cart. |
| `[:accrue, :ops, :pdf_adapter_unavailable]` | Start ChromicPDF (or switch PDF adapter); emails still send with hosted invoice link fallback. |
| `[:accrue, :ops, :events_upcast_failed]` | **Data migration issue** — unknown `schema_version` for `type`; deploy compatible upcaster before replaying events. |
| `[:accrue, :ops, :connect_account_deauthorized]` | Disconnect Connect account in product UI; stop destination charges; audit open Connect transfers. |
| `[:accrue, :ops, :connect_capability_lost]` | Read `capability` + `to` status; Stripe Connect onboarding / requirements. |
| `[:accrue, :ops, :connect_payout_failed]` | Use `payout_id` + `failure_code` in Stripe; update bank account or resolve restriction. |

## See also

- `Accrue.Telemetry` — `span/3` helper for the firehose namespace
- `Accrue.Telemetry.Ops` — `emit/3` helper for the ops namespace
- `Accrue.Telemetry.Metrics` — default `Telemetry.Metrics` recipe
- [`:telemetry`](https://hexdocs.pm/telemetry) — underlying event library
- [`telemetry_metrics`](https://hexdocs.pm/telemetry_metrics) — metric DSL
