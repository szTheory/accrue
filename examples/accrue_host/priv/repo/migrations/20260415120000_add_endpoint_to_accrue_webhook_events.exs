# accrue:generated
# accrue:fingerprint: 6d7a4ad4893b5693d8f04f8f3d11f6de770f64b411a43986af6bbfe67cf55651
defmodule Accrue.Repo.Migrations.AddEndpointToAccrueWebhookEvents do
  @moduledoc """
  Phase 5 (05-01) — closes the webhook endpoint persistence gap
  (Critical Finding). Phase 4's WH-13 plumbed `:endpoint` into the
  plug's telemetry metadata but never persisted it on the row, so
  `Accrue.Webhook.DispatchWorker` had no way to route Connect events
  to a Connect-specific handler.

  Adds:

  - `endpoint :string NOT NULL DEFAULT 'default'` — backs a
    `field :endpoint, Ecto.Enum, values: [:default, :connect]` on the
    `Accrue.Webhook.WebhookEvent` schema. Existing Phase 1-4 rows
    inherit `:default`, preserving single-endpoint semantics.
  - Partial index on `WHERE endpoint = 'connect'` — keeps Connect-only
    admin queries fast without bloating the hot single-tenant write
    path (D5-01).
  """

  use Ecto.Migration

  def change do
    alter table(:accrue_webhook_events) do
      add :endpoint, :string, null: false, default: "default"
    end

    create index(
             :accrue_webhook_events,
             [:endpoint],
             where: "endpoint = 'connect'",
             name: :accrue_webhook_events_connect_idx
           )
  end
end
