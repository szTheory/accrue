# First Hour

This guide mirrors the checked-in `examples/accrue_host` story in package-facing
terms. Your Phoenix app owns `MyApp.Billing`, routing, auth, runtime config,
and verification choices. Accrue owns the billing engine behind those public
boundaries.

## 1. First run

The first hour should end with one Fake-backed subscription, one signed webhook
proof, mounted admin inspection, and a focused verification pass.

### Install the packages

```elixir
defp deps do
  [
    {:accrue, "~> 0.1.2"},
    {:accrue_admin, "~> 0.1.2"}
  ]
end
```

```bash
mix deps.get
mix accrue.install --billable MyApp.Accounts.User --billing-context MyApp.Billing
```

The checked-in host example is the canonical local evaluation path:

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
browser smoke after the first-run story is already clear.

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
