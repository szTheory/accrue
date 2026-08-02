defmodule Accrue.Repo.Migrations.BoundAccrueEntitlementProviderIdentity do
  use Ecto.Migration

  def up do
    observations = Accrue.Migration.qualified_table(:accrue_entitlement_observations)
    grants = Accrue.Migration.qualified_table(:accrue_entitlement_grants)

    for field <-
          ~w[provider_event_id provider_transaction_id kind provider_lineage_id provider_product_id] do
      execute("ALTER TABLE #{observations} ALTER COLUMN #{field} TYPE text")
    end

    for field <- ~w[provider_lineage_id provider_product_id] do
      execute("ALTER TABLE #{grants} ALTER COLUMN #{field} TYPE text")
    end

    for {name, check} <- observation_constraints() do
      execute("ALTER TABLE #{observations} ADD CONSTRAINT #{name} CHECK (#{check})")
    end

    for {name, check} <- grant_constraints() do
      execute("ALTER TABLE #{grants} ADD CONSTRAINT #{name} CHECK (#{check})")
    end
  end

  def down do
    observations = Accrue.Migration.qualified_table(:accrue_entitlement_observations)
    grants = Accrue.Migration.qualified_table(:accrue_entitlement_grants)

    grant_constraints()
    |> Enum.reverse()
    |> Enum.each(fn {name, _check} ->
      execute("ALTER TABLE #{grants} DROP CONSTRAINT IF EXISTS #{name}")
    end)

    observation_constraints()
    |> Enum.reverse()
    |> Enum.each(fn {name, _check} ->
      execute("ALTER TABLE #{observations} DROP CONSTRAINT #{name}")
    end)

    for field <- ~w[provider_lineage_id provider_product_id] do
      execute("ALTER TABLE #{grants} ALTER COLUMN #{field} TYPE varchar(255)")
    end

    for field <-
          ~w[provider_event_id provider_transaction_id kind provider_lineage_id provider_product_id] do
      execute("ALTER TABLE #{observations} ALTER COLUMN #{field} TYPE varchar(255)")
    end
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
       "octet_length(provider_product_id) <= 255"},
      {"accrue_ent_obs_metadata_projection_check",
       "jsonb_typeof(metadata) = 'object' AND (metadata = '{}'::jsonb OR metadata = '{\"source\": \"apple_server\"}'::jsonb OR metadata = '{\"source\": \"fake_observer\"}'::jsonb)"}
    ]
  end

  defp grant_constraints do
    [
      {"accrue_ent_grants_provider_lineage_id_bytes_check",
       "octet_length(provider_lineage_id) <= 255"},
      {"accrue_ent_grants_provider_product_id_bytes_check",
       "octet_length(provider_product_id) <= 255"}
    ]
  end
end
