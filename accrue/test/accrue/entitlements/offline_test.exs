defmodule Accrue.Entitlements.OfflineTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.Offline

  @issuer "accrue.test.offline"
  @audience "accrue-offline-client"
  @kid "accrue-v1.59-offline-test-only"

  describe "four-state proof classification" do
    test "is fresh before fresh_until and stale at and after it without a derived 72-hour expiry" do
      signing_key = signing_key()
      public_key = public_key(signing_key)
      base = verification_context(public_key, 1_700_003_600)
      proof = compact(signing_key, claims(base, %{"exp" => 1_700_400_000}))

      assert {:ok, %{state: :fresh, reason: :ok}} =
               Offline.verify(proof, %{base | now: 1_700_003_599})

      assert {:ok, %{state: :stale_offline, reason: :revalidation_due}} =
               Offline.verify(proof, base)

      assert {:ok, %{state: :stale_offline, reason: :revalidation_due}} =
               Offline.verify(proof, %{base | now: 1_700_262_801})
    end

    test "hard-expires at and after exp and rejects temporal precision and order failures" do
      signing_key = signing_key()
      public_key = public_key(signing_key)
      base = verification_context(public_key, 1_700_007_200)

      assert {:ok, %{state: :invalid, reason: :hard_expired}} =
               Offline.verify(compact(signing_key, claims(base)), base)

      for changes <- [
            %{"exp" => 1_700_003_599},
            %{"iat" => 1_700_000_000.5},
            %{"nbf" => base.now + 1},
            %{"fresh_until" => 1_700_007_201}
          ] do
        assert {:ok, %{state: :invalid}} =
                 Offline.verify(compact(signing_key, claims(base, changes)), base)
      end
    end

    test "deny wins at equal revision and lower revisions, older issuance, regressed freshness, and clocks fail closed" do
      signing_key = signing_key()
      public_key = public_key(signing_key)
      base = verification_context(public_key, 1_700_000_001)

      deny_context = %{base | accepted_revision: 2, accepted_disposition: :deny}

      assert {:ok, %{state: :denied, reason: :signed_denial}} =
               Offline.verify(
                 compact(
                   signing_key,
                   claims(base, %{
                     "revision" => 2,
                     "disposition" => "deny",
                     "denial_reason" => "access_unavailable",
                     "plans" => [],
                     "features" => [],
                     "quantities" => %{}
                   })
                 ),
                 deny_context
               )

      for {context, changes} <- [
            {%{base | accepted_revision: 2}, %{"revision" => 1}},
            {%{base | accepted_revision: 1, accepted_iat: 1_700_000_001}, %{}},
            {%{base | accepted_revision: 1, accepted_fresh_until: 1_700_003_601}, %{}},
            {%{base | clock_high_water: %{now: base.now + 1}}, %{}}
          ] do
        assert {:ok, %{state: :invalid, reason: reason}} =
                 Offline.verify(compact(signing_key, claims(base, changes)), context)

        assert reason in [:superseded, :clock_rollback]
      end
    end

    test "normalizes only sorted effective allow authority and rejects empty or malformed members" do
      signing_key = signing_key()
      public_key = public_key(signing_key)
      base = verification_context(public_key, 1_700_000_001)

      for changes <- [
            %{"plans" => [], "features" => [], "quantities" => %{}},
            %{"plans" => ["pro", "pro"]},
            %{"features" => ["z", "a"]},
            %{"quantities" => %{"downloads" => 0}},
            %{"plans" => [nil]}
          ] do
        assert {:ok, %{state: :invalid}} =
                 Offline.verify(compact(signing_key, claims(base, changes)), base)
      end
    end
  end

  defp signing_key do
    __DIR__
    |> Path.join("../../../priv/entitlements/v1.59-offline-test-key.jwk.json")
    |> File.read!()
    |> Jason.decode!()
  end

  defp public_key(key),
    do:
      key
      |> Map.take(["kty", "crv", "kid", "x", "y"])
      |> Map.merge(%{"use" => "sig", "alg" => "ES256"})

  defp verification_context(key, now) do
    %{
      issuer: @issuer,
      audience: @audience,
      account_subject: "account-123",
      installation_id: "device-123",
      device_thumbprint: thumbprint(key),
      now: now,
      clock_high_water: %{revision: 0, iat: 0, fresh_until: 0},
      accepted_revision: 0,
      accepted_disposition: nil,
      accepted_iat: 0,
      accepted_fresh_until: 0,
      public_keys: [key]
    }
  end

  defp claims(context, changes \\ %{}) do
    Map.merge(
      %{
        "version" => "v1.59",
        "iss" => @issuer,
        "aud" => @audience,
        "jti" => "token-123",
        "sub" => context.account_subject,
        "cnf" => %{"jkt" => context.device_thumbprint},
        "revision" => 1,
        "iat" => 1_700_000_000,
        "nbf" => 1_700_000_000,
        "fresh_until" => 1_700_003_600,
        "exp" => 1_700_007_200,
        "disposition" => "allow",
        "plans" => ["pro"],
        "features" => ["offline_study"],
        "quantities" => %{"downloads" => 3}
      },
      changes
    )
  end

  defp compact(key, payload) do
    key
    |> JOSE.JWK.from()
    |> JOSE.JWS.sign(Jason.encode!(payload), %{
      "alg" => "ES256",
      "typ" => "accrue-entitlement-proof+jwt",
      "kid" => @kid
    })
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  defp thumbprint(key),
    do:
      key
      |> Map.take(["crv", "kty", "x", "y"])
      |> Jason.encode!()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.url_encode64(padding: false)
end
