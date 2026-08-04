defmodule Accrue.Entitlements.OfflineGoldenVectorsTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.OfflineGoldenVectorVerifier
  alias Accrue.Entitlements.DecisionCases

  test "the checked-in signed corpus is a merge-blocking verifier contract" do
    fixture = offline_fixture()

    assert Map.keys(fixture) == [
             "protocol_version",
             "public_jwks",
             "purpose",
             "schema_version",
             "vectors"
           ]

    assert fixture["schema_version"] == "v1.59"
    assert fixture["protocol_version"] == "v1.59"
    assert Map.keys(fixture["public_jwks"]) == ["keys"]
    assert is_list(fixture["public_jwks"]["keys"])

    assert Enum.all?(fixture["vectors"], fn vector ->
             Map.has_key?(vector, "expected_claims") and
               Map.has_key?(vector, "expected_state") and
               Map.has_key?(vector, "expected_next_action") and
               Map.has_key?(vector, "verification_context")
           end)

    assert {:ok, vectors, observations} = OfflineGoldenVectorVerifier.verify_fixture!()

    assert Enum.map(observations, & &1.id) == Enum.sort(Enum.map(observations, & &1.id))
    assert Enum.map(vectors, & &1["id"]) == Enum.map(observations, & &1.id)
    assert Enum.any?(observations, &(&1.id == "valid_allow" and &1.state == :fresh))
    assert Enum.any?(observations, &(&1.id == "valid_signed_denial" and &1.cache == :deny))

    assert expected_tuples(vectors) == observed_tuples(observations)

    Enum.each(observations, fn observation ->
      assert observation.state in [:fresh, :stale_offline, :denied, :invalid]

      assert observation.reason in [
               :ok,
               :revalidation_due,
               :signed_denial,
               :hard_expired,
               :wrong_issuer,
               :wrong_audience,
               :device_mismatch,
               :unknown_key,
               :superseded,
               :clock_rollback,
               :malformed
             ]
    end)
  end

  test "unknown signing key is rejected before cache replacement" do
    assert {:ok, vectors, observations} = OfflineGoldenVectorVerifier.verify_fixture!()
    unknown = Enum.find(vectors, &(&1["id"] == "unknown_kid"))
    observed = Enum.find(observations, &(&1.id == "unknown_kid"))

    assert unknown["expected_state"] == "invalid"
    assert unknown["expected_reason"] == "unknown_key"

    assert %{id: "unknown_kid", state: :invalid, reason: :unknown_key, cache: :allow} = observed
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
      assert {:error, diagnostic} =
               OfflineGoldenVectorVerifier.validate_corpus(%{
                 fixture
                 | "vectors" => [Map.put(first, field, value) | rest]
               })

      assert diagnostic =~ "offline corpus: vector #{first["id"]}"
    end

    assert canonical.contract_version == first["contract_version"]

    duplicate = %{fixture | "vectors" => [first, first | rest]}

    assert {:error, duplicate_diagnostic} =
             OfflineGoldenVectorVerifier.validate_corpus(duplicate)

    assert duplicate_diagnostic =~ "duplicate id"

    assert {:error, "offline corpus: schema"} =
             OfflineGoldenVectorVerifier.validate_corpus(%{fixture | "schema_version" => "v0.00"})
  end

  defp expected_tuples(vectors) do
    Enum.map(vectors, fn vector ->
      {vector["id"], String.to_atom(vector["expected_state"]),
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
    do: Enum.map(observations, &{&1.id, &1.state, &1.reason, &1.cache})
end
