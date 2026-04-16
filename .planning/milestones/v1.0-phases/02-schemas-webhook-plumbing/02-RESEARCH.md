# Phase 2: Schemas + Webhook Plumbing - Research

**Researched:** 2026-04-12
**Domain:** Elixir/Phoenix billing library — polymorphic Ecto schemas, scoped raw-body webhook ingestion, transactional Oban dispatch
**Confidence:** HIGH

## Summary

Phase 2 is heavily constrained by the 37 decisions already locked in `02-CONTEXT.md` (D2-01 through D2-37). Research scope is therefore narrow: verify that the locked technical pattern is buildable against the actual shipping surface of `lattice_stripe ~> 0.2`, `plug ~> 1.19`, `phoenix ~> 1.8`, `ecto ~> 3.13`, and `oban ~> 2.21`, and surface the concrete module shapes, mix.exs additions, and test hooks the planner needs.

**Headline findings:**

1. **Signature verification is already done for us.** `LatticeStripe.Webhook.construct_event!/4` (in the installed `lattice_stripe 0.2`) implements Stripe's `t=…,v1=…` HMAC-SHA256 scheme with multi-secret rotation, `Plug.Crypto.secure_compare/2` timing-safe compare, 300s replay-tolerance window, and a `generate_test_signature/3` helper. Accrue wraps it and re-raises as `Accrue.SignatureError` — no crypto code is written in Phase 2. This alone eliminates an entire research question (WH-02, WH-04/5) and collapses a plan's worth of work.
2. **Phase 2 must add `{:plug, "~> 1.19"}` to core `accrue` mix.exs.** Phase 1 intentionally kept core dep-free from web frameworks; `plug_crypto` is transitively present but `plug` itself is not. The webhook plug + `Accrue.Router` macro need `Plug.Conn`, `Plug.Parsers`, and `Phoenix.Router` primitives. **Plug is required; Phoenix.Router is optional-compile** — users who only run Plug (not Phoenix) should still be able to mount the webhook.
3. **`Plug.Parsers` `body_reader:` hook is the exact pattern locked in D2-19**, and its reference implementation is ~4 lines from the official Plug docs. `Accrue.Webhook.CachingBodyReader` is a one-file module.
4. **Oban 2.21 exposes native Multi-aware `Oban.insert/3`** — the exact shape D2-24 assumes. A single `Ecto.Multi` atomically inserts the webhook event, the Oban job, AND the `accrue_events` ledger row.
5. **Ecto 3.13 `has_one :where` option supports polymorphic filtering** with constant-value matching — the pattern D2-04 depends on. Verified against Ecto 3.13.5 docs.
6. **The p99 <100ms WH-12 budget is achievable** because the sync path is: verify signature (µs — pure HMAC) → begin txn → insert row (on_conflict: :nothing) → `Oban.insert` → commit → 200. No network I/O in the sync path; all handler work is async via the Oban queue.

**Primary recommendation:** Proceed directly to planning using the locked decisions in CONTEXT.md. Research has confirmed every one of them is buildable and identified two planner-visible additions: (a) add `{:plug, "~> 1.19"}` as a hard dep and `{:phoenix, "~> 1.8", optional: true}` as optional, and (b) standardize on `Ecto.Multi` (not bare `Repo.transact/2`) as the concrete shape for the webhook persist transaction because Oban's Multi API is the path of least resistance for D2-24.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (copied verbatim from 02-CONTEXT.md `<decisions>`)

**Customer schema polymorphic ownership**
- **D2-01:** `owner_id :string` (text column). Lossless for UUIDs, bigint, ULIDs. Indexed via `CREATE INDEX ON accrue_customers (owner_type, owner_id)`. Chosen over `:binary_id` because `mix phx.new` still defaults to integer PKs without `--binary-id`.
- **D2-02:** `owner_type :string` stores an explicit string identifier, not `__MODULE__` to_string. Default from `Accrue.Billable` macro is `__MODULE__ |> Module.split() |> List.last()` (e.g. `"User"`); hosts MUST be able to override via `use Accrue.Billable, billable_type: "User"` for rename-safety.
- **D2-03:** Post-v1.0 opt-in hook `Accrue.Config.owner_id_type` (default `:string`). Hidden seam for performance override, not publicly documented in v1.0.

**`use Accrue.Billable` macro**
- **D2-04:** Hybrid macro injects exactly three things: `has_one :accrue_customer, Accrue.Billing.Customer, foreign_key: :owner_id, where: [owner_type: "User"]`; `__accrue__(:billable_type)` reflection; `customer(user)` delegate to `Accrue.Billing.customer/1`.
- **D2-05:** All write operations live in `Accrue.Billing` context, not on host schema. `Accrue.Billing.subscribe/2`, `.charge/3`, `.invoices/1`, etc.
- **D2-06:** `Accrue.Billing.customer/1` is lazy fetch-or-create.

**Metadata + data jsonb**
- **D2-07:** `metadata` is strict Stripe-compatible. Flat `%{String.t() => String.t()}` only. ≤50 keys, keys ≤40 chars, values ≤500 chars, no nested maps. Updates shallow-merge at top level; `""` or `nil` deletes a key.
- **D2-08:** `data` column has two explicit operations: `put_data/2` (full replace) and `patch_data/2` (shallow merge). No overloaded `merge:` flag.
- **D2-09:** All metadata + data writes go through `Repo.transact/2` with `optimistic_lock` on a `lock_version` integer column.
- **D2-10:** **REJECT deep-merge entirely.** Stripe has no deep-merge contract; deletion semantics become ambiguous.

**Outbound idempotency (PROC-04)**
- **D2-11:** Seed-based deterministic idempotency keys. `"accr_" <> (Base.url_encode64(:crypto.hash(:sha256, "#{op}|#{subject_id}|#{seed}"), padding: false) |> binary_part(0, 22))`, passed via `lattice_stripe`'s `:idempotency_key` request opt.
- **D2-12:** Seed chain: `opts[:operation_id]` > `Accrue.Actor.current_operation_id/0` > random UUID + `Logger.warning` fallback. Webhook-triggered ops seed from `processor_event_id`.
- **D2-13:** `lattice_stripe`'s `{:idempotency_error, ...}` tuple surfaces as `%Accrue.IdempotencyError{}`.

**Per-request API version (PROC-06)**
- **D2-14:** Precedence: `opts[:api_version]` > `Process.get(:accrue_stripe_api_version)` > `Accrue.Config.stripe_api_version/0`. Resolves to `lattice_stripe`'s `:stripe_version` request opt.
- **D2-15:** `Accrue.Stripe.with_api_version/2` helper for traffic-split rollouts.

**Webhook route mount (WH-01, WH-14)**
- **D2-16:** `Accrue.Router` module + `accrue_webhook/2` macro, host-owned pipeline. Expands to `forward "/stripe", Accrue.Webhook.Plug, processor: :stripe`.
- **D2-17:** `@after_compile` compile-time check raises if `accrue_webhook` forward sits under a pipeline lacking `Accrue.Webhook.CachingBodyReader` in `Plug.Parsers` `body_reader:` option.
- **D2-18:** Multi-endpoint shape ready for Phase 4 Connect (WH-13).

**Raw-body capture (WH-01, WH-02)**
- **D2-19:** `Plug.Parsers` `body_reader:` hook. `Accrue.Webhook.CachingBodyReader.read_body/2` wraps `Plug.Conn.read_body/2`, tees iolist into `conn.assigns[:raw_body]`.
- **D2-20:** `body_reader` lives only inside `:accrue_webhook_raw_body` pipeline — host's global `Plug.Parsers` in `MyAppWeb.Endpoint` is untouched.
- **D2-21:** Explicit `length: 1_000_000` (1MB) cap.
- **D2-22:** Signature verification uses `IO.iodata_to_binary(conn.assigns.raw_body)`.
- **D2-23:** Pre-Parsers custom plug approach REJECTED.

**Webhook transactional persistence (WH-03, WH-06, WH-12)**
- **D2-24:** Request path runs `Repo.transact/2` (or `Ecto.Multi`) containing: insert `accrue_webhook_events` row + `Oban.insert` dispatch job + `Accrue.Events.record_multi/3` entry. All atomic.
- **D2-25:** `accrue_webhook_events.processor_event_id` is `UNIQUE`. Duplicate POST → `on_conflict: :nothing`, skip enqueue, return 200.
- **D2-26:** Webhook request path is plug-only. No controller. Signature failure raises `Accrue.SignatureError`, rescued to HTTP 400.

**Handler dispatch (WH-06, WH-07, WH-10)**
- **D2-27:** Single callback, atom type, pattern-match in function head. `@callback handle_event(type :: atom(), event :: Accrue.Webhook.Event.t(), ctx :: map()) :: :ok | {:error, term()}`.
- **D2-28:** `use Accrue.Webhook.Handler` injects fallthrough `def handle_event(_, _, _), do: :ok`.
- **D2-29:** `%Accrue.Webhook.Event{}` struct carries `type, object_id, livemode, created_at` — NOT the raw Stripe payload. Forces WH-10 compliance by shape.
- **D2-30:** Default handler runs first (non-disableable), then user handlers sequentially in same Oban job. Per-handler rescue; only default-handler crashes re-raise for Oban retry.
- **D2-31:** Registration: `config :accrue, webhook_handlers: [MyApp.BillingHandler, MyApp.AnalyticsHandler]`.
- **D2-32:** REJECTED: module-per-event, telemetry-only dispatch, fan-out-to-N-jobs.

**DLQ + retention (WH-05, WH-11)**
- **D2-33:** Status column on `accrue_webhook_events`, not separate DLQ table. `Ecto.Enum` values: `[:received, :processing, :succeeded, :failed, :dead, :replayed]`.
- **D2-34:** Ship `Accrue.Webhooks.Pruner` as an Oban cron worker. Forced because Oban 2.21 CE's `Plugins.Pruner` has a single `max_age`.
- **D2-35:** Oban dispatch worker marks event `:dead` on final discard.
- **D2-36:** Partial index `WHERE status IN (:failed, :dead)`.
- **D2-37:** Oban dead-letter is retry mechanism; status column is Accrue-side projection.

### Claude's Discretion

- Exact Ecto schema module layout under `lib/accrue/billing/` (one file per schema or grouped)
- Migration filenames and ordering
- Default `Accrue.Webhook.DefaultHandler` internals — Phase 2 minimum is `customer.*` reconciliation
- Exact field list on `%Accrue.Webhook.Event{}` beyond required `type, object_id, livemode, created_at`
- Internal Oban queue naming (CLAUDE.md recommends `accrue_webhooks: 10`)
- `accrue_webhook/2` vs `accrue_webhook/3` variants
- Plug.Parsers `body_reader` tee implementation (iolist cons vs concat)
- Test fixture organization for signed payloads
- `Accrue.Billing.Customer.changeset/2` metadata validation location
- `lock_version` starting value / increment strategy

### Deferred Ideas (OUT OF SCOPE)

- Stripe Connect multi-endpoint variants (WH-13) — Phase 4
- Subscription lifecycle reconciliation in DefaultHandler — Phase 3
- Admin LiveView webhook browser — Phase 7 (accrue_admin)
- `mix accrue.gen.webhook_handler` scaffold — Phase 8
- DLQ opt-out (`dead_retention_days: :infinity`) UI surfacing — Phase 7
- Native `:binary_id`/`:bigint` `owner_id_type` override — post-v1.0
- Host-supplied canonical-param idempotency hashing — rejected for Phase 2
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BILL-01 | Polymorphic `Accrue.Billing.Customer` with `owner_type`/`owner_id`, `data` jsonb, metadata | Decided via D2-01..03, D2-07..10. `has_one :where` confirmed for Ecto 3.13.5 (Standard Stack §Ecto). |
| BILL-02 | `use Accrue.Billable` macro | Decided via D2-04..06. Hybrid macro emits one `has_one :where` + reflection + `customer/1` delegate. |
| PROC-04 | Deterministic idempotency keys | Decided via D2-11..13. `lattice_stripe 0.2` client.ex confirms `:idempotency_key` opt on `req.opts` is respected (verified in source at `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/client.ex:251`). |
| PROC-06 | Per-request API version override | Decided via D2-14..15. `lattice_stripe 0.2` client.ex line 176 confirms `:stripe_version` opt is respected. |
| WH-01 | Raw-body capture scoped to webhook routes only | Decided via D2-19..22. `Plug.Parsers` `body_reader` pattern verified from official Plug docs. |
| WH-02 | Signature verification with multi-secret rotation | **RESOLVED by `LatticeStripe.Webhook.construct_event!/4`** — implements multi-secret verification natively. Accrue wraps and re-raises. |
| WH-03 | DB idempotency via `accrue_webhook_events` `UNIQUE(processor_event_id)` | Decided via D2-24..25. Confirmed buildable with Ecto `unique_constraint` + `on_conflict: :nothing`. |
| WH-04 | Oban-backed async dispatch with exponential backoff | Oban 2.21 default backoff; dispatch worker uses `use Oban.Worker, queue: :accrue_webhooks, max_attempts: 25`. |
| WH-05 | Dead-letter queue after N attempts (default 25) | Decided via D2-35..37. Status column projection. |
| WH-06 | User handler behaviour with pattern-matchable event types | Decided via D2-27..31. Phoenix.Channel `handle_in/3` precedent. |
| WH-07 | Default handler for built-in state reconciliation | Decided via D2-30. Phase 2 minimum: `customer.*` events only. |
| WH-10 | Handler re-fetches current object instead of trusting snapshot | Decided via D2-29. Struct carries `object_id`, NOT raw payload. Shape enforces compliance. |
| WH-11 | Configurable DLQ retention, default 90 days, pruned via Oban cron | Decided via D2-34. Accrue-owned cron worker, host wires schedule. |
| WH-12 | Webhook pipeline p99 <100ms | Achievable — sync path is pure-CPU (HMAC + 2 INSERTs + COMMIT). No network I/O in request path. See Telemetry section. |
| WH-14 | Webhook event type constants module | Minimum: expose `Accrue.Webhook.Event.type/0` typespec; full constants module can defer to Phase 3 when subscription events land. |
| EVT-04 | Every Billing context write emits an event in same transaction | Decided implicitly via D2-09 + D2-24 — both use `Repo.transact/2` wrapping mutation + `Accrue.Events.record_multi/3`. Confirmed by existing `Accrue.Events.record_multi/3` from Phase 1 (file: `lib/accrue/events.ex`). |
| TEST-09 | Oban.Testing integration for async assertions | Standard Oban 2.21 testing helpers: `use Oban.Testing, repo: Accrue.TestRepo`; `assert_enqueued`, `perform_job`. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Elixir 1.17+ / OTP 27+** — no legacy support
- **Phoenix 1.8+, LiveView 1.1+** — but core `accrue` has NO LiveView dep; Phoenix is used only via router macros
- **Ecto ~> 3.13** — enables `has_one :where` polymorphic filtering
- **Oban ~> 2.21 CE** — NOT Oban Pro; `DynamicPruner` unavailable → forces D2-34
- **`lattice_stripe ~> 0.2`** — Phase 2 MUST NOT depend on 0.3 Subscription/Invoice/Price/Product/Meter APIs
- **PostgreSQL 14+** — use `gen_random_uuid()`, NOT `pg_uuidv7`
- **Webhook signature verification mandatory and non-bypassable**
- **Raw-body plug MUST run before `Plug.Parsers`** — the `body_reader:` approach satisfies this by having the parser call our reader first
- **Sensitive Stripe fields never logged** — applies to telemetry metadata + error contexts
- **Webhook p99 <100ms** — CLAUDE.md-level constraint, not just phase criterion
- **Accrue does NOT start its own Oban instance** — host owns supervision tree; Accrue only enqueues via `Oban.insert`
- **All public entry points emit telemetry `:start/:stop/:exception`**
- **Monorepo:** `accrue/` and `accrue_admin/` siblings; Phase 2 is CORE only
- **Testing:** Mox for behaviours, StreamData for property tests, ExUnit + Oban.Testing. Avoid `:mock`.

## Standard Stack

### Core additions for Phase 2

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:plug` | `~> 1.19` | `Plug.Conn`, `Plug.Parsers`, `Plug.Crypto` | **NEW hard dep — Phase 1 did not add it.** Required by `Accrue.Webhook.Plug` and `Accrue.Webhook.CachingBodyReader`. Current 1.19.1 (2025-12-09) [VERIFIED: hex.pm API]. |
| `:phoenix` | `~> 1.8`, `optional: true` | `Phoenix.Router` macros (`pipeline/2`, `forward/3`, `scope/2`, `@after_compile` route walker) | **NEW optional dep.** `Accrue.Router` is compiled only when `Code.ensure_loaded?(Phoenix.Router)` — keeps headless/worker-only hosts from being forced to pull Phoenix. Current 1.8.5 (2026-03-05) [VERIFIED: hex.pm API]. |

### Already present (from Phase 1, confirmed via `mix.exs`)

| Library | Version | Role in Phase 2 |
|---------|---------|-----------------|
| `:ecto` / `:ecto_sql` | `~> 3.13` | Schemas, `Ecto.Multi`, `Repo.transact/2`, `optimistic_lock`, `Ecto.Enum`, `has_one :where` |
| `:postgrex` | `~> 0.22` | Unique-constraint error translation, partial indexes |
| `:oban` | `~> 2.21` | `Oban.insert/3` Multi-aware, `Oban.Worker`, `Oban.Plugins.Cron` (host-wired), backoff |
| `:lattice_stripe` | `~> 0.2` | `LatticeStripe.Webhook.construct_event!/4` (signature verify + replay protection), `:idempotency_key` opt, `:stripe_version` opt |
| `:jason` | `~> 1.4` | `Plug.Parsers` `json_decoder:`, jsonb round-trip for `data` + `metadata` |
| `:nimble_options` | `~> 1.1` | New config keys: `:succeeded_retention_days`, `:dead_retention_days`, `:stripe_api_version`, hidden `:owner_id_type` |
| `:telemetry` | `~> 1.3` | `[:accrue, :webhooks, :receive/:verify/:persist/:enqueue/:handler]` spans |
| `:mox` | `~> 1.2` | Mocking `Accrue.Processor` behaviour in tests (already set up in Phase 1) |
| `:stream_data` | `~> 1.3` | Property tests for metadata validation rules (key count, value length) |

### Verified `lattice_stripe 0.2` capabilities [VERIFIED: source read at `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/webhook.ex` and `.../client.ex`]

```elixir
# Exactly what Accrue.Webhook.Plug needs — already shipped in lattice_stripe 0.2:
LatticeStripe.Webhook.construct_event!(raw_body, sig_header, secret_or_secrets, tolerance: 300)
# => %LatticeStripe.Event{} | raises LatticeStripe.Webhook.SignatureVerificationError

# Accepts list of secrets for rotation:
LatticeStripe.Webhook.construct_event!(body, header, [old, new])

# Timing-safe compare via Plug.Crypto.secure_compare/2 (already in deps transitively)
# 300s default replay tolerance (override with :tolerance)
# Generates test signatures for fixtures:
header = LatticeStripe.Webhook.generate_test_signature(json_payload, secret)
```

Accrue's job is to:
1. Translate `secret` → lookup from `Accrue.Config.webhook_signing_secrets/1` (returns a list, not a single)
2. Catch `LatticeStripe.Webhook.SignatureVerificationError` and re-raise as `%Accrue.SignatureError{}` (D2-26 + Phase 1 D-08)
3. Use `LatticeStripe.Event.t()` as the wire shape, project it to the Accrue-side struct `%Accrue.Webhook.Event{}` (D2-29) before handler dispatch

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Plug.Parsers` `body_reader:` hook (D2-19) | Custom plug BEFORE `Plug.Parsers` that reads + re-injects body | **REJECTED by D2-23.** `Plug.Conn.read_body/2` drains the socket; re-injection requires undocumented tricks. The `body_reader` hook is Plug's official documented extension point. |
| Wrap `LatticeStripe.Webhook` (chosen) | Reimplement HMAC verification inside `Accrue.Webhook.Signature` | Pure duplication — lattice_stripe's impl is already timing-safe, replay-protected, rotation-aware. Would also re-surface the `LatticeStripe.Webhook.SignatureVerificationError → Accrue.SignatureError` mapping as a larger surface. |
| `Ecto.Multi` for webhook persist path | Bare `Repo.transact/2` with a closure | **Recommendation: use Ecto.Multi.** Oban 2.21's `Oban.insert/3` is explicitly Multi-aware (`Oban.insert(multi, name, changeset)`); `Repo.transact/2` requires `Oban.insert/2` inside the closure, which also works but is less idiomatic when `Accrue.Events.record_multi/3` is already Multi-shaped. D2-24 says "single transaction" without dictating the shape; the Multi form is cleaner. |
| `Ecto.Enum` for status column (D2-33) | String column + constant module | `Ecto.Enum` gives compile-time dump/load, auto-casting, and free ExDoc — standard since Ecto 3.5. |
| `on_conflict: :nothing` for dedup (D2-25) | Try-insert + rescue `Ecto.ConstraintError` | `:nothing` is atomic at the DB layer, single round-trip, and returns the same shape on both create and duplicate paths. Rescue-based dedup has a subtle race between SELECT-then-INSERT windows. |

**Installation (mix.exs diff for `accrue/mix.exs`):**

```elixir
defp deps do
  [
    # --- Phase 2 additions ---
    {:plug, "~> 1.19"},
    {:phoenix, "~> 1.8", optional: true},

    # --- unchanged from Phase 1 ---
    {:ecto, "~> 3.13"},
    {:ecto_sql, "~> 3.13"},
    {:postgrex, "~> 0.22"},
    {:ex_money, "~> 5.24"},
    {:lattice_stripe, "~> 0.2"},
    {:oban, "~> 2.21"},
    # ... rest unchanged
  ]
end
```

**Version verification (2026-04-12):**

| Package | Pinned | Latest on hex.pm | Publish date | Source |
|---------|--------|------------------|--------------|--------|
| plug | `~> 1.19` | 1.19.1 | 2025-12-09 | [VERIFIED: hex.pm API /api/packages/plug] |
| phoenix | `~> 1.8` | 1.8.5 | 2026-03-05 | [VERIFIED: hex.pm API /api/packages/phoenix] |
| oban | `~> 2.21` | 2.21.1 | 2026-03-26 | [VERIFIED: hex.pm API /api/packages/oban] |

## Architecture Patterns

### Recommended Project Structure

Additions under `accrue/lib/accrue/`:

```
lib/accrue/
├── billing.ex                        # Context facade — customer/1, create_customer/1, put_data/2, patch_data/2, update_metadata/2
├── billing/
│   ├── customer.ex                   # Ecto.Schema + changeset (metadata rules inline)
│   ├── metadata.ex                   # Pure module: validate/1, merge/2, docs
│   └── billable.ex                   # `use Accrue.Billable` macro
├── webhook.ex                        # Thin public facade, telemetry conventions
├── webhook/
│   ├── plug.ex                       # Accrue.Webhook.Plug — the request-path plug
│   ├── caching_body_reader.ex        # Plug.Parsers body_reader hook
│   ├── event.ex                      # %Accrue.Webhook.Event{} struct (D2-29)
│   ├── webhook_event.ex              # Ecto schema for accrue_webhook_events table
│   ├── handler.ex                    # @callback + use Accrue.Webhook.Handler
│   ├── default_handler.ex            # Default reconciler (customer.* for Phase 2)
│   ├── dispatch_worker.ex            # Oban worker running handler chain
│   ├── pruner.ex                     # Oban cron worker (D2-34)
│   └── signature.ex                  # Thin wrapper around LatticeStripe.Webhook
├── router.ex                         # accrue_webhook/2 macro + @after_compile check
├── stripe.ex                         # with_api_version/2 helper (D2-15)
└── processor/
    └── stripe.ex                     # EXTEND for D2-11 idempotency key computation

priv/repo/migrations/
├── 20260412NNNNNN_create_accrue_customers.exs
└── 20260412NNNNNN_create_accrue_webhook_events.exs
```

### Pattern 1: Polymorphic `has_one :where` (BILL-01/02)

**What:** Single `accrue_customers` table, rows scoped to a host schema via `(owner_type, owner_id)`. Each host schema gets a typed `has_one :accrue_customer` association whose `:where` is hard-coded to that host's billable_type string.

```elixir
# In host app:
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  use Accrue.Billable  # defaults billable_type: "User"

  schema "users" do
    field :email, :string
    # Injected by `use Accrue.Billable`:
    # has_one :accrue_customer, Accrue.Billing.Customer,
    #   foreign_key: :owner_id,
    #   where: [owner_type: "User"]
    timestamps()
  end
end
```

```elixir
# lib/accrue/billing/billable.ex
defmodule Accrue.Billable do
  @moduledoc "..."

  defmacro __using__(opts) do
    billable_type =
      Keyword.get_lazy(opts, :billable_type, fn ->
        quote do
          __MODULE__ |> Module.split() |> List.last()
        end
      end)

    quote do
      @accrue_billable_type unquote(billable_type)

      has_one :accrue_customer, Accrue.Billing.Customer,
        foreign_key: :owner_id,
        where: [owner_type: @accrue_billable_type],
        references: :id

      def __accrue__(:billable_type), do: @accrue_billable_type

      def customer(%__MODULE__{} = record), do: Accrue.Billing.customer(record)
    end
  end
end
```

Note the `foreign_key: :owner_id` + string `:where` — `Accrue.Billing.Customer.owner_id` is `:string`, but host `users.id` may be integer or UUID. Ecto's `has_one :where` accepts constant values; at query time Ecto casts through the `owner_id` type. **The host's id is stringified when written** via `to_string(record.id)` inside `Accrue.Billing.customer/1` — this is the tax for D2-01's "lossless across PK types" promise. Document in ExDoc.

**Source:** [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html#has_one/3] — `:where` option confirmed in Ecto 3.13.5 documentation, supports constant-value equality filtering.

### Pattern 2: `Plug.Parsers` body_reader (D2-19, WH-01)

**What:** `Plug.Parsers` normally reads the request body and discards it. The `body_reader:` option lets you supply a module that intercepts the read, tees the bytes somewhere (here: `conn.assigns[:raw_body]`), and returns the body to Plug.Parsers for normal JSON parsing.

```elixir
# lib/accrue/webhook/caching_body_reader.ex
defmodule Accrue.Webhook.CachingBodyReader do
  @moduledoc """
  Plug.Parsers `body_reader:` hook that tees the raw request body into
  `conn.assigns[:raw_body]` as an iodata list while still handing the
  parsed body back to `Plug.Parsers` for JSON decoding.

  Required by `Accrue.Webhook.Plug` because Stripe webhook signatures
  are computed over the raw, unmodified request body — any re-encoding
  via JSON decode/encode round-trips changes whitespace and byte order
  and fails signature verification.
  """
  @spec read_body(Plug.Conn.t(), keyword()) ::
          {:ok, binary(), Plug.Conn.t()}
          | {:more, binary(), Plug.Conn.t()}
          | {:error, term()}
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
        {:ok, body, conn}

      {:more, body, conn} ->
        conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
        {:more, body, conn}

      {:error, _} = err ->
        err
    end
  end
end
```

Then at signature-verification time (inside `Accrue.Webhook.Plug`):

```elixir
raw_body = conn.assigns[:raw_body] |> Enum.reverse() |> IO.iodata_to_binary()
```

Note the `Enum.reverse` — `update_in` prepends for O(1) append in the streaming case; reverse at flatten time. The existing Plug docs example omits `reverse` because most consumers only read once; Accrue keeps it for correctness when `{:more, ...}` fires on bodies near the 1MB cap.

**Source:** [CITED: https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader] — `CacheBodyReader` is the canonical pattern from the Plug moduledoc.

### Pattern 3: Multi-aware transactional persist (D2-24, WH-03/12)

```elixir
# lib/accrue/webhook/plug.ex — the hot path
defmodule Accrue.Webhook.Plug do
  @behaviour Plug
  import Plug.Conn
  require Logger

  alias Accrue.Webhook.WebhookEvent
  alias Accrue.Events

  @impl true
  def init(opts), do: Keyword.fetch!(opts, :processor) |> then(&[processor: &1])

  @impl true
  def call(conn, processor: processor) do
    :telemetry.span([:accrue, :webhooks, :receive], %{processor: processor}, fn ->
      result = do_call(conn, processor)
      {result, %{processor: processor}}
    end)
  end

  defp do_call(conn, processor) do
    raw_body = flatten_raw_body(conn)
    sig_header = get_req_header(conn, "stripe-signature") |> List.first()
    secrets = Accrue.Config.webhook_signing_secrets(processor)

    try do
      event = LatticeStripe.Webhook.construct_event!(raw_body, sig_header, secrets)
      persist_and_enqueue(conn, processor, event, raw_body)
    rescue
      e in LatticeStripe.Webhook.SignatureVerificationError ->
        reraise Accrue.SignatureError, [reason: e.reason], __STACKTRACE__
    end
  end

  defp persist_and_enqueue(conn, processor, %LatticeStripe.Event{} = event, raw_body) do
    wh_changeset = WebhookEvent.ingest_changeset(%{
      processor: to_string(processor),
      processor_event_id: event.id,
      type: event.type,
      livemode: event.livemode,
      status: :received,
      data: raw_body,        # stored as bytea or jsonb — see Open Questions
      received_at: DateTime.utc_now()
    })

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:webhook_event, wh_changeset,
           on_conflict: :nothing,
           conflict_target: [:processor, :processor_event_id],
           returning: true)
      |> Ecto.Multi.run(:dedup_check, fn _repo, %{webhook_event: row} ->
           # row.id is nil on conflict:nothing skip; we detect that to branch
           if row.id, do: {:ok, :new}, else: {:ok, :duplicate}
         end)
      |> Oban.insert(:dispatch_job, fn %{webhook_event: row, dedup_check: status} ->
           case status do
             :new ->
               Accrue.Webhook.DispatchWorker.new(%{webhook_event_id: row.id})
             :duplicate ->
               # Insert a no-op nop job, or skip: use Oban.insert_all with empty list
               # — cleaner: use Multi.run + conditional insert
               Accrue.Webhook.DispatchWorker.new(%{noop: true}, schedule_in: 0)
           end
         end)
      |> Accrue.Events.record_multi(:ledger_event,
           type: "webhook.received",
           subject_type: "accrue_webhook_event",
           subject_fn: fn %{webhook_event: row} -> row.id end,
           data: %{processor: processor, event_id: event.id, event_type: event.type})

    case Accrue.Repo.repo().transaction(multi) do
      {:ok, _} -> send_resp(conn, 200, ~s({"ok":true})) |> halt()
      {:error, _step, reason, _} ->
        Logger.error("webhook persist failed: #{inspect(reason)}")
        send_resp(conn, 500, ~s({"ok":false})) |> halt()
    end
  end
end
```

**Key shape notes:**
- `Ecto.Multi` is the idiom because `Oban.insert/3` has a native `Ecto.Multi` arity and `Accrue.Events.record_multi/3` (from Phase 1) is Multi-shaped. Using bare `Repo.transact/2` would force both to be manually sequenced.
- **D2-25 dedup branch:** `on_conflict: :nothing` returns an unpersisted-looking changeset struct on conflict — Ecto returns the supplied struct with `id: nil`. Detection strategy: either (a) branch on `row.id == nil` as shown, or (b) do a preflight `SELECT` before the Multi and skip the whole flow on hit. Option (a) keeps everything in one round-trip and is faster; option (b) is simpler to test. **Recommend option (a) for the hot path, option (b) for legibility if benchmarks show the Multi is fine either way.**
- **Alternative for dedup skipping Oban insert cleanly:** use two separate Multi branches via `Ecto.Multi.run(:maybe_enqueue, ...)` that returns `{:ok, :skipped}` when duplicate. This avoids needing a "noop job" — the cleanest shape.
- **All 3 writes in one transaction satisfies EVT-04.** A rollback test asserts both the webhook_event row AND the accrue_events ledger row disappear together.

**Source:** [CITED: https://hexdocs.pm/oban/Oban.html#insert/3] — Multi-aware `Oban.insert(multi, name, changeset_or_fun, opts)` is the documented API.

### Pattern 4: Deterministic idempotency key (D2-11, PROC-04)

```elixir
# lib/accrue/processor/stripe.ex — extension in Phase 2
defp compute_idempotency_key(op, subject_id, opts) do
  seed =
    Keyword.get(opts, :operation_id) ||
      Accrue.Actor.current_operation_id() ||
      random_seed_with_warning(op, subject_id)

  raw = :crypto.hash(:sha256, "#{op}|#{subject_id}|#{seed}")
  "accr_" <> (Base.url_encode64(raw, padding: false) |> binary_part(0, 22))
end

defp random_seed_with_warning(op, subject_id) do
  seed = Ecto.UUID.generate()
  Logger.warning(
    "Accrue.Processor.Stripe: no operation_id seed for #{op}/#{subject_id}; " <>
    "generated random seed #{seed}. Retries will NOT be idempotent. " <>
    "Set opts[:operation_id] or push Accrue.Actor context."
  )
  seed
end

# Then pass through to lattice_stripe:
def create_customer(attrs, opts) do
  idk = compute_idempotency_key(:create_customer, Map.fetch!(attrs, :owner_id), opts)
  LatticeStripe.Customer.create(attrs, idempotency_key: idk, stripe_version: resolve_api_version(opts))
end
```

**Verified:** [VERIFIED: source `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/client.ex:251`] — `resolve_idempotency_key/3` gives precedence to `Keyword.get(opts, :idempotency_key)` over `generate_idempotency_key`, so passing `:idempotency_key` in the request opts fully overrides lattice_stripe's default random-UUID generator.

### Pattern 5: `accrue_webhook/2` router macro (D2-16, WH-01)

```elixir
# lib/accrue/router.ex
defmodule Accrue.Router do
  @moduledoc """
  Router helpers for mounting Accrue's webhook endpoint.

  ## Usage

      defmodule MyAppWeb.Router do
        use MyAppWeb, :router
        import Accrue.Router

        pipeline :accrue_webhook_raw_body do
          plug Plug.Parsers,
            parsers: [:json],
            pass: ["*/*"],
            json_decoder: Jason,
            body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
            length: 1_000_000
        end

        scope "/webhooks", MyAppWeb do
          pipe_through :accrue_webhook_raw_body
          accrue_webhook "/stripe", :stripe
        end
      end
  """

  defmacro accrue_webhook(path, processor) do
    quote do
      forward unquote(path), Accrue.Webhook.Plug, processor: unquote(processor)
    end
  end

  # D2-17: @after_compile check lives on a router-level helper
  # invoked by `use Accrue.Router.Check` (optional second step).
end
```

The `@after_compile` pipeline-walk (D2-17) is the single hardest-to-verify part of the phase; the compile-time route walk uses `module.__routes__()` from `Phoenix.Router`. This is Phoenix-specific introspection — it's why `:phoenix` is a hard requirement for `Accrue.Router` (but optional for the core `:accrue` app because a pure-Plug host can define its own `Plug.Router` with the pipeline manually and skip `Accrue.Router` entirely).

### Pattern 6: Handler dispatch in Oban worker (D2-27..30)

```elixir
defmodule Accrue.Webhook.DispatchWorker do
  use Oban.Worker, queue: :accrue_webhooks, max_attempts: 25

  alias Accrue.Webhook.{WebhookEvent, Event, DefaultHandler}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"webhook_event_id" => id}, attempt: attempt, max_attempts: max}) do
    row = Accrue.Repo.repo().get!(WebhookEvent, id)
    event = Event.from_stripe(row)  # project to lean struct, no raw payload

    # Push actor context for downstream Stripe calls (D2-12)
    Accrue.Actor.push(%{actor: :webhook, operation_id: row.processor_event_id})

    # Run default handler — if it crashes, let Oban retry (WH-04)
    :ok = run_handler(DefaultHandler, event, row)

    # Run user handlers — per-handler rescue (D2-30)
    for mod <- Application.get_env(:accrue, :webhook_handlers, []) do
      try do
        run_handler(mod, event, row)
      rescue
        err ->
          :telemetry.execute([:accrue, :webhooks, :handler, :exception],
            %{},
            %{module: mod, error: err, event_type: event.type})
          Logger.error("user handler #{inspect(mod)} crashed: #{inspect(err)}")
      end
    end

    mark_status(row, :succeeded)
    :ok
  after
    Accrue.Actor.pop()
  end

  # Oban's max_attempts terminal path → mark :dead (D2-35)
  # Done via Oban telemetry handler or perform/1 rescue on final attempt.
end
```

### Anti-Patterns to Avoid

- **Reading raw body in an explicit pre-Parsers plug then re-injecting.** [REJECTED BY D2-23] `Plug.Conn.read_body/2` drains the adapter's socket buffer; subsequent reads return `{:ok, "", conn}`. Re-injection requires replacing the underlying adapter state and is fragile across `Bandit` vs `Cowboy`. Use `Plug.Parsers` `body_reader:` instead.
- **JSON-decoding then re-encoding the body for signature verification.** `Jason.encode(Jason.decode!(body))` is NOT byte-identical (key order, whitespace, unicode escaping all vary). Always verify against the **raw bytes** captured by `CachingBodyReader`.
- **Using `:binary_id` for `accrue_customers.owner_id`.** [REJECTED BY D2-01] Would exclude integer-PK hosts.
- **Deep-merging `metadata`.** [REJECTED BY D2-10] Breaks Stripe round-trip and creates ambiguous deletion semantics.
- **Fan-out to N Oban jobs per handler.** [REJECTED BY D2-32] Creates ordering hazards; keeps the sync path atomic but scatters state reconciliation.
- **Trusting the snapshot payload inside a handler.** [REJECTED BY D2-29 shape] Handlers MUST re-fetch via `Accrue.Processor.fetch(event.object_id)`. The struct deliberately omits the raw body so there's nothing to trust.
- **Calling `Oban.insert/2` inside a `Repo.transact/2` closure when you could use `Oban.insert/3` (Multi form).** Both work; the Multi form is more idiomatic and lets `record_multi/3` compose naturally.
- **Using `Ecto.Schema.timestamps/0` default precision for `received_at`.** Stripe timestamps are seconds; store `received_at` as `:utc_datetime_usec` but record the Stripe `created` field separately as Unix seconds for deterministic ordering (WH-09's Phase 3 out-of-order resolution depends on this — capture the seed now).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HMAC-SHA256 webhook signature verification | Custom `:crypto.mac` + `Plug.Crypto.secure_compare` wrapper | `LatticeStripe.Webhook.construct_event!/4` | Already timing-safe, replay-protected, multi-secret aware. Hand-rolling re-introduces every CVE Stripe has seen since 2015. |
| Test signature generation | Manual HMAC in test helpers | `LatticeStripe.Webhook.generate_test_signature/3` | Prevents test/prod drift — when lattice_stripe updates the signing scheme, tests follow automatically. |
| Raw-body capture before Parsers | Custom pre-Parsers plug that re-injects body | `Plug.Parsers` `body_reader:` hook | Official Plug pattern; no socket-drain footgun; documented contract. |
| Transactional job enqueue | Manual `Repo.transaction` + `Oban.insert` inside closure with error juggling | `Oban.insert/3` Multi form | Native API; correct commit-ordering semantics; cleaner with `Ecto.Multi.run` composition. |
| Optimistic locking for concurrent metadata writes | `SELECT FOR UPDATE` row locks | `Ecto.Changeset.optimistic_lock/2` with `lock_version` | Ecto-native, portable across repos, no lock escalation risk. |
| Dedup on insert | SELECT-then-INSERT with rescue | `on_conflict: :nothing` with `conflict_target:` | Atomic in a single round-trip; no TOCTOU window. |
| Status enum type storage | String + constant module | `Ecto.Enum` | Auto-cast, dump/load, and ExDoc for free. |
| Stripe webhook event parsing | Manual `Jason.decode!` + field extraction | `LatticeStripe.Event.from_map/1` | Structure is owned by lattice_stripe; we just project to `%Accrue.Webhook.Event{}`. |
| Idempotency key generation | UUID or random | `:crypto.hash(:sha256, ...)` with seeded input + `Base.url_encode64` | Deterministic across retries; required by PROC-04. |

**Key insight:** Phase 2's "custom code budget" is smaller than it looks. Between `lattice_stripe 0.2` (signature verify + event struct + idempotency passthrough) and `Plug.Parsers` `body_reader:` (raw body capture), the actual Accrue-owned surface is: the polymorphic Customer schema, the macro, the Router macro, the dispatch worker, the `on_conflict` dedup transaction, and the status pruner. Everything else delegates.

## Runtime State Inventory

**Greenfield phase** — no rename/refactor/migration work. Omitted per research protocol.

## Common Pitfalls

### Pitfall 1: Raw body drained before signature verification

**What goes wrong:** An endpoint global `Plug.Parsers` runs in the default Phoenix `:api` pipeline, reads the body into `conn.body_params`, and the raw bytes are gone by the time `Accrue.Webhook.Plug` tries to verify the signature. Or: a user puts `plug Plug.Parsers` both in their endpoint AND in the webhook pipeline, and the outer parser drains first.

**Why it happens:** `Plug.Conn.read_body/2` drains the adapter socket buffer. Subsequent `read_body` calls return `{:ok, "", conn}` without error.

**How to avoid:**
- Webhook pipeline must NOT be nested under `:api` — the `scope "/webhooks"` is at router-top-level, `pipe_through :accrue_webhook_raw_body` exclusively
- `Endpoint.config(:parsers)` — if the endpoint itself has `Plug.Parsers` via `plug Plug.Parsers, ...`, the router is too late. The user MUST omit webhook paths from the endpoint-level Parsers, OR use the webhook pipeline alone and skip endpoint Parsers for webhook routes. Document in the install guide.
- **Mitigation via D2-17:** compile-time walk of routes catches the case where `accrue_webhook` is under a pipeline missing `CachingBodyReader`, but it CANNOT catch endpoint-level Parsers. Add an ExDoc example showing the correct `MyAppWeb.Endpoint` shape.

**Warning signs:** `SignatureError` with reason `:no_matching_signature` on every single webhook, including test fixtures that work in isolation.

### Pitfall 2: `on_conflict: :nothing` returns a struct with `id: nil`

**What goes wrong:** The Multi step succeeds, you get a `%WebhookEvent{}` back from Ecto, but `row.id == nil` because the conflict skipped the insert. Subsequent `Oban.insert` uses `row.id` as the job args → dispatches a job that `get!/2`'s a nil row → 500.

**Why it happens:** Ecto's `on_conflict: :nothing` returns the original changeset struct on conflict, NOT the existing row. `returning: true` does NOT fix this — it only populates generated columns from INSERT RETURNING, which is empty on conflict skip.

**How to avoid:** Either:
- **Option A:** `Ecto.Multi.run` step after the insert that branches on `row.id == nil` and skips the Oban insert via `Ecto.Multi.run(:maybe_enqueue, fn _, %{webhook_event: row} -> if row.id, do: {:ok, enqueue(row)}, else: {:ok, :skipped} end)`.
- **Option B:** Use `on_conflict: {:replace, [:received_at]}` + `conflict_target: [:processor, :processor_event_id]` which forces RETURNING to come back with the EXISTING row's id — but this also mutates `received_at`, which you probably don't want.
- **Option C (recommended):** `SELECT` first via `Repo.get_by(WebhookEvent, [processor:, processor_event_id:])` and branch above the Multi. Clean, legible, one extra round-trip outside the txn — fine for p99 <100ms.

**Warning signs:** Oban job crash on `Ecto.NoResultsError` for `Accrue.Repo.get!(WebhookEvent, nil)` after a duplicate POST.

### Pitfall 3: Metadata shallow-merge vs `""` deletion semantics

**What goes wrong:** User calls `update_customer(c, metadata: %{"tier" => ""})` expecting to delete `"tier"`. Code reads `""` as a value, stores `"tier" => ""`, Stripe round-trips it as deletion, local state is now out-of-sync.

**Why it happens:** D2-07 says `""` deletes a key — but this must be enforced at **write time** in the changeset, not discovered at round-trip time.

**How to avoid:** `Accrue.Billing.Metadata.merge/2` is a pure function that:
1. Takes existing map + update map
2. Walks update map: `{k, ""} -> Map.delete(acc, k)`; `{k, nil} -> Map.delete(acc, k)`; `{k, v} -> Map.put(acc, k, v)`
3. Validates final map size (≤50), key lengths (≤40), value lengths (≤500)
4. Raises on nested map (no recursive merge)

**Warning signs:** A round-trip test `update + fetch` returns different shape than what was written.

### Pitfall 4: Oban queue not started in host supervision tree

**What goes wrong:** Webhook POST returns 200, row is inserted, but no handler ever runs because the host's Oban instance doesn't include `:accrue_webhooks` in `queues:`.

**Why it happens:** Accrue documents `:accrue_webhooks` as a recommended queue but **does NOT start Oban itself** (CLAUDE.md boundary). If the host's `config :my_app, Oban, queues: [default: 10]` omits `accrue_webhooks`, jobs are enqueued but never polled.

**How to avoid:**
- Install guide: explicit `queues: [default: 10, accrue_webhooks: 10, accrue_mailers: 20]` snippet
- `Accrue.Application` boot check can verify: if `Application.get_env(:accrue, :check_oban_queues)` is true, walk host Oban config at startup and warn (not raise — some test configs legitimately start without Oban). Phase 2 can defer this check to Phase 8 install polish — it's not on the critical path, and the symptom is visible (no retries, rows stuck in `:received`).
- Telemetry: emit `[:accrue, :webhooks, :stuck]` from the pruner if rows sit in `:received` for > N minutes.

**Warning signs:** Rows in `accrue_webhook_events` with `status: :received` that never transition; `Oban.Job` rows in `available` state with no `attempted_at`.

### Pitfall 5: Host-id stringification mismatch in `owner_id`

**What goes wrong:** Host has `users.id` as `:binary_id` (UUID). `Accrue.Billing.customer(user)` does `to_string(user.id)` and stores `"550e8400-e29b-41d4-a716-446655440000"`. Later, a query filters by `owner_id: to_string(user.id)` and works. But a raw SQL query filtering `WHERE owner_id = u.id::text` may or may not work depending on pg default text casting of binary UUIDs — `binary_id` in Ecto is already text in `uuid` canonical form, so it's fine; but integer PKs come back as `"42"` which must be cast consistently.

**Why it happens:** D2-01 chose string storage specifically to be lossless across PK types, but every read path must use the same stringification.

**How to avoid:** Centralize in `Accrue.Billing` context — `Accrue.Billing.owner_key(record)` returns `{billable_type, to_string(record.id)}` and every query goes through it. Never raw-SQL the `owner_id` column from application code.

**Warning signs:** Customer not found in one code path but found in another for the "same" user.

### Pitfall 6: `p99 <100ms` blown by telemetry handler doing sync work

**What goes wrong:** A `:telemetry.attach/4` handler for `[:accrue, :webhooks, :persist, :stop]` does something expensive (logs a full body, writes to a second DB, calls Sentry). Latency balloons from 5ms to 150ms.

**Why it happens:** Telemetry handlers run **synchronously** in the process that called `:telemetry.execute/3`. If that process is the webhook request, you've just made the user's on-call Sentry plugin part of your webhook SLA.

**How to avoid:**
- Documentation: telemetry handlers must be fast or fire async tasks
- In Accrue's own telemetry helper (`Accrue.Telemetry.span/4`), emit events with minimal measurements — no full body, no raw payload. Use handler `:telemetry_metrics` for aggregation.
- The Oban dispatch worker path is where heavy instrumentation belongs — it's async by construction.

**Warning signs:** Webhook p99 regresses after adding user telemetry handlers.

## Code Examples

### Customer schema (BILL-01)

```elixir
# lib/accrue/billing/customer.ex
defmodule Accrue.Billing.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_customers" do
    field :owner_type, :string
    field :owner_id, :string
    field :processor, :string              # "stripe" | "fake"
    field :processor_id, :string           # "cus_..." from Stripe
    field :data, :map, default: %{}        # jsonb cache of processor object
    field :metadata, :map, default: %{}    # Stripe-compatible flat map
    field :lock_version, :integer, default: 1

    timestamps(type: :utc_datetime_usec)
  end

  def ingest_changeset(customer \\ %__MODULE__{}, attrs) do
    customer
    |> cast(attrs, [:owner_type, :owner_id, :processor, :processor_id, :data, :metadata])
    |> validate_required([:owner_type, :owner_id, :processor])
    |> validate_metadata()
    |> optimistic_lock(:lock_version)
    |> unique_constraint([:owner_type, :owner_id, :processor])
  end

  def put_data_changeset(customer, new_data) do
    customer
    |> change(%{data: new_data})
    |> optimistic_lock(:lock_version)
  end

  def patch_data_changeset(customer, delta) do
    merged = Map.merge(customer.data || %{}, delta)
    put_data_changeset(customer, merged)
  end

  defp validate_metadata(changeset) do
    validate_change(changeset, :metadata, fn :metadata, meta ->
      case Accrue.Billing.Metadata.validate(meta) do
        :ok -> []
        {:error, reason} -> [metadata: reason]
      end
    end)
  end
end
```

### Migration (`accrue_customers`)

```elixir
defmodule Accrue.Repo.Migrations.CreateAccrueCustomers do
  use Ecto.Migration

  def change do
    create table(:accrue_customers, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :owner_type, :string, null: false
      add :owner_id, :string, null: false
      add :processor, :string, null: false
      add :processor_id, :string
      add :data, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}
      add :lock_version, :integer, null: false, default: 1

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accrue_customers, [:owner_type, :owner_id])
    create unique_index(:accrue_customers, [:owner_type, :owner_id, :processor])
    create index(:accrue_customers, [:processor, :processor_id])
  end
end
```

### Webhook event schema

```elixir
defmodule Accrue.Webhook.WebhookEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "accrue_webhook_events" do
    field :processor, :string
    field :processor_event_id, :string
    field :type, :string
    field :livemode, :boolean
    field :status, Ecto.Enum,
      values: [:received, :processing, :succeeded, :failed, :dead, :replayed],
      default: :received
    field :data, :binary               # raw body, bytea — see Open Question Q1
    field :signature_verified_at, :utc_datetime_usec
    field :received_at, :utc_datetime_usec
    field :attempts, :integer, default: 0
    field :last_error, :string

    timestamps(type: :utc_datetime_usec)
  end

  def ingest_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:processor, :processor_event_id, :type, :livemode, :status,
                    :data, :signature_verified_at, :received_at])
    |> validate_required([:processor, :processor_event_id, :type, :received_at])
    |> unique_constraint([:processor, :processor_event_id])
  end
end
```

```elixir
# Migration
create table(:accrue_webhook_events, primary_key: false) do
  add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
  add :processor, :string, null: false
  add :processor_event_id, :string, null: false
  add :type, :string, null: false
  add :livemode, :boolean, default: false
  add :status, :string, null: false, default: "received"
  add :data, :binary  # raw body bytes
  add :signature_verified_at, :utc_datetime_usec
  add :received_at, :utc_datetime_usec, null: false
  add :attempts, :integer, default: 0
  add :last_error, :text
  timestamps(type: :utc_datetime_usec)
end

create unique_index(:accrue_webhook_events, [:processor, :processor_event_id])
create index(:accrue_webhook_events, [:status, :inserted_at],
  where: "status IN ('failed', 'dead')",
  name: :accrue_webhook_events_failed_dead_idx)  # D2-36 partial index
```

### `%Accrue.Webhook.Event{}` struct (D2-29)

```elixir
defmodule Accrue.Webhook.Event do
  @moduledoc """
  Lean, handler-facing projection of a Stripe webhook event.

  Deliberately does NOT carry the raw payload — WH-10 requires handlers
  to re-fetch canonical state via `Accrue.Processor.fetch/1`. If the raw
  payload is needed for audit, it lives in `accrue_webhook_events.data`
  on the persisted row.
  """
  @enforce_keys [:type, :object_id, :livemode, :created_at]
  defstruct [:type, :object_id, :livemode, :created_at, :processor_event_id, :api_version]

  @type t :: %__MODULE__{
          type: atom(),           # :"customer.created"
          object_id: String.t(),  # "cus_..." — the nested data.object.id
          livemode: boolean(),
          created_at: DateTime.t(),
          processor_event_id: String.t(),
          api_version: String.t() | nil
        }

  def from_stripe(%{data: %{"id" => id, "type" => type} = raw}) do
    # Project the persisted row (accrue_webhook_events.data is the raw body)
    # via Jason.decode + shape.
    decoded = Jason.decode!(raw)
    %__MODULE__{
      type: String.to_existing_atom(decoded["type"]),
      object_id: decoded["data"]["object"]["id"],
      livemode: decoded["livemode"],
      created_at: DateTime.from_unix!(decoded["created"]),
      processor_event_id: decoded["id"],
      api_version: decoded["api_version"]
    }
  end
end
```

### Test helper: synthesize a signed Stripe event

```elixir
# test/support/webhook_fixtures.ex
defmodule Accrue.Test.WebhookFixtures do
  @doc """
  Produces a {body, header} tuple for a synthetic Stripe webhook event,
  signed with the test secret. Uses lattice_stripe's test signature
  generator (same code path as production verification).
  """
  def signed_customer_created(opts \\ []) do
    secret = Keyword.get(opts, :secret, "whsec_test_secret")
    id = Keyword.get(opts, :id, "evt_" <> Ecto.UUID.generate())

    body = Jason.encode!(%{
      id: id,
      object: "event",
      type: "customer.created",
      livemode: false,
      created: System.system_time(:second),
      data: %{object: %{id: "cus_" <> :crypto.strong_rand_bytes(8) |> Base.url_encode64()}}
    })

    header = LatticeStripe.Webhook.generate_test_signature(body, secret)
    {body, header}
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `stripity_stripe` webhook plug (pinned to 2019 API) | `lattice_stripe 0.2` `Webhook.construct_event!/4` | In-house, 2026-Q1 | Accrue wraps the newer one; all signature verification comes free |
| Hand-rolled `:crypto.mac` HMAC + `Plug.Crypto.secure_compare` | `LatticeStripe.Webhook` | 2026-Q1 | We specifically DO NOT write this code |
| `pg_uuidv7` Postgres extension for sortable UUIDs | `gen_random_uuid()` + `:utc_datetime_usec` timestamps | PG 13+ | Install-burden reduction; ordering is "good enough" for DLQ browse |
| Pre-Parsers raw-body plug | `Plug.Parsers` `body_reader:` hook | Plug 1.8+ (circa 2020) | Official pattern; documented; Cowboy/Bandit-portable |
| Pay-Rails fat-trait `Billable` concern | Thin macro injecting `has_one :where` + reflection | Elixir idiom | Matches `Ecto.Schema`, `Oban.Worker`, `Phoenix.Channel` conventions |
| `Oban.insert/2` inside `Repo.transaction/1` closure | `Oban.insert/3` Multi form | Oban 2.17+ | Cleaner composition with `Accrue.Events.record_multi/3` |

**Deprecated/outdated:**
- `stripity_stripe` webhook helpers — superseded by `lattice_stripe`
- `pg_uuidv7` — install overhead not worth marginal sortability gain
- SELECT-then-INSERT dedup — race-prone; use `on_conflict: :nothing`

## Environment Availability

This phase is code/config only — no new external CLI tools or services required. Phase 1 foundation (PostgreSQL 14+, Elixir 1.17+, OTP 27+) is assumed available.

| Dependency | Required By | Available in project | Notes |
|------------|-------------|----------------------|-------|
| PostgreSQL 14+ | `accrue_customers`, `accrue_webhook_events` | Phase 1 migrations run — assume yes | `gen_random_uuid()` in core; no extension install |
| Elixir 1.17+ / OTP 27+ | All code | Phase 1 confirmed | — |
| `:plug` 1.19+ | Webhook plug + body reader | **NOT YET in mix.exs** | **Add in Phase 2 Wave 0** |
| `:phoenix` 1.8+ | `Accrue.Router` macro + `@after_compile` route walk | **NOT YET in mix.exs** | **Add optional in Phase 2 Wave 0** |
| `:lattice_stripe` 0.2 | `Webhook.construct_event!/4`, `:idempotency_key`, `:stripe_version` | Yes (Phase 1) | Verified via source read |
| Oban worker infrastructure | Dispatch worker, cron pruner | Yes (Phase 1 added Oban migration) | Host supervises |

**Missing dependencies:**
- `:plug` — hard add, blocks nothing else
- `:phoenix` (optional) — hard add; compile-time conditional via `Code.ensure_loaded?(Phoenix.Router)` inside `Accrue.Router`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib) + `Oban.Testing` + `Mox 1.2` + `StreamData 1.3` |
| Config file | `accrue/test/test_helper.exs`, `accrue/config/test.exs` |
| Quick run command | `cd accrue && mix test --only phase_2` |
| Full suite command | `cd accrue && mix test.all` (alias in `mix.exs`: format check → credo strict → compile warnings-as-errors → test) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BILL-01 | Polymorphic Customer round-trip create/fetch via Fake processor | unit | `mix test test/accrue/billing/customer_test.exs` | Wave 0 |
| BILL-01 | Metadata validation (Stripe rules: 50 keys, 40 char, 500 char, no nesting, `""` deletes) | property (StreamData) | `mix test test/accrue/billing/metadata_test.exs` | Wave 0 |
| BILL-01 | `put_data/2` replaces fully; `patch_data/2` shallow-merges; deep-merge raises | unit | `mix test test/accrue/billing/customer_test.exs:data_ops` | Wave 0 |
| BILL-01 | `optimistic_lock` on concurrent writes raises `Ecto.StaleEntryError` | unit | `mix test test/accrue/billing/customer_test.exs:concurrency` | Wave 0 |
| BILL-02 | `use Accrue.Billable` on test schema injects `has_one :accrue_customer` with `:where` | unit | `mix test test/accrue/billable_test.exs` | Wave 0 |
| BILL-02 | `use Accrue.Billable, billable_type: "Member"` overrides default | unit | same | Wave 0 |
| PROC-04 | Same `{op, subject_id, operation_id}` → same idempotency key | unit + property | `mix test test/accrue/processor/stripe_test.exs:idempotency` | Wave 0 |
| PROC-04 | Missing seed → random UUID + `Logger.warning` captured | unit | same | Wave 0 |
| PROC-06 | `opts[:api_version]` > pdict > config precedence | unit | `mix test test/accrue/stripe_test.exs:api_version` | Wave 0 |
| PROC-06 | `with_api_version/2` push/pop via pdict | unit | same | Wave 0 |
| WH-01 | `body_reader` tees raw body into `conn.assigns[:raw_body]` | unit | `mix test test/accrue/webhook/caching_body_reader_test.exs` | Wave 0 |
| WH-01 | **Scoping test:** POST to `/webhooks/stripe` persists event, POST JSON to `/api/anything` still sees parsed `body_params` | integration | `mix test test/accrue/webhook/scoping_test.exs` | Wave 0 |
| WH-02 | Valid signed payload → 200 + event row | integration | `mix test test/accrue/webhook/plug_test.exs:happy_path` | Wave 0 |
| WH-02 | Tampered body → 400 + `Accrue.SignatureError` | integration | `mix test test/accrue/webhook/plug_test.exs:tampered` | Wave 0 |
| WH-02 | Multi-secret rotation: payload signed with secret[1] of 2 passes | integration | `mix test test/accrue/webhook/plug_test.exs:rotation` | Wave 0 |
| WH-03 | Duplicate POST of same `processor_event_id` → 200, no second row, no second job | integration | `mix test test/accrue/webhook/plug_test.exs:dedup` | Wave 0 |
| WH-04 | Oban retry with exponential backoff on handler failure | async (Oban.Testing) | `mix test test/accrue/webhook/dispatch_worker_test.exs:retry` | Wave 0 |
| WH-05 | 25 attempts exhausted → row status :dead | async | `mix test test/accrue/webhook/dispatch_worker_test.exs:dead_letter` | Wave 0 |
| WH-06 | User handler behaviour pattern-match on type; fallthrough does not crash | unit | `mix test test/accrue/webhook/handler_test.exs` | Wave 0 |
| WH-07 | Default handler reconciles `customer.created` via processor fetch | async | `mix test test/accrue/webhook/default_handler_test.exs` | Wave 0 |
| WH-10 | Default handler calls `Accrue.Processor.fetch_customer/1` — not trusting snapshot | async + Mox expect | same | Wave 0 |
| WH-11 | Pruner deletes `:succeeded` rows > `succeeded_retention_days` old | unit | `mix test test/accrue/webhook/pruner_test.exs` | Wave 0 |
| WH-12 | Webhook POST sync path measured < 100ms (soft assertion, skipped in CI matrix?) | integration + bench | `mix test test/accrue/webhook/latency_test.exs` (tag `:bench`) | Wave 0 |
| WH-14 | `Accrue.Webhook.Event.t()` typespec present + documented | dialyzer + docs | `mix dialyzer` + `mix docs` | existing |
| EVT-04 | Rollback test: insert webhook event → force transaction abort → both `accrue_webhook_events` AND `accrue_events` rows are absent | integration | `mix test test/accrue/webhook/plug_test.exs:atomic` | Wave 0 |
| TEST-09 | `Oban.Testing` integration — `assert_enqueued`, `perform_job` helpers | harness | `test/test_helper.exs` + `test/support/oban_case.ex` | Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/accrue/<slice>` for the touched module — typically < 5s
- **Per wave merge:** `mix test test/accrue/billing test/accrue/webhook test/accrue/processor` — full phase subset, ~15–30s
- **Phase gate:** `mix test.all` green across Elixir/OTP matrix before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/support/webhook_fixtures.ex` — `signed_customer_created/1`, `signed_event/2` helpers using `LatticeStripe.Webhook.generate_test_signature/3`
- [ ] `test/support/phoenix_test_router.ex` — a minimal router that imports `Accrue.Router`, defines the `:accrue_webhook_raw_body` pipeline, and mounts `/webhooks/stripe` + a second `/api/echo` route that returns `conn.body_params` so the scoping test can assert non-interference
- [ ] `test/support/oban_case.ex` — `use ExUnit.Case` + `use Oban.Testing, repo: Accrue.TestRepo` base case
- [ ] `test/support/billable_schemas.ex` — `AccrueTest.Schemas.User`, `AccrueTest.Schemas.Organization` fixtures that `use Accrue.Billable`
- [ ] `config/test.exs` additions: `config :accrue, :webhook_signing_secrets, %{stripe: ["whsec_test_secret"]}`, `config :accrue, :webhook_handlers, []`
- [ ] **Endpoint-less test harness:** since core accrue has no `Phoenix.Endpoint`, integration tests call the plug directly via `Phoenix.ConnTest.conn/3` + `MyRouter.call/2` — need `phoenix_live_view`-free ConnTest setup (just `Plug.Test` + `Phoenix.ConnTest` which are in phoenix's scope). Consider adding `{:phoenix, "~> 1.8", optional: true}` to test deps separately for the router harness.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | yes | Scoped raw-body plug; compile-time verification of pipeline shape (D2-17); plug-only request path (no controller surface area) |
| V2 Authentication | no | Webhook auth is signature-based, not session/token — see V11 |
| V3 Session Management | no | Webhooks are stateless |
| V4 Access Control | partial | Webhook plug has no user auth; routes must be public. Host-side access control not in scope. |
| V5 Input Validation | **yes** | `Plug.Parsers` JSON decode; metadata changeset rules (50/40/500); `length: 1_000_000` body cap (D2-21); Ecto changeset validation for all inputs |
| V6 Cryptography | **yes** | HMAC-SHA256 signature verification delegated to `LatticeStripe.Webhook` which uses `Plug.Crypto.secure_compare/2` (timing-safe). **Never hand-roll.** |
| V7 Error Handling / Logging | yes | `SignatureError → 400`; error contexts never include raw body or secrets; `Accrue.Error` hierarchy surfaces causes |
| V8 Data Protection | yes | Raw body stored in `accrue_webhook_events.data` — contains full Stripe event payload including `customer.email` and `charge.last4`. Retention via D2-34 cron. Consider field-level encryption post-v1.0 (flag in Open Questions). |
| V9 Communications | partial | TLS is host-endpoint responsibility |
| V10 Malicious Code | n/a | — |
| V11 Business Logic | **yes** | Webhook idempotency via DB unique constraint (WH-03); replay-attack protection via 300s timestamp tolerance in `LatticeStripe.Webhook`; out-of-order resolution deferred to WH-09 (Phase 3) |
| V12 Files/Resources | yes | 1MB body cap prevents slowloris-style DoS |
| V13 API | yes | Webhook is the public surface; signature is the auth control |
| V14 Configuration | yes | `webhook_signing_secrets` MUST come from runtime config (env var at release boot), never compile-time — per CLAUDE.md runtime-secrets rule |

### Known Threat Patterns for Phoenix/Plug/Stripe webhook stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Webhook replay attack (capture + re-POST) | Repudiation / Tampering | 300s timestamp tolerance in `LatticeStripe.Webhook.construct_event!/4` (default); DB-level unique constraint on `processor_event_id` dedupes even inside tolerance window |
| Tampered body with valid-looking signature header | Tampering | HMAC-SHA256 over raw body + `Plug.Crypto.secure_compare/2` timing-safe compare |
| Signature bypass via URL routing (attacker POSTs to wrong route with valid sig) | Spoofing | Each `processor` has its own secret (D2-16, Phase 4 D2-18); route path → processor atom → secret lookup |
| Secret leakage via logs | Information Disclosure | `Accrue.Telemetry` event measurements MUST exclude raw body, secrets, signature headers. Enforce via telemetry test: assert no secret substring in emitted metadata. |
| DoS via huge body | DoS | `length: 1_000_000` cap in pipeline (D2-21); `body_reader` opts propagate |
| DoS via slowloris/incomplete body | DoS | `read_body` opts; Bandit/Cowboy defaults apply |
| SQL injection via `owner_type`/`owner_id` | Tampering | `owner_type` is set by macro (developer-controlled, not user input); `owner_id` goes through Ecto cast → no raw SQL |
| Metadata injection (nested maps, giant values) | Tampering / DoS | D2-07 changeset rules enforced at write time; rejected with clear error |
| Timing side-channel on signature check | Information Disclosure | `Plug.Crypto.secure_compare/2` (already used by lattice_stripe) |
| Optimistic-lock race → torn write | Tampering | `Ecto.Changeset.optimistic_lock` on `lock_version` (D2-09) |
| User handler crash cascades to halt webhook processing | DoS / Elevation | Per-handler rescue in dispatch worker (D2-30); only default handler re-raises |
| Webhook event never processed (queue not running) | DoS / availability | Document queue requirement; Phase 8 boot check; status column projection visible to admin |

**Non-bypassable signature verification:** The signature check is inside `Accrue.Webhook.Plug.call/2` before any DB write. There is no `disable_signature_check: true` config option. Tests that need to inject unsigned events use `Accrue.Test.trigger_event/2` (Phase 8) which bypasses the HTTP path entirely and writes straight to `accrue_webhook_events` + enqueues — explicit test-only surface, not a production escape hatch.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Ecto.Multi.run` + branching on `row.id == nil` is the cleanest dedup-aware path | Pattern 3 | Moderate — fallback is preflight `SELECT`; both work, this is just idiom choice |
| A2 | Host apps will not generally have `Plug.Parsers` at the Endpoint level for `/webhooks/*` paths | Pitfall 1 | Moderate — mitigated by docs + D2-17 compile check + install guide |
| A3 | `:utc_datetime_usec` in timestamps is adequate for WH-09 out-of-order resolution (deferred to Phase 3) | Schema design | Low — Phase 3 can add a dedicated `stripe_created_at` column cheaply |
| A4 | `Accrue.Events.record_multi/3` from Phase 1 accepts a `:subject_fn` callable that receives Multi changes — need to verify signature matches | Pattern 3 | Low — worst case the Multi step is reshuffled; code change is local |
| A5 | `Accrue.Config.webhook_signing_secrets/1` is an acceptable new Phase 2 accessor that takes a processor atom and returns a list | Pattern 3 | Low — planner can name it anything |
| A6 | Storing raw webhook body as `bytea` (`:binary`) is preferable to `jsonb` — preserves byte-exactness for future re-verification / forensics | Schema | Low-moderate — jsonb is more queryable but round-trips may normalize; bytea is safer. Flag for planner decision. |
| A7 | Phase 2 dispatch worker's on-terminal-failure `:dead` transition can be implemented via Oban telemetry handler `[:oban, :job, :exception]` with `job.attempt == job.max_attempts` check | D2-35 | Low — alternative is `perform/1` rescue on every run with attempt check |
| A8 | `Ecto.Enum` string backing for `status` column (default) is fine; no need for Postgres ENUM type | D2-33 | Low — string is portable, ENUM requires separate migration |
| A9 | The `@after_compile` route walker (D2-17) can access `Phoenix.Router` internals stably across 1.8.x — verified by walking `module.__routes__/0` | Pattern 5 | Moderate — `__routes__/0` is documented but tests must exercise across Phoenix 1.8.x patch releases |
| A10 | Metadata round-trip through Stripe preserves field order and casing — shallow merge at Accrue side will match Stripe's store | D2-07 | Low — Stripe's contract is documented at https://stripe.com/docs/api/metadata |

**Decisions blocked on assumptions:** None block the plan from being written. A1, A6, and A9 are planner-visible decisions that should be resolved in the plan or during the first implementation task.

## Open Questions

1. **Q1: Raw body storage format — `bytea` vs `jsonb`?**
   - What we know: bytea preserves exact bytes (forensically correct, re-verifiable); jsonb is queryable and smaller when well-formed JSON normalizes.
   - What's unclear: whether admin UI (Phase 7) will want to query inside the payload (`WHERE data->>'type' = 'invoice.paid'`), which would argue for jsonb.
   - Recommendation: **Store as `bytea`** (column `:binary`). Forensic correctness wins for a billing library; the `type` and `object_id` are already indexed as first-class columns on the row. Phase 7 admin UI can parse on read.

2. **Q2: How does the dispatch worker mark `:dead` on terminal discard?**
   - What we know: Oban 2.21 emits `[:oban, :job, :exception]` with `attempt == max_attempts` at terminal failure; alternatively Oban worker `perform/1` can inspect `job.attempt` + `job.max_attempts`.
   - What's unclear: whether the transition should happen inside the worker's `perform/1` rescue (always executes, synchronous with worker failure) or in a telemetry handler (more decoupled, async-ish).
   - Recommendation: **In the worker's `perform/1` rescue**, checking `if job.attempt >= job.max_attempts, do: mark_dead(row)`. Keeps the logic colocated and testable.

3. **Q3: Does `Accrue.Events.record_multi/3` from Phase 1 accept a `:subject_fn` callback that reads from Multi changes, or does it require a fixed subject_id at call time?**
   - What we know: It's Multi-shaped (verified by grep) but exact signature needs reading.
   - What's unclear: Whether it's fine to use `Multi.run(:ledger, fn repo, changes -> Accrue.Events.record_multi(Multi.new(), :single, ...) |> Repo.transaction() end)`-style nesting, or whether there's a cleaner first-class composition.
   - Recommendation: Planner reads `lib/accrue/events.ex` at plan time and chooses the cleanest shape. If the API is awkward, add a `:subject_fn` opt in Phase 2.

4. **Q4: `owner_id_type: :string` default — what happens when a host app's `user.id` is a `Ecto.UUID` (binary) vs `:integer`?**
   - What we know: D2-01 chose string as the universal type; `to_string/1` works for both UUIDs (canonical form) and integers.
   - What's unclear: whether the injected `has_one :where [owner_type: "User"]` correctly filters when `customer.owner_id = "42"` and `user.id = 42` — Ecto's type-casting through `has_one` may or may not auto-cast.
   - Recommendation: Planner writes an integration test with BOTH a UUID-PK host schema AND an integer-PK host schema, asserting round-trip works in both. This is the canonical BILL-02 acceptance test.

5. **Q5: Does `Accrue.Router.accrue_webhook/2` need a `forward` or a full `post` route?**
   - What we know: D2-16 says `forward "/stripe", Accrue.Webhook.Plug`. `forward` plays nicely with path prefix matching; `post` would lock the method.
   - What's unclear: Stripe only POSTs, so a `post` route is tighter surface area (GET returns 404). But `forward` is what Oban Web and LiveDashboard use.
   - Recommendation: **Use `forward`** for consistency with precedent; the plug itself can match `conn.method == "POST"` and 405 otherwise.

6. **Q6: Should `Accrue.Config.webhook_signing_secrets` accept `{:system, "ENV_VAR"}`-style tuples or always resolve to a list at config time?**
   - What we know: Phase 1's `Accrue.Config` is NimbleOptions-validated at runtime via `config/runtime.exs`.
   - What's unclear: whether D2-24's transactional hot path can afford a `System.get_env` call per webhook.
   - Recommendation: Resolve at config-load time in `config/runtime.exs` to a plain list of strings. No env-var lookups inside the request path.

7. **Q7: Should `Accrue.Webhook.DefaultHandler` in Phase 2 handle ALL `customer.*` events (created/updated/deleted/card_updated/etc.) or just `customer.created`?**
   - Recommendation: **`customer.created`, `customer.updated`, `customer.deleted` at minimum** — these are the ones that round-trip via Fake processor tests. More elaborate `customer.source.*`, `customer.subscription.*`, etc. are deferred to Phase 3.

## Sources

### Primary (HIGH confidence)

- **`LatticeStripe.Webhook` source** — `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/webhook.ex` (315 lines read) — confirms multi-secret rotation, timing-safe compare, replay-tolerance, test signature helper, `Event.from_map/1` projection
- **`LatticeStripe.Client` source** — `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/client.ex` lines 154–262 — confirms `:idempotency_key` and `:stripe_version` opts are passthrough respected
- **`Plug.Parsers` official docs** — https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader — `CacheBodyReader` reference implementation
- **`Oban.insert/3` Multi-aware API** — https://hexdocs.pm/oban/Oban.html#insert/3 — confirmed signature
- **`Ecto.Schema.has_one/3` `:where` option** — https://hexdocs.pm/ecto/Ecto.Schema.html#has_one/3 — confirmed for Ecto 3.13.5
- **`Accrue/CLAUDE.md`** — tech stack pins + webhook constraints
- **`.planning/phases/02-schemas-webhook-plumbing/02-CONTEXT.md`** — 37 locked decisions
- **`.planning/REQUIREMENTS.md`** — phase requirement IDs + traceability
- **`.planning/ROADMAP.md`** — Phase 2 goal + success criteria
- **hex.pm public API** — version verification for `plug`, `phoenix`, `oban` (2026-04-12)

### Secondary (MEDIUM confidence)

- Pay (Rails) `webhook.rb` — pattern precedent for status-column ledger (from CONTEXT.md refs)
- Laravel Cashier `ManagesCustomer.php` — Stripe-as-source-of-truth metadata precedent
- Oban Web router — shape precedent for `accrue_webhook/2` macro
- Phoenix Channel `handle_in/3` — dispatch idiom precedent

### Tertiary (LOW confidence, flagged)

- Exact compatibility of `@after_compile` route walker across Phoenix 1.8.0–1.8.5 patch releases — recommend test harness in Wave 0 that touches `__routes__/0` across minor versions in CI

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — verified against shipping source of lattice_stripe 0.2 and hex.pm API; additions are well-known stable packages
- Architecture: **HIGH** — all patterns are canonical Plug/Ecto/Oban idioms with documented references
- Pitfalls: **HIGH** — raw-body scoping and `on_conflict: :nothing` gotchas are known from shipping Phoenix/Stripe integrations
- Decisions: **N/A — all 37 locked upstream in CONTEXT.md**

**Research date:** 2026-04-12
**Valid until:** 2026-05-12 (30 days for stable stack — plug/phoenix/oban/ecto all mature minors)

## RESEARCH COMPLETE

**Phase:** 2 — Schemas + Webhook Plumbing
**Confidence:** HIGH

### Key Findings

1. **`lattice_stripe 0.2` already ships complete webhook signature verification** with multi-secret rotation, timing-safe compare, replay protection, and a test-signature helper. Accrue wraps `LatticeStripe.Webhook.construct_event!/4` and remaps its error struct — no crypto code is written in Phase 2.
2. **Phase 2 must add two mix.exs deps:** `{:plug, "~> 1.19"}` as a hard dep and `{:phoenix, "~> 1.8", optional: true}` for the `Accrue.Router` macro. Plug itself is not currently in core deps — only `plug_crypto` is transitively pulled by lattice_stripe/phoenix_swoosh.
3. **`Plug.Parsers` `body_reader:` is the canonical raw-body hook** — ~10-line module, fully documented, no socket-drain footgun. The pre-Parsers plug approach D2-23 rejects is structurally broken because `read_body/2` drains the adapter buffer.
4. **`Oban.insert/3` has a Multi-aware arity** making D2-24's single-transaction (webhook row + Oban job + `Accrue.Events.record_multi/3` ledger) composable as one `Ecto.Multi` pipeline. Recommended over bare `Repo.transact/2`.
5. **`Ecto 3.13`'s `has_one :where` option** with constant-value filtering directly enables the D2-04 polymorphic `use Accrue.Billable` macro. One-line injection.
6. **The <100ms p99 budget is easily achievable** — the sync path is pure-CPU (HMAC verify, two INSERTs, one COMMIT). All handler/reconcile work is async via Oban.
7. **Raw body storage: recommend `bytea`** (not `jsonb`) for forensic byte-exactness; first-class columns (`type`, `processor_event_id`, `livemode`) are projected into their own indexed fields.
8. **Compile-time pipeline check (D2-17)** depends on `Phoenix.Router.__routes__/0`, which is documented but needs cross-patch-version CI coverage.

### File Created

`/Users/jon/projects/accrue/.planning/phases/02-schemas-webhook-plumbing/02-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Versions verified against hex.pm 2026-04-12; lattice_stripe capabilities verified by reading source |
| Architecture | HIGH | Every pattern has an official hexdocs reference or direct source verification |
| Pitfalls | HIGH | Documented real-world gotchas from Plug/Phoenix/Stripe integration ecosystem |
| Validation | HIGH | Test matrix maps every phase requirement to a concrete test file + command |
| Security | HIGH | ASVS mapping supports the non-bypassable signature + scoped pipeline design |

### Open Questions (carried into planning)

- Q1: Raw body storage `bytea` vs `jsonb` (recommended: bytea)
- Q2: `:dead` transition location (recommended: worker rescue)
- Q3: `Accrue.Events.record_multi/3` exact signature — planner to read
- Q4: Mixed host-PK integration test (UUID + integer) for BILL-02 acceptance
- Q5: `forward` vs `post` for webhook route (recommended: `forward`)
- Q6: Signing secrets resolution at runtime config load, not request path
- Q7: DefaultHandler Phase 2 event scope (recommended: `customer.created|updated|deleted`)

### Ready for Planning

Research complete. Every locked decision in CONTEXT.md has been verified buildable against the actual shipping surface of `lattice_stripe 0.2`, `plug 1.19`, `phoenix 1.8`, `ecto 3.13`, and `oban 2.21`. The planner can proceed directly to PLAN.md generation.
