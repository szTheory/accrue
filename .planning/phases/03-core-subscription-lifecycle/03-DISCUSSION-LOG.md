# Phase 3: Core Subscription Lifecycle - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 03-core-subscription-lifecycle
**Mode:** Interactive discuss with user-driven parallel advisor research (3 rounds)
**Areas discussed:** 12 gray areas across 3 rounds

---

## Round 1 — Area selection

### Gray area selection question

| Option | Description | Selected |
|--------|-------------|----------|
| State machine & predicates | active?/canceling?/canceled?/paused? computation, Ecto.Enum values, grace-period semantics (BILL-04/05/07) | ✓ |
| 3DS/SCA tagged returns | Which ops return `{:ok, :requires_action, intent}`, tag shape, SetupIntent parity (BILL-21/22) | ✓ |
| Invoice projection depth | Lines/discounts/tax storage strategy, workflow action ownership (BILL-17/18/19) | ✓ |
| Proration preview & plan swap | preview_upcoming_invoice shape, swap_plan proration opts, required-vs-optional (BILL-09/10) | ✓ |

**User directive:** research all 4 in parallel subagents, return pros/cons + coherent one-shot recommendations.

---

## Round 1 — Decisions

### State machine & predicates

| Option | Approach | Selected |
|--------|----------|----------|
| A: Stripe-faithful Ecto.Enum + pure predicates over columns | 8 Stripe values, real `cancel_at_period_end`/`pause_collection` columns, pure pattern-match predicates | ✓ |
| B: Accrue-owned collapsed enum | Narrow Accrue enum collapsing `unpaid→past_due`, `incomplete_expired→canceled` | |
| C: Stripe-faithful enum + private status + derived virtual state field | Virtual `:state` field, private status accessor | |

**Selected:** Option A + three-layer BILL-05 enforcement (moduledoc + custom Credo check `Accrue.Credo.NoRawStatusAccess` + `Accrue.Billing.Query` composable fragments).

**Rationale:** Zero translation loss. Stripe dev reads `status in [:active, :trialing]` and knows what it means. Predicates compose into Ecto `where` via Query module. No virtual field staleness. Trust Stripe's webhook-driven `incomplete_expired` transition (no `incomplete_expires_at` column).

### 3DS/SCA tagged returns

| Option | Approach | Selected |
|--------|----------|----------|
| A: Single `:requires_action` tag, uniform across PI/SI ops | One tag, 3-tuple, struct type disambiguates PI vs SI | ✓ |
| B: Enumerated status tags (`:requires_action`, `:processing`, `:requires_capture`) | Full Stripe status fidelity | |
| C: Raise `Accrue.ActionRequiredError` (Pay/Cashier parity) | Exception-based, reuses D-05 dichotomy | |

**Selected:** Option A, with `!` variants raising `Accrue.ActionRequiredError` on the action-required branch.

**Rationale:** ROADMAP success criterion locked `{:ok, :requires_action, %PaymentIntent{}}`. One tag to learn. `processing`/`requires_capture` ride on the struct; `requires_confirmation`/`requires_payment_method` normalize to `{:error, %CardError{}}`. Embedded `latest_invoice.payment_intent` on Subscription avoids 4-tuples.

### Invoice projection depth

| Option | Approach | Selected |
|--------|----------|----------|
| A: Full relational projection ("Stripe mirror") | Every Stripe field as typed column + child tables for items/tax/discounts | |
| B: Blob-only (Pay/Cashier parity) | Everything in `data` jsonb | |
| C: Hybrid (typed rollups + real items schema + jsonb detail) | Typed columns for admin filter/sort/sum; real `accrue_invoice_items`; tax/discounts nested in item `data` | ✓ |

**Selected:** Option C.

**Rationale:** Fast admin queries via indexed typed columns, idiomatic Ecto preloads for Phase 6 PDF rendering, bounded mapping surface (~2 schemas not 4), tax/discount drift doesn't matter because they're never in WHERE clauses. `changeset/2` + `force_status_changeset/2` split handles user-path vs webhook-path state machine enforcement.

### Proration preview & plan swap

| Option | Approach | Selected |
|--------|----------|----------|
| A: Dedicated `%UpcomingInvoice{}` struct, Stripe-faithful atoms, optional preview | New non-persistent struct; 1:1 Stripe atoms; no caching | ✓ |
| B: Reuse Invoice schema with `:preview` virtual state + semantic atoms | One schema, rename atoms to `:next_invoice`/`:immediate` | |
| C: Untyped map + boolean proration | Minimal surface | |

**Selected:** Option A.

**Rationale:** Dedicated struct pattern-matches cleanly and Phase 6 email templates render it directly. `:proration` required with no default, NimbleOptions-raised ArgumentError with BILL-09 pointer. Preview optional (stands alone for server-to-server). No caching in v1.0 — correctness hazard, host concern. `swap_plan/3` returns `intent_result(Subscription.t())` matching charge/subscribe.

---

## Round 2 — Area selection

### Gray area selection question

| Option | Description | Selected |
|--------|-------------|----------|
| Refund fees + OOO resolution | BILL-26 + WH-09 (coupled via webhook timing) | ✓ |
| PaymentMethod dedup + default PM | BILL-23 + BILL-25 | ✓ |
| Trial handling + trial_will_end | BILL-06, webhook surface, test-clock integration | ✓ |
| Test fixtures + factories | TEST-08, factory style, Fake vs Repo policy | ✓ |

**User directive:** same parallel-research approach as round 1.

---

## Round 2 — Decisions

### Refund fees (BILL-26) + OOO webhooks (WH-09)

| BILL-26 Option | Approach | Selected |
|--------|----------|----------|
| A: Sync-only (expand balance_transaction at create) | Single code path, writes fees inline | |
| B: Async-only (webhook reconciles) | Write row with nil fees, wait for charge.refund.updated | |
| C: Both (sync best-effort + webhook backstop + daily reconciler) | Expand at create, backstop webhook, cron sweep | ✓ |

| WH-09 Option | Approach | Selected |
|--------|----------|----------|
| A: Per-entity `last_stripe_event_ts` + skip-stale, no refetch | Fastest, violates D2-29 | |
| B: Always-refetch, no column | Pure D2-29, burns Stripe quota | |
| C: Column + skip-stale-for-efficiency + always-refetch-on-fast-path | Column, skip when stale, refetch otherwise | ✓ |

**Selected:** Option C for both.

**Rationale:** Same pattern — trust Stripe canonical, cache last-event-ts to avoid redundant work, scheduled reconciler as backstop. Uniform `{:ok, %Refund{}}` return (no pending_fees tag). Predicates + list helpers for ops dashboards. Skip-stale is orthogonal to D2-29 (stored state is newer than payload → safer to skip than refetch).

### PaymentMethod dedup + default PM

| BILL-23 Option | Approach | Selected |
|--------|----------|----------|
| A: Attach-time dedup in application layer | Query fingerprint, detach duplicate | ✓ (primary) |
| B: DB unique partial index, catch constraint | Partial unique index | ✓ (backstop) |
| C: Soft dedup in list queries | DISTINCT ON (fingerprint) | |

| BILL-25 Option | Approach | Selected |
|--------|----------|----------|
| A: `default_payment_method_id` FK on accrue_customers | Matches Stripe's data model | ✓ |
| B: `default?` boolean on PM with partial unique index | 2-row update tx | |
| C: Defer to Stripe, read from customer data jsonb | No local column | |

**Selected:** BILL-23 option A layered over option B (partial unique index backstop). BILL-25 option A.

**Rationale:** Return shape stays uniform via virtual `existing?: boolean` on the PM struct, not a 3-tuple tag — preserves `intent_result` consistency. `charge/3` without PM → loud `NoDefaultPaymentMethod` error, no silent fallback. Subscription-level override deferred to Phase 4.

### Trial handling

| Option | Approach | Selected |
|--------|----------|----------|
| A: Thin passthrough (Pay-Ruby parity) | Minimal, DateTime + `:now` only, no sugar | |
| B: Full sugar + synthesis + forced local scheduling | All 5 param forms, local Oban scheduling, unconditional email | |
| C: Idiomatic middle (DateTime + Duration sugar, synthesis with opt-out, no local scheduling) | 3 forms, auto-synthesize on Fake.advance, default email on | ✓ |

**Selected:** Option C.

**Rationale:** Reject unix ints (Stripe wire format) and `:trial_period_days` (redundant). No local Oban scheduling — Stripe owns trial state, duplicating creates drift. Keep `trial_will_end` as Stripe's event name (least surprise). Fake auto-synthesizes webhooks on clock advance — differentiator Pay/Cashier can't match. Default trial_ending email on by default via D-23 ladder ("real SaaS on day one" vision).

### Test fixtures + factories

| Option | Approach | Selected |
|--------|----------|----------|
| A: ExMachina-integrated factory | `use Accrue.Test.Factory` with traits, requires ExMachina dep | |
| B: Plain function module (primary) + Option C sibling | No macros, no deps, plain functions | ✓ |
| C: StreamData generators only | Property-test shape only | (sibling) |

**Selected:** Option B primary + Option C sibling (`Accrue.Test.Generators` gated by `Code.ensure_loaded?(StreamData)`).

**Rationale:** Ships in `lib/accrue/test/` (Phase 1 pattern). Routes through Fake processor not Repo.insert! (coheres with D-19/D-20, inherits deterministic IDs). 9 first-class factories; rare states defer to `subscription(status: ...)` primitive. Test clock threading as hard rule. Side-effect-pure contract enables Phase 8 `mix accrue.seed` reuse.

---

## Round 3 — Area selection

**User directive:** "keep digging until diminishing returns" with same parallel-research approach.

### Gray area selection (Claude-identified, not user-selected)

| Option | Description | Researched |
|--------|-------------|------------|
| Cancel / resume / pause / unpause (BILL-07/08) | API shape for cancel variants, final-invoice default, pause behavior, resume scope | ✓ |
| SubscriptionItem scope (Phase 3 ↔ Phase 4 boundary) | Schema depth, quantity opt, multi-item read/write split | ✓ |
| Idempotency seeds + canonical event taxonomy | subject_id strategy, operation_id propagation, 24 Phase 3 events | ✓ |
| Expiring-card warnings (BILL-24) | Detection strategy, thresholds, auto-update policy, dedup state | ✓ |

---

## Round 3 — Decisions

### Cancel / resume / pause / unpause

| Option | Approach | Selected |
|--------|----------|----------|
| A: Four separate functions (no overloading) | `cancel`, `cancel_at_period_end`, `cancel_at`, `resume` | |
| B: One `cancel(at:)` with opts | Single name, keyword-arg driven | |
| C: Two cancel verbs + strict resume/unpause split | `cancel`, `cancel_at_period_end`, `resume`, `pause`, `unpause` | ✓ |

**Selected:** Option C.

**Rationale:** No `cancel(at:)` overload avoids default-ambiguity footgun. `cancel/2` always immediate, `cancel_at_period_end/2` always soft (with `:at` opt for scheduled future DateTime). `resume` strictly unsets cancel; `unpause` strictly clears pause_collection. No auto-sequencing. Final-invoice default = no proration (opinionated, no-surprise-charge). `intent_result` only on `cancel/2` + `invoice_now: true`. Swap-on-canceling preserves Stripe behavior (implicit uncancel).

### SubscriptionItem scope

| Option | Approach | Selected |
|--------|----------|----------|
| A: Minimal — single-item only, defer everything | No read multi-item, no quantity opt | |
| B: Read-everything, write-single-item-only | Full read projection, narrow writes, quantity opt on swap | ✓ |
| C: Full item CRUD now | Ship add_item/remove_item/update_items immediately | |

**Selected:** Option B.

**Rationale:** "Single-item write, any-item read." `subscribe/2` accepts single price_id or `{price_id, quantity}` tuple (not list). `swap_plan/3` gains `:quantity` opt. Ship `update_quantity/2` as first-class (per-seat SaaS). Webhook reconciler handles N items (read projection). `get_subscription/1,2` auto-preloads items. Phase 4 migration zero-breaks — `MultiItemSubscription` guard just disappears.

### Idempotency seeds + event taxonomy

| Gray area A (subject_id) | Approach | Selected |
|--------|----------|----------|
| A: Pre-generate resource UUID (derived from operation_id) | UUID plays three roles: PK + subject_id + event FK | ✓ |
| B: Natural Stripe-ID subject with caller-supplied operation_id | Brittle for create-ops | |
| C: Composite tuple-hash subject, auto operation scope | Caller owns cycle math | |

| Gray area B (event format) | Approach | Selected |
|--------|----------|----------|
| A: Dotted-atom, domain-prefixed, medium granularity | `:"subscription.created"`, modality in payload | ✓ |
| B: Tuple events, fine-grained | `{:subscription, :canceled_at_period_end}` | |
| C: Mirror Stripe webhook names verbatim | `:"customer.subscription.created"` | |

**Selected:** A + A.

**Rationale:** Deterministic UUID derivation (`sha256("#{op}|#{operation_id}")` truncated to 16 bytes, cast to Ecto.UUID) means retries converge on the same pending row. Operation_id propagates via `Accrue.Plug.PutOperationId` (HTTP), `Accrue.LiveView.on_mount :accrue_operation` (LV), `Accrue.Oban.Middleware` (including attempt). Strict mode refuses random fallback. 24 Phase 3 events — drop `subscription.canceling` (payload mode) and `payment_method.deduped` (mechanism not event). Per-event Schema modules, NimbleOptions dev/test validation, all events at schema_version 1, upcasters only for breaking changes.

### Expiring-card warnings

| Option | Approach | Selected |
|--------|----------|----------|
| A: Webhook-only | React to Stripe's expiry events | |
| B: Scheduled scan only | `DetectExpiringCards` Oban cron with thresholds | |
| C: Both (webhook + scheduled scan, events-unified) | Scan drives thresholds, webhooks do data sync + aux signal | ✓ |

**Selected:** Option C.

**Rationale:** Webhook-only fails BILL-24 because modern PaymentMethods don't get `customer.source.expiring`. Ship `Accrue.Jobs.DetectExpiringCards` with `@default_cron "0 8 * * *"`, host wires to their Oban cron plugin. Default thresholds `[30, 7, 1]` days, configurable. Auto-updates are silent successes (event + telemetry, no default email). One semantic email `:card_expiring` with threshold assign (not separate types). Dedup state lives in `accrue_events` (reuses append-only ledger, no new column). Zero Phase 4 dunning coupling.

---

## Claude's Discretion

Claude has flexibility on:
- Exact module layout under `lib/accrue/billing/` (file-per-schema vs grouped)
- Migration filenames and ordering
- Internal function decomposition of `DefaultHandler`
- `Accrue.Events.Schemas.*` exact field lists beyond the subject-vs-linked rule
- `Accrue.Billing.Query` fragment module macro/function boundary
- Test file organization within `test/accrue/billing/`
- `Fake.transition/3` internal helper shape
- Whether NimbleOptions schemas live inline or in `Accrue.Billing.Schemas` module
- Worker module naming (`Accrue.Jobs.*` vs `Accrue.Workers.*`)

## Deferred Ideas

See `03-CONTEXT.md` `<deferred>` section. Highlights:
- Metered usage, multi-item write, dunning orchestration, subscription schedules, coupon CRUD, Checkout/Portal → Phase 4
- Connect → Phase 5
- Email templates, PDF rendering → Phase 6
- Admin UI → Phase 7
- `mix accrue.install`, test helpers, `mix accrue.seed` → Phase 8
- ExMachina integration — explicitly rejected as non-goal
