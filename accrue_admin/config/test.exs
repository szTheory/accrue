import Config

phase252_nonce = System.get_env("PHASE252_E2E_NONCE")
phase252_partition = System.get_env("PHASE252_E2E_PARTITION")
phase252_database = System.get_env("PHASE252_E2E_DATABASE")
phase252_port = System.get_env("PHASE252_E2E_PORT")
phase252_address = System.get_env("PHASE252_E2E_ADDRESS")
phase252_pg_host = System.get_env("PHASE252_E2E_PGHOST")
phase252_role = System.get_env("PHASE252_E2E_ROLE")
phase252_lane = System.get_env("PHASE252_E2E_LANE")
phase252_parent = System.get_env("PHASE252_E2E_PARENT_PID")

if not is_nil(phase252_nonce) do
  valid_partition =
    is_binary(phase252_partition) and Regex.match?(~r/^\d{8,16}$/, phase252_partition)

  valid_port = is_binary(phase252_port) and Regex.match?(~r/^\d{1,5}$/, phase252_port)

  valid_address =
    phase252_address == "::1" or
      (is_binary(phase252_address) and Regex.match?(~r/^127(?:\.\d{1,3}){3}$/, phase252_address))

  valid_pg_host = phase252_pg_host in ["127.0.0.1", "localhost", "::1"]

  unless valid_partition and phase252_database == "accrue_admin_test#{phase252_partition}" and
           System.get_env("MIX_TEST_PARTITION") == phase252_partition and valid_port and
           valid_address and valid_pg_host and phase252_role == "postgres" and
           phase252_lane in ["admin-test", "admin-review"] and
           is_binary(phase252_parent) and Regex.match?(~r/^\d+$/, phase252_parent) do
    raise "Phase 252 E2E identity is incomplete or unsafe; refusing test configuration"
  end
end

config :accrue_admin, :env, :test

config :accrue_admin, AccrueAdmin.TestRepo,
  database: "accrue_admin_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  port: String.to_integer(System.get_env("PGPORT", "5432")),
  parameters: [timezone: "UTC"]

config :accrue_admin, ecto_repos: [AccrueAdmin.TestRepo]

config :accrue_admin, AccrueAdmin.TestEndpoint,
  url: [host: "localhost"],
  secret_key_base: String.duplicate("a", 64),
  live_view: [signing_salt: "accrue-admin-test"]

config :accrue,
  env: :test,
  repo: AccrueAdmin.TestRepo,
  billing_schema: "billing",
  branding: [
    from_email: "noreply@example.test",
    support_email: "support@example.test"
  ]
