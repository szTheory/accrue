defmodule Accrue.Oban.Middleware do
  @moduledoc """
  Helper for setting `Accrue.Actor` operation_id from an Oban job (D3-63).

  Call `Accrue.Oban.Middleware.put/1` at the top of your worker's
  `perform/1` so the job's processor-side idempotency keys are
  deterministic across retry attempts:

      def perform(%Oban.Job{} = job) do
        Accrue.Oban.Middleware.put(job)
        # ... rest of perform
      end

  Format: `"oban-<job.id>-<job.attempt>"`. Keying on `attempt` (not just
  `id`) means a retry gets a fresh idempotency key — Stripe will
  re-process the call rather than return the cached result from the
  failed attempt. That is usually what you want for a retry.

  ## LiveView integration

  LiveView is a hard dependency of `accrue_admin` only, never `accrue`.
  The on_mount hook equivalent (setting operation_id from the LiveView
  socket's `session_id`) lives in `accrue_admin` — see CLAUDE.md for
  the dependency boundary rule.
  """

  @doc """
  Stamps the current process with a deterministic operation_id derived
  from the Oban job id and attempt number. Returns `:ok`.

  ## Connect account propagation (D5-01)

  If the Oban job args include a `"stripe_account"` key, the connected
  account id is restored into the process dictionary under
  `:accrue_connected_account_id` so downstream `Accrue.Processor.Stripe`
  calls pick it up via `resolve_stripe_account/1`'s precedence chain.
  This mirrors the api-version pdict pattern from D2-14 and keeps
  Connect context stable across the enqueue → perform boundary.

  The middleware only READS `stripe_account` from trusted enqueue-time
  args (never from webhook payloads); Oban stores args in jsonb which
  is trusted DB state, not external input.
  """
  @type job_like ::
          Oban.Job.t()
          | %{required(:id) => any(), required(:attempt) => integer(), optional(:args) => map()}

  @spec put(job_like()) :: :ok
  def put(%Oban.Job{id: id, attempt: attempt, args: args}) do
    Accrue.Actor.put_operation_id("oban-#{id}-#{attempt}")
    maybe_restore_stripe_account(args)
    :ok
  end

  def put(%{id: id, attempt: attempt} = job) do
    Accrue.Actor.put_operation_id("oban-#{id}-#{attempt}")
    maybe_restore_stripe_account(Map.get(job, :args))
    :ok
  end

  @spec maybe_restore_stripe_account(map() | nil) :: :ok
  defp maybe_restore_stripe_account(%{"stripe_account" => acct})
       when is_binary(acct) and acct != "" do
    Process.put(:accrue_connected_account_id, acct)
    :ok
  end

  defp maybe_restore_stripe_account(_args), do: :ok
end
