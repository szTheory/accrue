defmodule Accrue.Billing.Subscription do
  @moduledoc """
  Ecto schema for the `accrue_subscriptions` table.

  Stores the local projection of a processor subscription (e.g. Stripe
  `sub_xxx`). Phase 3 upgrades `:status` to an `Ecto.Enum` over the
  canonical Stripe subscription status set (BILL-05, D3-03) and adds
  the cancel-at-period-end + pause_collection fields needed for the
  full lifecycle state machine.

  ## Predicates (BILL-05)

  Never gate on raw `.status` access. The predicates defined in this
  module are the canonical way to ask "is this subscription X?" — raw
  access is lint-time forbidden by `Accrue.Credo.NoRawStatusAccess`.

    - `trialing?/1`
    - `active?/1` — includes `:trialing`
    - `past_due?/1` — `:past_due` or `:unpaid`
    - `canceled?/1` — `:canceled`, `:incomplete_expired`, or any `ended_at`
    - `canceling?/1` — `:active` + `cancel_at_period_end` + future period end
    - `paused?/1` — legacy `:paused` status OR non-nil `pause_collection`
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @statuses [
    :trialing,
    :active,
    :past_due,
    :canceled,
    :unpaid,
    :incomplete,
    :incomplete_expired,
    :paused
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_subscriptions" do
    belongs_to :customer, Accrue.Billing.Customer

    field :processor, :string
    field :processor_id, :string
    field :status, Ecto.Enum, values: @statuses
    field :cancel_at_period_end, :boolean, default: false
    field :pause_collection, :map
    field :current_period_start, :utc_datetime_usec
    field :current_period_end, :utc_datetime_usec
    field :trial_start, :utc_datetime_usec
    field :trial_end, :utc_datetime_usec
    field :cancel_at, :utc_datetime_usec
    field :canceled_at, :utc_datetime_usec
    field :ended_at, :utc_datetime_usec
    field :last_stripe_event_ts, :utc_datetime_usec
    field :last_stripe_event_id, :string
    field :metadata, :map, default: %{}
    field :data, :map, default: %{}
    field :lock_version, :integer, default: 1

    has_many :subscription_items, Accrue.Billing.SubscriptionItem

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    customer_id processor processor_id status
    cancel_at_period_end pause_collection
    current_period_start current_period_end
    trial_start trial_end cancel_at canceled_at ended_at
    last_stripe_event_ts last_stripe_event_id
    metadata data lock_version
  ]a

  @required_fields ~w[customer_id processor]a

  @doc "Canonical list of subscription statuses (D3-03, Stripe's 8 values)."
  @spec statuses() :: [atom()]
  def statuses, do: @statuses

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

  # ---------------------------------------------------------------------------
  # BILL-05 predicates
  # ---------------------------------------------------------------------------

  @doc "True if the subscription is currently in a trial."
  @spec trialing?(%__MODULE__{} | map()) :: boolean()
  def trialing?(%__MODULE__{status: :trialing}), do: true
  def trialing?(%{status: :trialing}), do: true
  def trialing?(_), do: false

  @doc """
  True if the subscription counts as "active" for entitlement purposes.

  Includes `:trialing` per D3-03.
  """
  @spec active?(%__MODULE__{} | map()) :: boolean()
  def active?(%__MODULE__{status: s}) when s in [:active, :trialing], do: true
  def active?(%{status: s}) when s in [:active, :trialing], do: true
  def active?(_), do: false

  @doc "True if the subscription is past due or unpaid (dunning territory)."
  @spec past_due?(%__MODULE__{} | map()) :: boolean()
  def past_due?(%__MODULE__{status: s}) when s in [:past_due, :unpaid], do: true
  def past_due?(%{status: s}) when s in [:past_due, :unpaid], do: true
  def past_due?(_), do: false

  @doc """
  True if the subscription has terminated.

  `:canceled`, `:incomplete_expired`, or any row with a non-nil `ended_at`.
  """
  @spec canceled?(%__MODULE__{} | map()) :: boolean()
  def canceled?(%__MODULE__{status: s}) when s in [:canceled, :incomplete_expired], do: true
  def canceled?(%__MODULE__{ended_at: %DateTime{}}), do: true
  def canceled?(%{status: s}) when s in [:canceled, :incomplete_expired], do: true
  def canceled?(%{ended_at: %DateTime{}}), do: true
  def canceled?(_), do: false

  @doc """
  True if the subscription is `:active` with `cancel_at_period_end` set and
  the current period end is still in the future (cancel_at_period_end cancel
  hasn't taken effect yet).
  """
  @spec canceling?(%__MODULE__{} | map()) :: boolean()
  def canceling?(%__MODULE__{
        status: :active,
        cancel_at_period_end: true,
        current_period_end: %DateTime{} = cpe
      }) do
    DateTime.compare(cpe, Accrue.Clock.utc_now()) == :gt
  end

  def canceling?(%{
        status: :active,
        cancel_at_period_end: true,
        current_period_end: %DateTime{} = cpe
      }) do
    DateTime.compare(cpe, Accrue.Clock.utc_now()) == :gt
  end

  def canceling?(_), do: false

  @doc """
  True if the subscription is paused.

  Covers both the legacy `:paused` status (used by earlier Stripe versions)
  and the modern `pause_collection` map (D3-03).
  """
  @spec paused?(%__MODULE__{} | map()) :: boolean()
  def paused?(%__MODULE__{pause_collection: pc}) when is_map(pc), do: true
  def paused?(%__MODULE__{status: :paused}), do: true
  def paused?(%{pause_collection: pc}) when is_map(pc), do: true
  def paused?(%{status: :paused}), do: true
  def paused?(_), do: false

  @doc """
  Extracts a pre-hydrated PaymentIntent from `data.latest_invoice.payment_intent`,
  used by Plan 04 `subscribe/3` to surface SCA/3DS action-required to the caller.
  """
  @spec pending_intent(%__MODULE__{} | map()) :: map() | nil
  def pending_intent(%__MODULE__{data: data}) when is_map(data) do
    # WR-02: dual-key lookup. Fake adapter returns atom-keyed maps,
    # Stripe adapter returns string-keyed maps. Normalize here rather
    # than forcing callers to know which shape they have.
    fetch_key(data, [:latest_invoice, "latest_invoice"])
    |> case do
      %{} = inv -> fetch_key(inv, [:payment_intent, "payment_intent"])
      _ -> nil
    end
  end

  def pending_intent(_), do: nil

  defp fetch_key(map, keys) when is_map(map) do
    Enum.find_value(keys, fn k -> Map.get(map, k) end)
  end

  defp fetch_key(_, _), do: nil
end
