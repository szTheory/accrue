defmodule AccrueHost.Accounts.OrganizationSlugAlias do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organization_slug_aliases" do
    field :old_slug, :string
    field :expires_at, :utc_datetime

    belongs_to :organization, AccrueHost.Accounts.Organization

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
