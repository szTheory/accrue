defmodule AccrueHostWeb.OrganizationScopeController do
  use AccrueHostWeb, :controller

  import Ecto.Query

  alias AccrueHost.Accounts.{Organization, OrganizationMembership, User}
  alias AccrueHost.Repo

  def update(conn, %{"organization_slug" => "personal"}) do
    case conn.assigns[:current_scope] do
      %{user: %User{}} ->
        conn
        |> put_session(:portal_billable_selection, "personal")
        |> redirect(to: ~p"/app/billing")

      _ ->
        conn
        |> put_flash(:error, "You must log in first.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def update(conn, %{"organization_slug" => slug}) when is_binary(slug) do
    case conn.assigns[:current_scope] do
      %{user: %User{} = user} ->
        case fetch_member_organization(user.id, slug) do
          %Organization{} = org ->
            org_ids = list_member_organization_ids(user.id)

            conn
            |> delete_session(:portal_billable_selection)
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

  def revoke_membership_for_e2e(conn, %{"organization_slug" => slug}) when is_binary(slug) do
    case conn.assigns[:current_scope] do
      %{user: %User{id: user_id}} ->
        deleted =
          from(membership in OrganizationMembership,
            join: organization in Organization,
            on: organization.id == membership.organization_id,
            where:
              membership.user_id == ^user_id and organization.slug == ^slug and
                is_nil(organization.deleted_at)
          )
          |> Repo.delete_all()

        case deleted do
          {1, _} ->
            case other_member_organization(user_id) do
              %Organization{} = organization ->
                conn
                |> put_session(:active_organization_id, organization.id)
                |> put_session(:active_organization_slug, organization.slug)
                |> put_session(:active_organization_name, organization.name)
                |> send_resp(:no_content, "")

              nil ->
                conn
                |> delete_session(:active_organization_id)
                |> put_session(:portal_billable_selection, "personal")
                |> send_resp(:no_content, "")
            end

          _ ->
            send_resp(conn, :not_found, "")
        end

      _ ->
        send_resp(conn, :unauthorized, "")
    end
  end

  def revoke_membership_for_e2e(conn, _params), do: send_resp(conn, :bad_request, "")

  defp other_member_organization(user_id) do
    from(organization in Organization,
      join: membership in OrganizationMembership,
      on: membership.organization_id == organization.id,
      where: membership.user_id == ^user_id and is_nil(organization.deleted_at),
      order_by: organization.slug,
      limit: 1,
      select: organization
    )
    |> Repo.one()
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
