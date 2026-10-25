defmodule AccrueAdmin.ScopedPath do
  @moduledoc false

  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.{ConnectAccounts, Coupons, Events, PromotionCodes, Webhooks}

  @return_routes %{
    "/subscriptions" => ~w(view status q customer_id),
    "/customers" => ~w(q owner_type has_default_payment_method),
    "/invoices" => ~w(view q status customer_id collection_method),
    "/payments" => ~w(view q status customer_id fees_settled),
    "/analytics/recovery" => ~w(window),
    "/events" => ~w(q type actor_type subject_type source_webhook_event_id),
    "/webhooks" => ~w(type status livemode),
    "/coupons" => ~w(view q valid),
    "/promotion-codes" => ~w(view q active coupon_id),
    "/connect" =>
      ~w(view q type charges_enabled payouts_enabled details_submitted deauthorized needs_attention)
  }
  @return_value_limits %{
    "view" => 32,
    "status" => 128,
    "q" => 200,
    "collection_method" => 64,
    "fees_settled" => 8,
    "customer_id" => 128,
    "tab" => 32,
    "owner_type" => 64,
    "has_default_payment_method" => 8,
    "window" => 8,
    "type" => 128,
    "actor_type" => 128,
    "subject_type" => 128,
    "source_webhook_event_id" => 128,
    "livemode" => 8,
    "valid" => 8,
    "active" => 8,
    "coupon_id" => 128,
    "charges_enabled" => 8,
    "payouts_enabled" => 8,
    "details_submitted" => 8,
    "deauthorized" => 8,
    "needs_attention" => 8
  }

  @doc false
  def build(mount_path, suffix, owner_scope, params \\ %{})

  def build(mount_path, suffix, %OwnerScope{} = owner_scope, params) do
    build(mount_path, suffix, Map.from_struct(owner_scope), params)
  end

  def build(
        mount_path,
        suffix,
        %{mode: :organization, organization_slug: slug},
        params
      )
      when is_binary(slug) do
    mount_path <> suffix <> "?" <> URI.encode_query(Map.put(params, "org", slug))
  end

  def build(mount_path, suffix, _owner_scope, params) when map_size(params) > 0 do
    mount_path <> suffix <> "?" <> URI.encode_query(params)
  end

  def build(mount_path, suffix, _owner_scope, _params), do: mount_path <> suffix

  @doc """
  Validates a local list return URL and rebuilds it inside the current mount and owner scope.

  Only known list routes and their small query allowlists survive. The URL can preserve
  navigation context, but it cannot choose the mount, owner or destination record.
  """
  def return_path(mount_path, raw_return_path, owner_scope)
      when is_binary(mount_path) do
    return_destination(mount_path, raw_return_path, owner_scope, nil, "/subscriptions").path
  end

  def return_path(mount_path, _raw_return_path, owner_scope),
    do: build(mount_path, "/subscriptions", owner_scope)

  @doc false
  def return_path(mount_path, raw_return_path, owner_scope, expected_customer_id)
      when is_binary(mount_path) and is_binary(expected_customer_id) do
    return_destination(
      mount_path,
      raw_return_path,
      owner_scope,
      expected_customer_id,
      "/subscriptions"
    ).path
  end

  def return_path(mount_path, raw_return_path, owner_scope, _expected_customer_id),
    do: return_path(mount_path, raw_return_path, owner_scope)

  @doc """
  Validates a local return origin once and returns its rebuilt path and matching label.

  Only destination-supported route meanings survive; the current owner is applied afresh.
  """
  def return_destination(
        mount_path,
        raw_return_path,
        owner_scope,
        expected_customer_id,
        fallback_suffix
      )
      when is_binary(mount_path) and is_binary(fallback_suffix) do
    case validate_return_path(mount_path, raw_return_path) do
      {:ok, "/customers/" <> customer_id = suffix, params}
      when is_binary(expected_customer_id) and customer_id == expected_customer_id ->
        destination(mount_path, suffix, params, owner_scope)

      {:ok, "/customers/" <> _customer_id, _params} ->
        destination(mount_path, fallback_suffix, %{}, owner_scope)

      {:ok, suffix, params} ->
        destination(mount_path, suffix, params, owner_scope)

      :error ->
        destination(mount_path, fallback_suffix, %{}, owner_scope)
    end
  end

  defp destination(mount_path, suffix, params, owner_scope) do
    %{path: build(mount_path, suffix, owner_scope, params), label: return_label(suffix, params)}
  end

  defp return_label("/customers/" <> _id, %{"tab" => "invoices"}), do: "Back to customer invoices"
  defp return_label("/customers/" <> _id, %{"tab" => "payments"}), do: "Back to customer payments"

  defp return_label("/customers/" <> _id, %{"tab" => "subscriptions"}),
    do: "Back to customer subscriptions"

  defp return_label("/customers/" <> _id, _params), do: "Back to customers"
  defp return_label("/events", _params), do: "Back to events"
  defp return_label("/webhooks", _params), do: "Back to webhooks"
  defp return_label("/coupons", _params), do: "Back to coupons"
  defp return_label("/promotion-codes", _params), do: "Back to promotion codes"
  defp return_label("/connect", _params), do: "Back to Connect accounts"
  defp return_label("/invoices", %{"customer_id" => _}), do: "Back to customer invoices"
  defp return_label("/invoices", _params), do: "Back to invoices"
  defp return_label("/payments", %{"customer_id" => _}), do: "Back to customer payments"
  defp return_label("/payments", _params), do: "Back to payments"
  defp return_label("/subscriptions", %{"customer_id" => _}), do: "Back to customer subscriptions"
  defp return_label("/subscriptions", _params), do: "Back to subscriptions"
  defp return_label("/customers", _params), do: "Back to customers"
  defp return_label("/analytics/recovery", _params), do: "Back to Recovery"
  defp return_label(_, _params), do: "Back to invoices"

  @doc false
  def return_path(mount_path, raw_return_path, owner_scope, expected_customer_id, fallback_suffix)
      when is_binary(fallback_suffix) do
    return_destination(
      mount_path,
      raw_return_path,
      owner_scope,
      expected_customer_id,
      fallback_suffix
    ).path
  end

  defp validate_return_path(_mount_path, raw) when not is_binary(raw), do: :error

  defp validate_return_path(mount_path, raw) when byte_size(raw) <= 4_096 do
    uri = URI.parse(raw)

    with true <-
           is_nil(uri.scheme) and is_nil(uri.host) and is_nil(uri.userinfo) and
             is_nil(uri.fragment),
         {suffix, allowed_keys} <- return_route(mount_path, uri.path),
         true <- is_nil(uri.path) or not String.contains?(uri.path, "\\") do
      params = decode_return_params(uri.query, allowed_keys, uri.path)
      if params == :error, do: :error, else: {:ok, suffix, params}
    else
      _ -> :error
    end
  rescue
    ArgumentError -> :error
  end

  defp validate_return_path(_mount_path, _raw), do: :error

  defp decode_return_params(nil, _allowed_keys, _path), do: %{}

  defp decode_return_params(query, allowed_keys, path) do
    if String.match?(query, ~r/%(?![0-9A-Fa-f]{2})/) do
      :error
    else
      decode_return_pairs(query, allowed_keys, path)
    end
  end

  defp decode_return_pairs(query, allowed_keys, path) do
    pairs = URI.query_decoder(query) |> Enum.to_list()
    keys = Enum.map(pairs, &elem(&1, 0))

    if length(keys) != MapSet.size(MapSet.new(keys)) do
      :error
    else
      supplied =
        pairs
        |> Enum.filter(fn {key, value} ->
          key in allowed_keys and safe_return_value?(key, value)
        end)
        |> Map.new()

      if Enum.any?(pairs, fn {key, value} ->
           key in allowed_keys and not safe_return_value?(key, value)
         end) do
        :error
      else
        normalize_destination_filter(path, supplied)
      end
    end
  rescue
    ArgumentError -> :error
  end

  defp normalize_destination_filter(path, params) do
    {module, extra_keys} =
      cond do
        String.ends_with?(path, "/events") -> {Events, []}
        String.ends_with?(path, "/webhooks") -> {Webhooks, []}
        String.ends_with?(path, "/coupons") -> {Coupons, ["view"]}
        String.ends_with?(path, "/promotion-codes") -> {PromotionCodes, ["view"]}
        String.ends_with?(path, "/connect") -> {ConnectAccounts, ["view"]}
        true -> {nil, []}
      end

    if is_nil(module) do
      params
    else
      filters = Map.drop(params, extra_keys)
      decoded = apply(module, :decode_filter, [filters])

      encoded =
        module
        |> apply(:encode_filter, [decoded])
        |> Map.new(fn {key, value} -> {to_string(key), value} end)

      if map_size(filters) == map_size(encoded) and
           Enum.all?(filters, fn {key, value} ->
             case Map.fetch(encoded, key) do
               {:ok, encoded_value} -> to_string(encoded_value) == value
               :error -> false
             end
           end) do
        Map.merge(encoded, Map.take(params, extra_keys))
      else
        :error
      end
    end
  end

  defp return_route(mount_path, path) do
    Enum.find(@return_routes, fn {route, _keys} -> path == mount_path <> route end) ||
      customer_detail_return_route(mount_path, path)
  end

  defp customer_detail_return_route(mount_path, path) do
    prefix = mount_path <> "/customers/"

    with true <- String.starts_with?(path, prefix),
         id <- String.replace_prefix(path, prefix, ""),
         true <- Ecto.UUID.cast(id) != :error do
      {String.replace_prefix(path, mount_path, ""), ["tab"]}
    else
      _ -> :error
    end
  end

  defp safe_return_value?(key, value) do
    max_bytes = Map.fetch!(@return_value_limits, key)

    is_binary(value) and byte_size(value) <= max_bytes and
      not String.match?(value, ~r/[\x00-\x1F\x7F]/) and
      (key != "view" or value == "all") and
      (key != "window" or value in ["7d", "30d", "90d"]) and
      (key != "tab" or value in ~w(subscriptions invoices payments)) and
      (key != "fees_settled" or value in ["true", "false"])
  end
end
