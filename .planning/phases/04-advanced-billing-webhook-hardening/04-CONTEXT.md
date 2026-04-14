# Phase 4: Advanced Billing + Webhook Hardening - Context

**Gathered:** 2026-04-14
**Status:** Ready for research & planning

<domain>
## Phase Boundary

Phase 4 fills out the long tail of subscription billing on top of Phase 3's lifecycle primitives and Phase 2's webhook plumbing, then hardens the webhook pipeline:

- **Advanced billing:** metered billing (BILL-13) via `Accrue.Billing.report_usage/3`, multi-item subscriptions (BILL-12), free/comped subscriptions (BILL-14), dunning/grace-period handling driving `past_due → unpaid` (BILL-15), subscription schedules for multi-phase intro pricing (BILL-16), pause/resume with `pause_behavior` (BILL-11), coupons + promotion codes (BILL-27) with discount application at sub/invoice/checkout levels (BILL-28).
- **Checkout + Customer Portal:** `Accrue.Checkout.Session` create/retrieve with sane defaults (CHKT-01), embedded + hosted modes (CHKT-02), line-item helpers (CHKT-03), `Accrue.BillingPortal.Session` (CHKT-04), portal configuration helper with "cancel-without-dunning" defenses (CHKT-05), success/cancel URL routing with state reconciliation (CHKT-06).
- **Webhook hardening:** DLQ replay tooling (WH-08), multi-endpoint webhook support with Connect-variant secret (WH-13), `Accrue.Events.Upcaster` pattern for schema evolution (EVT-05), query API — `timeline_for/2`, `state_as_of/3`, `bucket_by/3` (EVT-06/EVT-10).
- **Ops observability:** high-signal ops event stream separated from the firehose (OBS-03), trace/span naming conventions guide (OBS-04), default `Telemetry.Metrics` recipe (OBS-05).

**Out of scope:** Stripe Connect (Phase 5), email/PDF (Phase 6), admin LiveView (Phase 7), install/polish (Phase 8), release (Phase 9). Phase 4 lives entirely in the `accrue/` package — no `accrue_admin/` code.

</domain>

<decisions>
## Implementation Decisions

### lattice_stripe gap strategy (BILL-13 + CHKT-02)

- **D4-01: The gap is already closed. Cut `lattice_stripe 1.1` now and consume it normally — zero in-tree Stripe shims.**
  - The Phase 4 roadmap note assumed `BillingMeter/MeterEvent` and `BillingPortal.Session` were missing from lattice_stripe 1.0. Research confirmed that the sibling `lattice_stripe` repo has **66 commits on `main` since the 2026-04-13 `v1.0.0` tag** implementing Phase 20 (Metering: `LatticeStripe.Billing.Meter`, `MeterEvent`, `MeterEventAdjustment`) and Phase 21 (`LatticeStripe.BillingPortal.Session` with FlowData guards). Code-complete, not yet tagged.
  - **Action:** In `lattice_stripe`, bump `@version` to `1.1.0`, regenerate CHANGELOG, let Release Please cut the release (or hand-tag `1.1.0-rc.1` if Accrue Phase 4 dev wants to start before Release Please runs).
  - **In Accrue Phase 4 dev:** consume via `{:lattice_stripe, path: "../lattice_stripe"}` so bugs found during integration become one-line fixes in the sibling repo. Flip to `{:lattice_stripe, "~> 1.1"}` before Phase 4 merges to `main`.
  - Bump the `CLAUDE.md` dep constraint from `~> 1.0` to `~> 1.1` and delete the stale "pending in 1.1 blocks BILL-11/CHKT-02" note.
  - **`BillingPortal.Configuration` is deferred to lattice_stripe 1.2 (dashboard-managed in the interim — standard Stripe practice, matches Pay + Cashier convention).** For CHKT-05, Accrue treats portal configuration as host-managed via the Stripe Dashboard, with `Accrue.BillingPortal.Session.create/2` accepting an optional `configuration: "bpc_..."` ID. Landing `Configuration` support when 1.2 ships is additive and slots into any Accrue 1.x patch — no breaking change.
  - **Rationale:** Same author owns both libs — the "upstream vs fork-in-tree" friction that justifies in-tree shims in Pay/Cashier-style libraries doesn't exist here. Cutting a release is `git tag` + `mix hex.publish`. Shipping `Accrue.Stripe.MeterEvent` thin modules would create two parallel call shapes, force `Accrue.Processor.Fake` to mirror both, and leave "temporary" bridge code that survives forever. Single shape = single Fake = single mental model. Principle of least surprise: a Phoenix dev reading Accrue source sees `LatticeStripe.*` for every Stripe call, full stop.
  - **Coherence:** satisfies D3-12 (`intent_result/1` processor callback stays a single union type); satisfies the Fake processor source-of-truth strategy; satisfies "ship complete v1.0 with no v0.x-to-v1.0.1 migration churn."

### Dunning retry policy (BILL-15)

- **D4-02: Hybrid — Stripe Smart Retries owns the retry *cadence*; Accrue owns a thin *grace-period overlay* that transitions `past_due → unpaid` (or `canceled`) by calling the Stripe API, so D2-29 canonicality holds.**
  - **Config surface** (`config :accrue, :dunning`, validated via `NimbleOptions`):
    ```elixir
    config :accrue, :dunning,
      mode: :stripe_smart_retries,   # :stripe_smart_retries | :disabled
      grace_days: 14,                 # extra days past Stripe's last retry
      terminal_action: :unpaid,       # :unpaid | :canceled
      telemetry_prefix: [:accrue, :ops]
    ```
  - **`Accrue.Billing.Dunning`** — pure policy module with `compute_terminal_action/2` given `%Subscription{}` + last `invoice.payment_failed.next_payment_attempt`. Property-testable with StreamData. No side effects.
  - **`Accrue.Billing.Dunning.SweeperJob`** (Oban cron, queue `:accrue_dunning`, cron `"*/15 * * * *"`):
    - Queries `subscriptions` where `status = :past_due AND past_due_since < now() - grace_days AND dunning_sweep_attempted_at IS NULL`.
    - For each: calls `LatticeStripe.Subscription.update(id, status: "unpaid")` (or cancel), stamps `dunning_sweep_attempted_at`, writes `accrue_events` row `type: "dunning.terminal_action_requested"`.
    - **Does NOT fire telemetry. Does NOT touch local `status`.** Stripe is canonical — Stripe's `customer.subscription.updated` webhook is what flips Accrue's row.
  - **`Accrue.Webhooks.Handlers.CustomerSubscriptionUpdated`** — add a status diff check: if `old_status == :past_due and new_status in [:unpaid, :canceled]`, emit `[:accrue, :ops, :dunning_exhaustion]` inside the same `Repo.transact/2` as `force_status_changeset/2`. Metadata includes `:source` (`:accrue_sweeper | :stripe_native | :manual`) derived from whether `dunning_sweep_attempted_at` was set within the last 5 minutes.
  - **Needed column:** add `past_due_since :utc_datetime_usec` and `dunning_sweep_attempted_at :utc_datetime_usec` to `accrue_subscriptions`. `past_due_since` is sourced from `invoice.payment_failed.next_payment_attempt` and bumped forward whenever Stripe schedules another retry — so Accrue's grace window is "N days after Stripe *stops* retrying," not "N days after first failure." Correctness hinges on this.
  - **Idempotency under replay:** telemetry fires in the same txn as the state write; webhook dedup via `accrue_webhook_events` unique index on `stripe_event_id` short-circuits before the handler body, so telemetry cannot double-fire.
  - **Fake processor story:** `Accrue.Processor.Fake.subscription_update/2` mutates the in-memory map and enqueues a synthetic `customer.subscription.updated` event through the same webhook plug path. Test becomes `advance_clock(15.days); Oban.drain_queue(:accrue_dunning); assert_receive {:telemetry, [:accrue, :ops, :dunning_exhaustion], _, _}`.
  - **Why not Accrue-driven (Option B)?** D2-29 says Stripe is canonical. Locally flipping a row to `:unpaid` while Stripe says `:past_due` means the next webhook refetch overwrites it. Hard constraint violated.
  - **Why not pure Stripe delegation (Option A)?** Stripe Smart Retries are dashboard-only, account-wide, capped at 8 attempts / 2 months. No per-deploy grace policy. Accrue's whole thesis is "complete production-grade billing on day one" — matching Pay/Cashier's delegation is necessary but insufficient.
  - **Coherence:** satisfies D2-29, D3-01 (Stripe's 8 statuses verbatim), D3-17 (`force_status_changeset/2` on webhook path). Oban community edition is sufficient — just needs a new `:accrue_dunning` queue and a cron plugin entry.

### Metered usage write path (BILL-13)

- **D4-03: Synchronous pass-through via `Accrue.Billing.report_usage/3` with a transactional-outbox audit table and a small reconciliation Oban worker. Defer buffering to v1.1 as an additive `report_usage_async/3`.**
  - **Signature:**
    ```elixir
    @spec report_usage(
            customer :: Accrue.Billing.Customer.t() | String.t(),
            event_name :: String.t(),
            opts :: keyword()
          ) :: {:ok, Accrue.Billing.MeterEvent.t()} | {:error, term()}

    # opts:
    #   :value      - non_neg_integer(), default 1
    #   :timestamp  - DateTime.t(), default DateTime.utc_now()
    #   :identifier - String.t(), default derived from operation_id + event_name + hash
    #   :payload    - map(), extra keys merged into Stripe payload (advanced)
    ```
    Mirrors Laravel Cashier's `reportUsage($quantity = 1, $timestamp = null)` shape — principle of least surprise for any Cashier-literate dev.
  - **Schema — `accrue_meter_events`** (audit ledger + implicit outbox, NOT a flush buffer):
    ```elixir
    create table(:accrue_meter_events, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :customer_id, references(:accrue_customers, type: :binary_id, on_delete: :nilify_all)
      add :stripe_customer_id, :string, null: false
      add :event_name, :string, null: false
      add :value, :bigint, null: false
      add :identifier, :string, null: false
      add :occurred_at, :utc_datetime_usec, null: false
      add :reported_at, :utc_datetime_usec  # set on Stripe 2xx
      add :stripe_status, :string, null: false, default: "pending"  # pending|reported|failed
      add :stripe_error, :map
      add :operation_id, :string
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:accrue_meter_events, [:identifier])
    create index(:accrue_meter_events, [:customer_id, :event_name, :occurred_at])
    create index(:accrue_meter_events, [:stripe_status], where: "stripe_status = 'failed'")
    ```
    Partial index on `failed` rows gives ops a free DLQ view without a second table.
  - **Control flow** (respects D2-09/D3-18 — commit DB first, then Stripe, then update row):
    1. `Repo.transact/2`: insert `%MeterEvent{stripe_status: "pending"}` + `Events.record_multi(:meter_event_reported)` — commit.
    2. Call `Accrue.Processor.report_meter_event(row)` (outside the txn).
    3. On success: update row `stripe_status: "reported", reported_at: now`.
    4. On Stripe error: update row `stripe_status: "failed", stripe_error: ...`, return `{:error, err}` to caller.
  - **Idempotency key derivation** (uses Phase 3's `operation_id` pdict):
    ```elixir
    defp derive_identifier(customer, event_name, value, ts) do
      op = Accrue.Context.operation_id() || "unscoped"
      hash = :erlang.phash2({customer.processor_id, event_name, value, DateTime.to_unix(ts, :microsecond)})
      "accrue_mev_#{op}_#{event_name}_#{hash}"
    end
    ```
    Unique index on `identifier` dedupes at the audit layer; Stripe's `identifier` field dedupes server-side. Double-safe replay.
  - **`Accrue.Billing.MeterEvents.ReconcilerJob`** (Oban cron, queue `:accrue_meters`, every minute, LIMIT 1000) — retries rows where `stripe_status = "pending" AND inserted_at < now() - '60 seconds'`. Closes the "committed the row but crashed before Stripe call" gap. This is the minimum viable outbox — converts "best effort" into "eventually consistent with bounded staleness," at ~40 LOC.
  - **Fake processor:** `Accrue.Processor.Fake.report_meter_event(row)` writes to an ETS table and returns a canned `{:ok, %MeterEvent{id: "mev_fake_#{row.identifier}"}}`. Test helper `Accrue.Processor.Fake.meter_events_for(customer)` returns rows.
  - **Returns plain `{:ok, _}` / `{:error, _}`** — does NOT use `intent_result/1` (per D3-07/D3-12; meter reporting is not SCA-capable).
  - **Why not Oban-buffered?** Stripe's own high-volume guidance is "aggregate client-side, flush via v2 MeterEventStream" — that's a host-app concern, not a library concern. Accrue can't guess the correct aggregation window for the host's business logic. Shipping a buffer forces a policy and creates a new silent-failure mode (flush worker stuck → usage loss → invoice bugs). Callers who need batching wrap `report_usage/3` in their own Oban job in ~20 lines; documented in the guide.
  - **Why not hybrid (dev sync, prod buffered)?** Two code paths, two test surfaces, violates least surprise.
  - **Escape hatch:** if v1.1 adds `report_usage_async/3` or a built-in buffer, it's purely additive. Zero breaking-change risk.
  - **Coherence:** respects D2-09/D3-18 txn atomicity (no HTTP inside `Repo.transact/2`); uses the Phase 3 `operation_id` pdict for deterministic keys; Fake processor has a trivial implementation; no coupling to webhook DLQ machinery.

### DLQ + replay UX surface (WH-08)

- **D4-04: Ship `Accrue.Webhooks.DLQ` as the library core with thin Mix task wrappers (`mix accrue.webhooks.replay` / `mix accrue.webhooks.prune`). Phase 7 `accrue_admin` LiveView and the Mix tasks both call into the same library module.**
  - **Structural necessity:** `Oban.retry_job/2` refuses `:discarded`/`:cancelled` states, and Accrue's DLQ'd events correspond to exactly those. So replay cannot delegate to Oban — it MUST insert a fresh job via `Oban.insert/2` with the event's `processor_event_id` as args. That means a dedicated DLQ module is structurally required; the only live question is whether to *also* ship Mix tasks, and the answer is yes (ops engineers SSH into prod at 3am and `iex -S mix` is hostile UX for one-shot requeue).
  - **Ecosystem precedent:** Library + thin Mix wrapper is the unanimous Elixir pattern — `Ecto.Migrator` + `mix ecto.migrate`, `Oban.Migration` + `mix oban.install`. Mix task is 5-20 lines that parse argv and call the library.
  - **`Accrue.Webhooks.DLQ` public API** (lives in `accrue`, zero LiveView dep):
    ```elixir
    @type filter :: [
      type: String.t() | [String.t()],
      since: DateTime.t(),
      until: DateTime.t(),
      livemode: boolean()
    ]

    @type replay_opts :: [
      batch_size: pos_integer(),     # default 100
      stagger_ms: non_neg_integer(), # default 1_000
      dry_run: boolean(),            # default false
      force: boolean()               # default false (bypass max-rows cap)
    ]

    @spec requeue(Ecto.UUID.t())                    :: {:ok, WebhookEvent.t()} | {:error, Accrue.Error.t()}
    @spec requeue!(Ecto.UUID.t())                   :: WebhookEvent.t()
    @spec requeue_where(filter(), replay_opts())    :: {:ok, %{requeued: non_neg_integer(), skipped: non_neg_integer()}} | {:error, term()}
    @spec requeue_where!(filter(), replay_opts())   :: %{requeued: non_neg_integer(), skipped: non_neg_integer()}
    @spec list(filter(), [limit: pos_integer(), offset: non_neg_integer()]) :: [WebhookEvent.t()]
    @spec count(filter())                            :: non_neg_integer()
    @spec prune(retention_days :: pos_integer() | :infinity) :: {:ok, non_neg_integer()}
    ```
    Dual bang/tuple API per Phase 3 D-05 convention.
  - **`requeue/1` implementation** (`Repo.transact/2`):
    1. Guard `status in [:dead, :failed]`. On `:replayed` return `{:error, :already_replayed}` (idempotent caller view).
    2. Update `status: :received`.
    3. `Oban.insert/2` the dispatch worker with `processor_event_id` in args.
    4. `Events.record_multi/2` with `actor: :replay, operation_id: <original_processor_event_id>` — audit trail distinguishes replay from original dispatch.
    5. Emit `[:accrue, :ops, :webhook_dlq, :replay]` span events.
  - **`requeue_where/2` bulk implementation:** `Repo.stream` inside `Repo.transact/2`, `Stream.chunk_every(batch_size)`, insert each chunk, `Process.sleep(stagger_ms)` between. `dry_run: true` returns the count without mutation — critical for ops safety. Hard cap: if the query matches more than `Accrue.Config.dlq_replay_max_rows` (default `10_000`) rows, return `{:error, :replay_too_large}` unless `force: true`.
  - **Replay-death-loop prevention:** if `Processor.fetch/1` in the dispatch worker returns `{:error, :not_found}` (Stripe object deleted), treat as terminal-skip — set status `:replayed`, log warning, do NOT re-dead-letter.
  - **Mix tasks:**
    - `mix accrue.webhooks.replay <event_id>` — single requeue.
    - `mix accrue.webhooks.replay --since 2026-04-01 --type invoice.payment_failed --dry-run` — bulk.
    - `mix accrue.webhooks.replay --all-dead` — nuclear option; prompts `y/N` confirmation when >10 rows unless `--yes` passed (follows `mix ecto.migrate` precedent).
    - `mix accrue.webhooks.prune` — manual prune trigger (cron handles scheduled).
  - **`Accrue.Webhooks.Pruner`** (already locked in Phase 2 D2-34, finalize shape here):
    ```elixir
    defmodule Accrue.Webhooks.Pruner do
      use Oban.Worker, queue: :accrue_maintenance, max_attempts: 3, unique: [period: 60 * 60]

      @impl Oban.Worker
      def perform(%Oban.Job{}) do
        {:ok, dead} = Accrue.Webhooks.DLQ.prune(Accrue.Config.fetch!(:dead_retention_days))
        {:ok, ok}   = Accrue.Webhooks.DLQ.prune_succeeded(Accrue.Config.fetch!(:succeeded_retention_days))
        :telemetry.execute(
          [:accrue, :ops, :webhook_dlq, :prune],
          %{dead_deleted: dead, succeeded_deleted: ok},
          %{}
        )
        :ok
      end
    end
    ```
    Host wires the cron entry (documented in install guide): `{Oban.Plugins.Cron, crontab: [{"17 3 * * *", Accrue.Webhooks.Pruner}]}`.
  - **Config keys** (extend `Accrue.Config`): `:dead_retention_days` (default `90`, accepts `:infinity`), `:succeeded_retention_days` (default `14`), `:dlq_replay_batch_size` (default `100`), `:dlq_replay_stagger_ms` (default `1_000`), `:dlq_replay_max_rows` (default `10_000`).
  - **Telemetry event set** (extending the Phase 2 `:webhook_dlq` namespace):
    ```
    [:accrue, :ops, :webhook_dlq, :dead_lettered]
      measurements: %{count: 1}
      metadata:     %{event_id, processor_event_id, type, attempt}

    [:accrue, :ops, :webhook_dlq, :replay]  (span: :start | :stop | :exception)
      measurements: %{duration, requeued_count, skipped_count}
      metadata:     %{actor, filter, dry_run?}

    [:accrue, :ops, :webhook_dlq, :prune]
      measurements: %{dead_deleted, succeeded_deleted, duration}
      metadata:     %{retention_days}
    ```
    `:dead_lettered` fires on the `:failed → :dead` transition in the dispatch worker (D2-35), not only on replay — gives Phase 7 a clean "alert on DLQ growth" signal.
  - **Phase 7 consumption sketch (do NOT build in Phase 4):** `accrue_admin`'s LiveView calls `Accrue.Webhooks.DLQ.list/2` for the browser, `DLQ.requeue/1` for per-row replay, `DLQ.requeue_where/2` for bulk actions, subscribes to the telemetry namespace for a live count badge. Zero Phase 7 logic leaks into Phase 4.
  - **Coherence:** accrue core has no LiveView dep; replay is idempotent under D2-29 + the append-only events table; bulk safety via batch+stagger+max-rows cap; Mix tasks follow Ecto/Oban ecosystem precedent.

### Claude's Discretion

Downstream researcher and planner pick defaults for the following gray areas — not blocked on the user:

- **Coupon/Discount projection depth (BILL-27/28).** Phase 3 shipped minimal `accrue_coupons` + `accrue_invoice_coupons` (D3-16). Phase 4 expansion: thin passthrough + webhook-driven denormalization of fields the admin LV filters/sorts on, following the D3-14/D3-15 invoice projection pattern. Full Stripe mirror is not a goal. Discount composition at sub/invoice/checkout levels follows whatever Stripe's own discount semantics produce — we mirror Stripe's `discount` + `total_discount_amounts` fields, don't reinvent the math.
- **Upcaster registration pattern (EVT-05).** Default: module-per-version behaviour (`Accrue.Events.Upcasters.V1ToV2` implementing `@behaviour Accrue.Events.Upcaster` with `upcast/1` callback), dispatched by `schema_version` field on read. Chains (v1→v2→v3) compose via a version table in `Accrue.Events.UpcasterRegistry`. No macro DSL — principle of least surprise, easy to test with plain `ExUnit`.
- **Ops telemetry event set beyond the 4 named in the roadmap (OBS-03).** Roadmap names `[:accrue, :ops, :revenue_loss | :webhook_dlq | :dunning_exhaustion | :incomplete_expired]`. Also in-scope based on Phase 4 work: `[:accrue, :ops, :webhook_dlq, :replay | :prune]` (from D4-04), `[:accrue, :ops, :meter_reporting_failed]` for Stripe errors from D4-03, `[:accrue, :ops, :charge_failed]` as a low-cardinality signal. Default `Telemetry.Metrics` recipe (OBS-05) ships counters + spans (no distributions/summaries — those are host-choice).
- **Subscription Schedules (BILL-16) modeling.** Default: pure Stripe passthrough stored as `data` jsonb + typed columns only for fields the admin LV needs (current phase index, phases count, next phase timestamp). No dedicated `accrue_subscription_schedule_phases` child table in Phase 4 — add in v1.x only if needed.
- **Multi-endpoint webhook secret lookup (WH-13).** Default: config shape `config :accrue, :webhook_endpoints, [primary: [secret: ...], connect: [secret: ..., mode: :connect]]`, plug selects endpoint by route param or path suffix. Connect variant just uses a different signing secret — same verification path.
- **Embedded vs hosted Checkout mode shape (CHKT-02).** Default: single `Accrue.Checkout.Session.create/2` function with `mode: :hosted | :embedded` option. Return includes `client_secret` for embedded, `url` for hosted, both in a `%Session{}` struct.
- **Checkout success URL state reconciliation (CHKT-06).** Default: Accrue ships `Accrue.Checkout.reconcile/1` that takes a `checkout_session_id`, re-fetches from Stripe (D2-29), and ensures local state matches — called from host app's success URL controller. No cookie/session magic.

</decisions>

<specifics>
## Specific Ideas

- **"Cashier-for-Elixir" parity.** Laravel Cashier's API shapes are the benchmark for DX. `report_usage/3` mirrors `reportUsage`. Dunning delegation with a thin overlay matches Cashier's pattern while fixing its "no grace period" gap.
- **Ops engineer at 3am SSH'd into prod** is the explicit UX target for Mix tasks. They need `mix accrue.webhooks.replay --since ... --dry-run` to work without opening iex.
- **"Ship complete v1.0"** is the constraint under every decision. No in-tree shims that become v1.0.1 migration work. No deferred scaffolding that leaks into the public API.
- **Transactional outbox with sync-through + reconciler** is the mental model for metered usage — it's the minimum viable durability for a billing library.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 4 scope + requirements
- `.planning/ROADMAP.md` §"Phase 4: Advanced Billing + Webhook Hardening" — goal, requirements, success criteria, lattice_stripe gap note (now stale per D4-01)
- `.planning/REQUIREMENTS.md` — BILL-11/12/13/14/15/16/27/28, CHKT-01/02/03/04/05/06, WH-08/13, EVT-05/06/10, OBS-03/04/05
- `.planning/PROJECT.md` — vision, constraints, core value, release model
- `/Users/jon/projects/accrue/CLAUDE.md` — tech stack pins (note: `lattice_stripe ~> 1.0` pin must bump to `~> 1.1` per D4-01)

### Prior phase decisions that constrain Phase 4
- `.planning/phases/01-foundations/01-CONTEXT.md` — Fake processor strategy, Mox, dual bang/tuple API (D-05), `Accrue.Error` shape
- `.planning/phases/02-schemas-webhook-plumbing/02-CONTEXT.md` — D2-09 (transact+events atomicity), D2-29 (Stripe canonical), D2-33 (webhook event status enum + replay semantics), D2-34 (Pruner locked), D2-35 (dead-letter transition), D2-37 (Oban-as-retry engine)
- `.planning/phases/03-core-subscription-lifecycle/03-CONTEXT.md` — D3-01 (status enum verbatim), D3-04 (predicate enforcement), D3-12 (`intent_result/1` processor callback), D3-16 (minimal coupons schema — Phase 4 expands), D3-17 (user-path vs webhook-path changesets), D3-18 (workflow actions inside `Repo.transact/2`), `operation_id` pdict propagation

### lattice_stripe (sibling repo — read before implementing BILL-13 + CHKT-02)
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing/meter.ex` — `LatticeStripe.Billing.Meter` resource (Phase 20 complete on main)
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing/meter_event.ex` — `MeterEvent` resource including two-layer idempotency (body-level `identifier` + HTTP `idempotency_key`)
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing/meter_event_adjustment.ex` — adjustments
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing_portal/session.ex` — `BillingPortal.Session` with FlowData guards (Phase 21 complete on main)
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/request.ex` — generic request escape hatch (NOT used per D4-01, but documented for awareness)
- `/Users/jon/projects/lattice_stripe/guides/metering.md` — contains an `AccrueLike.UsageReporter` recipe; read before finalizing `report_usage/3` design to save rediscovering the idempotency contract
- `/Users/jon/projects/lattice_stripe/CHANGELOG.md` — v1.0.0 release notes, pending v1.1.0 content

### Stripe official documentation
- https://docs.stripe.com/billing/subscriptions/usage-based/recording-usage-api — BILL-13 primary reference
- https://docs.stripe.com/api/billing/meter-event — v1 MeterEvent API (sync, body-level `identifier` dedup)
- https://docs.stripe.com/api/v2/billing-meter-stream — v2 MeterEventStream (>1k eps escape hatch, documented for awareness only)
- https://docs.stripe.com/billing/revenue-recovery/smart-retries — BILL-15: dashboard-only, 8 attempts / 2 months cap
- https://docs.stripe.com/api/subscriptions/update — the hook D4-02 sweeper uses to drive terminal transitions
- https://docs.stripe.com/billing/subscriptions/customer-portal — CHKT-02/04/05: portal session + configuration model (configuration is Dashboard-managed per D4-01)
- https://docs.stripe.com/payments/checkout — CHKT-01/02/03: Checkout Session API

### Prior-art libs (inspiration, not copy-paste)
- https://laravel.com/docs/12.x/billing — Cashier: `reportUsage` shape (D4-03), dunning delegation (D4-02), Customer Portal session wrapper
- https://github.com/pay-rails/pay — Pay: delegation pattern for dunning, NOT a useful precedent for metered billing (issue #193 — known broken)
- https://hexdocs.pm/oban/Oban.html#retry_job/2 — confirms `:discarded`/`:cancelled` refusal (D4-04 structural necessity)
- https://hexdocs.pm/oban/Oban.Plugins.Cron.html — host-wired cron pattern for Pruner/Sweeper

### Architectural precedent (Elixir ecosystem)
- `Ecto.Migrator` + `mix ecto.migrate` — canonical "library core + thin Mix wrapper" pattern cited in D4-04

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (from Phases 1-3)
- **`Accrue.Processor.Fake`** — source of truth for tests. Phase 4 adds: `report_meter_event/1`, `portal_session_create/2`, `subscription_update/2` (for dunning sweeper). ETS-backed. No network.
- **`Accrue.Billing.Query`** (composable Ecto fragments, D3-04) — Phase 4 adds: `Query.metered_usage_pending/0`, `Query.dunning_sweep_candidates/1`, `Query.dlq_replayable/1` mirroring any new predicates.
- **`Accrue.Events.record_multi/2`** + append-only `accrue_events` table — all Phase 4 mutations slot into this via `Repo.transact/2`.
- **`operation_id` pdict propagation** via `Accrue.Plug.PutOperationId`, `Accrue.LiveView.on_mount :accrue_operation`, `Accrue.Oban.Middleware` — Phase 4 uses this for deterministic idempotency key seeding in `report_usage/3` and DLQ replay.
- **`Accrue.Billing.Invoice` hybrid projection** (D3-13/14/15) — Phase 4 coupon/discount work denormalizes `discount_minor` + related Stripe discount fields following the same pattern.
- **`Accrue.Config`** — NimbleOptions-backed. Phase 4 extends with `:dunning`, `:webhook_endpoints`, `:dead_retention_days`, `:succeeded_retention_days`, `:dlq_replay_batch_size`, `:dlq_replay_stagger_ms`, `:dlq_replay_max_rows`.

### Established Patterns
- **Commit-then-call-Stripe** (D2-09/D3-18) — every workflow action commits the local txn first, then calls Stripe, then updates via webhook refetch. D4-03 `report_usage/3` follows this identically.
- **Dual bang/tuple API** (D-05) — `requeue/1` + `requeue!/1`, `requeue_where/2` + `requeue_where!/2`.
- **`force_status_changeset/2` on webhook path** (D3-17) — D4-02 dunning transition flows through this. Stripe is canonical.
- **Mox for behaviours, Fake processor for integration tests** — no Bypass unless end-to-end plug tests demand it.
- **Oban queues:** `accrue_webhooks`, `accrue_mailers`, `accrue_maintenance` from Phase 2. Phase 4 adds `accrue_dunning` and `accrue_meters`.

### Integration Points
- **`lattice_stripe` sibling repo** (`../lattice_stripe/`) — must bump to 1.1 before Phase 4 merges. Consume via `path:` dep during dev.
- **Host app's `Oban` config** — Accrue documents recommended queue config + cron entries; does NOT start its own Oban instance.
- **Host app's Stripe Dashboard** — portal configuration (D4-01 footnote) and Smart Retries config (D4-02) live on the Stripe side, documented in install guide.
- **Phase 7 `accrue_admin`** — consumes `Accrue.Webhooks.DLQ.*` and subscribes to `[:accrue, :ops, :webhook_dlq, :*]` telemetry. Zero Phase 7 logic in Phase 4.

</code_context>

<deferred>
## Deferred Ideas

- **`BillingPortal.Configuration` programmatic support** — deferred to `lattice_stripe 1.2`. Additive, lands in an Accrue 1.x patch. (Raised under D4-01; Stripe Dashboard handles it in the interim, matching Pay/Cashier convention.)
- **`Accrue.Billing.report_usage_async/3` or built-in buffering** — deferred to Accrue 1.1. Additive, zero breaking change. Callers who need batching today wrap `report_usage/3` in their own Oban job (5-line pattern documented in the metered-billing guide). (Raised under D4-03.)
- **Stripe MeterEventStream v2 support (>1k eps high-volume path)** — deferred indefinitely. Out of scope for v1.0. Host apps at that scale aggregate client-side per Stripe's own guidance. (Raised under D4-03.)
- **Full local mirror of Stripe Coupon/PromotionCode fields for admin filtering** — deferred. Phase 4 denormalizes only what accrue_admin's Phase 7 LV actually filters/sorts on, following D3-14/D3-15 pattern. (Raised under BILL-27/28 Claude's Discretion.)
- **`accrue_subscription_schedule_phases` child schema** — deferred to v1.x if needed. Phase 4 uses `data` jsonb + minimal typed rollup columns. (Raised under BILL-16 Claude's Discretion.)
- **Macro DSL for upcaster registration** — rejected. Module-per-version behaviour is simpler and testable. (Raised under EVT-05 Claude's Discretion.)

</deferred>

---

*Phase: 04-advanced-billing-webhook-hardening*
*Context gathered: 2026-04-14*
