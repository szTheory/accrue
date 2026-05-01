# Phase 99: Refunds and Invoice Parity - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 99 extends the active Braintree slice into **refunds and refund-driven local truth**.

This phase should make Braintree refunds **usable and honest**:
- a Braintree-backed charge can be refunded through the public billing facade
- operators have a narrow first-party refund action in `AccrueAdmin`
- local `Refund`, `Charge`, and `Invoice` projections converge on Braintree transaction truth without pretending Stripe and Braintree refund semantics are identical
- refund behavior stays clearly separated from Braintree subscription-balance prorations

This phase does **not** broaden into:
- a broad finance/reporting workspace in `AccrueAdmin`
- customer self-serve refunds
- fake Stripe/Braintree sameness for refund or proration semantics
- a full processor-neutral billing ledger rewrite
- a manual invoice-preview engine for Braintree

</domain>

<decisions>
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

</decisions>

<specifics>
## Specific Ideas

- The most coherent Phase 99 story is:
  - public billing context owns refund creation
  - `AccrueAdmin` exposes one narrow charge-detail refund action
  - Braintree refunds are modeled as child refund facts, not as rewritten sale truth
  - invoices remain sale-cycle projections
  - operator surfaces show gross sale state plus refund progress, not one fake merged status
  - refund identity starts moving toward processor-neutral naming now
  - refund fee-field over-normalization waits until there is a real cross-processor reporting need
  - Braintree proration credits remain distinct from explicit refunds

- Important Braintree realities to preserve:
  - refunds only apply to `settling` / `settled` transactions
  - multiple partial refunds are supported
  - the initial refund success response is not the full lifecycle truth
  - downgrade prorations become subscription-balance credits, not card refunds

- DX principle:
  - developers should not have to guess whether a Braintree refund is “real,” “pending settlement,” or “just a Stripe-shaped abstraction”
  - operators should not be shown a refund button that silently means “maybe refund, maybe void, maybe credit”

- User preference captured:
  - future GSD processor-track passes should shift low-impact design decisions left into coherent recommendation bundles
  - only materially strategic choices should come back interactively

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone and locked context

- `.planning/milestones/v1.32-ROADMAP.md` — Phase 99 goal and success criteria
- `.planning/milestones/v1.32-REQUIREMENTS.md` — `PROC-18`, `PROC-19`
- `.planning/STRATEGY.md` — active processor-track posture and support-boundary rules
- `.planning/PROJECT.md` — project-level product posture and current milestone framing
- `.planning/STATE.md` — active milestone and execution position
- `.planning/milestones/v1.31-phases/094-strategy-capability-matrix-target-lock/094-CONTEXT.md` — locked provider/slice/support-posture decisions
- `.planning/milestones/v1.31-phases/095-official-processor-contract-conformance-harness/095-CONTEXT.md` — locked support-boundary and fail-clearly posture
- `.planning/milestones/v1.31-phases/096-chosen-second-provider-thin-slice/96-CONTEXT.md` — locked Braintree slice posture
- `.planning/milestones/v1.32-phases/098-payment-method-crud-operator-admin/098-CONTEXT.md` — current operator-surface and projection-first posture

### Refund and projection code

- `accrue/lib/accrue/billing.ex` — public refund facade boundary
- `accrue/lib/accrue/billing/refund_actions.ex` — current refund write path and idempotency/event posture
- `accrue/lib/accrue/billing/refund.ex` — persisted refund schema and current Stripe-shaped naming
- `accrue/lib/accrue/billing/charge.ex` — sale-truth projection anchor
- `accrue/lib/accrue/billing/invoice_projection.ex` — current Braintree invoice projection path
- `accrue/lib/accrue/webhook/default_handler.ex` — refund and projection reducers
- `accrue/lib/accrue/jobs/reconcile_refund_fees.ex` — current refund fee reconciliation posture
- `accrue/lib/accrue/events/schemas.ex` — refund event taxonomy
- `accrue/lib/accrue/processor.ex` — processor refund callbacks
- `accrue/lib/accrue/processor/braintree.ex` — current Braintree adapter and unsupported refund surface

### Proration and adjacent lifecycle semantics

- `accrue/lib/accrue/billing/subscription_actions.ex` — explicit proration contract and Braintree lifecycle seam
- `accrue/lib/accrue/billing/subscription_items.ex` — explicit proration contract on item mutations
- `accrue/lib/accrue/billing/upcoming_invoice.ex` — preview model that should remain unsupported for Braintree
- `accrue/test/accrue/billing/swap_plan_test.exs` — explicit-proration regression contract
- `accrue/test/accrue/billing/proration_roundtrip_test.exs` — current local proration proof posture
- `accrue/test/live_stripe/proration_fidelity_live_test.exs` — Stripe-only preview fidelity precedent

### Admin and operator seams

- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — current admin operator surface patterns
- `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` — copy-backed operator posture precedent
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` — LiveView verification precedent for operator flows

### External references that informed these decisions

- `https://developer.paypal.com/braintree/docs/reference/request/transaction/refund` — Braintree refund requirements and repeated partial-refund behavior
- `https://developer.paypal.com/braintree/articles/guides/refund-authorizations/` — refund request success vs later lifecycle reality
- `https://developer.paypal.com/braintree/articles/control-panel/transactions/refunds-voids-credits/` — void vs refund semantics and operator-facing posture
- `https://developer.paypal.com/braintree/docs/reference/general/statuses/` — Braintree status model
- `https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription/` — proration-triggered subscription transaction behavior
- `https://developer.paypal.com/braintree/articles/guides/recurring-billing/recurring-advanced-settings` — downgrade proration credit semantics
- `https://laravel.com/docs/12.x/billing` — bounded, polished provider-facing billing facade lessons
- `https://github.com/pay-rails/pay` — honest multi-processor support posture
- `https://github.com/activemerchant/active_merchant` — cautionary abstraction-breadth example

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Billing.RefundActions` already provides the canonical refund write seam, idempotency handling, and event recording pattern.
- `DefaultHandler` already provides webhook-first reducer structure with deferred out-of-order handling patterns.
- `InvoiceProjection` already has a Braintree branch, giving Phase 99 an existing projection seam to evolve rather than replace.
- `Charge` / `Invoice` already use processor-neutral identity fields, which gives refunds a clear additive normalization target.
- `AccrueAdmin` already has LiveView operator-surface, copy-export, and server-driven mutation patterns Phase 99 can reuse.

### Established Patterns

- The repo prefers **projection-first reads** and **webhook-backed convergence** over provider-live page rendering.
- Public support truth is documented and executable together.
- Unsupported processor semantics fail clearly instead of silently degrading into Stripe assumptions.
- Brownfield changes are safer when they are additive and compatibility-preserving through v1.x.

### Integration Points

- Phase 99 should connect refund creation, refund webhook convergence, charge/invoice read-model rollups, and narrow admin operator UX as one coupled slice.
- Refund data-model work should stay tightly scoped to additive neutral identity hardening plus Braintree support, not full billing-ledger redesign.
- Proration and refund work must remain coherent: Braintree proration credits should not leak into refund projections or operator copy as if they were card refunds.

</code_context>

<deferred>
## Deferred Ideas

- A broad refund reporting workspace in `AccrueAdmin`
- Customer self-serve refund UX
- Full refund-schema normalization and removal of all Stripe-shaped fee fields during v1.x
- A processor-transaction-ledger rewrite as the primary local billing truth
- A Braintree manual invoice-preview engine
- Coercing unsupported Braintree proration semantics into fake Stripe parity

</deferred>

---

*Phase: 099-refunds-and-invoice-parity*
*Context gathered: 2026-04-30*
