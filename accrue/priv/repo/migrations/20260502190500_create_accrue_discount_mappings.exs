defmodule Accrue.Repo.Migrations.CreateAccrueDiscountMappings do
  use Ecto.Migration

  def change do
    create Accrue.Migration.table(:accrue_discount_mappings, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:processor, :string, null: false, default: "braintree")
      add(:code, :string, null: false)
      add(:discount_id, :string, null: false)
      add(:active, :boolean, null: false, default: true)
      add(:amount_off_minor, :integer, null: false)
      add(:currency, :string, null: false)
      add(:duration_in_billing_cycles, :integer)
      add(:expires_at, :utc_datetime_usec)
      add(:max_redemptions, :integer)
      add(:times_redeemed, :integer, null: false, default: 0)
      add(:metadata, :map, null: false, default: %{})
      add(:data, :map, null: false, default: %{})
      add(:lock_version, :integer, null: false, default: 1)

      timestamps(type: :utc_datetime_usec)
    end

    create(Accrue.Migration.unique_index(:accrue_discount_mappings, [:processor, :code]))
    create(Accrue.Migration.index(:accrue_discount_mappings, [:processor, :discount_id]))
  end
end
