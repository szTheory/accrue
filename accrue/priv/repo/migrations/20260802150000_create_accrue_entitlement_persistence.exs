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
  end
end
