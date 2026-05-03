defmodule Accrue.Billing.MeterDefinitions do
  @moduledoc """
  Local write/read helpers for Braintree meter definitions.
  """

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.{MeterDefinition, SubscriptionItem}
  alias Accrue.Repo

  @processor "braintree"

  @spec upsert_meter_definition(String.t(), map()) ::
          {:ok, MeterDefinition.t()} | {:error, Ecto.Changeset.t() | term()}
  def upsert_meter_definition(event_name, attrs) when is_binary(event_name) and is_map(attrs) do
    normalized_event_name = String.trim(event_name)
    attrs = Map.new(attrs)

    with {:ok, %SubscriptionItem{} = item} <- fetch_subscription_item(attrs),
         definition_attrs <- build_attrs(normalized_event_name, item, attrs) do
      case Repo.transact(fn ->
             case Repo.get_by(MeterDefinition,
                    processor: @processor,
                    event_name: normalized_event_name
                  ) do
               nil ->
                 %MeterDefinition{}
                 |> MeterDefinition.changeset(definition_attrs)
                 |> Repo.insert()

               %MeterDefinition{} = definition ->
                 definition
                 |> MeterDefinition.changeset(definition_attrs)
                 |> Repo.update()
             end
           end) do
        {:ok, %MeterDefinition{} = definition} -> {:ok, definition}
        {:ok, {:ok, %MeterDefinition{} = definition}} -> {:ok, definition}
        {:ok, {:error, err}} -> {:error, err}
        {:error, err} -> {:error, err}
      end
    end
  end

  @spec get_meter_definition(String.t()) :: {:ok, MeterDefinition.t()} | {:error, :not_found}
  def get_meter_definition(event_name) when is_binary(event_name) do
    case Repo.get_by(MeterDefinition, processor: @processor, event_name: String.trim(event_name)) do
      %MeterDefinition{} = definition -> {:ok, definition}
      nil -> {:error, :not_found}
    end
  end

  @spec active_definitions_for_subscription(Ecto.UUID.t()) :: [MeterDefinition.t()]
  def active_definitions_for_subscription(subscription_id) when is_binary(subscription_id) do
    from(md in MeterDefinition,
      join: si in SubscriptionItem,
      on: si.id == md.subscription_item_id,
      where: si.subscription_id == ^subscription_id and md.processor == ^@processor and md.active,
      preload: [subscription_item: si],
      order_by: [asc: md.event_name]
    )
    |> Repo.all()
  end

  defp fetch_subscription_item(%{subscription_item_id: subscription_item_id})
       when is_binary(subscription_item_id) do
    case Repo.get(SubscriptionItem, subscription_item_id) do
      %SubscriptionItem{} = item -> {:ok, item}
      nil -> {:error, :subscription_item_not_found}
    end
  end

  defp fetch_subscription_item(_attrs), do: {:error, missing_target_changeset()}

  defp build_attrs(event_name, %SubscriptionItem{} = item, attrs) do
    snapshot =
      attrs
      |> Map.get(:billing_snapshot, Map.get(attrs, "billing_snapshot", %{}))
      |> Map.new()
      |> Map.new(fn {key, value} -> {to_string(key), value} end)
      |> Map.put_new("subscription_item_id", item.id)
      |> Map.put_new("price_id", item.price_id)
      |> Map.put_new("processor_plan_id", item.processor_plan_id)

    %{
      processor: @processor,
      event_name: event_name,
      subscription_item_id: item.id,
      price_id: item.price_id,
      aggregation_mode:
        Map.get(attrs, :aggregation_mode, Map.get(attrs, "aggregation_mode", "sum")),
      active: Map.get(attrs, :active, Map.get(attrs, "active", true)),
      billing_snapshot: snapshot,
      data: Map.get(attrs, :data, Map.get(attrs, "data", %{}))
    }
  end

  defp missing_target_changeset do
    %MeterDefinition{}
    |> MeterDefinition.changeset(%{
      processor: @processor,
      event_name: "placeholder",
      price_id: "placeholder",
      aggregation_mode: "sum",
      active: true,
      billing_snapshot: %{"placeholder" => true}
    })
    |> Ecto.Changeset.add_error(:subscription_item_id, "can't be blank")
  end
end
