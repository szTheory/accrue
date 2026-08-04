defmodule AccrueHost.ReferenceScenarioConformanceTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.ReferenceScenarios

  @tag :tracer
  test "the reference host consumes the Apple-to-web scenario by stable ID" do
    scenario = ReferenceScenarios.fetch!("apple_purchase_to_web_login")
    assert scenario.expected.snapshot.revision == 1
    assert scenario.expected.purchase.status == :block
  end
end
