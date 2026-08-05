defmodule Accrue.Entitlements.ReferenceScenarioExecutor.Ordering do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Grant, Observation, Projector}
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

  def parallel(repo, owner_id, %{command: %{payload: payload}}) do
    account = create_unboxed_account(repo, owner_id)

    try do
      results = release_workers(repo, account.id, payload)

      %{
        execution: :barrier,
        worker_count: length(payload.workers),
        results: Enum.sort(results),
        durable: unboxed(repo, fn -> durable_facts(repo, repo.get!(Account, account.id)) end)
      }
    after
      cleanup_unboxed(repo, account.id)
    end
  end

  def parallel_adversarial(repo, owner_id, %{command: %{payload: payload}},
        adapter: :generic_grant
      ) do
    account = create_unboxed_account(repo, owner_id)

    try do
      results =
        Enum.map(payload.workers, fn index ->
          unboxed(repo, fn ->
            deliver(repo, repo.get!(Account, account.id), Enum.at(payload.deliveries, index))
          end)
        end)

      %{
        execution: :sequential,
        worker_count: length(payload.workers),
        results: Enum.sort(results),
        durable: unboxed(repo, fn -> durable_facts(repo, repo.get!(Account, account.id)) end)
      }
    after
      cleanup_unboxed(repo, account.id)
    end
  end

  def parallel_adversarial(repo, owner_id, %{command: %{payload: payload}}, adapter: :no_effect) do
    account = create_unboxed_account(repo, owner_id)

    try do
      [first | rest] = payload.workers

      results =
        [
          unboxed(repo, fn ->
            deliver(repo, repo.get!(Account, account.id), Enum.at(payload.deliveries, first))
          end)
          | Enum.map(rest, fn _ -> %{insert: :existing, projection: :no_effect} end)
        ]

      %{
        execution: :replay,
        worker_count: length(payload.workers),
        results: Enum.sort(results),
        durable: unboxed(repo, fn -> durable_facts(repo, repo.get!(Account, account.id)) end)
      }
    after
      cleanup_unboxed(repo, account.id)
    end
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

  def matches_parallel_expected?(%{kind: "parallel_delivery"}, observed) do
    observed.execution == :barrier and observed.worker_count > 1 and
      observed.durable == %{
        observation_count: 1,
        grant_count: 1,
        snapshot_revision: 1,
        audit_count: 1
      } and Enum.count(observed.results, &(&1.projection == :projected)) == 1 and
      Enum.all?(observed.results, &(&1.projection in [:projected, :stale, :no_material_change]))
  end

  defp release_workers(repo, account_id, payload) do
    parent = self()
    ref = make_ref()

    tasks =
      Enum.map(payload.workers, fn index ->
        Task.async(fn ->
          unboxed(repo, fn ->
            send(parent, {ref, :ready, self()})

            receive do
              {^ref, :run} ->
                deliver(repo, repo.get!(Account, account_id), Enum.at(payload.deliveries, index))
            after
              5_000 -> raise "ordering barrier was not released"
            end
          end)
        end)
      end)

    for _ <- tasks, do: receive_ready!(ref)
    Enum.each(tasks, &send(&1.pid, {ref, :run}))
    Task.await_many(tasks, 10_000)
  end

  defp receive_ready!(ref) do
    receive do
      {^ref, :ready, _pid} -> :ok
    after
      5_000 -> raise "ordering worker did not reach the barrier"
    end
  end

  defp create_unboxed_account(repo, owner_id),
    do:
      unboxed(repo, fn ->
        Account.fetch_or_create(repo, "reference_scenario", owner_id) |> elem(1)
      end)

  defp cleanup_unboxed(repo, account_id) do
    unboxed(repo, fn ->
      repo.delete_all(from(g in Grant, where: g.account_id == ^account_id))
      repo.delete_all(from(o in Observation, where: o.account_id == ^account_id))
      repo.delete_all(from(a in Account, where: a.id == ^account_id))
    end)
  end

  defp unboxed(repo, fun), do: Ecto.Adapters.SQL.Sandbox.unboxed_run(repo, fun)

  defp deliver(repo, account, delivery) do
    observation =
      case Observation.insert_idempotently(
             repo,
             Map.put(delivery, :account_id, account.id) |> observation_attrs()
           ) do
        {:ok, observation} ->
          observation

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

    %{insert: if(projection == :projected, do: :owner, else: :existing), projection: projection}
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
