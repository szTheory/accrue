# Phase 3: Core Subscription Lifecycle - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 delivers the **full Stripe subscription lifecycle** on top of Phase 1 primitives and the Phase 2 schema/webhook layer, driven end-to-end through `Accrue.Processor.Fake` AND against real Stripe via `lattice_stripe` 1.0:

- Subscription create/swap/cancel/resume/pause/unpause, trial management, grace period
- Subscription state machine as `Ecto.Enum` with pure column-based predicates (`active?/canceling?/canceled?/paused?/trialing?/past_due?`)
- `SubscriptionItem` single-item write surface + any-item read/projection
- Invoice state machine (`:draft → :open → :paid | :void | :uncollectible`) with hybrid projection: typed rollup columns + real `accrue_invoice_items` child schema + jsonb detail
- Invoice workflow actions: `finalize/void/pay/mark_uncollectible/send`
- Charge wrapper with deterministic idempotency keys
- `PaymentIntent` + `SetupIntent` with uniform **`intent_result/1`** return type for 3DS/SCA
- `PaymentMethod` with fingerprint-based dedup + FK-on-customer default PM management
- Fee-aware `Refund` with `stripe_fee_refunded_amount` + `merchant_loss_amount` populated via sync-best-effort + webhook backstop + daily reconciler
- Out-of-order webhook resolution via per-entity `last_stripe_event_ts`/`last_stripe_event_id` skip-stale check
- Expiring-card warnings (BILL-24) via scheduled scan + webhook + events-table dedup
- `Accrue.Billing.Query` composable Ecto fragments mirroring each predicate for `where`-clause use
- Test factories (`Accrue.Test.Factory`) routed through the Fake processor
- Full canonical event taxonomy (24 event types) written to `accrue_events` in the same `Repo.transact/2` as every mutation
- `Accrue.Plug.PutOperationId`, `Accrue.LiveView.on_mount :accrue_operation`, `Accrue.Oban.Middleware` to propagate `operation_id` into actor pdict for deterministic idempotency-key seeding
- `Accrue.Clock` module (host-test-clock-aware time source consumed by every Phase 3 mutation)

**Out of scope for Phase 3 (deferred):**
- Dunning, retries, grace-period collection, past_due orchestration → Phase 4
- Metered/usage-reports, multi-item write (add_item/remove_item/update_items), free/comped tiers → Phase 4
- Coupons / promotion codes → Phase 4 (though a minimal `accrue_coupons` + `accrue_invoice_coupons` schema lands in Phase 3 because invoice projection references it)
- Subscription schedules (`Stripe.SubscriptionSchedule`) → Phase 4
- Checkout + Customer Portal sessions → Phase 4
- Stripe Connect multi-endpoint webhooks + per-account secret routing → Phase 5
- Email templates beyond `:trial_ending`, `:card_expiring`, `:card_auto_updated`, `:receipt`/`:payment_failed` (stub wiring only; template work → Phase 6)
- Admin LiveView pages for subscriptions/invoices/charges → Phase 7

</domain>

<decisions>
## Implementation Decisions

### Subscription State Machine & Predicates (BILL-04/05/07)

- **D3-01: `status` is `Ecto.Enum` with Stripe's 8 values verbatim** — `[:trialing, :active, :past_due, :canceled, :unpaid, :incomplete, :incomplete_expired, :paused]`. Stripe-faithful beats Accrue-owned collapsing: zero translation loss, Stripe dev reads `status in [:active, :trialing]` and knows exactly what it means, webhook refetch (D2-29) just maps Stripe object → columns.
- **D3-02: Add `cancel_at_period_end :boolean` (default false) and `pause_collection :map` as real columns on `accrue_subscriptions`**, denormalized from the Stripe object on every webhook refetch. Avoids `data` jsonb spelunking in the hot path; predicates become pure column reads.
- **D3-03: Predicates are pure functions over columns, pattern-matchable in function heads.** No virtual fields, no `after_load`, no `data` reads:
  ```elixir
  def trialing?(%__MODULE__{status: :trialing}), do: true
  def trialing?(_), do: false

  def active?(%__MODULE__{status: s}) when s in [:active, :trialing], do: true
  def active?(_), do: false

  def past_due?(%__MODULE__{status: s}) when s in [:past_due, :unpaid], do: true
  def past_due?(_), do: false

  def canceled?(%__MODULE__{status: s}) when s in [:canceled, :incomplete_expired], do: true
  def canceled?(%__MODULE__{ended_at: %DateTime{}}), do: true
  def canceled?(_), do: false

  def canceling?(%__MODULE__{status: :active, cancel_at_period_end: true,
                              current_period_end: %DateTime{} = cpe}),
    do: DateTime.compare(cpe, DateTime.utc_now()) == :gt
  def canceling?(_), do: false

  def paused?(%__MODULE__{pause_collection: pc}) when is_map(pc), do: true
  def paused?(%__MODULE__{status: :paused}), do: true  # legacy pre-2020
  def paused?(_), do: false
  ```
- **D3-04: BILL-05 enforcement is three-layer — docs + custom Credo check + Query fragments.** No hidden status field, no virtual shadowing. (1) Moduledoc and ExDoc loudly say "never gate features on `status`, always use predicates." (2) Ship `Accrue.Credo.NoRawStatusAccess` custom check that flags `sub.status ==`, `sub.status in`, `== :active` outside the `Accrue.Billing.Subscription` module. (3) Ship `Accrue.Billing.Query.active/1`, `Query.canceling/1`, `Query.past_due/1`, etc. as composable Ecto fragments so "cheap in function heads" and "callable in `where`" are both satisfied.
- **D3-05: Do NOT add an `incomplete_expires_at` column.** Trust Stripe's webhook-driven `incomplete_expired` transition — D2-29 says re-fetch canonical; don't duplicate Stripe's 23-hour clock. `active?/1` simply excludes `:incomplete` and `:incomplete_expired`; the 23-hour window is Stripe's problem.

### 3DS / SCA Tagged Returns (BILL-21/22)

- **D3-06: Single `:requires_action` tag, uniform across every PI/SI-capable op.** Define the canonical return type once:
  ```elixir
  @type intent_result(ok) ::
          {:ok, ok}
          | {:ok, :requires_action, PaymentIntent.t() | SetupIntent.t()}
          | {:error, Accrue.Error.t()}
  ```
- **D3-07: `intent_result/1` applies to exactly these public functions** — `charge/3`, `subscribe/2`, `swap_plan/3`, `pay_invoice/2`, `attach_payment_method/2`, and `cancel/2` only when called with `invoice_now: true`. Every other public function returns plain `{:ok, _}` / `{:error, _}`. Intent_result stays narrow and honest — only functions that *actually* may require SCA carry the richer shape.
- **D3-08: Other Stripe intent statuses normalize, they don't get their own tags.** `requires_confirmation` and `requires_payment_method` collapse into `{:error, %Accrue.CardError{}}` (we tried and it didn't go through). `requires_capture` and `processing` ride on the struct inside plain `{:ok, %PaymentIntent{status: :requires_capture | :processing}}`. Only user-blocking cases get the tag.
- **D3-09: `subscribe/2` and `swap_plan/3` embed the PaymentIntent on the returned Subscription — no 4-tuple.** The Subscription struct carries `latest_invoice.payment_intent` pre-hydrated. Ship helper `Accrue.Billing.Subscription.pending_intent/1` to extract it. The tag means "look at `sub.latest_invoice.payment_intent` and complete it."
- **D3-10: `attach_payment_method/2` uses the same `:requires_action` tag with `%SetupIntent{}` in the struct slot.** Reusing the tag (struct type disambiguates) means one tag to learn, not two.
- **D3-11: `!` variants raise `Accrue.ActionRequiredError{payment_intent}` on the action-required branch.** Bangs mean "give me the value or blow up"; a pending intent isn't the value. Callers who need to handle SCA MUST use the tuple variant — this preserves D-05's clean dichotomy and is a feature, not a limitation.
- **D3-12: Processor behaviour `@callback` uses the union type:**
  ```elixir
  @callback create_subscription(params) :: Accrue.intent_result(Subscription.t())
  ```
  Keeps dialyzer specs tight, gives Phase 4 meter/portal ops a ready-made return shape.

### Invoice Projection Depth (BILL-17/18/19)

- **D3-13: Hybrid projection — typed rollups + real child schema + jsonb detail.** Not "full Stripe mirror" (schema churn hell), not "blob only" (admin queries fall off a cliff).
- **D3-14: `accrue_invoices` gets typed columns for every scalar the admin LiveView filters/sorts/sums on:**
  ```
  status (Ecto.Enum :draft|:open|:paid|:uncollectible|:void),
  subtotal_minor, tax_minor, discount_minor, total_minor,
  amount_due_minor, amount_paid_minor, amount_remaining_minor, currency,
  number, hosted_url, pdf_url,
  period_start, period_end, due_date,
  collection_method, billing_reason,
  finalized_at, paid_at, voided_at,
  last_stripe_event_ts, last_stripe_event_id,
  metadata, data, lock_version
  ```
- **D3-15: Ship `accrue_invoice_items` child schema as real relational rows.** Phase 6 PDF preloads `invoice.items` via `Repo.preload`; Phase 4 event timelines reference individual items. Columns: `invoice_id, stripe_id, description, amount_minor, currency, quantity, period_start, period_end, proration, price_ref, subscription_item_ref, data`. Tax amounts and per-line discounts stay nested in each item's `data` jsonb — they're render-time concerns, never in WHERE clauses.
- **D3-16: Ship minimal `accrue_coupons` + `accrue_invoice_coupons` join.** Phase 3 owns coupons because invoice projection references them, but the CRUD API and promotion_code/usage/redemption logic is Phase 4. Schema exists, write API stays minimal (Phase 4 expands).
- **D3-17: Invoice state machine enforcement splits user-path vs webhook-path.** `Accrue.Billing.Invoice.changeset/2` validates legal transitions on user-initiated changesets. `Accrue.Billing.Invoice.force_status_changeset/2` bypasses the gate for webhook reconcile — per D2-29, Stripe is canonical and we must accept any state Stripe reports.
- **D3-18: Workflow actions all follow one shape inside `Repo.transact/2`:** (1) call `Accrue.Processor.<action>/1`, (2) on Stripe success `put_data` with the returned Invoice, (3) decompose into typed columns + child items via the same deterministic function the webhook path uses, (4) `Events.record_multi` with the matching `invoice.<action>` event, (5) commit. Return is the **post-Stripe, pre-webhook, locally-reconciled** invoice with items preloaded. The later `invoice.finalized` webhook is idempotent: it re-fetches, decomposes, and no-ops if `data` already matches. D2-08/D2-09/D2-29/D-13 all hold.

### Proration Preview & Plan Swap (BILL-09/10)

- **D3-19: Ship dedicated `%Accrue.Billing.UpcomingInvoice{}` non-persistent struct:**
  ```elixir
  %Accrue.Billing.UpcomingInvoice{
    subscription_id: String.t(),
    currency: atom(),
    subtotal: Money.t(),
    total: Money.t(),
    amount_due: Money.t(),
    starting_balance: Money.t(),
    period_start: DateTime.t(),
    period_end: DateTime.t(),
    proration_date: DateTime.t() | nil,
    lines: [UpcomingInvoice.Line.t()],
    fetched_at: DateTime.t()
  }
  %Accrue.Billing.UpcomingInvoice.Line{
    description, amount :: Money.t(), quantity,
    period :: {DateTime.t(), DateTime.t()},
    proration?: boolean(), price_id
  }
  ```
  Dedicated struct, not reused `Invoice` — pattern-matches cleanly, never written to DB, Phase 6 email templates render it directly.
- **D3-20: `:proration` atom set is 1:1 with Stripe** — `:create_prorations | :none | :always_invoice`. Principle of least surprise: users read Stripe docs constantly, renaming earns nothing.
- **D3-21: `swap_plan/3` full opts (NimbleOptions-validated, `:proration` REQUIRED with no default):**
  ```elixir
  proration: :create_prorations | :none | :always_invoice   # REQUIRED
  proration_date: DateTime.t() | nil                        # default nil
  billing_cycle_anchor: :unchanged | :now                   # default :unchanged
  payment_behavior: :default_incomplete | :pending_if_incomplete
                  | :error_if_incomplete | :allow_incomplete # default :default_incomplete
  quantity: pos_integer() | nil                             # from D3-31
  metadata: map() | nil
  operation_id: String.t() | nil                            # D2-11 idempotency seed
  stripe_api_version: String.t() | nil                      # D2-14
  ```
- **D3-22: Missing `:proration` opt raises NimbleOptions `ArgumentError`** with message: *"Accrue.Billing.swap_plan/3 requires an explicit :proration option (:create_prorations, :none, or :always_invoice). Accrue never inherits Stripe defaults — see BILL-09."* Fail-loud, not warn-and-default. Runtime check (opts are runtime values).
- **D3-23: Preview is optional, NOT required-before-commit.** Forcing `with {:ok, preview} <- preview_upcoming_invoice(...); ... <- swap_plan(...)` is heavy-handed for server-to-server callers (admin scripts, trial upgrades, scheduled migrations). `preview_upcoming_invoice/2` is a dual-API convenience for UX flows; `swap_plan/3` stands alone.
- **D3-24: No caching in v1.0.** Preview always live-fetches. Cache invalidation across proration_date/coupon/tax changes is a correctness hazard; 300ms on a confirm screen is acceptable (LiveView `assign_async` absorbs it). Document Cachex wrapping as host concern. Revisit post-v1.0 only if telemetry shows Stripe rate-limiting.
- **D3-25: `swap_plan/3` returns `intent_result(Subscription.t())`** — same shape as `charge/3` and `subscribe/2`. Preview never returns `:requires_action` (read-only Stripe call). After commit, D2-29 takes over: `customer.subscription.updated` webhook re-reconciles local state.

### Cancel, Resume, Pause, Unpause (BILL-07/08)

- **D3-26: Two cancel verbs + strict resume/unpause split. No `cancel(at:)` overload.**
  ```elixir
  cancel(sub, opts \\ [])                  # Immediate. DELETE /subscriptions/:id
  cancel_at_period_end(sub, opts \\ [])    # Soft; opts :at for scheduled future DateTime
  resume(sub)                              # Strictly unsets cancel_at_period_end / cancel_at
  pause(sub, opts \\ [])                   # opts :behavior :void (default) | :mark_uncollectible | :keep_as_draft, :resumes_at
  unpause(sub)                             # Strictly clears pause_collection
  ```
  Plus `!` variants per D-05.
- **D3-27: `cancel/2` opts are `invoice_now: boolean` (default false) and `prorate: boolean` (default false).** Opinionated default = no proration, no surprise charge. Callers who want the final prorated invoice opt in explicitly with `cancel(sub, invoice_now: true, prorate: true)`. Documented prominently in a "which cancel do I want?" cheatmd guide.
- **D3-28: `cancel/2` returns `intent_result(Subscription.t())`; all other cancel/pause ops return plain `{:ok, Subscription.t()}`.** Only `cancel/2` + `invoice_now: true` can trigger SCA. Keeping intent_result narrow where SCA is actually possible.
- **D3-29: `resume/1` is strictly scoped to canceling, `unpause/1` strictly to paused.** A sub that is paused AND canceling requires two calls in whichever order. Calling `resume/1` on a paused sub raises `Accrue.Error.InvalidState` pointing at `unpause/1`. They dispatch to different Stripe endpoints and emit different telemetry events.
- **D3-30: `swap_plan/3` on a canceling sub preserves Stripe's behavior — it succeeds and implicitly unsets `cancel_at_period_end`.** Documented explicitly. Callers wanting a guard use `canceling?/1` predicate before swap. No auto-`resume/1` requirement — that'd be ceremony fighting Stripe fidelity.
- **D3-30a: No `grace_period_remaining` virtual field.** `canceling?/1` predicate is sufficient; callers compute remaining time from `current_period_end` directly. Virtual fields drift from DB-canonical.

### SubscriptionItem Scope (BILL-03, Phase 3 ↔ Phase 4 boundary)

- **D3-31: Phase 3 owns "single-item write, any-item read."** Schema fills in `price_id`, `processor_plan_id`, `processor_product_id`, `current_period_start`, `current_period_end` (items carry their own period in Stripe since 2023), plus existing `metadata`, `data`, `lock_version`, `last_stripe_event_ts/id`. **Deferred to Phase 4 (all additive, non-breaking):** `tax_rates`, `discounts`, `billing_thresholds`, `usage_type`, `metered` flag. `data` jsonb absorbs anything the schema doesn't yet model.
- **D3-32: `subscribe/2` accepts a single `price_id` OR a `{price_id, quantity}` tuple — NOT a list.** Internally always sends Stripe `items: [%{price: ..., quantity: ...}]`. Passing a list raises `ArgumentError` pointing at Phase 4's `update_items/3`.
- **D3-33: Ship `Accrue.Billing.update_quantity/2`** — pure quantity delta, same single-item guard, no price change. Per-seat SaaS is the dominant pattern, deferring this to Phase 4 would make Phase 3 useless for most hosts. Skip `increment_quantity`/`decrement_quantity` — Elixir prefers explicit absolute values.
- **D3-34: `swap_plan/3` raises `Accrue.Error.MultiItemSubscription`** if `length(loaded_items) > 1`. Message points to Phase 4's (not-yet-shipped, but named) `update_items/3`.
- **D3-35: Webhook reconciler MUST handle N items correctly in Phase 3.** `customer.subscription.created/updated/deleted` projects every `items.data` entry, upserts by `processor_id`, deletes orphans. Host-created multi-item subs project cleanly; only write ops raise.
- **D3-36: `get_subscription/1,2` auto-preloads `:subscription_items` always.** Items are small, bounded (typically 1–3), universally needed. Escape hatch: `get_subscription(id, preload: false)` for bulk listing.
- **D3-37: Metered subscriptions are read-only in Phase 3.** No `report_usage/3`, no MeterEvent integration (blocked on lattice_stripe 1.1 anyway per CLAUDE.md). `swap_plan/3` incidentally works on a single-item metered sub at the Stripe API level; not advertised.

### Trials + `trial_will_end` (BILL-06)

- **D3-38: `:trial_end` accepts exactly three forms** — `:now` atom, `%DateTime{}`, and `{:days, pos_integer()}` / `%Duration{}` sugar. Reject unix integers (Stripe wire format — Accrue hides it) and `:trial_period_days` (redundant with `{:days, N}`). Normalize to `DateTime` at `subscribe/2` boundary before Processor dispatch. Sugar expands via `Accrue.Clock.utc_now()` so test-clock wins automatically.
- **D3-39: No local Oban scheduling for trial_will_end.** Stripe's webhook is reliable and duplicating it locally creates dual-source drift (e.g., trial extended via Stripe dashboard → local job fires against stale data). Stripe owns trial state; Accrue reacts.
- **D3-40: User handler event name is Stripe's — `:"customer.subscription.trial_will_end"`.** D2-27 pattern-match-in-head makes this trivial; least surprise beats Pay-Ruby's rename.
- **D3-41: Default handler additionally emits `[:accrue, :billing, :subscription, :trial_ending]` telemetry span** on top of the raw event. Clean attachment point for reporters and metrics layered over the webhook event. Two layers: raw event for custom logic, telemetry for observability.
- **D3-42: Fake processor auto-synthesizes webhooks on clock advance.** `Accrue.Processor.Fake.advance(sub_id, days: 14)` automatically fires synthetic `customer.subscription.trial_will_end` when crossing `trial_end - 3d` and `customer.subscription.updated` (trialing→active) when crossing `trial_end`, routed through the normal webhook pipeline so user + default handlers both run. Opt out via `synthesize_webhooks: false`. **This is a test-story differentiator** — Pay/Cashier cannot do this.
- **D3-43: Default trial_ending email fires on by default via D-23 override ladder.** Default handler enqueues `Accrue.Mailer.deliver(:trial_ending, %{subscription, user})`. Hosts disable via `config :accrue, emails: [trial_ending: false]` or MFA-gate. Shipping trial-ending off-by-default contradicts "real SaaS on day one."
- **D3-44: `trial_end: :now` path** normalizes to `Accrue.Clock.utc_now()`, passes to Stripe which skips trial. May trigger immediate charge → standard `intent_result` shape applies.

### Refund Fees (BILL-26) + Out-of-Order Webhooks (WH-09)

- **D3-45: Refund fee math — sync best-effort at create + webhook backstop + daily reconciler.** `create_refund/2` passes `expand: ["balance_transaction", "charge.balance_transaction"]` and writes fees if BT populated; otherwise writes row with nil fees. The `charge.refund.updated` webhook refetches canonical and fills fees, sets `fees_settled_at`, emits `[:accrue, :billing, :refund, :fees_settled]`. Same pattern for `original_fee` on `Charge` via `charge.updated`.
- **D3-46: Ship `Accrue.Jobs.ReconcileRefundFees` and `Accrue.Jobs.ReconcileChargeFees` as daily Oban cron workers.** Sweep rows with `fees_settled_at IS NULL AND inserted_at < now() - 24h` and force-refetch — handles dropped webhooks. Host wires the cron entry (Accrue doesn't start Oban, per CLAUDE.md).
- **D3-47: Refund return shape stays uniform `{:ok, %Refund{}}`** — no tagged `{:ok, :pending_fees, _}` variant. Callers use `Accrue.Billing.Refund.fees_settled?/1` predicate and `list_refunds_with_unsettled_fees/1` query helper. Tagged variants break D-05 uniformity.
- **D3-48: WH-09 — column + skip-stale + always-refetch-on-fast-path.** Add `last_stripe_event_ts :utc_datetime_usec` and `last_stripe_event_id :string` to every billing schema (subscriptions, invoices, charges, refunds, payment_methods, customers). Default handler flow:
  1. Load row by Stripe ID (optimistic_lock D2-09)
  2. If `event.stripe_created_at < row.last_stripe_event_ts` → emit `[:accrue, :webhooks, :stale_event]`, mark `accrue_webhook_events.data.stale = true`, return `:ok`. Skip the refetch entirely — our stored state is already newer; refetching would race with the newer event's handler. This is **orthogonal** to D2-29 (which says don't trust payload snapshots), not a violation.
  3. Otherwise: `Processor.fetch/1` canonical → `put_data` → bump `last_stripe_event_ts/id` → `Events.record_multi` in same tx.
- **D3-49: Tie on equal timestamps → don't skip.** Process the later arrival (idempotent). Stripe event IDs aren't guaranteed monotonic; prefer "don't skip on equal ts."
- **D3-50: Out-of-order `charge.refund.updated` before `charge.refunded` — refetch is canonical.** The handler calls `Processor.fetch_refund/1` which returns current state regardless of event order. If the refund row doesn't exist yet, upsert by `stripe_id`. `put_data` handles replacement cleanly. No ordering gymnastics, no queue-for-later.
- **D3-51: Skip-stale logic lives in `Accrue.Webhook.DefaultHandler`, not a macro.** Macros here would obscure the `optimistic_lock + Events.record_multi + telemetry` triple that every handler needs to make explicit.

### PaymentMethod Dedup (BILL-23) + Default PM (BILL-25)

- **D3-52: PaymentMethod dedup = attach-time application check layered over a partial unique index backstop.** `attach_payment_method/2` inside `Repo.transact/2`:
  1. Retrieve PM from Stripe (canonical per D2-29)
  2. If `fingerprint` present → query `accrue_payment_methods` by `(customer_id, fingerprint)`. If hit → `LatticeStripe.PaymentMethod.detach/1` on the duplicate `pm_xxx` and return the existing row.
  3. Otherwise insert and rely on `CREATE UNIQUE INDEX accrue_payment_methods_customer_fingerprint_idx ON accrue_payment_methods (customer_id, fingerprint) WHERE fingerprint IS NOT NULL` as the concurrency backstop.
  4. On `Ecto.ConstraintError` (race) → refetch, detach duplicate.
- **D3-53: Fingerprint-null PMs (Link, some bank debits) always insert fresh.** Scope is `(customer_id, fingerprint)` only — `(type, fingerprint)` cross-collision is theoretical and Stripe's fingerprint namespace already differs across PM types.
- **D3-54: Return shape keeps `intent_result` uniform via a virtual `existing?: boolean` field on the PM struct** — NOT a 3-tuple tag `{:ok, :existing, pm}`. `{:ok, %PaymentMethod{existing?: true}}` keeps the `intent_result` shape consistent and lets callers who care check the flag while callers who don't just get the PM.
- **D3-55: Expiry updates flow through `payment_method.updated` webhook → D2-29 refetch → D2-08 `patch_data` merges `exp_month`/`exp_year` into existing row.** No new row, no dedup path triggered.
- **D3-56: Default PM = `default_payment_method_id :binary_id` nullable FK on `accrue_customers`** with `ON DELETE SET NULL`. Matches Stripe's data model (invoice_settings.default_payment_method on Customer). Single source of truth per customer, `preload(:default_payment_method)` is a normal `belongs_to`.
- **D3-57: `set_default_payment_method/2`** runs in `Repo.transact/2`: assert PM is attached to this customer (else `{:error, %Accrue.Error.NotAttached{}}` — no auto-attach footgun) → `LatticeStripe.Customer.update/2` with `invoice_settings.default_payment_method` → `patch_data` + optimistic_lock bump → `Events.record_multi`. `customer.updated` webhook reconciles canonical.
- **D3-58: `charge/3` without an explicit PM** reads `customer.default_payment_method_id`; nil → `{:error, %Accrue.Error.NoDefaultPaymentMethod{customer_id: ...}}`. Loud, typed, pattern-matchable. No silent fallback to "first attached PM" — that's Cashier's footgun.
- **D3-59: Subscription-level `default_payment_method_id` override is Phase 4.** Phase 3 wires customer-level only.

### Idempotency Seeds + `operation_id` Propagation (PROC-02 / D2-11 extension)

- **D3-60: Pre-generate the resource UUID BEFORE the Stripe call.** That UUID plays three roles: (a) eventual `accrue_<table>.id` PK, (b) `subject_id` in the idempotency-key hash, (c) `subject_id` on the `accrue_events` row. One identifier, three jobs.
- **D3-61: UUID is deterministic from `operation_id` so retries converge:**
  ```elixir
  Ecto.UUID.cast!(binary_part(:crypto.hash(:sha256, "#{op}|#{operation_id}"), 0, 16))
  ```
  A retry of the same HTTP request regenerates the **same** UUID, so both the idempotency key AND the pending row converge. Without this, a failed retry creates a second pending row.
- **D3-62: Subject_id per op type:**
  - `create_subscription` / `create_charge` / `create_refund` / `attach_payment_method` → pre-generated Accrue UUID
  - `swap_plan` / `cancel` / `cancel_at_period_end` / `resume` / `pause` / `unpause` / `update_quantity` → existing `subscription.id` (Accrue UUID, not Stripe ID)
  - `pay_invoice` / `finalize_invoice` / `void_invoice` / `mark_uncollectible` / `send_invoice` → existing `invoice.id`
  - `set_default_payment_method` → existing `customer.id`
- **D3-63: `operation_id` propagation — one plug/middleware per entry point.**
  - **HTTP:** Ship `Accrue.Plug.PutOperationId` that runs after `Plug.RequestId`, reads `conn.assigns.request_id`, writes to `Accrue.Actor` pdict
  - **LiveView:** Ship `Accrue.LiveView.on_mount :accrue_operation` that stores `socket.id` + per-event counter (handle_event wrapper bumps)
  - **Oban:** Ship `Accrue.Oban.Middleware` that sets `operation_id = "oban-#{job.id}-#{job.attempt}"` (attempt included — Oban retries are new logical operations; previous events already recorded)
  - **Cron:** `"cron-#{worker}-#{cron_expression_hash}-#{scheduled_at_unix}"`
  - **Random fallback:** logs warning in `:dev`, **refuses in `:strict` config mode**
- **D3-64: Sequence suffix for legitimate multi-call requests** — `opts[:sequence]` (integer, default 0) folds into the hash: `sha256("#{op}|#{subject_id}|#{seed}|#{seq}")`. Escape hatch for auth+capture+upsell chains. 99% of calls omit.

### Canonical Event Taxonomy (EVT-04 extension)

- **D3-65: Event atom format is dotted atoms stored as strings** in `accrue_events.type`: `:"subscription.created"`, `:"invoice.paid"`. Same atom for user-action and webhook-reconcile paths. `actor :: :user | :system | :webhook | :oban | :admin` (D-15) plus `payload.source :: :api | :webhook | :reconcile | :cron` differentiate provenance.
- **D3-66: Phase 3 canonical event list — 24 events:**
  ```
  subscription.created, subscription.updated, subscription.trial_started,
  subscription.trial_ended, subscription.canceled, subscription.resumed,
  subscription.paused, subscription.plan_swapped,
  invoice.created, invoice.finalized, invoice.paid,
  invoice.payment_failed, invoice.voided, invoice.marked_uncollectible,
  charge.succeeded, charge.failed, charge.refunded,
  refund.created, refund.fees_settled,
  payment_method.attached, payment_method.detached, payment_method.updated,
  customer.default_payment_method_changed, card.expiring_soon
  ```
- **D3-67: Drop `subscription.canceling` and `payment_method.deduped` from the taxonomy.** Modality lives in payload: `subscription.canceled` carries `%{mode: :at_period_end | :immediate | :scheduled}`; `payment_method.attached` carries `%{deduped: true}` when dedup fired. Mechanism ≠ domain event.
- **D3-68: Payload shape = one module per event.** `Accrue.Events.Schemas.SubscriptionCreated` etc. — typed struct, `@derive Jason.Encoder`. Registry module `Accrue.Events.Schemas` maps atom → module for upcaster dispatch. Validated via NimbleOptions in dev/test only (zero prod cost).
- **D3-69: All Phase 3 events ship at `schema_version: 1`.** Additive fields in Phase 4 don't bump. Upcasters only exist for breaking changes (field rename, removal, structural reshape). Ship `Accrue.Events.Upcaster` behaviour now with zero implementations; document the contract.
- **D3-70: Reflexive subject rule:** `refund.fees_settled`'s subject is the refund UUID (not the parent charge); linked entities live in payload (`%{charge_id, fee_amount}`). General rule — the subject is the entity whose state changed; linked entities live in payload. Keeps `timeline_for/1` single-join.

### Expiring-Card Warnings (BILL-24)

- **D3-71: Detection is scheduled scan + webhook, both funneling through events + telemetry.** Webhook-only fails BILL-24 because Stripe's `customer.source.expiring` only fires for legacy `Source` objects — modern PaymentMethods get **nothing** re: upcoming expiry. Non-starter.
- **D3-72: Ship `Accrue.Jobs.DetectExpiringCards` Oban worker with `@default_cron "0 8 * * *"`.** Accrue ships the worker + documents the cron entry; host wires into their own Oban cron plugin per CLAUDE.md's config boundary ("Accrue does not start Oban"). Matches D-23 graduated-override shape.
- **D3-73: Default thresholds `[30, 7, 1]` days, configurable** via `config :accrue, :expiring_card_thresholds, [30, 7, 1]` (NimbleOptions-validated descending positive integers). Per-card, not per-customer.
- **D3-74: Auto-update handling — refresh silently, emit event + telemetry, no email by default.** `payment_method.card_automatically_updated` webhook → D2-29 refetch → `card.auto_updated` event → `[:accrue, :billing, :payment_method, :auto_updated]` telemetry. Auto-update is a *success*, not an action item. Hosts opt in to a `:card_auto_updated` email via the D-23 ladder.
- **D3-75: One semantic email type `:card_expiring`** with assigns `%{days_until_expiry, threshold, is_default_pm, payment_method, customer}`. Host templates branch on `@threshold` for escalating tone. NOT `:card_expiring_30d`/`:card_expiring_7d` separate types — violates D-22 semantic-type economy.
- **D3-76: Dedup state lives in `accrue_events`, not on a new column.** Query for existing `card.expiring_soon` events matching `(payment_method_id, threshold)` within last 365 days. Reuses the tamper-evident ledger (D-13). If hot, add `(payment_method_id, event_type)` partial index later. Rejects `last_expiry_warning_sent_at` column (duplicates ledger state).
- **D3-77: Default-PM escalation via telemetry metadata `is_default_pm: boolean`** — no separate event type, no auto-escalated email tone. Host concern. SRE metric "% customers with expiring default card" is derivable from `telemetry_metrics` filter.
- **D3-78: Zero Phase 4 dunning coupling.** Expiry warnings are pre-failure; dunning is post-failure. Share only the PM table. Phase 4 gets a clean dunning story.

### Test Fixtures + Factories (TEST-08)

- **D3-79: Plain function module primary API at `accrue/lib/accrue/test/factory.ex`** — no ExMachina dep. Continues Phase 1's pattern (`Accrue.Test.Mailer`, `Accrue.Test.PDF` live in `lib/accrue/test/`). Module-level `@moduledoc false` keeps hexdocs clean; per-function docs available.
- **D3-80: Nine first-class factories** (each returns `%{customer:, subscription:, items: ...}`):
  ```elixir
  Accrue.Test.Factory.customer(attrs \\ %{})
  Accrue.Test.Factory.subscription(attrs \\ %{})               # primitive
  Accrue.Test.Factory.trialing_subscription(attrs \\ %{})
  Accrue.Test.Factory.active_subscription(attrs \\ %{})
  Accrue.Test.Factory.past_due_subscription(attrs \\ %{})
  Accrue.Test.Factory.canceled_subscription(attrs \\ %{})
  Accrue.Test.Factory.incomplete_subscription(attrs \\ %{})
  Accrue.Test.Factory.canceling_subscription(attrs \\ %{})    # active + cancel_at_period_end
  Accrue.Test.Factory.grace_period_subscription(attrs \\ %{}) # canceled within current_period_end
  Accrue.Test.Factory.trial_ending_subscription(attrs \\ %{}) # trialing, trial_end within 72h
  ```
  `:unpaid`, `:incomplete_expired`, `:paused` defer to the `subscription(status: ...)` primitive.
- **D3-81: Sibling `Accrue.Test.Generators` at `lib/accrue/test/generators.ex`** for StreamData property tests. Gated by `Code.ensure_loaded?(StreamData)` since StreamData is dev/test-only in Accrue itself.
- **D3-82: Factories route through `Accrue.Processor.Fake`, not `Repo.insert!`.** Coherent with D-19 (Fake is the primary test surface) and D-20 (deterministic counter IDs come from Fake). Concretely: `trialing_subscription/1` calls `Fake.create_customer/1` then `Fake.create_subscription/2`. For states Fake can't reach directly (`:past_due`, `:canceled`, `:grace_period`), factories call `Fake.create_subscription/2` then `Fake.advance/2` + `Fake.transition/3` (internal helper Phase 3 needs for state-machine tests anyway).
- **D3-83: Test-clock threading is a hard rule** — every factory derives `trial_end`, `current_period_*`, `canceled_at`, `ended_at` from `Accrue.Processor.Fake.now/0` (via `Accrue.Clock`), never `DateTime.utc_now/0`. Documented in moduledoc.
- **D3-84: Factories are side-effect-pure** — no `IO.puts`, no `Logger.info`, no `Mix.env()` assertions. This is the Phase-3-to-Phase-8 contract: `mix accrue.seed` (Phase 8) calls factories directly in `:dev`.
- **D3-85: Async-safety test** — add an `async: true` test in Accrue's own suite that inserts 100 trialing subscriptions concurrently and asserts ID uniqueness. Regression guard for Fake counter isolation.

### Accrue.Clock module

- **D3-86: Ship `Accrue.Clock` as the canonical time source** for every Phase 3 mutation that stores a timestamp. In test env it delegates to `Accrue.Processor.Fake.now/0`; in dev/prod it's `DateTime.utc_now/0`. All `:trial_end` sugar, `current_period_*`, `canceled_at`, `ended_at`, `fees_settled_at`, `last_stripe_event_ts` reads go through `Accrue.Clock.utc_now/0`. Eliminates the "tests break at midnight" class of bugs.

### Claude's Discretion

Left to the Phase 3 planner / executor:

- Exact module layout under `lib/accrue/billing/` (one file per schema, one per workflow action, or grouped)
- Exact migration filenames and ordering (just needs `accrue_subscription_items` fill-out, `accrue_invoices` rollup columns + `accrue_invoice_items`, `accrue_charges`, `accrue_refunds`, `accrue_payment_methods` additions, `accrue_customers.default_payment_method_id`, and `last_stripe_event_ts/id` on all of the above)
- Exact internal function decomposition of `Accrue.Webhook.DefaultHandler` — just needs the skip-stale-then-refetch-then-record triple explicit
- Exact field list on `%Accrue.Events.Schemas.*{}` structs beyond the "subject is the changed entity, linked entities in payload" rule
- `Accrue.Billing.Query` fragment module's exact macro/function boundary — just needs composable in `where` clauses
- Test file organization (`test/accrue/billing/subscription_test.exs` vs grouped), property-test placement
- Internal shape of `Accrue.Processor.Fake.transition/3` helper
- Whether `NimbleOptions` schemas live inline in billing functions or in a `Accrue.Billing.Schemas` module
- Internal naming of worker modules (`Accrue.Jobs.*` vs `Accrue.Workers.*`) — CLAUDE.md leaves this open

### Folded Todos

None — no backlog items matched Phase 3.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project governance
- `/Users/jon/projects/accrue/CLAUDE.md` — tech stack pins, conditional-compile pattern, Oban CE vs Pro constraint, host-owned supervision ("Accrue does not start Oban / ChromicPDF"), monorepo layout
- `/Users/jon/projects/accrue/.planning/PROJECT.md` — vision, core value, "real SaaS on day one" constraint, zero-breaking-change-pain for v1.x
- `/Users/jon/projects/accrue/.planning/REQUIREMENTS.md` — Phase 3 requirement IDs: PROC-02, BILL-03..10, BILL-17..26, WH-09, TEST-08
- `/Users/jon/projects/accrue/.planning/ROADMAP.md` — Phase 3 goal, 6 success criteria, depends-on Phase 2

### Prior Phase contexts (MUST coherently extend)
- `/Users/jon/projects/accrue/.planning/phases/01-foundations/01-CONTEXT.md` — Phase 1 D-01..45 locked decisions (Money, error hierarchy, Fake processor with test clock, dual API, Events.record_multi, actor pdict, telemetry depth, mailer semantic API, PDF Shape B, Auth behaviour, conditional-compile Sigra)
- `/Users/jon/projects/accrue/.planning/phases/02-schemas-webhook-plumbing/02-CONTEXT.md` — Phase 2 D2-01..37 locked decisions (polymorphic Customer, Billable macro, metadata strict Stripe-compat, data jsonb put_data/patch_data, optimistic_lock, deterministic idempotency keys, Stripe API version override, webhook plug pipeline, transactional persist + Oban dispatch, DefaultHandler re-fetch canonical, DLQ status column, Pruner)

### External library docs (fetch via Context7 or WebFetch at plan time)
- `lattice_stripe ~> 1.0` source at `/Users/jon/projects/lattice_stripe/` — specifically:
  - `lib/lattice_stripe/subscription.ex` — Subscription API surface, including `items[]`, `cancel_at_period_end`, `pause_collection`
  - `lib/lattice_stripe/invoice.ex` — Invoice workflow endpoints (`finalize_invoice`, `void_invoice`, `mark_uncollectible`, `pay`, `send_invoice`, `upcoming`)
  - `lib/lattice_stripe/payment_intent.ex` — PI status enum, `next_action.type`, `client_secret`
  - `lib/lattice_stripe/setup_intent.ex` — SI parity
  - `lib/lattice_stripe/payment_method.ex` — `attach`, `detach`, fingerprint field
  - `lib/lattice_stripe/charge.ex` — balance_transaction expansion
  - `lib/lattice_stripe/refund.ex` — balance_transaction expansion for fee math
  - `lib/lattice_stripe/customer.ex` — `invoice_settings.default_payment_method`
  - `guides/error-handling.md` — idempotency error tuple shape
- Stripe API docs — https://stripe.com/docs/api
  - `POST /subscriptions` — https://stripe.com/docs/api/subscriptions/create (items[], trial_end, default_payment_method, payment_behavior)
  - `POST /subscriptions/:id` update — https://stripe.com/docs/api/subscriptions/update (proration_behavior, cancel_at_period_end, cancel_at, pause_collection)
  - `DELETE /subscriptions/:id` — https://stripe.com/docs/api/subscriptions/cancel (invoice_now, prorate)
  - `POST /subscriptions/:id/resume` — https://stripe.com/docs/api/subscriptions/resume
  - `GET /invoices/upcoming` — https://stripe.com/docs/api/invoices/upcoming (proration preview, proration_date)
  - Invoice workflow — https://stripe.com/docs/api/invoices/finalize, /void, /mark_uncollectible, /pay, /send
  - PaymentIntent status — https://stripe.com/docs/api/payment_intents/object#payment_intent_object-status
  - SCA flow — https://stripe.com/docs/payments/payment-intents#passing-to-client
  - Balance transactions + refund fees — https://stripe.com/docs/api/balance_transactions
  - Proration behavior — https://stripe.com/docs/billing/subscriptions/prorations
  - Trial webhook — https://stripe.com/docs/api/events/types#event_types-customer.subscription.trial_will_end
  - Card automatically updated — https://stripe.com/docs/api/events/types#event_types-payment_method.card_automatically_updated
  - Idempotency — https://stripe.com/docs/api/idempotent_requests
- `Ecto.Enum` — https://hexdocs.pm/ecto/Ecto.Enum.html (D3-01, D3-17)
- `Ecto.UUID` — https://hexdocs.pm/ecto/Ecto.UUID.html (D3-61 deterministic UUID derivation)
- `Ecto.Repo.transact/2` — https://hexdocs.pm/ecto/Ecto.Repo.html#c:transact/2
- `NimbleOptions` — https://hexdocs.pm/nimble_options (D3-21, D3-22 required `:proration` opt with ArgumentError)
- `Phoenix.LiveView.on_mount/1` — https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1 (D3-63)
- `Plug.RequestId` — https://hexdocs.pm/plug/Plug.RequestId.html (D3-63 HTTP operation_id source)
- `Oban.Worker` middleware — https://hexdocs.pm/oban/Oban.Worker.html (D3-63 Oban operation_id)
- `Oban.Plugins.Cron` — https://hexdocs.pm/oban/Oban.Plugins.Cron.html (D3-46, D3-72 host-wired cron)
- `Credo` custom check guide — https://hexdocs.pm/credo/writing-a-custom-check.html (D3-04 `Accrue.Credo.NoRawStatusAccess`)
- `StreamData` — https://hexdocs.pm/stream_data (D3-81 property test generators)

### Prior art (consult for API shape, NOT for code copying)
- Pay (Rails) — https://github.com/pay-rails/pay
  - `app/models/pay/subscription.rb` — predicate naming (`active?`, `on_trial?`, `cancelled?`), silent `swap` proration (what NOT to do, see BILL-09)
  - `app/models/concerns/pay/billable.rb` — `payment_processor` laziness precedent
  - `app/models/pay/charge.rb` — no fee-loss tracking (what NOT to do, BILL-26 is the differentiator)
  - `lib/pay/action_required.rb` — exception-based SCA (idiomatic in Ruby, inappropriate in Elixir — D3-06 tuple-based replacement)
- Laravel Cashier — https://github.com/laravel/cashier-stripe
  - `src/Subscription.php` — `cancel()`, `cancelNow()`, `resume()` naming (cleaner than Pay but loses Stripe fidelity — D3-26 keeps Stripe's `cancel_at_period_end` vocabulary)
  - `src/Concerns/InteractsWithPaymentBehavior.php` — `noProrate()`/`prorate()` builder API (what NOT to do — implicit prorate default violates BILL-09)
  - `src/Concerns/ManagesSubscriptions.php` — `updateQuantity()`, `incrementQuantity()`, `decrementQuantity()` (D3-33 keeps `update_quantity/2` only)
  - `src/Concerns/ManagesInvoices.php` — `invoicePreview()` returning raw Stripe object (what NOT to do — D3-19 ships typed struct)
  - `src/Exceptions/IncompletePayment.php` — exception-based SCA precedent (idiomatic in PHP, replaced by D3-06 tuple)
  - `src/Concerns/ManagesPaymentMethods.php` — `hasPaymentMethod()` predicate, silent first-PM fallback (D3-58 makes it loud instead)
- `izelnakri/paper_trail` — polymorphic item_type/item_id string column (Phase 2 D2-01, referenced)
- Stripe's own stripe-node / stripe-ruby SDKs — raw Stripe API shapes, no UX layer (not a pattern source, just API reference)

### Event ledger + idempotency precedent
- `Oban.Worker` `perform/1` pattern-match — https://hexdocs.pm/oban/Oban.Worker.html (D3-65 dotted-atom event types mirror Oban's `perform` dispatch idiom)
- Event sourcing upcasters — https://github.com/commanded/commanded (rejected as a CQRS framework, but the upcaster contract shape is referenced for D3-69 even though Accrue uses append-only events, not full CQRS)

### Webhook-driven reconciliation precedent
- `spatie/laravel-webhook-client` — status-column webhook event ledger (Phase 2 D2-33 reference)
- Stripe fixture replay patterns — https://github.com/stripe/stripe-mock — used as shape reference for D3-42 Fake synthesis

</canonical_refs>

<code_context>
## Existing Code Insights

Phase 3 builds on the Phase 2 schema + webhook layer shipped in `/Users/jon/projects/accrue/accrue/`:

### Reusable Assets (from Phase 1 + Phase 2)
- `Accrue.Money` + `Accrue.Ecto.Money` — used for every money column added in Phase 3 (`stripe_fee_amount`, `stripe_fee_refunded_amount`, `merchant_loss_amount`, invoice rollups, charge amounts)
- `Accrue.Error.*` hierarchy — Phase 3 adds `%Accrue.Error.MultiItemSubscription{}`, `%Accrue.Error.InvalidState{}`, `%Accrue.Error.NotAttached{}`, `%Accrue.Error.NoDefaultPaymentMethod{}`, `%Accrue.ActionRequiredError{payment_intent}`
- `Accrue.Events.record/1` + `record_multi/3` — wraps every Phase 3 state mutation (EVT-04 compliance)
- `Accrue.Processor` behaviour + `Accrue.Processor.Fake` — extended in Phase 3 with subscription lifecycle callbacks, `Fake.transition/3` internal helper, webhook synthesis on `advance/2`
- `Accrue.Processor.Stripe` adapter — extended with full Subscription/Invoice/Charge/PI/SI/PM/Refund operations; remains the ONLY module that imports `lattice_stripe`
- `Accrue.Actor` pdict — extended with `operation_id` slot (currently only holds actor type + operation_id from Phase 2 webhooks)
- `Accrue.Config` — adds `:expiring_card_thresholds`, `:idempotency_mode` (`:warn | :strict`), `:succeeded_refund_retention_days`
- `Accrue.Telemetry` — Phase 3 adds `[:accrue, :billing, :subscription, :*]`, `[:accrue, :billing, :invoice, :*]`, `[:accrue, :billing, :charge, :*]`, `[:accrue, :billing, :refund, :*]`, `[:accrue, :billing, :payment_method, :*]`, `[:accrue, :webhooks, :stale_event]`, `[:accrue, :webhooks, :refetched]` events
- Phase 2 `Accrue.Billing.Subscription` skeleton at `accrue/lib/accrue/billing/subscription.ex` — status field is currently `:string`; Phase 3 upgrades to `Ecto.Enum` and adds `cancel_at_period_end` + `pause_collection` columns
- Phase 2 `Accrue.Billing.Invoice` skeleton — Phase 3 fills in rollup columns, state machine, child items schema
- Phase 2 `Accrue.Billing.PaymentMethod` skeleton — Phase 3 adds `fingerprint`, `exp_month`, `exp_year`, `existing?` virtual field, partial unique index
- Phase 2 `Accrue.Billing.Charge` skeleton — Phase 3 adds `stripe_fee_amount`, `fees_settled_at`
- Phase 2 `Accrue.Billing.SubscriptionItem` skeleton — Phase 3 fills in `price_id`, `processor_plan_id`, `processor_product_id`, `current_period_start/end`
- Phase 2 `Accrue.Webhook.DefaultHandler` — Phase 3 extends with per-event reducers for subscription.*, invoice.*, charge.*, refund.*, payment_method.*, and the skip-stale + refetch + record triple
- Phase 2 `Accrue.Billing` context — Phase 3 adds full write surface; currently has `customer/1`, `create_customer/1`, `update_customer/2`, `put_data/2`, `patch_data/2`

### New schemas added in Phase 3
- `accrue_refunds` (new table)
- `accrue_invoice_items` (new table, FK to `accrue_invoices`)
- `accrue_invoice_coupons` (new join table)
- `accrue_coupons` (new minimal table; full coupon CRUD is Phase 4)

### Established Patterns (MUST extend, not duplicate)
- Dual tuple + raise! API on every public function (D-05)
- `intent_result/1` on every PI/SI-capable public function (D3-06/07, new in Phase 3)
- `Repo.transact/2` for all multi-step state mutations (Phase 2)
- Behaviour + Default Adapter + Test Adapter pattern (Phase 1) — Phase 3 extends `Accrue.Processor` behaviour
- `Events.record_multi/3` wrapping every state mutation (D-13, EVT-04)
- Telemetry span/3 wrapping every public function (D-17)
- Webhook handler chaining: DefaultHandler first (non-disableable), user handlers after, per-handler rescue (D2-30)
- `put_data` (full replace) / `patch_data` (merge) on processor-owned state (D2-08)
- `optimistic_lock` on `lock_version` for concurrent mutation safety (D2-09)
- Deterministic idempotency keys via SHA256(`op|subject_id|seed`) (D2-11, D3-60/61)
- `Accrue.Actor` process-dict context for actor + operation_id (D-15, D3-63)

### Integration Points
- Host router — existing `import Accrue.Router` + `accrue_webhook/2` macro from Phase 2
- Host Repo — `config :accrue, :repo, MyApp.Repo`; Accrue never supervises
- Host Oban instance — Phase 3 adds `accrue_refunds_reconciler` and `accrue_charges_reconciler` and `accrue_expiring_cards` jobs to the host's Oban cron plugin (Accrue documents; host wires)
- Host endpoint — new plug `Accrue.Plug.PutOperationId` runs after `Plug.RequestId`
- Host LiveView — new `Accrue.LiveView.on_mount :accrue_operation` hook for LiveView entry points
- Host `MyApp.Billing` context facade — Phase 8 installer will generate delegating wrappers around `Accrue.Billing.*`; Phase 3 ships the underlying context only

</code_context>

<specifics>
## Specific Ideas

- **Stripe-faithful status enum with Accrue-owned predicates** is the exact balance: D3-01 (Stripe vocab) + D3-03 (Accrue semantics) + D3-04 (Credo enforcement). Principle of least surprise wins on vocabulary; footgun gating wins on API.
- **Pre-generated deterministic UUIDs** (D3-60/61) are the specific differentiator enabling both idempotency AND consistent event FKs without the dual-write race. Not in Pay-Ruby, not in Cashier.
- **Fake processor auto-synthesizing `trial_will_end` + `subscription.updated` webhooks on `advance/2`** (D3-42) is the test-story differentiator — Pay-Ruby and Cashier-PHP cannot do this, and it's exactly where SaaS developers burn hours writing time-dependent tests.
- **Hybrid invoice projection** (D3-13/14/15) is specifically designed for Phase 7's admin LiveView — fast typed-column filter/sort/sum with preloadable child items for PDF rendering, without forcing every admin page to hit Stripe (Cashier's failure mode).
- **Single `:requires_action` tag reused across PI and SI** (D3-10) is Elixir-idiomatic: one atom to learn, struct type disambiguates. Two tags would be two things to memorize.
- **Events-table-as-dedup-state for expiring-card warnings** (D3-76) reuses the tamper-evident append-only ledger instead of adding a mutable column — coherent with D-13's "ledger IS truth" principle.
- **`intent_result/1` narrow doctrine** (D3-07) — intent_result appears only where SCA is actually possible, not sprinkled uniformly. Callers get a truthful type.
- **Two cancel verbs, not one overload** (D3-26) — `cancel/2` always immediate, `cancel_at_period_end/2` always soft, avoids the default-ambiguity footgun of `cancel(at:)`.
- **`update_quantity/2` as first-class single-item op** (D3-33) — per-seat SaaS needs this, deferring to Phase 4 would make Phase 3 useless for most hosts.
- **BILL-26 fee-loss tracking + daily reconciler** (D3-45/46) is a headline differentiator — Pay and Cashier silently swallow merchant loss on refunds.

</specifics>

<deferred>
## Deferred Ideas

These came up during discussion but belong in later phases. Noted so they're not lost and not re-surfaced as "missed":

- **Metered usage + `report_usage/3` + `Stripe.BillingMeter` / `MeterEvent`** — Phase 4 (BILL-11). Blocked on lattice_stripe 1.1 release.
- **Multi-item write operations (`add_item/2`, `remove_item/2`, `update_items/3`)** — Phase 4 (BILL-12). Phase 3 ships the read-any-item projection; Phase 3's `MultiItemSubscription` guard disappears in Phase 4.
- **Free/comped subscription tiers (subscribe without PaymentMethod)** — Phase 4 (BILL-13).
- **Dunning orchestration (past_due → unpaid state machine with retry policy)** — Phase 4 (BILL-14/15). Phase 3 only projects `past_due` state via webhook; the retry orchestration is Phase 4.
- **Subscription schedules** — Phase 4 (BILL-16).
- **Coupon / promotion code CRUD API + redemption** — Phase 4. Phase 3 ships the minimal `accrue_coupons` + `accrue_invoice_coupons` schema because invoice projection references them, but full CRUD is Phase 4.
- **Customer Portal Session** — Phase 4 (CHKT-02). Blocked on lattice_stripe 1.1.
- **Checkout Session** — Phase 4 (CHKT-01).
- **Subscription-level `default_payment_method_id` override** — Phase 4. Phase 3 wires customer-level default only (D3-59).
- **`preview_upcoming_invoice/2` caching** — documented as v1.1+ work if telemetry shows Stripe rate-limiting (D3-24).
- **`:card_auto_updated` email** — Phase 6 template work; Phase 3 emits the event + telemetry but doesn't fire the email by default (D3-74).
- **Escalating card-expiring email tones per threshold** — deferred to host template logic branching on `@threshold` assign (D3-75).
- **Stripe Connect multi-endpoint webhook variants with per-account secret routing** — Phase 5 (WH-13). Phase 2 D2-18 already left the macro shape Connect-ready.
- **Admin LiveView pages** (subscription detail, invoice detail, webhook inspector, refund initiation) — Phase 7.
- **Scheduled cron helpers documented in install guide** — Phase 8 `mix accrue.install` will generate the cron entries for `Accrue.Jobs.ReconcileRefundFees`, `Accrue.Jobs.ReconcileChargeFees`, `Accrue.Jobs.DetectExpiringCards`, `Accrue.Webhooks.Pruner`. Phase 3 ships the workers with documented `@default_cron` attrs.
- **`Accrue.Test.advance_clock/2`, `trigger_event/2`, `assert_event_recorded/2` helpers** — Phase 8 (TEST-02..07). Phase 3 factories pre-thread `Accrue.Clock` + `Fake` so Phase 8 wrappers reuse them directly.
- **`mix accrue.seed` dev-data populator** — Phase 8. Phase 3 keeps factories side-effect-pure as the seam (D3-84).
- **OpenTelemetry span auto-wiring per Billing context function** — Phase 8 (OBS-02).
- **ExMachina integration** — explicitly rejected as non-goal (D3-79).

</deferred>

---

*Phase: 03-core-subscription-lifecycle*
*Context gathered: 2026-04-14*
