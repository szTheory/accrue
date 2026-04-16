# Phase 4: Advanced Billing + Webhook Hardening - Research

**Researched:** 2026-04-14
**Domain:** Stripe advanced billing (metered, schedules, coupons, checkout/portal) + webhook pipeline hardening (DLQ/replay, upcasters, event query API) for Accrue (Elixir/Phoenix billing library)
**Confidence:** HIGH (stack, lattice_stripe integration shape, Stripe API surface — all verified against the sibling repo and canonical docs; all architectural decisions are already locked in CONTEXT.md D4-01..D4-04)

## Summary

Phase 4 is the largest and most heterogeneous phase in Accrue's roadmap: it closes the long tail of subscription billing on top of Phase 3's lifecycle primitives, then hardens the webhook pipeline with DLQ/replay, upcasters, and an event query API. All four pivotal architectural questions were settled before research started — the gap research goal was NOT to pick designs, but to (a) verify `lattice_stripe 1.1`'s API surface for the features Phase 4 consumes, (b) map Stripe semantics to Accrue's projection/idempotency/telemetry patterns, and (c) inventory the 22 requirements into a plan-ready work breakdown.

Every decision in `04-CONTEXT.md` has been cross-checked against the sibling `lattice_stripe` source on disk and Stripe's official docs. The implementation path is clear: consume `lattice_stripe 1.1` via `path:` dep during dev, add five schemas (`accrue_meter_events`, `accrue_subscription_schedules`, `accrue_promotion_codes`, plus three new columns on `accrue_subscriptions` and two on `accrue_invoices`), ship `Accrue.Webhooks.DLQ` + Mix tasks, wire the upcaster chain registry, add query API on top of `accrue_events`, and publish three observability modules.

**Primary recommendation:** Structure Phase 4 as **seven plans** grouped by cohesive surface area, not by requirement ID — each plan closes a behavior the host app can exercise end-to-end against the Fake processor. Lock the `lattice_stripe 1.1` bump as Wave 0 of Plan 04-01 so every subsequent wave compiles against the real API surface. Do NOT attempt parallel execution across DLQ / Checkout / Schedules — they share `accrue_webhook_events` + `accrue_events` write paths and the coordination cost exceeds the wall-clock savings.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D4-01: lattice_stripe gap strategy (BILL-13 + CHKT-02) — the gap is already closed.** Cut `lattice_stripe 1.1` now and consume it normally — zero in-tree Stripe shims. Phase 20 (Metering: `Billing.Meter`, `MeterEvent`, `MeterEventAdjustment`) and Phase 21 (`BillingPortal.Session` with FlowData guards) are code-complete on `lattice_stripe main`. In Accrue Phase 4 dev, consume via `{:lattice_stripe, path: "../lattice_stripe"}`; flip to `{:lattice_stripe, "~> 1.1"}` before Phase 4 merges. Bump `CLAUDE.md` constraint from `~> 1.0` to `~> 1.1`. `BillingPortal.Configuration` is deferred to `lattice_stripe 1.2` — Accrue treats portal configuration as Dashboard-managed (matches Pay/Cashier convention); `Accrue.BillingPortal.Session.create/2` accepts an optional `configuration: "bpc_..."` ID.

**D4-02: Dunning retry policy (BILL-15) = hybrid** — Stripe Smart Retries owns the cadence; Accrue owns a thin grace-period overlay that transitions `past_due → unpaid` (or `canceled`) by calling the Stripe API, so D2-29 canonicality holds. Config via `config :accrue, :dunning, mode:, grace_days:, terminal_action:, telemetry_prefix:`. `Accrue.Billing.Dunning.SweeperJob` Oban cron queries `subscriptions where status = :past_due AND past_due_since < now() - grace_days AND dunning_sweep_attempted_at IS NULL`, calls `LatticeStripe.Subscription.update(id, status: "unpaid")`, stamps sweep attempt, writes `dunning.terminal_action_requested` event. Does NOT touch local status — Stripe webhook flips the row via the standard `customer.subscription.updated` path. Telemetry `[:accrue, :ops, :dunning_exhaustion]` fires inside the handler's `Repo.transact/2`. **New columns:** `accrue_subscriptions.past_due_since :utc_datetime_usec` and `dunning_sweep_attempted_at :utc_datetime_usec`. `past_due_since` is sourced from `invoice.payment_failed.next_payment_attempt` and bumped forward on each retry — grace window is "N days after Stripe *stops* retrying," not "N days after first failure."

**D4-03: Metered usage write path (BILL-13) = synchronous pass-through** via `Accrue.Billing.report_usage/3` with a transactional-outbox audit table and a small reconciliation Oban worker. Defer buffering to v1.1 as additive `report_usage_async/3`. Signature mirrors Cashier's `reportUsage($quantity, $timestamp)`. Returns plain `{:ok, %MeterEvent{}}` / `{:error, term()}` — does NOT use `intent_result/1` (per D3-07/D3-12 — meter reporting is not SCA-capable). Schema `accrue_meter_events` is audit ledger + implicit outbox with partial index on `failed` rows (free DLQ view). Control flow: `Repo.transact/2` inserts `pending` row + `Events.record_multi(:meter_event_reported)` → commit → call `Accrue.Processor.report_meter_event(row)` OUTSIDE the txn → update row `reported` or `failed`. Idempotency key = `"accrue_mev_#{operation_id}_#{event_name}_#{phash2}"` (uses Phase 3 `operation_id` pdict). `ReconcilerJob` every minute retries `pending AND inserted_at < now() - '60 seconds'` with LIMIT 1000.

**D4-04: DLQ + replay UX (WH-08) = `Accrue.Webhooks.DLQ` library module + thin Mix task wrappers.** Structural necessity: `Oban.retry_job/2` refuses `:discarded`/`:cancelled`, so DLQ replay MUST insert a fresh job. Ecosystem precedent: `Ecto.Migrator` + `mix ecto.migrate`. Public API: `requeue/1`, `requeue!/1`, `requeue_where/2` (filter + `batch_size`, `stagger_ms`, `dry_run`, `force`), `list/2`, `count/1`, `prune/1`. Bulk cap = `dlq_replay_max_rows` (default 10_000) unless `force: true`. Replay-death-loop prevention: `{:error, :not_found}` from `Processor.fetch/1` → terminal-skip (Stripe object deleted). Mix tasks: `mix accrue.webhooks.replay [--since | --type | --dry-run | --all-dead | --yes]`, `mix accrue.webhooks.prune`. `Accrue.Webhooks.Pruner` Oban worker finalized here (D2-34 locked shape). Telemetry namespace `[:accrue, :ops, :webhook_dlq, :dead_lettered | :replay | :prune]`. Config extensions: `:dead_retention_days` (90), `:succeeded_retention_days` (14), `:dlq_replay_batch_size` (100), `:dlq_replay_stagger_ms` (1_000), `:dlq_replay_max_rows` (10_000).

### Claude's Discretion

- **Coupon/Discount projection depth (BILL-27/28).** Default: thin passthrough + webhook-driven denormalization of fields the admin LV filters/sorts on, following D3-14/D3-15 invoice projection pattern. Full Stripe mirror is NOT a goal. Discount composition at sub/invoice/checkout levels mirrors Stripe's `discount` + `total_discount_amounts` fields — don't reinvent the math.
- **Upcaster registration pattern (EVT-05).** Default: module-per-version behaviour (`Accrue.Events.Upcasters.V1ToV2` implementing `@behaviour Accrue.Events.Upcaster` with `upcast/1` callback), dispatched by `schema_version`. Chains compose via a version table in `Accrue.Events.UpcasterRegistry`. No macro DSL.
- **Ops telemetry event set (OBS-03).** Roadmap names `[:accrue, :ops, :revenue_loss | :webhook_dlq | :dunning_exhaustion | :incomplete_expired]`. Also in-scope: `[:accrue, :ops, :webhook_dlq, :replay | :prune]` (D4-04), `[:accrue, :ops, :meter_reporting_failed]` (D4-03), `[:accrue, :ops, :charge_failed]`. Default `Telemetry.Metrics` recipe ships counters + spans — no distributions/summaries (host-choice).
- **Subscription Schedules (BILL-16) modeling.** Default: pure Stripe passthrough stored as `data` jsonb + typed columns only for admin LV needs (current phase index, phases count, next phase timestamp). No dedicated child table in Phase 4.
- **Multi-endpoint webhook secret lookup (WH-13).** Default: `config :accrue, :webhook_endpoints, [primary: [secret: ...], connect: [secret: ..., mode: :connect]]`; plug selects by route param or path suffix. Connect variant uses a different signing secret — same verification path.
- **Embedded vs hosted Checkout mode (CHKT-02).** Default: single `Accrue.Checkout.Session.create/2` with `mode: :hosted | :embedded`. Returns `%Session{}` struct containing `client_secret` for embedded OR `url` for hosted.
- **Checkout success URL reconciliation (CHKT-06).** Default: `Accrue.Checkout.reconcile/1` takes `checkout_session_id`, re-fetches from Stripe (D2-29), ensures local state matches. Host app calls from success URL controller. No cookie/session magic.

### Deferred Ideas (OUT OF SCOPE)

- `BillingPortal.Configuration` programmatic support → `lattice_stripe 1.2` + additive Accrue 1.x patch.
- `Accrue.Billing.report_usage_async/3` or built-in buffering → Accrue 1.1, additive.
- Stripe MeterEventStream v2 (>1k eps high-volume path) → deferred indefinitely.
- Full local mirror of Stripe Coupon/PromotionCode fields → deferred; Phase 4 denormalizes only what Phase 7 admin LV filters/sorts on.
- `accrue_subscription_schedule_phases` child table → deferred to v1.x if needed.
- Macro DSL for upcaster registration → rejected.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **BILL-11** | Pause/resume with `pause_behavior` | `LatticeStripe.Subscription.update/4` accepts `pause_collection: %{behavior: "mark_uncollectible" \| "keep_as_draft" \| "void"}` (Stripe's three pause modes). Already plumbed through `lattice_stripe 1.0`. Wire via `Accrue.Billing.Subscription.pause/2` + `resume/2` in Phase 3 is `nil`-safe; Phase 4 adds `:pause_behavior` option + `:resumes_at` schedule. New subscription column: `paused_at :utc_datetime_usec`, `pause_behavior :string`. Webhook path: `customer.subscription.paused` / `.resumed`. |
| **BILL-12** | Multi-item subscriptions | `LatticeStripe.SubscriptionItem.create/update/delete/list` — already in 1.0. Stripe `items[]` on sub create; individual item mutations via SubscriptionItem endpoints. Accrue already has `Accrue.Billing.SubscriptionItem` schema (Phase 2 D2-xx). Phase 4 promotes it to a first-class surface: `Accrue.Billing.add_item/3`, `remove_item/2`, `update_item_quantity/3`. Projection already denormalizes `price_id`, `quantity`, `plan_id`. Proration mandatory per D-05 (`:proration` option explicit, never silent). |
| **BILL-13** | Metered billing | `LatticeStripe.Billing.Meter.create/3` (define once), `LatticeStripe.Billing.MeterEvent.create/3` (hot path, fire-and-forget). Confirmed in `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing/meter.ex` and `meter_event.ex`. Two-layer idempotency (body `identifier` + HTTP `idempotency_key:` opt) documented in `guides/metering.md`. `v1.billing.meter.error_report_triggered` webhook handles async failures. D4-03 locked: sync pass-through + outbox reconciler. |
| **BILL-14** | Free/comped subscriptions | Stripe idiom: `collection_method: "send_invoice"` + 100%-off coupon, OR `trial_end: "now" + 100 years` + `default_payment_method: nil`. Recommended path: **100%-off coupon** (re-uses discount infra from BILL-27/28, preserves invoice history, no fake trial). Accrue exposes `Accrue.Billing.comp_subscription/2` that applies a pre-created "comp_100_forever" coupon. Skips payment method requirement guard. |
| **BILL-15** | Dunning / grace → `past_due → unpaid` | D4-02 locked. `LatticeStripe.Subscription.update/4` with `status: "unpaid"` or `cancel/3`. Oban cron SweeperJob. Columns: `past_due_since`, `dunning_sweep_attempted_at`. Telemetry `[:accrue, :ops, :dunning_exhaustion]`. |
| **BILL-16** | Subscription Schedules | `LatticeStripe.SubscriptionSchedule.{create, retrieve, update, cancel, release}/3-4` + nested `SubscriptionSchedule.Phase`, `CurrentPhase`, `PhaseItem` structs. Two creation modes: `from_subscription` OR `customer + phases`. `end_behavior: "release" \| "cancel"`. Webhooks: `subscription_schedule.{created,updated,released,completed,canceled,expiring}`. **Schema:** new `accrue_subscription_schedules` table (thin projection per Discretion default) — columns: `id, stripe_id (unique), customer_id, subscription_id, status, current_phase_index, phases_count, next_phase_at, released_at, canceled_at, data :jsonb, timestamps`. Link to `accrue_subscriptions` via `subscription_id`. Phase transitions detected by diffing `current_phase.start_date` across webhook deliveries. |
| **BILL-27** | `Accrue.Billing.Coupon` + `PromotionCode` | `LatticeStripe.Coupon.{create, retrieve, update, delete, list}/3` + `LatticeStripe.PromotionCode.{create, retrieve, update, list}/3` — both in 1.0. Phase 3 D3-16 shipped minimal `accrue_coupons` schema (passthrough, no expansion). Phase 4 adds: `accrue_promotion_codes` table (passthrough: `code, coupon_id, active, max_redemptions, times_redeemed, expires_at, data`), unique index on `code`. `Accrue.Billing.Coupon.create/2` + `PromotionCode.create/2` thin wrappers. Customer-facing apply: `Accrue.Billing.apply_promotion_code(subscription, code)` calls `Subscription.update(sub_id, coupon: coupon_id)`. |
| **BILL-28** | Discount application at sub/invoice/checkout | Stripe composes discounts automatically — Accrue MIRRORS, never computes. Add columns to `accrue_invoices`: `discount_minor :integer`, `total_discount_amounts :jsonb` (Stripe's line-item breakdown). Add to `accrue_subscriptions`: `discount_id :string` (FK to coupon, nullable). Sources: `invoice.discounts[]`, `subscription.discount`, `checkout_session.discounts[]`. Denormalization happens in webhook handlers via `Accrue.Billing.Invoice.force_discount_changeset/2` (mirrors D3-17 force-path pattern). |
| **CHKT-01** | `Accrue.Checkout.Session.create/retrieve` | `LatticeStripe.Checkout.Session.{create, retrieve, expire, list_line_items, stream!}/3-4`. Verified in `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/checkout/session.ex`. `mode` is required — pre-network `ArgumentError` if missing. Accrue wraps with defaults: `mode: :subscription`, `payment_method_types: ["card"]`, `customer_creation: "if_required"`, success/cancel URLs from config. |
| **CHKT-02** | Embedded + hosted Checkout modes | Stripe param `ui_mode: "hosted" \| "embedded"`. Hosted → returns `url` for redirect. Embedded → returns `client_secret` for `<stripe-checkout>` element client-side. Accrue's `mode: :hosted \| :embedded` option maps to `ui_mode`. Struct returned has both fields populated (one is `nil` depending on mode). |
| **CHKT-03** | Line-item helpers | `LatticeStripe.Checkout.LineItem` struct exists. Accrue helper `Accrue.Checkout.LineItem.from_price(price_id, quantity)` → `%{"price" => price_id, "quantity" => quantity}`. Also `from_price_data/1` for ad-hoc one-time prices. |
| **CHKT-04** | `Accrue.BillingPortal.Session.create` | `LatticeStripe.BillingPortal.Session.create/3` verified. Required param: `customer`. Optional: `return_url`, `flow_data`, `configuration` (`bpc_*`), `locale`, `on_behalf_of`. FlowData guards in lattice_stripe raise `ArgumentError` pre-network. Accrue wraps with `return_url` default from config. URL masked in Inspect (short-lived bearer credential). |
| **CHKT-05** | Portal config + "cancel-without-dunning" defense | `BillingPortal.Configuration` deferred to lattice_stripe 1.2 per D4-01. Phase 4 ships an **install-guide checklist** documenting Dashboard settings to set: (1) Enable "Retain offers" on cancellation flow, (2) Require reason on cancel, (3) Set `subscription_cancel.mode: "at_period_end"` (NOT `"immediately"`) — Stripe's default immediate-cancel bypasses dunning entirely. `Accrue.BillingPortal.Session.create/2` accepts `configuration: "bpc_..."` ID; host selects which config to use. No runtime enforcement — Phase 4 provides the docs, the guard lands when Configuration API ships. |
| **CHKT-06** | Success/cancel URL state reconciliation | `Accrue.Checkout.reconcile/1` takes `checkout_session_id`, calls `LatticeStripe.Checkout.Session.retrieve/3`, mirrors `payment_status`, `customer`, `subscription`, `payment_intent`, `setup_intent` into local projections via force-path changesets. Host calls from success-URL controller after redirect. Returns `{:ok, %Session{}}` or `{:error, Accrue.Error.t()}`. Idempotent — safe to call repeatedly. |
| **WH-08** | DLQ replay tooling | D4-04 locked. `Accrue.Webhooks.DLQ` library + Mix task wrappers. `Oban.retry_job/2` refuses `:discarded`/`:cancelled` so replay inserts fresh job via `Oban.insert/2`. |
| **WH-13** | Multi-endpoint webhooks w/ Connect-variant secret | Stripe signature verification uses the same HMAC path regardless of endpoint — different secret per endpoint. `Accrue.Webhook.Plug` already exists (Phase 2). Phase 4 extends it: lookup secret by endpoint name from `config :accrue, :webhook_endpoints`. Endpoint disambiguated by path suffix (`/webhooks/stripe`, `/webhooks/stripe/connect`) OR route param (`/webhooks/stripe/:endpoint`). Connect variant sets `Stripe-Account` header handling downstream (Phase 5). **Decision for Phase 4:** path-suffix approach, because route params conflict with Plug matching on raw body. |
| **EVT-05** | Upcaster pattern | `Accrue.Events.Upcaster` behaviour **already exists** as scaffold in Phase 1 (file confirmed at `accrue/lib/accrue/events/upcaster.ex` — ships v1 identity upcasters). Phase 4 adds: `Accrue.Events.UpcasterRegistry` module with `@spec chain(String.t(), pos_integer(), pos_integer()) :: [module()]` composing `v1 → v2 → v3` via module list. Read path in `Accrue.Events.Schemas.for/1` (also already exists) fans out through the chain. Malformed/unknown `schema_version` → `{:error, :unknown_schema_version}` surfaced to caller (not swallowed). |
| **EVT-06** | `timeline_for/2`, `state_as_of/3`, `bucket_by/3` | Pure Ecto over existing `accrue_events` append-only table. `timeline_for(subject_type, subject_id)` → `WHERE subject_type=? AND subject_id=? ORDER BY inserted_at ASC`. `state_as_of(subject, ts)` → same filter + `inserted_at <= ts`, then app-side fold (do NOT attempt SQL window functions — Accrue's event payloads are heterogeneous). Returns `%{state: map, event_count: int, last_event_at: ts}`. `bucket_by(subject_or_type, bucket, filters)` → `SELECT date_trunc($1, inserted_at) AS bucket, count(*) ... GROUP BY bucket`. **Required index:** composite `(subject_type, subject_id, inserted_at DESC)` on `accrue_events` — already exists from Phase 1 EVT-02. **New partial index for bucket_by:** `CREATE INDEX accrue_events_type_inserted_at_idx ON accrue_events(type, inserted_at)` for type-level aggregation. |
| **EVT-10** | Analytics helper: bucket events by month/week/day | Subsumed by `bucket_by/3` above. Three bucket sizes: `:day`, `:week`, `:month` (Postgres `date_trunc`). |
| **OBS-03** | High-signal ops event stream | Namespace convention: `[:accrue, :ops, :*]` = ops-grade, SRE-actionable. `[:accrue, :*]` = firehose (every public entry point). Events: `:revenue_loss`, `:webhook_dlq` (sub-events), `:dunning_exhaustion`, `:incomplete_expired`, `:meter_reporting_failed`, `:charge_failed`. Fire inside the same `Repo.transact/2` as the state write per D2-09 idempotency. **Module:** `Accrue.Telemetry.Ops` with `emit/3` helper (validates namespace, encodes metadata consistently). |
| **OBS-04** | Trace/span naming conventions guide | OpenTelemetry semantic conventions. Span kind: `INTERNAL` for Accrue context functions, `CLIENT` for lattice_stripe calls. Span names: `accrue.billing.<resource>.<action>` (e.g. `accrue.billing.subscription.create`). Attributes: `accrue.subscription.id`, `accrue.customer.id`, `accrue.invoice.id` (Accrue's internal UUIDs — host-queryable); `stripe.subscription.id`, `stripe.customer.id` (upstream IDs — support-bridge). NEVER attribute PII. Guide lives at `accrue/guides/telemetry.md`. No runtime enforcement — it's a documentation + convention boundary. |
| **OBS-05** | Default `Telemetry.Metrics` recipe | Optional module `Accrue.Telemetry.Metrics` (runtime-conditional on `:telemetry_metrics` presence). Exposes `defaults/0` returning a list of metric definitions: `counter("accrue.billing.subscription.create.count")`, `counter("accrue.billing.charge.create.count", tags: [:status])`, `counter("accrue.webhooks.received.count", tags: [:type])`, `counter("accrue.webhooks.dispatched.count", tags: [:status])`, `counter("accrue.ops.webhook_dlq.dead_lettered.count")`, `counter("accrue.ops.dunning_exhaustion.count")`, `last_value("accrue.webhooks.queue_depth")`, `summary("accrue.webhooks.dispatch.duration", unit: {:native, :millisecond})`. Host wires into their own `Telemetry.Metrics.Supervisor` by appending `Accrue.Telemetry.Metrics.defaults()` to their metric list. |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Elixir 1.17+ / OTP 27+** — pinned. No fallback.
- **Phoenix 1.8+** (optional-at-runtime in `accrue` core — no LiveView in core).
- **Ecto 3.13+ / PostgreSQL 14+** — `Repo.transact/2` available (used per D2-09/D3-18 for atomic state+event writes).
- **`lattice_stripe ~> 1.1`** — **MUST bump from `~> 1.0` in `CLAUDE.md` as part of D4-01**. Wave 0 of Plan 04-01.
- **`oban ~> 2.21`** — community edition sufficient. Adds queues `:accrue_dunning`, `:accrue_meters` to the existing `:accrue_webhooks`, `:accrue_mailers`, `:accrue_maintenance`.
- **`nimble_options ~> 1.1`** — for all new config schemas (`:dunning`, `:webhook_endpoints`, DLQ keys).
- **`telemetry ~> 1.3`** + **`telemetry_metrics ~> 1.1` (optional)** — OBS-05 recipe is gated on telemetry_metrics being loaded.
- **Security:** webhook signature verification must remain non-bypassable; WH-13 adds endpoint selection WITHOUT weakening verification.
- **Performance:** webhook pipeline p99 <100ms unchanged — DLQ machinery runs outside the sync path.
- **Mox for behaviours, Fake processor for integration tests** — Phase 4 adds to Fake: `report_meter_event/1`, `portal_session_create/2`, `checkout_session_create/2`, `subscription_update/2` (for sweeper), `subscription_schedule_*`.
- **Dual bang/tuple API (D-05)** — all new public functions ship both.
- **Commit-then-call-Stripe (D2-09 / D3-18)** — HTTP calls NEVER inside `Repo.transact/2`.
- **GSD workflow enforcement** — Phase 4 work must go through `/gsd-execute-phase`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| BILL-11 pause/resume | Billing context (`Accrue.Billing`) | Processor + webhook handler | Host-callable write path; Stripe is canonical; webhook flips `paused_at`. |
| BILL-12 multi-item subs | Billing context | Processor + webhook projection | Mutations route through `LatticeStripe.SubscriptionItem.*`; reads from local projection. |
| BILL-13 metered usage | Billing context | Oban reconciler + webhook error-report handler | Sync outbox pattern; Oban retries `pending`; webhook surfaces async failures. |
| BILL-14 comped subs | Billing context | Coupon module | Re-uses BILL-27 coupon infra; bypasses payment-method guard. |
| BILL-15 dunning/grace | Oban cron (SweeperJob) | Webhook handler (terminal telemetry) | SweeperJob only CALLS Stripe; webhook handler writes state + fires telemetry. |
| BILL-16 subscription schedules | Billing context + new schema | Webhook handler (phase detection) | Thin projection; Stripe is canonical for phase state. |
| BILL-27/28 coupons/discounts | Billing context + schemas | Webhook projection | Force-path changesets on webhook, user-path create/retrieve in context. |
| CHKT-01/02/03 Checkout | New context `Accrue.Checkout` | Webhook handler (`checkout.session.completed`) | Host-facing session + reconcile on return. |
| CHKT-04/05/06 Portal | New context `Accrue.BillingPortal` | (none — Stripe-hosted UI) | Create-only surface; portal is fully Stripe-hosted. |
| WH-08 DLQ | New `Accrue.Webhooks.DLQ` library + Mix tasks | Oban dispatch worker | Library core; Mix tasks are thin wrappers; Phase 7 LiveView consumes. |
| WH-13 multi-endpoint | `Accrue.Webhook.Plug` (Phase 2) + config | — | Plug extension only; zero new infra. |
| EVT-05 upcasters | `Accrue.Events.UpcasterRegistry` + read-path dispatch | — | Pure stateless transform; gated by schema_version on read. |
| EVT-06/10 query API | `Accrue.Events` module | PostgreSQL indexes | App-side fold for `state_as_of`; SQL aggregation for `bucket_by`. |
| OBS-03 ops events | `Accrue.Telemetry.Ops` | Every writer | Centralized emit helper enforces namespace + metadata shape. |
| OBS-04 trace naming | `accrue/guides/telemetry.md` (docs) | — | Convention boundary, not runtime. |
| OBS-05 metrics recipe | `Accrue.Telemetry.Metrics` (optional module) | Host's `telemetry_metrics` supervisor | Host wires; Accrue exposes `defaults/0`. |

## Standard Stack

### Core (already in deps — no new additions)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:lattice_stripe` | `~> 1.1` (BUMP from `~> 1.0`) | All Stripe API calls | Sibling lib; 1.1 ships `Billing.Meter`, `MeterEvent`, `MeterEventAdjustment`, `BillingPortal.Session` required by Phase 4. `[VERIFIED: /Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing/{meter,meter_event}.ex, billing_portal/session.ex]` |
| `:oban` | `~> 2.21` | Async/cron jobs | Already in deps. Phase 4 adds `:accrue_dunning` + `:accrue_meters` queues + cron entries (host wires). |
| `:ecto_sql` | `~> 3.13` | Migrations + transactions | `Repo.transact/2` is load-bearing (D2-09). |
| `:nimble_options` | `~> 1.1` | Config schema | Extends `Accrue.Config` for 5+ new keys. |
| `:telemetry` | `~> 1.3` | Event instrumentation | Ops namespace `[:accrue, :ops, :*]`. |
| `:telemetry_metrics` | `~> 1.1` (optional) | OBS-05 recipe | Already declared optional in CLAUDE.md. |

### Version Verification

| Package | Current Version | Source | Date |
|---------|----------------|--------|------|
| `lattice_stripe` | `1.1.0` (unreleased; code-complete on `main`, 66 commits post `v1.0.0` tag from 2026-04-13) | `[VERIFIED: /Users/jon/projects/lattice_stripe/ sibling repo]` | 2026-04-14 |
| `oban` | `2.21.1` | `[CITED: CLAUDE.md]` | 2026-03-26 |
| `ecto_sql` | `3.13.5` | `[CITED: CLAUDE.md]` | 2025-11-09 |
| `nimble_options` | `1.1.1` | `[CITED: CLAUDE.md]` | 2024-05-25 |

**No new dependencies introduced in Phase 4.** All work is inside the existing dep graph.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                             Host Phoenix App                              │
└──────────┬───────────────────────────────────────────────┬──────────────┘
           │                                                │
           │ User write path                                │ Stripe webhook POST
           ▼                                                ▼
┌──────────────────────────┐                    ┌──────────────────────────┐
│ Accrue.Billing.*         │                    │ Accrue.Webhook.Plug      │
│  .report_usage/3 ──────┐ │                    │  (signature verify,      │
│  .add_item/3           │ │                    │   multi-endpoint lookup) │
│  .pause/2 / resume/2   │ │                    └───────┬──────────────────┘
│  .comp_subscription/2  │ │                            │ verified event
│  .apply_promotion_code │ │                            ▼
│                        │ │                    ┌──────────────────────────┐
│ Accrue.Checkout.*      │ │                    │ Webhooks.Ingest          │
│  .Session.create/2     │ │                    │  Repo.transact/2:        │
│  .reconcile/1          │ │                    │   insert webhook_event   │
│                        │ │                    │   + Oban.insert(dispatch)│
│ Accrue.BillingPortal.* │ │                    └──────────┬───────────────┘
│  .Session.create/2     │ │                               │
└──────────┬─────────────┘ │                               ▼
           │               │                    ┌──────────────────────────┐
           │               │                    │ DispatchWorker (Oban)    │
           │               │                    │  refetch + dispatch      │
           │               │                    │  handler by type         │
           ▼               │                    └──────────┬───────────────┘
┌──────────────────────────┴┐                              │
│ Repo.transact/2:           │                              ▼
│  insert domain row         │                    ┌──────────────────────────┐
│  Events.record_multi/2     │                    │ Handlers.*               │
│  ────────── COMMIT ────────│                    │  force_status_changeset  │
│  call lattice_stripe       │                    │  force_discount_changeset│
│  update row (confirmed)    │◄────Stripe HTTP────┤  phase diff (schedules)  │
└──────────┬─────────────────┘                    │  terminal telemetry      │
           │                                       └──────────┬───────────────┘
           ▼                                                  │
┌──────────────────────────┐                                  │
│ accrue_meter_events      │   (outbox pattern for BILL-13)   │
│  pending → reported      │                                  │
│                          │                                  │
│ ReconcilerJob (Oban cron)│                                  │
│  retries pending rows    │                                  │
└──────────────────────────┘                                  │
                                                              │
┌─────────────────────────────────────────────────────────────▼───────────┐
│ Write surface for all mutations:                                         │
│   accrue_subscriptions (+ past_due_since, dunning_sweep_attempted_at,    │
│                           paused_at, pause_behavior, discount_id)        │
│   accrue_invoices      (+ discount_minor, total_discount_amounts)        │
│   accrue_meter_events  (NEW — outbox)                                    │
│   accrue_subscription_schedules (NEW — thin projection)                  │
│   accrue_promotion_codes (NEW — thin projection)                         │
│   accrue_webhook_events (existing — status: dead / failed → :dead-letter)│
│   accrue_events (existing — append-only, query API + upcasters here)     │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ Ops plane (OBS-03/04/05):                                                │
│   [:accrue, :ops, :*] telemetry events ──► Accrue.Telemetry.Metrics     │
│                                              │                           │
│                                              ▼                           │
│                                         Host metric reporter             │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ Maintenance plane (Oban cron, host-wired):                               │
│   Pruner (D2-34 finalized here)   → prunes dead + succeeded webhook rows │
│   Dunning.SweeperJob (D4-02)       → past_due → unpaid via Stripe API    │
│   MeterEvents.ReconcilerJob (D4-03)→ retries pending meter events        │
└─────────────────────────────────────────────────────────────────────────┘
```

### Pattern 1: Transactional Outbox (BILL-13)

**What:** Write the domain row in a local txn first (status `pending`), commit, THEN call Stripe, then update the row with outcome. Reconciler retries stuck `pending` rows.

**When to use:** Any Accrue operation that must NOT be lost on process crash between commit and upstream call. Metered usage is the first such case; charge/invoice already rely on Stripe idempotency instead of outbox.

**Why:** The classic transactional-outbox pattern is the minimum-viable durability guarantee for "fire-and-forget" external events. Without it, a crash between DB commit and HTTP call silently loses events.

```elixir
# Source: pattern adapted from lattice_stripe guides/metering.md AccrueLike.UsageReporter
# + D4-03 locked shape
def report_usage(customer, event_name, opts) do
  value = Keyword.get(opts, :value, 1)
  timestamp = Keyword.get(opts, :timestamp, DateTime.utc_now())
  identifier = Keyword.get_lazy(opts, :identifier, fn ->
    derive_identifier(customer, event_name, value, timestamp)
  end)

  # Phase 1: transactional insert (commit BEFORE Stripe call)
  {:ok, {row, _event}} =
    Repo.transact(fn ->
      with {:ok, row} <- insert_meter_event(customer, event_name, value, timestamp, identifier),
           {:ok, event} <- Events.record_multi(:meter_event_reported, row) do
        {:ok, {row, event}}
      end
    end)

  # Phase 2: Stripe call OUTSIDE txn
  case Processor.report_meter_event(row) do
    {:ok, stripe_event} ->
      mark_reported(row, stripe_event)
    {:error, err} ->
      mark_failed(row, err)
      {:error, err}
  end
end
```

### Pattern 2: Library Core + Mix Task Wrapper (WH-08)

**What:** Public API lives in `Accrue.Webhooks.DLQ` module. Mix tasks `accrue.webhooks.replay` / `accrue.webhooks.prune` are 5–20 lines that parse argv and delegate.

**When to use:** Any ops-grade surface that needs to be callable from both iex (admin LV in Phase 7) and a shell (SRE 3am SSH). ALL new Phase 4 ops surfaces follow this.

**Precedent:** `Ecto.Migrator` + `mix ecto.migrate`, `Oban.Migration` + `mix oban.install`. Unanimous Elixir ecosystem pattern.

```elixir
# Source: D4-04 locked shape
defmodule Mix.Tasks.Accrue.Webhooks.Replay do
  use Mix.Task
  @shortdoc "Requeue dead-lettered webhook events"

  def run(argv) do
    Mix.Task.run("app.start")
    {opts, args, _} = OptionParser.parse(argv,
      strict: [since: :string, type: :string, dry_run: :boolean,
               all_dead: :boolean, yes: :boolean])

    case args do
      [event_id] ->
        Accrue.Webhooks.DLQ.requeue(event_id)
      [] ->
        filter = build_filter(opts)
        Accrue.Webhooks.DLQ.requeue_where(filter, dry_run: opts[:dry_run] || false)
    end
  end
end
```

### Pattern 3: Force-Path Changesets on Webhook (BILL-28 discounts, BILL-16 schedule phases)

**What:** Separate `force_<field>_changeset/2` functions that skip user-facing validation (e.g., "must be positive") because Stripe is canonical per D2-29. User-path changesets validate; webhook-path changesets trust.

**Why:** D3-17 lock. Stripe may legitimately send transitional states that would fail user-path validation. Blocking them breaks D2-29 canonicality.

```elixir
# Source: D3-17 pattern, extended to discounts
def force_discount_changeset(%Invoice{} = invoice, stripe_invoice_data) do
  invoice
  |> cast(%{
    discount_minor: stripe_invoice_data["total_discount_amounts"] |> sum_discounts(),
    total_discount_amounts: stripe_invoice_data["total_discount_amounts"]
  }, [:discount_minor, :total_discount_amounts])
  # no validate_number — Stripe is canonical
end
```

### Pattern 4: Ops Telemetry Emit Helper (OBS-03)

**What:** Every `[:accrue, :ops, :*]` event goes through `Accrue.Telemetry.Ops.emit/3` which validates namespace and enforces a metadata envelope (`operation_id`, `actor_type`, `subject_type`, `subject_id`).

```elixir
defmodule Accrue.Telemetry.Ops do
  @spec emit(atom() | [atom()], map(), map()) :: :ok
  def emit(suffix, measurements, metadata) when is_atom(suffix) do
    emit([suffix], measurements, metadata)
  end
  def emit(suffix, measurements, metadata) when is_list(suffix) do
    :telemetry.execute(
      [:accrue, :ops | suffix],
      measurements,
      Map.merge(%{operation_id: Accrue.Context.operation_id()}, metadata)
    )
  end
end
```

### Recommended Module Structure

```
accrue/lib/accrue/
├── billing/
│   ├── coupon.ex                      # exists (D3-16); Phase 4 expands
│   ├── promotion_code.ex              # NEW
│   ├── subscription.ex                # exists; Phase 4 adds pause_behavior + past_due_since cols
│   ├── subscription_schedule.ex       # NEW (schema + thin projection)
│   ├── meter_event.ex                 # NEW (outbox row)
│   ├── dunning.ex                     # NEW (pure policy module)
│   └── ...
├── billing.ex                         # add report_usage/3, add_item/3, pause/2, comp_subscription/2
├── checkout/
│   ├── session.ex                     # NEW
│   └── line_item.ex                   # NEW
├── checkout.ex                        # NEW (reconcile/1)
├── billing_portal/
│   └── session.ex                     # NEW
├── billing_portal.ex                  # NEW
├── webhooks/
│   ├── dlq.ex                         # NEW (D4-04 library core)
│   ├── pruner.ex                      # NEW (D2-34 finalized; Oban worker)
│   └── handlers/
│       ├── billing_meter_error_report_triggered.ex  # NEW
│       ├── checkout_session_completed.ex            # NEW
│       ├── customer_subscription_paused.ex          # NEW
│       ├── customer_subscription_resumed.ex         # NEW
│       ├── subscription_schedule_updated.ex         # NEW
│       ├── subscription_schedule_released.ex        # NEW
│       ├── subscription_schedule_canceled.ex        # NEW
│       ├── subscription_schedule_expiring.ex        # NEW
│       ├── customer_subscription_updated.ex         # exists — extend with dunning diff
│       └── ...
├── workers/
│   ├── dunning_sweeper.ex             # NEW (Oban cron)
│   └── meter_events_reconciler.ex     # NEW (Oban cron)
├── events/
│   ├── upcaster.ex                    # exists (behaviour)
│   ├── upcaster_registry.ex           # NEW (chain composition)
│   └── query.ex                       # NEW (timeline_for, state_as_of, bucket_by)
├── events.ex                          # extend with query fns
├── telemetry/
│   ├── ops.ex                         # NEW (emit helper)
│   └── metrics.ex                     # NEW (optional — OBS-05 recipe)
└── mix/tasks/
    ├── accrue.webhooks.replay.ex      # NEW
    └── accrue.webhooks.prune.ex       # NEW
```

### Anti-Patterns to Avoid

- **Running Stripe calls inside `Repo.transact/2`** — violates D2-09 / D3-18. The Sweeper and Reconciler BOTH must commit their intent row, THEN call Stripe, THEN update status.
- **Computing discount math locally** — Stripe is canonical. Mirror `total_discount_amounts`, never recompute.
- **Using `Oban.retry_job/2` for DLQ replay** — it refuses `:discarded`/`:cancelled` jobs. Insert fresh job via `Oban.insert/2` (D4-04 structural necessity).
- **Nightly batch flush of meter events** — lattice_stripe metering guide explicitly documents this as catastrophic (35-day backdating window + rate limits + double-count on mid-flush crash).
- **Storing `MeterEvent.payload` in logs** — contains `stripe_customer_id` (PII). lattice_stripe masks it in `Inspect` by default; Accrue's `accrue_meter_events` row stores derived fields only, never the raw payload.
- **Trusting webhook payload snapshots for state** (WH-10 already locked) — handler must refetch via `Processor.fetch/1`. BILL-16 phase diff especially — `current_phase` ages out quickly.
- **Local cancel on dunning sweep** — violates D2-29. Sweeper calls Stripe, webhook flips row.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stripe HTTP calls for Meter/MeterEvent | `Accrue.Stripe.MeterEvent` thin shim | `LatticeStripe.Billing.MeterEvent.create/3` | D4-01 locked. Sibling lib owns all Stripe wire-format concerns. |
| Stripe HTTP calls for BillingPortal | `Accrue.Stripe.BillingPortal` | `LatticeStripe.BillingPortal.Session.create/3` | Same. FlowData guards already ship in lattice_stripe. |
| Stripe HTTP calls for Checkout | `Accrue.Stripe.Checkout` | `LatticeStripe.Checkout.Session.create/3` | Same. `mode`-required pre-network guard already ships. |
| Stripe HTTP calls for SubscriptionSchedule | `Accrue.Stripe.SubscriptionSchedule` | `LatticeStripe.SubscriptionSchedule.*` | Same. `from_subscription` vs `customer+phases` shape handled. |
| Webhook signature verification | Custom HMAC | existing `Accrue.Webhook.Signature` (Phase 2) | Already solved. WH-13 just adds secret lookup by endpoint. |
| DLQ job replay | Oban API gymnastics | `Oban.insert/2` with processor_event_id in args | `Oban.retry_job/2` refuses discarded/cancelled jobs (D4-04). |
| Idempotency key derivation | Ad-hoc hashing | `operation_id` pdict + `:erlang.phash2({shape})` | Phase 3 D3-18 locked. Reuse. |
| Discount math | Local proration arithmetic | Mirror `invoice.total_discount_amounts` | Stripe is canonical. D2-29. |
| Dunning retry cadence | Custom backoff | Stripe Smart Retries (Dashboard) + Accrue grace overlay | D4-02 hybrid. Stripe handles cadence; Accrue handles terminal action. |
| Portal configuration | `Accrue.BillingPortal.Configuration` | `bpc_*` ID from Dashboard | `lattice_stripe 1.2` — deferred. |
| Meter event buffering | Oban-backed write buffer | Sync pass-through + outbox reconciler | D4-03 — buffering forces policy decisions that don't belong in a library. |
| Retry policy for meter reporting | Custom exponential backoff | `ReconcilerJob` sweep every 60s on `pending` rows | D4-03 — bounded staleness is sufficient; high-volume hosts buffer client-side. |
| SQL window functions for `state_as_of` | PL/pgSQL replay | App-side `Enum.reduce/3` over ordered rows | Event payloads are heterogeneous; SQL fold would require per-type logic in DB. |

**Key insight:** `lattice_stripe 1.1` closes every Stripe API gap Phase 4 needs. The temptation to ship "just one small shim" must be rejected — D4-01 documents why this creates parallel call shapes that survive forever. Single shape = single Fake = single mental model.

## Runtime State Inventory

> N/A — Phase 4 is greenfield work on top of Phase 1–3 primitives. No rename/refactor/migration. Five new schemas and two new columns on existing tables; no string-replacement or runtime-state rebinding.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Phase 4 introduces new tables/columns, does not rename existing | N/A |
| Live service config | Stripe Dashboard portal configuration (`bpc_*`) — host-managed, documented in install guide | Install-guide addition, not code |
| OS-registered state | None | N/A |
| Secrets/env vars | NEW: `:webhook_endpoints` config map supports multiple signing secrets (WH-13) — host provides via `config :accrue, :webhook_endpoints, primary: [secret: System.fetch_env!("STRIPE_WH_SECRET_PRIMARY")], connect: [...]` | Document in install guide + runtime.exs template |
| Build artifacts | `lattice_stripe` path dep during Phase 4 dev → must flip to `~> 1.1` before merge | Dep manifest update in pre-merge task |

## Common Pitfalls

### Pitfall 1: Dunning sweeper flips local status (violates D2-29)
**What goes wrong:** Implementer assumes "we own the grace period" → writes `update(subscription, status: :unpaid)` locally.
**Why:** Feels direct. Stripe is "eventually consistent."
**How to avoid:** Sweeper MUST call `LatticeStripe.Subscription.update(id, status: "unpaid")` ONLY. Local state is flipped by the webhook handler exclusively.
**Warning signs:** Test where sweeper runs and Stripe is down — if local row flips without Stripe confirming, the code is wrong.

### Pitfall 2: Meter event reporting blocks the caller or runs inside `Repo.transact/2`
**What goes wrong:** Implementer wraps `Stripe.MeterEvent.create/3` inside the Repo.transact to "get atomicity."
**Why:** HTTP inside txn is tempting because it looks like "all-or-nothing."
**How to avoid:** D2-09 lock. Commit row (status `pending`) → exit txn → call Stripe → update row. Reconciler handles the crash case.
**Warning signs:** Any `with {:ok, _} <- Repo.transact(...), {:ok, _} <- Processor.report_meter_event(...)` is the wrong shape. The Stripe call must be AFTER `Repo.transact/2`.

### Pitfall 3: DLQ replay uses `Oban.retry_job/2`
**What goes wrong:** `Oban.retry_job/2` silently refuses `:discarded`/`:cancelled` jobs — and Accrue's DLQ'd events are exactly those states.
**How to avoid:** `Oban.insert/2` a fresh job with `processor_event_id` in args. Update webhook_event status to `:received`. Update status to `:replayed` on completion.
**Warning signs:** Tests show replay "succeeds" but no new job runs — that's `Oban.retry_job/2` refusing silently.

### Pitfall 4: Out-of-order webhooks corrupt subscription schedule phase tracking
**What goes wrong:** `subscription_schedule.updated` arrives before `subscription_schedule.created` (rare but possible). Implementer's handler assumes the row exists → crashes or creates malformed row.
**How to avoid:** Webhook handlers use `upsert` pattern (not `insert` + fallback update), AND always refetch from Stripe (WH-10 lock). Store `current_phase.start_date` as the phase-diff anchor, not phase index (index can shift if Stripe re-orders).
**Warning signs:** Integration test where events arrive out of order and the final state diverges.

### Pitfall 5: `meter_event_value_not_found` silent drops
**What goes wrong:** Meter created with `formula: "sum"` but `value_settings.event_payload_key` missing — every event silently drops in Stripe's async pipeline. No sync error.
**How to avoid:** `lattice_stripe` GUARD-01 raises pre-network if this shape is wrong. Subscribe to `v1.billing.meter.error_report_triggered` webhook and wire Accrue handler that writes to `accrue_meter_events` (mark row `failed`) + fires `[:accrue, :ops, :meter_reporting_failed]`.
**Warning signs:** "We can see events in our DB but they're not on invoices." Check the error-report webhook handler is wired.

### Pitfall 6: Customer Portal "cancel without dunning" footgun
**What goes wrong:** Default Stripe portal configuration allows immediate cancel → subscription terminates without ever going through `past_due`, bypassing all dunning policy.
**How to avoid:** Phase 4 ships an install-guide checklist (CHKT-05) documenting required Dashboard toggles: `subscription_cancel.mode: "at_period_end"`, "Retain offers" enabled, reason-required. Runtime enforcement must wait for `BillingPortal.Configuration` in lattice_stripe 1.2.
**Warning signs:** Customer clicks cancel, subscription disappears, no `invoice.payment_failed` ever fires, Accrue MRR numbers drop with no corresponding dunning signal.

### Pitfall 7: Meter payload value sent as integer not string
**What goes wrong:** `"value" => 5` instead of `"value" => "5"` → Stripe silently drops with `meter_event_invalid_value`.
**How to avoid:** `Accrue.Billing.report_usage/3` always converts: `to_string(value)` at the boundary. Test with integer/float/Decimal inputs.
**Warning signs:** Usage rows in `accrue_meter_events` have `stripe_status: "reported"` but invoices show zero usage.

### Pitfall 8: `timestamp_too_far_in_past` on backdated reporting
**What goes wrong:** Caller passes a timestamp >35 days old → sync 400.
**How to avoid:** Validate `:timestamp` opt in `report_usage/3`: if `DateTime.diff(now, ts) > 35 * 86400`, return `{:error, :timestamp_out_of_window}` BEFORE calling Stripe (save an RTT + surface clean error).

### Pitfall 9: Upcaster chain drops events with unknown `schema_version`
**What goes wrong:** Old row has `schema_version: 99` (corrupt or future). Chain returns `{:error, :unknown}`, read path swallows it → silent data loss.
**How to avoid:** `UpcasterRegistry.chain/3` returns `{:error, {:unknown_schema_version, v}}` and the read path SURFACES it. Never silently drop. Log + emit `[:accrue, :ops, :events_upcast_failed]`.

### Pitfall 10: `state_as_of` replay doesn't apply upcasters
**What goes wrong:** Historical rows at `schema_version: 1` are folded into state using current field shape → mismatched keys → quiet map merge weirdness.
**How to avoid:** `state_as_of/3` MUST route every row through the upcaster chain to the current schema_version BEFORE folding.

## Code Examples

### Example 1: `Accrue.Billing.report_usage/3` (BILL-13)

```elixir
# Sources:
#   - /Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing/meter_event.ex
#   - /Users/jon/projects/lattice_stripe/guides/metering.md
#   - D4-03 locked shape in 04-CONTEXT.md
defmodule Accrue.Billing do
  @spec report_usage(Accrue.Billing.Customer.t() | String.t(), String.t(), keyword()) ::
          {:ok, Accrue.Billing.MeterEvent.t()} | {:error, term()}
  def report_usage(customer, event_name, opts \\ [])

  def report_usage(stripe_customer_id, event_name, opts) when is_binary(stripe_customer_id) do
    customer = Repo.get_by!(Accrue.Billing.Customer, processor_id: stripe_customer_id)
    report_usage(customer, event_name, opts)
  end

  def report_usage(%Accrue.Billing.Customer{} = customer, event_name, opts) do
    value = Keyword.get(opts, :value, 1)
    timestamp = Keyword.get(opts, :timestamp, DateTime.utc_now())
    identifier = Keyword.get_lazy(opts, :identifier, fn ->
      derive_identifier(customer, event_name, value, timestamp)
    end)

    with :ok <- validate_backdating_window(timestamp),
         {:ok, row} <- insert_pending(customer, event_name, value, timestamp, identifier) do
      case Accrue.Processor.report_meter_event(row) do
        {:ok, stripe_event} ->
          mark_reported(row, stripe_event)
        {:error, err} ->
          mark_failed(row, err)
          {:error, err}
      end
    end
  end

  defp derive_identifier(customer, event_name, value, ts) do
    op = Accrue.Context.operation_id() || "unscoped"
    hash = :erlang.phash2({customer.processor_id, event_name, value, DateTime.to_unix(ts, :microsecond)})
    "accrue_mev_#{op}_#{event_name}_#{hash}"
  end

  defp insert_pending(customer, event_name, value, ts, identifier) do
    Repo.transact(fn ->
      cs = Accrue.Billing.MeterEvent.pending_changeset(%{
        customer_id: customer.id,
        stripe_customer_id: customer.processor_id,
        event_name: event_name,
        value: value,
        identifier: identifier,
        occurred_at: ts,
        operation_id: Accrue.Context.operation_id()
      })

      with {:ok, row} <- Repo.insert(cs),
           {:ok, _event} <- Accrue.Events.record_multi(:meter_event_reported, %{
             subject_type: "meter_event",
             subject_id: row.id,
             data: %{event_name: event_name, value: value, identifier: identifier}
           }) do
        {:ok, row}
      end
    end)
  end

  defp validate_backdating_window(ts) do
    case DateTime.diff(DateTime.utc_now(), ts, :second) do
      diff when diff > 35 * 86_400 -> {:error, :timestamp_out_of_window}
      diff when diff < -300 -> {:error, :timestamp_in_future}
      _ -> :ok
    end
  end
end
```

### Example 2: `Accrue.Webhooks.DLQ.requeue/1` (WH-08)

```elixir
# Source: D4-04 locked shape
defmodule Accrue.Webhooks.DLQ do
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent
  alias Accrue.Events
  import Ecto.Query

  @spec requeue(Ecto.UUID.t()) :: {:ok, WebhookEvent.t()} | {:error, Accrue.Error.t()}
  def requeue(event_id) when is_binary(event_id) do
    Repo.transact(fn ->
      with {:ok, event} <- fetch_replayable(event_id),
           {:ok, updated} <- mark_received(event),
           {:ok, _job} <- enqueue_dispatch(updated),
           {:ok, _} <- Events.record_multi(:webhook_replayed, %{
             subject_type: "webhook_event",
             subject_id: updated.id,
             actor_type: :admin,
             data: %{original_event_id: event_id}
           }) do
        Accrue.Telemetry.Ops.emit([:webhook_dlq, :replay], %{count: 1},
          %{event_id: event_id, actor: :replay})
        {:ok, updated}
      end
    end)
  end

  defp fetch_replayable(event_id) do
    case Repo.get(WebhookEvent, event_id) do
      nil ->
        {:error, %Accrue.Error{type: :not_found, message: "webhook event #{event_id} not found"}}
      %{status: :replayed} ->
        {:error, %Accrue.Error{type: :already_replayed, message: "event already replayed"}}
      %{status: s} = event when s in [:dead, :failed] ->
        {:ok, event}
      %{status: s} ->
        {:error, %Accrue.Error{type: :invalid_state,
          message: "cannot replay event in status #{s}"}}
    end
  end

  defp enqueue_dispatch(event) do
    %{processor_event_id: event.processor_event_id, replay: true}
    |> Accrue.Webhook.DispatchWorker.new()
    |> Oban.insert()
  end
end
```

### Example 3: `Accrue.Events.state_as_of/3` (EVT-06)

```elixir
# Source: EVT-06 design from 04-CONTEXT.md + UpcasterRegistry chain composition
defmodule Accrue.Events do
  alias Accrue.Repo
  alias Accrue.Events.{Event, UpcasterRegistry}
  import Ecto.Query

  @spec state_as_of(String.t(), String.t(), DateTime.t()) :: {:ok, map()} | {:error, term()}
  def state_as_of(subject_type, subject_id, %DateTime{} = timestamp) do
    query =
      from e in Event,
        where: e.subject_type == ^subject_type and e.subject_id == ^subject_id,
        where: e.inserted_at <= ^timestamp,
        order_by: [asc: e.inserted_at]

    events = Repo.all(query)

    case upcast_all(events) do
      {:ok, upcasted} ->
        {:ok, Enum.reduce(upcasted, %{}, &apply_event/2)}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp upcast_all(events) do
    Enum.reduce_while(events, {:ok, []}, fn event, {:ok, acc} ->
      case UpcasterRegistry.upcast(event.type, event.schema_version, event.data) do
        {:ok, upcasted} -> {:cont, {:ok, [%{event | data: upcasted} | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, list} -> {:ok, Enum.reverse(list)}
      other -> other
    end
  end

  @spec timeline_for(String.t(), String.t()) :: [Event.t()]
  def timeline_for(subject_type, subject_id) do
    Repo.all(
      from e in Event,
        where: e.subject_type == ^subject_type and e.subject_id == ^subject_id,
        order_by: [asc: e.inserted_at]
    )
  end

  @spec bucket_by(keyword(), :day | :week | :month) :: [%{bucket: DateTime.t(), count: integer()}]
  def bucket_by(filters, bucket) when bucket in [:day, :week, :month] do
    Repo.all(
      from e in Event,
        where: ^apply_filters(filters),
        group_by: fragment("date_trunc(?, ?)", ^to_string(bucket), e.inserted_at),
        order_by: fragment("date_trunc(?, ?)", ^to_string(bucket), e.inserted_at),
        select: %{
          bucket: fragment("date_trunc(?, ?)", ^to_string(bucket), e.inserted_at),
          count: count(e.id)
        }
    )
  end
end
```

### Example 4: Multi-endpoint webhook secret lookup (WH-13)

```elixir
# Source: Discretion default — path-suffix approach
defmodule Accrue.Webhook.Plug do
  # ... existing init/call unchanged ...

  defp lookup_secret(conn) do
    endpoint_name = endpoint_from_path(conn.request_path)
    case Accrue.Config.fetch!([:webhook_endpoints, endpoint_name, :secret]) do
      {:ok, secret} -> {:ok, secret, endpoint_name}
      :error -> {:error, :unknown_endpoint}
    end
  end

  defp endpoint_from_path(path) do
    cond do
      String.ends_with?(path, "/stripe/connect") -> :connect
      String.ends_with?(path, "/stripe") -> :primary
      true -> :primary  # default
    end
  end
end
```

### Example 5: Dunning SweeperJob (BILL-15)

```elixir
# Source: D4-02 locked shape
defmodule Accrue.Billing.Dunning.SweeperJob do
  use Oban.Worker, queue: :accrue_dunning, max_attempts: 3

  alias Accrue.Billing.{Subscription, Dunning}
  alias Accrue.{Processor, Repo}
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    config = Accrue.Config.fetch!(:dunning)
    grace_days = config[:grace_days] || 14
    terminal = config[:terminal_action] || :unpaid

    Repo.all(candidates_query(grace_days))
    |> Enum.each(&sweep_one(&1, terminal))
    :ok
  end

  defp candidates_query(grace_days) do
    cutoff = DateTime.add(DateTime.utc_now(), -grace_days * 86_400, :second)
    from s in Subscription,
      where: s.status == :past_due,
      where: s.past_due_since < ^cutoff,
      where: is_nil(s.dunning_sweep_attempted_at)
  end

  defp sweep_one(sub, terminal_action) do
    # Mark attempted FIRST so concurrent job doesn't double-sweep
    {:ok, _} = Repo.transact(fn ->
      cs = Ecto.Changeset.change(sub, dunning_sweep_attempted_at: DateTime.utc_now())
      with {:ok, updated} <- Repo.update(cs),
           {:ok, _} <- Accrue.Events.record_multi(:dunning_terminal_action_requested, %{
             subject_type: "subscription",
             subject_id: updated.id,
             data: %{terminal_action: terminal_action, grace_exhausted: true}
           }) do
        {:ok, updated}
      end
    end)

    # Stripe call AFTER txn commit
    case terminal_action do
      :unpaid -> Processor.subscription_update(sub.processor_id, %{status: "unpaid"})
      :canceled -> Processor.subscription_cancel(sub.processor_id, %{})
    end
    # Webhook handler will flip local status + fire telemetry
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stripe Subscription.usage_records (v1) | `Billing.Meter` + `MeterEvent` | Stripe 2024 Meters launch | BILL-13 path — usage_records is deprecated. lattice_stripe 1.1 uses meters only. |
| `trial_end: unix_max` for comping | 100%-off forever coupon | Industry practice (Pay, Cashier) | BILL-14 — preserves invoice history, reuses discount infra. |
| Client-side Checkout form | `ui_mode: "embedded"` with `<stripe-checkout>` element + client_secret | Stripe 2024 embedded GA | CHKT-02 — single API, two rendering modes. |
| Polling for DLQ replay | `Oban.insert/2` fresh job (retry_job refuses discarded) | Oban 2.x docs | D4-04 — structural constraint, not a choice. |
| SQL window functions for event replay | App-side `Enum.reduce/3` fold | Accrue design | EVT-06 — event payloads are heterogeneous; DB logic would need per-type branching. |

**Deprecated/outdated:**
- Stripe `subscription.usage_records` — replaced by `billing/meter_events`. `[CITED: https://docs.stripe.com/billing/subscriptions/usage-based/recording-usage-api]`
- Stripe `subscription.pause_collection: true` (bool form) — now `pause_collection: %{behavior: ...}`. `[ASSUMED]` but consistent with lattice_stripe 1.0 surface.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Stripe `subscription.pause_collection` accepts `%{behavior: "mark_uncollectible" \| "keep_as_draft" \| "void"}` | BILL-11 row | LOW — verify in lattice_stripe Subscription update test fixtures at plan time. Impact: one line change in pause/resume helper. |
| A2 | `subscription_schedule.expiring` webhook fires ~7 days before phase transition | BILL-16 | LOW — Stripe docs describe it as "advance notice"; exact window should be verified from Stripe docs before plan time. |
| A3 | `subscription_cancel.mode: "at_period_end"` is the Dashboard toggle name for the "cancel without dunning" defense | CHKT-05 | LOW — dashboard-side string is internal. Install guide should screenshot + link Stripe docs rather than hardcode the label. |
| A4 | Postgres `date_trunc('week', ts)` bucketing aligns Monday-start (ISO) by default | EVT-06 `bucket_by` | LOW — Postgres default is ISO Monday, matches most analytics expectations. Document in function docs. |
| A5 | Default `Telemetry.Metrics` reporter list (counters + spans, no summaries) covers 95% of host needs | OBS-05 | MEDIUM — may need adjustment after Phase 7 admin LV exercises the metrics surface. Additive change. |
| A6 | `bucket_by/3` on `type` filter uses an index-only scan with `(type, inserted_at)` composite | EVT-06/10 | LOW — standard Postgres plan for group-by-time. Verify with `EXPLAIN ANALYZE` at test time. |
| A7 | Path-suffix webhook routing (`/webhooks/stripe/connect`) does NOT conflict with raw-body plug in Phoenix 1.8 routing | WH-13 | LOW — Phase 2 plug already handles `/webhooks/stripe`, adding `/connect` suffix is a Phoenix scope addition. Verify when writing the Phase 2 plug extension. |
| A8 | `v1.billing.meter.error_report_triggered` webhook event fires per-meter, aggregating errors over a short window (not per-event) | BILL-13 reconciliation | LOW — lattice_stripe guide confirms "when processing errors accumulate," suggesting aggregation. Impact: reconciler strategy — sweep by `meter_id + error_code` rather than per-event. |

**Summary:** 8 assumptions, all LOW/MEDIUM risk. None block planning. A1-A3 should be verified during plan-writing (one lattice_stripe test fixture read each). A5 can be revisited during Phase 7 without breaking changes.

## Open Questions

1. **Should `Accrue.Checkout.Session.create/2` also create a local `accrue_checkout_sessions` projection row, or is the webhook-driven `checkout.session.completed` handler sufficient?**
   - What we know: Stripe Checkout Sessions are short-lived (30 min default expiry); most data is transient.
   - What's unclear: Admin LV (Phase 7) may want to list "abandoned" sessions for recovery, which requires a local row pre-completion.
   - Recommendation: Ship Phase 4 WITHOUT a local projection (keep it thin). Revisit in Phase 7 if admin LV needs abandoned-cart surface. Defer decision to Phase 7 research. This matches the "minimal projection, expand when admin LV proves need" pattern from D3-14/D3-15.

2. **Should the DLQ `requeue_where/2` bulk op take an advisory lock to prevent two concurrent bulk replays?**
   - What we know: Bulk cap (`max_rows: 10_000`) + stagger_ms + unique constraint on `webhook_event.status` prevents double-enqueue.
   - What's unclear: Two ops engineers running bulk replay simultaneously could double the load on Stripe.
   - Recommendation: No advisory lock in Phase 4. Mix task prints "N rows match; requeueing in batches of 100 with 1s stagger; use --dry-run to preview" and logs loud. Document advisory locking as a Phase 7 admin LV concern (single-admin UI coordination is easier than DB locks).

3. **For BILL-14 comped subscriptions, should we create the "comp_100_forever" coupon automatically on first use, or require the host to define it in config?**
   - What we know: The coupon is a user-facing concept that may want a different name per host (e.g., "beta tester comp" vs "support comp").
   - Recommendation: Require host config `config :accrue, :comp_coupon_id` (no auto-create). Document the Stripe Dashboard creation step in the install guide. This keeps the library agnostic about coupon naming.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `lattice_stripe` sibling repo | BILL-13, CHKT-02, CHKT-04, BILL-16 | ✓ (on disk) | `1.1.0` code-complete on `main` | — |
| PostgreSQL 14+ | New migrations (5 schemas) | Assumed (host-provided) | ≥ 14 | — |
| Oban community edition | New queues `:accrue_dunning`, `:accrue_meters` | Assumed (existing in Phase 2) | `~> 2.21` | — |
| Chrome/Chromium | N/A (Phase 4 does no PDF work) | — | — | — |
| `telemetry_metrics` | OBS-05 optional recipe | Optional in deps | `~> 1.1` | Recipe returns `[]` when not loaded |

**No blockers.** Everything needed is either already in deps or available in the sibling repo.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + `Accrue.BillingCase` template (verified at `accrue/test/support/` — wraps sandbox, Fake processor, operation_id seed) |
| Config file | `accrue/config/test.exs` (existing) |
| Quick run command | `cd accrue && mix test --warnings-as-errors --max-failures 1` |
| Full suite command | `cd accrue && mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BILL-11 | Pause/resume with behavior option sets `pause_collection` correctly + webhook flips `paused_at` | unit + integration | `mix test test/accrue/billing/subscription_actions_test.exs` | Wave 0 extension |
| BILL-12 | `add_item/3`, `remove_item/2`, `update_item_quantity/3` round-trip through Fake | integration | `mix test test/accrue/billing/subscription_item_actions_test.exs` | ❌ Wave 0 |
| BILL-13 | `report_usage/3` inserts pending row → calls Fake → marks reported | integration | `mix test test/accrue/billing/meter_events_test.exs` | ❌ Wave 0 |
| BILL-13 | `report_usage/3` with Stripe error marks row failed + fires `[:accrue, :ops, :meter_reporting_failed]` | integration | same file | ❌ Wave 0 |
| BILL-13 | `ReconcilerJob` retries `pending AND inserted_at < now - 60s` | unit | `mix test test/accrue/workers/meter_events_reconciler_test.exs` | ❌ Wave 0 |
| BILL-13 | `v1.billing.meter.error_report_triggered` webhook flips matching rows to failed | integration | `mix test test/accrue/webhook/handlers/meter_error_test.exs` | ❌ Wave 0 |
| BILL-13 | Property: idempotency key is deterministic for same `(customer, event_name, value, ts)` | property | same file; StreamData | ❌ Wave 0 |
| BILL-14 | `comp_subscription/2` creates sub with `coupon_id` from config, no payment method required | integration | `mix test test/accrue/billing/comp_test.exs` | ❌ Wave 0 |
| BILL-15 | `SweeperJob` queries candidates, calls Stripe `subscription.update(status: unpaid)`, does NOT flip local | unit | `mix test test/accrue/billing/dunning_sweeper_test.exs` | ❌ Wave 0 |
| BILL-15 | Webhook `customer.subscription.updated` with `past_due → unpaid` fires `[:accrue, :ops, :dunning_exhaustion]` in same txn | integration | `mix test test/accrue/webhook/handlers/customer_subscription_updated_test.exs` | Wave 0 extension |
| BILL-15 | `past_due_since` column bumps forward on each `invoice.payment_failed.next_payment_attempt` | integration | `mix test test/accrue/webhook/handlers/invoice_payment_failed_test.exs` | Wave 0 extension |
| BILL-16 | Create schedule via `from_subscription` → row persisted + Stripe called | integration | `mix test test/accrue/billing/subscription_schedule_test.exs` | ❌ Wave 0 |
| BILL-16 | Webhook `subscription_schedule.updated` with new `current_phase.start_date` → `current_phase_index` bumps | integration | `mix test test/accrue/webhook/handlers/subscription_schedule_updated_test.exs` | ❌ Wave 0 |
| BILL-27 | `Coupon.create/2`, `PromotionCode.create/2` round-trip through Fake | integration | `mix test test/accrue/billing/coupon_actions_test.exs` | ❌ Wave 0 |
| BILL-27 | `apply_promotion_code/2` updates sub.coupon_id via Stripe | integration | same file | ❌ Wave 0 |
| BILL-28 | Invoice webhook with `total_discount_amounts` → invoice.discount_minor set | integration | `mix test test/accrue/webhook/handlers/invoice_finalized_test.exs` | Wave 0 extension |
| CHKT-01 | `Checkout.Session.create/2` rejects missing `mode`, applies defaults | integration | `mix test test/accrue/checkout/session_test.exs` | ❌ Wave 0 |
| CHKT-02 | `mode: :hosted` returns `%Session{url: _}`; `mode: :embedded` returns `%Session{client_secret: _}` | integration | same file | ❌ Wave 0 |
| CHKT-03 | `LineItem.from_price/2` + `from_price_data/1` produce Stripe-shaped maps | unit | `mix test test/accrue/checkout/line_item_test.exs` | ❌ Wave 0 |
| CHKT-04 | `BillingPortal.Session.create/2` requires customer, passes flow_data through guards | integration | `mix test test/accrue/billing_portal/session_test.exs` | ❌ Wave 0 |
| CHKT-05 | `Accrue.BillingPortal.Session.create/2` accepts `configuration: "bpc_..."` opt | unit | same file | ❌ Wave 0 |
| CHKT-06 | `Checkout.reconcile/1` refetches from Stripe + mirrors to local projection | integration | `mix test test/accrue/checkout_reconcile_test.exs` | ❌ Wave 0 |
| WH-08 | `DLQ.requeue/1` on `:dead` event → inserts Oban job + marks `:received` + writes `webhook_replayed` event | integration | `mix test test/accrue/webhooks/dlq_test.exs` | ❌ Wave 0 |
| WH-08 | `DLQ.requeue/1` on `:replayed` event → `{:error, :already_replayed}` | unit | same file | ❌ Wave 0 |
| WH-08 | `DLQ.requeue_where/2` with `dry_run: true` returns count without mutation | integration | same file | ❌ Wave 0 |
| WH-08 | `DLQ.requeue_where/2` exceeding `max_rows` without `force: true` returns `{:error, :replay_too_large}` | unit | same file | ❌ Wave 0 |
| WH-08 | Dispatch worker with `{:error, :not_found}` from Processor → terminal-skip (status `:replayed`), no re-dead-letter | integration | `mix test test/accrue/webhook/dispatch_worker_test.exs` | Wave 0 extension |
| WH-08 | `mix accrue.webhooks.replay <event_id>` CLI end-to-end | integration | `mix test test/mix/tasks/accrue_webhooks_replay_test.exs` | ❌ Wave 0 |
| WH-13 | Plug selects secret by path suffix `/stripe` vs `/stripe/connect` | integration | `mix test test/accrue/webhook/plug_test.exs` | Wave 0 extension |
| WH-13 | Connect secret rejects payload signed with primary secret | integration | same file | Wave 0 extension |
| EVT-05 | `UpcasterRegistry.chain("foo.bar", 1, 3)` returns `[V1ToV2, V2ToV3]` | unit | `mix test test/accrue/events/upcaster_registry_test.exs` | ❌ Wave 0 |
| EVT-05 | Unknown schema_version surfaces `{:error, {:unknown_schema_version, v}}` (not swallowed) | unit | same file | ❌ Wave 0 |
| EVT-06 | `timeline_for/2` returns events in `inserted_at` ASC order | unit | `mix test test/accrue/events/query_test.exs` | ❌ Wave 0 |
| EVT-06 | `state_as_of/3` with ts in the past reconstructs state correctly AND routes old rows through upcasters | integration | same file | ❌ Wave 0 |
| EVT-06/10 | `bucket_by/3` with `:day`/`:week`/`:month` + type filter | integration | same file | ❌ Wave 0 |
| OBS-03 | `Accrue.Telemetry.Ops.emit/3` enforces `[:accrue, :ops \| _]` namespace | unit | `mix test test/accrue/telemetry/ops_test.exs` | ❌ Wave 0 |
| OBS-04 | No runtime test — convention guide in `guides/telemetry.md` | manual-only | N/A (doc lint at release time) | ❌ Wave 0 |
| OBS-05 | `Accrue.Telemetry.Metrics.defaults/0` returns a non-empty list when `:telemetry_metrics` is loaded | unit | `mix test test/accrue/telemetry/metrics_test.exs` | ❌ Wave 0 |
| OBS-05 | Recipe compiles successfully against `Telemetry.Metrics.Supervisor` | integration | same file | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test --warnings-as-errors --max-failures 1 <specific_file>`
- **Per wave merge:** `cd accrue && mix test --warnings-as-errors`
- **Phase gate:** Full suite green (`mix test`, `mix credo --strict`, `mix dialyzer`, `mix compile --warnings-as-errors`) before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/accrue/billing/meter_events_test.exs` — covers BILL-13 report_usage + reconciler + error-report handler
- [ ] `test/accrue/billing/subscription_item_actions_test.exs` — covers BILL-12
- [ ] `test/accrue/billing/comp_test.exs` — covers BILL-14
- [ ] `test/accrue/billing/dunning_sweeper_test.exs` — covers BILL-15 sweeper
- [ ] `test/accrue/billing/subscription_schedule_test.exs` — covers BILL-16
- [ ] `test/accrue/billing/coupon_actions_test.exs` — covers BILL-27
- [ ] `test/accrue/checkout/session_test.exs` + `line_item_test.exs` — covers CHKT-01/02/03
- [ ] `test/accrue/billing_portal/session_test.exs` — covers CHKT-04/05
- [ ] `test/accrue/checkout_reconcile_test.exs` — covers CHKT-06
- [ ] `test/accrue/webhooks/dlq_test.exs` — covers WH-08 library
- [ ] `test/mix/tasks/accrue_webhooks_replay_test.exs` — covers WH-08 mix task
- [ ] `test/accrue/events/upcaster_registry_test.exs` — covers EVT-05
- [ ] `test/accrue/events/query_test.exs` — covers EVT-06/10
- [ ] `test/accrue/telemetry/ops_test.exs` — covers OBS-03
- [ ] `test/accrue/telemetry/metrics_test.exs` — covers OBS-05
- [ ] `test/accrue/webhook/handlers/meter_error_test.exs` — meter error report webhook
- [ ] `test/accrue/webhook/handlers/subscription_schedule_updated_test.exs` — schedule phase diff
- [ ] Extend `test/accrue/webhook/handlers/customer_subscription_updated_test.exs` — dunning_exhaustion path
- [ ] Extend `test/accrue/webhook/plug_test.exs` — multi-endpoint secret lookup
- [ ] Extend `Accrue.Processor.Fake` with: `report_meter_event/1`, `portal_session_create/2`, `checkout_session_create/2`, `checkout_session_retrieve/1`, `subscription_schedule_create/2`, `subscription_schedule_update/3`, `subscription_schedule_cancel/2`, `subscription_schedule_release/2`, `coupon_create/2`, `promotion_code_create/2`
- [ ] Extend `Accrue.Test.StripeFixtures` with canned payloads for: `checkout.session.completed`, `subscription_schedule.{created,updated,released,completed,canceled,expiring}`, `v1.billing.meter.error_report_triggered`, `customer.subscription.{paused,resumed}`

*(Framework already installed — no install command needed.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (portal/checkout session URLs are short-lived bearer credentials) | Stripe hosts the session; Accrue masks `url` and `client_secret` in Inspect (lattice_stripe already does this) |
| V3 Session Management | yes | Single-use, ~5min Stripe-owned TTL; no Accrue session state |
| V4 Access Control | yes (Mix tasks for DLQ replay are destructive) | `--yes` confirmation required for `--all-dead`; log every replay to `accrue_events` with `actor_type: :admin` |
| V5 Input Validation | yes | NimbleOptions validates all new config keys; `report_usage/3` validates backdating window + future cap pre-network |
| V6 Cryptography | yes (webhook HMAC verification — unchanged from Phase 2) | `Accrue.Webhook.Signature` already shipped; WH-13 only swaps the secret |
| V7 Error Handling | yes | `{:error, :unknown_schema_version}` surfaces, not swallowed (EVT-05); meter errors logged not raised |
| V8 Data Protection | yes | `MeterEvent.payload` hidden in `Inspect` (lattice_stripe); Accrue stores derived fields only, never raw payload; `checkout.session.client_secret` masked |
| V9 Communications | N/A | No new network surface; lattice_stripe handles TLS |
| V10 Malicious Code | N/A | — |
| V11 Business Logic | yes | Dunning grace window must be "N days after Stripe stops retrying" NOT "N days after first failure" (D4-02 correctness) |
| V12 Files/Resources | N/A | — |
| V13 API | yes | Dual bang/tuple API; every new public fn has `@spec` + ExDoc |
| V14 Configuration | yes | `webhook_endpoints` config supports multiple signing secrets per endpoint (rotation-friendly) |

### Known Threat Patterns for Elixir/Phoenix Billing Library

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Webhook replay attack | Tampering, Repudiation | HMAC verification (Phase 2) + DB idempotency on `processor_event_id` (Phase 2) — unchanged |
| Forged webhook with attacker-controlled endpoint | Spoofing | Per-endpoint secret lookup via `webhook_endpoints` config; unknown endpoint → 401 |
| DLQ replay as denial of wallet (enqueue 10k Stripe API calls) | Denial of Service | `dlq_replay_max_rows` cap + `stagger_ms` pacing + `dry_run` default in CI |
| Meter event double-count on process crash | Integrity | Two-layer idempotency (body `identifier` + HTTP `idempotency_key:`) — Stripe dedupes |
| Meter event silent drop (async) → revenue loss | Integrity | `v1.billing.meter.error_report_triggered` webhook → `accrue_meter_events.stripe_status = "failed"` + `[:accrue, :ops, :meter_reporting_failed]` alert |
| Stripe Customer Portal "immediate cancel" bypasses dunning | Business Logic | Install-guide checklist (CHKT-05); runtime enforcement deferred to `BillingPortal.Configuration` in lattice_stripe 1.2 |
| Stripe portal session URL leaked via Logger | Information Disclosure | `Inspect` masks `url` in lattice_stripe; Accrue must mask in its own wrapping structs |
| Dunning sweeper races with concurrent webhook | Race condition | Sweeper marks `dunning_sweep_attempted_at` FIRST in its own txn — idempotent guard |
| Upcaster chain fails mid-replay → partial state | Integrity | `state_as_of/3` uses `reduce_while` to halt on first upcaster error; never returns partial state |
| Mix task runs in prod against wrong DB | Safety | Tasks call `Mix.Task.run("app.start")` which uses `config/runtime.exs` — same DB as running app. Document in install guide: always `--dry-run` first. |

## Sources

### Primary (HIGH confidence)

- `[VERIFIED: /Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing/meter.ex]` — BILL-13 Meter API shape
- `[VERIFIED: /Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing/meter_event.ex]` — BILL-13 MeterEvent two-layer idempotency contract
- `[VERIFIED: /Users/jon/projects/lattice_stripe/lib/lattice_stripe/billing_portal/session.ex]` — CHKT-04/05 FlowData guard + Configuration deferral
- `[VERIFIED: /Users/jon/projects/lattice_stripe/lib/lattice_stripe/checkout/session.ex]` — CHKT-01/02/03 mode-required pre-network guard
- `[VERIFIED: /Users/jon/projects/lattice_stripe/lib/lattice_stripe/subscription_schedule.ex]` — BILL-16 two creation modes, cancel vs release semantics
- `[VERIFIED: /Users/jon/projects/lattice_stripe/guides/metering.md]` — complete `AccrueLike.UsageReporter` recipe, error code table, reconciliation patterns
- `[VERIFIED: /Users/jon/projects/accrue/accrue/lib/accrue/events/upcaster.ex]` — Phase 1 behaviour scaffold, confirms Phase 4 only adds registry + read path wiring
- `[VERIFIED: /Users/jon/projects/accrue/.planning/phases/04-advanced-billing-webhook-hardening/04-CONTEXT.md]` — all four D4 locked decisions
- `[VERIFIED: /Users/jon/projects/accrue/.planning/REQUIREMENTS.md]` — 22 Phase 4 requirements, full traceability
- `[VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]` — tech stack pins (needs `~> 1.1` bump for lattice_stripe)

### Secondary (MEDIUM confidence)

- `[CITED: https://docs.stripe.com/billing/subscriptions/usage-based/recording-usage-api]` — BILL-13 primary Stripe reference
- `[CITED: https://docs.stripe.com/api/billing/meter-event]` — v1 MeterEvent API body-level `identifier` dedup contract
- `[CITED: https://docs.stripe.com/billing/revenue-recovery/smart-retries]` — BILL-15 Dashboard-only cap (8 attempts / 2 months)
- `[CITED: https://docs.stripe.com/billing/subscriptions/customer-portal]` — CHKT-04/05 portal session + Dashboard-managed config model
- `[CITED: https://docs.stripe.com/payments/checkout]` — CHKT-01/02/03 Checkout Session API
- `[CITED: https://hexdocs.pm/oban/Oban.html#retry_job/2]` — confirms `:discarded`/`:cancelled` refusal (D4-04 structural necessity)
- `[CITED: https://hexdocs.pm/oban/Oban.Plugins.Cron.html]` — host-wired cron pattern for Pruner/Sweeper/Reconciler
- `[CITED: https://laravel.com/docs/12.x/billing]` — Cashier `reportUsage` DX benchmark

### Tertiary (LOW confidence)

- `[ASSUMED]` — exact Postgres week-bucketing alignment (A4)
- `[ASSUMED]` — Stripe portal Dashboard toggle names (A3)
- `[ASSUMED]` — `subscription_schedule.expiring` exact lead-time window (A2)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; lattice_stripe 1.1 surface verified on disk
- Architecture: HIGH — all four pivotal decisions locked in CONTEXT.md, cross-verified against sibling repo
- Pitfalls: HIGH — ten pitfalls are derived from lattice_stripe guides and Stripe semantics documented in source
- Validation: HIGH — test map follows existing `Accrue.BillingCase` pattern, Wave 0 gap list is exhaustive
- Security: HIGH — webhook pipeline unchanged from Phase 2; new surfaces inherit existing HMAC + idempotency

**Research date:** 2026-04-14
**Valid until:** 2026-05-14 (30 days — stack is stable, only risk is lattice_stripe 1.1 getting additional commits post-research)

---

*Phase: 04-advanced-billing-webhook-hardening*
*Research conducted: 2026-04-14*
