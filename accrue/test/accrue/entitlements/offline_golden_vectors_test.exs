defmodule Accrue.Entitlements.OfflineGoldenVectorsTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.OfflineGoldenVectorVerifier

  test "the checked-in signed corpus is a merge-blocking verifier contract" do
    assert {:ok, observations} = OfflineGoldenVectorVerifier.verify_fixture!()

    assert Enum.map(observations, & &1.id) == Enum.sort(Enum.map(observations, & &1.id))
    assert Enum.any?(observations, &(&1.id == "valid_allow" and &1.result == :accept))
    assert Enum.any?(observations, &(&1.id == "valid_signed_denial" and &1.cache == :deny))

    Enum.each(observations, fn observation ->
      assert observation.result in [:accept, :reject]
      assert observation.reason in [:ok, :signature, :key, :device, :rollback, :iat, :freshness, :fault_before_replace, :fault_after_replace]
    end)
  end
end
