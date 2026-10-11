defmodule AccrueHost.Seeds.Helpers do
  alias AccrueHost.Accounts
  alias AccrueHost.Accounts.OrganizationMembership
  alias AccrueHost.Accounts.Scope
  alias AccrueHost.Accounts.User
  alias AccrueHost.DemoBrand
  alias AccrueHost.Organizations
  alias AccrueHost.Repo

  def demo_password, do: DemoBrand.demo_password()

  def ensure_demo_user(email) do
    case Repo.get_by(User, email: email) do
      %User{} = user ->
        user

      nil ->
        {:ok, user} = Accounts.register_user(%{email: email})

        {:ok, user} =
          user
          |> User.confirm_changeset()
          |> Repo.update()

        {:ok, {user, _expired_tokens}} =
          Accounts.update_user_password(user, %{password: demo_password()})

        user
    end
  end

  def ensure_demo_admin(email) do
    user = ensure_demo_user(email)
    # Unconditionally set billing_admin: true — this field is not cast by any
    # User changeset, so we use Ecto.Changeset.change/2 directly. Safe to apply
    # on every re-seed (idempotent: true stays true, false becomes true).
    Ecto.Changeset.change(user, billing_admin: true) |> Repo.update!()
  end

  def ensure_demo_org(owner, name, slug) do
    case Repo.get_by(AccrueHost.Accounts.Organization, slug: slug) do
      %AccrueHost.Accounts.Organization{} = organization ->
        if organization.name == name do
          organization
        else
          organization
          |> Ecto.Changeset.change(name: name)
          |> Repo.update!()
        end

      nil ->
        {:ok, organization} =
          Organizations.create_organization(Scope.for_user(owner), %{name: name, slug: slug})

        organization
    end
  end

  def ensure_owner_membership(organization, user) do
    case Repo.get_by(OrganizationMembership,
           organization_id: organization.id,
           user_id: user.id
         ) do
      %OrganizationMembership{} = membership ->
        membership

      nil ->
        {:ok, membership} =
          %OrganizationMembership{}
          |> OrganizationMembership.changeset(%{
            role: :owner,
            organization_id: organization.id,
            user_id: user.id
          })
          |> Repo.insert()

        membership
    end
  end

  def record_at(attrs, idempotency_key, at) do
    row =
      attrs
      |> Map.put(:idempotency_key, idempotency_key)
      |> Map.put(:inserted_at, at)
      |> Map.put_new(:actor_type, "system")
      |> Map.put_new(:schema_version, 1)
      |> Map.put_new(:data, %{})

    {_count, _} =
      Repo.insert_all(Accrue.Events.Event, [row],
        on_conflict: :nothing,
        conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}
      )

    :ok
  end
end

