defmodule Accrue.Entitlements.Offline.Reconnect do
  @moduledoc false
  import Ecto.Query
  alias Accrue.Entitlements.{Account, Device}

  alias Accrue.Entitlements.Offline.{
    Challenge,
    Issuer,
    ReconnectAttempt,
    ReconnectWakeup,
    SourceCoordinator
  }

  defmodule Request do
    @enforce_keys [:installation_id, :challenge_id, :nonce, :nonce_signature, :idempotency_key]
    defstruct [
      :installation_id,
      :challenge_id,
      :nonce,
      :nonce_signature,
      :idempotency_key,
      :client_revision,
      :client_disposition,
      :client_issued_at
    ]
  end

  defmodule Outcome do
    @enforce_keys [:disposition, :reason, :next_action, :due_source_count]
    defstruct [
      :disposition,
      :reason,
      :next_action,
      :retry_after,
      :proof,
      :revision,
      :due_source_count
    ]
  end

  @spec reconnect(Account.t(), Request.t(), keyword()) :: {:ok, Outcome.t()} | {:error, atom()}
  def reconnect(%Account{} = account, %Request{} = request, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    started_at = System.monotonic_time(:millisecond)

    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :reconnect],
      %{
        action: :reconnect,
        protocol_version: "v1.59",
        correlation_hash: correlation_hash(request)
      },
      fn ->
        result = do_reconnect(account, request, now, opts)
        emit_telemetry(result, request, now, started_at, opts)
        result
      end
    )
  end

  def reconnect(_, _, _), do: {:error, :invalid_request}

  defp do_reconnect(account, request, now, opts) do
    with :ok <- validate_request(request),
         true <- authorized?(opts, account),
         {:ok, admission} <- consume_pop(account, request, now, opts) do
      case admission do
        {:replay, outcome} ->
          {:ok, outcome}

        {kind, _device, _challenge, attempt_id} when kind in [:new, :resume] ->
          # This hook is deliberately after the admission transaction. It gives
          # hosts a deterministic fault-injection seam and proves that a restart
          # leaves a durable attempt which an exact replay can resume.
          repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

          with :ok <- after_admission(opts),
               {:ok, {claimed_account, claimed_device, claimed_challenge, token}} <-
                 claim_attempt(repo, attempt_id, now),
               {:ok, outcome} <-
                 run_attempt(
                   claimed_account,
                   claimed_device,
                   claimed_challenge,
                   request,
                   now,
                   opts,
                   attempt_id,
                   token
                 ) do
            {:ok, outcome}
          end
      end
    else
      false -> {:error, :unauthorized}
      {:error, reason} -> {:error, reason}
    end
  end

  defp run_attempt(account, device, challenge, request, now, opts, attempt_id, token) do
    result =
      with {:ok, statuses} <- due_statuses(account, now, opts),
           {:ok, refreshed} <- refresh_due(account, statuses, now, opts),
           {:ok, outcome} <-
             settle(account, device, challenge, request, refreshed, now, opts, attempt_id, token) do
        {:ok, outcome}
      end

    # The admission row is a durable outbox: it exists before any provider call
    # or host enqueue, and an exact replay re-enters this path until it reaches a
    # terminal outcome. A failed enqueue is explicitly escalated, never hidden as
    # a replayable pending response.
    outcome = outcome_for_result(result)

    case outcome.disposition do
      :issued ->
        case after_issuance_commit(opts) do
          :ok -> {:ok, outcome}
          _ -> {:error, :issuance_interrupted}
        end

      _ ->
        case persist_outcome(challenge, attempt_id, token, outcome, opts) do
          :ok -> {:ok, outcome}
          {:error, _} -> {:error, :persistence_failed}
        end
    end
  end

  defp due_statuses(account, now, opts) do
    coordinator = Keyword.get(opts, :source_coordinator)

    with true <- is_atom(coordinator) and function_exported?(coordinator, :due_sources, 3),
         {:ok, statuses} <- coordinator.due_sources(account, now, opts),
         :ok <- SourceCoordinator.validate(statuses),
         do: {:ok, statuses},
         else: (_ -> {:error, :source_unavailable})
  end

  defp refresh_due(account, statuses, now, opts) do
    coordinator = Keyword.fetch!(opts, :source_coordinator)

    statuses
    |> Enum.reduce_while({:ok, []}, fn status, {:ok, accepted} ->
      result =
        if status.due, do: coordinator.refresh(account, status, now, opts), else: {:ok, status}

      case result do
        {:ok, %SourceCoordinator.SourceStatus{} = refreshed}
        when refreshed.source == status.source and refreshed.environment == status.environment ->
          # Due membership belongs to this reconnect attempt, not to a provider response.
          # A refresh may advance state/retry metadata but cannot make required work disappear.
          {:cont, {:ok, [%{refreshed | due: status.due} | accepted]}}

        _ ->
          {:halt, {:error, :source_unavailable}}
      end
    end)
    |> case do
      {:ok, refreshed} ->
        refreshed = Enum.reverse(refreshed)

        if SourceCoordinator.validate(refreshed) == :ok,
          do: {:ok, refreshed},
          else: {:error, :source_unavailable}

      error ->
        error
    end
  end

  defp settle(account, device, challenge, request, statuses, now, opts, attempt_id, token) do
    due = Enum.filter(statuses, & &1.due)
    unresolved = Enum.reject(due, &(&1.state == :resolved))

    if unresolved == [] do
      issuer = %Issuer.Request{
        account_id: account.id,
        device_id: device.id,
        now: now,
        client_revision: request.client_revision
      }

      admission = Issuer.Admission.from_reconnect_challenge(challenge, device)

      issuer_opts =
        Keyword.put(opts, :persist_issued_outcome, fn repo, minting_challenge, result ->
          complete_issued_in_transaction(
            repo,
            minting_challenge,
            attempt_id,
            token,
            result,
            length(due)
          )
        end)

      case Issuer.issue_after_admission(account, issuer, admission, issuer_opts) do
        {:ok, result} ->
          {:ok,
           %Outcome{
             disposition: :issued,
             reason: :ok,
             next_action: :none,
             proof: result.compact,
             revision: result.revision,
             due_source_count: length(due)
           }}

        {:error, reason} ->
          {:error, reason}
      end
    else
      case enqueue_repairs(account, unresolved, now, opts) do
        :ok ->
          state =
            if Enum.any?(unresolved, &(&1.state == :needs_repair)),
              do: :needs_repair,
              else: :pending

          retry =
            unresolved
            |> Enum.map(& &1.retry_after)
            |> Enum.filter(&is_integer/1)
            |> Enum.min(fn -> nil end)

          {:ok,
           %Outcome{
             disposition: state,
             reason: state,
             next_action: :reconnect_required,
             retry_after: retry,
             due_source_count: length(due)
           }}

        {:error, :repair_enqueue_failed} ->
          {:error, :repair_enqueue_failed}
      end
    end
  end

  defp enqueue_repairs(account, unresolved, now, opts) do
    coordinator = Keyword.fetch!(opts, :source_coordinator)

    Enum.reduce_while(unresolved, :ok, fn status, :ok ->
      case coordinator.enqueue_repair(account, status, now, opts) do
        :ok -> {:cont, :ok}
        _ -> {:halt, {:error, :repair_enqueue_failed}}
      end
    end)
  end

  defp consume_pop(account, request, now, opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    result =
      repo.transaction(fn ->
        device =
          repo.one(
            from(d in Device,
              where:
                d.account_id == ^account.id and d.installation_id == ^request.installation_id,
              lock: "FOR UPDATE"
            )
          )

        challenge =
          repo.one(
            from(c in Challenge,
              where: c.id == ^request.challenge_id and c.account_id == ^account.id,
              lock: "FOR UPDATE"
            )
          )

        with %Device{state: :active} = device <- device,
             %Challenge{purpose: :reconnect, consumed_at: nil} = challenge <- challenge,
             true <-
               challenge.installation_id == request.installation_id and
                 challenge.nonce_digest == digest(request.nonce) and
                 DateTime.compare(challenge.expires_at, now) == :gt,
             true <- valid_signature?(account, device, challenge, request),
             {:ok, persisted_challenge} <-
               repo.update(
                 Challenge.changeset(challenge, %{
                   consumed_at: now,
                   idempotency_digest: digest(request.idempotency_key),
                   reconnect_outcome: admission_map(request, now)
                 })
               ),
             {:ok, attempt} <-
               schedule_attempt(repo, account, device, persisted_challenge, now, opts) do
          {:ok, {:new, device, persisted_challenge, attempt.id}}
        else
          {:error, reason} ->
            repo.rollback(reason)

          %Challenge{
            purpose: :reconnect,
            consumed_at: consumed_at,
            idempotency_digest: stored_digest,
            reconnect_outcome: outcome
          } = challenge
          when not is_nil(consumed_at) and is_map(outcome) ->
            if replay_binding?(account, device, challenge, request, stored_digest),
              do: replay_admission(repo, device, challenge, outcome),
              else: repo.rollback(:challenge_invalid)

          _ ->
            repo.rollback(:challenge_invalid)
        end
      end)

    case result do
      {:ok, {:ok, admission}} -> {:ok, admission}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :challenge_invalid}
    end
  end

  defp schedule_attempt(repo, account, device, challenge, now, opts) do
    insert_job = Keyword.get(opts, :insert_wakeup_job, &repo.insert/1)

    with {:ok, attempt} <-
           repo.insert(
             ReconnectAttempt.changeset(%ReconnectAttempt{}, %{
               challenge_id: challenge.id,
               account_id: account.id,
               device_id: device.id,
               state: :admitted,
               scheduled_at: now,
               attempt_count: 0,
               due_source_count: 0
             })
           ),
         {:ok, _} <- ReconnectWakeup.enqueue_in_transaction(repo, attempt.id, now),
         {:ok, _} <- insert_job.(Accrue.Entitlements.Offline.ReconnectWakeupWorker.new(%{})) do
      {:ok, attempt}
    end
  end

  defp persist_outcome(challenge, attempt_id, token, outcome, opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    case repo.transact(fn ->
           with %ReconnectAttempt{state: :running, execution_token: ^token} = attempt <-
                  repo.one(
                    from(a in ReconnectAttempt, where: a.id == ^attempt_id, lock: "FOR UPDATE")
                  ),
                %Challenge{} = locked_challenge <-
                  repo.one(from(c in Challenge, where: c.id == ^challenge.id, lock: "FOR UPDATE")),
                true <-
                  get_in(locked_challenge.reconnect_outcome, ["state"]) in ["admitted", "minting"],
                {:ok, _} <-
                  repo.update(
                    Challenge.changeset(locked_challenge, %{
                      reconnect_outcome: outcome_map(outcome)
                    })
                  ),
                {:ok, _} <- complete_attempt(repo, attempt, outcome) do
             {:ok, :ok}
           else
             _ -> repo.rollback(:attempt_unavailable)
           end
         end) do
      {:ok, :ok} -> :ok
      _ -> {:error, :persistence_failed}
    end
  end

  defp complete_attempt(repo, attempt, outcome) do
    repo.update(
      ReconnectAttempt.changeset(attempt, %{
        state: if(outcome.disposition == :needs_repair, do: :needs_repair, else: :completed),
        completed_at: DateTime.utc_now(),
        due_source_count: outcome.due_source_count,
        revision: outcome.revision,
        failure_reason: if(outcome.reason == :ok, do: nil, else: Atom.to_string(outcome.reason)),
        execution_token: nil
      })
    )
  end

  @doc false
  def complete_issued_in_transaction(repo, challenge, attempt_id, token, result, due_source_count) do
    outcome = %Outcome{
      disposition: :issued,
      reason: :ok,
      next_action: :none,
      proof: result.compact,
      revision: result.revision,
      due_source_count: due_source_count
    }

    with %ReconnectAttempt{state: :running, execution_token: ^token} = attempt <-
           repo.one(from(a in ReconnectAttempt, where: a.id == ^attempt_id, lock: "FOR UPDATE")),
         true <- get_in(challenge.reconnect_outcome, ["state"]) == "minting",
         {:ok, _} <-
           repo.update(Challenge.changeset(challenge, %{reconnect_outcome: outcome_map(outcome)})),
         {:ok, _} <- complete_attempt(repo, attempt, outcome) do
      :ok
    else
      _ -> {:error, :attempt_unavailable}
    end
  end

  @doc false
  def drain_wakeups(repo, opts \\ []) do
    insert_job = Keyword.get(opts, :insert_job, &repo.insert/1)

    repo.transact(fn ->
      repo.all(
        from(w in ReconnectWakeup,
          order_by: [asc: w.requested_at],
          lock: "FOR UPDATE SKIP LOCKED"
        )
      )
      |> Enum.reduce_while({:ok, 0}, fn wakeup, {:ok, count} ->
        case insert_job.(
               Accrue.Entitlements.Offline.ReconnectWorker.new(%{
                 "attempt_id" => wakeup.attempt_id
               })
             ) do
          {:ok, _} ->
            {:ok, _} = repo.delete(wakeup)
            {:cont, {:ok, count + 1}}

          {:error, reason} ->
            repo.rollback({:job_insert_failed, reason})
        end
      end)
    end)
  end

  @doc false
  def enqueue_due(repo, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    insert_job = Keyword.get(opts, :insert_job, &repo.insert/1)
    lease_cutoff = DateTime.add(now, -Keyword.get(opts, :lease_seconds, 300), :second)

    repo.transact(fn ->
      repo.all(
        from(a in ReconnectAttempt,
          where:
            (a.state in [:admitted, :retrying] and
               (is_nil(a.next_attempt_at) or a.next_attempt_at <= ^now)) or
              (a.state == :running and not is_nil(a.started_at) and a.started_at <= ^lease_cutoff),
          limit: 100,
          lock: "FOR UPDATE SKIP LOCKED"
        )
      )
      |> Enum.reduce_while({:ok, 0}, fn attempt, {:ok, count} ->
        with {:ok, _} <-
               repo.update(
                 ReconnectAttempt.changeset(attempt, %{
                   state: :retrying,
                   next_attempt_at: now,
                   execution_token: nil
                 })
               ),
             {:ok, _} <-
               insert_job.(
                 Accrue.Entitlements.Offline.ReconnectWorker.new(%{"attempt_id" => attempt.id})
               ) do
          {:cont, {:ok, count + 1}}
        else
          {:error, reason} -> repo.rollback({:sweep_insert_failed, reason})
        end
      end)
    end)
  end

  @doc false
  def execute_attempt(attempt_id, opts \\ []) when is_binary(attempt_id) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())
    now = Keyword.get(opts, :now, DateTime.utc_now())

    config =
      Keyword.get(opts, :offline_reconnect, Application.get_env(:accrue, :offline_reconnect))

    with true <- is_list(config),
         coordinator when is_atom(coordinator) <- Keyword.get(config, :source_coordinator),
         provider when is_atom(provider) <- Keyword.get(config, :key_provider),
         {:ok, {account, device, challenge, token}} <- claim_attempt(repo, attempt_id, now),
         {:ok, _} <-
           run_attempt(
             account,
             device,
             challenge,
             %Request{
               installation_id: device.installation_id,
               challenge_id: challenge.id,
               nonce: "worker",
               nonce_signature: "worker",
               idempotency_key: "worker"
             },
             now,
             Keyword.merge(config, repo: repo),
             attempt_id,
             token
           ) do
      :ok
    else
      false -> mark_configuration_failure(repo, attempt_id, now)
      _ -> {:error, :attempt_unavailable}
    end
  end

  defp mark_configuration_failure(repo, attempt_id, now) do
    result =
      repo.transaction(fn ->
        case repo.one(from(a in ReconnectAttempt, where: a.id == ^attempt_id, lock: "FOR UPDATE")) do
          nil ->
            :attempt_unavailable

          %ReconnectAttempt{state: state} when state in [:completed, :needs_repair] ->
            :already_terminal

          %ReconnectAttempt{state: state} = attempt when state in [:admitted, :retrying] ->
            case repo.update(
                   ReconnectAttempt.changeset(attempt, %{
                     state: :needs_repair,
                     failure_reason: "config_invalid",
                     completed_at: now,
                     next_attempt_at: nil,
                     execution_token: nil
                   })
                 ) do
              {:ok, _} -> :config_invalid
              _ -> repo.rollback(:persistence_failed)
            end

          %ReconnectAttempt{} ->
            :attempt_unavailable
        end
      end)

    case result do
      {:ok, :already_terminal} -> :ok
      {:ok, :config_invalid} -> {:error, :config_invalid}
      {:ok, :attempt_unavailable} -> {:error, :attempt_unavailable}
      _ -> {:error, :persistence_failed}
    end
  end

  defp claim_attempt(repo, attempt_id, now) do
    repo.transact(fn ->
      with %ReconnectAttempt{} = attempt <-
             repo.one(
               from(a in ReconnectAttempt,
                 where: a.id == ^attempt_id and a.state in [:admitted, :retrying],
                 lock: "FOR UPDATE"
               )
             ),
           %Account{} = account <- repo.get(Account, attempt.account_id),
           %Device{} = device <- repo.get(Device, attempt.device_id),
           %Challenge{} = challenge <- repo.get(Challenge, attempt.challenge_id),
           token = Ecto.UUID.generate(),
           {:ok, _} <-
             repo.update(
               ReconnectAttempt.changeset(attempt, %{
                 state: :running,
                 started_at: now,
                 attempt_count: attempt.attempt_count + 1,
                 execution_token: token
               })
             ) do
        {:ok, {account, device, challenge, token}}
      else
        _ -> repo.rollback(:attempt_unavailable)
      end
    end)
    |> case do
      {:ok, value} -> {:ok, value}
      _ -> {:error, :attempt_unavailable}
    end
  end

  defp outcome_map(%Outcome{} = outcome) do
    %{
      "state" => "final",
      "disposition" => Atom.to_string(outcome.disposition),
      "reason" => Atom.to_string(outcome.reason),
      "next_action" => Atom.to_string(outcome.next_action),
      "retry_after" => outcome.retry_after,
      "proof" => outcome.proof,
      "revision" => outcome.revision,
      "due_source_count" => outcome.due_source_count,
      "repair_outbox" => repair_outbox_state(outcome)
    }
  end

  defp outcome_from_map(
         %{
           "state" => "final",
           "disposition" => disposition,
           "reason" => reason,
           "next_action" => next_action,
           "due_source_count" => due_source_count
         } = map
       )
       when disposition in ["issued", "pending", "needs_repair"] and
              reason in [
                "ok",
                "pending",
                "needs_repair",
                "repair_enqueue_failed",
                "source_unavailable",
                "config_invalid",
                "admission_invalid"
              ] and
              next_action in ["none", "reconnect_required"] and is_integer(due_source_count) do
    %Outcome{
      disposition: String.to_existing_atom(disposition),
      reason: String.to_existing_atom(reason),
      next_action: String.to_existing_atom(next_action),
      retry_after: map["retry_after"],
      proof: map["proof"],
      revision: map["revision"],
      due_source_count: due_source_count
    }
  end

  defp outcome_from_map(_), do: :resume

  defp bounded_outcome_reason(reason)
       when reason in [:source_unavailable, :config_invalid, :admission_invalid],
       do: reason

  defp bounded_outcome_reason(_), do: :needs_repair

  defp replay_admission(repo, device, challenge, outcome) do
    case outcome_from_map(outcome) do
      %Outcome{} = terminal ->
        {:ok, {:replay, terminal}}

      :resume ->
        case repo.one(
               from(a in ReconnectAttempt, where: a.challenge_id == ^challenge.id, select: a.id)
             ) do
          attempt_id when is_binary(attempt_id) -> {:ok, {:resume, device, challenge, attempt_id}}
          _ -> {:error, :attempt_unavailable}
        end
    end
  end

  defp admission_map(request, now) do
    %{
      "state" => "admitted",
      "attempt_version" => 1,
      "started_at" => DateTime.to_iso8601(now),
      # The request binding itself remains in dedicated challenge columns. This
      # outbox stores only bounded, one-way diagnostic values.
      "request" => %{
        "idempotency_digest" => digest(request.idempotency_key),
        "client_revision" => bounded_revision(request.client_revision)
      },
      "repair_outbox" => %{"state" => "scheduled", "scheduled_at" => DateTime.to_iso8601(now)}
    }
  end

  defp repair_outbox_state(%Outcome{reason: :repair_enqueue_failed}),
    do: %{"state" => "repair_escalated", "reason" => "repair_enqueue_failed"}

  defp repair_outbox_state(%Outcome{disposition: disposition})
       when disposition in [:pending, :needs_repair],
       do: %{"state" => "enqueued"}

  defp repair_outbox_state(_), do: %{"state" => "not_required"}

  defp outcome_for_result({:ok, outcome}), do: outcome

  defp outcome_for_result({:error, :repair_enqueue_failed}),
    do: %Outcome{
      disposition: :needs_repair,
      reason: :repair_enqueue_failed,
      next_action: :reconnect_required,
      due_source_count: 0
    }

  defp outcome_for_result({:error, reason}),
    do: %Outcome{
      disposition: :needs_repair,
      reason: bounded_outcome_reason(reason),
      next_action: :reconnect_required,
      due_source_count: 0
    }

  defp replay_binding?(account, device, challenge, request, stored_digest),
    do:
      stored_digest == digest(request.idempotency_key) and
        challenge.installation_id == request.installation_id and
        challenge.nonce_digest == digest(request.nonce) and
        valid_signature?(account, device, challenge, request)

  defp validate_request(%Request{} = request) do
    if Enum.all?(
         [
           request.installation_id,
           request.challenge_id,
           request.nonce,
           request.nonce_signature,
           request.idempotency_key
         ],
         &bounded_binary?/1
       ) and byte_size(request.nonce_signature) <= 256 do
      :ok
    else
      {:error, :invalid_request}
    end
  end

  defp bounded_binary?(value), do: is_binary(value) and byte_size(value) in 1..512

  defp valid_signature?(account, device, challenge, request) do
    {_, key} = JOSE.JWK.from(device.public_jwk) |> JOSE.JWK.to_public_key()

    :public_key.verify(
      signing_input(
        account.id,
        request.installation_id,
        challenge.id,
        request.nonce,
        request.idempotency_key
      ),
      :sha256,
      request.nonce_signature,
      key
    )
  rescue
    _ -> false
  end

  defp authorized?(opts, account) do
    case Keyword.get(opts, :authorize) do
      callback when is_function(callback, 2) -> callback.(account, :offline_reconnect) == true
      _ -> false
    end
  end

  defp after_admission(opts) do
    case Keyword.get(opts, :after_admission) do
      callback when is_function(callback, 0) ->
        case callback.() do
          :ok -> :ok
          _ -> {:error, :admission_interrupted}
        end

      _ ->
        :ok
    end
  end

  # This seam represents a process loss after the atomic issuance/final-outcome
  # commit and before response delivery. Replays must return that final result.
  defp after_issuance_commit(opts) do
    case Keyword.get(opts, :after_issuance_commit) do
      callback when is_function(callback, 0) -> callback.()
      _ -> :ok
    end
  end

  defp emit_telemetry(result, request, now, started_at, opts) do
    outcome =
      case result do
        {:ok, %Outcome{} = value} -> value
        _ -> nil
      end

    queue_age_ms = queue_age_ms(request.challenge_id, now, opts)

    :telemetry.execute(
      [:accrue, :entitlements, :offline, :reconnect],
      %{count: 1, latency_ms: elapsed_ms(started_at), queue_age_ms: queue_age_ms},
      %{
        action: :reconnect,
        disposition: if(outcome, do: outcome.disposition, else: :rejected),
        reason: if(outcome, do: outcome.reason, else: result_reason(result)),
        proof_state: if(outcome && is_binary(outcome.proof), do: :issued, else: :none),
        revision_delta: revision_delta(request, outcome),
        due_source_count: if(outcome, do: outcome.due_source_count, else: 0),
        retry_after: if(outcome, do: outcome.retry_after, else: nil),
        protocol_version: "v1.59",
        correlation_hash: correlation_hash(request)
      }
    )
  end

  defp elapsed_ms(started_at),
    do: (System.monotonic_time(:millisecond) - started_at) |> max(0) |> min(86_400_000)

  defp queue_age_ms(challenge_id, now, opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    case repo.one(
           from(a in ReconnectAttempt,
             where: a.challenge_id == ^challenge_id,
             select: a.scheduled_at
           )
         ) do
      %DateTime{} = scheduled ->
        DateTime.diff(now, scheduled, :millisecond) |> max(0) |> min(86_400_000)

      _ ->
        0
    end
  rescue
    _ -> 0
  end

  defp correlation_hash(%Request{idempotency_key: key}) when is_binary(key), do: digest(key)
  defp correlation_hash(_), do: nil
  defp bounded_revision(value) when is_integer(value) and value >= 0, do: value
  defp bounded_revision(_), do: nil

  defp revision_delta(%Request{client_revision: client}, %Outcome{revision: revision})
       when is_integer(client) and is_integer(revision),
       do: (revision - client) |> max(-1_000_000) |> min(1_000_000)

  defp revision_delta(_, _), do: nil

  defp result_reason({:error, reason})
       when reason in [
              :unauthorized,
              :invalid_request,
              :challenge_invalid,
              :admission_interrupted,
              :persistence_failed
            ],
       do: reason

  defp result_reason(_), do: :rejected

  defp signing_input(account, installation, challenge, nonce, key),
    do:
      ["v1.59", "reconnect", account, installation, challenge, nonce, digest(key)]
      |> Enum.map_join(fn v -> <<byte_size(v)::unsigned-big-integer-size(32), v::binary>> end)

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)
end
