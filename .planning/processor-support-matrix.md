# Processor support matrix

This matrix answers: **what does Accrue mean by official multi-processor support, and where does that promise stop?**

Phase 94 locks the contract before the runtime work is complete. This file is therefore the support SSOT for the active dual-provider track, not a claim that every Braintree row is already implemented on this branch today. Phase 95 and Phase 96 must satisfy the contract recorded here.

Accrue intentionally splits processor truth into a **deterministic Fake-first lane** and **provider-backed fidelity lanes**. `Fake` is the required local and CI proof surface. `Stripe` remains the default first-user path. `Braintree` is the locked second-provider target because it best matches Accrue's Stripe-shaped direct-gateway facade without pulling the repo into a merchant-of-record or finance-system strategy.

## Lane framing

- **Fake:** deterministic local and merge-blocking CI proof lane.
- **Stripe:** current first-user production path and reference implementation for broader surface area.
- **Braintree:** locked Stripe-like gateway target for the official second-provider track.
- **Custom processors:** extension-point adapters outside first-party support, parity promises, release gates, and the official matrix unless named explicitly here.

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
| customer.update | Required | Required | Required target | all first-party |
| payment_method.vault_acquisition | Deterministic proof | Supported | Required target | all first-party |
| subscription.direct_create | Required | Required | Required target | all first-party |
| subscription.fetch | Required | Required | Required target | all first-party |
| subscription.cancel | Required | Required | Required target | all first-party |
| subscription.lifecycle_webhook_projection | Deterministic projection | Supported | Required target | all first-party |
| invoice.lifecycle_webhook_projection | Deterministic projection | Supported | Required target | all first-party |
| webhook.verify | Required | Required | Required target | all first-party |
| webhook.parse | Required | Required | Required target | all first-party |
| checkout.hosted_handoff | Local proof helper | Supported | No | Stripe-only |
| billing_portal.hosted_self_serve | Local proof helper | Supported | No | Stripe-only |

The `Stripe-only` rows stay visible because they are real public APIs today, but they are not part of the first official second-provider promise. They remain **Stripe-first** until another first-party processor proves them honestly.

## Public facade API mapping

| Public API | Label | Notes |
|------------|-------|-------|
| `Accrue.Billing.subscribe/3` | all first-party | Primary gateway-subscription-core facade for the second-provider slice. |
| `Accrue.Billing.get_subscription/2` | all first-party | Read side required for lifecycle truth on the supported slice. |
| `Accrue.Billing.cancel/2` | all first-party | Cancellation is part of the bounded subscription core. |
| `Accrue.Billing.create_customer/1` | all first-party | Customer creation remains part of the supported facade boundary. |
| `Accrue.Billing.update_customer/2` | all first-party | Customer updates stay inside the bounded support contract. |
| `Accrue.Billing.create_checkout_session/2` | Stripe-only | Valuable public API, but not part of the first official second-provider promise. |
| `Accrue.Billing.create_billing_portal_session/2` | Stripe-only | Valuable public API, but not part of the first official second-provider promise. |
| `Accrue.Billing.list_payment_methods/2` | out of slice | Payment-method CRUD beyond minimal vault acquisition is not in the first slice. |
| `Accrue.Billing.subscribe_via_schedule/3` | out of slice | Advanced subscription scheduling is intentionally deferred. |
| `Accrue.Billing.preview_upcoming_invoice/2` | out of slice | Preview/proration parity is not part of gateway subscription core. |

## Explicit out-of-slice surfaces

The following remain intentionally **out of slice** for first-party second-provider support:

- embedded checkout
- setup/payment intents
- advanced subscription mutation parity such as swaps, quantity updates, pause/resume, schedules, previews, and proration
- refunds
- coupons
- promotion codes
- metering
- Connect

## Provider rationale and exclusions

`Braintree` is the locked second-provider target because it is the closest direct-gateway fit for Accrue's existing Stripe-shaped surface: customer records, vaulted payment methods, recurring subscriptions, transactions, and webhook-backed state convergence. It stays inside the strategy boundary better than enterprise-heavy or wallet-first alternatives, and it offers a tractable Elixir package surface for the next phases.

The following remain explicit non-targets for this track:

- `merchant-of-record` providers such as Paddle, Lemon Squeezy, and FastSpring
- `Adyen`
- `PayPal direct subscriptions`
- bank-debit specialists such as `GoCardless`

## Support-boundary rules

- Unsupported capabilities must **fail clearly and early** via capability checks rather than implying Stripe parity and surprising adopters later.
- Accrue should learn from **Laravel Cashier** by naming provider tracks honestly.
- Accrue should learn from **Pay (Rails)** by keeping the shared surface bounded and warning where provider behavior diverges.
- Accrue should avoid the **ActiveMerchant** trap of over-broad gateway sameness.
- The Ecto / Active Storage / Active Job lesson applies here too: adapter compatibility alone is not first-party support.
