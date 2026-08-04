defmodule Accrue.Repo.Migrations.CreateAccrueAppleReconciliationCheckpoints do
  use Ecto.Migration

  def change do
    create Accrue.Migration.table(:accrue_entitlement_apple_reconciliation_checkpoints,
             primary_key: false
           ) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))
      add(
        :lineage_id,
        Accrue.Migration.references(:accrue_entitlement_apple_lineages,
          type: :binary_id,
          name: :accrue_apple_reconciliation_checkpoints_lineage_id_fkey,
          on_delete: :delete_all
        ),
        null: false
      )
      add(:environment, :string, null: false)
      add(:query_fingerprint, :string)
      add(:pending_revision, :string)
      add(:completed_revision, :string)
      add(:run_state, :string, null: false, default: "idle")
      add(:page_count, :integer, null: false, default: 0)
      add(:page_budget, :integer, null: false, default: 25)
      add(:attempts, :integer, null: false, default: 0)
      add(:last_success_at, :utc_datetime_usec)
      add(:next_due_at, :utc_datetime_usec)
      add(:retry_after_at, :utc_datetime_usec)
      add(:last_provider_class, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_apple_reconciliation_checkpoints,
        [:lineage_id, :environment],
        name: :accrue_apple_reconciliation_lineage_environment_index
      )
    )

    table = Accrue.Migration.qualified_table(:accrue_entitlement_apple_reconciliation_checkpoints)

    execute(
      "ALTER TABLE #{table} ADD CONSTRAINT accrue_apple_reconciliation_state_check CHECK (run_state IN ('idle', 'running', 'retrying', 'needs_repair'))",
      "ALTER TABLE #{table} DROP CONSTRAINT accrue_apple_reconciliation_state_check"
    )

    execute(
      "ALTER TABLE #{table} ADD CONSTRAINT accrue_apple_reconciliation_page_check CHECK (page_count >= 0 AND page_budget BETWEEN 1 AND 25 AND page_count <= page_budget)",
      "ALTER TABLE #{table} DROP CONSTRAINT accrue_apple_reconciliation_page_check"
    )
  end
end
