defmodule AccrueHost.Accounts.OrganizationMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organization_memberships" do
    field :role, Ecto.Enum, values: [:owner, :admin, :member]

    belongs_to :organization, AccrueHost.Accounts.Organization
    belongs_to :user, AccrueHost.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role, :user_id, :organization_id])
    |> validate_required([:role, :user_id, :organization_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:organization)
    |> unique_constraint([:user_id, :organization_id])
  end
end
