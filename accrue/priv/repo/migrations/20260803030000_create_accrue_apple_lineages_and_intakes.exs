defmodule Accrue.Repo.Migrations.CreateAccrueAppleLineagesAndIntakes do
  use Ecto.Migration

  def change do
    create Accrue.Migration.table(:accrue_entitlement_apple_lineages, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:environment, :string, null: false)
      add(:original_transaction_id, :string, null: false)

      add(
        :account_id,
        Accrue.Migration.references(:accrue_entitlement_accounts,
          type: :binary_id,
          name: :accrue_apple_lineages_account_id_fkey
        )
      )

      add(:binding_state, :string, null: false, default: "unbound")
      add(:verified_token_digest, :string)
      add(:provider_order_high_water, :bigint, null: false, default: 0)
      add(:last_reason, :string, null: false, default: "received")
      add(:attempts, :integer, null: false, default: 0)
      add(:next_retry_at, :utc_datetime_usec)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_apple_lineages,
        [:environment, :original_transaction_id],
        name: :accrue_apple_lineages_environment_original_transaction_index
      )
    )

    create Accrue.Migration.table(:accrue_entitlement_apple_intakes, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:environment, :string, null: false)
      add(:provider_event_id, :string, null: false)

      add(
        :lineage_id,
        Accrue.Migration.references(:accrue_entitlement_apple_lineages,
          type: :binary_id,
          name: :accrue_apple_intakes_lineage_id_fkey
        ),
        null: false
      )

      add(:evidence_digest, :string, null: false)
      add(:correlation_hash, :string)
      add(:verifier_version, :string, null: false)
      add(:config_version, :string, null: false)
      add(:disposition, :string, null: false)
      add(:reason, :string, null: false)
      add(:next_action, :string, null: false)
      add(:attempts, :integer, null: false, default: 0)
      add(:next_retry_at, :utc_datetime_usec)
      add(:evidence_ref, :string)
      add(:evidence_expires_at, :utc_datetime_usec)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_apple_intakes,
        [:environment, :provider_event_id],
        name: :accrue_apple_intakes_environment_provider_event_index
      )
    )

    create Accrue.Migration.table(:accrue_entitlement_apple_reconciliation_wakeups,
             primary_key: false
           ) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :lineage_id,
        Accrue.Migration.references(:accrue_entitlement_apple_lineages,
          type: :binary_id,
          name: :accrue_apple_reconciliation_wakeups_lineage_id_fkey
        ),
        null: false
      )

      add(:environment, :string, null: false)
      add(:reason, :string, null: false)
      add(:requested_at, :utc_datetime_usec, null: false)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_apple_reconciliation_wakeups,
        [:lineage_id, :environment],
        name: :accrue_apple_reconciliation_wakeups_lineage_environment_index
      )
    )
  end
end
