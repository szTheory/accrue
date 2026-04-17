defmodule AccrueHostWeb.OrganizationScopeController do
  use AccrueHostWeb, :controller

  import Ecto.Query

  alias AccrueHost.Accounts.{Organization, OrganizationMembership, User}
  alias AccrueHost.Repo

  def update(conn, %{"organization_slug" => slug}) when is_binary(slug) do
    case conn.assigns[:current_scope] do
      %{user: %User{} = user} ->
        case fetch_member_organization(user.id, slug) do
          %Organization{} = org ->
            org_ids = list_member_organization_ids(user.id)

            conn
            |> put_session(:active_organization_id, org.id)
            |> put_session(:active_organization_slug, org.slug)
            |> put_session(:active_organization_name, org.name)
            |> put_session(:admin_organization_ids, org_ids)
            |> redirect(to: ~p"/app/billing")

          nil ->
            conn
            |> put_flash(:error, "That organization is not available for this account.")
            |> redirect(to: ~p"/app/billing")
        end

      _ ->
        conn
        |> put_flash(:error, "You must log in first.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def update(conn, _params) do
    conn
    |> put_flash(:error, "Missing organization.")
    |> redirect(to: ~p"/app/billing")
  end

  defp fetch_member_organization(user_id, slug) do
    from(o in Organization,
      join: m in OrganizationMembership,
      on: m.organization_id == o.id,
      where: m.user_id == ^user_id and o.slug == ^slug and is_nil(o.deleted_at),
      select: o
    )
    |> Repo.one()
  end

  defp list_member_organization_ids(user_id) do
    from(o in Organization,
      join: m in OrganizationMembership,
      on: m.organization_id == o.id,
      where: m.user_id == ^user_id and is_nil(o.deleted_at),
      select: o.id,
      order_by: o.slug
    )
    |> Repo.all()
  end
end
