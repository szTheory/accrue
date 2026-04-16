defmodule Accrue.Billing.Coupon do
  @moduledoc """
  Ecto schema for the `accrue_coupons` table.

  Stores the local projection of a processor coupon (e.g. Stripe coupon
  objects). Supports both amount-off and percent-off discount types.

  Full lifecycle changesets arrive in Phase 4.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_coupons" do
    field(:processor, :string)
    field(:processor_id, :string)
    field(:name, :string)
    field(:amount_off_cents, :integer)
    field(:amount_off_minor, :integer)
    field(:redeem_by, :utc_datetime_usec)
    field(:percent_off, :decimal)
    field(:currency, :string)
    field(:duration, :string)
    field(:duration_in_months, :integer)
    field(:max_redemptions, :integer)
    field(:times_redeemed, :integer, default: 0)
    field(:valid, :boolean, default: true)
    field(:metadata, :map, default: %{})
    field(:data, :map, default: %{})
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    processor processor_id name amount_off_cents amount_off_minor
    redeem_by percent_off
    currency duration duration_in_months max_redemptions
    times_redeemed valid metadata data lock_version
  ]a

  @required_fields ~w[processor]a

  @doc """
  Builds a changeset for creating or updating a Coupon.
  """
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(coupon_or_changeset, attrs \\ %{}) do
    coupon_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
  end
end
