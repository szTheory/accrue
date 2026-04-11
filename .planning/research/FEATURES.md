# Feature Research — Accrue v1.0

**Domain:** Open-source Elixir/Phoenix payments & billing library (Stripe-backed, with companion admin UI)
**Researched:** 2026-04-11
**Confidence:** HIGH (source of truth is PROJECT.md + locked decisions; Stripe gotchas drawn from field-guide research and prior art from Pay/Cashier/dj-stripe)

---

## 0. How To Read This Document

Every feature carries a unique identifier. Identifiers are stable and intended to be referenced by `REQUIREMENTS.md`, `ROADMAP.md`, commits, PRs, and tests. Prefixes:

| Prefix | Domain |
|---|---|
| `BILL` | Core billing domain (Customer, Subscription, Invoice, Charge, PaymentMethod, etc.) |
| `CONN` | Stripe Connect / marketplaces |
| `CHKT` | Checkout & Portal sessions |
| `PROC` | Processor abstraction (behaviour + adapters) |
| `WH`   | Webhook pipeline |
| `EVT`  | Event ledger |
| `MAIL` | Email |
| `PDF`  | PDF generation |
| `ADMIN`| Admin UI (`accrue_admin`) |
| `AUTH` | Auth integration |
| `INST` | Install generator / DX |
| `OBS`  | Observability |
| `TEST` | Testing helpers |
| `OSS`  | OSS hygiene / release infrastructure |
| `BRND` | Brand / theming |

Complexity scale: **T** = Trivial (<0.5d), **S** = Small (0.5–2d), **M** = Medium (2–5d), **L** = Large (5–10d), **XL** = X-Large (>10d). Ranges assume single-developer pace on a well-understood problem; they are calibration hints for the roadmapper, not estimates.

Category tags:
- **TS** = Table stakes (ship or the library is rejected)
- **DIFF** = Differentiator (competitive advantage vs Bling / bare lattice_stripe)
- **FOUND** = Foundational infrastructure (not user-visible, but everything depends on it)

---

## 1. Core Billing Domain

### 1.1 Customer + Polymorphic Billable

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BILL-001 | `Accrue.Billing.Customer` schema | TS | S | Polymorphic `owner_type` / `owner_id` pair; `data` jsonb for full Stripe Customer snapshot; `processor` discriminator; `processor_id` unique per processor; `deleted_at` soft delete |
| BILL-002 | `use Accrue.Billable` macro | TS / DIFF | S | Host-schema mixin exposing `customer/0`, `subscribe/2`, `charge/2`, `on_trial?/0`, `subscribed?/0`, `payment_methods/0`, `default_payment_method/0`, `invoices/0`. Macro is thin — delegates to context functions. |
| BILL-003 | `Accrue.Billing.create_customer/2` | TS | S | Creates Stripe customer via lattice_stripe + local row in single `Repo.transact`; idempotent on (owner_type, owner_id) |
| BILL-004 | Customer sync from webhook | TS | S | `customer.updated` → upsert local snapshot; respects last-write-wins with `updated_at` |
| BILL-005 | Customer metadata merge helper | DIFF | T | `update_customer_metadata/2` that deep-merges rather than replacing (common Stripe footgun — Stripe's API replaces the whole hash) |
| BILL-006 | Tax ID management | TS | S | Add/remove tax IDs on customer (EU VAT, US EIN). Required for B2B SaaS or invoices are non-compliant. |

**Gotchas flagged:** (a) `owner_type` must store the Elixir module string, not a table name — changing module names requires a data migration; document this. (b) Stripe customer deletion is soft; `deleted: true` is returned but ID still resolves — do not confuse with 404. (c) Metadata replace-not-merge trap (BILL-005 exists specifically to hide this).

### 1.2 Subscription

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BILL-010 | `Accrue.Billing.Subscription` schema | TS | S | `status`, `current_period_start/end`, `cancel_at_period_end`, `canceled_at`, `trial_end`, `data` jsonb, `processor_id`, FK to customer, multi-item support |
| BILL-011 | Create subscription | TS | M | `subscribe(billable, price, opts)` — creates Stripe sub, handles trial, collection_method, default payment method; returns `{:ok, sub}` or `{:error, %CardError{}}` |
| BILL-012 | Swap plan (proration) | TS | M | Upgrade/downgrade; defaults to `create_prorations`; `proration_behavior` option passes through. Must refresh local state after Stripe returns the updated sub. |
| BILL-013 | Quantity change | TS | S | Seat-based billing helper; single-call `update_quantity/2` |
| BILL-014 | Cancel at period end | TS | S | Sets `cancel_at_period_end = true`. **Gotcha:** local row stays `status = active` until period end — querying "is canceled" must also check `cancel_at_period_end`. Expose `canceling?/1` helper. |
| BILL-015 | Immediate cancel | TS | S | `cancel_now/1` — proration credit handling, then hard cancel |
| BILL-016 | Resume | TS | S | Only valid when `cancel_at_period_end = true` AND period still active. Hard error otherwise. |
| BILL-017 | Pause subscription | TS | S | Stripe `pause_collection` wrapper; three modes: `keep_as_draft`, `mark_uncollectible`, `void` |
| BILL-018 | Trial support | TS | S | `trial_ends_at`; webhook-driven transition to active; email hooks |
| BILL-019 | Comped / free-tier subscription | DIFF | S | Subscription on a 0-amount price OR `trial_end=forever`-style pattern; no PaymentMethod required; clearly documented pattern |
| BILL-020 | Grace period / dunning | TS | M | Configurable retry schedule (Smart Retries vs custom); `past_due` → `unpaid` → `canceled` transitions surfaced as domain events |
| BILL-021 | `on_grace_period?/1`, `subscribed?/1`, `on_trial?/1` predicates | TS | T | Consumer API polish; these are the functions users call in LiveView templates |
| BILL-022 | Multi-item subscriptions | TS | M | Sub with multiple `subscription_items`; per-item quantity; add/remove item helpers |
| BILL-023 | Metered billing (usage records) | TS | M | `report_usage/3`; supports `action: :increment | :set`; timestamp-aware |

**Gotchas flagged:** `cancel_at_period_end` staying active is the #1 footgun. `incomplete` status has a 23-hour window before Stripe auto-cancels; we must surface this in the admin UI clock. Proration behavior defaults bit everyone — force an explicit choice at the API level.

### 1.3 Invoice

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BILL-030 | `Accrue.Billing.Invoice` schema | TS | S | States: `draft | open | paid | void | uncollectible`; `total`, `amount_paid`, `amount_due`, `currency`, `lines` (jsonb), `hosted_invoice_url`, `invoice_pdf` |
| BILL-031 | Invoice state machine | TS | S | Explicit transitions via `Ecto.Multi`; illegal transitions raise `Accrue.InvalidTransitionError` |
| BILL-032 | Finalize invoice | TS | S | Draft → open; emits `invoice.finalized` domain event |
| BILL-033 | Pay invoice | TS | S | Manual pay; webhook-driven pay |
| BILL-034 | Void invoice | TS | T | Terminal; no re-open |
| BILL-035 | Mark uncollectible | TS | T | Terminal-ish; unlike void, can be reversed via `mark_collectible` |
| BILL-036 | Line items | TS | S | Read-through from Stripe `data`; helpers for description, amount, period |
| BILL-037 | Upcoming invoice preview | DIFF | S | `preview_upcoming_invoice/1` — critical for "here's what you'll be charged" UIs |
| BILL-038 | Send invoice email | TS | T | Wires to MAIL-004 / MAIL-007 |
| BILL-039 | Invoice PDF attachment | TS | S | Wires to PDF-003 |
| BILL-040 | Invoice numbering | TS | T | Read-through only (Stripe assigns); do not re-number |

### 1.4 Charge / PaymentIntent / SetupIntent

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BILL-050 | `Accrue.Billing.Charge` schema | TS | S | Mirrors Stripe charge; FK to customer; `amount`, `currency`, `status`, `data` |
| BILL-051 | `Accrue.Billing.PaymentIntent` schema | TS | S | `status`, `client_secret`, `next_action`, `data` |
| BILL-052 | `Accrue.Billing.SetupIntent` schema | TS | S | For off-session PM setup / adding cards without charging |
| BILL-053 | One-time charge | TS | S | `charge(billable, amount, currency, opts)` returning `{:ok, charge}` or `{:ok, :requires_action, intent}` |
| BILL-054 | `requires_action` / 3DS / SCA flow | TS | M | Returning a tagged tuple pushes the handling decision to the LiveView layer — documented pattern with example. Non-optional post-PSD2. |
| BILL-055 | Off-session charge attempt | TS | S | `off_session: true`; typed error on `authentication_required` |
| BILL-056 | Capture after auth-hold | DIFF | S | Separate auth + capture flow (hotel-style holds); `capture_method: :manual` |

**Gotchas flagged:** (a) `requires_action` is not an error — it's a normal flow state; typing it as `{:ok, :requires_action, _}` vs `{:error, _}` is a deliberate design decision to avoid user-code confusion. (b) `client_secret` must never be logged. (c) `incomplete` PIs expire after 23 hours — surface this in admin.

### 1.5 PaymentMethod

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BILL-060 | `Accrue.Billing.PaymentMethod` schema | TS | S | `type` (card/us_bank_account/etc), `last4`, `brand`, `exp_month`, `exp_year`, `fingerprint`, `data`, `is_default` |
| BILL-061 | Add payment method | TS | S | Via SetupIntent → attach; returns new PM |
| BILL-062 | Remove payment method | TS | T | Detaches from Stripe + soft-deletes locally |
| BILL-063 | Set default payment method | TS | S | Mutates Stripe customer `invoice_settings.default_payment_method`; local row `is_default` via transaction |
| BILL-064 | Fingerprint-based dedup | DIFF | S | Prevent adding the literal same card twice (Stripe won't block it; users hate it) |
| BILL-065 | Payment method expiry warning | DIFF | S | Domain event + email when `exp_month/year` is within 30 days of current period |

### 1.6 Refund

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BILL-070 | `Accrue.Billing.Refund` schema | TS | S | FK to charge; `amount`, `reason`, `status`, `data` |
| BILL-071 | Full refund | TS | S | `refund_charge/2` |
| BILL-072 | Partial refund | TS | S | `refund_charge/3` with amount |
| BILL-073 | **Fee-aware refund** | DIFF | S | Stripe does NOT refund the processing fee by default on refunds (gotcha #14). Accrue surfaces `refund_application_fee: true` option with clear docs and test-clock fixture coverage. |
| BILL-074 | Refund webhook reconciliation | TS | S | `charge.refunded` handler updates local charge `amount_refunded` |

### 1.7 Coupons, Promotion Codes, Gift Cards

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BILL-080 | `Accrue.Billing.Coupon` schema | TS | S | Percent or amount off; duration (once/forever/repeating); redemption limits; currency |
| BILL-081 | Create / list / delete coupons | TS | S | Context functions + admin UI pages |
| BILL-082 | `Accrue.Billing.PromotionCode` schema | TS | S | User-redeemable code wrapping a coupon; max_redemptions, expires_at |
| BILL-083 | Apply to subscription | TS | S | Adds promotion_code / coupon on Stripe sub |
| BILL-084 | Apply to one-time charge | TS | S | Via Checkout Session or invoice line discount |
| BILL-085 | Validate redemption | TS | S | `validate_promotion_code/2` — checks expiry, max redemptions, currency match |
| BILL-086 | Gift card / prepaid credit | DIFF | L | Gift card is NOT a Stripe primitive — model as `Accrue.Billing.GiftCard` schema with balance, redeem-to-customer-balance flow via Stripe customer balance; invoice auto-consumes. Complexity is "large" because Stripe doesn't model it. **Consider deferring** to v1.1 if roadmap pressure. |

**Recommendation:** BILL-086 gift cards are listed in PROJECT.md but are materially more complex than anything else in 1.x. Flag to the roadmapper: "if phase budget is tight, this is the one feature that cleanly descopes."

### 1.8 Multi-Currency

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BILL-090 | Currency-aware amount storage | TS | S | Always store `amount` as integer in smallest currency unit + `currency` field |
| BILL-091 | `Accrue.Money` value type | DIFF | S | `%Accrue.Money{amount: 1999, currency: "usd"}` with formatter, arithmetic, Decimal bridge |
| BILL-092 | Zero-decimal currency safety | TS | S | `zero_decimal?/1` helper; multiply/divide corrections; test fixtures for JPY, KRW, VND, CLP |
| BILL-093 | Three-decimal currency safety | TS | T | BHD, KWD, OMR — divide-by-1000 not 100. Often missed. |
| BILL-094 | Currency mismatch guard | TS | S | Cannot apply USD coupon to EUR subscription; raise at context-function boundary |

**Gotchas flagged:** Zero-decimal (`%{amount: 100, currency: "jpy"}` = ¥100, not ¥1) is the single most common multi-currency bug. Three-decimal currencies are almost always forgotten.

### 1.9 Subscription Schedules

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BILL-100 | `Accrue.Billing.SubscriptionSchedule` schema | TS | M | Wraps Stripe schedule; phases jsonb; start/end dates |
| BILL-101 | Create schedule from existing sub | TS | M | `schedule_subscription/2` migrates active sub onto a schedule |
| BILL-102 | Multi-phase (intro → standard pricing) | TS | M | Phase definitions with pricing swaps; reference use-case: "3 months at $9, then $29/mo forever" |
| BILL-103 | Release schedule | TS | S | `release_schedule/1` — converts back to plain sub |

---

## 2. Stripe Connect / Marketplaces

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| CONN-001 | `Accrue.Billing.ConnectedAccount` schema | TS | S | `type` (standard/express/custom), `details_submitted`, `charges_enabled`, `payouts_enabled`, `data` |
| CONN-002 | Create connected account | TS | S | `create_connected_account/2` with type selection |
| CONN-003 | Account Link (onboarding URL) | TS | S | `create_account_link/2` — returns ephemeral onboarding URL |
| CONN-004 | Onboarding status sync | TS | S | Webhook `account.updated` → local row |
| CONN-005 | Destination charges | TS | M | `charge(platform_customer, amount, on_behalf_of: connected_account, application_fee_amount: fee)` |
| CONN-006 | Separate charges + transfers | TS | M | Two-step: charge on platform, then `create_transfer/3` to connected account |
| CONN-007 | Platform fee computation helper | DIFF | S | `application_fee/2` — percentage or flat — keeps fee logic out of user code |
| CONN-008 | Dashboard / login link | TS | T | `create_login_link/1` for Express dashboard |
| CONN-009 | Payout schedule config | TS | S | Surfaces Stripe `payout_schedule` on account |
| CONN-010 | Reject account | DIFF | T | `reject_connected_account/2` — wraps Stripe reject API |
| CONN-011 | Capability management | TS | S | Request / check capabilities (card_payments, transfers) |

**Gotchas flagged:** (a) Connect onboarding links are single-use and expire — regenerate on demand, never cache. (b) `charges_enabled: false` while `details_submitted: true` is a valid state (Stripe review in progress) — admin UI must show this clearly. (c) Connect webhooks come from a different endpoint convention (`connect: true` on webhook endpoints) — the pipeline must support multiple endpoints.

---

## 3. Checkout & Portal Sessions

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| CHKT-001 | Create Checkout Session | TS | S | Supports `mode: :payment | :subscription | :setup`; return/cancel URLs; success session handling |
| CHKT-002 | Prefill customer | TS | T | Pass existing `customer` to avoid double-creation |
| CHKT-003 | Line items helper | TS | T | Ergonomic builder for `line_items` with price/quantity |
| CHKT-004 | Trial via Checkout | TS | T | `subscription_data: %{trial_period_days: _}` |
| CHKT-005 | Post-checkout sync | TS | S | `retrieve_session/1` to pull customer/subscription into local state on return URL |
| CHKT-006 | Create Customer Portal Session | TS | S | Returns URL; configuration ID supported |
| CHKT-007 | Portal configuration helper | DIFF | S | `configure_portal/1` — wraps Stripe portal configuration (what users can update) behind a typed API |

**Gotchas flagged:** (a) Checkout Session success-URL pattern — most users forget that webhook is the source of truth, not the redirect. Docs must lead with this. (b) Customer Portal default config is usually wrong (lets users cancel with no dunning) — Accrue's `configure_portal/1` with sane defaults is a legitimate differentiator.

---

## 4. Processor Abstraction

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| PROC-001 | `Accrue.Processor` behaviour | FOUND | M | Callbacks: `create_customer/2`, `update_customer/2`, `create_subscription/3`, `cancel_subscription/2`, `create_charge/3`, `create_refund/2`, `verify_webhook/3`, plus config + Connect variants. Designed to not leak Stripe specifics (no `payment_intent` callback — use `create_charge` + tagged return). |
| PROC-002 | Stripe adapter | FOUND / TS | L | `Accrue.Processor.Stripe` — delegates to lattice_stripe. **Large** because it bridges every callback. |
| PROC-003 | Fake processor | FOUND / DIFF | L | `Accrue.Processor.Fake` — in-memory ETS state, deterministic IDs, test clock, scriptable responses, event-trigger API. **Primary test surface**, not a corner case. |
| PROC-004 | Processor selection at call site | FOUND | S | Configured per-customer via `processor` field; runtime dispatch through a dispatcher module |
| PROC-005 | Processor capability introspection | DIFF | S | `processor.supports?(:metered_billing)` — keeps user code from hitting `:not_implemented` at runtime |

**Gotchas flagged:** Building the behaviour without a second real adapter is the #1 trap (Cashier's "beautiful lie"). Compensate by (a) documenting "Stripe-first, behaviour is experimental / may break in 1.x" in module doc, (b) having PROC-003 Fake be second adapter to pressure-test the shape.

---

## 5. Webhook Pipeline

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| WH-001 | Raw-body capture plug | TS | S | `Accrue.Plug.RawBody` — reads body into `conn.assigns[:raw_body]` before `Plug.Parsers` consumes the stream. **Mounted in a scoped pipeline** so it only runs on webhook routes (never global — it kills streaming elsewhere). |
| WH-002 | Signature verification | TS | S | Delegates to lattice_stripe; rejects non-matching with 400, timing-safe compare |
| WH-003 | `accrue_webhook_events` table | FOUND / TS | S | Columns: `processor_event_id` (UNIQUE), `type`, `payload` jsonb, `received_at`, `processed_at`, `status` (received/processing/processed/failed/dead_letter), `attempts`, `last_error`, `trace_id` |
| WH-004 | DB idempotency via INSERT | TS | S | Unique violation on `processor_event_id` is the dedup boundary; 409-equivalent returned 200 OK to Stripe (don't retry a dupe) |
| WH-005 | Oban dispatch | TS | S | Insert + enqueue in single `Repo.transact`; Oban worker picks up, loads event, dispatches to user handler |
| WH-006 | Exponential backoff + max attempts | TS | T | Oban default with project-overrideable config |
| WH-007 | Dead letter queue | TS | S | After N attempts, move to `status: dead_letter`; domain event emitted |
| WH-008 | User handler contract | TS | S | `@behaviour Accrue.Webhooks.Handler` with `handle_event(type, payload, meta)`; pattern-matchable event types as atoms |
| WH-009 | Built-in core handlers | TS | M | Accrue's own handler updates local state for every relevant event type (sub, invoice, customer, charge, refund) **before** user handler runs — keeps user handlers small |
| WH-010 | Event type constants | TS | T | `Accrue.Webhooks.Events` module with every Stripe event as an atom to avoid string typos (addresses a lattice_stripe gap) |
| WH-011 | Replay tool | TS | S | `Accrue.Webhooks.replay/1` — re-enqueues a specific event |
| WH-012 | Bulk requeue dead-lettered | TS | S | `Accrue.Webhooks.requeue_dead_letter/1` with filter (by type / time window) |
| WH-013 | Webhook endpoint registration helper | TS | T | `mix accrue.webhook.register` — convenience task |
| WH-014 | Multi-endpoint support (Connect) | TS | S | Separate endpoint secret for Connect webhooks; same pipeline, different verifier |
| WH-015 | Raw-body size guard | TS | T | Reject > configured max (default 1MB) to mitigate DoS |
| WH-016 | Out-of-order handling | TS | S | Use `created` timestamp + domain-level "is this stale?" check — never blindly overwrite newer state with older event |

**Gotchas flagged:** (a) Raw body plug must be scoped (WH-001) — globally mounting it is a common mistake that breaks every other route. (b) Webhooks arrive out of order; blind overwrites corrupt state (WH-016). (c) Stripe retries up to 3 days with backoff — DLQ policy must account for this. (d) `customer.subscription.deleted` can arrive BEFORE `customer.subscription.updated` in rare cases (WH-016 again).

---

## 6. Event Ledger

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| EVT-001 | `accrue_events` table | FOUND | S | `id`, `subject_type`, `subject_id`, `type`, `data` jsonb (with embedded `schema_version`), `actor_type`, `actor_id`, `trace_id`, `occurred_at`; indexes on `(subject_type, subject_id, occurred_at)` and `(type, occurred_at)` |
| EVT-002 | Append-only enforcement | FOUND | S | Postgres trigger: `BEFORE UPDATE OR DELETE ON accrue_events RAISE EXCEPTION`. Document how to bypass for data migrations (role with BYPASSRLS-ish pattern). |
| EVT-003 | `Accrue.Events.record/4` | FOUND | S | Takes a changeset/multi and appends the event in the same transaction (transactional atomicity) |
| EVT-004 | Domain event emission | TS | S | Every state-changing context function emits one or more events |
| EVT-005 | Timeline query API | DIFF | S | `Accrue.Events.timeline(subject, opts)` — paginated, filterable by type, time window |
| EVT-006 | Replay / as-of state | DIFF | M | `Accrue.Events.state_as_of(subject, datetime)` — walks events up to a point. **Not full event sourcing** — state is still the source of truth; this is a read-side analytics tool. |
| EVT-007 | Upcaster pattern | DIFF | S | `Accrue.Events.Upcaster` behaviour; called on read to transform old `schema_version` into current shape; documented with example |
| EVT-008 | OpenTelemetry correlation | TS | T | `trace_id` column populated from current OTel context on every write |
| EVT-009 | Sigra.Audit bridge | DIFF | S | When sigra is present, every `Accrue.Events.record/4` also writes to `Sigra.Audit`; single-direction bridge (Sigra never writes back) |
| EVT-010 | Analytics bucketing helpers | DIFF | S | `count_by_day/2`, `revenue_by_month/1` — LiveView dashboard support |
| EVT-011 | Event type registry | FOUND | T | Enumerated list of Accrue's own event types (separate from Stripe webhook event types) |

**Gotchas flagged:** (a) `schema_version` inside the jsonb payload, not a column — column migrations are painful, jsonb lets you evolve per-event-type. (b) Upcaster chain must be pure — no DB lookups during upcast, or replay becomes unsound.

---

## 7. Email

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| MAIL-001 | `Accrue.Mailer` facade | FOUND | S | Behaviour-wrapped Swoosh; users configure their own adapter via `Accrue.Mailer` module they own; Accrue never leaks Swoosh types |
| MAIL-002 | Email: receipt | TS | S | Sent on successful charge |
| MAIL-003 | Email: payment_succeeded | TS | T | Sent on `invoice.payment_succeeded` |
| MAIL-004 | Email: payment_failed | TS | S | Sent on `invoice.payment_failed`; includes retry timeline |
| MAIL-005 | Email: trial_ending | TS | S | Sent N days before trial end (configurable); Oban-scheduled |
| MAIL-006 | Email: trial_ended | TS | T | Sent on trial → active (or → canceled if no PM) |
| MAIL-007 | Email: invoice_finalized | TS | T | Draft → open |
| MAIL-008 | Email: invoice_paid | TS | T | Duplicate of receipt? No — receipts are one-time charges, invoice_paid is recurring. Separate template. |
| MAIL-009 | Email: invoice_payment_failed | TS | S | Linked to dunning timeline |
| MAIL-010 | Email: subscription_canceled | TS | T | |
| MAIL-011 | Email: subscription_paused | TS | T | |
| MAIL-012 | Email: subscription_resumed | TS | T | |
| MAIL-013 | Email: refund_issued | TS | T | |
| MAIL-014 | Email: coupon_applied | TS | T | |
| MAIL-015 | Email: gift_sent | TS | T | (Depends on BILL-086 gift cards — defer with that feature) |
| MAIL-016 | Email: gift_redeemed | TS | T | (Ditto) |
| MAIL-017 | HEEx templates (HTML + text) | TS | M | Each template has a `.html.heex` and `.text.heex`; shared layout; rendered via Phoenix.Template |
| MAIL-018 | Branding config | TS / DIFF | S | Single `config :accrue, :branding, logo_url:, primary_color:, from_name:, from_address:, support_email:, company_name:` covers the 80% case |
| MAIL-019 | Per-template override | TS | S | Users can drop a file at `lib/my_app/accrue_templates/payment_failed.html.heex` and it's used instead of Accrue's default |
| MAIL-020 | MJML support | DIFF | S | Optional `swoosh_mjml` dep; when enabled, HEEx templates can render through MJML for better client coverage |
| MAIL-021 | Plain-text first rendering | TS | T | text template renders cleanly without HTML-fallback garbage |
| MAIL-022 | Email client test matrix docs | DIFF | S | Doc guide with actual screenshots from Gmail/Outlook/Apple Mail (differentiator, adds trust) |
| MAIL-023 | Async send via Oban | TS | S | Never block a request on SMTP; Oban worker wraps `Mailer.deliver` |
| MAIL-024 | `assert_email_sent` test helper | TS | S | Built on Swoosh.TestAssertions with Accrue-typed email accessors |

### Email Matrix Summary

15 email types from PROJECT.md (MAIL-002 through MAIL-016). If BILL-086 gift cards defer, MAIL-015/016 defer with it → 13 emails for v1.0-proper. Complexity clusters on layout + branding (M), individual emails are T each once the layout exists.

---

## 8. PDF

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| PDF-001 | `Accrue.PDF` behaviour | FOUND | S | `render(template, assigns) :: {:ok, binary}` |
| PDF-002 | `Accrue.PDF.ChromicPDF` adapter | TS | S | Default; wraps ChromicPDF |
| PDF-003 | Invoice PDF template | TS | M | HEEx template shared with MAIL-008 invoice_paid — single source of truth for visual branding |
| PDF-004 | `Accrue.PDF.Test` adapter | TS / DIFF | S | In-memory, never spawns Chrome; records calls; `assert_pdf_rendered(%{invoice_id: _})` |
| PDF-005 | `Accrue.PDF.Null` adapter | DIFF | T | For production deploys that can't run Chrome (Fly minimal images, Alpine containers) — returns placeholder |
| PDF-006 | Gotenberg adapter example | DIFF | S | Documented in guide only — not shipped as code — demonstrates behaviour seam |
| PDF-007 | PDF download route | TS | S | `/accrue/invoices/:id/pdf` LiveView-less Plug; auth via `Accrue.Auth` |
| PDF-008 | PDF attachment on email | TS | T | Wires PDF adapter into MAIL-008 |
| PDF-009 | Async render via Oban | TS | S | Large invoices shouldn't block the web request |

**Gotchas flagged:** (a) ChromicPDF on Alpine / minimal containers is painful — PDF-005 Null + PDF-006 Gotenberg docs exist specifically for this. (b) HEEx → PDF CSS has quirks (no flexbox gap support in Chrome headless < 112 — version-pin docs). (c) Single HEEx source for email HTML + PDF is the differentiator; make sure template works in both contexts without branching.

---

## 9. Admin UI (`accrue_admin`)

### 9.1 Navigation / Layout

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| ADMIN-001 | Root layout with nav + header | TS | S | Sidebar on desktop, bottom-bar on mobile |
| ADMIN-002 | Mobile-first responsive | TS | M | Every page renders usably at 375px; data tables collapse to card view |
| ADMIN-003 | Light / dark mode toggle | TS | S | System-pref detect + user override; persisted in localStorage |
| ADMIN-004 | Brand palette theme | TS / DIFF | S | Ink/Slate/Fog/Paper foundation + Moss/Cobalt/Amber accents wired to CSS vars |
| ADMIN-005 | Breadcrumbs | TS | T | Standard nav polish |
| ADMIN-006 | Flash / toast system | TS | T | |
| ADMIN-007 | Global search | DIFF | M | Search customers / invoices / subscriptions / events by ID, email, Stripe ID |

### 9.2 Pages

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| ADMIN-010 | Dashboard / overview | TS | M | KPI cards: MRR, active subs, new subs (7d), churned (7d), webhook health, DLQ count |
| ADMIN-011 | Customers index | TS | M | Paginated table, filter by status, search; mobile card view |
| ADMIN-012 | Customer detail | TS | M | Tabs: Overview, Subscriptions, Invoices, Payment Methods, Events, Webhook Events |
| ADMIN-013 | Customer actions | TS | S | Apply coupon, issue refund, comp subscription, update default PM |
| ADMIN-014 | Subscriptions index | TS | S | Filter by status (active, past_due, canceled, trialing); bulk actions |
| ADMIN-015 | Subscription detail | TS | M | Timeline view from events ledger; swap plan, cancel, pause UI |
| ADMIN-016 | Invoices index | TS | S | Filter by state; link to Stripe hosted URL |
| ADMIN-017 | Invoice detail | TS | S | Line items, payment history, PDF download, refund links |
| ADMIN-018 | Charges index | TS | S | |
| ADMIN-019 | Charge detail | TS | S | Refund UI, fee breakdown (exposes Stripe fees clearly), dispute status if present |
| ADMIN-020 | Coupons / promo codes index | TS | S | Create, list, archive |
| ADMIN-021 | Coupon detail | TS | S | Redemptions over time chart |
| ADMIN-022 | Webhook events index | TS / DIFF | M | Filter by type, status (processed/failed/DLQ), time window; live-updating via Phoenix.PubSub |
| ADMIN-023 | Webhook event detail | TS / DIFF | M | Raw payload (pretty-printed), attempt history with errors, one-click replay, jump to Stripe dashboard |
| ADMIN-024 | DLQ bulk requeue | DIFF | S | Filtered bulk action on dead-lettered events |
| ADMIN-025 | Activity feed | DIFF | M | Firehose of `accrue_events`, filterable by subject; infinite scroll |
| ADMIN-026 | Connect: connected accounts index | TS | S | Only shown if Connect is configured |
| ADMIN-027 | Connect account detail | TS | S | Capabilities, onboarding status, payout schedule, login-link button |
| ADMIN-028 | Settings: branding preview | DIFF | M | Live preview of email + PDF templates with current branding applied |
| ADMIN-029 | Settings: webhook endpoints | TS | S | View + rotate endpoint secrets |
| ADMIN-030 | Settings: test clock (dev only) | DIFF | S | Advance Stripe test clock from admin UI — dev/test env only |

### 9.3 Admin Infrastructure

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| ADMIN-040 | `Accrue.Admin.Router` helper | TS | S | `accrue_admin "/admin/billing"` router macro |
| ADMIN-041 | `on_mount` auth hook | TS | S | Uses `Accrue.Auth.require_admin_plug` semantics |
| ADMIN-042 | LiveView components library | TS / FOUND | M | `DataTable`, `KeyValueList`, `StatusBadge`, `Timeline`, `JsonViewer`, `MoneyDisplay` — shared across all pages |
| ADMIN-043 | `accrue_admin` published to Hex | TS | S | Same-day release as core |
| ADMIN-044 | Zero-core-dependency rule | FOUND | T | `accrue_admin` depends on `accrue`, never the other direction; core has no LiveView |

**Admin count: 44 IDs.** This is the largest single area. Recommend the roadmapper gives it its own phase.

**Gotchas flagged:** (a) Mobile-first data tables are non-trivial — budget for the DataTable component alone. (b) Live webhook updates via PubSub require broadcast from the Oban worker, not direct DB polling. (c) JsonViewer needs to redact sensitive fields (card numbers, client secrets) even though they should never be there.

---

## 10. Auth Integration

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| AUTH-001 | `Accrue.Auth` behaviour | FOUND | S | Callbacks: `current_user/1`, `require_admin_plug/2`, `user_schema/0`, `log_audit/3`, `actor_id/1` |
| AUTH-002 | `Accrue.Auth.Default` fallback | TS | S | Session-reads; no admin gate (fails closed in prod); documented as dev-only |
| AUTH-003 | `Accrue.Integrations.Sigra` adapter | TS / DIFF | S | Conditionally compiled; first-party Sigra wiring |
| AUTH-004 | Auto-detection of sigra | TS | T | Installer inspects `mix.exs`, auto-wires if present |
| AUTH-005 | Community adapter docs | TS | S | Written guide: implementing for phx.gen.auth, Pow, Assent |
| AUTH-006 | Actor tracking on events | TS | S | `AUTH-001` → `EVT-001.actor_id/type` — wires admin actions to the ledger |

---

## 11. Install Generator / DX

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| INST-001 | `mix accrue.install` task | TS | M | Generates: migrations (core + admin + webhook + events), `MyApp.Billing` context stub, config, router mounts |
| INST-002 | Billable schema detection | TS | S | Prompts for host schema (`User`, `Account`, `Team`); validates it exists |
| INST-003 | Sigra detection | TS | T | Auto-wires `Accrue.Integrations.Sigra` if sigra found |
| INST-004 | Admin UI route injection | TS | S | Adds admin LiveView routes to router with default path `/admin/billing` |
| INST-005 | Webhook endpoint scaffold | TS | S | Generates endpoint Plug + pipeline entry |
| INST-006 | Idempotent re-run | TS | S | Running twice doesn't duplicate; detects existing state, offers to patch missing pieces |
| INST-007 | `mix accrue.gen.handler` | DIFF | T | Generates a user webhook handler stub with common event patterns pre-written |
| INST-008 | NimbleOptions config validation | TS | S | All runtime options pass through NimbleOptions; invalid config fails loudly at boot |
| INST-009 | Config doc generation | DIFF | T | NimbleOptions auto-generates config docs into ExDoc |
| INST-010 | `Accrue.Billing` context facade | TS | S | Public API surface that hides lattice_stripe from users — they import `alias MyApp.Billing` |

---

## 12. Observability

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| OBS-001 | Telemetry event naming convention | FOUND | T | `[:accrue, domain, action, :start | :stop | :exception]` — enforced by convention + docs + example helpers |
| OBS-002 | Core domain telemetry events | TS | S | Every public context function emits start/stop/exception |
| OBS-003 | OpenTelemetry span helpers | TS | S | `Accrue.Telemetry.with_span/3` — auto-attaches customer_id, subscription_id, event_type, processor attributes |
| OBS-004 | High-signal ops events | DIFF | S | `[:accrue, :ops, :revenue_loss]`, `[:accrue, :ops, :webhook_dlq]`, `[:accrue, :ops, :dunning_exhaustion]` — documented for SRE/on-call, emit only on notable state |
| OBS-005 | Low-signal firehose documented separately | DIFF | T | Guide: "subscribe to these for Grafana; subscribe to ops for PagerDuty" |
| OBS-006 | `Accrue.Error` exception hierarchy | FOUND / TS | S | `Accrue.Error` → `CardError`, `RateLimitError`, `InvalidTransitionError`, `WebhookSignatureError`, `ConfigurationError`, `ProcessorError` — pattern-matchable |
| OBS-007 | Stripe error mapping | TS | S | lattice_stripe errors mapped to Accrue exceptions; preserve original |
| OBS-008 | Metrics recipe guide | DIFF | S | Walkthrough: wiring Accrue telemetry to Prometheus / OpenTelemetry Collector |

---

## 13. Testing Helpers

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| TEST-001 | Fake processor (primary surface) | TS / DIFF | L | See PROC-003 — listed here for cross-reference |
| TEST-002 | Test clock / time advancement | TS | M | `Accrue.Test.advance_time(sub, ~D[2026-05-01])` → triggers renewal event locally |
| TEST-003 | Event triggering API | TS | S | `Accrue.Test.trigger(:invoice_payment_failed, sub)` — enqueues the same Oban job as a real webhook would |
| TEST-004 | State inspection helpers | TS | S | `get_subscription_state/1`, `get_events_for/1` |
| TEST-005 | `assert_email_sent/1` | TS | S | See MAIL-024 |
| TEST-006 | `assert_pdf_rendered/1` | TS | S | See PDF-004 |
| TEST-007 | `Accrue.Mailer` mock adapter | TS | S | Users can test their wiring without real SMTP |
| TEST-008 | `Accrue.PDF.Test` adapter | TS | S | See PDF-004 |
| TEST-009 | `Accrue.Auth` mock | TS | S | `put_current_user(conn, user)` test helper |
| TEST-010 | Fixtures module | DIFF | S | `Accrue.Test.Fixtures.customer/1`, `subscription/1`, `invoice/1` — with ExMachina-style overrides |
| TEST-011 | Testing guide | TS | S | ExDoc guide: "How to test billing without touching Stripe" — **this is a marketing asset as much as a docs asset** |

---

## 14. OSS Hygiene & Release

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| OSS-001 | Monorepo structure | FOUND | S | `accrue/`, `accrue_admin/` as sibling mix projects; shared `.github/`, `guides/` |
| OSS-002 | `mix.exs` for both packages | FOUND | T | Hex metadata, descriptions, links, `package:` with files list |
| OSS-003 | GitHub Actions CI matrix | TS | S | Elixir 1.17+, OTP 27+ matrix |
| OSS-004 | `mix format --check-formatted` gate | TS | T | |
| OSS-005 | `mix compile --warnings-as-errors` gate | TS | T | |
| OSS-006 | `mix test --warnings-as-errors` gate | TS | T | |
| OSS-007 | `mix credo --strict` gate | TS | T | |
| OSS-008 | `mix dialyzer` gate | TS | S | PLT caching; may be non-blocking initially |
| OSS-009 | `mix docs --warnings-as-errors` gate | TS | T | |
| OSS-010 | `mix hex.audit` gate | TS | T | |
| OSS-011 | Release Please + conventional commits | TS | S | Separate release streams per package |
| OSS-012 | CHANGELOG.md per package | TS | T | Release Please maintains |
| OSS-013 | README with quickstart | TS | M | Polished landing README with animated GIF or screenshot |
| OSS-014 | ExDoc guide: quickstart | TS | M | |
| OSS-015 | ExDoc guide: configuration | TS | S | |
| OSS-016 | ExDoc guide: testing | TS | S | |
| OSS-017 | ExDoc guide: Sigra integration | TS | T | |
| OSS-018 | ExDoc guide: custom processors | TS | S | |
| OSS-019 | ExDoc guide: custom PDF adapter | TS | T | |
| OSS-020 | ExDoc guide: brand customization | TS | S | |
| OSS-021 | ExDoc guide: admin UI setup | TS | S | |
| OSS-022 | ExDoc guide: upgrade guide | TS | T | (initially "v1.0 released — no upgrades yet") |
| OSS-023 | ExDoc guide: webhook gotchas | DIFF | S | "The field guide in your docs" — lift from the Stripe gotchas catalogued in this research |
| OSS-024 | LICENSE (MIT, single root) | TS | T | |
| OSS-025 | CONTRIBUTING.md | TS | T | |
| OSS-026 | CODE_OF_CONDUCT.md (CC 2.1) | TS | T | |
| OSS-027 | SECURITY.md | TS | T | Vuln disclosure email, scope, SLA |
| OSS-028 | Stable public API facade docs | TS | S | Explicit list of modules with semver guarantee |
| OSS-029 | Deprecation policy doc | TS | T | |

---

## 15. Brand / Theming

| ID | Feature | Cat | Cx | Description |
|---|---|---|---|---|
| BRND-001 | Brand palette CSS variables | TS | T | Ink #111418, Slate #24303B, Fog #E9EEF2, Paper #FAFBFC, Moss #5E9E84, Cobalt #5D79F6, Amber #C8923B |
| BRND-002 | Admin UI theme implementation | TS | S | See ADMIN-004 |
| BRND-003 | Email default theme | TS | S | Neutral palette, Moss accent |
| BRND-004 | PDF default theme | TS | S | Print-safe, Slate primary text |
| BRND-005 | Typography config | TS | T | Inter default with documented swap points |
| BRND-006 | Branding override config | TS | S | See MAIL-018 |
| BRND-007 | Amber "warning / grace period" convention | DIFF | T | Used consistently: dunning, expired cards, trial ending, webhook DLQ — semantic color coding |
| BRND-008 | Visual vocabulary docs | DIFF | T | Guide: timelines, state diagrams, offset blocks — no coin/card clichés (lifted from brand book) |

---

## 16. Anti-Features (Explicit v1.0 Non-Goals)

Each entry below is locked with reasoning from PROJECT.md + this research.

| ID | Anti-Feature | Why Tempting | Why NOT v1.0 | Alternative |
|---|---|---|---|---|
| NO-001 | Full CQRS/ES via Commanded | Billing feels event-shaped; Commanded is mature Elixir lib | Stripe models state as mutable + event notifications; CQRS is the wrong abstraction (600+ LOC vs ~150 for append-only log); billing needs transactional atomicity, not eventual projection | Append-only `accrue_events` table + Sigra.Audit bridge (EVT-001 through EVT-011) |
| NO-002 | Multi-database support (MySQL, SQLite) | Broader reach, more users | 7 load-bearing PG features with no clean fallback: jsonb/GIN, partial indexes, unique-where, advisory locks, exclusion constraints, transactional DDL, `SELECT ... FOR UPDATE SKIP LOCKED`. ~0% of serious Phoenix apps use non-PG in prod. | PostgreSQL 14+ only; revisit post-1.0 if real demand, following Oban's multi-engine playbook |
| NO-003 | First-party Paddle / Lemon Squeezy / Braintree adapters | "Multi-processor billing library" sounds impressive | Cashier's most-cited regret; false parity fails — every processor's subscription semantics differ. Building adapters without a second real user of them is guessing. | Stripe-only v1.0; `Accrue.Processor` behaviour exists for future adapters but is documented as "experimental, may break in 1.x"; future adapters ship as separate packages |
| NO-004 | Accrue owning the `users` / auth schema | "Batteries-included" could include auth | 15+ integration points with host auth; stepping on host user table breaks sigra, phx.gen.auth, Pow, Assent; migration nightmares | Polymorphic `owner_type`/`owner_id`; `use Accrue.Billable` macro; `Accrue.Auth` behaviour (AUTH-001) |
| NO-005 | Revenue recognition / GAAP accounting | Users will ask | Separate problem domain (ASC 606, deferred revenue schedules, RevRec engines); billing ≠ accounting; would double the scope and never satisfy real accounting teams | Expose events ledger + Stripe data for downstream accounting tools (ProfitWell, Maxio, SaaSOptics integrations are user-implemented) |
| NO-006 | Tax calculation / compliance | SaaS tax is a real pain | Stripe Tax exists and is correct; re-implementing it badly is worse than linking it; first-party tax obligates us to keep up with EU VAT / US state nexus changes forever | Document "use Stripe Tax via lattice_stripe; Accrue exposes tax lines through existing invoice API" |
| NO-007 | Dual-license / commercial tier | Sustainability | Splits community; complicates contribution model; MIT is ecosystem norm | Future commercial path via vertical integration (hosted service, compliance bundling, professional support), never paid features in core |
| NO-008 | MVP / iterate-in-public release strategy | Ship early, learn | User explicit: zero real users until fully usable; avoids Pay-style v2→v3 migration pain on early adopters; phases are internal build milestones, not public releases | Internal phases; v1.0 is first public release; strict semver from there |
| NO-009 | Admin UI in core package | One install, less friction | Keeps core headless-friendly (`phoenix_live_dashboard` / `oban_web` idiom); some Accrue users will have no LiveView at all; circular dep hell | Companion `accrue_admin` package, same-day release, same monorepo |
| NO-010 | First-party "Everything UI" (customer-facing pricing page, checkout embeds) | Completeness | Users' designs are too heterogeneous; becomes a design-system project; maintenance drag | Ship Checkout Session + Portal helpers (CHKT-001 to CHKT-007); LiveView components for common patterns can come post-1.0 |
| NO-011 | Custom PDF layout engine | Control | Every CSS-to-PDF engine has limits; writing our own is insane | ChromicPDF default; `Accrue.PDF` behaviour for escape hatches |
| NO-012 | ORM-style schema mirroring Stripe column-for-column | "Idiomatic Ecto" | dj-stripe's decade of pain: API drifts, migrations every Stripe release, schema tax | Store full API response in `data` jsonb; project named columns only for queries/indexes (dj-stripe's converged strategy) |
| NO-013 | Background recurring job scheduler built from scratch | Less deps | Oban is THE Elixir standard; rebuilding is antipattern | Oban as required dep |
| NO-014 | Supporting Phoenix <1.8 / LiveView <1.0 | Broader compat | Forces workarounds across 15+ features; 1.8 has been out long enough | Phoenix 1.8+, LiveView 1.0+ hard requirement |
| NO-015 | Wrapping every Stripe object | Completeness | Some objects (Reporting, Sigma, Radar rules, Issuing) are tangential to subscription/one-time billing | Scope to: Customer, PaymentMethod, Subscription, SubscriptionSchedule, Invoice, InvoiceItem, Charge, PaymentIntent, SetupIntent, Refund, Coupon, PromotionCode, Checkout Session, Portal Session, Connect Account, Transfer, Application Fee. Everything else: "use lattice_stripe directly." |

---

## 17. Feature Dependency Graph

Topological layers (lower layers must ship before higher layers depend on them). Within a layer, features are parallelizable.

```
LAYER 0 — Foundations (must exist before anything else)
├─ PROC-001 Processor behaviour
├─ PROC-002 Stripe adapter
├─ PROC-003 Fake processor
├─ EVT-001/002/003 Event ledger schema + append-only + record/4
├─ OBS-001/006 Telemetry convention + error hierarchy
├─ AUTH-001/002 Auth behaviour + default fallback
├─ MAIL-001 Mailer facade
├─ PDF-001 PDF behaviour
├─ OSS-001/002 Monorepo structure + mix.exs
└─ BRND-001 Brand palette CSS vars

LAYER 1 — Core schemas + webhook pipeline (everything below needs these)
├─ BILL-001 Customer schema
├─ BILL-002 Billable macro
├─ BILL-010 Subscription schema
├─ BILL-030 Invoice schema
├─ BILL-050/051/052 Charge/PaymentIntent/SetupIntent schemas
├─ BILL-060 PaymentMethod schema
├─ BILL-070 Refund schema
├─ BILL-080/082 Coupon + PromotionCode schemas
├─ BILL-090 Currency-aware storage
├─ WH-001 Raw-body plug
├─ WH-002 Signature verification
├─ WH-003/004 accrue_webhook_events + DB idempotency
├─ WH-005 Oban dispatch
├─ OBS-002 Core domain telemetry
└─ PDF-004 / TEST-001 Test adapters (so tests can run)

LAYER 2 — Business logic built on schemas
├─ BILL-003..006 Customer operations
├─ BILL-011..018 Subscription operations (create/swap/cancel/trial/pause)
├─ BILL-020 Dunning / grace period (depends on WH-009)
├─ BILL-021 Predicate helpers
├─ BILL-022/023 Multi-item + metered (depends on BILL-011)
├─ BILL-031..040 Invoice state machine + operations
├─ BILL-053..056 Charge operations (depends on BILL-050, handles requires_action)
├─ BILL-061..065 PaymentMethod operations
├─ BILL-071..074 Refund operations
├─ BILL-081, 083..085 Coupon/promo operations
├─ BILL-091..094 Money value type + currency guards
├─ WH-008/009/010 User handler + core handlers + event constants
├─ EVT-004 Domain event emission wired to context functions
└─ OBS-003 OTel span helpers

LAYER 3 — Advanced billing + Checkout/Portal
├─ BILL-100..103 Subscription Schedules (depends on BILL-011)
├─ BILL-019 Comped/free-tier (depends on BILL-011)
├─ BILL-086 Gift cards (depends on BILL-080 — MAY DEFER)
├─ CHKT-001..007 Checkout + Portal sessions
├─ WH-006/007/011/012/015/016 Webhook advanced (retry, DLQ, replay, ordering)
├─ EVT-005/006/007/008/010/011 Ledger query + replay + upcaster + analytics
├─ OBS-004/005/007 Ops events + Stripe error mapping
└─ AUTH-006 Actor tracking on events

LAYER 4 — Connect
├─ CONN-001..011 All Connect features (depend on BILL-053, WH-014)

LAYER 5 — Email + PDF rendering
├─ MAIL-002..016 All email types (depend on MAIL-017 templates + BILL domain events)
├─ MAIL-017 HEEx templates
├─ MAIL-018/019 Branding config + per-template override
├─ MAIL-020 MJML (optional)
├─ MAIL-021/023/024 Plain-text + async + test helper
├─ PDF-002 ChromicPDF adapter (depends on PDF-001)
├─ PDF-003 Invoice PDF template (shares with MAIL-008)
├─ PDF-005/006 Null adapter + Gotenberg docs
├─ PDF-007/008/009 Download route + attachment + async
└─ BRND-003/004/005/006/007 Themes for email, PDF, typography, Amber convention

LAYER 6 — Admin UI
├─ AUTH-003/004 Sigra adapter + auto-detection (admin UI is first consumer)
├─ EVT-009 Sigra.Audit bridge
├─ ADMIN-001..007 Layout + nav + theme + global search
├─ ADMIN-040..044 Router helper + on_mount + components library + package publishing
├─ ADMIN-010..030 All pages (dashboard, customers, subs, invoices, charges, coupons, webhook inspector, activity feed, Connect, settings)
└─ BRND-002 Admin UI theme implementation

LAYER 7 — Install + Observability Polish + Testing
├─ INST-001..010 Install generator + config validation + context facade
├─ OBS-008 Metrics recipe guide
├─ TEST-002..011 All test helpers (depend on PROC-003 Fake being mature)
└─ BRND-008 Visual vocabulary docs

LAYER 8 — Release
├─ OSS-003..010 CI matrix + quality gates
├─ OSS-011/012 Release Please + CHANGELOG
├─ OSS-013..023 README + all ExDoc guides
├─ OSS-024..029 LICENSE + CONTRIBUTING + COC + SECURITY + API facade + deprecation
└─ ADMIN-043 accrue_admin Hex publishing
```

### Topological Ordering Hint For Roadmapper

Phases suggested by this structure:

1. **Foundation** — Layer 0 (behaviours, fake processor, event ledger plumbing, error hierarchy, monorepo)
2. **Schemas + Webhook Plumbing** — Layer 1 (all schemas, raw body → signature → idempotency → Oban → handler contract stubbed)
3. **Core Subscription Lifecycle** — Critical slice of Layer 2: BILL-001..018, 031..040, 053..055, 061..063, 071..074, WH-008..010, EVT-004 — enough to run a real subscription charge end-to-end with test clock
4. **Advanced Billing + Webhook Hardening** — Rest of Layer 2 + Layer 3 minus Connect + minus gift cards
5. **Connect** — Layer 4 (clean phase boundary because it touches every prior layer exactly once)
6. **Email + PDF** — Layer 5 (parallelizable within; ~20 items but mostly Trivial/Small)
7. **Admin UI** — Layer 6 (single largest user-facing surface — needs its own phase)
8. **Install + Polish + Testing** — Layer 7
9. **Release** — Layer 8 (docs, CI, CHANGELOG, publishing)

Gift cards (BILL-086) and MAIL-015/016 sit as a sidebar that can defer to v1.1 if phase 4 runs long.

---

## 18. Stripe Field-Guide Gotchas — Cross-Reference

Non-obvious traps, mapped to the features that must defuse them.

| Gotcha | Features Affected | How Accrue Addresses It |
|---|---|---|
| `cancel_at_period_end` keeps `status = active` | BILL-014, BILL-021, ADMIN-015 | `canceling?/1` predicate; admin badge; docs lead with this |
| `incomplete` PI/subscription 23-hour expiry | BILL-054, BILL-010, ADMIN-015 | Surface countdown in admin; webhook handler for `subscription.deleted` with reason=`incomplete_expired` |
| Proration behavior unspecified → defaults change | BILL-012 | Force explicit `proration_behavior` at context API boundary |
| `requires_action` / 3DS SCA | BILL-054 | Tagged `{:ok, :requires_action, intent}` return type |
| Off-session authentication_required | BILL-055 | Typed error; dunning pipeline handles |
| Zero-decimal currency amount misscaling | BILL-090..093 | `Accrue.Money` value type with currency-aware math; fixture tests for JPY/KRW/BHD |
| Three-decimal currency forgotten | BILL-093 | Separate helper, explicit tests |
| Raw body consumed by Plug.Parsers | WH-001 | Scoped pipeline plug; install generator wires correctly |
| Webhook signature timing attack | WH-002 | Timing-safe compare via lattice_stripe |
| Duplicate webhook delivery | WH-003/004 | `UNIQUE(processor_event_id)`; dupe → 200 OK immediately |
| Webhook out-of-order delivery | WH-016, EVT-006 | `created` timestamp compare; event ledger gives audit trail |
| Webhook retry window (3 days) | WH-006/007 | Oban backoff schedule tuned for 72h |
| Connect webhooks come from different endpoint | WH-014 | Multi-endpoint pipeline |
| Onboarding link single-use | CONN-003 | Generate on demand; never cache |
| `charges_enabled: false` + `details_submitted: true` (pending review) | CONN-004, ADMIN-027 | Explicit status display in admin |
| Fee NOT refunded by default on refund | BILL-073 | `refund_application_fee: true` option with explicit docs |
| Stripe customer metadata replace-not-merge | BILL-005 | Deep-merge helper |
| Checkout success URL ≠ source of truth (webhook is) | CHKT-005 | Docs lead with this; post-checkout sync explicitly retrieves |
| Customer Portal defaults allow cancel with no dunning | CHKT-007 | `configure_portal/1` with sane defaults |
| Test clock is per-sub on Stripe side | TEST-002 | Expose `advance_time/2` tied to sub; document |
| Stripe deletion is soft (ID still resolves) | BILL-001, BILL-004 | Handle `deleted: true` explicitly, don't 404 |
| ChromicPDF on Alpine/minimal containers | PDF-005/006 | Null adapter + Gotenberg example |
| Idempotency key replay window (24h) | PROC-002 | Document; expose per-call override |
| Subscription update API race (read-modify-write) | BILL-012, BILL-022 | Always use Stripe-returned state, never optimistic merge |
| Invoice finalization auto-sends email by default | BILL-032, MAIL-007 | Configure Stripe `auto_advance=false` by default; Accrue owns the email |

---

## 19. Confidence Notes + Open Questions

**HIGH confidence:**
- Feature catalog completeness (every group in PROJECT.md is expanded with IDs)
- Anti-feature list (explicit in PROJECT.md Out of Scope section)
- Dependency ordering for Layers 0–3 (follows from standard Phoenix/Ecto/Oban patterns)
- Stripe gotchas (drawn from documented field-guide behavior + Pay/Cashier/dj-stripe lessons)

**MEDIUM confidence:**
- Complexity estimates — calibration is based on "standard Elixir pace" but some features (ADMIN-002 mobile-first tables, PROC-003 Fake processor, BILL-020 dunning) could slip a bucket
- BILL-086 gift cards as L-complexity — could be XL; depends on how deep into Stripe customer balance we go
- Admin UI feature count (44) — some features will collapse during implementation, some will split

**LOW confidence / flagged for downstream:**
- Whether lattice_stripe will have Billing (Subscription/Invoice/Price) coverage by the time Accrue needs it. PROJECT.md notes this gap. **Roadmapper must treat "lattice_stripe Billing contributions" as possible phase work that inflates PROC-002 from S to L or M.**
- Exact NimbleOptions schema for config (INST-008) — requires touching every feature, hard to estimate without prototype
- Whether `Accrue.Events.state_as_of/2` (EVT-006) can be implemented simply for the subjects we care about, or whether it gets pulled into "too close to event sourcing" territory

**Open questions for REQUIREMENTS.md elaboration:**
1. Does the install generator support idempotent re-run from day one (INST-006) or is that v1.1?
2. Is global search (ADMIN-007) MVP or differentiator? It's listed DIFF above but high user demand.
3. Does Connect support ship with full platform fee computation (CONN-007) or is that a guide-only pattern initially?
4. How does the admin UI handle orgs/multi-tenancy once sigra ships that milestone? Stub the extension point now or wait?
5. What's the DLQ retention policy (WH-007)? 30 days? Forever? Configurable?
6. Gift cards (BILL-086, MAIL-015/016) — in or out for v1.0? Listed in PROJECT.md but materially heavier than peers.

---

## 20. Summary For The Roadmapper

- **~180 feature IDs total** across 15 prefixes. ~130 are Trivial or Small, ~40 Medium, ~10 Large, ~1 XL candidate (BILL-086 gift cards).
- **Largest single area:** Admin UI (44 IDs). Needs its own phase.
- **Second largest:** Core billing domain (90+ IDs across BILL-001..103, but many are Trivial helpers).
- **Critical path:** Foundations → Schemas+Webhooks → Core Subscription Lifecycle. Until a subscription can be created and charged end-to-end via the Fake processor with a recorded event in the ledger, nothing downstream can be meaningfully tested.
- **Descope candidates if budget tight:** BILL-086 gift cards (+ MAIL-015/016), MAIL-020 MJML, ADMIN-007 global search, ADMIN-028 branding preview, EVT-006 state_as_of, INST-007 handler generator, OSS-023 webhook gotchas guide. Everything else is locked.
- **Test surface must come early.** PROC-003 Fake processor is FOUND-layer, not test-layer. Treat it as gating infrastructure.
- **Gotcha defusing is a differentiator.** The cross-reference in section 18 is effectively Accrue's moat vs Bling — we know the traps and the API is designed to make them unrepresentable or impossible to ignore.

---

*Feature research for: Accrue v1.0 — open-source Elixir/Phoenix payments library*
*Researched: 2026-04-11*
