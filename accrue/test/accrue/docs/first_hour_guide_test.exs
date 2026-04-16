defmodule Accrue.Docs.FirstHourGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/first_hour.md"
  @ordered_steps [
    "mix deps.get",
    "mix accrue.install",
    "config/runtime.exs",
    "mix ecto.migrate",
    "Oban",
    "/webhooks/stripe",
    ~s|accrue_admin "/billing"|,
    "MyApp.Billing.subscribe",
    "customer.subscription.created",
    "/billing",
    "mix test"
  ]
  @public_surfaces [
    "MyApp.Billing",
    "use Accrue.Webhook.Handler",
    "use Accrue.Test",
    "AccrueAdmin.Router.accrue_admin/2",
    "Accrue.ConfigError",
    "config :accrue, :webhook_signing_secrets, %{",
    ~s|stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")|
  ]
  @forbidden_surfaces [
    "Accrue.Billing.Customer",
    "Accrue.Billing.Subscription",
    "Accrue.Webhook.WebhookEvent",
    "Accrue.Events.Event",
    "GenServer.call",
    "worker internals"
  ]

  test "first hour guide preserves the Phoenix-order host boundary contract" do
    guide = File.read!(@guide)

    assert_order!(guide, @ordered_steps)

    Enum.each(@public_surfaces, fn surface ->
      assert guide =~ surface
    end)

    Enum.each(@forbidden_surfaces, fn surface ->
      refute guide =~ surface
    end)

    refute guide =~ ~r/webhook_signing_secret(?!s)/
  end

  defp assert_order!(guide, [first | rest]) do
    Enum.reduce(rest, index_of(guide, first), fn step, previous_index ->
      current_index = index_of(guide, step, previous_index + 1)
      assert current_index
      assert previous_index
      assert previous_index < current_index
      current_index
    end)
  end

  defp index_of(binary, pattern, offset \\ 0) do
    length = byte_size(binary) - offset

    case :binary.match(binary, pattern, [{:scope, {offset, length}}]) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end
end
