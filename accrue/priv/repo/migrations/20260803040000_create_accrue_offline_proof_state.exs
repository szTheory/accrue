defmodule Accrue.Repo.Migrations.CreateAccrueOfflineProofState do
  use Ecto.Migration

  def change do
    alter Accrue.Migration.table(:accrue_entitlement_devices) do
      add(:public_jwk, :map)
    end

    devices = Accrue.Migration.qualified_table(:accrue_entitlement_devices)

    execute(
      """
      ALTER TABLE #{devices} ADD CONSTRAINT accrue_entitlement_devices_public_jwk_check CHECK (
        public_jwk IS NULL OR (
          jsonb_typeof(public_jwk) = 'object' AND
          public_jwk ?& ARRAY['kty', 'crv', 'x', 'y'] AND
          public_jwk - 'kty' - 'crv' - 'x' - 'y' = '{}'::jsonb AND
          public_jwk->>'kty' = 'EC' AND public_jwk->>'crv' = 'P-256' AND
          public_jwk->>'x' ~ '^[A-Za-z0-9_-]{43}$' AND public_jwk->>'y' ~ '^[A-Za-z0-9_-]{43}$'
        )
      )
      """,
      "ALTER TABLE #{devices} DROP CONSTRAINT accrue_entitlement_devices_public_jwk_check"
    )

    create Accrue.Migration.table(:accrue_entitlement_offline_challenges, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :account_id,
        Accrue.Migration.references(:accrue_entitlement_accounts,
          type: :binary_id,
          name: :accrue_entitlement_offline_challenges_account_id_fkey,
          on_delete: :delete_all
        ),
        null: false
      )

      add(:installation_id, :string, null: false)
      add(:nonce_digest, :string, null: false)
      add(:purpose, :string, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)
      add(:consumed_at, :utc_datetime_usec)
      add(:idempotency_digest, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_offline_challenges,
        [:account_id, :installation_id, :nonce_digest],
        name: :accrue_entitlement_offline_challenges_nonce_identity_index
      )
    )

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_offline_challenges,
        [:account_id, :installation_id, :idempotency_digest],
        where: "idempotency_digest IS NOT NULL",
        name: :accrue_entitlement_offline_challenges_idempotency_identity_index
      )
    )

    challenges = Accrue.Migration.qualified_table(:accrue_entitlement_offline_challenges)

    execute(
      "ALTER TABLE #{challenges} ADD CONSTRAINT accrue_entitlement_offline_challenges_purpose_check CHECK (purpose IN ('registration', 'reconnect'))",
      "ALTER TABLE #{challenges} DROP CONSTRAINT accrue_entitlement_offline_challenges_purpose_check"
    )

    execute(
      "ALTER TABLE #{challenges} ADD CONSTRAINT accrue_entitlement_offline_challenges_digest_check CHECK (nonce_digest ~ '^[A-Za-z0-9_-]{43}$' AND (idempotency_digest IS NULL OR idempotency_digest ~ '^[A-Za-z0-9_-]{43}$'))",
      "ALTER TABLE #{challenges} DROP CONSTRAINT accrue_entitlement_offline_challenges_digest_check"
    )

    execute(
      "ALTER TABLE #{challenges} ADD CONSTRAINT accrue_entitlement_offline_challenges_installation_id_check CHECK (octet_length(installation_id) BETWEEN 1 AND 255 AND installation_id ~ '^[A-Za-z0-9][A-Za-z0-9._:-]*$')",
      "ALTER TABLE #{challenges} DROP CONSTRAINT accrue_entitlement_offline_challenges_installation_id_check"
    )

    create Accrue.Migration.table(:accrue_entitlement_offline_issuances, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :account_id,
        Accrue.Migration.references(:accrue_entitlement_accounts,
          type: :binary_id,
          name: :accrue_entitlement_offline_issuances_account_id_fkey,
          on_delete: :delete_all
        ),
        null: false
      )

      add(
        :device_id,
        Accrue.Migration.references(:accrue_entitlement_devices,
          type: :binary_id,
          name: :accrue_entitlement_offline_issuances_device_id_fkey,
          on_delete: :restrict
        ),
        null: false
      )

      add(:token_id_hash, :string, null: false)
      add(:kid, :string, null: false)
      add(:revision, :bigint, null: false)
      add(:disposition, :string, null: false)
      add(:issued_at, :utc_datetime_usec, null: false)
      add(:fresh_until, :utc_datetime_usec, null: false)
      add(:expires_at, :utc_datetime_usec)
      add(:correlation_hash, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      Accrue.Migration.unique_index(
        :accrue_entitlement_offline_issuances,
        [:account_id, :token_id_hash],
        name: :accrue_entitlement_offline_issuances_token_identity_index
      )
    )

    create(
      Accrue.Migration.index(
        :accrue_entitlement_offline_issuances,
        [:device_id, :revision, :disposition, :issued_at],
        name: :accrue_entitlement_offline_issuances_device_order_index
      )
    )

    issuances = Accrue.Migration.qualified_table(:accrue_entitlement_offline_issuances)

    execute(
      "ALTER TABLE #{issuances} ADD CONSTRAINT accrue_entitlement_offline_issuances_revision_check CHECK (revision >= 0)",
      "ALTER TABLE #{issuances} DROP CONSTRAINT accrue_entitlement_offline_issuances_revision_check"
    )

    execute(
      "ALTER TABLE #{issuances} ADD CONSTRAINT accrue_entitlement_offline_issuances_disposition_check CHECK (disposition IN ('allow', 'deny'))",
      "ALTER TABLE #{issuances} DROP CONSTRAINT accrue_entitlement_offline_issuances_disposition_check"
    )

    execute(
      "ALTER TABLE #{issuances} ADD CONSTRAINT accrue_entitlement_offline_issuances_time_order_check CHECK (issued_at <= fresh_until AND (expires_at IS NULL OR fresh_until <= expires_at))",
      "ALTER TABLE #{issuances} DROP CONSTRAINT accrue_entitlement_offline_issuances_time_order_check"
    )

    execute(
      "ALTER TABLE #{issuances} ADD CONSTRAINT accrue_entitlement_offline_issuances_digest_check CHECK (token_id_hash ~ '^[A-Za-z0-9_-]{43}$' AND (correlation_hash IS NULL OR correlation_hash ~ '^[A-Za-z0-9_-]{43}$'))",
      "ALTER TABLE #{issuances} DROP CONSTRAINT accrue_entitlement_offline_issuances_digest_check"
    )

    execute(
      "ALTER TABLE #{issuances} ADD CONSTRAINT accrue_entitlement_offline_issuances_kid_check CHECK (octet_length(kid) BETWEEN 1 AND 128 AND kid ~ '^[A-Za-z0-9._:-]+$')",
      "ALTER TABLE #{issuances} DROP CONSTRAINT accrue_entitlement_offline_issuances_kid_check"
    )
  end
end
