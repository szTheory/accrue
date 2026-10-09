# API Coverage — Existing Braintree JavaScript v3 Hosted Fields boundary

> Full component surface recorded. `INTEGRATE` here means retain and verify the existing Portal invocation through the Phase 236 secure-field journey. `OPT-OUT` means the method is not needed for Phase 236; the existing integration behavior remains unchanged. This phase adds no provider capability. Evidence uses deterministic fixtures and served-browser tests, not a live provider transaction.

The boundary is `BraintreeHostedFields` in `accrue_portal/priv/static/accrue_portal.js`: create a Braintree client from the server token, create iframe fields, tokenize into a single-use nonce, and tear down on abandonment or LiveView destruction. The official [HostedFields API](https://braintree.github.io/braintree-web/current/HostedFields.html), [hosted-fields module](https://braintree.github.io/braintree-web/current/module-braintree-web_hosted-fields.html), and [setup guide](https://developer.paypal.com/braintree/docs/guides/hosted-fields/setup-and-integration/javascript/v3) define the surface.

| capability | decision | reason |
|---|---|---|
| `braintree.client.create` | INTEGRATE | Existing client prerequisite using the server-issued authorization token. |
| `braintree.hostedFields.create` | INTEGRATE | Existing creation of official iframe card fields for the direct add-card and checkout routes. |
| `braintree.hostedFields.supportsInputFormatting` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.addClass` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.clear` | OPT-OUT | Not needed for Phase 236; existing teardown and nonce clearing govern abandonment; existing integration behavior remains unchanged. |
| `HostedFields.focus` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.getChallenges` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.getState` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.getSupportedCardTypes` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.off` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.on` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.removeAttribute` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.removeClass` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.setAttribute` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.setMessage` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.setMonthOptions` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.setPlaceholder` | OPT-OUT | Not needed for Phase 236; existing integration behavior remains unchanged. |
| `HostedFields.teardown` | INTEGRATE | Existing instance teardown on route destruction and abandonment; nonce state is cleared by Portal code. |
| `HostedFields.tokenize` | INTEGRATE | Existing tokenization returns a nonce for server-side mutation; raw card data stays in provider iframes. |

Plans `236-02` and `236-05` preserve and verify the four integrated calls and the nonce/teardown behavior. Opt-outs are explicit component-method decisions, not new product commitments.
