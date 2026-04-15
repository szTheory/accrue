import Config

config :accrue_admin, :env, :test

config :accrue_admin, AccrueAdmin.TestRepo,
  database: "accrue_admin_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost")

config :accrue_admin, ecto_repos: [AccrueAdmin.TestRepo]

config :accrue_admin, AccrueAdmin.TestEndpoint,
  url: [host: "localhost"],
  secret_key_base: String.duplicate("a", 64),
  live_view: [signing_salt: "accrue-admin-test"]

config :accrue,
  env: :test,
  repo: AccrueAdmin.TestRepo,
  branding: [
    from_email: "noreply@example.test",
    support_email: "support@example.test"
  ]
