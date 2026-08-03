defmodule Accrue.Entitlements.Apple.Intake do
  @moduledoc false
  use Accrue.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Accrue.Entitlements.{Observation, Projector, Snapshot}
  alias Accrue.Entitlements.Apple.{Lineage, Reconciliation, ReconciliationWakeup}
  alias Accrue.Events

  @terminal_reasons [
    :verified_unbound,
    :ownership_conflict,
    :invalid_payload,
    :invalid_algorithm,
    :invalid_chain,
    :invalid_certificate,
    :wrong_bundle,
    :wrong_environment,
    :wrong_app,
    :unsupported_family,
    :unmapped_product,
    :config_invalid
  ]
  @retryable_reasons [
    :provider_unavailable,
    :rate_limited,
    :persistence_unavailable,
    :reconciliation_stalled
  ]
  @max_attempts 12

  defmodule VerifiedEvidence do
    @enforce_keys [
      :environment,
      :original_transaction_id,
      :provider_event_id,
      :provider_transaction_id,
      :product_id,
      :lifecycle,
      :effective_at,
      :signed_at,
      :evidence_digest,
      :verifier_version,
      :config_version
    ]
    defstruct [
      :environment,
      :original_transaction_id,
      :app_account_token,
      :provider_event_id,
      :provider_transaction_id,
      :product_id,
      :logical_plan,
      :lifecycle,
      :effective_at,
      :expires_at,
      :grace_expires_at,
      :last_verified_expires_at,
      :signed_at,
      :evidence_digest,
      :verifier_version,
      :config_version
    ]
  end

  defmodule Outcome do
    @enforce_keys [:disposition, :reason, :next_action]
    defstruct [:disposition, :reason, :next_action, :snapshot, :revision]
    @type t :: %__MODULE__{}
  end

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accrue_entitlement_apple_intakes" do
    field(:environment, Ecto.Enum, values: [:production, :sandbox])
    field(:provider_event_id, :string)
    field(:lineage_id, :binary_id)
    field(:evidence_digest, :string)
    field(:correlation_hash, :string)
    field(:verifier_version, :string)
    field(:config_version, :string)
    field(:disposition, :string)
    field(:reason, :string)
    field(:next_action, :string)
    field(:attempts, :integer, default: 0)
    field(:next_retry_at, :utc_datetime_usec)
    field(:evidence_ref, :string)
    field(:evidence_expires_at, :utc_datetime_usec)
    timestamps(type: :utc_datetime_usec)
  end

  def observe(account, %VerifiedEvidence{} = evidence, opts \\ []) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    try do
      case repo.transact(fn -> {:ok, do_observe(repo, account, evidence, opts)} end) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error in RuntimeError ->
        if error.message == "injected_failure",
          do: {:error, :injected_failure},
          else: reraise(error, __STACKTRACE__)
    end
  end

  @doc false
  # Notifications are an account-independent reconciliation signal. They must
  # become durable before Apple receives an acknowledgement, but they never
  # claim a lineage or write an account observation directly.
  def observe_notification(%VerifiedEvidence{} = evidence, opts \\ []) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    try do
      case repo.transact(fn -> {:ok, do_observe_notification(repo, evidence, opts)} end) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error in RuntimeError ->
        if error.message == "injected_failure",
          do: {:error, :injected_failure},
          else: reraise(error, __STACKTRACE__)
    end
  end

  @doc false
  def quarantine_notification(
        environment,
        evidence_digest,
        verifier_version,
        config_version,
        reason,
        opts \\ []
      )
      when is_atom(environment) and is_binary(evidence_digest) and is_atom(reason) do
    evidence = %VerifiedEvidence{
      environment: environment,
      original_transaction_id: "quarantine:" <> evidence_digest,
      provider_event_id: "quarantine:" <> evidence_digest,
      provider_transaction_id: "quarantine:" <> evidence_digest,
      product_id: "quarantine",
      lifecycle: :grant,
      effective_at: DateTime.utc_now(),
      signed_at: DateTime.utc_now(),
      evidence_digest: evidence_digest,
      verifier_version: verifier_version,
      config_version: config_version
    }

    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    try do
      case repo.transact(fn ->
             lineage = Lineage.lock_or_insert(repo, environment, evidence.original_transaction_id)
             {:ok, persist_terminal(repo, lineage, evidence, reason)}
           end) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error in RuntimeError ->
        if error.message == "injected_failure",
          do: {:error, :injected_failure},
          else: reraise(error, __STACKTRACE__)
    end
  end

  @doc false
  def retry(_account, provider_event_id, opts \\ []) when is_binary(provider_event_id) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    repo.transact(fn ->
      intake =
        repo.one!(
          from(i in __MODULE__,
            where: i.provider_event_id == ^provider_event_id,
            lock: "FOR UPDATE"
          )
        )

      reason = String.to_existing_atom(intake.reason)

      {:ok,
       cond do
         reason in @terminal_reasons or intake.reason == "needs_repair" ->
           %Outcome{disposition: :quarantined, reason: reason, next_action: action_for(reason)}

         reason in @retryable_reasons and intake.attempts + 1 >= @max_attempts ->
           {:ok, updated} =
             repo.update(
               changeset(intake, %{
                 attempts: @max_attempts,
                 reason: "needs_repair",
                 next_action: "contact_support",
                 next_retry_at: nil
               })
             )

           %Outcome{
             disposition: :quarantined,
             reason: :needs_repair,
             next_action: :contact_support,
             revision: updated.attempts
           }

         reason in @retryable_reasons ->
           {:ok, updated} =
             repo.update(
               changeset(intake, %{
                 attempts: intake.attempts + 1,
                 next_action: "retry_reconciliation"
               })
             )

           %Outcome{
             disposition: :retryable,
             reason: reason,
             next_action: :retry_reconciliation,
             revision: updated.attempts
           }

         true ->
           %Outcome{
             disposition: :quarantined,
             reason: :needs_repair,
             next_action: :contact_support
           }
       end}
    end)
    |> case do
      {:ok, outcome} -> {:ok, outcome}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def repair(account, lineage_id, %VerifiedEvidence{} = evidence, opts \\ []) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    try do
      case repo.transact(fn -> {:ok, do_repair(repo, account, lineage_id, evidence, opts)} end) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error in RuntimeError ->
        if error.message == "injected_failure",
          do: {:error, :injected_failure},
          else: reraise(error, __STACKTRACE__)
    end
  end

  defp do_observe(repo, account, evidence, opts) do
    lineage = Lineage.lock_or_insert(repo, evidence.environment, evidence.original_transaction_id)

    case evidence.logical_plan do
      nil -> persist_terminal(repo, lineage, evidence, :unmapped_product)
      _ -> do_observe_claim(repo, lineage, account, evidence, opts)
    end
  end

  defp do_observe_notification(repo, evidence, opts) do
    lineage = Lineage.lock_or_insert(repo, evidence.environment, evidence.original_transaction_id)

    case insert_intake(repo, lineage, evidence, "verified", "verified", "reconcile") do
      {:duplicate, _} ->
        %Outcome{disposition: :noop, reason: :duplicate, next_action: :none}

      {:inserted, _} ->
        {:ok, _} =
          ReconciliationWakeup.enqueue_in_transaction(
            repo,
            lineage.id,
            evidence.environment,
            :notification
          )

        run_after_write(opts)
        %Outcome{disposition: :verified, reason: :verified, next_action: :reconcile}
    end
  end

  defp do_observe_claim(repo, lineage, account, evidence, opts) do
    case Lineage.claim(repo, lineage, account.id, evidence.app_account_token) do
      {:verified_unbound, lineage} ->
        persist_terminal(repo, lineage, evidence, :verified_unbound)

      {:ownership_conflict, lineage} ->
        persist_terminal(repo, lineage, evidence, :ownership_conflict)

      {_claim, lineage} ->
        persist_and_project(repo, lineage, account, evidence, opts)
    end
  end

  defp do_repair(repo, account, lineage_id, evidence, opts) do
    case Lineage.repair(repo, lineage_id, account.id, evidence.app_account_token, opts) do
      {:ownership_conflict, _lineage} ->
        %Outcome{
          disposition: :quarantined,
          reason: :ownership_conflict,
          next_action: :review_ownership
        }

      {:verified_unbound, _lineage} ->
        %Outcome{
          disposition: :quarantined,
          reason: :verified_unbound,
          next_action: :repair_lineage
        }

      {_binding, lineage} ->
        outcome =
          persist_and_project(
            repo,
            lineage,
            account,
            evidence,
            Keyword.put(opts, :defer_after_write, true)
          )

        record_repair_audit!(account, outcome, opts)

        {:ok, _} =
          ReconciliationWakeup.enqueue_in_transaction(
            repo,
            lineage.id,
            evidence.environment,
            :repair
          )

        run_after_write(opts)
        outcome
    end
  end

  defp persist_and_project(repo, lineage, account, evidence, opts) do
    case insert_intake(repo, lineage, evidence, "verified", "verified", "reconcile") do
      {:duplicate, _} ->
        %Outcome{disposition: :noop, reason: :duplicate, next_action: :none}

      {:inserted, _} ->
        {:ok, observation} =
          Observation.insert_idempotently(repo, observation_attrs(account, evidence))

        result =
          Projector.project_in_transaction(repo, observation, logical_plan: evidence.logical_plan)

        {:ok, snapshot} = normalize_projection(result, repo, account)

        {:ok, _} =
          ReconciliationWakeup.enqueue_in_transaction(
            repo,
            lineage.id,
            evidence.environment,
            :verified
          )

        unless Keyword.get(opts, :defer_after_write, false), do: run_after_write(opts)

        %Outcome{
          disposition: :verified,
          reason: :verified,
          next_action: :reconcile,
          snapshot: snapshot,
          revision: snapshot.revision
        }
    end
  end

  defp persist_terminal(repo, lineage, evidence, reason) do
    insert_intake(
      repo,
      lineage,
      evidence,
      "quarantined",
      Atom.to_string(reason),
      Atom.to_string(action_for(reason))
    )

    %Outcome{disposition: :quarantined, reason: reason, next_action: action_for(reason)}
  end

  defp insert_intake(repo, lineage, evidence, disposition, reason, next_action) do
    attrs = %{
      environment: evidence.environment,
      provider_event_id: evidence.provider_event_id,
      lineage_id: lineage.id,
      evidence_digest: evidence.evidence_digest,
      correlation_hash: digest(evidence.original_transaction_id),
      verifier_version: evidence.verifier_version,
      config_version: evidence.config_version,
      disposition: disposition,
      reason: reason,
      next_action: next_action,
      attempts: 0
    }

    case repo.get_by(__MODULE__,
           environment: evidence.environment,
           provider_event_id: evidence.provider_event_id
         ) do
      nil ->
        case repo.insert(changeset(%__MODULE__{}, attrs),
               on_conflict: :nothing,
               conflict_target: [:environment, :provider_event_id]
             ) do
          {:ok, row} -> {:inserted, row}
          {:error, error} -> raise "failed to persist Apple intake: #{inspect(error.errors)}"
        end

      _ ->
        {:duplicate, nil}
    end
  end

  defp observation_attrs(account, evidence) do
    normalized = Reconciliation.normalize_lifecycle(Map.from_struct(evidence))

    %{
      account_id: account.id,
      rail: :apple,
      environment: evidence.environment,
      provider_event_id: evidence.provider_event_id,
      provider_transaction_id: evidence.provider_transaction_id,
      kind: normalized.kind,
      provider_lineage_id: evidence.original_transaction_id,
      provider_product_id: evidence.product_id,
      provider_order: 1,
      provider_order_key: normalized.provider_order_key,
      observed_at: evidence.effective_at,
      expires_at: normalized.expires_at,
      state: :qualified,
      retry_count: 0,
      metadata: %{"source" => "apple_server"},
      evidence_digest: evidence.evidence_digest
    }
  end

  defp normalize_projection({:ok, snapshot}, _repo, _account), do: {:ok, snapshot}
  defp normalize_projection({:noop, _}, repo, account), do: {:ok, Snapshot.fetch(repo, account)}
  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)

  defp run_after_write(opts) do
    case Keyword.get(opts, :after_write) do
      nil -> :ok
      callback -> callback.()
    end
  end

  defp record_repair_audit!(account, outcome, opts) do
    actor_id =
      case Keyword.get(opts, :actor_id) do
        nil -> nil
        value -> :crypto.hash(:sha256, to_string(value)) |> Base.encode16(case: :lower)
      end

    case Events.record(%{
           type: "entitlement.apple_lineage_repaired",
           subject_type: "EntitlementAccount",
           subject_id: account.id,
           actor_type: "admin",
           actor_id: actor_id,
           idempotency_key: "apple-lineage-repair:#{account.id}:#{outcome.revision || 0}",
           data: %{"action" => "repair", "reason" => Atom.to_string(outcome.reason)}
         }) do
      {:ok, _} -> :ok
      {:error, error} -> raise "failed to audit Apple lineage repair: #{inspect(error)}"
    end
  end

  defp changeset(intake, attrs),
    do:
      cast(intake, attrs, [
        :environment,
        :provider_event_id,
        :lineage_id,
        :evidence_digest,
        :correlation_hash,
        :verifier_version,
        :config_version,
        :disposition,
        :reason,
        :next_action,
        :attempts,
        :next_retry_at
      ])
      |> validate_required([
        :environment,
        :provider_event_id,
        :lineage_id,
        :evidence_digest,
        :verifier_version,
        :config_version,
        :disposition,
        :reason,
        :next_action
      ])
      |> unique_constraint(:provider_event_id,
        name: :accrue_apple_intakes_environment_provider_event_index
      )

  defp action_for(:verified_unbound), do: :repair_lineage
  defp action_for(:ownership_conflict), do: :review_ownership
  defp action_for(:unmapped_product), do: :map_product

  defp action_for(reason)
       when reason in [
              :provider_unavailable,
              :rate_limited,
              :persistence_unavailable,
              :reconciliation_stalled
            ],
       do: :retry_reconciliation

  defp action_for(_reason), do: :inspect_verification
end
