defmodule Accrue.Repo.Migrations.CreateAccrueEvents do
  @moduledoc """
  Creates the append-only `accrue_events` table plus the immutability
  trigger and actor-type CHECK constraint.

  Defense in depth (D-09): this migration installs the BEFORE UPDATE/DELETE
  trigger that raises SQLSTATE '45A01' for any attempted mutation. A
  companion REVOKE stub lives at
  `priv/accrue/templates/migrations/revoke_accrue_events_writes.exs` which
  `mix accrue.install` (Phase 8) copies into the host app.
  """

  use Ecto.Migration

  def up do
    Accrue.Migration.create_billing_schema()

    events_table = Accrue.Migration.qualified_table(:accrue_events)

    immutable_function =
      Accrue.Migration.qualified_name(Accrue.Migration.billing_prefix(), :accrue_events_immutable)

    create Accrue.Migration.table(:accrue_events, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:type, :string, null: false)
      add(:schema_version, :integer, null: false, default: 1)
      add(:actor_type, :string, null: false)
      add(:actor_id, :string)
      add(:subject_type, :string, null: false)
      add(:subject_id, :string, null: false)
      add(:data, :map, null: false, default: %{})
      add(:trace_id, :string)
      add(:idempotency_key, :string)
      add(:inserted_at, :utc_datetime_usec, null: false, default: fragment("now()"))
    end

    create(Accrue.Migration.index(:accrue_events, [:subject_type, :subject_id, :inserted_at]))

    create(
      Accrue.Migration.unique_index(:accrue_events, [:idempotency_key],
        where: "idempotency_key IS NOT NULL",
        name: :accrue_events_idempotency_key_index
      )
    )

    execute(
      """
      ALTER TABLE #{events_table}
        ADD CONSTRAINT accrue_events_actor_type_check
        CHECK (actor_type IN ('user','system','webhook','oban','admin'))
      """,
      "ALTER TABLE #{events_table} DROP CONSTRAINT IF EXISTS accrue_events_actor_type_check"
    )

    execute(
      """
      CREATE OR REPLACE FUNCTION #{immutable_function}()
      RETURNS trigger
      LANGUAGE plpgsql AS $$
      BEGIN
        RAISE SQLSTATE '45A01'
          USING MESSAGE = 'accrue_events is append-only; UPDATE and DELETE are forbidden';
      END;
      $$;
      """,
      "DROP FUNCTION IF EXISTS #{immutable_function}()"
    )

    execute(
      """
      CREATE TRIGGER accrue_events_immutable_trigger
        BEFORE UPDATE OR DELETE ON #{events_table}
        FOR EACH ROW EXECUTE FUNCTION #{immutable_function}();
      """,
      "DROP TRIGGER IF EXISTS accrue_events_immutable_trigger ON #{events_table}"
    )
  end

  def down do
    events_table = Accrue.Migration.qualified_table(:accrue_events)

    immutable_function =
      Accrue.Migration.qualified_name(Accrue.Migration.billing_prefix(), :accrue_events_immutable)

    execute("DROP TRIGGER IF EXISTS accrue_events_immutable_trigger ON #{events_table}")
    execute("DROP FUNCTION IF EXISTS #{immutable_function}()")
    drop(Accrue.Migration.table(:accrue_events))
  end
end
