defmodule AccrueHost.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AccrueHost.Accounts` context.
  """

  import Ecto.Query

  alias AccrueHost.Accounts
  alias AccrueHost.Accounts.OrganizationMembership
  alias AccrueHost.Accounts.Scope
  alias AccrueHost.Organizations
  alias AccrueHost.Repo

  @organization_roles [:owner, :admin, :member]

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Accounts.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def unique_organization_name, do: "Organization #{System.unique_integer([:positive])}"
  def unique_organization_slug, do: "organization-#{System.unique_integer([:positive])}"

  def valid_organization_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_organization_name(),
      slug: unique_organization_slug()
    })
  end

  def organization_fixture(attrs \\ %{}) do
    owner = Map.get_lazy(attrs, :owner, &user_fixture/0)

    organization_attrs =
      attrs
      |> Map.delete(:owner)
      |> valid_organization_attributes()

    {:ok, organization} =
      Organizations.create_organization(Scope.for_user(owner), organization_attrs)

    organization
  end

  def organization_membership_fixture(attrs \\ %{}) do
    organization = Map.get_lazy(attrs, :organization, &organization_fixture/0)
    user = Map.get_lazy(attrs, :user, &user_fixture/0)
    role = Map.get(attrs, :role, :member)

    unless role in @organization_roles do
      raise ArgumentError,
            "expected role to be one of #{inspect(@organization_roles)}, got: #{inspect(role)}"
    end

    attrs =
      attrs
      |> Map.delete(:organization)
      |> Map.delete(:user)
      |> Map.put(:organization_id, organization.id)
      |> Map.put(:user_id, user.id)
      |> Map.put(:role, role)

    case Repo.get_by(OrganizationMembership,
           organization_id: organization.id,
           user_id: user.id
         ) do
      %OrganizationMembership{} = membership ->
        membership

      nil ->
        {:ok, membership} =
          %OrganizationMembership{}
          |> OrganizationMembership.changeset(attrs)
          |> Repo.insert()

        membership
    end
  end

  def active_organization_scope_fixture(attrs \\ %{}) do
    owner = Map.get_lazy(attrs, :owner, &user_fixture/0)

    organization =
      Map.get_lazy(attrs, :organization, fn -> organization_fixture(%{owner: owner}) end)

    role = Map.get(attrs, :role, :owner)

    membership =
      organization_membership_fixture(%{
        organization: organization,
        user: owner,
        role: role
      })

    %Scope{
      user: owner,
      active_organization: organization,
      membership: membership
    }
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    with {:ok, hashed_token} <- hash_raw_session_token(token) do
      AccrueHost.Repo.update_all(
        from(s in Accounts.UserSession, where: s.hashed_token == ^hashed_token),
        set: [inserted_at: authenticated_at, last_active_at: authenticated_at]
      )
    end
  end

  def generate_user_magic_link_token(user) do
    {:ok, {encoded_token, _url}} =
      Sigra.Auth.request_magic_link(AccrueHost.Repo, user.email,
        user_schema: Accounts.User,
        user_token_schema: Accounts.UserToken,
        url_fun: & &1
      )

    {:ok, decoded_token} = Base.url_decode64(encoded_token, padding: false)
    {encoded_token, Sigra.Token.hash_token(decoded_token)}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    with {:ok, hashed_token} <- hash_raw_session_token(token) do
      AccrueHost.Repo.update_all(
        from(s in Accounts.UserSession, where: s.hashed_token == ^hashed_token),
        set: [inserted_at: dt, last_active_at: dt]
      )
    end
  end

  defp hash_raw_session_token(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} -> {:ok, Sigra.Token.hash_token(decoded_token)}
      :error -> :error
    end
  end
end
