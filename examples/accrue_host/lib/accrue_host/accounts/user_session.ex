defmodule AccrueHost.Accounts.UserSession do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_sessions" do
    field :hashed_token, :binary
    field :type, :string, default: "standard"
    field :ip, :string
    field :user_agent, :string
    field :geo_city, :string
    field :geo_country_code, :string
    field :last_active_at, :utc_datetime_usec
    field :sudo_at, :utc_datetime_usec
    field :active_organization_id, :binary_id

    belongs_to :user, AccrueHost.Accounts.User

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end
end
