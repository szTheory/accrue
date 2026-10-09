# Phase 235: Customer Plan Selection & Checkout - Context

**Gathered:** 2026-10-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the existing customer offer-selection and checkout journeys understandable and reliable through the payment integrations already supported by Accrue. Customers must see the selected offer and trustworthy charge terms, preserve that choice through sign-in and safe return, and receive accurate outcomes for completion, validation, cancellation, expiry, provider failure, and uncertainty. Keep provider-hosted checkout separate from mounted secure fields and preserve existing host, processor, and authorization boundaries.

This phase refines existing checkout and host billing-entry paths. It does not add a generic plan catalog, new payment capability or processor, new billing policy, custom card collection, or a new account-selection model. Broader Portal self-service belongs to Phase 236; cross-surface closeout belongs to Phase 239.

</domain>

<decisions>
## Implementation Decisions

GSD `--auto` selected the documented recommended defaults for these areas. The phase requirements and accepted Phase 233 contract already settle the product boundaries; no new preference was needed from the user.

### Selected offer and charge terms

- **D-01:** Show the offer selected by the existing host flow. Use its trusted session/catalog metadata for the plan name, amount, currency, interval, and other supported charge terms; do not infer terms from a price identifier, a default, or a browser return parameter.
- **D-02:** If a material charge term is missing or ambiguous, identify it as unavailable and provide a safe recovery path. Do not turn missing data into a free price, guess an amount, or enable payment for an unknown charge. Keep plan discovery host-owned; do not create a generic Accrue catalog API in this phase.

### Sign-in, provider handoff, and return

- **D-03:** Preserve the exact selected offer and the displayed billable, Customer, and processor through sign-in and return. Revalidate the same context and action when the customer resumes. A context pin is an identity locator, not a lasting authorization grant; the host remains authoritative for actor, billable, membership, and action permission.
- **D-04:** Keep processor-supported paths distinct: provider-hosted checkout stays provider-owned, while mounted checkout uses the existing supported Hosted Fields integration. Do not imply provider parity from Fake-backed evidence, replace the official payment SDK, or use a return URL/query parameter as proof of payment.
- **D-05:** Use validated host/local return destinations and the existing safe fallback behavior. A completion state is shown only after server/provider evidence supports it; cancellation, unavailable return, and blocked context remain distinct outcomes.

### Failure, retry, and recovery

- **D-06:** Re-read session state and freshly authorize the same customer/provider/offer before an irreversible action. Represent invalid input, stale promotion, expiry, completed session, provider rejection, cancellation, and ambiguous outcome according to their evidence; do not collapse them into a success-like message.
- **D-07:** Never automatically replay an uncertain payment. Clear single-use nonce and secure-field state on failure, abandonment, or context invalidation. Permit another attempt only after authoritative state permits it and the customer starts a fresh action.
- **D-08:** Apply the project shift-left default: give every testable acceptance claim deterministic executable evidence, retain automated UAT results, and run checks in merge-blocking CI when they protect recurring behavior. Skip confirmation-only UAT when passing evidence covers the claim. Hand off only an actual product decision, unavailable external setup, irreversible external action, or irreducible subjective judgment.

### the agent's Discretion

- Choose the smallest session/form mechanism that preserves the existing selected offer and pinned context across the current host sign-in and return flow; do not add a public callback or dependency without concrete evidence that the existing boundary cannot serve it.
- Choose component boundaries, exact concise copy, and test layering. Keep accessible focus/status behavior, current host branding, secure SDK lifecycle, and evidence-specific payment outcomes intact.
- Determine which checkout assertions belong in unit/LiveView tests, host integration tests, browser tests, and recurring CI based on the observed seam and maintenance value.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary, requirements, and accepted product decisions

- `.planning/ROADMAP.md` §Phase 235 — phase goal, dependencies, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — CKO-01 through CKO-04; related POR-04/POR-05, SAFE-02/SAFE-03, and SHIP-01 boundaries.
- `.planning/PROJECT.md` §§Development Posture, Current Milestone v1.63, Verification posture — stable-core constraints, existing journey scope, provider boundaries, and shift-left default.
- `.planning/phases/233-shared-direction-portal-contract/233-CONTEXT.md` — accepted host resolve/authorize contract, separate actor/billable/Customer/processor identity, pinned form context, safe returns, visual roles, and secure payment SDK boundary.
- `.planning/phases/233-shared-direction-portal-contract/233-UI-SPEC.md` — shared semantic visual roles and UI acceptance contract.
- `.planning/phases/234-admin-customers-subscriptions/234-CONTEXT.md` — current milestone UI/accessibility and evidence conventions; do not pull Admin-only scope into checkout.
- `.planning/notes/2026-10-07-accrue-ui-refinement-scope.md` §§2, 4–9, 12 — current-source checkout findings, phase allocation, requirements, visual/accessibility guidance, automation posture, and evidence index.
- `.planning/notes/2026-10-07-portal-billable-context-contract.md` §§Recommendation, Small integration contract, Permission and lifecycle rules, Hosted sessions are grants of capability, Customer experience, and Milestone implications.
- `.planning/processor-support-matrix.md` — supported processor-specific checkout capabilities and limits.
- `PRODUCT.md` — actor, customer, host, and product boundaries.

### Checkout implementation and example-host seams

- `accrue_portal/lib/accrue_portal/live/checkout_live.ex` — mounted checkout rendering, session readiness, pricing, promotion validation, and LiveView submission behavior.
- `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` — POST completion, pinned-context authorization, session/offer checks, subscription call, and return behavior.
- `accrue_portal/priv/static/accrue_portal.js` — current Braintree Hosted Fields attach/tokenize/submit/teardown lifecycle.
- `accrue_portal/lib/accrue_portal/context.ex`, `customer_session.ex`, `auth_plug.ex`, and `auth_hook.ex` — host context pinning and independent HTTP/LiveView authorization boundaries.
- `accrue/lib/accrue/checkout/local_session.ex` and `accrue/lib/accrue/plan_resolver.ex` — persisted checkout session state and plan metadata contract.
- `examples/accrue_host/lib/accrue_host/billing/plan_resolver.ex` and `billing/plans.ex` — host-owned selected offers and available name/amount/currency/interval data.
- `accrue_portal/test/accrue_portal/live/checkout_live_test.exs`, `checkout_live_discount_test.exs`, and `checkout_context_test.exs` — existing session, discount, and context coverage.
- `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js` — current browser proof pattern for mounted provider checkout.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `AccruePortal.Live.CheckoutLive` already renders the mounted checkout, promotion state, current session amount, secure Hosted Fields, cancellation navigation, and a LiveView submission fallback.
- `AccruePortal.Controllers.CheckoutController` re-resolves the pinned host context on POST, checks the exact Customer/processor/offer and open unexpired session, authorizes the action, then calls the existing billing facade.
- `BraintreeHostedFields` in `accrue_portal/priv/static/accrue_portal.js` handles SDK initialization, tokenization, disabled submit, duplicate-submit prevention, nonce cleanup, and teardown.
- The canonical host's `Billing.Plans` and `Billing.PlanResolver` provide host-owned labels plus trusted price, amount, currency, interval, and processor metadata for the example journey.
- Existing Portal checkout tests and `phase233-braintree-checkout.spec.js` are the starting points for deterministic checkout and browser coverage.

### Established Patterns

- Initial HTTP, LiveView mount/reconnect/events, and POST paths are separate boundaries; each protected mutation re-resolves host context and must authorize the exact displayed target.
- Hosted provider checkout and mounted Braintree checkout have distinct capabilities and result paths. Their proof and copy must remain capability-explicit.
- `LocalSession` is the server-side checkout authority. A URL, client event, display preview, or nonce alone is not evidence that a subscription or charge completed.
- Portal package assets are served from the package's checked-in static output; an unrelated Admin build does not prove the served Portal asset is current.
- No `.planning/codebase/` maps were present; source scouting used the current Portal and canonical host files named above.

### Integration Points

- Host plan selection and sign-in feed a persisted checkout session, which the Portal renders and later revalidates for mounted LiveView or POST completion.
- Customer, billable owner, actor, configured processor, and chosen offer must remain distinct across the flow.
- Processor callbacks and redirects return to host/Portal destinations under existing validation; only authoritative server/provider state changes the displayed result.
- Form hooks, CSP/SRI, package JS/CSS output, mounted routes, and browser tests must agree on the exact source that is served.

</code_context>

<specifics>
## Specific Ideas

- In the example host, plan labels and terms already come from `Billing.Plans`; a raw identifier such as `price_pro` is not a customer-facing plan name.
- Prove the actual visible checkout form and its browser hook. A static render or direct controller call alone cannot establish that secure fields tokenize and reach the intended transport.
- Keep the proof bounded to relevant offer, provider, sign-in/return, keyboard, narrow viewport, and failure states. Do not multiply every route by every theme and viewport when the same behavior can be covered once at the owning seam.

</specifics>

<deferred>
## Deferred Ideas

- No new product capability was added to Phase 235. A generic plan-discovery/catalog API, new payment processor, dynamic processor routing, custom card fields, new pricing policy, or broad account-selection model remains out of scope.
- Broader Portal payment-method/subscription/invoice self-service is owned by Phase 236; integrated cross-surface coverage and handoff is owned by Phase 239.

</deferred>

---

*Phase: 235-customer-plan-selection-checkout*
*Context gathered: 2026-10-07*
