defmodule Accrue.Entitlements.ReferenceScenarioConformanceTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.ReferenceScenarios

  @tag :tracer
  test "apple purchase to web login is a deterministic shared scenario" do
    scenario = ReferenceScenarios.fetch!("apple_purchase_to_web_login")

    assert scenario.id == "apple_purchase_to_web_login"
    assert scenario.evidence_lane == :deterministic_conformance
    assert scenario.expected.snapshot.revision == 1
    assert scenario.expected.purchase.status == :block
  end
end
