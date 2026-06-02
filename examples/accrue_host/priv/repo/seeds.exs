defmodule AccrueHost.Seeds.Helpers do
  alias AccrueHost.Accounts
  alias AccrueHost.Accounts.OrganizationMembership
  alias AccrueHost.Accounts.Scope
  alias AccrueHost.Accounts.User
  alias AccrueHost.Organizations
  alias AccrueHost.Repo

  def demo_password, do: "accrue-demo-password"

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

  def ensure_demo_org(owner, name, slug) do
    case Repo.get_by(AccrueHost.Accounts.Organization, slug: slug) do
      %AccrueHost.Accounts.Organization{} = organization ->
        organization

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

# Use eval_file (not require_file) so the sub-seeds re-run every time seeds.exs is
# evaluated. require_file memoizes globally per BEAM node, which silently skips the
# sub-seeds on the 2nd+ eval — breaking the host-integration tests that each
# `Code.eval_file("priv/repo/seeds.exs")` in the same `mix test` run (they'd see 0
# rows). The sub-seeds are idempotent (ensure_*/on_conflict: :nothing), so re-eval
# is safe in production single-run too.
Code.eval_file("seeds/hero_accounts.exs", __DIR__)
Code.eval_file("seeds/background_data.exs", __DIR__)
Code.eval_file("seeds/showcase.exs", __DIR__)
