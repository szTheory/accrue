# Phase 112: Customer Update Contract Closure - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Promote `Accrue.Billing.update_customer/2` from a staged contract row to an explicit first-party Stripe/Fake/Braintree support row by making the runtime facade semantics, capability labels, adapter truth, local projection behavior, tests, and host-facing proof all agree.

This phase closes an already-shipped contract seam. It does not widen Accrue into a broad provider-param pass-through, does not reopen payment-method scope through the customer API, and does not turn customer updates into another parity-expansion sweep.

</domain>

<decisions>
## Implementation Decisions

### Contract breadth
- **D-01:** `Accrue.Billing.update_customer/2` should become first-party only for a **narrow explicit shared subset**, not a broad pass-through to processor-specific customer update parameters.
- **D-02:** The supported first-party subset should be limited to the stable, locally projected fields that fit Accrue's bounded multi-provider contract:
  - `name`
  - `email`
  - flat string `metadata`
- **D-03:** Do **not** include payment-method-driving or processor-specialized customer params in the shared facade contract, including examples such as:
  - Stripe `source`, `default_source`, nested invoice rendering/payment-source knobs
  - Braintree `payment_method_nonce`, `defaultPaymentMethodToken`, nested `creditCard`, card verification options
- **D-04:** Remote-specialized customer mutations should stay on separate explicit APIs rather than being smuggled into `update_customer/2`.
- **D-05:** `update_customer_tax_location/2` remains the precedent for a named specialized mutation path and should stay distinct from the general customer-update contract.

### Facade semantics
- **D-06:** The public meaning of `Accrue.Billing.update_customer/2` should change from **local-only row edit** to **bounded remote write-through plus local projection sync**.
- **D-07:** The current local-only behavior is too surprising for a first-party processor contract because the adapters already implement `update_customer/3` and the public support row is about processor truth, not just local Ecto state.
- **D-08:** Phase 112 should introduce or preserve a **separate explicit local-only API** for host-owned customer row maintenance that is not part of the promoted processor contract.
- **D-09:** Recommended execution shape:
  - validate supported attrs up front
  - call `Accrue.Processor.update_customer/3` first
  - sanitize the processor result into the local customer projection
  - persist the local projection and event inside `Repo.transact`
- **D-10:** On remote success followed by local persistence failure, Accrue should treat that as a **projection-sync failure**, emit explicit telemetry, and reconcile locally rather than retrying the remote mutation blindly.
- **D-11:** Local optimistic locking (`lock_version`) protects the local projection only. It must not be treated as protection for the remote processor state.
- **D-12:** `customer.updated` should mean **remote mutation accepted and projected locally**, not just “the local Ecto row changed.”

### Event, projection, and failure semantics
- **D-13:** Event payloads should stay bounded and privacy-safe:
  - changed field names
  - local customer id
  - processor id
  - processor name
  - operation / correlation id
  - no raw PII blobs beyond what existing event discipline already permits
- **D-14:** Local projection should continue sanitizing processor return data and should not start persisting raw nested address/shipping/tax structures unless a later explicit phase decides that projection contract.
- **D-15:** Webhook-side `customer.updated` handling should eventually converge on retrieve-and-project semantics; Phase 112 should not deepen the no-op gap between direct writes and webhook truth.
- **D-16:** Unsupported attrs should fail clearly and early with typed semantics rather than being silently ignored or opportunistically forwarded to some processors.

### Proof shape
- **D-17:** Use a **combined proof model**:
  - core semantic proof in `accrue/`
  - thin host-facing proof in `examples/accrue_host`
- **D-18:** Core proof is the merge-blocking semantic SSOT for:
  - capability label promotion
  - adapter truth
  - accepted/rejected attr contract
  - projection preservation
  - event semantics
  - failure semantics
- **D-19:** Example-host proof should stay thin and adoption-facing:
  - a host-owned billing wrapper resolves the billable/customer boundary
  - delegates to `Accrue.Billing.update_customer/2`
  - proves the installed-app ergonomics without becoming a second contract implementation
- **D-20:** Fake remains the merge-blocking deterministic SSOT. Provider-backed Stripe/Braintree checks may exist as advisory fidelity lanes, but they should not become the main proof model for this row.

### Host-facing ergonomics
- **D-21:** Hosts should not have to manually discover and mutate `%Accrue.Billing.Customer{}` records from UI code just to use the promoted contract.
- **D-22:** The example host should expose a thin helper adjacent to existing helpers like `customer_for/1`, `billing_state_for/1`, and `update_customer_tax_location/2` so the supported usage pattern is obvious.
- **D-23:** Host-facing helpers should stay generic and provider-neutral; no Braintree- or Stripe-jargon should leak into the generated or documented host facade for the shared update contract.

### Ecosystem lessons to preserve
- **D-24:** Learn from Stripe’s official customer-update API that customer update endpoints can have real side effects; that is a reason to **narrow** Accrue’s shared contract, not broaden it.
- **D-25:** Learn from Braintree’s customer-update API that “customer update” can easily become an overloaded bag of customer + payment-method + verification semantics; Accrue should explicitly avoid that trap.
- **D-26:** Learn from Laravel Cashier that broad pass-through can work when explicitly marked provider-specific (`updateStripeCustomer`), while bounded sync methods are better for a shared app-facing abstraction.
- **D-27:** Learn from Pay (Rails) that best-effort multi-processor sameness needs strong caveats; Accrue should continue preferring explicit bounded support over parity theater.
- **D-28:** Learn from dj-stripe that projection truth and explicit sync/reconcile posture matter; local rows should not pretend to be authoritative if remote updates are involved.
- **D-29:** Preserve the existing ActiveMerchant lesson already captured in prior phases: avoid over-broad gateway sameness that grows hidden divergence and long-tail DX pain.

### GSD shift-left preference
- **D-30:** For future processor-track discuss/planning passes, default to **deep research plus one cohesive recommendation package** for low-impact implementation forks instead of escalating them interactively.
- **D-31:** Reopen decisions interactively only when they materially change:
  - product boundary
  - public support promise
  - proof-lane philosophy
  - long-term public API surface
- **D-32:** For this track, the default recommendation posture should continue favoring:
  - explicit first-party slices
  - narrow shared contracts
  - provider-honest semantics
  - host-owned seams where appropriate
  - Fake-first merge-blocking proof

### the agent's Discretion
- Exact naming of the separate local-only customer maintenance API.
- Exact telemetry event names and correlation-key shape for remote-success/local-sync-failure handling.
- Exact host-facade helper name in `examples/accrue_host`, as long as it stays thin, generic, and adjacent to the existing billing helpers.
- Exact verifier/script split for docs and proof drift, as long as the capability label, runtime truth, and example-host contract move together.

</decisions>

<specifics>
## Specific Ideas

- Recommended overall shape:
  - narrow first-party customer-update contract
  - remote write-through `update_customer/2`
  - separate explicit local-only projection API
  - core semantic proof + thin host-facade proof
- Recommended accepted attrs for the promoted row:
  - `name`
  - `email`
  - flat `metadata`
- Recommended explicit rejections for the promoted row:
  - payment-source / payment-method mutation params
  - processor-only nested update bags
  - broad arbitrary nested customer payloads
- Recommended event meaning:
  - “remote customer mutation was accepted and local projection was updated”
- Recommended host DX:
  - teach one host-owned helper that resolves the billable/customer boundary and delegates to the public Accrue facade
- Preference captured explicitly:
  - shift low-impact processor-track decisions left into researched defaults
  - only escalate very impactful product/support/API choices

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and active contract truth
- `.planning/ROADMAP.md` — Phase 112 goal and success criteria
- `.planning/REQUIREMENTS.md` — `PROC-21`
- `.planning/STATE.md` — active milestone position
- `.planning/PROJECT.md` — project posture and bounded dual-provider philosophy
- `.planning/STRATEGY.md` — strategic parent for the dual-provider core track
- `.planning/research/ARCHITECTURE.md` — v1.36 integration points and build order
- `.planning/research/PITFALLS.md` — contract-drift and proof-lane risks
- `.planning/processor-support-matrix.md` — public support SSOT; current staged row to promote

### Prior locked context
- `.planning/milestones/v1.31-phases/095-official-processor-contract-conformance-harness/095-CONTEXT.md` — staged-contract posture, capability SSOT, Fake-first proof rules
- `.planning/milestones/v1.31-phases/096-chosen-second-provider-thin-slice/96-CONTEXT.md` — bounded provider-honest public surface and shift-left preference
- `.planning/milestones/v1.35-phases/109-support-contract-truth/109-CONTEXT.md` — co-update discipline for public contract truth
- `.planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-CONTEXT.md` — provider-honest semantics and recommendation-synthesis preference

### Runtime facade and processor seams
- `accrue/lib/accrue/billing.ex` — current local-only `update_customer/2` and remote-specialized `update_customer_tax_location/2`
- `accrue/lib/accrue/billing/subscription_actions.ex` — existing remote customer-update use during tax validation flow
- `accrue/lib/accrue/processor.ex` — adapter callback and runtime dispatch surface
- `accrue/lib/accrue/processor/capabilities.ex` — current `customer.update` support label
- `accrue/lib/accrue/processor/stripe.ex` — Stripe adapter customer-update truth
- `accrue/lib/accrue/processor/braintree.ex` — Braintree adapter customer-update truth
- `accrue/lib/accrue/processor/fake.ex` — Fake adapter customer-update truth and deterministic semantics
- `accrue/guides/custom_processors.md` — custom-processor contract boundary and non-first-party warning

### Proof and host-facing seams
- `accrue/test/accrue/processor/capabilities_test.exs` — support-label proof anchor
- `accrue/test/accrue/billing/events_transaction_test.exs` — current customer-update transaction/event tests
- `accrue/test/accrue/processor/fake_test.exs` — deterministic customer-update proof in Fake
- `accrue/test/accrue/processor/braintree_test.exs` — Braintree adapter customer-update proof
- `accrue/guides/testing.md` — Fake-first proof philosophy and host-vs-library proof split
- `guides/testing-live-stripe.md` — advisory provider-fidelity posture
- `examples/accrue_host/lib/accrue_host/billing.ex` — host-owned billing facade seam
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` — host-facade proof style

### External references that informed the decision
- `https://docs.stripe.com/api/customers/update?api-version=2024-06-20` — Stripe customer update breadth and side effects
- `https://docs.stripe.com/api/idempotent_requests?lang=curl` — Stripe idempotent write semantics
- `https://developer.paypal.com/braintree/docs/reference/request/customer/update/node` — Braintree customer update breadth and overload risk
- `https://laravel.com/docs/13.x/billing` — Cashier bounded sync vs provider-specific raw update lessons
- `https://github.com/pay-rails/pay` — best-effort multi-processor warning and bounded support posture
- `https://dj-stripe.dev/docs/dev/usage/manually_syncing_with_stripe` — explicit sync/projection lesson
- `https://hexdocs.pm/phoenix/1.8.0/contexts.html` — Phoenix context-boundary guidance
- `https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3` — optimistic-lock semantics for local projection writes
- `https://hexdocs.pm/ex_unit/ExUnit.DocTest.html` — docs-as-proof option for executable examples

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `update_customer_tax_location/2` already demonstrates the right high-level pattern for a named remote mutation plus local projection sync.
- `customer_projection_attrs/1` and `sanitize_customer_data/1` provide a reusable projection seam for processor result normalization.
- Adapter-level `update_customer/3` support already exists in Stripe, Fake, and Braintree.
- The example host already has a thin billing facade pattern with billable/scope helpers that can absorb one more generic helper cleanly.

### Established Patterns
- Accrue prefers bounded first-party support labels over generic “supports the whole provider API” claims.
- Fake is the merge-blocking semantic SSOT; provider-backed checks are secondary fidelity lanes.
- Public contract truth is maintained through co-updated docs, code mirrors, and tests.
- Host apps are supposed to call host-owned billing helpers rather than reach through UI code into internal schemas directly.

### Integration Points
- Capability labels, `.planning/processor-support-matrix.md`, runtime facade semantics, example-host helper shape, and proof lanes must all move in the same phase.
- If `update_customer/2` changes meaning, current local-only tests and docs must be reclassified rather than silently inherited.
- The separate local-only maintenance API should be named and documented in a way that prevents confusion with the promoted processor-backed row.

</code_context>

<deferred>
## Deferred Ideas

- Broad arbitrary customer-update pass-through to processor-specific params
- Pulling payment-method acquisition or default-payment-method semantics into `update_customer/2`
- Full nested address/shipping/tax projection expansion beyond the named tax-location path
- Live-provider merge-blocking proof for customer update
- Any broader processor-expansion or lifecycle-sweep work that belongs to later phases

</deferred>

---

*Phase: 112-customer-update-contract-closure*
*Context gathered: 2026-05-06*
