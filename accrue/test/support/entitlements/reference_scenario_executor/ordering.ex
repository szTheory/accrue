defmodule Accrue.Entitlements.ReferenceScenarioExecutor.Ordering do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.{Grant, Observation, Projector}
  alias Accrue.Events.Event

  def equal_orders(repo, account, %{command: %{payload: payload}}, opts) do
    finals =
      Enum.map(payload.permutations, fn permutation ->
        {:error, {:permutation, observed}} =
          repo.transaction(fn ->
            isolated =
              Keyword.fetch!(opts, :account_owner).(
                "#{account.owner_id}-#{Enum.join(permutation)}"
              )

            results =
              Enum.map(permutation, &deliver(repo, isolated, Enum.at(payload.deliveries, &1)))

            repo.rollback(
              {:permutation,
               %{
                 delivery_count: length(results),
                 results: results,
                 final: durable_facts(repo, isolated)
               }}
            )
          end)

        observed
      end)

    %{permutations: finals}
  end

  def repeat(repo, account, %{command: %{payload: payload}}) do
    delivery = hd(payload.deliveries)
    results = Enum.map(1..payload.repeat_count, fn _ -> deliver(repo, account, delivery) end)

    %{
      delivery_count: length(results),
      results: results,
      durable: durable_facts(repo, account)
    }
  end

  def matches_expected?(%{kind: "equal_order_delivery"}, %{permutations: permutations}) do
    permutations != [] and Enum.uniq(Enum.map(permutations, & &1.final)) |> length() == 1
  end

  def matches_expected?(%{kind: "repeat_delivery"}, observed) do
    observed.durable == %{
      observation_count: 1,
      grant_count: 1,
      snapshot_revision: 1,
      audit_count: 1
    } and
      Enum.count(observed.results, &(&1.insert == :owner)) == 1
  end

  defp deliver(repo, account, delivery) do
    owner? =
      not repo.exists?(
        from(o in Observation,
          where:
            o.rail == ^delivery.rail and o.environment == ^delivery.environment and
              o.provider_event_id == ^delivery.provider_event_id
        )
      )

    {insert, observation} =
      case Observation.insert_idempotently(
             repo,
             Map.put(delivery, :account_id, account.id) |> observation_attrs()
           ) do
        {:ok, observation} ->
          insert = if owner?, do: :owner, else: :existing
          {insert, observation}

        {:error, changeset} ->
          raise "ordering delivery rejected: #{inspect(changeset.errors)}"
      end

    projection =
      case Projector.project(observation, logical_plan: delivery.logical_product) do
        {:ok, _} -> :projected
        {:noop, :stale} -> :stale
        {:noop, :no_material_change} -> :no_material_change
        other -> raise "unexpected ordering projection: #{inspect(other)}"
      end

    %{insert: insert, projection: projection}
  end

  defp observation_attrs(delivery) do
    %{
      account_id: delivery.account_id,
      rail: delivery.rail,
      environment: delivery.environment,
      provider_event_id: delivery.provider_event_id,
      provider_transaction_id: delivery.provider_transaction_id,
      kind: "grant",
      provider_lineage_id: delivery.provider_lineage_id,
      provider_product_id: delivery.provider_product_id,
      provider_order: delivery.provider_order,
      observed_at: DateTime.from_iso8601(delivery.clock) |> elem(1),
      state: :qualified,
      retry_count: 0,
      metadata: %{"source" => "fake_observer"},
      evidence_digest: String.duplicate("a", 64)
    }
  end

  defp durable_facts(repo, account) do
    {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    %{
      observation_count:
        repo.aggregate(from(o in Observation, where: o.account_id == ^account.id), :count, :id),
      grant_count:
        repo.aggregate(
          from(g in Grant, where: g.account_id == ^account.id and is_nil(g.superseded_at)),
          :count,
          :id
        ),
      snapshot_revision: snapshot.revision,
      audit_count:
        repo.aggregate(from(e in Event, where: e.subject_id == ^account.id), :count, :id)
    }
  end
end
