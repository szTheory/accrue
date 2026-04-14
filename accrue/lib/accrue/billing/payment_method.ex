defmodule Accrue.Billing.PaymentMethod do
  @moduledoc """
  Ecto schema for the `accrue_payment_methods` table.

  Stores processor-side payment method references (e.g. Stripe `pm_xxx`).
  Card details are stored as Stripe references (brand, last4, expiry),
  never as raw PAN or PII (CLAUDE.md security constraint).

  Phase 3 adds:

    * `exp_month` / `exp_year` — top-level expiry used by the expiring-card
      notice scheduler (alias for the `card_exp_*` columns already in place)
    * `last_stripe_event_ts` / `last_stripe_event_id` — webhook watermark
    * virtual `existing?` — set by the `attach_payment_method/2` dedup path
      (Plan 06) when fingerprint matches an existing row on the customer
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_payment_methods" do
    belongs_to :customer, Accrue.Billing.Customer

    field :processor, :string
    field :processor_id, :string
    field :type, :string
    field :is_default, :boolean, default: false
    field :fingerprint, :string
    field :card_brand, :string
    field :card_last4, :string
    field :card_exp_month, :integer
    field :card_exp_year, :integer
    field :exp_month, :integer
    field :exp_year, :integer
    field :last_stripe_event_ts, :utc_datetime_usec
    field :last_stripe_event_id, :string
    field :metadata, :map, default: %{}
    field :data, :map, default: %{}
    field :lock_version, :integer, default: 1

    field :existing?, :boolean, virtual: true, default: false

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    customer_id processor processor_id type is_default
    fingerprint card_brand card_last4 card_exp_month card_exp_year
    exp_month exp_year last_stripe_event_ts last_stripe_event_id
    metadata data lock_version
  ]a

  @required_fields ~w[customer_id processor]a

  @doc "Builds a changeset for creating or updating a PaymentMethod."
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(payment_method_or_changeset, attrs \\ %{}) do
    payment_method_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:customer_id)
    |> unique_constraint([:customer_id, :fingerprint],
      name: :accrue_payment_methods_customer_fingerprint_idx
    )
  end
end
