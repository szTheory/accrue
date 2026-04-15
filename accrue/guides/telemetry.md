# Telemetry & Observability

Accrue emits `:telemetry` events for every public entry point. This guide
documents the conventions, the high-signal `[:accrue, :ops, :*]` namespace,
the OpenTelemetry span naming rules (OBS-04), and the default
`Telemetry.Metrics` recipe (OBS-05).

If you only read one section: jump to **Using the default metrics recipe**
below — that's the four-line host wiring snippet that gets you ~15 production
metrics with zero glue code.

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

Every ops event also carries an automatically-merged `operation_id` field
in metadata, sourced from `Accrue.Actor.current_operation_id/0` (the same
seed used for processor idempotency keys, D2-12). This lets you correlate
ops events with the originating webhook, Oban job, or admin action across
service boundaries.

## Span naming conventions (OpenTelemetry, OBS-04)

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
enforcement mechanism (T-04-08-01, T-04-08-05).

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

This wires in ~15 default metrics covering the billing context, webhook
pipeline, and ops namespace. Distributions and percentile summaries beyond
these are host choice — Accrue doesn't prescribe binning strategies because
appropriate buckets depend heavily on your traffic shape and SLO targets.

### Cardinality discipline (T-04-08-03)

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
outside the namespace via this helper (T-04-08-02). If you need to emit
under `[:accrue, :*]` for the firehose, use `Accrue.Telemetry.span/3`
instead.

## See also

- `Accrue.Telemetry` — `span/3` helper for the firehose namespace
- `Accrue.Telemetry.Ops` — `emit/3` helper for the ops namespace
- `Accrue.Telemetry.Metrics` — default `Telemetry.Metrics` recipe
- [`:telemetry`](https://hexdocs.pm/telemetry) — underlying event library
- [`telemetry_metrics`](https://hexdocs.pm/telemetry_metrics) — metric DSL
