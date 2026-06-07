defmodule Accrue.Billing.MeteredRenewal do
  @moduledoc """
  Immutable local renewal-window anchor for one metered billing period.
  """

  use Accrue.Schema

  import Ecto.Changeset

  @states [:pending, :retry_scheduled, :awaiting_payment_method, :paid, :failed_exhausted]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_metered_renewals" do
    belongs_to(:subscription, Accrue.Billing.Subscription)
    belongs_to(:customer, Accrue.Billing.Customer)
    belongs_to(:invoice, Accrue.Billing.Invoice)

    field(:processor, :string, default: "braintree")
    field(:state, Ecto.Enum, values: @states, default: :pending)
    field(:period_start, :utc_datetime_usec)
    field(:period_end, :utc_datetime_usec)
    field(:trigger_source, :string)
    field(:snapshot, :map, default: %{})
    field(:last_processor_event_id, :string)
    field(:last_processor_event_ts, :utc_datetime_usec)
    field(:invoice_status, :string)
    field(:invoice_authored_at, :utc_datetime_usec)
    field(:paid_at, :utc_datetime_usec)
    field(:data, :map, default: %{})
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    subscription_id customer_id processor state period_start period_end
    trigger_source snapshot last_processor_event_id last_processor_event_ts
    invoice_id invoice_status invoice_authored_at paid_at data lock_version
  ]a

  @required_fields ~w[
    subscription_id customer_id processor state period_start period_end
    trigger_source snapshot
  ]a

  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(renewal_or_changeset, attrs \\ %{}) do
    renewal_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_length(:processor, min: 1)
    |> validate_length(:trigger_source, min: 1)
    |> validate_change(:snapshot, &validate_snapshot/2)
    |> validate_period_bounds()
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:subscription_id)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:invoice_id)
    |> unique_constraint(:subscription_id,
      name: :accrue_metered_renewals_subscription_id_period_start_period_end_index
    )
  end

  defp validate_snapshot(:snapshot, snapshot) when is_map(snapshot) do
    if map_size(snapshot) == 0, do: [snapshot: "can't be blank"], else: []
  end

  defp validate_snapshot(:snapshot, _snapshot), do: [snapshot: "must be a map"]

  defp validate_period_bounds(%Ecto.Changeset{} = changeset) do
    case {get_field(changeset, :period_start), get_field(changeset, :period_end)} do
      {%DateTime{} = period_start, %DateTime{} = period_end} ->
        if DateTime.compare(period_end, period_start) == :gt do
          changeset
        else
          add_error(changeset, :period_end, "must be after period_start")
        end

      _ ->
        changeset
    end
  end
end
