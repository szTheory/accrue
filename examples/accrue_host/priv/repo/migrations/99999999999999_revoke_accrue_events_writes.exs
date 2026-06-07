# accrue:generated
# accrue:fingerprint: ea3db4f93c2d77da6f459f054eadbd78b32d22c9371a885f2506780fef60ebc6
defmodule AccrueHost.Repo.Migrations.RevokeAccrueEventsWrites do
  use Ecto.Migration

  @app_role "accrue_app"

  def up do
    execute(revoke_sql())
  end

  def down do
    execute(grant_sql())
  end

  defp revoke_sql do
    events_table = Accrue.Migration.qualified_table(:accrue_events)

    """
    DO $$
    BEGIN
      IF to_regrole('#{@app_role}') IS NOT NULL THEN
        EXECUTE 'REVOKE UPDATE, DELETE, TRUNCATE ON #{events_table} FROM #{@app_role}';
      END IF;
    END
    $$;
    """
  end

  defp grant_sql do
    events_table = Accrue.Migration.qualified_table(:accrue_events)

    """
    DO $$
    BEGIN
      IF to_regrole('#{@app_role}') IS NOT NULL THEN
        EXECUTE 'GRANT UPDATE, DELETE, TRUNCATE ON #{events_table} TO #{@app_role}';
      END IF;
    END
    $$;
    """
  end
end
