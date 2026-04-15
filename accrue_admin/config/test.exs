import Config

config :accrue_admin, :env, :test

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
