# Phase 97: Advanced Subscription Lifecycle - Research

**Researched:** 2026-04-30  
**Domain:** Braintree subscription mutation and webhook-backed lifecycle convergence in Accrue [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription]  
**Confidence:** MEDIUM [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]

<user_constraints>
## User Constraints

### Locked Decisions (inherited from Phase 96 CONTEXT)

### Payment-method handoff

- **D-01:** Braintree payment-method acquisition should stay **host-owned** at the browser/UI seam. Accrue should not absorb Braintree JS, browser tokenization, or a fake universal checkout abstraction into the core library. [VERIFIED: codebase grep]
- **D-02:** The public server-side contract should use **one narrow handoff reference** from the supported vault-acquisition flow rather than leaking raw provider jargon like `client_token`, `payment_method_nonce`, or `device_data` throughout the generic facade. [VERIFIED: codebase grep]
- **D-03:** Phase 97 should not route this story through payment-method inventory or CRUD surfaces. `payment_method.vault_acquisition` is in-slice; payment-method listing and broader CRUD remain out-of-slice unless already needed internally by the narrow path. [VERIFIED: codebase grep]

### `Accrue.Billing` contract shape

- **D-04:** `Accrue.Billing.subscribe/3` remains the primary public subscription contract for the Braintree provider track, and Phase 97 extends the existing public lifecycle methods rather than adding provider-specific facade calls. [VERIFIED: codebase grep]
- **D-05:** Keep the public facade free of provider-keyword soup; normalize Braintree-specific request and response shapes inside the adapter boundary. [VERIFIED: codebase grep]
- **D-06:** Preserve the existing support posture: Stripe remains the default first-user path, Fake remains the merge-blocking SSOT, and Braintree proof stays narrow and advisory in `examples/accrue_host`. [VERIFIED: codebase grep]

### Proof surface

- **D-07:** `examples/accrue_host` remains the only real Braintree proof surface; installer-generated host files stay thin and generic. [VERIFIED: codebase grep]
- **D-08:** Provider-backed Braintree proof remains subordinate to the Fake-first CI model. [VERIFIED: codebase grep]

### Public positioning

- **D-09:** `.planning/processor-support-matrix.md` remains the canonical public support SSOT, and README/guide/example-host wording must mirror it in the same change. [VERIFIED: codebase grep]
- **D-10:** Phase 97 must not imply generic multi-processor parity beyond the capabilities it actually implements. [VERIFIED: codebase grep]

### Claude's Discretion

- Exact Braintree adapter request and translation shape for mutation operations below the public facade. [VERIFIED: codebase grep]
- Exact webhook normalization strategy, as long as it stays processor-aware and preserves the Fake-first proof posture. [VERIFIED: codebase grep]
- Exact verification split between deterministic unit tests and advisory provider-facing host tests. [VERIFIED: codebase grep]

### Deferred Ideas (OUT OF SCOPE)

- Payment-method CRUD parity beyond what Phase 98 owns. [VERIFIED: codebase grep]
- Refund parity beyond what Phase 99 owns. [VERIFIED: codebase grep]
- Billing portal parity beyond what Phase 100 owns. [VERIFIED: codebase grep]
- Checkout parity outside Stripe. [VERIFIED: codebase grep]
- Broad processor-surface expansion that implies universal gateway sameness. [VERIFIED: codebase grep]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-14 | Implement subscription upgrades, downgrades (plan swaps), quantity changes, and pause/resume logic for Braintree adapters. [VERIFIED: codebase grep] | Use `Braintree.Subscription.update/3` for supported subscription mutations, but treat quantity and pause/resume as explicit planning gates because the Braintree recurring-billing docs checked here model plan, price, payment method, add-ons, discounts, and cancel/retry flows rather than Stripe-style root quantity or native pause/resume APIs. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/] |
| PROC-15 | Implement Braintree webhook event parsing to converge subscription mutation changes (swaps, quantity, pause, resume) locally. [VERIFIED: codebase grep] | Extend the existing Braintree webhook path to carry processor atom support, provider timestamp, canonical refetch, and normalized event kinds through `Accrue.Webhook.Event`, `DispatchWorker`, and `DefaultHandler`. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription] |
</phase_requirements>

## Summary

Phase 97 is not starting from zero: the public facade already exposes `swap_plan/3`, `update_quantity/3`, `pause/2`, `resume/2`, and `unpause/2`, while the current Braintree adapter still advertises `subscription.update`, `pause`, and `resume` as unsupported and only implements direct create plus fetch. [VERIFIED: codebase grep]

The reliable implementation surface for this phase is `Braintree.Subscription.update/3` plus the existing webhook ingest/reconcile pipeline. Official Braintree docs verified in this session show update support for `plan_id`, `price`, `payment_method_token`, `payment_method_nonce`, add-ons, discounts, and `prorate_charges`; they also document subscription webhook kinds such as `subscription_charged_successfully`, `subscription_canceled`, `subscription_went_active`, and `subscription_went_past_due`. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription]

The main planning risk is semantic mismatch, not plumbing. The Braintree recurring-billing docs checked here do not expose Stripe-style native pause/resume APIs, and the documented subscription model exposes base `plan_id` and `price` but not a root subscription-item quantity field like Stripe’s item model; quantity appears on add-ons and discounts instead. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/][CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage]

**Primary recommendation:** Plan Phase 97 as two tracks: implement Braintree-backed swap/update webhook convergence now, and put an explicit decision gate in front of Braintree quantity plus pause/resume semantics before promising parity in the support matrix or docs. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Host payment-method acquisition | Browser / Client | API / Backend | The host already owns Braintree Drop-in tokenization and only passes a narrow vault reference into `AccrueHost.Billing.subscribe_with_vault_reference/4`. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create] |
| Public lifecycle mutation facade | API / Backend | Database / Storage | `Accrue.Billing` delegates mutations into `SubscriptionActions`, which already owns idempotency, processor calls, local row updates, and event recording. [VERIFIED: codebase grep] |
| Provider mutation translation | API / Backend | — | Braintree-specific `plan_id`, `price`, payment-method, and webhook kind semantics belong in `Accrue.Processor.Braintree`, not in the facade. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/] |
| Local lifecycle convergence | API / Backend | Database / Storage | `SubscriptionProjection`, `InvoiceProjection`, `Webhook.Ingest`, `DispatchWorker`, and `DefaultHandler` are the shared reducers that translate canonical provider state into local rows. [VERIFIED: codebase grep] |
| Public support posture | CDN / Static | API / Backend | The matrix and mirrored docs are static truth artifacts, but they are enforced by executable CI contracts. [VERIFIED: codebase grep] |

## Project Constraints (from CLAUDE.md)

- Elixir `~> 1.17`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, and PostgreSQL `14+` are project floors. [VERIFIED: codebase grep]
- Webhook signature verification is mandatory and non-bypassable. [VERIFIED: codebase grep]
- Sensitive processor fields must not be logged verbatim. [VERIFIED: codebase grep]
- Public entry points are expected to emit telemetry. [VERIFIED: codebase grep]
- The repo is a monorepo with `accrue/` and `accrue_admin/` as sibling Mix projects. [VERIFIED: codebase grep]
- No project-local skills were present under `.claude/skills/` or `.agents/skills/`. [VERIFIED: local shell]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `braintree` | `0.16.0` published `2025-03-27` [VERIFIED: Hex API curl] | Server-side subscription update/find/cancel/retry-charge and webhook signature parsing. [VERIFIED: Hex API curl][VERIFIED: local dependency source] | The repo already depends on it, and its public API directly exposes the recurring-billing operations this phase needs. [VERIFIED: codebase grep][VERIFIED: local dependency source] |
| Existing `Accrue.Processor` boundary | in-repo [VERIFIED: codebase grep] | Runtime adapter dispatch and capability enforcement. [VERIFIED: codebase grep] | Phase 97 should extend this seam instead of bypassing it with Braintree-specific facade branches. [VERIFIED: codebase grep] |
| Existing webhook pipeline (`Plug` -> `Ingest` -> `DispatchWorker` -> `DefaultHandler`) | in-repo [VERIFIED: codebase grep] | Signature verification, persistence, async dispatch, and canonical convergence. [VERIFIED: codebase grep] | The hot path already exists and only needs Braintree-specific completion, not replacement. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing `Accrue.Processor.Fake` | in-repo [VERIFIED: codebase grep] | Merge-blocking deterministic lane for lifecycle API coverage. [VERIFIED: codebase grep] | Keep it as the primary CI proof while adding Braintree-specific mutation expectations. [VERIFIED: codebase grep] |
| Existing `Accrue.Processor.Stripe` | in-repo [VERIFIED: codebase grep] | Reference implementation for lifecycle semantics and non-regression. [VERIFIED: codebase grep] | Use it to identify where current lifecycle code is still Stripe-shaped. [VERIFIED: codebase grep] |
| Existing processor-support matrix + docs verifiers | in-repo [VERIFIED: codebase grep] | SSOT contract for public support claims. [VERIFIED: codebase grep] | Update them in the same phase if any capability label moves from out-of-slice to supported. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Braintree.Subscription.update/3` | Hand-rolled HTTP calls | Rejected because the installed Hex package already exposes update, cancel, retry, and webhook parsing directly. [VERIFIED: local dependency source] |
| Reusing Stripe item semantics verbatim | Braintree-specific synthetic single-item projection | Stripe items do not map 1:1 to Braintree subscriptions, so Phase 97 needs an explicit translation layer for local `subscription_items`. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/] |
| Promising full pause/resume parity immediately | Explicit planning gate or narrower support promise | The recurring-billing docs checked here show cancel and retry flows but did not surface a native Braintree recurring-billing pause/resume API. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/][VERIFIED: local dependency source] |

**Installation:**

```bash
cd accrue
mix deps.get
```

`accrue/mix.exs` already declares `{:braintree, "~> 0.16"}` and `accrue/mix.lock` is pinned to `0.16.0`. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Host UI
  -> chooses Braintree-backed subscription action
  -> AccrueHost.Billing facade
  -> Accrue.Billing lifecycle API
  -> SubscriptionActions
  -> capability check + processor-aware request build
  -> Accrue.Processor.Braintree update/find
  -> Braintree canonical subscription
  -> synthetic local subscription + item projection
  -> accrue_subscriptions / accrue_subscription_items / accrue_events

Braintree webhook POST
  -> Accrue.Webhook.Plug
  -> Braintree signature parse + notification normalize
  -> accrue_webhook_events row
  -> DispatchWorker
  -> DefaultHandler normalize_braintree_type
  -> Processor.fetch(:subscription, id)
  -> SubscriptionProjection / InvoiceProjection
  -> local convergence
```

### Recommended Project Structure

```text
accrue/lib/accrue/
├── processor/
│   ├── braintree.ex
│   └── capabilities.ex
├── billing/
│   ├── subscription_actions.ex
│   ├── subscription_projection.ex
│   └── invoice_projection.ex
└── webhook/
    ├── event.ex
    ├── plug.ex
    ├── ingest.ex
    ├── dispatch_worker.ex
    └── default_handler.ex

examples/accrue_host/
└── test + LiveView proof surface for advisory Braintree flows
```

### Pattern 1: Processor-aware mutation translation

**What:** Keep Braintree mutation request building inside `Accrue.Processor.Braintree`, with `SubscriptionActions` passing semantic intent only. [VERIFIED: codebase grep][VERIFIED: local dependency source]  
**When to use:** Plan swaps, payment-method replacement, price changes, and any mutation that would otherwise leak `plan_id`, `price`, or Braintree-only knobs into the facade. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]  
**Example:**

```elixir
# Source: existing Accrue adapter pattern + Braintree SDK surface
def update_subscription(id, %{plan_id: plan_id} = params, opts) do
  request =
    %{}
    |> Map.put(:plan_id, plan_id)
    |> maybe_put(:price, params[:price])
    |> maybe_put(:prorate_charges, params[:prorate_charges])
    |> maybe_put(:payment_method_token, params[:payment_method_token])

  Braintree.Subscription.update(id, request, opts)
  |> translate_subscription_result()
end
```

### Pattern 2: Synthetic single-item projection for Braintree subscriptions

**What:** Build one local `subscription_items` row from Braintree subscription state instead of expecting Stripe-style `items.data`. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/]  
**When to use:** Create, update, and webhook fetch paths for the Braintree adapter. [VERIFIED: codebase grep]  
**Example:**

```elixir
# Source: current local item expectations + Braintree response model
%{
  items: %{
    data: [
      %{
        id: "bt_item:" <> subscription.id,
        price: %{id: subscription.plan_id},
        quantity: 1
      }
    ]
  }
}
```

### Pattern 3: Normalize webhook rows before shared dispatch

**What:** Persist Braintree webhook notifications as first-class `Accrue.Webhook.Event` rows with a real `:braintree` processor atom, canonical object id, and provider timestamp. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription]  
**When to use:** Every Braintree webhook path beyond raw signature verification. [VERIFIED: codebase grep]  
**Example:**

```elixir
# Source: existing webhook pipeline shape
%Accrue.Webhook.Event{
  processor: :braintree,
  processor_event_id: synthetic_id,
  type: normalized_kind,
  object_id: subscription_id,
  created_at: notification_timestamp
}
```

### Anti-Patterns to Avoid

- **Assuming Stripe item semantics exist on Braintree subscriptions:** current `upsert_items/2` and `upsert_subscription_items/2` expect `items.data`, while Braintree subscriptions expose plan, price, add-ons, discounts, and transactions instead. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/]
- **Claiming native Braintree pause/resume parity without a verified provider primitive:** the docs checked here surfaced cancel and retry flows, not a recurring-billing pause/resume API. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/]
- **Using webhook receive time as lifecycle truth when provider timestamp exists:** current `Event.from_webhook_event/1` uses `received_at`, which weakens stale-event ordering for Braintree. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription]
- **Changing support labels in docs without updating executable capability maps:** current matrix and `Accrue.Processor.Capabilities` still classify advanced mutation as out-of-slice. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Subscription update transport | Custom HTTP request layer | `Braintree.Subscription.update/3` from the existing Hex dependency. [VERIFIED: local dependency source] | The package already exposes the request shape and returns typed subscription structs. [VERIFIED: local dependency source] |
| Webhook signature validation | Homegrown digest/HMAC logic | `Braintree.Webhook.parse/3` plus `Braintree.XML.Decoder.load/1`. [VERIFIED: local dependency source] | The installed package already validates signatures and decodes the base64 payload into XML. [VERIFIED: local dependency source] |
| Mid-cycle proration math | App-side manual calculations | Provider-side `prorate_charges` behavior with local convergence via canonical refetch. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription] | Braintree already creates the financial side effects; Accrue should converge on canonical state instead of simulating it. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription] |
| Public support messaging | Ad hoc README prose | `.planning/processor-support-matrix.md` plus existing verifier scripts. [VERIFIED: codebase grep] | The repo already treats the matrix as the public SSOT and enforces it in CI. [VERIFIED: codebase grep] |

**Key insight:** The real work in Phase 97 is not adding new public methods; it is translating Braintree’s plan/price/status/webhook model into Accrue’s existing Stripe-shaped lifecycle seams without widening the product boundary or overstating support. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/]

## Common Pitfalls

### Pitfall 1: Treating Braintree plan swaps as Stripe item swaps

**What goes wrong:** `swap_plan/3` currently builds Stripe-style `%{items: [%{id: ..., price: ...}]}` payloads, but Braintree updates are centered on `plan_id` and often `price`. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]  
**Why it happens:** The lifecycle API was built against Stripe item semantics first. [VERIFIED: codebase grep]  
**How to avoid:** Add a Braintree request builder that converts the semantic intent into `plan_id`, optional `price`, and `prorate_charges`, then synthesize the local item row after the canonical response. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]  
**Warning signs:** Any Phase 97 plan that only toggles capability flags without changing `SubscriptionActions.swap_plan/3` request construction. [VERIFIED: codebase grep]

### Pitfall 2: Assuming root subscription quantity exists on Braintree

**What goes wrong:** `update_quantity/3` currently sends `%{items: [%{id: ..., quantity: ...}]}`, but the Braintree docs checked here expose quantity on add-ons and discounts, not on a Stripe-like root item. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]  
**Why it happens:** Accrue models quantity via single-item subscriptions today. [VERIFIED: codebase grep]  
**How to avoid:** Gate this requirement behind an explicit mapping decision: either designated add-on quantity, catalog-level price-per-seat modeling, or an honest unsupported result. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/][ASSUMED]  
**Warning signs:** Planner assumes a one-line adapter change can make Braintree quantity parity work. [VERIFIED: codebase grep][ASSUMED]

### Pitfall 3: Conflating cancel/recreate with pause/resume

**What goes wrong:** Braintree cancel is terminal; the official docs say a canceled subscription cannot be edited or reactivated. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/]  
**Why it happens:** Accrue exposes both `resume/2` and `unpause/2`, and Stripe has native semantics for those paths. [VERIFIED: codebase grep]  
**How to avoid:** Require an explicit product decision before planning Braintree pause/resume: app-owned local suspend semantics, new-subscription recreation semantics, or a deferred capability row. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/][ASSUMED]  
**Warning signs:** Phase plan says “map pause to cancel and resume to create” without a discussion artifact or support-matrix change. [VERIFIED: codebase grep][ASSUMED]

### Pitfall 4: Completing webhook parsing but forgetting dispatch compatibility

**What goes wrong:** The plug can persist Braintree events today, but `Accrue.Webhook.Event.processor_to_atom/1` still only knows `"stripe"`, `"stripe_connect"`, and `"fake"`. [VERIFIED: codebase grep]  
**Why it happens:** Phase 96 only needed persistence and normalization experiments, not full dispatch coverage for mutation events. [VERIFIED: codebase grep]  
**How to avoid:** Add `"braintree" => :braintree` to the persisted-event projection path and test dispatch end to end through `DispatchWorker`. [VERIFIED: codebase grep]  
**Warning signs:** Braintree webhook ingest passes, but dispatch worker crashes on unknown processor. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and the current codebase:

### Braintree mutation path

```elixir
# Source: https://hexdocs.pm/braintree/ / deps/braintree/lib/subscription.ex
with {:ok, subscription} <-
       Braintree.Subscription.update(subscription_id, %{
         plan_id: "new_plan",
         price: "14.00",
         prorate_charges: true
       }, opts) do
  {:ok, subscription}
end
```

### Braintree webhook parse path

```elixir
# Source: deps/braintree/lib/webhook.ex + deps/braintree/lib/xml/decoder.ex
with {:ok, %{"payload" => decoded}} <- Braintree.Webhook.parse(sig, payload, opts) do
  decoded
  |> Braintree.XML.Decoder.load()
  |> Map.get("notification", %{})
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Braintree direct create only | Public facade already exposes broader lifecycle methods, but Braintree adapter still implements only create/fetch for the official slice. [VERIFIED: codebase grep] | Phase 96 completed on 2026-04-29. [VERIFIED: codebase grep] | Phase 97 must fill in adapter and webhook behavior below an already-public API surface. [VERIFIED: codebase grep] |
| Support matrix treated advanced mutation as out-of-slice | Phase 97 would move some of those rows if it succeeds. [VERIFIED: codebase grep] | Matrix locked in Phase 94 and still current. [VERIFIED: codebase grep] | Docs, capability labels, and tests must move together. [VERIFIED: codebase grep] |

**Deprecated/outdated:**

- Assuming a Braintree subscription can be projected from `items.data` the same way as Stripe is outdated for this phase; the provider response model is different. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Braintree quantity support for Accrue’s public single-item model will likely require either add-on mapping or an honest unsupported result rather than a root subscription field mapping. [ASSUMED] | Common Pitfalls / PROC-14 support | Planner may underestimate the design work or promise unsupported parity. |
| A2 | Braintree pause/resume for Accrue likely needs app-owned semantics or explicit deferral because native recurring-billing pause/resume was not surfaced in the docs checked here. [ASSUMED] | Summary / Common Pitfalls | Planner may commit to behavior the provider cannot support natively. |

## Open Questions

1. **What does “pause/resume” mean for Braintree in Accrue’s product contract?** [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/]
   - What we know: Stripe-style `pause_collection` / unpause semantics exist in Accrue today, but the Braintree recurring-billing docs checked here surfaced cancel, update, and retry rather than a native pause API. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/]
   - What's unclear: Whether Phase 97 should introduce app-owned local suspend semantics, map to some Braintree-adjacent pattern, or narrow the milestone promise. [ASSUMED]
   - Recommendation: Resolve this before PLAN.md is written; otherwise the planner cannot produce an honest acceptance test for PROC-14. [ASSUMED]

2. **How should Accrue represent Braintree quantity changes?** [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]
   - What we know: Accrue models quantity via a single local subscription item, while Braintree docs expose quantity on add-ons/discounts instead of a Stripe-like base item. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]
   - What's unclear: Whether quantity means seats-as-price, seats-as-add-on, or something else in the Braintree product model. [ASSUMED]
   - Recommendation: Make this a gating design decision, or split quantity into a follow-up phase if no decision exists yet. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `accrue` / `examples/accrue_host` test and compile loops | ✓ [VERIFIED: local shell] | `1.19.5` [VERIFIED: local shell] | — |
| Mix | dependency install and test commands | ✓ [VERIFIED: local shell] | `1.19.5` [VERIFIED: local shell] | — |
| PostgreSQL | local Ecto-backed test runs and host verification | ✓ [VERIFIED: local shell] | `14.17` and accepting connections on `:5432` [VERIFIED: local shell] | — |
| Braintree Hex package | adapter and webhook implementation | ✓ [VERIFIED: codebase grep] | `0.16.0` [VERIFIED: codebase grep][VERIFIED: Hex API curl] | — |
| Braintree sandbox credentials | advisory real-provider host proof | ✗ not present in environment vars checked here [VERIFIED: local shell] | — | Use deterministic adapter/unit tests and existing mocked host proof lane. [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:**

- None for code and deterministic test work. [VERIFIED: local shell]

**Missing dependencies with fallback:**

- Live Braintree credentials for advisory proof; the repo already has deterministic local proof patterns and a mocked host Braintree test. [VERIFIED: local shell][VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Mix aliases and CI shell verifiers. [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs`, `examples/accrue_host/test/test_helper.exs`, plus Mix aliases in `accrue/mix.exs` and `examples/accrue_host/mix.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test --warnings-as-errors` [VERIFIED: codebase grep] |
| Full suite command | `cd examples/accrue_host && mix verify.full` plus repo CI jobs. [VERIFIED: codebase grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-14 | Braintree swap/update/pause-resume semantics through `Accrue.Billing` | unit + host facade | `cd accrue && mix test test/accrue/billing/swap_plan_test.exs test/accrue/billing/subscription_cancel_test.exs test/accrue/billing/subscription_pause_resume_test.exs` | Partial existing coverage, Braintree-specific cases missing. [VERIFIED: codebase grep] |
| PROC-15 | Braintree webhook ingest and dispatch converge local mutation state | unit/integration | `cd accrue && mix test test/accrue/webhook/plug_test.exs test/accrue/webhook/default_handler_test.exs` | Partial existing coverage, mutation-convergence coverage missing. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test --warnings-as-errors` [VERIFIED: codebase grep]
- **Per wave merge:** repo CI `release-gate` and `docs-contracts-shift-left` jobs. [VERIFIED: codebase grep]
- **Phase gate:** `cd examples/accrue_host && mix verify.full` plus Braintree-specific ExUnit coverage for mutation and webhook convergence. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `accrue/test/accrue/processor/braintree_mutation_test.exs` for `update_subscription/3` translation, unsupported-path guards, and canonical response shaping. [VERIFIED: codebase grep]
- [ ] `accrue/test/accrue/webhook/braintree_dispatch_test.exs` for persisted Braintree event -> `DispatchWorker` -> `DefaultHandler` end-to-end coverage. [VERIFIED: codebase grep]
- [ ] `accrue/test/accrue/billing/braintree_subscription_lifecycle_test.exs` for `swap_plan/3`, `update_quantity/3`, and whichever Braintree pause/resume semantics get approved. [VERIFIED: codebase grep][ASSUMED]
- [ ] `examples/accrue_host/test/accrue_host/braintree_lifecycle_test.exs` for advisory host-level lifecycle proof beyond initial subscribe. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: codebase grep] | Host app owns auth; this phase touches billing internals and webhook ingest. [VERIFIED: codebase grep] |
| V3 Session Management | no [VERIFIED: codebase grep] | Host app owns sessions. [VERIFIED: codebase grep] |
| V4 Access Control | yes [VERIFIED: codebase grep] | Keep host-owned mutation authorization in `AccrueHost.Billing` / scope-based LiveView flows. [VERIFIED: codebase grep] |
| V5 Input Validation | yes [VERIFIED: codebase grep] | Keep `NimbleOptions` and explicit adapter request validation on lifecycle opts. [VERIFIED: codebase grep] |
| V6 Cryptography | yes [VERIFIED: codebase grep] | Use Braintree SDK webhook verification and never hand-roll signature validation. [VERIFIED: local dependency source] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged webhook payloads | Spoofing | Verify Braintree webhook signature before any persistence or dispatch. [VERIFIED: codebase grep][VERIFIED: local dependency source] |
| Logging raw payloads or tokens | Information Disclosure | Preserve current redaction posture and avoid logging raw `bt_payload`, nonce, or token fields. [VERIFIED: codebase grep] |
| Duplicate or replayed webhook posts | Tampering | Keep `UNIQUE(processor, processor_event_id)` dedupe and synthetic id generation deterministic for identical Braintree payloads. [VERIFIED: codebase grep] |
| Out-of-order lifecycle events | Integrity | Use provider timestamp rather than receive time when stamping Braintree events for stale-event checks. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription] |

## Sources

### Primary (HIGH confidence)

- `accrue/lib/accrue/billing.ex`, `subscription_actions.ex`, `processor/braintree.ex`, `processor/capabilities.ex`, `webhook/*.ex`, `.planning/processor-support-matrix.md`, `examples/accrue_host/**/*` - current facade, adapter, webhook, support-contract, and host-proof boundaries checked via repo grep and file reads. [VERIFIED: codebase grep]
- `https://developer.paypal.com/braintree/docs/reference/request/subscription/update/` - verified Braintree update request fields, price/plan semantics, `prorate_charges`, and payment-method fields. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]
- `https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription` - verified subscription webhook kinds and their meanings. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/subscription]
- `https://hex.pm/api/packages/braintree` - verified package version, publish date, and repo link for the installed Elixir Braintree client. [VERIFIED: Hex API curl]
- `deps/braintree/lib/subscription.ex`, `deps/braintree/lib/webhook.ex`, `deps/braintree/lib/xml/decoder.ex` - verified available Elixir client functions and webhook parse implementation. [VERIFIED: local dependency source]

### Secondary (MEDIUM confidence)

- `https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview` - verified recurring-billing statuses and retry/cancel posture. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview]
- `https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage` - verified which subscription fields are manageable by status and the absence of documented native resume guidance in the page checked. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage]
- `https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/` - verified cancel is terminal and not reactivatable. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/]
- `https://developer.paypal.com/braintree/docs/reference/response/subscription/` - verified response model centers on plan/price/status/transactions rather than Stripe-style items. [CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/]

### Tertiary (LOW confidence)

- None. Uncertain planning claims are recorded in `## Assumptions Log` rather than presented as verified facts. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - the repo already pins `braintree 0.16.0`, and the local dependency plus Hex API confirm the exact client surface. [VERIFIED: codebase grep][VERIFIED: Hex API curl][VERIFIED: local dependency source]
- Architecture: MEDIUM - the codebase seams are clear, but PROC-14 still hides a real product-model mismatch around quantity and pause/resume. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/update/]
- Pitfalls: HIGH - the major pitfalls are directly visible in current code and official Braintree docs. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/cancel/node/][CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/]

**Research date:** 2026-04-30  
**Valid until:** 2026-05-07 for provider-doc semantics and support-posture planning, because the open questions here are on a fast-moving implementation track. [ASSUMED]
