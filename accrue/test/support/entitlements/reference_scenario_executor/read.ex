defmodule Accrue.Entitlements.ReferenceScenarioExecutor.Read do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.{Grant, Observation, Projector, Snapshot}
  alias Accrue.Events.Event

  @login_kinds ~w(web_login ios_login)

  def execute(repo, account, %{kind: kind}) when kind in @login_kinds do
    before = counts(repo, account.id)
    {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    %{
      result: %{tag: "executed", disposition: kind},
      snapshot: snapshot_facts(snapshot),
      durable: Map.merge(counts(repo, account.id), deltas(before, counts(repo, account.id)))
    }
  end

  def execute(repo, account, %{kind: "purchase_preflight", command: %{payload: payload}}) do
    :ok = seed_equivalent_grant(repo, account, payload)
    before = counts(repo, account.id)

    decision =
      Accrue.Entitlements.purchase_decision(
        account.id,
        rail!(payload.rail),
        payload.provider_product_id,
        environment: rail!(payload.environment)
      )

    after_counts = counts(repo, account.id)

    %{
      result: %{
        tag: "executed",
        disposition: "purchase_preflight",
        status: Atom.to_string(decision.status),
        reason: Atom.to_string(decision.reason),
        target_rail: Atom.to_string(decision.target_rail),
        product_id: payload.provider_product_id
      },
      snapshot: %{revision: decision.revision, plans: [decision.logical_plan], sources: source_rails(decision.sources)},
      durable: Map.merge(after_counts, Map.put(deltas(before, after_counts), :snapshot_revision, decision.revision))
    }
  end

  def seed_equivalent_grant(repo, account, payload) do
    {rail, product_id} = equivalent_product!(payload)

    seed_grant(repo, account, payload, rail, product_id, "equivalent")
  end

  def seed_declared_grant(repo, account, payload) do
    seed_grant(repo, account, payload, rail!(payload.rail), payload.provider_product_id, "declared")
  end

  defp seed_grant(repo, account, payload, rail, product_id, suffix) do

    {:ok, observation} =
      Observation.insert_idempotently(repo, %{
        account_id: account.id,
        rail: rail,
        environment: payload.environment,
        provider_event_id: "#{payload.provider_event_id}:#{suffix}",
        provider_transaction_id: "#{payload.provider_transaction_id}:#{suffix}",
        kind: "grant",
        provider_lineage_id: "#{payload.provider_lineage_id}:#{suffix}",
        provider_product_id: product_id,
        provider_order: payload.provider_order,
        observed_at: DateTime.from_iso8601(payload.clock) |> elem(1),
        state: :qualified,
        retry_count: 0,
        metadata: %{"source" => "fake_observer"},
        evidence_digest: String.duplicate("b", 64)
      })

    _ = Projector.project(observation, logical_plan: payload.logical_product)
    :ok
  end

  def adversarial_result(repo, account, action, adapter: :generic_grant) do
    %{command: %{payload: payload}} = action
    :ok = seed_grant_on_target_rail(repo, account, payload)

    decision =
      Accrue.Entitlements.purchase_decision(
        account.id,
        rail!(payload.rail),
        payload.provider_product_id,
        environment: rail!(payload.environment)
      )

    preflight_match(%{result: %{status: Atom.to_string(decision.status), reason: Atom.to_string(decision.reason)}})
  end

  def adversarial_result(_repo, account, %{command: %{payload: payload}}, adapter: :no_effect) do
    {:ok, _snapshot} = Accrue.Entitlements.snapshot(account)
    preflight_match(%{result: %{status: "eligible", reason: "no_effect", product_id: payload.provider_product_id}})
  end

  def adversarial_result(_repo, account, %{command: %{payload: payload}}, adapter: :snapshot_only) do
    _snapshot = Snapshot.from_grants([], account_id: account.id, revision: 0, now: DateTime.from_iso8601(payload.clock) |> elem(1))
    preflight_match(%{result: %{status: "snapshot_only", reason: "no_decision", product_id: payload.provider_product_id}})
  end

  defp preflight_match(%{result: %{status: "block", reason: "equivalent_other_rail"}}), do: :ok
  defp preflight_match(_), do: {:error, :preflight_mismatch}

  defp seed_grant_on_target_rail(repo, account, payload) do
    seed_grant(repo, account, payload, rail!(payload.rail), payload.provider_product_id, "target")
  end

  defp equivalent_product!(payload) do
    target_rail = rail!(payload.rail)
    environment = rail!(payload.environment)
    logical_plan = rail!(payload.logical_product)

    Accrue.Config.entitlement_product_catalog()
    |> Enum.find_value(fn {{rail, candidate_environment, product_id}, plan} ->
      if rail != target_rail and candidate_environment == environment and plan == logical_plan,
        do: {rail, product_id}
    end)
    |> case do
      nil -> raise ArgumentError, "missing equivalent other-rail product"
      product -> product
    end
  end

  defp counts(repo, account_id) do
    %{
      observations: repo.aggregate(from(o in Observation, where: o.account_id == ^account_id), :count, :id),
      grants: repo.aggregate(from(g in Grant, where: g.account_id == ^account_id), :count, :id),
      audits: repo.aggregate(from(e in Event, where: e.subject_id == ^account_id), :count, :id)
    }
  end

  defp deltas(before, after_counts) do
    %{
      observation_delta: after_counts.observations - before.observations,
      grant_delta: after_counts.grants - before.grants,
      audit_delta: after_counts.audits - before.audits
    }
  end

  defp snapshot_facts(snapshot),
    do: %{revision: snapshot.revision, plans: snapshot.plans, sources: source_rails(snapshot.sources)}

  defp source_rails(sources), do: sources |> Enum.map(& &1.rail) |> Enum.sort()
  defp rail!(value) when is_atom(value), do: value
  defp rail!(value) when is_binary(value), do: String.to_existing_atom(value)
end
