# Accrue Portal

Mounted customer billing portal for Accrue.

`accrue_portal` is the customer-facing sibling to `accrue` and `accrue_admin`.
It gives host apps a package-owned portal mount for subscriptions, payment
methods, invoices, and local checkout flows when a processor uses
first-party-local-portal semantics.

> **Hex vs `main`:** The `{:accrue_portal, "~> …"}` line tracks
> `accrue_portal/mix.exs` `@version` on the branch you are reading
> (typically `main` on GitHub). [Hex.pm](https://hex.pm/packages/accrue_portal)
> publishes that train after release; use HexDocs matched to the resolved Hex
> version when you need portal docs tied to published artifacts.

For Braintree, both checkout and billing portal sessions return mounted local
URLs from your app, not upstream hosted URLs.

The portal boundary stays session-resolved-customer-only. Hosts that need
emailed-link checkout must add their own `/checkout/start?token=...` bootstrap
endpoint before redirecting into the mounted portal.

## Mount

```elixir
import AccruePortal.Router

accrue_portal "/billing", session_keys: [:user_token]
```

Mount `accrue_admin "/admin"` and `accrue_portal "/billing"` as sibling scopes.

## Requirements

- `accrue` configured with a real `:repo` and `:auth_adapter`
- host session contains the keys your auth adapter uses for `Accrue.Auth.current_user/1`
- `portal_mount_path` config matches the mounted route
- `portal_base_url` is set to an absolute host URL so
  `Accrue.Billing.create_checkout_session/2` and
  `Accrue.Billing.create_billing_portal_session/2` return absolute URLs
- Plug and LiveView mounts preserve auth/session continuity for the same customer
- Hosted Fields scripts and CSP are ready before the mounted checkout opens

## Braintree local checkout

The Braintree checkout path wires through package-owned Hosted Fields.
`Accrue.Billing.create_checkout_session/2` returns a URL under the mounted
portal path, and the checkout page completes the subscription using the same
core `Accrue.Billing.subscribe/3` flow as the rest of the library.

This README stays concise by design. Use
[`accrue/guides/braintree-local-portal.md`](../accrue/guides/braintree-local-portal.md)
for the deeper mounted-path contract, failure semantics, sibling scope
expectations, and the hand-rolled escape hatch.
