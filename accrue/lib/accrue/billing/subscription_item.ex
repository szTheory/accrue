defmodule Accrue.Billing.SubscriptionItem do
  @moduledoc """
  Ecto schema for the `accrue_subscription_items` table.

  Represents a single line item within a subscription (e.g. a specific
  price/plan and quantity). Maps to Stripe `si_xxx`. Phase 3 adds the
  processor plan/product refs and per-item period bounds per D3-31.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_subscription_items" do
    belongs_to(:subscription, Accrue.Billing.Subscription)

    field(:processor, :string)
    field(:processor_id, :string)
    field(:price_id, :string)
    field(:processor_plan_id, :string)
    field(:processor_product_id, :string)
    field(:quantity, :integer, default: 1)
    field(:current_period_start, :utc_datetime_usec)
    field(:current_period_end, :utc_datetime_usec)
    field(:last_stripe_event_ts, :utc_datetime_usec)
    field(:last_stripe_event_id, :string)
    field(:metadata, :map, default: %{})
    field(:data, :map, default: %{})
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    subscription_id processor processor_id price_id
    processor_plan_id processor_product_id quantity
    current_period_start current_period_end
    last_stripe_event_ts last_stripe_event_id
    metadata data lock_version
  ]a

  @required_fields ~w[subscription_id processor]a

  @doc """
  Builds a changeset for creating or updating a SubscriptionItem.
  """
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(subscription_item_or_changeset, attrs \\ %{}) do
    subscription_item_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:subscription_id)
  end
end
