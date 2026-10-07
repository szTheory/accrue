defmodule AccrueHost.PortalContextAdapter do
  @moduledoc """
  Optional example adapter that resolves the host's active organization and
  rechecks current membership for each Portal action.
  """

  @behaviour Accrue.Portal.Context

  alias AccrueHost.Billing, as: HostBilling
  alias AccrueHost.Accounts.{Organization, User}

  @impl true
  def resolve(%User{} = actor, %{source: :session, values: values}) do
    case {Map.get(values, "portal_billable_selection"), Map.get(values, "active_organization_id")} do
      {"personal", _organization_id} ->
        resolve_personal(actor)

      {nil, id} when is_binary(id) and id != "" ->
        resolve_organization(actor, id)

      {nil, nil} ->
        resolve_personal(actor)

      _ ->
        {:error, :unavailable}
    end
  end

  def resolve(%User{} = actor, %{
        source: :pin,
        values: %{"owner_type" => "Organization", "owner_id" => id}
      }) do
    resolve_organization(actor, id)
  end

  def resolve(%User{} = actor, %{
        source: :pin,
        values: %{"owner_type" => "User", "owner_id" => id}
      }) do
    if id == actor.id do
      {:ok,
       %{
         billable: actor,
         display_name: actor.email,
         display_detail: "Personal billing",
         switch_path: "/app/billing"
       }}
    else
      {:error, :unavailable}
    end
  end

  def resolve(_, _), do: {:error, :unavailable}

  defp resolve_personal(actor) do
    {:ok,
     %{
       billable: actor,
       display_name: actor.email,
       display_detail: "Personal billing",
       switch_path: "/app/billing"
     }}
  end

  @impl true
  def authorize(%User{} = actor, %{billable: billable} = context, action, target) do
    HostBilling.authorize_portal_action(actor, billable, context.customer, action, target)
  end

  def authorize(_, _, _, _), do: {:error, :forbidden}

  defp resolve_organization(actor, id) when is_binary(id) and id != "" do
    case HostBilling.portal_organization_for(actor, id) do
      {:ok, %Organization{} = organization} ->
        {:ok,
         %{
           billable: organization,
           display_name: organization.name,
           display_detail: "Workspace billing",
           switch_path: "/app/billing"
         }}

      error ->
        error
    end
  end

  defp resolve_organization(_, _), do: {:error, :unavailable}
end
