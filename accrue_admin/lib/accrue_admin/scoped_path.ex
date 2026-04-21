defmodule AccrueAdmin.ScopedPath do
  @moduledoc false

  alias AccrueAdmin.OwnerScope

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
end
