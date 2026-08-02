defmodule Accrue.Entitlements.OfflineGoldenVectorsTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.OfflineGoldenVectorVerifier
  alias Accrue.Entitlements.DecisionCases

  test "the checked-in signed corpus is a merge-blocking verifier contract" do
    assert {:ok, vectors, observations} = OfflineGoldenVectorVerifier.verify_fixture!()

    assert Enum.map(observations, & &1.id) == Enum.sort(Enum.map(observations, & &1.id))
    assert Enum.map(vectors, & &1["id"]) == Enum.map(observations, & &1.id)
    assert Enum.any?(observations, &(&1.id == "valid_allow" and &1.result == :accept))
    assert Enum.any?(observations, &(&1.id == "valid_signed_denial" and &1.cache == :deny))

    assert expected_tuples(vectors) == observed_tuples(observations)

    Enum.each(observations, fn observation ->
      assert observation.result in [:accept, :reject]

      assert observation.reason in [
               :ok,
               :signature,
               :key,
               :algorithm,
               :device,
               :account,
               :audience,
               :type,
               :malformed,
               :revision,
               :rollback,
               :iat,
               :freshness,
               :disposition,
               :fault_before_replace,
               :fault_after_replace
             ]
    end)
  end

  test "unknown signed disposition is rejected before cache replacement" do
    assert {:ok, vectors, observations} = OfflineGoldenVectorVerifier.verify_fixture!()
    unknown = Enum.find(vectors, &(&1["id"] == "unknown_disposition"))
    observed = Enum.find(observations, &(&1.id == "unknown_disposition"))

    assert unknown["expected_verification"] == "reject"
    assert unknown["expected_reason"] == "disposition"

    assert observed == %{
             id: "unknown_disposition",
             result: :reject,
             reason: :disposition,
             cache: :allow
           }
  end

  test "the reader binds every vector to canonical case, version, disposition, and identity metadata" do
    fixture = offline_fixture()
    assert {:ok, _vectors} = OfflineGoldenVectorVerifier.validate_corpus(fixture)

    [first | rest] = fixture["vectors"]
    canonical = Map.fetch!(Map.new(DecisionCases.all(), &{&1.id, &1}), first["case_id"])

    for {field, value} <- [
          {"case_id", "unknown_case"},
          {"contract_version", "v0.00"},
          {"expected_disposition", "mutated"}
        ] do
      diagnostic = "offline corpus: vector #{first["id"]} #{field}"

      assert {:error, ^diagnostic} =
               OfflineGoldenVectorVerifier.validate_corpus(%{
                 fixture
                 | "vectors" => [Map.put(first, field, value) | rest]
               })
    end

    assert canonical.contract_version == first["contract_version"]

    duplicate = %{fixture | "vectors" => [first, first | rest]}
    duplicate_diagnostic = "offline corpus: vector #{first["id"]} duplicate id"

    assert {:error, ^duplicate_diagnostic} =
             OfflineGoldenVectorVerifier.validate_corpus(duplicate)

    assert {:error, "offline corpus: schema_version"} =
             OfflineGoldenVectorVerifier.validate_corpus(%{fixture | "schema_version" => "v0.00"})
  end

  defp expected_tuples(vectors) do
    Enum.map(vectors, fn vector ->
      {vector["id"], String.to_atom(vector["expected_verification"]),
       String.to_atom(vector["expected_reason"]),
       String.to_atom(vector["expected_cache_disposition"])}
    end)
  end

  defp offline_fixture do
    __DIR__
    |> Path.join("../../../priv/entitlements/v1.59-offline-golden-vectors.json")
    |> File.read!()
    |> Jason.decode!()
  end

  defp observed_tuples(observations),
    do: Enum.map(observations, &{&1.id, &1.result, &1.reason, &1.cache})
end
