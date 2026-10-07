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

Without an adapter, the portal resolves the signed-in person to that person's
existing Accrue Customer. Hosts that need emailed-link checkout must add their
own `/checkout/start?token=...` bootstrap endpoint before redirecting into the
mounted portal.

## Mount

```elixir
import AccruePortal.Router

accrue_portal "/billing", session_keys: [:user_token]
```

Mount `accrue_admin "/admin"` and `accrue_portal "/billing"` as sibling scopes.

## Optional host-owned billable context

Personal-only hosts can keep the simple mount above. It needs no organization,
account picker, role vocabulary, or custom callback. When one signed-in person
can bill a personal account or a host-owned organization, add an adapter mount
and pass only the session keys that identify the actor and current host
selection:

```elixir
accrue_portal "/shared-billing",
  session_keys: [:user_token, :active_organization_id, :portal_billable_selection],
  login_path: "/users/log-in",
  context_adapter: MyApp.PortalContextAdapter
```

The adapter implements the public `Accrue.Portal.Context` callbacks. `resolve/2`
receives the authenticated human and a locator map, then reloads and returns the
selected billable's presentation data. `authorize/4` checks current host policy
for every named action and the server-loaded target:

```elixir
defmodule MyApp.PortalContextAdapter do
  @behaviour Accrue.Portal.Context

  @impl true
  def resolve(_actor, _selection), do: {:error, :unavailable}

  @impl true
  def authorize(_actor, _context, _action, _target), do: {:error, :forbidden}
end
```

These deny-all bodies are a safe compileable starting point, not a working
integration. Replace them with current host queries and action policy; the
canonical [example adapter](../examples/accrue_host/lib/accrue_host/portal_context_adapter.ex)
shows personal, organization, and mixed resolution.

`resolve/2` returns `{:ok, %{billable: struct, display_name: binary}}` and may
also return `display_detail` and `switch_path`; `{:error, :forbidden}` and
`{:error, :unavailable}` stop the flow. The host's authenticated human (`actor`),
the selected `billable`, its exact Accrue `Customer`, configured `processor`,
and each protected `target` stay separate. The signed-in person is not replaced
with an organization in `current_user`.

`authorize/4` receives this named action vocabulary:

`:read`, `:manage_payment_methods`, `:payment_method_create`,
`:payment_method_default`, `:payment_method_delete`, `:manage_subscription`,
`:subscription_cancel`, `:subscription_change`, `:subscription_preview`,
`:checkout_validate_promo`, and `:checkout_complete`.

Selection values are host-owned session keys when `source: :session`; when
`source: :pin`, values identify the pinned `owner_type` and lossless `owner_id`.
The resolver must look up that identity again, verify current membership, and
return the same billable. Never fall back to a personal account, first
organization, other Customer, or operator account for an invalid, deleted, or
revoked selection. Accrue resolves the exact owner type, owner ID, and
configured processor Customer for custom billables, and authorizes the initial
read before it may provision one. Without an adapter, one existing user-owned
Customer row remains the personal fallback, including its configured
processor; no row may be provisioned, and multiple rows are ambiguous and
blocked.

Portal forms and routes carry a short-lived signed context pin containing the
selected identity and exact Customer/processor locator. The pin keeps separate
tabs attached to the billable they display; it is not a permission grant.
LiveView mounts, reconnects, protected events, and each POST resolve that pin
again and call `authorize/4` for the current action and target. A denial stops
before provider token issuance or mutation, clears pending secure form input,
and does not retry or replay the operation. Existing login behavior remains
controlled by `login_path` for unauthenticated people; an authenticated but
unavailable selection gets the generic Portal blocked page.

If `switch_path` is returned, Accrue accepts only a local path outside the
Portal mount. The value is navigation and presentation data, never authority.
For example, this repository's [`AccrueHost.PortalContextAdapter`](../examples/accrue_host/lib/accrue_host/portal_context_adapter.ex)
uses the host's active organization for custom billing, an explicit personal
selection for mixed use, and the user's own identity when no organization is
selected. Its role names and schema are examples; adopters keep their own.

Portal billing managers remain customer-facing users. Their host-defined
permission to manage one billable does not grant access to `accrue_admin`, which
continues to use the separate `Accrue.Auth` admin authorization boundary.

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
[`accrue/guides/braintree-local-portal.md`](https://github.com/szTheory/accrue/blob/main/accrue/guides/braintree-local-portal.md)
for the deeper mounted-path contract, failure semantics, sibling scope
expectations, and the hand-rolled escape hatch.

## Ownership boundary (thin mirror)

- `accrue_portal` owns mounted self-serve billing UI plus package-local checkout/portal flows.
- Host apps own Repo wiring, migrations, Oban supervision, auth/session continuity, routing policy, runtime secrets, and app-domain membership policy.
- Canonical setup and mount order live in [`accrue/guides/first_hour.md`](https://github.com/szTheory/accrue/blob/main/accrue/guides/first_hour.md).
- Scope and maturity framing live in [`accrue/guides/jobs_to_be_done.md#scope-and-maturity`](https://github.com/szTheory/accrue/blob/main/accrue/guides/jobs_to_be_done.md#scope-and-maturity).
- Stable-core posture policy lives in [`accrue/guides/maturity-and-maintenance.md`](https://github.com/szTheory/accrue/blob/main/accrue/guides/maturity-and-maintenance.md).
