defmodule AccrueHost.AppleNotificationIngress do
  @moduledoc false
  @behaviour Plug

  alias Accrue.Entitlements.Apple.NotificationPlug

  @impl true
  def init(_opts), do: []

  @impl true
  def call(conn, _opts) do
    :accrue_host
    |> Application.fetch_env!(:apple_notification_ingress)
    |> NotificationPlug.init()
    |> then(&NotificationPlug.call(conn, &1))
  end

  def load_trust_roots!(path) when is_binary(path) and byte_size(path) > 0 do
    with {:ok, pem} <- File.read(path),
         entries when is_list(entries) and entries != [] <- :public_key.pem_decode(pem),
         roots <- Enum.map(entries, &certificate_der!/1) do
      roots
    else
      _ -> raise ArgumentError, "APPLE_TRUST_ROOTS_PEM_PATH must contain PEM certificates"
    end
  end

  def load_trust_roots!(_),
    do: raise(ArgumentError, "APPLE_TRUST_ROOTS_PEM_PATH must contain PEM certificates")

  def decode_product_map!(json, configured_plan_keys)
      when is_binary(json) and byte_size(json) > 0 do
    plan_lookup = configured_plan_lookup!(configured_plan_keys)

    with {:ok, product_map} when is_map(product_map) and map_size(product_map) > 0 <-
           Jason.decode(json) do
      Map.new(product_map, fn
        {product_id, plan}
        when is_binary(product_id) and byte_size(product_id) > 0 and is_binary(plan) and
               byte_size(plan) > 0 ->
          {product_id, configured_plan!(plan, plan_lookup)}

        _ ->
          raise ArgumentError, "APPLE_PRODUCT_MAP_JSON must be a non-empty product-to-plan object"
      end)
    else
      _ ->
        raise ArgumentError, "APPLE_PRODUCT_MAP_JSON must be a non-empty product-to-plan object"
    end
  end

  def decode_product_map!(_, _),
    do: raise(ArgumentError, "APPLE_PRODUCT_MAP_JSON must be a non-empty product-to-plan object")

  defp certificate_der!({:Certificate, der, _}) when is_binary(der) and byte_size(der) > 0,
    do: der

  defp certificate_der!(_),
    do: raise(ArgumentError, "APPLE_TRUST_ROOTS_PEM_PATH must contain PEM certificates")

  defp configured_plan_lookup!(plan_keys) when is_list(plan_keys) and plan_keys != [] do
    if Enum.all?(plan_keys, &is_atom/1) do
      Map.new(plan_keys, &{Atom.to_string(&1), &1})
    else
      raise ArgumentError, "APPLE_PRODUCT_MAP_JSON requires configured entitlement plans"
    end
  end

  defp configured_plan_lookup!(_),
    do: raise(ArgumentError, "APPLE_PRODUCT_MAP_JSON requires configured entitlement plans")

  defp configured_plan!(plan, plan_lookup) do
    case Map.fetch(plan_lookup, plan) do
      {:ok, configured_plan} -> configured_plan
      :error -> raise ArgumentError, "APPLE_PRODUCT_MAP_JSON contains an unknown plan"
    end
  end
end
