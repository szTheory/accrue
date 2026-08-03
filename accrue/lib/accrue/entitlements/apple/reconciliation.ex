defmodule Accrue.Entitlements.Apple.Reconciliation.Checkpoint do
  @moduledoc false
  use Accrue.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accrue_entitlement_apple_reconciliation_checkpoints" do
    field(:lineage_id, :binary_id)
    field(:environment, Ecto.Enum, values: [:production, :sandbox])
    field(:query_fingerprint, :string)
    field(:pending_revision, :string)
    field(:completed_revision, :string)

    field(:run_state, Ecto.Enum,
      values: [:idle, :running, :retrying, :needs_repair],
      default: :idle
    )

    field(:page_count, :integer, default: 0)
    field(:page_budget, :integer, default: 25)
    field(:attempts, :integer, default: 0)
    field(:last_success_at, :utc_datetime_usec)
    field(:next_due_at, :utc_datetime_usec)
    field(:retry_after_at, :utc_datetime_usec)
    field(:last_provider_class, :string)
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(checkpoint, attrs) do
    checkpoint
    |> cast(attrs, [
      :lineage_id,
      :environment,
      :query_fingerprint,
      :pending_revision,
      :completed_revision,
      :run_state,
      :page_count,
      :page_budget,
      :attempts,
      :last_success_at,
      :next_due_at,
      :retry_after_at,
      :last_provider_class
    ])
    |> validate_required([
      :lineage_id,
      :environment,
      :run_state,
      :page_count,
      :page_budget,
      :attempts
    ])
    |> validate_number(:page_count, greater_than_or_equal_to: 0)
    |> validate_number(:page_budget, greater_than: 0, less_than_or_equal_to: 25)
    |> unique_constraint(:lineage_id,
      name: :accrue_apple_reconciliation_lineage_environment_index
    )
  end
end

defmodule Accrue.Entitlements.Apple.Reconciliation do
  @moduledoc false
  import Ecto.Query

  alias Accrue.Entitlements.Apple.{Client, ReconciliationWakeup}
  alias Accrue.Entitlements.Apple.Reconciliation.Admission
  alias Accrue.Entitlements.Apple.Reconciliation.Checkpoint

  @page_budget 25
  @regular_seconds 6 * 60 * 60
  @max_attempts 12
  @apple_lifecycle_precedence %{
    active: 10,
    renewal_disabled: 20,
    grace: 30,
    billing_retry: 40,
    expired: 50,
    refunded: 60,
    revoked: 70
  }

  @doc false
  # This is deliberately the only Apple lifecycle/order normalization seam. It
  # accepts facts only after verification; raw provider identifiers never take
  # part in ordering.
  def normalize_lifecycle(%{} = facts) do
    lifecycle = facts |> Map.fetch!(:lifecycle) |> normalize_lifecycle_name()
    signed_at = Map.fetch!(facts, :signed_at)
    effective_at = Map.fetch!(facts, :effective_at)
    evidence_digest = Map.fetch!(facts, :evidence_digest)

    %{
      kind: Atom.to_string(lifecycle),
      expires_at: lifecycle_bound(lifecycle, facts),
      provider_order_key: apple_order_key(signed_at, effective_at, lifecycle, evidence_digest)
    }
  end

  @doc false
  def apple_order_key(
        %DateTime{} = signed_at,
        %DateTime{} = effective_at,
        lifecycle,
        evidence_digest
      )
      when is_binary(evidence_digest) do
    lifecycle = normalize_lifecycle_name(lifecycle)

    [
      epoch_key(signed_at),
      epoch_key(effective_at),
      @apple_lifecycle_precedence
      |> Map.fetch!(lifecycle)
      |> Integer.to_string()
      |> String.pad_leading(2, "0"),
      binary_part(evidence_digest, 0, min(byte_size(evidence_digest), 32))
    ]
    |> Enum.join(":")
  end

  defp lifecycle_bound(lifecycle, facts) when lifecycle in [:active, :renewal_disabled],
    do: Map.get(facts, :expires_at)

  defp lifecycle_bound(:grace, facts), do: Map.get(facts, :grace_expires_at)

  defp lifecycle_bound(:billing_retry, facts), do: Map.get(facts, :last_verified_expires_at)

  defp lifecycle_bound(_terminal, _facts), do: nil

  defp normalize_lifecycle_name(lifecycle)
       when lifecycle in [
              :active,
              :renewal_disabled,
              :grace,
              :billing_retry,
              :expired,
              :refunded,
              :revoked
            ],
       do: lifecycle

  defp normalize_lifecycle_name(lifecycle) when is_binary(lifecycle),
    do: lifecycle |> String.to_existing_atom() |> normalize_lifecycle_name()

  defp normalize_lifecycle_name(:grant), do: :active

  defp epoch_key(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_unix(:microsecond)
    |> Integer.to_string()
    |> String.pad_leading(20, "0")
  end

  def enqueue(lineage_id, environment, reason, opts \\ []) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    repo.transact(fn ->
      enqueue_in_transaction(repo, lineage_id, environment, reason)
    end)
  end

  @doc false
  def enqueue_in_transaction(repo, lineage_id, environment, reason) do
    with {:ok, wakeup} <-
           ReconciliationWakeup.enqueue_in_transaction(repo, lineage_id, environment, reason),
         {:ok, _job} <- Oban.insert(Accrue.Entitlements.Apple.ReconciliationWakeupWorker.new(%{})) do
      {:ok, wakeup}
    end
  end

  # A wakeup is deleted only after its job has been inserted in the same database transaction.
  # PostgreSQL row locking, rather than Oban uniqueness, is the execution ownership boundary.
  def drain_wakeups(repo, opts \\ []) do
    insert_job = Keyword.get(opts, :insert_job, &Oban.insert/1)

    repo.transact(fn ->
      repo.all(
        from(w in ReconciliationWakeup,
          order_by: [asc: w.requested_at],
          lock: "FOR UPDATE SKIP LOCKED"
        )
      )
      |> Enum.reduce_while({:ok, 0}, fn wakeup, {:ok, count} ->
        job =
          Accrue.Entitlements.Apple.ReconcileWorker.new(%{
            "lineage_id" => wakeup.lineage_id,
            "environment" => Atom.to_string(wakeup.environment),
            "reason" => wakeup.reason
          })

        case insert_job.(job) do
          {:ok, _} ->
            {:ok, _} = repo.delete(wakeup)
            {:cont, {:ok, count + 1}}

          {:error, reason} ->
            repo.rollback({:job_insert_failed, reason})
        end
      end)
    end)
  end

  def due(%{next_due_at: nil}, _now), do: true
  def due(%{next_due_at: %DateTime{} = due}, now), do: DateTime.compare(due, now) != :gt
  def due(_, _), do: false

  def query_fingerprint(filters) when is_map(filters) do
    filters
    |> canonical()
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  def retry_after({:error, {:rate_limited, seconds}}, _attempt, now)
      when is_integer(seconds) and seconds >= 0,
      do: DateTime.add(now, seconds, :second)

  def retry_after({:error, _}, attempt, now) do
    # Deterministic positive jitter is intentionally bounded at ten percent so tests and
    # host telemetry retain a reproducible upper bound.
    seconds = min(30 * trunc(:math.pow(2, max(attempt - 1, 0))), @regular_seconds)
    DateTime.add(now, min(trunc(seconds * 1.1), @regular_seconds), :second)
  end

  def run(args, opts \\ [])

  def run(%{"lineage_id" => lineage_id, "environment" => environment} = args, opts)
      when is_binary(environment) do
    run(
      %{
        lineage_id: lineage_id,
        environment: normalize_environment(environment),
        filters: Map.get(args, "filters", %{sort: :ascending, product_types: ["AUTO_RENEWABLE"]})
      },
      opts
    )
  end

  def run(%{lineage_id: lineage_id, environment: environment} = args, opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())
    client = Keyword.fetch!(opts, :client)
    filters = Map.get(args, :filters, %{sort: :ascending, product_types: ["AUTO_RENEWABLE"]})
    now = Keyword.get(opts, :now, DateTime.utc_now())

    repo.transact(fn ->
      checkpoint = lock_checkpoint(repo, lineage_id, environment)
      fingerprint = query_fingerprint(filters)

      result =
        cond do
          checkpoint.query_fingerprint not in [nil, fingerprint] and
              not is_nil(checkpoint.pending_revision) ->
            mark_repair(repo, checkpoint, :cursor_corruption)

          checkpoint.attempts >= @max_attempts ->
            mark_repair(repo, checkpoint, :attempts_exhausted)

          true ->
            reconcile_page(
              repo,
              checkpoint,
              client,
              lineage_id,
              environment,
              filters,
              fingerprint,
              now,
              opts
            )
        end

      {:ok,
       if(match?({:error, _}, result),
         do: schedule_retry(repo, checkpoint, result, now),
         else: result
       )}
    end)
  end

  defp reconcile_page(
         repo,
         checkpoint,
         client,
         lineage_id,
         environment,
         filters,
         fingerprint,
         now,
         opts
       ) do
    # Status is current-state authority; notification history is intentionally absent from
    # this admission path because it can only seed another durable wakeup.
    with {:ok, statuses} <- Client.subscription_statuses(client, lineage_id, environment),
         :ok <- admit_statuses(repo, lineage_id, environment, statuses, opts),
         {:ok, page} <-
           Client.transaction_history(
             client,
             lineage_id,
             filters,
             checkpoint.pending_revision,
             environment
           ) do
      with :ok <-
             admit_transactions(
               repo,
               lineage_id,
               environment,
               Map.get(page, :signed_transactions, []),
               opts
             ) do
        persist_page(repo, checkpoint, page, fingerprint, now, opts)
      end
    else
      {:error, :config_invalid} -> mark_repair(repo, checkpoint, :config_invalid)
      {:error, :unauthorized} -> mark_repair(repo, checkpoint, :unauthorized)
      error -> schedule_retry(repo, checkpoint, error, now)
    end
  end

  defp persist_page(repo, checkpoint, page, fingerprint, now, opts) do
    pages = checkpoint.page_count + 1

    cond do
      pages > min(checkpoint.page_budget, @page_budget) ->
        mark_repair(repo, checkpoint, :page_budget_exhausted)

      Map.get(page, :has_more, false) ->
        checkpoint =
          update_checkpoint(repo, checkpoint, %{
            query_fingerprint: fingerprint,
            pending_revision: Map.get(page, :revision),
            page_count: pages,
            run_state: :running,
            retry_after_at: nil
          })

        with {:ok, _job} <-
               Keyword.get(opts, :continue, &Oban.insert/1).(
                 Accrue.Entitlements.Apple.ReconcileWorker.new(%{
                   "lineage_id" => checkpoint.lineage_id,
                   "environment" => Atom.to_string(checkpoint.environment),
                   "reason" => "continuation"
                 })
               ) do
          checkpoint
        else
          {:error, reason} -> repo.rollback({:continuation_insert_failed, reason})
        end

      true ->
        revision = Map.get(page, :revision, checkpoint.pending_revision)

        update_checkpoint(repo, checkpoint, %{
          query_fingerprint: fingerprint,
          pending_revision: nil,
          completed_revision: revision,
          page_count: 0,
          attempts: 0,
          run_state: :idle,
          last_success_at: now,
          next_due_at: DateTime.add(now, @regular_seconds, :second),
          retry_after_at: nil,
          last_provider_class: "ok"
        })
    end
  end

  defp schedule_retry(repo, checkpoint, error, now) do
    attempt = checkpoint.attempts + 1

    if attempt >= @max_attempts,
      do: mark_repair(repo, checkpoint, :attempts_exhausted),
      else:
        update_checkpoint(repo, checkpoint, %{
          attempts: attempt,
          run_state: :retrying,
          retry_after_at: retry_after(error, attempt, now),
          last_provider_class: provider_class(error)
        })
  end

  defp mark_repair(repo, checkpoint, reason),
    do:
      update_checkpoint(repo, checkpoint, %{
        run_state: :needs_repair,
        retry_after_at: nil,
        last_provider_class: to_string(reason)
      })

  defp update_checkpoint(repo, checkpoint, attrs),
    do: repo.update!(Checkpoint.changeset(checkpoint, attrs))

  defp lock_checkpoint(repo, lineage_id, environment) do
    repo.insert!(
      Checkpoint.changeset(%Checkpoint{}, %{
        lineage_id: lineage_id,
        environment: environment,
        run_state: :idle,
        page_count: 0,
        page_budget: @page_budget,
        attempts: 0
      }),
      on_conflict: :nothing,
      conflict_target: [:lineage_id, :environment]
    )

    repo.one!(
      from(c in Checkpoint,
        where: c.lineage_id == ^lineage_id and c.environment == ^environment,
        lock: "FOR UPDATE"
      )
    )
  end

  defp provider_class({:error, {:rate_limited, _}}), do: "rate_limited"
  defp provider_class({:error, reason}), do: to_string(reason)
  defp provider_class(_), do: "provider_unavailable"
  defp normalize_environment(value) when value in [:production, :sandbox], do: value
  defp normalize_environment("production"), do: :production
  defp normalize_environment("sandbox"), do: :sandbox

  defp admit_transactions(repo, lineage_id, environment, transactions, opts) do
    case Keyword.get(opts, :admission) do
      admission when is_list(admission) ->
        Enum.reduce_while(transactions, :ok, fn transaction, :ok ->
          case Admission.admit_transaction(repo, lineage_id, environment, transaction, admission) do
            :ok -> {:cont, :ok}
            {:ok, _} -> {:cont, :ok}
            {:error, _} = error -> {:halt, error}
            _ -> {:halt, {:error, :admission_failed}}
          end
        end)

      _ ->
        {:error, :config_invalid}
    end
  end

  defp admit_statuses(repo, lineage_id, environment, statuses, opts) when is_list(statuses) do
    case Keyword.get(opts, :admission) do
      admission when is_list(admission) ->
        Enum.reduce_while(statuses, :ok, fn status, :ok ->
          case Admission.admit_status(repo, lineage_id, environment, status, admission) do
            :ok -> {:cont, :ok}
            {:error, _} = error -> {:halt, error}
          end
        end)

      _ ->
        {:error, :config_invalid}
    end
  end

  defp admit_statuses(_, _, _, _, _), do: {:error, :invalid_payload}

  defp canonical(map) when is_map(map),
    do: map |> Enum.map(fn {key, value} -> {key, canonical(value)} end) |> Enum.sort()

  defp canonical(list) when is_list(list), do: Enum.map(list, &canonical/1)
  defp canonical(value), do: value
end
