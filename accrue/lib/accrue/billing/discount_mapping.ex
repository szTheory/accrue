defmodule Accrue.Billing.DiscountMapping do
  @moduledoc """
  Canonical local discount mapping for Braintree promotion-code resolution.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_discount_mappings" do
    field(:processor, :string, default: "braintree")
    field(:code, :string)
    field(:discount_id, :string)
    field(:active, :boolean, default: true)
    field(:amount_off_minor, :integer)
    field(:currency, :string)
    field(:duration_in_billing_cycles, :integer)
    field(:expires_at, :utc_datetime_usec)
    field(:max_redemptions, :integer)
    field(:times_redeemed, :integer, default: 0)
    field(:metadata, :map, default: %{})
    field(:data, :map, default: %{})
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    processor code discount_id active amount_off_minor currency
    duration_in_billing_cycles expires_at max_redemptions times_redeemed
    metadata data
  ]a

  @required_fields ~w[processor code discount_id active amount_off_minor currency]a

  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(mapping_or_changeset, attrs \\ %{}) do
    mapping_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_number(:amount_off_minor, greater_than_or_equal_to: 0)
    |> validate_number(:duration_in_billing_cycles, greater_than: 0)
    |> validate_number(:max_redemptions, greater_than: 0)
    |> validate_number(:times_redeemed, greater_than_or_equal_to: 0)
    |> validate_length(:processor, min: 1)
    |> validate_length(:code, min: 1)
    |> validate_length(:discount_id, min: 1)
    |> validate_length(:currency, min: 1)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> unique_constraint(:code, name: :accrue_discount_mappings_processor_code_index)
  end
end
