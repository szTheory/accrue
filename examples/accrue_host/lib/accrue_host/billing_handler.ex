# accrue:generated
# accrue:fingerprint: dad750ca2f976e1afe99f17407c64406199f6224dfe2c432a7ed525af27d3709
defmodule AccrueHost.BillingHandler do
  @moduledoc """
  Host-owned Accrue webhook side-effect handler.
  """

  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(type, event, ctx) do
    # Add custom side effects for the events your app cares about.
    # Example:
    #
    #   if type == "invoice.payment_failed" do
    #     MyApp.BillingNotifications.deliver_payment_failed(event, ctx)
    #   end
    _ = type
    _ = event
    _ = ctx

    :ok
  end
end
