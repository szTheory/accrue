# accrue:generated
# accrue:fingerprint: 061b198d96ae179c0fd99db560adfc733148ac6c3b42c9af28a99fb6c704b2ff
defmodule Accrue.Repo.Migrations.CreateAccrueMeterDefinitionsAndMeteredRenewals do
  use Ecto.Migration

  def change do
    create table(:accrue_meter_definitions, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :subscription_item_id,
        references(:accrue_subscription_items, type: :binary_id, on_delete: :restrict),
        null: false
      )

      add(:processor, :string, null: false, default: "braintree")
      add(:event_name, :string, null: false)
      add(:price_id, :string, null: false)
      add(:aggregation_mode, :string, null: false, default: "sum")
      add(:active, :boolean, null: false, default: true)
      add(:billing_snapshot, :map, null: false, default: %{})
      add(:data, :map, null: false, default: %{})
      add(:lock_version, :integer, null: false, default: 1)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:accrue_meter_definitions, [:processor, :event_name]))
    create(index(:accrue_meter_definitions, [:subscription_item_id]))

    create table(:accrue_metered_renewals, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :subscription_id,
        references(:accrue_subscriptions, type: :binary_id, on_delete: :restrict), null: false)

      add(:customer_id, references(:accrue_customers, type: :binary_id, on_delete: :restrict),
        null: false
      )

      add(:processor, :string, null: false, default: "braintree")
      add(:state, :string, null: false, default: "pending")
      add(:period_start, :utc_datetime_usec, null: false)
      add(:period_end, :utc_datetime_usec, null: false)
      add(:trigger_source, :string, null: false)
      add(:snapshot, :map, null: false, default: %{})
      add(:last_processor_event_id, :string)
      add(:last_processor_event_ts, :utc_datetime_usec)
      add(:data, :map, null: false, default: %{})
      add(:lock_version, :integer, null: false, default: 1)

      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(
        :accrue_metered_renewals,
        [:subscription_id, :period_start, :period_end]
      )
    )

    create(index(:accrue_metered_renewals, [:customer_id, :state]))
  end
end
