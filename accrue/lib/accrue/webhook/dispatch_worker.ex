defmodule Accrue.Webhook.DispatchWorker do
  @moduledoc """
  Oban worker for async webhook handler dispatch (D2-27).

  Enqueued by `Accrue.Webhook.Ingest` in the same transaction as the
  webhook event row. Loads the `WebhookEvent`, projects it to
  `%Accrue.Webhook.Event{}`, and dispatches to the handler chain.

  ## Dispatch order (D2-30)

  1. `Accrue.Webhook.DefaultHandler` runs first (non-disableable)
  2. User handlers from `Accrue.Config.webhook_handlers/0` run sequentially
  3. Each handler is rescue-wrapped for crash isolation

  ## Retry policy

  25 attempts with exponential backoff (WH-05). On final attempt,
  transitions the webhook event to `:dead` status (D2-35).

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

    ctx = %{
      attempt: attempt,
      max_attempts: max_attempts,
      webhook_event_id: id,
      endpoint: row.endpoint
    }

    # Push actor context (D2-12)
    Accrue.Actor.put_current(%{type: :webhook, id: row.processor_event_id})

    # D2-30 + D5-01: Default handler first (non-disableable), branched by
    # `row.endpoint`. Connect-scoped events route to `ConnectHandler`;
    # everything else routes to the platform `DefaultHandler`. The
    # user-handler loop below is endpoint-agnostic.
    default_handler =
      case row.endpoint do
        :connect -> ConnectHandler
        _ -> DefaultHandler
      end

    default_result = safe_handle(default_handler, event, ctx)

    _user_results =
      Accrue.Config.webhook_handlers()
      |> Enum.map(fn handler -> safe_handle(handler, event, ctx) end)

    # Only re-raise if default handler failed (D2-30).
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
