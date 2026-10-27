defmodule AccrueAdmin.Test.SubscriptionScenarioRepo do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias AccrueAdmin.Storybook.SubscriptionScenarios

  @customer_fields [:id, :owner_type, :owner_id, :processor, :processor_id, :name, :email]
  @subscription_fields [
    :id,
    :customer_id,
    :processor,
    :processor_id,
    :status,
    :cancel_at_period_end,
    :current_period_start,
    :current_period_end,
    :dunning_campaign_started_at
  ]
  @item_fields [:id, :subscription_id, :processor, :processor_id, :price_id, :quantity]

  @doc "Persists one validated ordinary Cadence scenario and returns its reloaded graph."
  def persist!(repo, input) when is_atom(repo) do
    facts = input |> SubscriptionScenarios.validate!() |> ensure_processor_references!()

    case identity_state(repo, facts) do
      {:matched, graph} ->
        graph

      :conflict ->
        raise_identity_conflict!()

      :absent ->
        persist_absent!(repo, facts)
    end
  end

  @doc "Reloads a persisted subscription, its customer, and ordered subscription items."
  def reload(repo, subscription_id) when is_atom(repo) do
    case repo.get(Subscription, subscription_id) do
      nil ->
        nil

      subscription ->
        subscription = repo.preload(subscription, [:customer, :subscription_items])
        items = Enum.sort_by(subscription.subscription_items, & &1.id)
        subscription = %{subscription | subscription_items: items}

        %{customer: subscription.customer, subscription: subscription, items: items}
    end
  end

  defp persist_absent!(repo, facts) do
    case repo.transaction(fn ->
           with {:ok, _customer} <- insert_customer(repo, facts),
                {:ok, _subscription} <- insert_subscription(repo, facts),
                :ok <- insert_items(repo, facts) do
             reload(repo, facts.subscription.id)
           else
             {:error, :identity_conflict} -> repo.rollback(:identity_conflict)
           end
         end) do
      {:ok, graph} ->
        graph

      {:error, :identity_conflict} ->
        case identity_state(repo, facts) do
          {:matched, graph} -> graph
          _ -> raise_identity_conflict!()
        end

      {:error, reason} ->
        raise ArgumentError, "Cadence scenario persistence failed: #{inspect(reason)}"
    end
  end

  defp insert_customer(repo, facts) do
    attrs = Map.take(facts.customer, @customer_fields)
    changeset = Customer.changeset(%Customer{id: attrs.id}, Map.delete(attrs, :id))

    changeset
    |> Ecto.Changeset.unique_constraint(:processor_id,
      name: :accrue_customers_processor_processor_id_index
    )
    |> Ecto.Changeset.unique_constraint(:id, name: :accrue_customers_pkey)
    |> insert_result(repo)
  end

  defp insert_subscription(repo, facts) do
    attrs = Map.take(facts.subscription, @subscription_fields)

    changeset =
      Subscription.changeset(%Subscription{id: attrs.id}, Map.delete(attrs, :id))
      |> Ecto.Changeset.unique_constraint(:processor_id,
        name: :accrue_subscriptions_processor_processor_id_index
      )
      |> Ecto.Changeset.unique_constraint(:id, name: :accrue_subscriptions_pkey)

    insert_result(changeset, repo)
  end

  defp insert_items(repo, facts) do
    facts.subscription.items
    |> Enum.reduce_while(:ok, fn attrs, :ok ->
      fields = Map.take(attrs, @item_fields)

      changeset =
        SubscriptionItem.changeset(%SubscriptionItem{id: fields.id}, Map.delete(fields, :id))
        |> Ecto.Changeset.unique_constraint(:processor_id,
          name: :accrue_subscription_items_processor_processor_id_index
        )
        |> Ecto.Changeset.unique_constraint(:id, name: :accrue_subscription_items_pkey)

      case insert_result(changeset, repo) do
        {:ok, _item} -> {:cont, :ok}
        {:error, :identity_conflict} -> {:halt, {:error, :identity_conflict}}
      end
    end)
  end

  defp insert_result(changeset, repo) do
    case repo.insert(changeset) do
      {:ok, record} -> {:ok, record}
      {:error, _changeset} -> {:error, :identity_conflict}
    end
  end

  defp identity_state(repo, facts) do
    customer_rows =
      identity_rows(
        repo,
        Customer,
        facts.customer.id,
        facts.customer.processor,
        facts.customer.processor_id
      )

    subscription_rows =
      identity_rows(
        repo,
        Subscription,
        facts.subscription.id,
        facts.subscription.processor,
        facts.subscription.processor_id
      )

    item_rows =
      Enum.map(facts.subscription.items, fn item ->
        identity_rows(repo, SubscriptionItem, item.id, item.processor, item.processor_id)
      end)

    rows = [customer_rows, subscription_rows | item_rows]

    cond do
      Enum.all?(rows, &(&1 == [])) ->
        :absent

      Enum.any?(rows, &(&1 == [])) or Enum.any?(rows, &(length(&1) != 1)) ->
        :conflict

      true ->
        case reload(repo, facts.subscription.id) do
          %{customer: %Customer{}, subscription: %Subscription{}, items: items} = graph ->
            if matches_facts?(graph, facts) and length(items) == length(facts.subscription.items) do
              {:matched, graph}
            else
              :conflict
            end

          _ ->
            :conflict
        end
    end
  end

  defp identity_rows(repo, schema, id, processor, processor_id) do
    repo.all(
      from(row in schema,
        where:
          row.id == ^id or
            (row.processor == ^processor and row.processor_id == ^processor_id),
        limit: 2
      )
    )
  end

  defp matches_facts?(graph, facts) do
    fields_match?(graph.customer, facts.customer, @customer_fields) and
      fields_match?(graph.subscription, facts.subscription, @subscription_fields) and
      Enum.map(graph.items, &Map.take(&1, @item_fields)) ==
        facts.subscription.items
        |> Enum.map(&Map.take(&1, @item_fields))
        |> Enum.sort_by(& &1.id)
  end

  defp fields_match?(actual, expected, fields) do
    Enum.all?(fields, fn field ->
      same_value?(Map.get(actual, field), Map.get(expected, field))
    end)
  end

  defp same_value?(%DateTime{} = actual, %DateTime{} = expected),
    do: DateTime.compare(actual, expected) == :eq

  defp same_value?(actual, expected), do: actual == expected

  defp ensure_processor_references!(facts) do
    references =
      [facts.customer.processor_id, facts.subscription.processor_id] ++
        Enum.map(facts.subscription.items, & &1.processor_id)

    if Enum.all?(references, &(is_binary(&1) and String.trim(&1) != "")) do
      facts
    else
      raise ArgumentError, "Cadence persisted scenarios require explicit provider references"
    end
  end

  defp raise_identity_conflict! do
    raise ArgumentError,
          "Cadence scenario conflicts with an existing customer, subscription, or item identity"
  end
end
