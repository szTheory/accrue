# AccrueAdmin Integration Guide

`accrue_admin` mounts a package-scoped LiveView billing UI inside a host Phoenix app. The package owns its own router macro, private static bundle, and non-prod inspection tools.

## Host Setup

Add the package to your router and mount it where operators expect billing controls:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  import AccrueAdmin.Router

  scope "/" do
    pipe_through [:browser]

    accrue_admin "/billing",
      session_keys: [:user_token],
      on_mount: [{MyAppWeb.UserAuth, :mount_current_user}]
  end
end
```

`accrue_admin "/billing"` creates:

- hashed package asset routes under `/billing/assets/*`
- the main billing LiveView routes under `/billing/*`
- compile-gated dev routes under `/billing/dev/*` only outside `MIX_ENV=prod`

## Branding

The package reads its brand chrome from `Accrue.Config.branding/0` via `AccrueAdmin.BrandPlug`. Configure the host app's billing identity once and the admin shell inherits it:

```elixir
config :accrue,
  branding: [
    business_name: "Acme Corp",
    from_email: "billing@acme.test",
    support_email: "support@acme.test",
    logo_url: "https://example.test/logo.svg",
    accent_color: "#5E9E84"
  ]
```

## Auth Expectations

The mount macro wires `AccrueAdmin.AuthHook` into the LiveSession by default. `Accrue.Auth.current_user/1` must return an admin-capable user for the forwarded session keys, and the host app remains responsible for browser-session setup before the admin routes mount.

## Private Asset Bundle

The package serves its own committed bundle from `priv/static/`. Rebuild it locally with:

```bash
cd accrue_admin
mix accrue_admin.assets.build
```

That task only touches:

- `priv/static/accrue_admin.css`
- `priv/static/accrue_admin.js`

No host Tailwind config edits or host JavaScript bootstrap changes are required.

## Dev-Only Surfaces

Outside prod builds, a floating dev toolbar links to:

- `/billing/dev/clock`
- `/billing/dev/email-preview`
- `/billing/dev/webhook-fixtures`
- `/billing/dev/components`
- `/billing/dev/fake-inspect`

Those pages are hidden entirely from prod builds and also refuse to expose tooling unless the configured processor is `Accrue.Processor.Fake`.

## Prod Compile Guarantee

`accrue_admin` enforces the dev surface in two layers:

- compile time: the dev LiveViews, toolbar component, and `/billing/dev/*` routes are only defined when `Mix.env() != :prod`
- runtime: even in `:dev` and `:test`, the pages render only when `Application.get_env(:accrue, :processor)` is `Accrue.Processor.Fake`

Use `MIX_ENV=prod mix compile` in `accrue_admin/` as the smoke check that the package ships without any dev-only admin tooling in production builds.
