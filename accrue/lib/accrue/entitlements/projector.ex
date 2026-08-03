defmodule Accrue.Entitlements.Projector do
  @moduledoc "The sole transactional writer for current grants and account revisions."

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Grant, Observation, Snapshot}

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

    Accrue.Telemetry.span([:accrue, :entitlements, :projector, :project], metadata, fn ->
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
    Accrue.Repo.transact(fn repo ->
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
               Snapshot.authorization_signature(after_snapshot) do
            {:noop, :no_material_change}
          else
            revision = account.revision + 1
            {:ok, updated} = repo.update(Account.changeset(account, %{revision: revision}))
            snapshot = %{Snapshot.fetch(repo, updated) | revision: revision}
            insert_follow_up!(snapshot, observation)
            {:ok, snapshot}
          end
      end
    end)
    |> unwrap_transaction()
  end

  defp apply_observation(repo, observation, _opts) do
    current =
      repo.one(
        from(grant in Grant,
          where:
            grant.account_id == ^observation.account_id and grant.rail == ^observation.rail and
              grant.environment == ^observation.environment and
              grant.provider_lineage_id == ^observation.provider_lineage_id and
              is_nil(grant.superseded_at),
          limit: 1
        )
      )

    cond do
      current && current.provider_order >= observation.provider_order ->
        :noop

      current ->
        {:ok, _} = repo.update(Grant.changeset(current, %{superseded_at: DateTime.utc_now()}))
        insert_grant!(repo, observation)
        :changed

      true ->
        insert_grant!(repo, observation)
        :changed
    end
  end

  defp insert_grant!(repo, observation) do
    attrs = %{
      account_id: observation.account_id,
      source_observation_id: observation.id,
      rail: observation.rail,
      environment: observation.environment,
      provider_lineage_id: observation.provider_lineage_id,
      provider_product_id: observation.provider_product_id,
      source_item_id: observation.provider_transaction_id || observation.provider_event_id,
      quantity: 1,
      provider_order: observation.provider_order,
      account_revision: 0,
      effective_at: observation.observed_at
    }

    repo.insert!(Grant.changeset(%Grant{}, attrs))
  end

  defp insert_follow_up!(snapshot, observation) do
    %{
      "account_id" => snapshot.account_id,
      "revision" => snapshot.revision,
      "action" => "projected",
      "rail" => Atom.to_string(observation.rail)
    }
    |> FollowUpWorker.new(
      unique: [fields: [:args], keys: ["account_id", "revision", "action"], period: :infinity]
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
      actor_id: Keyword.get(opts, :actor_id)
    }
    |> Map.take(@metadata_keys)
  end
end
