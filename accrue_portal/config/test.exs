import Config

config :accrue_portal, :env, :test

config :accrue_portal, AccruePortal.TestRepo,
  database: "accrue_portal_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost")

config :accrue_portal, ecto_repos: [AccruePortal.TestRepo]

config :accrue_portal, AccruePortal.TestEndpoint,
  url: [host: "localhost"],
  secret_key_base: String.duplicate("a", 64),
  live_view: [signing_salt: "accrue-portal-test"],
  render_errors: [formats: [html: &Phoenix.Controller.status_message_from_template/1]]
