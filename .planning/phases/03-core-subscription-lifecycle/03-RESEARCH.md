# Phase 3: Core Subscription Lifecycle - Research

**Researched:** 2026-04-14
**Domain:** Stripe subscription lifecycle, invoice state machine, PaymentIntent/SetupIntent 3DS handling, webhook ordering, fee-aware refunds, Ecto state projection
**Confidence:** HIGH (CONTEXT.md contains 86 locked decisions + lattice_stripe 1.0 is a sibling project we can grep directly)

## Summary

Phase 3 delivers the full Stripe subscription lifecycle on top of Phase 2's schema/webhook layer. CONTEXT.md has already locked 86 implementation decisions (D3-01 through D3-86) covering state machine shape, intent_result return type, proration API, cancel/pause verb split, PaymentMethod dedup, refund fee tracking, out-of-order webhook resolution, event taxonomy, and test factories. This research verifies the Stripe API primitives and lattice_stripe 1.0 function signatures the plans will call, confirms the state machine semantics against Stripe docs, and defines the validation architecture.

**Primary recommendation:** The planner should treat CONTEXT.md as authoritative and use this research only to (a) cite exact lattice_stripe function signatures for each call site, (b) confirm Stripe status/next_action enum values, (c) wire the Nyquist validation layers. No new architectural decisions are needed — the discuss phase was thorough.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (86 items, D3-01 through D3-86)

**State machine (D3-01..05):** Status is `Ecto.Enum` with Stripe's 8 values verbatim (`:trialing, :active, :past_due, :canceled, :unpaid, :incomplete, :incomplete_expired, :paused`). `cancel_at_period_end :boolean` and `pause_collection :map` are real denormalized columns. Predicates are pure function-head pattern matches. BILL-05 enforcement is three-layer: docs + custom `Accrue.Credo.NoRawStatusAccess` check + `Accrue.Billing.Query` fragments. NO `incomplete_expires_at` column — trust Stripe's webhook-driven expiry.

**Intent result type (D3-06..12):** Single canonical type:
```elixir
@type intent_result(ok) ::
  {:ok, ok}
  | {:ok, :requires_action, PaymentIntent.t() | SetupIntent.t()}
  | {:error, Accrue.Error.t()}
```
Applies ONLY to `charge/3`, `subscribe/2`, `swap_plan/3`, `pay_invoice/2`, `attach_payment_method/2`, and `cancel/2` when `invoice_now: true`. Other intent statuses (`requires_confirmation`, `requires_payment_method`) collapse into `{:error, %CardError{}}`. `subscribe/swap_plan` embed PI on `latest_invoice.payment_intent` — no 4-tuple. `attach_payment_method/2` uses the same `:requires_action` tag with a `%SetupIntent{}`. `!` variants raise `Accrue.ActionRequiredError{payment_intent}`.

**Invoice projection (D3-13..18):** Hybrid — typed rollup columns on `accrue_invoices` (status, subtotal_minor, tax_minor, discount_minor, total_minor, amount_due_minor, amount_paid_minor, amount_remaining_minor, currency, number, hosted_url, pdf_url, period_start, period_end, due_date, collection_method, billing_reason, finalized_at, paid_at, voided_at, last_stripe_event_ts, last_stripe_event_id, metadata, data, lock_version) + real `accrue_invoice_items` child table + jsonb detail. Workflow actions share one Repo.transact shape: Stripe call → put_data → decompose to typed columns + child items (same deterministic function as webhook path) → Events.record_multi → commit. User-path changeset validates transitions; webhook path uses `force_status_changeset/2` bypass.

**Proration + swap (D3-19..25):** Dedicated `%Accrue.Billing.UpcomingInvoice{}` struct (not reused `Invoice`). `:proration` atom set matches Stripe 1:1: `:create_prorations | :none | :always_invoice`. `swap_plan/3` opts validated by NimbleOptions, `:proration` REQUIRED with no default — missing raises `ArgumentError` with exact error text from D3-22. Preview is optional (not required-before-commit). No caching in v1.0. `swap_plan/3` returns `intent_result(Subscription.t())`.

**Cancel/pause verbs (D3-26..30a):** Two cancel verbs — `cancel/2` (immediate) and `cancel_at_period_end/2` (soft, with `:at` for future date). Strict `resume/1` (canceling only) vs `unpause/1` (paused only) split — paused+canceling requires two calls. `pause/2` opts: `:behavior :void|:mark_uncollectible|:keep_as_draft`, `:resumes_at`. `cancel/2` opts: `invoice_now: false` (default), `prorate: false` (default). Only `cancel/2 + invoice_now: true` returns `intent_result`; others return `{:ok, Subscription.t()}`. `swap_plan/3` on canceling sub implicitly unsets `cancel_at_period_end` (Stripe behavior, documented). No `grace_period_remaining` virtual field.

**SubscriptionItem scope (D3-31..37):** Phase 3 = "single-item write, any-item read." `subscribe/2` accepts `price_id` OR `{price_id, quantity}` — list raises `ArgumentError`. `swap_plan/3` raises `Accrue.Error.MultiItemSubscription` if `length(items) > 1`. Webhook reconciler MUST handle N items correctly (upsert by processor_id, delete orphans). `get_subscription/1,2` auto-preloads `:subscription_items`. Metered read-only (no `report_usage/3` — Phase 4). Ship `update_quantity/2` (pure quantity delta, single-item guard).

**Trials (D3-38..44):** `:trial_end` accepts `:now | DateTime.t() | {:days, pos_integer()} | Duration.t()`. Reject unix ints and `:trial_period_days`. Normalize to DateTime at boundary. NO local Oban scheduling for `trial_will_end` (Stripe owns trial state). User handler event name is Stripe's (`:"customer.subscription.trial_will_end"`). Default handler emits `[:accrue, :billing, :subscription, :trial_ending]` telemetry span. Fake processor auto-synthesizes `trial_will_end` + `subscription.updated` webhooks on `advance/2` (test-story differentiator). Default trial_ending email fires on by default.

**Refund fees + WH-09 (D3-45..51):** Sync best-effort at create (`expand: ["balance_transaction", "charge.balance_transaction"]`) + webhook backstop + daily reconciler Oban cron (`Accrue.Jobs.ReconcileRefundFees`, `Accrue.Jobs.ReconcileChargeFees`, sweeping rows with `fees_settled_at IS NULL AND inserted_at < now() - 24h`). Refund return stays uniform `{:ok, %Refund{}}` — no `:pending_fees` tag. WH-09 resolution: `last_stripe_event_ts :utc_datetime_usec` + `last_stripe_event_id :string` columns on every billing schema. Handler flow: load row → skip-stale check (`event.stripe_created_at < row.last_stripe_event_ts` → emit `[:accrue, :webhooks, :stale_event]`, mark `stale = true`, return `:ok`) → otherwise `Processor.fetch/1` canonical → put_data → bump ts/id → Events.record_multi. Tie on equal ts → don't skip. Skip-stale lives in `Accrue.Webhook.DefaultHandler`, NOT a macro.

**PaymentMethod dedup + default (D3-52..59):** Attach-time application check + partial unique index backstop: `CREATE UNIQUE INDEX accrue_payment_methods_customer_fingerprint_idx ON accrue_payment_methods (customer_id, fingerprint) WHERE fingerprint IS NOT NULL`. Fingerprint-null PMs (Link, some bank debits) always insert fresh. Return shape uses virtual `existing?: boolean` on PM struct (NOT a 3-tuple tag). Default PM = `default_payment_method_id :binary_id` nullable FK on `accrue_customers` with `ON DELETE SET NULL`. `set_default_payment_method/2` asserts PM attached (else `%Accrue.Error.NotAttached{}`). `charge/3` without PM reads customer default; nil → `%Accrue.Error.NoDefaultPaymentMethod{customer_id}`. Subscription-level default PM override is Phase 4.

**Idempotency + operation_id (D3-60..64):** Pre-generate resource UUID BEFORE Stripe call using `Ecto.UUID.cast!(binary_part(:crypto.hash(:sha256, "#{op}|#{operation_id}"), 0, 16))` — same UUID plays three roles (PK / idempotency subject / event subject). Retries converge to same UUID. Ship `Accrue.Plug.PutOperationId` (after `Plug.RequestId`), `Accrue.LiveView.on_mount :accrue_operation`, `Accrue.Oban.Middleware` (`operation_id = "oban-#{job.id}-#{job.attempt}"`). Cron seed: `"cron-#{worker}-#{cron_expression_hash}-#{scheduled_at_unix}"`. Random fallback logs warning in `:dev`, refuses in `:strict`. Sequence suffix `opts[:sequence]` folds into hash for multi-call requests.

**Event taxonomy (D3-65..70):** Dotted atom strings. 24 Phase 3 events: `subscription.created, subscription.updated, subscription.trial_started, subscription.trial_ended, subscription.canceled, subscription.resumed, subscription.paused, subscription.plan_swapped, invoice.created, invoice.finalized, invoice.paid, invoice.payment_failed, invoice.voided, invoice.marked_uncollectible, charge.succeeded, charge.failed, charge.refunded, refund.created, refund.fees_settled, payment_method.attached, payment_method.detached, payment_method.updated, customer.default_payment_method_changed, card.expiring_soon`. Modality in payload (`subscription.canceled` carries `%{mode: :at_period_end | :immediate | :scheduled}`). One module per event in `Accrue.Events.Schemas.*`, `@derive Jason.Encoder`, NimbleOptions validation in dev/test only. All Phase 3 events at `schema_version: 1`. Reflexive subject rule — subject is the changed entity, linked entities in payload.

**Expiring cards (D3-71..78):** Scheduled scan + webhook (modern PM expiry gets no webhook). Ship `Accrue.Jobs.DetectExpiringCards` Oban cron `@default_cron "0 8 * * *"`. Default thresholds `[30, 7, 1]`, configurable via `:expiring_card_thresholds`. Auto-update silent (event + telemetry, no email by default). One semantic email type `:card_expiring` — host branches on `@threshold`. Dedup via `accrue_events` query (last 365d per (pm_id, threshold)), NOT a new column. Default-PM escalation via telemetry metadata. Zero Phase 4 dunning coupling.

**Test factories (D3-79..85):** Plain function module at `accrue/lib/accrue/test/factory.ex`. No ExMachina. Nine first-class factories: `customer, subscription, trialing_subscription, active_subscription, past_due_subscription, canceled_subscription, incomplete_subscription, canceling_subscription, grace_period_subscription, trial_ending_subscription`. Sibling `Accrue.Test.Generators` for StreamData (gated). Factories route through `Accrue.Processor.Fake`, not `Repo.insert!`. Test-clock threading hard rule. Factories side-effect-pure. Async-safety regression test (100 concurrent trialing subs, ID uniqueness).

**Clock (D3-86):** Ship `Accrue.Clock` as canonical time source. Test env delegates to `Accrue.Processor.Fake.now/0`; dev/prod `DateTime.utc_now/0`.

### Claude's Discretion
- Module layout under `lib/accrue/billing/` (one file per schema/action vs grouped)
- Migration filenames + ordering (content constrained; filenames free)
- Internal decomposition of `Accrue.Webhook.DefaultHandler` (skip-stale-then-refetch-then-record triple must be explicit)
- Exact fields on `%Accrue.Events.Schemas.*{}` structs beyond reflexive-subject rule
- `Accrue.Billing.Query` macro/function boundary (composable in `where` is the only constraint)
- Test file organization, property-test placement
- Internal shape of `Accrue.Processor.Fake.transition/3`
- Whether NimbleOptions schemas live inline or in `Accrue.Billing.Schemas`
- Internal naming `Accrue.Jobs.*` vs `Accrue.Workers.*`

### Deferred Ideas (OUT OF SCOPE for Phase 3)
- Metered usage, `report_usage/3`, BillingMeter/MeterEvent → Phase 4 (also blocked on lattice_stripe 1.1)
- Multi-item write ops (`add_item`, `remove_item`, `update_items`) → Phase 4
- Free/comped tiers (subscribe without PM) → Phase 4
- Dunning orchestration → Phase 4
- Subscription schedules → Phase 4
- Coupon/promotion_code CRUD + redemption → Phase 4 (Phase 3 ships minimal schema only)
- Customer Portal + Checkout Session → Phase 4 (Portal blocked on lattice_stripe 1.1)
- Subscription-level default PM override → Phase 4
- `preview_upcoming_invoice/2` caching → v1.1+
- `:card_auto_updated` email → Phase 6 template work
- Escalating card-expiring email tones → host template logic
- Connect multi-endpoint webhooks → Phase 5
- Admin LiveView pages → Phase 7
- `Accrue.Test.advance_clock/2`, `trigger_event/2`, `assert_event_recorded/2` helpers → Phase 8
- `mix accrue.seed` → Phase 8
- OpenTelemetry span auto-wiring → Phase 8
- ExMachina integration — explicitly rejected
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-02 | `Accrue.Processor.Stripe` adapter delegating to lattice_stripe | Verified function signatures below (lattice_stripe 1.0 sibling source) |
| BILL-03 | Subscription create/retrieve/swap/cancel/resume/pause | D3-26..30, lattice_stripe `Subscription.create/update/cancel/resume/pause_collection` |
| BILL-04 | Subscription state machine trialing→active→past_due→incomplete/incomplete_expired→unpaid/paused→canceled | D3-01 Ecto.Enum verbatim Stripe values; Stripe Subscription object status reference |
| BILL-05 | Three canonical predicates never exposing `status` | D3-03..04 three-layer enforcement (docs + Credo check + Query fragments) |
| BILL-06 | Trial support with `trial_end`, `trial_will_end` webhook handling | D3-38..44; Stripe `customer.subscription.trial_will_end` fires ~3 days before `trial_end` |
| BILL-07 | `cancel_at_period_end` with grace tracking | D3-02 real column; D3-26 `cancel_at_period_end/2` verb |
| BILL-08 | Immediate cancel with optional final-invoice | D3-27 `cancel(sub, invoice_now: true, prorate: true)` |
| BILL-09 | Plan swap with **explicit** `:proration` | D3-20..22 NimbleOptions required opt, fail-loud ArgumentError |
| BILL-10 | `preview_upcoming_invoice/2` | D3-19 dedicated struct; lattice_stripe `Invoice.upcoming/3` + `Invoice.create_preview/3` |
| BILL-17 | Invoice state machine draft→open→paid\|void\|uncollectible | D3-13..17 hybrid projection + dual changeset paths |
| BILL-18 | Invoice line items, discounts, tax | D3-15 child schema, tax/per-line discounts in `data` jsonb |
| BILL-19 | `finalize/void/mark_uncollectible/pay/send` workflow | D3-18 one shape inside `Repo.transact/2`; lattice_stripe `Invoice.finalize/void/pay/mark_uncollectible/send_invoice` verified |
| BILL-20 | Charge wrapper with idempotency | D3-60..64 pre-generated deterministic UUIDs |
| BILL-21 | PaymentIntent tagged return | D3-06..09 `intent_result/1` with embedded PI in subscription |
| BILL-22 | SetupIntent for off-session card-on-file | D3-10 same `:requires_action` tag with `%SetupIntent{}` |
| BILL-23 | PaymentMethod fingerprint dedup | D3-52..55 attach-time check + partial unique index + virtual `existing?` |
| BILL-24 | Expiring-card warnings via telemetry + events | D3-71..78 scheduled scan + webhook, events-table dedup |
| BILL-25 | Default PM management per customer | D3-56..58 FK on customers, loud errors on unset |
| BILL-26 | Fee-aware refunds | D3-45..47 sync best-effort + webhook backstop + daily reconciler |
| WH-09 | Out-of-order delivery resolution | D3-48..51 `last_stripe_event_ts/id` columns + skip-stale check |
| TEST-08 | Test fixtures for common subscription states | D3-79..85 nine factories routed through Fake, test-clock threading |
</phase_requirements>

## Standard Stack

### Core (already in deps from Phase 1/2)
| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| `lattice_stripe` | `~> 1.0` | Stripe API — Subscription, Invoice, PaymentIntent, SetupIntent, PaymentMethod, Customer, Charge, Refund, BalanceTransaction | [VERIFIED: sibling project at `/Users/jon/projects/lattice_stripe/`] |
| `ecto` / `ecto_sql` | `~> 3.13` | Ecto.Enum for status, Repo.transact/2 for atomic mutations, optimistic_lock | [CITED: CLAUDE.md] |
| `postgrex` | `~> 0.22` | Partial unique index for PM fingerprint dedup | [CITED: CLAUDE.md] |
| `oban` | `~> 2.21` | Cron workers: ReconcileRefundFees, ReconcileChargeFees, DetectExpiringCards | [CITED: CLAUDE.md] |
| `nimble_options` | `~> 1.1` | swap_plan/3, pause/2, cancel/2 opts validation; required :proration enforcement | [CITED: CLAUDE.md] |
| `jason` | `~> 1.4` | `@derive Jason.Encoder` on event payload structs | [CITED: CLAUDE.md] |
| `telemetry` | `~> 1.3` | Span events on every billing context function | [CITED: CLAUDE.md] |

### No new runtime deps for Phase 3
All primitives come from Phase 1/2. Phase 3 is purely domain logic and state machines.

**Version verification:** Not needed — CLAUDE.md verified all versions on 2026-04-11 (3 days ago). Deps lock already written in Phase 1 mix.exs.

## Key APIs & lattice_stripe Function Signatures

All verified via Grep against `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/` [VERIFIED: source inspection 2026-04-14].

### Subscription
```elixir
LatticeStripe.Subscription.create(client, params, opts)
LatticeStripe.Subscription.retrieve(client, id, opts)
LatticeStripe.Subscription.update(client, id, params, opts)
LatticeStripe.Subscription.cancel(client, id, opts)                  # 3-arity, DELETE /subscriptions/:id
LatticeStripe.Subscription.cancel(client, id, params, opts)          # 4-arity with invoice_now/prorate
LatticeStripe.Subscription.resume(client, id, opts)                  # POST /subscriptions/:id/resume
LatticeStripe.Subscription.pause_collection(client, id, behavior, params, opts)
  # behavior :: :keep_as_draft | :mark_uncollectible | :void
  # Implemented in lattice_stripe as update-with-pause_collection convenience
LatticeStripe.Subscription.list(client, params, opts)
```

**Key params for `create`:** `customer, items: [%{price, quantity}], trial_end (unix), default_payment_method, payment_behavior, proration_behavior, metadata, expand: ["latest_invoice.payment_intent"]` [CITED: https://stripe.com/docs/api/subscriptions/create].

**Key params for `update` (swap path):** `items: [%{id: si_xxx, price: price_new, quantity}], proration_behavior: "create_prorations" | "none" | "always_invoice", proration_date, billing_cycle_anchor, payment_behavior, cancel_at_period_end, cancel_at, expand: ["latest_invoice.payment_intent"]`.

**Key params for `cancel` (immediate DELETE):** `invoice_now :: boolean, prorate :: boolean`.

### Invoice
```elixir
LatticeStripe.Invoice.create(client, params, opts)
LatticeStripe.Invoice.retrieve(client, id, opts)
LatticeStripe.Invoice.update(client, id, params, opts)
LatticeStripe.Invoice.finalize(client, id, params, opts)             # POST /invoices/:id/finalize
LatticeStripe.Invoice.void(client, id, params, opts)                 # POST /invoices/:id/void
LatticeStripe.Invoice.pay(client, id, params, opts)                  # POST /invoices/:id/pay
LatticeStripe.Invoice.send_invoice(client, id, params, opts)         # POST /invoices/:id/send (note: send_invoice, not send — `send` is reserved in Elixir)
LatticeStripe.Invoice.mark_uncollectible(client, id, params, opts)
LatticeStripe.Invoice.upcoming(client, params, opts)                 # GET /invoices/upcoming (deprecated in recent Stripe API)
LatticeStripe.Invoice.create_preview(client, params, opts)           # POST /invoices/create_preview (new, 2024+ replacement for upcoming)
LatticeStripe.Invoice.upcoming_lines(client, params, opts)
LatticeStripe.Invoice.create_preview_lines(client, params, opts)
LatticeStripe.Invoice.list_line_items(client, invoice_id, params, opts)
```

**Important:** Stripe deprecated `GET /invoices/upcoming` in favor of `POST /invoices/create_preview` in 2024. Phase 3 should prefer `create_preview/3` for BILL-10 with `upcoming/3` as a fallback — lattice_stripe exposes both. [VERIFIED: lattice_stripe source exposes both].

**Preview params:** `customer, subscription, subscription_details.items, subscription_details.proration_behavior, subscription_details.proration_date, schedule` [CITED: https://stripe.com/docs/api/invoices/create_preview].

### PaymentIntent
```elixir
LatticeStripe.PaymentIntent.create(client, params, opts)
LatticeStripe.PaymentIntent.retrieve(client, id, opts)
LatticeStripe.PaymentIntent.update(client, id, params, opts)
LatticeStripe.PaymentIntent.confirm(client, id, params, opts)
LatticeStripe.PaymentIntent.cancel(client, id, params, opts)
LatticeStripe.PaymentIntent.list(client, params, opts)
```

**Status enum (from Stripe API):** `requires_payment_method | requires_confirmation | requires_action | processing | requires_capture | canceled | succeeded` [CITED: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-status].

**Accrue mapping per D3-08:**
- `succeeded` → `{:ok, %PaymentIntent{}}`
- `requires_action` → `{:ok, :requires_action, %PaymentIntent{}}` (SCA path)
- `requires_confirmation` → `{:error, %Accrue.CardError{}}`
- `requires_payment_method` → `{:error, %Accrue.CardError{}}`
- `processing` → `{:ok, %PaymentIntent{status: :processing}}`
- `requires_capture` → `{:ok, %PaymentIntent{status: :requires_capture}}`
- `canceled` → `{:error, %Accrue.CardError{}}`

**3DS detection via `next_action.type`:** When `status == "requires_action"`, inspect `next_action.type` (`"use_stripe_sdk" | "redirect_to_url" | "verify_with_microdeposits"`). The `client_secret` on the PI is what host apps pass to Stripe.js to complete SCA. Accrue surfaces the PI struct; host renders. [CITED: https://stripe.com/docs/payments/payment-intents#passing-to-client].

### SetupIntent
Mirror of PaymentIntent — `create/retrieve/update/confirm/cancel/list`. Same status enum (minus `requires_capture`, `processing`). Used for off-session card-on-file capture (BILL-22). Returns `%SetupIntent{}` in the `:requires_action` tag slot when 3DS is required to save the card.

### PaymentMethod
```elixir
LatticeStripe.PaymentMethod.create(client, params, opts)
LatticeStripe.PaymentMethod.retrieve(client, id, opts)
LatticeStripe.PaymentMethod.update(client, id, params, opts)
LatticeStripe.PaymentMethod.list(client, params, opts)
LatticeStripe.PaymentMethod.attach(client, id, params, opts)
LatticeStripe.PaymentMethod.detach(client, id, params, opts)
```

**Fingerprint path:** Raw Stripe payload is `payment_method.card.fingerprint` (a hash that's stable for the same underlying card across tokenizations). Not a Card on the Stripe PM object in 2024+ — the PM object nests `card.fingerprint`. [CITED: https://stripe.com/docs/api/payment_methods/object]. Fingerprint is NULL for some PM types (Link, some bank_account debits per D3-53).

**Dedup implementation:** Grep against source confirmed lattice_stripe does NOT provide a dedup helper — application-level. Phase 3 wraps in `attach_payment_method/2` per D3-52.

### Charge
```elixir
LatticeStripe.Charge.*  # create/retrieve/update/capture/list
# expand: ["balance_transaction"] populates fee breakdown for BILL-26
```

Charge's `balance_transaction` → `BalanceTransaction.fee`, `BalanceTransaction.fee_details[]`, `BalanceTransaction.net`. Required for `stripe_fee_amount` column. [CITED: https://stripe.com/docs/api/balance_transactions].

### Refund
```elixir
LatticeStripe.Refund.create(client, params, opts)
LatticeStripe.Refund.retrieve(client, id, opts)
LatticeStripe.Refund.update(client, id, params, opts)
LatticeStripe.Refund.cancel(client, id, params, opts)
LatticeStripe.Refund.list(client, params, opts)
```

**Fee expansion:** `LatticeStripe.Refund.create(client, %{charge: "ch_...", expand: ["balance_transaction", "charge.balance_transaction"]}, opts)`. The refund's own `balance_transaction.fee` is typically 0 (Stripe doesn't charge a fee to process a refund), but the original charge's `balance_transaction.fee` is the Stripe fee that may or may not be refunded depending on Stripe's fee-refund policy and the connected account config. The asymmetric loss = `charge.balance_transaction.fee - charge.balance_transaction.fee_refunded` — this is `merchant_loss_amount` per D3-45. [CITED: https://stripe.com/docs/refunds, https://stripe.com/docs/api/balance_transactions/object#balance_transaction_object-fee_details].

**Fee settlement timing:** Refund fee data may not populate synchronously at refund creation — `charge.refund.updated` webhook carries canonical fee data. D3-46 daily reconciler sweeps rows with `fees_settled_at IS NULL AND inserted_at < now() - 24h` as backstop.

### Customer
```elixir
LatticeStripe.Customer.update(client, id, %{invoice_settings: %{default_payment_method: pm_id}}, opts)
```
Path for `set_default_payment_method/2` per D3-57.

## State Machines

### Subscription State Machine (Stripe-faithful per D3-01)

Stripe's 8 canonical statuses [CITED: https://stripe.com/docs/api/subscriptions/object#subscription_object-status]:

| Status | Meaning | Accrue Predicate |
|--------|---------|------------------|
| `trialing` | In trial period, no charge yet | `active?/1 = true`, `trialing?/1 = true` |
| `active` | Paid and current | `active?/1 = true` |
| `past_due` | Payment failed, Stripe retrying | `past_due?/1 = true` |
| `unpaid` | Retries exhausted (per dunning config) | `past_due?/1 = true` |
| `canceled` | Terminal | `canceled?/1 = true` |
| `incomplete` | Initial charge failed, 23h window | (none true) |
| `incomplete_expired` | 23h window elapsed, terminal | `canceled?/1 = true` |
| `paused` | Legacy pre-2020 paused | `paused?/1 = true` |

**Modern pause is `pause_collection` map on active subscription** — status stays `active`, `pause_collection` is `%{behavior, resumes_at}`. D3-03 predicate pattern-matches both the legacy `:paused` status AND a present `pause_collection` map.

**Transitions observed via webhook (MUST all route through skip-stale + refetch per D3-48):**
- `trialing → active` (on trial_end)
- `active → past_due` (payment failed, retries in progress)
- `past_due → active` (retry succeeded)
- `past_due → unpaid` (retries exhausted per dunning policy)
- `past_due → canceled` (dunning exhausted with cancel policy)
- `active → canceled` (immediate cancel or cancel_at_period_end reached)
- `incomplete → active` (SCA completed, payment succeeded)
- `incomplete → incomplete_expired` (23h elapsed — D3-05 trusts Stripe's clock)
- `active → active (pause_collection set)` (pause)
- `active (pause_collection set) → active (nil)` (unpause)

**`canceling?/1` is NOT a status** — it's a derived predicate: `status == :active AND cancel_at_period_end == true AND current_period_end > now`.

### Invoice State Machine (per D3-14)

Stripe's 5 statuses [CITED: https://stripe.com/docs/api/invoices/object#invoice_object-status]:

| Status | Terminal? | User-path transition legal from | Webhook-path (force) |
|--------|-----------|------|----|
| `draft` | No | (creation only) | any |
| `open` | No | `draft` (via `finalize`) | any |
| `paid` | Yes | `open` (via `pay`) | any |
| `uncollectible` | Yes | `open` (via `mark_uncollectible`) | any |
| `void` | Yes | `draft`, `open` (via `void`) | any |

**D3-17 split:**
- `Accrue.Billing.Invoice.changeset/2` enforces legal transitions on user-initiated changes.
- `Accrue.Billing.Invoice.force_status_changeset/2` bypasses for webhook reconcile (Stripe is canonical, any state must be accepted).

## Proration & Preview

**Stripe proration_behavior enum** [CITED: https://stripe.com/docs/billing/subscriptions/prorations]:
- `"create_prorations"` — default in Stripe; creates prorating line items on next invoice.
- `"none"` — no proration; new price takes effect at next billing cycle.
- `"always_invoice"` — creates prorating line items AND immediately invoices them.

**Accrue 1:1 atom mapping per D3-20:** `:create_prorations | :none | :always_invoice`. Translated to string at lattice_stripe boundary.

**`swap_plan/3` opts (D3-21, NimbleOptions-validated):**
```elixir
[
  proration: [type: {:in, [:create_prorations, :none, :always_invoice]}, required: true],
  proration_date: [type: {:or, [:any, nil]}, default: nil],  # DateTime.t() | nil
  billing_cycle_anchor: [type: {:in, [:unchanged, :now]}, default: :unchanged],
  payment_behavior: [type: {:in, [:default_incomplete, :pending_if_incomplete, :error_if_incomplete, :allow_incomplete]}, default: :default_incomplete],
  quantity: [type: :pos_integer, default: nil],
  metadata: [type: :map, default: nil],
  operation_id: [type: :string, default: nil],
  stripe_api_version: [type: :string, default: nil]
]
```

**D3-22 error text (verbatim):** *"Accrue.Billing.swap_plan/3 requires an explicit :proration option (:create_prorations, :none, or :always_invoice). Accrue never inherits Stripe defaults — see BILL-09."*

**Preview via `create_preview/3`** (preferred over deprecated `upcoming/3`):
```elixir
LatticeStripe.Invoice.create_preview(client, %{
  customer: cus_id,
  subscription: sub_id,
  subscription_details: %{
    items: [%{id: si_id, price: new_price_id}],
    proration_behavior: "create_prorations",
    proration_date: proration_unix_ts
  }
}, opts)
```

Returns a full Invoice object with `lines.data` containing prorating credit + new-price-prorated line items. Phase 3 decomposes into `%Accrue.Billing.UpcomingInvoice{}` (D3-19) — typed Money fields, never persisted.

## SCA / 3DS Tagged Returns

### Detection logic
```elixir
defp wrap_intent_result({:ok, stripe_obj}) do
  case stripe_obj do
    %{latest_invoice: %{payment_intent: %{status: "requires_action"} = pi}} ->
      {:ok, :requires_action, pi}
    %{status: "requires_action"} = intent ->
      {:ok, :requires_action, intent}
    %{status: "succeeded"} = obj ->
      {:ok, obj}
    %{status: "requires_confirmation"} ->
      {:error, Accrue.CardError.requires_confirmation(stripe_obj)}
    %{status: "requires_payment_method"} ->
      {:error, Accrue.CardError.requires_payment_method(stripe_obj)}
    _ ->
      {:ok, stripe_obj}
  end
end
```

### Per-function application (D3-07 narrow doctrine)
| Function | Returns `intent_result`? | Why |
|----------|---|---|
| `subscribe/2` | Yes | Initial charge may need SCA |
| `swap_plan/3` | Yes | Proration invoice payment may need SCA |
| `charge/3` | Yes | Direct charge may need SCA |
| `pay_invoice/2` | Yes | Manual retry of failed invoice may need SCA |
| `attach_payment_method/2` | Yes | SetupIntent may need SCA |
| `cancel/2` with `invoice_now: true` | Yes | Final invoice payment may need SCA |
| `cancel/2` default | No | Plain `{:ok, Subscription.t()}` |
| `cancel_at_period_end/2` | No | No payment attempted |
| `resume/1` / `pause/2` / `unpause/1` | No | No payment attempted |
| `update_quantity/2` | No per D3-33 | Quantity delta on billing cycle boundary, Stripe invoices next period |
| `set_default_payment_method/2` | No | No payment attempted |

### `!` variants
Per D3-11, `!` variants raise `Accrue.ActionRequiredError{payment_intent: pi}` on the requires_action branch. Example:
```elixir
def subscribe!(billable, price_id, opts \\ []) do
  case subscribe(billable, price_id, opts) do
    {:ok, sub} -> sub
    {:ok, :requires_action, pi} -> raise Accrue.ActionRequiredError, payment_intent: pi
    {:error, err} -> raise err
  end
end
```

## Webhook Ordering & Idempotency (WH-09)

Per D3-48, every billing schema gets `last_stripe_event_ts :utc_datetime_usec` and `last_stripe_event_id :string`. The default handler flow is:

```elixir
def handle(%{type: type, id: evt_id, created: created_unix, data: %{object: obj}} = _event) do
  evt_ts = DateTime.from_unix!(created_unix)
  Repo.transact(fn ->
    with {:ok, row} <- load_row_by_stripe_id(obj["id"]),
         :ok <- check_not_stale(row, evt_ts, evt_id),
         {:ok, canonical} <- Processor.fetch(obj["object"], obj["id"]),
         {:ok, updated} <- put_data_and_bump_ts(row, canonical, evt_ts, evt_id),
         {:ok, _event_row} <- Events.record_multi(actor: :webhook, subject: updated, type: derive_event_type(type), payload: %{source: :webhook}) do
      {:ok, updated}
    else
      :stale ->
        :telemetry.execute([:accrue, :webhooks, :stale_event], %{}, %{type: type, id: evt_id})
        mark_webhook_row_stale(evt_id)
        {:ok, :stale}
    end
  end)
end

defp check_not_stale(%{last_stripe_event_ts: nil}, _, _), do: :ok
defp check_not_stale(%{last_stripe_event_ts: last}, evt_ts, _) do
  case DateTime.compare(evt_ts, last) do
    :lt -> :stale
    _ -> :ok   # :gt or :eq both proceed (D3-49: tie → don't skip)
  end
end
```

**Key points:**
- D3-48 step 2: when stale, **skip the refetch entirely**. Refetching on a stale event would race with the newer event's handler. This is orthogonal to D2-29 (don't trust payload snapshots), not a violation.
- D3-50: Out-of-order `charge.refund.updated` before `charge.refunded` → refetch is canonical (upsert by stripe_id if row doesn't exist). No queue-for-later.
- D3-51: Logic lives in `DefaultHandler`, NOT a macro — keeps the `optimistic_lock + Events.record_multi + telemetry` triple explicit.

**Stripe event fields used** [CITED: https://stripe.com/docs/api/events/object]:
- `id` — `evt_xxx`
- `created` — unix timestamp (seconds)
- `type` — dotted string like `customer.subscription.updated`
- `data.object` — snapshot at event time (NOT trusted per D2-29; we refetch)

## Fee-Aware Refunds

### Stripe fee data shape
```
charge.balance_transaction = %BalanceTransaction{
  fee: 320,               # cents, Stripe fee on original charge
  fee_details: [
    %{amount: 320, type: "stripe_fee", currency: "usd", description: "..."},
    # Connect apps may have additional "application_fee" entries
  ],
  net: 9680
}
```

On refund:
```
refund = %Refund{
  amount: 10000,
  charge: "ch_xxx",
  balance_transaction: %BalanceTransaction{
    fee: 0,              # refund itself has no fee
    ...
  },
  # After async settlement:
  # charge.balance_transaction.fee_refunded is the key field
}
```

**Math per D3-45:**
```elixir
stripe_fee_amount = charge.balance_transaction.fee              # ~320 (cents)
stripe_fee_refunded_amount = charge.balance_transaction.fee_refunded  # 0, partial, or full
merchant_loss_amount = stripe_fee_amount - stripe_fee_refunded_amount  # The Stripe fee the merchant eats
```

**Policy:** Stripe's standard policy refunds the percentage fee on refunds but NOT the fixed fee ($0.30 on US cards) for partial refunds [CITED: https://support.stripe.com/questions/understanding-fees-for-refunded-payments]. Varies by region and card type. The asymmetric loss is what BILL-26 exposes.

**Settlement delay:** `fee_refunded` populates on the charge's balance_transaction asynchronously (often within seconds, but not guaranteed). `charge.refund.updated` webhook carries canonical. D3-46 daily reconciler handles dropped webhooks.

## Payment Method Dedup

### Stripe fingerprint semantics
`payment_method.card.fingerprint` is a hash that is **stable per unique card across tokenizations and customers** [CITED: https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-fingerprint]. The same physical card tokenized 10 times by different users yields the same fingerprint. Not all PM types have fingerprint (D3-53 — Link, some bank_account, crypto, etc.).

### Dedup algorithm per D3-52
```elixir
def attach_payment_method(customer, pm_id, opts \\ []) do
  Repo.transact(fn ->
    with {:ok, canonical_pm} <- Processor.retrieve_payment_method(pm_id),
         :ok <- ensure_customer_relation(canonical_pm, customer),
         fingerprint <- get_in(canonical_pm, [:card, :fingerprint]),
         {:ok, result} <- dedup_or_insert(customer, canonical_pm, fingerprint) do
      # ... Events.record_multi
      {:ok, result}
    end
  end)
end

defp dedup_or_insert(customer, pm, nil), do: insert_new(customer, pm)  # D3-53
defp dedup_or_insert(customer, pm, fingerprint) do
  case Repo.one(from p in PaymentMethod,
                where: p.customer_id == ^customer.id and p.fingerprint == ^fingerprint) do
    nil ->
      try do
        insert_new(customer, pm)
      rescue
        Ecto.ConstraintError ->
          # Concurrent race — another process inserted first
          Processor.detach_payment_method(pm.id)
          existing = Repo.get_by!(PaymentMethod, customer_id: customer.id, fingerprint: fingerprint)
          {:ok, %{existing | existing?: true}}
      end
    existing ->
      Processor.detach_payment_method(pm.id)   # detach the duplicate on Stripe
      {:ok, %{existing | existing?: true}}
  end
end
```

**Partial unique index backstop (migration):**
```sql
CREATE UNIQUE INDEX accrue_payment_methods_customer_fingerprint_idx
  ON accrue_payment_methods (customer_id, fingerprint)
  WHERE fingerprint IS NOT NULL;
```

## Trial Management

**Stripe trial params on subscription create/update:**
- `trial_end` — unix timestamp OR `"now"` string
- `trial_period_days` — integer (Accrue rejects per D3-38; always normalizes to `trial_end`)
- `trial_settings.end_behavior.missing_payment_method` — `"cancel" | "create_invoice" | "pause"` [CITED: https://stripe.com/docs/api/subscriptions/create#create_subscription-trial_settings-end_behavior-missing_payment_method]

**Accrue `:trial_end` forms per D3-38:**
```elixir
case opts[:trial_end] do
  :now -> "now"
  %DateTime{} = dt -> DateTime.to_unix(dt)
  {:days, n} when is_integer(n) and n > 0 ->
    Accrue.Clock.utc_now() |> DateTime.add(n, :day) |> DateTime.to_unix()
  %Duration{} = d ->
    Accrue.Clock.utc_now() |> DateTime.shift(d) |> DateTime.to_unix()
  int when is_integer(int) -> raise ArgumentError, "unix ints rejected; use DateTime or {:days, N}"
  :trial_period_days -> raise ArgumentError, "use {:days, N} sugar instead"
end
```

**`customer.subscription.trial_will_end` webhook** fires approximately 3 days before `trial_end` [CITED: https://stripe.com/docs/api/events/types#event_types-customer.subscription.trial_will_end]. Stripe is canonical — Accrue does NOT schedule local Oban jobs (D3-39).

**Fake processor synthesis (D3-42):** `Accrue.Processor.Fake.advance(sub_id, days: 14)` internally:
1. Advances test clock
2. Checks if crossing `trial_end - 3d` → synthesize `customer.subscription.trial_will_end` event, route through webhook pipeline
3. Checks if crossing `trial_end` → synthesize `customer.subscription.updated` with `status: "active"` transition, route through webhook pipeline
4. Opt-out via `synthesize_webhooks: false`

## Schema Additions

Per `<code_context>` in CONTEXT.md and new-schema list:

### New tables
| Table | Key columns |
|-------|------------|
| `accrue_refunds` | id (binary_id), charge_id FK, stripe_id, amount (Money), currency, reason, status (Ecto.Enum), stripe_fee_refunded_amount (Money), merchant_loss_amount (Money), fees_settled_at, data jsonb, metadata, lock_version, last_stripe_event_ts, last_stripe_event_id, inserted_at, updated_at |
| `accrue_invoice_items` | id, invoice_id FK, stripe_id, description, amount_minor, currency, quantity, period_start, period_end, proration (bool), price_ref, subscription_item_ref, data jsonb, inserted_at, updated_at |
| `accrue_invoice_coupons` | id, invoice_id FK, coupon_id FK, amount_off_minor, inserted_at |
| `accrue_coupons` | id, stripe_id, name, percent_off, amount_off_minor, currency, duration, duration_in_months, max_redemptions, redeem_by, data jsonb, inserted_at, updated_at (minimal; full CRUD Phase 4 per D3-16) |

### Column additions to existing tables
| Table | Columns | Purpose |
|-------|---------|---------|
| `accrue_subscriptions` | `status` → `Ecto.Enum` (was `:string`), `cancel_at_period_end :boolean` default false, `pause_collection :map`, `last_stripe_event_ts`, `last_stripe_event_id` | D3-01, D3-02, D3-48 |
| `accrue_subscription_items` | `price_id`, `processor_plan_id`, `processor_product_id`, `current_period_start`, `current_period_end` (fill-out), `last_stripe_event_ts`, `last_stripe_event_id` | D3-31 |
| `accrue_invoices` | Full D3-14 rollup column set | D3-14 |
| `accrue_charges` | `stripe_fee_amount` (Money), `fees_settled_at`, `last_stripe_event_ts`, `last_stripe_event_id` | D3-45, D3-48 |
| `accrue_payment_methods` | `fingerprint :string`, `exp_month :integer`, `exp_year :integer`, partial unique index on `(customer_id, fingerprint) WHERE fingerprint IS NOT NULL`, `last_stripe_event_ts`, `last_stripe_event_id` + virtual `existing?: boolean` field | D3-52, D3-55 |
| `accrue_customers` | `default_payment_method_id :binary_id` nullable FK with `ON DELETE SET NULL`, `last_stripe_event_ts`, `last_stripe_event_id` | D3-56, D3-48 |

## Architecture Patterns

### Pattern 1: Workflow Action Shape (D3-18)
**What:** Every state-mutating public function follows one shape.
**When to use:** Any Billing context function that calls Stripe + persists state.
**Example:**
```elixir
def finalize_invoice(invoice, opts \\ []) do
  operation_id = Accrue.Actor.current_operation_id!()
  subject_uuid = invoice.id  # existing row
  idempotency_key = Accrue.Processor.idempotency_key(:finalize_invoice, subject_uuid, operation_id)

  Accrue.Telemetry.span([:accrue, :billing, :invoice, :finalize], %{invoice_id: invoice.id}, fn ->
    Repo.transact(fn ->
      with {:ok, stripe_invoice} <- Processor.finalize_invoice(invoice.stripe_id,
                                      idempotency_key: idempotency_key),
           {:ok, updated} <- put_data_and_decompose(invoice, stripe_invoice),
           {:ok, _} <- Events.record_multi(
             actor: Accrue.Actor.current!(),
             subject: updated,
             type: :"invoice.finalized",
             payload: %Accrue.Events.Schemas.InvoiceFinalized{...}
           ) do
        {:ok, Repo.preload(updated, :items)}
      end
    end)
  end)
end
```

### Pattern 2: Dual API (D-05 from Phase 1, extended in Phase 3)
Every public function has a `foo/n` tuple variant and a `foo!/n` raising variant. `!` variants raise `Accrue.ActionRequiredError` on requires_action (D3-11).

### Pattern 3: Composable Ecto Query Fragments (D3-04)
```elixir
defmodule Accrue.Billing.Query do
  import Ecto.Query

  def active(query \\ Accrue.Billing.Subscription) do
    from s in query, where: s.status in [:active, :trialing]
  end

  def canceling(query \\ Accrue.Billing.Subscription) do
    from s in query,
      where: s.status == :active and s.cancel_at_period_end == true and
             s.current_period_end > ^DateTime.utc_now()
  end
  # ...
end

# Use:
Accrue.Billing.Query.active() |> Repo.all()
from(s in Subscription, where: s.customer_id == ^id) |> Accrue.Billing.Query.active() |> Repo.all()
```

### Pattern 4: Custom Credo Check for BILL-05 enforcement
`Accrue.Credo.NoRawStatusAccess` walks the AST flagging `sub.status ==`, `sub.status in`, `== :active` patterns outside `Accrue.Billing.Subscription` module itself. [CITED: https://hexdocs.pm/credo/writing-a-custom-check.html].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Subscription state machine | Bespoke state table with transition validation | `Ecto.Enum` + pure predicate functions + changeset validation | Stripe IS the state machine; we project it. D3-01. |
| Webhook ordering | Local event queue with head-of-line blocking | Skip-stale column check + always-refetch canonical | Stripe is monotonic via `created` ts; refetch eliminates reorder concerns. D3-48..51. |
| PaymentMethod fingerprint comparison | Parse card BIN and hash PAN ourselves | Stripe's `card.fingerprint` field | PCI-hostile and unnecessary; Stripe provides the stable hash. |
| Idempotency key generation | Random UUID per call | Deterministic SHA256(`op|subject_id|operation_id|seq`) | Retries must converge to same key. D3-60..64. |
| Trial timer | Oban job scheduled at `trial_end - 3d` | Stripe's `customer.subscription.trial_will_end` webhook | Dual-source drift when trial extended via Stripe dashboard. D3-39. |
| Refund fee math from card BIN | Per-country fee table | Stripe's `balance_transaction.fee_details[]` | Authoritative, updated server-side. |
| Invoice preview caching | Cachex layer in Accrue | Always live-fetch | Cache invalidation across proration_date/coupon/tax is a correctness hazard. D3-24. |
| Card-expiring scheduler | Custom GenServer scan loop | Oban cron worker | Oban handles clustering, retries, crash recovery. D3-72. |
| PaymentIntent status polling | Background poller | Webhooks only (per Stripe best practice) | Polling is anti-pattern; webhooks are canonical. |
| State-machine changeset bypass | Remove validation entirely | Two changesets: user-path validates, webhook-path forces | Stripe is canonical; must accept any state Stripe reports. D3-17. |

**Key insight:** Phase 3 is about **faithful projection of Stripe state** with Accrue-owned semantic predicates and tagged returns. Hand-rolling state logic fights the one source of truth.

## Common Pitfalls

### Pitfall 1: Trusting webhook payload snapshots instead of refetching
**What goes wrong:** Payload represents state at event time, not now; out-of-order delivery leaves DB stale.
**Why it happens:** Stripe delivers events reliably but not strictly ordered; simultaneous updates race.
**How to avoid:** D3-48 always-refetch-canonical for non-stale events; skip-stale for stale events. D2-29 (Phase 2 locked) enshrines this.
**Warning signs:** Tests pass but prod has invoices stuck in `open` after `paid` events arrived.

### Pitfall 2: Implicit proration default (Pay-Ruby / Cashier's footgun)
**What goes wrong:** Developer calls `swap_plan` without thinking about proration, gets surprise charge on next invoice.
**Why it happens:** Stripe's default is `create_prorations`; silently inheriting is friendly-looking but footgun-shaped.
**How to avoid:** D3-22 fail-loud — missing `:proration` raises at NimbleOptions validation with explicit error message.
**Warning signs:** Fine in dev; angry customer support tickets in prod.

### Pitfall 3: Subscribing to only `customer.subscription.updated` for state transitions
**What goes wrong:** Missing lifecycle signals like `trial_will_end`, `payment_failed`, `deleted`.
**Why it happens:** Stripe has ~15 subscription-related event types; `updated` alone misses the semantic ones.
**How to avoid:** D3-66's 24-event taxonomy maps Stripe event types to Accrue semantic events. DefaultHandler handles all subscription.* types.

### Pitfall 4: Using `DateTime.utc_now/0` in factories / schema defaults
**What goes wrong:** Tests break at midnight; trial boundaries drift; Fake processor test clock desyncs from schema timestamps.
**How to avoid:** D3-86 `Accrue.Clock.utc_now/0` hard rule. Every `trial_end`, `current_period_*`, `canceled_at`, `ended_at`, `fees_settled_at` read goes through it. D3-83 enforces in factories.

### Pitfall 5: `send` as a function name (Elixir reserved)
**What goes wrong:** `def send(invoice)` shadows `Kernel.send/2`.
**How to avoid:** lattice_stripe already uses `send_invoice/4` — Accrue mirrors `send_invoice/2` in its context. [VERIFIED: lattice_stripe source].

### Pitfall 6: PaymentIntent created without `expand: ["latest_invoice.payment_intent"]`
**What goes wrong:** `subscribe/2` returns subscription without pre-hydrated PI; SCA detection misses.
**How to avoid:** Every create/update call that may trigger a PI uses `expand: ["latest_invoice.payment_intent"]`. Codified in `Accrue.Processor.Stripe` adapter.

### Pitfall 7: Fingerprint-null PaymentMethods silently matching each other
**What goes wrong:** Treating NULL fingerprints as equal dedupes Link wallets together.
**How to avoid:** D3-53 — fingerprint-null PMs always insert fresh. Partial unique index `WHERE fingerprint IS NOT NULL` enforces at DB.

### Pitfall 8: Assuming refund fee data is available at refund creation
**What goes wrong:** Insert refund row with `merchant_loss_amount = 0`; user thinks Stripe refunded the fee.
**How to avoid:** D3-45/46 — sync best-effort, webhook backstop, daily reconciler. Ship `fees_settled?/1` predicate and don't surface fee data until settled.

### Pitfall 9: Allowing `cancel(sub, at: future_dt)` overload
**What goes wrong:** Ambiguous API; users don't know if "cancel" is soft or hard.
**How to avoid:** D3-26 two-verb split. `cancel/2` always immediate, `cancel_at_period_end/2` always soft.

### Pitfall 10: Virtual `grace_period_remaining` field
**What goes wrong:** Drifts from DB-canonical; computed on load so differs across processes.
**How to avoid:** D3-30a — no virtual field. Use `canceling?/1` predicate + compute from `current_period_end` directly.

## Testing Strategy

### Three-layer test surface
1. **Unit tests against `Accrue.Processor.Fake`** — primary surface (D-19 from Phase 1). Fast, deterministic, parallel, no network. Covers state machine transitions, predicate logic, changeset validation, proration math, intent_result wrapping.
2. **Property tests via StreamData** (D3-81) — `Accrue.Test.Generators`. Money math correctness, proration invariants, zero-decimal currency handling, fingerprint dedup idempotence.
3. **Integration tests against real Stripe via lattice_stripe test mode** — gated behind `@tag :stripe_live`, runs in CI when `STRIPE_TEST_KEY` env var is set. Covers the PROC-02 adapter happy path and the trickier SCA flows using Stripe's test card `4000 0025 0000 3155` for 3DS.

### Fake processor features (extended in Phase 3)
- `Accrue.Processor.Fake.advance(sub_id, days: N)` — advances test clock + synthesizes webhooks (D3-42)
- `Accrue.Processor.Fake.transition(sub_id, :past_due)` — internal helper to reach states the happy-path can't hit (D3-82)
- `Accrue.Processor.Fake.scripted_response(op, result)` — scripts a single response for chaos testing
- Deterministic IDs (from Phase 1 counter) make assertions stable

### Test factories per D3-80 (nine first-class factories)
All route through `Fake.create_customer/1` + `Fake.create_subscription/2`, deriving timestamps from `Accrue.Clock.utc_now/0` (which reads `Fake.now/0` in test env).

### Async-safety regression test (D3-85)
```elixir
test "100 concurrent trialing subscriptions have unique IDs", %{} do
  tasks = for _ <- 1..100 do
    Task.async(fn -> Accrue.Test.Factory.trialing_subscription() end)
  end
  results = Task.await_many(tasks)
  ids = Enum.map(results, & &1.subscription.id)
  assert length(Enum.uniq(ids)) == 100
end
```

### Mox boundaries
Use Mox sparingly — the Fake Processor pattern (D-19) replaces most mock needs. Mox is for:
- `Accrue.Mailer.Test` assertions (already from Phase 1)
- `Accrue.PDF.Test` assertions (Phase 1)
- Verifying `Accrue.Processor` behaviour contract compliance via `Mox.defmock(ProcessorMock, for: Accrue.Processor)` — used ONLY to prove Fake and Stripe adapters both satisfy the behaviour shape. Not used for test isolation.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir standard) + StreamData (property tests) + Mox (contract verification) |
| Config file | `accrue/test/test_helper.exs` (exists from Phase 1) |
| Quick run command | `cd accrue && mix test --stale` |
| Full suite command | `cd accrue && mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-02 | Stripe adapter delegates every op to lattice_stripe | contract (Mox) + integration (tagged `:stripe_live`) | `mix test test/accrue/processor/stripe_test.exs` | Wave 0 |
| BILL-03 | Subscription create/retrieve/swap/cancel/resume/pause round-trip | unit (Fake) | `mix test test/accrue/billing/subscription_test.exs` | Wave 0 |
| BILL-04 | State machine transitions trialing→active→past_due→...→canceled | unit (Fake + `transition/3`) | `mix test test/accrue/billing/subscription_state_machine_test.exs` | Wave 0 |
| BILL-05 | Predicates + Credo check + Query fragments | unit + Credo lint | `mix test test/accrue/billing/subscription_predicates_test.exs && mix credo --strict` | Wave 0 (test); Wave 0 (Credo check module) |
| BILL-06 | Trial creation + `trial_will_end` handler + `:now`/DateTime/{:days,N} normalization | unit (Fake synth webhooks) | `mix test test/accrue/billing/trial_test.exs` | Wave 0 |
| BILL-07 | `cancel_at_period_end/2` + grace period | unit | `mix test test/accrue/billing/subscription_cancel_test.exs` | Wave 0 |
| BILL-08 | Immediate `cancel/2` with `invoice_now: true` returning `intent_result` | unit + property (cancel options matrix) | `mix test test/accrue/billing/subscription_cancel_test.exs` | Wave 0 |
| BILL-09 | `swap_plan/3` requires explicit `:proration` — missing opt raises `ArgumentError` | unit | `mix test test/accrue/billing/swap_plan_test.exs` | Wave 0 |
| BILL-10 | `preview_upcoming_invoice/2` returns `%UpcomingInvoice{}` with prorated lines | unit (Fake) + integration (`:stripe_live`) | `mix test test/accrue/billing/upcoming_invoice_test.exs` | Wave 0 |
| BILL-17 | Invoice state machine `:draft → :open → :paid | :void | :uncollectible` | unit | `mix test test/accrue/billing/invoice_state_machine_test.exs` | Wave 0 |
| BILL-18 | Invoice line items + discounts + tax projection | unit | `mix test test/accrue/billing/invoice_items_test.exs` | Wave 0 |
| BILL-19 | `finalize/void/pay/mark_uncollectible/send_invoice` workflow actions | unit | `mix test test/accrue/billing/invoice_workflow_test.exs` | Wave 0 |
| BILL-20 | Charge wrapper with deterministic idempotency key | unit + property (key determinism across retries) | `mix test test/accrue/billing/charge_test.exs` | Wave 0 |
| BILL-21 | PaymentIntent `intent_result` tagged return on 3DS card | unit (Fake scripted) + integration (`:stripe_live` with `4000 0025 0000 3155`) | `mix test test/accrue/billing/payment_intent_test.exs` | Wave 0 |
| BILL-22 | SetupIntent parallel coverage for off-session card-on-file | unit + integration | `mix test test/accrue/billing/setup_intent_test.exs` | Wave 0 |
| BILL-23 | PaymentMethod fingerprint dedup: attach same card twice, verify dedup + race condition | unit + async concurrency test | `mix test test/accrue/billing/payment_method_dedup_test.exs` | Wave 0 |
| BILL-24 | Expiring-card detection: scheduled job + webhook paths, dedup via events table | unit (Oban.Testing) | `mix test test/accrue/jobs/detect_expiring_cards_test.exs` | Wave 0 |
| BILL-25 | Default PM FK on customers, `set_default_payment_method/2` loud errors | unit | `mix test test/accrue/billing/default_payment_method_test.exs` | Wave 0 |
| BILL-26 | Refund populates `stripe_fee_refunded_amount` + `merchant_loss_amount`; reconciler sweeps nil-fee rows | unit + property (fee math) | `mix test test/accrue/billing/refund_test.exs test/accrue/jobs/reconcile_refund_fees_test.exs` | Wave 0 |
| WH-09 | Out-of-order events: skip-stale + always-refetch | unit (inject out-of-order events into DefaultHandler) | `mix test test/accrue/webhook/default_handler_out_of_order_test.exs` | Wave 0 |
| TEST-08 | Nine factories produce valid states routed through Fake; async-safety 100-concurrent test | unit | `mix test test/accrue/test/factory_test.exs` | Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test --stale` — runs only tests affected by changed files
- **Per wave merge:** `mix test --warnings-as-errors` — full Phase 3 unit + property suite (should be green in < 30s)
- **Phase gate:** Full suite green + `mix credo --strict` green + `mix dialyzer` green + `@tag :stripe_live` integration suite green (requires `STRIPE_TEST_KEY`) before `/gsd-verify-work`

### Wave 0 Gaps
All test files below do not yet exist and must be created alongside their implementation tasks. No new framework install needed — ExUnit, StreamData, Mox, Oban.Testing are all in deps from Phase 1/2.

- [ ] `test/accrue/processor/stripe_test.exs` — PROC-02 contract + `:stripe_live` integration
- [ ] `test/accrue/billing/subscription_test.exs` — BILL-03
- [ ] `test/accrue/billing/subscription_state_machine_test.exs` — BILL-04
- [ ] `test/accrue/billing/subscription_predicates_test.exs` — BILL-05
- [ ] `test/accrue/billing/trial_test.exs` — BILL-06
- [ ] `test/accrue/billing/subscription_cancel_test.exs` — BILL-07, BILL-08
- [ ] `test/accrue/billing/swap_plan_test.exs` — BILL-09
- [ ] `test/accrue/billing/upcoming_invoice_test.exs` — BILL-10
- [ ] `test/accrue/billing/invoice_state_machine_test.exs` — BILL-17
- [ ] `test/accrue/billing/invoice_items_test.exs` — BILL-18
- [ ] `test/accrue/billing/invoice_workflow_test.exs` — BILL-19
- [ ] `test/accrue/billing/charge_test.exs` — BILL-20
- [ ] `test/accrue/billing/payment_intent_test.exs` — BILL-21
- [ ] `test/accrue/billing/setup_intent_test.exs` — BILL-22
- [ ] `test/accrue/billing/payment_method_dedup_test.exs` — BILL-23
- [ ] `test/accrue/jobs/detect_expiring_cards_test.exs` — BILL-24
- [ ] `test/accrue/billing/default_payment_method_test.exs` — BILL-25
- [ ] `test/accrue/billing/refund_test.exs` — BILL-26
- [ ] `test/accrue/jobs/reconcile_refund_fees_test.exs` — BILL-26
- [ ] `test/accrue/jobs/reconcile_charge_fees_test.exs` — BILL-26
- [ ] `test/accrue/webhook/default_handler_out_of_order_test.exs` — WH-09
- [ ] `test/accrue/test/factory_test.exs` — TEST-08
- [ ] `test/accrue/billing/query_test.exs` — Query fragment composability
- [ ] `test/accrue/billing/properties/proration_test.exs` — property test for proration math
- [ ] `test/accrue/billing/properties/idempotency_key_test.exs` — property test for deterministic UUID derivation
- [ ] `lib/accrue/credo/no_raw_status_access.ex` + `test/accrue/credo/no_raw_status_access_test.exs` — BILL-05 custom Credo check

## Environment Availability

Phase 3 is pure code/schema work on top of Phase 1/2 infrastructure. No new external dependencies introduced.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All tasks | ✓ (assumed per Phase 1/2 completion) | ~> 1.17 | — |
| PostgreSQL 14+ | Migrations | ✓ (assumed) | 14+ | — |
| `lattice_stripe ~> 1.0` | PROC-02 adapter | ✓ (mix dep, sibling project at `/Users/jon/projects/lattice_stripe/`) | 1.0 | — |
| Stripe test API key | `@tag :stripe_live` integration tests only | unknown (host-provided via `STRIPE_TEST_KEY` env var) | N/A | Skip `:stripe_live` tag — unit suite via Fake covers everything else |

No blocking dependencies.

## Project Constraints (from CLAUDE.md)

- **Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.13+, PostgreSQL 14+.** Phase 3 does not upgrade any of these.
- **`lattice_stripe ~> 1.0`** is the ONLY module that imports lattice_stripe — per existing Phase 2 pattern, `Accrue.Processor.Stripe` is the sole boundary. [CITED: CLAUDE.md lattice_stripe row].
- **Accrue does NOT start Oban.** All Phase 3 cron workers (`Accrue.Jobs.ReconcileRefundFees`, `Accrue.Jobs.ReconcileChargeFees`, `Accrue.Jobs.DetectExpiringCards`) are defined with `@default_cron` attrs and documented; host wires them into their own Oban cron plugin config. [CITED: CLAUDE.md config boundaries].
- **Oban Community Edition only.** All features Phase 3 uses (cron, retries, uniqueness, Oban.Testing) are CE. [CITED: CLAUDE.md].
- **Mox decisively — Fake Processor pattern eliminates most mock needs.** Phase 3 uses Mox only for behaviour contract verification, not for test isolation. [CITED: CLAUDE.md "Test Library Decision"].
- **NimbleOptions for all config validation.** `swap_plan/3` and `pause/2` opts must use NimbleOptions schemas. [CITED: CLAUDE.md].
- **Webhook signature verification non-bypassable (Phase 2 concern).** Phase 3 extends the DefaultHandler but never touches signature verification.
- **Raw-body plug before `Plug.Parsers` (Phase 2 concern).** Phase 3 does not touch the webhook plug chain.
- **Sensitive Stripe fields never logged.** PaymentIntent `client_secret`, PaymentMethod raw card details, webhook signing secrets never appear in logs or events.
- **Webhook p99 <100ms, async handler per Oban config.** Phase 3's DefaultHandler runs inside the Oban worker (async path), not the webhook HTTP handler. Skip-stale is O(1), refetch + put_data + Events.record_multi is O(1) per event.
- **All public entry points emit `:telemetry` start/stop/exception events.** Every Billing context function wraps in `Accrue.Telemetry.span/3` (pattern from Phase 1).
- **Phoenix 1.8+ LiveView not required in core `accrue`.** `Accrue.LiveView.on_mount :accrue_operation` lives in `accrue` core but is opt-in — it gracefully degrades when LiveView isn't loaded. **Flag to planner:** verify this doesn't force a hard LiveView dep; Phase 1's conditional-compile pattern should apply.
- **MIT license (Phase 1 landed LICENSE file).** Phase 3 doesn't touch licensing.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `LatticeStripe.Invoice.upcoming/3` is still available in lattice_stripe 1.0 (Stripe deprecated `GET /invoices/upcoming` in favor of `create_preview`) | Key APIs: Invoice | [VERIFIED via grep — both `upcoming/3` and `create_preview/3` exist in source] — LOW risk. Planner should prefer `create_preview/3`. |
| A2 | Stripe `customer.subscription.trial_will_end` fires ~3 days before `trial_end` | Trial Management | [CITED: Stripe docs] — LOW risk. Default handler subscribes to the event regardless of exact delay. |
| A3 | Stripe refund fee policy (percentage refunded, fixed fee kept on partial) is current in 2026 | Fee-Aware Refunds | [CITED: Stripe support docs — may have regional variance] — MEDIUM risk. Phase 3 computes `merchant_loss = fee - fee_refunded` directly from balance_transaction, so code is correct regardless of policy specifics. |
| A4 | `charge.refund.updated` event populates canonical fee_refunded reliably | Fee-Aware Refunds | [CITED: Stripe API events] — LOW risk. D3-46 daily reconciler handles dropped events regardless. |
| A5 | `Accrue.LiveView.on_mount :accrue_operation` can live in core `accrue` without forcing a LiveView dep via conditional compilation | Project Constraints | [ASSUMED] — MEDIUM risk. Planner must verify Phase 1's conditional-compile pattern applies, or move this module to `accrue_admin`. CLAUDE.md says "Hard Phoenix/LiveView dep in core" is out-of-scope. |
| A6 | PaymentMethod `card.fingerprint` is present on all card-type PMs across 2024–2026 | Payment Method Dedup | [CITED: Stripe docs — documented as "may be null for non-card types"] — LOW risk. D3-53 already handles NULL. |
| A7 | `Ecto.UUID.cast!(binary_part(:crypto.hash(:sha256, ...), 0, 16))` produces a valid UUID | Idempotency | [VERIFIED: binary_part returns 16 bytes which is the UUID binary length; Ecto.UUID.cast! accepts raw 16-byte binaries] — LOW risk. Plan should write a unit test proving determinism. |
| A8 | `Oban.Worker` middleware plug hook exists and can set pdict before `perform/1` | operation_id propagation | [CITED: https://hexdocs.pm/oban/Oban.Worker.html] — LOW risk. `Oban.Engine.Middleware` pattern is stable. |
| A9 | Stripe PaymentIntent `next_action.type` enum values in 2026 include `use_stripe_sdk | redirect_to_url | verify_with_microdeposits` | SCA / 3DS | [CITED: Stripe docs] — LOW risk. Phase 3 surfaces the PI struct unchanged; host code reads `next_action`. |
| A10 | lattice_stripe 1.0 `Subscription.pause_collection/5` wraps the `update` endpoint (it's a convenience, not a separate Stripe API) | Key APIs: Subscription | [VERIFIED via grep of source — confirmed at line 332 of subscription.ex, builds pause_collection map and calls through to update] — LOW risk. |
| A11 | Phase 2's `Accrue.Webhook.DefaultHandler` exposes a pluggable per-event reducer interface Phase 3 can extend | Integration Points | [ASSUMED from `<code_context>` in CONTEXT.md which says "Phase 3 extends with per-event reducers"] — MEDIUM risk. Planner should read Phase 2 DefaultHandler source first to confirm the extension shape. |

## Open Questions

1. **Does Phase 2's `Accrue.Webhook.DefaultHandler` already expose a per-event reducer / dispatch table that Phase 3 can extend, or does Phase 3 need to refactor it?**
   - What we know: Phase 2 context says DefaultHandler handles "subscription/invoice/charge updates" at a skeleton level. Phase 3 adds the full 24-event taxonomy handlers.
   - What's unclear: Whether the extension is additive (new clauses) or requires restructuring.
   - Recommendation: First task in Wave 1 reads `accrue/lib/accrue/webhook/default_handler.ex` and documents the extension shape. If refactoring needed, do it in a dedicated task before the per-event handlers.

2. **`Accrue.LiveView.on_mount :accrue_operation` — hard dep or conditional compile?**
   - What we know: CLAUDE.md says core `accrue` must work for headless/worker-only apps. LiveView is a hard dep only in `accrue_admin`.
   - What's unclear: Whether `on_mount` hook can live in `accrue` core via `Code.ensure_loaded?(Phoenix.LiveView)` conditional compile (Phase 1's Sigra pattern), or must move to `accrue_admin`.
   - Recommendation: Planner should use Phase 1's conditional-compile pattern (D-28 from Phase 1). If LiveView absent, module either doesn't compile or exports no-op stubs. Alternative: move the `on_mount` hook to `accrue_admin` and ship only `Accrue.Plug.PutOperationId` in core for HTTP controllers — LiveView users pick it up via `accrue_admin` anyway.

3. **Should `Accrue.Credo.NoRawStatusAccess` ship in `accrue` (runtime dep on credo) or in a separate dev-only module?**
   - What we know: CLAUDE.md lists credo as dev-only (`runtime: false`).
   - What's unclear: Whether custom Credo checks can be dev-only or must compile unconditionally.
   - Recommendation: Put the check in `accrue/lib/accrue/credo/` with `@moduledoc "Compiled only when :credo is loaded"` and `Code.ensure_loaded?(Credo.Check)` guard. Follows D-28 conditional-compile precedent.

4. **`Accrue.Jobs.*` vs `Accrue.Workers.*` naming** (noted as Claude's discretion in CONTEXT.md D-86 follow-on).
   - Recommendation: Planner picks `Accrue.Jobs.*` to match CONTEXT.md's references (`Accrue.Jobs.ReconcileRefundFees` etc.).

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/accrue/.planning/phases/03-core-subscription-lifecycle/03-CONTEXT.md` — 86 locked decisions covering every architectural choice
- `/Users/jon/projects/accrue/.planning/REQUIREMENTS.md` — v1 requirement IDs and descriptions
- `/Users/jon/projects/accrue/.planning/ROADMAP.md` — Phase 3 goal + 6 success criteria
- `/Users/jon/projects/accrue/CLAUDE.md` — stack versions, conditional compile pattern, config boundaries, Oban/ChromicPDF host-ownership rule
- `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/*.ex` — [VERIFIED via grep] function signatures for Subscription, Invoice, PaymentIntent, SetupIntent, PaymentMethod, Charge, Refund, Customer
- Stripe API docs — https://stripe.com/docs/api (Subscription, Invoice, PaymentIntent, SetupIntent, PaymentMethod, Charge, Refund, BalanceTransaction, events)

### Secondary (MEDIUM confidence)
- Stripe SCA flow docs — https://stripe.com/docs/payments/payment-intents
- Stripe proration docs — https://stripe.com/docs/billing/subscriptions/prorations
- Stripe refund fee policy — https://support.stripe.com/questions/understanding-fees-for-refunded-payments
- Ecto.Enum, Ecto.Repo.transact — https://hexdocs.pm/ecto/
- NimbleOptions — https://hexdocs.pm/nimble_options/
- Credo custom check guide — https://hexdocs.pm/credo/writing-a-custom-check.html

### Tertiary (LOW confidence / reference only)
- Pay (Rails) subscription.rb — prior art for predicate naming (what to borrow) and silent proration (what to avoid)
- Laravel Cashier Subscription.php — prior art for cancel verb naming
- Stripe's test cards for SCA — `4000 0025 0000 3155` for `:requires_action` path

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions pinned in CLAUDE.md 3 days ago, no upgrades in Phase 3
- Architecture: HIGH — CONTEXT.md has 86 pre-discussed locked decisions; research only verified Stripe/lattice_stripe primitives
- State machines: HIGH — Stripe status enums verified against official API docs
- lattice_stripe APIs: HIGH — verified via direct grep of sibling source
- Pitfalls: HIGH — distilled from CONTEXT.md decisions, Phase 2 learnings, and documented Stripe gotchas
- Validation architecture: HIGH — Phase 1/2 already shipped ExUnit + Oban.Testing + StreamData + Mox; Phase 3 tests are additive
- Open questions: MEDIUM — three items need Phase 2 code inspection during planning

**Research date:** 2026-04-14
**Valid until:** 2026-05-14 (30 days — stack is stable; Stripe API versions are `2026-03-25.dahlia` per CLAUDE.md and Accrue pins per-request version overrides)
