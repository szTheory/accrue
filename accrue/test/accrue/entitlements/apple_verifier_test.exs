defmodule Accrue.Entitlements.Apple.VerifierTest do
  use ExUnit.Case, async: true

  Code.require_file("../../fixtures/apple/server_evidence.exs", __DIR__)

  alias Accrue.Entitlements.Apple.Verifier
  alias Accrue.Entitlements.Apple.Verifier.Production
  alias Accrue.Test.AppleServerEvidence, as: Evidence

  @config %Verifier.Config{
    roots: [Evidence.production_root()],
    bundle_id: "com.accrue.test",
    environment: :production,
    app_apple_id: 42,
    verifier_version: "apple-v1",
    config_version: "test-v1"
  }

  test "malformed compact input has a closed error" do
    assert {:error, :invalid_payload} =
             Production.verify_notification(Evidence.malformed(), @config)
  end

  test "a real Apple-purpose ES256 chain verifies only allowlisted transaction facts" do
    assert {:ok, facts} =
             Production.verify_transaction(Evidence.production_transaction(), @config)

    assert facts["expiresDate"] == 1_800_000_000_000

    assert Map.keys(facts) |> Enum.sort() ==
             [
               "appAppleId",
               "bundleId",
               "environment",
               "expiresDate",
               "originalTransactionId",
               "productId",
               "signedDate",
               "transactionId"
             ]
  end

  test "cryptographically valid hostile purpose chains close at the purpose predicate" do
    for kind <- [
          :wrong_leaf_purpose,
          :missing_leaf_purpose,
          :wrong_intermediate_purpose,
          :missing_intermediate_purpose,
          :ca_leaf,
          :missing_digital_signature,
          :ca_signing_only
        ] do
      assert {:error, :invalid_certificate_purpose} =
               Production.verify_transaction(Evidence.hostile_transaction(kind), @config)
    end
  end

  test "algorithm, header, chain, and signature failures are closed" do
    assert {:error, :invalid_algorithm} =
             Production.verify_transaction(
               Evidence.jws(%{"alg" => "none", "x5c" => ["x"]}, Evidence.valid_claims()),
               @config
             )

    assert {:error, :invalid_header} =
             Production.verify_transaction(
               Evidence.jws(
                 %{"alg" => "ES256", "crit" => ["b64"], "x5c" => ["x"]},
                 Evidence.valid_claims()
               ),
               @config
             )

    assert {:error, :invalid_chain} =
             Production.verify_renewal(
               Evidence.jws(%{"alg" => "ES256", "x5c" => ["x"]}, Evidence.valid_claims()),
               @config
             )
  end

  test "verification is stateless and never returns raw signed evidence" do
    input = Evidence.malformed()

    results =
      for _ <- 1..8, do: Task.async(fn -> Production.verify_notification(input, @config) end)

    assert Enum.uniq(Enum.map(results, &Task.await/1)) == [{:error, :invalid_payload}]
  end

  test "closed reasons do not expose fixture or claim bytes" do
    result = Production.verify_notification(Evidence.malformed(), @config)
    refute inspect(result) =~ "not-a-jws"
  end
end
