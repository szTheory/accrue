defmodule Accrue.Repo.Migrations.CreateAccrueOfflineReconnectAttempts do
  use Ecto.Migration

  def change do
    create Accrue.Migration.table(:accrue_entitlement_offline_reconnect_attempts,
             primary_key: false
           ) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :challenge_id,
        Accrue.Migration.references(:accrue_entitlement_offline_challenges,
          type: :binary_id,
          on_delete: :delete_all
        ),
        null: false
      )

      add(
        :account_id,
        Accrue.Migration.references(:accrue_entitlement_accounts,
          type: :binary_id,
          on_delete: :delete_all
        ),
        null: false
      )

      add(
        :device_id,
        Accrue.Migration.references(:accrue_entitlement_devices,
          type: :binary_id,
          on_delete: :restrict
        ),
        null: false
      )

      add(:state, :string, null: false)
      add(:scheduled_at, :utc_datetime_usec, null: false)
      add(:started_at, :utc_datetime_usec)
      add(:completed_at, :utc_datetime_usec)
      add(:next_attempt_at, :utc_datetime_usec)
      add(:attempt_count, :integer, null: false, default: 0)
      add(:failure_reason, :string)
      add(:due_source_count, :integer, null: false, default: 0)
      add(:revision, :bigint)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_offline_reconnect_attempts,
        [:challenge_id],
        name: :accrue_offline_reconnect_attempt_challenge_index
      )
    )

    create(
      Accrue.Migration.index(:accrue_entitlement_offline_reconnect_attempts, [
        :state,
        :next_attempt_at
      ])
    )

    create Accrue.Migration.table(:accrue_entitlement_offline_reconnect_wakeups,
             primary_key: false
           ) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :attempt_id,
        Accrue.Migration.references(:accrue_entitlement_offline_reconnect_attempts,
          type: :binary_id,
          on_delete: :delete_all
        ),
        null: false
      )

      add(:requested_at, :utc_datetime_usec, null: false)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(:accrue_entitlement_offline_reconnect_wakeups, [:attempt_id])
    )
  end
end
