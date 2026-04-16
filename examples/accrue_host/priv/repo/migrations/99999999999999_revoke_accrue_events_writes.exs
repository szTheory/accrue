# accrue:generated
# accrue:fingerprint: 8e68e83d5835edffa26d74158ae6771ad71ef66679340dff89597c6f0db9f1f6
defmodule AccrueHost.Repo.Migrations.RevokeAccrueEventsWrites do
  use Ecto.Migration

  @app_role "accrue_app"

  def up do
    execute revoke_sql()
  end

  def down do
    execute grant_sql()
  end

  defp revoke_sql do
    """
    DO $$
    BEGIN
      IF to_regrole('#{@app_role}') IS NOT NULL THEN
        EXECUTE 'REVOKE UPDATE, DELETE, TRUNCATE ON accrue_events FROM #{@app_role}';
      END IF;
    END
    $$;
    """
  end

  defp grant_sql do
    """
    DO $$
    BEGIN
      IF to_regrole('#{@app_role}') IS NOT NULL THEN
        EXECUTE 'GRANT UPDATE, DELETE, TRUNCATE ON accrue_events TO #{@app_role}';
      END IF;
    END
    $$;
    """
  end
end
