defmodule Accrue.Webhook.Handler do
  @moduledoc """
  Behaviour for webhook event handlers (D2-27).

  Implement `handle_event/3` and pattern-match on the event type string:

      defmodule MyApp.BillingHandler do
        use Accrue.Webhook.Handler

        def handle_event("invoice.payment_failed", event, _ctx) do
          MyApp.Slack.notify(event.object_id)
        end
      end

  ## Registration

  Register handlers in your application config:

      config :accrue, webhook_handlers: [MyApp.BillingHandler, MyApp.AnalyticsHandler]

  ## Dispatch order (D2-30)

  1. `Accrue.Webhook.DefaultHandler` runs first (non-disableable)
  2. User handlers run sequentially in config list order
  3. Each handler is rescue-wrapped -- a crash in one handler does not
     prevent others from running

  ## Fallthrough

  `use Accrue.Webhook.Handler` injects a fallthrough clause that returns
  `:ok` for unmatched event types (D2-28). Override this by defining your
  own catch-all clause.
  """

  @callback handle_event(type :: String.t(), event :: Accrue.Webhook.Event.t(), ctx :: map()) ::
              :ok | {:error, term()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Accrue.Webhook.Handler

      # D2-28: Fallthrough -- unmatched events are silently ignored
      def handle_event(_type, _event, _ctx), do: :ok
      defoverridable handle_event: 3
    end
  end
end
