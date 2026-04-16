# accrue:generated
# accrue:fingerprint: dad750ca2f976e1afe99f17407c64406199f6224dfe2c432a7ed525af27d3709
defmodule AccrueHost.BillingHandler do
  @moduledoc """
  Host-owned Accrue webhook side-effect handler.
  """

  alias Accrue.Events

  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(type, event, ctx) do
    attrs = %{
      type: "host.webhook.handled",
      subject_type: "WebhookEvent",
      subject_id: to_string(Map.get(ctx, :webhook_event_id, event.processor_event_id)),
      caused_by_webhook_event_id: Map.get(ctx, :webhook_event_id),
      idempotency_key: "host-handler:#{event.processor_event_id}",
      data: %{
        handler: inspect(__MODULE__),
        event_type: type,
        object_id: event.object_id,
        processor: event.processor
      }
    }

    case Events.record(attrs) do
      {:ok, _event} -> :ok
      {:error, _reason} = error -> error
    end
  end
end
