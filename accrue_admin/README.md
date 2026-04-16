# AccrueAdmin

LiveView admin UI for Accrue billing operations.

## Quickstart

Add `accrue_admin` to your host application and mount the package router where operators manage billing:

```elixir
defp deps do
  [
    {:accrue_admin, "~> 1.0.0"}
  ]
end
```

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  import AccrueAdmin.Router

  scope "/" do
    pipe_through [:browser]

    accrue_admin "/billing"
  end
end
```

Run `mix deps.get`, configure the host billing app, and continue with the package guide for route session options, branding, and auth integration details.

## Host setup

`accrue_admin` expects the host app to provide browser session state and an `Accrue.Auth` adapter that can resolve an admin-capable operator. The full router mount, branding config, and auth expectations live in the [admin UI guide](guides/admin_ui.md).

Published `accrue_admin` releases resolve `accrue ~> 1.0.0`. Monorepo development keeps the sibling `../accrue` path dependency unless `ACCRUE_ADMIN_HEX_RELEASE=1` is set for release validation.

## Assets

The package ships its own committed static bundle from `priv/static/`. Rebuild it locally with:

```bash
cd accrue_admin
mix accrue_admin.assets.build
```

No host Tailwind config or JavaScript bootstrap changes are required.

## Browser UAT

The browser regression suite lives under `e2e/` and runs against the package's test Phoenix endpoint:

```bash
cd accrue_admin
npm ci
npx playwright install chromium
npm run e2e
```

## Guides

- [Admin UI integration guide](guides/admin_ui.md)

## Project policies

- [Contributing guide](https://github.com/szTheory/accrue/blob/main/CONTRIBUTING.md)
- [Code of Conduct](https://github.com/szTheory/accrue/blob/main/CODE_OF_CONDUCT.md)
- [Security policy](https://github.com/szTheory/accrue/blob/main/SECURITY.md)
