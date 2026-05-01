# Phase 98: Payment Method CRUD & Operator Admin - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 98 extends the shipped Braintree slice from Phase 96 and the subscription-mutation work in Phase 97 into **payment-method management** for both the public `Accrue.Billing` facade and the companion `AccrueAdmin` customer payment-method surface.

This phase should make Braintree payment methods **manageable without lying**:
- developers can add, replace, list, delete, and set default payment methods through an honest public facade
- operators can see and perform the narrow management actions that fit AccrueAdmin's role
- local projections stay coherent with provider truth
- destructive flows are guarded against Braintree-specific footguns

This phase does **not** broaden into:
- generic checkout parity
- billing-portal parity
- raw-card capture inside `accrue_admin`
- pretending Stripe and Braintree payment-method semantics are identical
- a finance/accounting expansion

</domain>

<decisions>
## Implementation Decisions

### Public facade contract

- **D-01:** Phase 98 should move the payment-method public surface toward **honest CRUD verbs** instead of leaning on Stripe-shaped `attach` semantics for Braintree.
- **D-02:** The preferred public shape is: `add_payment_method/3`, `update_payment_method/3`, `delete_payment_method/2`, `set_default_payment_method/3`, and `list_payment_methods/2`.
- **D-03:** `list_payment_methods/2` should become a **local-row-first** read model for app/admin ergonomics rather than a provider-live-only inventory call.
- **D-04:** Braintree add/update flows should accept **one narrow `vault_acquisition` handoff payload** rather than leaking raw provider vocabulary throughout the facade.
- **D-05:** Braintree “update payment method” should be documented and implemented as **replacement-oriented semantics**, not as a fake universal in-place card edit.
- **D-06:** Existing Stripe-shaped `attach` / `detach` seams may remain temporarily for compatibility, but Phase 98 planning should treat the new CRUD verbs as the long-term canonical contract.

### Projection and source-of-truth posture

- **D-07:** Accrue should stay **projection-first** for payment-method inventory: local `PaymentMethod` rows remain the primary read model for `AccrueAdmin` and host-facing reads.
- **D-08:** Braintree remains the **write authority**. After add, delete, set-default, or replacement flows, Accrue should immediately **refetch canonical provider state and re-project locally**.
- **D-09:** Phase 98 should include an explicit **reconcile/resync path** for payment-method drift because Braintree's payment-method webhook surface is not rich enough to guarantee full convergence from webhooks alone.
- **D-10:** The payment-method read model should stay fast and local for Phoenix/LiveView ergonomics; provider-live reads should be reserved for write-through refreshes, reconciliation, or explicitly scoped operator recovery actions.
- **D-11:** Phase 98 must not collapse customer default truth and subscription-funding truth into one naive flag. Braintree customer default changes do **not** automatically migrate existing subscriptions to the new token.

### Operator surface in `AccrueAdmin`

- **D-12:** `AccrueAdmin` should remain a **narrow operator control plane**, not a provider-specific browser tokenization app.
- **D-13:** The customer payment-method tab should support **inventory + explicit set-default** as a first-class operator action.
- **D-14:** Delete should be treated as a **high-risk operator action** with strong guardrails and explicit impact messaging, not as a casual row action.
- **D-15:** Adding or replacing a Braintree payment method should stay **host-assisted / host-owned** at the browser seam rather than embedding Braintree JS / Drop-in directly into `accrue_admin`.
- **D-16:** If operators need to help repair a customer payment method, the preferred experience is a **tightly scoped handoff** from admin to a host-managed flow, not raw payment entry inside the admin package.
- **D-17:** `AccrueAdmin` copy and UI should explain the operator/customer boundary clearly so users understand why some actions happen in admin and others require a host-side billing flow.

### Delete and default semantics

- **D-18:** Phase 98 should use **explicit replacement + guarded delete**, not best-effort fallback magic and not raw provider passthrough semantics.
- **D-19:** `set_default_payment_method/3` should remain an explicit command. Default changes should never be inferred implicitly from row order or “last remaining method” heuristics.
- **D-20:** Deleting a **non-default** payment method is allowed only when Phase 98 can prove the token is not still funding an active Braintree subscription, or when the system can safely repoint that dependency first.
- **D-21:** Deleting the **default** payment method should require an explicit replacement when another usable payment method exists; the system should not silently pick a fallback default.
- **D-22:** Clearing a customer to “no default payment method” is acceptable only when it is the **last** method and no active dependency blocks removal.
- **D-23:** Phase 98 should not mirror raw Braintree deletion semantics through the public facade because raw delete can cancel associated subscriptions immediately. Accrue must guard this behavior deliberately.
- **D-24:** Error policy should distinguish:
  - unsupported capability (`processor_operation_unsupported`)
  - replacement required
  - payment method still in use
  - stale/conflict state
  - provider/API failure
- **D-25:** Local truth should continue to anchor on `Customer.default_payment_method_id`; any `PaymentMethod.is_default` field should be treated as derived or updated in the same transaction to avoid drift.

### Elixir / Phoenix / Ecto posture

- **D-26:** The public billing surface should stay **context-style and explicit**: validated attrs, narrow handoff structs/maps, tuple returns, and persistence-backed read models.
- **D-27:** Phase 98 should prefer **`Ecto.Multi` / transactional local commits + provider write-through + explicit resync** over hidden side effects or UI-only state assumptions.
- **D-28:** LiveView actions should stay **server-driven and auditable** for default/delete operator flows. Browser tokenization remains a separate host concern.
- **D-29:** Accrue should learn from successful ecosystems by keeping the shared surface **bounded and honest**:
  - from **Laravel Cashier**: clear billable verbs, explicit destructive-payment-method warnings
  - from **Pay (Rails)**: bounded multi-processor support with visible divergence
  - avoid the **ActiveMerchant** footgun: over-broad gateway sameness that hides real processor differences

### Shift-left preference for future GSD passes

- **D-30:** For future processor-track GSD discuss/planning workflows, low-impact implementation choices should be **researched and auto-synthesized into recommendations by default** rather than escalated interactively.
- **D-31:** Reopen choices interactively only when they materially change:
  - public API shape
  - first-party support promise
  - destructive-state semantics
  - operator/security boundary
  - long-term proof-lane philosophy
- **D-32:** Future recommendation bundles should continue to optimize for:
  - least surprise
  - honest support boundaries
  - host-owned browser seams
  - projection-first Phoenix ergonomics
  - explicit state transitions
  - strong DX and clear user/operator copy

### the agent's Discretion

- Exact compatibility/deprecation path for old Stripe-shaped payment-method facade helpers once honest CRUD verbs land.
- Exact shape of the `vault_acquisition` payload as long as it remains narrow, provider-honest, and host-owned at the browser seam.
- Whether `update_payment_method/3` is exposed as a first-class helper or implemented as orchestrated add + set-default + optional cleanup behind a clearer higher-level command.
- Exact reconciliation trigger shape (explicit admin “sync now”, job, write-through helper, or a combination) as long as projection-first truth remains intact.
- Exact admin copy, warning hierarchy, and confirmation UX for destructive flows.

</decisions>

<specifics>
## Specific Ideas

- The most coherent Phase 98 story is:
  - host-owned Braintree vault acquisition
  - honest CRUD verbs on `Accrue.Billing`
  - local payment-method projection as the default UI/read model
  - write-through refetch + explicit reconcile for drift
  - narrow `AccrueAdmin` mutations (`set_default`, guarded delete)
  - host-assisted add/replace flows instead of raw-card admin capture
  - explicit replacement semantics instead of pretending universal in-place card edits

- Important Braintree realities to preserve:
  - customer default changes do **not** automatically update existing subscriptions
  - payment-method deletion can have destructive subscription consequences
  - update flows are often better modeled as replacement via a new vaulted reference

- DX principle:
  - developers should not need to memorize Braintree footguns to use the public facade safely
  - operators should not be given buttons whose real effect is more dangerous than the UI implies

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone and locked context

- `.planning/milestones/v1.32-ROADMAP.md` — Phase 98 goal and success criteria
- `.planning/milestones/v1.32-REQUIREMENTS.md` — `PROC-16`, `PROC-17`
- `.planning/PROJECT.md` — active processor-track posture and product boundaries
- `.planning/STATE.md` — active milestone status
- `.planning/processor-support-matrix.md` — support-label SSOT and current out-of-slice posture
- `.planning/milestones/v1.31-phases/095-official-processor-contract-conformance-harness/095-CONTEXT.md` — executable support-boundary and unsupported-operation posture
- `.planning/milestones/v1.31-phases/096-chosen-second-provider-thin-slice/96-CONTEXT.md` — locked host-owned vault-acquisition and proof-surface posture
- `.planning/milestones/v1.24-phases/77-customer-pm-tab-verify-theme-copy-export/77-CONTEXT.md` — prior customer payment-method tab UX / VERIFY / copy posture

### Public facade and processor seams

- `accrue/lib/accrue/billing.ex` — current public payment-method facade
- `accrue/lib/accrue/billing/payment_method_actions.ex` — current write/list semantics and guard behavior
- `accrue/lib/accrue/billing/payment_method.ex` — local payment-method projection schema
- `accrue/lib/accrue/billing/customer.ex` — customer default-payment-method relationship
- `accrue/lib/accrue/processor.ex` — adapter contract
- `accrue/lib/accrue/processor/capabilities.ex` — support labels and first-party capability gating
- `accrue/lib/accrue/processor/braintree.ex` — current Braintree unsupported PM surface
- `accrue/lib/accrue/webhook/default_handler.ex` — projection/refetch webhook posture
- `accrue/lib/accrue/errors.ex` — current error taxonomy

### Admin and host seams

- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — current customer payment-method tab
- `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` — current copy surface
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` — customer payment-method tab assertions
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` — current host-owned Braintree vault-acquisition UI seam
- `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs` — current Braintree host/facade proof
- `examples/accrue_host/README.md` — current host proof story and support-language mirror

### External references that informed these decisions

- `https://developer.paypal.com/braintree/docs/guides/payment-methods/` — Braintree payment-method lifecycle and defaults
- `https://developer.paypal.com/braintree/docs/reference/request/payment-method/update/ruby/` — update semantics and nonce caveats
- `https://developer.paypal.com/braintree/docs/reference/request/customer/update/ruby/` — customer default payment-method updates
- `https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node/` — destructive delete semantics
- `https://developer.paypal.com/braintree/docs/reference/general/webhooks/payment-method` — limited payment-method webhook surface
- `https://developer.paypal.com/braintree/articles/guides/recurring-billing/subscriptions` — subscription/payment-method behavior coupling
- `https://laravel.com/docs/12.x/billing` — Cashier lessons for bounded billing verbs and destructive warnings
- `https://github.com/pay-rails/pay` — bounded multi-processor support posture
- `https://github.com/activemerchant/active_merchant` — cautionary gateway-sameness example
- `https://hexdocs.pm/phoenix_live_view` — LiveView server-driven mutation patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Billing` already has payment-method facade seams, telemetry wrapping, and tuple-returning ergonomics that Phase 98 can extend.
- `PaymentMethodActions` already embodies provider write + local persistence patterns that can be evolved into the Phase 98 CRUD contract.
- `Customer.default_payment_method_id` already provides a strong local anchor for explicit default-state semantics.
- `DefaultHandler` already models a refetch-and-project posture that Phase 98 can reuse for payment-method reconciliation.
- `CustomerLive` already provides the mounted customer payment-method operator surface and copy-backed rendering.
- The host example already has a working Braintree vault-acquisition seam that proves the project prefers host-owned browser tokenization.

### Established Patterns

- Support truth is documented and executable together (`processor-support-matrix` + capability map + tests).
- Unsupported processor operations fail clearly rather than silently falling back to Stripe assumptions.
- The repo prefers local Ecto projections for admin/operator reads instead of provider-live page rendering.
- Browser payment acquisition for Braintree is host-owned, while admin remains a narrower mounted operator surface.
- Fake remains the deterministic proof lane; provider-specific flows are bounded and explicit.

### Integration Points

- Phase 98 should connect new payment-method CRUD work to the existing Braintree host seam rather than replacing it.
- Admin mutation UX must fit the current customer payment-method tab and its VERIFY/copy discipline.
- Any new default/delete logic must integrate with existing customer/subscription projections and error taxonomy.
- Planning should treat reconciliation, guardrails, and support-language updates as coupled work, not as separate cleanups.

</code_context>

<deferred>
## Deferred Ideas

- Embedding Braintree Drop-in or raw card-entry UX directly into `accrue_admin`
- Generic provider-live payment-method inventory as the default read path
- Automatic fallback-default magic after deletion
- Pretending payment-method updates are universal in-place mutations across processors
- Full checkout parity or billing-portal parity
- Broad payment-method UX beyond the bounded first-party Braintree/Stripe story

</deferred>

---

*Phase: 098-payment-method-crud-operator-admin*
*Context gathered: 2026-04-30*
