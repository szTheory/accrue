defmodule Accrue.Billing.Refund do
  @moduledoc """
  Ecto schema for the `accrue_refunds` table (D3-45).

  Models a Stripe refund with first-class fee reconciliation:

    * `stripe_fee_refunded_amount_minor` — portion of the original Stripe
      fee that Stripe returned to the merchant on refund
    * `merchant_loss_amount_minor` — non-recoverable fee the merchant eats
    * `fees_settled_at` — wall-clock when the fee pull-forward completes

  See `Accrue.Billing.Refund.fees_settled?/1`.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @statuses [:pending, :requires_action, :succeeded, :failed, :canceled]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_refunds" do
    belongs_to :charge, Accrue.Billing.Charge

    field :stripe_id, :string
    field :amount_minor, :integer
    field :currency, :string
    field :reason, :string
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :stripe_fee_refunded_amount_minor, :integer
    field :merchant_loss_amount_minor, :integer
    field :fees_settled_at, :utc_datetime_usec
    field :last_stripe_event_ts, :utc_datetime_usec
    field :last_stripe_event_id, :string
    field :data, :map, default: %{}
    field :metadata, :map, default: %{}
    field :lock_version, :integer, default: 1

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    charge_id stripe_id amount_minor currency reason status
    stripe_fee_refunded_amount_minor merchant_loss_amount_minor
    fees_settled_at last_stripe_event_ts last_stripe_event_id
    data metadata lock_version
  ]a

  @required_fields ~w[charge_id amount_minor currency]a

  @doc "Canonical list of refund statuses."
  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  @doc "Builds a changeset for creating or updating a Refund."
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(refund_or_changeset, attrs \\ %{}) do
    refund_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:charge_id)
  end

  @doc "True if the fee reconciliation has completed."
  @spec fees_settled?(%__MODULE__{} | map()) :: boolean()
  def fees_settled?(%__MODULE__{fees_settled_at: %DateTime{}}), do: true
  def fees_settled?(%{fees_settled_at: %DateTime{}}), do: true
  def fees_settled?(_), do: false
end
