# AccrueAdmin Integration Guide

`accrue_admin` mounts a package-scoped LiveView billing UI inside a host Phoenix app. The package owns its own router macro, private static bundle, and non-prod inspection tools.

Start with the package quickstart in [`README.md`](../README.md), then return here for the host wiring and release checks. Published `accrue_admin` releases depend on the matching `accrue` minor (see Hex for the current `~>` range), while monorepo development keeps the local sibling dependency shape by default.

## UI stack and polish direction

- **Build:** Tailwind CSS v3 compiles [`assets/css/app.css`](../assets/css/app.css) into `priv/static/accrue_admin.css` via `mix accrue_admin.assets.build`. [`assets/tailwind.config.js`](../assets/tailwind.config.js) scans `lib/**/*.{ex,heex}`; [`assets/tailwind_preset.js`](../assets/tailwind_preset.js) maps CSS variables to Tailwind theme colors so utilities stay on the same tokens as `ax-*` rules.
- **Authoring:** Prefer **`ax-*` classes** in `app.css` / `theme.css` for layout, surfaces, and reusable blocks. Add **Tailwind utilities in HEEx** when they reduce duplication (spacing, responsive tweaks) without fighting the preset.
- **Principles:** least surprise for billing operators; clear hierarchy (context → KPIs → primary work area); visible focus states; explicit empty, loading, and error states on lists; microcopy that matches host and Stripe language (subscription, invoice, webhook) unless the screen is intentionally abstracted.
- **Motion:** light CSS transitions on shells, drawers, and modals; honor `prefers-reduced-motion`; reach for LiveView `JS` only when CSS cannot carry the interaction.
- **Responsive:** keep the mounted shell usable on small viewports first; avoid wide horizontal scroll for primary tables unless unavoidable—prefer column discipline and secondary detail surfaces.

## Theming and exceptions

Semantic color and spacing tokens for the mounted admin UI live in [`assets/css/theme.css`](../assets/css/theme.css) and are composed in [`assets/css/app.css`](../assets/css/app.css). If you introduce a **non-token color literal** (for example a one-off hex in HEEx or a fallback brand map in Elixir) during hierarchy or polish work, add a row to the phase registry at [`.planning/phases/26-hierarchy-and-pattern-alignment/26-theme-exceptions.md`](../../.planning/phases/26-hierarchy-and-pattern-alignment/26-theme-exceptions.md) so reviewers can see the exception without spelunking git history.

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

The package reads its brand chrome from `Accrue.Config.branding/0` through the package branding plug. Configure the host app's billing identity once and the admin shell inherits it:

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

The mount macro wires the package auth hook into the LiveSession by default.
`Accrue.Auth` must be able to resolve the current operator from the forwarded
session data, and `session_keys: [:user_token]` is the supported host boundary
for the standard Phoenix auth flow.

The host app remains responsible for browser-session setup before the admin
routes mount. Keep `accrue_admin "/billing"` inside the authenticated browser
scope so `/billing` inherits the same auth boundary as the rest of the app.

## Private Asset Bundle

The package serves its own committed bundle from `priv/static/`. The JavaScript bundle must be **valid ES module output** (not a placeholder): it includes Phoenix + LiveView so admin `phx-click` interactions work in the browser. Rebuild it locally with:

```bash
cd accrue_admin
mix accrue_admin.assets.build
```

That task only touches:

- `priv/static/accrue_admin.css`
- `priv/static/accrue_admin.js`

No host Tailwind config edits or host JavaScript bootstrap changes are required.

## Release Verification

CI and local publish dry runs must force the Hex-safe sibling dependency shape:

```bash
cd accrue_admin
export ACCRUE_ADMIN_HEX_RELEASE=1
```

Use this release gate before shipping or validating publish automation:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix credo --strict
mix docs --warnings-as-errors
mix dialyzer --format github
mix hex.audit
mix hex.build
mix hex.publish --dry-run
```

## Browser UAT

Phase 7 operator verification is automated with Playwright specs under `e2e/`. The suite starts a local test Phoenix endpoint, seeds deterministic billing data, and runs the dashboard, webhook replay, bulk DLQ replay, and step-up refund flows in desktop and mobile Chromium profiles.

Run it locally with:

```bash
cd accrue_admin
npm ci
npx playwright install chromium
npm run e2e
```

CI runs the same suite in `.github/workflows/accrue_admin_browser.yml` with Postgres and uploads Playwright traces on failure.

To replay the GitHub Actions job locally with `act`:

```bash
act workflow_dispatch \
  -W .github/workflows/accrue_admin_browser.yml \
  -j browser-uat
```

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
