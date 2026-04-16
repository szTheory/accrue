defmodule Accrue.Billing.InvoiceItem do
  @moduledoc """
  Ecto schema for the `accrue_invoice_items` table (D3-15).

  Represents a single line on an invoice. Amounts are integer minor units
  (cents, yen, etc.). Proration items carry `proration: true` and a period
  window. Price and subscription item references are stored as string
  `*_ref` columns rather than FKs because Stripe may reference objects we
  haven't projected locally yet.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_invoice_items" do
    belongs_to(:invoice, Accrue.Billing.Invoice)

    field(:stripe_id, :string)
    field(:description, :string)
    field(:amount_minor, :integer)
    field(:currency, :string)
    field(:quantity, :integer, default: 1)
    field(:period_start, :utc_datetime_usec)
    field(:period_end, :utc_datetime_usec)
    field(:proration, :boolean, default: false)
    field(:price_ref, :string)
    field(:subscription_item_ref, :string)
    field(:data, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    invoice_id stripe_id description amount_minor currency
    quantity period_start period_end proration
    price_ref subscription_item_ref data
  ]a

  @required_fields ~w[invoice_id amount_minor currency]a

  @doc "Builds a changeset for creating or updating an InvoiceItem."
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(invoice_item_or_changeset, attrs \\ %{}) do
    invoice_item_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:invoice_id)
  end
end
