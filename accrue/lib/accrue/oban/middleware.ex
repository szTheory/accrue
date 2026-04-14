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
  """
  @spec put(%{id: any(), attempt: integer()}) :: :ok
  def put(%{id: id, attempt: attempt}) do
    Accrue.Actor.put_operation_id("oban-#{id}-#{attempt}")
    :ok
  end
end
