defmodule Accrue.Entitlements.Device do
  @moduledoc "Account-scoped device registration with durable revocation history."

  use Accrue.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @states [:active, :revoked, :superseded]

  schema "accrue_entitlement_devices" do
    belongs_to(:account, Accrue.Entitlements.Account, type: :binary_id)
    field(:installation_id, :string)
    field(:key_thumbprint, :string)
    field(:state, Ecto.Enum, values: @states, default: :active)
    field(:registered_at, :utc_datetime_usec)
    field(:last_seen_at, :utc_datetime_usec)
    field(:last_accepted_revision, :integer, default: 0)
    field(:revoked_at, :utc_datetime_usec)
    field(:superseded_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}
  @fields ~w[account_id installation_id key_thumbprint state registered_at last_seen_at last_accepted_revision revoked_at superseded_at]a
  @required ~w[account_id installation_id key_thumbprint state registered_at last_accepted_revision]a

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(device_or_changeset, attrs \\ %{}) do
    device_or_changeset
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_number(:last_accepted_revision, greater_than_or_equal_to: 0)
    |> validate_lifecycle_timestamps()
    |> check_constraint(:state, name: :accrue_entitlement_devices_state_domain_check)
    |> check_constraint(:last_accepted_revision,
      name: :accrue_entitlement_devices_last_accepted_revision_nonnegative_check
    )
    |> check_constraint(:state, name: :accrue_entitlement_devices_lifecycle_check)
    |> foreign_key_constraint(:account_id, name: :accrue_entitlement_devices_account_id_fkey)
    |> unique_constraint(:installation_id,
      name: :accrue_entitlement_devices_current_installation_identity_index
    )
    |> unique_constraint(:key_thumbprint,
      name: :accrue_entitlement_devices_current_thumbprint_identity_index
    )
  end

  defp validate_lifecycle_timestamps(changeset) do
    state = get_field(changeset, :state)
    revoked_at = get_field(changeset, :revoked_at)
    superseded_at = get_field(changeset, :superseded_at)

    valid? =
      case state do
        :active -> is_nil(revoked_at) and is_nil(superseded_at)
        :revoked -> not is_nil(revoked_at) and is_nil(superseded_at)
        :superseded -> is_nil(revoked_at) and not is_nil(superseded_at)
      end

    if valid?,
      do: changeset,
      else: add_error(changeset, :state, "must match revocation or supersession timestamps")
  end
end
