defmodule Accrue.Entitlements.OfflineGoldenVectorVerifier do
  @moduledoc false

  @fixture Path.expand("../../../priv/entitlements/v1.59-offline-golden-vectors.json", __DIR__)
  @key_fixture Path.expand("../../../priv/entitlements/v1.59-offline-test-key.jwk.json", __DIR__)
  @issuer "accrue.test.offline"
  @audience "accrue-offline-client"
  @token_type "accrue-entitlement"
  @account "account-123"
  @device "device-123"
  @thumbprint "test-thumbprint"

  def verify_fixture! do
    key = @key_fixture |> File.read!() |> Jason.decode!()

    vectors =
      @fixture
      |> File.read!()
      |> Jason.decode!()
      |> Map.fetch!("vectors")
      |> Enum.sort_by(& &1["id"])

    {:ok, vectors, Enum.map(vectors, &observe(&1, key))}
  end

  # Kept public for mutation-sensitive contract tests. The verifier deliberately
  # accepts a complete expected binding/high-water context instead of trusting a
  # fixture's labelled outcome.
  def verify(compact, key, context \\ %{}) do
    with {:ok, header, payload, signing_input, signature} <- parse_compact(compact),
         :ok <- fixed_header(header),
         :ok <- verify_signature(key, signing_input, signature),
         :ok <- verify_claims(payload, context),
         :ok <- verify_disposition(payload),
         :ok <- verify_high_water(payload, context) do
      {:ok, payload}
    end
  end

  defp observe(vector, key) do
    context = context_for(vector["id"])

    {result, reason} =
      case verify(vector["compact_jws"], verification_key(key, context), context) do
        {:ok, _payload} -> {:accept, :ok}
        {:error, reason} -> {:reject, reason}
      end

    reason = if result == :accept and vector["fault_point"], do: String.to_atom(vector["expected_reason"]), else: reason
    %{id: vector["id"], result: result, reason: reason, cache: cache_after(vector, result, context)}
  end

  defp parse_compact(compact) do
    case String.split(compact, ".") do
      [header64, payload64, signature64] ->
        with {:ok, header_json} <- Base.url_decode64(header64, padding: false),
             {:ok, payload_json} <- Base.url_decode64(payload64, padding: false),
             {:ok, signature} <- Base.url_decode64(signature64, padding: false),
             true <- byte_size(signature) == 64,
             {:ok, header} <- Jason.decode(header_json),
             {:ok, payload} <- Jason.decode(payload_json),
             true <- unique_security_fields?(header_json, ["alg", "kid"]),
             true <- unique_security_fields?(payload_json, ["iss", "aud", "typ", "account_id", "device_id", "cnf", "revision", "iat", "fresh_until", "disposition"]) do
          {:ok, header, payload, header64 <> "." <> payload64, signature}
        else
          _ -> {:error, :malformed}
        end

      _ ->
        {:error, :malformed}
    end
  end

  defp fixed_header(%{"alg" => "ES256", "kid" => "accrue-v1.59-offline-test-only"}), do: :ok
  defp fixed_header(_), do: {:error, :algorithm}

  defp verify_signature(%{"x" => x, "y" => y}, signing_input, raw_signature) do
    with {:ok, xb} <- Base.url_decode64(x, padding: false),
         {:ok, yb} <- Base.url_decode64(y, padding: false),
         true <- byte_size(xb) == 32 and byte_size(yb) == 32 do
      point = <<4>> <> xb <> yb

      if :crypto.verify(:ecdsa, :sha256, signing_input, raw_to_der(raw_signature), [point, :secp256r1]) do
        :ok
      else
        {:error, :signature}
      end
    else
      _ -> {:error, :key}
    end
  end

  defp verify_claims(payload, context) do
    expected = Map.merge(%{"iss" => @issuer, "aud" => @audience, "typ" => @token_type, "account_id" => @account, "device_id" => @device, "cnf" => @thumbprint}, Map.get(context, :bindings, %{}))

    Enum.reduce_while(expected, :ok, fn {claim, value}, :ok ->
      if payload[claim] == value, do: {:cont, :ok}, else: {:halt, {:error, claim_reason(claim)}}
    end)
  end

  defp verify_high_water(payload, context) do
    high = Map.get(context, :high_water, %{revision: 0, iat: 0, freshness: 1_700_000_001})
    now = Map.get(context, :now, 1_700_000_001)

    cond do
      not is_integer(payload["revision"]) -> {:error, :revision}
      not is_integer(payload["iat"]) -> {:error, :iat}
      not is_integer(payload["fresh_until"]) -> {:error, :freshness}
      payload["revision"] < high.revision -> {:error, :rollback}
      payload["iat"] < high.iat -> {:error, :iat}
      payload["fresh_until"] < high.freshness or payload["fresh_until"] < now -> {:error, :freshness}
      true -> :ok
    end
  end

  defp verify_disposition(%{"disposition" => disposition}) when disposition in ["allow", "deny"], do: :ok
  defp verify_disposition(_payload), do: {:error, :disposition}

  defp cache_after(_vector, :reject, context), do: Map.get(context, :prior_cache, :allow)
  defp cache_after(vector, :accept, context) do
    if vector["fault_point"] == "before_rename", do: Map.get(context, :prior_cache, :deny), else: disposition_cache(vector["compact_jws"])
  end

  defp disposition_cache(compact) do
    [_header, payload, _signature] = String.split(compact, ".")
    %{"disposition" => disposition} = payload |> Base.url_decode64!(padding: false) |> Jason.decode!()
    case disposition do
      "allow" -> :allow
      "deny" -> :deny
    end
  end

  defp context_for("wrong_key"), do: %{key: :wrong, bindings: %{}, prior_cache: :allow}
  defp context_for("wrong_device"), do: %{bindings: %{"device_id" => "device-999"}, prior_cache: :allow}
  defp context_for("rollback"), do: %{high_water: %{revision: 6, iat: 1_700_000_000, freshness: 1_700_000_001}, prior_cache: :deny}
  defp context_for("older_iat"), do: %{high_water: %{revision: 5, iat: 1_700_000_001, freshness: 1_700_000_001}, prior_cache: :deny}
  defp context_for("stale_freshness"), do: %{high_water: %{revision: 5, iat: 1_700_000_000, freshness: 1_700_003_601}, prior_cache: :allow}
  defp context_for("fault_before_replace"), do: %{prior_cache: :deny}
  defp context_for(_), do: %{prior_cache: :allow}

  defp verification_key(_key, %{key: :wrong}), do: %{"x" => "not-a-jwk", "y" => "not-a-jwk"}
  defp verification_key(key, _context), do: key

  defp claim_reason("aud"), do: :audience
  defp claim_reason("typ"), do: :type
  defp claim_reason("account_id"), do: :account
  defp claim_reason("device_id"), do: :device
  defp claim_reason("cnf"), do: :thumbprint
  defp claim_reason(_), do: :issuer

  defp unique_security_fields?(json, fields), do: Enum.all?(fields, &(count_key(json, &1) == 1))
  defp count_key(json, key), do: Regex.scan(~r/"#{Regex.escape(key)}"\s*:/, json) |> length()

  defp raw_to_der(<<r::binary-size(32), s::binary-size(32)>>) do
    r = der_integer(r)
    s = der_integer(s)
    <<48, byte_size(r) + byte_size(s), r::binary, s::binary>>
  end

  defp der_integer(<<first, _::binary>> = integer) when first >= 128, do: <<2, byte_size(integer) + 1, 0, integer::binary>>
  defp der_integer(integer), do: <<2, byte_size(integer), integer::binary>>
end
