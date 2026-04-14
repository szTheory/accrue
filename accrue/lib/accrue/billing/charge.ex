defmodule Accrue.Billing.Charge do
  @moduledoc """
  Ecto schema for the `accrue_charges` table.

  Stores the local projection of a processor charge or payment intent
  (e.g. Stripe `ch_xxx` or `pi_xxx`). Amounts are stored as integers in
  the smallest currency unit (cents for USD, yen for JPY).

  Phase 3 adds Stripe fee tracking (`stripe_fee_amount_minor`,
  `fees_settled_at`) needed by the refund fee-reconciliation path (D3-45).
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_charges" do
    belongs_to :customer, Accrue.Billing.Customer
    belongs_to :subscription, Accrue.Billing.Subscription
    belongs_to :payment_method, Accrue.Billing.PaymentMethod
    has_many :refunds, Accrue.Billing.Refund

    field :processor, :string
    field :processor_id, :string
    field :amount_cents, :integer
    field :currency, :string
    field :status, :string
    field :stripe_fee_amount_minor, :integer
    field :stripe_fee_currency, :string
    field :fees_settled_at, :utc_datetime_usec
    field :last_stripe_event_ts, :utc_datetime_usec
    field :last_stripe_event_id, :string
    field :metadata, :map, default: %{}
    field :data, :map, default: %{}
    field :lock_version, :integer, default: 1

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    customer_id subscription_id payment_method_id
    processor processor_id amount_cents currency status
    stripe_fee_amount_minor stripe_fee_currency fees_settled_at
    last_stripe_event_ts last_stripe_event_id
    metadata data lock_version
  ]a

  @required_fields ~w[customer_id processor]a

  @doc "Builds a changeset for creating or updating a Charge."
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(charge_or_changeset, attrs \\ %{}) do
    charge_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:subscription_id)
    |> foreign_key_constraint(:payment_method_id)
  end
end
