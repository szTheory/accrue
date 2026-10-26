import Config

portal_theme =
  case System.get_env("ACCRUE_HOST_PORTAL_THEME") do
    theme when theme in ["light", "dark"] -> String.to_atom(theme)
    _ -> :system
  end

admin_theme =
  case System.get_env("ACCRUE_HOST_ADMIN_THEME") do
    theme when theme in ["light", "dark"] -> String.to_atom(theme)
    _ -> :system
  end

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
if System.get_env("ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX") == "1" do
  # The dedicated Phase 234 search browser lane exercises Task workers that
  # need independent Repo connections. Normal test runs keep sandbox isolation.
  config :accrue_host, :sql_sandbox, false
else
  config :accrue_host, :sql_sandbox, true
  config :accrue_host, AccrueHost.Repo, pool: Ecto.Adapters.SQL.Sandbox
end

config :accrue_host, AccrueHost.Repo,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  port: String.to_integer(System.get_env("PGPORT", "5432")),
  database: "accrue_host_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool_size: String.to_integer(System.get_env("ACCRUE_HOST_TEST_POOL_SIZE", "10"))

config :accrue,
  env: :test,
  repo: AccrueHost.Repo,
  processor:
    if(System.get_env("ACCRUE_HOST_BROWSER_USE_BRAINTREE") == "1",
      do: Accrue.Processor.Braintree,
      else: Accrue.Processor.Fake
    ),
  plan_resolver: AccrueHost.Billing.PlanResolver,
  braintree_client_token_generator: AccrueHost.BraintreePortalStub.ClientTokenGenerator,
  webhook_handlers: [AccrueHost.BillingHandler],
  # test.exs — PLACEHOLDER ONLY. Production must use:
  #   webhook_signing_secrets: %{stripe: System.fetch_env!("STRIPE_WEBHOOK_SECRET")}
  webhook_signing_secrets: %{stripe: "whsec_test_host"},
  branding: [
    business_name: "Cadence",
    from_name: "Cadence Billing",
    from_email: "billing@cadence.test",
    support_email: "support@cadence.test",
    accent_color: "#26785F",
    secondary_color: "#3E6E91",
    theme: portal_theme
  ],
  admin_branding: [
    app_name: "Accrue Admin",
    accent_color: "#5D79F6",
    theme: admin_theme
  ]

config :accrue_host, Oban,
  repo: AccrueHost.Repo,
  queues: false,
  plugins: false,
  testing: :manual

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :accrue_host, AccrueHostWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  check_origin: false,
  secret_key_base: "eOS25suUgAkyXpcFF1hfjqAUQ9/hauf6AN83BzyrjnJin+b7+q0dgZUq8AxG9PgY",
  server: false

# In test we don't send emails
config :accrue_host, AccrueHost.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
