# First Hour

This guide follows the same host-owned path proved in
`examples/accrue_host`. The app owns `MyApp.Billing`, routing, auth, and
runtime configuration. Accrue owns the billing engine behind that boundary.

## 1. Add the dependency

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
```

## 2. Run the installer

Generate the host billing facade and route snippets from your Phoenix app:

```bash
mix accrue.install --billable MyApp.Accounts.User --billing-context MyApp.Billing
```

If setup validation fails, Accrue raises `Accrue.ConfigError` with a stable
diagnostic code. The [Troubleshooting guide](troubleshooting.md) maps each code
to an exact fix.

## 3. Configure `config/runtime.exs`

Keep processor secrets and environment-specific values in `config/runtime.exs`:

```elixir
import Config

config :accrue, :processor, Accrue.Processor.Fake

config :accrue,
  repo: MyApp.Repo,
  webhook_signing_secret: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")
```

The local first-hour path uses the Fake processor so you can prove the host
integration before introducing live Stripe keys.

## 4. Run database setup

```bash
mix ecto.create
mix ecto.migrate
```

Accrue persists billing state, webhook ingest, and replay history in your host
database, so migrations must run before the app boots cleanly.

## 5. Start Oban with the app

Make sure `Oban` is configured in your supervision tree before you rely on
webhook dispatch, replay, or async follow-up work:

```elixir
children = [
  MyApp.Repo,
  {Oban, Application.fetch_env!(:my_app, Oban)},
  MyAppWeb.Endpoint
]
```

## 6. Mount signed webhook ingest at `/webhooks/stripe`

Add a raw-body pipeline before `Plug.Parsers` consumes the request body, then
mount the Accrue webhook route:

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

Your host handler stays on the public boundary:

```elixir
defmodule MyApp.BillingHandler do
  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(type, event, ctx) do
    MyApp.Billing.handle_webhook(type, event, ctx)
  end
end
```

## 7. Mount `accrue_admin "/billing"` behind host auth

Forward the session key your app already uses and keep the admin UI inside the
browser-authenticated part of the router. `AccrueAdmin.Router.accrue_admin/2`
is the public mount surface:

```elixir
import AccrueAdmin.Router

scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  accrue_admin "/billing",
    session_keys: [:user_token],
    on_mount: [{MyAppWeb.UserAuth, :mount_current_user}]
end
```

`Accrue.Auth` reads that host session context. The host app decides who is
allowed to see billing controls.

## 8. Create a first Fake-backed subscription

Use the generated host facade, not private package tables:

```elixir
user = MyApp.Accounts.get_user!(user_id)

{:ok, subscription} =
  MyApp.Billing.subscribe(user, "price_basic", trial_end: {:days, 14})
```

For test setup, prefer `use Accrue.Test` so your host tests stay on the
supported Fake-backed surface.

## 9. Post a signed `customer.subscription.created` proof

The example host app proves webhook ingest by posting a signed
`customer.subscription.created` payload through `/webhooks/stripe` and
asserting the host handler side effect. Reuse that shape in your app-level
tests instead of calling internal dispatch code.

## 10. Inspect `/billing`

Start the Phoenix server and sign in through your host auth flow:

```bash
mix phx.server
```

Visit `/billing` and confirm the mounted admin UI reflects the subscription you
created through `MyApp.Billing.subscribe/3`.

## 11. Run focused tests

```bash
mix test test/accrue_host/billing_facade_test.exs
mix test test/accrue_host_web/webhook_ingest_test.exs
mix test test/accrue_host_web/admin_mount_test.exs
```

Those proofs cover the host billing facade, signed webhook ingest, and mounted
admin boundary in the same order you configured them.
