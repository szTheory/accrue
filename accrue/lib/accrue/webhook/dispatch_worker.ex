defmodule Accrue.Webhook.DispatchWorker do
  @moduledoc """
  Oban worker for async webhook handler dispatch (D2-27).

  Enqueued by `Accrue.Webhook.Ingest` in the same transaction as the
  webhook event row. Loads the `WebhookEvent`, projects it to
  `%Accrue.Webhook.Event{}`, and dispatches to the handler chain.

  ## Retry policy

  25 attempts with exponential backoff (WH-05). On final attempt,
  transitions the webhook event to `:dead` status (D2-35).
  """

  use Oban.Worker,
    queue: :accrue_webhooks,
    max_attempts: 25

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"webhook_event_id" => _id}}) do
    # Full implementation in Task 2
    :ok
  end
end
