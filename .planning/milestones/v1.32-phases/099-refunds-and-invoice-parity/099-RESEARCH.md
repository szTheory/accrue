# Phase 99: Refunds and Invoice Parity - Research

**Researched:** 2026-04-30
**Domain:** Braintree refunds, refund projection convergence, and Braintree proration semantics in an Elixir/Phoenix billing library. [VERIFIED: accrue/mix.exs] [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md]
**Confidence:** MEDIUM [VERIFIED: accrue/lib/accrue/processor/braintree.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Refund entrypoint and operator surface

- **D-01:** The canonical refund mutation seam remains the public billing context, not the admin UI. Phase 99 should center refunds on `Accrue.Billing.refund/2` semantics, with any compatibility path from the current `create_refund/2` surface handled as an implementation detail.
- **D-02:** Phase 99 should include a **narrow `AccrueAdmin` charge-detail refund action** so the roadmap promise that operators can issue refunds is true without turning the admin package into a finance console.
- **D-03:** `AccrueAdmin` should stay a **thin operator shell** over `Accrue.Billing`: server-driven action, explicit confirmation, audit/event trail, and projection-first reads.
- **D-04:** Phase 99 should **not** introduce a broad refunds workspace, customer self-serve refund UI, or invoice-level refund command center.
- **D-05:** Refund eligibility and copy must be explicit:
  - refunds apply to Braintree transactions that are `settling` or `settled`
  - voiding pre-settlement transactions is a different operation
  - partial refunds are allowed and may occur multiple times
  - refund API success is not the final lifecycle truth

### Refund projection semantics

- **D-06:** Use **sale-truth parent + first-class child refunds** as the local-truth model.
- **D-07:** `Charge` remains the projection of the original sale transaction. Its status should continue to reflect sale truth, not be rewritten into a fake “netted refund state.”
- **D-08:** `Refund` rows remain first-class child facts. Multiple partial refunds must remain visible as separate refund facts rather than being collapsed into one synthetic parent status.
- **D-09:** `Invoice` remains the sale-cycle projection, not a synthetic “net after refunds” document.
- **D-10:** Operator UX should be powered by **derived rollups**, not by mutating the parent into fake processor-neutral sameness. Planning should expect derived fields/read-models in the charge/invoice surface such as:
  - total refunded amount
  - refund count
  - refund progress summary
- **D-11:** Phase 99 should tolerate webhook ordering and asynchronous settlement realities:
  - refund creation may succeed before final refund settlement truth is known
  - later webhook events may confirm, settle, or decline refund outcomes
  - out-of-order child-before-parent events must defer cleanly rather than crash

### Refund data model

- **D-12:** Refund identity should begin moving toward a **processor-neutral core now, but additively**.
- **D-13:** Add `processor_id` to `accrue_refunds` in Phase 99 and dual-write/read-both for Stripe-backed and Braintree-backed refunds.
- **D-14:** Keep `stripe_id` as a deprecated compatibility alias through v1.x. Do **not** rename fields in place or force a full refund-schema reset in this phase.
- **D-15:** Do **not** pay the full abstraction tax on refund fee semantics yet. Existing Stripe-specific fee-settlement fields may remain for now.
- **D-16:** Any Braintree-specific refund details that do not map cleanly to the current first-class schema should live in `data` until a concrete cross-processor reporting/query need justifies new first-class fields.
- **D-17:** Phase 99 should improve refund schema coherence where the gain is immediate and low-risk:
  - neutralize identity first
  - defer deep fee normalization
  - avoid speculative provider-agnostic redesign

### Braintree refund behavior and truth rules

- **D-18:** Braintree refund support should stay **transaction-honest**:
  - refunds are created against prior settled/settling transactions
  - repeated partial refunds are supported
  - a refund is a child transaction, not a mutation of the original sale transaction into a different object
- **D-19:** Phase 99 should project Braintree refund lifecycle truth through adapter fetch + webhook-driven convergence rather than assuming the initial API response is final.
- **D-20:** Planning should expect Braintree refund projection to react to refund-related transaction lifecycle signals, including successful settlement and settlement-decline paths where applicable.
- **D-21:** Local truth should remain projection-first and auditable:
  - original sale truth on `Charge`
  - refund facts on `Refund`
  - operator summaries derived from those facts

### Proration posture

- **D-22:** Keep Accrue’s existing rule that **proration must be explicit** on mutating billing APIs. Do not soften this for Braintree.
- **D-23:** Braintree support should stay **honest and narrow**:
  - support `:none`
  - support `:create_prorations`
  - reject `:always_invoice`
  - reject `proration_date`
  - reject `billing_cycle_anchor`
  - reject Stripe-only payment-behavior knobs
- **D-24:** Enable Braintree `swap_plan/3` only for the subset the provider can support honestly through the generic facade. Planning should treat cross-frequency plan swaps as unsupported unless proven otherwise.
- **D-25:** When Braintree uses `proration: :create_prorations`, planning should pass provider-native settings that avoid hidden debt and rollback ambiguity, including `prorate_charges: true` and `revert_subscription_on_proration_failure: true`.
- **D-26:** Do **not** emulate Stripe’s upcoming-invoice preview semantics for Braintree in Phase 99. `preview_upcoming_invoice/2` should remain unsupported for Braintree until Accrue is willing to own a real manual proration engine.
- **D-27:** Braintree downgrade proration credits are **not refunds**. Subscription-balance credits must stay distinct from explicit `refund/2` flows in local truth, docs, and operator copy.

### Elixir / Phoenix / Ecto posture

- **D-28:** The context owns the mutation; LiveView/admin owns the operator presentation. This is the idiomatic division for this repo and for Phoenix/Ecto systems like it.
- **D-29:** Webhook-driven convergence should continue to be **projection-first** and persistence-backed, with explicit reducer logic and deferral paths instead of UI-only or provider-live reads.
- **D-30:** Brownfield schema evolution should be **additive and compatibility-safe** in v1.x: additive columns, dual-write/read-both, deprecate, remove only in a later major.
- **D-31:** Public APIs must continue to **fail clearly** when the provider cannot honor the advertised semantic. Do not coerce unsupported Braintree semantics into misleading “close enough” behavior.

### Ecosystem lessons to preserve

- **D-32:** Learn from **Laravel Cashier**: keep provider stories useful and polished, but do not pretend complex provider behavior is identical when it is not.
- **D-33:** Learn from **Pay (Rails)**: bounded multi-processor support works when the common surface stays narrow and divergence is documented honestly.
- **D-34:** Avoid the **ActiveMerchant** trap: broad gateway sameness creates conceptual debt, DX drift, and surprise behavior around long-tail processor edge cases.
- **D-35:** For this repo, the least-surprise story is:
  - narrow but real support
  - projection-backed operator truth
  - explicit unsupported semantics
  - additive schema hardening where needed

### Shift-left preference for future GSD passes

- **D-36:** Future processor-track discuss/planning passes should default to **research-backed recommendation bundles** instead of interactive question trees for low-impact implementation choices.
- **D-37:** Reopen choices interactively only when they materially change:
  - product boundary
  - public support promise
  - destructive-state semantics
  - schema migration risk at major-contract level
  - proof-lane philosophy
  - user-visible UX philosophy in a meaningful way
- **D-38:** Future recommendation bundles should stay coherent with the project’s existing strategy:
  - least surprise
  - capability-explicit support
  - narrow operator control planes
  - projection-first Phoenix ergonomics
  - additive brownfield evolution

### the agent's Discretion

- Exact compatibility path between `create_refund/2` and `refund/2` as long as the public mutation seam stays singular and well-documented.
- Exact naming and storage of derived refund rollups on the charge/invoice read model.
- Exact reducer and webhook event wiring for Braintree refund settlement and settlement-decline convergence.
- Exact deprecation messaging for `stripe_id` once `processor_id` is added to refunds.
- Exact admin copy, warning hierarchy, and confirmation UX for operator-triggered refunds.

### Deferred Ideas (OUT OF SCOPE)

No deferred ideas section is present in `099-CONTEXT.md`. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-18 | Implement the Braintree `charge.refund` flow with parity to the Stripe implementation. | Add a canonical `Accrue.Billing.refund/2` seam over the existing refund action pattern, implement `Accrue.Processor.Braintree.create_refund/2` and `retrieve_refund/2`, keep additive schema evolution on `accrue_refunds`, and preserve child-refund projection semantics. [VERIFIED: accrue/lib/accrue/billing/refund_actions.ex] [VERIFIED: accrue/lib/accrue/processor/braintree.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] |
| PROC-19 | Implement Braintree webhook convergence for refunds, ensuring local `Invoice` and `Charge` records correctly project Braintree's transaction statuses. | Extend the existing projection-first reducer path, but do not plan on generic card-refund webhooks; use applicable Braintree webhook signals plus explicit fetch/reconcile for card refunds, and derive charge/invoice refund rollups without mutating sale truth. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue/lib/accrue/billing/invoice_projection.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/] |
</phase_requirements>

## Summary

Phase 99 is an extension of existing refund and operator seams, not a greenfield build. The repo already has a Stripe-shaped refund write path in `Accrue.Billing.create_refund/2`, a first-class `Refund` schema keyed by `stripe_id`, an admin charge-detail refund action, and a projection-first webhook reducer with out-of-order deferral logic. The missing work is concentrated in the Braintree adapter, additive refund schema normalization, and Braintree-specific convergence rules. [VERIFIED: accrue/lib/accrue/billing.ex] [VERIFIED: accrue/lib/accrue/billing/refund_actions.ex] [VERIFIED: accrue/lib/accrue/billing/refund.ex] [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]

The most important planning constraint is that Braintree refund lifecycle truth is not Stripe-like. Braintree refunds are child transactions issued against settled or settling sale transactions, repeated partial refunds are allowed, voiding remains a separate pre-settlement operation, and downgrade proration credits stay on the subscription balance instead of becoming card refunds. [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] [CITED: https://developer.paypal.com/braintree/docs/reference/general/statuses/] [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/recurring-advanced-settings] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/]

The second critical planning constraint is that generic Braintree transaction webhooks are documented as available for ACH and SEPA Direct Debit transaction sale/refund requests, not broad credit-card refunds. For this phase, planner tasks should treat "webhook convergence" as "webhook where applicable plus adapter refetch/reconcile for card refunds," otherwise PROC-19 will be over-promised. This is consistent with the locked context language that refund settlement signals apply "where applicable." [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/] [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md]

**Primary recommendation:** Implement Phase 99 as an additive refund-core hardening pass: introduce `refund/2` as the canonical facade, add `processor_id` to refunds with dual read/write compatibility, implement Braintree refund create/retrieve plus fetch-driven convergence, and derive refund rollups on charge/invoice views without mutating sale truth. [VERIFIED: accrue/lib/accrue/billing.ex] [VERIFIED: accrue/lib/accrue/billing/refund.ex] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/]

## Project Constraints (from CLAUDE.md)

- The repo is a monorepo with sibling `accrue/` and `accrue_admin/` Mix projects. [VERIFIED: CLAUDE.md]
- Tech floor is Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, PostgreSQL `14+`. The local machine currently exceeds that floor with Elixir `1.19.5`, OTP `28`, and PostgreSQL `14.17`. [VERIFIED: CLAUDE.md] [VERIFIED: elixir --version] [VERIFIED: psql --version]
- Webhook signature verification is mandatory and non-bypassable. [VERIFIED: CLAUDE.md]
- Public billing entry points must emit telemetry and follow the existing Billing context boundary rather than leaking provider calls into UI code. [VERIFIED: CLAUDE.md] [VERIFIED: accrue/lib/accrue/billing.ex]
- Brownfield changes in v1.x should stay additive and compatibility-safe. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md] [VERIFIED: CLAUDE.md]
- Repo guidance says use GSD workflows for edits; this research file is part of that workflow. [VERIFIED: CLAUDE.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical refund command (`refund/2`) | API / Backend | Frontend Server (SSR) | Refund issuance is a money-moving mutation and already belongs in `Accrue.Billing`; admin UI should delegate. [VERIFIED: accrue/lib/accrue/billing.ex] [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] |
| Provider refund execution | API / Backend | — | `Accrue.Processor.Braintree` owns translation to `Braintree.Transaction.refund/3` and refetches. [VERIFIED: accrue/lib/accrue/processor/braintree.ex] [VERIFIED: accrue/deps/braintree/lib/transaction.ex] |
| Refund persistence and compatibility migration | Database / Storage | API / Backend | `accrue_refunds` is the durable truth for refund facts; Phase 99 needs additive schema evolution there. [VERIFIED: accrue/priv/repo/migrations/20260414120000_phase3_schema_upgrades.exs] [VERIFIED: accrue/lib/accrue/billing/refund.ex] |
| Refund lifecycle convergence | API / Backend | Database / Storage | The reducer/fetch path and reconciliation jobs own stale ordering, deferral, and replay-safe projection. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue/lib/accrue/jobs/reconcile_refund_fees.ex] |
| Charge/invoice refund rollups | API / Backend | Frontend Server (SSR) | Charge and invoice rows remain sale-truth anchors; refund summaries should be derived in read models and rendered in admin. [VERIFIED: accrue/lib/accrue/billing/invoice_projection.ex] [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] |
| Operator refund UX | Frontend Server (SSR) | API / Backend | The existing LiveView charge detail already owns confirmation, step-up, and audit flow, but it must stay thin over Billing. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] [VERIFIED: accrue_admin/test/accrue_admin/live/charge_live_test.exs] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `braintree` | `0.16.0` | Elixir Braintree server SDK used by the adapter. [VERIFIED: mix deps] [VERIFIED: https://hex.pm/packages/braintree] | The repo already depends on it and the local dependency exposes `Transaction.refund/3` and `Webhook.parse/3`. [VERIFIED: accrue/mix.exs] [VERIFIED: accrue/deps/braintree/lib/transaction.ex] [VERIFIED: accrue/deps/braintree/lib/webhook.ex] |
| `ecto` / `ecto_sql` | `3.13.5` / `3.13.5` | Additive migration work and optimistic-lock-backed refund persistence. [VERIFIED: mix deps] | The existing refund schema, reducer, and tests already use Ecto patterns the planner should preserve. [VERIFIED: accrue/lib/accrue/billing/refund.ex] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] |
| `phoenix_live_view` | `1.1.28` | Thin operator surface in `AccrueAdmin`. [VERIFIED: mix deps] | The existing charge-detail refund flow already lives here and should be extended, not replaced. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] |
| `oban` | `2.21.1` | Async reconciliation backstop for eventual refund truth where provider immediacy is unreliable. [VERIFIED: mix deps] | The repo already has `ReconcileRefundFees`; a Braintree refund reconciliation sweep can follow the same pattern if needed. [VERIFIED: accrue/lib/accrue/jobs/reconcile_refund_fees.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `nimble_options` | `1.1.1` | Strict public option validation for explicit-proration APIs. [VERIFIED: mix deps] | Reuse for Braintree refund/proration option gating instead of ad hoc keyword parsing. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex] |
| `ex_money` | `5.24.2` | Money-safe partial refund option handling. [VERIFIED: mix deps] | Reuse the existing `%Accrue.Money{}` refund amount input pattern. [VERIFIED: accrue/lib/accrue/billing/refund_actions.ex] |
| `telemetry` | `1.4.1` | Preserve billing/webhook observability on new refund and reconcile paths. [VERIFIED: mix deps] | Use on reducer deferrals, stale events, and any new reconciliation job. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue/lib/accrue/jobs/reconcile_refund_fees.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Additive `processor_id` + compatibility `stripe_id` | Full in-place rename of refund columns | Full rename is cleaner eventually, but it contradicts the locked additive v1.x migration posture and would create more break risk now. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md] |
| Fetch/reconcile for card refunds plus applicable webhooks | Webhook-only convergence | Webhook-only is simpler in code, but official Braintree docs only document transaction webhooks for ACH and SEPA direct debit sale/refund requests. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/] |
| Derived refund rollups on charge/invoice reads | Mutating `Charge.status` or `Invoice.status` into netted refund states | Mutating parent sale truth would create fake cross-processor sameness and breaks the locked local-truth model. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md] |

**Installation:**
```bash
cd accrue && mix deps
```
[VERIFIED: accrue/mix.exs] [VERIFIED: mix deps]

**Version verification:** Current locked versions in this repo are `braintree 0.16.0`, `ecto 3.13.5`, `ecto_sql 3.13.5`, `phoenix_live_view 1.1.28`, and `oban 2.21.1`. The Braintree Hex package page shows `v0.16.0` and "Last Updated Mar 27, 2025." [VERIFIED: mix deps] [VERIFIED: https://hex.pm/packages/braintree]

## Architecture Patterns

### System Architecture Diagram

```text
Admin charge detail / Billing caller
        |
        v
Accrue.Billing.refund/2
        |
        v
RefundActions / option validation / idempotency
        |
        +----> Accrue.Processor.Braintree.create_refund/2
        |              |
        |              v
        |        Braintree.Transaction.refund/3
        |
        v
accrue_refunds insert (processor_id + stripe_id compatibility, data payload)
        |
        +----> accrue_events audit/event append
        |
        +----> immediate adapter refetch/retrieve_refund/2 when needed
        |
        +----> webhook reducer if applicable
        |          |
        |          v
        |    fetch canonical refund/parent transaction
        |          |
        |          v
        |    upsert refund fact + derived charge/invoice rollups
        |
        v
Admin reads charge/invoice sale truth + derived refund summary
```
[VERIFIED: accrue/lib/accrue/billing/refund_actions.ex] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/]

### Recommended Project Structure

```text
accrue/lib/accrue/
├── billing/
│   ├── refund_actions.ex        # canonical refund command + compatibility bridge
│   ├── refund.ex                # refund schema and dual-read/write fields
│   ├── invoice_projection.ex    # sale-truth invoice projection + derived refund rollups
│   └── subscription_actions.ex  # explicit Braintree proration gating
├── processor/
│   ├── braintree.ex             # refund create/retrieve/fetch and Braintree proration update mapping
│   └── fake.ex                  # refund + proration regression doubles
├── webhook/
│   └── default_handler.ex       # applicable Braintree refund lifecycle convergence + deferral
└── jobs/
    └── reconcile_refund_fees.ex # existing pattern to mirror for Braintree reconcile if needed

accrue_admin/lib/accrue_admin/live/
└── charge_live.ex               # thin operator refund UX over Billing
```
[VERIFIED: accrue/lib/accrue/billing/refund_actions.ex] [VERIFIED: accrue/lib/accrue/processor/braintree.ex] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex]

### Pattern 1: Context-Owned Refund Mutation

**What:** Keep refund initiation in `Accrue.Billing`, not in LiveView or adapter code. [VERIFIED: accrue/lib/accrue/billing.ex] [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex]

**When to use:** For every operator-triggered or internal refund issuance path. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md]

**Example:**
```elixir
def refund(charge, opts \\ []) do
  span_billing(:refund, :create, charge, opts, fn ->
    RefundActions.create_refund(charge, opts)
  end)
end
```
Source pattern: [VERIFIED: accrue/lib/accrue/billing.ex]

### Pattern 2: Child Refund Facts, Parent Sale Truth

**What:** Persist refunds as first-class child rows and derive summaries rather than netting the parent charge/invoice status. [VERIFIED: accrue/lib/accrue/billing/refund.ex] [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex]

**When to use:** For partial refunds, repeated refunds, refund decline handling, and operator read models. [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md]

**Example:**
```elixir
%Refund{}
|> Refund.changeset(%{
  charge_id: charge.id,
  processor_id: canonical_id,
  stripe_id: canonical_id
})
```
Source pattern: [VERIFIED: accrue/lib/accrue/billing/refund.ex]

### Pattern 3: Fetch-Driven Convergence With Deferral

**What:** Use webhook/event inputs as triggers to refetch canonical provider state, then upsert locally with stale-event and orphan deferral protection. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]

**When to use:** For any Braintree refund lifecycle signal that exists, and for explicit reconcile/backfill paths where no webhook exists. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]

**Example:**
```elixir
with {:ok, canonical} <- Processor.__impl__().fetch(:refund, processor_id),
     {:ok, updated} <- upsert_refund(row, canonical, evt_ts, evt_id) do
  {:ok, updated}
end
```
Source pattern: [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]

### Anti-Patterns to Avoid

- **Webhook-only card refund convergence:** Official Braintree docs do not document generic card refund transaction webhooks, so planner tasks must not assume them. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]
- **Refunding by voiding or voiding by refunding:** Braintree draws a hard line between pre-settlement voids and settled/settling refunds. [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] [CITED: https://developer.paypal.com/braintree/docs/reference/general/statuses/]
- **Plan swap by `plan_id` only:** Official Braintree docs say updating `plan_id` does not automatically change subscription price and cross-cycle swaps are constrained. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/ruby/]
- **Treating downgrade credits as refunds:** Official Braintree docs say downgrade prorations are applied to subscription balance and do not issue a payment-method refund. [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/recurring-advanced-settings] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Refund gateway call | Custom HTTP client to Braintree refund endpoint | `Braintree.Transaction.refund/3` through `Accrue.Processor.Braintree` | The repo already ships the SDK and its refund entrypoint. [VERIFIED: accrue/deps/braintree/lib/transaction.ex] |
| Webhook signature verification | Custom signature parser/validator | `Braintree.Webhook.parse/3` plus existing XML decode path | The repo already verifies webhook signatures this way, matching project security constraints. [VERIFIED: accrue/lib/accrue/webhook/signature.ex] [VERIFIED: accrue/deps/braintree/lib/webhook.ex] |
| Manual Braintree invoice preview engine | Fake "upcoming invoice" implementation for Braintree | Explicit unsupported error for `preview_upcoming_invoice/2` on Braintree | Locked context explicitly rejects a manual preview engine in this phase. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md] |
| Synthetic netted refund status machine | Custom merged `Charge`/`Invoice` status model | Child `Refund` facts + derived read-model rollups | Multiple partial refunds and asynchronous settlement are simpler and more auditable as separate facts. [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md] |

**Key insight:** The complexity here is not "can Braintree refund?" but "how do we keep local truth honest when refund lifecycle semantics, webhook coverage, and proration behavior diverge from Stripe?" Reusing SDK calls and existing projection patterns is safer than inventing abstraction-heavy parity layers. [VERIFIED: accrue/lib/accrue/processor/braintree.ex] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]

## Common Pitfalls

### Pitfall 1: Assuming refund creation success is final truth

**What goes wrong:** The API call returns success, but later settlement can still fail or settle differently. [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] [CITED: https://developer.paypal.com/braintree/docs/reference/general/statuses/]

**Why it happens:** Braintree models refunds as transactions with their own lifecycle, including settlement-decline paths. [CITED: https://developer.paypal.com/braintree/docs/reference/general/statuses/] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]

**How to avoid:** Persist the initial refund fact, then refetch and reconcile lifecycle truth asynchronously. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue/lib/accrue/jobs/reconcile_refund_fees.ex]

**Warning signs:** Code branches on immediate success only, or no subsequent fetch/reconcile path exists for Braintree refunds. [VERIFIED: accrue/lib/accrue/processor/braintree.ex]

### Pitfall 2: Planning webhook-only refund convergence for Braintree cards

**What goes wrong:** PROC-19 is planned as if Stripe-style refund webhooks exist for all Braintree refunds, leaving card refunds stuck in optimistic local state. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]

**Why it happens:** The transaction webhook docs are easy to over-generalize, but the documented availability is limited to ACH and SEPA Direct Debit sale/refund requests. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]

**How to avoid:** Make reconcile/fetch a first-class part of the Braintree refund design and treat webhook handling as conditional. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]

**Warning signs:** Planner tasks mention only webhook mapping and never mention a Braintree refund retrieve/reconcile loop. [VERIFIED: accrue/lib/accrue/processor/braintree.ex]

### Pitfall 3: Conflating downgrade proration credits with refunds

**What goes wrong:** Subscription mutations appear to "refund" customers when Braintree is actually applying balance credits. [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/recurring-advanced-settings] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/]

**Why it happens:** Stripe invoice-preview mental models encourage treating all mid-cycle credits as refund-like money movement. [VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs]

**How to avoid:** Keep refund and proration codepaths distinct in API, reducer logic, copy, and tests. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md]

**Warning signs:** Charge or invoice rollups try to merge subscription balance credits into `Refund` rows. [VERIFIED: accrue/lib/accrue/billing/invoice_projection.ex]

### Pitfall 4: Trying to emulate Stripe preview semantics for Braintree

**What goes wrong:** The phase grows into a manual invoice/proration calculator with high correctness risk. [VERIFIED: accrue/lib/accrue/billing/upcoming_invoice.ex] [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]

**Why it happens:** `preview_upcoming_invoice/2` already exists for Stripe, so parity pressure can hide the fact that Braintree does not provide the same preview model. [VERIFIED: accrue/lib/accrue/billing/upcoming_invoice.ex]

**How to avoid:** Reject unsupported knobs and keep Braintree preview unsupported in this phase. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md]

**Warning signs:** Planner tasks propose synthetic invoice rows or manual proration math for Braintree. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md]

## Code Examples

Verified patterns from primary sources:

### Braintree Refund Call
```elixir
{:ok, transaction} =
  Braintree.Transaction.refund("txn_id", %{amount: "10.00"})
```
Source: [VERIFIED: accrue/deps/braintree/lib/transaction.ex]

### Braintree Webhook Parse
```elixir
with {:ok, parsed} <- Braintree.Webhook.parse(bt_signature, bt_payload, opts) do
  Braintree.XML.Decoder.load(parsed["payload"])
end
```
Source: [VERIFIED: accrue/deps/braintree/lib/webhook.ex] [VERIFIED: accrue/lib/accrue/webhook/signature.ex]

### Existing Projection-First Refund Upsert
```elixir
with {:ok, canonical} <- Processor.__impl__().fetch(:refund, processor_id),
     {:ok, updated} <- upsert_refund(row, canonical, evt_ts, evt_id) do
  {:ok, updated}
end
```
Source: [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stripe-only refund identity via `stripe_id` | Additive processor-neutral refund identity via `processor_id` while retaining `stripe_id` compatibility | Phase 99 should introduce this now under locked D-12..D-14. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md] | Enables Braintree refunds without destructive refund-schema reset. [VERIFIED: accrue/lib/accrue/billing/refund.ex] |
| Webhook optimism | Fetch/reconcile projection convergence | Already standard in the repo reducer architecture and mandatory for Braintree card refunds. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/] | Reduces stale local truth and handles out-of-order events. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] |
| Generic plan swap optimism | Explicit proration flags plus Braintree-specific update payloads | Current Braintree docs require explicit price update and expose `prorate_charges` / `revert_subscription_on_proration_failure`. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/ruby/] | Planner must scope Braintree `swap_plan/3` narrowly and reject unsupported knobs honestly. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex] |

**Deprecated/outdated:**

- Refund planning that assumes `Accrue.Billing.create_refund/2` is the final public seam is outdated against locked D-01, which names `Accrue.Billing.refund/2` as the canonical seam. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md] [VERIFIED: accrue/lib/accrue/billing.ex]
- Any assumption that Braintree `plan_id` swaps automatically change subscription price is outdated against the official subscription update docs. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/ruby/]

## Assumptions Log

All material claims in this research were verified from the codebase, local dependency source, runtime inspection, or official Braintree/Hex documentation in this session. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] [VERIFIED: https://hex.pm/packages/braintree]

## Open Questions

1. **Should Phase 99 rename the public API immediately or ship `refund/2` as a compatibility alias over `create_refund/2`?**
   - What we know: locked D-01 names `Accrue.Billing.refund/2` as canonical, while the current code only exposes `create_refund/2`. [VERIFIED: .planning/milestones/v1.32-phases/099-refunds-and-invoice-parity/099-CONTEXT.md] [VERIFIED: accrue/lib/accrue/billing.ex]
   - What's unclear: whether docs and tests should flip callers immediately or stage a deprecation. [VERIFIED: accrue/lib/accrue/billing.ex]
   - Recommendation: plan for `refund/2` + `refund!/2` as new public entrypoints, keep `create_refund/2` delegating for v1.x, and update admin to call the canonical name in the same phase. [VERIFIED: accrue/lib/accrue/billing.ex]

2. **How should Braintree card refund convergence be proven for PROC-19 when generic transaction webhooks are not documented for card refunds?**
   - What we know: official docs scope transaction webhooks to ACH and SEPA Direct Debit sale/refund requests; current Braintree event normalization only handles subscription events. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]
   - What's unclear: whether the team wants a scheduled reconcile, post-write refetch, or both as the normative convergence path. [VERIFIED: accrue/lib/accrue/jobs/reconcile_refund_fees.ex]
   - Recommendation: planner should make an explicit choice for card refunds: immediate post-write retrieve plus idempotent periodic reconcile is the safest bounded design. [VERIFIED: accrue/lib/accrue/processor/braintree.ex] [VERIFIED: accrue/lib/accrue/jobs/reconcile_refund_fees.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core implementation and tests | ✓ | `1.19.5` | — |
| Erlang/OTP | Core implementation and tests | ✓ | `28` | — |
| Mix | Build/test workflow | ✓ | `1.19.5` | — |
| PostgreSQL CLI/server | Ecto migration-backed tests | ✓ | `14.17` | — |
| Node.js / npm | Repo tooling and optional docs/frontend build paths | ✓ | `22.14.0` / `11.1.0` | — |
| Braintree SDK dep | Adapter implementation | ✓ | `0.16.0` | — |

All rows above were verified locally with runtime inspection or `mix deps`. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: psql --version] [VERIFIED: node --version] [VERIFIED: npm --version] [VERIFIED: mix deps]

**Missing dependencies with no fallback:**

- None for planning or fake-lane implementation. Live Braintree fidelity was not probed and is not required for the merge-blocking local test lane. [VERIFIED: accrue/test/test_helper.exs] [VERIFIED: .planning/milestones/v1.31-phases/095-official-processor-contract-conformance-harness/095-CONTEXT.md]

**Missing dependencies with fallback:**

- Generic Braintree refund webhook coverage for card refunds has no official-doc evidence; use fetch/reconcile as the fallback convergence mechanism. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto sandbox and Oban manual testing. [VERIFIED: accrue/test/test_helper.exs] [VERIFIED: accrue_admin/test/test_helper.exs] |
| Config file | none; setup is in `accrue/test/test_helper.exs` and `accrue_admin/test/test_helper.exs`. [VERIFIED: accrue/test/test_helper.exs] [VERIFIED: accrue_admin/test/test_helper.exs] |
| Quick run command | `cd accrue && mix test test/accrue/billing/refund_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors` [VERIFIED: accrue/test/accrue/billing/refund_test.exs] [VERIFIED: accrue/test/accrue/processor/braintree_test.exs] |
| Full suite command | `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors` [VERIFIED: .github/workflows/ci.yml] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-18 | Full and partial Braintree refunds work through canonical Billing facade and adapter compatibility path. | unit/integration | `cd accrue && mix test test/accrue/billing/refund_braintree_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors` | ❌ Wave 0 |
| PROC-19 | Braintree refund convergence updates local refund facts and derived charge/invoice truth with explicit non-webhook fallback for card refunds. | integration | `cd accrue && mix test test/accrue/webhook/braintree_refund_convergence_test.exs test/accrue/billing/invoice_projection_braintree_refund_test.exs --warnings-as-errors` | ❌ Wave 0 |
| PROC-18 / PROC-19 operator surface | Charge detail refund flow stays thin, auditable, and copy-honest for Braintree states. | LiveView integration | `cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs --warnings-as-errors` | ✅ extend existing |

### Sampling Rate

- **Per task commit:** run the targeted refund and Braintree adapter tests for the touched seam. [VERIFIED: accrue/test/accrue/billing/refund_test.exs] [VERIFIED: accrue/test/accrue/processor/braintree_test.exs]
- **Per wave merge:** run both package test suites with warnings-as-errors. [VERIFIED: .github/workflows/ci.yml]
- **Phase gate:** full `accrue` + `accrue_admin` suites green before `/gsd-verify-work`. [VERIFIED: .planning/config.json] [VERIFIED: .github/workflows/ci.yml]

### Wave 0 Gaps

- [ ] `accrue/test/accrue/billing/refund_braintree_test.exs` — canonical `refund/2` behavior, partial/refull refund semantics, void-vs-refund guardrails, and compatibility wrapper coverage for PROC-18. [VERIFIED: accrue/lib/accrue/billing.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/]
- [ ] `accrue/test/accrue/webhook/braintree_refund_convergence_test.exs` — applicable webhook normalization plus fetch/reconcile fallback coverage for PROC-19. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]
- [ ] `accrue/test/accrue/billing/invoice_projection_braintree_refund_test.exs` — prove invoice sale-truth preservation plus derived refund rollup expectations. [VERIFIED: accrue/lib/accrue/billing/invoice_projection.ex]
- [ ] Extend `accrue_admin/test/accrue_admin/live/charge_live_test.exs` — Braintree eligibility copy, unsupported-void warning, and derived refund summary assertions. [VERIFIED: accrue_admin/test/accrue_admin/live/charge_live_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Admin refund confirmation already routes through step-up auth in `ChargeLive`; keep that intact for Braintree refunds. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] |
| V3 Session Management | yes | Admin refund execution depends on authenticated LiveView session state and current admin actor context. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] |
| V4 Access Control | yes | Refund issuance must remain inside admin-owned surfaces and Billing context authorization/audit seams. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] [VERIFIED: accrue/lib/accrue/events.ex] |
| V5 Input Validation | yes | Refund amount parsing, proration option validation, and explicit unsupported semantic errors should remain typed and strict. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex] |
| V6 Cryptography | yes | Webhook authenticity must continue to use Braintree signature verification and not custom crypto. [VERIFIED: CLAUDE.md] [VERIFIED: accrue/lib/accrue/webhook/signature.ex] [VERIFIED: accrue/deps/braintree/lib/webhook.ex] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized operator refund | Elevation of Privilege | Keep refund execution behind admin auth + step-up + event audit trail. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] |
| Replay or forged webhook payload | Spoofing / Tampering | Keep mandatory `Braintree.Webhook.parse/3` verification before XML decode. [VERIFIED: accrue/lib/accrue/webhook/signature.ex] [VERIFIED: accrue/deps/braintree/lib/webhook.ex] |
| Out-of-order refund lifecycle overwrite | Tampering | Preserve reducer stale-event checks and orphan deferral pattern when Braintree refund convergence is added. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] |
| Over-refund or invalid partial refund input | Tampering | Enforce amount bounds locally and let provider validation reject excess remaining-balance refunds. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] |
| Sensitive provider payload leakage | Information Disclosure | Keep provider payloads in `data` and follow existing no-raw-PII logging posture from project constraints. [VERIFIED: CLAUDE.md] [VERIFIED: accrue/lib/accrue/billing/refund_actions.ex] |

## Sources

### Primary (HIGH confidence)

- `accrue/lib/accrue/billing.ex` - current public refund seam and lack of `refund/2`. [VERIFIED: accrue/lib/accrue/billing.ex]
- `accrue/lib/accrue/billing/refund_actions.ex` - current refund command, idempotency, and insert pattern. [VERIFIED: accrue/lib/accrue/billing/refund_actions.ex]
- `accrue/lib/accrue/billing/refund.ex` - current refund schema and Stripe-shaped identity fields. [VERIFIED: accrue/lib/accrue/billing/refund.ex]
- `accrue/lib/accrue/processor/braintree.ex` - current unsupported refund callbacks and Braintree capability surface. [VERIFIED: accrue/lib/accrue/processor/braintree.ex]
- `accrue/lib/accrue/webhook/default_handler.ex` - existing reducer, deferral, and Braintree event normalization. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]
- `accrue_admin/lib/accrue_admin/live/charge_live.ex` - existing thin operator refund surface and step-up flow. [VERIFIED: accrue_admin/lib/accrue_admin/live/charge_live.ex]
- `https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/` - official refund requirements and partial refund semantics. [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/]
- `https://developer.paypal.com/braintree/docs/reference/general/statuses/` - official transaction status meanings for void vs refund and settlement decline. [CITED: https://developer.paypal.com/braintree/docs/reference/general/statuses/]
- `https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/` - official transaction webhook availability and refund settlement signals. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]
- `https://developer.paypal.com/braintree/docs/reference/request/subscription/update/ruby/` - official Braintree proration update parameters and plan/price constraints. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/ruby/]

### Secondary (MEDIUM confidence)

- `https://developer.paypal.com/braintree/articles/guides/recurring-billing/recurring-advanced-settings` - proration upgrade/downgrade operational semantics and subscription-balance credit behavior. [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/recurring-advanced-settings]
- `https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/` - subscription balance and negative-balance behavior, refunding subscription transactions. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/]
- `https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription/php` - subscription webhook behavior for proration-created mid-cycle transactions. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription/php]
- `https://hex.pm/packages/braintree` - package version and release date for the Elixir Braintree SDK. [VERIFIED: https://hex.pm/packages/braintree]

### Tertiary (LOW confidence)

- None. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - repo dependencies and local runtime versions were directly verified. [VERIFIED: mix deps] [VERIFIED: elixir --version]
- Architecture: MEDIUM - the repo seams are clear, but Braintree card-refund convergence requires a designed reconcile path because official webhook coverage is narrower than Stripe's. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/]
- Pitfalls: HIGH - the main failure modes are explicit in official Braintree docs and visible in the current Stripe-shaped code. [VERIFIED: accrue/lib/accrue/processor/braintree.ex] [CITED: https://developer.paypal.com/braintree/docs/reference/request/transaction/refund/ruby/] [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/recurring-advanced-settings]

**Research date:** 2026-04-30
**Valid until:** 2026-05-30 for repo structure; re-check Braintree docs sooner if the plan starts depending on webhook coverage or subscription-update parameter details. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/transaction/node/] [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/ruby/]
