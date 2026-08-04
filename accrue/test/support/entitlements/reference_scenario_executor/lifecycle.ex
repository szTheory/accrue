defmodule Accrue.Entitlements.ReferenceScenarioExecutor.Lifecycle do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.{Grant, Observation, Projector}
  alias Accrue.Events.Event

  @lifecycle_kinds ~w(apple_verified_purchase stripe_verified_purchase grant_observation refund_observation stripe_retraction)

  def execute(repo, account, %{kind: "apple_verified_purchase", command: %{payload: payload}}) do
    before_audits = audit_count(repo, account.id)

    with {:ok, outcome} <-
           Accrue.Entitlements.observe_apple_evidence(account, apple_evidence(account, payload)),
         %Observation{} = observation <-
           repo.one!(
             from(o in Observation,
               where:
                 o.account_id == ^account.id and o.rail == :apple and
                   o.provider_transaction_id == ^payload.provider_transaction_id
             )
           ) do
      collect(repo, account, "apple_verified_purchase", observation, outcome, before_audits)
    end
  end

  def execute(repo, account, %{kind: kind, command: %{payload: payload}})
      when kind in @lifecycle_kinds do
    before_audits = audit_count(repo, account.id)

    with {:ok, observation} <- insert_observation(repo, account, payload, observation_kind(kind)),
         outcome <- Projector.project(observation, logical_plan: payload.logical_product) do
      collect(repo, account, kind, observation, outcome, before_audits)
    end
  end

  # The synthetic Apple command remains bounded. Apple admission itself is covered by
  # its dedicated tracer; lifecycle collection here follows the shared Observation /
  # Projector authority used for all fixture rows.
  defp insert_observation(repo, account, payload, kind) do
    Observation.insert_idempotently(repo, %{
      account_id: account.id,
      rail: payload.rail,
      environment: payload.environment,
      provider_event_id: payload.provider_event_id,
      provider_transaction_id: payload.provider_transaction_id,
      kind: kind,
      provider_lineage_id: payload.provider_lineage_id,
      provider_product_id: payload.provider_product_id,
      provider_order: payload.provider_order,
      observed_at: DateTime.from_iso8601(payload.clock) |> elem(1),
      state: :qualified,
      retry_count: 0,
      metadata: %{"source" => "fake_observer"},
      evidence_digest: String.duplicate("a", 64)
    })
  end

  defp apple_evidence(account, payload) do
    Jason.encode!(%{
      "originalTransactionId" => payload.provider_lineage_id,
      "appAccountToken" => account.id,
      "transactionId" => payload.provider_transaction_id,
      "productId" => payload.provider_product_id,
      "signedDate" => 1_754_000_000_000,
      "expiresDate" => 1_800_000_000_000
    })
  end

  defp collect(repo, account, kind, _observation, outcome, before_audits) do
    {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    %{
      result: %{
        tag: outcome_tag(outcome),
        disposition: kind,
        projection: projection_disposition(outcome)
      },
      durable: %{
        observation_kind: observation_kind(kind),
        observation_count:
          repo.aggregate(from(o in Observation, where: o.account_id == ^account.id), :count, :id),
        grant_count:
          repo.aggregate(
            from(g in Grant, where: g.account_id == ^account.id and is_nil(g.superseded_at)),
            :count,
            :id
          ),
        source_count: length(snapshot.sources),
        plan_count: length(snapshot.plans),
        snapshot_revision: snapshot.revision,
        audit_delta: audit_count(repo, account.id) - before_audits
      },
      cache: %{disposition: cache_disposition(kind, outcome)}
    }
  end

  defp observation_kind("refund_observation"), do: "retract"
  defp observation_kind("stripe_retraction"), do: "retract"
  defp observation_kind(_), do: "grant"
  defp outcome_tag({:ok, _}), do: "projected"
  defp outcome_tag({:noop, _}), do: "noop"
  defp outcome_tag({:error, _}), do: "error"

  defp outcome_tag(%{disposition: disposition}) when is_atom(disposition),
    do: Atom.to_string(disposition)

  defp projection_disposition({:ok, _}), do: "material_change"
  defp projection_disposition({:noop, reason}), do: Atom.to_string(reason)
  defp projection_disposition({:error, _}), do: "error"

  defp projection_disposition(%{disposition: disposition}) when is_atom(disposition),
    do: Atom.to_string(disposition)

  defp cache_disposition(kind, _) when kind in ["refund_observation", "stripe_retraction"],
    do: "replace"

  defp cache_disposition(_, _), do: "preserve"

  defp audit_count(repo, account_id),
    do: repo.aggregate(from(e in Event, where: e.subject_id == ^account_id), :count, :id)
end
