# accrue:generated
# accrue:fingerprint: f1c5a2e3d3714abc2f8d381c028e0e7525ece126aab9d8522279818029407250
defmodule Accrue.Repo.Migrations.CreateAccrueWebhookEvents do
  @moduledoc """
  Creates the `accrue_webhook_events` table for the webhook ingestion
  pipeline (D2-33). Includes:

  - UNIQUE(processor, processor_event_id) for idempotent ingestion (D2-25)
  - Partial index on failed/dead status for admin UI queries (D2-36)
  - bytea raw_body for forensic replay
  """

  use Ecto.Migration

  def change do
    create table(:accrue_webhook_events, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :processor, :string, null: false
      add :processor_event_id, :string, null: false
      add :type, :string, null: false
      add :livemode, :boolean, default: false, null: false
      add :status, :string, default: "received", null: false
      add :raw_body, :binary
      add :received_at, :utc_datetime_usec
      add :processed_at, :utc_datetime_usec
      add :data, :map, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:accrue_webhook_events, [:processor, :processor_event_id],
             name: :accrue_webhook_events_processor_event_id_index
           )

    create index(:accrue_webhook_events, [:type])
    create index(:accrue_webhook_events, [:livemode])

    create index(:accrue_webhook_events, [:status],
             where: "status IN ('failed', 'dead')",
             name: :accrue_webhook_events_failed_dead_index
           )
  end
end
