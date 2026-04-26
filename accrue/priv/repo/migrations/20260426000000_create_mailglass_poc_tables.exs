defmodule Accrue.Repo.Migrations.CreateMailglassPocTables do
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    create table(:mailglass_deliveries, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:mailable, :text, null: false)
      add(:stream, :text, null: false)
      add(:recipient, :text, null: false)
      add(:recipient_domain, :text, null: false)
      add(:provider, :text)
      add(:provider_message_id, :text)
      add(:last_event_type, :text, null: false)
      add(:last_event_at, :utc_datetime_usec, null: false)
      add(:terminal, :boolean, null: false, default: false)
      add(:dispatched_at, :utc_datetime_usec)
      add(:delivered_at, :utc_datetime_usec)
      add(:bounced_at, :utc_datetime_usec)
      add(:complained_at, :utc_datetime_usec)
      add(:suppressed_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})
      add(:lock_version, :integer, null: false, default: 1)
      add(:idempotency_key, :text)
      add(:status, :text, null: false, default: "queued")
      add(:last_error, :map)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:mailglass_deliveries, [:idempotency_key],
        where: "idempotency_key IS NOT NULL",
        name: :mailglass_deliveries_idempotency_key_unique_idx,
        prefix: prefix
      )
    )

    create(
      unique_index(:mailglass_deliveries, [:provider, :provider_message_id],
        where: "provider_message_id IS NOT NULL",
        name: :mailglass_deliveries_provider_msg_id_idx,
        prefix: prefix
      )
    )

    create table(:mailglass_events, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:delivery_id, :uuid)
      add(:type, :text, null: false)
      add(:occurred_at, :utc_datetime_usec, null: false)
      add(:idempotency_key, :text)
      add(:reject_reason, :text)
      add(:normalized_payload, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})
      add(:trace_id, :text)
      add(:needs_reconciliation, :boolean, null: false, default: false)
      add(:inserted_at, :utc_datetime_usec, null: false, default: fragment("now()"))
    end

    create(
      unique_index(:mailglass_events, [:idempotency_key],
        where: "idempotency_key IS NOT NULL",
        name: :mailglass_events_idempotency_key_idx,
        prefix: prefix
      )
    )
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    drop(table(:mailglass_events, prefix: prefix))
    drop(table(:mailglass_deliveries, prefix: prefix))
  end
end
