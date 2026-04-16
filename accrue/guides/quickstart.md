# Quickstart

## Install

Add Accrue to your host app and fetch dependencies:

```elixir
defp deps do
  [
    {:accrue, "~> 1.0.0"}
  ]
end
```

```bash
mix deps.get
```

## Configure Stripe

Set the processor at config time and keep secrets in `config/runtime.exs`:

```elixir
config :accrue, :processor, Accrue.Processor.Stripe
```

```elixir
config :accrue,
  stripe_secret_key: System.fetch_env!("STRIPE_SECRET_KEY"),
  webhook_signing_secret: System.fetch_env!("STRIPE_WEBHOOK_SIGNING_SECRET")
```

Use placeholder env vars in development and never commit live keys or webhook secrets.

## Run the installer

Run the installer from the host app:

```bash
mix accrue.install
```

The installer wires the generated billing facade, router mounts, and starter config around your host application.

## First subscription

With the generated billing facade in place, create a first subscription through the host boundary:

```elixir
user = MyApp.Accounts.get_user!(user_id)

{:ok, subscription} =
  MyApp.Billing.subscribe(user, "price_basic_monthly",
    payment_method: "pm_card_visa"
  )
```

From there you can preview upcoming invoices, open checkout, receive webhooks, and assert the flow locally with `Accrue.Test`.
