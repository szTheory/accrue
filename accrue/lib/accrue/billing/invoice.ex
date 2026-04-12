defmodule Accrue.Billing.Invoice do
  @moduledoc """
  Ecto schema for the `accrue_invoices` table.

  Stores the local projection of a processor invoice (e.g. Stripe
  `in_xxx`). Amounts are stored as integers in the smallest currency
  unit.

  Full lifecycle changesets (draft/open/paid/void/uncollectible state
  machine, line items, discounts, tax) arrive in Phase 3.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_invoices" do
    belongs_to :customer, Accrue.Billing.Customer
    belongs_to :subscription, Accrue.Billing.Subscription

    field :processor, :string
    field :processor_id, :string
    field :status, :string
    field :total_cents, :integer
    field :currency, :string
    field :due_date, :utc_datetime_usec
    field :paid_at, :utc_datetime_usec
    field :metadata, :map, default: %{}
    field :data, :map, default: %{}
    field :lock_version, :integer, default: 1

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    customer_id subscription_id processor processor_id
    status total_cents currency due_date paid_at
    metadata data lock_version
  ]a

  @required_fields ~w[customer_id processor]a

  @doc """
  Builds a changeset for creating or updating an Invoice.
  """
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(invoice_or_changeset, attrs \\ %{}) do
    invoice_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:subscription_id)
  end
end
