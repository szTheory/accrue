# AccrueAdmin

LiveView admin UI for Accrue billing operations. Versioning tracks the
**[`accrue`](https://hexdocs.pm/accrue/)** package—use the same `~>` range for
both. For a plain-language history of releases (instead of only GitHub release
bullets), see **[Accrue release notes](https://hexdocs.pm/accrue/release-notes.html)**.

## Quickstart

`accrue_admin` stays downstream of the core billing setup. Start with the
checked-in Fake-backed demo or the Accrue First Hour guide, get the core
billing facade and signed webhook path working, then mount the admin UI for
operators.

Add `accrue_admin` to your host application and mount the package router where operators manage billing:

```elixir
defp deps do
  [
    {:accrue_admin, "~> 0.2.0"}
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

Run `mix deps.get`, finish the core billing and signed-webhook path, and then
continue with the package guide on HexDocs for route session options, branding,
and auth details:

- <https://hexdocs.pm/accrue_admin/admin_ui.html>

## Operator copy (tiers)

Contributors should treat operator-facing strings in three tiers (Phase 27 CONTEXT D-03):

- **Tier A — Host contract:** production `accrue_admin` LiveView copy on mounted routes lives in `AccrueAdmin.Copy` (and verbatim legal/replay gates in `AccrueAdmin.Copy.Locked`). Treat changes as host-visible: follow semver and call them out under `### Host-visible copy (accrue_admin)` in this package `CHANGELOG.md`.
- **Tier B — Library demo:** `ComponentKitchenLive` and fixture-heavy previews are non-contract; safe for marketing or instructional tone.
- **Tier C — Dev-only:** routes behind dev flags may use placeholder copy but must not imply safety or compliance the library does not provide.

## Host setup

`accrue_admin` expects the host app to provide browser session state and an `Accrue.Auth` adapter that can resolve an admin-capable operator. The full router mount, branding config, and auth expectations live in the admin UI guide on HexDocs:

- <https://hexdocs.pm/accrue_admin/admin_ui.html>

The first-time host setup path for the core package lives in the Accrue First Hour guide:

- <https://hexdocs.pm/accrue/first_hour.html>

The canonical local demo path lives in the checked-in host app:

- `examples/accrue_host/README.md`

Published `accrue_admin` releases resolve `accrue ~> 0.2.0`. Monorepo development keeps the sibling `../accrue` path dependency unless `ACCRUE_ADMIN_HEX_RELEASE=1` is set for release validation.

## Assets

The package ships its own committed static bundle from `priv/static/`. Rebuild it locally with:

```bash
cd accrue_admin
mix accrue_admin.assets.build
```

No host Tailwind config or JavaScript bootstrap changes are required.

## Browser UAT

**VERIFY-01** in [`examples/accrue_host/README.md`](https://github.com/szTheory/accrue/blob/main/examples/accrue_host/README.md) is the **merge-blocking** path for mounted admin browser proofs on the real example host. The commands below are fast package smoke against the admin fixture endpoint only.

The browser regression suite lives under `e2e/` and runs against the package's test Phoenix endpoint:

```bash
cd accrue_admin
npm ci
npx playwright install chromium
npm run e2e
```

## Guides

- [Admin UI integration guide](https://hexdocs.pm/accrue_admin/admin_ui.html)

## Project policies

- [Contributing guide](https://github.com/szTheory/accrue/blob/main/CONTRIBUTING.md)
- [Code of Conduct](https://github.com/szTheory/accrue/blob/main/CODE_OF_CONDUCT.md)
- [Security policy](https://github.com/szTheory/accrue/blob/main/SECURITY.md)
