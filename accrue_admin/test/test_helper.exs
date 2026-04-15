Application.put_env(:accrue, :env, :test)
Application.put_env(:accrue, :auth_adapter, Accrue.Auth.Default)
Application.put_env(:accrue_admin, :cursor_secret, "accrue-admin-test-cursor-secret")

Application.put_env(:accrue, :branding,
  business_name: "Accrue",
  from_email: "noreply@example.com",
  support_email: "support@example.com",
  logo_url: nil,
  accent_color: "#5D79F6"
)

repo = AccrueAdmin.TestRepo
migrations_path = Path.expand("../../accrue/priv/repo/migrations", __DIR__)

case repo.__adapter__().storage_up(repo.config()) do
  :ok -> :ok
  {:error, :already_up} -> :ok
end

{:ok, _, _} =
  Ecto.Migrator.with_repo(repo, fn migrated_repo ->
    Ecto.Migrator.run(migrated_repo, migrations_path, :up, all: true, log: false)
  end)

{:ok, _} = repo.start_link(pool: Ecto.Adapters.SQL.Sandbox)
Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)

ExUnit.start()
