defmodule Accrue.Entitlements.CompatibilityState do
  @moduledoc false

  use Accrue.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_entitlement_compatibility_states" do
    belongs_to(:account, Accrue.Entitlements.Account, type: :binary_id)
    field(:authority, Ecto.Enum, values: [:canonical, :local_map])
    field(:transition_digest, :string)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(state, attrs) do
    state
    |> cast(attrs, [:account_id, :authority, :transition_digest])
    |> validate_required([:account_id, :authority, :transition_digest])
    |> foreign_key_constraint(:account_id,
      name: :accrue_entitlement_compatibility_states_account_id_fkey
    )
    |> unique_constraint(:account_id,
      name: :accrue_entitlement_compatibility_states_account_index
    )
  end
end
