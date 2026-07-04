# Accrue — Library Summary for Admin/Operator UI Deep Research

## 0. What this document is

This is a factual summary of the **Accrue** library, written to hand to a designer (or an LLM acting as one) so they can design, **from first principles**, the ideal *admin/operator UI/UX* for it — information architecture, navigation, content hierarchy, per-screen controls, and a storyboarded end-to-end operator journey.

It is context, not a spec. It describes **the domain the UI operates on, who operates it, how it must feel, and the hard constraints** — and deliberately does *not* prescribe the screens. If you are pairing this with a separate "billing-admin best-practices / operator jobs-to-be-done" prompt, treat that prompt as the *doctrine* and this document as the *ingredients*.

One caveat up front: Accrue already has a working admin UI. It is summarized in **Appendix A** only as anti-anchoring reference — so the design can build on real domain knowledge and *deliberately diverge or improve*, rather than either replicating the current UI or designing blind. The goal is to **re-derive the ideal**, not to reproduce what exists.

---

## 1. Accrue in one paragraph

**Accrue** is an open-source **Elixir / Phoenix payments-and-billing library**, inspired by *Pay* (Rails) and *Laravel Cashier* but built idiomatically for the Ecto/Plug/Phoenix ecosystem. Tagline: **"Billing state, modeled clearly."** Its core promise: *a Phoenix developer can install Accrue + its companion admin UI and launch a real SaaS with subscription billing on day one* — subscriptions, checkout, invoices, coupons, transactional emails, PDFs, webhooks, a tamper-evident audit ledger, telemetry, and an operator admin. It ships **complete** (no public v0.x iteration cycle; first public release is conceptually "v1.0 = done"), not as an MVP.

**The facade boundary is central to how it's used:** the host application owns the billing *facade* (`MyApp.Billing`), its routes, its auth boundary, and its runtime config. **Accrue owns the billing engine behind them.** The admin UI is *operator chrome over that engine* — it is not the customer-facing billing surface (that's checkout + the Stripe/host billing portal).

---

## 2. The mental model: three worlds

Everything in Accrue lives across three layers, and a good operator UI is legible about which layer a given fact comes from:

1. **The processor** — Stripe or Braintree (plus a credential-free **Fake** processor for tests/demos). This is *canonical*. It holds the real money movement and the source-of-truth objects.
2. **The application** — the host SaaS. It cares about *entitlements* ("can this user use the feature?") and its own domain.
3. **Operations** — reconciliation, support, incident response, audit. This is what the admin UI mostly serves.

**Local rows are read-optimized projections of the processor.** Nearly every entity is a *projection table* with a common shape: a UUID primary key, `processor` (`"stripe"`/`"braintree"`), `processor_id`, a `metadata` map, a `data` map holding the **raw processor payload**, an optimistic-lock `lock_version`, and `last_stripe_event_ts` / `last_stripe_event_id` **watermarks** so webhooks apply idempotently. **Money is stored in integer minor units** (e.g. cents), never floats.

**Two write paths exist for most stateful entities** — a distinction the UI should respect:
- **Operator/user path** — validated changesets that *enforce state-machine transitions* (`changeset/2`). This is what an operator action in the admin drives.
- **Webhook path** — `force_status_changeset/2`, which *trusts the processor* and bypasses transition validation (because Stripe is canonical). This is what inbound webhooks drive.

So the admin is a **safe, auditable control plane over billing projections and billing operations** — closer to a reconciliation/support/incident cockpit than to a CRUD table editor.

---

## 3. The domain model — what the UI operates on

Grouped by cluster. States and lifecycle are called out because they drive most of the visual language (badges, filters, allowed actions).

### Customers & payment
- **Customer** — polymorphic owner (`owner_type` + `owner_id` point at the host's user/org). Has `name`, `email`, a `default_payment_method`, and `preferred_locale` / `preferred_timezone` (used to localize emails/receipts). Unique per `(owner, processor)`.
- **PaymentMethod** — belongs to a customer. `card_brand`, `card_last4`, `exp_month/year`, `is_default`, dedup `fingerprint`. **Stored as processor references, never raw PII.**

### Subscriptions
- **Subscription** — the richest entity. **8-state status enum:** `trialing`, `active`, `past_due`, `canceled`, `unpaid`, `incomplete`, `incomplete_expired`, `paused`. Helper predicates group these (`active?` = active|trialing; `past_due?` = past_due|unpaid; `dunning_sweepable?` = past_due). Carries `current_period_start/end`, `trial_start/end`, `cancel_at_period_end`, pause fields (`pause_collection`, `paused_at`, `pause_behavior`), a **dunning overlay** (`past_due_since`, `dunning_sweep_attempted_at`, `dunning_campaign_started_at`), a `discount_id`, and tax flags.
- **SubscriptionItem** — line within a subscription (`price_id`, `quantity`, per-item period).
- **SubscriptionSchedule** — phased/scheduled plans. States: `not_started`, `active`, `completed`, `released`, `canceled`; tracks `current_phase_index`, `phases_count`, `next_phase_at`.

### Invoices
- **Invoice** — **5-state legal machine:** `draft → open → {paid | uncollectible | void}` (draft can also go straight to void; paid/uncollectible/void are terminal). This machine is *enforced* on the operator path. Money is a set of minor-unit rollups: `subtotal`, `tax`, `discount`, `total`, `amount_due`, `amount_paid`, `amount_remaining`. Also `number`, `hosted_url`, `pdf_url`, `period_start/end`, `collection_method`, `billing_reason`, `due_date`, `finalized_at`, `voided_at`, `paid_at`.
- **InvoiceItem** — `description`, `amount_minor`, `quantity`, period, and a **`proration` flag**.
- **InvoiceCoupon** — join row recording a *realized* coupon redemption on an invoice (`amount_off_minor`).

### Money movement
- **Charge** — `amount_cents`, `currency`, `status`, plus Stripe fee tracking (`stripe_fee_amount_minor`, `fees_settled_at`).
- **Refund** — belongs to a charge. States: `pending`, `requires_action`, `succeeded`, `failed`, `canceled`. Carries fee-reconciliation fields (`stripe_fee_refunded_amount_minor`, `merchant_loss_amount_minor`).

### Discounts
- **Coupon** — `amount_off` or `percent_off`, `duration` (once/repeating/forever), `max_redemptions`, `times_redeemed`, `redeem_by`, `valid`.
- **PromotionCode** — customer-facing code that points at a coupon; `active`, `expires_at`, redemption caps.
- **DiscountMapping** — Braintree-oriented shim (Braintree has no coupon primitive); maps a code → discount.

### Metered / usage billing
- **MeterEvent** — an idempotent usage-report **outbox / audit ledger** (one row per usage report; `stripe_status` `pending → reported | failed`; a partial index on `failed` is effectively a free **DLQ view**).
- **MeterDefinition** — ties an `event_name` + aggregation mode (`sum`/`max`/`last`) to a subscription item.
- **MeteredRenewal** / **MeteredChargeAttempt** — state machines for usage-based renewal billing: `pending`, `retry_scheduled`, `awaiting_payment_method`, `paid`, `failed_exhausted`.

### Acquisition & self-service
- **CheckoutSession** — `mode` (subscription/payment/setup), `ui_mode` (hosted/embedded), `status`, `payment_status`, line items, success/cancel/return URLs.
- **BillingPortal Session** — a wrapper over the processor's customer portal (not persisted as its own table).

### Platform / marketplace
- **Connect Account** — projection of a connected account: `charges_enabled`, `payouts_enabled`, `details_submitted`, `capabilities`, **`requirements`** (what the account still owes to stay enabled), `country`, soft-delete `deauthorized_at`. Also platform fees, account links, login links.

### Access
- **EntitlementSummary** — advisory local cache of the customer's active entitlements (`entitlement_count`, `truncated`, `synced_at`). Backs `Accrue.Entitlements.entitled?/3` and friends.

### The two operational ledgers (backbone for the admin)
- **WebhookEvent** — inbound processor events. States: `received`, `processing`, `succeeded`, `failed`, `dead`, `replayed`. Stores the **raw request body** for forensic replay. Partial index on `failed`/`dead` = the incident queue.
- **Event ledger (`accrue_events`)** — an **append-only, immutable** audit log. A Postgres BEFORE-UPDATE/DELETE trigger raises on any mutation (defense-in-depth: write grants are also revoked). Every row records `type`, `actor_type` (`user`/`system`/`webhook`/`oban`/`admin`), `actor_id`, `subject_type`/`subject_id`, a `data` map, `trace_id`, and **causality links** (`caused_by_event_id`, `caused_by_webhook_event_id`). ~24 registered event types across subscription/invoice/charge/refund/payment_method/card lifecycles. It supports **`timeline_for/3`** (chronological subject history) and **`state_as_of/3`** (point-in-time state reconstruction). This is what makes "who did what, when — and what caused it?" answerable.

---

## 4. Operations the operator performs

The engine exposes a verb-rich API; each write commits the entity row **and** its audit-ledger entry atomically. The operator UI is a surface over these verbs:

- **Subscriptions:** subscribe, cancel, cancel-at-period-end, resume, pause, unpause, swap plan, update quantity, **comp** (free subscription), add/remove item, preview upcoming invoice.
- **Invoices:** finalize, void, pay, mark uncollectible, send, add/remove invoice item.
- **Money:** charge, create payment intent, create setup intent, **refund** (full or partial).
- **Payment methods:** attach, detach, set default, sync.
- **Discounts:** create coupon, create promotion code, apply promotion code.
- **Usage:** report usage.
- **Webhooks/incidents:** replay a single event, **bulk DLQ replay**, prune.
- **Connect:** create/retrieve/update/reject account, create account/login links.
- **Search:** trigram-backed search across customers, subscriptions, invoices.

**Sensitive actions (e.g. refunds) require step-up auth** — a re-authentication modal before the action commits. Any UI must treat destructive/irreversible money actions as a distinct, guarded interaction class.

---

## 5. Who operates it — six personas and their jobs

There are **six operator personas**. The load-bearing insight: **personas 1–3 all work the same billing entities and differ only in *altitude*** (glance → queue), while **4–6 are specialist rooms** that light up only when they have work. **Compliance is a saved lens (an actor-filtered view of the audit ledger), not its own destination.**

| # | Persona | The one job | Cadence | Natural entry |
|---|---------|-------------|---------|---------------|
| 1 | **Operator / Founder** | "Is billing healthy right now?" | Daily glance, seconds | Home overview (exceptions + a few KPIs) |
| 2 | **Customer Support** | "Find *one* customer and see *everything* about them" | All day, per-ticket | Global search → customer 360 |
| 3 | **Finance / Billing Ops** | "Work the open-invoice queue to zero" | Daily, heavy | Invoices as a *worklist* |
| 4 | **Recovery / Growth Ops** | "Watch the dunning funnel and at-risk revenue" | Daily/weekly | Recovery dashboard |
| 5 | **Developer / Integration** | "Debug a failed webhook end-to-end" | Bursty (incidents) | Webhooks → events → raw JSON |
| 6 | **Compliance / Audit** | "Who did what, when — and what caused it?" | Rare | Event ledger, actor-filtered |

The recurring operator question the whole thing exists to answer fast: **"This customer says they paid — why are they blocked?"** — which threads processor state, invoice state, subscription state, entitlement state, and the event/webhook history into one coherent story.

---

## 6. Cross-cutting operational realities (design "exceptions-first")

Billing operators spend their time chasing **exception states**, not admiring healthy ones. The system already surfaces these as first-class, indexed conditions — a good UI leads with them:

- **Dead-lettered / failed webhooks** (the incident queue).
- **Past-due subscriptions** (`past_due_since`) and the dunning campaign in flight.
- **Failed meter reports** (usage that didn't reach the processor).
- **Unsettled or mismatched fees** (charge/refund fee reconciliation).
- **Expiring cards** (proactive churn risk).
- **Connect accounts** losing capabilities or with outstanding `requirements`.

Supporting machinery the UI can lean on:
- **Dunning** — campaigns are ordered steps at absolute day-offsets from `dunning_campaign_started_at`; a background sweeper advances past-due subscriptions; there's a recovery/analytics surface for the funnel.
- **Telemetry ops events** — the system emits named operational signals (`revenue_loss`, `dunning_exhaustion`, `charge_failed`, `webhook_dlq.dead_lettered`, `connect_payout_failed`, `meter_reporting_failed`, …). These are the *machine* version of the exceptions above and can drive badges/alerts.
- **16 transactional emails** (invoice finalized/paid/payment-failed, receipt, refund issued, trial ending/ended, subscription canceled/paused/resumed, coupon applied, card expiring, dunning action-required / final-notice) — locale/timezone-aware.
- **Invoice PDFs** — rendered from a HEEx template; the admin can view/fetch them.
- **Money** — integer minor units, multi-currency, **proration handled at the line-item level** (mirrored from the processor, previewable via "upcoming invoice"), tax kept as narrow observability columns with the full payload in `data`.

---

## 7. Brand & voice — how it must feel

Accrue's identity is deliberately **"well-made developer tooling," not "fintech."** The reference frame is a *really good Ecto library*, not a payments startup. Keywords: **calm confidence, technical clarity, excellent defaults, quiet polish.** Guardrails: don't lean on finance clichés, don't over-brand, no playful money language.

**Palette (ratified tokens):**

| Role | Name | Hex |
|------|------|-----|
| Primary text / dark surface | Ink | `#111418` |
| Secondary dark, borders | Slate | `#24303B` |
| Soft neutral light | Fog | `#E9EEF2` |
| Page base | Paper | `#FAFBFC` |
| Primary accent / success / active | Moss | `#5E9E84` |
| Interactive / links / focus | Cobalt | `#5D79F6` |
| Warning / pending / grace | Amber | `#C8923B` |
| Danger | — | `#D64B4B` |
| Info (calm teal, distinct from accent) | — | `#3878A6` |

A full **dark-mode counterpart set** exists (base `#0F1318`, elevated `#171D24`). Several brand hues are AA-large-only on Paper, so they're used for icons / large text / dark surfaces — status is **never color-only**.

- **Typography:** **Geist Sans** (headings/wordmark) + **Geist Mono** (IDs, event names, status labels, code), with **tabular numerals** for money/tables. Medium-weight headings, high-legibility body, mono accents; docs-readability first, brand-expression second.
- **Imagery metaphor:** *not money.* It's **accumulation, timelines, state transitions, layered records, aligned intervals, durable structure.** Prefer state diagrams / timelines / event streams / lifecycle charts. **Avoid** credit-card illustrations, coins, carts, price tags, smiling stock people, SaaS blob gradients.
- **Density:** a **4px spacing scale** with a deliberate **2px "dense-table" step** — the admin is expected to support **information-dense, operator-grade tables** (docs surfaces get generous whitespace; operator tables get controlled density). The design rubric **penalizes both cramped *and* wasteful whitespace.**
- **Voice:** four fixed adjectives — **measured, exact, native, durable** — north star *"sounds like a maintainer you trust."* Literal and precise by default; imagery only to make a mechanism concrete.
- **Banned words** (claims-by-adjective): *production-grade, batteries-included, bank-grade, seamless, powerful, robust, easy, effortless, simple, best-in-class, world-class, wallet, money, funds, demo.* State a named mechanism instead.
- **Error microcopy posture:** state the fact, give the next action — **no apologetic softening.** Empty states are quietly explanatory (e.g. *"No active subscriptions." / "Subscriptions appear here after a customer completes checkout."*).
- **Comparative brand anchors** for the *look*: Linear, Vercel, Prisma, Tailscale, Oban dashboards. **Stripe is explicitly dropped as a brand-positive exemplar** (it's the fintech look Accrue is *not*) — usable only as a density/IA reference, never as a style target.

---

## 8. Hard constraints for the UI

- **Phoenix LiveView** is the runtime (server-rendered, live updates).
- **`ax-*` CSS-custom-property design tokens are the single source of truth.** Tailwind exists *only* as a build-time compiler/minifier for the committed CSS bundle — **it is not an authoring path.** Author against the token system, not utility classes.
- **Light + dark themes** both first-class; system-follow by default.
- **Mobile-first and usable at 360px** — data tables degrade to stacked label/value cards on narrow screens.
- **Restrained, purposeful motion** honoring `prefers-reduced-motion`.
- **A dense operator console**, not a marketing page — the density defender is a real design constraint.
- **Multi-tenant owner-scoping** — an `?org=` scope threads through navigation so a single admin can be scoped to one tenant.
- Admin chrome branding is host-derivable and may differ from the customer-facing billing brand.

---

## Appendix A — What exists today (reference only; goal is to re-derive, not replicate)

Included so the design can build on real domain knowledge and **deliberately improve or diverge** — *not* as a template to reproduce. Treat this as the current baseline to beat.

**Navigation groups (current):**
- **Home** — operator overview.
- **Billing** — Customers · Subscriptions · Invoices · Payments.
- **Recovery** — dunning/at-risk dashboard (badge = at-risk count).
- **Developer** — Webhooks (badge = dead-letter/blocked count) · Event log.
- **Catalog** — Coupons · Promotion codes.
- **Connect** — connected accounts (stands alone).
- *(Compliance is a saved actor-filter lens on the event log, not its own group.)*

**~17 screens:** dashboard; customers list + customer-360 detail (tabbed: subscriptions/invoices/payments + entitlements/tax/payment-methods); subscriptions list + detail; invoices list + detail; payments list + detail; coupons + detail; promotion codes + detail; connect accounts + detail; events list + detail; webhooks list + detail; recovery dashboard + per-subscription campaign timeline. Dev-only surfaces (Fake processor): time-travel clock, email preview, webhook fixtures, a component gallery, and a Fake-inspect view.

**Three screen-archetype grammars in use:**
1. **Overview (dashboard/recovery)** — four zones: *exceptions-first attention rail → verb-labeled task launchers + visible ⌘K search → demoted-but-clickable KPI cluster → recent-activity strip.* Principle: **one page = one decision/task, not a wall of metrics.**
2. **List / queue (the ~9 index pages)** — page header (breadcrumbs, title, stat strip, filters) → filter-chip row with result count + clear-all → responsive data table (stacks to cards on mobile) → server pagination. **Table-first, work-queue default pre-applied with "All" one chip away; column priority = identity · state · money · time; ≥8 rows above the fold.**
3. **Detail (single-object pages)** — breadcrumbs → an always-on summary-list header (GOV.UK-style state summary) → action menu (≤2 primary buttons + overflow) → collapsible drill sections → exactly one related-resources strip → lazy activity timeline + raw JSON at the bottom. Principle: **summary-then-drill, not everything-at-once.** Tabs are only for peer record-sets, never for primary state/actions.

*(These are the current answers. The exercise is to decide, from the domain + personas + brand above, whether they're the* right *answers — and to storyboard the full breadth-and-depth journey you'd design instead.)*
