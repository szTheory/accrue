# accrue:generated
# accrue:fingerprint: 9918754e5537b3a801a5f2f7a3055820bc4cfa7cf7c302cb89b27dc7f9b2b451
defmodule Accrue.Repo.Migrations.CreateAccrueMeterEvents do
  @moduledoc """
  Phase 4 (04-01) — metered billing audit ledger / transactional outbox
  table per D4-03.

  Stores one row per `Accrue.Billing.report_usage/3` call. The row is
  inserted in the same `Repo.transact/2` as the events-ledger entry,
  committed, and only then does the sync-through call to
  `LatticeStripe.Billing.MeterEvent.create/1` fire. On Stripe success the
  row moves from `stripe_status: "pending"` to `"reported"`; on failure
  to `"failed"`. The partial index on `failed` rows gives ops a free DLQ
  view without a second table.

  Does NOT store the raw Stripe payload (threat model T-04-01-02) — only
  derived error codes in `stripe_error :map`, set by the projection code
  in plan 04-02.
  """

  use Ecto.Migration

  def change do
    create Accrue.Migration.table(:accrue_meter_events, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :customer_id,
        Accrue.Migration.references(:accrue_customers, type: :binary_id, on_delete: :nilify_all),
        null: true
      )

      add(:stripe_customer_id, :string, null: false)
      add(:event_name, :string, null: false)
      add(:value, :bigint, null: false)
      add(:identifier, :string, null: false)
      add(:occurred_at, :utc_datetime_usec, null: false)
      add(:reported_at, :utc_datetime_usec, null: true)
      add(:stripe_status, :string, null: false, default: "pending")
      add(:stripe_error, :map, null: true)
      add(:operation_id, :string, null: true)

      timestamps(type: :utc_datetime_usec)
    end

    create(Accrue.Migration.unique_index(:accrue_meter_events, [:identifier]))

    create(
      Accrue.Migration.index(
        :accrue_meter_events,
        [:customer_id, :event_name, :occurred_at],
        name: :accrue_meter_events_customer_event_occurred_idx
      )
    )

    create(
      Accrue.Migration.index(
        :accrue_meter_events,
        [:stripe_status],
        where: "stripe_status = 'failed'",
        name: :accrue_meter_events_failed_idx
      )
    )
  end
end
