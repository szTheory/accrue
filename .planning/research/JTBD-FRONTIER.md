# JTBD Frontier — Capability Map, Gaps, and Diminishing Returns

**As of:** accrue / accrue_admin / accrue_portal **1.1.1** (milestone **v1.38**, 2026-05-08) · written **2026-05-22**
**Audience:** maintainer / milestone planning. **Internal — not published to HexDocs** (matches v1.27 "no public roadmap" posture).
**Regenerate via:** the JTBD docs prompt (same prompt creates this on first run and updates it on later runs). Re-verify status cells against code + `.planning/MILESTONES.md` before editing; append an Update log entry.

**Public companion:** the "Scope & maturity" section of [`accrue/guides/jobs_to_be_done.md`](../../accrue/guides/jobs_to_be_done.md) is the user-facing summary of this map. Keep the two in sync when status changes.

## How this reconciles with existing posture

This doc does **not** introduce a new "should we keep building?" framework. It feeds the existing one:

- **Stop rules S1/S5** and the intake-gated maintenance stance live in [`research/v1.17-north-star.md`](v1.17-north-star.md) and [`accrue/guides/maturity-and-maintenance.md`](../../accrue/guides/maturity-and-maintenance.md). Those say *default to not doing speculative multi-file work*.
- This doc answers the prior question those rules assume: **which JTBD are even on the table**, and **where the value curve flattens**, so that when a sourced request or strategy change arrives, prioritization is already reasoned.
- New scoped work still enters through [`research/v1.17-FRICTION-INVENTORY.md`](v1.17-FRICTION-INVENTORY.md) with the priority bar + sources — not through this doc's prose. This is the "what would be worth doing if we decided to," not a commitment.

## TL;DR verdict

**Accrue is feature-complete for its core promise** — "a Phoenix dev can launch a real SaaS with subscription billing on day one." On the core subscription-billing JTBD it **matches or exceeds** Pay (Rails) and Laravel Cashier, and it ships things they don't (companion admin UI, tamper-evident audit ledger, first-class telemetry, metered billing, Connect, pure-Elixir invoice PDFs).

The value curve has flattened. Of everything still missing, exactly **one** item meaningfully dents the "feature-complete for a real SaaS" claim: **entitlements / plan-gating** — you can bill a customer but Accrue gives you nothing first-party to *gate features* on that subscription. Everything else is either an intentional non-goal (accounting, marketplace-MoR) or genuine polish.

**If one more milestone is ever spent on user-flow surface, spend it on entitlements.** After that, diminishing returns are real.

## Coverage map — what's built

Status legend: **✅ Shipped** · **🟡 Partial** (bounded; note says how) · **🚫 Out-of-scope** (intentional non-goal) · **⛔ Gap** (genuinely absent).

### Core subscription lifecycle
| JTBD | Status | Evidence | Notes |
|------|--------|----------|-------|
| Create a billing customer (lazy or explicit) | ✅ | `Accrue.Billing.customer/1`, `create_customer/1` | Polymorphic billable (`owner_type`/`owner_id`) |
| Start a subscription | ✅ | `Accrue.Billing.subscribe/3` | Primary facade entry; PROC-08 second-provider slice |
| Free trials | ✅ | `subscribe/3` `:trial_end` (`{:days,n}` / `DateTime`) | `:trialing` status; `trial_will_end` → `:trial_ending` email |
| Change plan (upgrade/downgrade) | 🟡 | `swap_plan/3` + `preview_upcoming_invoice/2` | Stripe native · Braintree bounded (needs `:plan_resolver`) · Fake test-only |
| Change quantity / seats | 🟡 | `update_quantity/3`, `update_item_quantity/3` | Stripe/Fake official; Braintree bounded |
| Multi-item subscriptions | ✅ | `add_item/3`, `remove_item/2` | |
| Phased / scheduled changes | ✅ | `subscribe_via_schedule/3`, `update_schedule/3`, `release_schedule/2` | Stripe SubscriptionSchedule |
| Pause / resume | 🟡 | `pause/2`, `unpause/2`, `resume/2` | Provider-honest; see `lifecycle_semantics.md` |
| Cancel (immediate) | ✅ | `cancel/2` | Shared immediate path across providers |
| Cancel at period end | 🟡 | `cancel_at_period_end/2` | Stripe/Fake only (Braintree scheduled-end semantics differ) |
| Comp / discounted internal subs | ✅ | `comp_subscription/3` | |

### Money movement
| JTBD | Status | Evidence | Notes |
|------|--------|----------|-------|
| Hosted checkout | ✅ | `create_checkout_session/2` | Stripe hosted URL · Braintree mounted local (`accrue_portal`) |
| One-off charge | ✅ | `charge/3`, `create_payment_intent/2`, `create_setup_intent/2` | |
| Invoices: finalize/pay/void/uncollectible/send | ✅ | `finalize_invoice/2`, `pay_invoice/2`, `void_invoice/2`, `mark_uncollectible/2`, `send_invoice/2` | Lifecycle from processor projection |
| Invoice PDFs | ✅ | `render_invoice_pdf/2`, `store_invoice_pdf/2`, `fetch_invoice_pdf/1` | Rendro default (no Chrome); ChromicPDF compat path |
| Payment methods CRUD + default | ✅ | `add/attach/detach/delete/update/set_default/list/sync_payment_methods` | Stored as processor refs, never PII |
| Refunds (full + partial + fee reconciliation) | ✅ | `refund/2` `:amount` (Money) | Currency match enforced; tracks fee-refunded + merchant-loss |
| Manual / ad-hoc invoice line items | ⛔ | `InvoiceItem` schema is read-projection only | No public creator; invoices treated immutable post-finalize |

### Growth, usage, tax
| JTBD | Status | Evidence | Notes |
|------|--------|----------|-------|
| Coupons | ✅ | `create_coupon/2` | |
| Promotion codes | ✅ | `create_promotion_code/2`, `apply_promotion_code/3` | |
| Custom code → discount bridge | ✅ | `upsert/get/resolve_discount_mapping` | Braintree local promo support |
| Usage / metered billing | ✅ | `report_usage/3` | Two-layer idempotency; Stripe meters + Braintree local metering ledger (v1.33) |
| Automatic tax | 🟡 | `update_customer_tax_location/2`, `automatic_tax` flag (v1.3) | **Stripe only**; no Braintree tax |
| Multi-currency | 🟡 | per-object `currency` (charge/invoice/refund) | Per-transaction, not per-customer; no currency-selection logic |
| Proration | 🟡 | `swap_plan/3` `:proration`, preview flags | Processor-native; no local proration math |

### Failure handling, sync, trust
| JTBD | Status | Evidence | Notes |
|------|--------|----------|-------|
| Webhook ingest (verify→persist→enqueue→200) | ✅ | `Accrue.Router.accrue_webhook/2`, `Webhook.Plug`, `Webhook.Ingest` | Signature mandatory, raw-body before parsers |
| Webhook handler customization | ✅ | `use Accrue.Webhook.Handler` | Host pattern-matches event types; rescue-wrapped |
| Replay / DLQ | ✅ | admin `/webhooks`, `DispatchWorker` | Idempotent replay |
| Dunning / failed-payment recovery | 🟡 | `Accrue.Billing.Dunning`, `Accrue.Jobs.DunningSweeper` | Grace-period overlay + terminal-action decision; **Stripe owns retry cadence**; no notification journeys |
| Disputes / chargebacks | ⛔ | none | No schema/handler/surface |
| Immutable audit ledger | ✅ | `Accrue.Events` `record/timeline_for/state_as_of/bucket_by` | PG trigger blocks UPDATE/DELETE; idempotency + actor/trace capture |
| Telemetry / observability | ✅ | `[:accrue, …]` span events, `guides/telemetry.md` | OTel helpers no-op if otel absent |

### Operator & platform
| JTBD | Status | Evidence | Notes |
|------|--------|----------|-------|
| Admin UI (dashboard/customers/subs/invoices/charges/webhooks/events) | ✅ | `accrue_admin` LiveViews | Mounted via `accrue_admin/2`, host-auth gated |
| Customer self-service portal | ✅ | `create_billing_portal_session/2` | Stripe hosted · Braintree mounted local |
| Organization / multi-tenant billing | ✅ | polymorphic billable + owner-scoped queries (v1.3 ORG, v1.8 non-Sigra recipes) | Sigra optional, not required |
| Marketplace / Connect (accounts, split charges, transfers) | ✅ | `Accrue.Connect` | Stripe Connect |
| Admin search across billing records | ⛔ | none | SEED-002 #5 (Scrypath) |
| Entitlements / plan-gating (`has_active_plan?`, plugs/guards) | ⛔ | `Subscription.is_active?/1` exists but no public gate | **SEED-002 #4 — the headline gap** |
| SaaS metrics (MRR/ARR/churn/LTV) | 🚫 | ledger primitives only (`bucket_by/2`) | Opinionated math deliberately left to host |
| Revenue recognition / accounting exports | 🚫 | — | **FIN-03** explicit non-goal |
| GDPR data purge / cascading delete | 🚫 | — | Host policy; ledger immutable by design |
| Merchant-of-record processors (Paddle, Lemon Squeezy) | 🚫 | Stripe + Braintree + Fake | PROC-08 bounded; MoR/tax-handling not in scope |
| Marketplace payouts via Hyperwallet | 🚫 | — | Durable no-go (v1.33) |

## Delta to feature-complete (ecosystem benchmark)

Benchmarked against the libraries Accrue is positioned next to, plus the commercial ceiling:

| Capability | Accrue | Pay (Rails) | Laravel Cashier | Stripe Billing native | Chargebee/Recurly |
|------------|:------:|:-----------:|:---------------:|:---------------------:|:-----------------:|
| Subscription core (create/swap/qty/cancel/trial) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Coupons / promo codes | ✅ | ✅ | ✅ | ✅ | ✅ |
| Invoices + PDFs | ✅ | ✅ | ✅ | ✅ | ✅ |
| Proration | 🟡 (native) | ✅ | ✅ | ✅ | ✅ |
| Dunning | 🟡 (grace+terminal) | ✅ (flows) | 🟡 (grace) | ✅ | ✅ (full) |
| Metered / usage | ✅ | 🟡 | 🟡 | ✅ | ✅ |
| Tax | 🟡 (Stripe Tax) | 🟡 | 🟡 | ✅ | ✅ |
| Webhooks (batteries-included) | ✅ | ✅ | ✅ | n/a | n/a |
| **Companion admin UI** | ✅ | ⛔ | ⛔ | (Dashboard) | ✅ |
| **Tamper-evident audit ledger** | ✅ | ⛔ | ⛔ | 🟡 | 🟡 |
| **First-class telemetry/OTel** | ✅ | ⛔ | ⛔ | n/a | n/a |
| Connect / marketplace | ✅ | 🟡 | ⛔ | ✅ | 🟡 |
| **Entitlements / feature-gating** | ⛔ | ⛔ | ⛔ | ✅ (Entitlements API, 2024) | ✅ |
| Revenue recognition | 🚫 | ⛔ | ⛔ | ✅ | ✅ |
| MRR/ARR/churn analytics | 🚫 | ⛔ | ⛔ | ✅ (Sigma) | ✅ |
| # of processors | 2 + Fake | 4 + Fake | 1–2 | n/a | n/a |

**Reading of the delta:**

1. **Accrue already wins the "Phoenix-idiomatic batteries-included" comparison.** Versus Pay/Cashier it is at parity on the billing core and *ahead* on admin UI, audit, observability, metering, and PDF. Nothing here is a gap — this is the moat.
2. **The one capability every comparator-or-better has that Accrue lacks is entitlements.** Stripe shipped a first-class Entitlements API; Chargebee/Recurly have always had it. Pay/Cashier also lack it, but Accrue's whole pitch is "more complete than they are." This is the gap that's *inconsistent with Accrue's own positioning*.
3. **The rest of the delta is intentional.** Revenue recognition (FIN-03), opinionated MRR math, MoR processors, Hyperwallet — all explicit non-goals with written boundaries. Closing them would be scope-creep into "accounting platform" / "merchant of record," which Accrue has deliberately decided not to be.

## Prioritized future JTBD (if/when a milestone opens)

Ranked by **value × fit-with-posture ÷ effort**. None of these are committed — they're the reasoned ordering for when intake or a strategy change pulls one in.

1. **Entitlements / plan-gating** — `Accrue.has_active_plan?(billable, "pro")`, Plug + LiveView `on_mount` guards, optional sync from Stripe's `entitlements.active_entitlement_summary.updated` webhook.
   - *Why #1:* highest-frequency post-subscription JTBD ("I'm subscribed — now gate the feature"), the only gap that contradicts the "more complete than Pay/Cashier" claim, increasingly table-stakes, and **already seeded** (SEED-002 #4: Sigra/Lockspire identity). Subscription state already exists locally — this is a thin, high-leverage layer, not a new domain.
2. **Dunning depth / notification journeys** — move from grace+terminal decision to multi-step recovery (email → wait → escalate). Maps to SEED-002 #1 (Chimeway + Mailglass). Recovers revenue; current state is bounded.
3. **Admin search** — Ecto-native search across Customer/Invoice/Subscription in `accrue_admin`. SEED-002 #5 (Scrypath). Pure operator-JTBD friction that grows with customer count.
4. **Ad-hoc / manual invoice line items** — let hosts add one-off charges/credits to an invoice before finalize. Fills a real B2B billing edge; small surface.
5. **Disputes / chargebacks visibility (read-only)** — project `charge.dispute.*` events into the ledger + admin for operator awareness. Read-only keeps it cheap and on-posture.
6. **Audit bridge** — sink critical events to an external immutable audit platform (SEED-002 #2, Threadline). Low marginal value since Accrue already has its own tamper-evident ledger; mostly for shops standardizing on a separate audit system.

## Diminishing-returns frontier — "definition of done"

```
 value to a real SaaS dev
   ^
   |  subscription core ──────●  (DONE: matches Pay/Cashier)
   |  invoices/PM/webhooks ───●  (DONE)
   |  audit/telemetry/admin ──●  (DONE: ahead of comparators)
   |  metering/Connect/tax ───●  (DONE / bounded)
   |                          ●  entitlements   ← the last high-value point
   |                            ◌  dunning journeys, admin search
   |                              ◌ ad-hoc items, disputes view
   |                                ◌ audit bridge, more processors…
   +----------------------------------------------------------------> effort
                              ▲
                    diminishing returns begin here
```

**Definition of "done" for the user-flow surface:** Accrue is *done* the moment a Phoenix dev can **bill a customer, change/cancel that subscription, recover failed payments, let the customer self-serve, gate access on what they paid for, and operate it all from an admin UI with an audit trail.** Five of those six are shipped. **The sixth — gate access — is the only missing piece of the canonical SaaS loop.**

Therefore:
- **Above the line (worth building if pulled in):** entitlements (#1), and arguably dunning depth (#2) for revenue-recovery shops.
- **At the line (intake-only):** admin search, ad-hoc invoice items, disputes view — build only on a sourced request, per stop rule S1.
- **Below the line (don't):** anything that turns Accrue into an accounting system (FIN-03), a metrics product, a merchant-of-record, or a marketplace-payouts platform. These are not "more billing" — they are *different products*. Pursuing them is the textbook diminishing-returns trap for a billing library.

The honest summary for the maintainer: **the autopilot did, in fact, build a feature-complete billing library.** The "we're basically done / intake-gated" posture is correct. Entitlements is the one place where "basically" is doing real work — it's the highest-leverage thing left, and it's already on the seed list.

## Update log

- **2026-05-22** — Initial frontier map. As-of accrue 1.1.1 / v1.38. Verified all status cells against source (`accrue/lib/accrue/billing.ex` et al.) and `.planning/MILESTONES.md`; corrected first-pass errors (Stripe Tax, partial refunds, trials, org billing, webhook customization are all shipped). Benchmarked vs Pay/Cashier/Stripe Billing/Chargebee. Verdict: feature-complete on core; entitlements is the single headline gap.
