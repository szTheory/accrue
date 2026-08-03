defmodule Accrue.Entitlements.Grant do
  @moduledoc "A rail-qualified entitlement grant with retained supersession history."

  use Accrue.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @rails [:stripe, :apple]
  @environments [:production, :sandbox]
  @provider_lineage_id_max_bytes 255
  @provider_product_id_max_bytes 255
  @provider_order_key_max_bytes 128

  schema "accrue_entitlement_grants" do
    belongs_to(:account, Accrue.Entitlements.Account, type: :binary_id)
    belongs_to(:source_observation, Accrue.Entitlements.Observation, type: :binary_id)
    field(:rail, Ecto.Enum, values: @rails)
    field(:environment, Ecto.Enum, values: @environments)
    field(:provider_lineage_id, :string)
    field(:provider_product_id, :string)
    field(:logical_plan, :string)
    field(:source_item_id, :string)
    field(:quantity, :integer)
    field(:provider_order, :integer, default: 0)
    field(:provider_order_key, :string)
    field(:account_revision, :integer, default: 0)
    field(:effective_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    field(:superseded_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}
  @fields ~w[account_id source_observation_id rail environment provider_lineage_id provider_product_id logical_plan source_item_id quantity provider_order provider_order_key account_revision effective_at expires_at superseded_at]a
  @required ~w[account_id rail environment provider_lineage_id provider_product_id source_item_id quantity provider_order account_revision effective_at]a

  @doc "Builds the grant changeset; PostgreSQL chooses the current-row winner."
  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(grant_or_changeset, attrs \\ %{}) do
    grant_or_changeset
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_length(:provider_lineage_id, max: @provider_lineage_id_max_bytes, count: :bytes)
    |> validate_length(:provider_product_id, max: @provider_product_id_max_bytes, count: :bytes)
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:provider_order, greater_than_or_equal_to: 0)
    |> validate_length(:provider_order_key, max: @provider_order_key_max_bytes, count: :bytes)
    |> validate_number(:account_revision, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:account_id, name: :accrue_entitlement_grants_account_id_fkey)
    |> foreign_key_constraint(:source_observation_id,
      name: :accrue_entitlement_grants_source_observation_id_fkey
    )
    |> foreign_key_constraint(:source_observation_id,
      name: :accrue_entitlement_grants_source_observation_scope_fkey
    )
    |> check_constraint(:rail, name: :accrue_entitlement_grants_rail_domain_check)
    |> check_constraint(:environment, name: :accrue_entitlement_grants_environment_domain_check)
    |> check_constraint(:quantity, name: :accrue_entitlement_grants_quantity_positive_check)
    |> check_constraint(:provider_order,
      name: :accrue_entitlement_grants_provider_order_nonnegative_check
    )
    |> check_constraint(:provider_order_key,
      name: :accrue_ent_grants_provider_order_key_bytes_check
    )
    |> check_constraint(:account_revision,
      name: :accrue_entitlement_grants_account_revision_nonnegative_check
    )
    |> check_constraint(:provider_lineage_id,
      name: :accrue_ent_grants_provider_lineage_id_bytes_check
    )
    |> check_constraint(:provider_product_id,
      name: :accrue_ent_grants_provider_product_id_bytes_check
    )
    |> unique_constraint(:provider_lineage_id,
      name: :accrue_entitlement_grants_current_identity_index
    )
  end
end
