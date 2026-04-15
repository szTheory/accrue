defmodule Accrue.Webhook.ConnectHandler do
  @moduledoc """
  Webhook handler for events arriving on the `:connect` endpoint (D5-01).

  Stripe Connect platforms receive two distinct webhook streams:

  1. **Platform events** (`/webhooks/stripe`) — account-scoped events
     targeting the platform account itself; dispatched to
     `Accrue.Webhook.DefaultHandler`.
  2. **Connect events** (`/webhooks/stripe/connect`) — events relayed by
     Stripe from a connected account (`account.updated`,
     `account.application.{authorized,deauthorized}`, `capability.updated`,
     `payout.*`, etc.); dispatched to this module.

  The `Accrue.Webhook.DispatchWorker` reads `row.endpoint` from the
  persisted `accrue_webhook_events` row and selects the handler module
  at dispatch time. The split exists so Connect-account state projection
  never races with platform-level state machines, and so Connect-only
  reducers (fully_onboarded?, charges_enabled?) see a stable input
  stream.

  ## Plan boundary

  This module lands as a minimal pass-through in Plan 05-01 to unblock
  the plumbing chain (row.endpoint → dispatch → handler module). The
  full Connect reducers (account projection, capability updates, payout
  state) land in Plan 05-06 once the `accrue_connect_accounts` schema
  (Plan 05-02) and account context functions (Plan 05-03) are in place.
  """

  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(_type, _event, _ctx), do: :ok
end
