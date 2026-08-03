defmodule Accrue.Repo.Migrations.CreateAccrueEntitlementCompatibilityEvidence do
  use Ecto.Migration

  def change do
    create Accrue.Migration.table(:accrue_entitlement_compatibility_states, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :account_id,
        Accrue.Migration.references(:accrue_entitlement_accounts,
          type: :binary_id,
          name: :accrue_entitlement_compatibility_states_account_id_fkey
        ),
        null: false
      )

      add(:authority, :string, null: false)
      add(:transition_digest, :string, null: false)
      timestamps(type: :utc_datetime_usec)
    end

    create Accrue.Migration.unique_index(:accrue_entitlement_compatibility_states, [:account_id],
             name: :accrue_entitlement_compatibility_states_account_index
           )

    create Accrue.Migration.table(:accrue_entitlement_compatibility_audits, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :account_id,
        Accrue.Migration.references(:accrue_entitlement_accounts,
          type: :binary_id,
          name: :accrue_entitlement_compatibility_audits_account_id_fkey
        )
      )

      add(:action, :string, null: false)
      add(:disposition, :string, null: false)
      add(:reason, :string, null: false)
      add(:blocker_count, :integer, null: false, default: 0)
      add(:comparison_count, :integer, null: false, default: 0)
      add(:cohort_digest, :string)
      add(:catalog_digest, :string)
      add(:config_digest, :string)
      add(:state_digest, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create Accrue.Migration.index(:accrue_entitlement_compatibility_audits, [:account_id, :action],
             name: :accrue_entitlement_compatibility_audits_account_action_index
           )
  end
end
