defmodule Accrue.Billing.PromotionCode do
  @moduledoc """
  Ecto schema for the `accrue_promotion_codes` table.

  Stores the thin local projection of a processor promotion code — the
  customer-facing string (e.g. `"SUMMER25"`) that resolves to a
  `Coupon`. Phase 4 (BILL-27) mirrors only the fields the admin
  LiveView needs to filter/sort: `code`, `active`, `max_redemptions`,
  `times_redeemed`, `expires_at`, plus the FK to `accrue_coupons`.

  Per D4-01 / Claude's Discretion: full processor mirror is NOT a
  goal. The canonical source of truth is the processor; Accrue
  denormalizes only what the admin UI touches.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_promotion_codes" do
    field(:processor, :string, default: "stripe")
    field(:processor_id, :string)
    field(:code, :string)

    belongs_to(:coupon, Accrue.Billing.Coupon, type: :binary_id)

    field(:active, :boolean, default: true)
    field(:max_redemptions, :integer)
    field(:times_redeemed, :integer, default: 0)
    field(:expires_at, :utc_datetime_usec)
    field(:data, :map, default: %{})
    field(:metadata, :map, default: %{})
    field(:last_stripe_event_ts, :utc_datetime_usec)
    field(:last_stripe_event_id, :string)
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    processor processor_id code coupon_id active
    max_redemptions times_redeemed expires_at data metadata
    last_stripe_event_ts last_stripe_event_id
  ]a

  @required_fields ~w[processor processor_id code]a

  @doc """
  User-path changeset. Validates required fields plus metadata shape,
  enforces uniqueness on `processor_id` and `code`, and optimistic
  locking on `lock_version`.
  """
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(promo_or_changeset, attrs \\ %{}) do
    promo_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> unique_constraint(:processor_id)
    |> unique_constraint(:code)
    |> foreign_key_constraint(:coupon_id)
  end

  @doc """
  Webhook-path changeset (D3-17). Skips required-field validation so
  out-of-order webhook events can settle partial state. Processor is
  canonical (D2-29).
  """
  @spec force_status_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def force_status_changeset(promo_or_changeset, attrs \\ %{}) do
    promo_or_changeset
    |> cast(attrs, @cast_fields)
    |> optimistic_lock(:lock_version)
    |> unique_constraint(:processor_id)
    |> unique_constraint(:code)
    |> foreign_key_constraint(:coupon_id)
  end
end
