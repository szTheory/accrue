defmodule Accrue.Billing.SubscriptionItems do
  @moduledoc """
  Multi-item subscription surface (BILL-12).

  `add_item/3`, `remove_item/2`, and `update_item_quantity/3` mutate
  a subscription's item list through the processor adapter and project
  the result to the local `accrue_subscription_items` table inside a
  single `Repo.transact/1` block.

  All three require an explicit `:proration` option (BILL-09 carryover) —
  Accrue never inherits Stripe's default proration behavior. Missing
  proration raises at NimbleOptions validation time.

  The WR-09 non-bang + `reduce_while` pattern is used for any list
  upsert path so `Ecto.InvalidChangesetError` propagates cleanly
  rather than aborting the enclosing transaction.
  """

  import Ecto.Query, only: [from: 2]

  require Logger

  alias Accrue.Actor
  alias Accrue.Billing.{Subscription, SubscriptionItem}
  alias Accrue.{Events, Processor, Repo}
  alias Accrue.Processor.Idempotency

  @add_schema [
    quantity: [type: :pos_integer, default: 1],
    proration: [
      type: {:in, [:create_prorations, :none, :always_invoice]},
      required: true
    ],
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @remove_schema [
    proration: [
      type: {:in, [:create_prorations, :none, :always_invoice]},
      required: true
    ],
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @update_schema [
    proration: [
      type: {:in, [:create_prorations, :none, :always_invoice]},
      required: true
    ],
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  # -----------------------------------------------------------------
  # add_item/3
  # -----------------------------------------------------------------

  @spec add_item(Subscription.t(), String.t(), keyword()) ::
          {:ok, SubscriptionItem.t()} | {:error, term()}
  def add_item(%Subscription{} = sub, price_id, opts \\ []) when is_binary(price_id) do
    v = NimbleOptions.validate!(opts, @add_schema)
    op_id = v[:operation_id] || Actor.current_operation_id!()
    idem_key = Idempotency.key(:subscription_item_create, sub.id, op_id)

    Repo.transact(fn ->
      with {:ok, stripe_item} <-
             Processor.__impl__().subscription_item_create(
               %{
                 subscription: sub.processor_id,
                 price: price_id,
                 quantity: v[:quantity],
                 proration_behavior: proration_to_stripe(v[:proration])
               },
               idempotency_key: idem_key
             ),
           {:ok, item} <- insert_item(sub, stripe_item, price_id, v[:quantity]),
           {:ok, _} <-
             Events.record(%{
               type: "subscription.item_added",
               subject_type: "Subscription",
               subject_id: sub.id,
               data: %{item_id: item.id, price_id: price_id}
             }) do
        {:ok, item}
      end
    end)
  end

  @spec add_item!(Subscription.t(), String.t(), keyword()) :: SubscriptionItem.t()
  def add_item!(sub, price_id, opts \\ []), do: unwrap!(add_item(sub, price_id, opts))

  # -----------------------------------------------------------------
  # remove_item/2
  # -----------------------------------------------------------------

  @spec remove_item(SubscriptionItem.t(), keyword()) ::
          {:ok, SubscriptionItem.t()} | {:error, term()}
  def remove_item(%SubscriptionItem{} = item, opts \\ []) do
    v = NimbleOptions.validate!(opts, @remove_schema)
    op_id = v[:operation_id] || Actor.current_operation_id!()
    idem_key = Idempotency.key(:subscription_item_delete, item.id, op_id)

    Repo.transact(fn ->
      with {:ok, _stripe_result} <-
             Processor.__impl__().subscription_item_delete(
               item.processor_id,
               %{proration_behavior: proration_to_stripe(v[:proration])},
               idempotency_key: idem_key
             ),
           {:ok, deleted} <- Repo.delete(item),
           {:ok, _} <-
             Events.record(%{
               type: "subscription.item_removed",
               subject_type: "Subscription",
               subject_id: item.subscription_id,
               data: %{item_id: item.id, price_id: item.price_id}
             }) do
        {:ok, deleted}
      end
    end)
  end

  @spec remove_item!(SubscriptionItem.t(), keyword()) :: SubscriptionItem.t()
  def remove_item!(item, opts \\ []), do: unwrap!(remove_item(item, opts))

  # -----------------------------------------------------------------
  # update_item_quantity/3
  # -----------------------------------------------------------------

  @spec update_item_quantity(SubscriptionItem.t(), pos_integer(), keyword()) ::
          {:ok, SubscriptionItem.t()} | {:error, term()}
  def update_item_quantity(%SubscriptionItem{} = item, new_quantity, opts \\ [])
      when is_integer(new_quantity) and new_quantity > 0 do
    v = NimbleOptions.validate!(opts, @update_schema)
    op_id = v[:operation_id] || Actor.current_operation_id!()
    idem_key = Idempotency.key(:subscription_item_update, item.id, op_id)

    Repo.transact(fn ->
      with {:ok, stripe_item} <-
             Processor.__impl__().subscription_item_update(
               item.processor_id,
               %{
                 quantity: new_quantity,
                 proration_behavior: proration_to_stripe(v[:proration])
               },
               idempotency_key: idem_key
             ),
           {:ok, updated} <- update_item(item, stripe_item, new_quantity),
           {:ok, _} <-
             Events.record(%{
               type: "subscription.item_quantity_updated",
               subject_type: "Subscription",
               subject_id: item.subscription_id,
               data: %{item_id: item.id, quantity: new_quantity}
             }) do
        {:ok, updated}
      end
    end)
  end

  @spec update_item_quantity!(SubscriptionItem.t(), pos_integer(), keyword()) ::
          SubscriptionItem.t()
  def update_item_quantity!(item, qty, opts \\ []),
    do: unwrap!(update_item_quantity(item, qty, opts))

  # -----------------------------------------------------------------
  # internals
  # -----------------------------------------------------------------

  defp proration_to_stripe(:create_prorations), do: "create_prorations"
  defp proration_to_stripe(:none), do: "none"
  defp proration_to_stripe(:always_invoice), do: "always_invoice"

  defp insert_item(sub, stripe_item, price_id, quantity) do
    processor_id = stripe_item[:id] || stripe_item["id"]

    attrs = %{
      subscription_id: sub.id,
      processor: processor_name(),
      processor_id: processor_id,
      price_id: price_id,
      processor_plan_id: price_id,
      quantity: quantity,
      data: %{}
    }

    case Repo.one(from(i in SubscriptionItem, where: i.processor_id == ^processor_id)) do
      nil ->
        %SubscriptionItem{}
        |> SubscriptionItem.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> SubscriptionItem.changeset(attrs)
        |> Repo.update()
    end
  end

  defp update_item(item, _stripe_item, new_quantity) do
    item
    |> SubscriptionItem.changeset(%{quantity: new_quantity})
    |> Repo.update()
  end

  defp processor_name do
    case Processor.__impl__() do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end

  defp unwrap!({:ok, v}), do: v
  defp unwrap!({:error, err}) when is_exception(err), do: raise(err)
  defp unwrap!({:error, other}), do: raise("SubscriptionItems action failed: #{inspect(other)}")
end
