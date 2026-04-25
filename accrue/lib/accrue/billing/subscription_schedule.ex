defmodule Accrue.Billing.SubscriptionSchedule do
  @moduledoc """
  Ecto schema for `accrue_subscription_schedules`.

  A subscription schedule lets you pre-program future plan changes:
  start a customer on a discounted trial phase, then automatically
  migrate them to full pricing at a specific date — without manual
  intervention. Use a schedule instead of a plain subscription when you
  need time-boxed phases or future price changes locked in advance.

  This schema stores a thin local projection of Stripe's
  SubscriptionSchedule resource. Stripe is canonical for phase state;
  Accrue persists only the typed columns the admin UI needs to filter
  and sort on, plus a `data` jsonb with the full Stripe payload for
  callers that need the raw shape.

  Two changeset functions reflect the two sources of writes:
  `changeset/2` validates status on the user path, while
  `force_status_changeset/2` bypasses that check on the webhook path
  because Stripe is the source of truth for schedule state.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  @statuses ~w[not_started active completed released canceled]

  schema "accrue_subscription_schedules" do
    field(:processor, :string, default: "stripe")
    field(:processor_id, :string)
    belongs_to(:customer, Accrue.Billing.Customer)
    belongs_to(:subscription, Accrue.Billing.Subscription)
    field(:status, :string)
    field(:current_phase_index, :integer)
    field(:phases_count, :integer)
    field(:next_phase_at, :utc_datetime_usec)
    field(:released_at, :utc_datetime_usec)
    field(:canceled_at, :utc_datetime_usec)
    field(:data, :map, default: %{})
    field(:metadata, :map, default: %{})
    field(:lock_version, :integer, default: 1)
    field(:last_stripe_event_ts, :utc_datetime_usec)
    field(:last_stripe_event_id, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    processor processor_id customer_id subscription_id status
    current_phase_index phases_count next_phase_at
    released_at canceled_at data metadata lock_version
    last_stripe_event_ts last_stripe_event_id
  ]a

  @required_fields ~w[processor processor_id status]a

  @doc "Canonical list of SubscriptionSchedule statuses."
  @spec statuses() :: [String.t()]
  def statuses, do: @statuses

  @doc "User-path changeset with status validation."
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(schedule_or_changeset, attrs \\ %{}) do
    schedule_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, @statuses)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> unique_constraint(:processor_id)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:subscription_id)
  end

  @doc """
  Webhook-path changeset. Stripe is canonical for schedule state; this
  path skips the status allowlist so out-of-order events can settle
  arbitrary state without validation failing.
  """
  @spec force_status_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def force_status_changeset(schedule_or_changeset, attrs \\ %{}) do
    schedule_or_changeset
    |> cast(attrs, @cast_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> unique_constraint(:processor_id)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:subscription_id)
  end
end
