defmodule Accrue.Repo.Migrations.AddAppleOrderingToEntitlementRecords do
  use Ecto.Migration

  def up do
    observations = Accrue.Migration.qualified_table(:accrue_entitlement_observations)
    grants = Accrue.Migration.qualified_table(:accrue_entitlement_grants)

    alter table(:accrue_entitlement_observations, prefix: Accrue.Migration.billing_prefix()) do
      add(:provider_order_key, :string)
      add(:expires_at, :utc_datetime_usec)
    end

    alter table(:accrue_entitlement_grants, prefix: Accrue.Migration.billing_prefix()) do
      add(:provider_order_key, :string)
    end

    execute(
      "ALTER TABLE #{observations} ADD CONSTRAINT accrue_ent_obs_provider_order_key_bytes_check CHECK (provider_order_key IS NULL OR (octet_length(provider_order_key) > 0 AND octet_length(provider_order_key) <= 128))"
    )

    execute(
      "ALTER TABLE #{grants} ADD CONSTRAINT accrue_ent_grants_provider_order_key_bytes_check CHECK (provider_order_key IS NULL OR (octet_length(provider_order_key) > 0 AND octet_length(provider_order_key) <= 128))"
    )
  end

  def down do
    observations = Accrue.Migration.qualified_table(:accrue_entitlement_observations)
    grants = Accrue.Migration.qualified_table(:accrue_entitlement_grants)

    execute(
      "ALTER TABLE #{grants} DROP CONSTRAINT accrue_ent_grants_provider_order_key_bytes_check"
    )

    execute(
      "ALTER TABLE #{observations} DROP CONSTRAINT accrue_ent_obs_provider_order_key_bytes_check"
    )

    alter table(:accrue_entitlement_grants, prefix: Accrue.Migration.billing_prefix()) do
      remove(:provider_order_key)
    end

    alter table(:accrue_entitlement_observations, prefix: Accrue.Migration.billing_prefix()) do
      remove(:expires_at)
      remove(:provider_order_key)
    end
  end
end
