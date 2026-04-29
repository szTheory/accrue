# Phase 96: Chosen second-provider thin slice - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 96 proves one real **Braintree-backed** billing path through the documented public facade and updates Accrue's public support story so adopters can see exactly what is now official versus still deferred.

The slice is intentionally narrow:
- `Accrue.Billing.subscribe/3` is the primary public-facade proof path.
- The supported capability family remains **gateway subscription core**.
- `Stripe` remains the default first-user path.
- `create_checkout_session/2` and `create_billing_portal_session/2` remain **Stripe-only**.

This phase does **not** broaden the official first-party slice into generic processor parity, payment-method CRUD parity, checkout parity, portal parity, or a second full proof lane.

</domain>

<decisions>
## Implementation Decisions

### Payment-method handoff

- **D-01:** Braintree payment-method acquisition should stay **host-owned** at the browser/UI seam. Accrue should not absorb Braintree JS, browser tokenization, or a fake universal checkout abstraction into the core library.
- **D-02:** The public server-side contract should use **one narrow handoff reference** from the supported vault-acquisition flow rather than leaking raw provider jargon like `client_token`, `payment_method_nonce`, or `device_data` throughout the generic facade.
- **D-03:** Phase 96 should not route this story through payment-method inventory or CRUD surfaces. `payment_method.vault_acquisition` is in-slice; payment-method listing and broader CRUD remain out-of-slice unless already needed internally by the narrow path.

### `subscribe/3` contract shape

- **D-04:** `Accrue.Billing.subscribe/3` remains the primary public subscription contract for the second-provider slice.
- **D-05:** Phase 96 should preserve `subscribe/3` as the semantic "create subscription" call and avoid widening it into provider-keyword soup.
- **D-06:** If Phase 96 needs an additional public seam, prefer **one narrow preparatory helper for vault-acquisition handoff** over provider-specific alternate subscription APIs or raw Braintree-shaped `subscribe/3` opts.
- **D-07:** Phase 96 should not invent fake Stripe/Braintree sameness for return values. The Braintree-backed path should be honest about its narrower behavior as long as the documented public contract stays coherent.

### Proof surface

- **D-08:** `examples/accrue_host` should be the **only real Braintree proof surface** for the first official provider-backed slice.
- **D-09:** The installer-generated host should remain a **thin boundary/smoke surface**: generated facade shape, compile/install smoke, and docs/verifier needles. It should not become a second full Braintree proof lane.
- **D-10:** Provider-backed Braintree proof should stay **narrow and advisory**, consistent with the current Fake-first proof posture. Fake remains the merge-blocking SSOT for the supported slice.

### Public positioning

- **D-11:** Public messaging should be **matrix-led and docs-mirrored**. The canonical support truth remains `.planning/processor-support-matrix.md`, with concise mirrored language in package docs and example-host docs.
- **D-12:** The wording should explicitly state: Stripe remains the default first-user path; Braintree is now official for the **gateway subscription core** slice; Checkout and Billing Portal remain **Stripe-only**; staged/deferred rows stay visibly distinct from supported rows.
- **D-13:** Phase 96 should avoid any README or guide wording that implies generic “Braintree support” without naming the supported slice.

### GSD shift-left defaults

- **D-14:** For future processor-track GSD discuss/planning passes, default to **research-backed recommendation synthesis** for low-impact implementation choices instead of escalating them interactively.
- **D-15:** Reopen choices interactively only when they materially change product boundary, public support promise, proof-lane philosophy, or long-term API surface.
- **D-16:** Future discuss phases should bias toward recommendations that preserve least surprise, honest support boundaries, bounded first-party promises, host-owned UI seams, and Phoenix-idiomatic context boundaries.

### the agent's Discretion

- Exact name and shape of the narrow handoff reference passed into the supported Braintree-backed subscription path.
- Whether Phase 96 needs a small public preparatory helper now or can keep the first pass entirely host-driven while still documenting the contract clearly.
- The exact Braintree advisory-proof harness location and naming, as long as it stays subordinate to the canonical Fake-first proof model.
- Exact wording placement across README/guides/adoption-proof docs, as long as the matrix remains the canonical SSOT and mirrored language stays consistent.

</decisions>

<specifics>
## Specific Ideas

- The most coherent Phase 96 story is:
  - host-owned Braintree browser/vault acquisition
  - one honest public `subscribe/3` slice
  - canonical proof in `examples/accrue_host`
  - installer kept generic and thin
  - matrix-led support messaging
- Good ecosystem lessons to preserve:
  - **Laravel Cashier** keeps provider stories separate instead of flattening them.
  - **Pay (Rails)** keeps multi-processor support bounded and warns that provider behavior diverges.
  - **ActiveMerchant** is the cautionary example for over-broad gateway sameness.
  - **Oban** is a useful Elixir precedent for keeping installer automation distinct from the deeper real-app proof story.
- Preference captured from discussion:
  - future GSD processor-track passes should shift low-impact decisions left into coherent recommendation bundles unless a choice is strategically meaningful enough to reopen interactively.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and locked context

- `.planning/ROADMAP.md` — Phase 96 goal and success criteria
- `.planning/REQUIREMENTS.md` — `PROC-12` and `PROC-13`
- `.planning/PROJECT.md` — v1.31 product posture and processor-track framing
- `.planning/STATE.md` — active milestone position
- `.planning/processor-support-matrix.md` — canonical first-party support SSOT
- `.planning/phases/94-strategy-capability-matrix-target-lock/094-CONTEXT.md` — locked provider/slice/support-posture decisions
- `.planning/phases/95-official-processor-contract-conformance-harness/095-CONTEXT.md` — locked conformance, guard, and proof-lane posture

### Current code and host seams

- `accrue/lib/accrue/billing.ex` — public billing facade boundary
- `accrue/lib/accrue/billing/subscription_actions.ex` — current `subscribe/3` implementation seam and request assembly boundary
- `accrue/lib/accrue/billing/payment_method_actions.ex` — payment-method slice boundaries and out-of-slice precedent
- `accrue/lib/accrue/processor.ex` — internal adapter surface
- `accrue/lib/accrue/processor/capabilities.ex` — executable capability map
- `examples/accrue_host/lib/accrue_host/billing.ex` — host-owned policy seam and canonical facade wrapper
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` — current host-level facade proof
- `examples/accrue_host/README.md` — canonical host evaluation story
- `examples/accrue_host/docs/adoption-proof-matrix.md` — proof-lane SSOT for adopters and maintainers
- `guides/testing-live-stripe.md` — advisory provider-fidelity posture
- `accrue/priv/accrue/templates/install/billing.ex.eex` — installer boundary that should stay thin
- `accrue/guides/custom_processors.md` — extension-point guidance and non-first-party support boundary

### External implementation and product-shape references

- `https://developer.paypal.com/braintree/articles/guides/recurring-billing/overview` — Braintree recurring-billing shape and prerequisites
- `https://developer.paypal.com/braintree/docs/reference/request/subscription/create` — Braintree subscription create contract
- `https://developer.paypal.com/braintree/docs/guides/payment-method-nonces` — nonce semantics and one-time handoff constraints
- `https://developer.paypal.com/braintree/docs/guides/authorization/overview/` — client-token/server-handshake model
- `https://developer.paypal.com/braintree/docs/guides/3d-secure/applying-3ds-to-transactions-and-verifications/node/` — recurring-flow 3DS constraints
- `https://laravel.com/docs/12.x/billing` — bounded Stripe-first billing facade precedent
- `https://laravel.com/docs/11.x/cashier-paddle` — provider-specific story split precedent
- `https://github.com/pay-rails/pay` — bounded multi-processor support posture
- `https://github.com/activemerchant/active_merchant` — cautionary example for over-broad gateway abstraction
- `https://github.com/solidusio/solidus_braintree` — generator + real-app split lessons
- `https://hexdocs.pm/oban/installation.html` — installer-vs-real-app proof precedent in Elixir

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Billing.subscribe/3` already exists as the intended public thin-slice entrypoint.
- `SubscriptionActions.build_subscription_request/4` already isolates provider-shaped request assembly behind one seam.
- `Accrue.Processor.Capabilities` and `.planning/processor-support-matrix.md` already provide the language and executable shape for explicit support boundaries.
- `examples/accrue_host` already provides the canonical Phoenix host proof surface and host-owned facade wrapper.

### Established Patterns

- The repo is already **Fake-first** for merge-blocking proof and **provider-backed** only for narrow fidelity checks.
- The repo already prefers **docs + verifier SSOT pairs** rather than vague support claims.
- The repo already treats generated installer files as **thin host-owned boundaries**, not as the place for provider-specific demo logic.
- The project posture is already **facade-first and capability-explicit**, not “all processors behave the same.”

### Integration Points

- Phase 96 should connect Braintree vault acquisition to the host app and then into the narrow `subscribe/3` slice without widening unrelated public APIs.
- Phase 96 should update the support matrix, host README, adoption-proof matrix, and any package-facing support language together in the same truth pass.
- Phase 96 planning should keep any new Braintree proof lane subordinate to the current Fake-first CI contract.

</code_context>

<deferred>
## Deferred Ideas

- Full public helper surface for generic multi-provider payment-method acquisition
- Broad payment-method CRUD parity across first-party processors
- Checkout parity outside Stripe
- Billing Portal parity outside Stripe
- A second full Braintree proof lane in installer-generated temp apps
- Any processor-surface broadening that implies generic parity beyond gateway subscription core

</deferred>

---

*Phase: 96-chosen-second-provider-thin-slice*
*Context gathered: 2026-04-29*
