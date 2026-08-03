defmodule Accrue.Repo.Migrations.CreateAccrueEntitlementPurchaseOperations do
  use Ecto.Migration

  def change do
    create Accrue.Migration.table(:accrue_entitlement_purchase_operations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:account_id, :uuid, null: false)
      add(:operation_id, :string, null: false)
      add(:rail, :string, null: false)
      add(:product_id, :string, null: false)
      add(:status, :string, null: false)
      add(:subscription_id, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_purchase_operations,
        [:account_id, :operation_id],
        name: :accrue_entitlement_purchase_operations_account_operation_index
      )
    )
  end
end
