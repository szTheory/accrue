defmodule Accrue.Repo.Migrations.AllowBase64urlDeviceThumbprints do
  use Ecto.Migration

  def up do
    devices = Accrue.Migration.qualified_table(:accrue_entitlement_devices)
    constraint = "accrue_ent_devices_key_thumbprint_opaque_check"

    execute("ALTER TABLE #{devices} DROP CONSTRAINT IF EXISTS #{constraint}")

    execute(
      "ALTER TABLE #{devices} ADD CONSTRAINT #{constraint} " <>
        "CHECK (octet_length(key_thumbprint) BETWEEN 1 AND 255 AND " <>
        "key_thumbprint ~ '^[A-Za-z0-9_-][A-Za-z0-9._:-]*$')"
    )
  end

  def down do
    devices = Accrue.Migration.qualified_table(:accrue_entitlement_devices)
    constraint = "accrue_ent_devices_key_thumbprint_opaque_check"

    execute("ALTER TABLE #{devices} DROP CONSTRAINT IF EXISTS #{constraint}")

    execute(
      "ALTER TABLE #{devices} ADD CONSTRAINT #{constraint} " <>
        "CHECK (octet_length(key_thumbprint) BETWEEN 1 AND 255 AND " <>
        "key_thumbprint ~ '^[A-Za-z0-9][A-Za-z0-9._:-]*$')"
    )
  end
end
