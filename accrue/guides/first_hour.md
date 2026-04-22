# First Hour

This guide mirrors the checked-in `examples/accrue_host` story in package-facing
terms. Your Phoenix app owns `MyApp.Billing`, routing, auth, runtime config,
and verification choices. Accrue owns the billing engine behind those public
boundaries.

## How to enter this guide

This guide is one **spine** with three **entry capsules** — pick where you are starting, then follow the same ordered story (deps → install → runtime → migrations → Oban → webhooks → admin → proof). Public wording and step order stay aligned with [`examples/accrue_host/README.md`](../../examples/accrue_host/README.md#proof-and-verification); when the spine or command vocabulary changes, update that README in the **same** pull request (**D-02**).

### Capsule H — Hex consumer

You already have a Phoenix app. Add Accrue to `mix.exs`, run `mix deps.get`, then `mix accrue.install …` and continue from **§ 1. First run** below (runtime config → migrations → Oban → webhook route → admin mount → subscription + proof).

### Capsule M — Monorepo clone

From the repository root: `cd examples/accrue_host`, run **`mix setup`**, start **`mix phx.server`**, then follow the numbered host README story (subscription → signed webhook → admin → `mix verify`) — the same Fake-backed arc this guide describes in package terms.

### Capsule R — Evaluate / read-only

Shortest read-only path: clone the repo, `cd examples/accrue_host`, run **`mix verify`** or **`mix verify.full`**. For merge-blocking VERIFY-01 detail and Playwright entry points, use [**#proof-and-verification**](../../examples/accrue_host/README.md#proof-and-verification) in the host README when you need more than the bounded proof commands.

## 1. First run

The first hour should end with one Fake-backed subscription, one signed webhook
proof, mounted admin inspection, and a focused verification pass.

### Install the packages

Pre-1.0 **minor** bumps on Hex may include breaking API changes. **`accrue_admin`** is released in **lockstep** with **`accrue`** for each train; keep the two `~>` pins on the **same three-part version**. Patch releases within that minor are the usual safe upgrade path.

```elixir
defp deps do
  [
    {:accrue, "~> 0.3.0"},
    {:accrue_admin, "~> 0.3.0"}
  ]
end
```

```bash
mix deps.get
mix accrue.install --billable MyApp.Accounts.User --billing-context MyApp.Billing
```

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
merge-blocking command matrix, VERIFY-01, and Playwright entry points, see
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
