# Phase 103: Metering Engine - Pattern Map

**Mapped:** 2026-05-02
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/billing/meter_definition.ex` | model | CRUD | `accrue/lib/accrue/billing/meter_event.ex` | role-match |
| `accrue/lib/accrue/billing/meter_definitions.ex` | service | CRUD | `accrue/lib/accrue/billing/meter_events.ex` | role-match |
| `accrue/lib/accrue/billing/metered_renewal.ex` | model | event-driven | `accrue/lib/accrue/billing/meter_event.ex` | partial |
| `accrue/lib/accrue/billing/metered_charge_attempt.ex` | model | event-driven | `accrue/lib/accrue/billing/refund.ex` | partial |
| `accrue/lib/accrue/billing/metered_renewal_actions.ex` | service | event-driven | `accrue/lib/accrue/billing/meter_event_actions.ex` | strong |
| `accrue/lib/accrue/jobs/metered_renewal_reconciler.ex` | worker | batch | `accrue/lib/accrue/jobs/meter_events_reconciler.ex` | exact |
| `accrue/lib/accrue/jobs/process_metered_renewal.ex` | worker | request-response | `accrue/lib/accrue/jobs/meter_events_reconciler.ex` | role-match |
| `accrue/lib/accrue/webhook/default_handler.ex` | webhook reducer | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` | exact |
| `accrue/lib/accrue/billing/charge_actions.ex` | service | request-response | `accrue/lib/accrue/billing/charge_actions.ex` | exact |
| `accrue/lib/accrue/billing/invoice_projection.ex` | service | transform | `accrue/test/accrue/billing/invoice_projection_test.exs` | data-match |
| `accrue/lib/accrue/errors.ex` | utility | transform | `accrue/lib/accrue/errors.ex` | exact |
| `accrue/lib/accrue/telemetry/ops.ex` | utility | event-driven | `accrue/lib/accrue/telemetry/ops.ex` | exact |
| `accrue/lib/accrue/telemetry/metrics.ex` | config | event-driven | `accrue/lib/accrue/telemetry/metrics.ex` | exact |

## Pattern Assignments

### `accrue/lib/accrue/billing/metered_renewal_actions.ex` and `meter_definitions.ex`

**Analog:** `accrue/lib/accrue/billing/meter_event_actions.ex`

**Imports and dependency shape** ([meter_event_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/meter_event_actions.ex:28)):
```elixir
require Logger

alias Accrue.Actor
alias Accrue.Billing.Customer
alias Accrue.Billing.MeterEvent
alias Accrue.Billing.MeterEvents
alias Accrue.Events
alias Accrue.Processor
alias Accrue.Repo
```

**Durable outbox + external side effect split** ([meter_event_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/meter_event_actions.ex:81)):
```elixir
with :ok <- validate_backdating_window(ts),
     {:ok, row} <-
       insert_pending(customer, event_name, value, ts, identifier, override_op) do
  # Stripe call OUTSIDE Repo.transact/2. Crashes here leave the row in
  # `pending` for the reconciler to retry on its next cron tick.
  cond do
    row.stripe_status == "pending" ->
      case Processor.__impl__().report_meter_event(row) do
```

**Idempotent pre-check before transaction** ([meter_event_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/meter_event_actions.ex:164)):
```elixir
case Repo.get_by(MeterEvent, identifier: identifier) do
  %MeterEvent{} = existing ->
    {:ok, existing}

  nil ->
    do_insert_pending(customer, event_name, value, ts, identifier, override_op)
end
```

**What to copy for Phase 103**
- Persist the renewal-window record first, then do any Braintree settlement call outside `Repo.transact/2`.
- Make the renewal record, not Oban uniqueness, the canonical dedupe anchor.
- Record an `accrue_events` row in the same transaction as the local state change.

---

### `accrue/lib/accrue/jobs/metered_renewal_reconciler.ex` and `process_metered_renewal.ex`

**Analog:** `accrue/lib/accrue/jobs/meter_events_reconciler.ex`

**Worker shell** ([meter_events_reconciler.ex](/Users/jon/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex:35)):
```elixir
use Oban.Worker, queue: :accrue_meters, max_attempts: 3

@impl Oban.Worker
def perform(%Oban.Job{} = job) do
  _ = Accrue.Oban.Middleware.put(job)
  {:ok, _count} = reconcile()
  :ok
end
```

**Grace-window batch scan** ([meter_events_reconciler.ex](/Users/jon/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex:60)):
```elixir
cutoff = DateTime.add(Clock.utc_now(), -@grace_seconds, :second)

pending =
  from(m in MeterEvent,
    where: m.stripe_status == "pending" and m.inserted_at < ^cutoff,
    order_by: [asc: m.inserted_at],
    limit: @limit
  )
  |> Repo.all()
```

**Per-row retry with bounded failure transition** ([meter_events_reconciler.ex](/Users/jon/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex:71)):
```elixir
for row <- pending do
  case Processor.__impl__().report_meter_event(row) do
    {:ok, stripe_event} ->
      row
      |> MeterEvent.reported_changeset(stripe_event)
      |> Repo.update()

    {:error, err} ->
      _ = MeterEvents.mark_failed_with_telemetry(row, err, :reconciler)
      :ok
  end
end
```

**Operation-id restoration** ([middleware.ex](/Users/jon/projects/accrue/accrue/lib/accrue/oban/middleware.ex:48)):
```elixir
def put(%Oban.Job{id: id, attempt: attempt, args: args}) do
  Accrue.Actor.put_operation_id("oban-#{id}-#{attempt}")
  maybe_restore_stripe_account(args)
  :ok
end
```

**What to copy for Phase 103**
- Use one worker as the scheduled stale-window backstop and one worker as the unique renewal processor.
- Call `Accrue.Oban.Middleware.put/1` at the top of `perform/1`.
- Reconciliation should scan old `pending` or `retry_scheduled` rows after a grace period, not all rows.

---

### `accrue/lib/accrue/webhook/default_handler.ex`

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex`

**Webhook-first convergence contract** ([default_handler.ex](/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex:13)):
```elixir
1. Derives `evt_ts` from the raw event `created` unix timestamp.
2. Loads the local row by processor id.
3. **Skip stale**
4. **Refetch canonical:** always call `Accrue.Processor.fetch/2`
5. Project via the appropriate `*Projection.decompose/1`
6. Stamp `last_stripe_event_ts` / `last_stripe_event_id`
7. Record an `accrue_events` row in the same `Repo.transact/1`.
```

**Braintree type normalization** ([default_handler.ex](/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex:127)):
```elixir
case normalize_braintree_type(type) do
  {:ok, normalized_type} ->
    case dispatch(normalized_type, event.processor_event_id, event.created_at, %{
           "id" => event.object_id
         }) do
```

**Dispatch pattern for synthetic/local events** ([default_handler.ex](/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex:244)):
```elixir
defp dispatch("accrue.portal.checkout.completed", evt_id, evt_ts, obj) do
  reduce_portal_checkout_completed(evt_id, evt_ts, obj)
end
```

**Braintree invoice convergence via canonical fetch, not raw payload trust** ([default_handler.ex](/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex:661)):
```elixir
fetch_type = if processor_name() == "braintree", do: :subscription, else: :invoice

reduce_row(:invoice, stripe_id, evt_ts, evt_id, fn row ->
  with {:ok, canonical} <- Processor.__impl__().fetch(fetch_type, stripe_id),
       {:ok, %{invoice_attrs: attrs, item_attrs: item_attrs}} <-
         InvoiceProjection.decompose(canonical),
```

**What to copy for Phase 103**
- Open or advance the renewal window from Braintree lifecycle webhooks first.
- Normalize Braintree event names into Accrue’s existing event family model.
- Refetch canonical subscription/transaction state before mutating local renewal, invoice, or charge-attempt rows.
- If a renewal webhook arrives out of order, defer or no-op rather than overwrite newer local truth.

---

### `accrue/lib/accrue/billing/charge_actions.ex`

**Analog:** `accrue/lib/accrue/billing/charge_actions.ex`

**Typed no-default-PM failure** ([charge_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/charge_actions.ex:84)):
```elixir
{:error,
 %Accrue.Error.NoDefaultPaymentMethod{
   customer_id: customer.id,
   message:
     "Accrue.Billing.charge/3 requires an explicit :payment_method or " <>
```

**Deterministic idempotency key derivation** ([charge_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/charge_actions.ex:100)):
```elixir
op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
subject_uuid = Idempotency.subject_uuid(:create_charge, op_id)
idem_key = Idempotency.key(:create_charge, subject_uuid, op_id)
```

**External charge before local persistence** ([charge_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/charge_actions.ex:118)):
```elixir
# Call the processor OUTSIDE the Repo.transact so we can branch on
# SCA/3DS shape without persisting a half-baked Charge row
case Processor.__impl__().create_charge(params, stripe_opts) do
```

**Replay-safe local insert** ([charge_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/charge_actions.ex:245)):
```elixir
case Repo.get(Charge, subject_uuid) do
  %Charge{} = existing -> {:ok, existing}
  nil -> insert_charge(subject_uuid, customer, stripe_ch, amount)
end
```

**What to copy for Phase 103**
- Metered month-end settlement should derive its own deterministic subject/idempotency key from the renewal record.
- Resolve payment method explicitly and fail loudly with typed errors when absent.
- Persist the Braintree sale plus event record only after the processor call succeeds.

---

### `accrue/lib/accrue/billing/invoice_projection.ex` and local ledger/projection work

**Analog:** `accrue/test/accrue/billing/invoice_projection_test.exs` and `invoice_projection_braintree_refund_test.exs`

**Braintree invoice decomposition expectations** ([invoice_projection_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/invoice_projection_test.exs:217)):
```elixir
{:ok, %{invoice_attrs: attrs, item_attrs: items}} =
  InvoiceProjection.decompose(braintree_sub)

assert attrs.processor_id == "tx_abcde"
assert attrs.status == :paid
assert attrs.billing_reason == "subscription_cycle"
```

**Single local line item from Braintree transaction truth** ([invoice_projection_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/invoice_projection_test.exs:250)):
```elixir
assert length(items) == 1
[item] = items
assert item.stripe_id == "tx_abcde"
assert item.description == "Braintree subscription sub_12345"
assert item.price_ref == "basic_plan"
```

**Derived rollups without rewriting parent sale truth** ([invoice_projection_braintree_refund_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/invoice_projection_braintree_refund_test.exs:27)):
```elixir
{:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(braintree_sub)

assert Map.has_key?(attrs, :total_refunded_amount_minor)
assert Map.has_key?(attrs, :refund_count)
assert Map.has_key?(attrs, :refund_progress)
```

**What to copy for Phase 103**
- Keep the local invoice ledger canonical and decompose metered charges into invoice items.
- Expose derived rollups on read models instead of mutating sale-truth parent rows.
- Build customer/operator explanation from local invoice items and usage aggregates, not Braintree metadata strings.

---

### `accrue/lib/accrue/errors.ex`

**Analog:** `accrue/lib/accrue/errors.ex`

**Typed exceptions with user-safe messages** ([errors.ex](/Users/jon/projects/accrue/accrue/lib/accrue/errors.ex:161)):
```elixir
defmodule Accrue.Error.InvalidState do
  defexception [:current, :attempted, :message]
end
```

**Domain-specific typed error precedent** ([errors.ex](/Users/jon/projects/accrue/accrue/lib/accrue/errors.ex:213)):
```elixir
defmodule Accrue.Error.NoDefaultPaymentMethod do
  defexception [:customer_id, :message]
end
```

**What to copy for Phase 103**
- Add metering-specific typed errors instead of ad hoc atoms for invalid meter definitions, closed renewal states, and replay conflicts.
- Keep sensitive gateway payloads off exception messages; put raw provider detail in bounded data fields, not logs.

---

### `accrue/lib/accrue/telemetry/ops.ex` and `metrics.ex`

**Analog:** `accrue/lib/accrue/telemetry/ops.ex` and `metrics.ex`

**High-signal ops namespace only** ([ops.ex](/Users/jon/projects/accrue/accrue/lib/accrue/telemetry/ops.ex:41)):
```elixir
def emit(suffix, measurements, metadata)
    when is_list(suffix) and is_map(measurements) and is_map(metadata) do
  event = [:accrue, :ops] ++ suffix
```

**Automatic correlation metadata** ([ops.ex](/Users/jon/projects/accrue/accrue/lib/accrue/telemetry/ops.ex:63)):
```elixir
merged_metadata =
  Map.put_new_lazy(metadata, :operation_id, fn ->
    Accrue.Actor.current_operation_id()
  end)
```

**Low-cardinality metrics posture** ([metrics.ex](/Users/jon/projects/accrue/accrue/lib/accrue/telemetry/metrics.ex:33)):
```elixir
Tags on the default counters are restricted to low-cardinality fields
(`:status`, `:source`, `:type`, `:stripe_status`).
```

**Existing meter failure metric precedent** ([metrics.ex](/Users/jon/projects/accrue/accrue/lib/accrue/telemetry/metrics.ex:68)):
```elixir
counter("accrue.ops.meter_reporting_failed.count", tags: [:source])
counter("accrue.ops.charge_failed.count")
counter("accrue.ops.revenue_loss.count")
```

**What to copy for Phase 103**
- Emit ops events only on durable transitions such as `awaiting_payment_method`, `failed_exhausted`, or stale renewal detection.
- Keep tags bounded to fields like `:source`, `:status`, and maybe `:processor`; never meter definition ids or customer ids.
- Reuse `operation_id` correlation across webhook, worker, and recovery paths.

## Shared Patterns

### Unique jobs are advisory, local records are canonical
**Source:** [103-CONTEXT.md](/Users/jon/projects/accrue/.planning/phases/103-metering-engine/103-CONTEXT.md:64), [meter_event_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/meter_event_actions.ex:21)

Planner should require:
- a local unique renewal-window row per `subscription + period_start + period_end`
- a unique processing job keyed from that local row
- recovery logic that safely re-enqueues from local state

### Webhook-first, cron-backstop second
**Source:** [103-CONTEXT.md](/Users/jon/projects/accrue/.planning/phases/103-metering-engine/103-CONTEXT.md:39), [meter_events_reconciler.ex](/Users/jon/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex:54), [default_handler.ex](/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex:13)

Planner should treat the scheduler as stale-window detection only. Renewal and charge processing should primarily converge from webhook-derived cycle advancement.

### Local ledger first, gateway settlement second
**Source:** [103-CONTEXT.md](/Users/jon/projects/accrue/.planning/phases/103-metering-engine/103-CONTEXT.md:52), [invoice_projection_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/invoice_projection_test.exs:217)

Planner should split work so invoice-item/local-ledger persistence lands before Braintree sale orchestration, with the sale linked back to local invoice and aggregate rows.

### Typed errors and low-noise telemetry
**Source:** [103-CONTEXT.md](/Users/jon/projects/accrue/.planning/phases/103-metering-engine/103-CONTEXT.md:64), [errors.ex](/Users/jon/projects/accrue/accrue/lib/accrue/errors.ex:161), [ops.ex](/Users/jon/projects/accrue/accrue/lib/accrue/telemetry/ops.ex:1)

Planner should avoid “retry everything” flows. Distinguish retryable processor failures from customer-repair states using typed errors and emit ops telemetry once per durable transition.

### Recent Braintree plan granularity
**Source:** [100-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.32-phases/100-billing-portal-semantics/100-PLAN.md:1), [099-01-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-01-PLAN.md:1), [099-02-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-02-PLAN.md:1)

Planner should mirror these conventions:
- frontmatter with `wave`, `depends_on`, `files_modified`, `requirements`, `must_haves`, and `key_links`
- 2-3 tasks per plan, usually “tests first” then “implementation”, optionally a third narrow task
- each task names exact files, behavior bullets, a concrete action paragraph, `rg`-based acceptance criteria, one automated verify command, and a one-sentence `done`
- threat model and success criteria stay narrow to the slice, not the whole phase

## No Analog Found

None. Phase 103’s main seams all have partial or strong precedents in existing metering, refund convergence, charge, and projection code.

## Metadata

**Analog search scope:** `accrue/lib/accrue/billing`, `accrue/lib/accrue/jobs`, `accrue/lib/accrue/webhook`, `accrue/lib/accrue/processor`, `accrue/lib/accrue/telemetry`, `accrue/test/accrue/billing`, `.planning/phases`, `.planning/milestones/v1.32-phases`

**Files scanned:** 18
**Pattern extraction date:** 2026-05-02
