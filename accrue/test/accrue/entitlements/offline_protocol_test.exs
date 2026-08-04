defmodule Accrue.Entitlements.OfflineProtocolTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.Offline

  @issuer "accrue.test.offline"
  @audience "accrue-offline-client"
  @kid "accrue-v1.59-offline-test-only"

  test "a public P-256 JWK verifies one production-profile allow proof" do
    signing_key = signing_key()
    public_key = public_key(signing_key)
    context = verification_context(public_key)

    assert {:ok, %{state: :fresh, reason: :ok, claims: claims}} =
             Offline.verify(compact(signing_key, claims(context)), context)

    assert claims.plans == ["pro"]
    assert claims.features == ["offline_study"]
    assert claims.quantities == %{"downloads" => 3}
    refute Map.has_key?(context.public_keys |> hd(), "d")
  end

  test "strictly bounded D-06 failures close hostile proof inputs" do
    signing_key = signing_key()
    public_key = public_key(signing_key)
    context = verification_context(public_key)
    payload = claims(context)
    valid_compact = compact(signing_key, payload)

    cases = [
      {"wrong algorithm", replace_header(valid_compact, %{"alg" => "HS256"}), :wrong_algorithm},
      {"wrong type", compact(signing_key, payload, %{"typ" => "wrong"}), :wrong_type},
      {"wrong issuer", compact(signing_key, Map.put(payload, "iss", "wrong")), :wrong_issuer},
      {"wrong audience", compact(signing_key, Map.put(payload, "aud", "wrong")), :wrong_audience},
      {"unknown key", compact(signing_key, payload, %{"kid" => "unknown"}), :unknown_key},
      {"remote key header",
       compact(signing_key, payload, %{"jku" => "https://invalid.test/jwks"}), :malformed},
      {"unknown critical header", compact(signing_key, payload, %{"crit" => ["exp"]}),
       :malformed},
      {"malformed compact", "not-a-jws", :malformed},
      {"duplicate issuer", duplicate_issuer_compact(signing_key, payload), :malformed},
      {"invalid signature", invalidate_signature(compact(signing_key, payload)),
       :signature_invalid}
    ]

    for {_name, compact, reason} <- cases do
      assert {:ok, %{state: :invalid, reason: ^reason, claims: nil}} =
               Offline.verify(compact, context)
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
      Map.take(key, ["kty", "crv", "kid", "x", "y"])
      |> Map.put("use", "sig")
      |> Map.put("alg", "ES256")

  defp verification_context(key) do
    %{
      issuer: @issuer,
      audience: @audience,
      account_subject: "account-123",
      installation_id: "device-123",
      device_thumbprint: thumbprint(key),
      now: 1_700_000_001,
      clock_high_water: %{revision: 0, iat: 0, fresh_until: 0},
      accepted_revision: 0,
      accepted_disposition: :allow,
      accepted_iat: 0,
      accepted_fresh_until: 0,
      public_keys: [key]
    }
  end

  defp claims(context) do
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
    }
  end

  defp compact(key, payload, header \\ %{}) do
    header =
      Map.merge(
        %{"alg" => "ES256", "typ" => "accrue-entitlement-proof+jwt", "kid" => @kid},
        header
      )

    key
    |> JOSE.JWK.from()
    |> JOSE.JWS.sign(Jason.encode!(payload), header)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  defp duplicate_issuer_compact(key, payload) do
    payload_json =
      Jason.encode!(payload)
      |> String.replace(~s("iss":"#{@issuer}"), ~s("iss":"#{@issuer}","iss":"#{@issuer}"))

    key
    |> JOSE.JWK.from()
    |> JOSE.JWS.sign(payload_json, %{
      "alg" => "ES256",
      "typ" => "accrue-entitlement-proof+jwt",
      "kid" => @kid
    })
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  defp invalidate_signature(compact) do
    [header, payload, signature] = String.split(compact, ".")
    {:ok, <<first, rest::binary>>} = Base.url_decode64(signature, padding: false)

    header <>
      "." <>
      payload <>
      "." <>
      Base.url_encode64(<<Bitwise.bxor(first, 1)>> <> rest, padding: false)
  end

  defp replace_header(compact, changes) do
    [_header64, payload, signature] = String.split(compact, ".")

    header =
      %{"alg" => "ES256", "typ" => "accrue-entitlement-proof+jwt", "kid" => @kid}
      |> Map.merge(changes)
      |> Jason.encode!()
      |> Base.url_encode64(padding: false)

    header <> "." <> payload <> "." <> signature
  end

  defp thumbprint(key) do
    key
    |> Map.take(["crv", "kty", "x", "y"])
    |> Jason.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end
end
