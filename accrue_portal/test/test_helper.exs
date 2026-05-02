Application.put_env(:accrue, :env, :test)
Application.put_env(:accrue, :auth_adapter, Accrue.Auth.Mock)
Application.put_env(:accrue, :repo, AccruePortal.TestRepo)
Application.put_env(:accrue, :processor, Accrue.Processor.Fake)
Application.put_env(:accrue, :portal_mount_path, "/billing")

Application.put_env(:accrue, :branding,
  business_name: "Accrue",
  from_email: "noreply@example.com",
  support_email: "support@example.com",
  logo_url: nil,
  accent_color: "#5D79F6"
)

Application.put_env(:accrue_portal, AccruePortal.TestEndpoint,
  secret_key_base: String.duplicate("abcd1234", 8),
  server: false,
  url: [host: "localhost"],
  render_errors: [formats: [html: Phoenix.Controller.status_message_from_template/1]]
)

repo = AccruePortal.TestRepo
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

{:ok, _} =
  Oban.start_link(
    repo: repo,
    testing: :manual,
    queues: false,
    plugins: false,
    notifier: Oban.Notifiers.PG
  )

{:ok, _} = AccruePortal.TestEndpoint.start_link()

ExUnit.start()
