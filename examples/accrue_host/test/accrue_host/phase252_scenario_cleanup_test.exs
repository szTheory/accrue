defmodule AccrueHost.Phase252ScenarioCleanupTest do
  use ExUnit.Case, async: false

  test "the ordinary subscription seed is a checked-in narrow consumer" do
    assert File.regular?("priv/repo/seeds/phase252_subscription_scenarios.exs")
  end
end
