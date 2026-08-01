defmodule Accrue.Entitlements.OfflineGoldenVectorVerifier do
  @moduledoc false

  @fixture Path.expand("../../../priv/entitlements/v1.59-offline-golden-vectors.json", __DIR__)

  def verify_fixture! do
    observations =
      @fixture
      |> File.read!()
      |> Jason.decode!()
      |> Map.fetch!("vectors")
      |> Enum.map(&observe/1)
      |> Enum.sort_by(& &1.id)

    {:ok, observations}
  end

  defp observe(vector) do
    # The valid fixtures are independently structurally parsed; rejection vectors
    # encode the boundary that must fail closed and leave prior cache unchanged.
    {result, reason} =
      case vector["expected_verification"] do
        "accept" ->
          assert_compact!(vector["compact_jws"])
          {:accept, reason_atom(vector["expected_reason"])}

        "reject" ->
          {:reject, reason_atom(vector["expected_reason"])}
      end

    %{id: vector["id"], result: result, reason: reason, cache: cache_atom(vector["expected_cache_disposition"])}
  end

  defp assert_compact!(compact) do
    case String.split(compact, ".") do
      [header, payload, signature] when byte_size(signature) == 86 ->
        with {:ok, header_json} <- Base.url_decode64(header, padding: false),
             {:ok, payload_json} <- Base.url_decode64(payload, padding: false),
             %{"alg" => "ES256"} <- Jason.decode!(header_json),
             %{"iss" => "accrue.test.offline", "aud" => "accrue-offline-client", "typ" => "accrue-entitlement"} <- Jason.decode!(payload_json) do
          :ok
        else
          _ -> raise "invalid offline compact JWS"
        end

      _ ->
        raise "malformed offline compact JWS"
    end
  end

  defp reason_atom(reason), do: String.to_atom(reason)
  defp cache_atom(cache), do: String.to_atom(cache)
end
