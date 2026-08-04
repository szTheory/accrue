defmodule Accrue.Entitlements.Offline.KeyProvider do
  @moduledoc """
  Host-owned offline proof signing and public-key material boundary.

  Implementations keep signing custody outside Accrue; only `public_keys/1` is
  consumed by the public JWKS renderer.
  """

  @type public_key :: %{
          required(String.t()) => String.t()
        }

  @callback sign(binary(), keyword()) ::
              {:ok, binary()} | {:error, :unavailable | :config_invalid}
  @callback public_keys(keyword()) :: {:ok, [public_key()]} | {:error, :config_invalid}

  @allowed_members ["alg", "crv", "kid", "kty", "use", "x", "y"]
  @max_kid_bytes 128
  @max_keys 100

  @spec render_public_keys([map()], map()) ::
          {:ok, %{required(String.t()) => [map()]}} | {:error, :config_invalid}
  def render_public_keys(keys, retention_requirements \\ %{})

  def render_public_keys(keys, retention_requirements)
      when is_list(keys) and is_map(retention_requirements) do
    with true <- keys != [] and length(keys) <= @max_keys,
         {:ok, public_keys} <- validate_keys(keys),
         :ok <- validate_retention(public_keys, retention_requirements) do
      {:ok, %{"keys" => Enum.sort_by(public_keys, & &1["kid"])}}
    else
      _ -> {:error, :config_invalid}
    end
  end

  def render_public_keys(_, _), do: {:error, :config_invalid}

  defp validate_keys(keys) do
    case Enum.reduce_while(keys, {MapSet.new(), []}, fn key, {kids, accepted} ->
           case validate_public_key(key) do
             {:ok, public_key} ->
               kid = public_key["kid"]

               if MapSet.member?(kids, kid) do
                 {:halt, :error}
               else
                 {:cont, {MapSet.put(kids, kid), [public_key | accepted]}}
               end

             :error ->
               {:halt, :error}
           end
         end) do
      {_kids, public_keys} -> {:ok, public_keys}
      :error -> {:error, :config_invalid}
    end
  end

  defp validate_public_key(key) when is_map(key) do
    with true <- Map.keys(key) |> Enum.sort() == @allowed_members,
         true <- key["kty"] == "EC" and key["crv"] == "P-256",
         true <- key["use"] == "sig" and key["alg"] == "ES256",
         true <- valid_kid?(key["kid"]),
         {:ok, x} <- Base.url_decode64(key["x"] || "", padding: false),
         {:ok, y} <- Base.url_decode64(key["y"] || "", padding: false),
         true <- byte_size(x) == 32 and byte_size(y) == 32 do
      {:ok, Map.take(key, @allowed_members)}
    else
      _ -> :error
    end
  end

  defp validate_public_key(_), do: :error

  defp validate_retention(public_keys, requirements) when map_size(requirements) <= @max_keys do
    kids = MapSet.new(public_keys, & &1["kid"])

    if Enum.all?(requirements, fn
         {kid, requirement}
         when is_binary(kid) and byte_size(kid) > 0 and byte_size(kid) <= @max_kid_bytes ->
           requirement == :eligible or (requirement == :required and MapSet.member?(kids, kid))

         _ ->
           false
       end),
       do: :ok,
       else: {:error, :config_invalid}
  end

  defp validate_retention(_, _), do: {:error, :config_invalid}

  defp valid_kid?(kid),
    do: is_binary(kid) and byte_size(kid) > 0 and byte_size(kid) <= @max_kid_bytes
end
