# Phase 102: Coupon / Discount Mapping - Context

**Gathered:** 2026-05-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 102 delivers **local promotion-code resolution for Braintree**. Customers enter a promotion code during checkout, Accrue validates that code locally, resolves it to a configured Braintree discount ID, and applies that discount when creating the subscription.

This phase satisfies **BT-04** and **BT-05**:
- Accrue maintains a local database of promotion-code mappings.
- Checkout-applied codes resolve to the correct Braintree discount ID at subscription creation time.

This phase does **not**:
- Invent upstream Braintree coupon/promotion-code CRUD that Braintree does not have
- Change Stripe coupon/promotion-code semantics
- Ship a generic cross-processor promotions engine beyond what this Braintree slice needs
- Turn discount drift into silent fallback behavior

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<specifics>
## Specific Ideas

- Example mapping shape: `"SPRING25" -> "bt_disc_25_off"` where the code is local/customer-facing and the target ID is the Braintree Control Panel discount identifier.
- Provide one end-to-end example where `Accrue.Portal` validates a code, recomputes the displayed total, then creates a Braintree subscription with the mapped discount attached.
- Add a short guide explicitly comparing **Stripe vs Braintree promotions** so developers do not assume identical upstream capability.
- If a discount-cache import exists, make the admin/operator UX select from imported discount IDs while keeping the local mapping row as the canonical object.
- Include a safe checkout handling example:
  `{:error, %Accrue.Error.DiscountMappingInvalid{}} -> show "This promotion is temporarily unavailable" and log/alert internally`
- Include accessibility guidance for portal UX: promo status and total changes announced via `aria-live`, keyboard-submittable input, and no color-only feedback.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone and locked context
- `.planning/ROADMAP.md` — Phase 102 goal, success criteria, and v1.33 framing
- `.planning/milestones/v1.33-REQUIREMENTS.md` — BT-04 and BT-05 requirement text and traceability
- `.planning/phases/101-accrue-portal-foundation-checkout/101-CONTEXT.md` — Portal/checkout decisions Phase 102 must integrate with, especially local checkout behavior and “strong defaults” posture

### Current billing and coupon surface
- `accrue/lib/accrue/billing.ex` — public facade shape that Phase 102 should extend honestly
- `accrue/lib/accrue/billing/coupon_actions.ex` — current Stripe-shaped coupon/promotion semantics and local validation behavior
- `accrue/lib/accrue/billing/subscription_actions.ex` — current subscription-create flow and request assembly path
- `accrue/lib/accrue/billing/coupon.ex` — existing coupon projection model
- `accrue/lib/accrue/billing/promotion_code.ex` — existing promotion-code projection model
- `accrue/lib/accrue/billing/promotion_code_projection.ex` — current processor-to-local projection assumptions

### Braintree integration seam
- `accrue/lib/accrue/processor.ex` — processor contract surface and capability expectations
- `accrue/lib/accrue/processor/braintree.ex` — Braintree adapter, current discount/coupon limitations, and checkout/subscribe request translation seam
- `accrue/lib/accrue/processor/stripe.ex` — reference for current Stripe-native coupon/promotion semantics that must remain unchanged
- `accrue/lib/accrue/errors.ex` — typed error taxonomy precedent for configuration/contract failures
- `accrue/lib/accrue/config.ex` — local portal config/error precedent

### Portal checkout UX
- `accrue/lib/accrue/checkout/local_session.ex` — local checkout session state and price snapshot seam
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex` — checkout interaction model Phase 102 should extend
- `accrue/guides/braintree-local-portal.md` — host-built portal recipe that should share the same validation/mapping semantics

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Billing.CouponActions` already contains useful local-validation concepts: active flag, expiry, max redemptions, and typed pre-processor failures.
- `Accrue.Billing.subscribe/3` and `SubscriptionActions` already provide the canonical subscription-create seam where Braintree discount attachment should be integrated.
- `Accrue.Portal` checkout already has a local-session-driven flow that can support preview-state UX before payment submit.
- Existing typed error patterns in `accrue/lib/accrue/errors.ex` provide precedent for distinguishing operator/configuration failures from customer-domain validation failures.

### Established Patterns

- Accrue prefers a stable public facade and honest capability boundaries over pretending processors behave the same.
- Stripe paths are allowed to stay Stripe-shaped when that is the true processor model; Braintree paths should be explicit when they differ materially.
- Local state is acceptable when it captures Accrue-owned semantics, but thin projections should not be mistaken for canonical truth if the processor model differs.
- First-party portal UX should avoid promising billing outcomes the core library cannot enforce.

### Integration Points

- `SubscriptionActions.build_subscription_request/4` and Braintree request translation need a new seam for resolved discount mappings.
- The existing `%{coupon: ...}` path should not be reused as the Braintree attach-discount contract.
- Checkout preview state must feed into the same core validation/mapping path later used at submit time.
- Telemetry and troubleshooting should key off the resolved local mapping row, promotion code, target discount ID, and processor validation result.

</code_context>

<deferred>
## Deferred Ideas

- Optional imported/cached Braintree discount catalog for dropdown selection and drift warnings, if it does not fit cleanly into the first Phase 102 slice
- Broader cross-processor promotions abstraction beyond the Braintree-specific local mapping need
- Richer admin/operator UX for discount-catalog browsing and drift repair if the first slice only ships API/setup examples
- Any future processor-specific public namespace unless the facade-first approach proves insufficient

</deferred>

---

*Phase: 102-coupon-discount-mapping*
*Context gathered: 2026-05-02*
