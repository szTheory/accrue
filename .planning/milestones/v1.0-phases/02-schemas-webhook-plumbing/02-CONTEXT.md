# Phase 2: Schemas + Webhook Plumbing - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 delivers the **Billing schema layer + webhook ingestion pipeline**, driven end-to-end through `Accrue.Processor.Fake` with zero dependency on unreleased `lattice_stripe` 0.3:

- Polymorphic `Accrue.Billing.Customer` schema with `owner_type`/`owner_id`, `data` jsonb, `metadata` jsonb (Stripe-compatible)
- `use Accrue.Billable` macro — one-line install on any host schema (User, Organization, Team)
- `Accrue.Billing` context — round-trip create/fetch against the Fake processor
- `accrue_webhook_events` table with `UNIQUE(processor_event_id)` dedupe + `status` enum ledger
- `Accrue.Webhook.Plug` + `Accrue.Router` macro for scoped raw-body webhook ingestion
- Signature verification with multi-secret rotation (`Accrue.SignatureError` raises per Phase 1 D-08)
- Transactional persist + Oban enqueue via `Repo.transact/1`
- Webhook handler behaviour + default reconciliation handler + user handler chaining
- Deterministic idempotency keys for outbound Stripe calls
- Per-request Stripe API version override
- Accrue-owned cron pruner for webhook event retention (DLQ)

**Out of scope for Phase 2 (deferred to later phases):**
- Subscription lifecycle (Phase 3: trials, proration, cancellation, renewals)
- Dunning, retries, grace periods, coupons (Phase 4)
- Stripe Connect / multi-account webhook variants (Phase 4, WH-13)
- Email templates beyond `PaymentSucceeded` stub from Phase 1 (Phase 6)
- Admin UI LiveView for webhook event browser/replay (Phase 7)
- Any concrete `lattice_stripe` 0.3 Subscription/Invoice/Price calls — adapter stubs only

</domain>

<decisions>
## Implementation Decisions

### Customer Schema — Polymorphic owner_id

- **D2-01: `owner_id :string` (text column).** Lossless for UUIDs, bigint, ULIDs, and any future PK format host apps use. Indexed via `CREATE INDEX ON accrue_customers (owner_type, owner_id)`. Chosen over `:binary_id` because `mix phx.new` still defaults to integer PKs without `--binary-id`; shipping UUID-only would exclude ~40% of existing Phoenix hosts and violate CLAUDE.md's "zero breaking-change pain for v1.x" constraint. Precedent: `izelnakri/paper_trail`, Pay-Rails mixed-PK hosts. Performance cost at Accrue scale (thousands to low millions of customers/tenant) is unmeasurable.
- **D2-02: `owner_type :string` stores an explicit string identifier, not `__MODULE__` to_string.** Default resolution in the `Accrue.Billable` macro is `__MODULE__ |> Module.split() |> List.last()` (e.g. `"User"`), but host apps MUST be able to override via `use Accrue.Billable, billable_type: "User"` for rename-safety. Document loudly in ExDoc that changing the module name without pinning `billable_type:` requires a data migration on `accrue_customers.owner_type`.
- **D2-03: Post-v1.0 opt-in hook `Accrue.Config.owner_id_type` (default `:string`).** Leaves room for a performance-sensitive user to override the migration with a native `:binary_id` or `:bigint` column, without breaking the default. Not exposed publicly in v1.0 docs — just leaves the seam.

### `use Accrue.Billable` Macro Surface

- **D2-04: Hybrid macro — reflection + one association + one convenience function.** Injects exactly:
  1. `has_one :accrue_customer, Accrue.Billing.Customer, foreign_key: :owner_id, where: [owner_type: "User"]` using Ecto 3.1+'s `:where` assoc option (the `where:` value is interpolated at macro-expansion time from `billable_type:`). Preloads and joins work transparently; `user.accrue_customer` is first-class in tests and admin LiveView.
  2. `__accrue__(:billable_type)` reflection callback for Accrue-internal dispatch.
  3. One convenience: `customer(user)` delegating to `Accrue.Billing.customer/1` (lazy fetch-or-create). Pay's laziness is the right default; explicit creation is a footgun for new users.
- **D2-05: All write operations live in `Accrue.Billing` context, not on the host schema.** `Accrue.Billing.subscribe(user, plan)`, `Accrue.Billing.charge(user, amount, opts)`, `Accrue.Billing.invoices(user)`, etc. Matches Phoenix context conventions, mirrors `Ecto.Schema` + `Repo`, and keeps Phase 1 D-05's dual tuple + raise API coherent. Rejects Pay/Cashier's fat-trait pattern as a Rails/PHP idiom Elixir doesn't need — precedent: `Oban.Worker`, `Ecto.Schema`, `Phoenix.Controller` all keep ops in the framework module.
- **D2-06: `Accrue.Billing.customer/1` is lazy fetch-or-create.** First call auto-creates an `accrue_customers` row via the current processor (Fake by default), subsequent calls return the cached row. Explicit `Accrue.Billing.create_customer/1` is available but not required. Matches Pay's `payment_processor` laziness.

### Metadata + data jsonb Semantics

- **D2-07: `metadata` column is strict Stripe-compatible.** Flat `%{String.t() => String.t()}` only. Changeset enforces: ≤50 keys, keys ≤40 chars, values ≤500 chars, no nested maps (rejected at write time with clear error). Updates shallow-merge at the top level — `update_customer(c, metadata: %{"tier" => "pro"})` sets `"tier"`, preserves all other keys, `""`/`nil` deletes the key. Identical to `https://stripe.com/docs/api/metadata` contract byte-for-byte. Any developer who knows Stripe already knows Accrue.
- **D2-08: `data` column is processor-owned cache with TWO explicit operations.**
  - `Accrue.Billing.put_data(record, attrs)` — full replacement, used by webhook reconcile paths that receive the whole object (e.g. `customer.updated`)
  - `Accrue.Billing.patch_data(record, attrs)` — shallow merge, used when a partial event carries only a delta
  Splitting intent into two named functions beats overloading one function with a `merge:` flag — code reads itself, review can enforce one policy per call site.
- **D2-09: All metadata + data writes go through `Repo.transact/2` with `optimistic_lock` on a `lock_version` integer column.** Prevents torn writes when a user update and a webhook reconcile race on the same customer. Locking is Ecto-native, not Postgres row-lock — keeps it portable.
- **D2-10: Reject deep-merge entirely.** Recursive merge invents a contract Stripe doesn't have, can't round-trip through Stripe's API, and makes deletion semantics ambiguous. If a user wants nested state they can encode it in the `data` column and use `put_data`. Precedent: Pay and Cashier both treat Stripe as source of truth and do not deep-merge locally.

### Outbound Idempotency Keys (PROC-04)

- **D2-11: Seed-based deterministic idempotency keys.** `Accrue.Processor.Stripe` computes `"accr_" <> (Base.url_encode64(:crypto.hash(:sha256, "#{op}|#{subject_id}|#{seed}"), padding: false) |> binary_part(0, 22))` and passes it to `lattice_stripe` via its existing `:idempotency_key` request opt — overriding lattice_stripe's default random-UUID key generation. Rejects full-param canonicalization (Option A) because timestamps, Decimals, and map ordering are drift footguns; Stripe's own SDKs don't hash params either.
- **D2-12: Seed resolution chain:** `opts[:operation_id]` (explicit) > `Accrue.Actor.current_operation_id/0` (process dict, populated by Oban middleware + webhook plug, analogous to D-15 actor context) > fallback to random UUID + `Logger.warning(...)` in prod (so non-deterministic calls are observable). Webhook-triggered ops naturally seed from `processor_event_id`.
- **D2-13: `lattice_stripe`'s existing `{:idempotency_error, ...}` tuple handling is the escape hatch.** If the caller mutates params between retries (Stripe returns 409), Accrue surfaces it as `%Accrue.IdempotencyError{}` per Phase 1 D-06.

### Per-Request API Version Override (PROC-06)

- **D2-14: Three-level precedence: `opts[:api_version]` > `Process.get(:accrue_stripe_api_version)` > `Accrue.Config.stripe_api_version/0`.** Mirrors `Ecto.Repo`'s `put_dynamic_repo/1` precedence pattern verbatim — a Phoenix developer already knows this shape. Resolves to `lattice_stripe`'s existing `:stripe_version` request opt.
- **D2-15: Ship `Accrue.Stripe.with_api_version/2` helper for traffic-split rollouts.** `Accrue.Stripe.with_api_version("2026-03-25", fn -> Accrue.Billing.create_customer(...) end)` — pushes pdict value, runs function, pops. Plug-friendly for "sample 1% of requests" rollouts. Oban middleware propagates the pdict value across job boundaries (same mechanism as actor context D-15 requires).

### Webhook Route Mount Pattern

- **D2-16: `Accrue.Router` module + `accrue_webhook/2` macro, host-owned pipeline.** Matches unanimous Elixir precedent — Oban Web's `oban_dashboard`, LiveDashboard's `live_dashboard`, Pow's `pow_routes()`, Swoosh's mailbox preview all share this shape: host imports a router module, host owns `scope` + `pipe_through`, library owns the route-defining macro. Host code:
  ```elixir
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
  ```
  The macro expands to `forward "/stripe", Accrue.Webhook.Plug, processor: :stripe` plus any telemetry/logging wrappers.
- **D2-17: Compile-time footgun check via `@after_compile`.** `Accrue.Router` walks the router's routes at compile time and raises a clear error if any `accrue_webhook` forward sits under a pipeline that does NOT include `Accrue.Webhook.CachingBodyReader` in its `Plug.Parsers` `body_reader:` option. Turns the one real misconfiguration path into a compile error — gives us Option B's safety without inventing a non-idiomatic pattern.
- **D2-18: Multi-endpoint ready for Phase 4 Connect (WH-13).** The macro accepts a processor atom; calling `accrue_webhook "/stripe", :stripe` and `accrue_webhook "/connect", :stripe_connect` in the same scope works natively — each resolves to its own signing secret via `Accrue.Config`. Phase 2 ships single-endpoint but the shape is Connect-ready.

### Raw-Body Capture Strategy

- **D2-19: `Plug.Parsers` `body_reader:` hook — Plug's official pattern.** `Accrue.Webhook.CachingBodyReader.read_body/2` wraps `Plug.Conn.read_body/2`, tees iolist into `conn.assigns[:raw_body]`, returns `{:ok, body, conn}`. Documented in `Plug.Parsers` moduledoc (https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader), stable across Plug 1.16+, and is exactly what `stripity_stripe`'s webhook docs redirect users to.
- **D2-20: The `body_reader` lives only inside the `:accrue_webhook_raw_body` pipeline.** Host's global `Plug.Parsers` in `MyAppWeb.Endpoint` is untouched — satisfies WH-01 (scoped to webhook routes only) and Phase 2 success criterion #3 (mounting Accrue's plug doesn't affect streaming or body parsing on non-webhook routes). The success criterion test is a two-request assertion: POST signed fixture to `/webhooks/stripe`, assert 200 + event persisted; POST JSON to `/api/anything`, assert `conn.body_params != %{}`.
- **D2-21: Explicit `length: 1_000_000` (1MB) in the pipeline as defense-in-depth.** Stripe webhooks are ~2-10KB; the default 8MB is over-generous. Beats silent DoS on malformed huge bodies.
- **D2-22: Signature verification uses `IO.iodata_to_binary(conn.assigns.raw_body)`.** Avoids pre-flattening until verification time.
- **D2-23: Pre-Parsers custom plug approach is REJECTED as structurally broken.** Once `read_body/2` drains the socket the next call returns `{:ok, "", conn}`; any design that reads the body before `Plug.Parsers` must also inject it back, which collapses into D2-19 with extra steps.

### Webhook Transactional Persistence

- **D2-24: Request path runs `Repo.transact/2` containing: insert `accrue_webhook_events` row + `Oban.insert` the dispatch job + `Accrue.Events.record_multi/3` entry.** All three succeed atomically or none do (Phase 2 success criterion #4). Oban's Multi-aware insert is used natively — one transaction, three writes.
- **D2-25: `accrue_webhook_events.processor_event_id` is `UNIQUE`.** Duplicate POST of the same event ID hits `on_conflict: :nothing`, returns the existing row, skips the Oban enqueue, and returns 200 (Phase 2 success criterion #2). Webhook idempotency is DB-enforced.
- **D2-26: Webhook request path is plug-only.** No controller. Plug chain: CachingBodyReader → Jason decode (via Plug.Parsers) → `Accrue.Webhook.Plug` (verify sig, persist, enqueue, respond). Signature failure raises `Accrue.SignatureError` per Phase 1 D-08, translated to HTTP 400 by the plug's rescue.

### Webhook Handler Dispatch

- **D2-27: Single callback, atom type, pattern-match in function head.**
  ```elixir
  @callback handle_event(type :: atom(), event :: Accrue.Webhook.Event.t(), ctx :: map()) ::
              :ok | {:error, term()}
  ```
  This IS Elixir's dispatch idiom — Phoenix `handle_in/3`, Oban `perform/1`, GenServer `handle_info/2`, `handle_cast/2`. Users write `def handle_event(:"invoice.payment_failed", %{object_id: id}, _ctx), do: MyApp.Slack.notify(id)`.
- **D2-28: `use Accrue.Webhook.Handler` injects a fallthrough `def handle_event(_, _, _), do: :ok`.** Users never need to match every event type.
- **D2-29: `%Accrue.Webhook.Event{}` struct carries `type`, `object_id`, `livemode`, `created_at` — deliberately NOT the raw Stripe payload.** Forces WH-10 (re-fetch current state) compliance by shape. Handlers call `Accrue.Processor.fetch(event.object_id)` for canonical state. No footgun closure that tempts snapshot-trust.
- **D2-30: Chaining: default handler first (non-disableable, WH-07), then user handlers sequentially within the same Oban job.** Per-handler rescue: one user handler crash doesn't block the next. Each rescue emits `[:accrue, :webhooks, :handler, :exception]` with `module:` metadata. The whole job re-raises (so Oban retries) only if the DEFAULT handler crashes. User-handler crashes are logged but don't block Accrue's own state reconciliation from succeeding.
- **D2-31: Registration: `config :accrue, webhook_handlers: [MyApp.BillingHandler, MyApp.AnalyticsHandler]`.** List, ordered, Pay-style.
- **D2-32: REJECTED: module-per-event (Pay Ruby style), telemetry-only dispatch, struct-only dispatch, and fan-out-to-N-Oban-jobs.** Module-per-event is a Ruby autoload idiom. Telemetry-only fails discoverability (no `@callback` = no ExDoc entry) and violates telemetry's own guidance against heavy work in handlers. Fan-out creates ordering hazards (user handler reads stale state before default has reconciled).

### DLQ Representation + Retention

- **D2-33: Status column on `accrue_webhook_events`, not a separate DLQ table.**
  ```elixir
  field :status, Ecto.Enum, values: [:received, :processing, :succeeded, :failed, :dead, :replayed]
  ```
  The event row is the ledger, Oban jobs are ephemeral. One LiveView stream filtered by status gives the admin UI a clean single-table browser in Phase 7. Replay is a 2-op transaction: update `status: :received`, enqueue new Oban job.
- **D2-34: Accrue ships `Accrue.Webhooks.Pruner` as an Oban cron worker.** Forced because Oban 2.21 CE's `Plugins.Pruner` has a single `max_age` across completed/cancelled/discarded — per-state retention requires Oban Pro's `DynamicPruner`, which CLAUDE.md explicitly rules out for v1.0. Our worker deletes `:succeeded` rows older than `Accrue.Config.succeeded_retention_days` (default 14) and `:dead` rows older than `Accrue.Config.dead_retention_days` (default 90). `:infinity` opts out entirely. Cron schedule is host-wired; Accrue documents the recommended Oban cron entry in the install guide.
- **D2-35: The Oban dispatch worker marks the event `:dead` on final discard.** Uses `perform/1` rescue clauses + attempt count; on attempt == max_attempts and failure, transitions the event row from `:failed` to `:dead` in its own small transaction.
- **D2-36: `accrue_webhook_events` has a partial index `WHERE status IN (:failed, :dead)`.** Admin UI queries for failing events are cheap even at large row counts.
- **D2-37: Oban dead-letter is the retry mechanism; the status column is the Accrue-side projection.** Oban owns retry/backoff (WH-04 exponential backoff, 25 attempt default from WH-05). Accrue only projects Oban's terminal state onto the event row for admin observability and retention control.

### Claude's Discretion

The following are left to the Phase 2 planner / executor to decide:

- Exact Ecto schema module layout under `lib/accrue/billing/` (one file per schema or grouped)
- Migration filenames and ordering (just needs `accrue_customers`, `accrue_webhook_events`, indexes + CHECK constraints landed in the right order)
- Default `Accrue.Webhook.DefaultHandler` internals — which Stripe event types it reconciles in Phase 2 (at minimum `customer.*`; subscription reconciliation lands in Phase 3)
- Exact field list on `%Accrue.Webhook.Event{}` struct beyond the required `type`, `object_id`, `livemode`, `created_at`
- Internal Oban queue naming (CLAUDE.md suggests `accrue_webhooks: 10`)
- Whether `Accrue.Router` exposes `accrue_webhook/2` and `accrue_webhook/3` variants or just one with opts
- Exact shape of the Plug.Parsers `body_reader` tee (iolist cons vs binary concat) — just needs to produce `{:ok, body, conn}` correctly
- Test fixture organization for signed webhook payloads
- Where `Accrue.Billing.Customer.changeset/2` enforces metadata validation (inline function vs called helper)
- `lock_version` starting value and increment strategy — Ecto defaults are fine

### Folded Todos

None — no backlog items matched Phase 2.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project governance
- `/Users/jon/projects/accrue/CLAUDE.md` — tech stack pins (Elixir 1.17+, Ecto 3.13+, Oban 2.21 CE, `lattice_stripe ~> 0.2`), Oban CE vs Pro constraint (no `DynamicPruner`), monorepo layout
- `/Users/jon/projects/accrue/.planning/PROJECT.md` — vision, zero-breaking-change-pain constraint
- `/Users/jon/projects/accrue/.planning/REQUIREMENTS.md` — Phase 2 requirement IDs: BILL-01, BILL-02, PROC-04, PROC-06, WH-01..07, WH-10..12, WH-14, EVT-04, TEST-09
- `/Users/jon/projects/accrue/.planning/ROADMAP.md` — Phase 2 goal, success criteria, depends-on Phase 1
- `/Users/jon/projects/accrue/.planning/phases/01-foundations/01-CONTEXT.md` — Phase 1 locked decisions (D-01..45) that Phase 2 builds on: dual API (D-05), error structs (D-06), SignatureError raises (D-08), Events.record_multi (D-13), actor pdict (D-15), telemetry depth (D-17), Fake processor (D-19), Processor.Stripe facade (D-07)

### External library docs (fetch via Context7 or WebFetch at plan time)
- `Plug.Parsers` `body_reader` custom-body-reader docs — https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader — the canonical raw-body tee pattern (D2-19). Stable across Plug 1.16+, current 1.19.1.
- `Ecto.Schema` `has_one :where` assoc option — https://hexdocs.pm/ecto/Ecto.Schema.html#has_one/3 — Ecto 3.1+ polymorphic `has_one` mechanism used by `use Accrue.Billable` (D2-04)
- `Ecto.Repo.transact/2` — https://hexdocs.pm/ecto/Ecto.Repo.html#c:transact/2 — used by webhook persist+enqueue (D2-24) and metadata optimistic-lock writes (D2-09)
- `Ecto.Changeset` `optimistic_lock/2` — https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/2 — used for `lock_version` on Customer writes (D2-09)
- `Ecto.Enum` — https://hexdocs.pm/ecto/Ecto.Enum.html — status column on `accrue_webhook_events` (D2-33)
- `Oban` Multi-aware insert — https://hexdocs.pm/oban/Oban.html#insert/3 — transactional job enqueue (D2-24)
- `Oban.Cron` — https://hexdocs.pm/oban/Oban.Plugins.Cron.html — host-wired schedule for `Accrue.Webhooks.Pruner` (D2-34)
- `Oban.Plugins.Pruner` — https://hexdocs.pm/oban/Oban.Plugins.Pruner.html — CE single-`max_age` limitation that forces D2-34 to exist
- `:telemetry.span/3` — https://hexdocs.pm/telemetry/ — handler invocation wrapping (D2-30)
- `Phoenix.Router` `forward/3` + `pipeline/2` — https://hexdocs.pm/phoenix/Phoenix.Router.html — primitive the `accrue_webhook` macro expands to (D2-16)
- `Jason` — https://hexdocs.pm/jason — JSON decoder for Plug.Parsers pipeline (D2-19)
- `lattice_stripe ~> 0.2` — sibling lib, source at `/Users/jon/projects/lattice_stripe/` (or `/Users/jon/getfluent/lattice_stripe/`). Specifically:
  - `lib/lattice_stripe/client.ex` — current default idempotency key generation (`idk_ltc_<uuid4>`) that Accrue must override (D2-11)
  - `lib/lattice_stripe.ex` — `:stripe_version` per-request opt (D2-14)
  - `guides/error-handling.md` — `{:idempotency_error, ...}` tuple shape (D2-13)

### Router-library precedent (shape `Accrue.Router` after these)
- Oban Web router — https://github.com/oban-bg/oban_web/blob/main/lib/oban/web/router.ex — `oban_dashboard` macro, host-owned pipeline pattern
- LiveDashboard — `live_dashboard` macro inside host `scope` + `pipe_through`
- Pow — `Pow.Phoenix.Router` + `pow_routes()` macro
- Plug.Swoosh.MailboxPreview — bare `forward` precedent for the simpler case

### Prior art (consult for API shape, NOT for code copying)
- Pay (Rails) — https://github.com/pay-rails/pay
  - `app/models/pay/webhook.rb` — webhook event ledger pattern (D2-33 model)
  - `lib/pay/webhooks.rb` — event configuration / delegator pattern (precedent reviewed and rejected for D2-27 in favor of Elixir-native pattern matching)
  - `app/models/concerns/pay/billable.rb` — billable surface (reviewed and rejected for D2-04 in favor of thin-macro idiom)
- Laravel Cashier — https://github.com/laravel/cashier-stripe
  - `src/Concerns/ManagesCustomer.php::syncStripeCustomerDetails` — Stripe-as-source-of-truth metadata precedent (D2-07, D2-10)
  - `webhook_calls` table pattern via `spatie/laravel-webhook-client` — status-column precedent (D2-33)
- `stripity_stripe` — webhook `construct_event/4` docs explicitly redirect to `Plug.Parsers` `body_reader` pattern (D2-19)

### Stripe spec references
- Stripe API metadata contract — https://stripe.com/docs/api/metadata — flat string/string, 50 keys, 40-char keys, 500-char values, `""` deletes, unset preserves (D2-07)
- Stripe idempotency key docs — https://stripe.com/docs/api/idempotent_requests — retry semantics (D2-11)
- Stripe API versioning — https://stripe.com/docs/api/versioning — per-request `Stripe-Version` header (D2-14)

### Elixir dispatch-idiom precedent (shape `Accrue.Webhook.Handler` after these)
- `Oban.Worker` `perform/1` — https://hexdocs.pm/oban/Oban.Worker.html — pattern-match in function head idiom (D2-27)
- `Phoenix.Channel` `handle_in/3` — https://hexdocs.pm/phoenix/Phoenix.Channel.html — atom + payload dispatch (D2-27)
- GenServer `handle_info/2`, `handle_cast/2` — core OTP dispatch idiom

### Polymorphic-association precedent
- `izelnakri/paper_trail` — https://github.com/izelnakri/paper_trail — `item_type/item_id` with string column (D2-01)
- Ecto polymorphic associations guide — https://hexdocs.pm/ecto/polymorphic-associations-with-many-to-many.html — Ecto's official stance and the `:where` option

</canonical_refs>

<code_context>
## Existing Code Insights

**Greenfield project** — Phase 2 builds directly on Phase 1's first commit. At the start of Phase 2 the codebase contains:

### Reusable Assets (all shipped in Phase 1)
- `Accrue.Money` + `Accrue.Ecto.Money` — money value type for `Invoice` schemas in Phase 3+; not directly used in Phase 2
- `Accrue.Error.*` hierarchy — `%Accrue.SignatureError{}`, `%Accrue.IdempotencyError{}`, `%Accrue.ConfigError{}`, `%Accrue.APIError{}` are direct Phase 2 consumers (D2-13, D2-26)
- `Accrue.Events.record/1` + `Accrue.Events.record_multi/3` — used by the webhook persist transaction (D2-24) and by every `Accrue.Billing.*` write to satisfy EVT-04
- `Accrue.Processor` behaviour + `Accrue.Processor.Fake` — primary test surface for Phase 2. Every test in Phase 2 runs against Fake; no real Stripe calls.
- `Accrue.Processor.Stripe` adapter — the ONE place that knows about `lattice_stripe`. Phase 2 extends it with deterministic idempotency-key computation (D2-11) and `:stripe_version` passthrough (D2-14).
- `Accrue.Actor` process-dict context — webhook plug pushes `actor: :webhook` + `operation_id: processor_event_id` (D2-12)
- `Accrue.Config` NimbleOptions schema — Phase 2 adds `:succeeded_retention_days`, `:dead_retention_days`, `:stripe_api_version`, (hidden) `:owner_id_type`
- `Accrue.Telemetry` — Phase 2 adds `[:accrue, :webhooks, :receive|:verify|:persist|:enqueue|:handler]` spans with D-17-compliant naming

### Established Patterns (locked by Phase 1)
- Dual tuple + raise API on every public function (D-05)
- Ecto 3.13 `Repo.transact/2` for all multi-step state mutations
- Behaviour + Default Adapter + Test Adapter pattern (Processor, Mailer, PDF, Auth) — Phase 2 extends this pattern to `Accrue.Webhook.Handler`
- Conditional compile for optional deps (Sigra pattern, CLAUDE.md §conditional-compile) — Phase 2 does NOT introduce new optional deps
- Events.record_multi/3 wrapping every state mutation (D-13, satisfies EVT-04)
- Telemetry span/3 wrapping every public function (D-17)

### Integration Points
- **Host router** — user calls `import Accrue.Router` + `accrue_webhook/2` inside a host-owned `:accrue_webhook_raw_body` pipeline (D2-16)
- **Host `MyApp.Repo`** — Accrue uses it via `config :accrue, :repo, MyApp.Repo`; does not supervise
- **Host Oban instance** — Accrue enqueues to host's Oban with queue `:accrue_webhooks` (CLAUDE.md recommendation); host starts Oban in their supervision tree
- **Host `MyApp.Endpoint`** — remains untouched. Global `Plug.Parsers` in endpoint is preserved; the webhook-scoped `Plug.Parsers` with `body_reader:` only runs inside Accrue's pipeline (D2-20, Phase 2 success criterion #3)

</code_context>

<specifics>
## Specific Ideas

- **`Ecto.Repo.put_dynamic_repo/1` precedence is the specific model for D2-14** (opt > pdict > config default).
- **`izelnakri/paper_trail`'s `item_type/item_id` string column is the specific model for D2-01** — lossless across host PK types without install-time configuration.
- **`Plug.Parsers` moduledoc `CacheBodyReader` example is the reference implementation for `Accrue.Webhook.CachingBodyReader`** (D2-19).
- **Oban Web's router macro shape is the specific model for `Accrue.Router.accrue_webhook/2`** (D2-16).
- **Phoenix channel `handle_in/3` pattern-match style is the specific model for `Accrue.Webhook.Handler.handle_event/3`** (D2-27).
- **Stripe's own metadata update contract is the specific model for D2-07** (byte-for-byte — a developer who knows Stripe already knows Accrue).

</specifics>

<deferred>
## Deferred Ideas

These came up during discussion but belong in later phases:

- **Stripe Connect multi-endpoint webhook variants with per-account signing secrets** (WH-13) — Phase 4. D2-18 leaves the macro shape ready; a second `accrue_webhook/2` call in the same scope "just works" when Connect lands.
- **Subscription lifecycle reconciliation inside `Accrue.Webhook.DefaultHandler`** — Phase 3. Phase 2's default handler only reconciles `customer.*` events; `customer.subscription.*` events require Phase 3's schema.
- **Admin LiveView webhook browser with replay button** — Phase 7 (`accrue_admin`). Phase 2 ships the status-column ledger and replay transaction shape, Phase 7 puts a UI on it.
- **`mix accrue.gen.webhook_handler` Mix task** — nice-to-have scaffolding for a new `MyApp.BillingHandler` module; Phase 8 (install + polish).
- **Opting out of DLQ entirely via `config :accrue, dead_retention_days: :infinity`** — documented behavior but Admin UI affordance (visible "retention: disabled" badge) is Phase 7.
- **Native `:binary_id` or `:bigint` `owner_id_type` override** — seam exists in `Accrue.Config` from Phase 2 (D2-03) but not publicly documented until a real user needs it.
- **Host-supplied canonical-param idempotency hashing** — rejected for Phase 2 (D2-11 Option A) but documented in RESEARCH.md as a considered-and-rejected alternative.

</deferred>

---

*Phase: 02-schemas-webhook-plumbing*
*Context gathered: 2026-04-12*
