defmodule Accrue.Billing.InvoiceCoupon do
  @moduledoc """
  Ecto schema for the `accrue_invoice_coupons` redemption link table (D3-16).

  Records that a coupon was applied to an invoice and the resulting
  discount amount in minor units. This is the redemption ledger — the
  `accrue_coupons` row holds the coupon definition, this row records
  application.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_invoice_coupons" do
    belongs_to :invoice, Accrue.Billing.Invoice
    belongs_to :coupon, Accrue.Billing.Coupon

    field :amount_off_minor, :integer

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @cast_fields ~w[invoice_id coupon_id amount_off_minor]a
  @required_fields ~w[invoice_id coupon_id amount_off_minor]a

  @doc "Builds a changeset for creating an InvoiceCoupon redemption row."
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(row_or_changeset, attrs \\ %{}) do
    row_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:invoice_id)
    |> foreign_key_constraint(:coupon_id)
  end
end
