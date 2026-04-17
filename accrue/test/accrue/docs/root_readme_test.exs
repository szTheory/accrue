defmodule Accrue.Docs.RootReadmeTest do
  use ExUnit.Case, async: true

  @readme Path.expand("../../../../README.md", __DIR__)
  @required_surfaces [
    "MyApp.Billing",
    "use Accrue.Webhook.Handler",
    "use Accrue.Test",
    "AccrueAdmin.Router.accrue_admin/2",
    "Accrue.Auth",
    "Accrue.ConfigError"
  ]
  @required_links [
    "examples/accrue_host/README.md",
    "accrue/guides/first_hour.md",
    "accrue/README.md",
    "accrue_admin/README.md",
    "RELEASING.md",
    "SECURITY.md"
  ]
  @forbidden_surfaces [
    "Accrue.Billing.Customer",
    "Accrue.Webhook.WebhookEvent",
    "Accrue.Events.Event",
    "GenServer.call"
  ]

  test "root readme presents the front door route map and public boundary contract" do
    readme = File.read!(@readme)

    assert readme =~ "Billing state, modeled clearly."

    assert readme =~
             "Accrue is an open-source billing library for Elixir, Ecto, and Phoenix."

    assert readme =~
             "Your app owns the billing facade, routes, auth boundary, and runtime config; Accrue owns the billing engine behind them."

    assert readme =~
             "Start one Fake-backed subscription. Post one signed webhook. Inspect and replay the result in admin. Run the focused proof suite."

    Enum.each(@required_links, fn path ->
      assert readme =~ path
    end)

    Enum.each(@required_surfaces, fn surface ->
      assert readme =~ surface
    end)

    Enum.each(@forbidden_surfaces, fn surface ->
      refute readme =~ surface
    end)

    assert readme =~ "Canonical local demo: Fake"
    assert readme =~ "Provider parity: Stripe test mode"
    assert readme =~ "Advisory/manual: live Stripe"
  end
end
