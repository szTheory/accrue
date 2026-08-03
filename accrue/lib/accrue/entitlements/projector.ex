defmodule Accrue.Entitlements.Projector do
  @moduledoc "The sole transactional writer for current grants and account revisions."

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Grant, Observation, Snapshot}
  alias Accrue.Events

  @metadata_keys [
    :revision,
    :action,
    :rail,
    :environment,
    :disposition,
    :reason,
    :account_id,
    :actor_id
  ]

  @spec project(Observation.t(), keyword()) ::
          {:ok, Snapshot.t()} | {:noop, atom()} | {:error, term()}
  def project(%Observation{} = observation, opts \\ []) do
    metadata = metadata(observation, opts)

    Accrue.Telemetry.span_private([:accrue, :entitlements, :projector, :project], metadata, fn ->
      do_project(observation, opts)
    end)
  end

  defmodule FollowUpWorker do
    @moduledoc false
    use Oban.Worker, queue: :accrue_entitlements, max_attempts: 3

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"account_id" => account_id, "revision" => revision}}) do
      case Accrue.Repo.get(Accrue.Entitlements.Account, account_id) do
        %{revision: current} when current == revision -> :ok
        _ -> :ok
      end
    end
  end

  defp do_project(%{state: state}, _opts) when state != :qualified, do: {:noop, :not_qualified}

  defp do_project(observation, opts) do
    Accrue.Repo.transact(fn repo -> {:ok, project_in_transaction(repo, observation, opts)} end)
    |> unwrap_transaction()
  end

  @doc false
  def project_in_transaction(repo, observation, opts \\ [])

  def project_in_transaction(_repo, %{state: state}, _opts) when state != :qualified,
    do: {:noop, :not_qualified}

  def project_in_transaction(repo, observation, opts) do
    account =
      repo.one!(
        from(account in Account,
          where: account.id == ^observation.account_id,
          lock: "FOR UPDATE"
        )
      )

    before = Snapshot.fetch(repo, account)

    case apply_observation(repo, observation, opts) do
      :noop ->
        {:noop, :stale}

      :changed ->
        after_snapshot = Snapshot.fetch(repo, account)

        if Snapshot.authorization_signature(before) ==
             Snapshot.authorization_signature(after_snapshot) or
             survivor_retraction?(observation, before, after_snapshot) do
          {:noop, :no_material_change}
        else
          revision = account.revision + 1
          {:ok, updated} = repo.update(Account.changeset(account, %{revision: revision}))
          snapshot = %{Snapshot.fetch(repo, updated) | revision: revision}
          record_projection!(account, snapshot, observation, opts)
          insert_follow_up!(snapshot, observation)
          {:ok, snapshot}
        end
    end
  end

  defp apply_observation(repo, observation, opts) do
    current =
      repo.all(
        from(grant in Grant,
          where:
            grant.account_id == ^observation.account_id and grant.rail == ^observation.rail and
              grant.environment == ^observation.environment and
              grant.provider_lineage_id == ^observation.provider_lineage_id and
              grant.provider_product_id == ^observation.provider_product_id and
              is_nil(grant.superseded_at)
        )
      )

    cond do
      current != [] and Enum.all?(current, &(not newer_than?(&1, observation))) ->
        :noop

      current == [] and stale_apple_observation?(repo, observation) ->
        :noop

      current != [] and retraction?(observation) ->
        supersede!(repo, current)
        :changed

      current != [] ->
        supersede!(repo, current)
        insert_grant!(repo, observation, opts)
        :changed

      retraction?(observation) ->
        :noop

      true ->
        insert_grant!(repo, observation, opts)
        :changed
    end
  end

  defp insert_grant!(repo, observation, opts) do
    attrs =
      %{
        account_id: observation.account_id,
        source_observation_id: observation.id,
        rail: observation.rail,
        environment: observation.environment,
        provider_lineage_id: observation.provider_lineage_id,
        provider_product_id: observation.provider_product_id,
        source_item_id: observation.provider_transaction_id || observation.provider_event_id,
        quantity: 1,
        provider_order: observation.provider_order,
        provider_order_key: observation.provider_order_key,
        account_revision: 0,
        effective_at: observation.observed_at,
        expires_at: observation.expires_at
      }
      |> maybe_put_logical_plan(Keyword.get(opts, :logical_plan))

    repo.insert!(Grant.changeset(%Grant{}, attrs))
  end

  defp maybe_put_logical_plan(attrs, nil), do: attrs

  defp maybe_put_logical_plan(attrs, plan) when is_atom(plan),
    do: Map.put(attrs, :logical_plan, Atom.to_string(plan))

  defp maybe_put_logical_plan(attrs, plan) when is_binary(plan),
    do: Map.put(attrs, :logical_plan, plan)

  defp supersede!(repo, grants) do
    Enum.each(grants, fn grant ->
      {:ok, _} = repo.update(Grant.changeset(grant, %{superseded_at: DateTime.utc_now()}))
    end)
  end

  defp retraction?(%{kind: kind}) when kind in ["retract", "revoked", "expired", "refunded"],
    do: true

  defp retraction?(_), do: false

  # Apple uses the complete, fixed-width key produced from verified lifecycle
  # facts. Other rails retain the Phase 217 integer ordering contract.
  defp newer_than?(%Grant{rail: :apple, provider_order_key: current}, %{
         rail: :apple,
         provider_order_key: incoming
       })
       when is_binary(current) and is_binary(incoming),
       do: incoming > current

  defp newer_than?(%Grant{provider_order: current}, %{provider_order: incoming}),
    do: incoming > current

  # Retractions leave no current grant to compare. Qualified Apple observations
  # retain the terminal high-water mark for that exact source scope.
  defp stale_apple_observation?(repo, %{rail: :apple, provider_order_key: incoming} = observation)
       when is_binary(incoming) do
    repo.exists?(
      from(candidate in Observation,
        where:
          candidate.account_id == ^observation.account_id and candidate.rail == :apple and
            candidate.environment == ^observation.environment and
            candidate.provider_lineage_id == ^observation.provider_lineage_id and
            candidate.provider_product_id == ^observation.provider_product_id and
            candidate.state == :qualified and candidate.provider_order_key > ^incoming
      )
    )
  end

  defp stale_apple_observation?(_repo, _observation), do: false

  # A retracted source does not advance the account revision when another current
  # source preserves the same effective plan, feature, quantity, and validity
  # bounds. The source summaries remain diagnostic-only; revision tracks access.
  defp survivor_retraction?(observation, before, after_snapshot) do
    retraction?(observation) and
      {before.plans, before.features, before.quantities, before.authorization_bounds} ==
        {after_snapshot.plans, after_snapshot.features, after_snapshot.quantities,
         after_snapshot.authorization_bounds}
  end

  defp record_projection!(account, snapshot, observation, opts) do
    attrs = %{
      type: "entitlement.projected",
      subject_type: "EntitlementAccount",
      subject_id: account.id,
      actor_type: "system",
      actor_id: hashed_actor_id(Keyword.get(opts, :actor_id)),
      idempotency_key: "entitlement-projected:#{account.id}:#{snapshot.revision}",
      data: %{
        "revision" => snapshot.revision,
        "action" => "projected",
        "rail" => Atom.to_string(observation.rail),
        "environment" => Atom.to_string(observation.environment),
        "disposition" => "material",
        "reason" => "authorization_changed",
        "account_id" => account.id
      }
    }

    case Events.record(attrs) do
      {:ok, _event} -> :ok
      {:error, error} -> raise "failed to audit entitlement projection: #{inspect(error)}"
    end
  end

  defp hashed_actor_id(nil), do: nil

  defp hashed_actor_id(actor_id),
    do: :crypto.hash(:sha256, to_string(actor_id)) |> Base.encode16(case: :lower)

  defp insert_follow_up!(snapshot, observation) do
    %{
      "account_id" => snapshot.account_id,
      "revision" => snapshot.revision,
      "action" => "projected",
      "rail" => Atom.to_string(observation.rail)
    }
    |> FollowUpWorker.new(
      unique: [
        fields: [:worker, :args],
        keys: [:account_id, :revision, :action],
        period: :infinity,
        states: [:available, :scheduled, :executing, :retryable, :completed]
      ]
    )
    |> Oban.insert()
    |> case do
      {:ok, _job} ->
        :ok

      {:error, changeset} ->
        raise "failed to enqueue entitlement follow-up: #{inspect(changeset.errors)}"
    end
  end

  defp unwrap_transaction({:ok, result}), do: result
  defp unwrap_transaction({:error, reason}), do: {:error, reason}

  defp metadata(observation, opts) do
    %{
      revision: Keyword.get(opts, :revision),
      action: :project,
      rail: observation.rail,
      environment: observation.environment,
      disposition: observation.state,
      reason: nil,
      account_id: observation.account_id,
      actor_id: hashed_actor_id(Keyword.get(opts, :actor_id))
    }
    |> Map.take(@metadata_keys)
  end
end
