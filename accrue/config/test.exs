import Config

# Swoosh test mailbox — enables Swoosh.TestAssertions.assert_email_sent/1 (Plan 05 Task 1).
config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Test

# Accrue.TestRepo — lives in test/support only (never in lib/ — D-10). Plan 03 uses this
# as the Repo for event-ledger integration tests. Sandbox wiring so parallel tests work.
config :accrue, Accrue.TestRepo,
  database: "accrue_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  priv: "priv/repo"

config :accrue, ecto_repos: [Accrue.TestRepo]
config :accrue, :repo, Accrue.TestRepo
