defmodule Accrue.Billing.MeterDefinition do
  @moduledoc """
  Accrue-owned billability contract for one raw usage event name.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @aggregation_modes ~w(sum max last)

  @type t :: %__MODULE__{}

  schema "accrue_meter_definitions" do
    belongs_to(:subscription_item, Accrue.Billing.SubscriptionItem)

    field(:processor, :string, default: "braintree")
    field(:event_name, :string)
    field(:price_id, :string)
    field(:aggregation_mode, :string, default: "sum")
    field(:active, :boolean, default: true)
    field(:billing_snapshot, :map, default: %{})
    field(:data, :map, default: %{})
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    subscription_item_id processor event_name price_id aggregation_mode
    active billing_snapshot data lock_version
  ]a

  @required_fields ~w[subscription_item_id processor event_name price_id aggregation_mode active]a

  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(definition_or_changeset, attrs \\ %{}) do
    definition_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:aggregation_mode, @aggregation_modes)
    |> validate_length(:processor, min: 1)
    |> validate_length(:event_name, min: 1)
    |> validate_length(:price_id, min: 1)
    |> validate_change(:billing_snapshot, &validate_snapshot/2)
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:subscription_item_id)
    |> unique_constraint(:event_name, name: :accrue_meter_definitions_processor_event_name_index)
  end

  defp validate_snapshot(:billing_snapshot, snapshot) when is_map(snapshot) do
    if map_size(snapshot) == 0 do
      [billing_snapshot: "can't be blank"]
    else
      []
    end
  end

  defp validate_snapshot(:billing_snapshot, _snapshot), do: [billing_snapshot: "must be a map"]
end
