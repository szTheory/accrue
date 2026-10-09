# API Coverage — Phase 235 selected-offer checkout

> Full coverage is the default for this phase's Stripe hosted-checkout and Braintree mounted-checkout surfaces. This ledger is scoped to checkout operations; it does not claim full coverage of either provider's wider API. Automated phase evidence uses deterministic SDK stubs, provider fakes, and persisted fixtures; it does not claim live-provider outcomes.

The Braintree mounted path generates a client token, initializes Hosted Fields, tokenizes in the browser, submits the resulting nonce to the existing server route, and creates a subscription. The Braintree checkout locator and post-submit result use the local persisted `LocalSession`. The Stripe hosted path creates a Checkout Session and retrieves it by the returned `cs_` identifier before treating a return as paid. Phase plans and code: `235-01` through `235-06`, `accrue_portal/priv/static/accrue_portal.js`, `accrue_portal/lib/accrue_portal/braintree_client.ex`, `accrue/lib/accrue/processor/braintree.ex`, `accrue/lib/accrue/processor/stripe.ex`, and `accrue/lib/accrue/checkout.ex`.

| capability | decision | reason |
|---|---|---|
| `Braintree.ClientToken.generate` for the selected Customer | INTEGRATE | Supplies the authorization token required to initialize the existing mounted checkout. |
| Braintree JavaScript `client.create` | INTEGRATE | Creates the browser client from the server-issued token. |
| Braintree JavaScript `hostedFields.create` | INTEGRATE | Mounts the provider-owned secure card fields used by the visible checkout form. |
| Braintree JavaScript `HostedFields.tokenize` | INTEGRATE | Produces the one-time nonce submitted to the existing server checkout route; raw card details remain in provider iframes. |
| Braintree JavaScript `HostedFields.teardown` and client `teardown` | INTEGRATE | Releases fields/client on route destruction, stale setup, and retry lifecycle paths. |
| Braintree `Subscription.create` (nonce + selected plan) | INTEGRATE | Executes the existing supported subscription checkout through `Accrue.Billing.subscribe/3`. |
| Braintree `Subscription.find` to establish return completion | OPT-OUT | The mounted path resolves its scoped persisted `LocalSession`; no provider fetch is needed or used for the return. |
| Braintree `Transaction.sale` for one-time checkout | OPT-OUT | Phase 235 creates subscriptions through `Subscription.create`; one-time charges are outside this checkout contract. |
| Braintree remote checkout-session create/fetch | OPT-OUT | Braintree checkout locators are local `LocalSession` records, not a remote provider Checkout Session. |
| Other Braintree billing APIs | OPT-OUT | Customer/payment-method work, lifecycle changes, refunds, webhooks, and portal operations are outside selected-offer checkout and remain under their existing owners. |
| Stripe `Checkout.Session.create` for hosted selected-offer checkout | INTEGRATE | Preserves the existing hosted Stripe handoff and its trusted selected-offer terms. |
| Stripe `Checkout.Session.retrieve` by `cs_` locator | INTEGRATE | The return path fetches authoritative provider state before projecting a paid checkout as complete. |
| Stripe Checkout Session update, expire, or remote cancellation | OPT-OUT | Phase 235 cancellation is a safe return/navigation path and does not mutate a hosted provider session. |
| Other Stripe billing APIs | OPT-OUT | PaymentIntent/SetupIntent, subscription mutation, refunds, customer/webhook, and Billing Portal operations are outside this checkout path and remain under their existing owners. |
