defmodule AccrueAdmin.ScopedPath do
  @moduledoc false

  alias AccrueAdmin.OwnerScope

  @return_routes %{
    "/subscriptions" => ~w(view status q sort direction cursor customer_id),
    "/customers" => ~w(q owner_type has_default_payment_method sort direction cursor tab),
    "/invoices" => ~w(q status sort direction cursor),
    "/payments" => ~w(q status sort direction cursor)
  }
  @return_value_limits %{
    "view" => 32,
    "status" => 128,
    "q" => 200,
    "sort" => 64,
    "direction" => 8,
    "cursor" => 2_048,
    "customer_id" => 128,
    "tab" => 32,
    "owner_type" => 64,
    "has_default_payment_method" => 8
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
    case validate_return_path(mount_path, raw_return_path) do
      {:ok, suffix, params} -> build(mount_path, suffix, owner_scope, params)
      :error -> build(mount_path, "/subscriptions", owner_scope)
    end
  end

  def return_path(mount_path, _raw_return_path, owner_scope),
    do: build(mount_path, "/subscriptions", owner_scope)

  defp validate_return_path(_mount_path, raw) when not is_binary(raw), do: :error

  defp validate_return_path(mount_path, raw) when byte_size(raw) <= 4_096 do
    uri = URI.parse(raw)

    with true <-
           is_nil(uri.scheme) and is_nil(uri.host) and is_nil(uri.userinfo) and
             is_nil(uri.fragment),
         {suffix, allowed_keys} <- return_route(mount_path, uri.path),
         true <- is_binary(uri.query) do
      params =
        uri.query
        |> URI.decode_query()
        |> Enum.filter(fn {key, value} ->
          key in allowed_keys and safe_return_value?(key, value)
        end)
        |> Map.new()

      {:ok, suffix, params}
    else
      _ -> :error
    end
  rescue
    ArgumentError -> :error
  end

  defp validate_return_path(_mount_path, _raw), do: :error

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
      (key != "view" or value in ["all", "at_risk"]) and
      (key != "direction" or value in ["asc", "desc"]) and
      (key != "tab" or value in ~w(subscriptions invoices payments))
  end
end
