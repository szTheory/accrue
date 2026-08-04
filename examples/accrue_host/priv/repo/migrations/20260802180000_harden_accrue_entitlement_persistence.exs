defmodule Accrue.Repo.Migrations.HardenAccrueEntitlementPersistence do
  use Ecto.Migration

  def up do
    accounts = Accrue.Migration.qualified_table(:accrue_entitlement_accounts)
    observations = Accrue.Migration.qualified_table(:accrue_entitlement_observations)
    grants = Accrue.Migration.qualified_table(:accrue_entitlement_grants)
    devices = Accrue.Migration.qualified_table(:accrue_entitlement_devices)

    execute(
      "ALTER TABLE #{accounts} ADD CONSTRAINT accrue_entitlement_accounts_revision_nonnegative_check CHECK (revision >= 0)"
    )

    for {name, check} <- [
          {"accrue_entitlement_observations_rail_domain_check", "rail IN ('stripe', 'apple')"},
          {"accrue_entitlement_observations_environment_domain_check",
           "environment IN ('production', 'sandbox')"},
          {"accrue_entitlement_observations_state_domain_check",
           "state IN ('received', 'qualified', 'quarantined', 'retrying')"},
          {"accrue_entitlement_observations_provider_order_nonnegative_check",
           "provider_order >= 0"},
          {"accrue_entitlement_observations_retry_count_nonnegative_check", "retry_count >= 0"},
          {"accrue_entitlement_observations_identity_present_check",
           "provider_event_id IS NOT NULL OR provider_transaction_id IS NOT NULL"},
          {"accrue_entitlement_observations_identity_nonblank_check",
           "(provider_event_id IS NULL OR btrim(provider_event_id) <> '') AND (provider_transaction_id IS NULL OR btrim(provider_transaction_id) <> '')"},
          {"accrue_entitlement_observations_evidence_reference_locator_check",
           "evidence_ref IS NULL OR (octet_length(evidence_ref) <= 255 AND evidence_ref ~ '^opaque://[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)*$')"}
        ] do
      execute("ALTER TABLE #{observations} ADD CONSTRAINT #{name} CHECK (#{check})")
    end

    execute(
      "ALTER TABLE #{observations} ADD CONSTRAINT accrue_entitlement_observations_source_scope_key UNIQUE (id, account_id, rail, environment)"
    )

    execute(
      "ALTER TABLE #{grants} ADD CONSTRAINT accrue_entitlement_grants_source_observation_scope_fkey FOREIGN KEY (source_observation_id, account_id, rail, environment) REFERENCES #{observations} (id, account_id, rail, environment)"
    )

    for {name, check} <- [
          {"accrue_entitlement_grants_rail_domain_check", "rail IN ('stripe', 'apple')"},
          {"accrue_entitlement_grants_environment_domain_check",
           "environment IN ('production', 'sandbox')"},
          {"accrue_entitlement_grants_quantity_positive_check", "quantity > 0"},
          {"accrue_entitlement_grants_provider_order_nonnegative_check", "provider_order >= 0"},
          {"accrue_entitlement_grants_account_revision_nonnegative_check",
           "account_revision >= 0"}
        ] do
      execute("ALTER TABLE #{grants} ADD CONSTRAINT #{name} CHECK (#{check})")
    end

    for {name, check} <- [
          {"accrue_entitlement_devices_state_domain_check",
           "state IN ('active', 'revoked', 'superseded')"},
          {"accrue_entitlement_devices_last_accepted_revision_nonnegative_check",
           "last_accepted_revision >= 0"},
          {"accrue_entitlement_devices_lifecycle_check",
           "(state = 'active' AND revoked_at IS NULL AND superseded_at IS NULL) OR (state = 'revoked' AND revoked_at IS NOT NULL AND superseded_at IS NULL) OR (state = 'superseded' AND revoked_at IS NULL AND superseded_at IS NOT NULL)"}
        ] do
      execute("ALTER TABLE #{devices} ADD CONSTRAINT #{name} CHECK (#{check})")
    end
  end

  def down do
    accounts = Accrue.Migration.qualified_table(:accrue_entitlement_accounts)
    observations = Accrue.Migration.qualified_table(:accrue_entitlement_observations)
    grants = Accrue.Migration.qualified_table(:accrue_entitlement_grants)
    devices = Accrue.Migration.qualified_table(:accrue_entitlement_devices)

    for name <-
          ~w[accrue_entitlement_devices_lifecycle_check accrue_entitlement_devices_last_accepted_revision_nonnegative_check accrue_entitlement_devices_state_domain_check],
        do: execute("ALTER TABLE #{devices} DROP CONSTRAINT #{name}")

    for name <-
          ~w[accrue_entitlement_grants_account_revision_nonnegative_check accrue_entitlement_grants_provider_order_nonnegative_check accrue_entitlement_grants_quantity_positive_check accrue_entitlement_grants_environment_domain_check accrue_entitlement_grants_rail_domain_check],
        do: execute("ALTER TABLE #{grants} DROP CONSTRAINT #{name}")

    execute(
      "ALTER TABLE #{grants} DROP CONSTRAINT accrue_entitlement_grants_source_observation_scope_fkey"
    )

    execute(
      "ALTER TABLE #{observations} DROP CONSTRAINT accrue_entitlement_observations_source_scope_key"
    )

    for name <-
          ~w[accrue_entitlement_observations_evidence_reference_locator_check accrue_entitlement_observations_identity_nonblank_check accrue_entitlement_observations_identity_present_check accrue_entitlement_observations_retry_count_nonnegative_check accrue_entitlement_observations_provider_order_nonnegative_check accrue_entitlement_observations_state_domain_check accrue_entitlement_observations_environment_domain_check accrue_entitlement_observations_rail_domain_check],
        do: execute("ALTER TABLE #{observations} DROP CONSTRAINT #{name}")

    execute(
      "ALTER TABLE #{accounts} DROP CONSTRAINT accrue_entitlement_accounts_revision_nonnegative_check"
    )
  end
end
