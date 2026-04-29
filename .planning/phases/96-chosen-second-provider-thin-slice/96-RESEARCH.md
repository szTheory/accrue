# Phase 96: Chosen second-provider thin slice - Research

**Researched:** 2026-04-29  
**Domain:** Braintree-backed subscription creation through Accrue's public billing facade  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

- Full public helper surface for generic multi-provider payment-method acquisition
- Broad payment-method CRUD parity across first-party processors
- Checkout parity outside Stripe
- Billing Portal parity outside Stripe
- A second full Braintree proof lane in installer-generated temp apps
- Any processor-surface broadening that implies generic parity beyond gateway subscription core
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-12 | The chosen second processor supports one real end-to-end public billing slice through the documented Accrue facade, with Stripe and Fake non-regression still passing. [VERIFIED: codebase grep] | Use `Accrue.Billing.subscribe/3` as the only public proof path, normalize Braintree request/response data at the adapter boundary, and keep Fake plus Stripe coverage on the same facade path. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create] |
| PROC-13 | Strategy, adopter docs, and public positioning are honest about the new state of the project. [VERIFIED: codebase grep] | Keep `.planning/processor-support-matrix.md` as the SSOT and update mirrored wording in package docs and `examples/accrue_host` to say “Braintree supports gateway subscription core only; checkout and portal remain Stripe-only.” [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 96 should be planned as a narrow adapter-and-host proof, not as a generic processor expansion. `Accrue.Billing.subscribe/3` already exists as the intended public seam, the processor matrix already labels `payment_method.vault_acquisition` and `subscription.direct_create` as the supported cross-provider slice, and `examples/accrue_host` is already the canonical proof surface. [VERIFIED: codebase grep]

The shortest honest path is: keep Braintree payment-method collection in the host browser layer, hand only one narrow server-side reference into the facade call, add `Accrue.Processor.Braintree` plus processor-aware request/projection/webhook normalization, and prove that path in `examples/accrue_host` while leaving checkout, billing portal, and payment-method CRUD untouched. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/client-token/generate/node/][CITED: https://developer.paypal.com/braintree/docs/guides/payment-method-nonces][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create]

The main planning risk is not the create call itself; it is the Stripe-shaped assumptions around request assembly, webhook verification, and projection. `SubscriptionActions.build_subscription_request/4`, `Accrue.Webhook.Signature`, `Accrue.Webhook.Plug`, and parts of `Accrue.Webhook.DefaultHandler` currently assume Stripe semantics and need an explicit second-provider path instead of “universal” defaults. [VERIFIED: codebase grep]

**Primary recommendation:** Plan Phase 96 around one Braintree-backed `subscribe/3` path that accepts a narrow vault-acquisition handoff, maps `price_id` directly to a Braintree `plan_id` for this thin slice, and adds processor-specific webhook verify/parse plus subscription normalization rather than broadening the public API. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create][ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Braintree payment-method acquisition | Browser / Client | API / Backend | Locked context keeps Braintree JS/tokenization host-owned at the browser seam, while the backend only receives the narrow handoff artifact. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/client-token/generate/node/][CITED: https://developer.paypal.com/braintree/docs/guides/payment-method-nonces] |
| Public `subscribe/3` facade execution | API / Backend | Database / Storage | `Accrue.Billing.subscribe/3` delegates to `SubscriptionActions.subscribe/3`, which builds processor params, calls the adapter, inserts rows, and records events transactionally. [VERIFIED: codebase grep] |
| Subscription projection into local rows | API / Backend | Database / Storage | `SubscriptionProjection.decompose/2` and `InvoiceProjection.decompose/1` are the normalization seam between provider payloads and persisted billing rows. [VERIFIED: codebase grep] |
| Webhook signature verification and parsing | API / Backend | — | Webhook requests enter through `Accrue.Webhook.Plug`, and Braintree requires parsing `bt_signature` plus `bt_payload` on the server. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse] |
| Lifecycle truth persistence | Database / Storage | API / Backend | The default handler refetches and projects canonical processor objects into local subscription and invoice tables. [VERIFIED: codebase grep] |
| Public support messaging | CDN / Static | API / Backend | The matrix and mirrored docs are static truth artifacts, but CI verifiers enforce them from the codebase. [VERIFIED: codebase grep] |

## Project Constraints (from CLAUDE.md)

- Elixir `~> 1.17`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, and PostgreSQL `14+` are project floors. [VERIFIED: codebase grep]
- Webhook signature verification is mandatory and non-bypassable. [VERIFIED: codebase grep]
- Sensitive processor fields must not be logged verbatim. [VERIFIED: codebase grep]
- All public entry points are expected to emit telemetry. [VERIFIED: codebase grep]
- The repo is a monorepo with `accrue/` and `accrue_admin/` as sibling Mix projects. [VERIFIED: codebase grep]
- Planning should respect the existing GSD workflow; no extra project-local skills were found. [VERIFIED: codebase grep]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `braintree` | `0.16.0` published 2025-03-27 [VERIFIED: Hex API] | Server-side Braintree API client for customer, payment method, subscription, client-token, and webhook operations. [VERIFIED: Hex API][VERIFIED: GitHub API] | It is the current Hex package for Elixir Braintree integration, its repo is active, and it matches the official Braintree server-side concepts Accrue needs for this phase. [VERIFIED: Hex API][VERIFIED: GitHub API][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse] |
| Existing `Accrue.Processor` boundary | in-repo [VERIFIED: codebase grep] | Runtime adapter dispatch and capability enforcement. [VERIFIED: codebase grep] | The repo already routes all billing work through this seam, so Phase 96 should add `Accrue.Processor.Braintree` rather than bypassing the boundary. [VERIFIED: codebase grep] |
| Existing `examples/accrue_host` proof surface | in-repo [VERIFIED: codebase grep] | Canonical real-app smoke path for the public facade. [VERIFIED: codebase grep] | Locked context requires it to be the only real Braintree proof surface. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing `Accrue.Processor.Fake` | in-repo [VERIFIED: codebase grep] | Merge-blocking deterministic proof lane. [VERIFIED: codebase grep] | Keep it as the default CI contract for the same `subscribe/3` path. [VERIFIED: codebase grep] |
| Existing `Accrue.Processor.Stripe` | in-repo [VERIFIED: codebase grep] | First-user production reference and non-regression lane. [VERIFIED: codebase grep] | Reuse it to prove Phase 96 did not break the existing public billing facade. [VERIFIED: codebase grep] |
| Existing docs verifiers and `host-integration` lane | in-repo [VERIFIED: codebase grep] | Public support wording drift detection and example-host proof. [VERIFIED: codebase grep] | Use for PROC-13 wording and host proof updates; do not invent a separate docs gate. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `braintree` Hex package | Direct HTTP wrapper around Braintree APIs | Rejected because webhook parsing, request signing conventions, and resource shapes are already packaged, and hand-rolling expands risk for no Phase 96 benefit. [VERIFIED: Hex API][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse] |
| Host-owned handoff + `subscribe/3` | Provider-specific `subscribe_with_braintree/…` API | Rejected by locked context because it would widen the public facade and leak provider jargon into the first-party contract. [VERIFIED: codebase grep] |
| `examples/accrue_host` only | Installer-generated host as second proof lane | Rejected by locked context because the installer must remain thin and generic. [VERIFIED: codebase grep] |

**Installation:**

```elixir
# accrue/mix.exs
defp deps do
  [
    {:braintree, "~> 0.16"}
  ]
end
```

```bash
cd accrue
mix deps.get
```

**Version verification:** `braintree` latest stable is `0.16.0`, updated `2025-03-27T17:14:15.809517Z`. [VERIFIED: Hex API]

## Architecture Patterns

### System Architecture Diagram

```text
Host browser
  -> Braintree client flow (client token -> nonce / vaulted method reference)
  -> Host app submit
  -> AccrueHost.Billing.subscribe(...)
  -> Accrue.Billing.subscribe/3
  -> SubscriptionActions.subscribe/3
  -> Accrue.Processor.Braintree.create_subscription(...)
  -> Braintree gateway
  -> normalized subscription payload
  -> SubscriptionProjection / local inserts / accrue_events
  -> webhook arrives (bt_signature + bt_payload)
  -> processor-aware webhook parse + canonical refetch
  -> DefaultHandler projection
  -> local subscription / invoice truth
```

### Recommended Project Structure

```text
accrue/lib/accrue/
├── processor/
│   ├── braintree.ex          # new adapter and capability declaration
│   └── capabilities.ex       # keep executable support mirror aligned
├── billing/
│   ├── subscription_actions.ex
│   ├── subscription_projection.ex
│   └── invoice_projection.ex
└── webhook/
    ├── signature.ex
    ├── plug.ex
    └── default_handler.ex

examples/accrue_host/
├── lib/accrue_host/          # host-owned browser/server handoff seam
├── test/                     # advisory Braintree proof + existing facade regression
└── README.md                 # mirrored support wording
```

### Pattern 1: Adapter-level request normalization

**What:** Keep provider-specific request assembly and response translation inside `Accrue.Processor.Braintree`, not in the public facade. [VERIFIED: codebase grep]  
**When to use:** Any place Braintree needs `plan_id`, payment-method token/nonce handling, or webhook-object translation. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse]  
**Example:**

```elixir
# Source: codebase pattern + Braintree subscription docs
def create_subscription(%{plan_id: plan_id} = params, opts) do
  request =
    %{}
    |> put_if_present(:payment_method_token, params[:payment_method_token])
    |> put_if_present(:payment_method_nonce, params[:payment_method_nonce])
    |> Map.put(:plan_id, plan_id)

  Braintree.Subscription.create(request, gateway_opts(opts))
  |> translate_subscription_result()
end
```

### Pattern 2: Host-owned vault acquisition, narrow server handoff

**What:** Generate a Braintree client token on the server, tokenize or select the payment method in the host UI, then pass only the resulting narrow handoff reference back to the server. [CITED: https://developer.paypal.com/braintree/docs/reference/request/client-token/generate/node/][CITED: https://developer.paypal.com/braintree/docs/guides/payment-method-nonces]  
**When to use:** The one real Braintree-backed `subscribe/3` proof path in `examples/accrue_host`. [VERIFIED: codebase grep]  
**Example:**

```elixir
# Source: locked phase context + Braintree docs
{:ok, client_token} = AccrueHost.Braintree.client_token_for(customer)
# browser uses client_token to obtain a vaulted payment method handoff
AccrueHost.Billing.subscribe(org, "starter", payment_method: %{vault_acquisition: handoff})
```

### Pattern 3: Processor-aware webhook parse before shared reducers

**What:** Branch by processor at webhook ingress, parse the provider payload into a normalized event shape, then reuse the shared persistence and reducer pipeline where possible. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse]  
**When to use:** All Braintree webhook handling for the Phase 96 supported slice. [VERIFIED: codebase grep]  
**Example:**

```elixir
# Source: codebase webhook seam + Braintree docs
case processor do
  :stripe -> Signature.verify_stripe!(raw_body, sig_header, secrets)
  :braintree -> Signature.parse_braintree!(params["bt_signature"], params["bt_payload"], gateway)
end
```

### Anti-Patterns to Avoid

- **Provider keyword soup in `subscribe/3`:** Locked context explicitly rejects raw `client_token`, `payment_method_nonce`, and `device_data` leakage through the public facade. [VERIFIED: codebase grep]
- **Treating a Braintree nonce as durable state:** Braintree nonces are single-use and expire after 3 hours if unused. [CITED: https://developer.paypal.com/braintree/docs/guides/payment-method-nonces]
- **Pretending Stripe webhooks and Braintree webhooks are shape-equivalent:** Braintree posts form fields (`bt_signature`, `bt_payload`) and documents non-sequential delivery. [CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse]
- **Building a second merge-blocking provider lane:** Locked context and existing docs keep Fake as the merge-blocking SSOT. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Braintree webhook verification and parsing | Custom HMAC / XML parser | Braintree SDK webhook parsing through the Elixir `braintree` client path. [VERIFIED: Hex API][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse] | Braintree already defines the payload contract and invalid-signature behavior. [CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse] |
| Browser card collection | Raw PCI card form inside Accrue | Host-owned Braintree client flow with client token and nonce/vault handoff. [CITED: https://developer.paypal.com/braintree/docs/reference/request/client-token/generate/node/][CITED: https://developer.paypal.com/braintree/docs/guides/payment-method-nonces] | This keeps PCI-sensitive handling out of Accrue’s core library and matches the locked phase boundary. [VERIFIED: codebase grep] |
| Second-provider public abstraction layer | Generic “all processors are the same” API surface | Capability-labeled facade with adapter normalization behind it. [VERIFIED: codebase grep] | The repo has already chosen explicit support labels over universal parity. [VERIFIED: codebase grep] |
| Plan/catalog translation system in Phase 96 | New cross-provider pricing registry | Direct `price_id` -> Braintree `plan_id` usage for the thin slice. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create][ASSUMED] | A catalog abstraction is broader than the phase boundary and not required to prove one real path. [VERIFIED: codebase grep][ASSUMED] |

**Key insight:** The deceptive complexity in this phase is at the seams, not the HTTP call. Braintree differs at payment-method acquisition, subscription prerequisites, and webhook ingress, so the plan should spend effort on those boundaries instead of broad API design. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse]

## Common Pitfalls

### Pitfall 1: Assuming `price_id` means the same thing on Braintree as Stripe

**What goes wrong:** The current facade thinks in `price_id`, while Braintree subscription creation requires a `plan_id`. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create]  
**Why it happens:** Stripe’s request shape is currently assembled directly in `build_subscription_request/4`. [VERIFIED: codebase grep]  
**How to avoid:** For Phase 96, keep the public arg name but map it to `plan_id` inside the Braintree adapter, and document the thin-slice expectation clearly in the host proof. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create][ASSUMED]  
**Warning signs:** Planner starts introducing a new product-catalog abstraction or provider-specific public arg names. [VERIFIED: codebase grep][ASSUMED]

### Pitfall 2: Designing around raw nonces as stable identifiers

**What goes wrong:** The server stores or reuses a nonce as if it were durable state. [CITED: https://developer.paypal.com/braintree/docs/guides/payment-method-nonces]  
**Why it happens:** Braintree’s browser handoff begins with a nonce, but a subscription is usually simplest with a vaulted payment method token. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create]  
**How to avoid:** Treat the nonce as a transient handoff artifact; convert it into the stable subscription create input inside the provider flow. [CITED: https://developer.paypal.com/braintree/docs/guides/payment-method-nonces][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create]  
**Warning signs:** Server code starts persisting `payment_method_nonce` directly in local billing tables. [VERIFIED: codebase grep][ASSUMED]

### Pitfall 3: Reusing Stripe webhook ingress unchanged

**What goes wrong:** `Accrue.Webhook.Plug` keeps expecting `stripe-signature` and raw JSON while Braintree sends form-encoded `bt_signature` and `bt_payload`. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse]  
**Why it happens:** Current webhook verification is hard-wired to `LatticeStripe.Webhook.construct_event!/4`. [VERIFIED: codebase grep]  
**How to avoid:** Add processor-aware webhook parsing before shared reducer logic and normalize Braintree webhook kinds into the local event vocabulary. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription]  
**Warning signs:** Planner treats webhook work as “already solved” because `webhook.verify` and `webhook.parse` are in the capability matrix. [VERIFIED: codebase grep][ASSUMED]

### Pitfall 4: Letting provider-backed proof redefine CI

**What goes wrong:** The plan grows a second blocking provider suite instead of an advisory Braintree lane. [VERIFIED: codebase grep]  
**Why it happens:** Real-provider confidence is tempting when landing a new adapter. [ASSUMED]  
**How to avoid:** Keep Fake and existing facade tests as the blocking path, and make the Braintree proof lane narrow and host-scoped. [VERIFIED: codebase grep]  
**Warning signs:** New required CI jobs duplicate the Fake contract against Braintree credentials. [VERIFIED: codebase grep][ASSUMED]

## Code Examples

Verified patterns from official sources and current repo seams:

### Braintree webhook parse contract

```ruby
# Source: https://developer.paypal.com/braintree/docs/guides/webhooks/parse
gateway.webhook_notification.parse(
  request.params["bt_signature"],
  request.params["bt_payload"]
)
```

### Braintree subscription create contract

```ruby
# Source: https://developer.paypal.com/braintree/docs/reference/request/subscription/create
gateway.subscription.create(
  payment_method_token: "the_token",
  plan_id: "the_plan_id"
)
```

### Existing Accrue public seam to preserve

```elixir
# Source: codebase
def subscribe(user, price_id_or_opts \\ [], opts \\ []) do
  span_billing(:subscription, :create, user, opts, fn ->
    SubscriptionActions.subscribe(user, price_id_or_opts, opts)
  end)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Implicit broad processor compatibility | Explicit capability-labeled first-party slice in `.planning/processor-support-matrix.md` and `Accrue.Processor.Capabilities`. [VERIFIED: codebase grep] | Phases 94-95 on 2026-04-29. [VERIFIED: codebase grep] | Phase 96 should add only the Braintree rows it can honestly prove. [VERIFIED: codebase grep] |
| Stripe-shaped assumptions in shared billing paths | Narrow conformance around `subscribe/3`, support labels, and early unsupported-operation errors. [VERIFIED: codebase grep] | Phase 95 on 2026-04-29. [VERIFIED: codebase grep] | The plan should extend the hardened seam, not reopen abstraction scope. [VERIFIED: codebase grep] |
| Single provider webhook verification path | Processor-aware webhook verify/parse is now required for any real Braintree slice. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse] | Needed in Phase 96. [VERIFIED: codebase grep][ASSUMED] | Webhook work is part of the thin slice, not a follow-up cleanup. [VERIFIED: codebase grep][ASSUMED] |

**Deprecated/outdated:**

- Treating `Accrue.Processor` implementation alone as equivalent to first-party support is outdated for this repo; the support matrix and capability labels are now the contract. [VERIFIED: codebase grep]
- Using the current Stripe-only webhook verifier unchanged for Braintree is not viable for this phase. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | For the thinnest Phase 96 slice, `price_id` should map directly to a Braintree `plan_id` instead of introducing a new catalog layer. | Summary / Don’t Hand-Roll / Pitfalls | Medium — if the project already needs provider-agnostic catalog mapping, the implementation plan changes shape. |
| A2 | The narrow public handoff can likely remain an opt shape under `subscribe/3` rather than requiring a new public helper immediately. | Summary | Medium — if the current `subscribe/3` validation cannot absorb this cleanly, a small helper becomes necessary. |
| A3 | Existing shared webhook reducers can be reused after processor-aware ingress normalization rather than needing a fully separate Braintree reducer tree. | Architecture Patterns | Medium — if Braintree lifecycle shapes diverge too far, more explicit branching is required. |

## Open Questions

1. **What is the exact public handoff shape for the Braintree vault-acquisition artifact?**
   - What we know: locked context requires one narrow handoff and forbids raw provider jargon leaking broadly. [VERIFIED: codebase grep]
   - What's unclear: whether that handoff fits cleanly as a `subscribe/3` opt or needs a tiny preparatory helper. [VERIFIED: codebase grep]
   - Recommendation: decide this in planning before task breakdown; it affects facade tests, docs, and host proof wiring. [ASSUMED]

2. **How will the Braintree proof host obtain or map plan identifiers?**
   - What we know: Braintree subscription creation requires `plan_id`, and the current Accrue facade passes a `price_id` string. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create][VERIFIED: codebase grep]
   - What's unclear: whether the host should pass Braintree plan ids directly or introduce a local alias layer. [ASSUMED]
   - Recommendation: keep Phase 96 direct and host-local unless another active milestone already needs cross-provider catalog translation. [ASSUMED]

3. **How much webhook normalization can stay shared?**
   - What we know: Braintree delivers `bt_signature` and `bt_payload`, warns about non-sequential delivery, and exposes subscription webhook kinds such as `subscription_went_active` and `subscription_charged_successfully`. [CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription]
   - What's unclear: the minimum mapping needed to drive Accrue’s existing subscription and invoice truth model. [ASSUMED]
   - Recommendation: treat webhook normalization as a first-class planning task, not a hidden adapter detail. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core `accrue` implementation and tests | ✓ [VERIFIED: local command] | `1.19.5` on OTP `28` observed locally. [VERIFIED: local command] | — |
| Node.js | `examples/accrue_host` browser/build verification | ✓ [VERIFIED: local command] | Present locally; exact version probe was partially degraded by shell behavior in this session. [VERIFIED: local command][ASSUMED] | Run only Mix-based host tests if browser tasks are intentionally deferred. [ASSUMED] |
| npm / npx | Playwright and host asset/browser lanes | ✓ [VERIFIED: local command] | Present locally. [VERIFIED: local command] | Same as above. [ASSUMED] |
| PostgreSQL client / server availability | `mix verify`, `mix verify.full`, and host proof | Partial [VERIFIED: local command] | `psql` is available locally; no DB env vars were set in this shell. [VERIFIED: local command] | Local defaults already point the host app to `localhost:5432`. [VERIFIED: codebase grep] |
| Braintree sandbox credentials | Real Braintree advisory lane | ✗ in current shell [VERIFIED: local command] | No `BRAINTREE_*` env vars detected. [VERIFIED: local command] | Keep Fake and Stripe as blocking lanes; document Braintree proof as opt-in or protected-branch/manual until credentials exist. [VERIFIED: codebase grep][ASSUMED] |
| Stripe test-mode credentials | Existing advisory Stripe lane | ✗ in current shell [VERIFIED: local command] | No `STRIPE_TEST_SECRET_KEY` or live-lane price env vars detected. [VERIFIED: local command] | Existing Fake lane remains blocking. [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:**

- Braintree sandbox credentials for any real-provider execution in this shell. [VERIFIED: local command]

**Missing dependencies with fallback:**

- Stripe test-mode credentials are absent here, but the repo already treats that lane as advisory and keeps Fake as the merge-blocking SSOT. [VERIFIED: codebase grep][VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit across `accrue` and `examples/accrue_host`. [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs` plus Mix aliases in each package. [VERIFIED: codebase grep] |
| Quick run command | `cd examples/accrue_host && mix verify` for the bounded host slice; `cd accrue && mix test` for core regressions. [VERIFIED: codebase grep] |
| Full suite command | `cd examples/accrue_host && mix verify.full` and repo-root CI jobs `docs-contracts-shift-left` plus `host-integration`. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-12 | Fake non-regression on the public `subscribe/3` path | unit/integration | `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_test.exs` | ✅ [VERIFIED: codebase grep] |
| PROC-12 | Host facade still drives the bounded public subscription path | integration | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs` | ✅ [VERIFIED: codebase grep] |
| PROC-12 | Real Braintree advisory proof through the documented host facade | integration/manual-or-opt-in | `cd examples/accrue_host && MIX_ENV=test mix test ...` with Braintree sandbox env vars and proof fixture setup. [ASSUMED] | ❌ Wave 0 [VERIFIED: codebase grep] |
| PROC-13 | Processor support wording stays aligned across docs | bash/doc contract | `bash scripts/ci/verify_processor_support_matrix.sh` plus existing doc verifiers | ✅ [VERIFIED: codebase grep] |
| PROC-13 | Full public proof posture stays consistent in example-host docs | integration/doc contract | `cd examples/accrue_host && mix verify.full` and repo-root `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs` plus touched-core tests. [VERIFIED: codebase grep][ASSUMED]
- **Per wave merge:** `cd examples/accrue_host && mix verify` and `bash scripts/ci/verify_processor_support_matrix.sh`. [VERIFIED: codebase grep][ASSUMED]
- **Phase gate:** full docs + host proof green, with Braintree real-provider evidence captured separately if credentials are available. [VERIFIED: codebase grep][ASSUMED]

### Wave 0 Gaps

- [ ] `accrue/test/accrue/processor/braintree_test.exs` or equivalent adapter contract coverage for request/response translation. [VERIFIED: codebase grep][ASSUMED]
- [ ] `accrue/test/accrue/webhook/...` coverage for Braintree parse + normalization into local lifecycle truth. [VERIFIED: codebase grep][ASSUMED]
- [ ] `examples/accrue_host/test/...` advisory Braintree proof for the documented facade path. [VERIFIED: codebase grep][ASSUMED]
- [ ] CI policy decision for where the advisory Braintree lane runs if credentials are available later. [VERIFIED: codebase grep][ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host app owns end-user auth; Accrue does not. [VERIFIED: codebase grep] |
| V3 Session Management | no | Host app owns session policy; example host wraps the billing facade. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Keep billing mutations on the host-owned facade and scope the real proof to `examples/accrue_host`. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Preserve `NimbleOptions` validation at public seams and validate any new Braintree handoff shape narrowly. [VERIFIED: codebase grep][ASSUMED] |
| V6 Cryptography | yes | Use provider SDK verification for webhook signatures; do not hand-roll Braintree parsing or Stripe signature checks. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged webhook request | Spoofing | Processor-specific signature verification before persistence; current repo already enforces this for Stripe and must extend it to Braintree. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse] |
| Replay or out-of-order lifecycle events | Tampering | Use provider timestamps, keep idempotent persistence, and preserve the existing stale-event guard model when normalizing Braintree webhooks. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse] |
| Sensitive payment data leakage in logs | Information Disclosure | Keep browser tokenization host-owned and avoid logging raw provider payloads or credentials. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/payment-method-nonces] |
| Widened facade accepts raw provider artifacts everywhere | Elevation of Privilege / Tampering | Confine provider-specific fields to one narrow handoff seam and reject broad payment-method CRUD expansion in this phase. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `accrue/lib/accrue/billing.ex`, `accrue/lib/accrue/billing/subscription_actions.ex`, `accrue/lib/accrue/processor.ex`, `accrue/lib/accrue/processor/capabilities.ex`, `accrue/lib/accrue/webhook/*`, `examples/accrue_host/*` - current facade, adapter, webhook, proof, and docs boundaries checked via repo reads and `rg`. [VERIFIED: codebase grep]
- https://developer.paypal.com/braintree/docs/reference/request/subscription/create - checked subscription create prerequisites, `plan_id`, token vs nonce, merchant-account currency, and 3DS-enriched nonce requirements. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create]
- https://developer.paypal.com/braintree/docs/guides/webhooks/parse - checked webhook POST shape, parsing contract, invalid-signature behavior, retries, and ordering warning. [CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse]
- https://developer.paypal.com/braintree/docs/guides/payment-method-nonces - checked nonce purpose, PCI rationale, single-use semantics, and 3-hour expiry. [CITED: https://developer.paypal.com/braintree/docs/guides/payment-method-nonces]
- https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription - checked subscription webhook kinds and lifecycle semantics. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription]
- https://developer.paypal.com/braintree/docs/reference/request/client-token/generate/node/ - checked client-token generation, `customerId`, and `verifyCard` behavior. [CITED: https://developer.paypal.com/braintree/docs/reference/request/client-token/generate/node/]
- `https://hex.pm/api/packages/braintree` - checked current Hex package version and update date. [VERIFIED: Hex API]

### Secondary (MEDIUM confidence)

- `https://api.github.com/repos/sorentwo/braintree-elixir` - checked repo activity and maintenance signal. [VERIFIED: GitHub API]
- `https://github.com/sorentwo/braintree-elixir` README - checked library configuration, telemetry notes, and testing expectations. [CITED: https://github.com/sorentwo/braintree-elixir]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - package/version and official Braintree contracts are verified, but the exact adapter API shape inside Accrue is still unimplemented. [VERIFIED: Hex API][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create]
- Architecture: MEDIUM - repo seams are clear, but the exact webhook normalization depth and public handoff shape still need a planning decision. [VERIFIED: codebase grep][ASSUMED]
- Pitfalls: HIGH - the main risks are directly evidenced by current Stripe-specific code and official Braintree docs. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/webhooks/parse]

**Research date:** 2026-04-29  
**Valid until:** 2026-05-06
