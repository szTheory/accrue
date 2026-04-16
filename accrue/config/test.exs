import Config

# Swoosh test mailbox — enables Swoosh.TestAssertions.assert_email_sent/1 (Plan 05 Task 1).
config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Test

# D6-05: default test-env mailer adapter sidesteps Oban and sends
# `{:accrue_email_delivered, type, assigns}` to the calling test pid.
# Tests that need a rendered %Swoosh.Email{} body can override per-test
# via `Application.put_env/3` back to `Accrue.Mailer.Default`.
config :accrue, :mailer, Accrue.Mailer.Test

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

# Phase 6 (D6-02): seed nested :branding with the two required keys so
# existing Phase 1-5 tests continue to validate_at_boot!/0 cleanly.
config :accrue, :branding,
  from_email: "noreply@example.test",
  support_email: "support@example.test"

# The SDK defaults to the OTLP exporter, but this package does not depend on
# `:opentelemetry_exporter`. Disable exporters in test so `ensure_all_started/1`
# and targeted OTel tests stay warning-free under `--warnings-as-errors`.
config :opentelemetry,
  traces_exporter: :none,
  metrics_exporter: :none
