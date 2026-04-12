defmodule Accrue.Billing.Subscription do
  @moduledoc """
  Ecto schema for the `accrue_subscriptions` table.

  Stores the local projection of a processor subscription (e.g. Stripe
  `sub_xxx`). The `status` field is a plain string in Phase 2; the full
  state machine with Ecto.Enum arrives in Phase 3.

  Full lifecycle changesets (trials, proration, cancellation, renewals)
  arrive in Phase 3.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_subscriptions" do
    belongs_to :customer, Accrue.Billing.Customer

    field :processor, :string
    field :processor_id, :string
    field :status, :string
    field :current_period_start, :utc_datetime_usec
    field :current_period_end, :utc_datetime_usec
    field :trial_start, :utc_datetime_usec
    field :trial_end, :utc_datetime_usec
    field :cancel_at, :utc_datetime_usec
    field :canceled_at, :utc_datetime_usec
    field :ended_at, :utc_datetime_usec
    field :metadata, :map, default: %{}
    field :data, :map, default: %{}
    field :lock_version, :integer, default: 1

    has_many :subscription_items, Accrue.Billing.SubscriptionItem

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    customer_id processor processor_id status
    current_period_start current_period_end
    trial_start trial_end cancel_at canceled_at ended_at
    metadata data lock_version
  ]a

  @required_fields ~w[customer_id processor]a

  @doc """
  Builds a changeset for creating or updating a Subscription.
  """
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(subscription_or_changeset, attrs \\ %{}) do
    subscription_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:customer_id)
  end
end
