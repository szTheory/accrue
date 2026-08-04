defmodule Accrue.Repo.Migrations.CreateAccrueEntitlementPurchaseOverrides do
  use Ecto.Migration

  def change do
    create Accrue.Migration.table(:accrue_entitlement_purchase_overrides, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :account_id,
        Accrue.Migration.references(:accrue_entitlement_accounts,
          type: :binary_id,
          name: :accrue_entitlement_purchase_overrides_account_id_fkey
        ),
        null: false
      )

      add(:capability_digest, :string, null: false)
      add(:rail, :string, null: false)
      add(:logical_plan, :string, null: false)
      add(:reason, :string, null: false)
      add(:sources_digest, :string, null: false)
      add(:decision_revision, :bigint, null: false)
      add(:actor_id, :string, null: false)
      add(:justification, :text, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)
      add(:operation_id, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_purchase_overrides,
        [:capability_digest]
      )
    )

    create(
      Accrue.Migration.index(
        :accrue_entitlement_purchase_overrides,
        [:account_id, :decision_revision]
      )
    )
  end
end
