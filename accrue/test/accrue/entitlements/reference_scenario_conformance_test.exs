defmodule Accrue.Entitlements.ReferenceScenarioConformanceTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.ReferenceScenarios

  @tag :tracer
  test "apple purchase to web login exposes closed production operation inputs" do
    scenario = ReferenceScenarios.fetch!("apple_purchase_to_web_login")

    assert scenario.id == "apple_purchase_to_web_login"
    assert scenario.evidence_lane == :deterministic_conformance
    assert scenario.expected.snapshot.revision == 1
    assert scenario.expected.purchase.status == :block
    assert [%{kind: "apple_verified_purchase", operation: operation} | _] = scenario.actions
    assert operation.rail == :apple
    assert operation.logical_product == "pro"
    assert ReferenceScenarios.valid?(scenario)
  end

  test "the loader exposes only the closed scenario contract" do
    refute ReferenceScenarios.valid?(%{id: "apple_purchase_to_web_login"})
    assert "apple_purchase_to_web_login" in Enum.map(ReferenceScenarios.all(), & &1.id)
  end

  test "deterministic proof scenarios cover the required boundary IDs" do
    ids = ReferenceScenarios.all() |> Enum.map(& &1.id) |> MapSet.new()

    assert MapSet.subset?(
             MapSet.new([
               "stripe_purchase_to_ios_login",
               "duplicate_purchase_prevention",
               "stale_downloaded_study_continuity",
               "offline_reconnect",
               "refund_revocation",
               "survivor_grant",
               "device_replacement",
               "deny_tombstone",
               "clock_rollback",
               "key_rotation",
               "empty_evidence_fails_closed",
               "equal_order_stability",
               "repeat_idempotency",
               "parallel_execution",
               "interrupted_resume"
             ]),
             ids
           )
  end

  test "only deterministic rows form the merge-blocking enumeration" do
    merge_blocking_ids =
      ReferenceScenarios.all()
      |> Enum.filter(&(&1.evidence_lane == :deterministic_conformance))
      |> Enum.map(& &1.id)

    assert "apple_purchase_to_web_login" in merge_blocking_ids
    refute "crosswake_runtime_capability" in merge_blocking_ids
    refute "provider_advisory_parity" in merge_blocking_ids
  end
end
