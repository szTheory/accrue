# accrue:generated
# accrue:fingerprint: 4d26052524487cb5c43084d4458d3ff03fb81ae74980fdff5fbeebd09aa18531
defmodule Accrue.Repo.Migrations.CreateAccrueSubscriptionSchedules do
  @moduledoc """
  Phase 4 (04-01) — thin projection table for Stripe Subscription
  Schedules (BILL-16).

  Pure Stripe passthrough stored as `data` jsonb + typed columns only
  for the fields `accrue_admin` Phase 7 LiveView filters/sorts on:
  `status`, `current_phase_index`, `phases_count`, `next_phase_at`,
  plus lifecycle timestamps (`released_at`, `canceled_at`). Full Stripe
  mirror is NOT a goal — per BILL-16 Claude's Discretion, child-phase
  rows are deferred to v1.x.

  Uses `processor_id` naming (not `stripe_id`) to match the Phase 3
  D3-15 convention for multi-processor-ready projection tables.

  `subscription_id` is nullable: a schedule can exist before its
  subscription is created (Stripe's `start_date: future` flow).
  """

  use Ecto.Migration

  def change do
    create table(:accrue_subscription_schedules, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :processor, :string, null: false, default: "stripe"
      add :processor_id, :string, null: false

      add :customer_id,
          references(:accrue_customers, type: :binary_id, on_delete: :nilify_all),
          null: true

      add :subscription_id,
          references(:accrue_subscriptions, type: :binary_id, on_delete: :nilify_all),
          null: true

      add :status, :string, null: false
      add :current_phase_index, :integer, null: true
      add :phases_count, :integer, null: true
      add :next_phase_at, :utc_datetime_usec, null: true
      add :released_at, :utc_datetime_usec, null: true
      add :canceled_at, :utc_datetime_usec, null: true
      add :data, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}
      add :lock_version, :integer, null: false, default: 1
      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:accrue_subscription_schedules, [:processor_id])
    create index(:accrue_subscription_schedules, [:customer_id])
    create index(:accrue_subscription_schedules, [:subscription_id])
  end
end
