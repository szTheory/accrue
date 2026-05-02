import Config

config :ex_cldr, default_backend: Accrue.Cldr
config :ex_money, default_cldr_backend: Accrue.Cldr

config :accrue, :env, :test
config :accrue, :auth_adapter, Accrue.Auth.Mock
config :accrue, :repo, AccruePortal.TestRepo
config :accrue, :processor, Accrue.Processor.Fake
config :accrue, :portal_mount_path, "/billing"

config :accrue, :branding,
  business_name: "Accrue",
  from_email: "noreply@example.com",
  support_email: "support@example.com",
  logo_url: nil,
  accent_color: "#5D79F6"

import_config "#{config_env()}.exs"
