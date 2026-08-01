defmodule Accrue.Entitlements.OfflineGoldenVectorsTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.OfflineGoldenVectorVerifier

  test "the checked-in signed corpus is a merge-blocking verifier contract" do
    assert {:ok, vectors, observations} = OfflineGoldenVectorVerifier.verify_fixture!()

    assert Enum.map(observations, & &1.id) == Enum.sort(Enum.map(observations, & &1.id))
    assert Enum.map(vectors, & &1["id"]) == Enum.map(observations, & &1.id)
    assert Enum.any?(observations, &(&1.id == "valid_allow" and &1.result == :accept))
    assert Enum.any?(observations, &(&1.id == "valid_signed_denial" and &1.cache == :deny))

    assert expected_tuples(vectors) == observed_tuples(observations)

    Enum.each(observations, fn observation ->
      assert observation.result in [:accept, :reject]
      assert observation.reason in [:ok, :signature, :key, :algorithm, :device, :account, :audience, :type, :malformed, :revision, :rollback, :iat, :freshness, :disposition, :fault_before_replace, :fault_after_replace]
    end)
  end

  test "unknown signed disposition is rejected before cache replacement" do
    assert {:ok, vectors, observations} = OfflineGoldenVectorVerifier.verify_fixture!()
    unknown = Enum.find(vectors, &(&1["id"] == "unknown_disposition"))
    observed = Enum.find(observations, &(&1.id == "unknown_disposition"))

    assert unknown["expected_verification"] == "reject"
    assert unknown["expected_reason"] == "disposition"
    assert observed == %{id: "unknown_disposition", result: :reject, reason: :disposition, cache: :allow}
  end

  defp expected_tuples(vectors) do
    Enum.map(vectors, fn vector ->
      {vector["id"], String.to_atom(vector["expected_verification"]), String.to_atom(vector["expected_reason"]), String.to_atom(vector["expected_cache_disposition"])}
    end)
  end

  defp observed_tuples(observations), do: Enum.map(observations, &{&1.id, &1.result, &1.reason, &1.cache})
end
