# Phase 112: Customer Update Contract Closure - Research

**Researched:** 2026-05-06  
**Domain:** `Accrue.Billing.update_customer/2` contract closure across facade semantics, processor truth, bounded attr support, local projection, deterministic proof, and host-facing ergonomics  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Contract breadth
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

#### Facade semantics
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

#### Event, projection, and failure semantics
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

#### Proof shape
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

#### Host-facing ergonomics
- **D-21:** Hosts should not have to manually discover and mutate `%Accrue.Billing.Customer{}` records from UI code just to use the promoted contract.
- **D-22:** The example host should expose a thin helper adjacent to existing helpers like `customer_for/1`, `billing_state_for/1`, and `update_customer_tax_location/2` so the supported usage pattern is obvious.
- **D-23:** Host-facing helpers should stay generic and provider-neutral; no Braintree- or Stripe-jargon should leak into the generated or documented host facade for the shared update contract.

#### Ecosystem lessons to preserve
- **D-24:** Learn from Stripe’s official customer-update API that customer update endpoints can have real side effects; that is a reason to **narrow** Accrue’s shared contract, not broaden it.
- **D-25:** Learn from Braintree’s customer-update API that “customer update” can easily become an overloaded bag of customer + payment-method + verification semantics; Accrue should explicitly avoid that trap.
- **D-26:** Learn from Laravel Cashier that broad pass-through can work when explicitly marked provider-specific (`updateStripeCustomer`), while bounded sync methods are better for a shared app-facing abstraction.
- **D-27:** Learn from Pay (Rails) that best-effort multi-processor sameness needs strong caveats; Accrue should continue preferring explicit bounded support over parity theater.
- **D-28:** Learn from dj-stripe that projection truth and explicit sync/reconcile posture matter; local rows should not pretend to be authoritative if remote updates are involved.
- **D-29:** Preserve the existing ActiveMerchant lesson already captured in prior phases: avoid over-broad gateway sameness that grows hidden divergence and long-tail DX pain.

#### GSD shift-left preference
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

### Claude's Discretion
- Exact naming of the separate local-only customer maintenance API.
- Exact telemetry event names and correlation-key shape for remote-success/local-sync-failure handling.
- Exact host-facade helper name in `examples/accrue_host`, as long as it stays thin, generic, and adjacent to the existing billing helpers.
- Exact verifier/script split for docs and proof drift, as long as the capability label, runtime truth, and example-host contract move together.

### Deferred Ideas (OUT OF SCOPE)
- Broad arbitrary customer-update pass-through to processor-specific params
- Pulling payment-method acquisition or default-payment-method semantics into `update_customer/2`
- Full nested address/shipping/tax projection expansion beyond the named tax-location path
- Live-provider merge-blocking proof for customer update
- Any broader processor-expansion or lifecycle-sweep work that belongs to later phases
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-21 | Host code can call `Accrue.Billing.update_customer/2` on the official Stripe, Fake, and Braintree processors with one explicit first-party support contract and deterministic proof. | The repo already has processor callbacks and adapter implementations for customer update, but the public facade still performs only a local `Customer.changeset/2` write, the support label remains staged, and the host example exposes only `update_customer_tax_location/2`; Phase 112 therefore needs bounded attr validation, remote write-through plus local projection semantics, promoted capability labels, merge-blocking core tests, and one thin host helper/proof lane. [VERIFIED: `accrue/lib/accrue/processor.ex:331-344`, `accrue/lib/accrue/processor/stripe.ex:139-159`, `accrue/lib/accrue/processor/fake.ex:247-251`, `accrue/lib/accrue/processor/braintree.ex:114-121`, `accrue/lib/accrue/billing.ex:925-956`, `accrue/lib/accrue/processor/capabilities.ex:11-16`, `.planning/processor-support-matrix.md:31-35`, `examples/accrue_host/lib/accrue_host/billing.ex:49-61`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs:41-52,177-220`] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- The project floor is locked to Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, and PostgreSQL `14+`, so Phase 112 should remain a brownfield contract-closure pass on the existing stack rather than introduce new platform dependencies. [VERIFIED: `CLAUDE.md`, `.planning/PROJECT.md`]
- Webhook signature verification, privacy-safe processor persistence, and telemetry on public entry points remain mandatory repo-wide constraints, so any new customer-update failure or reconciliation semantics must fit existing telemetry and privacy discipline rather than widen stored PII. [VERIFIED: `CLAUDE.md`, `.planning/PROJECT.md`]
- The repo’s workflow posture prefers GSD-scoped changes and Fake-first deterministic proof over speculative breadth, which matches the locked processor-track proof philosophy for this phase. [VERIFIED: `CLAUDE.md`, `.planning/STRATEGY.md`, `.planning/processor-support-matrix.md`]

## Summary

`Accrue.Billing.update_customer/2` is the main remaining customer-surface mismatch in the dual-provider core. The public contract still labels it as staged in both the capability SSOT and processor-support matrix, yet all three first-party adapters already expose `update_customer/3`, and `Processor.update_customer/3` already dispatches it with customer-update telemetry. The missing closure work is at the billing facade, attr boundary, event meaning, and proof lanes, not at the adapter callback layer. [VERIFIED: `accrue/lib/accrue/processor/capabilities.ex:11-16`, `.planning/processor-support-matrix.md:31-35,58-65`, `accrue/lib/accrue/processor.ex:331-344`, `accrue/lib/accrue/processor/fake.ex:247-251`, `accrue/lib/accrue/processor/stripe.ex:139-159`, `accrue/lib/accrue/processor/braintree.ex:114-121`]

The current facade semantics are locally coherent but no longer match the desired first-party promise. `update_customer/2` performs only a local `Customer.changeset/2` write and emits a `"customer.updated"` event whose payload is just `Map.take(attrs, [:metadata, :name, :email, "metadata", "name", "email"])`, while the adjacent `update_customer_tax_location/2` already demonstrates the intended remote-write-through pattern: call `Processor.update_customer/3`, sanitize the processor result with `customer_projection_attrs/1`, persist the projection, and record a processor-aware event. That neighboring path is the strongest in-repo precedent for Phase 112. [VERIFIED: `accrue/lib/accrue/billing.ex:872-905`, `accrue/lib/accrue/billing.ex:925-956`, `accrue/lib/accrue/billing.ex:1000-1027`]

The biggest risk is accidental contract widening. Today the local `Customer.changeset/2` can cast fields such as `default_payment_method_id`, `preferred_locale`, `preferred_timezone`, `data`, and `lock_version`, while Stripe forwards `stringify_keys(params)` directly and Braintree mostly stringifies params plus remaps `name` to `company`. If Phase 112 simply flips the support label and reuses those raw paths, the shared facade will quietly become a provider-specific pass-through. The right implementation target is therefore a narrow remote-write-through contract for `name`, `email`, and flat string `metadata`, plus one separate explicit local-only API for host-owned row maintenance. [VERIFIED: `accrue/lib/accrue/billing/customer.ex:72-99`, `accrue/lib/accrue/billing.ex:937-955`, `accrue/lib/accrue/processor/stripe.ex:146-156`, `accrue/lib/accrue/processor/braintree.ex:629-642`, `accrue/test/accrue/processor/stripe_test.exs:192-224`]

**Primary recommendation:** split Phase 112 into three plans:

1. promote the runtime contract by converting `update_customer/2` into bounded remote write-through and introducing a separate explicit local-only API
2. add merge-blocking core semantic proof for capability labels, accepted/rejected attrs, projection/event semantics, and failure handling
3. add one thin host-facing helper plus example-host proof so installed-app ergonomics match the promoted contract

That sequencing keeps the first-party promise narrow, testable, and host-usable without turning this closure phase into a broader customer-API expansion. [VERIFIED: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/112-customer-update-contract-closure/112-CONTEXT.md`, `examples/accrue_host/lib/accrue_host/billing.ex:35-61`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs:200-233`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Shared customer-update contract | `accrue/lib/accrue/billing.ex` | `accrue/lib/accrue/processor.ex` | The first-party contract lives at the public billing facade; the processor layer is already a dispatch seam, not the place to define the shared attr boundary. [VERIFIED: `accrue/lib/accrue/billing.ex:925-956`, `accrue/lib/accrue/processor.ex:331-344`] |
| Attr allowlist and typed rejection semantics | `accrue/lib/accrue/billing.ex` | adapter translators | Billing must reject unsupported attrs before they leak into Stripe/Braintree-specific request shapes. [VERIFIED: `accrue/lib/accrue/billing/customer.ex:72-99`, `accrue/lib/accrue/processor/stripe.ex:146-156`, `accrue/lib/accrue/processor/braintree.ex:629-642`] |
| Local customer projection after remote success | `accrue/lib/accrue/billing.ex` | webhook reconcile path | `customer_projection_attrs/1` and `sanitize_customer_data/1` already define the persisted projection seam, while webhook-side `customer.updated` is still a no-op and should not be relied on for immediate convergence in this phase. [VERIFIED: `accrue/lib/accrue/billing.ex:1000-1027`, `accrue/lib/accrue/webhook/default_handler.ex:73-76`] |
| Public support truth | `accrue/lib/accrue/processor/capabilities.ex` | `.planning/processor-support-matrix.md` | Runtime labels and public matrix must move together or the staged-vs-first-party drift reappears immediately. [VERIFIED: `accrue/lib/accrue/processor/capabilities.ex:11-16`, `.planning/processor-support-matrix.md:31-35,58-65`] |
| Deterministic semantic proof | `accrue/test/accrue/**/*` | `examples/accrue_host/test/**/*` | Core tests should remain the merge-blocking SSOT, with the host app proving only the installed-app helper ergonomics. [VERIFIED: `accrue/test/accrue/processor/fake_test.exs:58-90`, `accrue/test/accrue/processor/braintree_test.exs:337-355`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs:177-220`] |

## Current-State Findings

### The public support contract is still staged even though adapter truth already exists

- `Capabilities.support_label([:customer, :update])` is still `"staged first-party target"`, and the public processor-support matrix repeats the same staged row for both the capability table and the facade API mapping. [VERIFIED: `accrue/lib/accrue/processor/capabilities.ex:11-16`, `.planning/processor-support-matrix.md:31-35,58-65`]
- The adapter layer is already real, not hypothetical: Fake, Stripe, and Braintree all declare `customer.update: true`, and each implements `update_customer/3`. [VERIFIED: `accrue/lib/accrue/processor/fake.ex:222-250`, `accrue/lib/accrue/processor/stripe.ex:81-82,139-159`, `accrue/lib/accrue/processor/braintree.ex:19,114-121`]
- The current capability proof does not pin `customer.update` specifically; `capabilities_test.exs` asserts staged labels for subscription rows but not for the customer-update row, so the contract is under-proved today. [VERIFIED: `accrue/test/accrue/processor/capabilities_test.exs:67-76`] 

### `Accrue.Billing.update_customer/2` is still a local-only row edit

- The function docstring still describes `update_customer/2` as an atomic local `Customer` update plus `"customer.updated"` event, with no processor call at all. [VERIFIED: `accrue/lib/accrue/billing.ex:925-956`]
- The current event payload records only a bounded `changes` map derived from the caller attrs and does not include processor name, processor id, or operation/correlation identifiers. [VERIFIED: `accrue/lib/accrue/billing.ex:943-950`]
- By contrast, `update_customer_tax_location/2` already performs the desired remote-write-through sequence and emits a processor-aware event payload with `processor`, `processor_id`, `validate_location`, and `changed_fields`. [VERIFIED: `accrue/lib/accrue/billing.ex:877-905`]

### The current attr surface is wider than the desired first-party contract on both the local and remote sides

- `Customer.changeset/2` currently casts more than the intended shared contract, including `default_payment_method_id`, `preferred_locale`, `preferred_timezone`, `data`, and `lock_version`, so the existing local-only `update_customer/2` already accepts fields Phase 112 should not silently preserve as part of the promoted processor contract. [VERIFIED: `accrue/lib/accrue/billing/customer.ex:72-99`, `accrue/lib/accrue/billing.ex:937-955`]
- Stripe forwards `stringify_keys(params)` to `LatticeStripe.Customer.update/3`, and the Stripe tests explicitly verify that nested address, shipping, and tax-location maps pass through on customer update requests. That is useful for the specialized tax-location API, but too broad for the shared `update_customer/2` facade. [VERIFIED: `accrue/lib/accrue/processor/stripe.ex:146-156`, `accrue/test/accrue/processor/stripe_test.exs:192-224`]
- Braintree’s customer translator mostly stringifies incoming params and only special-cases `name -> company`, which means unsupported provider-specific keys would also slip through unless Billing rejects them first. [VERIFIED: `accrue/lib/accrue/processor/braintree.ex:629-642`]

### Projection helpers exist, but direct customer-update convergence is not yet end-to-end

- `customer_projection_attrs/1` and `sanitize_customer_data/1` already define a bounded projection that keeps `name`, `email`, `metadata`, and sanitized `data`, while explicitly dropping `address`, `shipping`, `phone`, and `tax`. That is the existing seam Phase 112 should reuse instead of inventing a new persistence shape. [VERIFIED: `accrue/lib/accrue/billing.ex:1000-1027`]
- The webhook default handler currently logs `"customer.updated"` and returns `:ok`, so direct write-through cannot rely on webhook reconciliation to finish the local sync path. [VERIFIED: `accrue/lib/accrue/webhook/default_handler.ex:73-76`]
- The existing tax-location path already has the same remote-success/local-failure hazard Phase 112 must name explicitly: the remote processor update occurs before the local `Repo.update()`, but there is no dedicated projection-sync telemetry or reconcile hook yet. [VERIFIED: `accrue/lib/accrue/billing.ex:878-905`]

### Proof lanes are partially present but not yet aligned to the promoted contract

- Fake already proves deterministic customer-update mutation semantics at the adapter level by merging params into stored customer state and surfacing a typed missing-resource error. [VERIFIED: `accrue/test/accrue/processor/fake_test.exs:58-90`]
- Braintree already proves create/retrieve/update customer callbacks through the gateway, but only at the adapter layer. [VERIFIED: `accrue/test/accrue/processor/braintree_test.exs:337-355`]
- The current billing-event coverage for `update_customer/2` only checks metadata validation failures; it does not cover remote write-through, event meaning, rejected attrs, or projection preservation. [VERIFIED: `accrue/test/accrue/billing/events_transaction_test.exs:113-139`]
- The example host currently exposes and tests `update_customer_tax_location/2`, not `update_customer/2`, which means there is no installed-app proof for the promoted row yet even though the host facade pattern is already in place. [VERIFIED: `examples/accrue_host/lib/accrue_host/billing.ex:49-61`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs:41-52,177-220`] 

## Validation Architecture

### Contract and drift lane

```bash
rg -n "customer.update|update_customer/2|staged first-party target|all first-party" \
  .planning/processor-support-matrix.md \
  accrue/lib/accrue/processor/capabilities.ex \
  accrue/lib/accrue/billing.ex \
  examples/accrue_host/lib/accrue_host/billing.ex
```

This grep lane should fail if the matrix, support labels, facade docs, and host-facing helper fall out of sync again. [VERIFIED: `.planning/processor-support-matrix.md:31-35,58-65`, `accrue/lib/accrue/processor/capabilities.ex:11-16`, `accrue/lib/accrue/billing.ex:925-956`, `examples/accrue_host/lib/accrue_host/billing.ex:49-61`]

### Core semantic lane

```bash
cd accrue && mix test \
  test/accrue/processor/capabilities_test.exs \
  test/accrue/billing/events_transaction_test.exs \
  test/accrue/processor/fake_test.exs \
  test/accrue/processor/braintree_test.exs \
  test/accrue/processor/stripe_test.exs
```

This is the right merge-blocking bundle for Phase 112 because it covers label truth, local event/projection semantics, deterministic Fake behavior, Braintree adapter truth, and the Stripe customer-update request shape already used by the tax-location precedent. [VERIFIED: `accrue/test/accrue/processor/capabilities_test.exs:67-76`, `accrue/test/accrue/billing/events_transaction_test.exs:113-139`, `accrue/test/accrue/processor/fake_test.exs:58-90`, `accrue/test/accrue/processor/braintree_test.exs:337-355`, `accrue/test/accrue/processor/stripe_test.exs:192-224`]

### Host-facing proof lane

```bash
cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs
```

The host lane should stay thin: prove one helper adjacent to `customer_for/1`, `billing_state_for/1`, and `update_customer_tax_location/2`, and verify that the generated facade source remains generic and provider-neutral. [VERIFIED: `examples/accrue_host/lib/accrue_host/billing.ex:35-61`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs:41-52,177-233`] 

## Resolved Questions

- **Does Phase 112 need a new processor callback or adapter class?** No. `Processor.update_customer/3` already exists and all three first-party adapters already implement it, so the closure work belongs at the billing-facade and proof layers. [VERIFIED: `accrue/lib/accrue/processor.ex:331-344`, `accrue/lib/accrue/processor/fake.ex:247-251`, `accrue/lib/accrue/processor/stripe.ex:139-159`, `accrue/lib/accrue/processor/braintree.ex:114-121`]
- **Can the promoted contract simply inherit the current local `Customer.changeset/2` or raw adapter param bags?** No. The local cast set and remote translators are both broader than the locked shared contract, so Billing must impose the boundary explicitly before calling the processor. [VERIFIED: `accrue/lib/accrue/billing/customer.ex:72-99`, `accrue/lib/accrue/processor/stripe.ex:146-156`, `accrue/lib/accrue/processor/braintree.ex:629-642`]
- **Should the existing local-only semantics disappear entirely once `update_customer/2` becomes remote write-through?** No. The phase context explicitly preserves a separate explicit local-only API for host-owned row maintenance, and the current repo already distinguishes specialized remote mutation paths such as `update_customer_tax_location/2` from generic row-edit behavior. [VERIFIED: `.planning/phases/112-customer-update-contract-closure/112-CONTEXT.md`, `accrue/lib/accrue/billing.ex:872-905,925-956`]
- **Can webhook `customer.updated` be the primary projection-sync mechanism for this phase?** No. The handler is still a no-op today, so direct `update_customer/2` must persist its local projection itself and only treat later webhook work as convergence follow-on, not as the primary success path. [VERIFIED: `accrue/lib/accrue/webhook/default_handler.ex:73-76`, `.planning/phases/112-customer-update-contract-closure/112-CONTEXT.md`]
- **Should provider-backed live runs be the main proof lane for the promoted row?** No. The locked milestone posture remains Fake-first merge-blocking proof with thin host-facing evidence, while provider-backed runs stay secondary fidelity checks. [VERIFIED: `.planning/STRATEGY.md`, `.planning/processor-support-matrix.md`, `.planning/phases/112-customer-update-contract-closure/112-CONTEXT.md`] 

## Plan Shape Recommendation

| Plan | Focus | Why it should be separate |
|------|-------|---------------------------|
| 112-01 | `update_customer/2` contract promotion + explicit local-only API | This is the public-semantics change: bounded attr validation, remote write-through, local projection reuse, event meaning change, and projection-sync failure handling belong together. [VERIFIED: `accrue/lib/accrue/billing.ex:872-905,925-956`, `accrue/lib/accrue/billing/customer.ex:72-99`] |
| 112-02 | capability/matrix alignment + core deterministic proof | Once the runtime contract is fixed, the repo needs the support-label promotion and merge-blocking tests that pin accepted attrs, rejected attrs, projection semantics, and adapter truth. [VERIFIED: `accrue/lib/accrue/processor/capabilities.ex:11-16`, `.planning/processor-support-matrix.md:31-35,58-65`, `accrue/test/accrue/processor/capabilities_test.exs:67-76`, `accrue/test/accrue/billing/events_transaction_test.exs:113-139`] |
| 112-03 | thin host helper + example-host proof | Host ergonomics are a distinct surface: add one provider-neutral helper next to existing facade helpers and prove the generated host path without duplicating core contract logic. [VERIFIED: `examples/accrue_host/lib/accrue_host/billing.ex:35-61`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs:41-52,177-233`] |

---

*Phase: 112-customer-update-contract-closure*  
*Research completed: 2026-05-06*
