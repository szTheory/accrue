# Accrue Portal

Mounted customer billing portal for Accrue.

`accrue_portal` is the customer-facing sibling to `accrue` and `accrue_admin`.
It gives host apps a package-owned portal mount for subscriptions, payment
methods, invoices, and local checkout flows when a processor uses
first-party-local-portal semantics.

Phase 101 keeps the portal boundary session-resolved-customer-only. Hosts that
need emailed-link checkout must add their own `/checkout/start?token=...`
bootstrap endpoint before redirecting into the mounted portal.

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

## Braintree local checkout

Phase 101 wires Braintree checkout through package-owned Hosted Fields.
`Accrue.Billing.create_checkout_session/2` returns a URL under the mounted
portal path, and the checkout page completes the subscription using the same
core `Accrue.Billing.subscribe/3` flow as the rest of the library.
