defmodule Accrue.Repo.Migrations.CreateAccrueEntitlementPersistence do
  use Ecto.Migration

  def change do
    create Accrue.Migration.table(:accrue_entitlement_accounts, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:owner_type, :string, null: false)
      add(:owner_id, :string, null: false)
      add(:revision, :integer, null: false, default: 0)

      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(:accrue_entitlement_accounts, [:owner_type, :owner_id],
        name: :accrue_entitlement_accounts_owner_identity_index
      )
    )

    create Accrue.Migration.table(:accrue_entitlement_observations, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :account_id,
        Accrue.Migration.references(:accrue_entitlement_accounts,
          type: :binary_id,
          name: :accrue_entitlement_observations_account_id_fkey
        ),
        null: false
      )

      add(:rail, :string, null: false)
      add(:environment, :string, null: false)
      add(:provider_event_id, :string)
      add(:provider_transaction_id, :string)
      add(:kind, :string, null: false)
      add(:provider_lineage_id, :string, null: false)
      add(:provider_product_id, :string, null: false)
      add(:provider_order, :bigint, null: false, default: 0)
      add(:observed_at, :utc_datetime_usec, null: false)
      add(:state, :string, null: false, default: "received")
      add(:quarantine_reason, :string)
      add(:retry_count, :integer, null: false, default: 0)
      add(:next_retry_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})
      add(:evidence_digest, :string, null: false)
      add(:evidence_ref, :string)
      add(:evidence_expires_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_observations,
        [:rail, :environment, :provider_event_id],
        where: "provider_event_id IS NOT NULL",
        name: :accrue_entitlement_observations_provider_event_identity_index
      )
    )

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_observations,
        [:rail, :environment, :provider_transaction_id, :kind],
        where: "provider_event_id IS NULL AND provider_transaction_id IS NOT NULL",
        name: :accrue_entitlement_observations_transaction_kind_identity_index
      )
    )

    create(
      Accrue.Migration.index(:accrue_entitlement_observations, [:account_id],
        name: :accrue_entitlement_observations_account_index
      )
    )

    create(
      Accrue.Migration.index(:accrue_entitlement_observations, [:state, :next_retry_at],
        name: :accrue_entitlement_observations_retry_index
      )
    )

    table = Accrue.Migration.qualified_table(:accrue_entitlement_observations)

    execute(
      "ALTER TABLE #{table} ADD CONSTRAINT accrue_entitlement_observations_evidence_reference_pair_check CHECK ((evidence_ref IS NULL) = (evidence_expires_at IS NULL))",
      "ALTER TABLE #{table} DROP CONSTRAINT accrue_entitlement_observations_evidence_reference_pair_check"
    )
  end
end
