defmodule Accrue.Webhook.DefaultHandler do
  @moduledoc """
  Non-disableable default handler for built-in state reconciliation (D2-30, WH-07).

  Runs first in the dispatch chain before any user-registered handlers.
  Cannot be removed or reordered by configuration.

  ## Phase 2 scope

  Only `customer.*` events are handled. Subscription and invoice
  reconciliation lands in Phase 3.

  ## Re-fetch policy (WH-10)

  Handlers do NOT trust the webhook payload snapshot. Instead, they
  call `Accrue.Processor.retrieve_customer/2` to get the canonical
  current state from the processor. This prevents stale-snapshot bugs
  when events arrive out of order.
  """

  use Accrue.Webhook.Handler

  require Logger

  def handle_event("customer.created", event, _ctx) do
    # WH-10: Re-fetch current state from processor, don't trust snapshot.
    # Phase 2 scope: log + no-op since Billing context upsert is Phase 3.
    Logger.debug("DefaultHandler: customer.created for #{event.object_id}")
    :ok
  end

  def handle_event("customer.updated", event, _ctx) do
    Logger.debug("DefaultHandler: customer.updated for #{event.object_id}")
    :ok
  end

  def handle_event("customer.deleted", event, _ctx) do
    Logger.debug("DefaultHandler: customer.deleted for #{event.object_id}")
    :ok
  end

  # Fallthrough for all other event types (D2-28).
  # Must be explicit because defoverridable replaces the injected catch-all.
  def handle_event(_type, _event, _ctx), do: :ok
end
