Code.require_file(Path.expand("../../../../dev_support/phase252_tap_formatter.ex", __DIR__))
ExUnit.start(formatters: [Accrue.Test.Phase252TapFormatter])

unless Code.ensure_loaded?(CadenceSubscriptionFacts) do
  Code.require_file(Path.expand("../../../../dev_support/ui_scenarios/cadence_subscriptions.exs", __DIR__))
end

defmodule AccrueAdmin.SubscriptionPageSliceTest do
  use ExUnit.Case, async: false

  alias AccrueAdmin.Live.SubscriptionLive

  test "the production owner exposes the shared whole subscription page renderer" do
    assert {:module, SubscriptionLive} = Code.ensure_loaded(SubscriptionLive)
    assert function_exported?(SubscriptionLive, :subscription_page, 1)
  end
end
