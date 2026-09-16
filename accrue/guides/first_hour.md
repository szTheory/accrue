# First Hour

This guide mirrors the checked-in `examples/accrue_host` story in package-facing
terms. Your Phoenix app owns `MyApp.Billing`, routing, auth, runtime config,
and verification choices. Accrue owns the billing engine behind those public
boundaries. Read-only processor queries such as saved payment methods use
`Accrue.Billing.list_payment_methods/2` (and the host wrapper `MyApp.Billing.list_payment_methods/2` after `mix accrue.install`); see [`guides/telemetry.md`](telemetry.md) for the `[:accrue, :billing, :payment_method, :list]` span.
Server-side checkout session creation uses **`Accrue.Billing.create_checkout_session/2`**
(and your host facade after install); telemetry is **`[:accrue, :billing, :checkout_session, :create]`**
— see [`guides/telemetry.md#billing-checkout-session-create`](telemetry.md#billing-checkout-session-create).

Customer Portal session creation is the parallel server-side helper for
billing self-service.

Server-side billing portal session creation uses **`Accrue.Billing.create_billing_portal_session/2`**
(and your host facade after install); telemetry is **`[:accrue, :billing, :billing_portal, :create]`**
— see [`guides/telemetry.md#billing-billing-portal-create`](telemetry.md#billing-billing-portal-create).

Provider behavior stays honest across the shared facade:

| Provider | Checkout session result | Billing portal result |
| --- | --- | --- |
| Stripe | Upstream hosted URL | Upstream hosted URL |
| Braintree | Mounted local URL | Mounted local URL |

This guide mirrors only the setup-critical needles from the processor support matrix: the shared checkout and portal facade stays provider-honest, `update_customer/2` remains a bounded provider-neutral write-through, `cancel/2` is the shared immediate path, and the official active-subscription-change contract is `swap_plan/3` plus `preview_upcoming_invoice/2`. Preview is the canonical path where supported before commit; `swap_plan/3` is native on Stripe, testing/local-only on Fake, bounded on Braintree when the host configures `:plan_resolver`, and `cancel_at_period_end/2` stays a Fake/Stripe-only scheduled-end path.

## How to enter this guide

This guide is one **spine** with three **entry capsules** — pick where you are starting, then follow the same ordered story (deps → install → runtime → migrations → Oban → webhooks → admin → proof). Public wording and step order stay aligned with [`examples/accrue_host/README.md`](../../examples/accrue_host/README.md#proof-and-verification); when the spine or command vocabulary changes, update that README in the same pull request. Same-PR capsule discipline lives in the contributor map [`scripts/ci/README.md`](../../scripts/ci/README.md).

For **Maturity and maintenance** posture (when to stop speculative doc work, how friction is intake-gated, and what reopens expansion), see [Maturity and maintenance](maturity-and-maintenance.md).

### Capsule H — Hex consumer

You already have a Phoenix app. Add Accrue to `mix.exs`, run `mix deps.get`, then `mix accrue.install …` and continue from **§ 1. First run** below (runtime config → migrations → Oban → webhook route → admin mount → subscription + proof).

### Capsule M — Monorepo clone

From the repository root: `cd examples/accrue_host`, run **`mix setup`**, start **`mix phx.server`**, then follow the numbered host README story (subscription → signed webhook → admin → `mix verify`) — the same Fake-backed arc this guide describes in package terms. **Sigra** is wired in the checked-in demo for convenience and reproducibility, not because production Accrue apps must use it.

### Capsule R — Evaluate / read-only

Shortest read-only path: clone the repo, `cd examples/accrue_host`, run **`mix verify`** or **`mix verify.full`**. For the full browser-proof walkthrough and Playwright entry points, use [**#proof-and-verification**](../../examples/accrue_host/README.md#proof-and-verification) in the host README when you need more than the bounded proof commands.

### Trust boundary (production vs demo)

Production apps integrate billing through host-owned **`Accrue.Auth`**; see [Auth adapters](auth_adapters.md) for adapter choices and wiring contracts. **Sigra** is optional: the demo uses it for deterministic organization billing and CI, not as a blanket production requirement. When you are not on Sigra, follow **Capsule H** and [Organization billing (non-Sigra)](organization_billing.md) for org-scoped Stripe customers. Demo-specific `mix.exs` and setup commands stay in [`examples/accrue_host/README.md`](../../examples/accrue_host/README.md).

When you are preparing a **real** deploy (not the demo loop), walk [Production readiness](production-readiness.md) once — it links the same guides in ship order without duplicating them.

## Stripe-first spine, early Braintree branch

Stay on the default Stripe-hosted path unless you already know you need
Braintree. Stripe remains the fastest first-user production route through this
guide, while the bounded Braintree branch keeps the same public facade with
mounted local checkout and portal behavior.

If you are using Braintree instead, branch early and treat the mounted portal
contract as part of initial setup, not a later polish task:

- add `accrue_portal`
- mount `accrue_portal "/billing"` as a sibling scope beside `accrue_admin`
- set `portal_mount_path` to the mounted portal route
- set `portal_base_url` to an absolute host URL
- configure `:plan_resolver` if you want first-party plan swaps through
  `Accrue.Billing.swap_plan/3` or `accrue_admin`
- use `Accrue.Billing.preview_upcoming_invoice/2` as the canonical
  preview-before-commit path where supported; Braintree remains unsupported
- keep auth/session continuity across the Plug and LiveView portal mounts
- satisfy the Hosted Fields script and CSP contract before opening checkout

That branch stays intentionally short here. Use
[Braintree local portal](braintree-local-portal.md) for the full mounted-path
setup, the packaged `accrue_portal` default story, and the sharp failure modes
to expect when `portal_mount_path`, `portal_base_url`, auth/session state, or
Hosted Fields readiness are wrong.

## 1. First run

The first hour should end with one Fake-backed subscription, one signed webhook
proof, mounted admin inspection, and a focused verification pass.

### Install the packages

> **Hex vs `main`:** The version pins below mirror `accrue/mix.exs` and `accrue_admin/mix.exs` `@version` on the branch you are reading (usually `main` on GitHub). [Hex.pm](https://hex.pm/packages/accrue) / [Hex.pm/packages/accrue_admin](https://hex.pm/packages/accrue_admin) reflect what is published; use HexDocs when you need docs tied to the resolved Hex version.

1. The fenced `~>` pins below track the **Hex-published** SemVer line for the `@version` pair this branch ships with.
2. **`path:`** / monorepo installs must keep **`accrue`** and **`accrue_admin`** on the **same three-part `~>`** (lockstep trains).
3. For the post-1.0 line, treat **`mix.lock`** as the production stability boundary and follow the documented deprecation cycle for breaking changes.

```elixir
defp deps do
  [
    {:accrue, "~> 1.5.1"},
    {:accrue_admin, "~> 1.5.1"}
  ]
end
```

```bash
mix deps.get
mix accrue.install --billable MyApp.Accounts.User --billing-context MyApp.Billing
```

`mix accrue.install` writes compile-time billing schema config to
`config/config.exs`:

```elixir
config :accrue, :billing_schema, "billing"
```

That keeps Accrue-owned billing tables in the Postgres `billing` schema by
default. Use `mix accrue.install --billing-schema public` or set
`config :accrue, :billing_schema, "public"` only when you intentionally want
Accrue tables in the default schema.

The checked-in host example is the canonical local evaluation loop:

```bash
cd examples/accrue_host
mix setup
mix phx.server
```

### Keep runtime config host-owned

Accrue raises `Accrue.ConfigError` when required setup is missing. Keep secrets
and environment-specific values in `config/runtime.exs`:

```elixir
import Config

config :accrue, :processor, Accrue.Processor.Fake

config :accrue, repo: MyApp.Repo

config :accrue, :webhook_signing_secrets, %{
  stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")
}
```

Run your database setup before boot:

```bash
mix ecto.create
mix ecto.migrate
```

Invoice rendering now defaults to Rendro, so the normal invoice path does
not require Chrome. Only hosts that explicitly choose the legacy
Chromic compatibility path need ChromicPDF setup; the deeper renderer and
migration details live in [PDF Rendering](pdf.md).

Start Oban with the app so webhook dispatch and replay work end to end:

```elixir
children = [
  MyApp.Repo,
  {Oban, Application.fetch_env!(:my_app, Oban)},
  MyAppWeb.Endpoint
]
```

### Mount the public billing boundaries

Add signed webhook ingest at `/webhooks/stripe` and keep the handler on the
public callback surface:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  import Accrue.Router

  pipeline :accrue_webhook_raw_body do
    plug Plug.Parsers,
      parsers: [:json],
      pass: ["*/*"],
      json_decoder: Jason,
      body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}
  end

  scope "/webhooks" do
    pipe_through :accrue_webhook_raw_body
    accrue_webhook "/stripe", :stripe
  end
end
```

> **When this fails**
>
> - Raw body / parser order: [Troubleshooting — `ACCRUE-DX-WEBHOOK-RAW-BODY`](troubleshooting.md#accrue-dx-webhook-raw-body)
> - Missing signing secret: [Troubleshooting — `ACCRUE-DX-WEBHOOK-SECRET-MISSING`](troubleshooting.md#accrue-dx-webhook-secret-missing)
> - Webhook behind the wrong pipeline: [Troubleshooting — `ACCRUE-DX-WEBHOOK-PIPELINE`](troubleshooting.md#accrue-dx-webhook-pipeline)
> - **`mix accrue.install`** reruns / conflicts: [Upgrade — installer rerun behavior](upgrade.md#installer-rerun-behavior)

```elixir
defmodule MyApp.BillingHandler do
  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(type, event, ctx) do
    MyApp.Billing.handle_webhook(type, event, ctx)
  end
end
```

Mount `accrue_admin "/billing"` behind your host auth boundary.
`AccrueAdmin.Router.accrue_admin/2` is the public router macro:

```elixir
import AccrueAdmin.Router

scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  accrue_admin "/billing",
    session_keys: [:user_token],
    on_mount: [{MyAppWeb.UserAuth, :mount_current_user}]
end
```

### Prove the first subscription and webhook

Create the first subscription through the generated facade:

```elixir
user = MyApp.Accounts.get_user!(user_id)

{:ok, subscription} =
  MyApp.Billing.subscribe(user, "price_basic", trial_end: {:days, 14})
```

For app-level tests, stay on supported helpers:

```elixir
use Accrue.Test
```

Then post one signed `customer.subscription.created` payload through
`/webhooks/stripe`, visit `/billing`, and confirm the mounted admin UI shows the
resulting billing state plus replay visibility.

Finish the guided path with the focused host proofs:

```bash
mix verify
```

`mix verify` is the focused tutorial proof suite. `mix verify.full` is the
CI-equivalent local gate that adds compile, assets, dev boot, regression, and
browser smoke after the first-run story is already clear. For the authoritative
browser-proof command matrix and Playwright entry points, see
[Proof and verification in the host demo README](../../examples/accrue_host/README.md#proof-and-verification).

## 2. Seeded history

`Seeded history` is for deterministic replay/history evaluation, not for the
main teaching path.

```bash
cd examples/accrue_host
mix setup
mix verify.full
```

Use it when you need replay-ready webhook states, browser smoke fixtures, or
other evaluation setup that should not become public integration guidance.

## 3. Focused verification

- `mix verify` proves the host-owned tutorial arc: installer boundary, first
  subscription through `MyApp.Billing`, signed webhook ingest, mounted
  `/billing` inspection, and replay visibility.
- `mix verify.full` is the CI-equivalent local gate for maintainers.
- `bash scripts/ci/accrue_host_uat.sh` is the repo-root wrapper around that
  same full contract.
- `bash scripts/ci/accrue_host_hex_smoke.sh` is Hex smoke and stays separate
  from the checked-in host demo.
- `mix accrue.install` remains the production setup command for your own host
  app.

## 4. Rerunning mix accrue.install

Reruns refresh **pristine** generated files that still match the Accrue
fingerprint marker; **user-edited** generated files are skipped so local policy
changes are preserved. Unmarked existing files stay skipped unless you opt into
a narrow overwrite, and `--write-conflicts` writes reviewable artifacts under
`.accrue/conflicts/` instead of patching live files blindly — the same contract
as the upgrade guide. See
[Upgrade guide — Installer rerun behavior](upgrade.md#installer-rerun-behavior)
for the full installer rerun semantics.
