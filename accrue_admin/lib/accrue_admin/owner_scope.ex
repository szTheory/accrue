defmodule AccrueAdmin.OwnerScope do
  @moduledoc false

  alias Accrue.Auth

  @owner_scope_session_keys [
    :active_organization_id,
    :active_organization_slug,
    :active_organization_name,
    :admin_organization_ids
  ]

  @enforce_keys [:mode, :current_admin, :platform_admin?, :admin_org_ids]
  defstruct [
    :mode,
    :current_admin,
    :organization_id,
    :organization_slug,
    :organization_display_name,
    :platform_admin?,
    :admin_org_ids,
    :active_organization_id,
    :active_organization_slug
  ]

  @type mode :: :global | :organization

  @type t :: %__MODULE__{
          mode: mode(),
          current_admin: map() | struct(),
          organization_id: String.t() | nil,
          organization_slug: String.t() | nil,
          organization_display_name: String.t() | nil,
          platform_admin?: boolean(),
          admin_org_ids: [String.t()],
          active_organization_id: String.t() | nil,
          active_organization_slug: String.t() | nil
        }

  @type error_reason :: :unauthenticated | :forbidden | :not_found

  @spec session_keys() :: [atom()]
  def session_keys, do: @owner_scope_session_keys

  @doc """
  Human-readable label for tenant chrome when `?org=` scope is active.
  Prefers the host-session `active_organization_name` when set; otherwise the
  verified session slug (never the raw query param alone).
  """
  @spec active_organization_banner_name(t()) :: String.t() | nil
  def active_organization_banner_name(%__MODULE__{mode: :organization} = scope) do
    cond do
      is_binary(scope.organization_display_name) and
          String.trim(scope.organization_display_name) != "" ->
        String.trim(scope.organization_display_name)

      is_binary(scope.organization_slug) and scope.organization_slug != "" ->
        scope.organization_slug

      true ->
        nil
    end
  end

  def active_organization_banner_name(_), do: nil

  @spec resolve(map(), map()) :: {:ok, t()} | {:error, error_reason()}
  def resolve(session, params) when is_map(session) and is_map(params) do
    user = Auth.current_user(session)
    platform_admin? = Auth.admin?(user)
    active_organization_id = session_value(session, "active_organization_id")
    active_organization_slug = session_value(session, "active_organization_slug")
    admin_org_ids = normalize_admin_org_ids(session_value(session, "admin_organization_ids"))
    requested_slug = requested_slug(params)
    organization_display_name = trimmed_session_string(session, "active_organization_name")

    cond do
      is_nil(user) ->
        {:error, :unauthenticated}

      is_nil(requested_slug) and platform_admin? ->
        {:ok,
         %__MODULE__{
           mode: :global,
           current_admin: user,
           organization_id: nil,
           organization_slug: nil,
           organization_display_name: organization_display_name,
           platform_admin?: true,
           admin_org_ids: admin_org_ids,
           active_organization_id: active_organization_id,
           active_organization_slug: active_organization_slug
         }}

      is_nil(requested_slug) ->
        {:error, :forbidden}

      is_nil(active_organization_id) or is_nil(active_organization_slug) ->
        {:error, :not_found}

      requested_slug != active_organization_slug ->
        {:error, :not_found}

      platform_admin? or active_organization_id in admin_org_ids ->
        {:ok,
         %__MODULE__{
           mode: :organization,
           current_admin: user,
           organization_id: active_organization_id,
           organization_slug: active_organization_slug,
           organization_display_name: organization_display_name,
           platform_admin?: platform_admin?,
           admin_org_ids: admin_org_ids,
           active_organization_id: active_organization_id,
           active_organization_slug: active_organization_slug
         }}

      true ->
        {:error, :not_found}
    end
  end

  defp requested_slug(params) do
    params["org"] || params[:org]
  end

  defp session_value(session, key) do
    Map.get(session, key, Map.get(session, String.to_atom(key)))
  end

  defp normalize_admin_org_ids(ids) when is_list(ids) do
    ids
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end

  defp normalize_admin_org_ids(_ids), do: []

  defp trimmed_session_string(session, key) do
    case session_value(session, key) do
      value when is_binary(value) ->
        trimmed = String.trim(value)
        if trimmed == "", do: nil, else: trimmed

      _ ->
        nil
    end
  end
end
