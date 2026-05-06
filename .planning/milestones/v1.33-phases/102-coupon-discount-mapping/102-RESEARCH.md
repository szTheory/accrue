# Phase 102: Coupon/Discount Mapping - Research

**Researched:** 2026-05-02
**Domain:** Braintree subscription discount attachment and local promotion-code mapping
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Mapping model

- **D-01:** For Braintree, the canonical business object is **local promotion-code mapping**, not a mirror of processor-native coupons. Accrue owns the customer-facing code and eligibility state; Braintree owns the target discount object referenced by ID.
- **D-02:** Model Braintree promotion support as **local code -> Braintree discount ID** resolution at subscription create/update time. Do not pretend Braintree has Stripe-style promotion-code objects.
- **D-03:** Any imported Braintree discount metadata is **optional projection/cache only**, useful for operator discovery, validation, and drift warnings. It is not the canonical source of customer-facing code semantics.
- **D-04:** If Phase 102 ships without import/sync, structure the schema and write path so an optional discount-cache layer can be added later without changing the public contract.

### Public write surface

- **D-05:** Do **not** overload `Accrue.Billing.create_coupon/2` or `create_promotion_code/2` for Braintree. Those functions already mean “processor-backed object create, local projection second,” which is honest for Stripe and dishonest for Braintree.
- **D-06:** Add a **new local mapping write surface** on `Accrue.Billing`, such as `create_discount_mapping/2` or `upsert_discount_mapping/2`, documented explicitly as local setup for processors that do not expose customer-facing promo-code objects upstream.
- **D-07:** Keep the public surface facade-first. Do not introduce a first-iteration public namespace like `Accrue.Billing.Braintree.*` unless a later phase proves that a generic facade cannot stay honest.
- **D-08:** Bulk bootstrapping via seeds/examples is allowed as a companion path, but **not** as the only supported setup path. Direct table writes are not the primary DX.

### Checkout validation UX

- **D-09:** Use **hybrid validation** in checkout: preview locally before payment submit, then revalidate authoritatively during subscription creation before the mapped Braintree discount ID is attached.
- **D-10:** Checkout should show updated savings and total before the pay CTA when a code is valid. The customer should not click “Pay $X” and then discover after submit that the discount failed.
- **D-11:** Final revalidation is mandatory. Preview success is provisional because expiry, deactivation, redemption limits, or operator drift can invalidate the mapping between preview and submit.
- **D-12:** The validation and mapping logic lives in `accrue`, not only in `accrue_portal`, so hand-rolled host portals and first-party portal flows share the same semantics.
- **D-13:** UX copy must distinguish preview from final confirmation. Prefer wording like “discount ready” or “estimated total” before submit rather than implying the gateway has already committed the discount.

### Failure semantics

- **D-14:** Keep **user-invalid code** failures in the user domain: `:not_found`, `:inactive`, `:expired`, `:max_redemptions_reached`, or equivalent explicit local-validation results before any processor call.
- **D-15:** If a valid local code resolves to a missing, invalid, or unusable Braintree discount ID, return a **typed internal/configuration error**, distinct from user-invalid-code results. This is operator drift, not customer mistake.
- **D-16:** Do **not** flatten mapping drift into generic “invalid code” UX and do **not** silently ignore the code. Both options hide the real problem and violate billing least-surprise.
- **D-17:** Preferred shape is a domain-specific typed error such as `%Accrue.Error.DiscountMappingInvalid{...}` rather than overloading generic invalid-request semantics. The checkout UI may translate that into safe customer copy such as “This promotion is temporarily unavailable.”
- **D-18:** A valid code whose target discount is broken must hard-fail subscription creation. Never create the subscription at the undiscounted amount after promising a discounted total in checkout.

### Subscription-path integration

- **D-19:** BT-05 applies at **subscription creation time**, not only as a later follow-up mutation. The Braintree subscribe path must resolve the local mapping and translate it into Braintree’s subscription discount payload shape.
- **D-20:** The current Stripe-shaped `%{coupon: ...}` path is not sufficient for Braintree. The Braintree adapter/request builder must attach discounts using Braintree’s subscription discount semantics, not Stripe coupon semantics.
- **D-21:** `apply_promotion_code/3` may remain useful for post-create mutation flows, but Phase 102’s primary truth is checkout-time subscription creation with discount attachment.

### Operator and DX posture

- **D-22:** Document the processor distinction plainly: Stripe promotions are processor-backed; Braintree promotions are local-code mappings to control-panel-managed discounts.
- **D-23:** Provide a drift-handling story: clear typed error, telemetry, and operator troubleshooting guidance when local mappings target missing or incompatible Braintree discounts.
- **D-24:** Downstream planning/execution should bias toward **strong coherent defaults** and ask the user only on genuinely high-impact choices that materially change product semantics or strategic scope. Low-ambiguity implementation details should be decided autonomously.

### the agent's Discretion

- Exact API name for the local mapping writer (`create_discount_mapping/2` vs `upsert_discount_mapping/2`)
- Whether the first slice reuses current local tables carefully or introduces a more explicit schema/module for Braintree mappings
- Whether optional Braintree discount import lands in this phase or is deferred behind the same public contract
- Exact telemetry event names and metadata fields, provided they follow existing Accrue conventions
- The precise checkout UI layout and microcopy, provided it preserves the preview-before-submit and typed-failure semantics above

### Deferred Ideas (OUT OF SCOPE)

- Optional imported/cached Braintree discount catalog for dropdown selection and drift warnings, if it does not fit cleanly into the first Phase 102 slice
- Broader cross-processor promotions abstraction beyond the Braintree-specific local mapping need
- Richer admin/operator UX for discount-catalog browsing and drift repair if the first slice only ships API/setup examples
- Any future processor-specific public namespace unless the facade-first approach proves insufficient
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BT-04 | System MUST maintain a local database of Promotion Codes. [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md] | Add a new explicit local mapping schema and facade write path rather than reusing Stripe projection writes. [VERIFIED: codebase grep] |
| BT-05 | System MUST validate local Promotion Codes and apply the corresponding Braintree Discount ID upon subscription creation. [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md] | Resolve code locally in `accrue`, preview it in `accrue_portal`, and translate it into Braintree `discounts.add[*].inherited_from_id` during `subscribe/3`. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/] |
</phase_requirements>

## Summary

Phase 102 should be planned as a **new local discount-mapping domain** layered into the existing `Accrue.Billing.subscribe/3` path, not as an extension of the current Stripe coupon/projection surface. `Accrue.Billing.CouponActions` explicitly describes `accrue_coupons` and `accrue_promotion_codes` as thin processor projections, and `Accrue.Processor.Braintree` still returns `unsupported()` for coupon and promotion-code callbacks. [VERIFIED: accrue/lib/accrue/billing/coupon_actions.ex][VERIFIED: accrue/lib/accrue/processor/braintree.ex]

The current Stripe-native leak is concentrated in two seams: `CouponActions.apply_promotion_code/3` updates subscriptions with `%{coupon: coupon.processor_id}`, and `SubscriptionActions.maybe_put_coupon/2` translates `opts[:coupon]` into `discounts: [%{coupon: id}]`. Braintree’s official subscription-create contract is different: discounts are attached through `discounts.add[*].inherited_from_id`, and Braintree discounts themselves are Control-Panel-managed objects that the API can only view and attach, not create. [VERIFIED: accrue/lib/accrue/billing/coupon_actions.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/][CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/add-ons-discounts/]

The planning implication is straightforward: put canonical validation and mapping resolution in `accrue`, extend `accrue_portal` checkout to preview the same resolution before submit, and hard-fail create-time subscription attempts when a locally valid code points at a broken Braintree discount. The current `CheckoutLive` has no promotion-code input and the current Braintree subscription projection drops `discount_id` to `nil`, so Phase 102 needs both a new mapping model and a create-time request-builder/projection change. [VERIFIED: accrue_portal/lib/accrue_portal/live/checkout_live.ex][VERIFIED: accrue/lib/accrue/billing/subscription_projection.ex]

**Primary recommendation:** Add an explicit `DiscountMapping` domain in `accrue`, resolve it inside `subscribe/3`, and teach the Braintree adapter to emit `discounts: %{add: [%{inherited_from_id: ...}]}` at subscription creation time. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Local promotion-code canonical state | Database / Storage | API / Backend | Phase 102’s source of truth is a local row, not a processor object. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] |
| Promotion-code validation and discount resolution | API / Backend | Database / Storage | Locked context requires the logic to live in `accrue` so portal and hand-rolled hosts share semantics. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] |
| Checkout preview state and microcopy | Frontend Server (SSR/LV) | API / Backend | `accrue_portal` owns the LiveView interaction, but preview must call back into core validation. [VERIFIED: accrue_portal/lib/accrue_portal/live/checkout_live.ex][VERIFIED: .planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md] |
| Subscription create-time discount attachment | API / Backend | Database / Storage | `SubscriptionActions.build_subscription_request/4` and `Accrue.Processor.Braintree.create_subscription/2` are the seam where the Braintree payload is built. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/processor/braintree.ex] |
| Drift detection and alertable telemetry | API / Backend | Database / Storage | Typed operator failures and ops telemetry belong beside the resolution logic, not in the browser. [VERIFIED: accrue/lib/accrue/telemetry/ops.ex][VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] |

## Project Constraints (from CLAUDE.md)

- Target the locked BEAM stack: Elixir `~> 1.17`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, PostgreSQL `14+`. [VERIFIED: CLAUDE.md]
- Stay within the existing dependency posture: `:braintree`, `:oban`, `:nimble_options`, `:telemetry`, `:ecto_sql`, `:postgrex`, and the sibling `accrue_portal` package are already first-party choices. [VERIFIED: CLAUDE.md][VERIFIED: accrue/mix.exs][VERIFIED: accrue_portal/mix.exs]
- Preserve Accrue’s observability contract: public entry points emit telemetry start/stop/exception events, and sensitive processor payloads must not leak into logs or telemetry metadata. [VERIFIED: CLAUDE.md][VERIFIED: accrue/lib/accrue/billing.ex][VERIFIED: accrue/lib/accrue/errors.ex]
- Preserve the headless-core boundary: `accrue` owns domain logic and `accrue_portal` owns the mounted checkout UI. [VERIFIED: CLAUDE.md][VERIFIED: .planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md]
- Do not recommend approaches that weaken the existing security baseline around payment data handling, webhook verification, or host-owned auth. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `accrue` | `1.0.0` [VERIFIED: accrue/mix.exs] | Canonical promotion validation, mapping resolution, telemetry, and subscription request building. | The locked context requires shared semantics in core, not only in `accrue_portal`. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] |
| `accrue_portal` | `1.0.0` [VERIFIED: accrue_portal/mix.exs] | LiveView checkout preview/revalidation surface for Braintree local checkout. | Phase 101 established it as the first-party portal home for Braintree checkout. [VERIFIED: .planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md] |
| `braintree` | `0.16.0` (published 2025-03-27) [VERIFIED: accrue_portal/mix.lock][CITED: https://hex.pm/packages/braintree] | Elixir gateway wrapper used by `Accrue.Processor.Braintree` for subscription create/update and optional discount catalog fetches. | The package already exposes `Braintree.Subscription.create/2` and `Braintree.Discount.all/1`, so no new gateway client is needed. [VERIFIED: accrue/deps/braintree/lib/subscription.ex][VERIFIED: accrue/deps/braintree/lib/discount.ex] |
| `ecto` / `ecto_sql` | `~> 3.13` [VERIFIED: accrue/mix.exs] | Local mapping persistence and transactional create-time redemption state. | The repo already uses Ecto transactions for billing writes, which is the right place to keep mapping state and event writes coherent. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/billing/coupon_actions.ex] |
| `nimble_options` | `~> 1.1` [VERIFIED: accrue/mix.exs] | Public facade option validation for the new mapping write/read surface and checkout preview inputs. | Existing public billing surfaces validate inputs this way already. [VERIFIED: accrue/lib/accrue/checkout/session.ex][VERIFIED: accrue/lib/accrue/billing.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Accrue.Telemetry` / `Accrue.Telemetry.Ops` | in-repo [VERIFIED: accrue/lib/accrue/telemetry/ops.ex] | Span metadata and alertable drift events. | Use billing spans for request lifecycles and ops events for mapping drift or catalog inconsistency. [VERIFIED: accrue/lib/accrue/billing.ex][VERIFIED: accrue/lib/accrue/telemetry/ops.ex] |
| `Braintree.Discount.all/1` | `0.16.0` [VERIFIED: accrue/deps/braintree/lib/discount.ex][CITED: https://hexdocs.pm/braintree/Braintree.Discount.html] | Optional write-time verification and future catalog import/cache. | Use when validating a configured Braintree discount id or when building an operator-facing lookup list. [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/add-ons-discounts/] |
| `Accrue.Checkout.LocalSession` | in-repo [VERIFIED: accrue/lib/accrue/checkout/local_session.ex] | Persisted local checkout context that Phase 102 can extend with preview state or selected code. | Use for Braintree local checkout state, not as a substitute for canonical mapping storage. [VERIFIED: accrue/lib/accrue/processor/braintree.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New explicit local mapping schema | Reuse `accrue_promotion_codes` | Reuse is smaller, but the existing schema is documented as a thin processor projection, requires `processor_id`, has Stripe-specific event columns, and points at coupons rather than discount ids. [VERIFIED: accrue/lib/accrue/billing/promotion_code.ex][VERIFIED: accrue/priv/repo/migrations/20260414130200_create_accrue_promotion_codes.exs] |
| Write-time advisory catalog verification | No catalog lookup at all | Skipping lookup is simpler, but it delays operator drift discovery until checkout submit or subscription create. [CITED: https://hexdocs.pm/braintree/Braintree.Discount.html][VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] |

**Installation:**
```bash
# No new dependency is required for the recommended Phase 102 slice.
cd accrue && mix deps.get
cd ../accrue_portal && mix deps.get
```

**Version verification:** `{:braintree, "~> 0.16"}` is already declared in [accrue/mix.exs](/Users/jon/projects/accrue/accrue/mix.exs:58), and Hex lists `0.16.0` as the current published version with a `2025-03-27` update date. [CITED: https://hex.pm/packages/braintree]

## Architecture Patterns

### System Architecture Diagram

```text
Customer enters code in CheckoutLive
  -> LiveView event ("validate_promo")
    -> Accrue.Billing.DiscountMappings.resolve_preview(customer, price_id, code)
      -> local mapping table lookup
      -> local eligibility checks (active / expiry / redemption cap)
      -> optional Braintree discount catalog verification
      -> returns preview result + adjusted total or typed error
        -> CheckoutLive updates aria-live status + estimated total

Customer submits Hosted Fields nonce
  -> CheckoutLive calls Accrue.Billing.subscribe(customer, price_id, promotion_code: code, payment_method: nonce)
    -> SubscriptionActions.build_subscription_request/4
      -> re-resolve code authoritatively in core
      -> attach Braintree discounts.add[*].inherited_from_id
      -> create subscription through Accrue.Processor.Braintree
        -> Braintree.Subscription.create(%{payment_method_token, plan_id, discounts: ...})
          -> success: persist subscription + redemption/event state + telemetry
          -> drift/failure: typed internal error + ops telemetry, no silent fallback
```

### Recommended Project Structure

```text
accrue/lib/accrue/billing/
├── discount_mapping.ex          # canonical local schema + changeset
├── discount_mapping_actions.ex  # write surface + resolve/preview helpers
└── subscription_actions.ex      # create-time integration seam

accrue/lib/accrue/processor/
└── braintree.ex                 # request-builder translation for discounts.add

accrue_portal/lib/accrue_portal/live/
└── checkout_live.ex             # promo input, preview state, final submit wiring
```

### Pattern 1: Explicit Local Mapping Domain
**What:** Add a dedicated local model for `promotion_code -> braintree_discount_id` plus preview/eligibility fields. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md]
**When to use:** Use for processors where Accrue owns customer-facing code semantics and the processor only owns the attachable discount object. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md]
**Example:**
```elixir
# Source: derived from locked context + current Accrue facade shape
attrs = %{
  code: "SPRING25",
  processor: "braintree",
  discount_id: "discount_id_1",
  active: true,
  amount_off_minor: 700,
  max_redemptions: 100,
  expires_at: ~U[2026-06-01 00:00:00Z]
}

Accrue.Billing.create_discount_mapping(attrs, operation_id: "phase102-seed-1")
```

### Pattern 2: Create-Time Braintree Discount Attachment
**What:** Resolve the code in `SubscriptionActions`, then translate it into Braintree’s documented `discounts.add[*].inherited_from_id` payload. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/]
**When to use:** Any Braintree direct-create subscription flow that accepts a promotion code at checkout. [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md]
**Example:**
```elixir
# Source: Braintree subscription create docs + current Accrue adapter seam
%{
  payment_method_token: token,
  plan_id: price_id,
  discounts: %{
    add: [
      %{inherited_from_id: mapping.discount_id}
    ]
  }
}
```

### Pattern 3: Shared Preview and Revalidation Resolver
**What:** Expose one core resolver used by both `CheckoutLive` preview and `subscribe/3` submit-time enforcement. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md]
**When to use:** Always; duplicating logic between LiveView and core violates the locked context. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md]
**Example:**
```elixir
# Source: derived from current CheckoutLive + locked hybrid validation decision
case Accrue.Billing.resolve_discount_mapping(customer, price_id, code) do
  {:ok, preview} -> assign(socket, :discount_preview, preview)
  {:error, :not_found} -> assign(socket, :promo_error, :not_found)
  {:error, %Accrue.Error.DiscountMappingInvalid{} = err} -> {:error, err}
end
```

### Anti-Patterns to Avoid

- **Overloading Stripe projection writes for Braintree:** `create_coupon/2` and `create_promotion_code/2` are explicitly processor-backed today, and Braintree does not support those upstream objects. [VERIFIED: accrue/lib/accrue/billing/coupon_actions.ex][VERIFIED: accrue/lib/accrue/processor/braintree.ex]
- **Passing `opts[:coupon]` into Braintree subscribe:** the existing helper writes a Stripe-shaped `discounts: [%{coupon: id}]` structure, which does not match Braintree’s request contract. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/]
- **Trusting preview state at submit time:** local checkout sessions currently store price and line-item snapshots, but preview success is not authoritative once operator drift or eligibility changes occur. [VERIFIED: accrue/lib/accrue/checkout/local_session.ex][VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Upstream Braintree promo CRUD | Fake coupon/promotion-code processor objects | Local mapping rows + Braintree Control-Panel discounts | Official docs say discounts are created/deleted in the Control Panel and the API only views/attaches them. [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/add-ons-discounts/] |
| Gateway request translation | Ad hoc browser-side payload mutation | `SubscriptionActions.build_subscription_request/4` + `Accrue.Processor.Braintree.build_request/1` | Those are already the canonical create-time seams. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/processor/braintree.ex] |
| Drift alerting | Logger-only warnings | `Accrue.Telemetry.Ops.emit/3` + typed exceptions | Ops telemetry is the repo’s alertable namespace and already carries operation ids safely. [VERIFIED: accrue/lib/accrue/telemetry/ops.ex] |
| Portal-only validation | Duplicate LiveView-only code paths | Core resolver called from LiveView and submit path | Locked context requires the same semantics for `accrue_portal` and hand-rolled portals. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] |

**Key insight:** The hard part is not storing a code string; it is keeping preview math, create-time gateway attachment, local eligibility, and operator drift handling coherent across `accrue` and `accrue_portal`. The existing code already has the right seams, so Phase 102 should extend them instead of introducing a parallel mini-engine. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Reusing the Stripe projection tables as the Braintree canonical model
**What goes wrong:** The plan writes Braintree mappings into `accrue_promotion_codes` or `accrue_coupons`, then starts fighting Stripe-oriented semantics like required `processor_id`, coupon FKs, and `last_stripe_event_*` columns. [VERIFIED: accrue/lib/accrue/billing/promotion_code.ex][VERIFIED: accrue/priv/repo/migrations/20260414130200_create_accrue_promotion_codes.exs]
**Why it happens:** Those tables already exist and look close enough at first glance. [VERIFIED: codebase grep]
**How to avoid:** Use a new explicit schema for the Braintree/local mapping slice and leave Stripe projection semantics untouched. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md]
**Warning signs:** Planner language starts saying “processor_id means discount id” or “promotion codes are canonical for Braintree too.” [VERIFIED: codebase grep]

### Pitfall 2: Forgetting that Braintree discount attach semantics are create-time payload semantics
**What goes wrong:** The code validates a local promo code but never translates it into `discounts.add[*].inherited_from_id`, so the subscription is created without the discount. [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/]
**Why it happens:** The current Braintree adapter only builds `%{payment_method_token, plan_id}` and the current subscribe helper is Stripe-shaped. [VERIFIED: accrue/lib/accrue/processor/braintree.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]
**How to avoid:** Put resolution in `build_subscription_request/4` and extend `build_request/1` to include Braintree discount payloads. [VERIFIED: codebase grep]
**Warning signs:** Tests only cover `apply_promotion_code/3` post-create flows or only assert preview UI state. [VERIFIED: accrue/test/accrue/billing/coupon_actions_test.exs]

### Pitfall 3: Offering preview totals without enough local discount economics
**What goes wrong:** Checkout can validate the code string but cannot compute savings before submit because only the Braintree discount id is stored locally. [VERIFIED: accrue_portal/lib/accrue_portal/live/checkout_live.ex][CITED: https://developer.paypal.com/braintree/docs/reference/response/discount/node]
**Why it happens:** Braintree discount objects are upstream-managed and preview UX requires local math. [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/add-ons-discounts/]
**How to avoid:** Store or cache enough preview data locally for the slice you support, at minimum the discount amount/cycle semantics documented by Braintree. [CITED: https://developer.paypal.com/braintree/docs/reference/response/discount/node][CITED: https://hexdocs.pm/braintree/Braintree.Discount.html]
**Warning signs:** Planned UI copy promises “updated total” but the schema only stores `code` and `discount_id`. [VERIFIED: codebase grep]

### Pitfall 4: Treating operator drift as a customer typo
**What goes wrong:** A valid local code points to a deleted or incompatible Braintree discount id, and the user sees “invalid promo code.” [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md]
**Why it happens:** Generic error handling collapses config errors into user-domain failures. [VERIFIED: accrue/lib/accrue/errors.ex]
**How to avoid:** Return a typed internal error and emit ops telemetry with mapping id/code/discount id. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md][VERIFIED: accrue/lib/accrue/telemetry/ops.ex]
**Warning signs:** The plan has `{:error, :not_found}` as the only invalid-code outcome, or it falls back to unsubsidized create on processor errors. [VERIFIED: codebase grep]

### Pitfall 5: Enforcing redemption caps without mutating redemption state
**What goes wrong:** `max_redemptions` is checked, but no successful create path increments `times_redeemed`, so the cap never closes. [VERIFIED: accrue/lib/accrue/billing/coupon_actions.ex][VERIFIED: accrue/test/accrue/billing/coupon_actions_test.exs]
**Why it happens:** The current `apply_promotion_code/3` tests cover validation branches and event writes, not redemption accounting. [VERIFIED: accrue/test/accrue/billing/coupon_actions_test.exs]
**How to avoid:** Make redemption-state mutation part of the successful create-time transaction, or explicitly defer/redesign caps if Phase 102 cannot support them honestly. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md]
**Warning signs:** The plan mentions `max_redemptions` but has no task touching `times_redeemed` or a redemption ledger. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources:

### Create-time Braintree subscription payload with discount attachment
```elixir
# Source: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/
%{
  payment_method_token: token,
  plan_id: price_id,
  discounts: %{
    add: [
      %{inherited_from_id: "discount_id_1"}
    ]
  }
}
```

### Optional discount-catalog verification path
```elixir
# Source: https://hexdocs.pm/braintree/Braintree.Discount.html
with {:ok, discounts} <- Braintree.Discount.all(),
     %Braintree.Discount{id: ^discount_id} = discount <- Enum.find(discounts, &(&1.id == discount_id)) do
  {:ok, discount}
else
  nil -> {:error, %Accrue.Error.DiscountMappingInvalid{reason: :missing_discount}}
  {:error, reason} -> {:error, reason}
end
```

### Shared preview and submit resolver shape
```elixir
# Source: derived from current CheckoutLive + SubscriptionActions seam
with {:ok, mapping} <- DiscountMappings.resolve(customer, price_id, code),
     {:ok, params} <- build_subscription_request(customer, item_params, trial_end, discount_mapping: mapping) do
  Processor.__impl__().create_subscription(params, opts)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stripe-backed coupon and promotion-code projection as the only supported promo model | Braintree local portal exists, but promotions are still unsupported in the Braintree adapter | Phase 101 introduced `accrue_portal`; Phase 102 closes the promotion gap. [VERIFIED: .planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md][VERIFIED: accrue/lib/accrue/processor/braintree.ex] | Phase 102 should extend the Braintree local-checkout stack, not re-open portal architecture questions. |
| Post-create `apply_promotion_code/3` flow centered on `%{coupon: ...}` | Create-time mapping and Braintree `discounts.add` are now the required slice | Locked for Phase 102. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] | Planning should bias toward request-builder and subscription-create tests, not only mutate-after-create tests. |

**Deprecated/outdated:**

- Treating Braintree like Stripe for promotion CRUD is outdated for this phase because official Braintree docs say discounts are Control-Panel-managed and API-view/attach only. [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/add-ons-discounts/]
- Treating `CheckoutLive`’s current one-screen Hosted Fields flow as phase-complete is outdated because there is no promotion-code preview or revalidation path yet. [VERIFIED: accrue_portal/lib/accrue_portal/live/checkout_live.ex]

## Assumptions Log

All claims in this research were verified or cited in this session — no user confirmation is required before planning.

## Open Questions (RESOLVED)

1. **Should the first slice ship a discount-catalog cache or only direct local mappings?**
   - What we know: The locked context allows deferring import/sync, and the current Elixir Braintree client already exposes `Braintree.Discount.all/1`. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md][VERIFIED: accrue/deps/braintree/lib/discount.ex]
   - Resolution: Phase 102 will ship direct local mappings first, with optional discount-cache/import deferred behind the same public contract. Operator DX in this slice is satisfied by the facade write path, setup examples, and advisory verification rather than dropdown discovery. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md][VERIFIED: .planning/phases/102-coupon-discount-mapping/102-01-PLAN.md][VERIFIED: .planning/phases/102-coupon-discount-mapping/102-03-PLAN.md]

2. **How should local redemption accounting be modeled for `max_redemptions`?**
   - What we know: Existing promo validation checks `times_redeemed` but current success paths do not increment it. [VERIFIED: accrue/lib/accrue/billing/coupon_actions.ex][VERIFIED: accrue/test/accrue/billing/coupon_actions_test.exs]
   - Resolution: Phase 102 will mutate executable redemption state on successful subscription create/update rather than introduce a separate ledger in this slice. The first implementation is a transactional counter-based path that keeps `times_redeemed` honest; a richer audit ledger remains a future enhancement if later phases need it. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md][VERIFIED: .planning/phases/102-coupon-discount-mapping/102-01-PLAN.md][VERIFIED: .planning/phases/102-coupon-discount-mapping/102-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `accrue` / `accrue_portal` compile and test | ✓ | `1.19.5` [VERIFIED: command output] | — |
| Erlang/OTP | BEAM runtime | ✓ | `28` [VERIFIED: command output] | — |
| Mix | compile/test/docs commands | ✓ | `1.19.5` [VERIFIED: command output] | — |
| Node.js | portal asset/tooling workflows if needed | ✓ | `v22.14.0` [VERIFIED: command output] | — |
| npm | package/bootstrap workflows if needed | ✓ | `11.1.0` [VERIFIED: command output] | — |
| PostgreSQL | local Ecto-backed tests | ✓ | `14.17`, `pg_isready` accepting connections on `5432` [VERIFIED: command output] | — |
| Braintree Elixir dep | gateway adapter and optional discount catalog calls | ✓ | `0.16.0` [VERIFIED: accrue_portal/mix.lock][CITED: https://hex.pm/packages/braintree] | — |
| Braintree merchant account / sandbox | provider-backed smoke validation only | ✗ / not checked | — | Use existing stubbed gateway tests as the merge-blocking lane. [VERIFIED: accrue/test/accrue/processor/braintree_test.exs][VERIFIED: accrue_portal/test/accrue_portal/live/checkout_live_test.exs] |
| Chromium | PDF/browser-adjacent tooling | broken local install | wrapper exists but app target missing [VERIFIED: command output] | Not required for Phase 102. |

**Missing dependencies with no fallback:**

- None for code, schema, or test-driven Phase 102 execution. [VERIFIED: command output]

**Missing dependencies with fallback:**

- Live Braintree account access was not verified, but the repo already uses stubbed Braintree gateway modules for deterministic tests. [VERIFIED: accrue/test/accrue/processor/braintree_test.exs][VERIFIED: accrue_portal/test/accrue_portal/live/checkout_live_test.exs]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix for `accrue` and `accrue_portal`. [VERIFIED: accrue/mix.exs][VERIFIED: accrue_portal/mix.exs] |
| Config file | [accrue/mix.exs](/Users/jon/projects/accrue/accrue/mix.exs:1), [accrue_portal/mix.exs](/Users/jon/projects/accrue/accrue_portal/mix.exs:1), CI gate in [.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml:1). [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test test/accrue/checkout/local_session_test.exs test/accrue/processor/braintree_local_portal_test.exs test/accrue/billing/coupon_actions_test.exs test/accrue/telemetry/portal_checkout_completed_test.exs` plus `cd ../accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs`. [VERIFIED: codebase grep] |
| Full suite command | `cd accrue && mix test.all && cd ../accrue_admin && mix test --warnings-as-errors && cd ../accrue_portal && mix test --warnings-as-errors`. [VERIFIED: accrue/mix.exs][VERIFIED: .github/workflows/ci.yml] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BT-04 | Persist explicit local promotion-code mappings with honest Braintree semantics. [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md] | unit/integration | `cd accrue && mix test test/accrue/billing/discount_mapping_actions_test.exs` | ❌ Wave 0 |
| BT-05 | Validate local codes in core and attach mapped Braintree discount ids on subscription create. [VERIFIED: .planning/milestones/v1.33-REQUIREMENTS.md] | integration | `cd accrue && mix test test/accrue/billing/braintree_discount_mapping_subscribe_test.exs test/accrue/processor/braintree_test.exs` | ❌ Wave 0 |
| BT-05 | Preview updated savings/total in local checkout, then revalidate at submit. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] | LiveView/integration | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_discount_test.exs` | ❌ Wave 0 |
| BT-05 | Emit typed drift failures and ops telemetry for broken mappings. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] | unit/integration | `cd accrue && mix test test/accrue/telemetry/discount_mapping_invalid_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run the new targeted `accrue` and `accrue_portal` files plus the existing Braintree local-checkout tests. [VERIFIED: codebase grep]
- **Per wave merge:** Run `cd accrue && mix test.all`, `cd accrue_admin && mix test --warnings-as-errors`, and `cd accrue_portal && mix test --warnings-as-errors` to match the CI posture. [VERIFIED: accrue/mix.exs][VERIFIED: .github/workflows/ci.yml]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: .planning/config.json]

### Wave 0 Gaps

- [ ] `accrue/test/accrue/billing/discount_mapping_actions_test.exs` — local schema/write surface, uniqueness, eligibility, and redemption-cap semantics. [VERIFIED: codebase grep]
- [ ] `accrue/test/accrue/billing/braintree_discount_mapping_subscribe_test.exs` — `subscribe/3` request assembly proves `discounts.add[*].inherited_from_id` and typed failures. [VERIFIED: codebase grep]
- [ ] `accrue/test/accrue/telemetry/discount_mapping_invalid_test.exs` — ops telemetry and error taxonomy for drift conditions. [VERIFIED: codebase grep]
- [ ] `accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs` — promo input UX, aria-live copy, preview totals, and final revalidation. [VERIFIED: codebase grep]
- [ ] Existing test commands currently fail in this environment because Mix cannot write temporary lock files under `/var/folders/...` due to `no space left on device`. [VERIFIED: command output]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Reuse host-owned `Accrue.Auth`; promo validation must not bypass the existing signed-in checkout boundary. [VERIFIED: accrue_portal/lib/accrue_portal/live/checkout_live.ex][VERIFIED: CLAUDE.md] |
| V3 Session Management | yes | Use existing local checkout session tokens and keep final authorization in server-side LiveView handlers. [VERIFIED: accrue/lib/accrue/checkout/local_session.ex][VERIFIED: accrue_portal/lib/accrue_portal/live/checkout_live.ex] |
| V4 Access Control | yes | Resolve codes against the current checkout/customer context only; do not allow arbitrary cross-customer mapping application. [VERIFIED: accrue/lib/accrue/processor/braintree.ex][VERIFIED: accrue_portal/lib/accrue_portal/live/checkout_live.ex] |
| V5 Input Validation | yes | Validate public attrs with `NimbleOptions` and schema changesets; treat invalid codes and drift as distinct failures. [VERIFIED: accrue/lib/accrue/checkout/session.ex][VERIFIED: accrue/lib/accrue/billing/promotion_code.ex][VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] |
| V6 Cryptography | no | No new crypto primitive is needed beyond existing signed session/auth infrastructure. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Promo-code enumeration through checkout | Information Disclosure | Use typed but generic user copy, rate-limit at the host boundary if needed, and keep detailed causes in server telemetry only. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md][VERIFIED: accrue/lib/accrue/telemetry/ops.ex] |
| Preview/submit mismatch | Tampering | Re-resolve the code in `subscribe/3` and fail closed if eligibility or mapping drift changes after preview. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] |
| Silent undiscounted subscription creation after a valid preview | Integrity / Repudiation | Hard-fail on `%Accrue.Error.DiscountMappingInvalid{}` rather than dropping the discount. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md] |
| Sensitive payload leakage in telemetry | Information Disclosure | Follow the existing allowlist metadata pattern in `Accrue.Billing` spans; never emit raw processor payloads. [VERIFIED: accrue/lib/accrue/billing.ex][VERIFIED: accrue/lib/accrue/errors.ex] |

## Sources

### Primary (HIGH confidence)

- Local codebase inspection across [accrue/lib/accrue/billing/coupon_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/coupon_actions.ex:1), [subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:1), [processor/braintree.ex](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:1), [checkout/local_session.ex](/Users/jon/projects/accrue/accrue/lib/accrue/checkout/local_session.ex:1), and [accrue_portal/live/checkout_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/checkout_live.ex:1). [VERIFIED: codebase grep]
- Braintree official subscription create docs: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/ [CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/]
- Braintree official add-ons/discounts guide: https://developer.paypal.com/braintree/articles/guides/recurring-billing/add-ons-discounts/ [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/add-ons-discounts/]
- Braintree official discount response docs: https://developer.paypal.com/braintree/docs/reference/response/discount/node [CITED: https://developer.paypal.com/braintree/docs/reference/response/discount/node]
- Braintree Hex package page: https://hex.pm/packages/braintree [CITED: https://hex.pm/packages/braintree]
- Braintree HexDocs: https://hexdocs.pm/braintree/Braintree.Subscription.html and https://hexdocs.pm/braintree/Braintree.Discount.html [CITED: https://hexdocs.pm/braintree/Braintree.Subscription.html][CITED: https://hexdocs.pm/braintree/Braintree.Discount.html]

### Secondary (MEDIUM confidence)

- Phase context and planning docs: [102-CONTEXT.md](/Users/jon/projects/accrue/.planning/phases/102-coupon-discount-mapping/102-CONTEXT.md:1), [101-CONTEXT.md](/Users/jon/projects/accrue/.planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md:1), [v1.33-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.33-REQUIREMENTS.md:1). [VERIFIED: codebase grep]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - The phase can reuse existing in-repo packages and the current published `braintree` dependency; no speculative dependency selection is required. [VERIFIED: accrue/mix.exs][CITED: https://hex.pm/packages/braintree]
- Architecture: HIGH - The locked context already constrains the domain model and the relevant code seams are concrete in `SubscriptionActions`, `Braintree`, and `CheckoutLive`. [VERIFIED: .planning/phases/102-coupon-discount-mapping/102-CONTEXT.md][VERIFIED: codebase grep]
- Pitfalls: HIGH - The biggest risks are visible directly in the current code and official Braintree request contract. [VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/reference/request/subscription/create/ruby/]

**Research date:** 2026-05-02
**Valid until:** 2026-06-01
