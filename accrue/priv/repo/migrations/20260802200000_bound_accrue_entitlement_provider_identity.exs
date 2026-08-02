defmodule Accrue.Repo.Migrations.BoundAccrueEntitlementProviderIdentity do
  use Ecto.Migration

  def up do
    observations = Accrue.Migration.qualified_table(:accrue_entitlement_observations)

    for {name, check} <- observation_constraints() do
      execute("ALTER TABLE #{observations} ADD CONSTRAINT #{name} CHECK (#{check})")
    end
  end

  def down do
    observations = Accrue.Migration.qualified_table(:accrue_entitlement_observations)

    observation_constraints()
    |> Enum.reverse()
    |> Enum.each(fn {name, _check} ->
      execute("ALTER TABLE #{observations} DROP CONSTRAINT #{name}")
    end)
  end

  defp observation_constraints do
    [
      {"accrue_ent_obs_provider_event_id_bytes_check",
       "provider_event_id IS NULL OR octet_length(provider_event_id) <= 255"},
      {"accrue_ent_obs_provider_transaction_id_bytes_check",
       "provider_transaction_id IS NULL OR octet_length(provider_transaction_id) <= 255"},
      {"accrue_ent_obs_kind_bytes_check", "octet_length(kind) <= 64"},
      {"accrue_ent_obs_provider_lineage_id_bytes_check",
       "octet_length(provider_lineage_id) <= 255"},
      {"accrue_ent_obs_provider_product_id_bytes_check",
       "octet_length(provider_product_id) <= 255"}
    ]
  end
end
