defmodule Accrue.Webhook.DispatchWorker do
  @moduledoc """
  Oban worker for async webhook handler dispatch.

  Enqueued by `Accrue.Webhook.Ingest` in the same transaction as the
  webhook event row. Loads the `WebhookEvent`, projects it to
  `%Accrue.Webhook.Event{}`, and dispatches to the handler chain.

  ## Handler context (`ctx`)

  Besides `attempt`, `max_attempts`, `webhook_event_id`, and `endpoint`, the
  map includes `:meter_error_object` — the raw Stripe map at
  `row.data["data"]["object"]` when present (else `%{}`). Meter error
  handlers read this key so `handle_event/3` can extract usage identifiers
  without re-parsing the full signing payload.

  ## Dispatch order

  1. `Accrue.Webhook.DefaultHandler` runs first (non-disableable).
     Connect-scoped events route to `Accrue.Webhook.ConnectHandler`.
  2. User handlers from `Accrue.Config.webhook_handlers/0` run sequentially.
  3. Each handler is rescue-wrapped for crash isolation — a user handler
     crash is logged and emits telemetry, but does not cause a retry.

  ## Retry policy

  25 attempts with exponential backoff. On the final attempt, transitions
  the webhook event to `:dead` status and emits
  `[:accrue, :ops, :webhook_dlq, :dead_lettered]` telemetry. Dead-lettered
  events can be replayed via `Accrue.Webhooks.DLQ.requeue/1`.

  ## Status lifecycle

      :received -> :processing -> :succeeded
                                -> :failed (retryable)
                                -> :dead (final attempt)
  """

  use Oban.Worker,
    queue: :accrue_webhooks,
    max_attempts: 25

  alias Accrue.Webhook.{WebhookEvent, Event, DefaultHandler, ConnectHandler}

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"webhook_event_id" => id},
        attempt: attempt,
        max_attempts: max_attempts
      }) do
    repo = Accrue.Repo.repo()
    row = repo.get!(WebhookEvent, id)

    # Transition to :processing (capture updated row to avoid stale struct)
    row =
      row
      |> WebhookEvent.status_changeset(:processing)
      |> repo.update!()

    event = Event.from_webhook_event(row)

    meter_error_object =
      case row.data do
        %{"data" => %{"object" => %{} = obj}} -> obj
        _ -> %{}
      end

    ctx = %{
      attempt: attempt,
      max_attempts: max_attempts,
      webhook_event_id: id,
      endpoint: row.endpoint,
      meter_error_object: meter_error_object
    }

    # Push actor context so telemetry and audit events carry webhook identity.
    Accrue.Actor.put_current(%{type: :webhook, id: row.processor_event_id})

    # Default handler runs first (non-disableable), branched by endpoint.
    # Connect-scoped events route to ConnectHandler; everything else routes
    # to the platform DefaultHandler. The user-handler loop is endpoint-agnostic.
    default_handler =
      case row.endpoint do
        :connect -> ConnectHandler
        _ -> DefaultHandler
      end

    default_result = safe_handle(default_handler, event, ctx)

    _user_results =
      Accrue.Config.webhook_handlers()
      |> Enum.map(fn handler -> safe_handle(handler, event, ctx) end)

    # Only re-raise if the default handler failed.
    # User handler crashes are logged but do not cause retry.
    case default_result do
      :ok ->
        mark_succeeded(repo, row)
        :ok

      {:error, reason} ->
        mark_failed_or_dead(repo, row, attempt, max_attempts)
        {:error, reason}
    end
  end

  @doc false
  def safe_handle(handler, event, ctx) do
    handler.handle_event(event.type, event, ctx)
  rescue
    e ->
      Logger.error(
        "Webhook handler #{inspect(handler)} crashed: #{Exception.format(:error, e, __STACKTRACE__)}"
      )

      :telemetry.execute(
        [:accrue, :webhook, :handler, :exception],
        %{},
        %{module: handler, error: e}
      )

      {:error, e}
  end

  defp mark_succeeded(repo, row) do
    row
    |> WebhookEvent.status_changeset(:succeeded)
    |> repo.update!()
  end

  defp mark_failed_or_dead(repo, row, attempt, max_attempts) do
    status = if attempt >= max_attempts, do: :dead, else: :failed

    updated =
      row
      |> WebhookEvent.status_changeset(status)
      |> repo.update!()

    if status == :dead do
      :telemetry.execute(
        [:accrue, :ops, :webhook_dlq, :dead_lettered],
        %{count: 1},
        %{
          event_id: updated.id,
          processor_event_id: updated.processor_event_id,
          type: updated.type,
          attempt: attempt
        }
      )
    end

    updated
  end
end
