defmodule Accrue.Entitlements.Repair do
  @moduledoc """
  Bounded, host-authorized recovery actions for entitlement operations.

  This context deliberately exposes named actions rather than a generic repair
  dispatcher. It never reconstructs accounts or invokes provider lifecycle or
  financial APIs. The host resolves the account and makes the authorization
  decision before calling this boundary; this module records the operator's
  bounded intent in the same transaction as any delegated local repair work.
  """

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Admin}
  alias Accrue.Entitlements.Apple.Reconciliation
  alias Accrue.Events.Event

  @max_reason_bytes 280
  @max_operation_id_bytes 128
  @opaque_id ~r/\A[A-Za-z0-9][A-Za-z0-9._:-]*\z/
  @environments [:production, :sandbox]

  @type outcome :: %{
          required(:action) => atom(),
          required(:disposition) => atom(),
          optional(:audit_id) => integer(),
          optional(:current_revision) => non_neg_integer(),
          optional(:diagnostic) => map()
        }

  @spec retry_missed_notification(Account.t(), map(), keyword()) ::
          {:ok, outcome()} | {:error, atom()}
  def retry_missed_notification(account, target, opts \\ []),
    do: reconciliation_action(:retry_missed_notification, account, target, opts)

  @spec recover_history_cursor(Account.t(), map(), keyword()) ::
          {:ok, outcome()} | {:error, atom()}
  def recover_history_cursor(account, target, opts \\ []),
    do: reconciliation_action(:recover_history_cursor, account, target, opts)

  @spec retry_provider_check(Account.t(), map(), keyword()) :: {:ok, outcome()} | {:error, atom()}
  def retry_provider_check(account, target, opts \\ []),
    do: reconciliation_action(:retry_provider_check, account, target, opts)

  @spec drain_reconciliation_backlog(Account.t(), map(), keyword()) ::
          {:ok, outcome()} | {:error, atom()}
  def drain_reconciliation_backlog(account, target, opts \\ []),
    do: execute(:drain_reconciliation_backlog, account, target, opts, :backlog)

  @spec replace_revoked_device(Account.t(), map(), keyword()) ::
          {:ok, outcome()} | {:error, atom()}
  def replace_revoked_device(account, target, opts \\ []),
    do: execute(:replace_revoked_device, account, target, opts, :device)

  @spec rotate_signing_keys(Account.t(), map(), keyword()) :: {:ok, outcome()} | {:error, atom()}
  def rotate_signing_keys(account, target, opts \\ []),
    do: execute(:rotate_signing_keys, account, target, opts, :key_set)

  @spec review_ownership_conflict(Account.t(), map(), keyword()) ::
          {:ok, outcome()} | {:error, atom()}
  def review_ownership_conflict(account, target, opts \\ []),
    do: review_action(:review_ownership_conflict, :needs_review, account, target, opts)

  @spec escalate_duplicate_charge(Account.t(), map(), keyword()) ::
          {:ok, outcome()} | {:error, atom()}
  def escalate_duplicate_charge(account, target, opts \\ []),
    do: review_action(:escalate_duplicate_charge, :escalated, account, target, opts)

  defp reconciliation_action(action, account, target, opts) do
    execute(action, account, target, opts, :reconciliation)
  end

  defp execute(action, %Account{} = account, target, opts, target_kind) do
    with :ok <- authorized?(account, opts),
         {:ok, normalized_target} <- normalize_target(target, target_kind),
         {:ok, command} <- command(opts) do
      if Keyword.get(opts, :dry_run, false) do
        {:ok, %{action: action, disposition: :dry_run, current_revision: account.revision}}
      else
        persist_and_run(action, account, normalized_target, command, opts)
      end
    end
  end

  defp execute(_, _, _, _, _), do: {:error, :invalid_account}

  defp review_action(action, disposition, %Account{} = account, target, opts) do
    with :ok <- authorized?(account, opts),
         {:ok, normalized_target} <- normalize_target(target, :correlation),
         {:ok, command} <- command(opts) do
      if Keyword.get(opts, :dry_run, false) do
        {:ok, %{action: action, disposition: :dry_run, current_revision: account.revision}}
      else
        persist_and_run(action, account, normalized_target, command, opts, disposition)
      end
    end
  end

  defp review_action(_, _, _, _, _), do: {:error, :invalid_account}

  defp persist_and_run(action, account, target, command, opts, disposition \\ :queued) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    repo.transact(fn ->
      locked_account =
        repo.one(from(a in Account, where: a.id == ^account.id, lock: "FOR UPDATE")) ||
          repo.rollback(:account_not_found)

      case existing_event(repo, command.operation_id) do
        %Event{subject_id: subject_id, id: audit_id} when subject_id == locked_account.id ->
          {:ok,
           %{
             action: action,
             disposition: :already_completed,
             audit_id: audit_id,
             current_revision: locked_account.revision
           }}

        %Event{} ->
          repo.rollback(:operation_id_conflict)

        nil ->
          audit =
            repo.insert!(Event.changeset(audit_attrs(action, locked_account, target, command)))

          case run_effect(action, target, opts, repo) do
            :ok -> {:ok, converged(repo, locked_account, action, disposition, audit.id)}
            {:ok, _} -> {:ok, converged(repo, locked_account, action, disposition, audit.id)}
            {:error, reason} -> repo.rollback({:repair_effect_failed, reason})
            _ -> repo.rollback(:repair_effect_failed)
          end
      end
    end)
    |> case do
      {:ok, outcome} -> {:ok, outcome}
      {:error, reason} -> {:error, reason}
    end
  end

  defp run_effect(action, target, opts, repo)
       when action in [:retry_missed_notification, :recover_history_cursor, :retry_provider_check] do
    case Keyword.get(opts, :effect) do
      effect when is_function(effect, 1) ->
        effect.(target)

      _ ->
        enqueue = Keyword.get(opts, :enqueue, &default_enqueue/4)
        enqueue.(target.lineage_id, target.environment, Atom.to_string(action), repo: repo)
    end
  end

  defp run_effect(:drain_reconciliation_backlog, target, opts, repo) do
    case Keyword.get(opts, :effect) do
      effect when is_function(effect, 1) -> effect.(target)
      _ -> Reconciliation.enqueue_due(repo, limit: target.limit)
    end
  end

  # Device replacement and key rotation are intentionally guidance actions. They
  # do not accept proof material or credentials and cannot mutate a provider.
  defp run_effect(_action, target, opts, _repo) do
    case Keyword.get(opts, :effect) do
      effect when is_function(effect, 1) -> effect.(target)
      _ -> :ok
    end
  end

  defp default_enqueue(lineage_id, environment, reason, opts) do
    Reconciliation.enqueue_in_transaction(
      Keyword.fetch!(opts, :repo),
      lineage_id,
      environment,
      reason
    )
  end

  defp converged(repo, account, action, disposition, audit_id) do
    case Admin.diagnostic_for_account(account, repo: repo) do
      {:ok, diagnostic} ->
        %{
          action: action,
          disposition: disposition,
          audit_id: audit_id,
          current_revision: diagnostic.snapshot.revision,
          diagnostic: diagnostic
        }

      {:error, _} ->
        repo.rollback(:post_action_diagnostic_unavailable)
    end
  end

  defp authorized?(account, opts) do
    actor = Keyword.get(opts, :actor)

    cond do
      valid_actor?(actor) and is_function(Keyword.get(opts, :authorize), 2) ->
        if Keyword.fetch!(opts, :authorize).(account, actor),
          do: :ok,
          else: {:error, :unauthorized}

      valid_actor?(actor) and Keyword.get(opts, :authorized?, false) == true ->
        :ok

      true ->
        {:error, :unauthorized}
    end
  end

  defp command(opts) do
    with {:ok, reason} <- bounded_text(Keyword.get(opts, :reason), @max_reason_bytes),
         {:ok, operation_id} <-
           bounded_identifier(Keyword.get(opts, :operation_id), @max_operation_id_bytes) do
      {:ok, %{actor: Keyword.fetch!(opts, :actor), reason: reason, operation_id: operation_id}}
    else
      _ -> {:error, :invalid_command}
    end
  end

  defp normalize_target(%{lineage_id: lineage_id, environment: environment}, :reconciliation)
       when environment in @environments do
    with {:ok, lineage_id} <- bounded_identifier(lineage_id, 255) do
      {:ok, %{lineage_id: lineage_id, environment: environment}}
    end
  end

  defp normalize_target(%{limit: limit}, :backlog) when is_integer(limit) and limit in 1..100,
    do: {:ok, %{limit: limit}}

  defp normalize_target(%{device_id: device_id}, :device) do
    with {:ok, device_id} <- bounded_identifier(device_id, 255),
         do: {:ok, %{device_id: device_id}}
  end

  defp normalize_target(%{key_set: key_set}, :key_set) do
    with {:ok, key_set} <- bounded_identifier(key_set, 255), do: {:ok, %{key_set: key_set}}
  end

  defp normalize_target(%{correlation: correlation}, :correlation) do
    with {:ok, correlation} <- bounded_identifier(correlation, 255),
         do: {:ok, %{correlation: correlation}}
  end

  defp normalize_target(_, _), do: {:error, :invalid_target}

  defp valid_actor?(%{type: type, id: id}) when type in [:admin, "admin"] do
    match?({:ok, _}, bounded_identifier(id, 255))
  end

  defp valid_actor?(_), do: false

  defp bounded_text(value, max_bytes) when is_binary(value) and byte_size(value) > 0 do
    if byte_size(value) <= max_bytes, do: {:ok, value}, else: {:error, :invalid_text}
  end

  defp bounded_text(_, _), do: {:error, :invalid_text}

  defp bounded_identifier(value, max_bytes) when is_binary(value) and byte_size(value) > 0 do
    if byte_size(value) <= max_bytes and Regex.match?(@opaque_id, value),
      do: {:ok, value},
      else: {:error, :invalid_identifier}
  end

  defp bounded_identifier(_, _), do: {:error, :invalid_identifier}

  defp existing_event(repo, operation_id),
    do:
      repo.one(
        from(event in Event, where: event.idempotency_key == ^operation_id, lock: "FOR UPDATE")
      )

  defp audit_attrs(action, account, target, command) do
    %{
      type: "entitlements.repair.#{action}",
      actor_type: "admin",
      actor_id: command.actor.id,
      subject_type: "EntitlementAccount",
      subject_id: account.id,
      idempotency_key: command.operation_id,
      data: %{
        "action" => Atom.to_string(action),
        "reason" => command.reason,
        "target_correlation" => correlation(target),
        "before_revision" => account.revision
      }
    }
  end

  defp correlation(target) do
    target
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
    |> binary_part(0, 16)
  end
end
