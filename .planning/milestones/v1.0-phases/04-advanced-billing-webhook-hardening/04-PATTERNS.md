# Phase 4: Advanced Billing + Webhook Hardening - Pattern Map

**Mapped:** 2026-04-14
**Files analyzed:** 35 new/modified files
**Analogs found:** 33 / 35 (2 with no direct analog — Mix tasks)

This document maps every new/modified file in Phase 4 to its closest existing analog in the Accrue codebase, with concrete excerpts the planner can cite as `read_first:` in PLAN action steps. All file paths are absolute.

---

## File Classification

### New schemas

| New File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/lib/accrue/billing/meter_event.ex` | schema | CRUD (outbox) | `/Users/jon/projects/accrue/accrue/lib/accrue/billing/coupon.ex` | role-match (thin projection w/ `data :map`) |
| `accrue/lib/accrue/billing/subscription_schedule.ex` | schema | webhook projection | `/Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice.ex` | role-match (dual changeset — user + `force_*`) |
| `accrue/lib/accrue/billing/promotion_code.ex` | schema | CRUD (passthrough) | `/Users/jon/projects/accrue/accrue/lib/accrue/billing/coupon.ex` | exact (Phase 3 D3-16 thin projection shape) |

### New / modified contexts (write surface)

| File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/lib/accrue/billing/meter_event_actions.ex` (NEW) — `report_usage/3` | context (Repo.transact + commit-then-Stripe) | request-response | `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex` (`subscribe/3` lines 68–102) | exact |
| `accrue/lib/accrue/billing/dunning.ex` (NEW) — pure policy | service (no side effects) | transform | `/Users/jon/projects/accrue/accrue/lib/accrue/billing/query.ex` | role-match (pure, property-testable) |
| `accrue/lib/accrue/billing/subscription_actions.ex` — extend `pause/2`/`unpause/2`/`resume/2` with `pause_behavior` | context | request-response | **self** — `pause/2` lines 491–537 already implements the idiom | exact (in-file extension) |
| `accrue/lib/accrue/billing/subscription_items.ex` (NEW) — `add_item/3`, `remove_item/2`, `update_item_quantity/3` (BILL-12) | context | CRUD | `subscription_actions.ex` (`update_quantity/3` lines 302–338) | exact |
| `accrue/lib/accrue/billing/coupon_actions.ex` (NEW) — `Coupon.create/2`, `apply_promotion_code/2`, `comp_subscription/2` (BILL-14/27) | context | CRUD | `subscription_actions.ex` (`subscribe/3`) + `coupon.ex` schema | exact (pattern cocktail) |
| `accrue/lib/accrue/billing/subscription_schedule_actions.ex` (NEW) (BILL-16) | context | CRUD | `subscription_actions.ex` (`subscribe/3`) | exact |
| `accrue/lib/accrue/checkout.ex` (NEW) — `Accrue.Checkout` context | context | CRUD + reconcile | `/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex` (facade) + `subscription_actions.ex` | role-match (no existing Checkout context) |
| `accrue/lib/accrue/checkout/session.ex` (NEW) — schema + create/retrieve | schema + context | CRUD | `subscription.ex` + `subscription_actions.ex` | role-match |
| `accrue/lib/accrue/checkout/line_item.ex` (NEW) — helper module | utility | transform | `/Users/jon/projects/accrue/accrue/lib/accrue/billing/metadata.ex` | role-match (tiny stateless helper) |
| `accrue/lib/accrue/billing_portal.ex` (NEW) + `billing_portal/session.ex` (NEW) | context + struct | request-response | `subscription_actions.ex` (tiny commit-then-Stripe path) | role-match |

### New Oban workers

| File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/lib/accrue/billing/meter_events/reconciler_job.ex` (NEW) | worker (cron) | batch reconcile | `/Users/jon/projects/accrue/accrue/lib/accrue/jobs/detect_expiring_cards.ex` | exact |
| `accrue/lib/accrue/billing/dunning/sweeper_job.ex` (NEW) | worker (cron) | batch reconcile | `accrue/lib/accrue/jobs/detect_expiring_cards.ex` + `accrue/lib/accrue/webhook/pruner.ex` | exact |
| `accrue/lib/accrue/webhooks/pruner.ex` — already exists at `accrue/lib/accrue/webhook/pruner.ex` | worker (cron) | delete-by-retention | **self** (finalize shape per D4-04) | exact (in-file extension) |

### New webhook handlers

| File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/lib/accrue/webhook/default_handler.ex` — add `customer.subscription.paused` / `.resumed` clauses | handler clause | event-driven | **self** — `reduce_subscription/4` lines 172–197 | exact (in-file extension; the `paused`/`resumed` atoms are already whitelisted in the dispatch guard line 138) |
| Same file — add `subscription_schedule.*` clauses | handler clause | event-driven | `reduce_subscription/4` lines 172–231 | exact |
| Same file — add `checkout.session.completed` | handler clause | event-driven | `reduce_invoice/4` lines 285–306 | exact |
| Same file — add `invoice.payment_failed` dunning column update (write `past_due_since`) | handler clause | event-driven | `reduce_invoice/4` + `reduce_subscription` force path | exact |
| Same file — add `customer.subscription.updated` terminal-action telemetry (D4-02) | handler clause | event-driven | **self** — `reduce_subscription/4` | exact |

### New webhook DLQ surface

| File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/lib/accrue/webhooks/dlq.ex` (NEW) — library core (`requeue/1`, `requeue_where/2`, `list/2`, `count/1`, `prune/1`) | context | CRUD + Oban.insert | `subscription_actions.ex` (Repo.transact + Events.record) + `webhook/pruner.ex` | role-match |
| `accrue/lib/mix/tasks/accrue.webhooks.replay.ex` (NEW) | mix task | CLI wrapper | **no in-project analog** — reference `Ecto.Migrator`/`mix ecto.migrate` | none |
| `accrue/lib/mix/tasks/accrue.webhooks.prune.ex` (NEW) | mix task | CLI wrapper | **no in-project analog** | none |

### Events query API + upcasters

| File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/lib/accrue/events.ex` — add `timeline_for/2`, `state_as_of/3`, `bucket_by/3` | context (read) | query | **self** — existing `record/1`/`record_multi/3` shape | exact (in-file extension) |
| `accrue/lib/accrue/events/upcaster_registry.ex` (NEW) | registry module | transform | `/Users/jon/projects/accrue/accrue/lib/accrue/events/upcaster.ex` (behaviour, 28 lines) | role-match (extends the scaffold) |
| `accrue/lib/accrue/events/upcasters/v1_to_v2.ex` (example stub) | upcaster impl | transform | `accrue/lib/accrue/events/upcaster.ex` behaviour contract | exact |

### Webhook plug: multi-endpoint (WH-13)

| File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/lib/accrue/webhook/plug.ex` — extend for endpoint-keyed secret lookup | plug | request-response | **self** — existing Phase 2 plug | exact (in-file extension) |
| `accrue/lib/accrue/config.ex` — add `:webhook_endpoints`, `:dunning`, DLQ keys | config | N/A | **self** (NimbleOptions schema) lines 1–120 | exact |

### Ops telemetry (OBS-03/04/05)

| File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/lib/accrue/telemetry/ops.ex` (NEW) | telemetry helper | event-driven | `/Users/jon/projects/accrue/accrue/lib/accrue/telemetry.ex` | role-match |
| `accrue/lib/accrue/telemetry/metrics.ex` (NEW, optional) | telemetry helper | N/A | same | role-match |
| `accrue/guides/telemetry.md` (NEW) | docs | N/A | — | n/a |

### Processor behaviour + Fake extensions

| File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/lib/accrue/processor.ex` — add `report_meter_event/1`, `checkout_session_create/2`, `portal_session_create/2`, `subscription_schedule_*/n` callbacks | behaviour | N/A | **self** lines 77–100 | exact (append callbacks) |
| `accrue/lib/accrue/processor/stripe.ex` — implementations delegating to `LatticeStripe.*` | behaviour impl | request-response | **self** (existing clauses) | exact |
| `accrue/lib/accrue/processor/fake.ex` — add `report_meter_event/1`, `checkout_session_create/2`, `portal_session_create/2`, `subscription_update/2` (sweeper), `subscription_schedule_*/n` | test adapter | in-process GenServer | **self** (existing 1355-line Fake) | exact |
| `accrue/test/support/stripe_fixtures.ex` — add `meter_event_created/1`, `checkout_session_completed/1`, `billing_portal_session/1`, `subscription_schedule_*/1` | fixture helper | N/A | **self** — `subscription_created/1` (lines 16–57) | exact |

### Database migrations (new + alter)

| File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `accrue/priv/repo/migrations/NNNN_create_accrue_meter_events.exs` | migration | N/A | Phase 3 migrations for `accrue_coupons` / `accrue_invoice_coupons` | exact |
| `accrue/priv/repo/migrations/NNNN_create_accrue_subscription_schedules.exs` | migration | N/A | same | exact |
| `accrue/priv/repo/migrations/NNNN_create_accrue_promotion_codes.exs` | migration | N/A | same | exact |
| `accrue/priv/repo/migrations/NNNN_add_dunning_and_pause_columns_to_subscriptions.exs` | migration (alter) | N/A | Phase 3 alter migrations | exact |
| `accrue/priv/repo/migrations/NNNN_add_discount_columns_to_invoices.exs` | migration (alter) | N/A | same | exact |
| `accrue/priv/repo/migrations/NNNN_add_events_type_index.exs` (for `bucket_by/3`) | migration (index) | N/A | Phase 1 EVT-02 composite index | exact |

---

## Pattern Assignments

### 1. `Accrue.Billing.MeterEventActions.report_usage/3` — commit-then-Stripe outbox

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex`

**Imports block** (lines 16–31):
```elixir
require Logger

import Ecto.Query, only: [from: 2]

alias Accrue.Actor
alias Accrue.Billing.Customer
alias Accrue.Billing.IntentResult
alias Accrue.Billing.Subscription
alias Accrue.Events
alias Accrue.Processor
alias Accrue.Processor.Idempotency
alias Accrue.Repo
```

**Core pattern — `Repo.transact` + commit-then-Stripe + `Events.record` inside the with-chain** (`subscribe/3`, lines 86–102):
```elixir
result =
  Repo.transact(fn ->
    with {:ok, stripe_sub} <-
           Processor.__impl__().create_subscription(
             stripe_params,
             [idempotency_key: idem_key] ++ sanitize_opts(opts)
           ),
         {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
         {:ok, sub} <- insert_subscription(customer.id, attrs),
         {:ok, _items} <- upsert_items(sub, stripe_sub),
         {:ok, _} <- record_event("subscription.created", sub, %{price_id: price_id}) do
      sub = Repo.preload(sub, :subscription_items, force: true)
      {:ok, sub}
    end
  end)
```

**Note for planner:** D4-03 requires the Stripe HTTP call *outside* the `Repo.transact/2` (not inside, like `subscribe/3` does today). The shape for `report_usage/3` inverts the order:
1. `Repo.transact` → insert `%MeterEvent{stripe_status: "pending"}` + `Events.record_multi(:meter_event_reported)` → commit.
2. Outside txn: call `Processor.__impl__().report_meter_event(row)`.
3. Update row with `"reported"` or `"failed"` (non-transactional `Repo.update`).

**Idempotency key derivation** (analog lines 71, 178, 311 — `Idempotency.key/3` + `Actor.current_operation_id!()`):
```elixir
op_id = resolve_operation_id(opts)
idem_key = Idempotency.key(:create_subscription, customer.id, op_id)
```
For meter events use D4-03 formula: `"accrue_mev_#{op_id}_#{event_name}_#{:erlang.phash2(...)}"`.

**Dual bang/tuple pattern** (analog lines 57–66):
```elixir
@spec subscribe!(term(), term(), keyword()) :: Subscription.t()
def subscribe!(billable, price_spec, opts \\ []) do
  case subscribe(billable, price_spec, opts) do
    {:ok, %Subscription{} = sub} -> sub
    {:ok, :requires_action, pi} -> raise Accrue.ActionRequiredError, payment_intent: pi
    {:error, err} when is_exception(err) -> raise err
    {:error, other} -> raise "subscribe!/3 failed: #{inspect(other)}"
  end
end
```
`report_usage!/3` is simpler — drop the `:requires_action` clause (D4-03: "returns plain `{:ok, _}` / `{:error, _}` — does NOT use `intent_result/1`").

**NimbleOptions schema pattern** (analog lines 136–161, `@swap_schema`):
```elixir
@swap_schema [
  proration: [type: {:in, [:create_prorations, :none, :always_invoice]}, required: true],
  proration_date: [type: :any, default: nil],
  operation_id: [type: {:or, [:string, nil]}, default: nil],
  ...
]
```
`report_usage/3` uses the same shape for `value`, `timestamp`, `identifier`, `operation_id`.

**Record event helper** (analog lines 729–736):
```elixir
defp record_event(type, %Subscription{} = sub, data) when is_binary(type) do
  Events.record(%{
    type: type,
    subject_type: "Subscription",
    subject_id: sub.id,
    data: data
  })
end
```

---

### 2. `Accrue.Billing.MeterEvent` schema — thin passthrough projection

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/coupon.ex` (full 61 lines)

**Schema pattern** (analog lines 17–39):
```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id

schema "accrue_coupons" do
  field :processor, :string
  field :processor_id, :string
  ...
  field :metadata, :map, default: %{}
  field :data, :map, default: %{}
  field :lock_version, :integer, default: 1

  timestamps(type: :utc_datetime_usec)
end
```

**Changeset** (analog lines 48–60):
```elixir
@cast_fields ~w[processor processor_id ...]a
@required_fields ~w[processor]a

def changeset(coupon_or_changeset, attrs \\ %{}) do
  coupon_or_changeset
  |> cast(attrs, @cast_fields)
  |> validate_required(@required_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
end
```

Apply verbatim to `MeterEvent`, `PromotionCode`, `SubscriptionSchedule` — with the D4-03 `accrue_meter_events` column list + unique index on `:identifier`.

---

### 3. `Accrue.Billing.SubscriptionSchedule` — dual changeset (user + webhook-force path)

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice.ex` (full 150 lines)

**Dual-changeset D3-17 pattern** (analog lines 99–128):
```elixir
@doc "User-path changeset with transition validation."
def changeset(invoice_or_changeset, attrs \\ %{}) do
  invoice_or_changeset
  |> cast(attrs, @cast_fields)
  |> validate_required(@required_fields)
  |> Metadata.validate_metadata(:metadata)
  |> validate_transition()
  |> optimistic_lock(:lock_version)
  |> foreign_key_constraint(:customer_id)
  |> foreign_key_constraint(:subscription_id)
end

@doc "Webhook-path changeset — Stripe is canonical, transition bypassed."
def force_status_changeset(invoice_or_changeset, attrs \\ %{}) do
  invoice_or_changeset
  |> cast(attrs, @cast_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
  |> foreign_key_constraint(:customer_id)
  |> foreign_key_constraint(:subscription_id)
end
```

Also reuse for the `past_due_since` / `dunning_sweep_attempted_at` columns on `Subscription` — these land via `force_status_changeset/2` inside `Default Handler`'s `reduce_subscription` path.

---

### 4. `Accrue.Webhook.DefaultHandler` extension — `paused`, `resumed`, `subscription_schedule.*`, `checkout.session.completed`

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex`

**Dispatch clause shape** (lines 137–165):
```elixir
defp dispatch("customer.subscription." <> action, evt_id, evt_ts, obj)
     when action in ~w(created updated trial_will_end deleted paused resumed) do
  reduce_subscription(action, evt_id, evt_ts, obj)
end

defp dispatch("invoice." <> action, evt_id, evt_ts, obj)
     when action in ~w(created finalized paid payment_failed voided marked_uncollectible sent) do
  reduce_invoice(action, evt_id, evt_ts, obj)
end
```
**Note:** `paused` and `resumed` are **already in the whitelist** on line 138 — Phase 4 work is wiring the downstream reducer, not extending the dispatch guard. For schedules and checkout, add:
```elixir
defp dispatch("subscription_schedule." <> action, evt_id, evt_ts, obj)
     when action in ~w(created updated released completed canceled expiring) do
  reduce_subscription_schedule(action, evt_id, evt_ts, obj)
end

defp dispatch("checkout.session." <> action, evt_id, evt_ts, obj)
     when action in ~w(completed expired async_payment_succeeded async_payment_failed) do
  reduce_checkout_session(action, evt_id, evt_ts, obj)
end
```

**Reducer shape** (analog lines 172–231, `reduce_subscription/4` + `upsert_subscription/3`):
```elixir
defp reduce_subscription(action, evt_id, evt_ts, obj) do
  stripe_id = get(obj, :id)

  reduce_row(:subscription, stripe_id, evt_ts, evt_id, fn row ->
    with {:ok, canonical} <- Processor.__impl__().fetch(:subscription, stripe_id),
         {:ok, attrs} <- SubscriptionProjection.decompose(canonical),
         attrs <- stamp_watermark(attrs, evt_ts, evt_id),
         {:ok, upsert_result} <- upsert_subscription(row, canonical, attrs) do
      case upsert_result do
        :deferred -> {:ok, :deferred}
        %Subscription{} = updated ->
          with {:ok, _} <- upsert_subscription_items(updated, canonical),
               {:ok, _} <- record_event(subscription_event_type(action), "Subscription", updated.id, evt_id) do
            {:ok, updated}
          end
      end
    end
  end)
end
```

**Orphan handling via `:deferred`** (lines 203–225) — required for any webhook-first-for-unknown-customer path (checkout.session.completed + schedule both need this).

**D4-02 terminal-action telemetry** — inside the existing subscription handler, add an emit between the with-chain successful upsert and the `record_event` call:
```elixir
# Inside reduce_subscription before record_event:
if row && row.status == :past_due and updated.status in [:unpaid, :canceled] do
  source = dunning_source(row.dunning_sweep_attempted_at)
  :telemetry.execute(
    [:accrue, :ops, :dunning_exhaustion],
    %{count: 1},
    %{subscription_id: updated.id, source: source}
  )
end
```

---

### 5. `Accrue.Billing.Dunning.SweeperJob` + `Accrue.Billing.MeterEvents.ReconcilerJob` — Oban cron workers

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/jobs/detect_expiring_cards.ex` (full 110 lines)

**Worker shape** (analog lines 25–57):
```elixir
use Oban.Worker, queue: :accrue_scheduled, max_attempts: 3

import Ecto.Query

alias Accrue.{Clock, Config, Events, Repo}
alias Accrue.Billing.{Customer, PaymentMethod}

@impl Oban.Worker
def perform(%Oban.Job{} = job) do
  Accrue.Oban.Middleware.put(job)
  scan()
end

def perform(_other), do: scan()

def scan do
  thresholds = Config.get!(:expiring_card_thresholds)
  now = Clock.utc_now()
  query = from p in PaymentMethod, where: not is_nil(p.exp_month) and not is_nil(p.exp_year)
  pms = Repo.all(query)
  for pm <- pms, threshold <- thresholds, do: maybe_emit(pm, threshold, now)
  :ok
end
```

**Dedup via `accrue_events` query** (lines 90–103) — the Sweeper uses `dunning_sweep_attempted_at IS NULL` column instead, but same pattern:
```elixir
defp already_warned?(pm_id, threshold) do
  one_year_ago = DateTime.add(Clock.utc_now(), -365 * 86_400, :second)

  query =
    from e in "accrue_events",
      where:
        e.subject_id == ^pm_id and
          e.type == "card.expiring_soon" and
          fragment("(?->>'threshold')::int = ?", e.data, ^threshold) and
          e.inserted_at > ^one_year_ago,
      select: count()

  Repo.one(query) > 0
end
```

**For the SweeperJob (D4-02):** queue is `:accrue_dunning` (new), max_attempts 3, scans `Subscription` where `status = :past_due AND past_due_since < now() - grace_days AND dunning_sweep_attempted_at IS NULL`, calls `Processor.update_subscription(id, %{status: "unpaid"})`, stamps `dunning_sweep_attempted_at`, records `accrue_events` row `type: "dunning.terminal_action_requested"`. Does NOT fire telemetry (that happens in the webhook handler when Stripe's webhook flips status — see Pattern #4).

**For the ReconcilerJob (D4-03):** queue is `:accrue_meters` (new), every minute, LIMIT 1000, filters `stripe_status = "pending" AND inserted_at < now() - '60 seconds'`, replays Stripe call, updates row.

---

### 6. `Accrue.Webhook.Pruner` — retention sweeper (existing; finalize per D4-04)

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/pruner.ex` (full 58 lines)

```elixir
use Oban.Worker, queue: :accrue_maintenance

@impl Oban.Worker
def perform(_job) do
  repo = Accrue.Repo.repo()
  succeeded_days = Accrue.Config.succeeded_retention_days()
  dead_days = Accrue.Config.dead_retention_days()

  unless succeeded_days == :infinity do
    cutoff = DateTime.utc_now() |> DateTime.add(-succeeded_days * 86_400, :second)
    from(w in WebhookEvent, where: w.status == :succeeded and w.inserted_at < ^cutoff)
    |> repo.delete_all()
  end

  unless dead_days == :infinity do
    cutoff = DateTime.utc_now() |> DateTime.add(-dead_days * 86_400, :second)
    from(w in WebhookEvent, where: w.status == :dead and w.inserted_at < ^cutoff)
    |> repo.delete_all()
  end

  :ok
end
```
**Phase 4 change:** wrap the two `delete_all` calls so the deleted counts feed `:telemetry.execute([:accrue, :ops, :webhook_dlq, :prune], %{dead_deleted: ..., succeeded_deleted: ...}, ...)` per D4-04, and delegate the actual deletion to `Accrue.Webhooks.DLQ.prune/1` / `prune_succeeded/1` so the Mix task can call the same function.

---

### 7. `Accrue.Webhooks.DLQ` — library core for replay/prune/list

**Analog mix:**
- Repo.transact + Events.record pattern: `subscription_actions.ex` `subscribe/3`
- Oban insert pattern: `accrue/lib/accrue/webhook/dispatch_worker.ex`
- Retention sweep pattern: `accrue/lib/accrue/webhook/pruner.ex`

**`requeue/1` concrete shape** (composed from analogs):
```elixir
@spec requeue(Ecto.UUID.t()) :: {:ok, WebhookEvent.t()} | {:error, Accrue.Error.t()}
def requeue(id) when is_binary(id) do
  Repo.transact(fn ->
    with {:ok, row} <- fetch_replayable(id),
         {:ok, updated} <-
           row
           |> WebhookEvent.status_changeset(:received)
           |> Repo.update(),
         {:ok, _job} <-
           Oban.insert(
             Accrue.Webhook.DispatchWorker.new(%{"webhook_event_id" => updated.id})
           ),
         {:ok, _evt} <-
           Events.record(%{
             type: "webhook.replay_requested",
             subject_type: "WebhookEvent",
             subject_id: updated.id,
             data: %{original_processor_event_id: row.processor_event_id},
             idempotency_key: "replay:" <> row.processor_event_id
           }) do
      {:ok, updated}
    end
  end)
end

defp fetch_replayable(id) do
  case Repo.get(WebhookEvent, id) do
    nil -> {:error, :not_found}
    %WebhookEvent{status: :replayed} -> {:error, :already_replayed}
    %WebhookEvent{status: s} when s in [:dead, :failed] = row -> {:ok, row}
    %WebhookEvent{} -> {:error, :not_dead_lettered}
  end
end
```

**`Oban.insert` of dispatch worker** — see `accrue/lib/accrue/webhook/dispatch_worker.ex` line 27 (`use Oban.Worker, queue: :accrue_webhooks, max_attempts: 25`). Args map keyed by `"webhook_event_id"` — always use string keys when enqueuing Oban jobs (analog lines 36–40).

**`requeue_where/2` bulk shape** — use `Repo.stream` + `Stream.chunk_every(batch_size)` inside `Repo.transact`; `dry_run: true` returns the count without mutation; `:dlq_replay_max_rows` cap + `force: true` bypass.

**`prune/1` shape** — take directly from `Webhook.Pruner.perform/1` (lines 42–54).

---

### 8. `Accrue.Webhooks.DLQ` dual bang/tuple API

**Analog:** `subscription_actions.ex` (the whole file — every public function follows this).

Template (lines 430–437):
```elixir
@spec cancel_at_period_end!(Subscription.t(), keyword()) :: Subscription.t()
def cancel_at_period_end!(sub, opts \\ []) do
  case cancel_at_period_end(sub, opts) do
    {:ok, s} -> s
    {:error, err} when is_exception(err) -> raise err
    {:error, other} -> raise "cancel_at_period_end!/2 failed: #{inspect(other)}"
  end
end
```

Apply verbatim to `requeue!/1`, `requeue_where!/2`.

---

### 9. `Accrue.Events` read API extension — `timeline_for/2`, `state_as_of/3`, `bucket_by/3`

**Analog (same file):** `/Users/jon/projects/accrue/accrue/lib/accrue/events.ex`

**`record/1` query helper shape** (lines 192–199):
```elixir
defp fetch_by_idempotency_key(key) do
  query = from e in Event, where: e.idempotency_key == ^key, limit: 1
  case Accrue.Repo.one(query) do
    nil -> {:error, :idempotency_lookup_failed}
    event -> {:ok, event}
  end
end
```

**For `bucket_by/3`**, use raw `fragment/2` for `date_trunc` (precedent in `jobs/detect_expiring_cards.ex` line 98):
```elixir
fragment("(?->>'threshold')::int = ?", e.data, ^threshold)
```
Adapt to:
```elixir
from e in Event,
  where: e.subject_type == ^subject_type and e.inserted_at >= ^since,
  group_by: fragment("date_trunc(?, ?)", ^bucket_str, e.inserted_at),
  select: {fragment("date_trunc(?, ?)", ^bucket_str, e.inserted_at), count(e.id)}
```

---

### 10. `Accrue.Events.UpcasterRegistry` + upcaster impls

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/events/upcaster.ex` (full 28 lines)

**Behaviour contract** (lines 27–28):
```elixir
@callback upcast(map()) :: {:ok, map()} | {:error, term()}
```

**Registry shape (new):**
```elixir
defmodule Accrue.Events.UpcasterRegistry do
  @chains %{
    "subscription.created" => %{1 => [], 2 => [Accrue.Events.Upcasters.V1ToV2]},
    ...
  }

  @spec chain(String.t(), pos_integer(), pos_integer()) ::
          {:ok, [module()]} | {:error, :unknown_schema_version}
  def chain(type, from_version, to_version) do
    ...
  end
end
```
Read-path dispatch inside `Accrue.Events.Schemas.for/1` (already exists per research — Phase 4 just wires the chain).

---

### 11. `Accrue.Processor.Fake` extensions

**Analog (self):** `/Users/jon/projects/accrue/accrue/lib/accrue/processor/fake.ex` (1355 lines, deterministic id prefixes, GenServer + State module).

**ID prefix pattern** (lines 70–79):
```elixir
@customer_prefix "cus_fake_"
@subscription_prefix "sub_fake_"
@invoice_prefix "in_fake_"
@payment_intent_prefix "pi_fake_"
...
```
Phase 4 additions: `@meter_event_prefix "mev_fake_"`, `@checkout_session_prefix "cs_fake_"`, `@billing_portal_session_prefix "bps_fake_"`, `@subscription_schedule_prefix "sub_sched_fake_"`, `@promotion_code_prefix "promo_fake_"`.

**Scripted response hook** — the existing `scripted_response/2` must extend to cover the new ops so tests can simulate `report_meter_event` failures (D4-03's `stripe_status: "failed"` path) without mocking.

**Synthesize event path** — D4-02 relies on `Accrue.Processor.Fake.subscription_update/2` mutating state AND enqueuing a synthetic `customer.subscription.updated` event through the same webhook plug path. The existing `transition/3` (lines 30–31 docstring mentions "optionally synthesizing `customer.subscription.updated` webhooks in-process") is the template.

---

### 12. `Accrue.Test.StripeFixtures` extensions

**Analog (self):** `/Users/jon/projects/accrue/accrue/test/support/stripe_fixtures.ex` (`subscription_created/1` lines 16–57)

**Fixture shape (string-keyed, Unix seconds, `"object"` discriminator, `deep_merge(base, overrides)`):**
```elixir
def subscription_created(overrides \\ %{}) do
  now = DateTime.utc_now()
  customer_id = "cus_test_" <> rand()
  sub_id = "sub_test_" <> rand()

  base = %{
    "id" => sub_id,
    "object" => "subscription",
    "customer" => customer_id,
    "status" => "trialing",
    ...
  }

  deep_merge(base, overrides)
end
```

Phase 4 adds: `meter_event_created/1`, `meter_event_error_report_triggered/1`, `checkout_session_completed/1`, `billing_portal_session/1`, `subscription_schedule_created/1`, `subscription_schedule_updated/1`, `subscription_schedule_released/1`, `promotion_code_created/1`, `customer_subscription_paused/1`, `customer_subscription_resumed/1`.

---

### 13. `Accrue.Config` NimbleOptions extension

**Analog (self):** `/Users/jon/projects/accrue/accrue/lib/accrue/config.ex` (lines 1–120)

**Schema entry shape** (lines 9–18):
```elixir
processor: [
  type: :atom,
  default: Accrue.Processor.Fake,
  doc: "Processor adapter implementing `Accrue.Processor` behaviour."
],
```

**Phase 4 additions (append to `@schema`):**
```elixir
dunning: [
  type: :keyword_list,
  default: [mode: :stripe_smart_retries, grace_days: 14, terminal_action: :unpaid],
  doc: "Dunning grace-period overlay config (D4-02)."
],
webhook_endpoints: [
  type: :keyword_list,
  default: [],
  doc: "Map of endpoint name to [secret:, mode:] for multi-endpoint WH-13."
],
dead_retention_days: [type: {:or, [:pos_integer, {:in, [:infinity]}]}, default: 90, ...],
succeeded_retention_days: [type: {:or, [:pos_integer, {:in, [:infinity]}]}, default: 14, ...],
dlq_replay_batch_size: [type: :pos_integer, default: 100, ...],
dlq_replay_stagger_ms: [type: :non_neg_integer, default: 1_000, ...],
dlq_replay_max_rows: [type: :pos_integer, default: 10_000, ...]
```

---

### 14. `Accrue.Checkout` + `Accrue.BillingPortal` contexts

**Analog:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex` (mixed: commit-then-Stripe + dual bang/tuple + NimbleOptions)

These contexts do NOT mutate local state on create (Stripe hosts the flow); they only record the session row + call `Processor.checkout_session_create/2` / `portal_session_create/2`. The `reconcile/1` path is the mirror of `subscribe/3`'s `Repo.transact` — accepts a `checkout_session_id`, calls `Processor.fetch(:checkout_session, id)`, projects into local rows via `force_status_changeset/2`.

**Inspect PII mask** — `%BillingPortal.Session{}` must mask the `url` field in its `Inspect` impl (research line 65: "URL masked in Inspect — short-lived bearer credential"). Precedent: `accrue/lib/accrue/webhook/webhook_event.ex` `raw_body` Inspect exclusion.

---

## Shared Patterns

### A. `Repo.transact` + commit-then-Stripe atomicity (D2-09, D3-18)

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex` lines 86–102

**Apply to:** every new write-surface context function that touches both local DB state and Stripe — BUT: for `report_usage/3` (D4-03) the Stripe call lives OUTSIDE `Repo.transact` (outbox pattern, step 2 of 3). This is the key deviation: all prior Phase 3 actions call Stripe *inside* transact; Phase 4 `report_usage/3` flips this because the row MUST be durable before the Stripe call.

### B. `Events.record/1` + `Events.record_multi/2` (EVT-04)

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/events.ex` lines 80–127

**Apply to:** every write path. Use `record/1` inside `Repo.transact/2` closures, `record_multi/3` inside `Ecto.Multi` pipelines. Pass `idempotency_key:` when replays must collapse (notably DLQ `requeue/1`).

### C. Dual bang/tuple API (D-05)

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex` (every public function)

**Apply to:** every new public function in `Accrue.Billing.*`, `Accrue.Checkout.*`, `Accrue.BillingPortal.*`, `Accrue.Webhooks.DLQ.*`.

### D. `force_status_changeset/2` on webhook path vs `changeset/2` on user path (D3-17)

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice.ex` lines 99–128

**Apply to:** any schema that has user-settable status transitions — in Phase 4 that's `SubscriptionSchedule`, and the new `past_due_since`/`dunning_sweep_attempted_at` columns on `Subscription` (use `force_status_changeset/2` from the webhook handler).

### E. NimbleOptions input validation

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex` lines 136–244 (`@swap_schema` + `validate_swap_opts!`)

**Apply to:** every context function that takes `opts :: keyword()` — including `report_usage/3`, `add_item/3`, `subscribe_via_schedule/3`, `Checkout.Session.create/2`, `BillingPortal.Session.create/2`, `DLQ.requeue_where/2`.

### F. Oban worker shape with `Accrue.Oban.Middleware.put(job)` for operation_id propagation

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/jobs/detect_expiring_cards.ex` lines 25, 32–38

**Apply to:** `MeterEvents.ReconcilerJob`, `Dunning.SweeperJob`, and the existing `Webhook.Pruner` (add the middleware call if missing).

### G. Telemetry namespace split — `[:accrue, :*]` firehose vs `[:accrue, :ops, :*]` ops-grade (OBS-03)

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/dispatch_worker.ex` line 85 (firehose), + research D4-02/D4-04 event names.

**Apply to:** all new telemetry emits — anything SRE-actionable goes under `:ops`, everything else stays in the firehose namespace. Fire inside the same `Repo.transact/2` as the state write (D4-02 coherence).

### H. Orphan `:deferred` tolerance for webhook-first-for-unknown-customer (CR-03)

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex` lines 203–225, 308–327, 401–428

**Apply to:** any new webhook reducer (subscription_schedule, checkout.session.completed) that may arrive before the parent customer row exists locally.

### I. String-keyed Stripe payload handling — `SubscriptionProjection.get/2` dual-key helper

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription.ex` lines 182–196 (`fetch_key/2`) + `default_handler.ex` lines 252–279 (price + price_id extraction)

**Apply to:** every new projection module (`MeterEventProjection`, `SubscriptionScheduleProjection`, `CheckoutSessionProjection`). Fake returns atom-keyed; Stripe returns string-keyed. Normalize at read time, never in the caller.

### J. Stringify-for-jsonb (`data` column hygiene)

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex` lines 719–727

```elixir
defp stringify(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
defp stringify(%{__struct__: _} = s), do: s |> Map.from_struct() |> stringify()
defp stringify(map) when is_map(map) do
  for {k, v} <- map, into: %{}, do: {to_string(k), stringify(v)}
end
defp stringify(list) when is_list(list), do: Enum.map(list, &stringify/1)
defp stringify(other), do: other
```

**Apply to:** any new projection writing Stripe payloads into the `data :map` column (per WR-11 guidance in commit `dfc2c66`).

### K. `WR-09` — never use bang variants of `Repo.insert!/update!` inside a `Repo.transact` with-chain

**Source:** `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex` lines 676–714 (`upsert_items/2` using `reduce_while` + non-bang)

**Apply to:** every list-of-children upsert in Phase 4 (promotion codes, schedule phases, checkout line items). Bang variants raise `Ecto.InvalidChangesetError` which *escapes* the enclosing with-chain and rolls back transparently — non-bang + `reduce_while` is the locked idiom.

---

## No Analog Found

| File | Role | Reason |
|---|---|---|
| `accrue/lib/mix/tasks/accrue.webhooks.replay.ex` | Mix task | No in-project Mix task analog. Reference `Ecto.Migrator` + `mix ecto.migrate` from the Ecto project (see canonical_refs in CONTEXT.md). Task parses argv (`--since`, `--type`, `--dry-run`, `--all-dead`, `--yes`), calls `Accrue.Webhooks.DLQ.requeue_where/2`, prints progress. Follow `mix ecto.migrate` confirmation prompt precedent for nuclear options (>10 rows triggers `y/N` unless `--yes`). |
| `accrue/lib/mix/tasks/accrue.webhooks.prune.ex` | Mix task | Same — thin wrapper calling `Accrue.Webhooks.DLQ.prune/1` and `.prune_succeeded/1`. Should delegate to `Accrue.Webhook.Pruner.perform(%Oban.Job{})` to ensure identical code path with cron execution. |

For both Mix tasks the planner should reference the Hex `Mix.Task` docs: `use Mix.Task`, `@shortdoc`, `@moduledoc`, `def run(args)`. Boot the app via `Mix.Task.run("app.start")` before calling any `Accrue.Repo` function.

---

## Metadata

**Analog search scope:**
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing/`
- `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/`
- `/Users/jon/projects/accrue/accrue/lib/accrue/events/` + `events.ex`
- `/Users/jon/projects/accrue/accrue/lib/accrue/processor/` + `processor.ex`
- `/Users/jon/projects/accrue/accrue/lib/accrue/jobs/`
- `/Users/jon/projects/accrue/accrue/lib/accrue/config.ex`
- `/Users/jon/projects/accrue/accrue/test/support/`

**Files scanned in detail:**
- `billing/subscription.ex` (197 lines — schema + predicates)
- `billing/subscription_actions.ex` (812 lines — Repo.transact shape, dual API, NimbleOptions, commit-then-Stripe, stringify, upsert_items reduce_while)
- `billing/invoice.ex` (150 lines — dual changeset D3-17)
- `billing/coupon.ex` (61 lines — thin passthrough schema)
- `billing/query.ex` (69 lines — composable predicates)
- `webhook/default_handler.ex` (first 500 lines — reducer shape, `:deferred`, string-key extraction)
- `webhook/dispatch_worker.ex` (107 lines — Oban worker, status lifecycle, telemetry)
- `webhook/pruner.ex` (58 lines — cron retention sweep)
- `events.ex` (220 lines — `record/1`, `record_multi/3`, idempotency, Postgrex error translation)
- `events/upcaster.ex` (28 lines — behaviour contract)
- `jobs/detect_expiring_cards.ex` (110 lines — Oban cron + event-table dedup)
- `processor.ex` (first 100 lines — behaviour callbacks, `intent_result` type)
- `processor/fake.ex` (first 120 lines — ID prefixes, GenServer shape)
- `test/support/stripe_fixtures.ex` (first 60 lines — `deep_merge(base, overrides)` shape)
- `config.ex` (first 120 lines — NimbleOptions schema)

**Pattern extraction date:** 2026-04-14
