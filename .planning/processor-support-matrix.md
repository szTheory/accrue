# Processor support matrix

This matrix answers: **what does Accrue mean by official multi-processor support, and where does that promise stop?**

This file is the canonical support SSOT for Accrue's official dual-provider track. It records the finalized `gateway subscription core` contract and the provider-honest boundaries that ship with it.

Accrue intentionally splits processor truth into a **deterministic Fake-first lane** and **provider-backed fidelity lanes**. `Fake` is the required local and CI proof surface. `Stripe` remains the default first-user path. `Braintree` is the locked second-provider target because it best matches Accrue's Stripe-shaped direct-gateway facade without pulling the repo into a merchant-of-record or finance-system strategy.

## Lane framing

- **Fake:** deterministic local and merge-blocking CI proof lane.
- **Stripe:** current first-user production path and reference implementation for broader surface area.
- **Braintree:** locked Stripe-like gateway target for the official second-provider track.
- **Custom processors:** extension-point adapters outside first-party support, parity promises, release gates, and the official matrix unless named explicitly here.

The required Braintree proof is hermetic: checked-in Fake/mock host coverage proves the generic facade path locally and in CI with no network access. Any real-provider Braintree run is fidelity evidence only and stays advisory unless the support boundary changes explicitly.

## Official first-party capability slice

The first official dual-provider promise is **gateway subscription core**:

- customer create / retrieve / update
- payment-method vault acquisition through each provider's honest handoff
- one direct subscription acquisition path through the public facade
- webhook verify / parse
- webhook-backed subscription and invoice lifecycle projection
- explicit capability gates where a surface is unsupported

### Capability contract

| Capability | Fake | Stripe | Braintree | Public label |
|------------|------|--------|-----------|--------------|
| customer.create | Required | Required | Required target | all first-party |
| customer.retrieve | Required | Required | Required target | all first-party |
| customer.update | Supported | Supported | Supported | all first-party |
| payment_method.vault_acquisition | Deterministic proof | Supported | Required target | all first-party |
| payment_method.create | Supported via attach-style compatibility | Supported | Required target | all first-party |
| payment_method.list | Supported via local projection | Supported | Required target | all first-party |
| payment_method.update | Unsupported | Supported | Required target | all first-party |
| payment_method.delete | Supported via detach-style compatibility | Supported | Required target | all first-party |
| payment_method.set_default | Supported | Supported | Required target | all first-party |
| subscription.direct_create | Required | Required | Required target | all first-party |
| subscription.fetch | Required | Required | Required target | all first-party |
| subscription.cancel | Supported | Supported | Supported | all first-party |
| subscription.swap_plan | testing/local-only | native | bounded first-party | official active-subscription-change |
| subscription.update_quantity | testing/local-only | native | unsupported | official active-subscription-change |
| subscription_item.add | testing/local-only | native | unsupported | official active-subscription-change |
| subscription_item.remove | testing/local-only | native | unsupported | official active-subscription-change |
| subscription_item.update_quantity | testing/local-only | native | unsupported | official active-subscription-change |
| subscription.cancel_immediately | Supported | Supported | Supported | all first-party |
| subscription.cancel_at_period_end | Supported | Supported | Unsupported | staged first-party target |
| subscription.lifecycle_webhook_projection | Deterministic projection | Supported | Required target | all first-party |
| invoice.lifecycle_webhook_projection | Deterministic projection | Supported | Required target | all first-party |
| invoice.preview_upcoming_invoice | testing/local-only | native | unsupported | official active-subscription-change |
| webhook.verify | Required | Required | Required target | all first-party |
| webhook.parse | Required | Required | Required target | all first-party |
| checkout.hosted_handoff | Local proof helper | Supported | Supported via first-party local checkout | all first-party |
| billing_portal.hosted_self_serve | Local proof helper | Supported | Supported via mounted first-party portal | all first-party |
| entitlements.local_mapping | local-identical | local-identical | local-identical | all first-party |
| entitlements.stripe_native_sync | out of slice | native (advisory) | unsupported | Stripe-native advisory (observational) |

The checkout and billing-portal rows stay visible because the public API shape is shared while the provider implementation stays honest: Stripe returns upstream hosted URLs, while Braintree returns mounted first-party local checkout and portal URLs through Accrue-owned local UI.

## Entitlements

The `entitlements.local_mapping` row is the matrix's first **convergence** row, and it inverts the checkout/portal honesty framing above. For checkout and the billing portal the public API shape is shared while the provider implementation diverges; for entitlements **both the public API shape AND the implementation are identical by construction**. Local plan-to-feature mapping **behaves identically across Stripe, Braintree, and Fake** because `Accrue.Entitlements.Resolver.LocalMap` derives entitlements from local subscription state only — `accrue_customers`, active subscription items, and the `price_id -> plan` configuration — with **zero processor calls**. The resolver takes no processor argument, so swapping `:processor` cannot change who is entitled; the identity is structural, not coincidental. That is why every provider lane reads `local-identical` rather than the `native`/`bounded first-party`/`unsupported` divergence labels used by the gateway rows above.

The Stripe-native Entitlements API is not wrapped by `lattice_stripe` 1.1, and **local mapping remains the canonical default** for all providers. The `entitlements.stripe_native_sync` row is a separate, **divergence** row covering the optional Stripe-native webhook-to-cache sync (off by default, `stripe_native_sync: :disabled`). It is **advisory / observational only**: on Stripe it records `entitlements.active_entitlement_summary.updated` summaries to an advisory cache for audit / telemetry / the admin read-seam, but it **never displaces the local-first resolution path** and **does NOT change `entitled?/2` or `has_active_plan?/2`**. Fake is out of slice and Braintree is unsupported. Because Stripe-native sync exists but never gates, the row honestly carries `native (advisory)` for Stripe while the `entitlements.local_mapping` convergence row above must never sprout a per-provider divergence label.

The shipped Braintree slice includes explicit subscription mutation semantics at the existing facade boundary. `cancel/2` is the shipped immediate-cancel path across Fake, Stripe, and Braintree, `swap_plan/3` is a bounded first-party path when the host configures `:plan_resolver`, and `preview_upcoming_invoice/2` remains the canonical path where supported rather than implied cross-provider parity. `cancel_at_period_end/2` remains a Stripe/Fake-only scheduled-end path. Quantity updates and subscription-item mutations are official active-subscription-change APIs on Stripe/Fake, while Braintree keeps those rows explicitly unsupported with typed errors instead of implied parity. Pause/unpause and resume remain out of slice.

## Public facade API mapping

| Public API | Label | Notes |
|------------|-------|-------|
| `Accrue.Billing.subscribe/3` | all first-party | Primary gateway-subscription-core facade for the second-provider slice. |
| `Accrue.Billing.get_subscription/2` | all first-party | Read side required for lifecycle truth on the supported slice. |
| `Accrue.Billing.cancel/2` | all first-party | Immediate cancellation is the shared shipped path across Fake, Stripe, and Braintree. |
| `Accrue.Billing.swap_plan/3` | official active-subscription-change | Official active-subscription-change facade for plan changes: Stripe is native, Fake is testing/local-only, and Braintree is bounded first-party only when the host provides `:plan_resolver`. |
| `Accrue.Billing.update_quantity/3` | official active-subscription-change | Official quantity-change facade for single-item subscriptions on Stripe/Fake. Braintree explicitly rejects this semantic with a typed unsupported error. |
| `Accrue.Billing.cancel_at_period_end/2` | staged first-party target | Scheduled-end cancellation remains supported on Fake and Stripe; Braintree rejects it with a typed unsupported error and a host-owned next-step hint. |
| `Accrue.Billing.create_customer/1` | all first-party | Customer creation remains part of the supported facade boundary. |
| `Accrue.Billing.update_customer/2` | all first-party | Bounded remote write-through facade for the shared `name`, `email`, and flat `metadata` contract only. |
| `Accrue.Billing.add_payment_method/3` | all first-party | Canonical add verb; Braintree accepts only the narrow vault-acquisition handoff. |
| `Accrue.Billing.update_payment_method/3` | all first-party | Replacement-oriented payment-method update semantics. |
| `Accrue.Billing.delete_payment_method/2` | all first-party | Guarded delete that blocks still-in-use and replacement-required paths. |
| `Accrue.Billing.set_default_payment_method/3` | all first-party | Explicit customer-default mutation remains canonical. |
| `Accrue.Billing.list_payment_methods/2` | all first-party | Local projection read path; provider fetches are reserved for write-through sync and repair. |
| `Accrue.Billing.create_checkout_session/2` | all first-party | Stripe returns upstream hosted URLs; Braintree returns mounted first-party local checkout URLs. |
| `Accrue.Billing.create_billing_portal_session/2` | all first-party | Stripe returns upstream hosted URLs; Braintree returns mounted first-party local portal URLs. |
| `Accrue.Billing.add_item/3` | official active-subscription-change | Official subscription-item add facade on Stripe/Fake. Braintree remains explicitly unsupported. |
| `Accrue.Billing.remove_item/2` | official active-subscription-change | Official subscription-item remove facade on Stripe/Fake. Braintree remains explicitly unsupported. |
| `Accrue.Billing.update_item_quantity/3` | official active-subscription-change | Official subscription-item quantity facade on Stripe/Fake. Braintree remains explicitly unsupported. |
| `Accrue.Billing.subscribe_via_schedule/3` | out of slice | Advanced subscription scheduling is intentionally deferred. |
| `Accrue.Billing.preview_upcoming_invoice/2` | official active-subscription-change | Official active-subscription-change preview facade and the canonical path where supported before committing a swap. Stripe is native, Fake is testing/local-only proof, and Braintree is explicitly unsupported. |

## Explicit out-of-slice surfaces

The following remain intentionally **out of slice** for first-party second-provider support:

- embedded checkout
- setup/payment intents
- pause/resume, schedules beyond the bounded swap contract, and invented preview equivalents
- refunds
- coupons
- promotion codes
- marketplace Connect parity for Braintree via Hyperwallet

## Provider rationale and exclusions

`Braintree` is the locked second-provider target because it is the closest direct-gateway fit for Accrue's existing Stripe-shaped surface: customer records, vaulted payment methods, recurring subscriptions, transactions, and webhook-backed state convergence. It stays inside the strategy boundary better than enterprise-heavy or wallet-first alternatives, and it offers a tractable Elixir package surface for the bounded support slice.

The following remain explicit non-targets for this track:

- `merchant-of-record` providers such as Paddle, Lemon Squeezy, and FastSpring
- `Adyen`
- `PayPal direct subscriptions`
- bank-debit specialists such as `GoCardless`

## Support-boundary rules

- Unsupported capabilities must **fail clearly and early** via capability checks rather than implying Stripe parity and surprising adopters later.
- Rows labeled `staged first-party target` remain documented and executable, but they are not part of the Fake-first lane's merge-blocking support bundle.
- Braintree pay-ins and Hyperwallet payouts are separate truths. Marketplace parity through Hyperwallet is strategically out of bounds unless the project boundary changes.
- Any revisit to Braintree marketplace support must start from the rule that reopening requires an explicit strategy change plus a new milestone.
- Accrue should learn from **Laravel Cashier** by naming provider tracks honestly.
- Accrue should learn from **Pay (Rails)** by keeping the shared surface bounded and warning where provider behavior diverges.
- Accrue should avoid the **ActiveMerchant** trap of over-broad gateway sameness.
- The Ecto / Active Storage / Active Job lesson applies here too: adapter compatibility alone is not first-party support.
